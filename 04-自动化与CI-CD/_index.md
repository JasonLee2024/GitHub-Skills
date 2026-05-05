---
title: 04 — 自动化与 CI/CD
nav_order: 0
---

# 04 — 自动化与 CI/CD

## 本章节内容

从 GitHub Actions 到 Webhook，构建完整的自动化体系。

| 文档 | 内容 | 技能来源 |
|------|------|---------|
| [[webhook-subscriptions]] | Webhook 订阅管理、事件驱动架构、安全签名 | `webhook-subscriptions` |
| [[ci-cd-workflows]] | CI/CD 工作流设计模式、GitHub Actions 精讲 | `github-repo-management` |
| [[automation-patterns]] | 自动化模式：定时任务、自动回复、自动合并 | `webhook-subscriptions` |

## 自动化流水线

```
Git Push → GitHub Actions → Test → Build → Deploy (Pages)
                              │
                   Webhook → Agent 通知
```

### 各文件速览

- **webhook-subscriptions.md** — 涵盖 Hermes Webhook 平台配置、订阅管理命令、Prompt 模板语法、GitHub/Stripe/CI 集成模式、安全签名验证、故障排查
- **ci-cd-workflows.md** — 涵盖 GitHub Actions 触发器、矩阵构建、Docker 构建与推送、多环境部署流水线、可复用工作流、复合 Action、自托管 Runner、OIDC、缓存策略、Pages 部署、安全最佳实践
- **automation-patterns.md** — 涵盖 8 种自动化模式（定时任务、自动回复、自动合并、依赖更新、分支清理、通知报告、生命周期管理、数据汇总），附决策树和最佳实践

## 相关 Hermes 技能

- `webhook-subscriptions`, `github-repo-management`
- `github-pages-setup` — Pages 部署（详见 [[../02-GitHub-核心操作/github-pages-setup]]）
- `blogwatcher` — RSS 监控与自动化
