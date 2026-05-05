---
date: 2026-05-05
tags:
  - code-review
  - security
  - verification
  - quality
  - pre-commit
  - 软件开发方法论
source_skill: requesting-code-review
category: 软件开发方法论
---

# 预提交验证管线 — Code Review

> 本文档基于 Hermes Agent 的 `requesting-code-review` 技能整理，介绍一套自动化的预提交代码验证流程。

## 概述

预提交代码验证是一套**在代码提交前自动执行的验证管线**。它的核心理念是：

**没有 Agent 应该自己验证自己的工作。一个全新的上下文能发现你所遗漏的东西。**

这个管线包含以下环节：

1. 获取代码变更差异（diff）
2. 静态安全扫描
3. 基线测试与 lint 检查
4. 自我审查清单
5. 独立审查 Agent
6. 结果评估
7. 自动修复循环
8. 提交

## 何时使用

- 实现功能或修复 bug 之后，在 `git commit` 或 `git push` 之前
- 用户说"提交"、"推送"、"完成了"、"验证一下"
- 在一个 git 仓库中完成 2 个以上文件编辑后
- 在 Subagent-Driven Development 中，每个任务完成后

**跳过情况：** 纯文档变更、纯配置修改、或用户说"跳过验证"。

## 与 GitHub Code Review 的区别

| 特性 | 本技能（预提交验证） | GitHub Code Review |
|------|---------------------|-------------------|
| 角色 | 你自己提交前的检查 | 审查其他人的 PR |
| 时机 | commit 之前 | PR 创建之后 |
| 方式 | 自动化脚本 + Agent | 内联评论 + 人工审查 |
| 范围 | 当前变更 | 整个 PR |

## 第一步：获取差异

```bash
# 获取暂存区差异
git diff --cached

# 如果暂存区为空，尝试工作区差异
git diff

# 或对比上次提交
git diff HEAD~1 HEAD
```

如果差异过大（超过 15,000 字符），按文件拆分：

```bash
git diff --name-only
git diff HEAD -- specific_file.py
```

## 第二步：静态安全扫描

扫描新增行中的安全隐患。任何匹配项都作为安全问题输入到后续审查环节。

```bash
# 硬编码密钥
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token|passwd)\s*=\s*['\"][^'\"]{6,}['\"]"

# shell 注入
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True"

# 危险 eval/exec
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("

# 不安全的反序列化
git diff --cached | grep "^+" | grep -E "pickle\.loads?\("

# SQL 注入（查询中使用字符串格式化）
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT|\.format\(.*INSERT"
```

## 第三步：基线测试和 lint

检测项目语言并运行相应的工具。在变更前的基线结果（`baseline_failures`）与变更后的结果进行对比，**只阻止新增的失败**。

```bash
# Python (pytest)
python -m pytest --tb=no -q 2>&1 | tail -5

# Python 代码检查
which ruff && ruff check . 2>&1 | tail -10
which mypy && mypy . --ignore-missing-imports 2>&1 | tail -10
```

**基线对比：** 先 stash 变更，运行测试记录基线失败数，然后 pop 恢复变更，重新跑测试。只有**新出现**的失败才阻止提交。

## 第四步：自我审查清单

在分派独立审查之前，快速自查：

- [ ] 没有硬编码密钥、API Key 或凭据
- [ ] 用户输入有校验
- [ ] SQL 查询使用参数化语句
- [ ] 文件操作验证路径（无路径遍历）
- [ ] 外部调用有错误处理（try/catch）
- [ ] 没有遗留的调试 print/console.log
- [ ] 没有注释掉的代码
- [ ] 新代码有测试（如果项目有测试套件）

## 第五步：独立审查 Agent

这是整个流程的核心机制。分派一个全新的 Agent 来审查代码变更，确保其没有任何关于"这些变更如何产生的"上下文。

**关键原则：**
- 审查 Agent 只拿到 diff 和静态扫描结果
- 与实现者不共享上下文
- 失败关闭原则：如果返回的结果无法解析，视为失败
- 安全问题和逻辑错误导致自动不通过
- 仅建议项不阻止提交

审查 Agent 返回一个结构化的 JSON 结果：

```json
{
  "passed": true,
  "security_concerns": [],
  "logic_errors": [],
  "suggestions": [],
  "summary": "一句话结论"
}
```

## 第六步：评估结果

综合静态扫描、测试/ lint、独立审查的结果。

**全部通过：** 进入提交步骤。

**任何失败：** 报告失败详情，进入自动修复循环。

```
验证失败

安全问题：[静态扫描 + 审查发现的]
逻辑错误：[审查发现的]
回归：[新的测试失败]
新的 lint 错误：[详情]
建议（非阻塞）：[清单]
```

## 第七步：自动修复循环

**最多进行 2 轮修复-重验循环。**

分派第三个 Agent（不是你实现者，也不是审查者）。它只修复被报告的问题：

- 不重构、不改名、不改其他东西
- 不添加功能
- 修复精确的问题

修复后，重新运行整个验证流程：
- 通过：进入提交
- 失败且尝试 < 2：重复本步骤
- 失败且尝试 ≥ 2：将剩余问题报告给用户，建议撤销变更

## 第八步：提交

验证通过后：

```bash
git add -A && git commit -m "[verified] <描述>"
```

前缀 `[verified]` 表示此变更经过了独立审查者的批准。

## 常见需要标记的模式

### Python

```python
# 错误：SQL 注入
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
# 正确：参数化
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# 错误：shell 注入
os.system(f"ls {user_input}")
# 正确：安全调用
subprocess.run(["ls", user_input], check=True)
```

### JavaScript

```javascript
// 错误：XSS
element.innerHTML = userInput;
// 正确：安全
element.textContent = userInput;
```

## 常见问题

### Q: diff 为空怎么办？

A: 检查 `git status`。如果确实没有变更，告诉用户无需验证。

### Q: 不是 git 仓库怎么办？

A: 跳过验证，告知用户。

### Q: diff 太大怎么办？

A: 按文件拆分审查，每个文件单独走流程。

### Q: 审查 Agent 返回了误报？

A: 如果是故意的（比如测试密钥），在修复提示中注明。

### Q: 没有测试框架怎么办？

A: 跳过回归检查，审查 Agent 仍然运行。

## 与其它方法论的关系

- **Subagent-Driven Development**：每个任务完成后运行验证管线，作为质量关卡
- **TDD**：管线验证 TDD 纪律是否被遵守——有测试、测试通过、无回归
- **Writing Plans**：验证实现是否符合计划规格

## 相关链接

- [[subagent-driven-development]] — 子代理开发中的验证阶段
- [[test-driven-development]] — TDD 纪律验证
- [[../99-附录与速查/术语表|术语表]]
