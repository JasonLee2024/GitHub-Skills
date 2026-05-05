---
date: 2026-05-05
tags:
  - plan
  - planning
  - workflow
  - implementation
  - design
  - 软件开发方法论
source_skill: writing-plans
category: 软件开发方法论
---

# 编写可执行计划 — Writing Plans

> 本文档基于 Hermes Agent 的 `writing-plans` 技能整理，提供一种让计划可执行的文档撰写方法。

## 概述

Writing Plans 是一种**面向执行的计划撰写方法论**。与传统项目计划（偏重时间线和里程碑）不同，Writing Plans 的核心原则是：

**一个好的实现计划，让执行变得显而易见。如果执行者需要猜测，说明计划不完整。**

这意味着计划中应该包含：
- 精确的文件路径（不是"模型文件"而是 `src/models/user.py`）
- 完整的代码示例（可直接复制粘贴的代码）
- 精确的命令和期望输出（`pytest tests/test_auth.py -v` 期望 3 passed）
- 验证步骤（如何确认每一步正确）

## 何时使用

**每次实施多步骤功能之前都要写计划。** 不要跳过，即使：
- 功能看起来很简单（假设导致 bug）
- 你打算自己实现（未来的你需要指导）
- 只有你一个人开发（文档很重要）

## 任务粒度的黄金标准

**每个任务 = 2-5 分钟的专注工作。**

每一小步只做一件事：

```
Step 1: 写一个会失败的测试        ← 一个步骤
Step 2: 运行测试确认它失败          ← 一个步骤
Step 3: 写最简实现代码             ← 一个步骤
Step 4: 运行测试确认它通过          ← 一个步骤
Step 5: 提交                      ← 一个步骤
```

**过大的任务：**

```
### Task 1: 构建用户认证系统
[50 行代码分布在 5 个文件中]
```

**合适的粒度：**

```
### Task 1: 创建 User 模型（含 email 字段）
[10 行代码, 1 个文件]

### Task 2: 为 User 添加密码哈希字段
[8 行代码, 1 个文件]

### Task 3: 创建密码哈希工具函数
[15 行代码, 1 个文件]
```

## 计划文档结构

### 头部信息

每个计划必须以标准头部开始：

```markdown
# [功能名称] 实现计划

**目标：** [一句话描述要构建什么]

**架构方案：** [2-3 句说明技术方案]

**技术栈：** [核心技术/库]

---
```

### 任务格式

每个任务的格式应当统一：

````markdown
### Task N: [描述性任务名]

**目标：** 这一小步要完成什么（一句话）

**文件：**
- 创建：`exact/path/to/new_file.py`
- 修改：`exact/path/to/existing.py`
- 测试：`tests/path/to/test_file.py`

**Step 1: 编写会失败的测试**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: 运行测试验证失败**

运行：`pytest tests/path/test.py::test_specific_behavior -v`
期望结果：FAIL — "function not defined"

**Step 3: 编写最简实现**

```python
def function(input):
    return expected
```

**Step 4: 运行测试验证通过**

运行：`pytest tests/path/test.py::test_specific_behavior -v`
期望结果：PASS

**Step 5: 提交**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## 编写流程

### 第一步：理解需求

阅读并理解：
- 功能需求
- 设计文档或用户描述
- 验收标准
- 约束条件

### 第二步：探索代码库

使用 Hermes 工具了解项目：
- 查看项目结构
- 阅读类似功能的实现
- 检查现有测试
- 阅读关键文件

### 第三步：设计方案

确定：
- 架构模式
- 文件组织
- 依赖需求
- 测试策略

### 第四步：编写任务

按顺序创建任务：
1. 搭建/基础设施
2. 核心功能（每个都用 TDD）
3. 边界情况
4. 集成
5. 清理/文档

### 第五步：补充完整细节

每个任务都要有：
- **精确文件路径**（不是"配置文件"而是 `src/config/settings.py`）
- **完整代码示例**（不是"添加验证"而是完整的验证函数代码）
- **精确命令和期望输出**
- **验证步骤**

### 第六步：检查计划

逐项检查：
- [ ] 任务顺序合理、有逻辑
- [ ] 每个任务都是 2-5 分钟粒度
- [ ] 文件路径精确
- [ ] 代码示例完整（可复制粘贴）
- [ ] 命令精确且有期望输出
- [ ] 无遗漏上下文
- [ ] 遵循 DRY、YAGNI、TDD 原则

### 第七步：保存计划

将计划保存到项目文档目录，并提交。

## 核心原则

### DRY — 不要重复自己

**错误做法：** 在 3 个地方复制粘贴验证逻辑
**正确做法：** 提取验证函数，统一使用

### YAGNI — 你不需要它

**错误做法：** 为未来需求预留"灵活性"

```python
# 错误 — YAGNI 违反
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.preferences = {}   # 现在不需要！
        self.metadata = {}      # 现在不需要！
```

**正确做法：** 只实现当前需要的东西。

```python
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
```

### TDD — 测试驱动开发

每个产生代码的任务都应包含完整的 TDD 循环：
1. 编写会失败的测试
2. 运行确认失败
3. 编写最简实现
4. 运行确认通过

### 频繁提交

每个任务完成后提交一次：

```bash
git add [files]
git commit -m "type: description"
```

## 常见错误

### 任务描述模糊

**错误：** "添加用户认证功能"
**正确：** "创建 User 模型，包含 email 和 password_hash 字段"

### 代码示例不完整

**错误：** "Step 1: 添加验证函数"（没有代码）
**正确：** "Step 1: 添加验证函数"后跟完整的函数代码

### 缺少验证步骤

**错误：** "Step 3: 测试能否正常工作"
**正确：** "Step 3: 运行 `pytest tests/test_auth.py -v`，期望 3 passed"

### 文件路径不精确

**错误：** "创建模型文件"
**正确：** "创建：`src/models/user.py`"

## 与其它方法论的关系

- **Plan Mode** 是"模式开关"，Writing Plans 是"撰写方法"
- Writing Plans 的输出通过 **Subagent-Driven Development** 执行
- 每步执行遵循 **TDD** 的 RED-GREEN-REFACTOR
- 完成后通过 **Code Review** 验证

## 相关链接

- [[plan]] — Plan Mode 计划模式
- [[test-driven-development]] — TDD 测试驱动开发
- [[subagent-driven-development]] — 子代理驱动开发
- [[../99-附录与速查/术语表|术语表]]
