---
date: 2026-05-05
tags:
  - blogwatcher
  - rss
  - feed-reader
  - monitoring
  - blogs
  - 科研工作流
source_skill: blogwatcher
category: 科研工作流
---

# 博客与 RSS 监控

> 本文档基于 Hermes Agent 的 `blogwatcher` 技能整理，覆盖从 RSS 订阅添加到每日博客监控的全流程。

## 概述

学术研究不能只靠 arXiv——许多重要的学术观点、技术解析和行业动态首先出现在个人博客和技术博客中。比如 Andrej Karpathy 的博客、Lil'Log（李沐）、Stochastic Blog 等，都是 AI 领域的高质量信息来源。

RSS（Really Simple Syndication）是最古老也最高效的博客跟踪协议。它不需要算法推荐，不会制造信息茧房，你想要看什么就订阅什么。

`blogwatcher-cli` 是一个终端 RSS/Atom 阅读器，支持：

- 自动发现博客的 RSS/Atom Feed
- 支持 HTML 页面抓取作为后备方案
- 跟踪已读/未读状态
- 按分类筛选文章
- OPML 导入/导出（方便迁移）
- SQLite 数据库存储，轻量高效

---

## 安装 blogwatcher-cli

### 方法一：Go 安装（推荐）

```bash
# 需要 Go 1.21+
go install github.com/JulienTant/blogwatcher-cli/cmd/blogwatcher-cli@latest
```

### 方法二：直接下载二进制

```bash
# Linux amd64
curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_linux_amd64.tar.gz | \
  tar xz -C /usr/local/bin blogwatcher-cli

# macOS Apple Silicon
curl -sL https://github.com/JulienTant/blogwatcher-cli/releases/latest/download/blogwatcher-cli_darwin_arm64.tar.gz | \
  tar xz -C /usr/local/bin blogwatcher-cli
```

### 方法三：Docker 使用

```bash
docker run --rm -v blogwatcher-data:/data \
  -e BLOGWATCHER_DB=/data/blogwatcher-cli.db \
  ghcr.io/julientant/blogwatcher-cli scan
```

### 验证安装

```bash
blogwatcher-cli --version  # 确认安装成功
blogwatcher-cli --help     # 查看所有命令
```

---

## 基础使用

### 添加博客

```bash
# 最简单的添加方式——blogwatcher 会自动发现 RSS Feed
blogwatcher-cli add "Lil'Log" https://lilianweng.github.io/

# 明确指定 Feed URL（跳过自动发现）
blogwatcher-cli add "Karpathy" https://karpathy.github.io/ --feed-url https://karpathy.github.io/feed.xml

# 如果 RSS 不可用，用 HTML 抓取作为后备
blogwatcher-cli add "Stochastic Blog" https://www.stochasticlif.com/ --scrape-selector "article h2 a"
```

### 查看已添加的博客

```bash
blogwatcher-cli blogs
```

输出示例：

```
Tracked blogs (3):

  Lil'Log
    URL: https://lilianweng.github.io/
    Feed: https://lilianweng.github.io/atom.xml
    Last scanned: 2026-05-05 08:30

  Karpathy
    URL: https://karpathy.github.io/
    Feed: https://karpathy.github.io/feed.xml
    Last scanned: 2026-05-05 08:30

  Stochastic Blog
    URL: https://www.stochasticlif.com/
    Scraper selector: article h2 a
    Last scanned: 2026-05-05 08:30
```

### 扫描最新文章

```bash
# 扫描所有博客
blogwatcher-cli scan

# 只扫描某个博客
blogwatcher-cli scan "Lil'Log"

# 静默模式（只输出汇总结果）
BLOGWATCHER_SILENT=1 blogwatcher-cli scan
```

输出示例：

```
Scanning 3 blog(s)...

  Lil'Log
    Source: RSS | Found: 5 | New: 2

  Karpathy
    Source: RSS | Found: 3 | New: 0

  Stochastic Blog
    Source: Scraper | Found: 8 | New: 3

Found 5 new article(s) total!
```

### 查看文章列表

```bash
# 只看未读文章
blogwatcher-cli articles

# 看所有文章
blogwatcher-cli articles --all

# 按博客过滤
blogwatcher-cli articles --blog "Lil'Log"

# 按分类过滤（如果 Feed 提供了分类信息）
blogwatcher-cli articles --category "Deep Learning"

# 限制数量
blogwatcher-cli articles --all --limit 20
```

输出示例：

```
Unread articles (5):

  [1] [new] LLM Powered Autonomous Agents
       Blog: Lil'Log
       URL: https://lilianweng.github.io/posts/2023-06-23-agent/
       Published: 2023-06-23
       Categories: AI, Agents, NLP

  [2] [new] Contrastive Representation Learning
       Blog: Lil'Log
       URL: https://lilianweng.github.io/posts/2021-12-15-contrastive/
       Published: 2021-12-15
       Categories: Deep Learning, Representation Learning

  [3] [new] Transformer Circuits Thread
       Blog: Stochastic Blog
       URL: https://www.stochasticlif.com/transformer-circuits/
       Published: 2026-05-04
       Categories: Mechanistic Interpretability
```

### 标记已读

```bash
# 标记特定文章为已读
blogwatcher-cli read 1     # 标记 #1 文章为已读
blogwatcher-cli read 1 2 3 # 批量标记

# 全部标记为已读
blogwatcher-cli read-all

# 某个博客的全部标记为已读
blogwatcher-cli read-all --blog "Lil'Log" --yes

# 撤销已读标记
blogwatcher-cli unread 1
```

---

## 高级用法

### OPML 导入/导出

OPML 是 RSS 订阅列表的标准交换格式。如果你从 Feedly、Inoreader、NewsBlur 或其他阅读器迁移过来：

```bash
# 导出当前订阅（所有博客）
blogwatcher-cli export subscriptions.opml

# 从 OPML 文件导入
blogwatcher-cli import subscriptions.opml
```

导出文件示例（`subscriptions.opml`）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>Blog Subscriptions</title>
  </head>
  <body>
    <outline text="AI Research" title="AI Research">
      <outline type="rss" text="Lil'Log" title="Lil'Log"
               xmlUrl="https://lilianweng.github.io/atom.xml"
               htmlUrl="https://lilianweng.github.io/"/>
      <outline type="rss" text="Karpathy" title="Karpathy"
               xmlUrl="https://karpathy.github.io/feed.xml"
               htmlUrl="https://karpathy.github.io/"/>
    </outline>
  </body>
</opml>
```

### 推荐的 AI/ML 博客列表

以下是一些高质量的中英文 AI/ML 博客推荐，可以批量添加：

```bash
cat << 'EOF' | while IFS='|' read name url feed; do
  blogwatcher-cli add "$name" "$url" --feed-url "$feed"
done

# Lil'Log（李沐的博客——必读）
Lil'Log|https://lilianweng.github.io/|https://lilianweng.github.io/atom.xml

# Karpathy 博客
Andrej Karpathy|https://karpathy.github.io/|https://karpathy.github.io/feed.xml

# Sebastian Ruder
Sebastian Ruder|https://ruder.io/|https://ruder.io/rss/index.xml

# Google AI Blog
Google AI|https://ai.googleblog.com/|https://ai.googleblog.com/feeds/posts/default

# OpenAI Blog
OpenAI|https://openai.com/blog|https://openai.com/blog/feed.xml

# DeepMind Blog
DeepMind|https://deepmind.google/discover/blog/|https://deepmind.google/discover/blog/feed.xml

# Meta AI
Meta AI|https://ai.meta.com/blog/|https://ai.meta.com/blog/feed.xml

# Anthropic
Anthropic|https://www.anthropic.com/feed.xml|https://www.anthropic.com/feed.xml

# Simon Willison（Python / LLM 实践）
Simon Willison|https://simonwillison.net/|https://simonwillison.net/atom/everything/

# Jay Alammar（可视化 ML 教程）
Jay Alammar|https://jalammar.github.io/|https://jalammar.github.io/feed.xml

# Chris Olah（可解释性研究）
Chris Olah|https://colah.github.io/|https://colah.github.io/feed.xml

# Distill（交互式文章平台）
Distill|https://distill.pub/|https://distill.pub/rss.xml

# Eugene Yan（推荐系统 / LLM 应用）
Eugene Yan|https://eugeneyan.com/|https://eugeneyan.com/feed.xml

# Chip Huyen（ML 工程实践）
Chip Huyen|https://huyenchip.com/|https://huyenchip.com/feed.xml
EOF
```

### 中文 AI 博客推荐

```bash
cat << 'EOF' | while IFS='|' read name url feed; do
  blogwatcher-cli add "$name" "$url" --feed-url "$feed"
done

# 机器之心
机器之心|https://www.jiqizhixin.com/|https://www.jiqizhixin.com/rss

# 量子位
量子位|https://www.qbitai.com/|https://www.qbitai.com/feed

# PaperWeekly
PaperWeekly|https://www.paperweekly.site/|https://www.paperweekly.site/feed

# 知乎日报（AI 相关）
知乎 AI|https://www.zhihu.com/topic/19559484|https://www.zhihu.com/rss
EOF
```

注意：中文网站的 RSS Feed 支持程度不一，部分网站可能已停止提供 RSS。

### 配置并发扫描

`blogwatcher-cli` 支持并发扫描，提高扫描速度：

```bash
# 使用 16 个并发工作线程（默认是 8）
BLOGWATCHER_WORKERS=16 blogwatcher-cli scan
```

### 使用自定义数据库路径

```bash
# 默认数据库在 ~/.blogwatcher-cli/blogwatcher-cli.db
# 如果你想把数据放在特定位置：
blogwatcher-cli scan --db /path/to/custom/blogwatcher.db

# 或者通过环境变量
export BLOGWATCHER_DB=/mnt/d/skywalker/blogwatcher.db
blogwatcher-cli articles
```

### 删除博客

```bash
# 删除一个博客（会提示确认）
blogwatcher-cli remove "Lil'Log"

# 跳过确认直接删除
blogwatcher-cli remove "Lil'Log" --yes

# 删除博客及其所有文章记录
blogwatcher-cli remove "Lil'Log" --remove-articles --yes
```

---

## 自动化监控

### 每日自动扫描脚本

将博客监控做成每日定时任务：

```python
#!/usr/bin/env python3
"""
daily_blog_monitor.py — 每日博客监控脚本

功能：
1. 扫描所有订阅博客的新文章
2. 提取未读文章列表
3. 输出日报（可配合 cron 使用）
"""

import subprocess
import json
import re
from datetime import datetime

def scan_blogs():
    """运行 blogwatcher-cli 扫描"""
    result = subprocess.run(
        ["blogwatcher-cli", "scan"],
        capture_output=True, text=True, timeout=120
    )
    return result.stdout + result.stderr

def get_unread_articles():
    """获取未读文章列表"""
    result = subprocess.run(
        ["blogwatcher-cli", "articles"],
        capture_output=True, text=True, timeout=30
    )
    return result.stdout

def get_all_blogs():
    """获取所有订阅的博客"""
    result = subprocess.run(
        ["blogwatcher-cli", "blogs"],
        capture_output=True, text=True, timeout=15
    )
    return result.stdout

def generate_daily_report():
    """生成日报"""
    print("=" * 60)
    print(f"📡 博客监控日报 | {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print("=" * 60)
    print()

    # 列出所有博客
    blogs = get_all_blogs()
    print("📋 当前订阅:")
    print(blogs)
    print()

    # 扫描新文章
    print("🔍 正在扫描新文章...")
    scan_result = scan_blogs()
    print(scan_result)
    print()

    # 获取未读文章
    print("📖 未读文章:")
    unread = get_unread_articles()
    if "No unread articles" in unread:
        print("  暂无未读文章 🎉")
    else:
        print(unread)

    # 统计数据
    new_count = len(re.findall(r'\[new\]', scan_result))
    print(f"\n📊 统计: {new_count} 篇新文章")

if __name__ == "__main__":
    generate_daily_report()
```

### crontab 定时任务

```bash
# 每天早上 9 点运行监控
# crontab -e
0 9 * * * cd /home/skywalker && python3 ~/daily_blog_monitor.py >> ~/blog_daily.log 2>&1

# 或者直接调用 blogwatcher-cli
0 9 * * * BLOGWATCHER_SILENT=1 blogwatcher-cli scan >> ~/blog_scan.log 2>&1
```

### 结合 LLM Wiki 知识库

扫描到新文章后，可以将重要内容摄入到知识库中：

```python
#!/usr/bin/env python3
"""
blog_to_wiki.py — 将博客新文章自动摄入到 LLM Wiki

用法：先扫描博客，然后对重要的新文章提取内容并写入 Wiki
"""

import subprocess
import re
import sys
from datetime import datetime

def get_new_articles():
    """提取新文章链接"""
    result = subprocess.run(
        ["blogwatcher-cli", "articles"],
        capture_output=True, text=True, timeout=30
    )
    output = result.stdout

    # 解析模式：[N] [new] 标题
    #            URL: <url>
    articles = []
    current = {}

    for line in output.split("\n"):
        new_match = re.match(r'\s*\[(\d+)\]\s+\[new\]\s+(.+)', line)
        url_match = re.match(r'\s*URL:\s+(.+)', line)

        if new_match:
            if current.get("title"):
                articles.append(current)
            current = {"num": new_match.group(1), "title": new_match.group(2).strip()}
        elif url_match and current:
            current["url"] = url_match.group(1).strip()
            articles.append(current)
            current = {}

    return articles

# 获取新文章
new_articles = get_new_articles()
print(f"📝 发现 {len(new_articles)} 篇新文章")
for a in new_articles:
    print(f"  - {a['title']}")
    print(f"    {a.get('url', 'N/A')}")
```

---

## 故障排查

| 问题 | 原因 | 解决方法 |
|------|------|----------|
| `blogwatcher-cli: command not found` | 没安装或在 PATH 之外 | 确保 `$GOPATH/bin` 在 PATH 中，或用绝对路径 |
| `Failed to discover feed` | 自动发现 RSS 失败 | 手动找到 Feed URL 并用 `--feed-url` 指定 |
| 扫描总是 0 篇新文章 | Feed 可能被缓存了 | 检查博客的实际更新日期，有些博客更新很慢 |
| 中文乱码 | 终端编码问题 | 确保终端使用 UTF-8，执行 `export LANG=zh_CN.UTF-8` |
| Docker 数据丢失 | 容器重启后数据库丢失 | 使用 volume 挂载持久化，设置 `BLOGWATCHER_DB` 环境变量 |
| SQLite 数据库被锁定 | 多个进程同时访问 | 不要同时运行多个 `blogwatcher-cli` 实例 |
| HTML 抓取无结果 | `--scrape-selector` 的 CSS 选择器不对 | 检查网页结构，用浏览器开发者工具找到正确的选择器 |

---

## 高级：搭建个人 RSS 聚合服务

如果博客数量很多（50+），可以考虑搭建一个自托管的 RSS 阅读服务：

| 服务 | 语言 | 特点 |
|------|------|------|
| Miniflux | Go | 极简，单二进制，PostgreSQL 存储 |
| FreshRSS | PHP | 功能丰富，支持多用户 |
| Tiny Tiny RSS | PHP | 老牌 RSS 阅读器 |
| Wallabag | PHP | 不只是 RSS——还支持"保存稍后阅读" |

Miniflux 安装最方便：

```bash
docker run -d --name miniflux \
  -p 8080:8080 \
  -e DATABASE_URL="postgres://miniflux:password@db/miniflux?sslmode=disable" \
  -e RUN_MIGRATIONS=1 \
  miniflux/miniflux
```

---

## 总结

```
添加博客 (add) → 自动发现 Feed
     ↓
扫描新文章 (scan) → 对比已读/未读
     ↓
查看文章 (articles) → 打开链接阅读全文
     ↓
标记已读 (read) → 更新状态
     ↓
（可选）摄入知识库 → 沉淀到 LLM Wiki
```

`blogwatcher-cli` 的命令行 RSS 工作流做到了极致简洁。配合 cron 定时扫描，每天打开终端就能看到最新的博客更新，而不会被社交媒体算法绑架。
