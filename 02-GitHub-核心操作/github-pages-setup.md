---
date: 2026-05-05
tags:
  - github
  - pages
  - deployment
  - jekyll
  - static-site
  - GitHub核心操作
source_skill: github-pages-setup
category: GitHub 核心操作
---

# GitHub Pages 部署指南

> 本文档基于 Hermes Agent 的 `github-pages-setup` 技能整理，涵盖从启用 Pages 到自定义域名的全流程。

## 概述

GitHub Pages 是 GitHub 提供的免费静态网站托管服务。适合托管个人博客、项目文档、简历、知识库等纯静态内容。有三种 Pages 类型：

1. **User/Organization Pages** — `username.github.io`，一个用户只能有一个
2. **Project Pages** — `username.github.io/repo-name`，每个项目都可以有
3. **Organization Pages** — `org.github.io`，组织专属

本文档聚焦于 Project Pages 的部署实操，这也是知识库部署的常用方式。

---

## 一、启用 GitHub Pages

### 方法一：通过 GitHub Web UI

1. 进入仓库 → **Settings** → **Pages**
2. 在 "Source" 下拉菜单中选择 `Deploy from a branch`
3. 选择分支（通常是 `main` 或 `gh-pages`）和目录（`/` 根目录或 `/docs`）
4. 点击 **Save**

### 方法二：通过 gh CLI

```bash
# 查看当前 Pages 配置
gh api repos/$OWNER/$REPO/pages

# 启用 Pages（从 main 分支根目录部署）
gh api --method POST repos/$OWNER/$REPO/pages \
  -f source='{"branch":"main","path":"/"}'

# 如果已经启用，可以更新配置
gh api --method PUT repos/$OWNER/$REPO/pages \
  -f source='{"branch":"main","path":"/docs"}'
```

### 方法三：通过 curl API

```bash
# 启用 Pages
curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$OWNER/$REPO/pages \
  -d '{
    "source": {
      "branch": "main",
      "path": "/"
    }
  }'

# 更新配置
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pages \
  -d '{
    "source": {
      "branch": "main",
      "path": "/docs"
    }
  }'
```

---

## 二、构建与部署方式

GitHub Pages 支持两种构建方式：

### 方式 1：Legacy 构建（默认）

直接从分支提供静态文件。最简单，适合纯 HTML/CSS/JS。

```
仓库: main 分支根目录 → 直接部署
```

特点：不需要配置构建步骤，推代码即部署。

### 方式 2：GitHub Actions 构建（推荐）

通过 GitHub Actions 工作流构建后部署，适合需要预处理（Jekyll、Hugo、Next.js 等）的项目。

```yaml
# .github/workflows/pages.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/jekyll-build-pages@v1
      - uses: actions/upload-pages-artifact@v3

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

启用 Actions 构建后，需要在 Pages 设置中将 Source 改为 **GitHub Actions**。

---

## 三、Jekyll 配置与常见问题

GitHub Pages 内建 Jekyll 支持。如果你的仓库根目录有 `_config.yml`，Jekyll 会自动构建。

### 基础配置

```yaml
# _config.yml
title: "我的知识库"
description: "技术学习研究积累"
theme: jekyll-theme-cayman
markdown: kramdown
```

### 常见问题：日期解析错误

这是 Jekyll 最常见的报错之一：

```
Recursive dependency detected when processing ...
Liquid Exception: Liquid syntax error ...
```

**原因：** Jekyll 自动为 Markdown 文件推断 `date` 属性，如果文件名以日期开头（如 `2026-01-01-post.md`），Jekyll 会尝试解析并可能与其他插件冲突。

**解决方案：**

1. **在 `_config.yml` 中关闭自动日期推断**
```yaml
# _config.yml
future: true
# 如果有日期相关报错，添加：
defaults:
  - scope:
      path: ""
    values:
      layout: default
```

2. **移除文件名中的日期前缀**
   - `2026-01-01-post.md` → `post.md`
   - 或者在文件 YAML frontmatter 中显式声明 `date` 字段

3. **排除冲突文件**
```yaml
exclude:
  - vendor/
  - node_modules/
  - "*.md"  # 根据需要调整
```

4. **禁用 Liquid 标签处理**（如果是包含模板语法）
```yaml
markdown: kramdown
kramdown:
  parse_block_html: false
```

---

## 四、自定义域名

### 配置步骤

1. **在域名提供商处添加 CNAME 记录**
   - 记录类型：`CNAME`
   - 名称：`www` 或 `@`
   - 目标：`<你的用户名>.github.io`

2. **在仓库中添加 CNAME 文件**

```bash
# 在仓库根目录创建 CNAME 文件
echo "www.yourdomain.com" > CNAME
git add CNAME && git commit -m "chore: add custom domain" && git push
```

3. **或者通过 Web UI 配置**
   - Settings → Pages → Custom domain
   - 输入域名，点击 Save
   - 等待 DNS 解析（可能需要几分钟到几小时）

### 通过 API 配置

```bash
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$OWNER/$REPO/pages \
  -d '{"cname": "www.yourdomain.com", "source": {"branch": "main", "path": "/"}}'
```

### HTTPS 强制

GitHub Pages 自动为自定义域名提供 HTTPS。启用后，所有 HTTP 请求会被 301 重定向到 HTTPS。

---

## 五、验证部署

```bash
# 检查 Pages 部署状态
curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pages \
  | python3 -c "
import sys, json
p = json.load(sys.stdin)
print(f'状态: {p.get(\"status\", \"未知\")}')
print(f'URL: {p.get(\"html_url\", \"\")}')
print(f'分支: {p[\"source\"][\"branch\"]}  路径: {p[\"source\"][\"path\"]}')
print(f'自定义域名: {p.get(\"cname\", \"无\")}')
print(f'HTTPS 强制: {p.get(\"https_enforced\", \"否\")}')
print(f'构建类型: {p.get(\"build_type\", \"legacy\")}')"

# 或用 gh CLI
gh api repos/$OWNER/$REPO/pages --jq '.html_url'
```

---

## 六、工作流程建议

### 最佳实践

1. **先用 Legacy 模式快速验证** — 直接部署 `main` 分支根目录，确认页面能访问
2. **再切换 Actions 构建** — 需要预处理时再配工作流
3. **`.nojekyll` 文件** — 如果不想用 Jekyll，在根目录放个空文件 `.nojekyll` 即可禁用
4. **注意文件大小** — Pages 部署有上限（1GB/仓库，每月 100GB 带宽），大文件用 CDN

### 故障排查速查

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 404 页面 | 没有 `index.html` 或部署未完成 | 等待 1-2 分钟，检查 Actions 状态 |
| 样式丢失 | 相对路径问题 | 检查 CSS/JS 引用路径，用 `site.baseurl` |
| Jekyll 构建失败 | `_config.yml` 语法错误 | 本地 `jekyll build` 调试 |
| 日期解析错误 | 文件名以日期开头 | 改名或设置 `future: true` |
| 自定义域名 404 | DNS 未生效 | `dig yourdomain.com CNAME` 检查解析 |
| HTTPS 证书失败 | DNS 刚变更有延迟 | 等待几分钟到 24 小时 |

## 相关链接

- [[01-入门指南/github-auth]] — 认证基础
- [[01-入门指南/github-repo-management]] — 仓库管理（创建和配置仓库）
- [[github-pr-workflow]] — PR 工作流
- [[../04-自动化与CI-CD/github-actions]] — GitHub Actions
- [[../99-附录与速查/术语表|术语表]]
