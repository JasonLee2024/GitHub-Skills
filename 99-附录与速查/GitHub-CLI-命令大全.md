---
date: 2026-05-05
tags:
  - github
  - cli
  - gh
  - reference
  - cheatsheet
  - 附录与速查
category: 附录与速查
---

# GitHub CLI 命令大全

> `gh` 命令速查表，涵盖认证、仓库、PR、Issue、Actions、Release、Gist 等核心操作。

## 快速参考

```bash
# 最常用 10 个命令
gh auth status              # 查看认证状态
gh repo clone owner/repo    # 克隆仓库
gh repo create my-repo      # 创建仓库
gh pr create --fill         # 创建 PR（使用 commit msg 填充）
gh pr view --web            # 在浏览器打开 PR
gh issue list -L 20         # 列出最近 20 个 Issue
gh issue view 42            # 查看 Issue
gh workflow run build       # 触发工作流
gh run watch                # 监控运行中的工作流
gh release create v1.0.0    # 创建 Release
```

## 认证 (auth)

```bash
# 登录
gh auth login               # 交互式登录
gh auth login --with-token < token.txt  # Token 登录
gh auth refresh             # 刷新权限

# 状态
gh auth status              # 查看认证状态
gh auth token               # 查看当前 Token
gh auth list                # 列出所有认证账号

# 切换账号
gh auth switch              # 切换 GitHub 账号
```

## 仓库 (repo)

```bash
gh repo create [name]           # 创建仓库
  --public                      # 公开
  --private                     # 私有
  --internal                    # 内部
  --template owner/repo         # 从模板创建
  --clone                       # 创建后克隆

gh repo fork [owner/repo]       # Fork 仓库
  --clone                       # Fork 后克隆

gh repo clone owner/repo        # 克隆仓库
  -- --depth 1                  # 浅克隆

gh repo view [owner/repo]       # 查看仓库
  --web                         # 浏览器打开
  --branch main                 # 指定分支

gh repo list [owner]            # 列出仓库
  -L 50                         # 限制数量
  --public                      # 只显示公开
  --private                     # 只显示私有
  --fork                        # 包含 fork

gh repo rename new-name         # 重命名仓库
gh repo delete [owner/repo]     # 删除仓库
gh repo archive [owner/repo]    # 归档仓库
```

## Pull Request (pr)

```bash
gh pr create                    # 创建 PR
  --title "Title"
  --body "Description"
  --base main                   # 目标分支
  --head my-branch              # 源分支
  --fill                        # 用 commit 信息填充
  --draft                       # 草稿 PR
  --reviewer user               # 指定审查人
  --label bug                   # 添加标签
  --assignee me                 # 分配给自己

gh pr list                      # 列出 PR
  -L 30                         # 限制数量
  -s open                       # open / closed / merged / all
  -a @me                        # 我的 PR
  -l bug                        # 按标签筛选
  --json number,title,state     # JSON 输出

gh pr view [number]             # 查看 PR
  --web                         # 浏览器打开
  --comments                    # 显示评论
  --json state,title,body       # JSON 输出

gh pr checkout [number]         # 检出 PR 到本地
gh pr diff [number]             # 查看 diff
gh pr review [number]           # 审查 PR
  -a                            # 批准 (approve)
  -c                            # 需修改 (comment)
  -r                            # 拒绝 (request changes)
  -b "LGTM"                     # 审查正文

gh pr merge [number]            # 合并 PR
  --squash                      # Squash 合并
  --rebase                      # Rebase 合并
  --merge                       # Merge 合并
  --delete-branch               # 合并后删除分支

gh pr close [number]            # 关闭 PR
gh pr reopen [number]           # 重新打开 PR
gh pr ready [number]            # 标记为就绪（草稿→非草稿）
```

## Issue

```bash
gh issue create                 # 创建 Issue
  --title "Title"
  --body "Description"
  --label bug                   # 标签
  --assignee me                 # 分配
  --project "Sprint 12"         # 关联 Project

gh issue list                   # 列出 Issue
  -L 30
  -s open
  -a @me
  -l bug,help-wanted
  --json number,title,labels

gh issue view 42                # 查看 Issue
  --web
  --comments

gh issue close 42               # 关闭 Issue
gh issue reopen 42              # 重新打开
gh issue edit 42                # 编辑 Issue
gh issue comment 42 -b "Done"   # 添加评论
```

## Actions (workflow / run)

```bash
# 工作流管理
gh workflow list                # 列出工作流
gh workflow view [id/name]      # 查看工作流
gh workflow run [id/name]       # 触发工作流
  --ref main                    # 指定分支
  -f param=value                # 传入参数

# 运行管理
gh run list                     # 列出运行
  -L 10                         # 最近 10 次
  -s success                    # 按状态筛选
  -w build.yml                  # 按工作流筛选
  --json databaseId,status,conclusion

gh run view [id]                # 查看运行
  --log                         # 查看日志
  --attempt 2                   # 指定重试次数

gh run watch [id]               # 实时监控
gh run cancel [id]              # 取消运行
gh run rerun [id]               # 重新运行
  --failed                      # 只重新运行失败的 job
gh run download [id]            # 下载 artifact
```

## Release

```bash
gh release list                 # 列出 Releases
  -L 10
  --json tagName,createdAt

gh release view [tag]           # 查看 Release
gh release create v1.0.0        # 创建 Release
  --title "v1.0.0"
  --notes "Release notes..."
  --notes-file CHANGELOG.md     # 从文件读取
  --target main                 # 目标提交
  --prerelease                  # 预发布
  --draft                       # 草稿
  --generate-notes              # 自动生成日志

gh release upload v1.0.0 ./dist/*.zip   # 上传附件
gh release download v1.0.0     # 下载附件
gh release edit v1.0.0         # 编辑
gh release delete v1.0.0       # 删除
```

## Gist

```bash
gh gist create file.py          # 创建 Gist
  --public                      # 公开
  --filename "name.py"          # 文件名

gh gist list                    # 列出 Gist
  -L 20
  --public
  --secret

gh gist view [id]               # 查看 Gist
gh gist edit [id] file.py       # 编辑
gh gist delete [id]             # 删除
```

## 搜索 (search)

```bash
gh search repos "keyword"       # 搜索仓库
  --stars 1000
  --language python
  --topic "machine-learning"

gh search issues "bug"          # 搜索 Issue
  --repo owner/repo
  --state open
  --author @me

gh search prs "feat"            # 搜索 PR
gh search commits "fix"         # 搜索提交
gh search code "TODO"           # 搜索代码
```

## 配置与别名

```bash
gh config set editor vim        # 设置编辑器
gh config set git_protocol ssh  # 设置 Git 协议

# 常用别名
gh alias set co "pr checkout"
gh alias set pl "pr list -L 20"
gh alias set il "issue list -L 20"
gh alias set wl "workflow list"
gh alias set rl "release list -L 10"

# 使用别名
gh co 42                        # 等于 gh pr checkout 42
gh pl                           # 等于 gh pr list -L 20
```

## JSON 输出

```bash
# 全面的 JSON 支持
gh pr view 42 --json title,body,author,state,mergedAt
gh issue list --json number,title,labels -q '.[] | {number, title}'

# jq 配合使用
gh pr list --json number,title,author,createdAt \
  | jq '.[] | "\(.number) - \(.title) by \(.author.login)"'

# API 直接调用
gh api repos/:owner/:repo/pulls
gh api /user/repos --jq '.[].full_name'
```

## 相关文档

- [[GitHub-REST-API-速查]]
- [[术语表]]
