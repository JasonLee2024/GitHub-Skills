---
date: 2026-05-05
tags:
  - nano-pdf
  - pdf
  - document-editing
  - natural-language
  - productivity
  - 生产工具与效率
source_skill: nano-pdf
category: 生产工具与效率
---

# PDF 自然语言编辑

> 本文档基于 Hermes Agent 的 `nano-pdf` 技能整理，覆盖通过自然语言指令编辑 PDF 文件的完整流程。

## 概述

`nano-pdf` 是一个通过**自然语言指令**编辑 PDF 文件的工具。无需学习复杂的 PDF 编辑软件，只需像和人说话一样描述你想做的修改，Agent 就会解析并执行相应的 PDF 操作。

### 核心理念

```
用户输入 → Agent 分析 → 提取操作意图 → 执行 PDF 修改 → 返回结果
```

### 支持的编辑操作

| 操作 | 说明 | 示例指令 |
|------|------|---------|
| 文字替换 | 替换 PDF 中的特定文本 | "把'旧版'改成'新版'" |
| 内容插入 | 在指定位置添加内容 | "在第二页末尾添加一段总结" |
| 内容删除 | 删除特定内容 | "删掉第三页的免责声明" |
| 格式调整 | 修改字体、大小、颜色 | "把标题改成红色加粗" |
| 页面操作 | 添加/删除/重排页面 | "把第五页移到第二页后面" |
| 合并分割 | 合并多个 PDF 或拆分 | "把这两个 PDF 合并成一个" |
| 水印 | 添加文字或图片水印 | "在每页右下角加'机密'水印" |
| 元数据 | 修改文档属性 | "把标题改为'最终版本'" |

---

## 环境准备

```bash
# 安装依赖
pip install pypdf2 pymupdf reportlab pillow

# 可选：PDF 渲染工具
# sudo apt-get install poppler-utils  # pdftoppm, pdfinfo
```

---

## 文字替换

### 使用 PyMuPDF（推荐，支持中文）

```python
import fitz  # PyMuPDF

def replace_text_pdf(input_pdf, output_pdf, old_text, new_text):
    """替换 PDF 中的指定文本"""
    doc = fitz.open(input_pdf)
    
    for page_num in range(doc.page_count):
        page = doc[page_num]
        # 搜索文本
        text_instances = page.search_for(old_text)
        
        for inst in text_instances:
            # 创建红色覆盖矩形
            annot = page.add_redact_annot(inst, fill=(1, 1, 1))
            # 应用红action（覆盖原文）
            page.apply_redactions()
            # 在相同位置插入新文本
            page.insert_text(
                point=(inst.x0, inst.y1 - 5),
                text=new_text,
                fontname="china-s",
                fontsize=11,
                color=(0, 0, 0)
            )
    
    doc.save(output_pdf)
    doc.close()
    print(f"✅ 文字替换完成: '{old_text}' → '{new_text}'")

# 使用示例
replace_text_pdf("report.pdf", "report_updated.pdf", 
                 "Confidential", "公开文档")
```

### 使用命令行工具（简单替换）

```bash
# 使用 pdftotext + sed（仅适用于纯文本类 PDF）
pdftotext input.pdf - | sed 's/旧版本/新版本/g' | \
  enscript -o - | ps2pdf - output.pdf
```

---

## 页面操作

### 提取指定页面

```python
from PyPDF2 import PdfReader, PdfWriter

def extract_pages(input_pdf, output_pdf, page_list):
    """提取指定页面"""
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    
    for page_num in page_list:
        writer.add_page(reader.pages[page_num - 1])  # 1-indexed
    
    with open(output_pdf, 'wb') as f:
        writer.write(f)
    
    print(f"✅ 已提取 {len(page_list)} 页: {page_list}")

# 提取第 1, 3, 5 页
extract_pages("document.pdf", "extracted.pdf", [1, 3, 5])
```

### 合并多个 PDF

```python
def merge_pdfs(pdf_list, output_pdf):
    """合并多个 PDF"""
    merger = PdfWriter()
    
    for pdf in pdf_list:
        merger.append(pdf)
    
    with open(output_pdf, 'wb') as f:
        merger.write(f)
    
    print(f"✅ 已合并 {len(pdf_list)} 个 PDF 到 {output_pdf}")

# 合并
merge_pdfs(["part1.pdf", "part2.pdf", "part3.pdf"], "complete.pdf")
```

### 旋转页面

```python
def rotate_page(input_pdf, output_pdf, page_num, angle=90):
    """旋转指定页面"""
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    
    for i, page in enumerate(reader.pages):
        if i + 1 == page_num:
            page.rotate(angle)
        writer.add_page(page)
    
    with open(output_pdf, 'wb') as f:
        writer.write(f)
    
    print(f"✅ 第 {page_num} 页已旋转 {angle}°")
```

---

## 添加水印和注释

### 文字水印

```python
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
import io

def add_watermark(input_pdf, output_pdf, watermark_text):
    """在每页添加透明水印"""
    # 创建水印 PDF
    packet = io.BytesIO()
    c = canvas.Canvas(packet, pagesize=(595, 842))  # A4
    
    # 旋转45度居中
    c.setFont("Helvetica", 48)
    c.setFillColorRGB(0.5, 0.5, 0.5, 0.3)  # 半透明灰色
    c.saveState()
    c.translate(297, 421)
    c.rotate(45)
    c.drawCentredString(0, 0, watermark_text)
    c.restoreState()
    c.save()
    
    packet.seek(0)
    watermark_pdf = PdfReader(packet)
    watermark_page = watermark_pdf.pages[0]
    
    # 应用到每一页
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    
    for page in reader.pages:
        page.merge_page(watermark_page)
        writer.add_page(page)
    
    with open(output_pdf, 'wb') as f:
        writer.write(f)
    
    print(f"✅ 水印已添加: '{watermark_text}'")

add_watermark("report.pdf", "report_watermarked.pdf", "内部机密")
```

---

## Hermes Agent 自然语言编辑

在 Hermes Agent 中，直接使用自然语言指令编辑 PDF：

```
"帮我把这份 report.pdf 中的 'draft' 全部替换为 'final'"
"从 technical_spec.pdf 中提取第 3 到第 8 页保存为 spec_extract.pdf"
"给 contract.pdf 每页右下角加上 '已签署' 水印"
"把这份 PDF 的前两页旋转 90 度"
"合并 invoice_1.pdf 和 invoice_2.pdf"
"把这份 PDF 按章节拆分成多个文件"
```

Agent 会：
1. 解析自然语言指令，提取操作类型和参数
2. 如果指令模糊，会询问澄清
3. 执行对应的 PDF 操作
4. 显示操作结果摘要
5. 保存修改后的文件

---

## 高级技巧

### OCR + PDF 编辑（扫描件处理）

对于扫描件 PDF，先 OCR 识别文字再编辑：

```bash
# 使用 Tesseract OCR
# 安装
sudo apt-get install tesseract-ocr tesseract-ocr-chi-sim
pip install pytesseract pdf2image

# 流程：PDF → 图片 → OCR → 创建可选文字PDF
```

### 批量处理

```bash
# 批量替换多个文件中的相同文本
for f in *.pdf; do
  python replace_text.py "$f" "temp_$f" "旧文本" "新文本"
  mv "temp_$f" "$f"
done
```

### 元数据修改

```python
def update_metadata(input_pdf, output_pdf, metadata):
    """更新 PDF 元数据"""
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    
    for page in reader.pages:
        writer.add_page(page)
    
    writer.add_metadata(metadata)
    
    with open(output_pdf, 'wb') as f:
        writer.write(f)

update_metadata("doc.pdf", "doc_meta.pdf", {
    "/Title": "最终技术规范",
    "/Author": "研发团队",
    "/Subject": "v2.1.0 发布版本",
    "/Keywords": "technical, specification, v2.1"
})
```

---

## 限制与注意事项

1. **PDF 编码** — 中文 PDF 需要字体支持，部分 PDF 编码不兼容
2. **扫描件限制** — 图片型 PDF 无法直接编辑文字，需先 OCR
3. **表单 PDF** — AcroForm 表单操作需要额外的库支持
4. **加密 PDF** — 受密码保护的 PDF 需要先解密
5. **字体嵌入** — 替换文本时需确保字体匹配

---

## 相关技能

- [[07-ocr-documents]] — OCR 与文档提取
- [[05-powerpoint]] — PowerPoint 自动化
- [[01-google-workspace]] — Google Workspace 集成
