# 错误排查指南（Error Troubleshooting）

> 排查顺序：**先分类，再定位**。错误类别决定排查路径。
> 高频错误类别（按优先级）：权限错误 > 路径错误 > JSON 格式错误 > 引擎失败 > 环境差异。

## 1. 日志位置

| 日志 | 路径 | 特点 |
|------|------|------|
| CLI 主日志 | `<logDir>/codescanner.log`（默认 `scanner/logs/codescanner.log`） | 完整 stdout/stderr、参数、每引擎耗时 |
| homeflow 引擎日志 | `HomeFlow.log`（位于部署目录 bin/scanner/logs 等） | — |
| cpp-agent 日志 | `code_scanner_cpp.log` 等 | **append-only：排查用 tail 不用 head** |

排查步骤：
1. 退出码 `2` → 看 stderr（Logger 可能未初始化，无日志文件）。
2. 退出码 `1` → 看 stderr 的 `[toolId] ERROR:` 行 + 日志文件对应段落。
3. 引擎细节 → 看引擎自身日志（主日志只存净化摘要，完整 stderr 在日志文件）。

## 2. 错误分类表

### 2.1 权限错误（最高优先级）

| 错误信息特征 | 根因 | 修复 |
|--------------|------|------|
| `is not readable: <p>` | 目录/文件不可读；Windows 上 `accessSync(R_OK)` 可能误过但 `readdirSync` 兜底拦截（EPERM） | 检查 ACL/只读属性；`icacls` 授权 |
| `is not writable: <p> (<errno>)` | 输出/日志目录写探测失败（临时文件创建被拒）；Windows 上 `accessSync(W_OK)` 不可靠，必须真实写探测 | 放开目录写权限 |
| `compile_commands.json is not readable` | compile_commands.json 读取被拒（EPERM/EACCES） | 授权文件读取；**优先级高于 JSON 格式错误**——先报"不可读"而非"非法 JSON" |
| 引擎 `Failed to start` | 引擎可执行文件缺失或不可执行 | 检查部署完整性（codescanner/homeflow、cpp-agent/） |

### 2.2 路径错误

| 错误信息特征 | 根因 | 修复 |
|--------------|------|------|
| `xxx not found: <p>` | 必选路径不存在（projectPath 必选） | 核对路径 |
| `xxx is not a directory / is not a file` | 类型不符 | 纠正路径 |
| `xxx path is too long (... chars, max 200)` | Windows MAX_PATH=260，阈值 200 留余量；产出文件路径单独校验 | 缩短工程路径或输出路径 |
| `xxx cannot be an empty string` | 参数传入空白串 | 修正参数 |
| 相对路径行为 | 所有路径内部 `path.resolve` 规范化 | 无需处理 |

### 2.3 JSON 格式错误

| 错误信息特征 | 根因 | 修复 |
|--------------|------|------|
| `compile_commands.json is not valid JSON: <p>` | 文件存在、可读，但内容非法 JSON | 重新生成 compile_commands.json（改 CMakeLists.txt 后必须重新生成） |
| `Invalid SARIF output` | 引擎成功退出但产物文件非法 JSON/SARIF | 检查引擎版本/产物 |
| 插件 `Invalid format "xxx", must be: sarif or html` | `-f` 传了非法值 | 修正 format |

> compile_commands.json 处理逻辑（tool-configs.ts）：不存在 → "not found"；读取被拒 → "not readable"（优先）；内容非法 → "not valid JSON"。三类均**跳过 C++ 检查**并打印 `[error]`，不中断整体扫描。跳过属**静默降级**而非引擎失败：若 ArkTS 成功，整体退出码为 0（见 [exit-codes.md](exit-codes.md) §3）。

### 2.4 引擎失败（退出码 1）

| stderr 特征 | 根因 | 修复 |
|-------------|------|------|
| `[homeflow] ERROR: ...` | ArkTS 引擎失败 | 查 HomeFlow.log；确认 SDK 有效 |
| `[cpp-agent] ERROR: ...` | C++ 引擎失败 | 查 code_scanner_cpp.log（tail）；确认 compile_commands.json 有效 |
| `Exited with code N` | 引擎非零退出 | 按 N 查引擎自身文档 |
| `Timed out after Ns` | 引擎超时（默认无超时限制） | 视引擎配置 |
| `Output file not found` | 引擎成功但未产出 SARIF | 检查引擎输出配置 |
| 全部失败 → `All tools failed, no SARIF output` | 无任何成功引擎 | 逐一排查各引擎 |

### 2.5 环境差异（跨平台）

| 现象 | 根因 | 修复 |
|------|------|------|
| Linux 上运行 Windows 产物报 `required file not found` | shell 脚本含 CRLF（Windows 换行） | `sed -i 's/\r$//'` |
| Linux 上 cpp-agent 找不到头文件 | compile_commands.json 的 `-I` 注入不全（toolchain file 不会自动注入 SDK include） | 重新生成 compile_commands.json，确保含 SDK include 路径 |
| Windows 路径被拼进 Linux 环境 | 路径污染（历史 DTS2026090266276 同类问题） | 用 Linux 路径重跑；校验产物路径 |
| `codescanner -v` 指向旧版本 | 多套安装，PATH 被旧版本抢占 | 用绝对路径调用目标部署；检查 PATH 顺序 |

### 2.6 工具可用性（command line tools 未安装 / 未入 PATH）

> 扫描类请求的前置检查。用户报 `codescanner: command not found`、`不是内部或外部命令`，
> 或询问"工具在哪下载 / 怎么配环境变量"时进入本节。

| 现象 | 判定 | 处理 |
|------|------|------|
| `codescanner: command not found`（Linux/macOS） | 未安装或未入 PATH | 二选一：① 用户已有工具 → 让其给出 **command line tools 位置**（解压后根目录）；② 无工具 → 引导下载（见下） |
| `'codescanner' 不是内部或外部命令`（Windows cmd） | 未安装或未入 PATH | 同上 |
| 工具包版本 **< 26.0.1**（以部署目录/安装包名中的 26.0.x 为准；注意 `codescanner -v` 输出的 CLI_VERSION `1.0.0` 是 CLI 内部版本，不反映工具包版本） | **版本不符（不支持扫描）** | 明确告知：仅 **26.0.1+** 支持 codescanner 扫描，旧版无此功能；引导下载/升级到 26.0.1+（见下下载引导） |
| 命令可执行、工具包版本 ≥ 26.0.1 但非期望部署 | 已安装但多套安装 | 用绝对路径调用目标部署（`<工具根目录>/command-line-tools/codescanner/bin/codescanner -v`），检查 PATH 顺序 |

**版本门槛（硬性要求）**：

- **仅 26.0.1 及以上版本**的 command line tools 支持 codescanner 扫描功能。
- 用户版本 < 26.0.1 → 不做扫描指导，直接引导升级：下载 26.0.1+（官方下载页即最新 26.0.x），或让用户提供 ≥ 26.0.1 的工具位置。
- 判定动作：`codescanner -v` 仅确认命令可执行；**工具包版本以部署目录/安装包名中的 26.0.x 为准**（`-v` 输出的 CLI_VERSION=1.0.0 是 CLI 内部版本号，不能用于判定工具包版本）。

**下载引导（用户无工具或版本 < 26.0.1 时）**：

- 官方下载页：[https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos](https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos) （下载为当前最新 26.0.x，满足版本门槛）
- 下载解压后结构：`command-line-tools/`（内含 `bin/`、`codescanner/`、`sdk/` 等）
- 给出位置后，无 PATH 也可用绝对路径调用：
  - Windows：`<工具根目录>\command-line-tools\codescanner\bin\codescanner.exe ...`
  - Linux：`<工具根目录>/command-line-tools/codescanner/bin/codescanner ...`
- 可选：配置 PATH（Windows 加 `...\command-line-tools\bin`；Linux `export PATH=<工具根目录>/command-line-tools/bin:$PATH`）

**配套检查**：

- SDK：`-s` 缺省时按默认顺序解析（部署 sdk/ → DEVECO_SDK_HOME → DEVECO_PATH/sdk）；工具自带 sdk/ 通常已满足。
- 下载/解压后若在 Linux 遇到 `required file not found` → 按 §2.5 CRLF 处理（`sed -i 's/\r$//'`）。

## 3. stderr 净化规则（识别"假报错"）

子进程 stderr 在终端只显示 `summarizeStderr` 摘要：
- 摘要格式：`[toolId] stderr: <Error line + errno 字段>`，**丢弃 at:/node:fs 等 Node 内部堆栈帧**。
- 若用户贴的报错含完整 Node 堆栈，多半是从日志文件复制的——属预期行为，不是新错误。
- 完整 stderr 只在 `<logDir>/codescanner.log`。

## 4. 通用排查流程

```
0. 前置：确认 command line tools 可用（codescanner -v）；缺失 → 走 §2.6 引导安装/给位置
1. 拿到退出码 → 退出码 2：看 stderr；退出码 1：看 [toolId] ERROR:
2. 按错误信息匹配分类表 → 权限 > 路径 > JSON > 引擎 > 环境 > 工具可用性
3. 修复后重跑；对比新旧日志差异（cpp-agent 日志 append-only，tail 旧日志即可）
4. 若涉及 CMakeLists.txt 改动 → 先重新生成 compile_commands.json 再扫
```
