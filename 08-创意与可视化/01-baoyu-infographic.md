---
date: 2026-05-05
tags:
  - baoyu-infographic
  - infographic
  - visualization
  - visual-summary
  - data-visualization
  - image-generation
  - 创意与可视化
source_skill: baoyu-infographic
category: 创意与可视化
---

# 信息图设计（21 种布局 × 21 种风格）

> 本文档基于 Hermes Agent 的 `baoyu-infographic` 技能整理，覆盖从内容分析到信息图生成的全流程实操。

## 概述

信息图（Infographic）是**高密度信息可视化**的艺术——在有限的画布上，用视觉语言传达数据和概念。Hermes Agent 集成了宝玉（JimLiu）开发的 `baoyu-infographic` 信息图生成器，提供 **21 种布局 × 21 种视觉风格** 的组合矩阵，满足几乎所有内容类型的信息图需求。

本技能的两大核心维度：
- **布局（Layout）** — 信息的组织结构
- **风格（Style）** — 视觉美学表达

任何布局可以任意搭配任何风格，组合出 441+ 种独特的信息图。

---

## 布局画廊

| 布局 | 最佳用途 | 描述 |
|------|----------|------|
| `linear-progression` | 时间线、步骤教程 | 线性递进展示发展历程 |
| `binary-comparison` | 对比分析 | A vs B、前后对比、优劣 |
| `comparison-matrix` | 多因素对比 | 表格化多维比较 |
| `hierarchical-layers` | 金字塔、优先级 | 层级结构展示 |
| `tree-branching` | 分类、分类学 | 树状分支展示类别 |
| `hub-spoke` | 中心概念 | 中心主题 + 关联子项 |
| `structural-breakdown` | 分解视图 | 爆炸图和剖面图 |
| `bento-grid` | 综合概览 | 多主题网格布局（默认） |
| `iceberg` | 表面 vs 深层 | 冰山模型揭示隐藏内容 |
| `bridge` | 问题-方案 | 从问题到解决方案 |
| `funnel` | 转化漏斗 | 转化率和过滤过程 |
| `isometric-map` | 空间关系 | 等距视图展示空间布局 |
| `dashboard` | 指标面板 | 关键指标仪表盘 |
| `periodic-table` | 分类集合 | "元素周期表"风格 |
| `comic-strip` | 叙事序列 | 漫画分格叙事 |
| `story-mountain` | 故事张力 | 情节结构张力弧 |
| `jigsaw` | 互连部件 | 拼图式展示关联 |
| `venn-diagram` | 重叠概念 | 韦恩图展示交集 |
| `winding-roadmap` | 路线图 | 曲折路径 + 里程碑 |
| `circular-flow` | 循环流程 | 循环和迭代过程 |
| `dense-modules` | 高密度信息 | 数据密集型内容（信息大图） |

---

## 风格画廊

| 风格 | 描述 | 适用场景 |
|------|------|----------|
| `craft-handmade` | 手绘质感、纸张工艺（默认） | 通用、教育内容 |
| `claymation` | 3D 黏土角色、定格动画 | 儿童内容、趣味话题 |
| `kawaii` | 日式可爱、柔和粉彩 | 社交媒体、生活类 |
| `storybook-watercolor` | 水彩手绘、童话感 | 故事讲述、人文内容 |
| `chalkboard` | 黑板粉笔 | 教学、头脑风暴 |
| `cyberpunk-neon` | 赛博霓虹、未来感 | 科技、AI 话题 |
| `bold-graphic` | 漫画风格、网点效果 | 大胆观点、社交传播 |
| `aged-academia` | 复古科学、暖色调 | 历史、学术内容 |
| `corporate-memphis` | 扁平矢量、孟菲斯风格 | 商业报告、企业展示 |
| `technical-schematic` | 工程蓝图 | 架构、机械、数据流 |
| `origami` | 折纸几何 | 创意、设计话题 |
| `pixel-art` | 8-bit 像素风 | 复古主题、游戏内容 |
| `ui-wireframe` | 灰度线框 | 产品设计、原型展示 |
| `subway-map` | 地铁线路图 | 流程、路线、关系图 |
| `ikea-manual` | 宜家极简线稿 | 教程、步骤说明 |
| `knolling` | 整理排列摄影风 | 资源盘点、工具展示 |
| `lego-brick` | 乐高积木 | 创意、模块化内容 |
| `pop-laboratory` | 蓝图网格 + 坐标标记 | 科学实验、技术指南 |
| `morandi-journal` | 莫兰迪色系手账 | 生活方式、知识笔记 |
| `retro-pop-grid` | 1970 复古波普 | 流行文化、设计趋势 |
| `hand-drawn-edu` | 马卡龙色系手绘 | 儿童教育、流程图 |

---

## 实战用法

### 推荐组合速查

| 内容类型 | 推荐布局 + 风格 |
|----------|----------------|
| 时间线/历史 | `linear-progression` + `craft-handmade` |
| 步骤教程 | `linear-progression` + `ikea-manual` |
| A vs B 对比 | `binary-comparison` + `corporate-memphis` |
| 层级结构 | `hierarchical-layers` + `craft-handmade` |
| 概念重叠 | `venn-diagram` + `craft-handmade` |
| 转化漏斗 | `funnel` + `corporate-memphis` |
| 循环流程 | `circular-flow` + `craft-handmade` |
| 技术架构 | `structural-breakdown` + `technical-schematic` |
| 关键指标 | `dashboard` + `corporate-memphis` |
| 教育内容 | `bento-grid` + `chalkboard` |
| 发展路线 | `winding-roadmap` + `storybook-watercolor` |
| 分类集合 | `periodic-table` + `bold-graphic` |
| 产品指南 | `dense-modules` + `morandi-journal` |
| 技术指南 | `dense-modules` + `pop-laboratory` |
| 趋势指南 | `dense-modules` + `retro-pop-grid` |

### Hermes Agent 内置工作流

当你在 Hermes 中请求生成信息图时，Agent 会自动执行以下步骤：

```
Step 1: 分析内容
  读取 source 内容 → 分析：主题、数据类型、复杂度、语气、受众
  保存 analysis.md

Step 2: 生成结构化内容
  标题 + 学习目标 → 分节（关键概念、内容、视觉元素）
  保存 structured-content.md

Step 3: 推荐组合
  根据数据类型 → 推荐 3-5 种布局×风格组合

Step 4: 确认选项
  询问用户选择：
  Q1: 选择组合
  Q2: 选择宽高比
  Q3: 选择语言

Step 5: 生成 Prompt
  加载选中的布局 + 风格定义 → 组装完整 prompt
  保存 prompts/infographic.md

Step 6: 生成图片
  调用 image_generate → 保存信息图
```

### 快捷关键词

| 用户输入 | 自动选择布局 | 推荐风格 |
|----------|-------------|----------|
| 高密度信息大图 / high-density-info | `dense-modules` | morandi, pop-lab, retro-pop |
| 信息图 / infographic | `bento-grid` | craft-handmade |

---

## 实操示例

### 示例 1：技术对比信息图

假设你想做一篇关于 "Transformer vs RNN" 的对比信息图：

**推荐布局**：`binary-comparison`（对比最适合）
**推荐风格**：`technical-schematic`（技术内容选蓝图风格最专业）

Agent 会：
1. 分析你的内容（Transformer vs RNN 的工作原理、优缺点）
2. 结构化：左栏 = RNN（时序处理），右栏 = Transformer（并行注意力）
3. 生成包含对比表格、性能数据、适用场景的完整 prompt
4. 调用图像生成工具输出 PNG

### 示例 2：AI 发展时间线

**推荐布局**：`linear-progression`
**推荐风格**：`cyberpunk-neon`（AI 主题用霓虹风格很出效果）

**推荐组合**：也可以考虑 `winding-roadmap` + `storybook-watercolor` 创造更叙事化的时间线

---

## 高级技巧

### 自定义宽高比

除了标准比例（16:9、9:16、1:1），还可以使用自定义宽高比：

```text
landscape  → 16:9（默认，适合屏幕展示）
portrait   → 9:16（适合手机分享）
square     → 1:1（适合社交媒体）
custom     → 任意比例如 3:4、4:3、2.35:1
```

### 多语言支持

信息图支持中英文在内的多种语言。Agent 会自动检测源语言和用户语言，当两者不一致时会询问用户确认。

### 内容保真原则

信息图生成的核心原则是**数据完整性**：
- 所有统计数据、引用、数值必须**原样保留**
- 禁止摘要、改写或修改源数据
- "73% 增长"必须保持为"73% 增长"，不能写成"显著增长"

---

## 限制与注意事项

1. **长文本限制**  — 信息图不适合大量文字，核心内容最好在 200 字以内
2. **数量限制**  — 不要在单张图里放超过 8 个主要概念
3. **风格一致性**  — 同一张图内不要混合多种风格
4. **内容敏感信息**  — Agent 会自动扫描并移除 API Key 和凭证

---

## 相关技能

- [[02-excalidraw]] — Excalidraw 手绘风格图表
- [[03-architecture-diagram]] — 深色主题 SVG 架构图
- [[04-p5js-manim]] — p5js 交互视觉 + Manim 动画
