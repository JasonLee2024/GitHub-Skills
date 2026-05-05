---
date: 2026-05-05
tags:
  - tdd
  - testing
  - development
  - quality
  - red-green-refactor
  - 软件开发方法论
source_skill: test-driven-development
category: 软件开发方法论
---

# 测试驱动开发 — TDD

> 本文档基于 Hermes Agent 的 `test-driven-development` 技能整理，完整介绍 RED-GREEN-REFACTOR 循环和测试优先的开发纪律。

## 概述

测试驱动开发（Test-Driven Development，TDD）是一种**先写测试、后写代码**的开发方法。它遵循一个严格的循环：

```
1. RED — 编写一个会失败的测试
2. GREEN — 编写最简代码让测试通过
3. REFACTOR — 在测试保护下重构代码
```

**核心信条：如果你没有亲眼看到测试失败，你就无法确定它测试的是正确的东西。**

## TDD 的铁律

```
没有会失败的测试，就不能写生产代码。
```

如果在写测试之前已经写了代码——删掉它，重来。

**没有例外：**
- 不要保留代码当"参考"
- 不要在写测试时"改编"现有代码
- 不要看它
- 删除就是删除

从测试开始重新实现。

## RED — 编写会失败的测试

### 好的测试

```python
def test_retries_failed_operations_3_times():
    attempts = 0
    def operation():
        nonlocal attempts
        attempts += 1
        if attempts < 3:
            raise Exception('fail')
        return 'success'

    result = retry_operation(operation)

    assert result == 'success'
    assert attempts == 3
```

特点：名称清晰、测试真实行为、只测一件事。

### 不好的测试

```python
def test_retry_works():
    mock = MagicMock()
    mock.side_effect = [Exception(), Exception(), 'success']
    result = retry_operation(mock)
    assert result == 'success'  # 重试次数呢？时机呢？
```

特点：名称模糊、测试 mock 而非真实代码。

### 要求

- 一个测试只测一种行为
- 描述性的清晰命名（名字里出现"and"？说明应该拆成两个测试）
- 使用真实代码，不是 mock（除非确实无法避免）
- 名称描述行为，而非实现

## 验证 RED — 亲眼看见测试失败

**绝对不能跳过这一步。**

```bash
pytest tests/test_feature.py::test_specific_behavior -v
```

确认：
- 测试确实失败（不是因 typo 报错）
- 失败消息符合预期
- 失败是因为功能缺失

**测试立即通过？** 说明你在测试已有行为。修改测试。
**测试报错？** 修复错误，重新运行直到正确失败。

## GREEN — 编写最简实现

编写能让测试通过的最简单代码。仅此而已。

**好的做法：**

```python
def add(a, b):
    return a + b  # 不多不少
```

**不好的做法：**

```python
def add(a, b):
    result = a + b
    logging.info(f"Adding {a} + {b} = {result}")  # 多余的！
    return result
```

**在 GREEN 阶段，作弊是可以的：**
- 硬编码返回值
- 复制粘贴
- 重复代码
- 跳过边界情况

这些会在 REFACTOR 阶段清理。

## 验证 GREEN — 亲眼看见测试通过

**必须执行的步骤。**

```bash
# 运行具体测试
pytest tests/test_feature.py::test_specific_behavior -v

# 然后运行全部测试，确认无回归
pytest tests/ -q
```

确认：
- 测试通过
- 其他测试仍然通过
- 输出干净（无错误、无警告）

**测试失败？** 修复代码，不是测试。
**其他测试失败？** 立即修复回归。

## REFACTOR — 清理代码

只在 GREEN（所有测试通过）之后才能重构：
- 消除重复
- 改善命名
- 提取辅助函数
- 简化表达式

保持测试持续通过。不要添加新行为。

**重构时测试失败了？** 立即撤销。回归到更小的步骤。

## 重复循环

下一个测试 → 下一个行为。一次只做一个循环。

## 为什么顺序重要？

### "我之后会补测试来验证"

测试后写会立即通过。立即通过证明不了任何事情：
- 可能测错了东西
- 可能测的是实现方式而非行为
- 可能遗漏了你忘记的边界情况
- 你从来没看到它捕获过 bug

测试优先迫使你看到测试失败的场景，证明它确实在测试某些东西。

### "我已经手动测试了所有边界情况"

手动测试是随机的。你以为测试了全部，但实际上：
- 没有测试记录
- 代码变更后无法重新运行
- 压力下容易遗漏
- "我试过没出问题" ≠ 全面的测试

自动化测试是系统性的。每次运行时行为一致。

### "删除 X 小时的工作太浪费了"

沉没成本谬误。时间已经花掉了。你现在有两个选择：
- 删除并用 TDD 重写（高置信度）
- 保留并后补测试（低置信度，大概率有 bug）

"浪费"的是保留了无法信任的代码。

## 常见借口的真相

| 借口 | 真相 |
|------|------|
| "太简单了不需要测" | 简单代码也会出问题。写个测试只要 30 秒。 |
| "之后补测试" | 后补的测试立即通过，证明不了什么。 |
| "我先探索一下" | 可以。探索完扔掉，用 TDD 重新开始。 |
| "手动测试更快" | 手动测试证明不了边界情况。每次变更都要重测。 |
| "TDD 会拖慢我" | TDD 比调试快。讲求实效就应该测试优先。 |
| "测试难写 = 设计不清晰" | 倾听测试的声音。难测 = 难用。 |

## 红旗警告 — 立即停下重新开始

如果你发现自己做了以下任何事，删除代码，用 TDD 重新开始：

- 生产代码先于测试
- 实现之后才写测试
- 测试第一次运行就通过
- 说不清测试为什么失败
- 打算"稍后加测试"
- 给自己找借口"就这一次"
- "我已经手动测试过了"
- "后补测试能达到同样的目的"
- "保留参考"或"改编现有代码"
- "已经花了 X 小时，删了浪费"
- "TDD 是教条的，我要务实"
- "这次不同因为..."

**所有这些都意味着：删除代码，用 TDD 重新开始。**

## 完成检查清单

在标记任务完成前，逐项检查：

- [ ] 每个新函数/方法都有测试
- [ ] 亲眼看到每个测试先失败再实现
- [ ] 每个测试因为预期原因失败（功能缺失，不是打错字）
- [ ] 写了最简代码让每个测试通过
- [ ] 全部测试通过
- [ ] 输出干净（无错误、无警告）
- [ ] 测试使用真实代码（只在无法避免时用 mock）
- [ ] 覆盖了边界情况和错误场景

如果无法勾选全部，说明你跳过了 TDD。重新开始。

## 与其它方法论的关系

- **Writing Plans** 在计划中为每个代码任务嵌入完整的 TDD 循环
- **Subagent-Driven Development** 在分派任务时要求子代理遵循 TDD
- **Systematic Debugging** 在修复 bug 时：先写一个复现 bug 的测试（RED），再修复（GREEN）
- **Code Review** 验证 TDD 纪律是否被遵守

## 相关链接

- [[writing-plans]] — 如何在计划中嵌入 TDD 步骤
- [[systematic-debugging]] — 结合 TDD 的系统化调试
- [[subagent-driven-development]] — 在子代理开发中强制执行 TDD
- [[../99-附录与速查/术语表|术语表]]
