---
date: 2026-05-05
tags:
  - modal
  - serverless
  - gpu
  - cloud
  - deployment
  - operations
  - 运维与监控
source_skill: modal-serverless-gpu
category: 运维与监控
---

# Modal 无服务器 GPU 运维

> 本文档基于 Hermes Agent 的 `modal-serverless-gpu` 技能整理，覆盖 Modal 无服务器 GPU 平台的配置、部署和运维实操。

## 概述

Modal 是一个**无服务器 GPU 云平台**，专为 ML/AI 工作负载设计。与传统的云 GPU（如 AWS EC2 G5）不同，Modal 自动处理基础设施的伸缩和计费，只在代码实际运行时收费。

### 核心优势

| 特性 | Modal | 传统 GPU 云 |
|------|-------|------------|
| 计费模式 | 按秒计费，仅运行时间 | 按小时计费，即使空闲 |
| 启动时间 | 秒级冷启动 | 分钟级 |
| 自动伸缩 | 原生支持 | 需手动配置 |
| 开发体验 | Python 函数式 | 虚拟机管理 |
| 文件系统 | 分布式持久化 | 需挂载 |

### 支持的工作负载

- LLM 推理（vLLM, TGI）
- 模型微调（LoRA）
- 批量推理和 ETL
- Web 应用部署（Gradio, FastAPI）
- 定时任务（Cron Jobs）
- 大规模数据处理

---

## 环境配置

### 安装和认证

```bash
# 安装
pip install modal

# 认证（首次使用）
modal token new
# 浏览器打开 → 登录 → 确认 Token

# 验证
modal profile current
```

### 项目结构

```
my-modal-project/
├── app.py           # 主应用定义
├── config.py        # 配置文件
├── requirements.txt # Python 依赖
├── .modal/          # 本地缓存（忽略）
└── secrets/         # Secrets（不进版本控制）
```

---

## 基础用法

### Hello World

```python
# app.py
import modal

app = modal.App("hello-world")

@app.function()
def hello():
    return "Hello from Modal!"

# 本地运行
if __name__ == "__main__":
    with app.run():
        print(hello.remote())
```

### 运行命令

```bash
# 本地运行函数（模拟云端）
modal run app.py

# 部署到云端
modal deploy app.py

# 交互式 Shell（在 Modal 环境中）
modal shell app.py

# 查看日志
modal logs hello-world
```

---

## GPU 工作负载

### 使用 GPU

```python
import modal

app = modal.App("gpu-example")

# GPU 配置选项
GPU_CONFIGS = {
    "T4": "t4",           # 入门级，适合推理
    "L4": "l4",           # 中等，适合微调
    "A10G": "a10g",       # 高性能，适合训练
    "A100": "a100",       # 旗舰级，适合大模型
    "H100": "h100",       # 顶级，适合千亿参数模型
}

@app.function(
    gpu="t4",             # GPU 类型
    timeout=600,          # 超时时间（秒）
    memory=16384,         # 内存（MB）
    cpu=4.0,              # CPU 核数
)
def run_inference(prompt: str) -> str:
    """在 GPU 上运行推理"""
    import torch
    
    # 检查 GPU
    print(f"GPU 可用: {torch.cuda.is_available()}")
    print(f"GPU 型号: {torch.cuda.get_device_name(0)}")
    print(f"显存: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
    
    # 在这里加载模型并运行推理
    return f"Inference result for: {prompt[:50]}..."
```

### 容器镜像

```python
# 创建自定义容器镜像
image = modal.Image.debian_slim(python_version="3.11").pip_install(
    "torch==2.1.0",
    "transformers==4.36.0",
    "accelerate==0.25.0",
    "huggingface_hub==0.20.0",
)

app = modal.App("custom-image", image=image)

@app.function(gpu="t4")
def load_and_infer():
    from transformers import AutoModelForCausalLM, AutoTokenizer
    
    model = AutoModelForCausalLM.from_pretrained(
        "Qwen/Qwen2.5-1.5B-Instruct",
        device_map="auto",
    )
    tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-1.5B-Instruct")
    
    inputs = tokenizer("你好，介绍一下自己", return_tensors="pt").to("cuda")
    outputs = model.generate(**inputs, max_new_tokens=100)
    return tokenizer.decode(outputs[0])
```

---

## 持久化存储

### Volume（持久化文件系统）

```python
import modal

# 创建 Volume（持久化存储）
volume = modal.Volume.from_name("my-data", create_if_missing=True)

app = modal.App("volume-example")

@app.function(
    volumes={"/data": volume},  # 挂载 Volume 到 /data
    gpu="t4",
    timeout=3600,
)
def train_with_checkpoints():
    import os
    
    # 写入数据（持久化）
    with open("/data/checkpoint.pt", "w") as f:
        f.write("model checkpoint data")
    
    # 读取数据
    for item in os.listdir("/data"):
        print(f"  📦 {item}")
    
    return "Checkpoint saved!"

# 列出 Volume 中的文件
modal volume ls my-data

# 上传本地文件到 Volume
modal volume put my-data ./local_file.txt /remote/path/
```

---

## Web 应用部署

### Gradio 应用

```python
import modal

app = modal.App("demo-app")

# 构建镜像
image = modal.Image.debian_slim().pip_install(
    "gradio",
    "transformers",
    "torch",
)

@app.function(
    image=image,
    gpu="t4",
    concurrency_limit=1,  # 同时只能运行一个实例
    container_idle_timeout=300,  # 空闲 5 分钟后自动停止
)
@modal.web_endpoint(method="GET", label="demo")
def web_demo():
    """部署 Web 应用"""
    import gradio as gr
    
    def greet(name):
        return f"Hello {name}!"
    
    iface = gr.Interface(
        fn=greet,
        inputs=gr.Textbox(label="输入"),
        outputs=gr.Textbox(label="输出"),
        title="Modal Demo",
    )
    
    return iface.launch(
        server_name="0.0.0.0",
        server_port=8000,
        share=False
    )
```

### FastAPI 应用

```python
import modal
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

web_app = FastAPI()
app = modal.App("fastapi-demo")

class QueryRequest(BaseModel):
    prompt: str
    max_tokens: int = 100

@web_app.get("/health")
def health():
    return {"status": "ok"}

@web_app.post("/infer")
def infer(request: QueryRequest):
    # 在这里实现推理逻辑
    return {
        "prompt": request.prompt,
        "result": f"Generated {request.max_tokens} tokens",
    }

@app.function(
    gpu="t4",
    container_idle_timeout=300,
)
@modal.asgi_app()
def fastapi_app():
    return web_app

# 部署后获得 URL: https://your-app.modal.run
```

---

## 定时任务

```python
import modal

app = modal.App("scheduled-tasks")

@app.function(schedule=modal.Period(days=1))
def daily_report():
    """每日自动生成报告"""
    print("📊 生成每日报告...")
    # 在这里实现报告生成逻辑
    return "报告完成"

@app.function(schedule=modal.Cron("0 */6 * * *"))
def check_updates():
    """每 6 小时检查更新"""
    print("🔍 检查更新...")
    # 检查 RSS 源、博客更新等
    return "检查完成"
```

---

## 运维命令

```bash
# 列出所有应用
modal app list

# 查看应用状态
modal app status my-app

# 查看日志（实时）
modal logs my-app --tail

# 查看 GPU 使用情况
modal app logs my-app --since 1h | grep -i gpu

# 删除应用
modal app stop my-app

# 列出 Secrets
modal secret list

# 创建 Secret
modal secret create my-secret KEY1=value1 KEY2=value2

# 查看 Volume
modal volume ls my-volume

# 清理旧版本
modal deploy my-app --version
```

---

## Secrets 管理

```python
# 在代码中使用 Secrets
import modal

app = modal.App("secrets-example")

# 在 Modal 中创建 Secret
# modal secret create huggingface-token HF_TOKEN=hf_xxxx

# 在函数中使用
@app.function(
    secrets=[modal.Secret.from_name("huggingface-token")],
    gpu="t4",
)
def use_secret():
    import os
    token = os.environ["HF_TOKEN"]
    print(f"Using token: {token[:8]}...")
    return token
```

---

## 成本控制

```bash
# 查看费用
modal cost breakdown

# 设置预算限制
# 在 Dashboard → Settings → Billing 中设置

# 监控实时费用
modal app logs my-app | grep -E "cost|duration"
```

### 成本优化策略

| 策略 | 说明 | 效果 |
|------|------|------|
| 设置 `container_idle_timeout` | 空闲自动停止 | 减少空闲费用 |
| 使用 `concurrency_limit` | 限制并发 | 防止意外扩展 |
| 选择合适 GPU | T4 足够则不用 A100 | T4 成本为 A100 的 1/4 |
| 使用 Spot 实例（支持中） | 使用闲置资源 | 可节省 60-80% |
| 缓存容器镜像 | 减少冷启动 | 间接节省 |

---

## 相关技能

- [[01-webhook-ops]] — Webhook 订阅管理
- [[02-blog-monitor]] — Blog/RSS 监控
- [[03-pages-ops]] — GitHub Pages 运维
