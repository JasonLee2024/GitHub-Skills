---
date: 2026-05-05
tags:
  - github-security
  - security
  - authentication
  - secrets
  - best-practices
  - 安全与红队
source_skill: github-auth
category: 安全与红队
---

# GitHub 安全最佳实践

> 本文档基于 Hermes Agent 的 `github-auth` 技能和开源安全最佳实践整理，覆盖 GitHub 仓库和账号安全配置。

## 概述

GitHub 安全涵盖从**身份认证**到**代码保护**的多个层面。正确配置安全措施可以防止凭证泄露、代码窃取和供应链攻击。

### 安全层次

| 层次 | 措施 | 目标 |
|------|------|------|
| 账号安全 | 2FA、SSH Key、PAT | 防止账号被盗 |
| 仓库安全 | 分支保护、Secret 扫描 | 防止代码泄露 |
| 代码安全 | Dependabot、CodeQL | 防止漏洞引入 |
| 供应链安全 | SBOM、签名、SLSA | 防止依赖攻击 |

---

## 1. 账号安全

### 启用双因素认证（2FA）

```bash
# 检查账号 2FA 状态
gh api user --jq '{login, two_factor_authentication, has_2fa_enabled}'

# GitHub 支持以下 2FA 方式
# - TOTP（Google Authenticator / Authy）
# - 短信（不推荐）
# - WebAuthn（硬件安全密钥，推荐）
# - GitHub Mobile
```

### SSH 密钥管理

```bash
# 生成强 SSH 密钥（推荐 ed25519）
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/github -C "your@email.com"

# 添加到 SSH Agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github

# 上传到 GitHub
gh ssh-key add ~/.ssh/github.pub --title "工作笔记本"

# 配置 ~/.ssh/config
cat >> ~/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github
  IdentitiesOnly yes
EOF

# 验证连接
ssh -T git@github.com
# 输出: Hi username! You've successfully authenticated...
```

### Personal Access Token（PAT）

```bash
# 创建 PAT（经典）
gh auth token  # 查看当前 token

# 通过 API 创建（推荐 fine-grained）
gh api user/tokens \
  --method POST \
  --field note="Hermes Agent" \
  --field scopes='["repo","workflow","admin:org"]'

# 细粒度 PAT（推荐）
# 在 GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
# 优点：
# - 按仓库限制权限
# - 可设置过期时间（最长 1 年）
# - 安全审计更精确

# PAT 存储建议
# 1. 使用密码管理器（1Password, Bitwarden）
# 2. 环境变量（仅会话级别）
# 3. 不要硬编码在代码中
# 4. 不要在 CI 日志中泄露
```

---

## 2. 仓库安全

### Secret 扫描

GitHub 自动扫描仓库中的常见 Secrets（如 AWS Key、GitHub Token）：

```bash
# 检查 Secret 扫描告警
gh api repos/:owner/:repo/secret-scanning/alerts \
  --jq '.[] | "\(.secret_type) | \(.state) | \(.created_at) | \(.secret)"'

# 启用推送保护（阻止包含 Secret 的提交）
# 在仓库 Settings → Code security → Secret scanning → Push protection

# 自定义 Secret 扫描模式
# 在仓库根目录创建 .github/secret_scanning.yml
```

**禁止提交的文件类型**：

```bash
# 在 .gitignore 中添加
.env
*.key
*.pem
*password*
*secret*
*credential*
*.env.local
service-account*.json
```

### 分支保护规则

```bash
# 设置分支保护（通过 API）
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --input - << 'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["continuous-integration", "code-review"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON
```

**推荐的分支保护配置**：

| 设置 | 推荐 | 说明 |
|------|------|------|
| 需要 PR 审查 | ✅ | 至少 1 人 Approval |
| 驳回过期审查 | ✅ | 新提交后必须重新审查 |
| 要求状态检查 | ✅ | CI/CD 必须通过 |
| 线性历史 | ✅ | 禁止 Merge Commit |
| 禁止强制推送 | ✅ | 防止历史重写 |
| 要求代码所有者审查 | ✅ | 敏感文件需特定人审批 |

---

## 3. 依赖安全

### Dependabot 配置

```yaml
# .github/dependabot.yml
version: 2
updates:
  # Python 依赖
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "security"
    reviewers:
      - "team-security"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

  # Node.js 依赖
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-type: "direct"
    ignore:
      - dependency-name: "some-package"
        versions: [">=2.0.0"]

  # Docker
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "monthly"
```

### 检查已知漏洞

```bash
# 查看 Dependabot 告警
gh api repos/:owner/:repo/dependabot/alerts \
  --jq '.[] | "\(.security_advisory.severity) | \(.security_advisory.summary)[:50]"'

# 查看 CodeQL 告警
gh api repos/:owner/:repo/code-scanning/alerts \
  --jq '.[] | "\(.rule.severity) | \(.rule.description)[:50] | \(.state)"'

# 启用自动化安全修复
gh api repos/:owner/:repo/automated-security-fixes \
  --method PUT \
  --field enabled=true
```

---

## 4. Actions 安全

### 最小权限原则

```yaml
# Bad: 使用默认的 write-all 权限
permissions: write-all

# Good: 只授予必要权限
permissions:
  contents: read
  issues: write
  pull-requests: write

# 最佳实践：在 workflow 级别限制
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # 仅当需要 OIDC 时
    steps:
      - uses: actions/checkout@v4
```

### 使用 OIDC 替代 Static Secrets

```yaml
# 使用 OIDC 访问云资源（避免存储云凭证）
jobs:
  deploy:
    permissions:
      id-token: write
      contents: read
    steps:
      - name: 配置 AWS 凭证
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
      - name: 部署到 S3
        run: aws s3 sync ./dist s3://my-bucket
```

### Actions 安全最佳实践

1. **固定 Action 版本** — 使用 SHA 而非 tag
   ```yaml
   # 不安全
   - uses: actions/checkout@v4
   # 更安全
   - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
   ```
2. **避免 `pull_request_target`** — 除非了解安全含义
3. **限制环境变量** — 只在需要的步骤中暴露 Secret
4. **审查第三方 Action** — 尤其是社区版
5. **使用 `actions/attest`** — 验证 Action 来源

---

## 5. 安全审计

```bash
# 查看所有安全告警
gh api repos/:owner/:repo/security-advisories \
  --jq '.[] | "\(.severity) | \(.summary) | \(.state)"'

# 查看仓库的权限设置
gh api repos/:owner/:repo/collaborators \
  --jq '.[] | "\(.login) | \(.role_name)"'

# 检查外部协作成员
gh api repos/:owner/:repo/outside-collaborators \
  --jq '.[] | "\(.login) | \(.permissions)"'

# 导出安全日志
gh api orgs/:org/audit-log \
  --jq '.[] | select(.action | contains("repo"))' | head -20
```

---

## 6. 安全摘要清单

### 每日检查

- [ ] 查看 Dependabot 告警 → 及时更新
- [ ] 检查 Secret 扫描结果 → 处理泄露
- [ ] 查看 Actions 运行日志 → 确认无异常

### 每周检查

- [ ] 审查协作成员列表 → 移除无关人员
- [ ] 检查分支保护规则 → 确认未失效
- [ ] 检查开放安全 Issue → 及时处理

### 每月检查

- [ ] 轮换 PAT 和 Deploy Keys
- [ ] 审查 Actions 使用情况
- [ ] 运行安全审计
- [ ] 更新 `.gitignore` 和 `dependabot.yml`

---

## 相关技能

- [[02-security-code-review]] — 安全代码审查
- [[03-godmode]] — 红队技术
- [[04-obliteratus]] — 模型安全与越狱
