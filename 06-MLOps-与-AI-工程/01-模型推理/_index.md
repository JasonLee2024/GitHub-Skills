# 06-01 — 模型推理

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[llama-cpp]] | `llama-cpp` | LLM 本地推理，支持 GGUF 量化，CPU/Apple Silicon/AMD GPU |
| [[vllm]] | `serving-llms-vllm` | 高吞吐模型服务，PagedAttention，连续批处理 |
| [[outlines]] | `outlines` | 结构化生成，保证 JSON/XML/代码格式 |

## 选择指南

- **本地单机推理**（CPU/Mac/AMD） → `llama-cpp`
- **高吞吐 API 服务**（NVIDIA GPU） → `vllm`
- **需要结构化输出** → 配合 `outlines`（支持多后端）

## 学习路线

1. 从 `llama-cpp` 开始，了解 GGUF 量化和基础推理
2. 学习 `vllm` 掌握生产级部署
3. 深入 `outlines` 实现结构化生成
