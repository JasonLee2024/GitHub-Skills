---
title: Hugging Face Hub — 模型注册表与社区平台
description: 使用 Hugging Face Hub CLI（hf）搜索、下载、上传和管理模型、数据集与 Spaces
---

# Hugging Face Hub — 模型注册表与社区平台

## 概述

Hugging Face Hub 是全球最大的机器学习模型和数据集社区平台。通过 `huggingface-hub` 库和 `hf` CLI 工具，开发者可以轻松地搜索、下载、上传和管理 AI 资源。

### 核心特性

- **模型注册表**：20 万+ 开源模型
- **数据集库**：10 万+ 数据集
- **Spaces**：云端 AI 应用托管
- **版本控制**：基于 Git 的文件管理
- **社区协作**：讨论、Issue、Pull Request

### 与之前内容的关系

| 文档 | 关系 |
|------|------|
| [[llama-cpp]] | 使用 HF Hub 下载 GGUF 模型 |
| [[vllm]] | 从 HF Hub 加载模型权重 |
| [[peft-lora]] | 上传/下载微调后的 LoRA 权重 |
| [[modal-serverless-gpu]] | 集成 HF Hub 的身份验证和模型下载 |

## 安装与配置

```bash
# 安装
pip install huggingface-hub

# 安装 CLI（完整功能）
pip install "huggingface-hub[cli]"

# 登录（交互式）
huggingface-cli login

# 或使用 token
huggingface-cli login --token hf_your_token_here

# 验证登录
huggingface-cli whoami
```

### 环境变量

```bash
# 推荐：写入 ~/.bashrc
export HF_HOME="$HOME/.cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$HF_HOME/hub"

# 镜像加速（国内用户）
export HF_ENDPOINT=https://hf-mirror.com
```

## 搜索模型

### CLI 搜索

```bash
# 基本搜索
huggingface-cli search qwen

# 按任务筛选
huggingface-cli search --task text-generation

# 按框架筛选
huggingface-cli search --library transformers

# 按语言筛选
huggingface-cli search --language zh

# 按流行度排序
huggingface-cli search --sort downloads

# 按最近更新
huggingface-cli search --sort last_modified
```

### 复杂筛选

```bash
# 组合条件：中文对话模型
huggingface-cli search qwen --task text-generation --language zh --sort downloads

# 查找 GGUF 格式的模型
huggingface-cli search --library llama.cpp

# 查找特定参数量的模型
huggingface-cli search --query "1.5B" --task text-generation
```

### Python API

```python
from huggingface_hub import HfApi

api = HfApi()

# 搜索模型
models = api.list_models(
    task="text-generation",
    library="transformers",
    search="qwen",
    sort="downloads",
    direction=-1,  # 降序
    limit=10,
)

for model in models:
    print(f"{model.modelId} ⭐ {model.downloads} downloads")

# 获取模型详情
info = api.model_info("Qwen/Qwen2.5-7B-Instruct")
print(f"Tags: {info.tags}")
print(f"Pipeline Tag: {info.pipeline_tag}")
print(f"Siblings: {len(info.siblings)} files")
```

## 下载模型

### 下载整个模型

```python
# Python API - 推荐
from huggingface_hub import snapshot_download

# 下载完整模型
model_path = snapshot_download("Qwen/Qwen2.5-7B-Instruct")
print(f"模型保存在: {model_path}")

# 指定下载目录
snapshot_download(
    "Qwen/Qwen2.5-7B-Instruct",
    local_dir="./models/qwen",
    local_dir_use_symlinks=False,  # 不使用软链接（复制实际文件）
)

# 使用 token 下载私有模型
snapshot_download(
    "your-org/private-model",
    token="hf_your_token_here",
)
```

```bash
# CLI
huggingface-cli download Qwen/Qwen2.5-7B-Instruct
```

### 下载特定文件

```python
from huggingface_hub import hf_hub_download

# 下载单个文件
file_path = hf_hub_download(
    "Qwen/Qwen2.5-7B-Instruct",
    filename="tokenizer.json",
)
print(f"文件保存到: {file_path}")

# 下载 GGUF 模型
gguf_path = hf_hub_download(
    "bartowski/Qwen2.5-7B-Instruct-GGUF",
    filename="qwen2.5-7b-instruct-q4_k_m.gguf",
)
```

```bash
# CLI 下载特定文件
huggingface-cli download \
  bartowski/Qwen2.5-7B-Instruct-GGUF \
  qwen2.5-7b-instruct-q4_k_m.gguf \
  --local-dir ./models

# 加速下载（多线程）
huggingface-cli download \
  Qwen/Qwen2.5-7B-Instruct \
  --multi-file  # 多文件并行下载
```

### 缓存管理

```bash
# 查看缓存
huggingface-cli scan-cache

# 清理缓存
huggingface-cli delete-cache

# 设置缓存路径
export HF_HOME=/data/hf_cache
```

## 上传模型

### 创建模型仓库

```python
from huggingface_hub import HfApi

api = HfApi()

# 创建仓库
api.create_repo(
    repo_id="your-username/my-finetuned-model",
    repo_type="model",
    private=True,  # 私有仓库
)
```

```bash
# CLI 创建
huggingface-cli repo create my-finetuned-model --type model --private
```

### 上传文件

```python
from huggingface_hub import HfApi, login

# 方法 1：上传单个文件
api = HfApi()
api.upload_file(
    path_or_fileobj="./outputs/pytorch_model.bin",
    path_in_repo="pytorch_model.bin",
    repo_id="your-username/my-finetuned-model",
)

# 方法 2：上传整个文件夹
api.upload_folder(
    folder_path="./outputs/",
    repo_id="your-username/my-finetuned-model",
    commit_message="Upload fine-tuned model",
    ignore_patterns=[".cache", "*.tmp"],  # 忽略文件
)

# 方法 3：使用大文件支持
api.upload_file(
    path_or_fileobj="my_model.safetensors",
    path_in_repo="model.safetensors",
    repo_id="your-username/my-finetuned-model",
    run_as_future=True,  # 异步上传
)
```

```bash
# CLI 上传整个文件夹
huggingface-cli upload your-username/my-finetuned-model ./outputs/ --repo-type model

# 上传大文件
huggingface-cli upload your-username/my-finetuned-model ./big_model.safetensors --repo-type model
```

### 上传 LoRA 权重

```python
from huggingface_hub import HfApi
import json

api = HfApi()

# 上传微调后的 LoRA 权重
api.upload_folder(
    folder_path="./lora-weights/",
    repo_id="your-username/qwen-lora-adapter",
    commit_message="Qwen LoRA adapter after SFT",
)

# 同时上传 README
with open("README.md", "w") as f:
    f.write("""---
license: apache-2.0
language:
  - zh
  - en
tags:
  - qwen
  - lora
  - peft
---

# Qwen LoRA Adapter

## 训练详情
- 基础模型: Qwen/Qwen2.5-7B-Instruct
- LoRA rank: 16
- 数据集: 自定义指令数据
""")

api.upload_file(
    path_or_fileobj="README.md",
    path_in_repo="README.md",
    repo_id="your-username/qwen-lora-adapter",
)
```

## 数据集操作

### 搜索和下载数据集

```python
from datasets import load_dataset
from huggingface_hub import HfApi

# 搜索数据集
api = HfApi()
datasets = api.list_datasets(
    task="text-generation",
    search="zh",
    sort="downloads",
)

# 加载数据集
dataset = load_dataset("your-username/zh-instructions", split="train")
print(f"数据集大小: {len(dataset)}")

# 流式加载大型数据集
dataset = load_dataset("big-code/the-stack", split="train", streaming=True)
for i, example in enumerate(dataset):
    if i > 100:
        break
    # 处理数据...
```

### 上传数据集

```python
from huggingface_hub import HfApi

api = HfApi()

# 创建数据集仓库
api.create_repo(
    repo_id="your-username/my-dataset",
    repo_type="dataset",
)

# 上传数据文件
api.upload_folder(
    folder_path="./dataset/",
    repo_id="your-username/my-dataset",
    repo_type="dataset",
)
```

## Spaces 部署

Spaces 是 Hugging Face 的 AI 应用托管平台，支持 Gradio、Streamlit、Docker。

```bash
# 创建 Space
huggingface-cli repo create my-space --type space --space-sdk gradio

# 上传代码
git clone https://huggingface.co/spaces/your-username/my-space
cd my-space
echo "your code" > app.py
git add . && git commit -m "init" && git push
```

### 示例：Gradio Chat UI

```python
# app.py
import gradio as gr
from transformers import pipeline

pipe = pipeline("text-generation", model="Qwen/Qwen2.5-7B-Instruct")

def chat(message, history):
    response = pipe(message, max_new_tokens=256)[0]["generated_text"]
    return response

gr.ChatInterface(chat).launch()
```

## Git 工作流

Hub 使用 Git 进行版本控制，支持完整的 Git 操作。

```bash
# 克隆模型仓库（需安装 git-lfs）
git lfs install
git clone https://huggingface.co/Qwen/Qwen2.5-7B-Instruct

# 查看文件（大文件由 LFS 管理）
cd Qwen2.5-7B-Instruct
git lfs track "*.safetensors"
git add .gitattributes

# 提交和推送
git add .
git commit -m "update model card"
git push
```

## 推理集成

### Transformers 加载

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

# 自动从 Hub 下载
model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen2.5-7B-Instruct",
    device_map="auto",
    torch_dtype="auto",
)
tokenizer = AutoTokenizer.from_pretrained("Qwen/Qwen2.5-7B-Instruct")
```

### 设置镜像源

```python
import os

# 国内镜像
os.environ["HF_ENDPOINT"] = "https://hf-mirror.com"
os.environ["HF_HOME"] = "/data/hf_cache"

# 下载时自动使用镜像
model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen2.5-7B-Instruct",
    cache_dir="/data/hf_cache/models",
)
```

## 模型卡片（README.md）

```markdown
---
license: apache-2.0
language:
  - zh
  - en
tags:
  - text-generation
  - qwen
pipeline_tag: text-generation
base_model: Qwen/Qwen2.5-7B-Instruct
---

# Model Name

## 模型描述
简要描述模型的功能和特点。

## 训练参数
- 学习率: 2e-5
- 批次大小: 128
- 训练步数: 1000
- 优化器: AdamW

## 评估结果
| 基准 | 分数 |
|------|------|
| MMLU | 72.5 |
| C-Eval | 68.3 |

## 使用方式
```python
from transformers import pipeline
pipe = pipeline("text-generation", model="your-username/your-model")
```

## 限制
- 基于特定数据集训练，可能不适用于所有场景
- 需要至少 16GB 显存运行
```

## 常用命令速查

```bash
# 身份验证
huggingface-cli login                       # 登录
huggingface-cli logout                      # 登出
huggingface-cli whoami                      # 查看当前用户

# 搜索
huggingface-cli search qwen                 # 搜索模型
huggingface-cli search --task text-generation  # 按任务搜索

# 下载
huggingface-cli download Qwen/Qwen2.5-7B-Instruct  # 下载模型
huggingface-cli download your-repo/file.bin --local-dir ./  # 下载特定文件

# 上传
huggingface-cli upload repo ./local/ --repo-type model   # 上传文件

# 仓库管理
huggingface-cli repo create my-model --type model        # 创建仓库
huggingface-cli repo delete my-model                     # 删除仓库

# 缓存
huggingface-cli scan-cache             # 查看缓存
huggingface-cli delete-cache           # 清理缓存
```

## 最佳实践

1. **模型标识**：为模型添加准确的 tags 和描述
2. **版本控制**：使用语义化版本标记模型迭代
3. **大文件处理**：使用 safetensors 格式和 Git LFS
4. **缓存管理**：定期清理缓存，设置合理的 HF_HOME
5. **镜像使用**：国内用户设置 HF_ENDPOINT 加速下载
6. **私有部署**：企业用户考虑使用 Hugging Face Hub Enterprise

## 参考链接

- 文档: https://huggingface.co/docs/hub
- Hugging Face Hub: https://huggingface.co
- 镜像站: https://hf-mirror.com
- GitHub: https://github.com/huggingface/huggingface-hub
