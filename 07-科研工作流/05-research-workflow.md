---
date: 2026-05-05
tags:
  - research-workflow
  - pipeline
  - literature-review
  - automation
  - 科研工作流
source_skill: 综合
category: 科研工作流
---

# 完整研究流程工作流

> 本文档综合 Hermes Agent 的多个科研技能，构建一条从论文发现到知识输出的完整自动化研究流水线。

## 概述

科研工作的核心流程可以抽象为几个连续阶段：**发现 → 筛选 → 深入阅读 → 知识沉淀 → 成果输出**。每个阶段都有特定的工具和方法，组合起来可以极大提升研究效率。

本文将展示如何将本章的各个技能串联成一条完整的自动化研究流水线。

---

## 一、研究流水线全景

```
┌─────────────────────────────────────────────────────────────┐
│                   完整科研工作流                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ① 论文发现 ─────────────────────────────────────────────── │
│  arXiv 搜索  │  Semantic Scholar  │  RSS 博客  │  YouTube  │
│                                                             │
│  ② 初筛评估 ─────────────────────────────────────────────── │
│  阅读摘要  │  引用影响力分析  │  相关论文推荐  │  作者追踪  │
│                                                             │
│  ③ 深入阅读 ─────────────────────────────────────────────── │
│  全文阅读  │  PDF 下载与标注  │  幻灯片提取  │  视频字幕  │
│                                                             │
│  ④ 知识沉淀 ─────────────────────────────────────────────── │
│  LLM Wiki  │  笔记整理  │  引用管理  │  Anki 闪卡  │  BibTeX  │
│                                                             │
│  ⑤ 成果输出 ─────────────────────────────────────────────── │
│  文献综述  │  博客文章  │  演示文稿  │  代码实现  │  论文  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 阶段详解

| 阶段 | 目标 | 工具/技能 | 预期产出 |
|------|------|-----------|----------|
| **发现** | 找到值得关注的论文和信息 | `arxiv`, `youtube-content`, `blogwatcher` | 论文列表、视频链接 |
| **初筛** | 判断论文是否值得深入 | `arxiv` (摘要/引用) | 已筛选论文清单 |
| **深入** | 理解论文内容 | `ocr-and-documents`, PDF 工具 | 笔记、标注 |
| **沉淀** | 将知识变成可复用的资产 | `llm-wiki`, `knowledge-base-scaffold` | 知识库条目、闪卡 |
| **输出** | 分享和应用研究成果 | 各种输出工具 | 文章、代码、演示 |

---

## 二、流水线实战

### 2.1 论文发现阶段

#### 每日自动化检查

```bash
#!/bin/bash
# daily-research.sh — 每日科研例行检查

echo "=== 📚 每日研究简报 $(date) ==="

echo ""
echo "=== arXiv 新论文 ==="
# 在指定分类中搜索最新论文
arxiv_search() {
    local query="$1"
    python3 << EOF
import urllib.request, xml.etree.ElementTree as ET
import json

query = urllib.parse.quote("$query")
url = f"http://export.arxiv.org/api/query?search_query=all:{query}&sortBy=submittedDate&sortOrder=descending&max_results=5"

response = urllib.request.urlopen(url)
root = ET.fromstring(response.read().decode('utf-8'))
ns = {'a': 'http://www.w3.org/2005/Atom'}

for entry in root.findall('a:entry', ns)[:5]:
    title = entry.find('a:title', ns).text.strip().replace('\n', ' ')
    published = entry.find('a:published', ns).text[:10]
    link = entry.find('a:id', ns).text
    print(f"  📄 {title}")
    print(f"     {published} | {link}")
    print()
EOF
}

arxiv_search "machine+learning"
arxiv_search "large+language+model"
```

#### 综合来源扫描

```bash
#!/bin/bash
# scan-all-sources.sh — 扫描多个信息来源

echo "🔍 扫描 arXiv 最新论文..."
curl -s "http://export.arxiv.org/api/query?search_query=cat:cs.AI&sortBy=submittedDate&max_results=10" | python3 -c "
import sys, xml.etree.ElementTree as ET
data = sys.stdin.read()
root = ET.fromstring(data)
ns = {'a': 'http://www.w3.org/2005/Atom'}
for e in root.findall('a:entry', ns)[:5]:
    t = e.find('a:title', ns).text.strip().replace('\n',' ')
    print(f'  {t[:80]}...')
"

echo ""
echo "🔍 检查 RSS 博客更新..."
blogwatcher update
blogwatcher list --unread

echo ""
echo "🔍 检查 YouTube 频道..."
# 使用 yt-dlp 检查频道最新视频
yt-dlp --flat-playlist --print "title" "https://youtube.com/@ChannelName" 2>/dev/null | head -5
```

---

### 2.2 论文初筛与评估

#### 快速评分系统

```python
#!/usr/bin/env python3
"""paper-scorer.py — 给论文快速评分，决定是否深入阅读"""

def score_paper(title, abstract, citations=None, is_recent=True):
    """
    对论文进行快速评分（0-100）
    
    - 标题相关度: 0-20分
    - 摘要质量: 0-40分
    - 引用影响: 0-25分
    - 时效性: 0-15分
    """
    score = 0
    
    # 1. 标题分析（20分）
    title_keywords = ['transformer', 'attention', 'pretrain', 'fine-tune',
                      'reinforcement', 'diffusion', 'generative', 'large language',
                      'multimodal', 'prompt', 'alignment', 'efficient']
    title_lower = title.lower()
    title_matches = sum(1 for kw in title_keywords if kw in title_lower)
    score += min(title_matches * 5, 20)
    
    # 2. 摘要分析（40分）
    abstract_lower = abstract.lower()
    # 方法明确性
    method_indicators = ['propose', 'introduce', 'present', 'novel', 'method', 'approach']
    has_method = any(w in abstract_lower for w in method_indicators)
    if has_method: score += 10
    
    # 结果明确性
    result_indicators = ['achieve', 'improve', 'outperform', 'state-of-the-art', 'SOTA', 'demonstrate']
    has_results = any(w in abstract_lower for w in result_indicators)
    if has_results: score += 10
    
    # 技术深度
    tech_depth = sum(1 for w in ['theorem', 'proof', 'analysis', 'theoretical',
                                  'convergence', 'bound', 'complexity']
                     if w in abstract_lower)
    score += min(tech_depth * 3, 10)
    
    # 实用性
    practical = sum(1 for w in ['implement', 'open-source', 'dataset', 'benchmark',
                                'code', 'practical', 'application']
                    if w in abstract_lower)
    score += min(practical * 3, 10)
    
    # 3. 引用影响力（25分）— 需要 Semantic Scholar API
    if citations is not None:
        if citations['citation_count'] >= 50:
            score += 25
        elif citations['citation_count'] >= 20:
            score += 18
        elif citations['citation_count'] >= 10:
            score += 12
        elif citations['citation_count'] >= 5:
            score += 7
        elif citations['citation_count'] >= 1:
            score += 3
    
    # 4. 时效性（15分）
    if is_recent: score += 15
    
    return min(score, 100)


def interpret_score(score):
    """解释评分含义"""
    if score >= 80:
        return "★★★★★ 必读 — 高影响力，强相关"
    elif score >= 60:
        return "★★★★☆ 推荐 — 值得深入阅读"
    elif score >= 40:
        return "★★★☆☆ 参考 — 扫描摘要即可"
    elif score >= 20:
        return "★★☆☆☆ 略读 — 关注方法部分"
    else:
        return "★☆☆☆☆ 跳过 — 当前不相关"


# 使用示例
if __name__ == '__main__':
    papers = [
        {
            'title': 'Attention Is All You Need',
            'abstract': 'We propose a novel network architecture, the Transformer, \
based solely on attention mechanisms, dispensing with recurrence and convolutions \
entirely. Experiments on two machine translation tasks show these models to be \
superior in quality while being more parallelizable and requiring significantly \
less time to train.',
            'recent': True,
        },
        # 更多论文...
    ]
    
    for paper in papers:
        score = score_paper(paper['title'], paper['abstract'])
        rating = interpret_score(score)
        print(f"{paper['title']}")
        print(f"  评分: {score}/100 {rating}\n")
```

#### 引用链分析

```python
def build_citation_chain(paper_id, depth=2):
    """
    使用 Semantic Scholar API 构建论文引用链
    
    paper_id: Semantic Scholar 论文 ID 或 arXiv ID
    depth: 追踪深度（1=直接引用，2=两跳）
    """
    import requests, time
    
    base_url = "https://api.semanticscholar.org/graph/v1/paper"
    
    def get_citations(pid, fields='title,year,citationCount'):
        resp = requests.get(f"{base_url}/{pid}/citations", 
                          params={'fields': fields, 'limit': 20})
        if resp.status_code == 200:
            data = resp.json()
            return [c['citingPaper'] for c in data.get('data', [])
                   if c.get('citingPaper')]
        return []
    
    def get_references(pid):
        resp = requests.get(f"{base_url}/{pid}/references",
                          params={'fields': 'title,year,citationCount', 'limit': 20})
        if resp.status_code == 200:
            data = resp.json()
            return [r['citedPaper'] for r in data.get('data', [])
                   if r.get('citedPaper')]
        return []
    
    chain = {'paper': paper_id, 'citations': [], 'references': []}
    
    # 第一层：直接引用
    chain['citations'] = get_citations(paper_id)
    chain['references'] = get_references(paper_id)
    
    if depth > 1:
        # 第二层：引用的引用
        for cited in chain['citations'][:3]:
            sub = get_citations(cited['paperId'])
            cited['citations'] = sub
            time.sleep(1)  # API 限流
    
    return chain
```

---

### 2.3 知识沉淀到 LLM Wiki

#### 论文笔记自动化

```bash
#!/bin/bash
# add-paper-to-wiki.sh — 添加论文到 LLM Wiki

PAPER_TITLE="$1"
PAPER_URL="$2"
ABSTRACT="$3"
NOTES="$4"

WIKI_DIR="./wiki/papers"

mkdir -p "$WIKI_DIR"

# 根据论文标题生成文件名
FILENAME=$(echo "$PAPER_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILEPATH="$WIKI_DIR/$FILENAME.md"

# 写入笔记
cat > "$FILEPATH" << EOF
---
title: $PAPER_TITLE
url: $PAPER_URL
added: $(date +%Y-%m-%d)
tags:
  - paper
  - to-read
---

# $PAPER_TITLE

## 摘要
$ABSTRACT

## 我的笔记
$NOTES

## 关键见解

## 待办
- [ ] 深入阅读全文
- [ ] 提取关键方法
- [ ] 添加引用信息

## 相关论文
- [[TODO: 添加相关论文]]
EOF

echo "✅ 论文笔记已保存: $FILEPATH"
```

#### 自动引用提取

```python
#!/usr/bin/env python3
"""extract-bibtex.py — 从 PDF 中提取引用信息"""

import re
import requests
from typing import Optional, Dict

def extract_arxiv_id_from_url(url: str) -> Optional[str]:
    """从 URL 提取 arXiv ID"""
    match = re.search(r'arxiv\.org/(?:abs|pdf)/(\d+\.\d+)', url)
    if match:
        return match.group(1)
    return None

def fetch_bibtex_from_arxiv(arxiv_id: str) -> Optional[str]:
    """从 arXiv API 获取 BibTeX"""
    url = f"http://export.arxiv.org/api/query?id_list={arxiv_id}"
    try:
        resp = requests.get(url)
        if resp.status_code == 200:
            import xml.etree.ElementTree as ET
            root = ET.fromstring(resp.text)
            ns = {'a': 'http://www.w3.org/2005/Atom'}
            entry = root.find('a:entry', ns)
            if entry is not None:
                title = entry.find('a:title', ns).text.strip().replace('\n', ' ').strip()
                authors = []
                for author in entry.findall('a:author', ns):
                    name = author.find('a:name', ns).text
                    # 转换为 BibTeX 格式: Last, First
                    parts = name.split()
                    if len(parts) >= 2:
                        authors.append(f"{parts[-1]}, {' '.join(parts[:-1])}")
                    else:
                        authors.append(name)
                
                year = entry.find('a:published', ns).text[:4]
                # 生成 BibTeX 键
                first_author_last = authors[0].split(',')[0] if authors else 'Unknown'
                bib_key = f"{first_author_last.lower()}{year}"
                
                bibtex = f"""@misc{{{bib_key},
  author = {{{' and '.join(authors)}}},
  title = {{{title}}},
  year = {{{year}}},
  eprint = {{{arxiv_id}}},
  archivePrefix = {{arXiv}},
  primaryClass = {{cs.AI}}
}}"""
                return bibtex
    except Exception as e:
        print(f"获取 BibTeX 失败: {e}")
    return None


# 使用示例
if __name__ == '__main__':
    url = "https://arxiv.org/abs/1706.03762"
    arxiv_id = extract_arxiv_id_from_url(url)
    if arxiv_id:
        bib = fetch_bibtex_from_arxiv(arxiv_id)
        if bib:
            print(bib)
```

---

### 2.4 完整自动化流水线

```bash
#!/bin/bash
# full-pipeline.sh — 端到端研究流水线

echo "🚀 启动研究流水线"

# 阶段 1: 发现
echo ""
echo "📡 阶段 1/4: 论文发现"
./daily-research.sh

# 阶段 2: 筛选
echo ""
echo "🔎 阶段 2/4: 论文筛选"
python3 paper-scorer.py

# 阶段 3: 获取
echo ""
echo "📥 阶段 3/4: 下载与笔记"
# 下载评分高的论文 PDF
python3 << 'PYEOF'
import urllib.request
# 示例：下载 arXiv 论文
arxiv_id = "1706.03762"
url = f"https://arxiv.org/pdf/{arxiv_id}.pdf"
urllib.request.urlretrieve(url, f"papers/{arxiv_id}.pdf")
print(f"  ✅ 下载完毕: papers/{arxiv_id}.pdf")
PYEOF

# 阶段 4: 沉淀
echo ""
echo "📚 阶段 4/4: 知识入库"
# 将论文添加到 LLM Wiki
# ./add-paper-to-wiki.sh "论文标题" "URL" "摘要" "笔记"

echo ""
echo "✅ 流水线执行完毕"
```

---

## 三、每周研究回顾模板

```markdown
# 研究周报: 2026-W##

## 📥 本周新发现
- 
- 
- 

## 📖 已阅读
- [ ] 

## 🔖 值得深入
- 
- 

## 📝 知识库更新
- 
- 

## 🎯 下周计划
1. 
2. 
3. 

## 💡 零散想法
- 
- 
```

---

## 四、工具协同矩阵

| 任务 | arXiv | Semantic Scholar | blogwatcher | yt-content | LLM Wiki | 最佳组合 |
|------|-------|-----------------|-------------|------------|----------|----------|
| 发现新论文 | ✅ | ❌ | ✅ | ✅ | ❌ | arXiv + YouTube |
| 评估影响力 | ❌ | ✅ | ❌ | ❌ | ❌ | Semantic Scholar |
| 跟踪作者 | ✅ | ✅ | ❌ | ✅ | ❌ | 所有来源 |
| 管理文献库 | ❌ | ❌ | ❌ | ❌ | ✅ | LLM Wiki |
| 生成引用 | ✅ | ✅ | ❌ | ❌ | ✅ | arXiv → BibTeX |
| 写作输出 | ❌ | ❌ | ❌ | ❌ | ✅ | Wiki → 博客 |

---

## 五、最佳实践与注意事项

### 效率建议

1. **批量优于单次**：不要每次只处理一篇论文，批量获取和评估效率更高
2. **自动化日常检查**：设置 cron 任务每天自动扫描 arXiv 和博客
3. **用评分代替直觉**：制定评分标准，减少决策疲劳
4. **知识要可复用**：所有笔记直接写入结构化格式（Markdown），避免复制粘贴
5. **建立回链**：在 LLM Wiki 中使用 `[[wikilinks]]` 建立论文间关联

### 常见陷阱

1. **信息过载**：订阅太多来源会导致永远读不完，定期清理不相关的订阅
2. **收藏等于读了**：标记为"待读"的论文每周清理一次，超过一个月未读的果断删除
3. **忽视非论文来源**：技术博客、YouTube 演讲、开源项目往往比论文更有实践价值
4. **不做二次整理**：原始笔记需要经过提炼才能成为长期记忆

### Cron 设置示例

```bash
# crontab -e
# 每天早上 8 点检查 arXiv 新论文
0 8 * * * /home/user/scripts/daily-research.sh >> /home/user/logs/research.log 2>&1

# 每周一检查博客更新
0 9 * * 1 blogwatcher update && blogwatcher list --unread

# 每月清理未读论文
0 10 1 * * /home/user/scripts/cleanup-papers.sh
```

---

## 六、扩展阅读

- [[01-arxiv-paper-search]] — arXiv 论文搜索与引用分析
- [[02-blog-monitoring]] — 博客与 RSS 监控
- [[03-llm-wiki-knowledge-base]] — LLM Wiki 知识库构建
- [[04-youtube-content]] — YouTube 字幕获取与内容结构化
