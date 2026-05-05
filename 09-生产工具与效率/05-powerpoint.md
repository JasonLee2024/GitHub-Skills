---
date: 2026-05-05
tags:
  - powerpoint
  - pptx
  - presentation
  - automation
  - slides
  - productivity
  - 生产工具与效率
source_skill: powerpoint
category: 生产工具与效率
---

# PowerPoint 自动化

> 本文档基于 Hermes Agent 的 `powerpoint` 技能整理，覆盖 .pptx 文件创建、编辑和自动化的完整流程。

## 概述

PowerPoint 自动化允许程序化地创建和编辑演示文稿。通过 python-pptx 库，开发者可以完成从简单幻灯片生成到复杂模板填充的所有操作。

### 核心能力

| 功能 | 说明 | 适用场景 |
|------|------|---------|
| 幻灯片创建 | 添加新幻灯片 | 动态生成报告 |
| 内容填充 | 添加文本、图片、表格、图表 | 模板化演示 |
| 样式控制 | 修改字体、颜色、对齐 | 品牌一致性 |
| 模板处理 | 基于模板生成 | 周报、会议纪要 |
| 动画和切换 | 设置动画效果 | 美化演示 |
| 批量生成 | 从数据源批量创建 | 销售报告、课程 |

---

## 环境准备

```bash
pip install python-pptx Pillow
```

---

## 基础操作

### 创建最简单的演示文稿

```python
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

# 创建演示文稿
prs = Presentation()

# 添加标题幻灯片
slide_layout = prs.slide_layouts[0]  # 标题幻灯片
slide = prs.slides.add_slide(slide_layout)
title = slide.shapes.title
subtitle = slide.placeholders[1]

title.text = "项目进度报告"
subtitle.text = "2024 年第一季度"

# 保存
prs.save("presentation.pptx")
print("✅ 演示文稿已创建")
```

### 幻灯片布局

python-pptx 提供多种内置布局：

```python
# 查看所有布局
prs = Presentation()
for i, layout in enumerate(prs.slide_layouts):
    print(f"  {i}: {layout.name}")

# 常用布局索引
# 0: 标题幻灯片
# 1: 标题和内容
# 2: 标题和两列内容
# 3: 空白
# 6: 标题和图片/标题
```

---

## 内容填充

### 添加文本和格式

```python
def add_text_slide(prs, title_text, body_text):
    """添加标题+内容幻灯片"""
    slide = prs.slides.add_slide(prs.slide_layouts[1])
    
    # 设置标题
    title = slide.shapes.title
    title.text = title_text
    
    # 设置正文
    body = slide.placeholders[1]
    tf = body.text_frame
    tf.text = body_text
    
    # 格式化（注意：reset 后 placeholder 可能变化）
    for paragraph in tf.paragraphs:
        paragraph.font.size = Pt(18)
        paragraph.font.color.rgb = RGBColor(0x33, 0x33, 0x33)
    
    return slide

add_text_slide(prs, "本周进展", "• 完成前端页面重构\n• 修复 12 个 Bug\n• 新增支付模块")
```

### 添加表格

```python
def add_table_slide(prs, title_text, headers, data):
    """添加数据表格幻灯片"""
    slide = prs.slides.add_slide(prs.slide_layouts[5])  # 空白布局
    
    # 添加标题
    txBox = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), 
                                      Inches(8), Inches(0.6))
    tf = txBox.text_frame
    tf.text = title_text
    
    # 添加表格
    rows = len(data) + 1  # +1 for header
    cols = len(headers)
    table_shape = slide.shapes.add_table(rows, cols, 
                                          Inches(0.5), Inches(1.2),
                                          Inches(9), Inches(4))
    table = table_shape.table
    
    # 设置列宽
    for i in range(cols):
        table.columns[i].width = Inches(9 / cols)
    
    # 填充表头
    for i, header in enumerate(headers):
        cell = table.cell(0, i)
        cell.text = header
        cell.fill.solid()
        cell.fill.fore_color.rgb = RGBColor(0x2B, 0x57, 0x9A)
        # 表头文字颜色
        for paragraph in cell.text_frame.paragraphs:
            paragraph.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            paragraph.font.bold = True
    
    # 填充数据行
    for r, row_data in enumerate(data, 1):
        for c, value in enumerate(row_data):
            cell = table.cell(r, c)
            cell.text = str(value)
            # 交替行颜色
            if r % 2 == 0:
                cell.fill.solid()
                cell.fill.fore_color.rgb = RGBColor(0xF0, 0xF0, 0xF0)
    
    return slide

# 使用示例
add_table_slide(prs, "Q1 业绩数据",
    headers=["月份", "收入", "支出", "利润"],
    data=[
        ["一月", "¥120,000", "¥80,000", "¥40,000"],
        ["二月", "¥150,000", "¥90,000", "¥60,000"],
        ["三月", "¥180,000", "¥95,000", "¥85,000"],
    ]
)
```

### 添加图表

```python
def add_chart_slide(prs, title_text, categories, values):
    """添加柱状图幻灯片"""
    from pptx.chart.data import CategoryChartData
    from pptx.enum.chart import XL_CHART_TYPE
    
    slide = prs.slides.add_slide(prs.slide_layouts[5])
    
    # 标题
    txBox = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), 
                                      Inches(8), Inches(0.6))
    txBox.text_frame.text = title_text
    
    # 图表数据
    chart_data = CategoryChartData()
    chart_data.categories = categories
    chart_data.add_series('数值', values)
    
    # 添加图表
    chart_frame = slide.shapes.add_chart(
        XL_CHART_TYPE.COLUMN_CLUSTERED,
        Inches(0.5), Inches(1.2), Inches(9), Inches(5),
        chart_data
    )
    return slide

add_chart_slide(prs, "月度活跃用户增长",
    categories=["一月", "二月", "三月", "四月", "五月"],
    values=[1200, 1800, 2500, 3200, 4100]
)
```

### 添加图片

```python
def add_image_slide(prs, title_text, image_path):
    """添加图片幻灯片"""
    slide = prs.slides.add_slide(prs.slide_layouts[5])
    
    # 标题
    txBox = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), 
                                      Inches(8), Inches(0.6))
    txBox.text_frame.text = title_text
    
    # 图片（居中显示）
    slide.shapes.add_picture(
        image_path,
        Inches(1), Inches(1.5),  # 位置
        Inches(8), Inches(5)     # 尺寸
    )
    return slide
```

---

## 模板化生成

### 基于模板创建

```python
def generate_from_template(template_path, data, output_path):
    """基于模板生成演示文稿（替换占位符）"""
    prs = Presentation(template_path)
    
    for slide in prs.slides:
        for shape in slide.shapes:
            if shape.has_text_frame:
                for paragraph in shape.text_frame.paragraphs:
                    for run in paragraph.runs:
                        # 替换 {{变量}}
                        for key, value in data.items():
                            if f"{{{{{key}}}}}" in run.text:
                                run.text = run.text.replace(
                                    f"{{{{{key}}}}}", str(value)
                                )
            if shape.has_table:
                # 表格中的占位符替换
                pass
    
    prs.save(output_path)
    print(f"✅ 模板渲染完成: {output_path}")

# 使用示例
generate_from_template(
    "weekly_report_template.pptx",
    {
        "report_title": "2024-05-05 周报",
        "author": "张三",
        "department": "研发部",
        "week": "第 19 周",
        "summary": "本周重点完成了支付模块的测试和部署",
    },
    "weekly_report_2024_W19.pptx"
)
```

---

## Hermes Agent 自然语言生成

在 Hermes Agent 中，通过自然语言操控 PowerPoint：

```
"帮我创建一个 3 页的项目介绍演示文稿"
"把这份会议纪要导出为 PPT"
"给现有 presentation.pptx 添加一页数据汇总表格"
"基于模板 weekly_template.pptx 生成上周的周报"
"把这份 Excel 数据生成一个 PPT 图表"
```

Agent 自动执行：
1. 分析指令，确定操作类型
2. 准备内容（可能从其他文件读取数据）
3. 调用 python-pptx 执行操作
4. 保存文件并确认

---

## 批量生成脚本

### 批量周报生成

```python
import csv
from pptx import Presentation
from pptx.util import Inches

def batch_generate_reports(csv_path, template_path):
    """从 CSV 数据批量生成 PPT"""
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            data = {
                "name": row["姓名"],
                "department": row["部门"],
                "week": row["周次"],
                "tasks": row["完成任务"],
                "plan": row["下周计划"],
            }
            output = f"周报_{data['name']}_{data['week']}.pptx"
            generate_from_template(template_path, data, output)
            print(f"  ✅ {output}")

batch_generate_reports("weekly_data.csv", "template.pptx")
```

---

## 最佳实践

1. **使用模板** — 固定样式尽量在模板中定义，减少代码中的样式控制
2. **图片压缩** — 大图片会显著增加文件大小，生成前压缩
3. **字体兼容** — 中文环境需指定中文字体，避免跨平台显示异常
4. **图表数据** — 图表要有标题和轴标签，避免歧义
5. **文件大小** — 控制每页幻灯片的内容量，避免超大文件

---

## 相关技能

- [[01-google-workspace]] — Google Workspace 集成
- [[04-nano-pdf]] — PDF 编辑
- [[07-ocr-documents]] — OCR 与文档提取
