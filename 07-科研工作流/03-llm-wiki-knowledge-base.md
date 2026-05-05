---
date: 2026-05-05
tags:
  - llm-wiki
  - knowledge-base
  - knowledge-management
  - karpathy
  - obsidian
  - 科研工作流
source_skill: llm-wiki
category: 科研工作流
---

# LLM Wiki 知识库构建

> 本文档基于 Andrej Karpathy 提出的 LLM Wiki 模式，结合 Hermes Agent 的 `llm-wiki` 技能整理。覆盖从知识摄入、查询检索到质量维护的完整流程。

## 概述

LLM Wiki 是一种**持久化的、相互链接的 Markdown 知识库**。它由 Andrej Karpathy 提出，核心理念是：

> 不要每次从零查找，而是把知识编译好、链接好、维护好——像 Wikipedia 一样，但由 AI Agent 帮你打理。

### 与传统 RAG 的区别

| 特性 | RAG（检索增强生成） | LLM Wiki |
|------|---------------------|----------|
| 工作方式 | 每次查询都从头检索+生成 | 知识已编译，直接查找 |
| 一致性 | 每次结果可能不同 | 一致且可复现 |
| 交叉引用 | 不存在 | `[[wikilinks]]` 双向链接 |
| 矛盾处理 | 无感知 | 显式标记，人工裁决 |
| 知识积累 | 无 | 持续增长，相互引用 |
| 维护成本 | 低（但不可靠） | 中等（但越用越值钱） |

---

## 三层架构

LLM Wiki 分为三个层次，由 AI Agent 管理，人只需提供源材料并做方向性指导：

```
wiki/
├── SCHEMA.md           # 约定：结构规则、标签体系
├── index.md            # 目录：所有页面列表 + 一句话摘要
├── log.md              # 日志：所有操作的时序记录
├── raw/                # 第一层：不可变的原始材料
│   ├── articles/       # 网页文章、剪报
│   ├── papers/         # PDF、arXiv 论文
│   ├── transcripts/    # 会议记录、访谈
│   └── assets/         # 图片、图表
├── entities/           # 第二层：实体页面（人物、组织、产品、模型）
├── concepts/           # 第二层：概念/主题页面
├── comparisons/        # 第二层：对比分析页面
└── queries/            # 第二层：值得保留的查询结果
```

### 第一层：原始材料（raw/）

**不可变的**。Agent 会读取但永远不会修改这些文件。相当于你的"引用列表"。

```markdown
# raw/papers/attention-is-all-you-need.md
# 由 Agent 保存，永不修改。你的原始参考。
```

### 第二层：Wiki 页面（entities/、concepts/、comparisons/、queries/）

**Agent 可写的**。Agent 在这里创建、更新和交叉引用页面。

- **entities/** — 实体页面。一页一个实体（人物、组织、产品、模型）
- **concepts/** — 概念页面。一页一个概念或主题
- **comparisons/** — 对比分析。逐维度比较的页面
- **queries/** — 查询结果。值得再次使用的深度查询结果

### 第三层：元数据（SCHEMA.md、index.md、log.md）

**导航和约定的骨架**。

---

## 初始化一个新的 Wiki

### Step 1：创建目录结构

```bash
WIKI_PATH="${WIKI_PATH:-$HOME/wiki}"
mkdir -p "$WIKI_PATH"/{raw/{articles,papers,transcripts,assets},entities,concepts,comparisons,queries}
```

### Step 2：编写 SCHEMA.md

这是 Wiki 的"宪法"，定义了所有约定：

```markdown
# Wiki Schema

## 领域
机器学习 / LLM 研究知识库

## 约定
- 文件名：小写、连字符、无空格（如 `transformer-architecture.md`）
- 每个页面以 YAML frontmatter 开头
- 使用 `[[wikilinks]]` 链接到其他页面（每页至少 2 个链接）
- 更新页面时始终更新 frontmatter 中的 `updated` 日期
- 新页面必须加入 `index.md`
- 所有操作必须记录到 `log.md`

## Frontmatter 模板
---
title: 页面标题
created: 2026-05-05
updated: 2026-05-05
type: entity | concept | comparison | query | summary
tags: [model, architecture, benchmark]
sources: [raw/articles/source-name.md]
---

## 标签分类
- 模型类: model, architecture, benchmark, training, inference
- 人物/组织: person, company, lab, open-source
- 技术类: optimization, fine-tuning, alignment, data, evaluation
- 元类: comparison, timeline, controversy, prediction

规则：页面上所有标签必须来自此分类。添加新标签前先在此添加。

## 页面创建阈值
- 当一个实体/概念在 2 个以上来源中出现时 → 创建页面
- 当来源提到已有内容时 → 更新现有页面
- 不要为一次性提及创建页面
- 页面超过 200 行时 → 拆分为子主题
```

### Step 3：编写初始 index.md

```markdown
# Wiki Index

> 内容目录。每个 Wiki 页面按类型列出，附一句话摘要。
> 查询前先读此页，快速定位相关内容。
> 最后更新：2026-05-05 | 总页面数：3

## Entities
- [[openai]] — OpenAI 组织与产品线

## Concepts
- [[transformer-architecture]] — Transformer 模型架构详解
- [[reinforcement-learning-from-human-feedback]] — RLHF 对齐技术

## Comparisons
（暂无）

## Queries
（暂无）
```

### Step 4：编写初始 log.md

```markdown
# Wiki Log

> 所有 Wiki 操作的时序记录。只追加不修改。
> 格式：## [YYYY-MM-DD] 操作 | 主题
> 操作：ingest（摄入）, update（更新）, query（查询）, lint（检查）, 
>        create（创建）, archive（归档）, delete（删除）

## [2026-05-05] create | Wiki 初始化
- 领域：机器学习 / LLM 研究
- 创建目录结构：raw/, entities/, concepts/, comparisons/, queries/
- 编写 SCHEMA.md, index.md, log.md
```

---

## 核心操作一：知识摄入（Ingest）

摄入是知识库增长的驱动力。当你发现一篇好论文、一篇优质博客或一条有价值的推文时，把它"吃进"知识库。

### 完整摄入流程

```python
"""
ingest_source.py — 知识摄入脚本

将一个来源摄入到 LLM Wiki 中。
"""
import os
import sys
import json
from datetime import datetime

WIKI_PATH = os.environ.get("WIKI_PATH", os.path.expanduser("~/wiki"))

def ingest_article(title, url, content):
    """将一篇网页文章摄入到 Wiki"""
    date_str = datetime.now().strftime("%Y-%m-%d")
    filename = title.lower().replace(" ", "-")[:50] + ".md"
    # 过滤不可用于文件名的字符
    filename = "".join(c if c.isalnum() or c in "-_" else "-" for c in filename)

    # 1. 保存原始材料
    raw_path = os.path.join(WIKI_PATH, "raw/articles")
    os.makedirs(raw_path, exist_ok=True)
    raw_file = os.path.join(raw_path, filename)

    with open(raw_file, "w", encoding="utf-8") as f:
        f.write(f"""---
title: {title}
url: {url}
date: {date_str}
type: raw
---

来源：{url}

{content}
""")

    print(f"📄 原始材料已保存：{raw_file}")
    return raw_file

def create_entity_page(entity_name, summary, tags, source_file):
    """创建一个实体页面"""
    date_str = datetime.now().strftime("%Y-%m-%d")
    filename = entity_name.lower().replace(" ", "-") + ".md"
    filename = "".join(c if c.isalnum() or c in "-_" else "-" for c in filename)

    page_path = os.path.join(WIKI_PATH, "entities", filename)
    tags_str = ", ".join(tags)

    with open(page_path, "w", encoding="utf-8") as f:
        f.write(f"""---
title: {entity_name}
created: {date_str}
updated: {date_str}
type: entity
tags: [{tags_str}]
sources: [{os.path.relpath(source_file, WIKI_PATH)}]
---

# {entity_name}

## 概述
{summary}

## 关键信息
- 类别：{[t for t in tags if t in ['person', 'company', 'lab', 'product', 'model']]}

## 相关实体
- 待补充

## 来源
- {os.path.relpath(source_file, WIKI_PATH)}
""")

    print(f"🏷️  创建实体页面：{page_path}")
    return page_path

def update_index(page_path, category, summary):
    """在 index.md 中添加条目"""
    index_path = os.path.join(WIKI_PATH, "index.md")

    page_name = os.path.splitext(os.path.basename(page_path))[0]
    category_headers = {
        "entity": "## Entities",
        "concept": "## Concepts",
        "comparison": "## Comparisons",
        "query": "## Queries"
    }

    section_header = category_headers.get(category, "## Other")
    new_entry = f"- [[{page_name}]] — {summary}\n"

    with open(index_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 在对应分类下追加
    if section_header in content:
        # 找到分类标题，在后面添加
        lines = content.split("\n")
        for i, line in enumerate(lines):
            if line.strip() == section_header:
                # 找到该分类的末尾（下一个标题或文件结尾）
                j = i + 1
                while j < len(lines) and not lines[j].startswith("## "):
                    j += 1
                lines.insert(j, new_entry.rstrip())
                break
        content = "\n".join(lines)
    else:
        content += f"\n{section_header}\n{new_entry}"

    with open(index_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"📑 已更新 index.md：添加 {page_name}")

def append_log(action, subject, details):
    """在 log.md 中追加操作记录"""
    log_path = os.path.join(WIKI_PATH, "log.md")
    date_str = datetime.now().strftime("%Y-%m-%d %H:%M")
    entry = f"\n## [{date_str}] {action} | {subject}\n"

    for key, val in details.items():
        entry += f"- {key}: {val}\n"

    with open(log_path, "a", encoding="utf-8") as f:
        f.write(entry)

# 使用示例
if __name__ == "__main__":
    title = "GPT-4 Technical Report"
    url = "https://arxiv.org/abs/2303.08774"
    content = "We report the development of GPT-4..."

    raw_file = ingest_article(title, url, content)
    entity_file = create_entity_page(
        "GPT-4",
        "OpenAI 发布的大语言模型，支持多模态输入",
        ["model", "openai", "llm"],
        raw_file
    )
    update_index(entity_file, "entity", "OpenAI 第四代大语言模型，支持文本和图像输入")
    append_log("ingest", "GPT-4 Technical Report", {
        "files": [raw_file, entity_file],
        "tags": "model, openai, llm"
    })
```

### 手动摄入流程

如果不想写脚本，也可以手动操作：

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"

# 1. 用 web_extract 获取文章内容并保存
web_extract "https://arxiv.org/abs/2303.08774" \
  > "$WIKI/raw/articles/gpt-4-technical-report.md"

# 2. 创建实体或概念页面
# （用编辑器或模板创建）

# 3. 更新 index.md
# （手动或使用 find 检查新页面）

# 4. 记录到 log.md
echo "## [$(date '+%Y-%m-%d %H:%M')] ingest | GPT-4 Technical Report" \
  >> "$WIKI/log.md"
```

---

## 核心操作二：查询（Query）

当你想向知识库提问时，流程如下：

### 查询流程

```bash
WIKI="${WIKI_PATH:-$HOME/wiki}"

# 1. 先读 index.md 了解有什么
read_file "$WIKI/index.md"

# 2. 搜索所有页面中的相关内容
search_files "transformer" path="$WIKI" file_glob="*.md"

# 3. 读取相关页面
read_file "$WIKI/entities/transformer-architecture.md"

# 4. 综合回答
```

### Python 查询助手

```python
"""
query_wiki.py — Wiki 查询助手
"""
import os
import re

WIKI_PATH = os.environ.get("WIKI_PATH", os.path.expanduser("~/wiki"))

def search_wiki(query):
    """在 Wiki 中搜索内容"""
    results = []

    for root, dirs, files in os.walk(WIKI_PATH):
        # 跳过 raw/ 目录（只搜 Wiki 页面，不搜原始材料）
        if "/raw/" in root:
            continue

        for f in files:
            if not f.endswith(".md"):
                continue

            filepath = os.path.join(root, f)
            with open(filepath, "r", encoding="utf-8") as file:
                content = file.read()

            matches = []
            for line_no, line in enumerate(content.split("\n"), 1):
                if query.lower() in line.lower():
                    matches.append((line_no, line.strip()))

            if matches:
                rel_path = os.path.relpath(filepath, WIKI_PATH)
                results.append({
                    "path": rel_path,
                    "matches": matches[:5]  # 只保留前 5 行
                })

    return results

def format_results(results):
    """格式化搜索结果"""
    if not results:
        return "😴 未找到相关内容。"

    output = f"🔍 在 {len(results)} 个页面中找到匹配项：\n\n"
    for r in results:
        output += f"📄 {r['path']}\n"
        for line_no, line in r["matches"]:
            output += f"  L{line_no}: {line[:80]}...\n"
        output += "\n"

    return output

# 使用示例
result = search_wiki("attention mechanism")
print(format_results(result))
```

### 将查询结果归档

如果某次查询生成了有价值的综合分析，应该保存下来：

```bash
# 创建一个查询结果页面
cat > "$WIKI/queries/attention-mechanism-evolution.md" << 'QUERY'
---
title: 注意力机制演变综述
created: 2026-05-05
updated: 2026-05-05
type: query
tags: [architecture, attention, transformer]
sources: [entities/transformer-architecture.md, concepts/attention-is-all-you-need.md]
---

# 查询：注意力机制的演变

## 原始查询
"Attention mechanism 从 Bahdanau Attention 到 Multi-Query Attention 的演变路径"

## 综合发现
待整理...

## 相关页面
- [[transformer-architecture]]
- [[multi-head-attention]]
QUERY
```

---

## 核心操作三：维护（Lint）

定期维护可以防止知识库变得混乱和过时。

### 完整质量检查脚本

```python
"""
lint_wiki.py — Wiki 质量检查脚本
"""
import os
import re
from datetime import datetime, timedelta
from collections import defaultdict

WIKI_PATH = os.environ.get("WIKI_PATH", os.path.expanduser("~/wiki"))

def get_all_pages():
    """获取所有 Wiki 页面（不包括 raw/ 和 index/log）"""
    pages = []
    skip_dirs = {"raw", "_archive"}
    skip_files = {"index.md", "log.md", "SCHEMA.md"}

    for root, dirs, files in os.walk(WIKI_PATH):
        # 跳过特定目录
        rel = os.path.relpath(root, WIKI_PATH)
        if any(s in rel.split(os.sep) for s in skip_dirs):
            continue

        for f in files:
            if f in skip_files or not f.endswith(".md"):
                continue
            pages.append(os.path.join(root, f))

    return pages

def check_wikilinks(pages):
    """检查内部链接是否有效"""
    all_link_names = set()
    name_to_path = {}

    for p in pages:
        name = os.path.splitext(os.path.basename(p))[0]
        all_link_names.add(name)
        name_to_path[name] = p

    issues = []
    for p in pages:
        with open(p, "r", encoding="utf-8") as f:
            content = f.read()

        links = re.findall(r'\[\[([^\]]+)\]\]', content)
        for link in links:
            if link not in all_link_names:
                rel_path = os.path.relpath(p, WIKI_PATH)
                issues.append(f"🔗 断链：{rel_path} -> [[{link}]]")

    return issues

def check_inbound_links(pages):
    """检查孤立页面（没有入站链接的页面）"""
    inbound = defaultdict(int)

    for p in pages:
        with open(p, "r", encoding="utf-8") as f:
            content = f.read()

        links = re.findall(r'\[\[([^\]]+)\]\]', content)
        for link in links:
            inbound[link] += 1

    orphans = []
    for p in pages:
        name = os.path.splitext(os.path.basename(p))[0]
        if inbound[name] == 0:
            rel_path = os.path.relpath(p, WIKI_PATH)
            orphans.append(f"👤 孤立页面：{rel_path}（没有其他页面链接到这里）")

    return orphans

def check_stale_pages(pages):
    """检查超过 90 天未更新的页面"""
    old_threshold = datetime.now() - timedelta(days=90)
    stale = []

    for p in pages:
        with open(p, "r", encoding="utf-8") as f:
            content = f.read()

        # 从 frontmatter 中提取 updated 日期
        match = re.search(r'updated:\s*(\d{4}-\d{2}-\d{2})', content)
        if match:
            updated = datetime.strptime(match.group(1), "%Y-%m-%d")
            if updated < old_threshold:
                rel_path = os.path.relpath(p, WIKI_PATH)
                days_ago = (datetime.now() - updated).days
                stale.append(f"⏰ 内容过时：{rel_path}（{days_ago} 天未更新）")

    return stale

def check_frontmatter(pages):
    """检查 frontmatter 完整性"""
    required_fields = {"title", "created", "updated", "type", "tags", "sources"}
    issues = []

    for p in pages:
        with open(p, "r", encoding="utf-8") as f:
            content = f.read()

        # 尝试提取 frontmatter（--- 之间的部分）
        match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
        if not match:
            rel_path = os.path.relpath(p, WIKI_PATH)
            issues.append(f"⚠️ 缺少 frontmatter：{rel_path}")
            continue

        front = match.group(1)
        for field in required_fields:
            if field not in front:
                rel_path = os.path.relpath(p, WIKI_PATH)
                issues.append(f"⚠️ 缺少字段 {field}：{rel_path}")

    return issues

def check_page_size(pages):
    """检查超过 200 行的页面——考虑拆分"""
    oversized = []
    for p in pages:
        with open(p, "r", encoding="utf-8") as f:
            lines = f.readlines()
        if len(lines) > 200:
            rel_path = os.path.relpath(p, WIKI_PATH)
            oversized.append(f"📏 页面过长：{rel_path}（{len(lines)} 行，建议拆分）")

    return oversized

def run_full_lint():
    """运行完整质量检查"""
    print("🔍 正在运行 Wiki 质量检查...\n")

    pages = get_all_pages()
    print(f"📊 检查 {len(pages)} 个页面\n")

    all_issues = {
        "断链": check_wikilinks(pages),
        "孤立页面": check_inbound_links(pages),
        "内容过时": check_stale_pages(pages),
        "Frontmatter 问题": check_frontmatter(pages),
        "页面过长": check_page_size(pages),
    }

    total = sum(len(v) for v in all_issues.values())

    if total == 0:
        print("✅ Wiki 状态良好！未发现任何问题。")
    else:
        print(f"发现 {total} 个问题：\n")
        for category, issues in all_issues.items():
            if issues:
                print(f"=== {category}（{len(issues)} 个）===")
                for issue in issues:
                    print(f"  {issue}")
                print()
            else:
                print(f"✅ {category}：无问题")

    return all_issues

if __name__ == "__main__":
    run_full_lint()
```

### 手动快速检查

```bash
# 简化的命令行检查
WIKI="${WIKI_PATH:-$HOME/wiki}"

# 1. 检查孤立页面
echo "=== 可能存在孤立页面的文件 ==="
for f in "$WIKI"/entities/*.md "$WIKI"/concepts/*.md; do
    name=$(basename "$f" .md)
    count=$(grep -r "\[\[$name\]\]" "$WIKI"/entities/ "$WIKI"/concepts/ "$WIKI"/comparisons/ | grep -v "$f" | wc -l)
    if [ "$count" -eq 0 ]; then
        echo "  👤 $name.md（无入链）"
    fi
done

# 2. 检查断链
echo "=== 断链检查 ==="
grep -roh '\[\[[^]]*\]\]' "$WIKI"/entities/ "$WIKI"/concepts/ "$WIKI"/comparisons/ | \
  sed 's/\[\[//;s/\]\]//' | sort -u | while read -r link; do
    if [ ! -f "$WIKI/entities/$link.md" ] && [ ! -f "$WIKI/concepts/$link.md" ] && \
       [ ! -f "$WIKI/comparisons/$link.md" ] && [ ! -f "$WIKI/queries/$link.md" ]; then
        echo "  🔗 [[$link]] → 页面不存在"
    fi
done

# 3. 检查大文件
echo "=== 大文件检查 ==="
find "$WIKI" -name "*.md" -not -path "*/raw/*" | while read -r f; do
    lines=$(wc -l < "$f")
    if [ "$lines" -gt 200 ]; then
        echo "  📏 $(basename $f) — ${lines} 行"
    fi
done
```

---

## Obsidian 集成

LLM Wiki 的目录结构天然兼容 Obsidian：

```bash
# 将 wiki 目录设为 Obsidian 仓库
# 在 Obsidian 中：Manage Vaults → Open folder as vault → 选择 ~/wiki
```

Obsidian 提供的额外能力：

| 功能 | 说明 |
|------|------|
| `[[wikilinks]]` | 可点击的双向链接（和 Wiki 内部完全一致） |
| Graph View | 可视化知识网络图 |
| Dataview 插件 | 用 SQL 风格的查询检索页面 |
| 快速搜索 | `Ctrl+P` 搜索所有页面 |
| 标签面板 | 按标签分类浏览 |

### 自动同步（远程机器 → Obsidian）

如果你在服务器上运行 Agent 写 Wiki，在本机用 Obsidian 阅读：

```bash
# 安装 obsidian-headless（需要 Node.js 22+）
npm install -g obsidian-headless

# 登录 Obsidian 账号（需要 Obsidian Sync 订阅）
ob login --email your@email.com --password 'your-password'

# 创建远程仓库
ob sync-create-remote --name "LLM Wiki"

# 连接本地 Wiki 目录
cd ~/wiki
ob sync-setup --vault "your-vault-id"

# 同步
ob sync

# 持续同步（适合用 systemd 管理）
ob sync --continuous
```

---

## 最佳实践

### DO

1. **先读 index.md** — 每次开始工作前扫一眼目录，知道有什么
2. **每页至少 2 个 `[[wikilinks]]`** — 知识孤岛是最差的
3. **按阈值创建页面** — 一个概念出现 2 次以上才开新页面
4. **记录每件事** — log.md 是你找回上下文的救命稻草
5. **定期 Lint** — 每周跑一次质量检查

### DON'T

1. **不要修改 raw/** — 原始材料不可变
2. **不要创建单次提及的页面** — 会变成知识垃圾
3. **不要跳过 log.md** — 否则历史丢失
4. **不要孤立页面** — 没入链的页面等于不存在
5. **不要忽略过时内容** — 标注旧信息比不标注更糟糕

---

## 总结

```
知识摄入 (Ingest) ──→ raw/（保存原始材料）
     │
     ├── 新实体/概念 → entities/ 或 concepts/（创建页面）
     ├── 已有内容    → 更新对应页面 + 交叉引用
     └── 重要对比   → comparisons/（创建对比页）
     │
     ↓
更新 index.md + log.md
     │
     ↓
查询时：index.md → 相关页面 → 综合回答
     │
     ↓
定期 Lint：断链、孤立、过时、超大页面
```

Karpathy 的 LLM Wiki 模式最强大的地方在于：它是**复利式增长**的。今天摄入一篇文章可能需要更新 5 个页面，但三个月后你查同一个主题时，所有信息已经在那等着你了。不是从一个模糊的需求开始检索，而是从已经组织好的知识中直接提取。
