---
title: LLM 评估框架 — EleutherAI LM Evaluation Harness
description: 使用 lm-eval-harness 对 LLM 进行 60+ 学术基准测试，支持 MMLU、HumanEval、GSM8K、TruthfulQA 等标准评测
---

# LLM 评估框架 — EleutherAI LM Evaluation Harness

## 概述

EleutherAI LM Evaluation Harness 是业界标准的 LLM 评估框架，支持 60+ 学术基准测试。被 Hugging Face、OpenAI、Anthropic 等主流实验室用于模型质量报告。

### 核心特性

- **60+ 预置评测基准**：MMLU、HumanEval、GSM8K、TruthfulQA、HellaSwag、ARC 等
- **多后端支持**：HuggingFace Transformers、vLLM、OpenAI/Anthropic API、TGI
- **自定义任务**：支持注册新的评测任务和数据集
- **Few-shot 评测**：支持 0-shot 到 5-shot 的上下文学习评测
- **标准化报告**：生成可复现、可比较的评测结果
- **并行评测**：多 GPU 和多进程加速

### 常用基准说明

| 基准 | 评估内容 | 格式 | 典型得分（7B 模型） |
|------|---------|------|-------------------|
| MMLU | 多任务语言理解（57 学科） | 4选1 | 60-65% |
| HumanEval | Python 代码生成 | pass@k | 30-45% |
| GSM8K | 数学推理 | 自由生成 | 40-60% |
| TruthfulQA | 事实准确性 | 多选题 | 40-55% |
| HellaSwag | 常识推理 | 4选1 | 75-82% |
| ARC-Easy/Challenge | 科学问答 | 4选1 Easy: 85%, Chal: 55-65% |
| BBH | 大模型推理能力 | 多任务 | 50-65% |

## 安装

```bash
# 从 PyPI 安装
pip install lm-eval

# 从源码安装（获取最新基准）
git clone https://github.com/EleutherAI/lm-evaluation-harness.git
cd lm-evaluation-harness
pip install -e .

# 验证安装
lm-eval --help
```

## 快速开始

### 评测 HuggingFace 模型

```bash
# 基本评测：MMLU (0-shot)
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --num_fewshot 0 \
  --batch_size auto

# 评测多个任务
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu,gsm8k,hellaswag \
  --device cuda:0

# 使用 4-bit 量化
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct,load_in_4bit=True \
  --tasks mmlu \
  --batch_size 1
```

### Python API

```python
import lm_eval
from lm_eval import evaluate
from lm_eval.models.hf_model import HFLM

# 创建模型
model = HFLM(
    pretrained="Qwen/Qwen2.5-7B-Instruct",
    device="cuda:0",
    batch_size="auto",
)

# 评测单个任务
results = lm_eval.simple_evaluate(
    model=model,
    tasks=["mmlu"],
    num_fewshot=5,
    batch_size="auto",
)

# 查看结果
print(f"MMLU 得分: {results['results']['mmlu']['acc']*100:.1f}%")
print(f"MMLU stderr: {results['results']['mmlu']['acc_stderr']*100:.1f}%")
```

## 高级用法

### 评测 vLLM 后端

```bash
# 使用 vLLM 加速推理
lm-eval --model vllm \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct,tensor_parallel_size=1,dtype=auto,gpu_memory_utilization=0.9 \
  --tasks mmlu \
  --batch_size auto

# 多 GPU 张量并行
lm-eval --model vllm \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct,tensor_parallel_size=2 \
  --tasks mmlu,gsm8k
```

### 评测 API 模型

```bash
# OpenAI
lm-eval --model openai-completions \
  --model_args model=gpt-4 \
  --tasks mmlu \
  --num_fewshot 5

# Anthropic
lm-eval --model anthropic \
  --model_args model=claude-3-opus-20240229 \
  --tasks mmlu

# 本地 API 服务器（如 vLLM 部署）
lm-eval --model local-completions \
  --model_args model=/path/to/model,base_url=http://localhost:8000/v1/completions,num_concurrent=8 \
  --tasks mmlu
```

### 自定义 Few-shot 数量

```bash
# 不同任务不同 shot
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu,gsm8k,hellaswag \
  --num_fewshot 5,4,3  # 对应每个任务

# 或对所有任务统一设置
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --num_fewshot 5
```

### 生成详细报告

```bash
# 输出到文件
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --output_path ./results/qwen_mmlu.json

# 生成 markdown 报告
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu,gsm8k,hellaswag \
  --output_path ./results/full_report.json

# 仅输出日志
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --log_samples \
  --output_path ./results/samples
```

## 自定义评测任务

### 注册自定义任务

```python
# custom_task.py
import lm_eval.api.task
from lm_eval.api.instance import Instance
from lm_eval.api.task import ConfigurableTask

class CustomTask(ConfigurableTask):
    VERSION = 0
    DATASET_PATH = "your-dataset-name"
    DATASET_NAME = None

    def has_training_docs(self):
        return True

    def has_validation_docs(self):
        return True

    def has_test_docs(self):
        return True

    def training_docs(self):
        return self.dataset["train"]

    def validation_docs(self):
        return self.dataset["validation"]

    def test_docs(self):
        return self.dataset["test"]

    def doc_to_text(self, doc):
        return f"Question: {doc['question']}\nAnswer:"

    def doc_to_target(self, doc):
        return f" {doc['answer']}"

    def process_results(self, doc, results):
        pred = results[0].strip()
        target = doc["answer"].strip()
        return {"acc": pred == target}
```

```bash
# 使用自定义任务
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks custom_task \
  --include_path ./custom_task/
```

### YAML 配置任务

```yaml
# tasks/custom_qa.yaml
task: custom_qa
dataset_path: json
dataset_kwargs:
  data_files: data/qa_test.json
output_type: generate_until
training_split: null
test_split: train
doc_to_text: "问题: {{question}}\n答案:"
doc_to_target: " {{answer}}"
metric_list:
  - metric: exact_match
    aggregation: mean
    higher_is_better: true
  - metric: f1
    aggregation: mean
    higher_is_better: true
generation_kwargs:
  max_gen_toks: 64
  temperature: 0
  do_sample: false
```

```bash
# 使用 YAML 配置的任务
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks custom_qa \
  --include_path ./tasks/
```

## 评测结果解读

### 输出格式

```python
# 评测结果示例
{
    "results": {
        "mmlu": {
            "acc": 0.625,            # 准确率
            "acc_stderr": 0.005,      # 标准误差
            "alias": "mmlu"          # 任务别名
        },
        "gsm8k": {
            "exact_match": 0.453,    # 精确匹配
            "exact_match_stderr": 0.012,
        }
    },
    "config": {
        "model": "Qwen/Qwen2.5-7B-Instruct",
        "num_fewshot": 5,
        "batch_size": "auto",
        "device": "cuda:0"
    },
    "model_configs": {
        "pretrained": "Qwen/Qwen2.5-7B-Instruct"
    }
}
```

### 分数解读

**MMLU (0-shot vs 5-shot)**

- 0-shot：直接提问，不提供示例
- 5-shot：提供 5 个示例后再提问
- 通常 5-shot 比 0-shot 高 5-15%

**HumanEval (pass@1 vs pass@10)**

```bash
# pass@k 需要多个采样
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks humaneval \
  --num_fewshot 0 \
  --gen_kwargs temperature=0.8,do_sample=True,num_return_sequences=10
```

- pass@1：单次生成功率
- pass@10：10 次采样中至少 1 次成功

## 模型对比评估

```python
import lm_eval
import json

models_to_test = [
    "Qwen/Qwen2.5-7B-Instruct",
    "mistralai/Mistral-7B-Instruct-v0.3",
    "meta-llama/Llama-3.1-8B-Instruct",
]

tasks = ["mmlu", "gsm8k", "hellaswag"]

results_summary = {}

for model_name in models_to_test:
    print(f"Evaluating {model_name}...")

    model = lm_eval.models.hf_model.HFLM(
        pretrained=model_name,
        device="cuda:0",
        batch_size="auto",
    )

    results = lm_eval.simple_evaluate(
        model=model,
        tasks=tasks,
        num_fewshot=5,
        batch_size="auto",
    )

    results_summary[model_name] = {
        task: results["results"][task]["acc"]
        for task in tasks
    }

# 打印对比表
print(f\"{'Model':<40} {'MMLU':<8} {'GSM8K':<8} {'HellaSwag':<10}\")
print("-" * 68)
for model, scores in results_summary.items():
    print(f"{model:<40} {scores['mmlu']*100:<8.1f} {scores['gsm8k']*100:<8.1f} {scores['hellaswag']*100:<10.1f}")
```

## 集成到训练流程

### 训练中定期评测

```python
# train_with_eval.py
import torch
from transformers import AutoModelForCausalLM, TrainingArguments, Trainer
import lm_eval
import wandb

# 训练回调：每 N 步评测
class EvalCallback:
    def __init__(self, eval_steps=500, tasks=["mmlu", "gsm8k"]):
        self.eval_steps = eval_steps
        self.tasks = tasks

    def on_step_end(self, args, state, control, model=None, **kwargs):
        if state.global_step % self.eval_steps == 0 and state.global_step > 0:
            # 评测
            results = lm_eval.simple_evaluate(
                model=lm_eval.models.hf_model.HFLM(
                    pretrained=model.config._name_or_path,
                    device="cuda:0",
                ),
                tasks=self.tasks,
                num_fewshot=0,
            )

            # 记录到 WandB
            for task, scores in results["results"].items():
                for metric, value in scores.items():
                    if metric.endswith("_stderr"):
                        continue
                    wandb.log({f"eval/{task}_{metric}": value}, step=state.global_step)
```

### 评测脚本自动化

```bash
#!/bin/bash
# eval_all_models.sh

MODELS=(
    "Qwen/Qwen2.5-7B-Instruct"
    "Qwen/Qwen2.5-14B-Instruct"
    "Qwen/Qwen2.5-32B-Instruct"
)

TASKS="mmlu,gsm8k,hellaswag,truthfulqa"

for MODEL in "${MODELS[@]}"; do
    MODEL_NAME=$(echo $MODEL | tr '/' '_')
    echo "Evaluating $MODEL..."

    lm-eval --model hf \
      --model_args pretrained=$MODEL \
      --tasks $TASKS \
      --num_fewshot 5 \
      --output_path "./results/${MODEL_NAME}_results.json" \
      --batch_size auto
done

# 生成汇总报告
python -c "
import json, os

results = {}
for f in os.listdir('./results'):
    if f.endswith('_results.json'):
        with open(f'./results/{f}') as fp:
            data = json.load(fp)
        model = f.replace('_results.json', '')
        results[model] = data['results']

print(json.dumps(results, indent=2))
"
```

## 常见问题

### 显存不足

```bash
# 降低 batch_size
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --batch_size 1

# 使用量化
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct,load_in_4bit=True \
  --tasks mmlu
```

### 评测速度慢

```bash
# 使用 vLLM 后端（10-50x 加速）
lm-eval --model vllm \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu

# 多进程加速
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct \
  --tasks mmlu \
  --num_fewshot 5 \
  --batch_size auto \
  --num_workers 4
```

### 结果不可复现

```bash
# 设置随机种子
lm-eval --model hf \
  --model_args pretrained=Qwen/Qwen2.5-7B-Instruct,seed=42 \
  --tasks mmlu
```

## 最佳实践

1. **选择合适的基准**：根据任务类型选择评测基准
2. **控制变量**：评测时固定 batch_size、precision、seed
3. **报告置信区间**：关注 stderr 而非仅有 acc
4. **Few-shot 一致性**：确保 few-shot 示例的随机种子固定
5. **链式评测**：先小任务（HellaSwag）再大任务（MMLU）
6. **记录配置**：保存评测时的完整 config 信息
7. **定期评测**：在训练过程中定期运行，跟踪模型变化

## 参考链接

- 文档: https://github.com/EleutherAI/lm-evaluation-harness
- 支持的基准列表: https://github.com/EleutherAI/lm-evaluation-harness/blob/main/docs/task_table.md
- 论文: https://arxiv.org/abs/2305.11952
- HuggingFace 集成: https://huggingface.co/blog/eval-harness-integration
