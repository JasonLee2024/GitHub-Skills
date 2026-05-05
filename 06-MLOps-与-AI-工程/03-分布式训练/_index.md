---
title: 06-03 — 分布式训练
nav_order: 0
---

# 06-03 — 分布式训练

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[pytorch-fsdp]] | `pytorch-fsdp` | 全分片数据并行（ZeRO-3 等效），支持 CPU Offload |

## 概述

FSDP（Fully Sharded Data Parallel）是 PyTorch 官方的分布式训练方案，将模型参数、梯度和优化器状态分片到多个 GPU 上，支持大模型训练。PyTorch 2.4+ 的 FSDP2 提供了更简洁的 composable API。

## 适用场景

- **单节点多 GPU**：8× A100/H100 训练 7B-13B 模型
- **多节点集群**：大规模训练 70B+ 模型
- **显存受限环境**：配合 CPU Offload 在有限 GPU 上训练大模型

## 学习路线

1. 了解分布式训练基础（DDP、ZeRO、FSDP 区别）
2. 使用 `Accelerate + FSDP` 快速上手
3. 深入 FSDP 配置：分片策略、混合精度、CPU Offload
4. 学习 FSDP2 composable API 和性能调优
