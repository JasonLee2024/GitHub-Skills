---
date: 2026-05-05
tags:
  - security-review
  - code-review
  - code-scanning
  - static-analysis
  - best-practices
  - 安全与红队
source_skill: github-code-review, requesting-code-review
category: 安全与红队
---

# 安全代码审查

> 本文档整合 Git 协作审查和安全审查实践，覆盖预提交检查、静态分析、CodeQL 扫描和手动审查方法论。

## 概述

安全代码审查是将安全实践融入开发流程的关键环节。通过多层次审查流水线，在代码合入主分支前发现安全漏洞。

### 审查层次

| 层次 | 时机 | 工具/方法 | 目标 |
|------|------|----------|------|
| 预提交 | 开发阶段 | Pre-commit hooks | 防止 Secret 泄露 |
| 静态分析 | PR 阶段 | CodeQL, Semgrep | 发现漏洞模式 |
| 依赖扫描 | PR 阶段 | Dependabot | 发现已知 CVE |
| 人工审查 | PR 阶段 | Reviewers | 业务逻辑安全 |
| 动态测试 | 合并后 | OWASP ZAP | 运行时漏洞 |

---

## 1. 预提交安全检查

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: detect-private-key  # 检测私钥

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

### Gitleaks 扫描

```bash
# 安装
brew install gitleaks  # macOS
sudo apt-get install gitleaks  # Linux

# 扫描当前仓库
gitleaks detect --verbose

# 扫描特定 commit
gitleaks detect --source . --commits HEAD~5..HEAD

# 扫描历史（发现已泄露的 Secret）
gitleaks detect --no-git --source ./

# 生成基线文件
gitleaks detect --report-path gitleaks-report.json

# 自定义规则
cat > .gitleaks.toml << 'EOF'
title = "自定义规则"
[[rules]]
id = "my-custom-rule"
description = "检测公司内部 Secret 格式"
regex = '''MYAPP_SECRET_[A-Za-z0-9]{32}'''
tags = ["myapp", "secret"]
EOF
```

---

## 2. CodeQL 静态分析

### 启用 CodeQL

```bash
# 通过 API 启用
gh api repos/:owner/:repo/code-scanning/analysis \
  --method POST \
  --field ref='refs/heads/main' \
  --field commit_sha='<latest-sha>' \
  --field analysis_key='.github/codeql-analysis.yml'

# 查看 CodeQL 告警
gh api repos/:owner/:repo/code-scanning/alerts \
  --jq '.[] | "\(.rule.severity) | \(.rule.description)[:60] | \(.state)"'

# 查看告警详情
gh api repos/:owner/:repo/code-scanning/alerts/:alert_id
```

### CodeQL 工作流

```yaml
# .github/workflows/codeql.yml
name: "CodeQL"

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
  schedule:
    - cron: '0 0 * * 0'  # 每周日扫描

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ${{ (matrix.language == 'swift' && 'macos-latest') || 'ubuntu-latest' }}
    timeout-minutes: ${{ (matrix.language == 'swift' && 120) || 360 }}
    permissions:
      security-events: write
      packages: read
      actions: read
      contents: read

    strategy:
      fail-fast: false
      matrix:
        include:
          - language: python
            build-mode: none
          - language: javascript-typescript
            build-mode: none
          - language: java-kotlin
            build-mode: none

    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 初始化 CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
          build-mode: ${{ matrix.build-mode }}
          queries: security-and-quality

      - name: 自动构建
        uses: github/codeql-action/autobuild@v3

      - name: 执行分析
        uses: github/codeql-action/analyze@v3
        with:
          category: "/language:${{matrix.language}}"
```

### CodeQL 查询示例

```ql
# 检测 Python 命令注入
import python

from Call call, Name name
where call.getFunc() = name
  and name.getId() = "eval"
  and exists(call.getArg(0).(Str))
select call, "使用 eval() 处理字符串可能会导致代码注入"

# 检测硬编码密码
import python

from Assignment assignment, Constant constant
where constant.getValue().(string).length() > 8
  and exists(string s | s = constant.getValue() |
    s.matches("%assword%") or s.matches("%secret%"))
select assignment, "检测到可能的硬编码凭据"
```

---

## 3. 安全审查 Checklist

### 输入验证

- [ ] SQL/NoSQL 注入防护（参数化查询）
- [ ] XSS 防护（输出编码）
- [ ] 命令注入防护（避免 `os.system`, `subprocess(shell=True)`）
- [ ] 路径遍历防护（路径规范化）
- [ ] 文件上传验证（类型/大小检查）
- [ ] 反序列化保护（安全的序列化库）

### 认证与授权

- [ ] 密码强度要求（≥8位，混合字符）
- [ ] Session 管理和有效期
- [ ] API Token 安全存储
- [ ] 最小权限原则
- [ ] 速率限制（Rate Limiting）
- [ ] 禁止硬编码 Token

### 数据保护

- [ ] HTTPS 强制
- [ ] 敏感数据加密存储
- [ ] 日志中不记录敏感信息
- [ ] CORS 正确配置
- [ ] 数据脱敏处理

### 依赖安全

- [ ] 无已知 CVE 依赖
- [ ] 依赖锁定文件（`requirements.txt`, `package-lock.json`）
- [ ] SBOM 清单
- [ ] 最小依赖原则

---

## 4. Semgrep 规则

```yaml
# .semgrep/rules/python-security.yaml
rules:
  - id: avoid-hardcoded-passwords
    patterns:
      - pattern: password = "..."
      - pattern-either:
          - pattern-inside: |
              config = {...}
          - pattern-inside: |
              class $CONFIG:
                ...
    message: "⚠️ 发现硬编码密码"
    severity: ERROR
    languages: [python]

  - id: avoid-eval
    pattern: eval(...)
    message: "⚠️ 避免使用 eval()，可能导致代码注入"
    severity: ERROR
    languages: [python]
    metadata:
      cwe: "CWE-95"

  - id: avoid-sql-injection
    patterns:
      - pattern: |
          cursor.execute("$QUERY" % $VAR)
      - pattern-not: |
          cursor.execute("$QUERY", $PARAMS)
    message: "⚠️ 检测到 SQL 注入风险"
    severity: ERROR
    languages: [python]
```

---

## 5. 自动化审查流水线

```yaml
# .github/workflows/security-review.yml
name: Security Review Pipeline

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: 运行 Gitleaks
        uses: gitleaks/gitleaks-action@v2
        continue-on-error: true

      - name: 运行 Semgrep
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/default
            p/python
            p/javascript
            p/owasp-top-ten

      - name: 运行 Bandit (Python)
        run: |
          pip install bandit
          bandit -r . -f json -o bandit-report.json

      - name: 生成审查摘要
        run: |
          echo "## 🔒 安全审查结果" > $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| 工具 | 结果 |" >> $GITHUB_STEP_SUMMARY
          echo "|------|------|" >> $GITHUB_STEP_SUMMARY

      - name: 添加 PR 评论
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🔒 安全审查已完成`
            })
```

---

## 6. 人工审查重点

### 高优先级审查项

1. **认证相关变更** — Login/Logout/Session/Token
2. **支付和财务逻辑** — 金额、支付状态机
3. **权限提升** — Role/Admin/超级管理员
4. **数据导出** — 批量数据下载、用户隐私
5. **第三方集成** — OAuth、Webhook、API 调用
6. **文件操作** — 上传/下载/删除文件

### 审查响应标准

| 严重级别 | 响应时间 | 处理方式 |
|---------|---------|---------|
| 🔴 严重 | 立即阻止合并 | 必须修复 |
| 🟠 高危 | 24 小时内 | 需要修复 |
| 🟡 中危 | 3 天内 | 建议修复 |
| 🟢 低危 | 7 天内 | 可选修复 |

---

## 相关技能

- [[01-github-security]] — GitHub 安全配置
- [[03-godmode]] — 红队技术
- [[04-obliteratus]] — 模型安全与越狱
