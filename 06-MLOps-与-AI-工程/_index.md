# 06 — MLOps & AI 工程

## 本章节内容

从模型推理到分布式训练，覆盖 ML 工程全链路。所有内容面向中文读者，包含丰富的实操命令和代码示例。

## 章节组织

```
06-MLOps-与-AI-工程/
├── 01-模型推理/              ← llama-cpp, vllm, outlines 结构化生成
├── 02-模型微调/              ← PEFT/QLoRA, Unsloth, Axolotl, TRL/RLHF
├── 03-分布式训练/            ← PyTorch FSDP 全分片数据并行
├── 04-模型服务与部署/        ← Modal 无服务器 GPU, HuggingFace Hub
├── 05-实验跟踪与评估/        ← W&B 实验跟踪, LLM Evaluation Harness
└── 06-DSPy-声明式AI/        ← 声明式 AI 系统编程与自动优化
```

## 学习路线

1. **模型推理** → 先学会运行和量化模型（llama-cpp + outines）
2. **模型微调** → 学会参数高效微调（PEFT → Unsloth → Axolotl → TRL）
3. **分布式训练** → 扩展到多 GPU 训练（FSDP）
4. **模型服务与部署** → 部署到生产环境（HuggingFace Hub + Modal）
5. **实验跟踪与评估** → 跟踪实验并标准化评测（W&B + Eval Harness）
6. **DSPy** → 进阶：声明式 AI 系统构建

## 相关 Hermes 技能

### 推理
- `llama-cpp` — 本地 LLM 推理与 GGUF 量化
- `outlines` — 结构化输出（JSON Schema / Pydantic）
- `serving-llms-vllm` — 高性能 vLLM 推理服务

### 微调
- `peft-fine-tuning` — LoRA/QLoRA 参数高效微调
- `unsloth` — 2-5x 加速的快速微调
- `axolotl` — YAML 驱动的微调框架
- `fine-tuning-with-trl` — RLHF/DPO/GRPO 强化学习微调

### 训练
- `pytorch-fsdp` — FSDP 分布式训练

### 部署
- `modal-serverless-gpu` — 无服务器 GPU 云平台
- `huggingface-hub` — 模型注册表与社区平台

### 评估
- `weights-and-biases` — ML 实验跟踪与 MLOps
- `evaluating-llms-harness` — LLM 标准化评测

### 架构
- `dspy` — 声明式语言模型编程

## 已创建的内容文件

| 目录 | 文件 | 说明 |
|------|------|------|
| 01-模型推理 | `llama-cmd.md` | 本地推理与 GGUF 量化 |
| | `vllm.md` | PagedAttention 高性能推理服务 |
| | `outlines.md` | 结构化生成（FSM / JSON Schema） |
| 02-模型微调 | `peft-lora.md` | LoRA/QLoRA 参数高效微调 |
| | `unsloth.md` | Unsloth 2-5x 加速微调 |
| | `axolotl.md` | Axolotl YAML 驱动的微调框架 |
| | `trl-rlhf.md` | TRL 强化学习微调（DPO/GRPO/PPO） |
| 03-分布式训练 | `pytorch-fsdp.md` | PyTorch FSDP 全分片训练 |
| 04-模型服务与部署 | `huggingface-hub.md` | HF Hub 模型管理 |
| | `modal-serverless-gpu.md` | Modal 无服务器 GPU |
| 05-实验跟踪与评估 | `llm-evaluation-harness.md` | LM Evaluation Harness |
| | `wandb.md` | Weights & Biases 实验跟踪 |
| 06-DSPy-声明式AI | `dspy.md` | DSPy 声明式 LM 编程 |
