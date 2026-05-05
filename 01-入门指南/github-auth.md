---
date: 2026-05-05
tags:
  - github
  - authentication
  - ssh
  - tokens
  - gh-cli
  - 入门指南
source_skill: github-auth
category: 入门指南
---

# GitHub 认证指南

> 本文档基于 Hermes Agent 的 `github-auth` 技能整理，以"学习笔记"的形式记录 GitHub 三种认证方式的完整实操。

## 概述

操作 GitHub 仓库的第一步是搞定认证。没有认证，你无法 clone 私有仓库、无法 push 代码、也无法调用 GitHub API。GitHub 从 2021 年 8 月起移除了对密码认证的支持，现在有且仅有三种方式可以验证你的身份：

1. **HTTPS + Personal Access Token（个人访问令牌）**— 最通用，适合所有环境
2. **SSH Key** — 密钥对认证，适合长期开发和 CI/CD 机器
3. **gh CLI（GitHub 官方命令行工具）**— 一站式搞定认证 + API + 仓库操作

这三种方式**不是互斥的**，可以混用。我实际开发中最常见的组合是：SSH 用于日常 git 操作，gh CLI 用于 PR/Issue/CI 管理等 API 相关操作。

---

## 前置检测：看看你当前的状态

在配置之前，先跑一下这段脚本来摸清现状：

```bash
# 检查 git 和 gh 是否已安装
git --version
gh --version 2>/dev/null || echo "❌ gh 未安装"

# 检查是否已经认证过
gh auth status 2>/dev/null || echo "❌ gh 未认证"
git config --global credential.helper 2>/dev/null || echo "ℹ️  未配置 git 凭据管理器"
```

我的输出示例：

```
$ git --version
git version 2.43.0

$ gh --version
gh version 2.49.2 (2024-06-04)
https://github.com/cli/cli/releases/tag/v2.49.2

$ gh auth status
❌ gh 未认证
```

如果 `gh auth status` 返回了 `✓ Logged in` 开头的成功信息，那你可以跳过大部分步骤了。否则根据你的需求选择下面的方法。

---

## 方法一：HTTPS + Personal Access Token

**适用场景**：需要在任何机器上快速干活、不方便配置 SSH、或者在一个受限环境中（如某些公司内网）。

### 使用心得

Token 的好处是"用完即弃"——你可以给每个设备/工具生成不同的 Token，到期后单独吊销，不影响其他地方。相比 SSH，Token 在穿越防火墙和代理时更少出问题。

### Step 1：创建 Personal Access Token

浏览器访问：**https://github.com/settings/tokens**

```
操作路径:
  Settings → Developer settings → Personal access tokens → Tokens (classic)
  → Generate new token (classic)
```

填写表单：

| 字段 | 推荐值 | 说明 |
|------|--------|------|
| Note | `hermes-agent-laptop` | 命名规则建议：`工具名-设备名`，方便后续管理 |
| Expiration | 90 天 | 别选 "No expiration" —— 出于安全考虑 |
| Scopes | `repo`(全选), `workflow`, `read:org` | 最常用的三个范围 |

**关键 Scope 说明：**

- `repo` — 读取/写入私有仓库、创建 PR、push 代码（最核心）
- `workflow` — 触发和管理 GitHub Actions
- `read:org` — 读取组织仓库（如果有的话）
- `admin:repo_hook` — 管理 Webhook（只有需要时才勾选）

> ⚠️ **重要**：Token 只在创建时展示一次，复制后立即保存到安全的位置。如果弄丢了，只能删掉重新生成。

### Step 2：配置 Git 凭据存储

推荐使用 `store` 模式将 Token 持久化到磁盘：

```bash
git config --global credential.helper store
```

这个命令在 `~/.gitconfig` 中写入：

```
[credential]
    helper = store
```

Token 会被明文存储在 `~/.git-credentials` 文件中。如果你对安全有顾虑，可以用 `cache` 模式代替——Token 只保存在内存中，超时后自动遗忘：

```bash
# 缓存 8 小时（28800 秒）
git config --global credential.helper 'cache --timeout=28800'
```

### Step 3：触发认证并保存 Token

执行一个需要认证的 git 操作来触发凭据输入：

```bash
# 将 <your-username> 和 <any-repo> 替换为你的实际信息
git ls-remote https://github.com/<your-username>/<any-repo>.git
```

控制台会弹出提示：

```
Username for 'https://github.com': your-github-username
Password for 'https://github.com': ⚡ 粘贴 Token 而非 GitHub 密码
```

实际效果示例：

```bash
$ git ls-remote https://github.com/skywalker/hello-world.git
Username: skywalker
Password: [粘贴 Token，输入时不会回显]
# 成功后输出远程 ref 列表
f7d3a2b...	HEAD
f7d3a2b...	refs/heads/main
```

第一次输入后，凭证被保存到 `~/.git-credentials`。之后的任何 git 操作都不会再要求输入。

### 备选方案：将 Token 嵌入远程 URL

如果你不想配置 credential helper，也可以直接把 Token 嵌入到特定仓库的远程 URL 中（注意：Token 会在 `git remote -v` 中明文显示）：

```bash
git remote set-url origin https://<username>:<token>@github.com/<owner>/<repo>.git
```

这在脚本和自动化中很有用，但不推荐日常使用。

### Step 4：配置 Git 身份信息

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

这会写入 `~/.gitconfig`：

```
[user]
    name = Your Name
    email = your-email@example.com
```

> 注意：这个邮箱会出现在你的每一次 commit 中。如果你想要隐私，可以在 GitHub Settings 中开启 "Keep my email addresses private"，然后使用 `@users.noreply.github.com` 邮箱。

### 验证

```bash
# 测试远程访问
git ls-remote https://github.com/<your-username>/<any-repo>.git

# 验证 git 配置
git config --global user.name
git config --global user.email
```

---

## 方法二：SSH Key

**适用场景**：日常开发主力机器、CI/CD 服务器、长期使用同一台机器的场景。

SSH 的核心是**公钥/私钥对**：私钥留在你的机器上（像你的身份证），公钥上传到 GitHub（像你的照片贴在门禁系统上）。当我用 SSH 方式连接了几年后，最大的感受是——一旦配置好就再也不用管了，比 Token 优雅很多。

### Step 1：检查是否已有 SSH 密钥

```bash
ls -la ~/.ssh/id_*.pub 2>/dev/null || echo "❌ 未找到 SSH 公钥"
```

如果输出类似这样，说明你已经有了：

```
-rw-r--r-- 1 user user  565 Mar 12 10:00 ~/.ssh/id_ed25519.pub
```

### Step 2：生成新的 SSH 密钥

```bash
# 使用 Ed25519 算法（现代、安全、速度快）
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519 -N ""
```

命令参数说明：

| 参数 | 含义 |
|------|------|
| `-t ed25519` | 算法类型。Ed25519 比 RSA 更安全、密钥更小、验证更快 |
| `-C "email"` | 注释标签，用于标识这个密钥属于谁 |
| `-f ~/.ssh/id_ed25519` | 密钥文件路径 |
| `-N ""` | 空密码（免密码使用，方便日常开发） |

如果你用的是过时的 RSA 算法（2048/4096 位），强烈建议切换到 Ed25519。比较一下：

```
RSA 4096: 密钥文件 ~3.2KB，签名验证较慢
Ed25519:  密钥文件 ~400B，签名验证极快，且同等安全强度
```

如果你必须用 RSA（例如连接某些老旧服务器），可以用：

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

生成后，你的 `~/.ssh/` 目录下会有两个文件：

```
~/.ssh/id_ed25519      ← 私钥（永！远！不！要！给！别！人！）
~/.ssh/id_ed25519.pub  ← 公钥（可以安全地到处贴）
```

### Step 3：查看并上传公钥到 GitHub

```bash
cat ~/.ssh/id_ed25519.pub
```

输出示例：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk8G8x... your-email@example.com
```

复制整行内容（以 `ssh-ed25519` 或 `ssh-rsa` 开头的那一串），然后访问：

**https://github.com/settings/keys**

```
操作路径:
  Settings → SSH and GPG keys → New SSH key
  Title: 填入 "hermes-agent-laptop"（便于区分设备）
  Key:   粘贴刚才复制的公钥内容
```

### Step 4：测试 SSH 连接

```bash
ssh -T git@github.com
```

成功输出：

```
Hi skywalker! You've successfully authenticated, but GitHub does not provide shell access.
```

如果遇到连接超时：

```bash
ssh -vT git@github.com
```

打开详细日志模式，查看在哪一步卡住。常见原因是公司防火墙屏蔽了 22 端口（见故障排查部分）。

### Step 5：配置 Git 自动使用 SSH

让 git 自动将 HTTPS 的 GitHub URL 重写为 SSH 方式：

```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

这样即使你 `git clone https://github.com/...`，git 也会自动转成 SSH 协议连接。这行配置会写入 `~/.gitconfig`：

```
[url "git@github.com:"]
    insteadOf = https://github.com/
```

### Step 6：验证完整工作流

```bash
# clone 一个仓库试试
git clone git@github.com:<your-username>/<any-repo>.git
cd <any-repo>
echo "# SSH test" >> README.md
git add .
git commit -m "test: SSH auth working"
git push
# 应该不会提示输入密码
```

---

## 方法三：gh CLI

**适用场景**：需要调用 GitHub API 进行 PR/Issue/CI 管理、或者想用最简便的方式一次性搞定认证。

gh CLI 是 GitHub 的官方命令行工具，集成了认证、API 调用、仓库管理等功能。对我而言，gh CLI 最大的价值在于它**整合了 git 认证和 API 认证**——一次认证，两边都通。

### 安装 gh

根据不同平台安装：

```bash
# macOS（Homebrew）
brew install gh

# Ubuntu/Debian（官方仓库）
(type -p curl >/dev/null || sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh -y

# Windows（winget）
winget install --id GitHub.cli

# WSL（我推荐用 Ubuntu 方式）
# 如果没 sudo 权限，可以去 GitHub Releases 下载 .deb 或 .tar.gz 手动安装
```

### 交互式浏览器登录（桌面环境）

```bash
gh auth login
```

交互式引导的完整流程：

```
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations? HTTPS
? Authenticate Git with your GitHub credentials? Yes
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: ABCD-1234
Press Enter to open github.com in your browser...
```

1. 复制显示的 `ABCD-1234` 格式的一次性代码
2. 按回车自动打开浏览器
3. 在浏览器中确认授权
4. 回到终端，认证完成

验证：

```bash
$ gh auth status
✓ Logged in to github.com as skywalker (keyring)
✓ Git operations for github.com configured to use HTTPS protocol.
✓ Authentication token is stored securely.
```

### Token 式登录（无头模式 / SSH 服务器）

如果你在远程服务器上工作（没有浏览器），用事先创建好的 Token：

```bash
# 方式 1：通过管道传入
echo "ghp_xxxxxxxxxxxxxxxxxxxx" | gh auth login --with-token

# 方式 2：从环境变量读取
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
echo "$GITHUB_TOKEN" | gh auth login --with-token
```

登录后，配置 gh 接管 git 认证：

```bash
gh auth setup-git
```

这个命令会配置 git 使用 gh 的 OAuth 凭证来操作 HTTPS 远程 URL，等价于自动配置了 credential helper。

### 使用环境变量实现免配置认证

在 CI/CD 或无交互的环境中，最简单的方式是通过环境变量：

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
gh repo list --limit 5  # 会自动读取 GITHUB_TOKEN
```

> 注意：`gh` 会优先读取 `GITHUB_TOKEN` 或 `GH_TOKEN` 环境变量。如果同时设置了 Token 环境变量又通过 `gh auth login` 登录了，环境变量优先级更高。

### 查看当前认证状态

```bash
gh auth status                    # 详细状态
gh auth status --show-token       # 显示 Token（前几位）
gh api /user                      # 测试 API 调用
```

---

## 从 Git 凭据中提取 Token（脚本自动化）

在自动化脚本中，如果你已经用 `credential.helper store` 存了 Token，可以用这种方法提取：

```bash
# 从 ~/.git-credentials 中提取 Token
grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | \
  sed 's|https://[^:]*:\([^@]*\)@.*|\1|'
```

更好的做法是加上一个通用的"认证检测"逻辑，放在脚本开头：

```bash
# 通用 GitHub 认证检测 —— 多种回退策略
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "AUTH_METHOD=gh"
elif [ -n "$GITHUB_TOKEN" ]; then
  echo "AUTH_METHOD=curl"  # 环境变量优先
elif [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
  export GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
  echo "AUTH_METHOD=curl"
elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
  export GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials | head -1 | \
    sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
  echo "AUTH_METHOD=curl"
else
  echo "AUTH_METHOD=none"
  echo "❌ 需要先配置 GitHub 认证！"
fi
```

---

## 使用 GitHub API 无需 gh

当 `gh` 不可用时，可以直接用 `curl` 调用 GitHub REST API。只需要设置好 `GITHUB_TOKEN` 环境变量：

```bash
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"

# 查看当前用户信息
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user | python3 -m json.tool
```

输出示例：

```json
{
  "login": "skywalker",
  "id": 1234567,
  "name": "Sky Walker",
  "public_repos": 42,
  "followers": 100
}
```

---

## 多 GitHub 账号管理

如果你有多个 GitHub 账号（比如个人账号 + 公司账号），需要特别配置才能共存。

### SSH 方式（推荐）

在 `~/.ssh/config` 中配置不同主机别名：

```
# 个人账号
Host github.com-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

# 公司账号
Host github.com-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

然后在每个仓库中指定对应的远程 URL：

```bash
git remote set-url origin git@github.com-personal:<username>/repo.git
```

### HTTPS 方式

每个仓库使用不同的远程 URL，里面嵌入不同的 Token：

```bash
# 个人仓库
git remote set-url origin https://personal-token@github.com/personal/repo.git

# 公司仓库
git remote set-url origin https://work-token@github.com/work/repo.git
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| `git push` 总是提示输入密码 | GitHub 已废弃密码认证 | 使用 Personal Access Token 代替密码 |
| `remote: Permission to user/repo denied` | Token 缺少 `repo` 范围 | 去 GitHub Settings → Tokens 重新生成，勾选 `repo` |
| `fatal: Authentication failed` | 缓存的凭据过期或失效 | `git credential reject` 清除缓存，重新认证 |
| `ssh: connect to host github.com port 22: Connection refused` | 公司防火墙拦截 22 端口 | 改用 SSH over HTTPS（见下文） |
| 凭据不持久化 | `credential.helper` 未正确配置 | 检查 `git config --global credential.helper` 是否为 `store` |
| `gh: command not found` | gh 未安装且无 sudo 权限 | 用方法一（HTTPS + Token）无需安装任何额外工具 |
| Token 泄露了 | 不小心把 Token commit 了 | 立即去 Settings 吊销该 Token，然后使用环境变量或 `.env` 文件管理 |

### SSH 端口被墙的解决方案

某些网络环境（如公司内网、公共 Wi-Fi）会封锁 22 端口。此时可以配置 SSH 通过 HTTPS 端口（443）连接：

在 `~/.ssh/config` 中添加：

```
Host github.com
  HostName ssh.github.com
  Port 443
  User git
```

或一行命令搞定：

```bash
echo -e "Host github.com\n  HostName ssh.github.com\n  Port 443\n  User git" >> ~/.ssh/config
```

测试：

```bash
ssh -T git@github.com
# 预期输出：Hi username! You've successfully authenticated...
```

### 凭据消失的急救

如果 git 突然要求重新认证：

```bash
# 检查 .git-credentials 是否存在
cat ~/.git-credentials

# 如果不存在了，重新配置
git config --global credential.helper store

# 触发一次认证操作即可重新保存
git ls-remote https://github.com/<username>/<repo>.git
```

---

## 认证方式对比总结

| 维度 | HTTPS + Token | SSH Key | gh CLI |
|------|--------------|---------|--------|
| **上手难度** | ⭐⭐ 中等 | ⭐⭐⭐ 略高 | ⭐ 最简单 |
| **初始配置步骤** | 4 步 | 6 步 | 2~3 步 |
| **持久化** | `store` 存在磁盘 / `cache` 存在内存 | 无密码密钥永久有效 | 存在系统密钥环 |
| **跨设备管理** | 每个设备独立 Token，可单独吊销 | 每台机器独立密钥，需逐个添加公钥 | 每台机器独立登录 |
| **防火墙友好度** | ✅ 极好（443 端口） | ⚠️ 可能被墙（22 端口） | ✅ 极好 |
| **API 调用** | 需配合 curl | ❌ 不支持 | ✅ 原生支持 |
| **CI/CD 兼容** | ✅ Token 作为 Secret 传入 | ⚠️ 需要加载私钥，操作较复杂 | ✅ 但 CI 中通常直接用 Token |
| **我的推荐** | 脚本/CI/CD 首选 | 日常开发首选 | 管理任务首选 |

**我的个人推荐组合：**

```
日常开发：  SSH Key（git 操作）+ gh CLI（管理操作）
服务器/CI： HTTPS + Token（环境变量）
临时环境：  gh auth login --with-token（又快又干净）
```

---

## 相关链接

- [[github-repo-management]] — 仓库管理（克隆、创建、Fork、配置、Release）
- [[02-GitHub-核心操作/github-pr-workflow]] — PR 工作流
- [[02-GitHub-核心操作/github-code-review]] — 代码审查
- [[02-GitHub-核心操作/github-issues]] — Issue 管理
- [[99-附录与速查/GitHub-CLI-命令大全]] — gh 命令速查表
- [[99-附录与速查/GitHub-REST-API-速查]] — API 端点速查
