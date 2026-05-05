---
date: 2026-05-05
tags:
  - conventional-commits
  - git
  - commit-message
  - reference
  - cheatsheet
  - 附录与速查
category: 附录与速查
---

# Conventional Commits 速查表

> 约定式提交（Conventional Commits）规范完整速查，参考 [conventionalcommits.org](https://www.conventionalcommits.org/)。

## 基本格式

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## 类型 (Types)

| 类型 | 语义 | 是否出现在 CHANGELOG | Emoji |
|------|------|---------------------|-------|
| `feat` | ✨ 新功能 | ✅ | ✨ |
| `fix` | 🐛 Bug 修复 | ✅ | 🐛 |
| `docs` | 📝 文档变更 | ❌ | 📝 |
| `style` | 🎨 代码格式（空格、分号等） | ❌ | 🎨 |
| `refactor` | ♻️ 代码重构 | ❌ | ♻️ |
| `perf` | ⚡ 性能优化 | ✅ | ⚡ |
| `test` | ✅ 添加测试 | ❌ | ✅ |
| `chore` | 🔧 构建/工具/依赖 | ❌ | 🔧 |
| `ci` | 👷 CI 配置 | ❌ | 👷 |
| `build` | 📦 构建系统/外部依赖 | ❌ | 📦 |
| `revert` | ⏪ 回退提交 | ❌ | ⏪ |

## Scope (作用域)

```bash
# 指定影响范围（可选）
feat(auth): 添加 OAuth 2.0 登录
fix(api): 修复分页参数错误
docs(readme): 更新安装说明
refactor(db): 重构查询逻辑
perf(cache): 优化 Redis 缓存策略
test(payment): 添加支付单元测试
```

常见的 scope: `api`, `auth`, `db`, `ui`, `cache`, `config`, `deps`, `docs`, `test`, `ci`, `docker`

## 破坏性变更 (Breaking Changes)

```bash
# 方式 1: type 后加 !
feat!: 重写认证模块，不再支持 v1 API

# 方式 2: scope 后加 !
feat(api)!: 删除 v1 端点，仅保留 v2

# 方式 3: footer 中标记
feat: 升级 Node.js 到 20

BREAKING CHANGE: 最低 Node.js 版本从 16 提升至 20
```

## Footer

```bash
# 关闭 Issue
Closes #123
Fixes #456
Resolves #789

# 关联 Issue
Refs #234
Related to #567

# 破坏性变更标记
BREAKING CHANGE: 描述

# 新增/废弃
Reviewed-by: user
Signed-off-by: user
Co-authored-by: user <email>
```

## 完整示例

```bash
# 最小形式
feat: 添加用户登录

# 带 scope
feat(auth): 添加 OAuth 2.0 登录

# 带 body
fix: 修复登录页提交后页面不跳转

在 Safari 浏览器下，登录成功后的重定向被阻止。
改为使用 window.location.replace() 替代。

Closes #142

# 带破坏性变更
feat!: 升级 Python 依赖到 3.12

BREAKING CHANGE: 最低 Python 版本从 3.10 提升至 3.12
不再支持 Python 3.10 以下版本

# 长提交信息
perf(db): 优化首页查询性能

将 N+1 查询改为 JOIN 查询：
- 首页文章列表：从 20 次查询减少到 2 次
- 首页加载时间：从 1.2s 降低到 180ms

Closes #234
Refs #567
Reviewed-by: reviewer1
```

## 工作中的实践

### 关联 Issue

```bash
# 推荐: 在 footer 中关联
feat: 添加用户注册功能

Fixes #123

# 也接受: 在标题中引用
fix(auth): 修复 token 刷新 #456
```

### 撤销提交

```bash
# 撤销上一个 commit
git revert HEAD

# 提交信息自动生成
revert: feat: 添加用户登录

This reverts commit abc123def456.
```

### Git 钩子校验

```bash
#!/bin/bash
# .git/hooks/commit-msg

COMMIT_MSG=$(cat "$1")
PATTERN="^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\(.+\))?!?: .{1,}"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
  echo "❌ 提交信息不符合 Conventional Commits 规范"
  echo ""
  echo "格式: <type>(<scope>): <description>"
  echo "示例: feat(auth): 添加 OAuth 2.0 登录"
  echo "       fix(api): 修复分页参数错误"
  exit 1
fi

echo "✅ 提交信息格式正确"
```

## 自动生成 CHANGELOG

```bash
# Standard Version (npm)
npx standard-version

# git-cliff (Rust) — 更强大
git-cliff -o CHANGELOG.md

# commit-and-tag-version
npx commit-and-tag-version

# 手动分类生成
git log --oneline --no-decorate | while read hash msg; do
  type=$(echo "$msg" | cut -d: -f1 | cut -d'(' -f1)
  case "$type" in
    feat)  echo "✨ $msg" ;;
    fix)   echo "🐛 $msg" ;;
    perf)  echo "⚡ $msg" ;;
    *)     ;;
  esac
done
```

## 常见错误

```bash
# ❌ 错误
git commit -m "fixbug"
git commit -m "修改了一些东西"
git commit -m "WIP"

# ✅ 正确
git commit -m "fix: 修复空数组导致的崩溃"
git commit -m "feat(api): 添加用户列表分页支持"
git commit -m "refactor(auth): 提取 JWT 验证为独立中间件"
```

## 相关文档

- [[GitHub-CLI-命令大全]]
- [[术语表]]
