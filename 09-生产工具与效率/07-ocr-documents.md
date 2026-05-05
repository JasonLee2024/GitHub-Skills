---
date: 2026-05-05
tags:
  - ocr
  - pdf-extraction
  - tesseract
  - document-processing
  - text-extraction
  - productivity
  - 生产工具与效率
source_skill: ocr-and-documents
category: 生产工具与效率
---

# OCR 与文档提取

> 本文档基于 Hermes Agent 的 `ocr-and-documents` 技能整理，覆盖从 PDF 和扫描件中提取文字的全流程实操。

## 概述

OCR（Optical Character Recognition，光学字符识别）是将图片或扫描件中的文字转换为可编辑文本的技术。Hermes Agent 的 `ocr-and-documents` 技能整合了多款 OCR 引擎和文档处理工具，提供从文档输入到结构化输出的完整管线。

### 核心能力

| 功能 | 技术 | 说明 |
|------|------|------|
| 图片 OCR | Tesseract OCR | 识别图片中的中英文文字 |
| PDF 文本提取 | PyMuPDF / pdfminer | 从数字 PDF 中提取文本 |
| 扫描件 OCR | pdf2image + Tesseract | PDF 扫描件转文字 |
| 表格提取 | camelot / tabula | 从 PDF 中提取表格数据 |
| 文档格式转换 | pandoc | Markdown / HTML / DOCX 互转 |

---

## 环境安装

```bash
# Tesseract OCR 引擎
sudo apt-get install tesseract-ocr
sudo apt-get install tesseract-ocr-chi-sim   # 中文简体
sudo apt-get install tesseract-ocr-chi-tra   # 中文繁体

# Python 库
pip install pytesseract pdf2image pillow PyMuPDF
pip install camelot-py[cv] tabula-py         # 表格提取
pip install pandoc                            # 格式转换
```

验证安装：

```bash
# 检查 Tesseract 版本和可用语言
tesseract --version
tesseract --list-langs

# 语言包目录
ls /usr/share/tesseract-ocr/4.00/tessdata/
```

---

## 图片 OCR

### 基础使用

```python
from PIL import Image
import pytesseract

def ocr_image(image_path, lang='chi_sim+eng'):
    """对图片进行 OCR 识别"""
    image = Image.open(image_path)
    text = pytesseract.image_to_string(image, lang=lang)
    return text

# 使用示例
text = ocr_image('screenshot.png', lang='chi_sim+eng')
print(text)
```

### 中文 OCR 优化

```python
def ocr_chinese(image_path):
    """优化后的中文 OCR"""
    image = Image.open(image_path)
    
    # 预处理：转为灰度，提高对比度
    gray = image.convert('L')
    
    # 二值化阈值处理
    threshold = 150
    bw = gray.point(lambda x: 0 if x < threshold else 255)
    
    # OCR 配置
    custom_config = r'--oem 3 --psm 6 -l chi_sim+eng'
    # oem: OCR Engine Mode (3=LSTM+Legacy)
    # psm: Page Segmentation Mode (6=uniform block)
    
    text = pytesseract.image_to_string(bw, config=custom_config)
    return text

# 保存结果
with open('ocr_result.txt', 'w', encoding='utf-8') as f:
    f.write(text)
```

### OCR 参数说明

| 参数 | 可选值 | 说明 |
|------|--------|------|
| `--oem` | 0=LSTM, 1=LSTM only, 2=Legacy, 3=Both | OCR 引擎模式 |
| `--psm` | 0-13 | 页面分割模式 |
| `-l` | chi_sim, eng, fra, deu, jpn | 语言组合 |

**PSM 模式详解**：

```
0 = 方向和脚本检测
1 = 自动分页（含OSD）
3 = 全自动分页（不含OSD，默认）
4 = 单列文本
6 = 单一文本块
7 = 单行文本
8 = 单个单词
10 = 单字符
11 = 稀疏文本（无特定顺序）
13 = 原始行文本
```

---

## PDF 文本提取

### 数字 PDF（原生文本）

```python
import fitz  # PyMuPDF

def extract_pdf_text(pdf_path, page_start=0, page_end=None):
    """从数字 PDF 中提取文本"""
    doc = fitz.open(pdf_path)
    
    if page_end is None:
        page_end = doc.page_count
    
    text = ''
    for page_num in range(page_start, page_end):
        page = doc[page_num]
        text += f"\n--- 第 {page_num + 1} 页 ---\n"
        text += page.get_text()
    
    doc.close()
    return text

def extract_pdf_with_metadata(pdf_path):
    """提取 PDF 文本和元数据"""
    doc = fitz.open(pdf_path)
    
    metadata = doc.metadata
    print(f"标题: {metadata.get('title', '未知')}")
    print(f"作者: {metadata.get('author', '未知')}")
    print(f"页数: {doc.page_count}")
    print(f"创建日期: {metadata.get('creationDate', '未知')}")
    
    return extract_pdf_text(pdf_path)
```

### 扫描件 PDF

对于扫描件（图片型 PDF），需要先转换为图片再 OCR：

```python
from pdf2image import convert_from_path

def ocr_scanned_pdf(pdf_path, lang='chi_sim+eng', dpi=300):
    """OCR 扫描件 PDF"""
    # PDF 转图片（高 DPI 保质量）
    images = convert_from_path(pdf_path, dpi=dpi)
    
    full_text = ''
    for i, image in enumerate(images):
        # 对每页图片 OCR
        text = pytesseract.image_to_string(image, lang=lang)
        full_text += f"\n--- 第 {i + 1} 页 ---\n"
        full_text += text
        print(f"  第 {i+1}/{len(images)} 页完成")
    
    return full_text

# 使用示例
text = ocr_scanned_pdf('scanned_contract.pdf', lang='chi_sim+eng')
with open('contract_text.txt', 'w', encoding='utf-8') as f:
    f.write(text)
```

---

## 表格提取

### 从 PDF 提取表格

```python
import camelot

def extract_tables(pdf_path, pages='1-end'):
    """从 PDF 中提取表格数据"""
    tables = camelot.read_pdf(pdf_path, pages=pages)
    
    print(f"发现 {tables.n} 个表格")
    
    for i, table in enumerate(tables):
        print(f"\n--- 表格 {i+1} ---")
        print(table.df.to_string())
        
        # 导出为 CSV
        table.to_csv(f'table_{i+1}.csv')
    
    return tables

# 使用示例
extract_tables('financial_report.pdf')
```

### 使用 Tabula

```python
import tabula

def extract_tables_tabula(pdf_path):
    """使用 Tabula 提取表格"""
    dfs = tabula.read_pdf(pdf_path, pages='all', multiple_tables=True)
    
    for i, df in enumerate(dfs):
        print(f"表格 {i+1}:")
        print(df)
        df.to_csv(f'tabula_table_{i+1}.csv', index=False)
    
    return dfs
```

---

## 文档格式转换（Pandoc）

### 安装 Pandoc

```bash
sudo apt-get install pandoc
```

### 格式转换

```bash
# PDF → Markdown
pandoc input.pdf -o output.md

# DOCX → Markdown
pandoc input.docx -o output.md

# HTML → DOCX
pandoc input.html -o output.docx

# Markdown → DOCX（带模板）
pandoc input.md -o output.docx --reference-doc=template.docx

# EPUB → 纯文本
pandoc input.epub -o output.txt --wrap=none
```

### Python 调用 Pandoc

```python
import subprocess

def convert_document(input_path, output_path, input_format=None):
    """使用 Pandoc 转换文档格式"""
    cmd = ['pandoc', input_path, '-o', output_path]
    if input_format:
        cmd.extend(['-f', input_format])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ 转换成功: {output_path}")
    else:
        print(f"❌ 转换失败: {result.stderr}")
```

---

## 完整工作流

### 文档处理流水线

```python
# document_pipeline.py
"""
文档处理流水线：
输入：扫描件 PDF / 图片
输出：Markdown 文件（含提取的表格）
"""

import os
import fitz
from PIL import Image
import pytesseract
from pdf2image import convert_from_path
import camelot

class DocumentPipeline:
    def __init__(self, lang='chi_sim+eng'):
        self.lang = lang
    
    def process(self, input_path, output_dir='./output'):
        os.makedirs(output_dir, exist_ok=True)
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        
        ext = os.path.splitext(input_path)[1].lower()
        
        if ext == '.pdf':
            text = self._process_pdf(input_path)
        elif ext in ('.png', '.jpg', '.jpeg', '.tiff'):
            text = self._process_image(input_path)
        else:
            raise ValueError(f"不支持的文件格式: {ext}")
        
        # 保存结果
        output_path = os.path.join(output_dir, f"{base_name}.md")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(f"# {base_name}\n\n")
            f.write(f"> 自动提取于 {input_path}\n\n")
            f.write(text)
        
        print(f"✅ 文档处理完成: {output_path}")
        return output_path
    
    def _process_pdf(self, pdf_path):
        """处理 PDF（自动检测数字/扫描件）"""
        # 尝试直接提取文本
        doc = fitz.open(pdf_path)
        text_pages = [page.get_text() for page in doc]
        doc.close()
        
        # 如果文本提取结果为空，说明是扫描件
        if all(len(page.strip()) < 10 for page in text_pages):
            print("⚠️ 检测到扫描件 PDF，启动 OCR 处理")
            return self._ocr_pdf(pdf_path)
        else:
            print("✅ 检测到数字 PDF，直接提取文本")
            # 尝试提取表格
            try:
                extract_tables(pdf_path)
            except:
                pass
            return '\n\n'.join(text_pages)
    
    def _ocr_pdf(self, pdf_path):
        """OCR 处理扫描件 PDF"""
        images = convert_from_path(pdf_path, dpi=300)
        texts = []
        for i, img in enumerate(images):
            text = pytesseract.image_to_string(img, lang=self.lang)
            texts.append(text)
            print(f"  OCR 第 {i+1}/{len(images)} 页")
        return '\n\n'.join(texts)
    
    def _process_image(self, image_path):
        """OCR 处理图片"""
        return pytesseract.image_to_string(
            Image.open(image_path), lang=self.lang
        )

# 使用示例
pipeline = DocumentPipeline(lang='chi_sim+eng')
pipeline.process('contract.pdf', './extracted')
```

---

## 最佳实践

1. **图片质量** — 300 DPI 以上的扫描件 OCR 准确率最高
2. **预处理** — 灰度化 + 二值化可显著提升识别率
3. **语言组合** — 中文文档使用 `chi_sim+eng` 同时识别中英文
4. **表格提取** — 表格线清晰的 PDF 使用 Camelot，无线的用 Tabula
5. **后处理** — OCR 结果需要人工校对，特别是数字和特殊字符

---

## 限制与注意事项

1. **手写识别** — Tesseract 对手写文字识别率较低
2. **字体识别** — 艺术字体和装饰字体可能识别不佳
3. **密集排版** — 小字号密集文字可能识别为乱码
4. **水印干扰** — 背景水印可能被误识别为正文
5. **多栏布局** — 复杂的多栏 PDF 需要设置正确的 PSM 参数

---

## 相关技能

- [[04-nano-pdf]] — PDF 编辑
- [[05-powerpoint]] — PowerPoint 自动化
- [[06-email-management]] — 邮件管理
