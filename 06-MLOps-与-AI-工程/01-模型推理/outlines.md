---
title: Outlines — 结构化文本生成
description: 使用 Outlines 保证 LLM 生成符合 JSON Schema / Pydantic 模型 / 正则表达式的结构化输出
---

# Outlines — 结构化文本生成

## 概述

Outlines 是一个开源的结构化生成库，通过有限状态机（FSM）在 token 级别约束 LLM 的输出，确保生成的文本始终符合预定义的结构规范。它的核心优势是**零开销**——结构化生成的速度与无约束生成一样快。

### 核心特性

- **Pydantic 模型支持**：直接使用 Python 类型定义输出结构
- **JSON Schema 保证**：任何 JSON Schema 都可作为约束
- **正则表达式约束**：确保生成内容匹配指定模式
- **多后端支持**：Transformers、llama.cpp、vLLM、OpenAI
- **零开销**：在 token 层面过滤，无需后处理重试
- **Fast-forward 优化**：确定性路径自动跳过

### 适用场景

| 场景 | 说明 |
|------|------|
| 信息提取 | 从非结构化文本提取结构化数据 |
| 分类任务 | 确保输出为枚举值之一 |
| API 响应 | 保证 JSON 格式正确 |
| 代码生成 | 生成符合语法的代码结构 |
| 表单填充 | 按 Schema 生成结构化表单 |

## 安装

```bash
# 基础安装
pip install outlines

# 带 Transformers 后端
pip install outlines transformers

# 带 llama.cpp 后端
pip install outlines llama-cpp-python

# 带 vLLM 后端（生产环境推荐）
pip install outlines vllm
```

## 快速开始

### 基础示例：分类

```python
import outlines

# 加载模型
model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")

# 约束为限定选择
prompt = "这句话的情感是：'这个产品太棒了！' -> "
generator = outlines.generate.choice(model, ["正面", "负面", "中性"])
sentiment = generator(prompt)

print(sentiment)  # "正面"（保证是三个之一）
```

### Pydantic 模型示例

```python
from pydantic import BaseModel
import outlines

class 用户信息(BaseModel):
    姓名: str
    年龄: int
    邮箱: str

model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")
generator = outlines.generate.json(model, 用户信息)

prompt = "提取用户信息：张三，28岁，zhangsan@example.com"
user = generator(prompt)

print(user.姓名)  # "张三"
print(user.年龄)  # 28
```

## 核心原理

### 约束生成流程

1. 将 Schema（JSON/Pydantic/正则）转换为上下文无关文法（CFG）
2. 将 CFG 转换为有限状态机（FSM）
3. 在生成过程中，FSM 过滤掉所有不符合约束的 token
4. 当只有一种有效 token 时，自动快速跳过

```python
# 示意图：Pydantic 模型 -> JSON Schema -> CFG -> FSM -> 约束生成
import outlines
from pydantic import BaseModel

class Person(BaseModel):
    name: str
    age: int

model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")

# 一行代码完成全部流程
generator = outlines.generate.json(model, Person)
result = generator("生成一个人：Alice，25岁")
```

### 结构化生成器类型

#### Choice Generator（选择）

```python
# 多选一
generator = outlines.generate.choice(
    model,
    ["积极", "消极", "中性"]
)

sentiment = generator("评论：这个服务很好！")
# 结果一定是这三个之一
```

#### JSON Generator（JSON）

```python
from pydantic import BaseModel

class 产品(BaseModel):
    名称: str
    价格: float
    库存: bool

# 生成符合 JSON Schema 的输出
generator = outlines.generate.json(model, 产品)
product = generator("提取：iPhone 15，$999，有货")

print(type(product))  # <class '__main__.产品'>
print(product.名称)   # "iPhone 15"
```

#### Regex Generator（正则）

```python
# 生成匹配正则的文本
generator = outlines.generate.regex(
    model,
    r"1[3-9]\d{9}"  # 中国手机号模式
)

phone = generator("生成一个手机号：")
# 结果保证是合法的手机号格式
```

#### Integer/Float Generator（数值）

```python
# 整数生成
int_gen = outlines.generate.integer(model)
age = int_gen("年龄：")  # 保证输出整数

# 浮点数生成
float_gen = outlines.generate.float(model)
price = float_gen("价格：")  # 保证输出浮点数
```

## 模型后端

### Transformers（HuggingFace）

```python
# 基本使用
model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")

# GPU 配置
model = outlines.models.transformers(
    "Qwen/Qwen2.5-1.5B-Instruct",
    device="cuda",
    model_kwargs={"torch_dtype": "float16"}
)

# 热门模型
model = outlines.models.transformers("Qwen/Qwen2.5-7B-Instruct")
model = outlines.models.transformers("mistralai/Mistral-7B-Instruct-v0.3")
```

### llama.cpp 后端

```python
# 加载 GGUF 模型
model = outlines.models.llamacpp(
    "./models/llama-3.2-3b-instruct.Q4_K_M.gguf",
    n_ctx=4096,         # 上下文窗口
    n_gpu_layers=35,    # GPU 层数
    n_threads=8         # CPU 线程
)

# 全 GPU 卸载
model = outlines.models.llamacpp(
    "./models/model.gguf",
    n_gpu_layers=-1
)
```

### vLLM 后端（生产推荐）

```python
# 单 GPU
model = outlines.models.vllm("Qwen/Qwen2.5-7B-Instruct")

# 多 GPU
model = outlines.models.vllm(
    "Qwen/Qwen2.5-72B-Instruct",
    tensor_parallel_size=4
)

# 带量化
model = outlines.models.vllm(
    "Qwen/Qwen2.5-7B-Instruct",
    quantization="awq"
)
```

## 实战模式

### 模式一：批量信息提取

```python
from pydantic import BaseModel
import outlines

class 公司信息(BaseModel):
    名称: str
    成立年份: int
    行业: str
    员工数: int

model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")
generator = outlines.generate.json(model, 公司信息)

texts = [
    "阿里巴巴集团成立于1999年，是电子商务和云计算行业的领导者，拥有约24.5万名员工。",
    "字节跳动成立于2012年，是社交媒体和人工智能领域的创新公司，员工超过15万人。",
]

for text in texts:
    company = generator(f"提取公司信息：{text}")
    print(f"{company.名称} | 成立: {company.成立年份} | 行业: {company.行业}")
```

### 模式二：嵌套结构提取

```python
from pydantic import BaseModel

class 地址(BaseModel):
    街道: str
    城市: str
    国家: str

class 人员(BaseModel):
    姓名: str
    年龄: int
    地址: 地址  # 嵌套模型

model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")
generator = outlines.generate.json(model, 人员)

person = generator("提取信息：王小明，30岁，住在北京市朝阳区建国路88号，中国")
print(person.地址.城市)  # "北京"
```

### 模式三：枚举与字面量约束

```python
from enum import Enum
from typing import Literal
from pydantic import BaseModel

class 状态(str, Enum):
    待审核 = "pending"
    已通过 = "approved"
    已拒绝 = "rejected"

class 申请(BaseModel):
    申请人: str
    状态: 状态
    优先级: Literal["低", "中", "高"]

generator = outlines.generate.json(model, 申请)
app = generator("生成申请")

print(app.状态)  # 状态.待审核（或已通过/已拒绝）
```

### 模式四：带置信度的分类

```python
from typing import Literal
from pydantic import BaseModel

class 分类结果(BaseModel):
    标签: Literal["科技", "商业", "体育", "娱乐"]
    置信度: float

model = outlines.models.transformers("Qwen/Qwen2.5-1.5B-Instruct")
classifier = outlines.generate.json(model, 分类结果)

result = classifier("文章：苹果发布新款iPhone...")
print(f"分类: {result.标签}, 置信度: {result.置信度:.2f}")
```

## 最佳实践

### 1. 使用具体类型

```python
# ✅ 好：具体类型
class 产品(BaseModel):
    名称: str
    价格: float     # 不是 str
    数量: int       # 不是 str
    有库存: bool    # 不是 str

# ❌ 差：全用字符串
class 产品(BaseModel):
    名称: str
    价格: str       # 应该是 float
    数量: str       # 应该是 int
```

### 2. 添加字段约束

```python
from pydantic import Field

class 用户(BaseModel):
    姓名: str = Field(min_length=1, max_length=100)
    年龄: int = Field(ge=0, le=150)
    邮箱: str = Field(pattern=r"^[\w\.-]+@[\w\.-]+\.\w+$")
```

### 3. 使用枚举代替自由字符串

```python
# ✅ 好：Enum 限定的分类
from enum import Enum
class 优先级(str, Enum):
    低 = "low"
    中 = "medium"
    高 = "high"

# ❌ 差：自由字符串
优先级: str  # 可能输出任何值
```

### 4. 提供清晰的提示上下文

```python
# ✅ 好：明确上下文
prompt = """从以下文本中提取产品信息。
文本：iPhone 15 Pro 售价 $999，目前有库存。
产品："""

# ❌ 差：缺少上下文
prompt = "iPhone 15 Pro 售价 $999"
```

### 5. 处理可选字段

```python
from typing import Optional

class 文章(BaseModel):
    标题: str            # 必需
    作者: Optional[str] = None  # 可选
    日期: Optional[str] = None  # 可选
    标签: list[str] = []        # 默认空列表
```

## 性能对比

| 特性 | Outlines | Instructor | Guidance | LMQL |
|------|----------|------------|----------|------|
| Pydantic 支持 | ✅ 原生 | ✅ 原生 | ❌ 不支持 | ❌ 不支持 |
| JSON Schema | ✅ 支持 | ✅ 支持 | ⚠️ 有限 | ✅ 支持 |
| 正则约束 | ✅ 支持 | ❌ 不支持 | ✅ 支持 | ✅ 支持 |
| 本地模型 | ✅ 完整 | ⚠️ 有限 | ✅ 完整 | ✅ 完整 |
| API 模型 | ⚠️ 有限 | ✅ 完整 | ✅ 完整 | ✅ 完整 |
| 零开销 | ✅ 是 | ❌ 否 | ⚠️ 部分 | ✅ 是 |
| 自动重试 | ❌ 无 | ✅ 有 | ❌ 无 | ❌ 无 |

### 选择建议

- **需要本地模型 + 最大速度** → Outlines
- **需要 API 模型 + 自动重试** → Instructor
- **复杂工作流 + token healing** → Guidance
- **声明式查询语法** → LMQL

## 常见问题

### 输出不符合预期？

1. 确保 Pydantic 模型约束合理
2. 提供更清晰的 prompt 上下文
3. 检查模型是否理解中文

### 性能缓慢？

- 使用 vLLM 后端代替 Transformers
- 减少嵌套层级
- 使用 `torch.compile` 加速

### 与 OpenAI 兼容？

Outlines 支持 OpenAI 后端，但部分功能受限。生产环境建议：
- 本地部署：vLLM + Outlines
- API 调用：Instructor

## 参考链接

- 文档: https://outlines-dev.github.io/outlines
- GitHub: https://github.com/outlines-dev/outlines
- Discord: https://discord.gg/R9DSu34mGd
- 博客: https://blog.dottxt.co
