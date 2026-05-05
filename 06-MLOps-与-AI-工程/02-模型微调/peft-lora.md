---
title: PEFT / LoRA — 参数高效微调
description: 使用 HuggingFace PEFT 和 LoRA/QLoRA 技术实现参数高效的 LLM 微调，大幅降低显存需求
---

# PEFT / LoRA — 参数高效微调

## 概述

PEFT（Parameter-Efficient Fine-Tuning）是 HuggingFace 的参数高效微调库，核心思想是冻结大部分预训练参数，仅训练少量新增的可训练参数。LoRA（Low-Rank Adaptation）是最流行的 PEFT 方法。

### 核心概念

- **LoRA**：在预训练权重旁插入低秩矩阵，训练时仅更新这些矩阵
- **QLoRA**：将预训练模型量化为 4-bit，进一步降低显存需求
- **AdaLoRA**：自适应分配 LoRA rank 到不同层
- **IA³**：通过学习向量缩放注意力机制

### 为什么需要 PEFT？

| 方法 | 可训练参数 | 7B 模型显存 | 训练时间 |
|------|-----------|------------|---------|
| 全参数微调 | 100% | ~60 GB | 慢 |
| LoRA | 0.1-1% | ~16 GB | 快 |
| QLoRA (4-bit) | 0.1-1% | ~10 GB | 中等 |

## 安装

```bash
pip install peft transformers accelerate bitsandbytes
```

## 快速开始：LoRA 微调

### 加载基础模型

```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

model_name = "Qwen/Qwen2.5-1.5B-Instruct"

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.bfloat16,
    device_map="auto",
)
```

### 配置 LoRA

```python
from peft import LoraConfig, get_peft_model

lora_config = LoraConfig(
    r=8,                    # LoRA 秩
    lora_alpha=32,          # 缩放参数
    target_modules=[        # 目标模块
        "q_proj",
        "k_proj",
        "v_proj",
        "o_proj",
        "gate_proj",
        "up_proj",
        "down_proj",
    ],
    lora_dropout=0.05,      # Dropout 率
    bias="none",            # 偏置处理
    task_type="CAUSAL_LM",  # 任务类型
)

# 应用 LoRA
model = get_peft_model(model, lora_config)

# 查看可训练参数
model.print_trainable_parameters()
# 输出示例: trainable params: 4.2M || all params: 1.5B || trainable: 0.28%
```

### 准备数据集

```python
from datasets import Dataset

# 准备对话数据
train_data = [
    {"instruction": "解释什么是机器学习", "output": "机器学习是人工智能的一个分支..."},
    {"instruction": "Python 的特点是什么", "output": "Python 是一种解释型、高级编程语言..."},
]

def format_chat(example):
    return {
        "text": tokenizer.apply_chat_template(
            [
                {"role": "user", "content": example["instruction"]},
                {"role": "assistant", "content": example["output"]},
            ],
            tokenize=False,
        )
    }

dataset = Dataset.from_list(train_data)
dataset = dataset.map(format_chat)
```

### 配置训练参数

```python
from transformers import TrainingArguments, Trainer

training_args = TrainingArguments(
    output_dir="./lora-qwen-output",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    warmup_steps=100,
    logging_steps=10,
    save_steps=100,
    evaluation_strategy="no",
    save_strategy="steps",
    fp16=False,
    bf16=True,
    report_to="none",
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    tokenizer=tokenizer,
    data_collator=lambda data: {
        "input_ids": torch.stack([f["input_ids"] for f in data]),
        "attention_mask": torch.stack([f["attention_mask"] for f in data]),
        "labels": torch.stack([f["input_ids"] for f in data]),
    },
)

trainer.train()
```

## QLoRA：4-bit 量化微调

QLoRA 将基础模型量化为 4-bit NF4 格式，使 7B 模型的微调显存从 ~60GB 降至 ~10GB。

```python
from transformers import BitsAndBytesConfig
import torch

# 4-bit 量化配置
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True,
)

# 加载 4-bit 量化模型
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    quantization_config=bnb_config,
    device_map="auto",
    torch_dtype=torch.bfloat16,
)

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

# 配置 LoRA（和上面一样）
lora_config = LoraConfig(
    r=8,
    lora_alpha=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
```

## LoRA 参数详解

### r（秩）

```python
# 不同 r 值的对比
LoraConfig(r=4)    # 最小参数，适合简单任务
LoraConfig(r=8)    # 推荐默认值
LoraConfig(r=16)   # 更大表达能力
LoraConfig(r=32)   # 复杂任务，更多参数
LoraConfig(r=64)   # 接近全参数微调
```

### lora_alpha（缩放参数）

```python
# alpha 控制 LoRA 权重的影响程度
LoraConfig(r=8, lora_alpha=16)    # 缩放 = 16/8 = 2
LoraConfig(r=8, lora_alpha=32)    # 缩放 = 32/8 = 4 (推荐)
LoraConfig(r=8, lora_alpha=64)    # 缩放 = 64/8 = 8
```

### target_modules（目标模块）

不同模型的常用 target_modules：

| 模型 | target_modules |
|------|---------------|
| LLaMA / Qwen | `q_proj`, `k_proj`, `v_proj`, `o_proj`, `gate_proj`, `up_proj`, `down_proj` |
| Mistral / Mixtral | `q_proj`, `k_proj`, `v_proj`, `o_proj` |
| GPT-2 / BLOOM | `query_key_value`, `dense` |
| BERT | `query`, `key`, `value` |

## 高级技巧

### 多任务 LoRA 合并

```python
from peft import PeftModel

# 加载多个 LoRA adapter
base_model = AutoModelForCausalLM.from_pretrained(model_name)

model = PeftModel.from_pretrained(base_model, "./lora-task1")
model.load_adapter("./lora-task2", adapter_name="task2")

# 切换 adapter
model.set_adapter("task2")  # 使用 task2

# 合并 adapter
model.add_adapter("merged_adpater")
model.add_weighted_adapter(
    adapters=["default", "task2"],
    weights=[0.7, 0.3],
    adapter_name="ensemble",
)
```

### 梯度检查点

```python
model.gradient_checkpointing_enable()  # 节省显存，略慢
```

### 混合精度训练

```python
# 推荐使用 bf16（如果 GPU 支持）
training_args = TrainingArguments(
    bf16=True,     # A100/H100 推荐
    # fp16=True,  # V100/T4 使用 fp16
    tf32=True,     # 仅在 Ampere GPU 有效
)
```

## 合并与导出

### 合并 LoRA 权重到基础模型

```python
from peft import PeftModel

# 加载基础模型
base_model = AutoModelForCausalLM.from_pretrained(model_name)

# 加载 LoRA
model = PeftModel.from_pretrained(base_model, "./lora-qwen-output/checkpoint-100")

# 合并权重
merged_model = model.merge_and_unload()

# 保存合并后的模型
merged_model.save_pretrained("./merged-model")
tokenizer.save_pretrained("./merged-model")
```

### 仅保存 LoRA 权重（推荐）

```python
# 训练后直接保存
model.save_pretrained("./lora-weights")
tokenizer.save_pretrained("./lora-weights")

# 加载使用
from peft import PeftModel

base = AutoModelForCausalLM.from_pretrained(model_name)
lora_model = PeftModel.from_pretrained(base, "./lora-weights")
```

## 性能对比

### 7B 模型微调资源需求

| 方法 | 显存 | 训练速度 | 质量 |
|------|------|---------|------|
| 全参数 | ~60 GB | 1x | 100% |
| LoRA (bf16) | ~16 GB | 1.2x | 98-99% |
| QLoRA (4-bit) | ~10 GB | 0.8x | 97-99% |

## 常见问题

### bitsandbytes 安装问题

```bash
# Windows 需要特殊处理
pip install bitsandbytes-windows  # Windows 专用

# Linux 标准安装
pip install bitsandbytes

# 如果 CUDA 版本不匹配，从源码编译
pip install bitsandbytes --no-binary bitsandbytes
```

### 显存不足

- 使用 QLoRA（4-bit 量化）
- 降低 `per_device_train_batch_size`
- 增加 `gradient_accumulation_steps`
- 启用梯度检查点

### 过拟合

- 降低 `r` 值
- 增加 `lora_dropout`
- 使用更少的训练步数
- 添加权重衰减

## 参考链接

- PEFT 文档: https://huggingface.co/docs/peft
- GitHub: https://github.com/huggingface/peft
- LoRA 论文: https://arxiv.org/abs/2106.09685
- QLoRA 论文: https://arxiv.org/abs/2305.14314
