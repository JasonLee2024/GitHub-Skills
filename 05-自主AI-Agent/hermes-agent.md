---
date: 2026-05-05
tags: [hermes-agent, agent, cli, gateway, skills, multi-agent]
source_skill: hermes-agent
category: 自主AI-Agent
---

# Hermes Agent 完全指南

## 概述

Hermes Agent 是由 Nous Research 开发的开源 AI 代理框架，可在终端、即时通讯平台和 IDE 中运行。它属于与 Claude Code（Anthropic）、Codex（OpenAI）和 OpenCode 同一类别的自主编码和任务执行代理——通过工具调用来与你的系统交互。Hermes 支持任何 LLM 提供商（OpenRouter、Anthropic、OpenAI、DeepSeek、本地模型等 20+ 家），并可在 Linux、macOS 和 WSL 上运行。

### Hermes 的独特之处

**自我进化的技能系统** — Hermes 通过将可复用的流程保存为技能来从经验中学习。当它解决复杂问题、发现工作流或得到纠正时，可以将这些知识持久化为技能文档，并在未来的对话中加载。技能会不断积累，使代理在你特定的任务和环境中变得越来越高效。

**跨会话持久记忆** — 记住你是谁、你的偏好、环境细节和经验教训。可插拔的记忆后端（内置、Honcho、Mem0 等）让你选择记忆的工作方式。

**多平台网关** — 同一个代理可在 Telegram、Discord、Slack、WhatsApp、Signal、Matrix、Email 等 10+ 平台上运行，并在所有平台上拥有完整的工具访问权限，而不仅仅是聊天。

**提供商无关** — 无需更改其他任何内容即可在对话中途切换模型和提供商。凭证池会自动在多个 API 密钥之间轮换。

**配置文件系统** — 运行多个独立的 Hermes 实例，每个实例拥有独立的配置、会话、技能和记忆。

**可扩展** — 插件系统、MCP 服务器、自定义工具、Webhook 触发器、定时任务和完整的 Python 生态系统。

人们使用 Hermes 进行软件开发、研究、系统管理、数据分析、内容创作、智能家居控制等任何受益于具有持久上下文的 AI 代理并拥有完整系统访问权限的任务。

## 快速入门

### 安装

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 交互式聊天（默认模式）
hermes

# 单次查询
hermes chat -q "什么是巴黎的首都？"

# 配置向导
hermes setup

# 切换模型/提供商
hermes model

# 健康检查
hermes doctor
```

### 首次使用流程

1. 安装后运行 `hermes setup` 进入配置向导
2. 选择或跳过各个配置部分（模型 → 终端 → 网关 → 工具 → 代理）
3. 或运行 `hermes model` 从交互式选取器中选择模型和提供商
4. 设置 API 密钥：`hermes config env-path` 找到 `.env` 文件位置，然后添加密钥
5. 运行 `hermes` 开始聊天

## CLI 参考

### 全局标志

```
hermes [flags] [command]

  --version, -V             显示版本
  --resume, -r SESSION      通过 ID 或标题恢复会话
  --continue, -c [NAME]     通过名称恢复，或恢复最近的会话
  --worktree, -w            隔离的 git worktree 模式（并行代理）
  --skills, -s SKILL        预加载技能（逗号分隔或重复使用标志）
  --profile, -p NAME        使用命名配置文件
  --yolo                    跳过危险命令审批
  --pass-session-id         将会话 ID 包含在系统提示中
```

不带子命令时默认进入 `chat` 模式。

### 聊天命令

```bash
hermes chat [flags]
  -q, --query TEXT          单次查询，非交互模式
  -m, --model MODEL         指定模型
  -t, --toolsets LIST       逗号分隔的工具集
  --provider PROVIDER       强制指定提供商
  -v, --verbose             详细输出
  -Q, --quiet               隐藏横幅、加载动画和工具预览
  --checkpoints             启用文件系统检查点（/rollback 命令）
  --source TAG              会话来源标签（默认：cli）
```

### 配置管理

```bash
hermes setup [section]      交互式向导（model|terminal|gateway|tools|agent）
hermes model                交互式模型/提供商选择器
hermes config               查看当前配置
hermes config edit          在 $EDITOR 中打开 config.yaml
hermes config set KEY VAL   设置配置值
hermes config path          打印 config.yaml 路径
hermes config env-path      打印 .env 路径
hermes config check         检查缺失或过时的配置
hermes config migrate       用新选项更新配置
hermes login [--provider P] OAuth 登录
hermes logout               清除存储的认证信息
hermes doctor [--fix]       检查依赖和配置
hermes status [--all]       显示组件状态
```

### 工具与技能管理

```bash
hermes tools                交互式工具启用/禁用（curses UI）
hermes tools list           显示所有工具及其状态
hermes tools enable NAME    启用某个工具集
hermes tools disable NAME   禁用某个工具集

hermes skills list          列出已安装的技能
hermes skills search QUERY  搜索技能中心
hermes skills install ID    安装技能
hermes skills inspect ID    预览但不安装
hermes skills config        按平台启用/禁用技能
hermes skills check         检查更新
hermes skills update        更新过时的技能
hermes skills uninstall N   移除中心技能
hermes skills publish PATH  发布到注册表
hermes skills browse        浏览所有可用技能
hermes skills tap add REPO  添加 GitHub 仓库作为技能来源
```

### MCP 服务器

```bash
hermes mcp serve            将 Hermes 作为 MCP 服务器运行
hermes mcp add NAME         添加 MCP 服务器（--url 或 --command）
hermes mcp remove NAME      移除 MCP 服务器
hermes mcp list             列出已配置的服务器
hermes mcp test NAME        测试连接
hermes mcp configure NAME   切换工具选择
```

### 会话管理

```bash
hermes sessions list        列出最近的会话
hermes sessions browse      交互式选取器
hermes sessions export OUT  导出为 JSONL
hermes sessions rename ID T 重命名会话
hermes sessions delete ID   删除会话
hermes sessions prune       清理旧会话（--older-than N 天）
hermes sessions stats       会话存储统计信息
```

## 架构深度解析

### 核心循环

Hermes 的运行基于一个简洁但强大的循环：

```
run_conversation():
  1. 构建系统提示（包含技能、记忆、配置文件上下文）
  2. 当迭代次数 < max_turns 时循环：
     a. 调用 LLM（OpenAI 格式的消息 + 工具模式）
     b. 如果有 tool_calls → 通过 handle_function_call() 分发每个调用
        → 追加结果 → 继续循环
     c. 如果是文本响应 → 返回
  3. 接近 token 限制时自动触发上下文压缩
```

### 系统提示构建

系统提示由多个组件动态构建：

1. **核心系统提示** — 定义 Hermes 的身份和基本行为
2. **技能内容** — 根据当前任务加载相关的技能文档
3. **用户画像** — 从记忆系统恢复的用户偏好
4. **环境信息** — 操作系统、工作目录、时间等
5. **配置指令** — 来自 config.yaml 的自定义行为
6. **平台适配** — 根据终端类型或网关平台调整输出格式

### 工具调度

每个工具通过 `tools/registry.py` 中的中央注册表注册：

```python
registry.register(
    name="example_tool",
    toolset="example",
    schema={"name": "example_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: example_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,
    requires_env=["EXAMPLE_API_KEY"],
)
```

工具自动发现：任何 `tools/*.py` 文件中包含顶层 `registry.register()` 调用都会被自动导入，无需手动注册。

所有处理器必须返回 JSON 字符串。路径应使用 `get_hermes_home()` 获取，永远不要硬编码 `~/.hermes`。

### 上下文压缩

当上下文窗口使用率达到阈值时（默认 50%），Hermes 自动触发压缩：

- **压缩策略**：总结早期对话的轮次，保留关键决策和结果
- **目标比例**：将上下文压缩到原始大小的 20%（可配置）
- **手动压缩**：在会话中输入 `/compress` 可手动触发
- **保护内容**：技能内容、用户画像和最近的轮次不会被压缩

## 配置详解

### 配置文件位置

```
~/.hermes/config.yaml       主配置文件
~/.hermes/.env              API 密钥和秘密信息
~/.hermes/skills/           已安装的技能
~/.hermes/sessions/         会话记录
~/.hermes/logs/             网关和错误日志
~/.hermes/auth.json         OAuth 令牌和凭证池
```

配置文件使用 `~/.hermes/profiles/<name>/` 结构，布局相同。

### 配置段说明

**模型配置**
```yaml
model:
  default: openrouter/anthropic/claude-sonnet-4
  provider: openrouter
  base_url: ""
  api_key: ""
  context_length: 200000
```

**代理行为**
```yaml
agent:
  max_turns: 90            # 单次对话最大轮次
  tool_use_enforcement:    # 工具使用强制策略
```

**终端后端**
```yaml
terminal:
  backend: local           # local | docker | ssh | modal
  cwd: ""
  timeout: 180             # 命令超时秒数
```

**上下文压缩**
```yaml
compression:
  enabled: true
  threshold: 0.50          # 触发压缩的阈值（上下文使用率）
  target_ratio: 0.20       # 压缩目标比例
```

**显示设置**
```yaml
display:
  skin: default            # CLI 主题
  tool_progress: true      # 显示工具调用进度
  show_reasoning: false    # 显示模型推理过程
  show_cost: false         # 显示每次调用的成本
```

**记忆系统**
```yaml
memory:
  memory_enabled: true
  user_profile_enabled: true
  provider: built-in       # built-in | honcho | mem0
```

**安全检查**
```yaml
security:
  tirith_enabled: true     # 命令安全扫描
  website_blocklist: []    # 阻止访问的网站列表
```

**委派系统**
```yaml
delegation:
  model: openrouter/anthropic/claude-sonnet-4
  provider: openrouter
  max_iterations: 50
  reasoning_effort: medium
```

**检查点**
```yaml
checkpoints:
  enabled: true
  max_snapshots: 50        # 最大快照数量
```

### 支持的提供商

| 提供商 | 认证方式 | 环境变量 |
|--------|---------|----------|
| OpenRouter | API Key | `OPENROUTER_API_KEY` |
| Anthropic | API Key | `ANTHROPIC_API_KEY` |
| Nous Portal | OAuth | `hermes auth` |
| OpenAI Codex | OAuth | `hermes auth` |
| GitHub Copilot | Token | `COPILOT_GITHUB_TOKEN` |
| Google Gemini | API Key | `GOOGLE_API_KEY` |
| DeepSeek | API Key | `DEEPSEEK_API_KEY` |
| xAI / Grok | API Key | `XAI_API_KEY` |
| Hugging Face | Token | `HF_TOKEN` |
| Kimi / Moonshot | API Key | `KIMI_API_KEY` |
| Alibaba / DashScope | API Key | `DASHSCOPE_API_KEY` |
| 自定义端点 | config | `base_url` + `api_key` |

## 技能系统

### 技能是什么

技能是 Hermes 的**过程性记忆** — 针对重复性任务类型的可复用流程。每个技能是一个 Markdown 文件（SKILL.md），包含 YAML 前置元数据和详细的步骤说明。

### 技能生命周期

1. **创建**：当代理完成复杂任务（5+ 工具调用）、修复棘手错误或发现非平凡工作流后
2. **存储**：保存到 `~/.hermes/skills/<category>/<name>/SKILL.md`
3. **加载**：下次遇到相关任务时自动加载，或通过 `hermes -s skill_name` 手动加载
4. **使用**：LLM 阅读技能内容并按照步骤执行
5. **更新**：当技能过时、不完整或存在错误时，使用 `skill_manage(action='patch')` 更新
6. **删除**：当技能不再相关时删除

### 技能结构

```markdown
---
name: skill-name
description: 简短描述
version: 1.0.0
author: Hermes Agent
tags: [tag1, tag2]
---

# 技能标题

## 何时使用
触发此技能的条件描述

## 步骤
1. 第一步
2. 第二步
   - 子步骤
3. 第三步

## 验证
如何确认执行成功

## 注意事项
常见的陷阱和避免方法
```

### 安装与浏览技能

```bash
hermes skills search 搜索词    # 搜索技能中心
hermes skills install ID      # 安装技能
hermes skills browse          # 浏览所有可用技能
hermes skills list            # 列出已安装技能
hermes skills uninstall N     # 移除技能
hermes skills publish PATH    # 发布自己的技能
hermes skills tap add REPO    # 添加 GitHub 仓库作为技能源
```

### 编写高质量技能的原则

- **触发条件明确**：什么情况下应该使用此技能
- **步骤可执行**：包含确切的命令和代码示例
- **包含验证步骤**：如何确认执行成功
- **包含注意事项**：常见陷阱和解决方法
- **版本管理**：更新时修改版本号

## 记忆系统

### 工作原理

Hermes 的记忆系统跨会话持久化信息：

**用户画像** — 记住用户的偏好、常用环境、工作习惯
**环境记忆** — 记住工作目录结构、依赖关系、项目规范
**经验教训** — 记住之前犯过的错误和学到的教训
**任务进度** — 记住进行中的任务状态

### 记忆提供者

| 提供者 | 说明 | 配置 |
|--------|------|------|
| built-in | 本地文件存储，无需外部依赖 | 默认启用 |
| Honcho | 分布式记忆系统，支持共享 | 需要安装 honcho 插件 |
| Mem0 | 第三方记忆服务 | 需要 API 密钥 |

### 记忆管理命令

```bash
hermes memory setup            # 配置记忆提供者
hermes memory status           # 查看记忆状态
hermes memory off              # 关闭记忆
```

在会话中通过 `/memory` 命令查看或搜索记忆。

## 网关多平台集成

### 支持的平台

Hermes 网关支持以下平台的消息收发：

| 平台 | 说明 |
|------|------|
| Telegram | 完整的机器人交互 |
| Discord | 支持频道和 DM |
| Slack | 支持频道消息和 DM |
| WhatsApp | 通过 API 集成 |
| Signal | 端到端加密消息 |
| Email | IMAP/SMTP 协议 |
| SMS | 短信集成 |
| Matrix | 去中心化通信 |
| Mattermost | 企业团队通信 |
| Home Assistant | 智能家居控制 |
| DingTalk | 钉钉集成 |
| Feishu/Lark | 飞书集成 |
| WeCom | 企业微信 |
| WeChat | 个人微信 |
| API Server | 自定义 Webhook |

### 网关管理

```bash
hermes gateway run             # 前台启动网关
hermes gateway install         # 安装为后台服务
hermes gateway start/stop      # 控制服务
hermes gateway restart         # 重启服务
hermes gateway status          # 检查状态
hermes gateway setup           # 配置平台
```

### 网关中的会话命令

在网关平台的消息中，可以使用以下命令：

```
/approve      批准待处理的命令
/deny         拒绝待处理的命令
/restart      重启网关
/sethome      将当前聊天设置为主频道
/update       更新 Hermes
/platforms    显示平台连接状态
/help         显示所有命令
/skills       管理技能
/tools        管理工具
```

## 定时任务与 Webhook

### Cron 定时任务

创建定时执行的任务：

```bash
hermes cron create "30m"         # 每 30 分钟执行一次
hermes cron create "every 2h"    # 每 2 小时执行一次
hermes cron create "0 9 * * *"   # 每天 9:00 执行（标准 cron 格式）
hermes cron list                 # 列出所有任务
hermes cron edit ID              # 编辑任务
hermes cron pause/resume ID      # 暂停/恢复
hermes cron remove ID            # 删除
hermes cron status               # 调度器状态
```

### Webhook 订阅

```bash
hermes webhook subscribe NAME    # 创建路由 /webhooks/<name>
hermes webhook list              # 列出订阅
hermes webhook remove NAME       # 删除订阅
hermes webhook test NAME         # 发送测试 POST
```

## 配置文件系统（Profiles）

配置文件允许运行多个完全独立的 Hermes 实例：

```bash
hermes profile create NAME            # 创建配置文件
hermes profile create NAME --clone    # 从当前配置克隆
hermes profile list                   # 列出所有配置
hermes profile use NAME               # 设置为默认
hermes profile show NAME              # 查看详情
hermes profile delete NAME            # 删除
hermes profile rename A B             # 重命名
hermes profile export NAME            # 导出为 tar.gz
hermes profile import FILE            # 从存档导入
hermes profile alias NAME             # 管理包装脚本
```

每个配置文件在 `~/.hermes/profiles/<name>/` 下拥有独立的 config.yaml、.env、skills/ 和 sessions/。

## 凭证池

管理多个 API 密钥以实现自动轮换：

```bash
hermes auth add                     # 交互式添加凭证
hermes auth list [PROVIDER]         # 列出池中凭证
hermes auth remove P INDEX          # 按提供商和索引删除
hermes auth reset PROVIDER          # 清除耗尽状态
```

当凭证池中有多个密钥时，Hermes 会自动轮换使用，在速率限制或配额耗尽时切换到下一个密钥。

## 插件系统

```bash
hermes plugins list                 # 列出已安装的插件
hermes plugins install NAME         # 安装插件
hermes plugins remove NAME          # 移除插件
```

## 内置工具集

| 工具集 | 功能说明 |
|--------|---------|
| web | 网络搜索和内容提取 |
| browser | 浏览器自动化 |
| terminal | Shell 命令和进程管理 |
| file | 文件读写/搜索/编辑 |
| code_execution | 沙箱化 Python 执行 |
| vision | 图像分析 |
| image_gen | AI 图像生成 |
| tts | 文本转语音 |
| skills | 技能浏览和管理 |
| memory | 跨会话持久记忆 |
| session_search | 搜索过往对话 |
| delegation | 子代理任务委派 |
| cronjob | 定时任务管理 |
| clarify | 向用户提问澄清 |
| messaging | 跨平台消息发送 |
| search | 网络搜索（web 的子集）|
| todo | 会话内任务规划和跟踪 |

## 故障排查

### 语音功能不可用

1. 检查 `stt.enabled: true` 是否在 config.yaml 中
2. 确认提供者配置：`pip install faster-whisper` 或设置 API 密钥
3. 网关模式下运行 `/restart`，CLI 模式下退出后重新启动

### 工具不可用

1. `hermes tools` — 检查工具集是否已为当前平台启用
2. 某些工具需要环境变量（检查 `.env` 文件）
3. 启用工具后需使用 `/reset` 重新开始会话

### 模型/提供商问题

1. `hermes doctor` — 检查配置和依赖
2. `hermes login` — 重新认证 OAuth 提供商
3. 检查 `.env` 是否有正确的 API 密钥
4. Copilot 403 错误：`gh auth login` 的令牌不能用于 Copilot API，必须使用 Copilot 特定的 OAuth 设备码流程

### 更改不生效

- **工具/技能变更**：使用 `/reset` 开始新会话
- **配置变更**：网关模式下运行 `/restart`，CLI 模式下退出后重新启动
- **代码变更**：重启 CLI 或网关进程

### 网关问题

首先检查日志：
```bash
grep -i "failed to send\|error" ~/.hermes/logs/gateway.log | tail -20
```

常见问题：
- **SSH 登出后网关停止**：启用 linger：`sudo loginctl enable-linger $USER`
- **WSL2 关闭后网关停止**：WSL2 需要在 `/etc/wsl.conf` 中设置 `systemd=true`
- **网关崩溃循环**：重置失败状态：`systemctl --user reset-failed hermes-gateway`

### 平台特定问题

- **Discord 机器人无响应**：必须在 Bot → Privileged Gateway Intents 中启用 Message Content Intent
- **Slack 机器人仅在 DM 中工作**：必须订阅 `message.channels` 事件
- **Windows HTTP 400 "No models provided"**：配置文件编码问题（BOM），确保 config.yaml 保存为无 BOM 的 UTF-8

## 附录：项目结构

对于有兴趣贡献代码的开发者，Hermes 的项目结构如下：

```
hermes-agent/
├── run_agent.py            # AIAgent — 核心对话循环
├── model_tools.py          # 工具发现和分发
├── toolsets.py             # 工具集定义
├── cli.py                  # 交互式 CLI（HermesCLI）
├── hermes_state.py         # SQLite 会话存储
├── agent/                  # 提示构建器、上下文压缩、记忆、模型路由、凭证池、技能分发
├── hermes_cli/             # CLI 子命令、配置、设置
│   ├── commands.py         # 斜杠命令注册表（CommandDef）
│   ├── config.py           # DEFAULT_CONFIG、环境变量定义
│   └── main.py             # CLI 入口和 argparse
├── tools/                  # 每个工具一个文件
│   └── registry.py         # 中央工具注册表
├── gateway/                # 消息网关
│   └── platforms/          # 平台适配器（telegram、discord 等）
├── cron/                   # 任务调度器
├── tests/                  # ~3000 个 pytest 测试
└── website/                # Docusaurus 文档网站
```
