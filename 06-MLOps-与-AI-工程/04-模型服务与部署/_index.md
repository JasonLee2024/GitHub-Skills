# 06-04 — 模型服务与部署

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[huggingface-hub]] | `huggingface-hub` | 模型注册表 API、搜索下载上传、Git 版本控制 |
| [[modal-serverless-gpu]] | `modal-serverless-gpu` | 无服务器 GPU 平台，自动扩缩，按需计费 |

## 概述

模型服务与部署是将训练好的模型投入生产环境的关键环节。本章涵盖两大主题：

1. **Hugging Face Hub** — 模型注册表、版本管理、社区协作
2. **Modal** — 无服务器 GPU 云平台，适合快速部署推理服务和批处理任务

## 工作流

```
训练 → HF Hub（存储版本）→ Modal（部署推理）→ 应用
                       ↘ 下载 GGUF → llama.cpp（本地推理）
                       ↘ 微调结果上传 → 版本迭代
```

## 选择指南

| 需求 | 推荐方案 |
|------|---------|
| 模型发现和下载 | Hugging Face Hub |
| 快速部署推理 API | Modal |
| 模型版本管理 | Hugging Face Hub |
| 无服务器自动扩缩 | Modal |
| 国内访问加速 | HF 镜像站 + 本地缓存 |
