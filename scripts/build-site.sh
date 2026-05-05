#!/bin/bash
# build-site.sh — Build the knowledge base as a static site for GitHub Pages
# Usage: scripts/build-site.sh [output-dir]

set -euo pipefail

OUTPUT_DIR="${1:-_site}"
BASE_DIR=$(dirname "$(dirname "$(realpath "$0")")")

echo "=== Building Static Site ==="

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy all markdown files as-is (GitHub Pages can serve markdown)
# For a richer experience, this would use Quartz or MkDocs
# For now, we copy the structure and create HTML wrappers

echo "Copying knowledge base structure..."
cp -r "$BASE_DIR"/*.md "$OUTPUT_DIR/" 2>/dev/null || true
cp -r "$BASE_DIR"/[0-9]* "$BASE_DIR"/[a-z]* "$OUTPUT_DIR/" 2>/dev/null || true

# Generate a simple index.html
cat > "$OUTPUT_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GitHub 技能知识库</title>
  <style>
    :root { --bg: #0d1117; --fg: #c9d1d9; --accent: #58a6ff; --border: #30363d; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; background: var(--bg); color: var(--fg); line-height: 1.6; max-width: 900px; margin: 0 auto; padding: 2rem; }
    h1 { color: var(--accent); border-bottom: 1px solid var(--border); padding-bottom: 0.5rem; margin-bottom: 1.5rem; }
    h2 { color: var(--accent); margin-top: 2rem; margin-bottom: 1rem; }
    h3 { margin-top: 1.5rem; }
    a { color: var(--accent); text-decoration: none; }
    a:hover { text-decoration: underline; }
    ul { padding-left: 1.5rem; margin: 0.5rem 0; }
    li { margin: 0.3rem 0; }
    p { margin: 0.5rem 0; }
    .tag { display: inline-block; background: #21262d; padding: 0.15rem 0.5rem; border-radius: 3px; font-size: 0.8rem; margin: 0.2rem; border: 1px solid var(--border); }
    .section { border: 1px solid var(--border); border-radius: 6px; padding: 1rem; margin: 1rem 0; }
    .section h3 { margin-top: 0; }
  </style>
</head>
<body>
  <h1>GitHub 技能知识库</h1>
  <p>基于 Hermes Agent 76 个技能的精华分析，以开发者学习路径为导向的 GitHub 知识体系。</p>
  
  <div id="content">
    <h2>章节索引</h2>
    <div id="chapters"></div>
  </div>

  <script>
    const chapters = [
      { num: '01', title: '入门指南', path: '01-入门指南/_index.md', desc: '环境准备、认证、基础操作' },
      { num: '02', title: 'GitHub 核心操作', path: '02-GitHub-核心操作/_index.md', desc: '仓库、Issues、PR、代码审查' },
      { num: '03', title: '软件开发方法论', path: '03-软件开发方法论/_index.md', desc: 'TDD、Plan、Debug、Review' },
      { num: '04', title: '自动化与 CI/CD', path: '04-自动化与CI-CD/_index.md', desc: 'Actions、Pages、Webhook' },
      { num: '05', title: '自主 AI Agent', path: '05-自主AI-Agent/_index.md', desc: 'Hermes、Claude Code、Codex' },
      { num: '06', title: 'MLOps & AI 工程', path: '06-MLOps-与-AI-工程/_index.md', desc: '推理、微调、训练、部署' },
      { num: '07', title: '科研工作流', path: '07-科研工作流/_index.md', desc: '论文搜索、知识库构建' },
      { num: '08', title: '创意与可视化', path: '08-创意与可视化/_index.md', desc: '信息图、图表、动画' },
      { num: '09', title: '生产工具与效率', path: '09-生产工具与效率/_index.md', desc: 'Google Workspace、Notion、Linear' },
      { num: '10', title: '运维与监控', path: '10-运维与监控/_index.md', desc: 'Webhook、RSS、Pages 运维' },
      { num: '11', title: '安全与红队', path: '11-安全与红队/_index.md', desc: '安全审查、红队测试' },
      { num: '12', title: '最佳实践与模式', path: '12-最佳实践与模式/_index.md', desc: '综合工作流、最佳实践' },
      { num: '99', title: '附录与速查', path: '99-附录与速查/_index.md', desc: 'API 速查、CLI 命令、术语表' },
    ];
    
    const container = document.getElementById('chapters');
    chapters.forEach(ch => {
      const div = document.createElement('div');
      div.className = 'section';
      div.innerHTML = `<h3><a href="${ch.path}">${ch.num} — ${ch.title}</a></h3><p>${ch.desc}</p>`;
      container.appendChild(div);
    });
  </script>
</body>
</html>
EOF

echo "=== Site built at: $OUTPUT_DIR ==="
echo "Total files: $(find "$OUTPUT_DIR" -type f | wc -l)"
