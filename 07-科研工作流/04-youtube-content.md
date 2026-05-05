---
date: 2026-05-05
tags:
  - youtube
  - transcript
  - content-extraction
  - video-summary
  - subtitle
  - 科研工作流
source_skill: youtube-content
category: 科研工作流
---

# YouTube 字幕获取与内容结构化

> 本文档基于 Hermes Agent 的 `youtube-content` 技能整理，覆盖从 YouTube 视频字幕获取到内容结构化输出的全流程实操。

## 概述

学术研究不只停留在论文里——许多前沿观点、技术演示和行业洞察首先出现在 YouTube 视频中。无论是技术大会的演讲录像（NeurIPS、ICML、CVPR）、AI 大佬的个人分享，还是开源项目的使用教程，视频都是极其重要的信息源。

`youtube-transcript-api` 是一个 Python 库，可以从任何 YouTube 视频中提取字幕/CC 文本，无需 API Key、无需 OAuth 认证。配合 Hermes Agent 的自动化能力，可以将视频内容转化为多种结构化格式。

本文将介绍：

1. **字幕获取** — 从 YouTube URL 提取字幕文本
2. **内容结构化** — 生成摘要、章节、博客文章等
3. **批量处理** — 播放列表和频道自动化
4. **多语言支持** — 翻译和跨语言处理

---

## 环境准备

### 安装依赖

```bash
# 核心库
pip install youtube-transcript-api
```

### Helper 脚本

Hermes Agent 内置了 `youtube-content` 技能的 helper 脚本，可以直接调用：

```bash
# 使用 Hermes 内置脚本
# $SKILL_DIR 是技能目录路径
python3 $SKILL_DIR/scripts/fetch_transcript.py "https://youtube.com/watch?v=VIDEO_ID"

# 纯文本输出
python3 $SKILL_DIR/scripts/fetch_transcript.py "URL" --text-only

# 带时间戳
python3 $SKILL_DIR/scripts/fetch_transcript.py "URL" --timestamps

# 指定语言
python3 $SKILL_DIR/scripts/fetch_transcript.py "URL" --language zh,en
```

### 支持的 URL 格式

本脚本支持所有常见 YouTube URL 格式：

- 标准链接: `https://youtube.com/watch?v=VIDEO_ID`
- 短链接: `https://youtu.be/VIDEO_ID`
- 嵌入链接: `https://www.youtube.com/embed/VIDEO_ID`
- 短视频: `https://youtube.com/shorts/VIDEO_ID`
- 直播链接: `https://www.youtube.com/watch?v=VIDEO_ID`
- 原始视频 ID: 直接传入 11 位字符

---

## 核心功能

### 1. 获取字幕

使用 Python API 直接获取字幕：

```python
from youtube_transcript_api import YouTubeTranscriptApi

# 获取字幕列表（查看有哪些语言可用）
transcript_list = YouTubeTranscriptApi.list_transcripts("VIDEO_ID")

for transcript in transcript_list:
    print(f"语言: {transcript.language} ({transcript.language_code})")
    print(f"自动生成: {transcript.is_generated}")
    print(f"可翻译: {transcript.is_translatable}")
    print("---")

# 获取指定语言的字幕
transcript = YouTubeTranscriptApi.get_transcript("VIDEO_ID", languages=['zh-Hans', 'en'])

# 遍历字幕条目
for entry in transcript:
    print(f"[{entry['start']:.1f}s] {entry['text']}")
    # entry 结构: {'text': '...', 'start': 12.5, 'duration': 3.0}
```

### 2. 语言回退策略

视频可能没有你首选语言的字幕。推荐的回退策略：

```python
def get_best_transcript(video_id, preferred_languages=['zh-Hans', 'en']):
    """获取最佳可用字幕，按优先级回退"""
    try:
        transcript = YouTubeTranscriptApi.get_transcript(
            video_id,
            languages=preferred_languages
        )
        return transcript
    except Exception as e:
        print(f"首选语言不可用: {e}")
        # 回退：获取任何可用的字幕
        try:
            transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
            # 优先选择手动字幕，其次自动生成
            for t in transcript_list:
                if not t.is_generated:
                    return t.fetch()
            # 最后选择自动生成的字幕
            return transcript_list.find_generated_transcript(['en']).fetch()
        except Exception as e2:
            print(f"无可用于幕: {e2}")
            return None
```

### 3. 翻译字幕

YouTube 自动翻译功能允许将字幕翻译成其他语言：

```python
# 将英文字幕翻译成中文
transcript_list = YouTubeTranscriptApi.list_transcripts("VIDEO_ID")
transcript = transcript_list.find_transcript(['en'])

# 翻译成中文
translated = transcript.translate('zh-Hans')
translated_entries = translated.fetch()

for entry in translated_entries:
    print(f"[{entry['start']:.1f}s] {entry['text']}")
```

### 4. 获取视频元数据

配合 yt-dlp 可以获取丰富的视频信息：

```bash
# 安装
pip install yt-dlp

# 获取元数据（JSON 格式）
yt-dlp --print-json "https://youtube.com/watch?v=VIDEO_ID" | python3 -m json.tool

# 提取关键信息
yt-dlp --print title "URL"
yt-dlp --print description "URL"
yt-dlp --print duration "URL"
yt-dlp --print channel "URL"
```

```python
import yt_dlp

def get_video_info(url):
    """获取视频元数据"""
    ydl_opts = {'quiet': True}
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        return {
            'title': info.get('title'),
            'duration': info.get('duration'),
            'channel': info.get('channel'),
            'upload_date': info.get('upload_date'),
            'description': info.get('description'),
            'view_count': info.get('view_count'),
            'tags': info.get('tags', []),
        }
```

---

## 内容结构化

获取字幕文本后，可以将其转化为多种结构化格式。这是 Hermes Agent 的核心增值能力。

### 1. 时间戳章节

根据内容主题切换点，自动生成带时间戳的章节列表：

```text
00:00 引言 — 主持人开场，介绍本期主题和嘉宾背景
03:45 背景介绍 — 现有方法的局限性和改进动机
12:20 核心方法 — 论文提出方法的技术细节详解
24:10 实验结果 — 在多个基准数据集上的对比分析
31:55 Q&A 环节 — 观众提问关于可扩展性和后续工作
```

### 2. 内容摘要

生成 5-10 句的简洁摘要，包含视频核心观点和结论：

```python
def generate_summary(transcript_entries, max_sentences=10):
    """将字幕文本转化为结构化摘要"""
    full_text = " ".join([e['text'] for e in transcript_entries])
    # 分段处理：超过 50K 字符需要分块
    chunks = chunk_text(full_text, max_chars=40000)
    
    summaries = []
    for i, chunk in enumerate(chunks):
        # 每块独立摘要（可用 LLM 处理）
        chunk_summary = summarize_chunk(chunk)
        summaries.append(chunk_summary)
    
    return merge_summaries(summaries)
```

### 3. 博客文章格式

将视频内容重写为完整的博客文章：

```text
# 标题：从视频提取的核心主题

## 引言
视频开场提出的问题和背景...

## 关键概念
视频中介绍的核心技术/方法论...

## 详细解析
逐步拆解视频的中段技术内容...

## 结论与展望
视频结尾总结的观点和未来方向...

## 原始视频
[视频标题](https://youtube.com/watch?v=VIDEO_ID)
```

### 4. 讨论帖/Thread 格式

适合在 Twitter/X 或论坛分享的轻量格式：

```text
1/8 今天看了一个关于 XXX 的精彩演讲，核心观点让我醍醐灌顶 🧵

2/8 作者指出当前方法最大的问题是... 这和我们团队之前遇到的瓶颈完全一致

3/8 解决方案分为三步：第一步是...

4/8 第二步引入了 XX 机制，解决了长期以来困扰该领域的 YY 问题

...
```

### 5. 精华语录

提取视频中的金句和关键引用：

```text
"我们花了三年时间才意识到，问题不在于模型不够大，而在于数据质量不够好"
  — 00:12:35

"如果你只能记住一件事，那就是：永远不要用测试集做验证"
  — 00:28:10
```

---

## 批量处理与自动化

### 播放列表处理

```python
import yt_dlp

def get_playlist_videos(playlist_url):
    """获取播放列表中所有视频的 URL"""
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(playlist_url, download=False)
        entries = info.get('entries', [])
        return [
            f"https://youtube.com/watch?v={e['id']}"
            for e in entries if e
        ]

# 使用示例
videos = get_playlist_videos("https://youtube.com/playlist?list=PL...")
for url in videos:
    process_video(url)  # 逐个处理
```

### 频道订阅监控

```bash
#!/bin/bash
# 每天运行：检查频道最新视频并提取字幕

CHANNEL_URL="https://youtube.com/@ChannelName"
OUTPUT_DIR="./youtube_transcripts"

# 获取最新视频列表
yt-dlp --flat-playlist --print-to-file url "$OUTPUT_DIR/urls.txt" "$CHANNEL_URL"

# 处理每个视频
while read url; do
    python3 fetch_transcript.py "$url" --timestamps > "$OUTPUT_DIR/$(date +%Y%m%d)-transcript.txt"
done < "$OUTPUT_DIR/urls.txt"
```

---

## 高级技巧

### 长视频分段处理

超过 1 小时的视频，字幕文本可能超过 50K 字符。需要分块处理：

```python
def chunk_text(text, max_chars=40000, overlap=2000):
    """将长文本分割为重叠块"""
    chunks = []
    start = 0
    while start < len(text):
        end = min(start + max_chars, len(text))
        if end < len(text):
            # 在段落边界处分割
            end = text.rfind('\n', start, end) + 1 or end
        chunk = text[start:end]
        chunks.append(chunk)
        start = end - overlap
    return chunks

def process_long_video(video_id):
    """处理长视频：分块 -> 逐块摘要 -> 合并"""
    transcript = YouTubeTranscriptApi.get_transcript(video_id, languages=['en'])
    full_text = format_with_timestamps(transcript)
    
    chunks = chunk_text(full_text)
    chunk_summaries = [summarize_chunk(c) for c in chunks]
    
    # 合并并生成最终结构
    final_content = merge_chapters(chunk_summaries, transcript)
    return final_content
```

### 时间轴对齐

将字幕时间戳与视频关键帧对齐，生成类似"图文稿"的输出：

```python
def format_with_timestamps(transcript, time_interval=30):
    """按时间间隔分组字幕，生成结构化输出"""
    current_interval = 0
    output = []
    group = []
    
    for entry in transcript:
        start_sec = entry['start']
        interval = int(start_sec // time_interval) * time_interval
        
        if interval > current_interval:
            if group:
                timestamp = format_time(current_interval)
                text = ' '.join(group)
                output.append(f"[{timestamp}] {text}")
                group = []
            current_interval = interval
        
        group.append(entry['text'])
    
    # 处理最后一组
    if group:
        timestamp = format_time(current_interval)
        output.append(f"[{timestamp}] {' '.join(group)}")
    
    return '\n\n'.join(output)

def format_time(seconds):
    """将秒数格式化为 HH:MM:SS"""
    h = seconds // 3600
    m = (seconds % 3600) // 60
    s = seconds % 60
    if h > 0:
        return f"{h:02d}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"
```

### 字幕到 Anki 闪卡

将视频中的知识点自动转化为 Anki 笔记格式：

```python
def transcript_to_anki(transcript, video_title):
    """从字幕生成 Anki 可导入的 CSV"""
    cards = []
    for i, entry in enumerate(transcript):
        text = entry['text'].strip()
        if not text or len(text) < 20:
            continue
        
        # 提问：视频中提到的一个概念
        question = f"在视频「{video_title}」中，{text[:50]}..."
        answer = f"{text}\n\n来源: {video_title} @ {format_time(entry['start'])}"
        
        cards.append(f'"{question}","{answer}"')
    
    # 输出为 CSV
    return '\n'.join(cards)
```

---

## 工作流最佳实践

### 推荐流程

```
收到 YouTube 链接
  ↓
获取字幕（首选语言 → 自动回退）
  ↓
检查字幕长度
  ├── < 50K 字符 → 直接处理
  └── ≥ 50K 字符 → 分块处理
  ↓
选择输出格式
  ├── 快速浏览 → 摘要
  ├── 知识沉淀 → 博客文章 + 语录
  ├── 社交分享 → Thread 格式
  └── 学习复习 → Anki 闪卡
  ↓
输出结构化内容并保存
```

### 错误处理

- **字幕禁用的视频**：视频所有者可能禁用了字幕，通知用户检查视频页面
- **私有/已删除视频**：返回错误信息，请用户验证链接
- **语言不匹配**：自动回退到任何可用语言，并标注实际语言
- **依赖缺失**：运行 `pip install youtube-transcript-api yt-dlp` 后重试

### 与科研工作流集成

```
arXiv 论文搜索 → 发现相关论文
  ↓
YouTube 技术演讲 → 获取论文作者讲解
  ↓
提取字幕 → 生成结构化笔记
  ↓
存入 LLM Wiki 知识库
  ↓
引用管理 → 纳入文献综述
```

---

## 实用命令速查

```bash
# 单条字幕获取
python3 fetch_transcript.py "https://youtube.com/watch?v=VIDEO_ID" --timestamps

# 纯文本输出（适合管道处理）
python3 fetch_transcript.py "URL" --text-only

# 中文优先，英文回退
python3 fetch_transcript.py "URL" --language zh-Hans,en

# 获取视频元数据
yt-dlp --print-json "URL" | python3 -m json.tool

# 批量处理播放列表
yt-dlp --flat-playlist --print url "https://youtube.com/playlist?list=PL..." | xargs -I{} python3 fetch_transcript.py {} --timestamps

# 查看所有可用字幕语言
python3 -c "from youtube_transcript_api import YouTubeTranscriptApi; [print(f'{t.language_code}: {t.language}{\" (auto)\" if t.is_generated else \"\"}') for t in YouTubeTranscriptApi.list_transcripts('VIDEO_ID')]"
```
