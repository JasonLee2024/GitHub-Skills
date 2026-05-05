---
date: 2026-05-05
tags:
  - blogwatcher
  - rss
  - atom
  - feed-monitor
  - content-tracking
  - operations
  - 运维与监控
source_skill: blogwatcher
category: 运维与监控
---

# Blog/RSS 监控

> 本文档基于 Hermes Agent 的 `blogwatcher` 技能整理，覆盖通过 RSS/Atom 订阅实时监控博客和技术站点更新的全流程。

## 概述

BlogWatcher 是一个轻量级的**博客和 RSS 订阅监控工具**，帮助开发者跟踪关注的技术博客、新闻源和文档更新。它能够定期抓取订阅源，检测新内容，并通过多种方式通知用户。

### 核心能力

| 功能 | 说明 | 适用场景 |
|------|------|---------|
| RSS 订阅 | 支持 RSS 2.0 和 Atom 1.0 | 博客更新跟踪 |
| 定时抓取 | 可配置的轮询间隔 | 按需监控 |
| 新内容检测 | 自动识别未读条目 | 不重复通知 |
| 多格式输出 | 终端、JSON、Markdown | 管道处理 |
| 通知集成 | Webhook、邮件、Slack 通知 | 即时告警 |
| 源管理 | 添加/删除/订阅列表 | 个性化配置 |

---

## 环境安装

```bash
# 使用 pip 安装
pip install feedparser requests beautifulsoup4

# 解析 HTML 的依赖
pip install lxml html5lib
```

---

## 基础用法

### 读取和解析 RSS 源

```python
import feedparser

def fetch_feed(feed_url):
    """获取并解析 RSS/Atom 订阅源"""
    feed = feedparser.parse(feed_url)
    
    print(f"📡 订阅源: {feed.feed.get('title', '未命名')}")
    print(f"   链接: {feed.feed.get('link', 'N/A')}")
    print(f"   条目数: {len(feed.entries)}")
    print()
    
    for entry in feed.entries[:10]:  # 只显示前 10 条
        title = entry.get('title', '无标题')
        link = entry.get('link', '')
        published = entry.get('published', '未知日期')
        summary = entry.get('summary', '')[:100]
        
        print(f"📄 {title}")
        print(f"   📅 {published}")
        print(f"   🔗 {link}")
        print(f"   {summary}...")
        print()
    
    return feed

# 使用示例
fetch_feed("https://github.com/blog.atom")
```

### 监控多个源

```python
import time
import hashlib
import json
from pathlib import Path

class FeedMonitor:
    """RSS 订阅监控器"""
    
    def __init__(self, state_file='~/.feedmonitor_state.json'):
        self.state_file = Path(state_file).expanduser()
        self.state = self._load_state()
    
    def _load_state(self):
        """加载已读条目状态"""
        if self.state_file.exists():
            return json.loads(self.state_file.read_text())
        return {'seen': {}, 'feeds': {}}
    
    def _save_state(self):
        """保存状态"""
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(json.dumps(self.state, indent=2))
    
    def _entry_id(self, entry):
        """生成条目的唯一 ID"""
        return entry.get('id') or entry.get('link') or \
               hashlib.md5(entry.get('title', '').encode()).hexdigest()
    
    def check_feed(self, name, feed_url):
        """检查单个订阅源的新内容"""
        feed = feedparser.parse(feed_url)
        
        new_entries = []
        for entry in feed.entries:
            eid = self._entry_id(entry)
            if eid not in self.state['seen']:
                new_entries.append(entry)
                self.state['seen'][eid] = {
                    'title': entry.get('title'),
                    'link': entry.get('link'),
                    'published': entry.get('published'),
                    'feed': name
                }
        
        self._save_state()
        
        if new_entries:
            print(f"🆕 [{name}] 发现 {len(new_entries)} 篇新文章!")
            for entry in new_entries[:5]:
                print(f"  📄 {entry.get('title')}")
                print(f"     {entry.get('link')}")
        else:
            print(f"✓ [{name}] 无新内容")
        
        return new_entries
    
    def check_all(self, feeds):
        """检查所有订阅源"""
        all_new = []
        for name, url in feeds.items():
            new = self.check_feed(name, url)
            all_new.extend(new)
            time.sleep(1)  # 避免请求过快
        return all_new

# 使用示例
monitor = FeedMonitor()

feeds = {
    "GitHub Blog": "https://github.blog/feed/",
    "Hermes Agent": "https://github.com/NousResearch/hermes-agent/releases.atom",
    "Python Weekly": "https://www.pythonweekly.com/atom.xml",
    "Hacker News": "https://hnrss.org/frontpage",
}

# 检查所有源
new_articles = monitor.check_all(feeds)

# 生成摘要
if new_articles:
    print(f"\n📰 共 {len(new_articles)} 篇新文章")
```

### 常用技术 RSS 源

| 名称 | RSS URL | 更新频率 |
|------|---------|---------|
| GitHub Blog | `https://github.blog/feed/` | 每周 2-3 篇 |
| GitHub Changelog | `https://github.blog/changelog/feed/` | 几乎每日 |
| Hacker News | `https://hnrss.org/frontpage` | 实时 |
| Python.org | `https://www.python.org/dev/peps/peps.rss` | 不定 |
| Google AI Blog | `https://ai.googleblog.com/feeds/posts/default` | 每周 |
| Cloudflare Blog | `https://blog.cloudflare.com/rss/` | 每日 |
| 阮一峰博客 | `https://www.ruanyifeng.com/blog/atom.xml` | 每周 |
| V2EX | `https://www.v2ex.com/index.xml` | 实时 |

---

## 高级用法

### 内容过滤和分类

```python
import re

def filter_entries(entries, keywords=None, categories=None):
    """根据关键词过滤文章"""
    if not keywords:
        return entries
    
    filtered = []
    for entry in entries:
        title = entry.get('title', '')
        summary = entry.get('summary', '')
        content = title + ' ' + summary
        
        # 检查是否有匹配关键词
        if any(kw.lower() in content.lower() for kw in keywords):
            filtered.append(entry)
    
    return filtered

# 只关注 AI 相关文章
ai_keywords = ['machine learning', 'deep learning', 'LLM', 'GPT', 
               'neural network', 'transformer', 'AI', 'artificial intelligence']

entries = feed.entries
ai_entries = filter_entries(entries, ai_keywords)
print(f"📊 共 {len(entries)} 条，其中 AI 相关 {len(ai_entries)} 条")
```

### 输出为 Markdown

```python
def entries_to_markdown(entries, feed_name="Feed"):
    """将订阅条目导出为 Markdown"""
    lines = [f"# 📡 {feed_name}\n"]
    
    for entry in entries:
        title = entry.get('title', '无标题')
        link = entry.get('link', '')
        published = entry.get('published', '')
        summary = entry.get('summary', '')[:200]
        
        # 清理 HTML
        summary_clean = re.sub('<[^<]+?>', '', summary)
        
        lines.append(f"## [{title}]({link})")
        lines.append(f"> {published}")
        lines.append(f"\n{summary_clean}\n")
    
    return '\n'.join(lines)

# 导出为文件
with open('feed_digest.md', 'w', encoding='utf-8') as f:
    f.write(entries_to_markdown(new_articles, "今日技术摘要"))
```

---

## 自动化脚本

### cron 定时监控

```bash
# crontab -e
# 每两小时检查一次新文章
0 */2 * * * cd /home/user/feed-monitor && python check_feeds.py >> feed_monitor.log 2>&1

# 每天上午 9 点发送摘要
0 9 * * * cd /home/user/feed-monitor && python send_digest.py
```

### Webhook 通知集成

```python
import requests

def notify_webhook(new_entries, webhook_url):
    """通过 Webhook 发送新文章通知"""
    if not new_entries:
        return
    
    payload = {
        "text": f"📰 发现 {len(new_entries)} 篇新文章\n\n",
        "entries": [
            {
                "title": e.get('title'),
                "url": e.get('link'),
                "source": e.get('source', {}).get('title', '未知')
            }
            for e in new_entries[:5]
        ]
    }
    
    try:
        resp = requests.post(webhook_url, json=payload, timeout=10)
        resp.raise_for_status()
        print(f"✅ Webhook 通知已发送")
    except Exception as e:
        print(f"❌ Webhook 发送失败: {e}")

# 使用企业微信/钉钉/Slack Webhook
SLACK_WEBHOOK = "https://hooks.slack.com/services/xxx"
DINGTALK_WEBHOOK = "https://oapi.dingtalk.com/robot/send?access_token=xxx"
```

---

## 最佳实践

1. **轮询间隔** — 高频更新的源设置较短间隔（HN 15min），低频源设置较长（博客 2h）
2. **状态持久化** — 使用 JSON 或 SQLite 记录已读状态，避免重复通知
3. **错误处理** — RSS 源可能偶尔不可用，添加重试和超时
4. **去重** — 部分源可能重复推送，使用 ID 或 MD5 去重
5. **速率限制** — 尊重目标服务器的速率限制，避免被封 IP

---

## 相关技能

- [[01-webhook-ops]] — Webhook 订阅管理
- [[03-pages-ops]] — GitHub Pages 运维
- [[04-serverless-gpu]] — Modal 无服务器 GPU 运维
