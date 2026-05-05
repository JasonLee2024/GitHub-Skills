---
date: 2026-05-05
tags: [codex, openai, coding-agent, cli, pr-review]
source_skill: codex
category: 自主AI-Agent
---

# OpenAI Codex CLI 集成指南

## 概述

Codex 是 OpenAI 开发的自主编码代理 CLI 工具，能够读取文件、编写代码、运行命令和管理 Git 工作流。相比 Claude Code 的深度推理，Codex 更强调快速执行和与 OpenAI 生态的紧密集成。

Codex 的核心特点：
- **OpenAI 原生** — 直接使用 OpenAI API，深度优化
- **沙箱安全** — 文件变更在沙箱中执行，变更需要确认
- **YOLO 模式** — 极速模式，跳过所有审批
- **Git 依赖** — 必须在 Git 仓库中运行

## 安装与前提条件

### 安装

```bash
# 全局安装
npm install -g @openai/codex

# 验证安装
codex --version
```

### 前提条件

1. **OpenAI API 密钥** — 配置在环境变量中：
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```
2. **Git 仓库** — Codex **拒绝**在没有 Git 仓库的目录中运行
3. **Node.js** — Codex 使用 Node.js 运行时

## 基本使用

### 一次性任务

```bash
# 在项目中执行任务
codex exec "为设置页面添加暗黑模式切换"

# 指定模型
codex exec --model o4-mini "重构用户认证模块"
```

### 交互式会话

```bash
# 启动交互式会话
codex

# 带初始提示启动
codex "构建一个 Python 贪吃蛇游戏"
```

## 关键模式

### exec 模式（推荐）

`codex exec` 是执行一次性任务的主要方式，执行完毕后自动退出：

```bash
codex exec "添加用户登录 API 端点"
```

### 沙箱机制

默认情况下，Codex 在沙箱中运行：
- 文件变更在沙箱预览中显示
- 需要用户确认才能应用变更
- 可以通过 `--full-auto` 自动批准沙箱内变更

### --full-auto 模式

```bash
# 沙箱保护但自动批准变更
codex exec --full-auto "添加数据验证逻辑"
```

### --yolo 模式

```bash
# 极速模式：无沙箱、无审批
codex exec --yolo "修复所有类型错误"
```

`--yolo` 是最快的模式，也是**最危险**的模式 — 文件变更立即应用，不经过任何审批。

## CLI 标志参考

| 标志 | 效果 |
|------|------|
| `exec "prompt"` | 一次性执行，完成后退出 |
| `--full-auto` | 沙箱保护但自动批准变更 |
| `--yolo` | 无沙箱、无审批（最快最危险） |
| `--model <model>` | 指定模型（如 o4-mini） |
| `--no-commit` | 不自动提交 |
| `--target-dir <path>` | 指定目标目录 |
| `--install-hints` | 根据代码提示安装依赖 |

## 使用场景

### 代码重构

```bash
# 重构模块
codex exec "将 auth.py 中的认证逻辑提取到独立的 AuthService 类"

# 重命名和迁移
codex exec "将 snake_case 变量重命名为 camelCase"
```

### Bug 修复

```bash
# 根据错误信息修复
codex exec "修复 TypeError: 'NoneType' object is not subscriptable in api/handlers.py"

# 批量修复
codex exec "修复所有 ESLint 错误"
```

### 功能实现

```bash
# 实现新功能
codex exec "实现密码重置功能：发送重置邮件、验证令牌、更新密码"

# 构建完整应用
codex exec "构建一个 Markdown 笔记应用，使用 React + Express + SQLite"
```

### 代码审查

```bash
# 审查当前变更
codex exec "审查我的改动，检查潜在 bug 和安全问题"

# 审查与主分支的差异
codex exec "git diff main 中的改动，提供详细审查"
```

### 测试编写

```bash
codex exec "为 user_service.py 编写单元测试，覆盖率至少 80%"
```

### 依赖管理

```bash
codex exec "添加 lodash 和 moment.js 依赖，并在代码中使用"
```

## PR 审查工作流

### 临时克隆审查

为了安全审查，克隆到临时目录：

```bash
REVIEW=$(mktemp -d)
git clone https://github.com/user/repo.git $REVIEW
cd $REVIEW
gh pr checkout 42
codex review --base origin/main
```

### 直接审查

在本地仓库中直接审查：

```bash
codex exec "审查 PR #42 的改动：检查 bug、安全问题和测试覆盖率" --full-auto
```

## 批量问题修复

使用 Git Worktree 并行修复多个问题：

```bash
# 为每个 Issue 创建工作树
git worktree add -b fix/issue-78 /tmp/issue-78 main
git worktree add -b fix/issue-99 /tmp/issue-99 main

# 并行启动 Codex
codex --yolo exec "修复 Issue #78：登录页面 CSRF 漏洞。完成后提交。" &
codex --yolo exec "修复 Issue #99：API 缓存未过期问题。完成后提交。" &

# 等待所有任务完成
wait

# 创建 PR
cd /tmp/issue-78 && git push -u origin fix/issue-78 && gh pr create
cd /tmp/issue-99 && git push -u origin fix/issue-99 && gh pr create

# 清理
git worktree remove /tmp/issue-78
git worktree remove /tmp/issue-99
```

## 批量 PR 审查

```bash
# 获取所有 PR 引用
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'

# 并行审查多个 PR
codex exec "审查 PR #86：检查 git diff origin/main...origin/pr/86 中的安全问题和性能瓶颈" &
codex exec "审查 PR #87：检查 git diff origin/main...origin/pr/87 中的代码质量和测试覆盖" &

# 发布审查结果
gh pr comment 86 --body '<审查结果>'
gh pr comment 87 --body '<审查结果>'
```

## 临时项目（Scratch Work）

Codex 需要 Git 仓库才能运行。对于临时项目，创建临时目录：

```bash
# 创建临时 Git 仓库
cd $(mktemp -d)
git init
codex exec "用 Python 构建一个贪吃蛇游戏"
```

或者在子代理驱动的开发中使用：

```bash
WORK_DIR=$(mktemp -d)
cd $WORK_DIR
git init
codex exec --yolo "创建一个 React 待办事项应用"
```

## 后台运行（长时间任务）

```bash
# 后台启动
codex exec --full-auto "重构整个 auth 模块，需要读写大量文件" &

# 检查是否还在运行
ps aux | grep codex

# 等待完成
wait
```

## 结合 Hermes Agent 编排

当 Hermes Agent 需要委派编码任务给 Codex 时：

### 单次任务

```
terminal(command="codex exec '添加暗黑模式切换'", workdir="~/project", pty=true)
```

### 后台长时间任务

```
terminal(command="codex exec --full-auto '重构认证模块'", workdir="~/project", background=true, pty=true)

# 监视进度
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# 如果 Codex 提问，输入响应
process(action="submit", session_id="<id>", data="yes")

# 完成后杀死进程
process(action="kill", session_id="<id>")
```

### 并行任务

```
terminal(command="codex --yolo exec '修复 Issue #78'", workdir="/tmp/issue-78", background=true, pty=true)
terminal(command="codex --yolo exec '修复 Issue #99'", workdir="/tmp/issue-99", background=true, pty=true)
```

## 与其他 Agent 的比较

| 特性 | Codex | Claude Code | OpenCode |
|------|-------|-------------|----------|
| 提供商 | OpenAI 专用 | Anthropic 专用 | 多提供商 |
| 沙箱 | 内置沙箱 | 对话框确认 | 无沙箱 |
| YOLO 模式 | 是 | --dangerously-skip-permissions | 无 |
| Git 要求 | 是 | 否 | 否 |
| TUI | 基本 | 高级 TUI | 高级 TUI |
| 调试能力 | 强 | 极强 | 强 |
| 速度 | 快 | 中等（深度推理） | 快 |
| PR 审查 | 有 | 有 | 有 |
| Worktree | 手动 | 内置 | 手动 |

## 最佳实践

### 如何选择模式

| 场景 | 推荐模式 | 原因 |
|------|---------|------|
| 简单的文件编辑 | `exec` | 沙箱保护，安全有保障 |
| 构建新功能 | `exec --full-auto` | 自动批准，无需手动确认 |
| CI/CD 自动化 | `exec --yolo` | 完全自动化，最快速度 |
| 临时项目 | `git init + exec` | Codex 需要 Git 仓库 |
| PR 审查 | `exec` + 管道 | 快速获取审查结果 |

### 提示词技巧

1. **明确指定文件路径** — "修复 src/auth.py 第 42 行的 bug" 比 "修复 bug" 更高效
2. **指定完成后的操作** — "...完成后创建新分支并提交"
3. **使用步骤分解** — "先做 A，然后 B，最后 C"
4. **提供上下文** — "我们使用 FastAPI 和 SQLAlchemy，项目结构在..."

## 常见问题

### Codex 拒绝运行

```
错误：必须在 Git 仓库中运行
```

解决方法：确保当前目录是 Git 仓库，或创建临时仓库：
```bash
cd $(mktemp -d) && git init
```

### 沙箱变更未应用

检查是否使用了 `--full-auto` 或 `--yolo` 标志。默认 `exec` 模式下，沙箱变更需要手动确认。

### 模型响应慢

- 使用 `--model o4-mini` 获取更快的响应
- 拆分大型任务为多个小任务
- 尽量缩小工作范围

### SSH 环境下的 PTY 问题

在 SSH 中运行 Codex 时，确保分配了 PTY：
```bash
ssh -t user@host "codex exec '...'"
```

## 限制与注意事项

1. **必须使用 Git** — 这是 Codex 最严格的限制。任何编码任务都必须在 Git 仓库中进行
2. **OpenAI 专属** — 不能切换其他提供商
3. **无交互式 TUI** — 相比 Claude Code，Codex 的交互体验较简单
4. **沙箱延迟** — 沙箱机制在处理大量文件时会增加延迟
5. **YOLO 模式无撤回** — 使用 `--yolo` 时，错误的变更会立即写入

## 安全建议

1. **避免在敏感仓库中使用 `--yolo`** — 使用 `exec` 或 `--full-auto` 以保留审查机会
2. **审查沙箱预览** — 执行前检查文件变更列表
3. **限制工作目录** — 为每个任务使用独立的 Git Worktree
4. **不要共享 API 密钥** — 使用环境变量而非命令行参数
5. **定期审查 Codex 创建的提交** — 确保变更符合预期
