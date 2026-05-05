# 03 — 软件开发方法论

## 本章节内容

Hermes Agent 生态中最精华的软件工程方法论。

在写代码之前，先掌握正确的方法。

| 文档 | 内容 | 技能来源 |
|------|------|---------|
|| [[plan]] | Plan Mode — 只计划不执行的开发模式 | `plan` |
|| [[writing-plans]] | 编写可执行实现计划的方法论 | `writing-plans` |
|| [[test-driven-development]] | RED-GREEN-REFACTOR 完整循环 | `test-driven-development` |
|| [[subagent-driven-development]] | 子代理驱动开发模式 | `subagent-driven-development` |
|| [[code-review-request]] | 安全扫描 + 质量门禁 + 自动修复 | `requesting-code-review` |
|| [[systematic-debugging]] | 4 阶段根因分析与系统化调试 | `systematic-debugging` |
|| [[codebase-inspection]] | LOC 统计、语言分布、代码质量 | `codebase-inspection` |

## 核心理念

这些技能形成了一个完整的开发流水线：

```
Plan → TDD → Implement → Code Review → Debug → Analyze
  ↑                                             │
  └─────────────────────────────────────────────┘
```

## 相关 Hermes 技能

- `writing-plans`, `test-driven-development`, `subagent-driven-development`
- `requesting-code-review`, `systematic-debugging`, `codebase-inspection`
