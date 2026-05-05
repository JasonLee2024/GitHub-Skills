---
date: 2026-05-05
tags:
  - github
  - repositories
  - git
  - releases
  - secrets
  - actions
  - 入门指南
source_skill: github-repo-management
category: 入门指南
---

# GitHub 仓库管理指南

> 本文档基于 Hermes Agent 的 `github-repo-management` 技能整理，覆盖仓库从创建到发布的全生命周期管理。

## 概述

仓库（Repository）是 GitHub 上最基本的组织单元——一切代码、Issue、PR、Action 都围绕仓库展开。本章涵盖你日常最常用的仓库操作：克隆、创建、Fork、配置、管理 Secrets、发布 Release、操作 Workflow。

每个操作我同时提供了两种方式：**`gh` CLI（推荐，命令更简洁）** 和 **`git` + `curl`（无 gh 时的回退方案）**。先走 `gh`，没有再用纯 `git` + API。

---

## 前置准备

所有操作的前提是已经完成 GitHub 认证。建议在脚本开头先设置好认证检测：

```bash
# === 通用认证检测 ===
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
  echo "✅ 使用 gh CLI"
else
  AUTH="git"
  echo "ℹ️  gh 不可用，使用 git + curl"
  # 从多个来源尝试获取 Token
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2)
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

# === 获取当前 GitHub 用户名 ===
if [ "$AUTH" = "gh" ]; then
  GH_USER=$(gh api user --jq '.login')
else
  GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/user | python3 -c \
    "import sys,json; print(json.load(sys.stdin)['login'])")
fi
echo "👤 当前用户: $GH_USER"
```

如果有时你已经在一个本地仓库里操作，还需要提取它的 `owner` 和 `repo` 名称：

```bash
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
echo "📦 当前仓库: $OWNER/$REPO"
```

---

## 1. 克隆仓库

克隆是最基本的操作。核心是 `git clone`，`gh` 只是提供一个简写。

### HTTPS 克隆（最通用）

```bash
# 标准克隆
git clone https://github.com/owner/repo-name.git

# 克隆到自定义目录
git clone https://github.com/owner/repo-name.git ./my-local-dir

# 浅克隆（只克隆最新一次 commit，适合大仓库）
git clone --depth 1 https://github.com/owner/repo-name.git

# 克隆指定分支
git clone --branch develop https://github.com/owner/repo-name.git
```

### SSH 克隆

```bash
git clone git@github.com:owner/repo-name.git
```

### gh 简写方式

```bash
# 简写，等效于 git clone
gh repo clone owner/repo-name

# 带 git 选项（-- 后面的参数会透传给 git）
gh repo clone owner/repo-name -- --depth 1
```

**实际经验**：我一般用原始 `git clone` 而不是 `gh repo clone`，因为 `git clone` 的命令行选项更熟悉，而且在不支持 gh 的环境（如纯 Docker 容器）中也能用。

---

## 2. 创建仓库

### 用 gh CLI 创建

```bash
# 创建公开仓库并克隆到本地
gh repo create my-new-project --public --clone

# 创建私有仓库，带描述和许可证
gh repo create my-new-project --private \
  --description "A useful automation tool" \
  --license MIT --clone

# 在组织下创建
gh repo create my-org/my-new-project --public --clone

# 从已有本地目录初始化并推送
cd /path/to/local/project
gh repo create my-project --source . --public --push
```

`--push` 参数很实用——它会自动在你的本地仓库添加 origin 并 push。省去了手动 `git remote add origin && git push -u origin main` 的步骤。

### 用 git + curl 创建

当 gh 不可用时，通过 REST API 创建：

```bash
# 创建远程仓库
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user/repos \
  -d '{
    "name": "my-new-project",
    "description": "A useful tool",
    "private": false,
    "auto_init": true,
    "license_template": "mit"
  }'

# 克隆到本地
git clone https://github.com/$GH_USER/my-new-project.git
cd my-new-project
```

如果是从已有本地项目创建：

```bash
cd /path/to/existing/project
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/$GH_USER/my-new-project.git
git push -u origin main
```

### 从模板创建

模板仓库是 GitHub 的一个极其实用的特性——你可以把项目骨架做成模板，然后一键生成新项目。

```bash
# gh 方式
gh repo create my-new-app --template owner/template-repo --public --clone

# curl 方式
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/template-repo/generate \
  -d '{"owner": "'"$GH_USER"'", "name": "my-new-app", "private": false}'
```

**模板仓库的好处**：它会完整复制目录结构、文件内容、甚至 GitHub 设置（如 Issue 模板、Label 配置），比手动复制粘贴省了 100% 的重复劳动。

---

## 3. Fork 仓库

Fork 是 GitHub 协作的基石——你先 Fork 别人的仓库到自己的账号下，修改后再提交 Pull Request。

```bash
# gh 方式（创建 Fork 并克隆到本地）
gh repo fork owner/repo-name --clone
```

### curl 方式（分两步做）

```bash
# Step 1: 通过 API 创建 Fork
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/owner/repo-name/forks

# 稍等几秒让 GitHub 处理
sleep 3

# Step 2: 克隆你自己的 Fork
git clone https://github.com/$GH_USER/repo-name.git
cd repo-name

# 添加上游仓库（原始仓库）作为远程
git remote add upstream https://github.com/owner/repo-name.git
```

### 保持 Fork 同步

这是 Fork 工作流中最高频的操作——把上游仓库的最新变更合并到你的 Fork 中。

```bash
# 方法 1：纯 git（适用所有环境）
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# 方法 2：gh 快捷方式
gh repo sync $GH_USER/repo-name
```

**实际经验**：`gh repo sync` 很方便但会直接 force push，如果你的 Fork 有未合并的本地提交会被覆盖。我用 `git fetch + merge` 的方式更多，控制权更大。

---

## 4. 查看仓库信息

```bash
# gh 方式
gh repo view owner/repo-name              # 查看仓库详情
gh repo list --limit 20                    # 列出我的仓库
gh search repos "machine learning" \
  --language python --sort stars           # 搜索仓库
```

`gh repo view` 的输出示例：

```
  open-mmlab/mmsegmentation
  OpenMMLab Semantic Segmentation Toolbox and Benchmark.
  - GitHub Action CI build passing
  - Updated 2 days ago
  - Python 44.7k ★
```

### 命令行下获取仓库信息的利器

```bash
# 用 API 获取 JSON 格式的仓库详情
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO | python3 -c "
import sys, json
r = json.load(sys.stdin)
print(f'名称:        {r[\"full_name\"]}')
print(f'描述:        {r[\"description\"]}')
print(f'★ 星数:      {r[\"stargazers_count\"]}  Fork: {r[\"forks_count\"]}')
print(f'默认分支:    {r[\"default_branch\"]}')
print(f'语言:        {r[\"language\"]}')
print(f'许可证:      {r[\"license\"][\"spdx_id\"] if r.get(\"license\") else \"无\"}')
print(f'创建时间:    {r[\"created_at\"]}')
print(f'最后更新:    {r[\"updated_at\"]}')
"
```

输出示例：

```
名称:        skywalker/my-awesome-tool
描述:        一个超好用的自动化工具
★ 星数:      42  Fork: 3
默认分支:    main
语言:        Python
许可证:      MIT
创建时间:    2026-01-15T10:30:00Z
最后更新:    2026-05-04T08:12:00Z
```

### 列出自己的仓库

```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=50&sort=updated" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    vis = '🔒 私有' if r['private'] else '🌐 公开'
    print(f'  {r[\"full_name\"]:45}  {vis:8}  {r.get(\"language\", \"\"):10}  ★{r[\"stargazers_count\"]}')
"
```

### 搜索仓库

```bash
curl -s \
  "https://api.github.com/search/repositories?q=machine+learning+language:python&sort=stars&per_page=10" \
  | python3 -c "
import sys, json
for i, r in enumerate(json.load(sys.stdin)['items'], 1):
    desc = (r['description'] or '')[:60]
    print(f'  {i:2}. {r[\"full_name\"]:40}  ★{r[\"stargazers_count\"]:6}  {desc}')
"
```

---

## 5. 修改仓库设置

创建仓库后，经常需要调整配置——修改描述、切换可见性、开启/关闭 Wiki、设置话题标签等。

### gh 方式

```bash
# 修改描述和可见性
gh repo edit --description "Updated description" --visibility public

# 开关功能
gh repo edit --enable-wiki=false --enable-issues=true

# 修改默认分支
gh repo edit --default-branch main

# 添加话题标签
gh repo edit --add-topic "machine-learning,python,automation"

# 开启自动合并
gh repo edit --enable-auto-merge
```

### curl 方式

```bash
# PATCH 请求修改仓库配置
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO \
  -d '{
    "description": "Updated description",
    "has_wiki": false,
    "has_issues": true,
    "allow_auto_merge": true
  }'

# 更新话题标签（注意需要特殊的 Accept header）
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.mercy-preview+json" \
  https://api.github.com/repos/$OWNER/$REPO/topics \
  -d '{"names": ["machine-learning", "python", "automation"]}'
```

### 常用设置项对照表

| 配置项 | API 字段 | gh 参数 | 说明 |
|--------|---------|---------|------|
| 仓库描述 | `description` | `--description` | 显示在仓库顶部 |
| 可见性 | `private` | `--visibility` | `public` / `private` / `internal` |
| 启用 Wiki | `has_wiki` | `--enable-wiki` | 默认 true |
| 启用 Issue | `has_issues` | `--enable-issues` | 默认 true |
| 默认分支 | `default_branch` | `--default-branch` | 改完后记得更新本地 |
| 是否允许自动合并 | `allow_auto_merge` | `--enable-auto-merge` | PR 自动合并 |
| 话题标签 | `topics` | `--add-topic` | 用于搜索分类 |

---

## 6. 分支保护（Branch Protection）

保护重要分支（通常是 `main`）不被直接 push、要求 PR 审查通过才能合并，是团队协作的基石。

```bash
# 查看当前保护规则
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  | python3 -m json.tool

# 设置保护规则（需 gh 或者 API）
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci/test", "ci/lint"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": {
      "required_approving_review_count": 1
    },
    "restrictions": null
  }'
```

保护参数说明：

| 参数 | 含义 | 我的建议 |
|------|------|---------|
| `required_status_checks.strict` | 强制分支与最新 base 保持同步 | `true`（避免合并时产生冲突） |
| `required_status_checks.contexts` | 需要哪些 CI 检查通过 | 至少包括你的关键 workflow job |
| `enforce_admins` | 管理员是否也受保护 | 个人项目设 `false`，团队项目设 `true` |
| `required_pull_request_reviews.required_approving_review_count` | 需要几次审查通过 | 团队 1~2 人，个人项目 0 |
| `restrictions` | 限制谁可以 push | `null` = 所有人（有写权限），或指定 team |

> **注意**：`gh` 目前没有直接设置分支保护的原生命令，所以即使是推荐用 gh 的场景，分支保护也需要通过 API 来完成。

---

## 7. Secrets 管理（GitHub Actions）

Secrets 是给 GitHub Actions 工作流使用的敏感信息——API Key、SSH 私钥、云服务凭证等。它们被加密存储在 GitHub 上，Actions 运行时自动注入到环境变量中。

### gh 方式（强烈推荐）

```bash
# 设置一个简单的 secret
gh secret set API_KEY --body "sk-xxxxxxxxxxxxxxxx"

# 从文件读取 secret 内容
gh secret set SSH_KEY < ~/.ssh/id_rsa

# 列出所有 secrets（只会显示名称，不会显示值）
gh secret list

# 删除 secret
gh secret delete API_KEY
```

`gh secret list` 输出示例：

```
NAME          UPDATED
API_KEY       2026-05-05 10:30:00 +0000 UTC
SSH_KEY       2026-05-04 15:20:00 +0000 UTC
DOCKER_TOKEN  2026-04-28 09:00:00 +0000 UTC
```

### curl 方式（API 方式，较复杂）

Secrets 的 API 设置需要先获取仓库的公钥，然后用公钥加密 secret 值，最后把加密后的值上传。这个过程比 `gh` 麻烦得多：

```bash
# Step 1: 获取仓库公钥
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/secrets/public-key

# Step 2: 用 Python + PyNaCl 加密
python3 -c "
from base64 import b64encode
from nacl import encoding, public
import json

key_id = '<key_id_from_step_1>'
public_key = '<base64_key_from_step_1>'

# 要加密的 secret 值
secret_value = 'your-secret-value'

# 使用公钥加密
sealed = public.SealedBox(
    public.PublicKey(public_key.encode('utf-8'), encoding.Base64Encoder)
).encrypt(secret_value.encode('utf-8'))

print(json.dumps({
    'encrypted_value': b64encode(sealed).decode('utf-8'),
    'key_id': key_id
}))
"

# Step 3: PUT 加密后的值
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/secrets/API_KEY \
  -d '<从 Step 2 得到的结果>'
```

**实际经验**：对于 Secrets 操作，`gh secret set` 比 API 方式简单太多了。你只需要记住一点——如果当前环境没有 gh，但又需要设置 Secrets，建议先装 gh 只做这一个操作。不装 gh 的话得装 `libsodium` / `PyNaCl` 依赖，反而更复杂。

---

## 8. Release 发布

Release 是给代码打上版本标签并附上发行说明的功能，通常配合二进制文件、变更日志一起发布。

### gh 方式

```bash
# 最简单的 Release（自动生成 Release Note）
gh release create v1.0.0 --title "v1.0.0" --generate-notes

# 预发布（用于 RC / Beta）
gh release create v2.0.0-rc1 --draft --prerelease --generate-notes

# 附带二进制文件的 Release
gh release create v1.0.0 ./dist/binary --title "v1.0.0" \
  --notes "## 变更\n- 新增 Feature A\n- 修复 Bug B"

# 查看所有 Release
gh release list

# 下载某个 Release 的资产
gh release download v1.0.0 --dir ./downloads
```

`--generate-notes` 非常实用——它会自动收集自上次 Release 以来的所有 commit 和 merged PR，生成一份格式标准的 Release Note。

### curl 方式

```bash
# 创建 Release
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/releases \
  -d '{
    "tag_name": "v1.0.0",
    "name": "v1.0.0",
    "body": "## 变更日志\n- Feature A\n- Bug fix B",
    "draft": false,
    "prerelease": false,
    "generate_release_notes": true
  }'

# 列出所有 Release
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/releases \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin):
    tag = r.get('tag_name', 'no tag')
    name = r['name'] or '(无标题)'
    status = '📄 草稿' if r['draft'] else '✅ 已发布'
    print(f'  {tag:18}  {name:30}  {status}')
"

# 上传 Release 资产（二进制文件）
RELEASE_ID=<从创建返回的 id>
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  "https://uploads.github.com/repos/$OWNER/$REPO/releases/$RELEASE_ID/assets?name=binary-amd64" \
  --data-binary @./dist/binary-amd64
```

输出的 Release 列表：

```
  v1.0.0              v1.0.0                         ✅ 已发布
  v2.0.0-rc1          v2.0.0 Release Candidate 1     📄 草稿
```

---

## 9. GitHub Actions Workflow 管理

创建仓库后，管理和调试 CI/CD 工作流是日常高频操作。

### 查看 Workflow

```bash
# gh 方式
gh workflow list                     # 列出所有 workflow
gh run list --limit 10               # 最近 10 次运行
gh run view <RUN_ID>                 # 查看某个运行的详情
gh run view <RUN_ID> --log-failed    # 只看失败的日志

# curl 方式
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/workflows \
  | python3 -c "
import sys, json
for w in json.load(sys.stdin)['workflows']:
    state = w['state']
    icon = '✅' if state == 'active' else '❌'
    print(f'  {icon}  {w[\"id\"]:8}  {w[\"name\"]:30}  {state}')
"
```

`gh workflow list` 输出示例：

```
*  CI                 active    ci.yml
*  Deploy             active    deploy.yml
*  Lint Check         active    lint.yml
```

### 查看 Workflow Run 日志

```bash
# 列出最近的运行
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?per_page=10" \
  | python3 -c "
import sys, json
for r in json.load(sys.stdin)['workflow_runs']:
    conclusion = r['conclusion'] or r['status']
    icon = {
        'success': '✅', 'failure': '❌', 'cancelled': '🚫',
        'in_progress': '⏳', 'skipped': '⏭️'
    }.get(conclusion, '❓')
    print(f'  {icon}  Run #{r[\"run_number\"]:5}  {r[\"name\"]:30}  {conclusion}')
"

# 下载指定运行的日志
RUN_ID=<run_id>
curl -s -L -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/logs \
  -o /tmp/ci-logs.zip
cd /tmp && unzip -o ci-logs.zip -d ci-logs
ls ci-logs/
```

### 重新运行失败的 Workflow

```bash
# gh 方式
gh run rerun <RUN_ID>              # 重新运行整个 workflow
gh run rerun <RUN_ID> --failed     # 只重新运行失败的 job

# curl 方式
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/rerun

# 只重试失败的 Job
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/rerun-failed-jobs
```

### 手动触发 Workflow

如果一个 workflow 定义了 `workflow_dispatch` 事件触发器（可以手动触发），你可以用它来按需运行：

```bash
# gh 方式
gh workflow run ci.yml --ref main
gh workflow run deploy.yml -f environment=staging  # 带输入参数

# curl 方式
WORKFLOW_ID=ci.yml
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/dispatches \
  -d '{"ref": "main", "inputs": {"environment": "staging"}}'
```

---

## 10. Gist（代码片段）

Gist 是 GitHub 的轻量级代码片段服务，适合分享单文件或小型代码集合。

```bash
# gh 方式
gh gist create script.py --public --desc "Useful script"
gh gist list

# curl 方式
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/gists \
  -d '{
    "description": "Useful script",
    "public": true,
    "files": {
      "script.py": {"content": "print(\"hello world\")"}
    }
  }'

# 列出你的所有 Gist
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/gists \
  | python3 -c "
import sys, json
for g in json.load(sys.stdin):
    files = ', '.join(g['files'].keys())
    desc = g['description'] or '(无描述)'
    print(f'  {g[\"id\"]:20}  {desc:40}  {files}')
"
```

---

## 快速参考表

| 操作 | `gh` 命令 | `git` + `curl` 方式 |
|------|-----------|-------------------|
| 克隆 | `gh repo clone owner/repo` | `git clone https://github.com/owner/repo.git` |
| 创建仓库 | `gh repo create name --public` | `curl POST /user/repos` |
| Fork | `gh repo fork owner/repo --clone` | `curl POST /repos/owner/repo/forks` + `git clone` |
| 查看仓库信息 | `gh repo view owner/repo` | `curl GET /repos/owner/repo` |
| 修改设置 | `gh repo edit --...` | `curl PATCH /repos/owner/repo` |
| 创建 Release | `gh release create v1.0` | `curl POST /repos/owner/repo/releases` |
| 列出 Workflow | `gh workflow list` | `curl GET /repos/owner/repo/actions/workflows` |
| 重新运行 CI | `gh run rerun ID` | `curl POST /repos/owner/repo/actions/runs/ID/rerun` |
| 设置 Secret | `gh secret set KEY` | `curl PUT /repos/owner/repo/actions/secrets/KEY` (+ 加密) |
| 搜索仓库 | `gh search repos "query"` | `curl GET /search/repositories?q=query` |
| Gist 创建 | `gh gist create file` | `curl POST /gists` |

---

## 日常开发最佳实践

经过长期实践，我总结了一套高效的仓库管理日常流程：

```bash
# 1️⃣ 早上同步所有 Fork
cd ~/projects/some-fork
git fetch upstream
git checkout main
git merge upstream/main
git push origin main

# 2️⃣ 创建新功能分支
git checkout -b feature/awesome-feature

# 3️⃣ 开发完成后创建 PR
gh pr create --title "feat: 添加超赞功能" \
  --body "实现了 XXX 功能，解决了 YYY 问题" \
  --reviewer colleague

# 4️⃣ CI 检查失败时查看日志
gh run list --limit 3
gh run view --log-failed

# 5️⃣ 发布新版
gh release create v1.1.0 --title "v1.1.0" --generate-notes

# 6️⃣ 上传构建产物
gh release upload v1.1.0 ./dist/app-linux-amd64
```

---

## 相关链接

- [[github-auth]] — GitHub 认证指南（前置条件）
- [[02-GitHub-核心操作/github-pr-workflow]] — PR 工作流
- [[02-GitHub-核心操作/github-code-review]] — 代码审查实战
- [[02-GitHub-核心操作/github-issues]] — Issue 管理
- [[04-自动化与CI-CD/github-actions]] — GitHub Actions 基础
- [[04-自动化与CI-CD/github-pages-setup]] — GitHub Pages 部署
- [[04-自动化与CI-CD/webhook-subscriptions]] — Webhook 订阅管理
- [[99-附录与速查/GitHub-CLI-命令大全]] — gh 命令速查表
- [[99-附录与速查/GitHub-REST-API-速查]] — API 端点速查
