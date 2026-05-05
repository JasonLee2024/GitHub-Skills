---
date: 2026-05-05
tags:
  - github
  - code-review
  - pull-request
  - best-practices
  - quality
  - GitHub核心操作
source_skill: github-code-review
category: GitHub 核心操作
---

# Code Review 实战指南

> 本文档基于 Hermes Agent 的 `github-code-review` 技能整理，覆盖本地审查和 PR 审查全流程。

## 概述

Code Review（代码审查）是保证代码质量的核心环节，也是团队知识传递的重要渠道。一个好的 Review 不只是"看代码有没有 bug"，还涉及架构合理性、可维护性、安全性、测试覆盖等多个维度。

本文覆盖两个场景：
1. **本地审查（Pre-Push）** — 在推送前审查自己的改动
2. **PR 审查（Post-Push）** — 审查他人提交的 PR

## 前置检查

```bash
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
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

## 一、本地审查（推送前自查）

这部分是纯 `git`，不需要 GitHub API。

### 查看改动

```bash
# 已暂存的改动（即将提交的内容）
git diff --staged

# 当前分支 vs main 的所有改动（PR 内容预览）
git diff main...HEAD

# 只看文件名
git diff main...HEAD --name-only

# 统计（每个文件增删行数）
git diff main...HEAD --stat

# 查看提交历史
git log main..HEAD --oneline
```

### 审查策略

分三步走：

**第一步：全局概览**

```bash
git diff main...HEAD --stat
git log main..HEAD --oneline
```

先了解这个 PR 改了多少文件、核心方向是什么。如果一个 PR 改了 30+ 个文件，建议拆成多个小 PR。

**第二步：逐文件审查**

```bash
# 看某个文件的完整 diff
git diff main...HEAD -- src/auth/login.py

# 用 read_file 看完整上下文（diff 只有改动行，不如看完整文件容易发现问题）
```

**第三步：自动化检查**

```bash
# 检查遗留的调试语句
git diff main...HEAD | grep -n "print(\|console\.log\|TODO\|FIXME\|HACK\|XXX\|debugger"

# 检查大文件（意外提交了二进制文件或生成文件）
git diff main...HEAD --stat | sort -t'|' -k2 -rn | head -10

# 检查敏感信息泄露
git diff main...HEAD | grep -in "password\|secret\|api_key\|token.*=\|private_key"

# 检查合并冲突遗留
git diff main...HEAD | grep -n "<<<<<<\|>>>>>>\|======="
```

> **经验：** `grep` 检查敏感信息这一步很重要。很多人习惯在代码里写死 API Key 做快速测试，结果不小心 push 上去了。一旦 push 上去，即使下一秒就删掉，Token 也已经暴露了——**历史记录里永远留着它**。

### 审查反馈格式

向用户展示审查结果时，用这个结构：

```
## 审查摘要

### 🔴 严重问题
- **src/auth.py:45** — SQL 注入风险：用户的输入直接拼接到 SQL 查询中
  建议：使用参数化查询

### ⚠️ 警告
- **src/models/user.py:23** — 密码以明文存储，建议用 bcrypt 或 argon2
- **src/api/routes.py:112** — 登录端点未添加频率限制

### 💡 建议
- **src/utils/helpers.py:8** — 与 `src/core/utils.py:34` 逻辑重复，建议合并
- **tests/test_auth.py** — 缺少过期 Token 的测试用例

### ✅ 不错
- 中间件层职责清晰分离
- 快乐路径测试覆盖全面
```

---

## 二、PR 审查（远程 Review）

### 查看 PR 信息

```bash
# gh CLI
gh pr view 123
gh pr diff 123
gh pr diff 123 --name-only

# curl
PR_NUMBER=123

# PR 基本信息
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "
import sys, json
pr = json.load(sys.stdin)
print(f'标题: {pr[\"title\"]}')
print(f'作者: {pr[\"user\"][\"login\"]}')
print(f'分支: {pr[\"head\"][\"ref\"]} -> {pr[\"base\"][\"ref\"]}')
print(f'状态: {pr[\"state\"]}')
print(f'\n内容:\n{pr[\"body\"]}')"

# 变更文件列表
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/files \
  | python3 -c "
import sys, json
for f in json.load(sys.stdin):
    print(f'{f[\"status\"]:10} +{f[\"additions\"]:-4} -{f[\"deletions\"]:-4}  {f[\"filename\"]}')"
```

### 在本地检出 PR

```bash
# gh CLI 模式
gh pr checkout 123

# 纯 git 模式（不需要 gh）
git fetch origin pull/123/head:pr-123
git checkout pr-123

# 现在可以完整查看文件、运行测试、搜索代码
# git diff main...HEAD 查看完整 diff

# 审查完毕后切回 main 并清理
git checkout main
git branch -D pr-123
```

---

## 三、在 PR 上提交 Review

### 发起 Review（三种事件）

**gh CLI 模式：**

```bash
# 批准（Approve）— 代码没问题
gh pr review 123 --approve --body "LGTM！代码干净利落。"

# 请求变更（Request Changes）— 需要修复
gh pr review 123 --request-changes --body "有几个问题需要修正，见内联评论。"

# 评论（Comment）— 有建议但不阻塞
gh pr review 123 --comment --body "整体不错，一些小建议。"
```

### 内联评论

在特定文件的特定行留下评论，是 Code Review 最精准的方式。

**gh CLI 配合 API 提交内联评论：**

```bash
HEAD_SHA=$(gh pr view 123 --json headRefOid --jq '.headRefOid')

gh api repos/$OWNER/$REPO/pulls/123/comments \
  --method POST \
  -f body="这里可以用列表推导式简化。" \
  -f path="src/auth/login.py" \
  -f commit_id="$HEAD_SHA" \
  -f line=45 \
  -f side="RIGHT"
```

**curl 提交原子化 Review（多条内联评论一次性提交）：**

```bash
HEAD_SHA=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['head']['sha'])")

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews \
  -d "{
    \"commit_id\": \"$HEAD_SHA\",
    \"event\": \"COMMENT\",
    \"body\": \"## Hermes 代码审查报告\",
    \"comments\": [
      {\"path\": \"src/auth.py\", \"line\": 45, \"body\": \"🔴 **严重：** 用户输入直接传入 SQL 查询，请使用参数化查询。\"},
      {\"path\": \"src/models/user.py\", \"line\": 23, \"body\": \"⚠️ **警告：** 密码未哈希存储。\"},
      {\"path\": \"src/utils/helpers.py\", \"line\": 8, \"body\": \"💡 **建议：** 与 core/utils.py:34 逻辑重复。\"}
    ]
  }"
```

**事件值：** `"APPROVE"`、`"REQUEST_CHANGES"`、`"COMMENT"`

> `line` 参数指向文件**新版本**中的行号。如果是针对被删掉的行，需要加 `"side": "LEFT"`。

---

## 四、审查清单

每次审查时系统性地检查以下维度：

### 正确性
- 代码是否实现了它声称要实现的功能？
- 边界情况是否处理了？（空值、异常数据、并发访问）
- 错误路径是否优雅处理？

### 安全性
- 没有硬编码的密钥、密码、Token
- 用户输入有校验（防 XSS、SQL 注入、路径遍历）
- 权限检查是否到位

### 代码质量
- 命名清晰（变量名、函数名、类名）
- 没有不必要的复杂性
- 没有重复逻辑（DRY 原则）
- 函数职责单一

### 测试
- 新增代码路径有测试覆盖？
- 快乐路径和错误情况都覆盖了？
- 测试本身可读性如何？

### 性能
- 没有 N+1 查询或不必要的循环
- 适当使用缓存
- 异步代码中没有阻塞操作

### 文档
- 公共 API 有文档注释？
- 复杂的逻辑有"为什么这么做"的注释？
- README 是否更新？

---

## 五、完整 PR 审查流程

```
1. 查看 PR 摘要（标题、描述、文件列表）
2. 在本地检出 PR 代码
3. 运行测试套件
4. 逐文件审查 diff
5. 用 read_file 获取完整上下文
6. 对照审查清单逐项检查
7. 编写审查结论（优先级分级）
8. 提交 Review（内联评论 + 总结）
9. 清理本地分支
```

### 决策标准

| 结果 | 条件 | 行动 |
|------|------|------|
| **Approve** | 无严重问题、无警告，只有建议或完全 OK | 批准 + 可选留言 |
| **Request Changes** | 有严重问题或警告需要修复 | 请求变更 + 说明原因 |
| **Comment** | 有建议但不阻塞 | 评论 + 可同时 Approve |
| **关闭 PR** | 方向错误、重复、不成熟 | 评论说明后手动关闭 |

> **经验：** 一个好的 Review 不只是"找茬"，还要指出"好的地方"。先给积极的反馈，再提改进建议，这样对方更容易接受。

---

## 六、AI 辅助审查模式

用 Hermes Agent 做 Code Review 时，可以自动化大部分常规检查：

```bash
# 1. 自动分析改动范围
git diff main...HEAD --stat

# 2. 自动检查常见问题
git diff main...HEAD | grep -n "TODO\|FIXME\|XXX\|debugger\|print("

# 3. 自动运行测试
python -m pytest 2>&1 | tail -20

# 4. 自动运行 Linter
ruff check . 2>&1 | head -30  # Python
# npm run lint                   # JS/TS
# cargo clippy                   # Rust

# 5. 自动生成审查报告
# （输出 structured review 给用户）
```

## 速查表

| 操作 | gh CLI | curl/git |
|------|--------|----------|
| 查看 PR 详情 | `gh pr view N` | `curl GET /pulls/N` |
| 查看 diff | `gh pr diff N` | `git diff main...HEAD` |
| 列出文件 | `gh pr diff N --name-only` | `git diff --name-only` |
| 检出新 PR | `gh pr checkout N` | `git fetch + checkout` |
| 批准 | `gh pr review N --approve` | `curl POST .../reviews -d '{"event":"APPROVE"}'` |
| 请求变更 | `gh pr review N --request-changes` | `curl POST .../reviews -d '{"event":"REQUEST_CHANGES"}'` |
| 评论 | `gh pr review N --comment` | `curl POST .../reviews -d '{"event":"COMMENT"}'` |
| 添加评论 | `gh pr comment N --body` | `curl POST .../issues/N/comments` |
| 内联评论 | `gh api .../pulls/N/comments` | `curl POST .../pulls/N/comments` |
| CI 状态 | `gh pr checks N` | `curl GET /commits/{sha}/check-runs` |

## 相关链接

- [[01-入门指南/github-auth]] — 认证基础
- [[github-pr-workflow]] — PR 工作流
- [[github-issues]] — Issue 管理
- [[../03-软件开发方法论/plan]] — 计划模式
- [[../03-软件开发方法论/test-driven-development]] — TDD 测试驱动开发
- [[../99-附录与速查/术语表|术语表]]
