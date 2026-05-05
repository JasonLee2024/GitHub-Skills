# GitHub 技能知识库 — 从小白到高手的学习地图

> 欢迎！这是一份**零基础友好的 GitHub 学习指南**。无论你是编程新手、在校学生、还是想提升开发效率的工程师，这份地图都能带你一步步从入门到精通。

---

## 快速定位：你现在在哪？

| 你的水平 | 对应章节 | 预计时间 |
|---------|---------|---------|
| 完全零基础 | 01-入门指南 | 1-2 天 |
| 会用 git 但不太熟 | 02-核心操作 | 3-5 天 |
| 日常协作没问题 | 03-软件开发方法论 | 3-5 天 |
| 想自动化一切 | 04-自动化与CI-CD | 2-3 天 |
| 想用 AI 辅助开发 | 05-自主AI-Agent | 3-5 天 |
| 对 AI 模型感兴趣 | 06-MLOps-与-AI-工程 | 5-10 天 |
| 需要做学术研究 | 07-科研工作流 | 2-3 天 |
| 想做炫酷的可视化 | 08-创意与可视化 | 3-5 天 |
| 想提升工作效率 | 09-生产工具与效率 | 2-3 天 |
| 负责系统运维 | 10-运维与监控 | 2-3 天 |
| 关心代码安全 | 11-安全与红队 | 2-3 天 |
| 想了解最佳实践 | 12-最佳实践与模式 | 1-2 天 |

---

## 第一阶段：GitHub 入门（01 → 02）

**目标：** 学会在 GitHub 上管理代码、与他人协作。

### 第 1 步：配置你的 GitHub 账号

1. 注册 GitHub 账号（github.com）
2. 安装 Git（Windows 用户推荐 Git for Windows）
3. 跟着教程配置认证：

- [[01-入门指南/github-auth]] — SSH 密钥、Token、gh CLI 三种认证方式
- 实操任务：完成 gh CLI 登录，创建你的第一个 Token

### 第 2 步：创建和管理仓库

- [[01-入门指南/github-repo-management]] — 从零创建、克隆、Fork、配置仓库
- 实操任务：创建一个名为 `hello-world` 的仓库，添加 README，克隆到本地

### 第 3 步：提交你的第一段代码

```
git clone https://github.com/你的用户名/hello-world.git
cd hello-world
echo "# Hello World" > README.md
git add .
git commit -m "feat: init project"
git push
```

### 第 4 步：参与协作 — Pull Request

- [[02-GitHub-核心操作/github-pr-workflow]] — PR 全流程
- 实操任务：找一个开源项目，提交一个文档修正的 PR

### 第 5 步：学会提 Issue

- [[02-GitHub-核心操作/github-issues]] — Issue 生命周期、标签、搜索
- 实操任务：在 hello-world 仓库创建一个 Bug 报告 Issue

---

## 第二阶段：团队协作（02 → 03）

**目标：** 成为团队中高效的协作者。

### 第 6 步：代码审查（Code Review）

- [[02-GitHub-核心操作/github-code-review]] — 审查清单、内联评论
- 实操任务：找一个同学的 PR，完整走一遍审查流程

### 第 7 步：部署你的项目页面

- [[02-GitHub-核心操作/github-pages-setup]] — GitHub Pages 免费部署
- 实操任务：把 hello-world 仓库部署到 GitHub Pages

### 第 8 步：学会写计划再动手

- [[03-软件开发方法论/plan]] — 先计划再执行
- [[03-软件开发方法论/writing-plans]] — 如何编写可执行的计划

### 第 9 步：测试驱动开发（TDD）

- [[03-软件开发方法论/test-driven-development]] — RED-GREEN-REFACTOR 循环
- 实操任务：用 TDD 方式写一个简单的计算器函数

### 第 10 步：学会系统化排错

- [[03-软件开发方法论/systematic-debugging]] — 4 阶段根因分析法
- 实操任务：故意写一个 Bug，用系统化方法调试

---

## 第三阶段：自动化（04 → 05）

**目标：** 用自动化省下大量重复劳动，用 AI 辅助开发。

### 第 11 步：CI/CD 自动构建测试

- [[04-自动化与CI-CD/ci-cd-workflows]] — GitHub Actions 工作流
- 实操任务：给 hello-world 仓库添加自动测试工作流

### 第 12 步：Webhook 事件驱动

- [[04-自动化与CI-CD/webhook-subscriptions]] — 订阅 GitHub 事件
- 实操任务：配置一个当 Issue 创建时自动回复的 Webhook

### 第 13 步：探索自动化模式

- [[04-自动化与CI-CD/automation-patterns]] — 定时任务、自动合并、依赖更新
- 实操任务：配置 Dependabot 自动更新依赖

### 第 14 步：AI 编程入门 — Hermes Agent

- [[05-自主AI-Agent/hermes-agent]] — 你的 AI 编程助手
- 实操任务：安装 Hermes Agent，跑一个简单的自动化任务

### 第 15 步：进阶 AI 代理

- [[05-自主AI-Agent/claude-code]] — Claude Code CLI
- [[05-自主AI-Agent/codex]] — OpenAI Codex
- [[05-自主AI-Agent/opencode]] — OpenCode
- 实操任务：用 Claude Code 完成一个小的代码重构任务

### 第 16 步：多代理协作

- [[05-自主AI-Agent/multi-agent-patterns]] — 并行开发、子代理分工
- 实操任务：拆解一个任务让多个代理并行完成

---

## 第四阶段：AI 模型实战（06）

**目标：** 了解并实践 AI 模型的本地运行、微调和部署。

> 这部分需要一定计算资源。如果只有普通电脑，从"模型推理"开始；如果有 GPU，可以尝试"微调"。

### 第 17 步：本地运行 LLM

- [[06-MLOps-与-AI-工程/01-模型推理/llama-cpp]] — 在本地运行开源模型
- 实操任务：下载一个 GGUF 格式模型，在本地跑起来

### 第 18 步：结构化输出

- [[06-MLOps-与-AI-工程/01-模型推理/outlines]] — 保证 JSON/XML 输出格式
- 实操任务：让 LLM 输出符合 JSON Schema 的结果

### 第 19 步：高性能推理

- [[06-MLOps-与-AI-工程/01-模型推理/vllm]] — vLLM 高吞吐服务
- 实操任务：用 vLLM 部署并调用 API

### 第 20 步：LoRA 微调入门

- [[06-MLOps-与-AI-工程/02-模型微调/peft-lora]] — 参数高效微调
- 实操任务：用 LoRA 微调一个小模型

### 第 21 步：快速微调

- [[06-MLOps-与-AI-工程/02-模型微调/unsloth]] — 2-5x 加速微调
- [[06-MLOps-与-AI-工程/02-模型微调/axolotl]] — YAML 配置微调

### 第 22 步：强化学习微调

- [[06-MLOps-与-AI-工程/02-模型微调/trl-rlhf]] — RLHF/DPO 训练
- 实操任务：用 DPO 让模型学会遵循特定风格

### 第 23 步：分布式训练基础

- [[06-MLOps-与-AI-工程/03-分布式训练/pytorch-fsdp]] — FSDP 分布式训练

### 第 24 步：模型部署与托管

- [[06-MLOps-与-AI-工程/04-模型服务与部署/huggingface-hub]] — Hugging Face Hub
- [[06-MLOps-与-AI-工程/04-模型服务与部署/modal-serverless-gpu]] — 无服务器 GPU

### 第 25 步：评测与实验跟踪

- [[06-MLOps-与-AI-工程/05-实验跟踪与评估/llm-evaluation-harness]] — 基准评测
- [[06-MLOps-与-AI-工程/05-实验跟踪与评估/wandb]] — Weights & Biases 实验管理

### 第 26 步：声明式 AI 系统

- [[06-MLOps-与-AI-工程/06-DSPy-声明式AI/dspy]] — 用 DSPy 构建 AI 系统
- 实操任务：用 DSPy 构建一个 RAG 问答系统

---

## 第五阶段：拓展技能（07 → 09）

**目标：** 掌握学术研究、创意可视化、生产工具等技能。

### 第 27 步：学术论文搜索

- [[07-科研工作流/01-arxiv-paper-search]] — arXiv API、引用分析
- 实操任务：搜索 3 篇你感兴趣的论文，分析引用关系

### 第 28 步：构建个人知识库

- [[07-科研工作流/03-llm-wiki-knowledge-base]] — Karpathy 式知识库
- [[01-入门指南/github-repo-management]] — 用 GitHub 管理知识库
- 实操任务：用 Obsidian + GitHub 搭建个人知识库

### 第 29 步：YouTube 内容提取

- [[07-科研工作流/04-youtube-content]] — 获取字幕、生成摘要
- 实操任务：提取一个技术演讲的字幕，生成结构化笔记

### 第 30 步：制作信息图

- [[08-创意与可视化/01-baoyu-infographic]] — 21 种布局 × 21 种风格
- 实操任务：把一份代码架构说明变成信息图

### 第 31 步：画手绘风格图表

- [[08-创意与可视化/02-excalidraw]] — 手绘风格架构图、流程图
- 实操任务：画出你上一个项目的架构图

### 第 32 步：设计软件架构图

- [[08-创意与可视化/03-architecture-diagram]] — 深色主题 SVG
- 实操任务：画出微服务架构图

### 第 33 步：创意动画与 ASCII 艺术

- [[08-创意与可视化/04-p5js-manim]] — p5js 交互 + Manim 数学动画
- [[08-创意与可视化/05-ascii-art-video]] — ASCII 艺术视频
- 实操任务：用 ASCII 做一个简单的 Logo 动画

### 第 34 步：Google Workspace 自动化

- [[09-生产工具与效率/01-google-workspace]] — Gmail/Calendar/Drive
- 实操任务：设置一个自动处理邮件的脚本

### 第 35 步：Notion + Linear 管理

- [[09-生产工具与效率/02-notion]] — Notion API
- [[09-生产工具与效率/03-linear]] — Linear 项目管理

### 第 36 步：文档处理

- [[09-生产工具与效率/04-nano-pdf]] — PDF 自然语言编辑
- [[09-生产工具与效率/05-powerpoint]] — PowerPoint 自动化
- [[09-生产工具与效率/07-ocr-documents]] — OCR 与文档提取

---

## 第六阶段：运维与安全（10 → 11）

**目标：** 学会系统运维和代码安全。

### 第 37 步：系统运维

- [[10-运维与监控/01-webhook-ops]] — Webhook 运维
- [[10-运维与监控/02-blog-monitor]] — 博客监控
- [[10-运维与监控/03-pages-ops]] — Pages 运维

### 第 38 步：GitHub 安全最佳实践

- [[11-安全与红队/01-github-security]] — Secrets/Branch Protection/Dependabot
- 实操任务：给你的仓库配置 Branch Protection 规则

### 第 39 步：安全代码审查

- [[11-安全与红队/02-security-code-review]] — 安全维度代码审查

### 第 40 步：了解红队技术

- [[11-安全与红队/03-godmode]] — G0DM0D3 模型越狱
- [[11-安全与红队/04-obliteratus]] — 模型安全

---

## 第七阶段：融会贯通（12 + 附录）

**目标：** 把所学知识整合成自己的工作流。

### 第 41 步：仓库管理最佳实践

- [[12-最佳实践与模式/01-repo-best-practices]]

### 第 42 步：工作流设计模式

- [[12-最佳实践与模式/02-workflow-patterns]]

### 第 43 步：协作工作流模式

- [[12-最佳实践与模式/03-collaboration-patterns]]

### 第 44 步：知识管理最佳实践

- [[12-最佳实践与模式/04-knowledge-management]]

### 第 45 步：现代开发工作流整合

- [[12-最佳实践与模式/05-modern-dev-workflow]] — 把所有技能串联起来

---

## 三个实战项目推荐

学完基础后，选一个你感兴趣的项目实战：

### 项目一：搭建个人博客（难度 ⭐）
```
GitHub Pages + Jekyll → 自动部署
涉及：01-认证 → 02-仓库管理 → 02-Pages部署 → 04-CI/CD
```

### 项目二：构建 AI 知识库（难度 ⭐⭐）
```
LLM Wiki + GitHub + Obsidian → 知识沉淀 + 自动同步
涉及：01-仓库 → 02-PR → 03-计划 → 07-LLM Wiki → 04-Actions
```

### 项目三：AI 模型微调与部署（难度 ⭐⭐⭐）
```
LoRA 微调 + vLLM 部署 + Hugging Face → 完整 MLOps 流水线
涉及：06-全章节 → 05-Agent 编排 → 04-CI/CD
```

---

## 学习建议

1. **不要一次性学完** — 每天 1-2 步，每个步骤包含实操
2. **边学边做笔记** — 用这个知识库 + Obsidian 记录你的学习笔记
3. **遇到问题先查附录** — [[99-附录与速查/术语表]] 有常见的术语解释
4. **善用速查表** — [[99-附录与速查/GitHub-CLI-命令大全]] 和 [[99-附录与速查/GitHub-REST-API-速查]] 是日常高频参考
5. **不懂的命令不要盲目复制** — 先理解再执行，安全第一

---

## 附录：学习进度表

复制以下内容到你的 Obsidian 或记事本，每完成一步打个勾：

```
- [ ] 01. 认证配置
- [ ] 02. 仓库管理
- [ ] 03. 克隆与提交
- [ ] 04. Pull Request
- [ ] 05. Issue 管理
- [ ] 06. Code Review
- [ ] 07. GitHub Pages
- [ ] 08-10. 软件开发方法论
- [ ] 11-13. CI/CD 自动化
- [ ] 14-16. AI 代理
- [ ] 17-26. MLOps
- [ ] 27-36. 科研/创意/效率
- [ ] 37-40. 运维/安全
- [ ] 41-45. 最佳实践
- [ ] 实战项目一
- [ ] 实战项目二
- [ ] 实战项目三
```

---

## 知识库结构一览

```
01-入门指南 → 02-GitHub核心操作 → 03-软件开发方法论
    ↓                                        ↓
04-自动化与CI/CD → 05-自主AI-Agent → 06-MLOps与AI工程
    ↓
07-科研工作流 → 08-创意与可视化 → 09-生产工具与效率
    ↓
10-运维与监控 → 11-安全与红队 → 12-最佳实践与模式
    ↓
99-附录与速查（随时查阅）
```

> 祝学习愉快！记住：**每个专家都曾是小白**，关键是持续动手实践。

---

**下一步：** 从 [[01-入门指南/github-auth]] 开始你的 GitHub 之旅吧！
