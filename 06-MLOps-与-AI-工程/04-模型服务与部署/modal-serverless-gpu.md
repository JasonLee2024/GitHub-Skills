---
title: Modal — 无服务器 GPU 云平台
description: 使用 Modal 在云上运行无服务器 GPU 任务，支持 LLM 推理、微调、数据批处理等工作负载
---

# Modal — 无服务器 GPU 云平台

## 概述

Modal 是一个无服务器 GPU 云平台，让开发者无需管理基础设施即可在云端运行 GPU 工作负载。它支持从秒级运行的批处理任务到长时间运行的 Web 服务。

### 核心特性

- **无服务器**：无需管理 GPU 实例，按需计费
- **秒级启动**：冷启动 <5 秒（通过自动快照）
- **自动扩缩**：从 0 到数千 GPU 的自动缩放
- **丰富的 GPU 类型**：T4、L4、A10G、A100、H100
- **持久化存储**：内置文件系统和 Volume
- **定时任务**：Cron 调度 GPU 任务
- **与 MLOps 集成**：支持 HuggingFace、Weights & Biases

### 适用场景

| 场景 | 推荐 GPU | 模式 |
|------|---------|------|
| LLM 推理服务 | A100 / H100 | Web 服务 |
| 模型微调 | A100-80G x2+ | 长时间任务 |
| 数据批处理 | T4 / L4 | 函数调用 |
| 嵌入生成 | T4 | 函数调用 |
| 视频/图像处理 | A10G | 函数调用 |

## 安装与配置

```bash
# 安装
pip install modal

# 注册并配置 token
modal setup

# 验证
modal run --help
```

## 快速开始

### Hello World GPU

```python
# hello_gpu.py
import modal

# 创建 App
app = modal.App("hello-gpu")

# 定义环境
image = modal.Image.debian_slim().pip_install("torch", "transformers")

@app.function(
    image=image,
    gpu="t4",  # GPU 类型
    timeout=300,
)
def greet(name: str) -> str:
    import torch
    return f"Hello {name}! CUDA available: {torch.cuda.is_available()}"

# 本地运行
if __name__ == "__main__":
    print(greet.remote("World"))
```

```bash
modal run hello_gpu.py
```

## LLM 推理服务

### 部署 OpenAI 兼容 API

```python
# llm_server.py
import modal
from pydantic import BaseModel

# 构建环境
image = (
    modal.Image.debian_slim()
    .pip_install(
        "vllm==0.6.0",
        "huggingface-hub",
    )
)

app = modal.App("llm-server", image=image)

# 定义请求/响应格式
class ChatRequest(BaseModel):
    messages: list[dict]
    temperature: float = 0.7
    max_tokens: int = 512

class ChatResponse(BaseModel):
    response: str

@app.cls(gpu="a100:1", container_idle_timeout=300, secrets=[modal.Secret.from_name("huggingface")])
class VLLM:
    def __init__(self):
        self.model_name = "Qwen/Qwen2.5-7B-Instruct"

    @modal.enter()
    def load_model(self):
        """热加载：容器启动时自动调用"""
        from vllm import AsyncLLMEngine, AsyncEngineArgs

        engine_args = AsyncEngineArgs(
            model=self.model_name,
            max_model_len=8192,
            gpu_memory_utilization=0.90,
            trust_remote_code=True,
        )
        self.engine = AsyncLLMEngine.from_engine_args(engine_args)

    @modal.method()
    async def generate(self, request: ChatRequest) -> ChatResponse:
        from vllm import SamplingParams

        sampling_params = SamplingParams(
            temperature=request.temperature,
            max_tokens=request.max_tokens,
        )

        # 应用聊天模板
        prompt = self._format_messages(request.messages)

        # 生成
        result = await self.engine.generate(prompt, sampling_params)
        text = result.outputs[0].text

        return ChatResponse(response=text)

    def _format_messages(self, messages):
        from transformers import AutoTokenizer
        tokenizer = AutoTokenizer.from_pretrained(self.model_name)
        return tokenizer.apply_chat_template(messages, tokenize=False)

    @modal.exit()
    def cleanup(self):
        """退出时清理"""
        pass

# FastAPI 接口
from fastapi import FastAPI
from modal import asgi_app

web_app = FastAPI()

@web_app.post("/v1/chat/completions")
async def chat_completion(request: ChatRequest):
    model = VLLM()
    result = await model.generate.remote(request)
    return {
        "id": "chatcmpl-123",
        "object": "chat.completion",
        "choices": [{"message": {"content": result.response}}],
    }

@app.function()
@asgi_app()
def fastapi_app():
    return web_app
```

```bash
# 部署
modal deploy llm_server.py

# 访问
curl https://your-app.modal.run/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "你好"}], "max_tokens": 256}'
```

### 模型微调任务

```python
# finetune.py
import modal

image = (
    modal.Image.debian_slim()
    .pip_install(
        "torch",
        "transformers",
        "datasets",
        "accelerate",
        "peft",
        "trl",
    )
)

app = modal.App("llm-finetune", image=image)
volume = modal.Volume.from_name("model-cache", create_if_missing=True)

@app.function(
    gpu="a100:2",            # 2 张 A100
    timeout=3600 * 4,        # 4 小时超时
    volumes={"/models": volume},
    secrets=[modal.Secret.from_name("huggingface")],
)
def finetune_lora():
    import torch
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import LoraConfig, get_peft_model
    from datasets import Dataset
    from trl import SFTTrainer

    # 加载模型
    model = AutoModelForCausalLM.from_pretrained(
        "Qwen/Qwen2.5-7B-Instruct",
        torch_dtype=torch.bfloat16,
        device_map="auto",
    )
    tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-7B-Instruct")

    # 配置 LoRA
    lora_config = LoraConfig(
        r=16, lora_alpha=32, target_modules=["q_proj", "k_proj", "v_proj", "o_proj"],
    )
    model = get_peft_model(model, lora_config)

    # 训练（简化示例）
    trainer = SFTTrainer(
        model=model,
        train_dataset=Dataset.from_list([{"text": "示例数据"}]),
        args=TrainingArguments(
            output_dir="/models/finetuned",
            num_train_epochs=3,
            per_device_train_batch_size=4,
            bf16=True,
        ),
    )
    trainer.train()

    # 保存
    trainer.save_model("/models/finetuned")
    tokenizer.save_pretrained("/models/finetuned")
    print("微调完成！")

if __name__ == "__main__":
    finetune_lora.remote()
```

```bash
modal run finetune.py
```

## GPU 配置选项

```python
# 可用 GPU 类型
@app.function(gpu="t4")          # T4 (16GB) - 入门级
@app.function(gpu="t4:2")        # 2 张 T4
@app.function(gpu="l4")          # L4 (24GB)
@app.function(gpu="a10g")        # A10G (24GB)
@app.function(gpu="a10g:4")      # 4 张 A10G
@app.function(gpu="a100")        # A100 (40GB)
@app.function(gpu="a100:80gb")   # A100 (80GB)
@app.function(gpu="a100:8")      # 8 张 A100
@app.function(gpu="h100")        # H100 (80GB)

# 更多配置
@app.function(
    gpu="a100:80gb",
    memory=512 * 1024,  # 512 GB RAM
    timeout=3600,       # 1 小时超时
    cpu=16,             # 16 核 CPU
)
```

## 持久化存储

### Volume（分布式文件系统）

```python
# 创建 Volume
volume = modal.Volume.from_name("my-data", create_if_missing=True)

@app.function(volumes={"/data": volume})
def write_data():
    with open("/data/hello.txt", "w") as f:
        f.write("Hello Modal!")

@app.function(volumes={"/data": volume})
def read_data():
    with open("/data/hello.txt") as f:
        print(f.read())
```

### 文件同步

```bash
# 上传文件到 Volume
modal volume put my-data local_file.txt /remote/path/

# 下载文件
modal volume get my-data /remote/path/file.txt local_file.txt

# 列出文件
modal volume ls my-data /path/
```

## 定时任务

```python
import modal

app = modal.App("scheduled-task")

@app.function(schedule=modal.Period(days=1))  # 每天运行
def daily_task():
    print("Running daily GPU task...")

@app.function(schedule=modal.Cron("0 3 * * *"))  # 每天凌晨 3 点
def cron_task():
    print("Cron scheduled task...")
```

## Secrets 管理

```python
# 创建 Secret
import modal

# 通过 CLI
modal secret create huggingface HF_TOKEN=hf_your_token_here
modal secret create wandb WANDB_API_KEY=your_wandb_key

# 在函数中使用
@app.function(secrets=[modal.Secret.from_name("huggingface")])
def use_secret():
    import os
    token = os.environ["HF_TOKEN"]
```

## 监控与日志

```bash
# 查看日志
modal logs llm-server

# 实时日志
modal logs llm-server --follow

# 查看函数调用
modal app list

# 停止所有运行
modal app stop llm-server
```

## 成本管理

```bash
# 查看使用量
modal usage

# 设置预算告警
# 在 Modal Dashboard 中设置

# 自动缩零：无请求时不会产生任何费用
```

## 与其他服务配合

### HuggingFace

```python
@app.function(
    secrets=[modal.Secret.from_name("huggingface")],
)
def download_model():
    from huggingface_hub import snapshot_download
    snapshot_download(
        "Qwen/Qwen2.5-7B-Instruct",
        local_dir="/models/qwen",
    )
```

### Weights & Biases

```python
@app.function(
    secrets=[modal.Secret.from_name("wandb")],
    gpu="a100",
)
def train_with_wandb():
    import wandb
    wandb.init(project="modal-training")
    # ...训练代码...
    wandb.finish()
```

## 常见问题

### 冷启动慢

```python
# 使用 container_idle_timeout 保持容器
@app.cls(gpu="a100", container_idle_timeout=600)  # 10 分钟空闲超时
```

### 显存不足

- 减少 `max_model_len`
- 使用更低精度的量化
- 增加 GPU 数量

### 超时

- 增加 `timeout` 参数
- 对长时间任务使用 Volume 分步处理
- 使用 `@app.cls` 保持长连接

## 参考链接

- 文档: https://modal.com/docs
- 示例: https://github.com/modal-labs/modal-examples
- 定价: https://modal.com/pricing
- Discord: https://modal.com/discord
