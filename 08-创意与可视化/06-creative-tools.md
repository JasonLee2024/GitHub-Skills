---
date: 2026-05-05
tags:
  - creative-tools
  - design-systems
  - music-generation
  - ideation
  - songwriting
  - art-generation
  - 创意与可视化
source_skill: popular-web-designs, songwriting-and-ai-music, ideation
category: 创意与可视化
---

# 创意工具集：设计系统、音乐创作与创意生成

> 本文档基于 Hermes Agent 的 `popular-web-designs`、`songwriting-and-ai-music` 和 `ideation` 技能整理，涵盖设计系统、AI 音乐创作和创意约束生成三大方向。

## 概述

本章节介绍除信息图、图表和动画之外的创意工具集合，覆盖三个主要方向：

1. **设计系统（popular-web-designs）** — 54 个生产级设计系统，可直接复用
2. **歌曲创作与 AI 音乐（songwriting-and-ai-music）** — 歌词创作 + Suno AI 音乐生成
3. **创意生成（ideation）** — 通过创造性约束激发项目灵感

---

## 设计系统库（popular-web-designs）

### 概述

`popular-web-designs` 技能提供了 **54 个生产级别的设计系统**，从真实世界的网页和应用中提取。每个设计系统包含完整的颜色、排版、UI 组件和布局模式。

### 设计系统结构

每个设计系统包含以下元素：

```
design-system/
├── colors/           # 配色方案（主色/辅色/中性色）
├── typography/       # 字体层级（标题/正文/标注）
├── components/       # UI 组件（按钮/输入框/卡片/导航）
├── layouts/          # 布局模式（网格/文章/仪表盘）
└── tokens/           # 设计令牌（间距/圆角/阴影）
```

### 设计系统风格分类

| 风格类别 | 代表系统 | 特点 |
|----------|---------|------|
| 极简主义 | Apple, Linear, Notion | 大量留白、细线条、克制 |
| 开发者工具 | GitHub, VSCode, Vercel | 深色模式、代码高亮、侧边栏 |
| 新闻媒体 | NYTimes, Medium, Substack | 排版驱动、文章为中心 |
| 电商 | Shopify, Stripe, Figma | 转化导向、卡片布局 |
| 社交 | Twitter(X), Discord, Slack | 实时更新、列表流 |
| 企业 SaaS | Salesforce, Atlassian, Monday | 仪表盘、数据表格 |
| 创意设计 | Dribbble, Behance, Awwwards | 视觉冲击、动效丰富 |

### 实战用法

#### 为项目选择设计系统

```bash
# 查询可用的设计系统
# 在 Hermes Agent 中：
"列出所有可用的设计系统"
"推荐适合博客站点的设计系统"
"我需要一个类似 Linear 的管理面板设计"

# 获取系统详细信息
"查看 GitHub 设计系统的配色方案"
"导出 Linear 的排版层级"
```

#### 复用设计系统

1. **搜索** — 按场景/风格查找匹配的设计系统
2. **分析** — Agent 详细解读该系统的视觉规则
3. **应用** — 将设计系统适配到你的项目中
4. **自定义** — 基于现有系统修改配色和排版

### 关键设计原则

```
颜色（5 个以内）：
  1 主色 + 1-2 辅色 + 2 中性色

排版（3 个层级）：
  H1: xxxl / H2: xl / 正文: md

间距（4 的倍数）：
  4px 8px 16px 24px 32px 48px 64px

圆角（3 种）：
  小 4px / 中 8px / 大 16px
```

---

## AI 音乐创作（songwriting-and-ai-music）

### 概述

Hermes Agent 的 `songwriting-and-ai-music` 技能在 AI 音乐生成的工作流中提供**歌词创作**支持（专注 Suno 平台）。

### 歌曲结构基础

```
[Intro]     — 前奏，建立氛围（4-8 小节）
[Verse]     — 主歌，讲述故事细节（8-16 小节）
[Chorus]    — 副歌，核心旋律和记忆点（8 小节）
[Verse 2]   — 第二段主歌，推进叙述
[Chorus]    — 副歌重复
[Bridge]    — 桥段，情感转折（4-8 小节）
[Chorus]    — 最后副歌，高潮
[Outro]     — 尾声，渐弱（4-8 小节）
```

### Suno AI Prompt 编写指南

Suno 是最流行的 AI 音乐生成平台之一。编写有效的 Suno Prompt 需要理解以下要素：

```
[风格标签] [情感描述] [乐器] [节奏/速度] [声乐风格]

示例：
"epic orchestral cinematic trailer music, 
 heroic and uplifting, 
 full orchestra with brass and strings, 
 120 BPM, 
 powerful male choir"
```

| 参数 | 示例 | 说明 |
|------|------|------|
| 风格 | pop, rock, hip-hop, orchestral, EDM | 定义音乐类型 |
| 情感 | happy, melancholic, energetic, dark | 定义情绪基调 |
| 乐器 | acoustic guitar, synth pads, piano | 定义音色 |
| 节奏 | 80 BPM, fast, slow, 4/4 | 定义速度 |
| 声乐 | female vocals, rap, choir, spoken word | 定义人声风格 |
| 参考 | 80s synthwave, lo-fi beats | 参考风格 |

### 歌词创作工作流

```
Step 1: 确定主题和情感基调
  → "写一首关于远程开发者的歌曲，孤独但充满希望"

Step 2: Agent 分析主题
  → 确定关键词：代码、深夜、屏幕、连接、创造
  → 确定情感弧：孤独 → 专注 → 成就 → 连接

Step 3: 生成歌词草案（含结构标注）
  → [Verse 1] 深夜屏幕的光 / 代码流淌如河
  → [Chorus] We build in the dark / To shine in the light
  → [Bridge] 千里之外 / 同一行代码

Step 4: 用户审阅和修改
  → 调整韵脚 / 修改比喻 / 优化结构

Step 5: 组合 Suno Prompt
  → 歌词 + 音乐风格描述 → Suno 生成
```

### 歌词创作技巧

| 技巧 | 说明 | 示例 |
|------|------|------|
| 具体意象 | 用具体的画面代替抽象概念 | "404 错误" 比 "出问题了" 好 |
| 情感弧线 | 从低到高或从混乱到有序 | 主歌低沉 → 副歌昂扬 |
| 韵脚模式 | AABB / ABAB / ABCB | "我在深夜 coding / 屏幕闪烁 glowing" |
| 重复钩子 | 副歌中的重复短语 | "Just one more commit..." |
| 科技隐喻 | 将技术术语情感化 | "你的微笑像 git merge" |

---

## 创意生成（ideation）

### 概述

`ideation` 技能通过**创造性约束**（Creative Constraints）来激发项目创意。与其问"有什么项目可以做"，不如通过一系列限制条件来缩小范围、提高创造力。

### 约束框架

```
约束类型：
├── 技术约束：语言、框架、运行时、硬件
├── 功能约束：解决什么问题、输入/输出
├── 体验约束：终端/TUI/GUI/Web/移动端
├── 时间约束：周末完成/一天/一小时
└── 创意约束：风格参考、主题限定
```

### 实战用法

```bash
# 生成创意
"给我一个 Python CLI 项目创意，终端界面，一天能完成"

# Agent 会基于约束生成：
"""
项目：Git History Visualizer

约束分析：
- 技术: Python
- 界面: CLI/TUI
- 时间: 一天

创意描述：
一个终端工具，git log 输出可视化为 
ASCII 分支图和时间线。
类似于 git log --graph 但更美观。

核心功能：
1. 读取 git 历史 
2. 颜色编码分支
3. ASCII 艺术渲染
4. 交互式导航（上下键）
5. 提交详情预览
"""
```

### 创意生成向导

| 约束维度 | 选项示例 |
|----------|---------|
| 技术栈 | Python CLI / Rust / Go / Node.js |
| 领域 | DevOps / 数据可视化 / 学习工具 / 自动 |
| 用户类型 | 开发者 / 设计师 / 学生 / 运维 |
| UI 类型 | TUI / Web / API库 / 浏览器扩展 |
| 时间范围 | 1小时 / 一天 / 一周 / 一个月 |
| 创意主题 | 复古 / 极简 / 游戏化 / 可视化 |

### 创意筛选矩阵

生成多个创意后，使用以下矩阵进行筛选：

```
| 创意 | 实用性 | 创新性 | 可学习性 | 可实现性 | 总分 |
|------|--------|--------|----------|----------|------|
| A    | 8/10   | 6/10   | 7/10     | 9/10     | 30   |
| B    | 5/10   | 9/10   | 8/10     | 4/10     | 26   |
| C    | 7/10   | 7/10   | 8/10     | 7/10     | 29   |
```

---

## 综合使用场景

### 示例：从创意到完整项目

```
1. Ideation: "一个开发者专用的终端音乐播放器"
   → 生成 3 个变体创意

2. Design System: "适合终端播放器的设计风格"
   → 加载 terminal 类设计系统（Retro/Cyberpunk）

3. Songwriting: "需要封面音乐"
   → 生成歌词 + Suno Prompt → 生成音乐

4. ASCII Art: "播放器的品牌标题"
   → pyfiglet + 字体组合
```

---

## 相关技能

- [[01-baoyu-infographic]] — 信息图设计
- [[02-excalidraw]] — 手绘风格图表
- [[03-architecture-diagram]] — 架构图设计
- [[04-p5js-manim]] — 交互视觉与动画
- [[05-ascii-art-video]] — ASCII 艺术与视频
