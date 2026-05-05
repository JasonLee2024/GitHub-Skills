---
date: 2026-05-05
tags:
  - github-actions
  - ci-cd
  - workflow
  - deployment
  - testing
  - automation
  - 自动化与CI-CD
source_skill: github-repo-management
category: 自动化与 CI-CD
---

# CI/CD 工作流设计模式

> 本文档基于 GitHub Actions 生态系统，系统介绍 CI/CD（持续集成/持续交付）的设计模式、最佳实践和实际案例。

## 概述

CI/CD（Continuous Integration / Continuous Delivery）是现代软件开发的核心实践。它通过自动化构建、测试和部署流程，确保代码变更能够快速、安全地交付到生产环境。

### 核心概念

| 概念 | 说明 | 关键目标 |
|------|------|---------|
| **持续集成 (CI)** | 频繁合并代码变更并自动运行测试 | 尽早发现集成问题 |
| **持续交付 (CD)** | 自动将验证通过的代码部署到预发布环境 | 随时可安全发布 |
| **持续部署** | 持续交付的延伸——自动部署到生产环境 | 完全自动化发布流程 |
| **左移测试** | 将测试提前到开发周期的早期阶段 | 降低修复成本 |

### GitHub Actions 工作流基础

GitHub Actions 使用 YAML 文件定义自动化流程，存放在 `.github/workflows/` 目录下。

最基本的工作流结构：

```yaml
name: CI Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run a script
        run: echo "Hello, CI!"
```

## 工作流触发器（Events）

GitHub Actions 支持多种触发器事件，选择合适的触发模式是设计高效 CI/CD 流程的第一步。

### 基础触发模式

```yaml
# 代码推送触发
on:
  push:
    branches: [main, develop]
    paths-ignore: ['docs/**', '*.md']  # 忽略文档变更

# PR 触发
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]

# 定时触发（cron 语法）
on:
  schedule:
    - cron: '0 2 * * *'  # 每天 UTC 2:00
    - cron: '0 0 * * 0'   # 每周日 UTC 0:00

# 手动触发
on:
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

# 复合触发
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
  schedule: [{ cron: '0 0 * * *' }]
  workflow_dispatch: {}
```

### 高级触发模式

```yaml
# 路径过滤——仅当特定目录变更时触发
on:
  push:
    paths:
      - 'src/**'
      - 'tests/**'
      - 'Dockerfile'
      - '.github/workflows/**'

# 标签触发——常用于发布流程
on:
  push:
    tags:
      - 'v*'
      - 'release-*'

# 工作流调用（可复用工作流）
on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js 版本'
        required: true
        type: string
    secrets:
      NPM_TOKEN:
        required: true
```

## 标准工作流设计模式

### 模式 1：基础 CI —— 测试 + 构建

这是最简单的 CI 模式，适合大多数项目：

```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  test:
    needs: lint
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/
```

### 模式 2：矩阵构建 —— 多版本/多平台测试

```yaml
name: Matrix CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [18, 20]
        include:
          - os: ubuntu-latest
            node: 22
        exclude:
          - os: windows-latest
            node: 18
      fail-fast: false  # 继续执行其他矩阵任务

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm ci
      - run: npm test
```

**矩阵策略配置参数：**
- `matrix` — 定义要测试的维度组合
- `include` — 添加额外的组合
- `exclude` — 排除特定组合
- `fail-fast` — 是否在一个矩阵任务失败时取消所有其他任务

### 模式 3：Docker 构建与推送

```yaml
name: Docker Build & Push
on:
  push:
    branches: [main]
    tags: ['v*']

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to container registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix=,suffix=,format=short
            type=ref,event=branch

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 模式 4：多环境部署流水线

```yaml
name: Deploy
on:
  push:
    branches: [main, staging]
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run lint
      - run: npm test

  build:
    needs: lint-and-test
    runs-on: ubuntu-latest
    outputs:
      artifact-name: ${{ steps.build.outputs.artifact-name }}

    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - id: build
        uses: actions/upload-artifact@v4
        with:
          name: build-${{ github.sha }}
          path: dist/

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build-${{ github.sha }}
          path: dist/
      - name: Deploy to staging
        run: |
          echo "Deploying to staging..."
          # 部署脚本

  deploy-production:
    needs: [build, deploy-staging]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: build-${{ github.sha }}
          path: dist/
      - name: Deploy to production
        run: |
          echo "Deploying to production..."
          # 部署脚本
```

## 高级 CI/CD 技术

### 可复用工作流

创建通用工作流模板，在多个项目间共享：

```yaml
# .github/workflows/node-ci.yml (可复用)
name: Node.js CI Template
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
        default: '20'
      run-lint:
        required: false
        type: boolean
        default: true
    secrets:
      NPM_TOKEN:
        required: false

jobs:
  lint:
    if: ${{ inputs.run-lint }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm test
```

引用方式：

```yaml
# 其他仓库中使用
name: CI
on: [push, pull_request]
jobs:
  ci:
    uses: org/shared-workflows/.github/workflows/node-ci.yml@main
    with:
      node-version: '20'
      run-lint: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 复合 Action

将多个步骤封装为可复用的 Action：

```yaml
# .github/actions/setup-node-env/action.yml
name: 'Setup Node.js Environment'
description: 'Setup Node.js with caching and npm install'
inputs:
  node-version:
    description: 'Node.js version'
    required: true
    default: '20'
outputs:
  cache-hit:
    description: 'npm cache hit'
    value: ${{ steps.cache.outputs.cache-hit }}

runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - id: cache
      uses: actions/cache@v3
      with:
        path: ~/.npm
        key: npm-${{ hashFiles('package-lock.json') }}
    - run: npm ci
      shell: bash
```

### 自托管 Runner

对于需要特定硬件或更大资源的场景：

```yaml
jobs:
  build-on-prem:
    runs-on: [self-hosted, linux, x64, gpu]
    steps:
      - uses: actions/checkout@v4
      - run: make build
```

配置自托管 Runner：

```bash
# 在服务器上注册 Runner
# 仓库 Settings → Actions → Runners → Add runner
./config.sh --url https://github.com/owner/repo --token AAAA...

# 作为服务运行
sudo ./svc.sh install
sudo ./svc.sh start
```

### OIDC（OpenID Connect）认证

使用 OIDC 替代长期密钥，提升安全性：

```yaml
jobs:
  deploy-to-aws:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # 允许请求 OIDC token
      contents: read

    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActions
          aws-region: us-east-1
      - run: aws s3 sync ./dist s3://my-bucket/
```

## 缓存策略

有效的缓存可以显著减少工作流执行时间：

```yaml
# npm 缓存
- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: npm-${{ hashFiles('package-lock.json') }}-${{ runner.os }}
    restore-keys: |
      npm-${{ hashFiles('package-lock.json') }}-
      npm-

# pip 缓存（Python）
- uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: pip-${{ hashFiles('**/requirements.txt') }}

# Docker layer 缓存
- uses: docker/setup-buildx-action@v3
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## GitHub Pages 部署

详细内容参见 [[../02-GitHub-核心操作/github-pages-setup]]，这里给出标准的 GitHub Actions 部署方式：

```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

## CI/CD 安全最佳实践

### 密钥管理

```bash
# 使用 gh CLI 管理 Actions secrets
gh secret set DOCKER_USERNAME --body "$DOCKER_USERNAME"
gh secret set DOCKER_PASSWORD --body "$DOCKER_PASSWORD"

# 查看已配置的 secrets
gh secret list

# 删除 secret
gh secret delete API_KEY
```

### 最小权限原则

```yaml
jobs:
  test:
    permissions:
      contents: read       # 只需要读取代码
      checks: write        # 写入检查结果
    steps:
      - uses: actions/checkout@v4
      - run: npm test
```

### 工作流安全清单

1. **避免内联密钥** — 始终使用 `secrets` 上下文
2. **锁定 Action 版本** — 使用 SHA hash 而非版本标签：`actions/checkout@<sha>`
3. **限制触发条件** — 精确配置 `on:` 触发条件
4. **使用 OIDC** — 减少长期密钥的存储
5. **审计第三方 Action** — 检查来源和代码质量
6. **配置环境保护规则** — 生产环境需要批准的部署规则
7. **清理临时文件** — 使用 `actions/upload-artifact` 后及时删除

## 调试 CI/CD

### 使用 tmate 会话调试

```yaml
- name: Debug with tmate
  if: ${{ failure() }}
  uses: mxschmitt/action-tmate@v3
  with:
    limit-access-to-actor: true
```

### 查看工作流日志

```bash
# 列出最近的运行
gh run list --limit 10

# 查看特定运行
gh run view <RUN_ID>

# 查看失败的步骤
gh run view <RUN_ID> --log-failed

# 重新运行
gh run rerun <RUN_ID>
gh run rerun <RUN_ID> --failed
```

## 实际案例：完整项目流水线

结合本节所有模式，构建一个完整的项目 CI/CD 流水线：

```yaml
name: Full Project Pipeline
on:
  push:
    branches: [main, develop]
    paths-ignore: ['docs/**', '*.md']
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # 每周一 6:00 UTC 安全扫描
  workflow_dispatch: {}

jobs:
  # Stage 1: 代码质量
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'npm' }
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check

  # Stage 2: 测试（矩阵）
  test:
    needs: quality
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ matrix.node-version }}, cache: 'npm' }
      - run: npm ci
      - run: npm test -- --coverage
      - uses: codecov/codecov-action@v3

  # Stage 3: 安全扫描
  security:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
      - uses: github/codeql-action/analyze@v3

  # Stage 4: 构建
  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with: { name: build, path: dist/ }

  # Stage 5: 部署（develop → staging）
  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/download-artifact@v4
        with: { name: build, path: dist/ }
      - run: ./deploy-staging.sh

  # Stage 6: 部署（main → production）
  deploy-production:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/download-artifact@v4
        with: { name: build, path: dist/ }
      - run: ./deploy-production.sh
```

## 相关文档

- [[webhook-subscriptions]] — Webhook 订阅管理
- [[automation-patterns]] — 自动化模式
- [[../02-GitHub-核心操作/github-pages-setup]] — GitHub Pages 部署
- [[../03-软件开发方法论/test-driven-development]] — 测试驱动开发
- [[../10-运维与监控]] — 运维与监控
