---
title: Weights & Biases — ML 实验跟踪与 MLOps 平台
description: 使用 W&B 进行实验跟踪、超参数优化、模型注册和团队协作，支持 PyTorch、TensorFlow、HuggingFace 等主流框架
---

# Weights & Biases — ML 实验跟踪与 MLOps 平台

## 概述

Weights & Biases（W&B）是业界领先的 ML 实验跟踪平台，拥有 20 万+ ML 从业者用户。它提供实验日志、超参数搜索、模型注册和报告协作的全链路 MLOps 能力。

### 核心特性

- **实验跟踪**：自动记录超参数、指标、代码版本
- **实时可视化**：训练过程中实时更新图表
- **超参数搜索**：网格搜索、随机搜索、贝叶斯优化
- **模型注册**：版本管理、资产追踪、回滚支持
- **团队协作**：共享项目、报告、看板
- **100+ 集成**：PyTorch、TensorFlow、HuggingFace、Lightning

### 与之前内容的关系

| 文档 | 关系 |
|------|------|
| [[axolotl]] | Axolotl 内置 W&B 日志支持 |
| [[trl-rlhf]] | TRL 训练可通过 W&B 记录训练曲线 |
| [[peft-lora]] | PEFT 微调配合 W&B 跟踪不同 LoRA 配置 |
| [[llm-evaluation-harness]] | 评测结果可以同步到 W&B 仪表盘 |

## 安装与配置

```bash
# 安装
pip install wandb

# 登录（第一次使用）
wandb login

# 或设置环境变量
export WANDB_API_KEY=your_api_key_here
```

### 配置说明

| 配置项 | 环境变量 | 说明 |
|--------|---------|------|
| API Key | WANDB_API_KEY | 用于认证 |
| 项目名 | WANDB_PROJECT | 默认项目 |
| 实体名 | WANDB_ENTITY | 团队或用户名 |
| 运行模式 | WANDB_MODE | online/offline/disabled |
| 日志目录 | WANDB_DIR | 本地日志存储路径 |

## 快速开始

### 基础实验跟踪

```python
import wandb

# 初始化运行
run = wandb.init(
    project="my-first-project",
    config={  # 记录超参数
        "learning_rate": 0.001,
        "epochs": 10,
        "batch_size": 32,
        "model": "Qwen2.5-7B",
        "optimizer": "AdamW",
    }
)

# 训练循环
for epoch in range(run.config.epochs):
    # 训练代码...
    train_loss, train_acc = train_epoch()
    val_loss, val_acc = validate()

    # 记录指标
    wandb.log({
        "epoch": epoch,
        "train/loss": train_loss,
        "train/accuracy": train_acc,
        "val/loss": val_loss,
        "val/accuracy": val_acc,
        "learning_rate": current_lr,
    })

# 结束运行
wandb.finish()
```

### 与 PyTorch 配合

```python
import torch
import wandb

# 初始化
wandb.init(project="pytorch-demo", config={
    "lr": 0.001,
    "epochs": 10,
    "batch_size": 32,
})

config = wandb.config

for epoch in range(config.epochs):
    for batch_idx, (data, target) in enumerate(train_loader):
        # 前向传播
        output = model(data)
        loss = criterion(output, target)

        # 反向传播
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        # 每 100 步记录
        if batch_idx % 100 == 0:
            wandb.log({
                "batch/loss": loss.item(),
                "epoch": epoch,
                "batch": batch_idx,
            })

# 保存模型
torch.save(model.state_dict(), "model.pth")
wandb.save("model.pth")  # 上传到 W&B

wandb.finish()
```

## 核心概念

### 1. 项目与运行（Projects & Runs）

```python
# 创建运行
run = wandb.init(
    project="llm-finetuning",      # 项目名称
    name="qwen-lora-r16-epoch3",   # 可选的运行名称
    tags=["baseline", "lora"],      # 用于组织和过滤
    notes="Qwen LoRA 微调基线",     # 备注说明
    group="experiment-v1",          # 分组
    job_type="train",               # 任务类型
)

# 每个运行有唯一 ID 和 URL
print(f"Run ID: {run.id}")
print(f"Run URL: {run.url}")
```

### 2. 配置管理

```python
# 方式 1：init 时传递
wandb.init(project="demo", config={
    "model": "Qwen2.5-7B",
    "lora_r": 16,
    "lora_alpha": 32,
    "learning_rate": 2e-5,
    "batch_size": 4,
    "gradient_accumulation_steps": 8,
})

# 方式 2：使用 wandb.config
run = wandb.init(project="demo")
run.config.model = "Qwen2.5-7B"
run.config.lora_r = 16
run.config.learning_rate = 2e-5
```

### 3. 指标记录

```python
# 记录标量
wandb.log({"loss": 0.5, "accuracy": 0.92})

# 记录多个指标
wandb.log({
    "train/loss": train_loss,
    "train/accuracy": train_acc,
    "val/loss": val_loss,
    "val/accuracy": val_acc,
    "learning_rate": current_lr,
})

# 自定义 x 轴
wandb.log({"loss": loss}, step=global_step)

# 记录图像
wandb.log({"examples": [wandb.Image(img) for img in images]})

# 记录直方图
wandb.log({"gradients": wandb.Histogram(gradients)})

# 记录表格
table = wandb.Table(columns=["id", "prediction", "ground_truth"])
wandb.log({"predictions": table})
```

### 4. 模型检查点

```python
import torch
import wandb

# 保存检查点
checkpoint = {
    "epoch": epoch,
    "model_state_dict": model.state_dict(),
    "optimizer_state_dict": optimizer.state_dict(),
    "loss": loss,
}

torch.save(checkpoint, "checkpoint.pth")

# 上传到 W&B
wandb.save("checkpoint.pth")

# 推荐：使用 Artifacts
artifact = wandb.Artifact("model", type="model")
artifact.add_file("checkpoint.pth")
wandb.log_artifact(artifact)
```

## 超参数优化（Sweeps）

自动搜索最优超参数组合。

### 定义搜索配置

```python
sweep_config = {
    "method": "bayes",  # grid / random / bayes
    "metric": {
        "name": "val/accuracy",
        "goal": "maximize"  # 或 minimize
    },
    "parameters": {
        "learning_rate": {
            "distribution": "log_uniform",
            "min": 1e-5,
            "max": 1e-1,
        },
        "batch_size": {
            "values": [16, 32, 64, 128],
        },
        "optimizer": {
            "values": ["adam", "sgd", "rmsprop"],
        },
        "lora_r": {
            "values": [8, 16, 32, 64],
        },
        "dropout": {
            "distribution": "uniform",
            "min": 0.1,
            "max": 0.5,
        },
    },
}

# 初始化 Sweep
sweep_id = wandb.sweep(sweep_config, project="hyperparameter-search")
```

### 定义训练函数

```python
def train():
    """单个 Sweep 试次的训练函数"""
    run = wandb.init()

    # 使用配置的参数
    lr = wandb.config.learning_rate
    batch_size = wandb.config.batch_size
    lora_r = wandb.config.lora_r

    # 构建模型
    model = build_model(lora_r=lora_r)
    optimizer = get_optimizer(lr)

    # 训练循环
    for epoch in range(NUM_EPOCHS):
        train_loss = train_epoch(model, optimizer, batch_size)
        val_acc = validate(model)

        wandb.log({
            "train/loss": train_loss,
            "val/accuracy": val_acc,
        })

    wandb.finish()

# 启动 Agent（比如 20 个试次）
wandb.agent(sweep_id, function=train, count=20)
```

### 搜索策略对比

| 策略 | 适用场景 | 收敛速度 | 推荐度 |
|------|---------|---------|-------|
| grid | 参数少且离散 | 慢 | ⭐⭐ |
| random | 不知道哪个参数重要 | 中 | ⭐⭐⭐ |
| bayes | 有经验，要精细调优 | 快 | ⭐⭐⭐⭐⭐ |

## Artifacts（资产版本管理）

### 记录数据/模型版本

```python
# 创建 Artifact
artifact = wandb.Artifact(
    name="training-dataset",
    type="dataset",
    description="指令微调数据集",
    metadata={
        "size": "10K samples",
        "split": "train",
        "languages": ["zh", "en"],
    },
)

# 添加文件
artifact.add_file("data/train.jsonl")
artifact.add_dir("data/")

# 记录
wandb.log_artifact(artifact)
```

### 使用已记录的 Artifact

```python
# 在另一个运行中使用
run = wandb.init(project="llm-finetuning")

# 下载 Artifact
artifact = run.use_artifact("dataset:v2")
artifact_dir = artifact.download()

# 加载数据
data = load_data(f"{artifact_dir}/train.jsonl")
```

### 模型注册表

```python
# 记录模型
model_artifact = wandb.Artifact(
    name="qwen-lora-model",
    type="model",
    metadata={
        "base_model": "Qwen/Qwen2.5-7B",
        "lora_r": 16,
        "accuracy": 0.85,
    },
)

model_artifact.add_file("adapter_model.safetensors")
model_artifact.add_file("adapter_config.json")
wandb.log_artifact(
    model_artifact,
    aliases=["best", "production"],  # 别名便于引用
)

# 链接到模型注册表
run.link_artifact(
    model_artifact,
    "model-registry/production-models"
)
```

## 框架集成

### HuggingFace Transformers

```python
from transformers import Trainer, TrainingArguments
import wandb

# 初始化 W&B
wandb.init(project="hf-transformers")

# 训练参数
training_args = TrainingArguments(
    output_dir="./results",
    report_to="wandb",        # 关键：启用 W&B 日志
    run_name="qwen-lora-v1",
    logging_steps=50,
    save_steps=500,
    evaluation_strategy="steps",
    eval_steps=100,
)

# Trainer 自动记录到 W&B
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    tokenizer=tokenizer,
)

trainer.train()
```

### Axolotl 集成

```yaml
# axolotl config.yaml
wandb:
  project: axolotl-llm
  entity: your-username
  run_name: qwen-sft-lora
  log_every_step: true
```

### PyTorch Lightning

```python
from pytorch_lightning import Trainer
from pytorch_lightning.loggers import WandbLogger
import wandb

# 创建 W&B Logger
wandb_logger = WandbLogger(
    project="lightning-demo",
    log_model=True,  # 自动记录检查点
)

# 使用 Trainer
trainer = Trainer(
    logger=wandb_logger,
    max_epochs=10,
    log_every_n_steps=10,
)

trainer.fit(model, datamodule=dm)
```

### Keras/TensorFlow

```python
import wandb
from wandb.keras import WandbCallback

wandb.init(project="keras-demo")

model.fit(
    x_train, y_train,
    validation_data=(x_val, y_val),
    epochs=10,
    callbacks=[WandbCallback()],
)
```

## 可视化与分析

### 自定义图表

```python
import matplotlib.pyplot as plt

# 记录 Matplotlib 图表
fig, ax = plt.subplots()
ax.plot(x, y)
wandb.log({"custom_plot": wandb.Image(fig)})

# 混淆矩阵
wandb.log({"confusion_matrix": wandb.plot.confusion_matrix(
    y_true=ground_truth,
    preds=predictions,
    class_names=class_names,
)})

# PR 曲线
wandb.log({"pr_curve": wandb.plot.pr_curve(
    y_true, y_scores, labels=class_names,
)})

# ROC 曲线
wandb.log({"roc_curve": wandb.plot.roc_curve(
    y_true, y_scores, labels=class_names,
)})
```

### 系统指标

```python
# W&B 自动记录系统指标：
# - GPU 利用率
# - GPU 内存
# - CPU 利用率
# - 磁盘 I/O
# - 网络 I/O

# 可以在仪表盘直接查看系统面板
```

## 团队协作

### 分享运行

```python
# 运行 URL 自动可共享
run = wandb.init(project="team-project")
print(f"分享此链接给队友: {run.url}")
```

### Reports

W&B Reports 支持创建可共享的报告：

- 组合多个运行的结果
- 并排对比实验
- 嵌入图表和文本
- Markdown 支持
- 团队协作编辑

### 团队设置

1. 在 wandb.ai 创建团队
2. 添加成员
3. 设置项目可见性（公开/私有）
4. 使用团队级别的 Artifacts 和模型注册表

## 离线模式

```python
import os

# 启用离线模式
os.environ["WANDB_MODE"] = "offline"

wandb.init(project="my-project")
# ... 训练代码 ...

# 稍后同步
# wandb sync <run_directory>
```

```bash
# 手动同步离线运行
wandb sync wandb/offline-<run-id>
```

## 最佳实践

### 1. 统一命名规范

```python
# ✅ 好的命名
wandb.init(
    project="llm-finetuning",
    name="qwen-7b-lora-r16-lr2e5-epoch3",
    tags=["qwen", "lora", "sft"],
    group="lora-experiments",
)

# ❌ 不好的命名
wandb.init(project="test", name="run1")
```

### 2. 记录完整上下文

```python
import git

# 记录 Git 提交
repo = git.Repo(search_parent_directories=True)
wandb.config.update({
    "git_commit": repo.head.object.hexsha,
    "git_branch": repo.active_branch.name,
})

# 记录数据信息
wandb.config.update({
    "dataset_size": len(dataset),
    "dataset_source": "custom-collection",
    "tokenizer": "Qwen2.5Tokenizer",
})
```

### 3. 使用 WandB Callbacks

```python
# HuggingFace Trainer 中
from transformers import TrainerCallback

class WandbEvalCallback(TrainerCallback):
    def __init__(self, eval_steps=100):
        self.eval_steps = eval_steps

    def on_step_end(self, args, state, control, **kwargs):
        if state.global_step % self.eval_steps == 0:
            # 自定义评估逻辑
            metrics = evaluate_model(kwargs["model"])
            wandb.log(metrics, step=state.global_step)
```

### 4. 保存重要资产

```python
# 保存最终模型
artifact = wandb.Artifact("final-model", type="model")
artifact.add_file("model.safetensors")
artifact.add_file("config.json")
artifact.add_dir("tokenizer/")
wandb.log_artifact(artifact)

# 保存预测结果分析
import pandas as pd
pred_df = pd.DataFrame({"input": inputs, "pred": predictions, "true": labels})
wandb.log({"predictions": wandb.Table(dataframe=pred_df)})
```

## 定价

| 层级 | 价格 | 特点 |
|------|------|------|
| Free | 免费 | 无限公开项目，100GB 存储 |
| Academic | 免费 | 学生/研究人员专属 |
| Teams | $50/座/月 | 私有项目，无限存储 |
| Enterprise | 定制 | 私有部署，SSO，合规 |

## 参考链接

- 文档: https://docs.wandb.ai
- GitHub: https://github.com/wandb/wandb (10.5k+ stars)
- 示例: https://github.com/wandb/examples
- 社区: https://wandb.ai/community
- Discord: https://wandb.me/discord
