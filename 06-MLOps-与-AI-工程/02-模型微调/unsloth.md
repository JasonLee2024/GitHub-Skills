---
title: Unsloth — 快速 LLM 微调框架
description: 使用 Unsloth 实现 2-5x 更快、50-80% 更省显存的 LLM 微调，支持 LoRA/QLoRA 和多种模型架构
---

# Unsloth — 快速 LLM 微调框架

## 概述

Unsloth 是一个专注于 LLM 微调速度优化的框架，通过手动优化的 CUDA 内核和内存管理技术，实现比标准 HuggingFace + PEFT 方案 2-5 倍的训练加速和 50-80% 的显存节省。

### 核心特性

- **2-5x 训练加速**：手动优化 CUDA 内核，减少 kernel launch 开销
- **50-80% 显存节省**：优化的激活值内存管理
- **零精度损失**：加速不会降低模型质量
- **广谱模型支持**：LLaMA、Mistral、Qwen、Gemma、Phi 等 100+ 模型
- **与 HuggingFace 生态兼容**：Trainer / SFTTrainer 无缝集成
- **GGUF 导出**：微调后直接导出为 GGUF 格式用于 llama.cpp 推理

### 适用场景

| 场景 | 推荐 |
|------|------|
| 快速微调实验 | ✅ 首选，速度最快 |
| 显存受限环境 | ✅ 比 QLoRA 更省显存 |
| 消费级 GPU | ✅ RTX 3090/4090 可微调 7B |
| 生产级微调 | ⚠️ Axolotl 功能更全 |
| 全参数微调 | ⚠️ 使用 PyTorch FSDP |

## 安装

```bash
# 安装 Unsloth（自动安装依赖）
pip install unsloth

# 或者从源码安装最新版
pip install "unsloth[cu124] @ git+https://github.com/unslothai/unsloth.git"

# 验证安装
python -c "import unsloth; print(unsloth.__version__)"
```

## 快速开始

### 基础 LoRA 微调

```python
import torch
from unsloth import FastLanguageModel
from datasets import Dataset
from trl import SFTTrainer
from transformers import TrainingArguments

# 1. 加载模型（自动优化）
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Qwen2.5-1.5B-Instruct",
    max_seq_length=2048,
    dtype=None,           # 自动选择最佳 dtype
    load_in_4bit=False,   # 4-bit 量化
)

# 2. 添加 LoRA adapter
model = FastLanguageModel.get_peft_model(
    model,
    r=16,                  # LoRA 秩
    target_modules=[       # 目标模块
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
    lora_alpha=16,
    lora_dropout=0,
    bias="none",
    use_gradient_checkpointing="unsloth",  # Unsloth 优化的梯度检查点
    random_state=3407,
    max_seq_length=2048,
    use_rslora=False,     # LoRA 缩放
)

# 3. 准备数据
train_data = [
    {"instruction": "什么是机器学习？", "output": "机器学习是..."},
    {"instruction": "解释 Python 装饰器", "output": "装饰器是..."},
]

def format_func(examples):
    texts = []
    for inst, out in zip(examples["instruction"], examples["output"]):
        text = tokenizer.apply_chat_template([
            {"role": "user", "content": inst},
            {"role": "assistant", "content": out},
        ], tokenize=False)
        texts.append(text)
    return {"text": texts}

dataset = Dataset.from_dict({
    "instruction": [d["instruction"] for d in train_data],
    "output": [d["output"] for d in train_data],
})
dataset = dataset.map(format_func, batched=True)

# 4. 配置训练
training_args = TrainingArguments(
    output_dir="./unsloth-output",
    per_device_train_batch_size=2,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    learning_rate=2e-4,
    warmup_steps=5,
    logging_steps=10,
    save_steps=100,
    optim="adamw_8bit",
    weight_decay=0.01,
    lr_scheduler_type="linear",
    seed=3407,
    report_to="none",
)

# 5. 开始训练
trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    args=training_args,
)

trainer.train()
```

### QLoRA 微调（4-bit）

```python
# 仅需修改模型加载参数
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name="unsloth/Qwen2.5-1.5B-Instruct",
    max_seq_length=2048,
    dtype=None,
    load_in_4bit=True,  # 启用 4-bit 量化
)
```

## 核心优势详解

### 1. 手动优化 CUDA 内核

Unsloth 重写了 Transformer 中的以下操作：

- **MLP 前向传播**：融合 activation 计算
- **RMS LayerNorm**：减少全局内存访问
- **RoPE 旋转位置编码**：手动实现高效版本
- **交叉熵损失**：优化的 logits 处理

### 2. 内存优化

| 组件 | 标准实现 | Unsloth | 节省 |
|------|---------|---------|------|
| 激活值内存 | 全精度存储 | 选择性存储 | 50-70% |
| KV cache | 标准实现 | 优化分配 | 30% |
| 梯度检查点 | PyTorch 默认 | 手动优化 | 20% |

### 3. 速度对比

| 模型 | 标准 PEFT | Unsloth | 加速比 |
|------|-----------|---------|--------|
| LLaMA-3.2-1B | 10 min | 3 min | 3.3x |
| Qwen2.5-7B | 60 min | 20 min | 3x |
| LLaMA-3.1-8B | 90 min | 27 min | 3.3x |
| Mistral-7B | 55 min | 18 min | 3.1x |

## 高级用法

### 使用完整数据集

```python
from datasets import load_dataset

# 加载 HuggingFace 数据集
dataset = load_dataset("json", data_files="train.jsonl", split="train")

# 应用对话模板
def format_chat(example):
    messages = [
        {"role": "user", "content": example["question"]},
        {"role": "assistant", "content": example["answer"]},
    ]
    return {"text": tokenizer.apply_chat_template(messages, tokenize=False)}

dataset = dataset.map(format_chat)

# 训练
trainer = SFTTrainer(
    model=model,
    tokenizer=tokenizer,
    train_dataset=dataset,
    dataset_text_field="text",
    max_seq_length=2048,
    args=training_args,
)
trainer.train()
```

### 导出为 GGUF 格式

```python
# 保存 LoRA 权重
model.save_pretrained("./lora-weights")
tokenizer.save_pretrained("./lora-weights")

# 合并权重并导出为 GGUF
model.save_pretrained_merged("./merged-model", tokenizer, save_method="merged_16bit")

# 导出为 GGUF（用于 llama.cpp）
model.save_pretrained_gguf(
    "./gguf-export",
    tokenizer,
    quantization_method="q4_k_m",  # GGUF 量化方法
)
```

### 推理测试

```python
# 推理模式
FastLanguageModel.for_inference(model)

# 生成
inputs = tokenizer.apply_chat_template([
    {"role": "user", "content": "你好，请介绍一下自己"},
], tokenize=True, add_generation_prompt=True, return_tensors="pt").to("cuda")

outputs = model.generate(
    input_ids=inputs,
    max_new_tokens=256,
    temperature=0.7,
    top_p=0.9,
    do_sample=True,
)

response = tokenizer.decode(outputs[0], skip_special_tokens=True)
print(response)
```

## 模型支持

Unsloth 支持 100+ 模型架构，部分模型列表：

| 模型系列 | 自动优化 | 推荐模型 |
|---------|---------|---------|
| LLaMA 3.2 | ✅ | unsloth/Llama-3.2-1B-Instruct |
| LLaMA 3.1 | ✅ | unsloth/Llama-3.1-8B-Instruct |
| Qwen 2.5 | ✅ | unsloth/Qwen2.5-7B-Instruct |
| Mistral | ✅ | unsloth/mistral-7b-instruct-v0.3 |
| Gemma 2 | ✅ | unsloth/gemma-2-9b-it |
| Phi-3 | ✅ | unsloth/Phi-3-mini-4k-instruct |
| LLaMA 4 | ✅ | unsloth/Llama-4-Scout-17B-16E-Instruct |

## 最佳实践

### 1. 选择合适的 max_seq_length

```python
# 短文本任务（指令微调）
model, tokenizer = FastLanguageModel.from_pretrained(
    max_seq_length=2048,  # 足够
)

# 长文本任务（文档摘要）
model, tokenizer = FastLanguageModel.from_pretrained(
    max_seq_length=4096,
)
```

### 2. 优化批次大小

```python
# 显存不足时
training_args = TrainingArguments(
    per_device_train_batch_size=1,   # 减小批次
    gradient_accumulation_steps=8,   # 增加累积步数
    optim="adamw_8bit",              # 8-bit 优化器
)
```

### 3. 使用 Unsloth 的优化器

```python
# Unsloth 提供了优化版的 adamw_8bit
training_args = TrainingArguments(
    optim="adamw_8bit",  # 比默认的 adamw 省 50% 优化器显存
)
```

## 常见问题

### 显存不足

```python
# 解决方案
model, tokenizer = FastLanguageModel.from_pretrained(
    max_seq_length=1024,   # 缩短序列长度
    load_in_4bit=True,     # 使用 4-bit
    dtype=torch.float16,   # 使用 fp16
)

training_args = TrainingArguments(
    per_device_train_batch_size=1,
    gradient_accumulation_steps=16,
    optim="adamw_8bit",
)
```

### 训练不稳定

- 降低学习率（1e-4 → 5e-5）
- 增加 warmup 步数
- 使用 `use_gradient_checkpointing="unsloth"`

### 输出质量差

- 增加训练数据量
- 提高 `r` 值（16 → 32）
- 检查数据格式是否正确

## 参考链接

- 文档: https://docs.unsloth.ai
- GitHub: https://github.com/unslothai/unsloth
- 模型库: https://huggingface.co/unsloth
- Discord: https://discord.gg/u54VK2nP3C
