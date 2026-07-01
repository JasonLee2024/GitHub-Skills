---
number: "12.06"
title: "开源项目反馈 Issue 提交指南"
status: 🌿 complete
difficulty: 🟢 beginner
created: "2026-07-02"
genre: howto
tags: [GitHub, Issue, 开源, 反馈, 提bug, wx_channel]
---

# 开源项目反馈 Issue 提交指南

> 实战记录：向 `nobiyou/wx_channel` 提交微信兼容性问题 Issue 的完整流程。

## 前提

- 有一个 GitHub 账号（已登录）
- 了解要反馈的项目仓库地址

## 步骤

### Step 1：打开 Issues 页面

```
https://github.com/<owner>/<repo>/issues
```

例：<https://github.com/nobiyou/wx_channel/issues>

### Step 2：点击 New Issue

绿色按钮，在 Issues 列表右上方。

### Step 3：填写 Issue

**标题**：简洁描述问题，包含关键版本号

例：`微信 4.1.11.23 注入引擎兼容性问题`

**正文**：按以下模板填写：

````markdown
## 环境

- 工具版本：v5.6.9（最新 Release）
- 微信版本：4.1.11.23
- OS：Windows 11 Pro
- 权限：管理员运行

## 现象
[用一两句话描述问题]

## 日志/截图
[粘贴关键日志，用 ``` 代码块包裹]

```
✓ 视频号注入引擎已就绪 (WeChatAppEx.exe)
⚠️ 注意：代理自检未通过

```

## 已尝试的排查

- 尝试 1：xxx → 无效
- 尝试 2：xxx → 无效

## 补充
[任何额外信息]
````

### Step 4：提交

点击 **Submit new issue** 按钮。

## 实战案例：wx_channel 微信 4.x 兼容性问题

| 字段 | 内容 |
|------|------|
| 仓库 | `nobiyou/wx_channel` |
| 标题 | 微信 4.1.11.23 注入引擎兼容性问题 |
| 核心日志 | `⚠️ 注意：代理自检未通过` |
| 已排查 | 管理员运行 ✅ / 降级微信 3.9 服务端拒绝 ✅ / 设系统代理 ✅ / 防火墙放行 ✅ |
| 阻塞影响 | MCP 服务 wechat-video-channels-mcp 无法完成端到端功能验证 |

## 写好 Issue 的要点

1. **标题含关键信息**：版本号 + 问题类型 → 方便作者快速定位
2. **贴日志不要贴感受**：说"代理自检未通过"比说"好像不行"有价值 100 倍
3. **列已排查项**：表示你已经尽了最大努力，不是伸手党
4. **环境信息完整**：OS + 工具版本 + 微信版本 → 三要素缺一不可
5. **语气尊重**：开源作者免费维护，用"反馈"而非"要求"

> 最后更新：2026-07-02
