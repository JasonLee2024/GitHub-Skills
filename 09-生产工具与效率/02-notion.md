---
date: 2026-05-05
tags:
  - notion
  - api
  - database
  - page-management
  - productivity
  - 生产工具与效率
source_skill: notion
category: 生产工具与效率
---

# Notion API 管理：页面与数据库

> 本文档基于 Hermes Agent 的 `notion` 技能整理，涵盖 Notion API 集成、页面管理、数据库操作和自动化工作流。

## 概述

Notion 是一款集笔记、文档、数据库和项目管理于一体的协作平台。通过 Hermes Agent 的 `notion` 技能，开发者可以程序化地创建、读取、更新和删除 Notion 页面和数据库记录。

### 核心能力

| 功能 | 说明 | 适用场景 |
|------|------|---------|
| 页面管理 | 创建、读取、更新、搜索页面 | 自动生成文档、周报 |
| 数据库操作 | 查询、创建、更新、排序数据 | 任务追踪、CRM 管理 |
| 块操作 | 操作页面内的内容块 | 内容编辑、模板填充 |
| 附件上传 | 上传图片和文件 | 资源管理 |
| 搜索 | 全文搜索工作区 | 信息检索 |

---

## 前置准备

### 1. 创建 Notion 集成

```bash
# 1. 访问 https://www.notion.so/my-integrations
# 2. 点击"新建集成"
# 3. 选择工作区，命名（如 "Hermes Agent"）
# 4. 获取 Internal Integration Secret（以 ntn_ 开头）
```

### 2. 配置环境

```bash
export NOTION_TOKEN="ntn_xxxxxxxxxxxxxxxxxxxx"
export NOTION_PAGE_ID="your-page-id"
```

### 3. 安装 SDK

```bash
pip install notion-client
```

### 4. 共享页面给集成

在 Notion 页面右上角 → 点击「Share」→ 添加你的集成名称 → 确认。

---

## 页面管理

### 创建页面

```python
from notion_client import Client

notion = Client(auth="ntn_xxxxxxxxxxxx")

def create_page(parent_page_id, title, content_blocks=None):
    """在父页面下创建新页面"""
    properties = {
        "title": {
            "title": [{"type": "text", "text": {"content": title}}]
        }
    }
    
    children = content_blocks or []
    
    page = notion.pages.create(
        parent={"page_id": parent_page_id},
        properties=properties,
        children=children
    )
    
    print(f"📄 页面已创建: {page['url']}")
    return page

# 使用示例
new_page = create_page(
    parent_page_id="your-parent-page-id",
    title="2024-05-05 日报",
    content_blocks=[
        {
            "heading_2": {
                "rich_text": [{"text": {"content": "今日完成"}}]
            }
        },
        {
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "完成 PR #42 代码审查"}}]
            }
        },
        {
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "修复了登录页面的 CSS 问题"}}]
            }
        },
        {
            "divider": {}
        }
    ]
)
```

### 读取页面

```python
def get_page_content(page_id):
    """读取页面所有内容块"""
    page = notion.pages.retrieve(page_id)
    title = page['properties']['title']['title'][0]['text']['content']
    print(f"📖 页面: {title}")
    
    # 获取子块
    blocks = notion.blocks.children.list(page_id)
    for block in blocks['results']:
        block_type = block['type']
        if block_type == 'paragraph':
            texts = block['paragraph']['rich_text']
            for t in texts:
                print(f"  {t['text']['content']}")
        elif block_type == 'heading_2':
            texts = block['heading_2']['rich_text']
            for t in texts:
                print(f"  ## {t['text']['content']}")
```

### 更新页面

```python
def update_page_properties(page_id, properties):
    """更新页面属性"""
    notion.pages.update(page_id=page_id, **properties)
    print(f"✅ 页面已更新")

# 添加封面
update_page_properties(page_id, {
    "cover": {
        "type": "external",
        "external": {"url": "https://example.com/cover.png"}
    }
})
```

---

## 数据库操作

### Notion 数据库基础

Notion 数据库类似于电子表格，每一条记录是一个页面，拥有预定义的属性（列）。

常见属性类型：

| 属性类型 | 说明 | Python 写入格式 |
|----------|------|----------------|
| title | 标题 | `{"title": [{"text": {"content": "标题"}}]}` |
| rich_text | 富文本 | `{"rich_text": [{"text": {"content": "内容"}}]}` |
| number | 数字 | `{"number": 42}` |
| select | 单选 | `{"select": {"name": "选项A"}}` |
| multi_select | 多选 | `{"multi_select": [{"name": "标签1"}]}` |
| date | 日期 | `{"date": {"start": "2024-01-01"}}` |
| checkbox | 勾选 | `{"checkbox": True}` |
| url | URL | `{"url": "https://example.com"}` |
| email | 邮箱 | `{"email": "test@example.com"}` |
| status | 状态 | `{"status": {"name": "进行中"}}` |

### 查询数据库

```python
def query_database(database_id, filter_params=None, sorts=None):
    """查询 Notion 数据库"""
    query_params = {"database_id": database_id}
    
    if filter_params:
        query_params["filter"] = filter_params
    if sorts:
        query_params["sorts"] = sorts
    
    results = notion.databases.query(**query_params)
    
    for page in results['results']:
        props = page['properties']
        title = props.get('Name', {}).get('title', [{}])[0].get('text', {}).get('content', '')
        status = props.get('Status', {}).get('status', {}).get('name', '')
        print(f"  📌 {title} [{status}]")
    
    return results

# 查询示例：未完成的任务，按优先级排序
query_database(
    database_id="your-db-id",
    filter_params={
        "property": "Status",
        "status": {"does_not_equal": "完成"}
    },
    sorts=[{"property": "优先级", "direction": "descending"}]
)
```

### 创建数据库条目

```python
def create_database_item(database_id, properties):
    """在数据库中创建新条目"""
    page = notion.pages.create(
        parent={"database_id": database_id},
        properties=properties
    )
    print(f"✅ 条目已创建: {page['url']}")
    return page

# 使用示例
create_database_item(
    database_id="your-task-db-id",
    properties={
        "Name": {
            "title": [{"text": {"content": "升级 Node.js 版本"}}]
        },
        "Status": {
            "status": {"name": "进行中"}
        },
        "优先级": {
            "select": {"name": "高"}
        },
        "截止日期": {
            "date": {"start": "2024-05-10"}
        },
        "负责人": {
            "rich_text": [{"text": {"content": "张三"}}]
        }
    }
)
```

---

## 块（Block）操作

### 支持的块类型

| 块类型 | Python key | 说明 |
|--------|-----------|------|
| 段落 | `paragraph` | 普通文本 |
| 标题1 | `heading_1` | 一级标题 |
| 标题2 | `heading_2` | 二级标题 |
| 标题3 | `heading_3` | 三级标题 |
| 无序列表 | `bulleted_list_item` | 项目符号列表 |
| 有序列表 | `numbered_list_item` | 编号列表 |
| 待办事项 | `to_do` | 勾选框 |
| 引用 | `quote` | 块引用 |
| 代码块 | `code` | 代码块 |
| 分割线 | `divider` | 水平线 |
| 图片 | `image` | 图片嵌入 |

### 追加内容块

```python
def append_blocks(page_id, blocks):
    """向页面追加内容块"""
    notion.blocks.children.append(
        block_id=page_id,
        children=blocks
    )
    print(f"✅ 已追加 {len(blocks)} 个内容块")

# 追加代码块
append_blocks(page_id, [
    {
        "code": {
            "rich_text": [{"text": {"content": "print('Hello Notion!')"}}],
            "language": "python"
        }
    },
    {
        "to_do": {
            "rich_text": [{"text": {"content": "完成代码审查"}}],
            "checked": False
        }
    }
])
```

---

## 综合自动化脚本

### 日报自动生成

```python
# daily_report.py
import datetime
from notion_client import Client

notion = Client(auth="YOUR_TOKEN")

def generate_daily_report():
    today = datetime.date.today()
    db_id = "your-database-id"
    
    # 查询今天完成的条目
    results = notion.databases.query(
        database_id=db_id,
        filter={
            "and": [
                {"property": "完成日期", "date": {"equals": today.isoformat()}},
                {"property": "类型", "select": {"equals": "任务"}}
            ]
        }
    ).get("results", [])
    
    # 生成日报页面
    content_blocks = [
        {"heading_2": {"rich_text": [{"text": {"content": f"日报 {today}"}}]}},
        {"paragraph": {"rich_text": [{"text": {"content": f"今日完成 {len(results)} 项任务"}}]}},
        {"divider": {}},
    ]
    
    for r in results:
        name = r['properties']['Name']['title'][0]['text']['content']
        content_blocks.append({
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": name}}]
            }
        })
    
    # 创建日报页面
    notion.pages.create(
        parent={"database_id": "daily-report-db-id"},
        properties={
            "标题": {"title": [{"text": {"content": f"日报 - {today}"}}]},
            "日期": {"date": {"start": today.isoformat()}}
        },
        children=content_blocks
    )
    print(f"✅ 日报已生成 - {today}")

if __name__ == "__main__":
    generate_daily_report()
```

---

## 最佳实践

1. **速率限制** — Notion API 有 3 req/sec 限制，批量操作时注意控制频率
2. **幂等性** — 创建操作可能重复，使用 UUID 去重
3. **分页处理** — 查询结果默认 100 条，需处理 start_cursor 分页
4. **缓存属性 ID** — 数据库属性 ID 不变，缓存可减少查询
5. **块嵌套限制** — 块嵌套最大深度为 3 层

---

## 相关技能

- [[01-google-workspace]] — Google Workspace 集成
- [[03-linear]] — Linear 项目管理
- [[06-email-management]] — 邮件管理（himalaya）
