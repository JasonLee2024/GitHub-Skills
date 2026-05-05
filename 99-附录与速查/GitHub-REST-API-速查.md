---
date: 2026-05-05
tags:
  - github
  - api
  - rest-api
  - reference
  - cheatsheet
  - 附录与速查
category: 附录与速查
---

# GitHub REST API 速查表

> 快速查阅常用的 GitHub REST API 端点，包含仓库、PR、Issue、Actions 和 Releases 操作。

## 仓库 (Repositories)

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 查看仓库 | GET | `/repos/{owner}/{repo}` | `gh api repos/:owner/:repo` |
| 创建仓库 | POST | `/user/repos` | `gh repo create` |
| Fork 仓库 | POST | `/repos/{o}/{r}/forks` | `gh repo fork` |
| 搜索仓库 | GET | `/search/repositories?q={query}` | `gh search repos` |
| 列出分支 | GET | `/repos/{o}/{r}/branches` | `gh api repos/:o/:r/branches` |
| 创建分支 | POST | `/repos/{o}/{r}/git/refs` | `git branch` |
| 列出文件 | GET | `/repos/{o}/{r}/contents/` | `gh api repos/:o/:r/contents/` |
| 获取 Readme | GET | `/repos/{o}/{r}/readme` | `gh api repos/:o/:r/readme` |
| 添加文件 | PUT | `/repos/{o}/{r}/contents/{path}` | — |
| 删除文件 | DELETE | `/repos/{o}/{r}/contents/{path}` | — |
| 查看语言 | GET | `/repos/{o}/{r}/languages` | `gh api repos/:o/:r/languages` |
| 查看标签 | GET | `/repos/{o}/{r}/tags` | `gh api repos/:o/:r/tags` |
| 查看发布 | GET | `/repos/{o}/{r}/releases` | `gh release list` |
| 查看贡献者 | GET | `/repos/{o}/{r}/contributors` | `gh api repos/:o/:r/contributors` |
| 查看统计 | GET | `/repos/{o}/{r}/stats/code_frequency` | — |

## Pull Requests

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 列出 PR | GET | `/repos/{o}/{r}/pulls` | `gh pr list` |
| 查看 PR | GET | `/repos/{o}/{r}/pulls/{number}` | `gh pr view {number}` |
| 创建 PR | POST | `/repos/{o}/{r}/pulls` | `gh pr create` |
| 合并 PR | PUT | `/repos/{o}/{r}/pulls/{n}/merge` | `gh pr merge {n}` |
| 关闭 PR | PATCH | `/repos/{o}/{r}/pulls/{n}` | `gh pr close` |
| 重新打开 PR | PATCH | `/repos/{o}/{r}/pulls/{n}` | — |
| 列出审查 | GET | `/repos/{o}/{r}/pulls/{n}/reviews` | `gh pr review {n}` |
| 提交审查 | POST | `/repos/{o}/{r}/pulls/{n}/reviews` | `gh pr review {n} -a` |
| 列出文件 | GET | `/repos/{o}/{r}/pulls/{n}/files` | `gh pr diff` |
| 列出提交 | GET | `/repos/{o}/{r}/pulls/{n}/commits` | `gh pr view {n} --commits` |
| 检查合并 | GET | `/repos/{o}/{r}/pulls/{n}/merge` | — |
| 请求审查 | POST | `/repos/{o}/{r}/pulls/{n}/requested_reviewers` | — |

## Issues

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 列出 Issue | GET | `/repos/{o}/{r}/issues` | `gh issue list` |
| 查看 Issue | GET | `/repos/{o}/{r}/issues/{n}` | `gh issue view {n}` |
| 创建 Issue | POST | `/repos/{o}/{r}/issues` | `gh issue create` |
| 更新 Issue | PATCH | `/repos/{o}/{r}/issues/{n}` | `gh issue edit` |
| 关闭 Issue | PATCH | `/repos/{o}/{r}/issues/{n}` | `gh issue close` |
| 重新打开 | PATCH | `/repos/{o}/{r}/issues/{n}` | `gh issue reopen` |
| 添加标签 | POST | `/repos/{o}/{r}/issues/{n}/labels` | `gh issue edit --add-label` |
| 移除标签 | DELETE | `/repos/{o}/{r}/issues/{n}/labels/{l}` | `gh issue edit --remove-label` |
| 添加评论 | POST | `/repos/{o}/{r}/issues/{n}/comments` | `gh issue comment` |
| 列出标签 | GET | `/repos/{o}/{r}/labels` | `gh label list` |
| 创建标签 | POST | `/repos/{o}/{r}/labels` | `gh label create` |
| 列出里程碑 | GET | `/repos/{o}/{r}/milestones` | — |

## Actions (CI/CD)

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 列出工作流 | GET | `/repos/{o}/{r}/actions/workflows` | `gh workflow list` |
| 查看工作流 | GET | `/repos/{o}/{r}/actions/workflows/{id}` | `gh workflow view` |
| 触发工作流 | POST | `/repos/{o}/{r}/actions/workflows/{id}/dispatches` | `gh workflow run` |
| 列出运行 | GET | `/repos/{o}/{r}/actions/runs` | `gh run list` |
| 查看运行 | GET | `/repos/{o}/{r}/actions/runs/{id}` | `gh run view {id}` |
| 取消运行 | POST | `/repos/{o}/{r}/actions/runs/{id}/cancel` | `gh run cancel` |
| 重新运行 | POST | `/repos/{o}/{r}/actions/runs/{id}/rerun` | `gh run rerun` |
| 下载日志 | GET | `/repos/{o}/{r}/actions/runs/{id}/logs` | `gh run view --log` |
| 查看 artifact | GET | `/repos/{o}/{r}/actions/artifacts` | — |
| 下载 artifact | GET | `/repos/{o}/{r}/actions/artifacts/{id}/zip` | — |

## Releases

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 列出 Release | GET | `/repos/{o}/{r}/releases` | `gh release list` |
| 查看 Release | GET | `/repos/{o}/{r}/releases/{id}` | `gh release view` |
| 创建 Release | POST | `/repos/{o}/{r}/releases` | `gh release create` |
| 更新 Release | PATCH | `/repos/{o}/{r}/releases/{id}` | `gh release edit` |
| 删除 Release | DELETE | `/repos/{o}/{r}/releases/{id}` | `gh release delete` |
| 上传资产 | POST | `/repos/{o}/{r}/releases/{id}/assets` | `gh release upload` |
| 下载资产 | GET | `/repos/{o}/{r}/releases/{id}/assets/{a}` | `gh release download` |
| 列出标签 | GET | `/repos/{o}/{r}/releases/{id}/assets` | — |

## Webhooks

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 列出 Webhook | GET | `/repos/{o}/{r}/hooks` | `gh api repos/:o/:r/hooks` |
| 查看 Webhook | GET | `/repos/{o}/{r}/hooks/{id}` | `gh api repos/:o/:r/hooks/:id` |
| 创建 Webhook | POST | `/repos/{o}/{r}/hooks` | `gh api repos/:o/:r/hooks -f ...` |
| 更新 Webhook | PATCH | `/repos/{o}/{r}/hooks/{id}` | `gh api repos/:o/:r/hooks/:id -X PATCH` |
| 删除 Webhook | DELETE | `/repos/{o}/{r}/hooks/{id}` | `gh api repos/:o/:r/hooks/:id -X DELETE` |
| 测试 Webhook | POST | `/repos/{o}/{r}/hooks/{id}/tests` | — |
| 列出组织 Webhook | GET | `/orgs/{org}/hooks` | `gh api orgs/:org/hooks` |
| 创建组织 Webhook | POST | `/orgs/{org}/hooks` | — |

## 用户与认证

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 查看当前用户 | GET | `/user` | `gh api user` |
| 查看用户 | GET | `/users/{username}` | `gh api users/:username` |
| 列出用户仓库 | GET | `/users/{u}/repos` | `gh repo list {u}` |
| 查看用户组织 | GET | `/users/{u}/orgs` | `gh api users/:u/orgs` |
| 列出用户 Gist | GET | `/users/{u}/gists` | `gh gist list` |
| 查看用户星标 | GET | `/users/{u}/starred` | — |
| 查看用户关注者 | GET | `/users/{u}/followers` | — |
| 关注用户 | PUT | `/user/following/{u}` | — |
| 取消关注 | DELETE | `/user/following/{u}` | — |

## Git 数据

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 获取引用 | GET | `/repos/{o}/{r}/git/ref/{ref}` | — |
| 创建引用 | POST | `/repos/{o}/{r}/git/refs` | — |
| 删除引用 | DELETE | `/repos/{o}/{r}/git/refs/{ref}` | — |
| 获取提交 | GET | `/repos/{o}/{r}/git/commits/{sha}` | — |
| 创建提交 | POST | `/repos/{o}/{r}/git/commits` | — |
| 获取 Blob | GET | `/repos/{o}/{r}/git/blobs/{sha}` | — |
| 创建 Blob | POST | `/repos/{o}/{r}/git/blobs` | — |
| 获取 Tag | GET | `/repos/{o}/{r}/git/tags/{sha}` | — |
| 创建 Tag | POST | `/repos/{o}/{r}/git/tags` | — |
| 比较提交 | GET | `/repos/{o}/{r}/compare/{base}...{head}` | `gh api repos/:o/:r/compare/:base...:head` |

## 组织管理

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 查看组织 | GET | `/orgs/{org}` | `gh api orgs/:org` |
| 更新组织 | PATCH | `/orgs/{org}` | — |
| 列出成员 | GET | `/orgs/{org}/members` | `gh api orgs/:org/members` |
| 检查成员 | GET | `/orgs/{org}/members/{u}` | — |
| 删除成员 | DELETE | `/orgs/{org}/members/{u}` | — |
| 列出团队 | GET | `/orgs/{org}/teams` | — |
| 创建团队 | POST | `/orgs/{org}/teams` | — |
| 列出邀请 | GET | `/orgs/{org}/invitations` | — |
| 列出仓库 | GET | `/orgs/{org}/repos` | `gh repo list {org}` |
| 查看审计日志 | GET | `/orgs/{org}/audit-log` | — |

## 搜索 API

| 操作 | 方法 | 端点 | gh 命令 |
|------|------|------|---------|
| 搜索仓库 | GET | `/search/repositories` | `gh search repos` |
| 搜索代码 | GET | `/search/code` | `gh search code` |
| 搜索 Issue | GET | `/search/issues` | `gh search issues` |
| 搜索用户 | GET | `/search/users` | `gh search users` |
| 搜索提交 | GET | `/search/commits` | `gh search commits` |

### 搜索参数

```bash
# 常用搜索限定符
?q=repo:owner/repo+languagbe:pyhon+topic:mlops
?q=is:issue+is:open+label:bug+author:@me
?q=path:src/+language:python+NOT format
```

## 通用分页参数

```bash
# 分页参数 (适用于所有列表端点)
?per_page=100    # 每页数量 (最大 100)
?page=1          # 页码

# 分页示例
gh api repos/:owner/:repo/issues?per_page=100&page=1

# 获取所有页
gh api repos/:owner/:repo/issues --paginate
```

## 通用过滤器

| 参数 | 示例 | 说明 |
|------|------|------|
| `state` | `?state=open` | open / closed / all |
| `sort` | `?sort=updated` | created / updated / comments |
| `direction` | `?direction=desc` | asc / desc |
| `since` | `?since=2024-01-01T00:00:00Z` | ISO 8601 时间戳 |
| `per_page` | `?per_page=100` | 每页数量 |
| `page` | `?page=1` | 页码 |

## 实用示例

```bash
# 1. 获取 Issue 统计
gh api repos/:owner/:repo/issues?state=closed&since=2024-01-01 \
  | jq length

# 2. 批量关闭旧 Issue
gh api repos/:owner/:repo/issues?state=open&per_page=100 \
  | jq -r '.[] | select(.updated_at < "2023-01-01") | .number' \
  | xargs -I{} gh issue close {}

# 3. 获取工作流运行时间和状态
gh api repos/:owner/:repo/actions/runs?per_page=50 \
  | jq '.workflow_runs[] | {name, status, conclusion, run_started_at}'

# 4. 列出所有仓库的主题
gh api orgs/:org/repos?per_page=100 --paginate \
  | jq '.[].topics | select(. != null) | .[]' | sort -u

# 5. 检查用户对仓库的权限
gh api repos/:owner/:repo/collaborators/:username/permission

# 6. 创建 Issue 并添加标签
gh api repos/:owner/:repo/issues \
  -f title="自动创建的 Issue" \
  -f body="由 API 创建的 Issue" \
  -f labels='["bug","automation"]'

# 7. 获取仓库贡献排名
gh api repos/:owner/:repo/contributors?per_page=10 \
  | jq '.[] | "\(.login): \(.contributions) commits"'
```

## 错误码参考

| 状态码 | 含义 | 处理 |
|--------|------|------|
| 200 OK | 请求成功 | 正常解析响应 |
| 201 Created | 资源创建成功 | 通常在 POST 后 |
| 202 Accepted | 已接受（异步任务） | 轮询状态 |
| 204 No Content | 成功无响应体 | 通常是 DELETE |
| 301 Moved | 永久重定向 | 跟随 Location |
| 304 Not Modified | 未修改（条件请求） | 使用缓存 |
| 400 Bad Request | 请求格式错误 | 检查参数 |
| 401 Unauthorized | 认证失败 | 检查 Token |
| 403 Forbidden | 无权限或限流 | 检查权限或等待 |
| 404 Not Found | 资源不存在 | 检查路径 |
| 409 Conflict | 冲突（如合并失败） | 更新后重试 |
| 422 Unprocessable | 语义错误 | 检查请求体 |
| 429 Too Many Requests | 限流 | 等待 Retry-After |

## 相关文档

- [[GitHub-CLI-命令大全]]
- [[术语表]]
