---
date: 2026-05-05
tags:
  - p5js
  - manim
  - animation
  - visualization
  - interactive
  - creative-coding
  - 创意与可视化
source_skill: p5js, manim-video
category: 创意与可视化
---

# p5js 交互视觉与 Manim 动画

> 本文档基于 Hermes Agent 的 `p5js` 和 `manim-video` 技能整理，覆盖交互式视觉创作和数学动画制作的全流程实操。

## 概述

本技能涵盖两大创作框架：

- **p5js** — 基于 Processing 理念的 JavaScript 创意编程库，专注于**交互式**视觉艺术
- **Manim**（Mathematical Animation Engine）— 3Blue1Brown 使用的 Python 动画引擎，专注于**数学和算法可视化**

两者的核心区别：

| 维度 | p5js | Manim |
|------|------|-------|
| 语言 | JavaScript（浏览器） | Python（CLI） |
| 输出 | HTML/Canvas（实时交互） | MP4 视频文件 |
| 交互性 | ✅ 鼠标键盘交互 | ❌ 输出为视频 |
| 数学渲染 | 基础图形 | ✅ LaTeX 排版 |
| 适用场景 | 数据可视化、艺术创作 | 数学教学、算法演示 |
| 运行环境 | 浏览器 / Node.js | Python 3.10+ |

---

## p5js — 交互式视觉创作

### 快速开始

```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.9.0/p5.min.js"></script>
  <script src="sketch.js"></script>
</head>
<body></body>
</html>
```

```javascript
// sketch.js — 基础交互示例
function setup() {
  createCanvas(800, 600);
  background(30);
}

function draw() {
  // 鼠标跟随粒子系统
  if (mouseIsPressed) {
    fill(random(100, 255), random(100, 255), random(200, 255), 180);
    noStroke();
    circle(mouseX, mouseY, random(10, 40));
  }
  
  // 网格背景
  stroke(60);
  strokeWeight(0.5);
  for (let x = 0; x < width; x += 40) {
    line(x, 0, x, height);
  }
  for (let y = 0; y < height; y += 40) {
    line(0, y, width, y);
  }
}
```

### 核心概念

#### setup() 与 draw() 循环

p5js 的核心是无限循环架构：

```javascript
let angle = 0;

function setup() {
  createCanvas(800, 600);
  frameRate(30);  // 每秒 30 帧
}

function draw() {
  background(20, 20, 30, 50);  // 半透明背景产生拖尾效果
  
  // 旋转动画
  translate(width/2, height/2);
  rotate(angle);
  fill(255, 100, 100);
  ellipse(100, 0, 50, 50);
  
  angle += 0.02;
}
```

#### 交互事件

```javascript
// 鼠标交互
function mousePressed() { /* 鼠标点击 */ }
function mouseDragged() { /* 鼠标拖拽 */ }
function mouseMoved() { /* 鼠标移动 */ }
function mouseWheel(event) { /* 滚轮 */ }

// 键盘交互
function keyPressed() {
  if (key === ' ') { /* 空格键 */ }
  if (keyCode === LEFT_ARROW) { /* 左箭头 */ }
}
```

### Hermes Agent 自动生成

当你在 Hermes 中请求生成 p5js 可视化时：

1. 分析你的视觉描述（数据/概念/交互需求）
2. 设计视觉系统 — 颜色、形状、运动模式
3. 考虑交互方式 — 鼠标跟踪、点击事件、键盘控制
4. 生成完整的 `index.html` 和 `sketch.js`
5. 提供预览方式（打开 HTML 文件或在 p5js Web Editor 中运行）

---

## Manim — 数学动画引擎

### 环境准备

```bash
# 安装 Manim
pip install manim manim-slides

# 验证安装
manim --version

# 可选：安装 LaTeX（用于公式渲染）
# Ubuntu/Debian
sudo apt-get install texlive texlive-latex-extra texlive-fonts-extra
# macOS
brew install mactex
```

### 基础动画示例

```python
# basic_scene.py
from manim import *

class BasicScene(Scene):
    def construct(self):
        # 创建圆形
        circle = Circle()
        circle.set_fill(PINK, opacity=0.5)
        
        # 创建文本
        text = Text("Hello, Manim!", font_size=48)
        text.next_to(circle, DOWN)
        
        # 播放动画
        self.play(Create(circle))
        self.play(Write(text))
        self.wait(2)
        
        # 变换动画
        square = Square()
        square.set_fill(BLUE, opacity=0.5)
        self.play(Transform(circle, square))
        self.wait(2)

# 运行：manim -pql basic_scene.py BasicScene
```

### 核心动画类型

| 动画类 | 效果 | 参数 |
|--------|------|------|
| `Create` | 绘制对象 | run_time, rate_func |
| `FadeIn` / `FadeOut` | 淡入/淡出 | scale, shift |
| `Transform` | 对象变形 | replace_mobject_with_target_in_scene |
| `Write` | 手写文本 | reverse, stroke_color |
| `GrowFromCenter` | 中心展开 | point_color |
| `Rotate` | 旋转 | angle, axis, about_point |
| `MoveAlongPath` | 沿路径运动 | path, rate_func |
| `Indicate` | 高亮闪烁 | scale_factor, color |

### LaTeX 数学公式

```python
class MathScene(Scene):
    def construct(self):
        # 欧拉公式
        euler = MathTex(
            "e^{i\\pi} + 1 = 0",
            font_size=60
        )
        self.play(Write(euler))
        self.wait()
        
        # 逐步展示公式推导
        formula = MathTex(
            "\\frac{d}{dx}", "f(x)g(x)",
            "=", "f'(x)g(x)", "+", "f(x)g'(x)"
        )
        formula[0].set_color(BLUE)
        formula[3].set_color(RED)
        formula[5].set_color(GREEN)
        self.play(Write(formula))
        self.wait()
```

### 实战：排序算法可视化

```python
from manim import *
import random

class SortVisualization(Scene):
    def construct(self):
        # 生成随机条形图
        values = [random.randint(1, 20) for _ in range(15)]
        bars = VGroup()
        
        for i, val in enumerate(values):
            bar = Rectangle(
                height=val * 0.2,
                width=0.4,
                fill_color=BLUE,
                fill_opacity=0.8,
                stroke_width=0
            )
            bar.move_to([i * 0.6 - 4, val * 0.1, 0], DOWN)
            bars.add(bar)
        
        self.play(Create(bars))
        
        # 简单冒泡排序动画
        for i in range(len(values)):
            for j in range(len(values) - i - 1):
                if values[j] > values[j + 1]:
                    values[j], values[j + 1] = values[j + 1], values[j]
                    # 交换条形位置
                    self.play(
                        bars[j].animate.move_to(bars[j+1].get_center()),
                        bars[j+1].animate.move_to(bars[j].get_center()),
                        run_time=0.3
                    )
                    bars[j], bars[j+1] = bars[j+1], bars[j]
    
    # 运行：manim -pql sort_visual.py SortVisualization
```

---

## Hermes Agent 集成工作流

### 生成 p5js 交互

```
用户输入: "为我生成一个展示分形树的 p5js 交互页面"

Agent 执行：
1. 读取分形树概念描述
2. 确定视觉方案：
   - 递归树结构
   - 角度随机偏移
   - 鼠标点击生成新树
   - 颜色根据递归深度渐变
3. 生成 index.html + sketch.js
4. 说明运行方式
```

### 生成 Manim 动画

```
用户输入: "制作一个展示傅里叶级数逼近的 Manim 动画"

Agent 执行：
1. 分析傅里叶级数的数学原理
2. 设计动画流程：
   - 显示原始方波函数
   - 逐步添加谐波项
   - 展示逼近过程
   - 标注频率和振幅
3. 生成 Python 场景代码
4. 提供渲染命令
```

---

## 高级技巧

### p5js 性能优化

```javascript
// 使用 p5.Graphics 离屏渲染
let pg;
function setup() {
  createCanvas(800, 600);
  pg = createGraphics(400, 300);
}

function draw() {
  pg.background(0);
  pg.fill(255);
  pg.circle(mouseX/2, mouseY/2, 50);
  image(pg, 0, 0);
}
```

### Manim 渲染配置

```bash
# -p: 预览      -q: 质量 (l/m/h/k)
# -f: 全屏      -s: 只最后帧
manim -pqh scene.py SceneName

# 自定义分辨率
manim -pqh --resolution 1920,1080 scene.py SceneName
```

### 组合使用

将 p5js 作为 Manim 的前端预览工具：

```python
# 在 Manim 中输出数据，用 p5js 实时预览
# 通过 JSON 或 WebSocket 通信
```

---

## 限制与注意事项

1. **Manim 版本** — 注意社区版（Community）和 3B1B 版的区别
2. **渲染时间** — 高画质渲染可能需要数小时
3. **LaTeX 依赖** — 数学公式需要安装完整的 TeX 发行版
4. **中文支持** — p5js 原生支持中文；Manim 需要配置中文字体
5. **浏览器兼容** — p5js 在 Chrome/Firefox 表现最佳

---

## 相关技能

- [[01-baoyu-infographic]] — 信息图设计
- [[02-excalidraw]] — Excalidraw 手绘风格图表
- [[03-architecture-diagram]] — 深色主题 SVG 架构图
- [[05-ascii-art-video]] — ASCII 艺术与视频
