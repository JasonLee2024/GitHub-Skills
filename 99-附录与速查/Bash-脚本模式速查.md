---
date: 2026-05-05
tags:
  - bash
  - shell
  - scripting
  - reference
  - cheatsheet
  - 附录与速查
category: 附录与速查
---

# Bash 脚本模式速查

> 日常开发中高频使用的 Bash/Shell 脚本模式合集。

## 脚本安全与调试

```bash
#!/bin/bash
set -euo pipefail  # 安全模式: 出错即停 / 未定义变量报错 / 管道错误传播
IFS=$'\n\t'        # 分割只按换行和制表符

# 调试模式
bash -x script.sh          # 执行时打印每行命令
set -x                     # 脚本内开启调试
set +x                     # 关闭调试
```

## 文件路径操作

```bash
# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 路径分解
dir=$(dirname "/path/to/file.txt")    # → /path/to
file=$(basename "/path/to/file.txt")  # → file.txt
name="${file%.*}"                     # → file (去扩展名)
ext="${file##*.}"                     # → txt (取扩展名)

# 路径拼接（避免尾部斜杠问题）
path="${parent_dir%/}/subdir/file.txt"

# 检查路径存在性
[[ -f "$file" ]]    # 是普通文件
[[ -d "$dir" ]]     # 是目录
[[ -e "$path" ]]    # 存在
[[ -L "$link" ]]    # 是符号链接
[[ -r "$file" ]]    # 可读
[[ -w "$file" ]]    # 可写
[[ -x "$file" ]]    # 可执行
[[ -s "$file" ]]    # 非空文件
```

## 字符串操作

```bash
s="Hello World from Bash"

# 截取
echo "${s:0:5}"           # → Hello
echo "${s:6}"             # → World from Bash
echo "${s: -4}"           # → Bash

# 替换
echo "${s/World/Earth}"            # 替换第一个 → Hello Earth from Bash
echo "${s//o/O}"                    # 替换所有 → HellO WOrld frOm Bash
echo "${s/#Hello/Hi}"              # 开头匹配 → Hi World from Bash
echo "${s/%Bash/Shell}"            # 结尾匹配 → Hello World from Shell

# 大小写
echo "${s,,}"                      # 全小写 → hello world from bash
echo "${s^^}"                      # 全大写 → HELLO WORLD FROM BASH
echo "${s,}"                       # 首字母小写
echo "${s^}"                       # 首字母大写

# 长度
echo "${#s}"                       # → 19

# 默认值
echo "${var:-default}"             # 变量未定义或为空时使用默认值
echo "${var:=default}"             # 同上，同时赋值
echo "${var:?错误: var 未定义}"    # 变量未定义时报错退出
echo "${var:+替换值}"              # 变量有值时替换，否则为空
```

## 数组操作

```bash
# 声明
arr=("apple" "banana" "cherry")
declare -a arr2=()

# 操作
echo "${arr[0]}"            # 第一个元素 → apple
echo "${arr[@]}"            # 所有元素
echo "${arr[*]}"            # 所有元素（作为单个字符串）
echo "${#arr[@]}"           # 数组长度 → 3
echo "${!arr[@]}"           # 所有索引 → 0 1 2

# 追加
arr+=("date")               # → ("apple" "banana" "cherry" "date")

# 遍历
for item in "${arr[@]}"; do
  echo "$item"
done

# 切片
echo "${arr[@]:1:2}"        # → banana cherry

# 配合 mapfile 读取文件
mapfile -t lines < "file.txt"
```

## 条件判断

```bash
# 数值比较
[[ $a -eq $b ]]   # ==
[[ $a -ne $b ]]   # !=
[[ $a -lt $b ]]   # <
[[ $a -le $b ]]   # <=
[[ $a -gt $b ]]   # >
[[ $a -ge $b ]]   # >=

# 字符串比较
[[ "$s1" = "$s2" ]]       # 相等
[[ "$s1" != "$s2" ]]      # 不等
[[ -z "$s" ]]              # 空字符串
[[ -n "$s" ]]              # 非空
[[ "$s" == *.txt ]]        # 通配符匹配
[[ "$s" =~ ^[0-9]+$ ]]    # 正则匹配

# 组合条件
[[ $a -gt 0 && $b -lt 10 ]]    # 与
[[ $a -gt 0 || $b -lt 10 ]]    # 或
[[ ! -f "$file" ]]             # 非

# 三元表达式
result=$([[ $a -gt 10 ]] && echo "yes" || echo "no")
```

## 循环

```bash
# for 循环
for i in {1..5}; do
  echo "$i"
done

for ((i=0; i<10; i++)); do
  echo "$i"
done

for file in *.txt; do
  echo "处理: $file"
done

# while 循环
while IFS= read -r line; do
  echo "$line"
done < "file.txt"

# until 循环
count=0
until [[ $count -eq 5 ]]; do
  echo "$count"
  ((count++))
done
```

## 函数

```bash
# 定义
log() {
  local level="${1:-INFO}"     # 带默认值的参数
  local message="$2"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message"
}

error_handler() {
  local exit_code=$?
  echo "错误: 脚本在第 $LINENO 行退出，退出码 $exit_code"
  exit "$exit_code"
}

trap error_handler ERR  # 错误时调用

# 使用
log "INFO" "开始执行"
die() {
  log "FATAL" "$1"
  exit 1
}
```

## 文件处理

```bash
# 逐行处理（正确方式）
while IFS= read -r line; do
  echo "行: $line"
done < "input.txt"

# 筛选
grep "pattern" file.txt
grep -v "排除" file.txt    # 排除匹配行
grep -r "pattern" .        # 递归搜索

# 替换
sed -i 's/old/new/g' file.txt

# 提取列
awk '{print $1, $3}' file.txt
awk -F',' '{print $2}' data.csv   # 逗号分隔

# 文件统计
wc -l file.txt           # 行数
wc -w file.txt           # 单词数
wc -c file.txt           # 字节数

# 排序去重
sort file.txt
sort -u file.txt         # 去重
sort -n file.txt         # 数值排序
sort -r file.txt         # 降序

# 临时文件
tmpfile=$(mktemp)
tmpdir=$(mktemp -d)
trap "rm -rf $tmpfile $tmpdir" EXIT  # 退出时清理
```

## 颜色输出

```bash
# ANSI 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# 使用
echo -e "${GREEN}✅ 成功${NC}"
echo -e "${RED}❌ 失败${NC}"
echo -e "${YELLOW}⚠️  警告${NC}"

# 格式化函数
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}   $*"; }
error()   { echo -e "${RED}[ERROR]${NC}  $*"; }

# 进度条
progress() {
  local total=$1 current=$2
  local percent=$(( current * 100 / total ))
  local bar_size=50
  local filled=$(( percent * bar_size / 100 ))
  printf "\r[%-${bar_size}s] %d%%" \
    "$(printf '#%.0s' $(seq 1 $filled))" "$percent"
}
```

## 常用模式

```bash
# 并行执行
for url in "${urls[@]}"; do
  (curl -s "$url" > "output_$(basename $url)") &
done
wait
echo "所有下载完成"

# 重试
retry() {
  local n=1
  local max=3
  until ((n > max)); do
    if "$@"; then
      return 0
    fi
    echo "重试 $n/$max..."
    sleep $((n * 2))
    ((n++))
  done
  return 1
}

retry curl -s "https://api.example.com"

# 超时控制
timeout 30 command_here || echo "命令超时"

# 日志轮转
logfile="app.log"
max_size=$((10 * 1024 * 1024))  # 10MB
if [[ -f "$logfile" && $(stat -f%z "$logfile") -gt $max_size ]]; then
  mv "$logfile" "${logfile}.$(date +%Y%m%d-%H%M%S)"
fi

# 检查命令是否存在
for cmd in git curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "缺少依赖: $cmd"
    exit 1
  fi
done
```

## 相关文档

- [[GitHub-CLI-命令大全]]
- [[术语表]]
