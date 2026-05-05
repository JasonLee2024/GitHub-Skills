---
date: 2026-05-05
tags:
  - loc
  - code-analysis
  - pygount
  - codebase
  - metrics
  - 软件开发方法论
source_skill: codebase-inspection
category: 软件开发方法论
---

# 代码库检查 — Codebase Inspection

> 本文档基于 Hermes Agent 的 `codebase-inspection` 技能整理，介绍如何使用 pygount 工具对代码库进行系统化的量化分析。

## 概述

代码库检查是指对仓库进行**系统化的量化分析**，包括代码行数统计、语言分布、代码与注释比例、文件数量等指标。这种分析可以帮助你：

- 快速了解一个不熟悉的项目有多大、用什么语言
- 评估项目健康状况（注释率、代码规模）
- 发现大量未分类或反常的文件
- 在重构前后对比代码规模变化
- 为技术报告或项目演示提供量化数据

## 工具基础

使用 `pygount` 工具进行代码统计。这是一个跨语言的源代码行数统计工具，支持几乎所有主流编程语言。

### 安装

```bash
pip install --break-system-packages pygount 2>/dev/null || pip install pygount
```

### 基本用法

```bash
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,.eggs,*.egg-info" \
  .
```

**重要：** 永远使用 `--folders-to-skip` 排除依赖和构建目录，否则 pygount 会逐一遍历并耗费极长时间（或卡死）。

## 常用操作

### 1. 基本汇总（最常用）

获取完整的语言分布、文件数和代码行数：

```bash
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,.venv,__pycache__,.cache,dist,build,.next,.tox,.eggs,.mypy_cache" \
  .
```

示例输出：

```
Language    Files   Code  Comment    %
Python        45   5234     1234  68%
TypeScript    12   1200      340  15%
YAML           8    320       45   4%
Markdown       6      0      890  11%
Shell          3     80       15   1%
...                              (95% coverage)
```

### 2. 按语言过滤

```bash
# 只统计 Python 文件
pygount --suffix=py --format=summary .

# 只统计 Python 和 YAML
pygount --suffix=py,yaml,yml --format=summary .
```

### 3. 详细文件级输出

```bash
# 默认格式显示每个文件的统计
pygount --folders-to-skip=".git,node_modules,venv" .

# 按代码行数排序（前 20 个文件）
pygount --folders-to-skip=".git,node_modules,venv" . | sort -t$'\t' -k1 -nr | head -20
```

### 4. 输出格式

```bash
# 推荐：汇总表
pygount --format=summary .

# JSON 格式（用于程序处理）
pygount --format=json .

# 管道友好：语言、文件数、代码、文档、空行、百分比
pygount --format=summary . 2>/dev/null
```

## 结果解读

汇总表的列：

| 列名 | 含义 |
|------|------|
| **Language** | 检测到的编程语言 |
| **Files** | 该语言的文件数量 |
| **Code** | 实际代码行数（可执行/声明式） |
| **Comment** | 注释或文档行数 |
| **%** | 占总量的百分比 |

特殊伪语言（用于标记特殊情况）：

| 伪语言 | 含义 |
|--------|------|
| `__empty__` | 空文件 |
| `__binary__` | 二进制文件（图片、编译产物等） |
| `__generated__` | 自动生成的文件 |
| `__duplicate__` | 内容完全相同的文件 |
| `__unknown__` | 无法识别的文件类型 |

## 实际应用场景

### 场景 1：初次评估陌生项目

```bash
cd /path/to/new-repo
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv,__pycache__,dist,build" \
  .
```

通过输出快速了解：
- 项目总规模（总代码行数）
- 主要技术栈（哪种语言占比最高）
- 注释密度（判断代码文档化程度）

### 场景 2：定位代码最多的模块

```bash
# 按目录统计
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv" \
  src/

# 对比其他模块
pygount --format=summary \
  --folders-to-skip=".git,node_modules,venv" \
  tests/
```

### 场景 3：重构前后的对比

重构前：
```bash
pygount --format=summary --folders-to-skip=".git,node_modules,venv" . > before.txt
```

重构后：
```bash
pygount --format=summary --folders-to-skip=".git,node_modules,venv" . > after.txt

# 对比
diff before.txt after.txt
```

### 场景 4：检查测试覆盖率比例

```bash
echo "生产代码:"
pygount --suffix=py --format=summary --folders-to-skip=".git,venv" src/
echo ""
echo "测试代码:"
pygount --suffix=py --format=summary --folders-to-skip=".git,venv" tests/
```

健康项目的测试代码通常与生产代码保持一定比例（推荐 0.5:1 到 1:1）。

## 常见陷阱

### 1. 没有排除依赖目录

**后果：** pygount 会遍历 `node_modules`（数万文件）、`venv`、`.git`，导致：
- 极长的执行时间（几分钟到几十分钟）
- 输出被无关文件淹没
- 可能因打开太多文件而崩溃

**解决方案：** 始终使用 `--folders-to-skip`。

### 2. Markdown 显示 0 行代码

pygount 把 Markdown 所有内容归类为注释，不是代码。这是预期行为。如果需要统计 Markdown 行数，用 `wc -l`。

### 3. JSON 文件显示很低的代码行数

pygount 对 JSON 的统计比较保守。需要精确 JSON 行数时用 `wc -l`。

### 4. 大型 Monorepo

对于非常大型的仓库，考虑先使用 `--suffix` 指定目标语言，而不是扫描所有文件。

## 与其它方法论的关系

代码库检查是一种**诊断和评估**工具，它可以：

- 在 **Writing Plans** 阶段帮助理解项目规模
- 在 **Code Review** 时作为项目的量化评估
- 在 **Subagent-Driven Development** 中用于评估实现规模
- 配合 **Systematic Debugging** 定位问题模块的大致范围

## 相关链接

- [[../01-入门指南/github-repo-management]] — 仓库管理基础
- [[../../99-附录与速查/术语表|术语表]]

## 扩展阅读

pygount 官方文档提供了更多高级用法，如：
- 自定义语言检测规则
- 按代码复杂度排序
- 与其他 CI/CD 工具集成
- 生成可视化报告
