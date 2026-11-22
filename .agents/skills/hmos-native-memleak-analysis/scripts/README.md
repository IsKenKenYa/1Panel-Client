# Flame Stack Analyzer

内存泄露堆栈分析工具，用于从 SQLite 数据库中查询指定内存块的调用栈信息。

## 功能特性

- 按内存块大小（`heap_size`）查询调用栈
- 自动筛选 **Create && Existing**（未释放，`end_ts = 0` 或 `end_ts > start_ts`）的内存块
- 自动识别 JS 堆栈
- 计算调用栈内存占比
- 支持按泄露类型过滤（`-t` 参数）

## 数据库表结构要求

工具依赖 trace_streamer 生成的 SQLite 数据库，需要包含以下表和字段：

### native_hook 表（优先）
如果 `native_hook` 表有数据，优先从该表查询：
| 字段 | 类型 | 说明 |
|------|------|------|
| callchain_id | INTEGER | 调用链ID |
| ipid | INTEGER | 进程ID |
| itid | INTEGER | 线程ID |
| addr | INTEGER | 内存地址 |
| heap_size | INTEGER | 内存块大小 |
| start_ts | INTEGER | 开始时间戳 |
| end_ts | INTEGER | 结束时间戳（0表示未释放） |
| event_type | TEXT | 事件类型（如 AllocEvent, JS_Alloc, ARKTS_Alloc） |
| sub_type_id | INTEGER | 子类型ID |

### native_hook_statistic 表（备选）
如果 `native_hook` 表没有数据，则从 `native_hook_statistic` 表查询：
| 字段 | 类型 | 说明 |
|------|------|------|
| callchain_id | INTEGER | 调用链ID |
| ipid | INTEGER | 进程ID |
| apply_size | INTEGER | 分配内存大小 |
| release_size | INTEGER | 释放内存大小 |
| type | INTEGER | 类型（0=AllocEvent, 1=MmapEvent, 3=ARKTS_Alloc, 5=JS_Alloc 等） |
| sub_type_id | INTEGER | 子类型ID |

### native_hook_frame 表
| 字段 | 类型 | 说明 |
|------|------|------|
| callchain_id | INTEGER | 调用链ID |
| depth | INTEGER | 栈帧深度 |
| ip | INTEGER | 指令地址 |
| symbol_id | INTEGER | 符号ID |
| file_id | INTEGER | 文件ID |
| offset | INTEGER | 偏移 |
| symbol_offset | INTEGER | 符号偏移 |

### data_dict 表
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 字符串ID |
| data | TEXT | 字符串数据 |

## 编译方法

### 方法一：使用 GN 编译

GN 是跨平台的构建系统，支持 Linux、Windows、macOS。

#### Linux

```bash
cd trace_streamer

# 配置编译
gn gen out/release --args="target_os=\"linux\" target_cpu=\"x64\""

# 编译
ninja -C out/release flame_stack_analyzer

# 二进制文件位置
# out/release/obj/flame_stack_analyzer/flame_stack_analyzer
```

#### Windows

```powershell
# 使用 Visual Studio Developer Command Prompt 或 PowerShell

cd trace_streamer

# 配置编译（Windows x64）
gn gen out/release --args="target_os=\"win\" target_cpu=\"x64\""

# 编译
ninja -C out/release flame_stack_analyzer

# 二进制文件位置
# out/release/obj/flame_stack_analyzer/flame_stack_analyzer.exe
```

#### macOS

```bash
cd trace_streamer

# 配置编译（macOS x64）
gn gen out/release --args="target_os=\"mac\" target_cpu=\"x64\""

# 编译
ninja -C out/release flame_stack_analyzer
```

### 方法二：使用 CMake 编译（独立）

创建 `CMakeLists.txt`：

```cmake
cmake_minimum_required(VERSION 3.10)
project(flame_stack_analyzer)

set(CMAKE_CXX_STANDARD 17)
include_directories(include)
find_package(SQLite3 REQUIRED)

add_executable(flame_stack_analyzer
    main.cpp
    flame_query.cpp
    leak_analyzer.cpp
    stack_resolver.cpp
)

target_link_libraries(flame_stack_analyzer SQLite3::SQLite3 pthread)
```

编译：

```bash
mkdir build && cd build
cmake .. && make -j4
```

## 静态打包

### Linux 静态编译

```bash
# 安装静态库
apt-get install -y libc6-dev libsqlite3-dev

# 静态编译
g++ -static -O2 -std=c++17 \
    main.cpp flame_query.cpp leak_analyzer.cpp stack_resolver.cpp \
    -I./include -lsqlite3 -lpthread \
    -o flame_stack_analyzer
```

### macOS 静态编译

```bash
# 安装 sqlite
brew install sqlite3

# 编译
g++ -O2 -std=c++17 \
    main.cpp flame_query.cpp leak_analyzer.cpp stack_resolver.cpp \
    -I./include -lsqlite3 \
    -o flame_stack_analyzer
```

## 调用方法

### 基本用法

```bash
# 查询指定内存块大小的调用栈，总内存使用所有未释放数据计算
./flame_stack_analyzer trace.db 1024

# 查询多个内存块大小的调用栈
./flame_stack_analyzer trace.db 1024 2048 4096

# 指定泄露类型
./flame_stack_analyzer trace.db -t JSHeap 1024

# 排除 JS 堆栈
./flame_stack_analyzer trace.db --no-js 1024
```

### 命令行参数

| 参数 | 说明 |
|------|------|
| `database_file` | SQLite 数据库文件路径 |
| `size` | 内存块大小（必需，用于过滤匹配的调用栈） |
| `-t, --type <type>` | 泄露类型：Malloc/JSHeap/ArkTSHeap/DartHeap 等 |
| `--no-js` | 排除 JS 堆栈 |
| `-v, --version` | 显示版本 |
| `-h, --help` | 显示帮助 |

### 泄露类型

- `Malloc` - malloc/free 分配
- `Mmap` - mmap/munmap 分配
- `JSHeap` - JavaScript 堆分配
- `ArkTSHeap` - ArkTS 堆分配
- `DartHeap` - Dart 堆分配
- `ArkGlobalHandle` - Ark 全局句柄
- `ArkLocalHandle` - Ark 局部句柄
- `KmpHeap` - KMP 堆分配
- `SO` - 共享库加载
- `FD` - 文件描述符打开
- `Thread` - 线程创建
- `GPU_VK` - Vulkan 分配
- `GPU_GLES` - OpenGL ES 分配

## 输出示例

```
Total Sample Memory: 15728640 bytes

--- #1 ---
Memory: 10485760 bytes, 66.67%, Count: 2, Type: Native
Block: 5242880 bytes
  #00 0x0000000000010000 libc.so(malloc+0x1234)
  #01 0x0000007f8c123456 libapp.so(main+0x100)

--- #2 ---
Memory: 5242880 bytes, 33.33%, Count: 1, Type: JS
Block: 5242880 bytes
  #00 0x0000007f8c123456 hermes.so(ark::JSFunction+0x2000)
```

## 字段说明

| 字段 | 说明 |
|------|------|
| Memory | 该调用链的总内存大小 |
| Percentage | 占总采样内存的百分比 |
| Count | 命中次数（相同调用链的内存块数） |
| Type | Native 或 JS |
| Block | 单个内存块的大小 |
| Stack | 调用栈路径，格式：`库名(函数+偏移)` |
