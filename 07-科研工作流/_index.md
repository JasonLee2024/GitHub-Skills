# 07 — 科研工作流

## 本章节内容

学术研究全流程自动化：论文搜索 → 引用分析 → 知识沉淀。

| 文档 | 内容 | 技能来源 |
|------|------|---------|
| [[01-arxiv-paper-search]] | arXiv API + Semantic Scholar 引用链 | `arxiv` |
| [[02-blog-monitoring]] | BlogWatcher RSS 博客跟踪 | `blogwatcher` |
| [[03-llm-wiki-knowledge-base]] | Karpathy 式三层架构知识库 | `llm-wiki` |
| [[04-youtube-content]] | YouTube 字幕获取与内容结构化 | `youtube-content` |
| [[05-research-workflow]] | 完整研究流程流水线 | 综合 |

## 完整工作流

```
Search (arXiv) → Assess Impact (Semantic Scholar) → Read Abstract → Read Full Paper
                                                          │
                    Find Related Work ← Get Recommendations
                                                          │
                                          Knowledge Base (LLM Wiki)
                                                          │
                                                Publish / Share
```

## 相关 Hermes 技能

- `arxiv` — 论文搜索和语义引用
- `llm-wiki` — 知识库构建
- `blogwatcher` — RSS 博客阅读与监控
- `youtube-content` — YouTube 字幕获取
- `ocr-and-documents` — PDF 文字提取
- `knowledge-base-scaffold` — Obsidian 知识库
