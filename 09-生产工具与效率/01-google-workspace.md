---
date: 2026-05-05
tags:
  - google-workspace
  - gmail
  - calendar
  - drive
  - sheets
  - docs
  - productivity
  - 生产工具与效率
source_skill: google-workspace
category: 生产工具与效率
---

# Google Workspace 集成：Gmail / Calendar / Drive / Sheets / Docs

> 本文档基于 Hermes Agent 的 `google-workspace` 技能整理，涵盖 Google 生产力套件的 API 集成和自动化操作。

## 概述

Google Workspace（原 G Suite）提供完备的云端办公套件。通过 Hermes Agent 的 `google-workspace` 技能，开发者可以直接通过命令行操作 Gmail、Calendar、Drive、Sheets 和 Docs，无需手动打开浏览器。

### 核心能力

| 服务 | 功能 | 适用场景 |
|------|------|---------|
| **Gmail** | 发送、搜索、管理邮件 | 自动通知、邮件分类 |
| **Calendar** | 创建事件、查询日程 | 日程管理、会议安排 |
| **Drive** | 文件上传、搜索、分享 | 文档管理、自动备份 |
| **Sheets** | 读写电子表格 | 数据记录、批量操作 |
| **Docs** | 创建和编辑文档 | 自动报告、模板化文档 |

---

## 前置准备：Google Cloud 配置

### 1. 创建项目

```bash
# 1. 访问 https://console.cloud.google.com/
# 2. 创建新项目（或选择现有项目）
# 3. 启用所需 API：
#    - Gmail API
#    - Google Calendar API
#    - Google Drive API
#    - Google Sheets API
#    - Google Docs API
```

### 2. 获取凭证

```bash
# 1. 创建 OAuth 2.0 Client ID（桌面应用类型）
# 2. 下载 credentials.json 到本地
# 3. 设置环境变量
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.google/credentials.json"
export GOOGLE_TOKEN_PATH="$HOME/.google/token.json"
```

### 3. 安装客户端库

```bash
pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

---

## Gmail 集成

### 发送邮件

```python
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from email.mime.text import MIMEText
import base64

def send_email(service, to, subject, body):
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject
    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    
    service.users().messages().send(
        userId='me',
        body={'raw': raw}
    ).execute()
    print(f"📧 邮件已发送至 {to}")

# 使用示例
service = build('gmail', 'v1', credentials=creds)
send_email(service, 'team@example.com', '构建通知', '流水线已完成 ✅')
```

### 搜索邮件

```python
def search_emails(service, query, max_results=10):
    """搜索邮件，支持 Gmail 搜索语法"""
    results = service.users().messages().list(
        userId='me',
        q=query,
        maxResults=max_results
    ).execute()
    
    messages = results.get('messages', [])
    for msg in messages:
        detail = service.users().messages().get(
            userId='me', id=msg['id']
        ).execute()
        headers = {h['name']: h['value'] for h in detail['payload']['headers']}
        print(f"  📬 {headers.get('Subject', '无主题')}")
        print(f"     from: {headers.get('From', '')}")
        print(f"     date: {headers.get('Date', '')}")
    
    return messages

# 示例搜索
search_emails(service, 'from:github.com is:unread')
search_emails(service, 'subject:deploy after:2024/01/01')
```

### Gmail 搜索语法速查

| 语法 | 示例 | 说明 |
|------|------|------|
| `from:` | `from:github.com` | 按发件人 |
| `to:` | `to:me` | 按收件人 |
| `subject:` | `subject:deploy` | 按主题 |
| `after:` / `before:` | `after:2024/01/01` | 按日期 |
| `is:unread` / `is:read` | `is:unread` | 按状态 |
| `has:attachment` | `has:attachment` | 有附件 |
| `label:` | `label:INBOX` | 按标签 |

---

## Calendar 集成

### 创建事件

```python
from datetime import datetime, timedelta
from googleapiclient.discovery import build

def create_calendar_event(service, summary, description, 
                          start_time, end_time, attendees=None):
    event = {
        'summary': summary,
        'description': description,
        'start': {
            'dateTime': start_time.isoformat(),
            'timeZone': 'Asia/Shanghai',
        },
        'end': {
            'dateTime': end_time.isoformat(),
            'timeZone': 'Asia/Shanghai',
        },
    }
    if attendees:
        event['attendees'] = [{'email': e} for e in attendees]
    
    event = service.events().insert(
        calendarId='primary', body=event
    ).execute()
    print(f"📅 事件已创建: {event.get('htmlLink')}")
    return event

# 使用示例
service = build('calendar', 'v3', credentials=creds)
now = datetime.now()
create_calendar_event(
    service,
    summary='Sprint 评审',
    description='第 12 次 Sprint 评审会议',
    start_time=now + timedelta(days=1),
    end_time=now + timedelta(days=1, hours=1),
    attendees=['dev@example.com', 'pm@example.com']
)
```

### 查询日程

```python
def list_upcoming_events(service, max_results=10):
    now = datetime.utcnow().isoformat() + 'Z'
    events_result = service.events().list(
        calendarId='primary',
        timeMin=now,
        maxResults=max_results,
        singleEvents=True,
        orderBy='startTime'
    ).execute()
    
    for event in events_result.get('items', []):
        start = event['start'].get('dateTime', event['start'].get('date'))
        print(f"  🕐 {start}: {event['summary']}")
```

---

## Drive 集成

### 文件操作

```python
def upload_file(service, filepath, mime_type='text/plain'):
    """上传文件到 Drive"""
    from googleapiclient.http import MediaFileUpload
    
    file_metadata = {'name': filepath.split('/')[-1]}
    media = MediaFileUpload(filepath, mimetype=mime_type)
    
    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, webViewLink'
    ).execute()
    print(f"📄 文件已上传: {file.get('webViewLink')}")

def search_files(service, query):
    """搜索 Drive 文件"""
    results = service.files().list(
        q=query, pageSize=10,
        fields="files(id, name, mimeType, webViewLink)"
    ).execute()
    
    for file in results.get('files', []):
        print(f"  📎 {file['name']} ({file['mimeType']})")
        print(f"     {file.get('webViewLink', '')}")
```

---

## Sheets 集成

### 读写电子表格

```python
def write_to_sheet(service, spreadsheet_id, range_name, values):
    """写入数据到 Google Sheets"""
    body = {'values': values}
    result = service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=range_name,
        valueInputOption='USER_ENTERED',
        body=body
    ).execute()
    print(f"📊 已写入 {result.get('updatedCells')} 个单元格")

def read_from_sheet(service, spreadsheet_id, range_name):
    """读取 Google Sheets 数据"""
    result = service.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id,
        range=range_name
    ).execute()
    return result.get('values', [])

# 使用示例
service = build('sheets', 'v4', credentials=creds)

# 写入
data = [
    ['日期', '提交数', '覆盖率'],
    ['2024-01-01', 12, '85%'],
    ['2024-01-02', 8, '87%'],
]
write_to_sheet(service, 'SPREADSHEET_ID', 'Sheet1!A1:C3', data)

# 读取
values = read_from_sheet(service, 'SPREADSHEET_ID', 'Sheet1!A1:C10')
for row in values:
    print(f"  📊 {row}")
```

---

## Docs 集成

### 创建和编辑文档

```python
def create_doc(service, title, content):
    """创建 Google Docs 文档"""
    doc = service.documents().create(body={'title': title}).execute()
    doc_id = doc['documentId']
    
    # 写入内容
    requests = [
        {
            'insertText': {
                'location': {'index': 1},
                'text': content
            }
        }
    ]
    service.documents().batchUpdate(
        documentId=doc_id, body={'requests': requests}
    ).execute()
    
    print(f"📝 文档已创建: https://docs.google.com/document/d/{doc_id}")
    return doc_id
```

---

## Hermes Agent 集成

在 Hermes Agent 中，通过自然语言操作 Google Workspace：

```
"发送邮件给团队：构建成功，版本 v2.1.0 已部署到生产环境"
"在明天的下午 3 点创建 Sprint 回顾会议，发送邀请给 team@example.com"
"上传项目根目录的 report.md 到 Drive 的 /reports 文件夹"
"读取上周的提交数据表格，生成 CSV"
```

Agent 会自动识别意图，调用对应的 Google API 执行操作，并返回结果摘要。

---

## 最佳实践

1. **令牌管理** — OAuth token 会过期，需实现刷新逻辑
2. **错误重试** — Google API 有速率限制，使用指数退避重试
3. **最小权限** — 仅请求需要的作用域（scope）
4. **本地缓存** — 频繁查询的结果在本地缓存以减少 API 调用
5. **批量操作** — Sheets 批量更新比逐行更新快 100 倍

---

## 相关技能

- [[02-notion]] — Notion API 管理
- [[03-linear]] — Linear 项目管理
- [[06-email-management]] — 邮件管理（himalaya）
