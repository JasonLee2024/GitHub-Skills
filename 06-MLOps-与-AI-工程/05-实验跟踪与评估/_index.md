# 06-05 — 实验跟踪与评估

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[llm-evaluation-harness]] | `evaluating-llms-harness` | 60+ 学术基准评测，MMLU/GSM8K/HumanEval |
| [[wandb]] | `weights-and-biases` | ML 实验跟踪，Sweep 超参搜索，模型注册 |

## 概述

实验跟踪与评估是 MLOps 的生命线。本章涵盖：

1. **LLM 评估** — 使用 EleutherAI LM Evaluation Harness 进行标准化评测
2. **实验跟踪** — 使用 Weights & Biases 记录训练过程、可视化对比、管理模型版本

## 工作流

```
训练实验 → W&B（记录指标 + 超参数）→ 评估（lm-eval-harness）→ 对比 + 报告
                                   ↘ Sweep 优化 → 下一轮实验
```

## 选择指南

| 需求 | 推荐方案 |
|------|---------|
| 模型标准化评测 | lm-eval-harness |
| 训练过程可视化 | W&B |
| 超参数自动搜索 | W&B Sweeps |
| 模型版本管理 | W&B Artifacts |
| 基准对比报告 | 两者结合 |
| 团队协作 | W&B Teams |
