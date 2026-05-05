---
date: 2026-05-05
tags:
  - webhook
  - events
  - automation
  - integrations
  - ci-cd
  - 自动化与CI-CD
source_skill: webhook-subscriptions
category: 自动化与 CI-CD
---

# Webhook 订阅管理

> 本文档基于 Hermes Agent 的 `webhook-subscriptions` 技能整理，详细介绍 Webhook 的创建、配置、安全管理和事件驱动编程模式。

## 概述

Webhook 是一种**事件驱动的通信机制**，允许外部服务（GitHub、GitLab、Stripe、CI/CD 系统、IoT 传感器、监控工具等）在特定事件发生时，通过 HTTP POST 请求将数据推送到指定的 URL。

与传统的轮询（Polling）模式相比，Webhook 具有以下优势：

- **实时性** — 事件发生时立即通知，无需定期查询
- **效率** — 只传输有意义的变更数据，节省带宽和计算资源
- **解耦** — 服务之间通过事件契约通信，无需共享状态
- **可扩展** — 可以连接任意数量的订阅者

GitHub 的 Webhook 是其生态系统的核心集成机制之一，贯穿于 CI/CD 流水线、自动化部署、代码审查通知和协作工作流中。

## 架构原理

```
┌─────────────┐     POST /webhook/events     ┌───────────────┐
│             │  ─────────────────────────>  │               │
│  事件源      │                              │  Webhook 适配器 │
│  (GitHub)    │                              │  (Hermes 网关)  │
│             │  <─── 200 OK ──────────────  │               │
└─────────────┘                              └───────┬───────┘
                                                      │
                                                      │ 触发 Agent
                                                      ▼
                                              ┌───────────────┐
                                              │               │
                                              │  Hermes Agent  │
                                              │  (处理 & 响应)  │
                                              │               │
                                              └───────┬───────┘
                                                      │
                                        ┌─────────────┼─────────────┐
                                        │             │             │
                                        ▼             ▼             ▼
                                    Telegram     Discord    GitHub Comment
```

## Hermes Webhook 平台配置

Hermes Agent 内置了 Webhook 适配器，可以动态管理订阅。

### 启用 Webhook 平台

```bash
# 检查当前状态
hermes webhook list

# 如果提示 "Webhook platform is not enabled"，执行设置向导
hermes gateway setup
```

### 手动配置

在 `~/.hermes/config.yaml` 中添加：

```yaml
platforms:
  webhook:
    enabled: true
    extra:
      host: "0.0.0.0"
      port: 8644
      secret: "generate-a-strong-secret-here"
```

或者使用环境变量（添加至 `~/.hermes/.env`）：

```bash
WEBHOOK_ENABLED=true
WEBHOOK_PORT=8644
WEBHOOK_SECRET=generate-a-strong-secret-here
```

### 启动网关

```bash
# 前台运行
hermes gateway run

# 或使用 systemd
systemctl --user restart hermes-gateway
```

### 验证运行状态

```bash
curl http://localhost:8644/health
# 返回：{"status": "ok"}
```

## 订阅管理命令

### 创建订阅

```bash
hermes webhook subscribe <subscription-name> \
  --prompt "Prompt template with {payload.fields}" \
  --events "event1,event2" \
  --description "订阅功能描述" \
  --skills "skill1,skill2" \
  --deliver telegram \
  --deliver-chat-id "12345" \
  --secret "optional-custom-secret"
```

命令执行后会返回 Webhook URL 和 HMAC 密钥，你需要将这些配置到外部服务中。

### 列出所有订阅

```bash
hermes webhook list
```

### 移除订阅

```bash
hermes webhook remove <subscription-name>
```

### 测试订阅

```bash
# 使用默认测试数据
hermes webhook test <subscription-name>

# 使用自定义 payload 测试
hermes webhook test <subscription-name> --payload '{"key": "value"}'
```

## Prompt 模板语法

Prompt 模板支持 `{dot.notation}` 语法访问嵌套的 payload 字段：

| 模板变量 | 对应数据 |
|---------|---------|
| `{issue.title}` | GitHub Issue 标题 |
| `{issue.number}` | Issue 编号 |
| `{issue.body}` | Issue 正文 |
| `{issue.user.login}` | 提报人用户名 |
| `{pull_request.title}` | PR 标题 |
| `{pull_request.user.login}` | PR 作者 |
| `{pull_request.head.ref}` | PR 源分支 |
| `{action}` | 事件动作类型 |
| `{data.object.amount}` | Stripe 支付金额 |
| `{data.object.status}` | 支付状态 |
| `{sensor.temperature}` | IoT 传感器温度 |
| `{project.name}` | 项目名称 |
| `{object_attributes.status}` | CI/CD 构建状态 |
| `{commit.message}` | 提交消息 |

如果未指定 prompt，完整的 JSON payload 会被直接注入到 Agent 的提示中。

## 常见集成模式

### GitHub Issue 事件

这是最常见的 Webhook 用例之一——当有新的 Issue 创建时自动触发 Agent 进行分流：

```bash
hermes webhook subscribe github-issues \
  --events "issues" \
  --prompt "新的 GitHub Issue #{issue.number}: {issue.title}

操作: {action}
作者: {issue.user.login}
内容:
{issue.body}

请对此 Issue 进行分析和分流。"
```

然后在 GitHub 仓库中配置 Webhook：

1. 进入仓库 Settings → Webhooks → Add webhook
2. Payload URL: 设置为返回的 webhook_url
3. Content type: application/json
4. Secret: 设置为返回的密钥
5. Events: 选择 "Issues"

### GitHub Pull Request 事件

```bash
hermes webhook subscribe github-prs \
  --events "pull_request" \
  --prompt "PR #{pull_request.number} {pull_request.action}: {pull_request.title}
作者: {pull_request.user.login}
分支: {pull_request.head.ref}

{pull_request.body}" \
  --skills "github-code-review" \
  --deliver github_comment
```

这个模式允许 Agent 自动审查新提交的 PR，并在 PR 上留下内联评论。

### CI/CD 构建通知

```bash
hermes webhook subscribe ci-builds \
  --events "pipeline" \
  --prompt "构建 {object_attributes.status} — 项目: {project.name}
分支: {object_attributes.ref}
提交: {commit.message}" \
  --deliver discord \
  --deliver-chat-id "1234567890"
```

### Stripe 支付事件

```bash
hermes webhook subscribe stripe-payments \
  --events "payment_intent.succeeded,payment_intent.payment_failed" \
  --prompt "支付 {data.object.status}: {data.object.amount} 分 ({data.object.currency})
来自: {data.object.receipt_email}" \
  --deliver telegram \
  --deliver-chat-id "-100123456789"
```

### 通用监控告警

```bash
hermes webhook subscribe alerts \
  --prompt "告警: {alert.name}
严重级别: {alert.severity}
消息: {alert.message}

请调查并建议修复方案。" \
  --deliver origin
```

## 安全机制

Webhook 安全是生产环境部署的关键环节：

1. **HMAC 签名验证** — 每个订阅自动生成 HMAC-SHA256 密钥，适配器在每次 POST 请求时验证签名
2. **自定义密钥** — 可以通过 `--secret` 参数提供自己的密钥
3. **静态路由保护** — 配置文件中的静态路由不受动态订阅影响
4. **持久化存储** — 订阅信息持久化到 `~/.hermes/webhook_subscriptions.json`

### 签名验证流程

```bash
# GitHub 发送 X-Hub-Signature-256 头
# GitLab 发送 X-Gitlab-Token 头
# 适配器比较签名与本地计算的 HMAC-SHA256

# 手动验证签名（调试用）
echo -n "$payload" | openssl dgst -sha256 -hmac "$secret"
```

## 故障排查指南

### Webhook 不工作的常见原因

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| 网关未响应 | 网关未运行 | `systemctl --user status hermes-gateway` 检查状态 |
| 端口未监听 | 端口被占用或配置错误 | `curl http://localhost:8644/health` 检查健康 |
| 签名不匹配 | 密钥配置错误 | 对比 `hermes webhook list` 中的密钥与外部服务配置 |
| 无事件触发 | 事件类型过滤 | 检查 `--events` 是否匹配服务发送的事件 |
| 无法从公网访问 | NAT/防火墙 | 本地开发使用 ngrok/cloudflared 隧道 |
| 超时 | 响应处理过慢 | 检查 Agent 的 prompt 是否过于复杂 |

### 日志检查

```bash
# 查看 Webhook 相关日志
grep webhook ~/.hermes/logs/gateway.log | tail -20

# 查看完整日志
tail -f ~/.hermes/logs/gateway.log
```

### 使用 ngrok 暴露本地服务

```bash
# 安装 ngrok
brew install ngrok  # macOS
# 或从 https://ngrok.com/download 下载

# 启动隧道
ngrok http 8644

# 将 https://xxx.ngrok.io 配置为 Webhook URL
```

## 最佳实践

### 1. 事件过滤

尽量精确配置 `--events` 参数，只订阅必要的事件类型，避免 Agent 被无关事件淹没。

### 2. 密钥管理

- 每个订阅使用独立的密钥
- 定期轮换密钥
- 不要在代码库中硬编码密钥

### 3. Prompt 设计

- 提供足够的上下文信息，但保持简洁
- 包含关键字段（事件类型、来源、涉及的对象）
- 对于复杂场景，指定要使用的 `--skills`

### 4. 幂等性处理

Webhook 可能会重复投递，建议在 prompt 中要求 Agent 检测并处理重复事件。

### 5. 分级通知

- 关键事件 → 即时通知（Telegram/Discord）
- 常规事件 → 异步处理（Issue 评论）
- 低优先级事件 → 汇总报告

## 实际案例：完整自动化流水线

结合 [[../05-自主AI-Agent/autonomous-agents]] 和本节的 Webhook，可以构建完整的自动化流水线：

```bash
# 1. GitHub Issue 创建 → Agent 自动分流
hermes webhook subscribe gh-issue-triage \
  --events "issues" \
  --prompt "新 Issue #{issue.number}: {issue.title}

请根据以下标准进行分流：
1. 是否为 Bug？→ 添加 `bug` 标签，分配优先级
2. 是否为功能请求？→ 添加 `enhancement` 标签
3. 是否需要更多信息？→ 评论请求详情
4. 设置合适的标签" \
  --skills "github-issues" \
  --deliver origin

# 2. PR 创建 → 自动代码审查
hermes webhook subscribe gh-pr-review \
  --events "pull_request" \
  --prompt "审查 PR #{pull_request.number}: {pull_request.title}

变更文件: {pull_request.changed_files}
变更行数: +{pull_request.additions}/-{pull_request.deletions}

请进行初步代码审查并留下反馈。" \
  --skills "github-code-review" \
  --deliver github_comment
```

## 相关文档

- [[ci-cd-workflows]] — CI/CD 工作流设计模式
- [[automation-patterns]] — 自动化模式
- [[../02-GitHub-核心操作/github-code-review]] — 代码审查
- [[../05-自主AI-Agent/autonomous-agents]] — 自主 AI Agent
