---
title: Axolotl — YAML 配置驱动的微调框架
description: 使用 Axolotl 通过 YAML 配置文件管理 LLM 微调全流程，支持 100+ 模型和多种训练策略
---

# Axolotl — YAML 配置驱动的微调框架

## 概述

Axolotl 是一个全功能的 LLM 微调框架，通过 YAML 配置文件管理训练参数、数据集、模型架构等全部设置。它支持 100+ 模型架构，集成了 LoRA/QLoRA、DeepSpeed、FSDP、多模态训练等高级功能。

### 核心特性

- **YAML 驱动**：所有配置通过 YAML 文件管理，可重复、可分享
- **100+ 模型支持**：LLaMA、Mistral、Qwen、Gemma 等主流架构
- **多训练策略**：LoRA、QLoRA、全参数微调、DPO/KTO/ORPO/GRPO
- **分布式训练**：集成 DeepSpeed ZeRO、FSDP
- **多模态支持**：LLaVA、Qwen-VL 等视觉语言模型
- **丰富的数据集格式**：Alpaca、ShareGPT、ChatML、指令格式等

### 适用场景

| 场景 | 推荐 |
|------|------|
| 生产级微调流水线 | ✅ 首选，配置可复现 |
| 复杂训练策略 | ✅ DPO/GRPO/ORPO 等多种 RLHF |
| 团队协作 | ✅ YAML 配置适合版本控制 |
| 快速实验 | ⚠️ 使用 Unsloth |
| 小规模微调 | ⚠️ 使用 PEFT/LoRA |

## 安装

```bash
# 使用 pip 安装
pip install axolotl

# 从源码安装
git clone https://github.com/OpenAccess-AI-Collective/axolotl
cd axolotl
pip install -e .

# 验证安装
python -c "import axolotl; print(axolotl.__version__)"
```

## 快速开始

### YAML 配置文件

创建一个 `config.yaml`：

```yaml
# 基础配置
base_model: Qwen/Qwen2.5-1.5B-Instruct
model_type: AutoModelForCausalLM
tokenizer_type: AutoTokenizer

# 训练配置
output_dir: ./axolotl-output
num_epochs: 3
per_device_train_batch_size: 4
gradient_accumulation_steps: 4
learning_rate: 2e-4
warmup_steps: 100
optimizer: adamw_bnb_8bit
lr_scheduler: cosine

# 精度配置
bf16: true
tf32: true
fp16: false

# LoRA 配置
lora_model_dir:
lora_r: 16
lora_alpha: 16
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - k_proj
  - v_proj
  - o_proj
  - gate_proj
  - up_proj
  - down_proj
lora_target_linear: false

# 数据集配置
datasets:
  - path: ./data/train.jsonl
    type: sharegpt
    conversation: chatml

# 序列长度
sequence_len: 2048

# 日志和保存
logging_steps: 10
save_steps: 100
eval_steps: 100
```

### 准备数据

```jsonl
# train.jsonl
{"conversations": [
  {"from": "human", "value": "什么是机器学习？"},
  {"from": "gpt", "value": "机器学习是人工智能的一个分支..."}
]}
```

### 运行训练

```bash
# 单 GPU 训练
accelerate launch -m axolotl.cli.train config.yaml

# 多 GPU 训练
torchrun --nproc_per_node=4 -m axolotl.cli.train config.yaml

# 从检查点恢复
accelerate launch -m axolotl.cli.train config.yaml --resume_from_checkpoint
```

## 数据集格式

Axolotl 支持多种数据集格式：

### ShareGPT 格式

```jsonl
{"conversations": [
  {"from": "system", "value": "你是一个有用的助手。"},
  {"from": "human", "value": "你好"},
  {"from": "gpt", "value": "你好！有什么可以帮助你的吗？"}
]}
```

### Alpaca 格式

```jsonl
{
  "instruction": "解释量子计算",
  "input": "",
  "output": "量子计算是一种利用量子力学原理的计算方式..."
}
```

### ChatML 格式

```jsonl
{"messages": [
  {"role": "system", "content": "你是一个有用的助手。"},
  {"role": "user", "content": "你好"},
  {"role": "assistant", "content": "你好！"}
]}
```

## 高级配置

### QLoRA（4-bit 量化）

```yaml
# 添加量化配置
load_in_4bit: true
bnb_4bit_quant_type: nf4
bnb_4bit_compute_dtype: bfloat16
bnb_4bit_use_double_quant: true

# 与 LoRA 配合
lora_r: 16
lora_alpha: 16
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - k_proj
  - v_proj
  - o_proj
```

### DeepSpeed ZeRO 配置

```yaml
# 使用 DeepSpeed ZeRO-2
deepspeed: deepspeed_configs/zero2.json

# 或 ZeRO-3
deepspeed: deepspeed_configs/zero3.json
```

`zero2.json`:

```json
{
  "zero_optimization": {
    "stage": 2,
    "allgather_partitions": true,
    "allgather_bucket_size": 2e8,
    "overlap_comm": true,
    "reduce_scatter": true,
    "reduce_bucket_size": 2e8,
    "contiguous_gradients": true
  },
  "gradient_accumulation_steps": 4,
  "gradient_clipping": "auto",
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto"
}
```

### FSDP 配置

```yaml
fsdp:
  - full_shard
  - auto_wrap
  - backward_prefetch
  - forward_prefetch
fsdp_config:
  fsdp_offload_params: false
  fsdp_state_dict_type: FULL_STATE_DICT
  fsdp_auto_wrap_policy: TRANSFORMER_BASED_WRAP
  fsdp_transformer_layer_cls_to_wrap: LlamaDecoderLayer
  fsdp_min_num_params: 100000000
```

### DPO/GRPO 训练

```yaml
# DPO 配置
rl: dpo
beta: 0.1
dpo_loss_type: sigmoid

# 数据集需要包含 chosen/rejected
datasets:
  - path: ./data/dpo-data.jsonl
    type: sharegpt
    conversation: chatml
    split:
      - chosen
      - rejected
```

## 分布式训练

### 多 GPU 训练

```bash
# 4 GPUs, DeepSpeed ZeRO-2
torchrun --nproc_per_node=4 -m axolotl.cli.train config.yaml

# 使用 accelerate
accelerate config  # 首次配置
accelerate launch -m axolotl.cli.train config.yaml
```

### 多节点训练

```bash
# 主节点
torchrun \
    --nnodes=2 \
    --nproc_per_node=8 \
    --node_rank=0 \
    --master_addr=192.168.1.1 \
    --master_port=29500 \
    -m axolotl.cli.train config.yaml

# 工作节点
torchrun \
    --nnodes=2 \
    --nproc_per_node=8 \
    --node_rank=1 \
    --master_addr=192.168.1.1 \
    --master_port=29500 \
    -m axolotl.cli.train config.yaml
```

## 模型导出

### 合并 LoRA 权重

Axolotl 训练后自动保存 LoRA 权重。需要合并时：

```bash
python -m axolotl.cli.merge_lora config.yaml \
    --lora_model_dir ./axolotl-output/checkpoint-100

# 或使用 Python API
```

```python
from axolotl.utils.inference import load_model

model, tokenizer = load_model(
    "./axolotl-output/checkpoint-100",
    model_config={"base_model": "Qwen/Qwen2.5-1.5B-Instruct"},
    inference=True,
)

model.save_pretrained("./merged-model")
tokenizer.save_pretrained("./merged-model")
```

### 转换为 GGUF

```bash
python -m axolotl.cli.quantize \
    --base_model ./merged-model \
    --output ./gguf-model \
    --quant_method q4_k_m
```

## 推理测试

```bash
# 使用训练好的模型推理
python -m axolotl.cli.inference config.yaml \
    --lora_model_dir ./axolotl-output/checkpoint-100 \
    --prompt "什么是机器学习？"
```

```python
from axolotl.utils.inference import load_model, generate

model, tokenizer = load_model(
    "./axolotl-output/checkpoint-100",
    model_config={"base_model": "Qwen/Qwen2.5-1.5B-Instruct"},
)

response = generate(
    model=model,
    tokenizer=tokenizer,
    prompt="什么是机器学习？",
    max_new_tokens=256,
    temperature=0.7,
)

print(response)
```

## 最佳实践

### 1. 系统化实验管理

```bash
# 每个实验使用独立的配置文件和输出目录
experiments/
├── baseline/
│   ├── config.yaml
│   └── output/
├── lora-r8/
│   ├── config.yaml
│   └── output/
└── lora-r16-lr5e5/
    ├── config.yaml
    └── output/
```

### 2. 数据质量控制

```yaml
# 数据集预处理
dataset_prepared:
  - shuffle: true
  - remove_duplicates: true
  - filter_by_length:
      max_length: 2048
```

### 3. 监控训练

```yaml
# 集成 WandB
wandb_project: my-axolotl-project
wandb_entity: my-username

# 日志
logging_steps: 10
report_to: wandb
```

## 常见问题

### CUDA Out of Memory

```yaml
# 解决方案
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
load_in_4bit: true
sequence_len: 1024
```

### 训练发散

```yaml
# 降低学习率
learning_rate: 1e-5
warmup_steps: 200
lr_scheduler: cosine

# 增加梯度裁剪
gradient_clipping: 1.0
```

### 数据加载慢

```yaml
# 使用多进程加载
dataloader_num_workers: 4
dataloader_prefetch_factor: 2
```

## 参考链接

- 文档: https://axolotl.ai
- GitHub: https://github.com/OpenAccess-AI-Collective/axolotl
- 数据集格式: https://axolotl.ai/docs/dataset-formats.html
- Discord: https://discord.gg/axolotl
