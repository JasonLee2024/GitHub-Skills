---
title: vLLM — 高性能 LLM 推理服务
description: 使用 vLLM 的 PagedAttention 技术实现高吞吐、低延迟的 LLM 推理服务部署
---

# vLLM — 高性能 LLM 推理服务

## 概述

vLLM 是一个高吞吐量、低内存的 LLM 推理引擎，由加州大学伯克利分校开发。其核心创新 PagedAttention 技术解决了传统推理系统中 KV cache 的内存碎片问题，实现了接近理论最优的内存利用率。

### 核心特性

- **PagedAttention**：类操作系统的分页机制管理 KV cache，消除内存碎片
- **连续批处理**（Continuous Batching）：动态调度请求，最大化 GPU 利用率
- **PREFIX caching**：复用相同的 prompt 前缀的 KV cache
- **OpenAI 兼容 API**：即插即用替代 OpenAI API
- **量化支持**：AWQ、GPTQ、FP8 等多种量化格式
- **多 GPU 支持**：Tensor Parallelism 和 Pipeline Parallelism
- **Speculative Decoding**：推测解码加速生成

### 适用场景

| 场景 | 推荐 |
|------|------|
| NVIDIA GPU 高吞吐服务 | ✅ 首选方案 |
| 生产级 API 部署 | ✅ 行业标准 |
| 多模型服务 | ✅ 多 LoRA 支持 |
| CPU 或非 NVIDIA GPU | ❌ 使用 llama.cpp |

## 安装

```bash
# 使用 pip 安装
pip install vllm

# 从源码安装（获取最新特性）
git clone https://github.com/vllm-project/vllm.git
cd vllm
pip install -e .

# 验证安装
python -c "import vllm; print(vllm.__version__)"
```

## 快速开始

### 命令行推理

```bash
# 单次生成
vllm serve Qwen/Qwen2.5-7B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.85

# 带 AWQ 量化
vllm serve Qwen/Qwen2.5-7B-Instruct-AWQ \
    --quantization awq \
    --dtype auto
```

### Python API

```python
from vllm import LLM, SamplingParams

# 加载模型
llm = LLM(
    model="Qwen/Qwen2.5-7B-Instruct",
    tensor_parallel_size=1,  # GPU 数量
    gpu_memory_utilization=0.85,
    max_model_len=8192,
)

# 配置采样参数
sampling_params = SamplingParams(
    temperature=0.7,
    top_p=0.9,
    max_tokens=512,
)

# 批量推理
prompts = [
    "用中文解释什么是机器学习",
    "Python 中的装饰器是什么",
    "简述 TCP/IP 协议栈",
]

outputs = llm.generate(prompts, sampling_params)

for output in outputs:
    prompt = output.prompt
    generated_text = output.outputs[0].text
    print(f"提示: {prompt!r}")
    print(f"生成: {generated_text}")
    print("-" * 50)
```

### OpenAI 兼容服务器

```bash
# 启动 API 服务器
vllm serve Qwen/Qwen2.5-7B-Instruct \
    --host 0.0.0.0 \
    --port 8000 \
    --api-key your-secret-key

# 聊天补全请求
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secret-key" \
  -d '{
    "model": "Qwen/Qwen2.5-7B-Instruct",
    "messages": [
      {"role": "system", "content": "你是一个有用的助手。"},
      {"role": "user", "content": "用中文写一首关于春天的诗"}
    ],
    "temperature": 0.7,
    "max_tokens": 256
  }'
```

客户端调用：

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="your-secret-key",
)

response = client.chat.completions.create(
    model="Qwen/Qwen2.5-7B-Instruct",
    messages=[
        {"role": "user", "content": "什么是 PagedAttention？"}
    ],
    temperature=0.7,
    max_tokens=512,
)

print(response.choices[0].message.content)
```

## 核心配置

### 采样参数

```python
from vllm import SamplingParams

# 基础配置
params = SamplingParams(
    temperature=0.8,
    top_p=0.95,
    top_k=50,
    max_tokens=1024,
    presence_penalty=0.1,
    frequency_penalty=0.1,
    stop=["<|im_end|>", "<|endoftext|>"],
)

# 束搜索（Beam Search）
beam_params = SamplingParams(
    temperature=0.0,
    best_of=4,
    use_beam_search=True,
    max_tokens=256,
)

# 流式输出
stream_params = SamplingParams(
    temperature=0.7,
    max_tokens=256,
)
```

### 服务器配置

```bash
vllm serve Qwen/Qwen2.5-7B-Instruct \
    # 模型配置
    --dtype auto \
    --max-model-len 16384 \
    --trust-remote-code \
    --revision main \
    \
    # 性能配置
    --tensor-parallel-size 2 \
    --pipeline-parallel-size 1 \
    --gpu-memory-utilization 0.90 \
    --max-num-seqs 256 \
    \
    # 服务质量
    --max-logprobs 20 \
    --enable-prefix-caching \
    --disable-log-requests \
    \
    # 网络配置
    --host 0.0.0.0 \
    --port 8000 \
    --api-key your-secret-key
```

## 高级特性

### PagedAttention

PagedAttention 是 vLLM 的核心创新，灵感来自操作系统的虚拟内存分页：

**传统方式的问题：**
- KV cache 预分配连续内存
- 内部碎片和外部碎片
- 利用率仅 20-40%

**PagedAttention 方案：**
- KV cache 按块（Block）管理，每块包含固定数量 token
- 物理上不连续，逻辑上连续
- 内存利用率接近 100%

### 连续批处理

传统批处理是所有请求同时开始、同时结束。连续批处理允许：

1. 新请求立即加入正在运行的批次
2. 完成的请求立即返回，释放资源
3. GPU 始终处理最大可能的批次

```python
# vLLM 自动处理连续批处理
# 只需正常调用，无需额外配置
llm = LLM(model="Qwen/Qwen2.5-7B-Instruct")

# 流式请求在连续批处理中表现优异
for request in streaming_requests:
    response = llm.generate(request, sampling_params)
```

### Prefix Caching

适合相同 prompt 前缀的请求（如多轮对话、系统提示相同）：

```bash
vllm serve model --enable-prefix-caching
```

启用后，相同的 prompt 前缀会复用已有的 KV cache，可将首 token 延迟降低 50-80%。

### Speculative Decoding

使用小模型辅助大模型生成，加速 2-3x：

```bash
vllm serve meta-llama/Llama-3.1-70B-Instruct \
    --speculative-model meta-llama/Llama-3.1-8B-Instruct \
    --num-speculative-tokens 5
```

### 多 LoRA 支持

同时服务多个 LoRA adapter：

```bash
vllm serve meta-llama/Llama-3.1-8B \
    --enable-lora \
    --lora-modules lora1=./lora-adapter-1 lora2=./lora-adapter-2 \
    --max-lora-rank 64
```

API 调用时指定 LoRA：

```python
response = client.chat.completions.create(
    model="lora1",  # 使用 lora-adapter-1
    messages=[{"role": "user", "content": "你好"}],
)
```

## 量化支持

### AWQ（推荐）

```bash
# 使用 AWQ 量化模型
vllm serve Qwen/Qwen2.5-7B-Instruct-AWQ \
    --quantization awq \
    --dtype half
```

### GPTQ

```bash
vllm serve TheBloke/Llama-2-7B-GPTQ \
    --quantization gptq \
    --dtype half
```

### FP8（H100/H200）

```bash
vllm serve meta-llama/Llama-3.1-8B-Instruct \
    --dtype float16 \
    --quantization fp8
```

## 性能优化

### GPU 内存配置

```python
# 保留更多显存给 KV cache
llm = LLM(
    model="Qwen/Qwen2.5-7B-Instruct",
    gpu_memory_utilization=0.95,  # 最大显存利用率
    max_model_len=4096,           # 降低上下文长度
)
```

### 批处理大小

```python
# 增加并发请求数
llm = LLM(
    model="Qwen/Qwen2.5-7B-Instruct",
    max_num_seqs=256,     # 最大并发序列
    max_num_batched_tokens=8192,  # 批处理 token 上限
)
```

### 性能基准

| 配置 | 7B 模型 | 70B 模型 |
|------|---------|----------|
| 1× A100-80G | 2000 tok/s | - |
| 4× A100-80G | - | 800 tok/s |
| 8× A100-80G | - | 1500 tok/s |
| 1× H100-80G | 3500 tok/s | - |

## 与 HuggingFace Transformers 集成

```python
from vllm import LLM
from transformers import AutoTokenizer

# 加载 tokenizer（可选，vLLM 会自动加载）
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-7B-Instruct")

# 使用 vLLM 推理
llm = LLM(model="Qwen/Qwen2.5-7B-Instruct")

# 应用聊天模板
prompts = [
    tokenizer.apply_chat_template(
        [{"role": "user", "content": "你好"}],
        tokenize=False,
        add_generation_prompt=True,
    )
]

outputs = llm.generate(prompts, sampling_params)
```

## 监控与日志

### Prometheus 指标

vLLM 内置 Prometheus 指标：

```bash
vllm serve model --enable-metrics
```

指标包括：
- `vllm:num_requests_running`：运行中的请求数
- `vllm:num_requests_waiting`：等待中的请求数
- `vllm:gpu_cache_usage`：GPU KV cache 使用率
- `vllm:time_to_first_token`：首 token 延迟
- `vllm:request_throughput`：请求吞吐量

## 常见问题

### 显存不足（OOM）

```bash
# 降低显存利用率
vllm serve model --gpu-memory-utilization 0.7

# 缩短上下文长度
vllm serve model --max-model-len 2048

# 使用量化
vllm serve model --quantization awq
```

### 输出质量差

- 检查 `temperature` 和 `top_p` 设置
- 确保 `max_model_len` 足够长
- 确认模型与任务匹配

### CUDA 错误

```bash
# 检查 CUDA 版本
nvidia-smi
python -c "import torch; print(torch.version.cuda)"

# 确保 vLLM 版本兼容
pip install --upgrade vllm
```

## 总结

vLLM 是生产环境部署 LLM 服务的首选方案，特别适合：

1. **NVIDIA GPU 集群**：最大化硬件利用率
2. **高吞吐 API 服务**：连续批处理 + PagedAttention
3. **多模型管理**：多 LoRA 支持
4. **企业级部署**：Prometheus 监控、Docker 支持

### 参考链接

- 文档: https://docs.vllm.ai
- GitHub: https://github.com/vllm-project/vllm
- 论文: https://arxiv.org/abs/2309.06180
- 模型支持: https://docs.vllm.ai/en/latest/models/supported_models.html
