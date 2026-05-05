---
title: llama.cpp — 本地 LLM 推理框架
description: 使用 llama.cpp 在 CPU/Apple Silicon/AMD GPU 上运行 LLM 推理，GGUF 量化模型格式详解
---

# llama.cpp — 本地 LLM 推理框架

## 概述

llama.cpp 是一个纯 C/C++ 实现的 LLM 推理框架，以极少的依赖、跨平台的硬件支持和灵活的量化能力著称。它使用 GGUF（GPT-Generated Unified Format）模型格式，支持从 2-bit 到 8-bit 的多种量化级别。

### 核心特性

- **跨平台**：CPU、Apple Silicon（Metal）、NVIDIA（CUDA）、AMD（ROCm）、Intel GPU
- **无 Python 运行时依赖**：纯 C/C++ 可执行文件，单二进制部署
- **丰富的量化格式**：K-quants、IQ-quants，2-bit 到 8-bit
- **OpenAI 兼容 API**：内置 HTTP 服务器，可直接替代 OpenAI API
- **生态系统丰富**：Ollama、LM Studio、text-generation-webui 均基于 llama.cpp

### 适用场景

| 场景 | 推荐 |
|------|------|
| CPU 无 GPU 环境 | ✅ 首选，纯 CPU 推理 |
| Apple Silicon Mac | ✅ Metal 加速，性能优异 |
| 边缘设备 / 嵌入式 | ✅ 单二进制部署 |
| 需要灵活量化 | ✅ 2-8 bit K-quants |
| 高吞吐服务 | ❌ 使用 vLLM |
| NVIDIA GPU 优化 | ⚠️ 可用，但 vLLM/TensorRT-LLM 更好 |

## 安装

### 从源码编译

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

# CPU only
make

# Apple Silicon (Metal 加速)
make GGML_METAL=1

# NVIDIA CUDA
make GGML_CUDA=1

# AMD ROCm
make LLAMA_HIP=1

# Intel GPU (OneAPI)
make GGML_SYCL=1
```

### macOS 使用 Homebrew

```bash
brew install llama.cpp
```

### Python 绑定

```bash
pip install llama-cpp-python

# 带 CUDA 支持
CMAKE_ARGS="-DGGML_CUDA=on" pip install llama-cpp-python --force-reinstall --no-cache-dir

# 带 Metal 支持
CMAKE_ARGS="-DGGML_METAL=on" pip install llama-cpp-python --force-reinstall --no-cache-dir
```

## 模型获取与转换

### 直接下载预量化 GGUF

```bash
# 从 HuggingFace 下载 GGUF 模型
pip install huggingface-hub

huggingface-cli download \
    TheBloke/Llama-2-7B-Chat-GGUF \
    llama-2-7b-chat.Q4_K_M.gguf \
    --local-dir ./models/
```

### 从 HuggingFace 转换

```bash
# 1. 下载原始模型
huggingface-cli download meta-llama/Llama-3.2-3B --local-dir ./llama-3.2-3b

# 2. 转换为 FP16 GGUF
python convert_hf_to_gguf.py ./llama-3.2-3b \
    --outfile llama-3.2-3b-f16.gguf \
    --outtype f16

# 3. 量化到 Q4_K_M
./llama-quantize llama-3.2-3b-f16.gguf \
    llama-3.2-3b-q4_k_m.gguf Q4_K_M
```

## 推理使用

### 命令行推理

```bash
# 单次提示
./llama-cli -m model.Q4_K_M.gguf \
    -p "请用中文解释什么是机器学习" \
    -n 512 \
    -t 8

# 交互式对话
./llama-cli -m model.Q4_K_M.gguf \
    --interactive \
    --color \
    --chat-template chatml

# 流式输出
./llama-cli -m model.Q4_K_M.gguf \
    -p "讲个笑话" \
    -n 256 \
    --no-display-prompt
```

### GPU 卸载

```bash
# 部分卸载到 GPU（视显存而定）
./llama-cli -m model.Q4_K_M.gguf -ngl 35 -p "Hello"

# 全部卸载到 GPU
./llama-cli -m model.Q4_K_M.gguf -ngl 99 -p "Hello"

# 多 GPU 分片
./llama-cli -m large-model.gguf \
    --tensor-split 0.5,0.5 \
    -ngl 60
```

### OpenAI 兼容 API 服务

```bash
# 启动 API 服务器
./llama-server \
    -m model.Q4_K_M.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -ngl 35 \
    -c 8192 \
    --parallel 4 \
    --cont-batching
```

使用 OpenAI Python 客户端调用：

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"
)

response = client.chat.completions.create(
    model="local-model",
    messages=[
        {"role": "system", "content": "你是一个有用的助手"},
        {"role": "user", "content": "用中文解释量子计算"}
    ],
    max_tokens=512,
    temperature=0.7
)

print(response.choices[0].message.content)
```

### Python 绑定使用

```python
from llama_cpp import Llama

# 加载模型
llm = Llama(
    model_path="./models/model-q4_k_m.gguf",
    n_ctx=4096,       # 上下文窗口
    n_gpu_layers=35,  # GPU 卸载层数，0=纯CPU
    n_threads=8,      # CPU 线程数
    n_batch=512,      # 批处理大小
)

# 基础生成
output = llm(
    "什么是深度学习？",
    max_tokens=256,
    temperature=0.7,
    stop=["</s>", "\n\n"],
)

print(output["choices"][0]["text"])

# 聊天补全 + 流式
for chunk in llm(
    "请列出三种编程语言:",
    max_tokens=256,
    stream=True,
):
    print(chunk["choices"][0]["text"], end="", flush=True)
```

## GGUF 量化详解

### K-quant 方法（推荐）

| 类型 | 位宽 | 7B 模型大小 | 质量 | 适用场景 |
|------|------|------------|------|---------|
| Q2_K | 2.5 | ~2.8 GB | 低 | 极限压缩 |
| Q3_K_S | 3.0 | ~3.0 GB | 中低 | 内存受限 |
| Q3_K_M | 3.3 | ~3.3 GB | 中等 | 小型设备 |
| Q4_K_S | 4.0 | ~3.8 GB | 中高 | 速度优先 |
| **Q4_K_M** | 4.5 | ~4.1 GB | **高** | **推荐默认** |
| Q5_K_S | 5.0 | ~4.6 GB | 高 | 质量优先 |
| Q5_K_M | 5.5 | ~4.8 GB | 很高 | 高质量 |
| Q6_K | 6.0 | ~5.5 GB | 优秀 | 接近原始 |
| Q8_0 | 8.0 | ~7.2 GB | 最佳 | 最大质量 |

### 任务推荐量化

| 任务 | 推荐量化 |
|------|---------|
| 通用对话 / 助手 | Q4_K_M |
| 代码生成 | Q5_K_M 或 Q6_K |
| 技术 / 医疗内容 | Q6_K 或 Q8_0 |
| 大模型（70B+） | Q3_K_M 或 Q4_K_S |
| 树莓派 / 边缘设备 | Q2_K 或 Q3_K_S |

### 重要性矩阵（imatrix）

imatrix 在低 bit 量化时显著提升质量：

```bash
# 1. 准备校准数据
cat > calibration.txt << 'EOF'
机器学习是人工智能的一个子集。
深度学习使用神经网络进行模式识别。
...（收集 100MB+ 多样性文本）
EOF

# 2. 生成重要性矩阵
./llama-imatrix -m model-f16.gguf \
    -f calibration.txt \
    --chunk 512 \
    -o model.imatrix \
    -ngl 35

# 3. 使用 imatrix 量化
./llama-quantize --imatrix model.imatrix \
    model-f16.gguf model-q4_k_m.gguf Q4_K_M
```

### 批量量化脚本

```bash
#!/bin/bash
MODEL="llama-3.2-3b-f16.gguf"
IMATRIX="llama-3.2-3b.imatrix"

./llama-imatrix -m $MODEL -f wiki.txt -o $IMATRIX -ngl 35

for QUANT in Q4_K_M Q5_K_M Q6_K Q8_0; do
    OUTPUT="llama-3.2-3b-${QUANT,,}.gguf"
    ./llama-quantize --imatrix $IMATRIX $MODEL $OUTPUT $QUANT
    echo "已创建: $OUTPUT ($(du -h $OUTPUT | cut -f1))"
done
```

### 质量测试（困惑度）

```bash
./llama-perplexity -m model.gguf -f wikitext-2-raw/wiki.test.raw -c 512
# FP16 基准: ~5.96  |  Q4_K_M: ~6.06 (+1.7%)  |  Q2_K: ~6.87 (+15.3%)
```

## 性能优化

### CPU 推理优化

```bash
# 匹配物理核心数（不是逻辑核心）
./llama-cli -m model.gguf -t 8

# 使用 BLAS 加速（2-3x 加速）
make LLAMA_OPENBLAS=1
```

Python 中优化 CPU 推理：

```python
llm = Llama(
    model_path="model.gguf",
    n_gpu_layers=0,
    n_threads=8,
    n_batch=512,  # 更大的 batch = 更快的 prompt 处理
)
```

### GPU 卸载原则

1. 尽可能多卸载层数到 GPU
2. 从 `-ngl 99` 开始，OOM 时每次减 5
3. 大模型使用混合模式（部分 GPU + 部分 CPU）

### KV Cache 量化

节省显存：

```python
Llama(
    model_path="...",
    type_k=2,  # Q4_0 KV cache
    type_v=2,
    n_gpu_layers=35
)
```

## 与生态系统集成

### Ollama

```dockerfile
# Modelfile
FROM ./model-q4_k_m.gguf
TEMPLATE """{{ .System }}
{{ .Prompt }}"""
PARAMETER temperature 0.7
PARAMETER num_ctx 4096
```

```bash
ollama create mymodel -f Modelfile
ollama run mymodel "你好！"
```

### LM Studio

1. 将 GGUF 文件放入 `~/.cache/lm-studio/models/`
2. 打开 LM Studio 选择模型
3. 配置上下文长度和 GPU 卸载

### text-generation-webui

```bash
cp model-q4_k_m.gguf text-generation-webui/models/
python server.py --model model-q4_k_m.gguf \
    --loader llama.cpp \
    --n-gpu-layers 35
```

## 常见问题排查

### 模型加载慢

使用内存映射：

```bash
./llama-cli -m model.gguf --mmap
```

### 显存不足（OOM）

- 减少 `-ngl` 值
- 使用更小的量化（Q4_K_S / Q3_K_M）
- 启用 KV cache 量化：`type_k=2`

### 输出乱码

- 温度太高：设 `temperature=0.1` 测试
- 使用了错误的 chat format
- 模型文件损坏

### 服务器连接失败

```bash
# 检查端口占用
lsof -i :8080

# 确保绑定到 0.0.0.0
./llama-server --host 0.0.0.0
```

## 性能基准

### CPU（Llama 2-7B Q4_K_M）

| CPU | 线程 | 速度 |
|-----|------|------|
| Apple M3 Max (Metal) | 16 | 50 tok/s |
| AMD Ryzen 9 7950X | 32 | 35 tok/s |
| Intel i9-13900K | 32 | 30 tok/s |

### GPU 卸载（RTX 4090）

| GPU 层数 | 速度 | VRAM |
|----------|------|------|
| 0 (纯 CPU) | 30 tok/s | 0 GB |
| 20 (混合) | 80 tok/s | 8 GB |
| 35 (全部) | 120 tok/s | 12 GB |

## 总结

llama.cpp 是本地 LLM 推理的最佳选择之一，特别是在以下场景：

1. **无 GPU 或 Apple Silicon** 环境的首选
2. **需要灵活量化** 平衡模型大小和质量
3. **边缘部署** 需要单二进制文件
4. **隐私敏感** 需要完全本地化

对于 NVIDIA GPU 高吞吐生产环境，建议配合 vLLM 使用。

### 参考链接

- GitHub: https://github.com/ggml-org/llama.cpp
- Python 绑定: https://github.com/abetlen/llama-cpp-python
- 预量化模型: https://huggingface.co/TheBloke
- GGUF 转换器: https://huggingface.co/spaces/ggml-org/gguf-my-repo
