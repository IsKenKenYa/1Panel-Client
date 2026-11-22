# 环境搭建指南

Skill 运行所需的本地工具及其安装方式。

## trace_streamer（htrace→SQLite 转换）

trace_streamer 通过 `tool_finder.py` 自动查找，查找优先级与其他工具相同：

1. `TRACE_STREAMER_PATH` 环境变量
2. DevEco Studio 安装目录（`<DevEcoStudio>/sdk/default/openharmony/toolchains/`）
3. 系统 PATH（`shutil.which()`）

若本机未找到，可从以下地址下载：

```
https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/HiSmartPerf_20260730/trace_streamer_binary.zip
```

**兜底地址**（上方链接失效时访问此页面，找最新版本的 trace_streamer_binary.zip）：

```
https://gitcode.com/openharmony/developtools_smartperf_host/releases
```

**zip 包包含全平台二进制，解压后按平台选择**：

| 平台 | 可执行文件名 |
|------|-------------|
| Windows | `trace_streamer_windows.exe` |
| Linux | `trace_streamer_linux` |
| macOS | `trace_streamer_mac` |

**安装步骤**：

1. 下载 zip 包并解压
2. 按平台选择对应的可执行文件
3. 配置环境变量（二选一）：
   - 设置 `TRACE_STREAMER_PATH` 指向可执行文件完整路径
   - 或将可执行文件重命名为 `trace_streamer`（Windows 上 `trace_streamer.exe`）并加入系统 PATH

**验证**：

```bash
python scripts/0_prerequisites/check_env.py
# 或直接运行
trace_streamer --help
```

### 已知问题：ArkTS heap 可拆解内存为 0（trace_streamer 版本过旧）

**症状**：topdown 分析中 ArkTS heap「可拆解内存 = 0」，全部内存被归入「分配器碎片」；查询 .db 发现 `ARKTS_HEAP_Alloc_Event` / `ARKTS_HEAP_Free_Event` 事件数 = 0。

**根因**：htrace→db 转换用了旧版 trace_streamer（v4.3.7, 2025-04），无法解析 `ARKTS_HEAP_*` / `FD_*` / `ION_*` 等事件类型。htrace 原始数据完整（`ARKTS_HEAP_Alloc_Event` 实际有上万条），纯粹是旧版 trace_streamer 解析遗漏。

**误判教训**：曾见「0 条 ARKTS_HEAP 事件」后错误归因为「应用 release 签名导致 ArkTS 堆追踪不可用」——数据一直在 htrace 里，与签名无关，纯属工具解析问题。

**解决方案**：下载新版 trace_streamer，用新版重新执行 htrace→db 转换。

**验证**：重转后 .db 中 ARKTS_HEAP 事件数 > 0，可拆解内存从 0 恢复为正常值（实测 0 → 62.66/70.76 MB）。

## hdc（HarmonyOS Device Connector）

hdc 随 DevEco Studio 工具链分发。

- **下载 DevEco Studio**：https://developer.huawei.com/consumer/cn/deveco-studio/
- 安装后 hdc 位于 `<DevEcoStudio>/sdk/default/openharmony/toolchains/` 目录
- 配置方式（二选一）：
  - 设置 `HDC_PATH` 环境变量指向 hdc 可执行文件
  - 或将 toolchains 目录加入系统 PATH
- `DEVECO_HOME` 环境变量可指向 DevEco Studio 安装根目录，tool_finder 会自动从中查找所有工具

## addr2line（SO 偏移→源码行号解析，Native Heap 步骤 4 用）

推荐使用 `llvm-addr2line`（比 GNU addr2line 对大型 SO 解析更快）。

- Windows：随 LLVM 安装，或从 [LLVM 官方](https://releases.llvm.org/) 下载
- Linux：`sudo apt install llvm`（提供 `llvm-addr2line`）
- macOS：`brew install llvm`
- 配置方式：设置 `ADDR2LINE_PATH` 环境变量，或加入 PATH

## 工具查找优先级

所有工具路径通过 `scripts/_lib/tool_finder.py` 自动查找，按以下优先级：

1. **环境变量**：`HDC_PATH` / `TRACE_STREAMER_PATH` / `ADDR2LINE_PATH` / `DEVECO_HOME`
2. **DevEco Studio 安装目录**：自动检测 `<DevEcoStudio>/sdk/default/openharmony/toolchains/`
3. **系统 PATH**：`shutil.which()` 查找

## Python 依赖

- Python >= 3.10（3.8 不支持 `DataFrame.map()`）
- 命令调用：Windows 用 `python` 或 `py`，Linux/macOS 用 `python3`（`check_env.py` 已内置版本门禁，低版本会友好提示退出而非崩溃）
- 依赖包：`pandas`、`openpyxl`
- 安装：`pip install pandas openpyxl`
- 修改代码后需清除缓存：`find scripts -name '__pycache__' -type d -exec rm -rf {} +`

## 一键环境检查

```bash
python scripts/0_prerequisites/check_env.py
# 检查指定应用是否安装
python scripts/0_prerequisites/check_env.py -b com.example.app
# 检查并安装
python scripts/0_prerequisites/check_env.py -b com.example.app --install /path/to/app.hap
```

check_env.py 会逐项检查 hdc / trace_streamer / Python 版本 / Python 依赖包 / 应用安装状态，并在有缺失时打印对应的下载地址和配置指引。
