---
date: 2026-05-05
tags: [claude-code, coding-agent, anthropic, pr-review, cli]
source_skill: claude-code
category: 自主AI-Agent
---

# Claude Code CLI 指南

## 概述

Claude Code 是 Anthropic 开发的自主编码代理 CLI 工具。它可以在终端中独立运行，通过工具调用来读取文件、编写代码、执行命令、管理 Git 工作流和生成 PR 审查。Claude Code v2.x 是功能完备的 TUI（终端用户界面）应用，支持交互式会话和一次性打印模式。

Claude Code 的主要优势在于其深度推理能力、对大规模代码库的理解能力以及与 GitHub 工作流的原生集成。它特别适合复杂的代码审查、大规模重构和需要多轮迭代的开发任务。

## 安装与认证

### 安装

```bash
# 全局安装
npm install -g @anthropic-ai/claude-code

# 验证安装
claude --version          # 需要 v2.x 以上
claude doctor             # 运行健康检查
```

### 认证

```bash
# 浏览器 OAuth 认证（推荐）
claude auth login

# Console 模式（API Key 计费）
claude auth login --console

# SSO 登录（企业用户）
claude auth login --sso

# 检查认证状态
claude auth status                 # JSON 格式
claude auth status --text           # 人类可读格式

# 设置 API 密钥（非交互环境）
export ANTHROPIC_API_KEY="sk-ant-..."
```

### 更新

```bash
claude update            # 更新到最新版
claude upgrade           # 同上
claude install stable    # 安装稳定版
claude install latest    # 安装最新版
```

## 交互式使用

### 启动会话

```bash
claude                   # 启动交互式 REPL
claude "任务描述"        # 启动带初始提示的 REPL
```

### 工作模式

在交互式会话中，Claude Code 通过 Status Bar 显示当前模式：

- 正常模式 — 每个操作需要用户确认
- 自动接受模式 — 自动批准文件编辑
- 计划模式 — 只制定计划不执行

使用 `Shift+Tab` 循环切换模式。

### 输入前缀

交互式输入支持多种前缀：

- `!npm test` — 直接执行 Bash 命令，跳过 AI 处理
- `@./src/api/` — 引用文件/目录（带自动补全）
- `# Use 2-space indentation` — 快速添加到 CLAUDE.md 记忆
- `/help` — 斜杠命令

### 多行输入

| 按键 | 效果 |
|------|------|
| `\` + `Enter` | 快速换行 |
| `Shift+Enter` | 换行（备选） |
| `Ctrl+J` | 换行（备选） |

### 键盘快捷键

**一般控制**
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+C` | 取消当前输入或生成 |
| `Ctrl+D` | 退出会话 |
| `Ctrl+R` | 反向搜索命令历史 |
| `Ctrl+B` | 将正在运行的任务放入后台 |
| `Ctrl+V` | 粘贴图片到对话中 |
| `Ctrl+O` | 查看 Claude 的思维过程 |
| `Ctrl+G` / `Ctrl+X Ctrl+E` | 在外部编辑器中打开提示 |
| `Esc Esc` | 回退对话或代码状态 / 总结 |

**模式切换**
| 快捷键 | 功能 |
|--------|------|
| `Shift+Tab` | 循环切换权限模式 |
| `Alt+P` | 切换模型 |
| `Alt+T` | 切换思维模式 |
| `Alt+O` | 切换快速模式 |

## Print 模式（-p）

Print 模式是一次性任务执行模式，执行完毕后自动退出，无需用户交互。这是 CI/CD 自动化和脚本集成的最佳选择。

### 基本用法

```bash
claude -p "为所有 API 调用添加错误处理"
```

### 结构化 JSON 输出

```bash
claude -p "分析 auth.py 的安全问题" --output-format json --max-turns 5
```

返回 JSON 对象，包含：
- `session_id` — 可恢复会话的 ID
- `num_turns` — 代理循环计数
- `total_cost_usd` — 费用跟踪
- `subtype` — 成功/错误检测（`success`、`error_max_turns`、`error_budget`）
- `usage` — 输入/输出 token 使用详情

### 实时流式输出

```bash
claude -p "写一个总结" --output-format stream-json --verbose --include-partial-messages
```

结合 jq 过滤实时文本：
```bash
claude -p "解释 X" --output-format stream-json --verbose --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

### 双向流式

```bash
claude -p "任务" --input-format stream-json --output-format stream-json --replay-user-messages
```

### 管道输入

```bash
# 分析文件
cat src/auth.py | claude -p "审查这段代码中的错误" --max-turns 1

# 多文件分析
cat src/*.py | claude -p "找出所有 TODO 注释" --max-turns 1

# 分析差异
git diff HEAD~3 | claude -p "总结这些变更" --max-turns 1
```

### 会话延续

```bash
# 恢复最近的会话
claude -p "上次做了什么？" --continue --max-turns 1

# 恢复指定会话
claude -p "继续添加连接池" --resume <session_id> --max-turns 5

# 分支会话（新 ID，保留历史）
claude -p "尝试不同的方法" --resume <id> --fork-session --max-turns 10
```

### JSON Schema 结构化提取

```bash
claude -p "列出 src/ 中所有函数" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}' \
  --max-turns 5
```

### 裸模式（CI/脚本）

```bash
claude --bare -p "运行所有测试并报告失败" --allowedTools "Read,Bash" --max-turns 10
```

`--bare` 跳过钩子、插件、MCP 发现和 CLAUDE.md 加载，启动最快。需要 `ANTHROPIC_API_KEY`。

## CLI 标志参考

### 会话与环境

| 标志 | 效果 |
|------|------|
| `-p, --print` | 非交互式一次性模式 |
| `-c, --continue` | 恢复当前目录最近的会话 |
| `-r, --resume <id>` | 恢复指定会话 |
| `--fork-session` | 分支会话（新 ID） |
| `--session-id <uuid>` | 使用指定 UUID |
| `--no-session-persistence` | 不保存会话到磁盘 |
| `--add-dir <paths>` | 添加额外工作目录 |
| `-w, --worktree [name]` | 在隔离的 git worktree 中运行 |
| `--tmux` | 为 worktree 创建 tmux 会话 |
| `--ide` | 自动连接 IDE |
| `--from-pr [number]` | 恢复与 PR 关联的会话 |

### 模型与性能

| 标志 | 效果 |
|------|------|
| `--model <alias>` | 模型选择：sonnet、opus、haiku |
| `--effort <level>` | 推理深度：low、medium、high、max、auto |
| `--max-turns <n>` | 代理循环上限（仅 print 模式） |
| `--max-budget-usd <n>` | API 费用上限（仅 print 模式） |
| `--fallback-model <model>` | 超载时自动降级模型 |
| `--betas <betas>` | Beta API 功能 |

### 权限与安全

| 标志 | 效果 |
|------|------|
| `--dangerously-skip-permissions` | 自动批准所有工具使用 |
| `--allow-dangerously-skip-permissions` | 启用绕过选项 |
| `--permission-mode <mode>` | 权限模式选择 |
| `--allowedTools <tools>` | 白名单工具 |
| `--disallowedTools <tools>` | 黑名单工具 |

### 输出格式

| 标志 | 效果 |
|------|------|
| `--output-format <fmt>` | text、json、stream-json |
| `--input-format <fmt>` | text 或 stream-json |
| `--json-schema <schema>` | 强制 JSON 结构化输出 |
| `--verbose` | 逐轮详细输出 |

### 系统提示与上下文

| 标志 | 效果 |
|------|------|
| `--append-system-prompt <text>` | 追加到默认系统提示 |
| `--system-prompt <text>` | 替换整个系统提示 |
| `--bare` | 跳过所有额外加载 |
| `--agents '<json>'` | 动态定义子代理 |
| `--mcp-config <path>` | 加载 MCP 服务器配置 |
| `--strict-mcp-config` | 仅使用指定的 MCP 配置 |

## 交互式会话命令

### 会话与控制

| 命令 | 用途 |
|------|------|
| `/help` | 显示所有命令 |
| `/compact [focus]` | 压缩上下文节省令牌 |
| `/clear` | 清除对话历史 |
| `/context` | 可视化上下文使用情况 |
| `/cost` | 查看令牌使用和成本 |
| `/resume` | 切换到其他会话 |
| `/rewind` | 回退到上一个检查点 |
| `/btw <question>` | 不影响主任务的旁路提问 |
| `/status` | 版本和连接信息 |
| `/exit` | 结束会话 |

### 开发与审查

| 命令 | 用途 |
|------|------|
| `/review` | 请求代码审查 |
| `/security-review` | 安全分析审查 |
| `/plan [description]` | 进入计划模式 |
| `/loop [interval]` | 定时重复任务 |

### 配置与工具

| 命令 | 用途 |
|------|------|
| `/model [model]` | 切换模型 |
| `/effort [level]` | 设置推理深度 |
| `/init` | 创建 CLAUDE.md 项目文件 |
| `/memory` | 编辑 CLAUDE.md |
| `/config` | 交互式配置 |
| `/permissions` | 查看/更新工具权限 |
| `/agents` | 管理子代理 |
| `/mcp` | 管理 MCP 服务器 |
| `/voice` | 语音模式 |
| `/release-notes` | 查看版本发布说明 |

## CLAUDE.md 项目配置

Claude Code 自动从项目根目录加载 `CLAUDE.md` 文件，作为项目的长期记忆。

### 基本结构

```markdown
# 项目：My API

## 架构
- FastAPI 后端 + SQLAlchemy ORM
- PostgreSQL 数据库、Redis 缓存
- pytest 测试，覆盖率目标 90%

## 关键命令
- `make test` — 运行完整测试套件
- `make lint` — ruff + mypy
- `make dev` — 在 :8000 启动开发服务器

## 代码规范
- 所有公共函数需要类型注解
- 文档字符串使用 Google 风格
- Python 使用 4 空格缩进，YAML 使用 2 空格
- 禁止通配符导入
```

### 规则目录

对于大型项目，使用规则目录代替单个 CLAUDE.md：

- **项目规则**：`.claude/rules/*.md` — 团队共享，git 跟踪
- **用户规则**：`~/.claude/rules/*.md` — 个人全局规则

每个 `.md` 文件作为额外上下文加载。

### 自动记忆

Claude 自动在 `~/.claude/projects/<project>/memory/` 中存储项目上下文：
- 限制：25KB 或 200 行
- 跨会话累积的项目笔记

## 自定义子代理

定义专业化代理处理特定任务。

### 位置优先级

1. `.claude/agents/` — 项目级，团队共享
2. `--agents` CLI 标志 — 会话级，动态
3. `~/.claude/agents/` — 用户级，个人

### 创建代理

```markdown
# .claude/agents/security-reviewer.md
---
name: security-reviewer
description: 安全代码审查
model: opus
tools: [Read, Bash]
---
你是一个高级安全工程师。审查代码中是否存在：
- 注入漏洞（SQL、XSS、命令注入）
- 认证/授权缺陷
- 代码中的密钥泄露
- 不安全的反序列化
```

调用方式：`@security-reviewer 审查 auth 模块`

## 钩子系统

在事件上自动触发操作，配置在 `.claude/settings.json` 中。

### 所有钩子类型

| 钩子 | 触发时机 | 常见用途 |
|------|----------|---------|
| `UserPromptSubmit` | Claude 处理用户提示前 | 输入验证、日志 |
| `PreToolUse` | 工具执行前 | 安全门禁 |
| `PostToolUse` | 工具执行后 | 自动格式化、运行 linter |
| `Stop` | Claude 完成响应后 | 完成日志 |
| `SessionStart` | 会话开始时 | 加载开发上下文 |

### 钩子配置示例

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write(*.py)",
      "hooks": [{"type": "command", "command": "ruff check --fix $CLAUDE_FILE_PATHS"}]
    }],
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "if echo \"$CLAUDE_TOOL_INPUT\" | grep -q 'rm -rf'; then echo '已阻止！' && exit 2; fi"}]
    }]
  }
}
```

### 钩子环境变量

| 变量 | 内容 |
|------|------|
| `CLAUDE_PROJECT_DIR` | 当前项目路径 |
| `CLAUDE_FILE_PATHS` | 正在修改的文件 |
| `CLAUDE_TOOL_INPUT` | JSON 格式的工具参数 |

## MCP 集成

添加外部工具服务器以连接数据库、API 和服务。

### 添加 MCP 服务器

```bash
claude mcp add -s user github -- npx @modelcontextprotocol/server-github
claude mcp add -s local postgres -- npx @anthropic-ai/server-postgres --connection-string postgresql://localhost/mydb
claude mcp add puppeteer -- npx @anthropic-ai/server-puppeteer
```

### MCP 作用域

| 标志 | 范围 | 存储位置 |
|------|------|---------|
| `-s user` | 全局（所有项目） | `~/.claude.json` |
| `-s local` | 当前项目（个人） | `.claude/settings.local.json` |
| `-s project` | 当前项目（团队） | `.claude/settings.json` |

### CI 模式下的 MCP

```bash
claude --bare -p "查询数据库" --mcp-config mcp-servers.json --strict-mcp-config
```

### MCP 限制与调优

- **工具描述**：每个服务器 2KB 上限
- **结果大小**：可通过 `maxResultSizeChars` 扩展至 **500K** 字符
- **输出令牌**：`export MAX_MCP_OUTPUT_TOKENS=50000`

## PR 审查工作流

### 快速审查（Print 模式）

```bash
cd /path/to/repo && git diff main...feature-branch | claude -p "审查此 diff：检查 bug、安全问题和代码风格" --max-turns 1
```

### 深度审查（交互式 + Worktree）

```bash
claude -w pr-review --tmux
```

创建隔离的 git worktree（`.claude/worktrees/pr-review`）并启动 tmux 会话。

### 按编号审查 PR

```bash
claude -p "彻底审查此 PR" --from-pr 42 --max-turns 10
```

## 并行 Claude 实例

同时运行多个独立的 Claude 任务：

```bash
# 任务 1：修复后端
tmux new-session -d -s task1 -x 140 -y 40
tmux send-keys -t task1 'cd ~/project && claude -p "修复 src/auth.py 中的认证 bug" --allowedTools "Read,Edit" --max-turns 10' Enter

# 任务 2：编写测试
tmux new-session -d -s task2 -x 140 -y 40
tmux send-keys -t task2 'cd ~/project && claude -p "为 API 端点编写集成测试" --allowedTools "Read,Write,Bash" --max-turns 15' Enter

# 监视所有任务
sleep 30 && for s in task1 task2; do echo '=== '$s' ==='; tmux capture-pane -t $s -p -S -5; done
```

## 环境变量

| 变量 | 效果 |
|------|------|
| `ANTHROPIC_API_KEY` | API 密钥 |
| `CLAUDE_CODE_EFFORT_LEVEL` | 默认推理深度 |
| `MAX_THINKING_TOKENS` | 限制思维令牌数 |
| `MAX_MCP_OUTPUT_TOKENS` | MCP 输出上限 |
| `CLAUDE_CODE_NO_FLICKER=1` | 消除终端闪烁 |

## 成本与性能优化

1. **设置 `--max-turns`** — 防止无限制循环，从 5-10 次开始
2. **设置 `--max-budget-usd`** — API 费用上限（最少 ~$0.05）
3. **简单任务用 `--effort low`** — 更快更便宜
4. **CI/脚本用 `--bare`** — 跳过插件/钩子发现开销
5. **审查用 `--allowedTools`** — 限制工具范围
6. **大上下文用 `/compact`** — 主动压缩节省令牌
7. **管道输入代替文件读取** — Claude 直接分析已知内容
8. **简单任务用 `--model haiku`** — 更便宜
9. **新会话处理不同任务** — 新鲜上下文更高效

## 自定义斜杠命令

创建 `.claude/commands/<name>.md`（项目共享）或 `~/.claude/commands/<name>.md`（个人）：

```markdown
# .claude/commands/deploy.md
运行部署流水线：
1. 运行所有测试
2. 构建 Docker 镜像
3. 推送到注册表
4. 更新 $ARGUMENTS 环境（默认：staging）
```

用法：`/deploy production` — `$ARGUMENTS` 替换为用户输入。

## 技能（自然语言调用）

在 `.claude/skills/` 中的技能是 Markdown 指南，当任务匹配时 Claude 会自动调用：

```markdown
# .claude/skills/database-migration.md
当被要求创建或修改数据库迁移时：
1. 使用 Alembic 生成迁移
2. 始终创建回滚函数
3. 在本地数据库副本上测试迁移
```

## 常见问题与陷阱

1. **Print 模式优先** — 单次任务使用 `-p` 模式，无需处理对话框
2. **交互模式需要 tmux** — Claude Code 是完整 TUI 应用
3. **`--dangerously-skip-permissions` 默认是"退出"** — 需按 Down 再 Enter
4. **`--max-budget-usd` 最少 ~$0.05** — 系统提示缓存创建成本
5. **`--max-turns` 仅 print 模式有效** — 交互式会话中无效
6. **会话恢复需要同一目录** — `--continue` 找当前工作目录的最近会话
7. **信任对话框只出现一次** — 每个目录首次访问后缓存
8. **tmux 后台会话会持续存在** — 完成后务必清理
9. **上下文退化是真实存在的** — 超过 70% 上下文窗口后质量明显下降

## 监控交互式会话

### 读取 TUI 状态

通过 `tmux capture-pane` 监控 Claude 状态：

- `❯` 在底部 = 等待用户输入
- `●` 行 = Claude 正在使用工具
- `⏵⏵ bypass permissions on` = 权限模式状态
- `ctrl+o to expand` = 工具输出被截断

### 上下文窗口健康

使用 `/context` 查看颜色网格：
- **< 70%** — 正常操作，高精度
- **70-85%** — 精度开始下降，考虑 `/compact`
- **> 85%** — 幻觉风险显著增加
