---
date: 2026-05-05
tags:
  - github-pages
  - static-site
  - deployment
  - dns
  - https
  - operations
  - 运维与监控
source_skill: github-pages-setup
category: 运维与监控
---

# GitHub Pages 运维

> 本文档基于 Hermes Agent 的 `github-pages-setup` 技能整理，覆盖 Pages 部署、域名配置、HTTPS 启用和常见问题排查。

## 概述

GitHub Pages 是 GitHub 提供的**静态网站托管服务**，支持从仓库的特定分支直接部署 HTML/CSS/JS 网站。适合个人博客、项目文档、知识库等场景。

### 三种 Pages 类型

| 类型 | URL 格式 | 适用场景 |
|------|---------|---------|
| User/Org 站点 | `username.github.io` | 个人主页、博客 |
| 项目站点 | `username.github.io/repo` | 项目文档 |
| 自定义域名 | `yourdomain.com` | 品牌化展示 |

---

## 基础配置

### 通过 GitHub CLI 配置

```bash
# 启用 Pages（使用默认分支 main，根目录）
gh api repos/:owner/:repo/pages \
  --method POST \
  --field source='{"branch":"main","path":"/"}'

# 使用 docs/ 目录
gh api repos/:owner/:repo/pages \
  --method POST \
  --field source='{"branch":"main","path":"/docs"}'

# 使用 GitHub Actions
gh api repos/:owner/:repo/pages \
  --method POST \
  --field build_type='workflow'
```

### 验证 Pages 状态

```bash
# 查看 Pages 配置
gh api repos/:owner/:repo/pages \
  --jq '{url: .html_url, status: .status, cname: .cname, https: .https_certificate}'

# 检查部署状态
gh api repos/:owner/:repo/pages/deployments \
  --jq '.[0] | {status, created_at, html_url}'

# 列出所有 Pages 构建
gh api repos/:owner/:repo/pages/builds \
  --jq '.[] | "\(.created_at) | \(.status) | \(.error.message // "ok")"'
```

---

## GitHub Actions 部署

### 使用静态站点生成器

常见的静态站点生成器集成：

| 工具 | 语言 | 配置文件 | 典型构建命令 |
|------|------|---------|-------------|
| Jekyll | Ruby | `_config.yml` | `jekyll build` |
| Hugo | Go | `hugo.yaml` | `hugo` |
| MkDocs | Python | `mkdocs.yml` | `mkdocs build` |
| Docusaurus | Node.js | `docusaurus.config.js` | `npm run build` |
| Astro | Node.js | `astro.config.mjs` | `npm run build` |
| VuePress | Node.js | `config.js` | `vuepress build` |

### GitHub Actions 部署工作流

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
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 设置 Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: 构建站点
        run: |
          pip install mkdocs mkdocs-material
          mkdocs build

      - name: 上传 Pages 构件
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: 部署到 GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 自定义域名配置

### 添加 CNAME

```bash
# 方式 1：在仓库根目录创建 CNAME 文件
echo "blog.example.com" > CNAME
git add CNAME
git commit -m "添加自定义域名"
git push

# 方式 2：通过 API 设置
gh api repos/:owner/:repo/pages \
  --method PUT \
  --field cname='blog.example.com'
```

### DNS 配置

根据 DNS 提供商配置以下记录：

```dns
# 方案 1：Apex 域名 (example.com) — 使用 A 记录
@  IN  A  185.199.108.153
@  IN  A  185.199.109.153
@  IN  A  185.199.110.153
@  IN  A  185.199.111.153
@  IN  AAAA  2606:50c0:8000::153
@  IN  AAAA  2606:50c0:8001::153
@  IN  AAAA  2606:50c0:8002::153
@  IN  AAAA  2606:50c0:8003::153

# 方案 2：子域名 (blog.example.com) — 使用 CNAME
blog  IN  CNAME  username.github.io.
```

### DNS 配置验证

```bash
# 验证 A 记录
dig +short example.com
# 应显示 GitHub Pages IP 之一

# 验证 CNAME
dig +short blog.example.com CNAME
# 应显示 username.github.io.

# 验证 TXT 记录（部分 DNS 提供商需要）
dig +short example.com TXT
# 可能需要: "hosted-for-username.github.io"
```

### HTTPS 证书

GitHub Pages 自动为自定义域名提供 HTTPS 支持（通过 Let's Encrypt）：

```bash
# 检查 HTTPS 证书状态
gh api repos/:owner/:repo/pages \
  --jq '{https_certificate, https_enforced}'

# 强制 HTTPS
gh api repos/:owner/:repo/pages \
  --method PUT \
  --field https_enforced=true
```

**HTTPS 配置注意**：

| 状态 | 说明 | 解决方式 |
|------|------|---------|
| ❌ 域名未验证 | DNS 未正确配置 | 检查和等待 DNS 生效 |
| ⏳ 证书发放中 | Let's Encrypt 正在验证 | 等待最多 15 分钟 |
| ✅ 证书有效 | HTTPS 正常工作 | — |
| ⚠️ 即将过期 | 证书将在 30 天内过期 | GitHub 会自动续期 |

---

## 高级配置

### 自定义 404 页面

```bash
# 在仓库根目录创建 404.html
cat > 404.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>404 - 页面未找到</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      margin: 0;
    }
    .container { text-align: center; }
    h1 { font-size: 4em; margin: 0; color: #58a6ff; }
  </style>
</head>
<body>
  <div class="container">
    <h1>404</h1>
    <p>页面未找到</p>
    <a href="/" style="color: #58a6ff;">返回首页</a>
  </div>
</body>
</html>
EOF
```

### 配置 Jekyll 主题

```yaml
# _config.yml
title: 我的知识库
description: 开发者知识管理系统
theme: jekyll-theme-cayman
show_downloads: false
google_analytics: G-XXXXXXXXXX

# 自定义
github:
  repository_url: https://github.com/username/repo

# 插件
plugins:
  - jekyll-seo-tag
  - jekyll-sitemap
```

---

## 问题排查

### 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| `Page build failure` | Jekyll 构建失败 | 检查 `_config.yml` 语法 |
| `404 on custom domain` | DNS 未生效 | 验证 DNS 记录 |
| `HTTPS not available` | 域名验证未完成 | 等待或确认 DNS |
| `Mixed content` | HTTP/HTTPS 混合 | 使用相对路径 |
| `CNAME already taken` | 域名已被占用 | 验证域名所有权 |
| `Build warning` | 已弃用的配置 | 查看构建日志 |

### 调试命令

```bash
# 查看构建日志
gh api repos/:owner/:repo/pages/builds/latest \
  --jq '{status, error: .error.message, commit: .commit, duration: .duration}'

# 本地预览 Jekyll 站点
gem install jekyll bundler
cd repo
jekyll serve --watch

# 清除 Pages 缓存（强制重新部署）
gh api repos/:owner/:repo/pages/builds \
  --method POST
```

---

## 最佳实践

1. **使用 Actions 部署** — Workflow 方式比分支部署更灵活
2. **配置子域名** — 避免 Apex 域名的 DNS 配置复杂性和 IP 变更风险
3. **强制 HTTPS** — 在 Pages 设置中勾选"Enforce HTTPS"
4. **添加 Sitemap** — 生成 `sitemap.xml` 有助于搜索引擎收录
5. **监控构建** — 配置 Webhook 监控构建状态
6. **CDN 缓存** — GitHub Pages 已经通过 Fastly CDN 加速

---

## 相关技能

- [[01-webhook-ops]] — Webhook 订阅管理
- [[02-blog-monitor]] — Blog/RSS 监控
- [[04-serverless-gpu]] — Modal 无服务器 GPU 运维
