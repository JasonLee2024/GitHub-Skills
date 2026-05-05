---
date: 2026-05-05
tags:
  - arxiv
  - research
  - paper-search
  - api
  - scholarly
  - 科研工作流
source_skill: arxiv
category: 科研工作流
---

# arXiv 论文搜索

> 本文档基于 Hermes Agent 的 `arxiv` 技能整理，覆盖从关键词检索到高级 API 查询再到 PDF 下载的全流程实操。

## 概述

arXiv（读作 "archive"）是全球最大的预印本（preprint）数据库，涵盖物理学、数学、计算机科学、定量生物学、定量金融学、统计学、电气工程和经济学等多个领域。每天有上千篇新论文上传，是所有科研工作者的"第一手"信息来源。

在命令行中操作 arXiv 的效率远高于浏览器手动搜索：你可以批量检索、自动过滤、一键下载 PDF、甚至构建自动化论文监控流水线。

本文将介绍三种检索方式：

1. **arXiv API 原生查询** — 最底层的 REST API，完全可控
2. **arxiv Python 库** — 封装好的 Python 客户端，简洁易用
3. **Semantic Scholar API** — 引用分析和影响力评估

---

## 前置准备：安装工具

```bash
# Python 生态必备
pip install arxiv pyperclip requests tqdm

# 可选：XML 解析（原生 API 需要）
pip install lxml

# 可选：PDF 提取工具
pip install pypdf2 pdfplumber
```

验证安装：

```bash
python3 -c "import arxiv; print(f'arxiv v{arxiv.__version__}')"
python3 -c "import requests; print('requests OK')"
```

---

## 方法一：arXiv API 原生查询

arXiv 提供了 RESTful API，无需注册或 API Key，完全开放。API 端点：

```
https://export.arxiv.org/api/query?search_query=<query>&start=0&max_results=10
```

### 基础用法

最简单的搜索示例 — 搜索量子计算相关的论文：

```bash
# 直接在终端中请求（返回 XML）
curl -s "https://export.arxiv.org/api/query?search_query=all:quantum+AND+all:computing&max_results=5" | head -100
```

输出是 Atom XML 格式，包含：`<entry>` / `<title>` / `<summary>` / `<id>`（论文 ID）/ `<published>` / `<arxiv:comment>` 等标签。

### 结构化 Python 查询

直接用 curl 看 XML 不直观，写一个 Python 脚本来解析：

```python
import requests
import xml.etree.ElementTree as ET

def search_arxiv(query, max_results=10, sort_by="relevance"):
    """
    通过 arXiv API 搜索论文

    参数:
        query: 搜索关键词（支持 AND/OR/NOT 逻辑）
        max_results: 最大返回数
        sort_by: 排序方式 — relevance | lastUpdatedDate | submittedDate
    """
    base_url = "https://export.arxiv.org/api/query"
    params = {
        "search_query": query,
        "start": 0,
        "max_results": max_results,
        "sortBy": sort_by,
        "sortOrder": "descending"
    }

    resp = requests.get(base_url, params=params, timeout=30)
    root = ET.fromstring(resp.content)

    # arXiv API 使用 Atom 命名空间
    ns = {"atom": "http://www.w3.org/2005/Atom",
          "arxiv": "http://arxiv.org/schemas/atom"}

    papers = []
    for entry in root.findall("atom:entry", ns):
        paper = {
            "id": entry.find("atom:id", ns).text,
            "title": entry.find("atom:title", ns).text.strip().replace("\n", " "),
            "summary": entry.find("atom:summary", ns).text.strip()[:200] + "...",
            "published": entry.find("atom:published", ns).text[:10],
            "authors": [a.find("atom:name", ns).text
                      for a in entry.findall("atom:author", ns)],
            "link": entry.find("atom:link", ns).attrib.get("href", "")
        }
        papers.append(paper)

    return papers

# 使用示例
papers = search_arxiv("all:large+language+model+AND+all:evaluation", max_results=5)
for i, p in enumerate(papers, 1):
    print(f"\n{'='*60}")
    print(f"#{i}: {p['title']}")
    print(f"日期: {p['published']}")
    print(f"作者: {', '.join(p['authors'][:3])}{'...' if len(p['authors']) > 3 else ''}")
    print(f"ID:   {p['id']}")
    print(f"链接: {p['link']}")
```

### 高级搜索语法

arXiv API 支持结构化搜索字段，比简单的关键词搜索精准得多：

| 字段 | 含义 | 示例 |
|------|------|------|
| `ti:` | 标题中搜索 | `ti:transformer` |
| `au:` | 作者搜索 | `au:yoshua_bengio` |
| `abs:` | 摘要中搜索 | `abs:attention+mechanism` |
| `cat:` | 分类中搜索 | `cat:cs.LG`（机器学习） |
| `all:` | 所有字段 | `all:reinforcement+learning` |

最常用的分类标识符：

| 分类代码 | 含义 |
|----------|------|
| `cs.AI` | 人工智能 |
| `cs.LG` | 机器学习 |
| `cs.CL` | 计算语言学 / NLP |
| `cs.CV` | 计算机视觉 |
| `cs.NE` | 神经与进化计算 |
| `stat.ML` | 统计学习 |
| `math.OC` | 优化与控制 |
| `physics` | 物理学（广义） |

**组合搜索示例：**

```bash
# 搜索 2024 年后计算机视觉领域的注意力机制论文
curl -s "https://export.arxiv.org/api/query?search_query=cat:cs.CV+AND+ti:attention&start=0&max_results=10&sortBy=submittedDate"

# 搜索指定作者的强化学习论文
curl -s "https://export.arxiv.org/api/query?search_query=au:richard_sutton+AND+all:reinforcement+learning&max_results=5"
```

### 搜索技巧

1. **使用引号**：`all:"chain-of-thought"` 搜索精确短语
2. **排除关键词**：`all:transformer+NOT+all:vision` 排除视觉相关
3. **时间过滤**：arXiv API 原生不支持按日期过滤，但可以通过 `submittedDate` 排序后手动筛选
4. **AND/OR**：默认是 AND 关系，用 `+OR+` 切换为或逻辑
5. **特殊字符编码**：`+` 代表空格，`%28` 和 `%29` 代表括号

---

## 方法二：arxiv Python 库

`arxiv` 库是对 arXiv API 的 Python 封装，API 设计更优雅，不需要手动解析 XML。

### 安装

```bash
pip install arxiv
```

### 基础搜索

```python
import arxiv

# 创建搜索客户端
client = arxiv.Client(
    page_size=100,       # 每页结果数（默认 100）
    delay_seconds=3,     # 请求间隔（遵守 arXiv 限流）
    num_retries=3        # 失败重试次数
)

# 构建搜索
search = arxiv.Search(
    query="attention mechanism AND transformer",
    max_results=20,
    sort_by=arxiv.SortCriterion.Relevance,
    sort_order=arxiv.SortOrder.Descending
)

# 执行搜索
results = client.results(search)

# 遍历结果
for i, paper in enumerate(results, 1):
    print(f"\n--- 论文 #{i} ---")
    print(f"标题: {paper.title}")
    print(f"出版日期: {paper.published.strftime('%Y-%m-%d')}")
    print(f"最新更新: {paper.updated.strftime('%Y-%m-%d')}")
    print(f"arXiv ID: {paper.entry_id}")
    print(f"PDF 链接: {paper.pdf_url}")
    print(f"分类: {', '.join(paper.categories)}")
    print(f"作者数: {len(paper.authors)}")
    print(f"摘要前 150 字: {paper.summary[:150]}...")

    # 检查是否有评论（如会议投稿信息）
    if paper.comment:
        print(f"评论: {paper.comment}")
```

### 根据 ID 获取特定论文

如果你已经知道论文的 arXiv ID（如 `2303.08774`）：

```python
import arxiv

search = arxiv.Search(id_list=["2303.08774", "2106.09685", "2005.14165"])
client = arxiv.Client()
results = list(client.results(search))

for paper in results:
    print(f"{paper.title} — {', '.join(a.name for a in paper.authors[:2])}")
```

### 按分类获取最新论文

```python
import arxiv
from datetime import datetime, timedelta

# 最近 7 天 cs.LG（机器学习）分类的论文
search = arxiv.Search(
    query="cat:cs.LG",
    max_results=50,
    sort_by=arxiv.SortCriterion.SubmittedDate,
)

client = arxiv.Client()
papers = list(client.results(search))

print(f"找到 {len(papers)} 篇 cs.LG 最新论文\n")
for paper in papers[:10]:
    days_ago = (datetime.now().replace(tzinfo=paper.published.tzinfo) - paper.published).days
    print(f"[{days_ago}d] {paper.title}")
```

### 搜索结果缓存

arXiv API 有请求频率限制（约每秒 1 次），建议缓存结果避免重复请求：

```python
import json
import os
import arxiv
from datetime import datetime

CACHE_FILE = os.path.expanduser("~/.arxiv_cache.json")

def search_with_cache(query, max_results=20, cache_ttl_hours=24):
    """带缓存功能的 arXiv 搜索，避免重复请求"""

    # 尝试从缓存读取
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            cache = json.load(f)

        cache_key = f"{query}_{max_results}"
        if cache_key in cache:
            cached_time = datetime.fromisoformat(cache[cache_key]["timestamp"])
            if (datetime.now() - cached_time).total_seconds() < cache_ttl_hours * 3600:
                print("📦 命中缓存")
                return cache[cache_key]["results"]

    # 执行实际搜索
    client = arxiv.Client()
    search = arxiv.Search(query=query, max_results=max_results)
    papers = list(client.results(search))

    # 序列化结果
    serialized = [{
        "title": p.title,
        "summary": p.summary[:300],
        "published": p.published.isoformat(),
        "pdf_url": p.pdf_url,
        "entry_id": p.entry_id,
        "categories": p.categories,
        "authors": [a.name for a in p.authors]
    } for p in papers]

    # 写入缓存
    if not os.path.exists(CACHE_FILE):
        cache = {}
    else:
        with open(CACHE_FILE, "r") as f:
            cache = json.load(f)

    cache_key = f"{query}_{max_results}"
    cache[cache_key] = {
        "timestamp": datetime.now().isoformat(),
        "results": serialized
    }

    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

    print(f"✅ 从 arXiv API 获取 {len(papers)} 篇论文")
    return serialized
```

---

## 方法三：Semantic Scholar API

Semantic Scholar（语义学者）是艾伦人工智能研究所（AI2）开发的学术搜索引擎。它的独特价值在于**引用分析**——可以看到某篇论文被谁引用、引用影响力如何。

### 基础用法

```python
import requests
import time

def search_semantic_scholar(query, limit=10, fields="title,year,authors,citationCount,externalIds"):
    """
    搜索 Semantic Scholar

    参数:
        query: 搜索关键词
        limit: 最大结果数
        fields: 返回字段（逗号分隔）
    """
    url = "https://api.semanticscholar.org/graph/v1/paper/search"
    params = {
        "query": query,
        "limit": min(limit, 100),
        "fields": fields
    }
    headers = {"User-Agent": "ResearchBot/1.0"}

    resp = requests.get(url, params=params, headers=headers, timeout=15)

    if resp.status_code == 429:
        print("⚠️ 请求频率限制，等待 3 秒重试...")
        time.sleep(3)
        resp = requests.get(url, params=params, headers=headers, timeout=15)

    data = resp.json()

    if "data" not in data:
        print(f"❌ API 错误: {data.get('message', '未知错误')}")
        return []

    return data["data"]

# 使用示例
results = search_semantic_scholar("chain of thought prompting", limit=5)
for i, paper in enumerate(results, 1):
    authors = ", ".join(a["name"] for a in paper.get("authors", [])[:3])
    citations = paper.get("citationCount", 0)
    print(f"\n#{i}: {paper['title']}")
    print(f"   作者: {authors}")
    print(f"   引用数: {citations}")
    print(f"   年份: {paper.get('year', 'N/A')}")
```

### 获取引用网络

Semantic Scholar 能展示论文的引用关系——这对做文献综述非常有用：

```python
def get_citation_network(paper_id, depth=1):
    """
    获取论文的引用网络

    参数:
        paper_id: Semantic Scholar paper ID 或 arXiv ID（如 arXiv:2305.11206）
        depth: 引用深度（0=只看论文本身, 1=看直接引用的论文）
    """
    # 注意：支持 arXiv ID 格式
    if paper_id.startswith("arXiv:"):
        url_id = paper_id
    else:
        url_id = paper_id

    # 获取论文信息 + 引用
    url = f"https://api.semanticscholar.org/graph/v1/paper/{url_id}"
    params = {
        "fields": "title,year,authors,citationCount,references.references.title,references.references.citationCount"
    }

    resp = requests.get(url, params=params, timeout=15)
    if resp.status_code != 200:
        print(f"❌ 获取失败: {resp.status_code}")
        return None

    data = resp.json()

    print(f"\n📄 论文: {data['title']}")
    print(f"📊 被引用次数: {data.get('citationCount', 'N/A')}")

    # 获取引用了该论文的论文（Citations In）
    citations_url = f"https://api.semanticscholar.org/graph/v1/paper/{url_id}/citations"
    citations_params = {
        "fields": "title,year,citationCount",
        "limit": 20
    }
    cit_resp = requests.get(citations_url, params=citations_params, timeout=15)
    if cit_resp.status_code == 200:
        cit_data = cit_resp.json()
        print("\n📎 引用该论文的重要论文（前 10 篇）:")
        for i, cit in enumerate(cit_data.get("data", [])[:10], 1):
            p = cit.get("citingPaper", {})
            print(f"  {i}. {p.get('title', 'N/A')} ({p.get('year', 'N/A')}) — {p.get('citationCount', 0)} 次引用")

    return data

# 使用 arXiv ID 查询
get_citation_network("arXiv:2305.11206")
```

### 引用影响力分析

通过比较论文的引用次数和发表年代，可以快速评估论文的影响力：

```python
def analyze_citation_impact(query, limit=20):
    """分析搜索结果中每篇论文的引用影响力"""
    papers = search_semantic_scholar(
        query,
        limit=limit,
        fields="title,year,authors,citationCount,externalIds,publicationDate"
    )

    print(f"\n📊 引用影响力分析: \"{query}\"\n")
    print(f"{'#':>3} | {'引用数':>5} | {'年份':>4} | {'标题'}")
    print("-" * 80)

    sorted_papers = sorted(papers, key=lambda p: p.get("citationCount", 0), reverse=True)

    for i, p in enumerate(sorted_papers, 1):
        title = p.get("title", "N/A")[:50]
        citations = p.get("citationCount", 0)
        year = p.get("year", "N/A")
        print(f"{i:>3} | {citations:>5} | {year:>4} | {title}")

    return sorted_papers

analyze_citation_impact("reinforcement learning from human feedback", limit=10)
```

---

## PDF 下载与管理

找到想要的论文后，下一步是下载 PDF。

### 单篇下载

```python
import arxiv
import requests

def download_pdf(arxiv_id, output_dir="~/papers"):
    """通过 arXiv ID 下载 PDF"""
    import os
    output_dir = os.path.expanduser(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    search = arxiv.Search(id_list=[arxiv_id])
    client = arxiv.Client()

    for paper in client.results(search):
        filename = f"{arxiv_id}_{paper.title[:50].replace('/', '_')}.pdf"
        filepath = os.path.join(output_dir, filename)

        print(f"⬇️  下载中: {paper.title[:50]}...")
        paper.download_pdf(dirpath=output_dir, filename=filename)
        print(f"✅ 保存到: {filepath}")

        return filepath

# 示例
download_pdf("2303.08774")
```

### 批量下载

```python
import arxiv
import os
from tqdm import tqdm

def batch_download(query, max_results=10, output_dir="~/papers"):
    """搜索并批量下载论文 PDF"""
    output_dir = os.path.expanduser(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    client = arxiv.Client()
    search = arxiv.Search(query=query, max_results=max_results)
    papers = list(client.results(search))

    print(f"🔍 找到 {len(papers)} 篇论文，开始下载...\n")

    for paper in tqdm(papers, desc="下载进度"):
        safe_title = paper.title.replace("/", "_").replace(":", " ")[:60]
        filename = f"{paper.entry_id.split('/')[-1]}_{safe_title}.pdf"
        filepath = os.path.join(output_dir, filename)

        if os.path.exists(filepath):
            print(f"⏭️  跳过已存在: {filename[:40]}...")
            continue

        try:
            paper.download_pdf(dirpath=output_dir, filename=filename)
        except Exception as e:
            print(f"❌ 下载失败 {filename[:30]}: {e}")

    print(f"\n✅ 全部完成！PDF 保存在 {output_dir}")
    # 列出下载的文件
    for f in sorted(os.listdir(output_dir)):
        if f.endswith(".pdf"):
            size = os.path.getsize(os.path.join(output_dir, f)) / 1024
            print(f"  📄 {f[:55]} ({size:.0f} KB)")

batch_download("cat:cs.LG+AND+ti:transformer", max_results=5)
```

### 命令行一键下载

简单场景下，直接用 curl 下载更快：

```bash
# 下载指定 arXiv ID 的 PDF
# 格式: https://arxiv.org/pdf/<arxiv_id>.pdf
ARXIV_ID="2303.08774"
curl -L -o "${ARXIV_ID}.pdf" "https://arxiv.org/pdf/${ARXIV_ID}.pdf"

# 批量从文件读取 ID 并下载
cat << 'EOF' > paper_ids.txt
2303.08774
2106.09685
2005.14165
EOF

while read -r id; do
    echo "下载 ${id}.pdf..."
    curl -sL -o "${id}.pdf" "https://arxiv.org/pdf/${id}.pdf"
    sleep 3  # 礼貌等待，避免被限流
done < paper_ids.txt
```

### PDF 内容提取

下载后要从 PDF 中提取文本做进一步分析：

```python
import pdfplumber

def extract_pdf_text(pdf_path, max_pages=5):
    """提取 PDF 前几页文本"""
    text_content = []
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages):
            if i >= max_pages:
                break
            text = page.extract_text()
            if text:
                text_content.append(f"--- Page {i+1} ---\n{text}")

    return "\n\n".join(text_content)

text = extract_pdf_text("2303.08774.pdf", max_pages=3)
print(text[:1000])
```

---

## 自动化监控：每日论文推送

建立一个每日自动搜索的流水线，不再错过重要论文：

```python
import arxiv
import json
import os
from datetime import datetime

def daily_paper_monitor(config_path="~/.arxiv_monitor.json"):
    """每日论文监控——搜索指定关键词并记录新论文"""
    config_path = os.path.expanduser(config_path)

    # 默认监控配置
    default_config = {
        "queries": [
            "cat:cs.LG+AND+ti:transformer",
            "cat:cs.CL+AND+ti:reasoning",
            "all:reinforcement+learning+AND+all:alignment"
        ],
        "max_per_query": 5,
        "seen_file": os.path.expanduser("~/.arxiv_seen.json")
    }

    if os.path.exists(config_path):
        with open(config_path) as f:
            config = json.load(f)
    else:
        config = default_config
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, "w") as f:
            json.dump(config, f, indent=2)
        print(f"📝 已创建默认配置文件: {config_path}")

    # 读取已看过的论文 ID
    seen_ids = set()
    if os.path.exists(config["seen_file"]):
        with open(config["seen_file"]) as f:
            seen_ids = set(json.load(f))

    client = arxiv.Client()
    new_papers = []

    print(f"📡 论文监控 | {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")

    for query in config["queries"]:
        print(f"🔍 搜索: {query}")
        search = arxiv.Search(query=query, max_results=config["max_per_query"])

        for paper in client.results(search):
            paper_id = paper.entry_id.split("/")[-1].split("v")[0]

            if paper_id not in seen_ids:
                new_papers.append(paper)
                seen_ids.add(paper_id)
                print(f"  🆕 [{paper.published.strftime('%m-%d')}] {paper.title[:60]}")

        print()

    # 更新已看记录
    with open(config["seen_file"], "w") as f:
        json.dump(list(seen_ids), f)

    if new_papers:
        print(f"🎉 发现 {len(new_papers)} 篇新论文！")
    else:
        print("😴 暂无新论文。")

    return new_papers

# 运行监控
daily_paper_monitor()
```

也可以配合 cron 做日报：

```bash
# 添加到 crontab（每天早上 8 点运行）
# crontab -e
# 0 8 * * * cd /home/skywalker && python3 ~/.arxiv_monitor.py >> ~/arxiv_daily.log 2>&1
```

---

## 常见问题排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 429 Too Many Requests | 请求过于频繁 | 添加 `time.sleep(3)` 控制速率 |
| XML 解析出错 | 查询语法有误 | 检查 URL 编码，确保 `+AND+` 格式正确 |
| PDF 下载失败 | arXiv ID 格式错误 | 使用 `entry_id.split('/')[-1]` 提取纯 ID |
| 搜索返回空结果 | 分类代码不存在 | 检查 `cat:` 后的分类代码是否正确 |
| Semantic Scholar 限流 | 免费 API 有速率限制 | 添加 `fields` 参数减少不必要的数据传输 |

---

## 总结

```
arXiv API（REST/XML） → 底层搜索，完全可控
  ↓
arxiv Python 库      → 简洁封装，推荐日常使用
  ↓
Semantic Scholar API → 引用分析和影响力评估
  ↓
PDF 下载             → 单篇 / 批量 / 自动监控
```

最有效的工作流是三层结合：

1. **arXiv 搜索**发现新论文
2. **Semantic Scholar**分析论文的引用价值和影响力
3. **批量下载 PDF**到本地，准备深入阅读

配合自动化监控脚本，每天醒来就能看到最新的论文动态。
