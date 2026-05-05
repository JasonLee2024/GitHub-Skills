---
title: PyTorch FSDP — 全分片数据并行分布式训练
description: 使用 PyTorch 的 Fully Sharded Data Parallel 进行大规模分布式训练，支持参数分片、混合精度和 CPU offloading
---

# PyTorch FSDP — 全分片数据并行分布式训练

## 概述

FSDP（Fully Sharded Data Parallel）是 PyTorch 官方的分布式训练方案，灵感来自 DeepSpeed ZeRO Stage 3。它将模型参数、梯度和优化器状态分片到多个 GPU 上，使得训练大模型成为可能。

### 核心概念

- **参数分片**：每个 GPU 只保存模型参数的一部分
- **通信高效**：仅在需要时通过 all-gather 收集完整参数
- **显存节省**：ZeRO Stage 3 级别的优化，显存随 GPU 数量线性减少
- **混合精度**：与 AMP（自动混合精度）完美结合
- **CPU Offloading**：将参数卸载到 CPU 内存，进一步降低 GPU 显存需求

### FSDP vs 其他分布式策略

| 方法 | 参数存储 | 梯度存储 | 优化器状态 | 显存节省 | 通信开销 |
|------|---------|---------|-----------|---------|---------|
| DDP | 副本 | 副本 | 副本 | 低 | 低 |
| ZeRO-1 | 副本 | 分片 | 分片 | 中 | 低 |
| ZeRO-2 | 副本 | 分片 | 分片 | 中 | 低 |
| ZeRO-3 / FSDP | 分片 | 分片 | 分片 | 高 | 高 |
| FSDP + CPU Offload | 分片(CPU) | 分片 | 分片(CPU) | 最高 | 最高 |

## 安装要求

```bash
pip install torch>=2.0.0 transformers accelerate datasets
```

## 快速开始

### 基础 FSDP 训练脚本

```python
# train_fsdp.py
import os
import torch
import torch.distributed as dist
from torch.distributed.fsdp import (
    FullyShardedDataParallel as FSDP,
    CPUOffload,
    MixedPrecision,
    BackwardPrefetch,
    ShardingStrategy,
)
from torch.distributed.fsdp.wrap import (
    transformer_auto_wrap_policy,
    size_based_auto_wrap_policy,
)
from torch.distributed.fsdp.api import StateDictType
from transformers import AutoModelForCausalLM, AutoTokenizer, TrainingArguments
from accelerate import Accelerator
import torch.nn as nn

# 初始化分布式环境
local_rank = int(os.environ["LOCAL_RANK"])
world_size = int(os.environ["WORLD_SIZE"])

torch.cuda.set_device(local_rank)
dist.init_process_group(backend="nccl")

# 加载模型
model_name = "Qwen/Qwen2.5-1.5B-Instruct"
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    torch_dtype=torch.bfloat16,
)

tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

# FSDP 包装策略 - 基于 Transformer 层自动包装
from transformers.models.llama.modeling_llama import LlamaDecoderLayer

auto_wrap_policy = transformer_auto_wrap_policy(
    transformer_layer_cls={LlamaDecoderLayer},
)

# 混合精度配置
mixed_precision = MixedPrecision(
    param_dtype=torch.bfloat16,
    reduce_dtype=torch.bfloat16,
    buffer_dtype=torch.bfloat16,
)

# 创建 FSDP 模型
fsdp_model = FSDP(
    model,
    auto_wrap_policy=auto_wrap_policy,
    mixed_precision=mixed_precision,
    cpu_offload=CPUOffload(offload_params=False),
    backward_prefetch=BackwardPrefetch.BACKWARD_PRE,
    sharding_strategy=ShardingStrategy.FULL_SHARD,
    device_id=local_rank,
)

# 优化器
optimizer = torch.optim.AdamW(fsdp_model.parameters(), lr=2e-5)

# 训练循环
fsdp_model.train()
for epoch in range(3):
    for batch in dataloader:
        input_ids = batch["input_ids"].to(local_rank)
        labels = batch["labels"].to(local_rank)

        outputs = fsdp_model(input_ids=input_ids, labels=labels)
        loss = outputs.loss

        loss.backward()
        optimizer.step()
        optimizer.zero_grad()

        if local_rank == 0:
            print(f"Epoch {epoch}, Loss: {loss.item():.4f}")

# 保存模型（仅在 rank 0）
if local_rank == 0:
    # FSDP 保存
    if fsdp_model:
        FSDP.save_model(
            fsdp_model,
            "./fsdp-checkpoint",
            rank0_only=True,
        )
    tokenizer.save_pretrained("./fsdp-checkpoint")

dist.destroy_process_group()
```

### 运行训练

```bash
# 单节点 4 GPU
torchrun --nproc_per_node=4 train_fsdp.py

# 单节点 8 GPU
torchrun --nproc_per_node=8 train_fsdp.py

# 多节点（每节点 8 GPU）
torchrun \
    --nnodes=2 \
    --nproc_per_node=8 \
    --node_rank=0 \
    --master_addr=master_ip \
    --master_port=29500 \
    train_fsdp.py
```

## FSDP 配置详解

### 分片策略

```python
from torch.distributed.fsdp import ShardingStrategy

# 完整分片（ZeRO-3 等效）
strategy = ShardingStrategy.FULL_SHARD

# 混合分片（ZeRO-2 等效，节省通信）
strategy = ShardingStrategy.HYBRID_SHARD

# 不分片（DDP 等效）
strategy = ShardingStrategy.NO_SHARD

# 仅分片部分参数
strategy = ShardingStrategy.SHARD_GRAD_OP  # ZeRO-2
```

### 自动包装策略

```python
# 策略 1：基于 Transformer 层
from torch.distributed.fsdp.wrap import transformer_auto_wrap_policy
from transformers.models.llama.modeling_llama import LlamaDecoderLayer

auto_wrap_policy = transformer_auto_wrap_policy(
    transformer_layer_cls={
        LlamaDecoderLayer,
        # 可以添加多种层类型
    },
)

# 策略 2：基于参数大小
from torch.distributed.fsdp.wrap import size_based_auto_wrap_policy

size_policy = size_based_auto_wrap_policy(
    min_num_params=100_000_000,  # 1 亿参数以上才包装
)

# 策略 3：自定义包装
def custom_wrap_policy(module: nn.Module, recurse: bool, nonwrapped_numel: int) -> bool:
    # 仅在特定条件下包装
    return nonwrapped_numel >= 50_000_000
```

### 混合精度

```python
from torch.distributed.fsdp import MixedPrecision
import torch

# BF16 混合精度（推荐，A100/H100）
bf16_policy = MixedPrecision(
    param_dtype=torch.bfloat16,
    reduce_dtype=torch.bfloat16,
    buffer_dtype=torch.bfloat16,
)

# FP16 混合精度（V100/T4）
fp16_policy = MixedPrecision(
    param_dtype=torch.float16,
    reduce_dtype=torch.float16,
    buffer_dtype=torch.float16,
)

# 仅通信使用低精度
comm_policy = MixedPrecision(
    param_dtype=torch.float32,  # 参数保持 FP32
    reduce_dtype=torch.float16,  # 梯度规约用 FP16
    buffer_dtype=torch.float32,
)
```

### CPU Offloading

```python
from torch.distributed.fsdp import CPUOffload

# 仅卸载参数
cpu_offload = CPUOffload(offload_params=True)

# 不卸载（更快但更耗显存）
cpu_offload = CPUOffload(offload_params=False)
```

## 使用 Accelerate 简化 FSDP

HuggingFace Accelerate 提供了更简洁的 FSDP 接口：

```python
# 方式 1：配置文件
"""
# fsdp_config.yaml
compute_environment: LOCAL_MACHINE
distributed_type: FSDP
fsdp_config:
  fsdp_auto_wrap_policy: TRANSFORMER_BASED_WRAP
  fsdp_backward_prefetch_policy: BACKWARD_PRE
  fsdp_cpu_ram_efficient_loading: true
  fsdp_forward_prefetch: false
  fsdp_offload_params: false
  fsdp_sharding_strategy: 1  # FULL_SHARD
  fsdp_state_dict_type: FULL_STATE_DICT
  fsdp_transformer_layer_cls_to_wrap: LlamaDecoderLayer
  fsdp_use_orig_params: true
machine_rank: 0
main_process_ip: null
main_process_port: null
main_training_function: main
mixed_precision: bf16
num_machines: 1
num_processes: 8
use_cpu: false
"""

# 运行
# accelerate launch --config_file fsdp_config.yaml train.py
```

### Accelerate 训练脚本

```python
# train_accelerate.py
from accelerate import Accelerator
from accelerate.utils import DummyOptim, DummyScheduler
from transformers import AutoModelForCausalLM, get_scheduler
import torch

accelerator = Accelerator()

model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen2.5-1.5B-Instruct",
    torch_dtype=torch.bfloat16,
)

optimizer = torch.optim.AdamW(model.parameters(), lr=2e-5)

# Accelerate 自动处理 FSDP 包装
model, optimizer, dataloader = accelerator.prepare(
    model, optimizer, dataloader
)

# 训练循环
for epoch in range(3):
    for batch in dataloader:
        with accelerator.accumulate(model):
            outputs = model(**batch)
            loss = outputs.loss
            accelerator.backward(loss)
            optimizer.step()
            optimizer.zero_grad()

        if accelerator.sync_gradients:
            accelerator.log({"loss": loss.item()})

# 保存
accelerator.save_state("./checkpoint")
```

## FSDP2（PyTorch 2.4+）

FSDP2 是 PyTorch 2.4 引入的下一代 FSDP 实现，使用 `composable` API：

```python
# PyTorch >= 2.4 的 FSDP2
import torch.distributed.fsdpx as fsdpx

# FSDP2 使用 composable API
from torch.distributed._composable.fsdp import fully_shard

# 对每一层应用 FSDP
for layer in model.model.layers:
    fully_shard(layer)

# 对整个模型应用 FSDP
fully_shard(model)

# 训练与 FSDP 相同
optimizer = torch.optim.AdamW(model.parameters(), lr=2e-5)
```

### FSDP2 优势

- **更快的编译集成**：与 `torch.compile` 更好配合
- **更低的内存碎片**：改进的内存管理
- **更简洁的 API**：无需复杂的包装策略配置
- **更好的通信重叠**：计算和通信更高效地重叠

## 训练大模型的配置建议

### 7B 模型（8× A100-80G）

```python
fsdp_model = FSDP(
    model,
    auto_wrap_policy=transformer_based_policy,
    mixed_precision=bf16_policy,
    sharding_strategy=ShardingStrategy.FULL_SHARD,
    backward_prefetch=BackwardPrefetch.BACKWARD_PRE,
)

# 批次配置
batch_size = 4          # per GPU
grad_accum = 8          # 梯度累积
global_batch = 4 * 8 * 8 = 256
```

### 70B 模型（8× A100-80G）

```python
# 必须使用 FSDP + CPU Offload
fsdp_model = FSDP(
    model,
    auto_wrap_policy=transformer_based_policy,
    mixed_precision=bf16_policy,
    cpu_offload=CPUOffload(offload_params=True),  # CPU 卸载
    sharding_strategy=ShardingStrategy.FULL_SHARD,
)

# 更小的批次
batch_size = 1
grad_accum = 32
```

## 性能调优

### 通信优化

```python
# 启用前向预取
FSDP(model, forward_prefetch=True)

# 启用后向预取
FSDP(model, backward_prefetch=BackwardPrefetch.BACKWARD_PRE)

# 限制分片大小
FSDP(model, limit_all_gathers=True)
```

### 内存优化

```python
# 梯度 checkpoint
model.gradient_checkpointing_enable()

# 使用参数原生 API
FSDP(model, use_orig_params=True)
```

### NCCL 环境变量

```bash
# 优化 NCCL 通信
export NCCL_ALGO=Ring
export NCCL_PROTO=Simple
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0  # 如果有 InfiniBand
export NCCL_IB_HCA=mlx5_0  # InfiniBand 设备
```

## 检查点管理

### 保存检查点

```python
# 方式 1：保存完整状态
FSDP.save_model(fsdp_model, "./checkpoint")

# 方式 2：仅保存权重（推荐，兼容性好）
if fsdp_model:
    FSDP.save_model(
        fsdp_model,
        "./checkpoint",
        rank0_only=True,  # 只在 rank 0 保存
    )

# 方式 3：使用 state_dict
state_dict = fsdp_model.state_dict()
if dist.get_rank() == 0:
    torch.save(state_dict, "./checkpoint/model.pt")
```

### 加载检查点

```python
# 方式 1：加载完整状态
FSDP.load_model(fsdp_model, "./checkpoint")

# 方式 2：加载 state_dict
state_dict = torch.load("./checkpoint/model.pt")
fsdp_model.load_state_dict(state_dict)
```

## 常见问题

### NCCL 超时

```bash
# 增加超时时间
export NCCL_TIMEOUT=600
export NCCL_SOCKET_TIMEOUT=600
```

### 显存不足

- 使用 CPU Offload
- 降低批次大小
- 启用梯度检查点
- 使用更小的模型或更高的量化

### 训练速度慢

- 检查 NCCL 通信是否正常
- 启用 `limit_all_gathers=True`
- 使用 `mixed_precision`（bf16）
- 确保 CPU 数据加载不成为瓶颈

## 参考链接

- FSDP 文档: https://pytorch.org/docs/stable/fsdp.html
- FSDP2 文档: https://pytorch.org/docs/main/fsdp2.html
- Accelerate FSDP: https://huggingface.co/docs/accelerate/main/en/fsdp
- ZeRO 论文: https://arxiv.org/abs/1910.02054
- PyTorch 分布式教程: https://pytorch.org/tutorials/intermediate/ddp_tutorial.html
