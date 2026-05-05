---
date: 2026-05-05
tags:
  - excalidraw
  - diagram
  - hand-drawn
  - visualization
  - json
  - 创意与可视化
source_skill: excalidraw
category: 创意与可视化
---

# Excalidraw 手绘风格图表

> 本文档基于 Hermes Agent 的 `excalidraw` 技能整理，覆盖从 JSON 格式生成到 Excalidraw 图表构建的全流程实操。

## 概述

Excalidraw 是一款开源的白板工具，以其标志性的**手绘风格**（Hand-drawn style）著称。其核心优势在于：
- **JSON 格式存储** — 所有图表以 JSON 描述，适合程序化生成
- **零依赖渲染** — 纯前端，无需后端支持
- **多人协作** — 端到端加密的实时协作
- **开源 MIT 许可** — 可自由集成到任何项目

Hermes Agent 的 `excalidraw` 技能允许你通过自然语言描述，自动生成 Excalidraw 兼容的 JSON 文件，然后直接在 Excalidraw 编辑器中打开。

---

## JSON 数据结构

Excalidraw 的 JSON 文件是一个包含 `type`、`elements`、`appState` 等字段的对象：

### 顶级结构

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "https://excalidraw.com",
  "elements": [],
  "appState": {},
  "files": {}
}
```

### 核心元素类型

| 类型 | 说明 | 关键属性 |
|------|------|---------|
| `rectangle` | 矩形 | x, y, width, height, backgroundColor, strokeColor |
| `ellipse` | 椭圆/圆 | x, y, width, height, backgroundColor |
| `diamond` | 菱形 | x, y, width, height |
| `text` | 文本 | text, fontSize, fontFamily, textAlign |
| `line` | 直线/箭头 | points[]数组, strokeWidth |
| `arrow` | 箭头 | points[], endArrowhead |
| `freedraw` | 自由绘制 | pressure, points |
| `image` | 图片 | fileId, width, height |

### 通用属性

每个元素都包含以下通用属性：

```json
{
  "id": "element-id",
  "type": "rectangle",
  "x": 100,
  "y": 200,
  "width": 300,
  "height": 100,
  "angle": 0,
  "strokeColor": "#1e1e1e",
  "backgroundColor": "transparent",
  "fillStyle": "hachure",
  "strokeWidth": 1,
  "strokeStyle": "solid",
  "roughness": 1,
  "opacity": 100,
  "groupIds": [],
  "roundness": null,
  "boundElements": [],
  "updated": 1,
  "link": null,
  "locked": false
}
```

**关键视觉属性**：
- `roughness` — 手绘粗糙度（0=完美线条, 1=轻微手绘, 2=强烈手绘）
- `fillStyle` — 填充风格（hachure, cross-hatch, solid, zigzag, dotted）
- `strokeStyle` — 线条风格（solid, dashed, dotted）
- `roundness` — 圆角控制

---

## 实战用法

### 场景 1：架构图生成

通过 Hermes Agent 的 Subagent 模式生成 Excalidraw 架构图是最推荐的方式：

```
## 步骤说明

1. 阅读你的架构描述（Markdown/文本/代码）
2. 分析架构的层级关系和组件交互
3. 生成 Excalidraw JSON 文件，包含：
   - 带颜色的矩形代表各个组件
   - 箭头表示数据流和依赖关系
   - 分组框表示服务边界
   - 文本标签标注每个组件
4. 建议尺寸：单个元素至少 150×50px，间距 20-40px
5. 使用「深色主题」配色方案
```

### 场景 2：手绘流程图

```python
# Python 生成 Excalidraw JSON 示例
import json

elements = []
# 开始节点
elements.append({
    "type": "ellipse",
    "x": 300, "y": 50,
    "width": 120, "height": 60,
    "backgroundColor": "#d4f0c0",
    "strokeColor": "#1e1e1e",
    "roughness": 1,
    "fillStyle": "solid",
    "label": {"text": "开始"}
})
# 判断节点
elements.append({
    "type": "diamond",
    "x": 310, "y": 180,
    "width": 100, "height": 80,
    "backgroundColor": "#fce4ec",
    "roughness": 1,
    "fillStyle": "solid"
})
# 连接箭头
elements.append({
    "type": "arrow",
    "x": 360, "y": 110,
    "points": [[0,0],[0,70]],
    "strokeColor": "#1e1e1e",
    "roughness": 1
})

excalidraw_json = {
    "type": "excalidraw",
    "version": 2,
    "source": "https://excalidraw.com",
    "elements": elements,
    "appState": {"theme": "light"}
}
print(json.dumps(excalidraw_json, indent=2))
```

### 场景 3：从文字描述生成图表

当你在 Hermes Agent 中说"生成一个微服务架构的 Excalidraw 图表"时，Agent 会自动：

1. 分析你的架构描述，提取组件、连接关系、边界
2. 为每个组件分配合适的元素类型：
   - 微服务 → `rectangle`
   - API 网关 → `diamond` 
   - 数据库 → `ellipse`
   - 消息队列 → `rectangle`（虚线边框）
3. 使用颜色编码不同层级：
   - 网关层：蓝色系
   - 服务层：绿色系
   - 数据层：橙色系
   - 基础设施：灰色系
4. 添加文本标签和数据流箭头
5. 生成可下载的 JSON 文件

---

## 设计原则

### 配色方案

Excalidraw 默认使用有限的调色板以获得一致的手绘风格：

| 颜色 | 用途 | 示例元素 |
|------|------|---------|
| `#1e1e1e` | 默认描边 | 所有元素边框 |
| `#ffffff` | 填充（浅色主题） | 背景填充 |
| `#e8f5e9` | 绿色系填充 | 成功/活跃组件 |
| `#fce4ec` | 粉色系填充 | 警告/热点组件 |
| `#e3f2fd` | 蓝色系填充 | 信息/网关组件 |
| `#fff3e0` | 橙色系填充 | 数据/存储组件 |
| `#f3e5f5` | 紫色系填充 | 外部/第三方组件 |

### 布局最佳实践

1. **从上到下** — 流程图和架构图建议从上到下布局
2. **从左到右** — 数据流和管道图建议从左到右
3. **间距一致性** — 元素间距保持 20-40px
4. **分组边界** — 使用大的无填充矩形作为组边界
5. **文本定位** — 文本水平居中，垂直偏上 10%

---

## 与其他工具的对比

| 特性 | Excalidraw | Draw.io | Mermaid | PlantUML |
|------|-----------|---------|---------|----------|
| JSON 格式 | ✅ 原生 | ✅ 可导出 | ❌ | ❌ |
| 手绘风格 | ✅ 核心特色 | ❌ | ❌ | ❌ |
| 程序化生成 | ✅ JSON API | ✅ XML | ✅ DSL | ✅ DSL |
| 实时协作 | ✅ 端到端加密 | ❌ | ❌ | ❌ |
| 离线可用 | ✅ PWA | ✅ 桌面 | ❌ | ✅ |
| 开源许可 | ✅ MIT | ✅ Apache | ✅ MIT | ✅ GPL |

---

## 高级技巧

### 使用 Roughness 控制风格

```json
{
  "roughness": 0,  // 完美直线，类似 Draw.io
  "roughness": 1,  // 轻微手绘，默认值
  "roughness": 2   // 强烈手绘，更自然的笔触
}
```

### 生成动画关联

Excalidraw 的 JSON 也可以嵌入超链接和交互：

```json
{
  "type": "rectangle",
  "x": 100, "y": 100,
  "width": 200, "height": 100,
  "link": "https://example.com",
  "boundElements": [
    {"type": "arrow", "id": "arrow-to-next"}
  ]
}
```

### 自动布局规则

当你通过 Subagent 生成时，默认布局规则：
- 画布宽度：1200px
- 画布高度：800px
- 默认起始位置：(100, 100)
- 纵向间距：100px
- 横向间距：150px

---

## 相关技能

- [[01-baoyu-infographic]] — 信息图设计（21×21 组合）
- [[03-architecture-diagram]] — 深色主题 SVG 架构图
- [[04-p5js-manim]] — p5js 交互视觉 + Manim 动画
- [[05-ascii-art-video]] — ASCII 艺术与视频
