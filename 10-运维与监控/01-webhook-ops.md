---
date: 2026-05-05
tags:
  - webhook
  - event-driven
  - automation
  - github
  - operations
  - 运维与监控
source_skill: webhook-subscriptions
category: 运维与监控
---

# Webhook 订阅管理

> 本文档基于 Hermes Agent 的 `webhook-subscriptions` 技能整理，覆盖 Webhook 创建、管理和事件驱动的自动化运维。

## 概述

Webhook 是 GitHub 生态中**事件驱动自动化**的核心机制。当仓库发生指定事件（如 push、PR、issue）时，GitHub 会向配置的 URL 发送 HTTP POST 请求。通过 Webhook，可以将 GitHub 事件与 CI/CD、通知、自动部署等系统实时联动。

### 核心能力

| 功能 | 说明 | 适用场景 |
|------|------|---------|
| 创建 Webhook | 为仓库/组织注册事件监听 | 自动触发流水线 |
| 管理 Webhook | 启用/禁用/更新/删除 | 运维配置变更 |
| 事件过滤 | 只订阅特定事件 | 降低噪音 |
| 失败重试 | 自动重试失败投递 | 高可用保障 |
| 安全签名 | Secret 验证请求来源 | 防伪造攻击 |
| 日志查看 | 查询投递历史和响应 | 调试和监控 |

---

## 通过 GitHub CLI 管理

### 列出 Webhook

```bash
# 列出仓库的 Webhook
gh api repos/:owner/:repo/hooks --jq '.[] | {id, name, url: .config.url, events, active}'

# 列出组织的 Webhook
gh api orgs/:org/hooks --jq '.[] | {id, name, url: .config.url, events, active}'

# 格式化输出
gh api repos/:owner/:repo/hooks \
  --jq '.[] | "\(.id) | \(.config.url) | \(.events | join(",")) | \(.active)"'
```

### 创建 Webhook

```bash
# 创建仓库 Webhook（监听所有事件）
gh api repos/:owner/:repo/hooks \
  --method POST \
  --field name='web' \
  --field active=true \
  --field 'config[url]="https://your-server.com/webhook"' \
  --field 'config[content_type]="json"' \
  --field 'config[secret]="your-webhook-secret"' \
  --field 'events[]'='*'

# 只监听特定事件（push 和 pull_request）
gh api repos/:owner/:repo/hooks \
  --method POST \
  --field name='web' \
  --field active=true \
  --field 'config[url]="https://your-server.com/github-events"' \
  --field 'config[content_type]="json"' \
  --field 'config[secret]="your-secret"' \
  --field 'events[]'='push' \
  --field 'events[]'='pull_request'
```

### 更新和删除

```bash
# 更新 Webhook URL
gh api repos/:owner/:repo/hooks/:hook_id \
  --method PATCH \
  --field 'config[url]="https://new-server.com/webhook"'

# 启用/禁用 Webhook
gh api repos/:owner/:repo/hooks/:hook_id \
  --method PATCH \
  --field active=false

# 删除 Webhook
gh api repos/:owner/:repo/hooks/:hook_id \
  --method DELETE
```

---

## 支持的 Webhook 事件

### 核心事件

| 事件名称 | 触发条件 | 负载示例 |
|----------|---------|---------|
| `push` | 推送提交到分支 | commits, ref, before/after SHA |
| `pull_request` | PR 创建/更新/关闭/合并 | action, number, changes |
| `pull_request_review` | PR 审查提交 | action, review state |
| `issues` | Issue 创建/更新/关闭 | action, issue body/labels |
| `issue_comment` | Issue 评论 | action, comment body |
| `create` | 创建分支/标签 | ref, ref_type |
| `delete` | 删除分支/标签 | ref, ref_type |
| `release` | 发布 Release | action, release tag |
| `workflow_run` | Actions 工作流完成 | workflow, conclusion |

### 组织级事件

| 事件名称 | 说明 |
|----------|------|
| `member` | 成员加入/离开组织 |
| `team` | 团队创建/修改/删除 |
| `organization` | 组织设置变更 |
| `repository` | 仓库创建/删除/转移 |

### 安全事件

| 事件名称 | 说明 |
|----------|------|
| `secret_scanning_alert` | Secret 扫描告警 |
| `dependabot_alert` | Dependabot 依赖告警 |
| `code_scanning_alert` | CodeQL 扫描告警 |

---

## Webhook 服务器实现

### Flask 接收端

```python
# webhook_server.py
from flask import Flask, request, jsonify
import hmac
import hashlib
import json
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Webhook Secret（与 GitHub 配置一致）
WEBHOOK_SECRET = "your-webhook-secret"

def verify_signature(payload, signature_header):
    """验证 GitHub Webhook 签名"""
    if not signature_header:
        return False
    
    # GitHub 使用 HMAC-SHA256
    expected = "sha256=" + hmac.new(
        WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(expected, signature_header)

@app.route('/webhook', methods=['POST'])
def handle_webhook():
    # 获取签名
    signature = request.headers.get('X-Hub-Signature-256')
    
    # 验证签名
    if not verify_signature(request.data, signature):
        return jsonify({'error': 'Invalid signature'}), 401
    
    # 获取事件类型
    event = request.headers.get('X-GitHub-Event')
    delivery_id = request.headers.get('X-GitHub-Delivery')
    payload = request.json
    
    logging.info(f"📡 收到事件: {event}")
    logging.info(f"    ID: {delivery_id}")
    
    # 根据事件类型处理
    if event == 'push':
        handle_push_event(payload)
    elif event == 'pull_request':
        handle_pr_event(payload)
    elif event == 'issues':
        handle_issue_event(payload)
    elif event == 'workflow_run':
        handle_workflow_event(payload)
    else:
        logging.info(f"未处理的事件类型: {event}")
    
    return jsonify({'status': 'ok'}), 200

def handle_push_event(payload):
    """处理 Push 事件"""
    ref = payload['ref']
    repo = payload['repository']['full_name']
    commits = payload.get('commits', [])
    
    logging.info(f"📦 [{repo}] Push to {ref}")
    for commit in commits[:3]:  # 只显示前 3 个
        author = commit['author']['name']
        message = commit['message'].split('\n')[0]
        logging.info(f"  💬 {author}: {message}")
    
    # 这里可以触发 CI/CD 构建等操作

def handle_pr_event(payload):
    """处理 Pull Request 事件"""
    action = payload['action']
    pr = payload['pull_request']
    repo = payload['repository']['full_name']
    
    logging.info(f"🔀 [{repo}] PR #{pr['number']} {action}")
    logging.info(f"    {pr['title']} by {pr['user']['login']}")
    
    if action == 'opened':
        # PR 打开时自动分配审查者
        auto_assign_reviewers(pr)

def handle_issue_event(payload):
    """处理 Issue 事件"""
    action = payload['action']
    issue = payload['issue']
    
    logging.info(f"📌 Issue #{issue['number']} {action}: {issue['title']}")

def handle_workflow_event(payload):
    """处理 Workflow Run 事件"""
    workflow = payload['workflow']
    run = payload['workflow_run']
    conclusion = run.get('conclusion', 'unknown')
    
    logging.info(f"⚡ Workflow: {workflow['name']} -> {conclusion}")

def auto_assign_reviewers(pr):
    """自动分配 PR 审查者（示例）"""
    # 实现自动分配逻辑
    pass

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, ssl_context='adhoc')
```

### 使用 ngrok 本地测试

```bash
# 1. 启动 Webhook 服务器
python webhook_server.py

# 2. 启动 ngrok 暴露本地端口
ngrok http 8080

# 3. 复制 ngrok 提供的 HTTPS URL
# https://abc123.ngrok.io

# 4. 使用该 URL 创建 Webhook
gh api repos/:owner/:repo/hooks \
  --method POST \
  --field name='web' \
  --field active=true \
  --field 'config[url]="https://abc123.ngrok.io/webhook"' \
  --field 'config[content_type]="json"' \
  --field 'config[secret]="your-secret"' \
  --field 'events[]'='push' \
  --field 'events[]'='pull_request'
```

---

## 投递日志与调试

```bash
# 查询最近投递记录
gh api repos/:owner/:repo/hooks/:hook_id/deliveries \
  --jq '.[] | "\(.id) | \(.delivered_at) | \(.response.status) | \(.event)"'

# 查看投递详情
gh api repos/:owner/:repo/hooks/:hook_id/deliveries/:delivery_id

# 重新投递失败的请求
gh api repos/:owner/:repo/hooks/:hook_id/deliveries/:delivery_id/attempts \
  --method POST
```

---

## 安全最佳实践

```python
# Webhook 安全验证完整版
import hmac
import hashlib

class WebhookSecurity:
    @staticmethod
    def verify(payload_body, secret, signature_header):
        """验证 Webhook 签名"""
        if not signature_header:
            return False
        
        # 支持两种签名格式
        hash_funcs = {
            'sha1': hashlib.sha1,
            'sha256': hashlib.sha256,
        }
        
        for prefix, hash_func in hash_funcs.items():
            expected_prefix = f"{prefix}="
            if signature_header.startswith(expected_prefix):
                expected = expected_prefix + hmac.new(
                    secret.encode(),
                    payload_body,
                    hash_func
                ).hexdigest()
                return hmac.compare_digest(expected, signature_header)
        
        return False
    
    @staticmethod
    def validate_ip(ip_address):
        """验证请求来源 IP 是否来自 GitHub"""
        # GitHub Webhook 来源 IP 范围
        # 完整列表: https://api.github.com/meta
        github_hooks_ips = [
            "192.30.252.0/22",
            "185.199.108.0/22",
            "140.82.112.0/20",
            "143.55.64.0/20",
        ]
        # 简化验证：使用 ipaddress 模块
        import ipaddress
        client_ip = ipaddress.ip_address(ip_address)
        for cidr in github_hooks_ips:
            if client_ip in ipaddress.ip_network(cidr):
                return True
        return False
```

---

## 相关技能

- [[02-blog-monitor]] — Blog/RSS 监控
- [[03-pages-ops]] — GitHub Pages 运维
- [[04-serverless-gpu]] — Modal 无服务器 GPU 运维
