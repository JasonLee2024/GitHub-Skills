---
date: 2026-05-05
tags: [multi-agent, orchestration, subagent, parallel, delegation, workflows]
source_skill: [hermes-agent, claude-code, codex, opencode]
category: 自主AI-Agent
---

# 多代理协作模式

## 概述

在现代 AI 开发工作流中，单一代理往往不足以高效完成所有任务。多代理协作模式通过将工作分配给多个专业化代理，实现并行执行、关注点分离和资源优化。

本章涵盖三种核心的多代理协作模式：
1. **子代理模式** — 主代理委派子任务给专用子代理
2. **任务委派模式** — 将完整任务分配给独立的外部代理进程
3. **并行执行模式** — 同时运行多个代理处理独立任务

## 多代理架构基础

### 为什么需要多代理

| 场景 | 单代理问题 | 多代理优势 |
|------|-----------|-----------|
| 大型项目构建 | 单个 LLM 上下文窗口不足 | 多个代理各负责一部分 |
| 复杂代码审查 | 视角单一 | 设计、安全、性能分别审查 |
| 前端+后端同时开发 | 串行执行，耗时长 | 并行开发，效率翻倍 |
| 大规模重构 | 容易遗漏边界情况 | 分模块处理，互不干扰 |
| 文档+代码同步更新 | 上下文切换成本高 | 专人专事，减少切换 |
| 探索性研究+编码 | 难以同时保持两种思维模式 | 研究代理和编码代理分工 |

### 多代理的挑战

尽管多代理带来很多优势，但也需要解决以下问题：

1. **上下文共享** — 代理之间如何传递知识和决策
2. **工作目录隔离** — 避免文件写入冲突
3. **资源管理** — 控制 API 成本和 token 消耗
4. **协调开销** — 设置和管理多个会话的成本
5. **错误传播** — 一个代理的错误可能影响其他代理
6. **一致性保证** — 确保各代理的工作风格和规范一致

## 模式一：子代理模式

### 概述

子代理模式是在**同一个进程内**通过 `delegate_task` 工具来委派子任务。主代理保留控制和协调权，子代理专注于执行具体任务。

### 适用场景

- 需要快速完成的小规模并行子任务（分钟级）
- 子任务之间需要上下文共享
- 不需要完全独立的环境

### Hermes 子代理

Hermes Agent 内置了 `delegation` 工具集，可以直接在会话中委派任务：

```
system: 你有一个 delegation 工具可以用来委派编码任务给子代理。

user: 帮我把 auth 模块拆分为独立的服务文件。

助手 (thinking): 这个任务需要创建多个文件，我可以委派子任务来处理。
[使用 delegation 工具，指定子代理模型和任务描述]
```

#### delegation 配置

```yaml
delegation:
  model: openrouter/anthropic/claude-sonnet-4  # 子代理使用的模型
  provider: openrouter                         # 子代理的提供商
  max_iterations: 50                           # 子代理最大迭代次数
  reasoning_effort: medium                     # 推理深度
```

#### 子代理工作流程

```
主代理
  │
  ├── delegate_task("创建 UserService 类")
  │     └── 子代理 A → 返回文件内容
  │
  ├── delegate_task("创建 AuthService 类")
  │     └── 子代理 B → 返回文件内容
  │
  └── 主代理合并结果、检查一致性、写入最终文件
```

### Claude Code 子代理

Claude Code 支持在 `.claude/agents/` 目录下定义专用子代理：

```markdown
# .claude/agents/db-expert.md
---
name: db-expert
description: 数据库架构和 SQL 优化专家
model: opus
tools: [Read, Bash]
---
你是一个数据库专家。擅长：
- SQL 查询优化
- 数据库架构设计
- ORM 映射优化
- 迁移脚本编写
```

在会话中通过 `@` 符号引用：
```
@db-expert 审查 users 表的索引策略
@security-reviewer 审计 auth 模块的认证流程
```

Claude Code 还可以动态通过 `--agents` 标志定义子代理：

```bash
claude --agents '{
  "reviewer": {
    "description": "代码审查专家",
    "prompt": "你是专注于性能优化的代码审查员"
  },
  "tester": {
    "description": "测试专家",
    "prompt": "你是测试驱动开发的专家"
  }
}' -p "使用 @reviewer 检查 auth.py，然后 @tester 添加测试"
```

### 子代理模式的优缺点

**优点**：
- 设置简单，无需额外进程管理
- 上下文共享自然
- 协调成本低

**缺点**：
- 与主代理共享进程资源
- 长时间运行会阻塞主代理
- 不适合独立运行数小时的大任务

## 模式二：任务委派模式

### 概述

任务委派模式是将完整任务分配给完全独立的代理进程。主代理启动子进程、监控进度、收集结果。

### 适用场景

- 需要独立环境的长时间任务（小时级）
- 任务需要完整的工具访问权限
- 需要与其他系统集成

### Hermes 委派外部 Agent

Hermes Agent 可以通过 terminal 工具启动独立的代理进程：

```yaml
# 启动 Claude Code 作为子代理执行编码任务
terminal(command="claude -p '在 src/auth/ 下实现 JWT 认证系统' --allowedTools 'Read,Edit,Write,Bash' --max-turns 20", workdir="~/project", timeout=300)

# 或者后台运行持续监视
terminal(command="claude -p '重构数据层' --allowedTools 'Read,Edit' --max-turns 30", workdir="~/project", background=true)

# 稍后检查进度
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")
```

### 委派决策树

```
任务是否需要隔离的工作目录？
├── 是 → 使用 Git Worktree 或临时目录
└── 否 → 可以直接在工作目录中执行

任务是否需要交互？
├── 是 → 使用交互式模式（PTY/tmux）
└── 否 → 使用 Print/run/exec 模式

任务的预期时长？
├── < 5 分钟 → 子代理模式（delegate_task）
├── 5-30 分钟 → Print 模式（claude -p / codex exec / opencode run）
└── > 30 分钟 → 后台进程 + 定期检查

任务是否需要完整的工具权限？
├── 是 → 委派给独立代理（CLI 模式）
└── 否 → 子代理模式（共享主代理的上下文）
```

### 子代理 vs 独立进程的对比

| 维度 | 子代理 (delegate_task) | 独立进程 (CLI 委派) |
|------|----------------------|-------------------|
| 隔离程度 | 共享进程 | 完全独立 |
| 时长 | 分钟级 | 小时级 |
| 工具访问 | 主代理的子集 | 完整工具访问 |
| 交互 | 否 | 是（PTY 模式）|
| 上下文共享 | 自动 | 手动传递 |
| 并行度 | 串行 | 真正并行 |
| 资源消耗 | 低 | 中等 |
| 监控 | 自动 | 需要 process 工具 |

## 模式三：并行执行模式

### 概述

并行执行模式是指同时启动多个独立代理，各自处理不相关的任务。这是最具扩展性的模式，能够大幅缩短开发周期。

### 适用场景

- 前后端同时开发
- 多个独立 Bug 修复
- 多模块并行实现
- 批量 PR 审查

### Git Worktree 隔离

并行执行最关键的是工作目录隔离。Git Worktree 是最佳方案：

```bash
# 为每个并行任务创建工作树
git worktree add -b feature/backend-api /tmp/backend-api main
git worktree add -b feature/frontend-ui /tmp/frontend-ui main
git worktree add -b feature/api-tests /tmp/api-tests main
```

每个 Worktree 是独立的文件系统副本，代理操作互不干扰。

### Hermes 并行

```yaml
# 并行任务 1：后端 API
terminal(command="claude -p '在 src/api/ 中实现用户 CRUD API' --allowedTools 'Read,Edit,Write,Bash' --max-turns 15", workdir="/tmp/backend-api", background=true, timeout=300)

# 并行任务 2：前端界面
terminal(command="opencode run '创建用户管理 React 组件' --thinking", workdir="/tmp/frontend-ui", background=true, timeout=300)

# 并行任务 3：测试
terminal(command="codex exec --full-auto '为用户 API 编写集成测试'", workdir="/tmp/api-tests", background=true, timeout=300)
```

### Claude Code 并行模式

Claude Code 的 `--worktree` 和 `--batch` 模式提供了内置的并行能力：

```bash
# 自动创建工作树并进入
claude -w feature/api --tmux

# 批量模式：将大变更拆分为 5-30 个工作树
claude /batch
```

### OpenCode 并行

```bash
# 多个独立任务
opencode run "实现用户注册功能" &
opencode run "实现用户登录功能" &
opencode run "实现密码重置功能" &
```

### 批量 PR 审查并行

```bash
# 审查多个 PR
codex exec "审查 PR #42" &
codex exec "审查 PR #43" &
codex exec "审查 PR #44" &
```

### 并行执行的状态管理

```yaml
# 启动多个后台进程
task1: terminal(command="claude -p '任务A'", background=true)
task2: terminal(command="claude -p '任务B'", background=true)
task3: terminal(command="claude -p '任务C'", background=true)

# 定期检查进度
process(action="poll", session_id="<id1>")
process(action="poll", session_id="<id2>")

# 任务完成后的处理
# 1. 收集变更摘要
# 2. 检查是否有冲突
# 3. 推送和创建 PR
```

## 实战案例

### 案例一：全栈功能开发

场景：在现有项目中添加"用户通知中心"功能。

**步骤 1：规划**

主代理分析需求，制定并行计划：

```
任务分解：
- 后端：通知模型 + API（→ Claude Code）
- 前端：通知组件 + UI（→ OpenCode）
- 数据库：迁移脚本（→ subagent）
- 测试：集成测试（→ Codex）
```

**步骤 2：创建 Worktree**

```bash
git worktree add -b feature/notif-api /tmp/notif-api main
git worktree add -b feature/notif-ui /tmp/notif-ui main
git worktree add -b feature/notif-tests /tmp/notif-tests main
```

**步骤 3：并行执行**

```yaml
# 后端 API
terminal(command="claude -p '在 src/api/notifications.py 中实现通知 API，使用 SSE 实现实时推送' --allowedTools 'Read,Edit,Write,Bash' --max-turns 20", workdir="/tmp/notif-api", background=true)

# 前端 UI
terminal(command="opencode run '在 src/components/ 下创建通知中心组件：通知列表、通知弹窗、设置页面' --thinking", workdir="/tmp/notif-ui", background=true)

# 测试
terminal(command="codex exec --full-auto '为通知功能编写端到端测试'", workdir="/tmp/notif-tests", background=true)
```

**步骤 4：合并与验证**

```yaml
# 检查所有任务是否完成
# 审查各分支的变更
# 合并到主分支
# 运行完整测试套件
```

### 案例二：大规模代码审查

场景：20+ 个 PR 需要审查。

**串行方式**：逐个审查，耗时 ~2 小时。

**并行方式**：

```yaml
# 批量启动审查
for pr in 42 43 44 45 46; do
  terminal(command="claude -p '审查 PR #$pr：检查 bug、安全问题、性能问题' --from-pr $pr --max-turns 3", workdir="~/project", background=true)
done

# 收集所有结果
# 为每个 PR 发布审查评论
```

### 案例三：多模块并行重构

场景：将单体应用拆分为微服务。

```yaml
# 服务 A：用户服务
terminal(command="claude -p '将 auth 模块提取为独立的用户微服务，包括 API、模型、数据库迁移' --worktree micro-auth --max-turns 40", workdir="~/project", background=true)

# 服务 B：订单服务
terminal(command="claude -p '将 order 模块提取为独立的订单微服务' --worktree micro-order --max-turns 40", workdir="~/project", background=true)

# 服务 C：支付服务
terminal(command="opencode run '将 payment 模块提取为支付微服务，实现完整的支付流程' --thinking", workdir="/tmp/micro-payment", background=true)
```

## Agent 能力矩阵与选择

| 任务类型 | 推荐 Agent | 原因 |
|---------|-----------|------|
| 复杂代码重构 | Claude Code | 深度推理，大上下文窗口 |
| 快速编码 | Codex | 速度快，OpenAI 优化 |
| 多提供商任务 | OpenCode | 灵活切换提供商 |
| 通用多平台 | Hermes Agent | 网关、技能、记忆系统 |
| 安全审查 | Claude Code (opus) | 最强安全分析能力 |
| API 开发 | 任一 | 偏好问题 |
| 前端开发 | OpenCode / Claude Code | 开源友好 |
| 批量 PR | Codex | exec 模式简洁高效 |
| 文档编写 | Hermes Agent | 技能系统复用 |
| 探索性编程 | Claude Code | 交互式 TUI 适合迭代 |

## 高级模式：混合编排

### 链式委派

将多个 Agent 串联执行，每个 Agent 的输出作为下一个的输入：

```
Codex（快速原型）
  → Claude Code（深度审查和优化）
    → Hermes Agent（文档和技能保存）
      → OpenCode（测试编写）
```

### 主-从-集群模式

```
主代理（Hermes）
  ├── 子代理集群（Claude Code × N）处理编码
  ├── 子代理集群（Codex × M）处理测试
  └── 审核代理（单独的 Claude Code）审查所有输出
```

### 对称并行

多个相同类型的 Agent 并行处理同类任务：

```
API 路由编写（Claude Code #1 → /users）
                    （Claude Code #2 → /orders）
                    （Claude Code #3 → /payments）
```

## 资源管理与优化

### API 成本控制

```yaml
# 为不同类型任务配置不同模型
简单编码 → haiku / o4-mini / OpenCode + minimal variant
中等任务 → sonnet / gpt-4o / OpenCode + 默认
复杂任务 → opus / o4 / OpenCode + max variant
```

### 上下文管理

- 大任务优先使用 Claude Code（200K 上下文窗口）
- 干净上下文更高效 — 每个任务使用新会话
- 利用 Worktree 隔离避免上下文污染

### 超时处理

```yaml
# 为不同类型任务设置合理的超时
简单修复：60 秒
功能实现：300 秒
大型重构：600 秒（或使用后台模式）
```

## 最佳实践总结

### 原则

1. **隔离优先** — 始终为每个并行任务使用独立目录或 Worktree
2. **明确边界** — 清晰定义每个代理的责任范围
3. **固定规范** — 通过 CLAUDE.md 或技能文档固定代码规范
4. **渐进式并行** — 从串行开始，逐步引入并行
5. **结果汇聚** — 并行执行后统一审查和合并
6. **资源监控** — 跟踪 API 消耗和任务进度

### 避免的反模式

1. **共享工作目录** — 导致文件冲突和未预期的覆盖
2. **过多并行** — 超过 5 个并行任务通常导致管理混乱
3. **忽略冲突** — Git 合并冲突如果不及时处理会越来越复杂
4. **无统一规范** — 不同 Agent 使用不同编码风格导致不一致
5. **无进度监控** — 后台任务应该定期检查状态

### 检查清单

```
启动前：
□ 是否需要隔离的 Worktree？
□ 任务是分钟级还是小时级？
□ 任务之间是否有依赖关系？
□ 使用什么模式（子代理/委派/并行）？
□ 每个任务使用什么模型？

执行中：
□ 是否监控了任务进度？
□ 是否有超时机制？
□ 是否有资源限制（API 预算）？

完成后：
□ 是否收集了各任务的结果？
□ 是否解决了冲突？
□ 是否运行了完整测试？
□ 是否更新了文档？
```

## 未来方向

### 自适应委派

未来的 AI Agent 可以自动评估任务复杂性并选择合适的代理：
- 简单任务 → 本地轻量模型
- 中等任务 → 云端中等模型
- 复杂任务 → 多代理并行协作

### 代理间通信

随着 MCP 和 ACP 协议的发展，代理之间将能够直接通信和协商，而不需要通过终端/进程来间接协调。

### 分布式代理集群

大规模场景下，代理不再局限于单机运行，而是可以在分布式集群中自动调度和扩展。
