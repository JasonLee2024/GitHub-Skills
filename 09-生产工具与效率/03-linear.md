---
date: 2026-05-05
tags:
  - linear
  - project-management
  - issues
  - teams
  - agile
  - productivity
  - 生产工具与效率
source_skill: linear
category: 生产工具与效率
---

# Linear 项目管理

> 本文档基于 Hermes Agent 的 `linear` 技能整理，涵盖 Linear GraphQL API 的 Issues、Projects、Teams 管理全流程。

## 概述

Linear 是一款为现代开发团队打造的**高效项目管理工具**，以其极致的速度和键盘优先操作著称。Hermes Agent 的 `linear` 技能允许通过命令行自动化管理 Issues、Projects、Teams 和工作流。

### 核心能力

| 功能 | 说明 | 适用场景 |
|------|------|---------|
| Issue 管理 | 创建、更新、查询、分配 | 任务跟踪、Bug 报告 |
| Project 管理 | 创建项目、绑定里程碑 | 项目规划、进度追踪 |
| Team 管理 | 查询团队、成员和配置 | 团队协作、工作流配置 |
| 工作流管理 | 状态转移、循环 Sprint | 敏捷开发流程 |
| 搜索和过滤 | 多维度查询问题 | 报告生成、数据分析 |
| Webhook 集成 | 事件驱动的自动化 | 与 CI/CD 联动 |

---

## 前置准备

### 1. 获取 API Key

```bash
# 1. 打开 Linear → Settings → API
# 2. 点击「创建 API Key」
# 3. 设置名称（如 "Hermes Agent"）和权限
# 4. 保存密钥
```

### 2. 配置环境

```bash
export LINEAR_API_KEY="lin_api_xxxxxxxxxxxxxxxx"
```

### 3. 安装 GraphQL 客户端

```bash
pip install gql requests
```

---

## 基础操作

### 使用 GraphQL 客户端

Linear 的 API 基于 GraphQL，所有操作都需要通过 GraphQL 查询和变更完成：

```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

transport = RequestsHTTPTransport(
    url="https://api.linear.app/graphql",
    headers={"Authorization": "lin_api_xxxxxxxxxxxx"},
    use_json=True,
)
client = Client(transport=transport, fetch_schema_from_transport=True)
```

---

## Issue 管理

### 创建 Issue

```python
create_issue_mutation = gql("""
  mutation CreateIssue($teamId: String!, $title: String!, 
                        $description: String, $priority: Int) {
    issueCreate(
      input: {
        teamId: $teamId
        title: $title
        description: $description
        priority: $priority
      }
    ) {
      success
      issue {
        id
        identifier
        title
        url
      }
    }
  }
""")

def create_issue(team_id, title, description=None, priority=2):
    """创建 Issue（priority: 0=none, 1=urgent, 2=high, 3=medium, 4=low）"""
    variables = {
        "teamId": team_id,
        "title": title,
        "description": description,
        "priority": priority
    }
    result = client.execute(create_issue_mutation, variable_values=variables)
    issue = result['issueCreate']['issue']
    print(f"📌 Issue 已创建: {issue['identifier']} - {issue['title']}")
    print(f"   🔗 {issue['url']}")
    return issue

# 使用示例
create_issue(
    team_id="your-team-id",
    title="升级 CI 服务器配置",
    description="## 背景\n当前的 CI 服务器磁盘空间不足\n\n## TODO\n- [ ] 清理缓存\n- [ ] 扩展磁盘\n- [ ] 更新 Runner 配置",
    priority=1  # Urgent
)
```

### 查询 Issue

```python
query_issues = gql("""
  query GetIssues($teamId: String!, $statusName: String) {
    issues(
      filter: {
        team: { id: { eq: $teamId } }
        state: { name: { eq: $statusName } }
      }
      first: 20
    ) {
      nodes {
        id
        identifier
        title
        description
        priority
        state { name }
        assignee { displayName }
        createdAt
        url
      }
    }
  }
""")

def list_issues(team_id, status=None):
    """列出团队 Issue"""
    variables = {"teamId": team_id, "statusName": status}
    result = client.execute(query_issues, variable_values=variables)
    
    for issue in result['issues']['nodes']:
        assignee = issue['assignee']['displayName'] if issue['assignee'] else '未分配'
        print(f"  [{issue['state']['name']}] {issue['identifier']}: {issue['title']}")
        print(f"     优先级: {issue['priority']} | 负责人: {assignee}")
        print(f"     {issue['url']}")
        print()

# 查询团队待办
list_issues("your-team-id", "进行中")
```

### 更新 Issue

```python
update_issue_mutation = gql("""
  mutation UpdateIssue($issueId: String!, $title: String, 
                        $description: String, $priority: Int,
                        $assigneeId: String) {
    issueUpdate(
      id: $issueId
      input: {
        title: $title
        description: $description
        priority: $priority
        assigneeId: $assigneeId
      }
    ) {
      success
      issue {
        id
        identifier
        title
      }
    }
  }
""")

def update_issue_status(issue_id, to_state_id):
    """变更 Issue 状态"""
    mutation = gql("""
      mutation UpdateIssueState($id: String!, $stateId: String!) {
        issueUpdate(id: $id, input: { stateId: $stateId }) {
          success
          issue { id identifier state { name } }
        }
      }
    """)
    result = client.execute(mutation, variable_values={
        "id": issue_id, "stateId": to_state_id
    })
    print(f"✅ Issue 状态已更新")
```

---

## 项目管理

### 创建项目

```python
create_project_mutation = gql("""
  mutation CreateProject($name: String!, $description: String,
                          $teamIds: [String!]!, $state: String) {
    projectCreate(
      input: {
        name: $name
        description: $description
        teamIds: $teamIds
        state: $state
      }
    ) {
      success
      project {
        id
        name
        url
      }
    }
  }
""")

def create_project(name, description, team_ids, state="planned"):
    """创建项目"""
    result = client.execute(
        create_project_mutation,
        variable_values={
            "name": name,
            "description": description,
            "teamIds": team_ids,
            "state": state
        }
    )
    project = result['projectCreate']['project']
    print(f"📋 项目已创建: {project['name']}")
    print(f"   🔗 {project['url']}")
```

---

## 团队管理

### 查询团队

```python
query_teams = gql("""
  query GetTeams {
    teams {
      nodes {
        id
        name
        key
        members {
          nodes {
            id
            displayName
            email
          }
        }
        states {
          nodes {
            id
            name
            type
            position
          }
        }
      }
    }
  }
""")

def list_teams():
    """列出所有团队及其工作流状态"""
    result = client.execute(query_teams)
    for team in result['teams']['nodes']:
        print(f"👥 团队: {team['name']} ({team['key']})")
        print(f"   成员: {', '.join(m['displayName'] for m in team['members']['nodes'])}")
        statuses = [f"{s['name']}({s['type']})" for s in team['states']['nodes']]
        print(f"   工作流: {' → '.join(statuses)}")
        print()
```

---

## 工作流自动化

### 批量创建 Sprint Issues

```python
def create_sprint_issues(team_id, issues_list, cycle_id=None):
    """批量创建 Sprint Issue"""
    for issue_data in issues_list:
        variables = {
            "teamId": team_id,
            "title": issue_data['title'],
            "description": issue_data.get('description'),
            "priority": issue_data.get('priority', 2),
        }
        if cycle_id:
            variables['cycleId'] = cycle_id
        
        result = client.execute(create_issue_mutation, variable_values=variables)
        issue = result['issueCreate']['issue']
        print(f"  ✅ {issue['identifier']} - {issue['title']}")

# 使用示例
sprint_backlog = [
    {"title": "实现用户认证模块", "priority": 1, "description": "OAuth 2.0 集成"},
    {"title": "重构 API 路由", "priority": 2},
    {"title": "添加单元测试覆盖率检查", "priority": 3},
]
create_sprint_issues("team-id", sprint_backlog)
```

### GitHub ↔ Linear 同步

```bash
# 通过 Webhook 实现 GitHub PR ↔ Linear Issue 关联
# 在 PR 描述中使用 Linear Issue 的 identifier：
# "Closes ENG-42 — 修复登录页闪退"
#
# Linear 自动检测并关联：
# - PR 合并 → Linear Issue 自动标记完成
# - PR 标题匹配 → 自动建立链接
```

---

## 搜索语法

| 搜索词 | 示例 | 说明 |
|--------|------|------|
| `priority:1` | `priority:1` | 紧急优先级 |
| `status:` | `status:进行中` | 按状态 |
| `assignee:` | `assignee:me` | 按负责人 |
| `team:` | `team:engineering` | 按团队 |
| `project:` | `project:sprint-12` | 按项目 |
| `label:` | `label:bug` | 按标签 |
| `created:` | `created:>7d` | 按创建时间 |

---

## 最佳实践

1. **保持 Issue 原子性** — 一个 Issue 只处理一个问题
2. **使用引用语法** — 在描述中引用相关 Issue: `ENG-41, ENG-45`
3. **模板化描述** — 创建团队统一的 Issue 模板
4. **自动化状态转移** — 通过 Webhook 连接 CI/CD
5. **定期清理** — 关闭超过 30 天未更新的 Issue

---

## 相关技能

- [[01-google-workspace]] — Google Workspace 集成
- [[02-notion]] — Notion API 管理
- [[04-nano-pdf]] — PDF 编辑
- [[05-powerpoint]] — PowerPoint 自动化
