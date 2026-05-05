---
title: DSPy — 声明式语言模型编程框架
description: 使用 DSPy 以声明式方式构建 AI 系统，自动优化提示词，构建模块化 RAG、Agent 和多阶段流水线
---

# DSPy — 声明式语言模型编程框架

## 概述

DSPy 是斯坦福 NLP 组开发的声明式语言模型编程框架（GitHub 22k+ stars）。与传统的提示工程不同，DSPy 让你用编程方式定义 AI 系统的行为，然后自动优化提示词，使得系统更加可靠、可维护、可复用。

### 核心思想

**告别手写提示词，用编译和优化的方式构建 AI 系统。**

```
传统方式: 手写 prompt → 试错 → 修改 prompt → 再试错...
DSPy方式: 定义签名（输入/输出）→ 提供示例 → 自动优化 → 可靠输出
```

### 核心特性

- **声明式编程**：用代码定义 AI 任务，而非手写提示词
- **自动优化**：基于训练数据自动改进提示词和模块行为
- **模块化设计**：Predict、ChainOfThought、ReAct 等可组合模块
- **多模型支持**：OpenAI、Anthropic、Ollama 本地模型等
- **类型安全**：Signatures 提供输入/输出的类型检查
- **可优化一次，到处部署**：在不同模型间迁移优化后的模块

### 与其他框架对比

| 特性 | 手动提示工程 | LangChain | DSPy |
|------|------------|-----------|------|
| 提示词编写 | 手动试错 | 手动 | 自动 |
| 优化方式 | 人工经验 | 无内置优化 | 数据驱动 |
| 模块化 | 低 | 中 | 高 |
| 类型安全 | 无 | 有限 | 签名约束 |
| 可移植性 | 低 | 中 | 高 |
| 学习曲线 | 低 | 中 | 中高 |

### 适用场景

- 有训练数据或可生成数据的任务
- 需要系统性提示词优化
- 构建多阶段复杂 AI 流水线
- 需要跨模型迁移的 AI 系统

## 安装

```bash
# 稳定版
pip install dspy

# 最新开发版
pip install git+https://github.com/stanfordnlp/dspy.git

# 带特定模型提供者
pip install dspy[openai]        # OpenAI
pip install dspy[anthropic]     # Anthropic Claude
pip install dspy[all]           # 全部
```

## 快速开始

### 基本问答

```python
import dspy

# 配置语言模型
lm = dspy.LM("openai/gpt-4o")  # 或使用 Anthropic / Ollama
dspy.settings.configure(lm=lm)

# 定义签名（输入 → 输出）
class QA(dspy.Signature):
    """用简短事实回答用户问题。"""
    question = dspy.InputField()
    answer = dspy.OutputField(desc="通常 1-5 个词的答案")

# 创建模块
qa = dspy.Predict(QA)

# 使用
response = qa(question="法国的首都是什么？")
print(response.answer)  # 巴黎
```

### 思维链推理

```python
import dspy

lm = dspy.LM("openai/gpt-4o")
dspy.settings.configure(lm=lm)

class MathProblem(dspy.Signature):
    """解决数学应用题。"""
    problem = dspy.InputField()
    answer = dspy.OutputField(desc="数字答案")

# ChainOfThought 自动生成推理过程
cot = dspy.ChainOfThought(MathProblem)

response = cot(problem="小明有 5 个苹果，给小红 2 个后，还有几个？")
print(response.rationale)  # 显示推理步骤
print(response.answer)     # 3
```

## 核心概念详解

### 1. Signatures（签名）

签名定义 AI 任务的输入/输出结构，是 DSPy 的核心抽象。

```python
# 内联签名（简单）
qa = dspy.Predict("question -> answer")

# 类签名（详细）
class Summarize(dspy.Signature):
    """将文本总结为关键点。"""
    text = dspy.InputField(desc="需要总结的文本")
    summary = dspy.OutputField(desc="要点列表，3-5 项")

summarizer = dspy.ChainOfThought(Summarize)

# 多输入/多输出签名
class Translate(dspy.Signature):
    """将文本从源语言翻译到目标语言。"""
    source_text = dspy.InputField()
    source_lang = dspy.InputField()
    target_lang = dspy.InputField()
    translated_text = dspy.OutputField()

translator = dspy.Predict(Translate)
result = translator(
    source_text="Hello world",
    source_lang="English",
    target_lang="Chinese",
)
print(result.translated_text)  # 你好世界
```

### 2. 模块（Modules）

DSPy 提供多种内置模块，可灵活组合。

#### dspy.Predict — 基础预测

```python
predictor = dspy.Predict("context, question -> answer")
result = predictor(
    context="法国首都是巴黎。",
    question="法国首都是什么？"
)
print(result.answer)
```

#### dspy.ChainOfThought — 思维链

生成推理步骤后再给出答案，适用于需要推理的任务。

```python
cot = dspy.ChainOfThought("question -> answer")
result = cot(question="天空为什么是蓝色的？")
print(result.rationale)  # 推理步骤
print(result.answer)     # 最终答案
```

#### dspy.ReAct — 推理与行动（Agent 模式）

结合推理和工具调用，适合需要外部信息获取的场景。

```python
from dspy.predict import ReAct

class SearchQA(dspy.Signature):
    """使用搜索工具回答问题。"""
    question = dspy.InputField()
    answer = dspy.OutputField()

def search_wiki(query: str) -> str:
    """搜索维基百科。"""
    # 你的搜索实现
    return f"关于 '{query}' 的结果"

react = ReAct(SearchQA, tools=[search_wiki])
result = react(question="Python 是什么时候创建的？")
print(result.answer)
```

#### dspy.ProgramOfThought — 代码推理

生成并执行 Python 代码进行推理。

```python
pot = dspy.ProgramOfThought("question -> answer")
result = pot(question="240 的 15% 是多少？")
# 自动生成: answer = 240 * 0.15
```

### 3. 优化器（Optimizers / Teleprompters）

优化器是 DSPy 最强大的功能 — 使用数据自动优化你的模块。

#### BootstrapFewShot — 少样本学习

```python
from dspy.teleprompt import BootstrapFewShot

# 训练数据
trainset = [
    dspy.Example(question="2+2=?", answer="4").with_inputs("question"),
    dspy.Example(question="3+5=?", answer="8").with_inputs("question"),
    dspy.Example(question="10-3=?", answer="7").with_inputs("question"),
]

# 定义评估指标
def validate_answer(example, pred, trace=None):
    return example.answer == pred.answer

# 优化
optimizer = BootstrapFewShot(metric=validate_answer, max_bootstrapped_demos=3)
optimized_qa = optimizer.compile(qa, trainset=trainset)

# 优化后的模块表现更好！
result = optimized_qa(question="15+7=?")
print(result.answer)
```

#### MIPRO — 提示词迭代优化

```python
from dspy.teleprompt import MIPRO

optimizer = MIPRO(
    metric=validate_answer,
    num_candidates=10,     # 每次迭代候选数
    init_temperature=1.0,
)

optimized_cot = optimizer.compile(
    cot,
    trainset=trainset,
    num_trials=100,        # 试验次数
)
```

#### BootstrapFinetune — 生成微调数据

```python
from dspy.teleprompt import BootstrapFinetune

optimizer = BootstrapFinetune(metric=validate_answer)
optimized_module = optimizer.compile(qa, trainset=trainset)
# 导出可用于模型微调的训练数据
```

### 4. 构建复杂系统

#### 多阶段流水线

```python
import dspy

class MultiHopQA(dspy.Module):
    """多跳问答系统。"""
    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=3)
        self.generate_query = dspy.ChainOfThought("question -> search_query")
        self.generate_answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 步骤 1：生成搜索查询
        search_query = self.generate_query(question=question).search_query

        # 步骤 2：检索上下文
        passages = self.retrieve(search_query).passages
        context = "\n".join(passages)

        # 步骤 3：生成答案
        answer = self.generate_answer(context=context, question=question).answer
        return dspy.Prediction(answer=answer, context=context)

# 使用系统
qa_system = MultiHopQA()
result = qa_system(question="谁写了改编成《银翼杀手》的那本书？")
```

#### RAG 系统

```python
import dspy
from dspy.retrieve.chromadb_rm import ChromadbRM

# 配置检索器
retriever = ChromadbRM(
    collection_name="documents",
    persist_directory="./chroma_db",
)

class RAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

# 创建并优化 RAG 系统
rag = RAG()

from dspy.teleprompt import BootstrapFewShot
optimizer = BootstrapFewShot(metric=validate_answer)
optimized_rag = optimizer.compile(rag, trainset=trainset)
```

## 模型提供者配置

### OpenAI

```python
lm = dspy.LM(
    "openai/gpt-4o",
    api_key="your-api-key",       # 或设置 OPENAI_API_KEY
    max_tokens=1000,
    temperature=0.7,
)
dspy.settings.configure(lm=lm)
```

### Anthropic Claude

```python
lm = dspy.LM(
    "anthropic/claude-sonnet-4-5-20250929",
    api_key="your-api-key",       # 或设置 ANTHROPIC_API_KEY
    max_tokens=1000,
)
dspy.settings.configure(lm=lm)
```

### 本地模型（Ollama）

```python
lm = dspy.LM(
    "ollama_chat/llama3.1",
    base_url="http://localhost:11434",
)
dspy.settings.configure(lm=lm)
```

### 多模型协作

```python
# 不同任务使用不同模型
cheap_lm = dspy.LM("openai/gpt-4o-mini")
strong_lm = dspy.LM("openai/gpt-4o")

# 检索用便宜模型
with dspy.settings.context(lm=cheap_lm):
    context = retriever(question)

# 推理用强模型
with dspy.settings.context(lm=strong_lm):
    answer = generator(context=context, question=question)
```

## 高级模式

### 结构化输出

```python
from pydantic import BaseModel, Field

class PersonInfo(BaseModel):
    name: str = Field(description="全名")
    age: int = Field(description="年龄")
    occupation: str = Field(description="当前职业")

class ExtractPerson(dspy.Signature):
    """从文本中提取人物信息。"""
    text = dspy.InputField()
    person: PersonInfo = dspy.OutputField()

extractor = dspy.TypedPredictor(ExtractPerson)
result = extractor(text="张三今年 35 岁，是一名软件工程师。")
print(result.person.name)       # 张三
print(result.person.age)        # 35
print(result.person.occupation) # 软件工程师
```

### 断言驱动优化

```python
from dspy.primitives.assertions import assert_transform_module, backtrack_handler

@assert_transform_module(backtrack_handler=backtrack_handler)
class MathQA(dspy.Module):
    def __init__(self):
        super().__init__()
        self.solve = dspy.ChainOfThought("problem -> solution: float")

    def forward(self, problem):
        solution = self.solve(problem=problem).solution

        # 断言解是有效数字
        dspy.Assert(
            isinstance(float(solution), float),
            "解必须是数字",
        )

        return dspy.Prediction(solution=solution)
```

### 自洽性（Self-Consistency）

```python
from collections import Counter

class ConsistentQA(dspy.Module):
    def __init__(self, num_samples=5):
        super().__init__()
        self.qa = dspy.ChainOfThought("question -> answer")
        self.num_samples = num_samples

    def forward(self, question):
        # 生成多个样本
        answers = []
        for _ in range(self.num_samples):
            result = self.qa(question=question)
            answers.append(result.answer)

        # 取最常见的答案
        most_common = Counter(answers).most_common(1)[0][0]
        return dspy.Prediction(answer=most_common)
```

### 检索重排序

```python
class RerankedRAG(dspy.Module):
    def __init__(self):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=10)
        self.rerank = dspy.Predict("question, passage -> relevance_score: float")
        self.answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        # 检索候选
        passages = self.retrieve(question).passages

        # 重排序
        scored = []
        for passage in passages:
            score = float(
                self.rerank(question=question, passage=passage).relevance_score
            )
            scored.append((score, passage))

        # 取前 3
        top_passages = [p for _, p in sorted(scored, reverse=True)[:3]]
        context = "\n\n".join(top_passages)

        # 生成答案
        return self.answer(context=context, question=question)
```

## 评估与度量

### 自定义指标

```python
def exact_match(example, pred, trace=None):
    """精确匹配指标。"""
    return example.answer.lower() == pred.answer.lower()

def f1_score(example, pred, trace=None):
    """F1 分数。"""
    pred_tokens = set(pred.answer.lower().split())
    gold_tokens = set(example.answer.lower().split())

    if not pred_tokens:
        return 0.0

    precision = len(pred_tokens & gold_tokens) / len(pred_tokens)
    recall = len(pred_tokens & gold_tokens) / len(gold_tokens)

    if precision + recall == 0:
        return 0.0

    return 2 * (precision * recall) / (precision + recall)
```

### 评估模块

```python
from dspy.evaluate import Evaluate

evaluator = Evaluate(
    devset=testset,
    metric=f1_score,
    num_threads=4,
    display_progress=True,
)

# 评估
score = evaluator(qa_system)
print(f"F1 分数: {score}")

# 对比优化前后
score_before = evaluator(qa)
score_after = evaluator(optimized_qa)
print(f"提升: {score_after - score_before:.2%}")
```

## 最佳实践

### 1. 从简单开始，逐步迭代

```python
# 第一步：先用 Predict
qa = dspy.Predict("question -> answer")

# 需要推理时加 ChainOfThought
qa = dspy.ChainOfThought("question -> answer")

# 有数据后加优化
optimized_qa = optimizer.compile(qa, trainset=data)
```

### 2. 使用有描述性的签名

```python
# ❌ 不好：模糊
class Task(dspy.Signature):
    input = dspy.InputField()
    output = dspy.OutputField()

# ✅ 好：描述清晰
class SummarizeArticle(dspy.Signature):
    """将新闻文章总结为 3-5 个关键点。"""
    article = dspy.InputField(desc="完整的文章文本")
    summary = dspy.OutputField(desc="要点列表，3-5 项")
```

### 3. 使用代表性数据进行优化

```python
# 创建多样化的训练示例
trainset = [
    dspy.Example(question="事实性问题", answer="...").with_inputs("question"),
    dspy.Example(question="推理问题", answer="...").with_inputs("question"),
    dspy.Example(question="计算问题", answer="...").with_inputs("question"),
]
```

### 4. 保存和加载优化模型

```python
# 保存
optimized_qa.save("models/qa_v1.json")

# 加载
loaded_qa = dspy.ChainOfThought("question -> answer")
loaded_qa.load("models/qa_v1.json")
```

### 5. 调试跟踪

```python
# 启用跟踪
dspy.settings.configure(lm=lm, trace=[])

# 运行
result = qa(question="...")

# 检查跟踪
for call in dspy.settings.trace:
    print(f"提示词: {call['prompt']}")
    print(f"响应: {call['response']}")
```

## 完整示例：优化版 RAG 系统

```python
import dspy
from dspy.teleprompt import BootstrapFewShot

# 1. 配置模型
lm = dspy.LM("openai/gpt-4o-mini")
dspy.settings.configure(lm=lm)

# 2. 定义 RAG 模块
class RAG(dspy.Module):
    def __init__(self, k=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=k)
        self.generate = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

# 3. 准备训练数据
trainset = [
    dspy.Example(
        question="法国首都是什么？",
        answer="巴黎",
    ).with_inputs("question"),
    dspy.Example(
        question="Python 是由谁创建的？",
        answer="Guido van Rossum",
    ).with_inputs("question"),
]

# 4. 定义评估指标
def validate(example, pred, trace=None):
    return example.answer.lower() in pred.answer.lower()

# 5. 优化
rag = RAG(k=3)
optimizer = BootstrapFewShot(metric=validate)
optimized_rag = optimizer.compile(rag, trainset=trainset)

# 6. 使用
result = optimized_rag(question="深度学习框架 PyTorch 由哪个团队开发？")
print(f"答案: {result.answer}")

# 7. 保存
optimized_rag.save("models/rag_optimized.json")
```

## 参考链接

- 文档: https://dspy.ai
- GitHub: https://github.com/stanfordnlp/dspy (22k+ stars)
- Discord: https://discord.gg/XCGy2WDCQB
- 论文: "DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines"
- 示例仓库: https://github.com/stanfordnlp/dspy/tree/main/examples
