---
date: 2026-05-05
tags: [opencode, coding-agent, open-source, cli, multi-provider]
source_skill: opencode
category: 自主AI-Agent
---

# OpenCode CLI 集成指南

## 概述

OpenCode 是一个开源、提供商无关的 AI 编码代理 CLI，由 Anomaly 公司开发。它支持多种 LLM 提供商（OpenRouter、Anthropic、OpenAI、DeepSeek 等），提供高级 TUI 界面和灵活的 `run` 命令模式。

OpenCode 的核心优势：
- **提供商无关** — 不绑定任何特定提供商，可通过同一界面使用不同模型
- **开源透明** — 完整开源，代码可在 GitHub 查看和贡献
- **高级 TUI** — 现代化的终端界面，支持标签切换、命令面板
- **灵活的代理系统** — 支持多个代理角色（build、plan）

## 安装与认证

### 安装

```bash
# 方式一：npm 全局安装
npm i -g opencode-ai@latest

# 方式二：Homebrew 安装（macOS）
brew install anomalyco/tap/opencode

# 验证安装
opencode --version

# 检查路径（可能有多个版本冲突）
which -a opencode
```

### 认证配置

OpenCode 支持多种认证方式：

```bash
# 交互式登录
opencode auth login

# 列出已配置的提供商
opencode auth list

# 查看使用统计
opencode stats
opencode stats --days 7 --models anthropic/claude-sonnet-4
```

### 环境变量配置

根据不同提供商设置环境变量：

| 提供商 | 环境变量 |
|--------|---------|
| OpenRouter | `OPENROUTER_API_KEY` |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| Google Gemini | `GOOGLE_API_KEY` |
| 自定义 | 在配置文件中设置 |

## 一次性任务（run 模式）

`opencode run` 是执行一次性任务的首选方式。它不需要 PTY，执行完毕后自动退出。

### 基本用法

```bash
# 简单任务
opencode run "为 API 调用添加重试逻辑并更新测试"

# 附加上下文文件
opencode run "审查此配置的安全问题" -f config.yaml -f .env.example

# 显示模型思维过程
opencode run "调试 CI 失败的原因" --thinking

# 指定特定模型
opencode run "重构认证模块" --model openrouter/anthropic/claude-sonnet-4
```

### run 模式标志

| 标志 | 效果 |
|------|------|
| `run 'prompt'` | 一次性执行，完成后退出 |
| `--file <path>` / `-f` | 附加文件到消息中 |
| `--thinking` | 显示模型的思维过程 |
| `--model provider/model` | 强制使用特定模型 |
| `--variant <level>` | 推理深度（high、max、minimal） |
| `--format json` | 机器可读的输出/事件 |
| `--title <name>` | 为会话命名 |
| `--agent <name>` | 选择代理角色（build 或 plan） |

## 交互式 TUI 使用

### 启动交互式会话

```bash
opencode                     # 启动 TUI
opencode "实现 OAuth 认证"   # 带初始提示启动
```

### TUI 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Enter` | 提交消息（有时需要按两次） |
| `Tab` | 在代理之间切换（build/plan） |
| `Ctrl+P` | 打开命令面板 |
| `Ctrl+X L` | 切换会话 |
| `Ctrl+X M` | 切换模型 |
| `Ctrl+X N` | 新建会话 |
| `Ctrl+X E` | 打开编辑器 |
| `Ctrl+C` | 退出 OpenCode |

### 会话管理

```bash
# 继续最近的会话
opencode -c
opencode --continue

# 继续特定会话
opencode -s ses_abc123
opencode --session ses_abc123

# 列出所有会话
opencode session list
```

## 代理系统

OpenCode 内置了两种代理角色：

### Build 代理

默认代理，专注于代码编写和执行：
- 读取文件、编写代码
- 运行命令
- 修改项目结构
- 执行构建和测试

### Plan 代理

专注规划和分析的代理：
- 代码审查和分析
- 架构设计
- 制定实现计划
- 风险评估

通过 `Tab` 键在代理之间切换。

## PR 审查工作流

### 内置 PR 命令

```bash
# 审查 PR #42
opencode pr 42

# 指定基础分支
opencode pr 42 --base staging
```

### 临时克隆审查

```bash
REVIEW=$(mktemp -d)
git clone https://github.com/user/repo.git $REVIEW
cd $REVIEW
opencode run "审查此 PR 与 main 分支的差异。报告 bug、安全风险、测试缺口和代码风格问题。" \
  -f $(git diff origin/main --name-only | head -20 | tr '\n' ' ')
```

### 审查提示词示例

```bash
opencode run "请审查当前代码变更：
1. 检查安全漏洞（注入、XSS、认证缺陷）
2. 检查性能问题（N+1 查询、不必要的循环）
3. 检查测试覆盖（缺少边界情况测试）
4. 检查代码风格（是否符合项目规范）
5. 给出 1-10 分评分和改进建议"
```

## 后台运行与监视

### 启动后台任务

```bash
# 后台启动 TUI（需要 PTY）
opencode &
# 或通过 process 工具启动

# 后台启动 run 任务
opencode run "长时间重构任务..." &
```

### 监视进度

```bash
# 检查进程
ps aux | grep opencode

# 等待完成
wait

# 查看日志（如果有）
cat ~/.opencode/logs/*.log
```

## 并行任务执行

使用独立工作目录避免冲突：

```bash
# 并行修复两个 Issue
cd /tmp/issue-101 && opencode run "修复 Issue #101 并提交" &
cd /tmp/issue-102 && opencode run "添加解析器回归测试并提交" &

# 等待所有完成
wait
```

### Git Worktree 并行

```bash
# 创建工作树
git worktree add -b fix/auth /tmp/fix-auth main
git worktree add -b fix/cache /tmp/fix-cache main

# 并行执行
cd /tmp/fix-auth && opencode run "修复认证令牌刷新问题" --thinking &
cd /tmp/fix-cache && opencode run "修复缓存未过期问题" --thinking &

# 等待进度
sleep 60

# 检查状态
cd /tmp/fix-auth && git log --oneline -3
cd /tmp/fix-cache && git log --oneline -3
```

## 多提供商策略

OpenCode 的优势在于可以灵活切换提供商：

### 按任务选择模型

```bash
# 简单任务使用快速便宜的模型
opencode run "格式化代码" --model openrouter/anthropic/claude-haiku

# 复杂推理使用更强模型
opencode run "设计数据库架构" --model openrouter/anthropic/claude-sonnet-4

# 编码任务使用编码优化模型
opencode run "实现 WebSocket 支持" --model openrouter/openai/o4-mini
```

### 提供商回退

当某个提供商不可用时，OpenCode 可以自动回退到其他已配置的提供商：
- 配置多个 API 密钥
- `opencode auth list` 查看所有可用的提供商
- 自动轮换使用不同的提供商

## 结合 Hermes Agent 编排

### 单次任务

```
# run 模式无需 PTY
terminal(command="opencode run '为 API 调用添加重试逻辑'", workdir="~/project")

# 附加上下文
terminal(command="opencode run '审查安全配置' -f config.yaml", workdir="~/project")
```

### 交互式后台

```
# 启动 TUI 在后台
terminal(command="opencode", workdir="~/project", background=true, pty=true)

# 发送提示
process(action="submit", session_id="<id>", data="实现 OAuth 刷新流程并添加测试")

# 监视
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# 发送后续提示
process(action="submit", session_id="<id>", data="现在添加令牌过期的错误处理")

# 退出（使用 Ctrl+C，不要用 /exit）
process(action="write", session_id="<id>", data="\x03")
```

### 并行任务

```
terminal(command="opencode run '修复 Issue #101'", workdir="/tmp/issue-101", background=true, pty=true)
terminal(command="opencode run '添加回归测试'", workdir="/tmp/issue-102", background=true, pty=true)
```

## 与其他 Agent 的比较

| 特性 | OpenCode | Claude Code | Codex |
|------|----------|-------------|-------|
| 提供商 | 多提供商 | Anthropic | OpenAI |
| 开源 | 是 | 否 | 否 |
| TUI | 高级 TUI | 高级 TUI | 简单 |
| run 模式 | 是 | -p（print） | exec |
| 代理角色 | build/plan | 自定义子代理 | 单一 |
| 命令面板 | Ctrl+P | 无 | 无 |
| 会话列表 | `session list` | 自动保存 | 有限 |
| PR 命令 | `pr <number>` | `--from-pr` | 手动 |
| 统计 | `stats` | `/cost` | 有限 |

## 最佳实践

### 如何选择运行模式

| 场景 | 推荐方式 | 原因 |
|------|---------|------|
| 简单编码任务 | `opencode run` | 无需 PTY，自动退出 |
| 多轮迭代 | 交互式 TUI | 支持后续提示 |
| 代码审查 | `opencode pr` 或 `run` | 灵活选择 |
| 长时间重构 | 后台 run | 不阻塞终端 |
| 并行任务 | 多个后台 run | 独立工作目录 |

### 提示词技巧

1. **指定文件范围** — "在 src/api/ 目录下添加用户管理端点"
2. **提供验收标准** — "添加后运行测试，确保所有测试通过"
3. **分步指导** — "先创建数据模型，然后添加 CRUD 接口，最后编写测试"
4. **指定模型** — 复杂任务使用更强模型，简单任务使用更快的模型

### 推理深度选择

```bash
# 最小推理：快速、便宜
opencode run "给所有函数添加类型注解" --variant minimal

# 高推理：适合复杂分析
opencode run "分析数据库查询性能瓶颈" --variant high

# 最大推理：适合关键决策
opencode run "设计分布式系统的数据分片策略" --variant max
```

## 常见问题与陷阱

### `/exit` 不是有效命令

**问题**：在 TUI 中输入 `/exit` 会打开代理选择器对话框，而不是退出。

**解决方法**：使用 `Ctrl+C` 退出 TUI，或关闭终端窗口。

### PATH 冲突

**问题**：系统中可能存在多个版本的 OpenCode。

**解决方法**：使用 `which -a opencode` 检查所有路径，必要时指定完整路径：
```bash
$HOME/.opencode/bin/opencode run "..."
```

### Enter 键需要按两次

在 TUI 中，第一次 Enter 完成文本输入，第二次 Enter 提交消息。

### 共享工作目录冲突

**问题**：多个 OpenCode 会话共享同一工作目录可能导致冲突。

**解决方法**：始终为每个任务使用独立的目录或 Git Worktree。

### 长时间运行无响应

1. 检查进程是否仍在运行：`ps aux | grep opencode`
2. 检查是否有对话框等待输入
3. 如果卡死，使用 `kill` 强制结束

## 会话与成本管理

### 查看会话历史

```bash
# 列出所有会话
opencode session list

# 继续特定会话
opencode -s ses_abc123
```

### 成本跟踪

```bash
# 查看总体统计
opencode stats

# 按时间范围和模型过滤
opencode stats --days 30 --models openrouter/anthropic/claude-sonnet-4
```

## 验证与烟雾测试

```bash
# 烟雾测试
opencode run "仅回复：OPENCODE_SMOKE_OK"

# 成功标准：
# - 输出包含 OPENCODE_SMOKE_OK
# - 命令正常退出
# - 无提供商/模型错误
```

## 高级技巧

### 自定义代理提示

通过 `-f` 附加详细的系统提示文件：

```bash
cat > /tmp/system-prompt.md << 'EOF'
你是专门优化 React 组件性能的专家。
总是检查：
1. 不必要的重新渲染
2. 大列表的虚拟化
3. 状态管理的优化机会
EOF

opencode run "优化仪表盘页面性能" -f /tmp/system-prompt.md
```

### 使用 --attach 连接运行中的服务器

```bash
# 在服务器上启动 OpenCode
opencode --server

# 在另一个终端连接
opencode --attach http://remote-server:8080
```

### 调试模式

```bash
# 完整调试输出
opencode run "调试数据库连接问题" --format json
```
