---
title: 06-06 — DSPy：声明式 AI 系统编程
nav_order: 0
---

# 06-06 — DSPy：声明式 AI 系统编程

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[dspy]] | `dspy` | 声明式 LM 编程，自动提示词优化，模块化 RAG/Agent |

## 概述

DSPy 是斯坦福 NLP 组开发的前沿框架，将 AI 系统构建从手写提示工程的试错模式，升级为声明式编程 + 数据驱动优化的工程化模式。

## 核心思想

```
手动提示工程: 写 prompt → 试 → 改 → 再试...
DSPy 方式:    定义签名 → 提供数据 → 自动优化 → 可靠运行
```

## 与本章其他内容的关系

| 组件 | 与 DSPy 的关联 |
|------|---------------|
| [[llm-evaluation-harness]] | DSPy 内置 Evaluate 支持自定义指标 |
| [[wandb]] | 可与 DSPy 配合记录优化过程 |
| [[peft-lora]] | DSPy 的 BootstrapFinetune 生成微调数据 |

## 学习路线

1. 理解 Signatures 和 Modules（Predict / ChainOfThought）
2. 掌握 ReAct 和 ProgramOfThought 等高级模块
3. 使用 BootstrapFewShot 进行少样本优化
4. 构建多阶段流水线和 RAG 系统
5. 探索 MIPRO 等高级优化器
