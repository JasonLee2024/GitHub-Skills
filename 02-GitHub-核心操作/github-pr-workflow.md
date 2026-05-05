---
date: 2026-05-05
tags:
  - github
  - pull-request
  - workflow
  - git
  - ci-cd
  - merge
  - GitHub核心操作
source_skill: github-pr-workflow
category: GitHub 核心操作
---

# Pull Request 全生命周期工作流

> 本文档基于 Hermes Agent 的 `github-pr-workflow` 技能整理，记录从分支创建到 PR 合并的完整实操流程。

## 概述

Pull Request（PR）是 GitHub 协作开发的核心机制。它不是 Git 的原生概念（Git 本身只有分支和合并），而是 GitHub 在 Git 之上构建的"代码审查 + 协作"层。一个完整的 PR 工作流包括：创建分支 → 提交代码 → 推送 → 创建 PR → CI 检查 → Code Review → 合并 → 清理。

本文档覆盖两种模式：
- **gh CLI 模式** — 有 `gh` 命令时的最简方式
- **git + curl 模式** — 纯 Git 环境也能完成全部操作

## 前置检查

```bash
# 检测当前认证方式
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
  echo "使用 gh CLI 模式"
else
  AUTH="git"
  echo "使用 git + curl 模式"
  # 从 git 凭据或环境变量获取 Token
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    elif grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi

# 获取仓库 owner/repo
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
echo "仓库: $OWNER/$REPO"
```

---

## 一、分支创建

这是纯 `git` 操作，不依赖任何 GitHub API。

```bash
# 确保从最新的主分支开始
git fetch origin
git checkout main && git pull origin main

# 创建功能分支（分支名即文档）
git checkout -b feat/user-authentication
```

### 分支命名规范

| 前缀 | 用途 | 示例 |
|------|------|------|
| `feat/` | 新功能 | `feat/login-page` |
| `fix/` | 缺陷修复 | `fix/login-redirect` |
| `refactor/` | 代码重构 | `refactor/auth-middleware` |
| `docs/` | 文档更新 | `docs/api-readme` |
| `test/` | 测试补充 | `test/auth-flow` |
| `ci/` | CI/CD 变更 | `ci/docker-build` |
| `chore/` | 杂项 | `chore/deps-update` |

实际项目中，分支命名越清晰越好——团队成员看一眼分支名就知道改动范围。

---

## 二、提交代码

用 `write_file`、`patch` 等工具修改文件后，用 git 提交：

```bash
# 添加特定文件（不要一股脑 git add .）
git add src/auth/login.py src/models/user.py tests/test_auth.py

# 使用 Conventional Commits 格式
git commit -m "feat: 添加 JWT 用户认证

- 新增登录/注册 API 端点
- 添加 User 模型及密码哈希
- 添加认证中间件保护路由
- 添加认证流程单元测试"
```

### Conventional Commits 格式

```
类型(范围): 简短描述（不超过72字符）

详细说明（如果有）。空行分隔。
```

**常用类型：**
- `feat` — 新功能
- `fix` — 缺陷修复
- `refactor` — 重构
- `docs` — 文档
- `test` — 测试
- `ci` — CI/CD
- `chore` — 杂项（依赖更新、构建配置等）
- `perf` — 性能优化
- `style` — 代码格式（不影响逻辑）

> **经验之谈：** Conventional Commits 的最大好处是**自动生成 CHANGELOG**。`feat` 和 `fix` 会自动进入 changelog 的 Features 和 Bug Fixes 部分，其他类型被忽略。

---

## 三、推送并创建 PR

### 推送分支

```bash
git push -u origin HEAD
```

### 创建 PR（gh CLI 模式）

```bash
gh pr create \
  --title "feat: 添加 JWT 用户认证" \
  --body "## 变更摘要

- 新增登录和注册 API 端点
- JWT Token 生成与验证
- 密码 bcrypt 哈希存储

## 测试计划

- [x] 单元测试通过
- [ ] E2E 测试验证

Closes #42" \
  --label "enhancement" \
  --reviewer teammate1,teammate2
```

**常用选项：**
- `--draft` — 草稿 PR（不请求审查）
- `--reviewer user1,user2` — 指定审查人
- `--label "bug,backend"` — 打标签
- `--base develop` — 目标分支（默认 main）

### 创建 PR（git + curl 回退）

```bash
BRANCH=$(git branch --show-current)

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d "{
    \"title\": \"feat: 添加 JWT 用户认证\",
    \"body\": \"## 变更摘要\\n新增登录和注册 API 端点\\n\\nCloses #42\",
    \"head\": \"$BRANCH\",
    \"base\": \"main\"
  }"
```

响应中的 `number` 字段就是 PR 编号，后续操作需要用到。添加 `"draft": true` 可创建草稿 PR。

---

## 四、监控 CI 状态

PR 创建后，GitHub Actions 或其他 CI 系统会自动运行检查。

### gh CLI 模式

```bash
# 一次性检查
gh pr checks

# 持续监控（每10秒轮询，直到完成）
gh pr checks --watch
```

### git + curl 回退

```bash
# 获取最新 commit SHA
SHA=$(git rev-parse HEAD)

# 查询综合状态
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'整体状态: {data[\"state\"]}')
for s in data.get('statuses', []):
    print(f'  {s[\"context\"]}: {s[\"state\"]} - {s.get(\"description\", \"\")}')"

# 查询 GitHub Actions Check Runs
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/check-runs \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for cr in data.get('check_runs', []):
    print(f'  {cr[\"name\"]}: {cr[\"status\"]} / {cr.get(\"conclusion\", \"pending\")}')"
```

### 自动轮询脚本

```bash
# 每30秒检查一次，最多10分钟
SHA=$(git rev-parse HEAD)
for i in $(seq 1 20); do
  STATUS=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])")
  echo "第 $i 次检查: $STATUS"
  if [ "$STATUS" = "success" ] || [ "$STATUS" = "failure" ] || [ "$STATUS" = "error" ]; then
    break
  fi
  sleep 30
done
```

---

## 五、自动修复 CI 失败

CI 失败时，按以下循环处理：

### 1. 获取失败详情

```bash
# gh CLI
gh run list --branch $(git branch --show-current) --limit 5
gh run view <RUN_ID> --log-failed

# 或 curl
BRANCH=$(git branch --show-current)
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?branch=$BRANCH&per_page=5" \
  | python3 -c "
import sys, json
runs = json.load(sys.stdin)['workflow_runs']
for r in runs:
    print(f'Run {r[\"id\"]}: {r[\"name\"]} - {r.get(\"conclusion\", r[\"status\"])}')"

# 下载失败日志
curl -s -L \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runs/<RUN_ID>/logs \
  -o /tmp/ci-logs.zip
cd /tmp && unzip -o ci-logs.zip -d ci-logs && cat ci-logs/*.txt
```

### 2. 修复并推送

```bash
# 用文件工具修复代码
# 然后:
git add <修复后的文件>
git commit -m "fix: 修复 CI 失败 - <原因>"
git push
```

### 3. 自动修复循环

```
1. 检查 CI 状态 → 识别失败项
2. 读取失败日志 → 理解错误原因
3. 修复代码 → git add + commit + push
4. 等待 CI 跑完 → 重新检查
5. 仍然失败则重复（最多3次，然后请用户介入）
```

> **经验：** 常见的 CI 失败原因排名：lint 错误 > 测试用例不兼容（环境差异）> 依赖版本冲突 > 并发问题。先检查最简单的 Lint 问题往往最快修复。

---

## 六、合并 PR

### gh CLI 模式

```bash
# Squash 合并 + 删除分支（功能分支最推荐）
gh pr merge --squash --delete-branch

# 设置自动合并（等 CI 通过后自动合并）
gh pr merge --auto --squash --delete-branch
```

### git + curl 回退

```bash
PR_NUMBER=<编号>

# 通过 API 合并（squash）
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/merge \
  -d "{
    \"merge_method\": \"squash\",
    \"commit_title\": \"feat: 添加用户认证 (#$PR_NUMBER)\"
  }"

# 删除远程分支
BRANCH=$(git branch --show-current)
git push origin --delete $BRANCH

# 切回 main 并拉取最新代码
git checkout main && git pull origin main
git branch -d $BRANCH
```

### 三种合并策略对比

| 策略 | 命令 | 提交历史 | 适用场景 |
|------|------|---------|---------|
| **Merge Commit** | `"merge"` | 保留所有提交 + 额外 merge commit | 长期分支、多人协作 |
| **Squash Merge** | `"squash"` | 所有提交压缩为1个 | **功能分支首选**，历史清晰 |
| **Rebase Merge** | `"rebase"` | 线性提交，无 merge commit | 小改动、个人分支 |

> **推荐：** 团队统一用 Squash Merge。每个 PR 在 main 上只留一个提交，git log 清晰如 README。需要查看 PR 细节时，GitHub 上原始 PR 历史还在。

### 设置自动合并（通过 GitHub GraphQL API）

```bash
# 自动合并不能用 REST API，必须用 GraphQL
PR_NODE_ID=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['node_id'])")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/graphql \
  -d "{\"query\": \"mutation { enablePullRequestAutoMerge(input: {pullRequestId: \\\"$PR_NODE_ID\\\", mergeMethod: SQUASH}) { clientMutationId } }\"}"
```

---

## 七、完整工作流示例

```bash
# 1. 从 main 开始
git checkout main && git pull origin main

# 2. 创建分支
git checkout -b fix/login-redirect-bug

# 3. （用工具修改代码文件）

# 4. 提交
git add src/auth/login.py tests/test_login.py
git commit -m "fix: 修复登录后重定向URL

保留 ?next= 参数，不再总是跳转到 /dashboard。"

# 5. 推送
git push -u origin HEAD

# 6. 创建 PR
gh pr create \
  --title "fix: 修复登录后重定向 URL" \
  --body "修复用户登录后不保留 ?next= 参数的问题" \
  --label "bug"

# 7. 等待 CI（自动检查）

# 8. CI 通过后合并
gh pr merge --squash --delete-branch

# 9. 本地同步
git checkout main && git pull origin main
```

## 常用 PR 命令速查表

| 操作 | gh CLI | git + curl |
|------|--------|-----------|
| 列出我的 PR | `gh pr list --author @me` | `curl GET /repos/o/r/pulls?state=open` |
| 查看 PR diff | `gh pr diff` | `git diff main...HEAD`（本地） |
| 添加评论 | `gh pr comment N --body "..."` | `curl POST .../issues/N/comments` |
| 请求审查人 | `gh pr edit N --add-reviewer user` | `curl POST .../pulls/N/requested_reviewers` |
| 关闭 PR | `gh pr close N` | `curl PATCH .../pulls/N -d '{"state":"closed"}'` |
| 检出他人 PR | `gh pr checkout N` | `git fetch origin pull/N/head:pr-N && git checkout pr-N` |

## 相关链接

- [[01-入门指南/github-auth]] — GitHub 认证基础
- [[01-入门指南/github-repo-management]] — 仓库管理
- [[github-issues]] — Issue 管理与关联
- [[github-code-review]] — Code Review 实战
- [[../99-附录与速查/术语表|术语表]]
