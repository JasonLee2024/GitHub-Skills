# 06-02 — 模型微调

## 内容

| 文档 | 技能来源 | 特色 |
|------|---------|------|
| [[peft-lora]] | `peft-fine-tuning` | LoRA/QLoRA 参数高效微调，显存优化 |
| [[unsloth]] | `unsloth` | 2-5x 快速微调，减少显存，GGUF 导出 |
| [[axolotl]] | `axolotl` | YAML 配置驱动的微调框架，支持 100+ 模型 |
| [[trl-rlhf]] | `fine-tuning-with-trl` | RLHF/DPO/GRPO/ORPO 强化学习微调 |

## 选择指南

- **快速实验** → `Unsloth`（速度最快，显存最少）
- **完整控制** → `Axolotl`（YAML 配置，适合生产环境）
- **参数高效** → `PEFT/LoRA`（灵活控制 LoRA 参数）
- **RL 对齐** → `TRL`（DPO/GRPO 人类偏好对齐）

## 工作流

```
数据准备 → Unsloth 快速实验 → Axolotl 生产训练 → TRL 偏好对齐 → 模型部署
```
