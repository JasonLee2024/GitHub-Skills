---
date: 2026-05-05
tags: [index, autonomous-agent, overview]
category: 自主AI-Agent
---

# 05 — 自主 AI Agent

## 本章节内容

Hermes Agent 生态的核心 — 自主 AI 开发助手的部署、配置和编排。

| 文档 | 内容 | 技能来源 |
|------|------|---------|
| [[hermes-agent]] | Hermes Agent 完全指南：架构、配置、技能系统、记忆系统、网关 | `hermes-agent` |
| [[claude-code]] | Claude Code CLI 指南：安装、Print 模式、交互式 TUI、PR 审查 | `claude-code` |
| [[codex]] | OpenAI Codex CLI 集成：快速编码、沙箱、批量修复 | `codex` |
| [[opencode]] | OpenCode CLI 集成：多提供商、run 模式、高级 TUI | `opencode` |
| [[multi-agent-patterns]] | 多代理协作模式：子代理、任务委派、并行执行 | 综合 |

## Agent 能力矩阵

| Agent | 最好用于 | 编排方式 | 提供商 |
|-------|---------|---------|--------|
| Hermes Agent | 通用任务、多平台集成、技能系统 | 原生技能 + delegation | 20+ 提供商 |
| Claude Code | 复杂编码、深度审查、大规模重构 | Print/PTY 模式 | Anthropic |
| Codex | 快速编码、沙箱安全、批量 Issue | exec/yolo 模式 | OpenAI |
| OpenCode | 开源编码、多提供商切换、灵活路由 | run/TUI 模式 | 多提供商 |

## 协作模式速览

```
单代理 → 适合简单、独立的单次任务
子代理 → 主代理内委派子任务（delegate_task）
委派  → 启动独立 Agent 进程完成任务
并行  → 多个 Agent 同时处理独立任务
混合  → 主-从-集群链式编排
```

## 各文件速览

| 文件 | 内容涵盖 |
|------|---------|
| **hermes-agent.md** | 安装、CLI 命令、架构（核心循环、工具调度、上下文压缩）、配置详解、技能系统（创建/安装/管理）、记忆系统、网关多平台（10+ 平台）、定时任务、Webhook、配置文件系统、凭证池、内置工具集（18 个）、故障排查 |
| **claude-code.md** | 安装认证、交互式 TUI（快捷键、输入前缀、模式切换）、Print 模式（JSON/流式输出、管道输入、JSON Schema）、CLI 标志参考、会话命令、CLAUDE.md 项目配置、自定义子代理、钩子系统（8 种类型）、MCP 集成、PR 审查、并行实例、成本优化 |
| **codex.md** | 安装前提、exec/yolo/full-auto 模式、沙箱机制、CLI 标志、代码重构/Bug 修复/功能实现/测试编写、PR 审查工作流、批量 Issue 修复（Worktree 并行）、临时项目搭建、后台运行、与 Hermes 编排集成、对比表格、安全建议 |
| **opencode.md** | 安装认证、run 模式（多种标志）、交互式 TUI（快捷键、代理角色 build/plan）、后台运行、并行执行、PR 审查、多提供商策略、会话与成本管理、最佳实践、对比表格、常见陷阱 |
| **multi-agent-patterns.md** | 三种核心模式：子代理（内部分配）、委派（独立进程）、并行（同时执行）、决策树、Worktree 隔离、实战案例（全栈开发/批量审查/微服务拆分）、能力矩阵、资源优化、最佳实践、避免的反模式 |

## 选择指南

**我需要...**

- 一个长期运行的多平台 AI 助手 → [[hermes-agent]]
- 深度代码审查和复杂重构 → [[claude-code]]
- 快速的一次性编码任务 → [[codex]]
- 灵活切换不同 AI 提供商 → [[opencode]]
- 同时管理多个编码工作流 → [[multi-agent-patterns]]

## 相关技能

| 技能 | 关联说明 |
|------|---------|
| `hermes-agent` | 本章核心技能 |
| `claude-code` | Claude Code 编排 |
| `codex` | Codex CLI 编排 |
| `opencode` | OpenCode CLI 编排 |
| `subagent-driven-development` | 子代理驱动开发详见 [[../03-软件开发方法论/subagent-driven-development]] |
| `webhook-subscriptions` | Agent 事件触发详见 [[../04-自动化与CI-CD/webhook-subscriptions]] |

## 延伸阅读

- [Hermes Agent 官方文档](https://hermes-agent.nousresearch.com/docs/)
- [Claude Code 文档](https://code.claude.com/docs/en/cli-reference)
- [OpenAI Codex](https://github.com/openai/codex)
- [OpenCode](https://opencode.ai)
