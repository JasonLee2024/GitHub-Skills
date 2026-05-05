---
date: 2026-05-05
tags:
  - himalaya
  - email
  - imap
  - smtp
  - mail-management
  - cli
  - productivity
  - 生产工具与效率
source_skill: himalaya
category: 生产工具与效率
---

# 邮件管理（Himalaya CLI）

> 本文档基于 Hermes Agent 的 `himalaya` 技能整理，覆盖通过 Himalaya CLI 管理 IMAP/SMTP 邮件的完整流程。

## 概述

Himalaya 是一款基于 Rust 编写的**命令行邮件客户端**，支持 IMAP 和 SMTP 协议。它的核心优势在于：
- **极速** — Rust 编译，秒级响应
- **纯 CLI** — 适合自动化脚本和管道处理
- **多账户** — 同时管理多个邮箱账户
- **加密支持** — TLS/SSL 连接
- **附件管理** — 下载和发送附件

### 核心能力

| 操作 | 命令 | 说明 |
|------|------|------|
| 列出邮件 | `himalaya list` | 列出收件箱邮件 |
| 阅读邮件 | `himalaya read <id>` | 查看邮件详情 |
| 发送邮件 | `himalaya send` | 编写并发送邮件 |
| 搜索邮件 | `himalaya search` | 搜索邮件内容 |
| 管理文件夹 | `himalaya folders` | 列出/切换邮箱文件夹 |
| 附件操作 | `himalaya attachment` | 下载/查看附件 |
| 账户管理 | `himalaya account` | 管理多账户 |

---

## 安装

```bash
# 方法 1：Cargo（推荐）
cargo install himalaya

# 方法 2：Linux 包管理器
# Ubuntu/Debian
sudo apt-get install himalaya

# macOS
brew install himalaya

# 方法 3：二进制发布
# 从 https://github.com/soywod/himalaya/releases 下载
```

---

## 配置

### 配置文件位置

```bash
# 全局配置
~/.config/himalaya/config.toml
# 或
$XDG_CONFIG_HOME/himalaya/config.toml

# Windows
%APPDATA%/himalaya/config.toml
```

### 基本配置示例

```toml
[accounts.default]
name = "张三"
email = "zhangsan@example.com"
imap_host = "imap.example.com"
imap_port = 993
imap_login = "zhangsan@example.com"
imap_pass_cmd = "pass show email/zhangsan"  # 密码命令
smtp_host = "smtp.example.com"
smtp_port = 465
smtp_login = "zhangsan@example.com"
smtp_pass_cmd = "pass show email/zhangsan"
```

### 多账户配置

```toml
[accounts]
default = "personal"
work = "work"

[accounts.personal]
name = "张三"
email = "zhangsan@gmail.com"
# ... gmail 配置

[accounts.work]
name = "Zhang San"
email = "zhang.san@company.com"
# ... 企业邮箱配置
```

### Gmail 特殊配置

```toml
[accounts.gmail]
name = "张三"
email = "username@gmail.com"
imap_host = "imap.gmail.com"
imap_port = 993
imap_login = "username@gmail.com"
# 需要生成 Gmail App Password: Google Account → Security → App Passwords
imap_pass_cmd = "echo 'your-app-password'"
smtp_host = "smtp.gmail.com"
smtp_port = 465
smtp_login = "username@gmail.com"
smtp_pass_cmd = "echo 'your-app-password'"
```

---

## 常用命令

### 列出邮件

```bash
# 列出收件箱（默认 20 封）
himalaya list

# 指定文件夹和数量
himalaya list -f INBOX -p 2 -s 50   # 第 2 页，每页 50 封

# 指定账户
himalaya list -a work

# 只显示未读
himalaya list -f INBOX -t "UNSEEN"

# 自定义显示格式
himalaya list --format "{id} | {date} | {from} | {subject}"
```

### 输出格式示例

```
 ID │ DATE                │ FROM                   │ SUBJECT
────┼─────────────────────┼────────────────────────┼────────────────────
  1 │ 2024-05-05 09:30    │ GitHub <noreply@github> │ [GitHub] PR #42 审核通过
  2 │ 2024-05-05 10:15    │ CI Bot <ci@company>     │ 构建成功: main #1234
  3 │ 2024-05-05 11:00    │ 张三 <zs@company>        │ 会议邀请: Sprint 评审
```

### 阅读邮件

```bash
# 阅读指定邮件
himalaya read 1

# 原始格式（不渲染）
himalaya read 1 --raw

# 下载附件
himalaya read 1 --attachment 1 -o ./downloads/

# 保存邮件为 eml 文件
himalaya read 1 -o ./archive/email.eml
```

### 发送邮件

```bash
# 交互式编写
himalaya send

# 直接发送
himalaya send \
  --to "team@example.com" \
  --cc "manager@example.com" \
  --subject "构建通知" \
  --body "v2.1.0 构建成功 ✅" \
  --attach "./report.pdf"

# 从文件读取正文
himalaya send --to "user@example.com" \
  --subject "周报" \
  --body-body "$(cat weekly_report.md)"
```

### 搜索邮件

```bash
# 搜索主题和正文
himalaya search "构建失败"

# 高级搜索（IMAP 搜索语法）
himalaya search "FROM github.com SUBJECT deploy" -f INBOX

# 搜索附件
himalaya search "HAS attachment"
```

### 文件夹管理

```bash
# 列出所有文件夹
himalaya folders

# 切换文件夹
himalaya list -f "INBOX/Sent"

# 创建文件夹
himalaya folder create "INBOX/Archive/2024"
```

---

## 自动化脚本

### CI/CD 通知脚本

```bash
#!/bin/bash
# notify.sh — 构建完成后发送通知邮件

BUILD_STATUS=$1
PROJECT=$2
BRANCH=$3
COMMIT_SHA=$4

if [ "$BUILD_STATUS" = "success" ]; then
  SUBJECT="✅ [CI] $PROJECT/$BRANCH 构建成功"
  BODY="提交: $COMMIT_SHA\n分支: $BRANCH\n状态: 成功 ✅\n\n查看详情: $CI_PIPELINE_URL"
else
  SUBJECT="❌ [CI] $PROJECT/$BRANCH 构建失败"
  BODY="提交: $COMMIT_SHA\n分支: $BRANCH\n状态: 失败 ❌\n\n查看详情: $CI_PIPELINE_URL"
fi

himalaya send \
  --to "team@example.com" \
  --subject "$SUBJECT" \
  --body "$BODY" \
  -a work
```

### 每日邮件摘要

```bash
#!/bin/bash
# daily_digest.sh — 生成每日邮件摘要

DATE=$(date +%Y-%m-%d)
OUTPUT="/tmp/digest_$DATE.md"

echo "# 邮件摘要 - $DATE" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "## 未读邮件" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
himalaya list -f INBOX -t "UNSEEN" --format \
  "| {date} | {from} | {subject} |" >> "$OUTPUT"
echo '```' >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "## 今日重要邮件" >> "$OUTPUT"

# 发送摘要给自己
himalaya send \
  --to "me@example.com" \
  --subject "每日邮件摘要 $DATE" \
  --body-body "$OUTPUT"

echo "✅ 摘要已发送"
```

### 邮件自动归档

```bash
#!/bin/bash
# archive.sh — 自动归档 7 天前的已读邮件

DAYS_OLD=7
ARCHIVE_FOLDER="INBOX/Archive"

himalaya list -f INBOX -t "SEEN" --format "{id}" | while read id; do
  # 获取邮件日期
  DATE=$(himalaya read $id --raw | grep "^Date:" | head -1)
  TIMESTAMP=$(date -d "$DATE" +%s)
  CUTOFF=$(date -d "$DAYS_OLD days ago" +%s)
  
  if [ $TIMESTAMP -lt $CUTOFF ]; then
    himalaya copy $id "$ARCHIVE_FOLDER"
    himalaya delete $id
    echo "📦 已归档 邮件 ID: $id"
  fi
done
```

---

## 最佳实践

1. **密码管理** — 使用 `pass`, `1password-cli` 等工具管理邮箱密码
2. **账户切换** — 日常使用 `-a <account>` 参数管理多账户
3. **别名配置** — 在 shell 配置中添加别名
   ```bash
   alias mail="himalaya"
   alias mail-w="himalaya -a work"
   alias mail-s="himalaya search"
   ```
4. **批量操作** — 使用 `xargs` 批量处理邮件
   ```bash
   himalaya list -t "UNSEEN" --format "{id}" | xargs -I{} himalaya read {}
   ```
5. **自动回复** — 结合 `vacation` 过滤规则实现自动回复

---

## 相关技能

- [[01-google-workspace]] — Google Workspace 集成
- [[02-notion]] — Notion API 管理
- [[07-ocr-documents]] — OCR 与文档提取
