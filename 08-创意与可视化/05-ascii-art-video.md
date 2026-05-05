---
date: 2026-05-05
tags:
  - ascii-art
  - ascii-video
  - pyfiglet
  - cowsay
  - terminal-art
  - 创意与可视化
source_skill: ascii-art, ascii-video
category: 创意与可视化
---

# ASCII 艺术与视频

> 本文档基于 Hermes Agent 的 `ascii-art` 和 `ascii-video` 技能整理，覆盖从静态 ASCII 艺术到全动态 ASCII 视频的制作流程。

## 概述

ASCII 艺术是最古老的计算艺术形式之一——用文字字符在终端中绘制图像。Hermes Agent 提供了从基础到高级的完整 ASCII 创作管线：

- **`ascii-art`** 技能 — 使用 pyfiglet（571 种字体）、cowsay、box 等工具快速生成静态 ASCII 艺术
- **`ascii-video`** 技能 — 将任何视频格式转换为 ASCII 动画（含音频同步）

---

## 静态 ASCII 艺术（ascii-art）

### 环境安装

```bash
# Python 工具链
pip install pyfiglet pycowsay

# 系统工具（Ubuntu/Debian/WSL）
sudo apt-get install cowsay cowthink boxes figlet toilet
```

### pyfiglet — 571 种字体

pyfiglet 是 Python 版本的 FIGlet 工具，支持 571 种字体：

```python
from pyfiglet import Figlet

# 列出所有字体
f = Figlet()
all_fonts = f.getFonts()
print(f"可用字体数: {len(all_fonts)}")
print(all_fonts[:10])  # 前 10 种

# 基本用法
f = Figlet(font='slant')
ascii_art = f.renderText('Hello World')
print(ascii_art)

# 不同字体对比
fonts_to_try = ['slant', 'big', 'banner', 'starwars', 'ogre',
                'ghost', 'bubble', 'digital', 'chunky', 'cosmic']
for font in fonts_to_try:
    f = Figlet(font=font)
    print(f"=== {font} ===")
    print(f.renderText('Dev'))
    print()
```

### 常用字体速查

针对不同场景推荐字体：

| 场景 | 推荐字体 | 风格描述 |
|------|---------|---------|
| 标题展示 | `slant`, `banner` | 经典斜体，高辨识度 |
| 代码注释 | `chunky`, `big` | 粗体大字号，易读 |
| 星战风格 | `starwars` | 电影 3D 风格 |
| 复古游戏 | `digital`, `cosmic` | 像素/数字感 |
| 怪异风格 | `ogre`, `ghost` | 有趣，适合 Halloween |
| 气泡风格 | `bubble`, `bubble3d` | 圆润可爱 |
| 最小主义 | `mini`, `small` | 窄幅节省空间 |
| 中国风 | `chinese` | 汉字排版（有限支持） |

### cowsay — 动物对话

```bash
# 基本用法
cowsay "Hello, Developer!"

# 列出所有角色
cowsay -l

# 使用不同角色
cowsay -f dragon "Git push --force"
cowsay -f tux "Linux 最棒"
cowthink -f stegosaurus "思考中..."

# 自定义眼睛
cowsay -e xx "震惊！"
cowsay -T U "吐舌头"

# 管道组合
echo "代码写完了" | cowsay -f daemon
figlet "DONE" | cowsay -n -f dragon
```

### boxes — 边框装饰

```bash
# 基本边框
echo "注意安全" | boxes

# 列出所有设计
boxes -l

# 不同风格
echo "代码审查" | boxes -d stone
echo "重要通知" | boxes -d warning
echo "完成!" | boxes -d whirly

# 自定义宽度
echo "长文本需要宽框" | boxes -d c -s 60
```

### 实战：终端信息面板

```python
# info_panel.py
from pyfiglet import Figlet
import subprocess, datetime

def create_panel():
    # 标题
    f = Figlet(font='slant')
    title = f.renderText('Dev Panel')
    
    # 系统信息
    hostname = subprocess.getoutput('hostname')
    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # 组合输出
    print("\033[36m" + title + "\033[0m")  # 青色
    print(f"\033[33m{'='*60}\033[0m")
    print(f"  🖥️  主机: {hostname}")
    print(f"  🕐  时间: {now}")
    print(f"  📂  路径: /home/dev/project")
    print(f"\033[33m{'='*60}\033[0m")

if __name__ == '__main__':
    create_panel()
```

---

## ASCII 视频管线（ascii-video）

### 管线架构

```
输入视频 → 帧提取 → 灰度映射 → 字符映射 → 音频提取 → 
  → 帧组合 → ASCII 视频输出（可带音频同步）
```

### 核心原理

每个像素的亮度值映射到一个 ASCII 字符：

```python
# 标准灰度到字符映射（从暗到亮）
ASCII_CHARS = '@%#*+=-:. '

def pixel_to_ascii(brightness):
    """将像素亮度(0-255)映射到ASCII字符"""
    idx = int(brightness / 255 * (len(ASCII_CHARS) - 1))
    return ASCII_CHARS[idx]

# 更精细的映射
ASCII_CHARS_DETAILED = '$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,"^`\'. '
```

### 完整转换脚本

```python
# video_to_ascii.py
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import subprocess, os, tempfile

# 字符调色板（从暗到亮）
CHARS = '@%#*+=-:. '

def frame_to_ascii(frame, new_width=120):
    """将视频帧转换为ASCII艺术帧"""
    # 转换为灰度
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # 计算字符尺寸
    height, width = gray.shape
    char_aspect = 0.55  # 字符宽高比校正
    new_height = int(new_width * (height / width) * char_aspect)
    
    # 缩放到字符网格
    resized = cv2.resize(gray, (new_width, new_height))
    
    # 映射到ASCII
    ascii_str = ''
    for row in resized:
        for pixel in row:
            ascii_str += CHARS[int(pixel / 255 * (len(CHARS) - 1))]
        ascii_str += '\n'
    
    return ascii_str

def video_to_ascii_video(input_path, output_path, width=120, fps=15):
    """将视频转换为ASCII视频文件"""
    cap = cv2.VideoCapture(input_path)
    original_fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    frame_count = 0
    ascii_frames = []
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        if frame_count % int(original_fps / fps) == 0:
            ascii_art = frame_to_ascii(frame, width)
            ascii_frames.append(ascii_art)
            
            # 进度
            progress = int(frame_count / total_frames * 50)
            bar = '█' * progress + '░' * (50 - progress)
            print(f'\r[{bar}] {frame_count}/{total_frames}', end='')
        
        frame_count += 1
    
    cap.release()
    
    # 保存为文本帧序列
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(f'FPS:{fps}\n')
        f.write(f'FRAMES:{len(ascii_frames)}\n')
        f.write('---ASCII VIDEO START---\n')
        for i, frame in enumerate(ascii_frames):
            f.write(f'===FRAME {i}===\n')
            f.write(frame)
            f.write('===FRAME END===\n')
    
    print(f'\n✅ 完成! 生成 {len(ascii_frames)} 帧')
    return ascii_frames
```

### 使用方法

```bash
# 转换视频为ASCII
python video_to_ascii.py input.mp4 output.txt

# 终端播放ASCII视频
python play_ascii.py output.txt

# 实时摄像头ASCII（有趣效果）
python cam_ascii.py
```

### 实时摄像头 ASCII

```python
# cam_ascii.py — 实时网络摄像头转ASCII
import cv2

CHARS = '@%#*+=-:. '

def main():
    cap = cv2.VideoCapture(0)  # 0 = 默认摄像头
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        # 缩小帧
        small = cv2.resize(frame, (80, 40))
        gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
        
        # 清屏 + 输出ASCII
        print('\033[2J\033[H', end='')  # ANSI 清屏
        for row in gray:
            line = ''
            for pixel in row:
                line += CHARS[int(pixel / 255 * (len(CHARS) - 1))]
            print(line)
        
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    cap.release()

if __name__ == '__main__':
    main()
```

---

## 高级技巧

### 彩色 ASCII 艺术（ANSI 转义码）

```python
def frame_to_color_ascii(frame, new_width=80):
    """保留颜色的ASCII艺术"""
    chars = '@%#*+=-:. '
    small = cv2.resize(frame, (new_width, int(new_width * 0.4)))
    height, width, _ = small.shape
    
    result = ''
    for y in range(height):
        for x in range(width):
            b, g, r = small[y, x]
            gray = 0.299 * r + 0.587 * g + 0.114 * b
            char_idx = int(gray / 255 * (len(chars) - 1))
            # ANSI 前景色转义
            result += f'\033[38;2;{r};{g};{b}m{chars[char_idx]}\033[0m'
        result += '\n'
    return result
```

### 文本视频优化

```bash
# 调整帧率（终端播放性能）
FPS=15  # 大多数终端流畅播放的上限

# 调整宽度（终端列数）
WIDTH=100  # 标准终端宽度

# 使用字符块代替单字符（Unicode 块元素）
# █ ▓ ▒ ░ ▄ ▀ ▌ ▐
BLOCK_CHARS = '█▓▒░ '
```

---

## 工具对比

| 工具 | 类型 | 字体/模板数 | 输出格式 | 运行方式 |
|------|------|------------|---------|---------|
| pyfiglet | Python | 571 | 文本 | pip install |
| figlet | CLI | 标准集 | 文本 | apt install |
| cowsay | CLI | ~70 角色 | 对话气泡 | apt install |
| boxes | CLI | ~80 边框 | 装饰框 | apt install |
| toilet | CLI | 标准集 | 彩色文本 | apt install |
| ascii-video | Python | — | 视频文本 | 自定义脚本 |

---

## 相关技能

- [[01-baoyu-infographic]] — 信息图设计
- [[02-excalidraw]] — 手绘风格图表
- [[03-architecture-diagram]] — 架构图设计
- [[04-p5js-manim]] — 交互式视觉与动画
