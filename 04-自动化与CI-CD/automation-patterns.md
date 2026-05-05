---
date: 2026-05-05
tags:
  - automation
  - patterns
  - cron
  - auto-merge
  - auto-reply
  - scheduled-tasks
  - 自动化与CI-CD
source_skill: webhook-subscriptions
category: 自动化与 CI-CD
---

# 自动化模式

> 本文档汇总了 GitHub 生态系统中常见的自动化模式，包括定时任务、自动回复、自动合并、依赖更新等场景的完整实现方案。

## 概述

自动化是提升开发效率的关键。GitHub 提供了多种自动化机制：

- **GitHub Actions** — 灵活的工作流引擎，支持任意自动化场景
- **Webhook 集成** — 事件驱动的外部系统调用
- **Probot** — GitHub App 自动化框架
- **Branch Protection Rules** — 分支级别的自动化规则
- **内置功能** — Dependabot、Code Owners、Saved Replies 等

选择合适的自动化工具是关键决策：

| 场景 | 推荐方案 | 替代方案 |
|------|---------|---------|
| 定时任务 | GitHub Actions (schedule) | cron + webhook |
| 自动合并 | GitHub Actions + merge| Probot Auto-Merge |
| 依赖更新 | Dependabot | Renovate |
| 自动回复 | Issue template + Saved Replies | Probot |
| 标签管理 | GitHub Actions + triage | Probot |
| 文档生成 | GitHub Actions | 自定义脚本 |

## 模式 1：定时任务（Scheduled Tasks）

### 每日安全扫描

```yaml
# .github/workflows/daily-security.yml
name: Daily Security Scan
on:
  schedule:
    - cron: '0 6 * * *'   # 每天 UTC 6:00
  workflow_dispatch: {}    # 支持手动触发

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - name: Run npm audit
        run: npm audit --audit-level=high
        continue-on-error: true

      - name: Run CodeQL
        uses: github/codeql-action/analyze@v3

      - name: Send alert if vulnerabilities found
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "🚨 安全告警：${{ github.repository }} 发现高危漏洞"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 每周依赖报告

```yaml
name: Weekly Dependency Report
on:
  schedule:
    - cron: '0 8 * * 1'  # 每周一 UTC 8:00

jobs:
  report:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci

      - name: Check outdated dependencies
        id: outdated
        run: |
          npm outdated --json > outdated.json || true
          echo "count=$(cat outdated.json | wc -l)" >> $GITHUB_OUTPUT

      - name: Create issue if outdated dependencies
        if: steps.outdated.outputs.count > 0
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const outdated = JSON.parse(fs.readFileSync('outdated.json', 'utf8'));
            let body = '## 过时依赖报告\n\n';
            for (const [name, info] of Object.entries(outdated)) {
              body += `- **${name}**: ${info.current} → ${info.latest}\n`;
            }
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '📦 依赖更新报告',
              body: body,
              labels: ['dependencies', 'automated']
            });
```

### 每月维护日脚本

```yaml
name: Monthly Maintenance
on:
  schedule:
    - cron: '0 9 1 * *'  # 每月第一天 UTC 9:00

jobs:
  cleanup:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      actions: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            // 关闭 30 天未活动的 stale issues
            const stale = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'open',
              labels: 'stale',
              sort: 'updated',
              direction: 'asc'
            });
            for (const issue of stale.data) {
              const daysSinceUpdate = (Date.now() - new Date(issue.updated_at)) / 86400000;
              if (daysSinceUpdate > 30) {
                await github.rest.issues.update({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  issue_number: issue.number,
                  state: 'closed'
                });
              }
            }
```

### 使用 cron 表达式

GitHub Actions 使用标准 cron 语法，但有几点需要注意：

| 表达式 | 含义 | 说明 |
|--------|------|------|
| `0 * * * *` | 每小时整点 | 测试频繁 |
| `*/15 * * * *` | 每 15 分钟 | 最高频率 |
| `0 0 * * *` | 每天午夜 | 日报类任务 |
| `0 8 * * 1-5` | 工作日 8:00 | 工作日任务 |
| `0 0 * * 0` | 每周日 | 周报类任务 |
| `0 0 1 * *` | 每月 1 日 | 月报类任务 |
| `0 0 1 1 *` | 每年 1 月 1 日 | 年度任务 |

**注意：** GitHub Actions 定时任务的最小间隔为每 5 分钟，且不能保证精确到秒级。

## 模式 2：自动回复（Auto-Reply）

### 新 Issue 自动回复

```yaml
name: Auto Reply on Issues
on:
  issues:
    types: [opened]

jobs:
  auto-reply:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const issue = context.payload.issue;
            const body = issue.body || '';
            let reply = '';

            // 根据内容选择回复模板
            if (body.toLowerCase().includes('bug') || body.toLowerCase().includes('错误')) {
              reply = `感谢您报告问题！🤗

请确保您已提供以下信息：
1. 操作系统和版本
2. Node.js 版本
3. 复现步骤
4. 错误日志

我们的团队会尽快处理此问题。`;
            } else if (body.toLowerCase().includes('feature') || body.toLowerCase().includes('功能')) {
              reply = `感谢您的功能建议！✨

我们会将您的提议纳入讨论。请考虑：
1. 这个功能解决什么问题？
2. 是否有现有替代方案？
3. 愿意参与实现吗？`;
            } else {
              reply = `感谢您的反馈！🙏

我们会尽快回复您的问题。`;
            }

            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: reply
            });
```

### 自动标签分类

```yaml
name: Auto Label Issues
on:
  issues:
    types: [opened, edited]

jobs:
  auto-label:
    runs-on: ubuntu-latest
    permissions:
      issues: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const title = context.payload.issue.title.toLowerCase();
            const body = (context.payload.issue.body || '').toLowerCase();
            const labels = [];

            // 通过关键词判断标签
            if (/bug|fix|error|crash|issue/.test(title + body)) {
              labels.push('bug');
            }
            if (/feature|request|enhancement|suggestion/.test(title + body)) {
              labels.push('enhancement');
            }
            if (/documentation|docs|readme|wiki/.test(title + body)) {
              labels.push('documentation');
            }
            if (/question|help|how to|tutorial/.test(title + body)) {
              labels.push('question');
            }
            if (/urgent|critical|important|asap/.test(title + body)) {
              labels.push('priority: high');
            }

            if (labels.length > 0) {
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                labels: labels
              });
            }
```

### 使用 Saved Replies

GitHub 提供了内置的 Saved Replies 功能，适合常用回复：

1. 访问 https://github.com/settings/replies
2. 创建常用回复模板
3. 在 Issue/PR 评论中使用快捷键 `Cmd/Ctrl + .` 调出

常用模板示例：

```
**Bug 报告确认模板：**
感谢您的报告。我们已经记录此问题（标记为 `bug`），开发团队会尽快处理。

**功能请求模板：**
感谢您的建议。我们已将其加入功能队列（标记为 `enhancement`），欢迎社区讨论。

**PR 合并模板：**
感谢您的贡献！🎉 该 PR 看起来没有问题，自动合并将在 CI 通过后执行。
```

## 模式 3：自动合并（Auto-Merge）

### 条件自动合并

```yaml
name: Auto Merge Dependabot PRs
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  auto-merge:
    if: |
      contains(github.event.pull_request.labels.*.name, 'dependencies') &&
      github.event.pull_request.base.ref == 'main'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const pr = context.payload.pull_request;
            // 只对 minor/patch 版本更新自动合并
            if (
              pr.title.includes('Bump') &&
              !pr.title.includes('major') &&
              !pr.title.includes('MAJOR')
            ) {
              await github.rest.pulls.merge({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: pr.number,
                merge_method: 'squash',
                commit_title: `chore(deps): ${pr.title} (#${pr.number})`
              });
            }
```

### 启用内置 Auto-Merge

GitHub 提供了内置的自动合并功能，无需额外配置：

```bash
# 启用仓库的自动合并
gh repo edit --enable-auto-merge

# 在 PR 上启用自动合并（需要 write 权限）
gh pr merge <PR_NUMBER> --auto --squash
```

### QA 通过的自动合并

```yaml
name: Auto Merge After QA
on:
  pull_request_review:
    types: [submitted]

jobs:
  auto-merge:
    if: github.event.review.state == 'approved'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const pr = context.payload.pull_request;

            // 获取所有检查状态
            const checks = await github.rest.checks.listForRef({
              owner: context.repo.owner,
              repo: context.repo.repo,
              ref: pr.head.sha
            });

            const allPassed = checks.data.check_runs.every(
              check => check.conclusion === 'success'
            );

            if (allPassed) {
              await github.rest.pulls.merge({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: pr.number,
                merge_method: 'squash'
              });
            }
```

## 模式 4：依赖更新自动化

### Dependabot 配置

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
      time: "09:00"
      timezone: "Asia/Shanghai"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "automated"
    reviewers:
      - "team-lead"
    assignees:
      - "maintainer"
    versioning-strategy: increase

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "docker"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "actions"
```

### Renovate 配置（Dependabot 替代方案）

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base",
    ":dependencyDashboard",
    ":prConcurrentLimit10",
    "group:allNonMajor"
  ],
  "labels": ["dependencies", "automated"],
  "schedule": ["before 9am on monday"],
  "timezone": "Asia/Shanghai",
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    },
    {
      "matchPackagePrefixes": ["@types/"],
      "automerge": true
    }
  ]
}
```

## 模式 5：分支清理自动化

### 自动删除合并后的分支

```yaml
name: Cleanup Branches
on:
  pull_request:
    types: [closed]

jobs:
  delete-branch:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const branch = context.payload.pull_request.head.ref;
            // 保护 main/develop 等核心分支
            if (!['main', 'develop', 'master'].includes(branch)) {
              await github.rest.git.deleteRef({
                owner: context.repo.owner,
                repo: context.repo.repo,
                ref: `heads/${branch}`
              });
              console.log(`Deleted branch: ${branch}`);
            }
```

### 定期清理陈旧分支

```yaml
name: Weekly Branch Cleanup
on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日

jobs:
  cleanup:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const branches = await github.rest.repos.listBranches({
              owner: context.repo.owner,
              repo: context.repo.repo,
              per_page: 100
            });

            for (const branch of branches.data) {
              // 跳过保护分支
              if (branch.protected) continue;

              const commits = await github.rest.repos.listCommits({
                owner: context.repo.owner,
                repo: context.repo.repo,
                sha: branch.name,
                per_page: 1
              });

              if (commits.data.length === 0) continue;

              const lastCommit = new Date(commits.data[0].commit.committer.date);
              const daysSince = (Date.now() - lastCommit) / 86400000;

              // 超过 90 天无活动的分支标记为 stale
              if (daysSince > 90) {
                // 创建一个提醒 issue
                await github.rest.issues.create({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  title: `🧹 过期分支：${branch.name}`,
                  body: `分支 \`${branch.name}\` 已经 ${Math.floor(daysSince)} 天未更新。

建议：如果不再需要，请删除此分支。如果分支将在 7 天内未被标记，将自动删除。`,
                  labels: ['cleanup', 'stale-branch']
                });
              }
            }
```

## 模式 6：通知与报告自动化

### Slack 通知

```yaml
name: Notify Team
on:
  pull_request:
    types: [opened, ready_for_review]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Send Slack notification
        uses: slackapi/slack-github-action@v1
        with:
          channel-id: 'C0123456789'
          slack-message: |
            📬 新的 PR 需要审查：
            *<${{ github.event.pull_request.html_url }}|${{ github.event.pull_request.title }}>*
            作者：${{ github.event.pull_request.user.login }}
            分支：`${{ github.event.pull_request.head.ref }}` → `${{ github.event.pull_request.base.ref }}`
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

### 每日站会摘要

```yaml
name: Daily Standup Digest
on:
  schedule:
    - cron: '0 7 * * 1-5'  # 工作日 7:00

jobs:
  digest:
    runs-on: ubuntu-latest
    permissions:
      issues: read
      pull-requests: read
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            // 获取昨天以来的活动
            const since = new Date(Date.now() - 86400000).toISOString();

            const issues = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              since: since,
              state: 'all',
              per_page: 50
            });

            const prs = await github.rest.pulls.list({
              owner: context.repo.owner,
              repo: context.repo.repo,
              state: 'open',
              sort: 'updated',
              direction: 'desc',
              per_page: 20
            });

            let digest = `# 📋 每日站会摘要 — ${new Date().toLocaleDateString('zh-CN')}\n\n`;

            // 统计
            digest += `## 统计数据\n`;
            digest += `- 昨天以来活动：${issues.data.length} 个 Issue/PR\n`;
            digest += `- 当前开放 PR：${prs.data.length} 个\n\n`;

            digest += `## 24 小时内更新的 Issue\n`;
            for (const issue of issues.data.slice(0, 10)) {
              digest += `- [#${issue.number}] ${issue.title} (${issue.state})\n`;
            }

            console.log(digest);
```

## 模式 7：Issue/PR 生命周期管理

### Stale Issue 自动标记

```yaml
name: Mark Stale Issues
on:
  schedule:
    - cron: '30 1 * * *'

jobs:
  stale:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
    steps:
      - uses: actions/stale@v9
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
          stale-issue-message: '此 Issue 已 60 天无活动。将被标记为 stale，并在 7 天后自动关闭。'
          stale-pr-message: '此 PR 已 30 天无活动。将被标记为 stale，并在 14 天后自动关闭。'
          days-before-stale: 60
          days-before-close: 7
          stale-issue-label: 'stale'
          stale-pr-label: 'stale'
          exempt-issue-labels: 'pinned,security,bug,enhancement'
          exempt-pr-labels: 'pinned,security,dependencies'
          operations-per-run: 100
```

### 自动分配 Assignee

```yaml
name: Auto Assign
on:
  pull_request:
    types: [opened]

jobs:
  assign:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            const contributors = [
              'alice', 'bob', 'charlie'
            ];
            // 简单的轮询分配
            const prNumber = context.payload.pull_request.number;
            const assignee = contributors[prNumber % contributors.length];

            await github.rest.issues.addAssignees({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber,
              assignees: [assignee]
            });
```

## 模式 8：数据汇总与监控

### 代码统计报告

```yaml
name: Code Stats
on:
  schedule:
    - cron: '0 0 1 * *'  # 每月 1 日

jobs:
  stats:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate stats
        run: |
          echo "# 📊 代码统计报告" > stats.md
          echo "" >> stats.md
          echo "## 本月变更" >> stats.md
          git log --since="1 month ago" --format="%s" --shortstat >> stats.md
          echo "" >> stats.md
          echo "## 语言分布" >> stats.md
          if command -v cloc &> /dev/null; then
            cloc . --md >> stats.md
          else
            echo "请安装 cloc" >> stats.md
          fi

      - name: Create or update stats file
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const stats = fs.readFileSync('stats.md', 'utf8');
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '📊 本月代码统计',
              body: stats,
              labels: ['report', 'automated']
            });
```

## 自动化模式选择决策树

```
你的需求是什么？
│
├─ 定时执行某操作？ → 模式 1：定时任务
│   ├─ 安全扫描 → cron + security-audit
│   ├─ 依赖检查 → cron + dep-report
│   └─ 清理维护 → cron + cleanup
│
├─ 响应 Issue/PR 事件？ → 模式 2/7/8
│   ├─ 自动回复 → auto-reply
│   ├─ 自动标签 → auto-label
│   ├─ 自动分配 → auto-assign
│   └─ Stale 标记 → stale-bot
│
├─ 管理 PR 合并？ → 模式 3
│   ├─ Dependabot PR → auto-merge-deps
│   ├─ 审查通过后 → auto-merge-approved
│   └─ 条件合并 → conditional-merge
│
├─ 管理依赖？ → 模式 4
│   ├─ Dependabot → dependabot.yml
│   └─ Renovate → renovate.json
│
├─ 分支清理？ → 模式 5
│
├─ 通知团队？ → 模式 6
│   ├─ Slack/钉钉 → webhook + message
│   └─ 每日摘要 → cron + digest
│
└─ 数据汇总？ → 模式 8
    └─ 代码统计 → cloc + report
```

## 最佳实践总结

### 设计原则

1. **幂等性** — 自动化脚本应可重复执行而不产生副作用
2. **可观测性** — 为自动化流程添加日志和告警
3. **渐进式** — 从简单模式开始，逐步增加复杂度
4. **错误处理** — 为每个自动化步骤准备降级策略
5. **限流保护** — 避免自动化导致 API 限流

### 安全注意事项

- 自动化脚本应遵循最小权限原则
- 敏感数据使用 Secrets 管理
- 定时任务考虑时区配置
- 生产环境的自动化需要人工审批环节
- 记录自动化操作的审计日志

### 维护建议

- 为自动化脚本编写测试
- 定期审查自动化效果和效率
- 关注 GitHub Actions 的定价策略（免费额度）
- 使用 `workflow_dispatch` 保留手动触发能力
- 复杂自动化使用 `actions/github-script` 代替多步 shell 命令

## 相关文档

- [[webhook-subscriptions]] — Webhook 订阅管理
- [[ci-cd-workflows]] — CI/CD 工作流设计模式
- [[../03-软件开发方法论/test-driven-development]] — 测试驱动开发
- [[../09-生产工具与效率]] — 生产工具与效率
- [[../05-自主AI-Agent/autonomous-agents]] — 自主 AI Agent
