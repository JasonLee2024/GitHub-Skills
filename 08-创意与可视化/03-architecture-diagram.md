---
date: 2026-05-05
tags:
  - architecture-diagram
  - svg
  - diagram
  - dark-theme
  - visualization
  - software-architecture
  - 创意与可视化
source_skill: architecture-diagram
category: 创意与可视化
---

# 深色主题 SVG 架构图

> 本文档基于 Hermes Agent 的 `architecture-diagram` 技能整理，涵盖从架构描述到深色 SVG 的完整生成流程。

## 概述

架构图是软件系统中不可或缺的沟通工具。Hermes Agent 的 `architecture-diagram` 技能专门针对**深色主题 SVG** 架构图设计，生成可直接嵌入博客、文档或演示文稿的高质量矢量图。

### 核心能力

- **深色主题原生支持** — 深色背景 + 合适的配色对比度
- **矢量格式输出** — SVG 格式，任意缩放不失真
- **层次化组织** — 分层分组表示系统边界
- **配色智能推荐** — 根据架构层级自动匹配颜色
- **文本标签系统** — 包含标题、组件名、描述文本

---

## 架构图结构

一个完整的架构图包含以下层级元素：

```
┌─ 系统边界（System Boundary）─────────────┐
│  ┌─ 服务边界（Service Boundary）─────┐   │
│  │  ┌─ 组件（Component）─────────┐  │   │
│  │  │  📦 名称                    │  │   │
│  │  │  🔗 描述                    │  │   │
│  │  │  ⚡ 状态/指标               │  │   │
│  │  └─────────────────────────────┘  │   │
│  │     ↕ 数据流 / 依赖关系            │   │
│  └─────────────────────────────────┘   │
│     ↕ API 调用 / 网络连接               │
└──────────────────────────────────────────┘
```

### 元素类型

| 类型 | SVG 实现 | 视觉呈现 |
|------|---------|---------|
| 系统边界 | `<rect>` + `<path>` | 大圆角矩形，半透明背景 |
| 服务边界 | `<rect>` | 圆角矩形，轻微填充 |
| 组件 | `<rect>` + `<text>` | 实色矩形，白色文字 |
| 数据流 | `<path>` + `<marker>` | 带箭头的折线或曲线 |
| 标签 | `<text>` | 标题/描述文字 |
| 图标指示 | `<circle>` + `<text>` | 小红点/状态指示灯 |

---

## 实战用法

### 场景 1：微服务架构图

通过 Hermes Agent 生成微服务架构图的工作流程：

**步骤 1：提供架构描述**

```
架构：电商系统
图层：
- 网关层：API Gateway, CDN, Load Balancer
- 服务层：用户服务, 商品服务, 订单服务, 支付服务
- 数据层：MySQL (主从), Redis, Elasticsearch
- 基础设施层：K8s Cluster, Docker, Prometheus

数据流：Client → API Gateway → 各微服务 → 数据库
```

**步骤 2：Agent 分析并生成 SVG**

Agent 会进行以下分析：
1. 识别 4 个层级（网关 → 服务 → 数据 → 基础设施）
2. 为每层分配配色（蓝 → 绿 → 橙 → 灰）
3. 计算布局位置（每层 100px 间距）
4. 推断数据流箭头方向（从上到下）
5. 添加标题和系统边界

**步骤 3：输出 SVG 文件**

生成的 SVG 以 `/tmp/architecture.svg` 保存，可直接在浏览器中打开。

### 场景 2：CI/CD 流水线图

```
流水线阶段：
1. Code Commit → 2. Lint & Test → 3. Build Image → 
4. Push Registry → 5. Deploy Staging → 6. E2E Test → 
7. Deploy Production

并行阶段：Lint + Unit Test 并行
条件分支：仅 main 分支触发 Deploy Production
```

SVG 生成结果将包含：
- 水平流水线布局（从左到右）
- 阶段矩形 + 箭头连接
- 并行分支使用分叉箭头
- 条件分支用菱形节点
- 每个阶段右上角标注状态（✅ / ⏳ / ❌）

### 场景 3：系统依赖关系图

```yaml
# 依赖关系描述
services:
  web-app:
    depends_on: [auth-service, api-gateway]
  api-gateway:
    depends_on: [user-service, order-service, payment-service]
  user-service:
    depends_on: [mysql, redis]
  order-service:
    depends_on: [mysql, rabbitmq]
  payment-service:
    depends_on: [mysql, stripe-api]
```

生成的 SVG 将以星型布局展示所有依赖关系，使用不同颜色的箭头区分不同的依赖类型。

---

## 配色方案与样式

### 标准深色主题配色

| 层级 | 背景色 | 边框色 | 文字色 |
|------|--------|--------|--------|
| 顶层（标题） | `#1a1a2e` | `#16213e` | `#ffffff` |
| 网关层 | `#0f3460` | `#1a5276` | `#e8f4f8` |
| 服务层 | `#1b4332` | `#2d6a4f` | `#d8f3dc` |
| 数据层 | `#4a3000` | `#7f5f00` | `#ffeeba` |
| 基础设施 | `#3c3c3c` | `#5c5c5c` | `#f0f0f0` |
| 外部系统 | `#4a154b` | `#6c2d6c` | `#f3e5f5` |

### 箭头样式

| 箭头类型 | 颜色 | 用途 |
|----------|------|------|
| 实线箭头 | `#76c7d5` | 同步 API 调用 |
| 虚线箭头 | `#a0d2db` | 异步消息/事件 |
| 粗箭头 | `#5ba3b5` | 主要数据流 |
| 红色箭头 | `#e74c3c` | 错误/告警流 |

---

## SVG 生成详解

### 基本 SVG 结构

```xml
<svg xmlns="http://www.w3.org/2000/svg" 
     viewBox="0 0 1200 800" 
     width="1200" height="800">
  
  <!-- 深色背景 -->
  <rect width="1200" height="800" fill="#0d1117"/>
  
  <!-- 标题 -->
  <text x="50" y="40" fill="#ffffff" 
        font-size="24" font-family="system-ui" 
        font-weight="bold">系统架构图</text>
  
  <!-- 系统边界 -->
  <rect x="30" y="60" width="1140" height="720" 
        rx="12" fill="none" stroke="#30363d" 
        stroke-width="2" stroke-dasharray="5,5"/>
  
  <!-- 组件 -->
  <g transform="translate(100, 150)">
    <rect width="200" height="80" rx="8" 
          fill="#0f3460" stroke="#1a5276" stroke-width="1.5"/>
    <text x="100" y="35" fill="#e8f4f8" 
          font-size="14" text-anchor="middle">API Gateway</text>
    <text x="100" y="55" fill="#8ab4f8" 
          font-size="11" text-anchor="middle">路由 / 限流 / 认证</text>
  </g>
  
  <!-- 箭头 -->
  <defs>
    <marker id="arrowBlue" viewBox="0 0 10 10" 
            refX="9" refY="5" markerWidth="6" 
            markerHeight="6" orient="auto">
      <path d="M0,0 L10,5 L0,10 Z" fill="#76c7d5"/>
    </marker>
  </defs>
  <line x1="200" y1="230" x2="200" y2="300" 
        stroke="#76c7d5" stroke-width="2" 
        marker-end="url(#arrowBlue)"/>
</svg>
```

### 自动布局算法

生成架构图时使用的默认布局策略：

```
水平布局（宽图 1200×800）：
  每层高度 = 120px
  层间距 = 60px
  每行组件数 = min(组件总数/层数, 4)
  组件宽度 = (画布宽度 - 边距 × 2 - 间距 × (每行数-1)) / 每行数

垂直布局（窄图 800×1200）：
  每层高度 = 150px  
  层间距 = 40px
  每行组件数 = min(组件总数/层数, 3)
```

---

## 高级技巧

### 添加鼠标悬停效果

```svg
<style>
.component:hover rect { filter: brightness(1.2); }
.component:hover text { fill: #ffffff !important; }
.tooltip { opacity: 0; }
.component:hover .tooltip { opacity: 1; }
</style>
```

### 添加微动画（用于演示模式）

```svg
<animateTransform attributeName="transform" 
  type="rotate" from="0 0 0" to="360 0 0" 
  dur="10s" repeatCount="indefinite"/>
```

### 导出其他格式

SVG 文件可以通过以下方式转换为其他格式：
```bash
# SVG → PNG (使用 Inkscape)
inkscape architecture.svg -o architecture.png -w 1920

# SVG → PDF  
rsvg-convert -f pdf -o architecture.pdf architecture.svg

# 直接在浏览器打开
open architecture.svg
```

---

## 限制与注意事项

1. **字体支持** — SVG 文本使用系统字体，在不同平台上可能渲染不同
2. **复杂嵌套** — 超过 100 个元素的大型图表建议拆分为多个子图
3. **颜色数量** — 同一张图使用不超过 8 种颜色以保持可读性
4. **文字长度** — 组件标签建议不超过 20 个字符
5. **文件大小** — 复杂 SVG 建议压缩（svgo 等工具）

---

## 相关技能

- [[01-baoyu-infographic]] — 信息图设计（21×21 组合）
- [[02-excalidraw]] — Excalidraw 手绘风格图表
- [[04-p5js-manim]] — p5js 交互视觉 + Manim 动画
- [[05-ascii-art-video]] — ASCII 艺术与视频
