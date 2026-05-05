---
title: TRL — 强化学习微调（RLHF/DPO/GRPO）
description: 使用 HuggingFace TRL 库进行 RLHF、DPO、GRPO 等强化学习微调，实现 LLM 与人类偏好的对齐
---

# TRL — 强化学习微调（RLHF/DPO/GRPO）

## 概述

TRL（Transformer Reinforcement Learning）是 HuggingFace 的强化学习微调库，支持多种人类对齐技术：从经典的 RLHF（基于 PPO）到更现代的 DPO、KTO、ORPO、GRPO 等方法。

### 核心概念

- **RLHF**：经典三阶段：SFT → 奖励建模 → PPO 强化学习
- **DPO**：直接偏好优化，无需单独的奖励模型
- **GRPO**：群体相对偏好优化，DeepSeek-R1 使用的训练方法
- **KTO**：基于 Kahneman-Tversky 优化，只需针对单个输出的反馈
- **ORPO**：在 SFT 过程中直接加入偏好约束

### 方法对比

| 方法 | 需要奖励模型 | 需要参考模型 | 数据要求 | 训练效率 |
|------|------------|------------|---------|---------|
| RLHF (PPO) | ✅ 是 | ✅ 是 | 成对偏好 | 低 |
| DPO | ❌ 否 | ✅ 是 | 成对偏好 | 中 |
| GRPO | ❌ 否 | ❌ 否 | 成对偏好 | 高 |
| KTO | ❌ 否 | ✅ 是 | 单输出反馈 | 中 |
| ORPO | ❌ 否 | ❌ 否 | 成对偏好 | 高 |

## 安装

```bash
pip install trl transformers datasets accelerate peft
```

## DPO：直接偏好优化

DPO 是目前最流行的对齐方法，直接在偏好数据上优化策略，无需训练奖励模型。

### 准备偏好数据

```python
from datasets import Dataset

# DPO 需要 (prompt, chosen, rejected) 三元组
data = [
    {
        "prompt": "什么是机器学习？",
        "chosen": "机器学习是人工智能的一个分支...",
        "rejected": "我不知道定义，但大概就是让机器自己学习？",
    },
    {
        "prompt": "Python 的特点是什么？",
        "chosen": "Python 是一种解释型、高级编程语言...",
        "rejected": "Python 是一种语言。",
    },
]

dataset = Dataset.from_list(data)
```

### DPO 训练

```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from trl import DPOTrainer, DPOConfig
from peft import LoraConfig, get_peft_model

# 加载基础模型
model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen2.5-1.5B-Instruct",
    torch_dtype=torch.bfloat16,
    device_map="auto",
)

# 加载参考模型（DPO 需要）
ref_model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen2.5-1.5B-Instruct",
    torch_dtype=torch.bfloat16,
    device_map="auto",
)

tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-1.5B-Instruct")
tokenizer.pad_token = tokenizer.eos_token

# LoRA 配置
lora_config = LoraConfig(
    r=8,
    lora_alpha=32,
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

# 应用 LoRA
model = get_peft_model(model, lora_config)

# 训练配置
dpo_config = DPOConfig(
    output_dir="./dpo-output",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    learning_rate=1e-5,
    warmup_steps=100,
    logging_steps=10,
    save_steps=100,
    bf16=True,
    beta=0.1,  # DPO 的温度参数
    max_length=1024,
    max_prompt_length=512,
)

# 创建 DPO Trainer
trainer = DPOTrainer(
    model=model,
    ref_model=ref_model,
    args=dpo_config,
    train_dataset=dataset,
    tokenizer=tokenizer,
    peft_config=lora_config,
)

trainer.train()
```

## GRPO：群体相对偏好优化

GRPO 是 DeepSeek-R1 使用的训练方法，不需要参考模型，更高效。

```python
from trl import GRPOTrainer, GRPOConfig

# GRPO 配置
grpo_config = GRPOConfig(
    output_dir="./grpo-output",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    learning_rate=1e-6,
    warmup_steps=100,
    logging_steps=10,
    save_steps=100,
    bf16=True,
    # GRPO 特有参数
    num_generations=4,         # 每组生成的候选数
    max_completion_length=512,  # 生成长度
    beta=0.04,                 # KL 惩罚系数
)

# 创建 GRPO Trainer
trainer = GRPOTrainer(
    model=model,
    args=grpo_config,
    train_dataset=dataset,
    tokenizer=tokenizer,
    reward_funcs=[reward_function],  # 奖励函数
)

trainer.train()
```

## ORPO：直接在 SFT 中偏好优化

ORPO 将偏好优化融入 SFT 过程，无需单独的偏好训练阶段：

```python
from trl import ORPOTrainer, ORPOConfig

orpo_config = ORPOConfig(
    output_dir="./orpo-output",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    num_train_epochs=3,
    learning_rate=1e-5,
    warmup_steps=100,
    logging_steps=10,
    save_steps=100,
    bf16=True,
    beta=0.1,  # ORPO 的偏好强度
)

trainer = ORPOTrainer(
    model=model,
    args=orpo_config,
    train_dataset=dataset,  # 同样需要偏好数据
    tokenizer=tokenizer,
)

trainer.train()
```

## KTO：单输出反馈优化

KTO 只需要对单个输出的反馈（好/不好），不需要成对比较：

```python
from trl import KTOTrainer, KTOConfig

# KTO 只需要 (prompt, completion, label)
kto_data = [
    {"prompt": "解释机器学习", "completion": "机器学习是...", "label": True},  # 好的
    {"prompt": "解释 Python", "completion": "Python 是...", "label": True},    # 好的
    {"prompt": "写一首诗", "completion": "哦哦哦哦...", "label": False},        # 差的
]

dataset = Dataset.from_list(kto_data)

kto_config = KTOConfig(
    output_dir="./kto-output",
    per_device_train_batch_size=4,
    num_train_epochs=3,
    learning_rate=1e-5,
    bf16=True,
    beta=0.1,
)

trainer = KTOTrainer(
    model=model,
    args=kto_config,
    train_dataset=dataset,
    tokenizer=tokenizer,
)

trainer.train()
```

## RLHF (PPO)：经典三阶段

完整的 RLHF 流程包含三个阶段：

### 阶段 1：SFT（监督微调）

```python
from trl import SFTTrainer

# 在有监督数据上微调
sft_trainer = SFTTrainer(
    model=model,
    train_dataset=sft_dataset,
    args=TrainingArguments(output_dir="./sft-output"),
)
sft_trainer.train()
```

### 阶段 2：奖励模型训练

```python
from trl import RewardTrainer

# 训练奖励模型
reward_trainer = RewardTrainer(
    model=reward_model,
    args=TrainingArguments(output_dir="./rm-output"),
    train_dataset=preference_dataset,
    tokenizer=tokenizer,
)
reward_trainer.train()
```

### 阶段 3：PPO 强化学习

```python
from trl import PPOTrainer, PPOConfig

ppo_config = PPOConfig(
    model_name="Qwen/Qwen2.5-1.5B-Instruct",
    learning_rate=1e-5,
    batch_size=4,
    mini_batch_size=1,
    gradient_accumulation_steps=4,
)

ppo_trainer = PPOTrainer(
    config=ppo_config,
    model=model,
    ref_model=ref_model,
    tokenizer=tokenizer,
    dataset=dataset,
)

# PPO 训练循环
for epoch in range(3):
    for batch in ppo_trainer.dataloader:
        # 生成响应
        response_tensors = ppo_trainer.generate(batch["input_ids"])

        # 计算奖励
        rewards = reward_model(batch["input_ids"], response_tensors)

        # PPO 步骤
        stats = ppo_trainer.step(
            batch["input_ids"],
            response_tensors,
            rewards,
        )
```

## 数据准备最佳实践

### 偏好数据格式

```jsonl
# DPO/GRPO 格式（成对偏好）
{"prompt": "问题", "chosen": "好的回答", "rejected": "差的回答"}

# KTO 格式（单输出反馈）
{"prompt": "问题", "completion": "回答", "label": true}

# RLHF 格式（奖励训练）
{"prompt": "问题", "chat": "完整对话", "chosen": "更好", "rejected": "更差"}
```

### 数据质量控制

```python
# 过滤过短/过长的样本
def filter_data(example):
    return (
        len(example["chosen"]) > 20 and
        len(example["rejected"]) > 20 and
        len(example["chosen"]) < 2048
    )

dataset = dataset.filter(filter_data)
```

## 评估对齐效果

```python
from trl import evaluate_alignment

# 使用内置评估
results = evaluate_alignment(
    model=model,
    tokenizer=tokenizer,
    eval_dataset=test_dataset,
)

print(f"偏好准确率: {results['accuracy']:.2%}")
print(f"平均奖励: {results['avg_reward']:.3f}")
```

## 常见问题

### DPO 训练不稳定

- 降低 `beta` 值（0.1 → 0.05）
- 降低学习率（1e-5 → 5e-6）
- 增加训练数据量

### 模型太保守（过度对齐）

- 提高 `beta` 值（0.1 → 0.2）
- 在偏好数据中混入非偏好数据

### 奖励攻击（Reward Hacking）

- 使用多个奖励函数
- 添加 KL 惩罚项
- 限制生成长度

## 选择建议

| 你的场景 | 推荐方法 |
|---------|---------|
| 有大量成对偏好数据 | DPO |
| 需要简单高效 | ORPO（融入 SFT） |
| 只有单输出评分 | KTO |
| 有自定义奖励函数 | GRPO（如 DeepSeek-R1） |
| 需要完整控制流程 | RLHF (PPO) |

## 参考链接

- 文档: https://huggingface.co/docs/trl
- GitHub: https://github.com/huggingface/trl
- DPO 论文: https://arxiv.org/abs/2305.18290
- GRPO 论文: https://arxiv.org/abs/2402.03300
- DeepSeek-R1: https://arxiv.org/abs/2501.12948
