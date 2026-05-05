---
date: 2026-05-05
tags:
  - github
  - issues
  - project-management
  - bug-tracking
  - triage
  - GitHub核心操作
source_skill: github-issues
category: GitHub 核心操作
---

# GitHub Issue 管理指南

> 本文档基于 Hermes Agent 的 `github-issues` 技能整理，覆盖 Issue 从创建到关闭的全生命周期管理。

## 概述

Issue 是 GitHub 上跟踪任务、缺陷和功能请求的核心方式。一个 Issue 不只是"一个帖子"——它有标题、正文、标签、指派人、里程碑、评论，还可以通过 PR 自动关闭。良好的 Issue 管理能大幅提升团队协作效率。

本文覆盖：创建 → 搜索 → 标签管理 → 指派 → 评论 → 关闭 → 批量操作。

## 前置检查

```bash
# 检测认证方式
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
  echo "使用 gh CLI"
else
  AUTH="git"
  if [ -z "$GITHUB_TOKEN" ]; then
    if [ -f ~/.hermes/.env ] && grep -q "^GITHUB_TOKEN=" ~/.hermes/.env; then
      GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" ~/.hermes/.env | head -1 | cut -d= -f2 | tr -d '\n\r')
    fi
  fi
fi

REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
```

---

## 一、查看 Issue

### gh CLI 模式

```bash
# 列出打开的 Issue
gh issue list

# 按标签筛选
gh issue list --state open --label "bug"

# 分配给自己的
gh issue list --assignee @me

# 关键词搜索
gh issue list --search "认证错误" --state all

# 查看某个 Issue 详情
gh issue view 42
```

### git + curl 回退

```bash
# 列出打开的 Issue
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?state=open&per_page=20" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin):
    if 'pull_request' not in i:  # 注意：GitHub API 把 PR 也返回在 /issues 里
        labels = ', '.join(l['name'] for l in i['labels'])
        print(f'#{i[\"number\"]:5}  {i[\"state\"]:6}  {labels:30}  {i[\"title\"]}')"

# 按标签筛选（bug 标签）
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?state=open&labels=bug&per_page=20"

# 查看具体 Issue
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  | python3 -c "
import sys, json
i = json.load(sys.stdin)
labels = ', '.join(l['name'] for l in i['labels'])
assignees = ', '.join(a['login'] for a in i['assignees'])
print(f'#{i[\"number\"]}: {i[\"title\"]}')
print(f'状态: {i[\"state\"]}  标签: {labels}  指派: {assignees}')
print(f'作者: {i[\"user\"][\"login\"]}  创建: {i[\"created_at\"]}')
print(f'\n{i[\"body\"]}')"

# 关键词搜索
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/search/issues?q=认证错误+repo:$OWNER/$REPO" \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin)['items']:
    print(f'#{i[\"number\"]}  {i[\"state\"]:6}  {i[\"title\"]}')"
```

> **注意：** GitHub API 会混入 PR 到 `/issues` 端点中。判断是否是真正的 Issue：检查 `pull_request` 字段是否不存在。

---

## 二、创建 Issue

### gh CLI 模式

```bash
gh issue create \
  --title "登录后跳转忽略 ?next= 参数" \
  --body "## 描述
登录后用户总是被重定向到 /dashboard。

## 复现步骤
1. 未登录状态下访问 /settings
2. 被重定向到 /login?next=/settings
3. 登录后
4. 实际：跳转到 /dashboard（应该跳转到 /settings）

## 预期行为
尊重 ?next= 查询参数。" \
  --label "bug,backend" \
  --assignee "username"
```

### curl 模式

```bash
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues \
  -d '{
    "title": "登录后跳转忽略 ?next= 参数",
    "body": "## 描述\n登录后用户总是被重定向到 /dashboard。\n\n## 复现步骤\n1. 访问 /settings\n2. 被重定向到 /login?next=/settings\n3. 登录后跳到 /dashboard\n\n## 预期\n保留 ?next 参数",
    "labels": ["bug", "backend"],
    "assignees": ["username"]
  }'
```

### 推荐 Issue 模板

**Bug Report 模板：**
```

## Bug 描述
<发生了什么问题>

## 复现步骤
1. <步骤一>
2. <步骤二>

## 预期行为
<应该怎么样>

## 实际行为
<实际怎么样>

## 环境
- OS: 
- 版本:
- 浏览器（如适用）:
```

**Feature Request 模板：**
```

## 功能描述
<想要什么功能>

## 动机
<为什么这个功能有用>

## 实现方案建议
<怎么实现>

## 备选方案
<其他考虑过的方案>
```

---

## 三、管理 Issue

### 标签管理

```bash
# gh - 添加标签
gh issue edit 42 --add-label "priority:high,bug"

# gh - 移除标签
gh issue edit 42 --remove-label "needs-triage"

# curl - 添加标签
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/labels \
  -d '{"labels": ["priority:high", "bug"]}'

# curl - 移除标签
curl -s -X DELETE \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/labels/needs-triage

# 查看项目中所有可用标签
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/labels \
  | python3 -c "
import sys, json
for l in json.load(sys.stdin):
    print(f'  {l[\"name\"]:30}  {l.get(\"description\", \"\")}')"
```

### 指派

```bash
# gh
gh issue edit 42 --add-assignee username

# curl
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/assignees \
  -d '{"assignees": ["username"]}'
```

### 评论

```bash
# gh
gh issue comment 42 --body "已排查——根因在认证中间件，正在修复。"

# curl
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42/comments \
  -d '{"body": "已排查——根因在认证中间件，正在修复。"}'
```

### 关闭与重新打开

```bash
# gh - 关闭
gh issue close 42
gh issue close 42 --reason "not planned"   # 标记为"不计划修复"

# gh - 重新打开
gh issue reopen 42

# curl - 关闭
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  -d '{"state": "closed", "state_reason": "completed"}'

# curl - 重新打开
curl -s -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/issues/42 \
  -d '{"state": "open"}'
```

### Issue 与 PR 关联

在 PR 正文中使用以下关键词，合并时会**自动关闭**关联 Issue：

```
Closes #42
Fixes #42
Resolves #42
```

同时也支持多 Issue：`Fixes #42, #43, #44`

从 Issue 创建分支：

```bash
# gh CLI 直接创建并检出
gh issue develop 42 --checkout

# 手动方式
git checkout main && git pull origin main
git checkout -b fix/issue-42-login-redirect
```

---

## 四、Issue 分类工作流

当需要批量处理待分类的 Issue 时：

```bash
# 1. 列出未分类的 Issue（带 needs-triage 标签）
gh issue list --label "needs-triage" --state open

# 2. 逐个查看详情
gh issue view <编号>

# 3. 根据内容打标签
gh issue edit <编号> --add-label "bug,priority:medium"
gh issue edit <编号> --remove-label "needs-triage"

# 4. 指派负责人
gh issue edit <编号> --add-assignee <用户名>

# 5. 必要时添加分类评论
gh issue comment <编号> --body "已分类为 Bug，优先级中等。"
```

### 分类标准建议

| 类别 | 标签 | 响应时间 |
|------|------|---------|
| Bug（可复现） | `bug` + `priority:<级别>` | 高优 24h / 低优 1周 |
| 功能请求 | `enhancement` | 1周内讨论 |
| 文档问题 | `docs` | 3天内 |
| 问题/求助 | `question` | 48h |
| 重复 | `duplicate` | 关闭并引用原 Issue |
| 不计划 | `wontfix` | 说明原因后关闭 |

---

## 五、批量操作

```bash
# gh - 批量关闭带有特定标签的 Issue
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"

# curl - 批量关闭
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/issues?labels=wontfix&state=open" \
  | python3 -c "import sys,json; [print(i['number']) for i in json.load(sys.stdin) if 'pull_request' not in i]" \
  | while read num; do
    curl -s -X PATCH \
      -H "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/$OWNER/$REPO/issues/$num \
      -d '{"state": "closed", "state_reason": "not_planned"}'
    echo "已关闭 #$num"
  done
```

> **经验：** 批量操作前最好先 `--limit 50` 预览一下，确认无误再执行写操作。不小心批量关闭了活跃 Issue 很尴尬。

---

## 速查表

| 操作 | gh CLI | curl 端点 |
|------|--------|-----------|
| 列出 | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| 查看 | `gh issue view N` | `GET /repos/{o}/{r}/issues/N` |
| 创建 | `gh issue create ...` | `POST /repos/{o}/{r}/issues` |
| 加标签 | `gh issue edit N --add-label` | `POST /repos/{o}/{r}/issues/N/labels` |
| 指派 | `gh issue edit N --add-assignee` | `POST /repos/{o}/{r}/issues/N/assignees` |
| 评论 | `gh issue comment N --body` | `POST /repos/{o}/{r}/issues/N/comments` |
| 关闭 | `gh issue close N` | `PATCH /repos/{o}/{r}/issues/N` |
| 搜索 | `gh issue list --search "..."` | `GET /search/issues?q=...` |

## 相关链接

- [[01-入门指南/github-auth]] — 认证基础
- [[01-入门指南/github-repo-management]] — 仓库管理
- [[github-pr-workflow]] — PR 工作流（用 Closes #N 关联 Issue）
- [[../99-附录与速查/术语表|术语表]]
