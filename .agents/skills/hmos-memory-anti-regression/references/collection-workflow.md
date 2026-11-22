# 采集工作流

## Windows (Git Bash) 路径转换问题

在 Windows 上通过 Git Bash 执行 `hdc shell` / `hdc file recv` 命令时，MSYS2 会自动将 `/data/local/tmp/...`、`/data/log/...`、`/proc/...` 等设备端路径转换为 `C:/Program Files/Git/data/local/tmp/...`，导致设备上找不到文件，**heapsnapshot / htrace 拉取全部失败**。

**修复方法**（在执行任何 hdc 命令前运行一次）：

```bash
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"
```

或者，**优先使用 Python 采集脚本**（`scripts/1_collection/collect.py`、`scripts/1_collection/dump_mem.py`），它们通过 `subprocess.run(list_args)` 直接调用 `hdc.exe`，不经过 shell，不受路径转换影响。

---

## 工具分工

| 数据类型 | 采集工具 | 输出格式 | 数据性质 |
|----------|----------|----------|----------|
| htrace | `hiprofiler_cmd` | .htrace | 过程态 |
| showmap | `hidumper --mem <pid> --prune` | .txt | 瞬时 |
| smaps | `hidumper --mem-smaps <pid>` | .txt | 瞬时 |
| heapsnapshot | `hidumper --mem-jsheap <pid> -T <pid>` | .heapsnapshot | 瞬时 |
| mm_dmabuf | `cat /proc/<pid>/mm_dmabuf_info` | .txt | 瞬时 |
| hilog | `hilog -T <pid>`（Popen+10s timeout 捕获流式输出） | .txt | 场景期日志 |
| 窗口/组件树 | `hidumper -s WindowManagerService -a "-dumpWindow"` | .txt | 瞬时 |

> 各命令的完整参数、输出格式、注意事项 → `references/hidumper_commands.md`

## 采集前确认（两阶段门控）

采集前确认分为**两个阶段**，缺一不可。**必须在调用 collect.py 之前全部完成**，不得依赖 collect.py 内部的确认（collect.py 以非交互子进程被调用，`prompt_confirm` 在非 TTY 且无 `--yes` 时直接报错退出，不会静默采集）。

### 阶段一：采集方案确认

告知用户采集方案并取得确认：

1. 告知用户即将执行的采集步骤（杀应用 → 重启 → htrace → 瞬时数据 → 拉取htrace）
2. 告知用户采集时长（如 60s）
3. 提醒用户确保应用已登录并处于正常使用状态
4. 等待用户明确确认后才开始

**示例提示**：
```
即将开始内存数据采集，步骤:
1. 杀死应用
2. 重启应用 (清除之前的内存干扰)
3. 启动 htrace 过程态采集 (nativehook 详细模式, 60s)
4. 采集 showmap / smaps / heapsnapshot
5. 拉取 htrace 文件

请确保应用已登录并处于正常使用状态
```

### 阶段二：复现时机确认（最关键）

hiprofiler_cmd 一旦启动即进入 trace 采集状态，用户必须在精确时刻开始操作场景。AI **必须使用 AskUserQuestion 工具**（不得仅用文本提示），在 collect.py 执行前再次向用户明确告知复现时机并取得确认：

**冷启动场景示例**：
```
即将开始 <app>_<版本号>[_<场景>] 的数据采集，请确认以下复现时机：

采集时长：60 秒
场景模式：冷启动

⚠️ 复现时机（关键）：
profiler 将在3秒后自动拉起应用，应用拉起后请立即开始操作/复现问题！
整个采集期间（60秒）请持续操作目标场景。

请确认您已了解复现时机，准备好后在应用拉起后立即操作：
- 已了解，准备好开始采集
- 稍等，我还没准备好
```

**运行态场景示例**：
```
即将开始 <app>_<版本号>[_<场景>] 的数据采集，请确认以下复现时机：

采集时长：30 秒
场景模式：运行态

⚠️ 复现时机（关键）：
profiler 启动后请立即开始操作/复现问题！
与 profiler 启动间隔越短越好，整个采集期间（30秒）请持续操作目标场景。

请确认您已了解复现时机，准备好后立即操作：
- 已了解，准备好开始采集
- 稍等，我还没准备好
```

**AI 调用方式（关键）**：正确流程为 ① 阶段一确认（采集方案）→ ② 阶段二确认（复现时机，必须用 AskUserQuestion）→ ③ 两阶段都确认后才运行 `python scripts/1_collection/collect.py --yes ...`（`--yes` 跳过确认门禁，前提是 AI 已与用户完成两阶段确认）。未传 `--yes` 的非交互调用 collect.py 会直接报错退出，杜绝静默采集。

**重要**：未经用户完成两阶段确认，不得执行任何采集操作（尤其是杀应用、启动 profiler 等破坏性操作）。


## 应用安装检查

采集前必须确认应用已安装。若应用未安装但用户提供了安装包路径（.hap/.app），则先安装。

**安装包数量检查**：若用户提供的目录中只检测到一个 `.hap`/`.app` 安装包，必须**提示用户**：内存防劣化分析需要对**两个版本**（旧版/基线 + 新版/当前）分别采集数据才能对比，单个安装包无法生成版本差值。询问用户是继续单版本采集（仅出单版本归因报告，无对比），还是补充另一个版本的安装包后再开始。

```bash
HDC="${HDC_PATH:-hdc}"

# 检查应用是否已安装
"$HDC" shell "bm dump -n <bundle>" | grep -q "com\." && echo "已安装" || echo "未安装"

# 未安装时，直接用本地安装包路径安装
HAP_LOCAL="/path/to/app.hap"
"$HDC" install "$HAP_LOCAL"

# 安装后必须再次确认安装成功（hdc install 有时失败但无明确报错）
"$HDC" shell "bm dump -n <bundle>" | grep -q "com\." && echo "已安装" || echo "安装失败"

# 安装失败时，先卸载已有版本再重装（签名冲突或版本降级时需此步骤）
"$HDC" uninstall <bundle>
"$HDC" install "$HAP_LOCAL"
"$HDC" shell "bm dump -n <bundle>" | grep -q "com\." && echo "已安装" || echo "安装失败"

# 获取已安装版本信息（用于产物目录命名，collect.py 自动提取 versionName）
"$HDC" shell "bm dump -n <bundle>" | grep -E "versionName|versionCode"
```

**注意**：`hdc install` 直接使用本地路径即可。安装后必须用 `bm dump` 再次确认安装成功。

**安装后必须完成登录前置操作**：应用安装后，通过 `--login-scenario` + `--login-scenario-dir` 自动执行 Hypium 登录预制脚本（如 `python main.py MyappPrerequisiteSetup`），脚本执行成功（退出码 0 + xdevice 报告校验通过）后自动继续；未提供时回退为人工确认，提示用户在设备上完成登录、初始设置等操作，并确认应用处于正常使用状态后，才能继续执行杀应用和采集流程。

## 双版本采集顺序（关键，不可逆）

完整对比流程是 **采旧版 → 换新版 → 采新版**，不要在同一安装版本上连采两次：

> 产物输出目录 = 运行 `collect.py` 时工作目录下的 `output/`（`collect.py` 默认 `--output-base ./output`，相对当前运行目录，**非 skill 安装目录**）。AI 调用时工作目录通常为 workspace 根目录，产物落到 `<workspace>/output/<app>_<版本号>[_<场景>]/`。**版本号自动从 HAP 或设备提取 versionName（如 `14.8.10`），禁止使用 `old`/`new` 等泛化标签。**

1. 安装旧版 → **登录前置**（`--login-scenario` + `--login-scenario-dir` 自动执行，或人工登录确认）→ 执行完整采集流程（htrace + 瞬时数据 + hilog）→ 产物归置到 `<工作目录>/output/<app>_<旧版本号>[_<场景>]/`
2. **先确认旧版产物已全部拉取并归置完成**——heapsnapshot/smaps/showmap 等瞬时数据在覆盖安装新版后**无法补采**
3. 覆盖安装新版（`hdc install <新版.hap>`）→ **登录前置**（`--login-scenario` 自动执行，或人工登录确认）→ 执行同一套采集流程 → 产物归置到 `<工作目录>/output/<app>_<新版本号>[_<场景>]/`
4. 两个版本的采集必须保持同一业务场景、同一采集时长、同一操作路径，否则差值无意义

## Windows 环境注意事项

Windows 下通过 `hdc shell` 管道传输二进制数据时，系统会自动将 `\n` 转换为 `\r\n`，导致 htrace 文件数据损坏、解析失败。

**规则**：
- Windows 下**必须**使用配置文件推送 + 设备端采集 + `hdc file recv` 拉取，禁止使用 heredoc 管道
- Linux/macOS 下直接使用 `hdc shell "hiprofiler_cmd -c - -o ... <<CONFIG ... CONFIG"` heredoc 管道方式即可
- Python 脚本（collect.py / dump_mem.py）已自动处理，无需手动适配

> 配置文件推送方式的完整示例 → `references/hiprofiler_config.md` "方式2: 配置文件推送"

## 场景复现自动化（--scenario + --scenario-dir 参数）

当外部 Hypium 场景复现工程可用时，可通过 `collect.py --scenario <xdevice测试用例名> --scenario-dir <工程路径>` 在 htrace 采集期间自动执行 UI 操作，替代手动复现。Hypium 工程为外部依赖，不包含在本 skill 内，需调用方提供路径。

### 工作原理

1. `collect.py` Phase 2 启动 hiprofiler_cmd 后，在后台启动 `<scenario-dir>/main.py <测试用例名>`（由 Hypium 脚本负责拉起应用）
2. 场景模式下 `collect.py` 不执行 `aa start`，由 Hypium 脚本的 step1 负责拉起应用
3. htrace 采集结束后，`collect.py` 等待场景脚本完成（最多 180s）
4. 场景脚本退出后，`collect.py` 解析 xdevice 报告校验执行结果（见「场景执行结果校验」）

### 场景执行结果校验

`collect.py` 在场景脚本退出后，自动检查 xdevice 报告判断场景是否执行成功：

1. **定位报告**：在 `<scenario-dir>/reports/` 下，按时间窗口（场景启动时间之后）+ 场景名匹配（module.name 包含 `--scenario` 参数值，大小写不敏感）定位本次场景的报告
2. **判断结果**：读取 `report_data.json`，检查 `summary.failed` 和 `cases[].result` / `steps[].completed`
3. **失败处理**：
   - 交互模式：提示用户选择「重新采集」或「继续使用当前数据」
   - `--yes` 模式：打印修复建议，返回退出码 `2`

退出码：`0`=成功, `1`=采集出错, `2`=场景执行失败

### 采集时长自动调整

当 `--scenario` 指定时，`collect.py` 自动估算采集时长，确保覆盖完整场景操作：

1. **优先从历史 xdevice 报告读取实际耗时**（最准确，加 5s 缓冲）
2. **无历史报告时使用保守默认值**（180s）

若用户指定时长不足，自动上调至估算值。

### Hypium 工程约定

collect.py 调用 Hypium 工程时遵循以下约定：
- 工程根目录下必须有 `main.py` 入口
- `main.py` 支持 `<xdevice测试用例名>` 参数格式（如 `MyappScenarioReplay`）
- xdevice 测试报告输出到 `<工程路径>/reports/<timestamp>/`

## 采集模式

| 模式 | startup_mode | 流程 | 复现时机 | 说明 |
|------|-------------|------|---------|------|
| 冷启动 | `true` | 杀应用 → 启动 profiler → sleep 3 → 启动应用 → wait | 应用拉起后即可开始复现 | 从应用启动瞬间开始采集 |
| 运行态 | `false` | 应用已运行 → 启动 profiler → wait | profiler 启动后立即开始复现 | 采集运行期间内存分配 |

## 采集参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| `statistics_interval` | `0` | 详细模式（记录每条事件，数据精准） |
| `startup_mode` | `true`/`false` | 应用未启动必须 true，已运行必须 false |
| `sample_interval` | `4096` | 采样间隔 |
| `max_stack_depth` | `30` | 调用栈深度 |
| `smb_pages` | `16384` | 共享内存页数 |
| `restrace_tag` | 9个全选 | DMA/FD/ArkTS/JS/GPU 全覆盖 |

## hiprofiler_cmd 参数

| 参数 | 说明 |
|------|------|
| `-c -` | stdin 管道传配置（推荐，无需临时文件） |
| `-c <path>` | 配置文件路径（设备上的路径） |
| `-o` | 输出 htrace 文件路径（设备上的路径） |
| `-t` | 采集时长（秒） |
| `-s` | 启动 profiling 服务 |
| `-k` | 结束后 kill profiling 服务 |

**警告**：应用已运行时必须设 `startup_mode: false`；应用未启动时必须设 `startup_mode: true`。

## restrace_tag 类型

| restrace_tag | 说明 |
|---|---|
| `RES_DMABUF_MASK` | DMA buffer 分配栈 |
| `RES_FD_ALL` | 文件描述符分配栈 |
| `RES_ARKTS_HEAP_MASK` | ArkTS 堆分配栈 |
| `RES_JS_HEAP_MASK` | JS 堆分配栈 |
| `RES_GPU_VK` | Vulkan GPU 内存 |
| `RES_GPU_GLES_BUFFER` | OpenGL ES Buffer |
| `RES_GPU_GLES_IMAGE` | OpenGL ES Image |
| `RES_GPU_CL_BUFFER` | OpenCL Buffer |
| `RES_GPU_CL_IMAGE` | OpenCL Image |

推荐在一个配置中使用多个 restrace_tag，同时采集多种资源类型。

## 采集产物目录结构

collect.py / dump_mem.py 自动将产物按以下结构归置到 `<output>/<app>_<版本号>[_<场景>]/meminfo/`：

```
meminfo/
├── dynamic_meminfo/          ← hidumper --mem --prune（系统级内存总览）
├── dynamic_dumpMem/          ← hidumper -s 10 -a dumpMem（进程级内存摘要）
├── dynamic_showmap/          ← hidumper --mem-smaps <pid>（逐映射 12 列明细）
├── dynamic_appsmaps/         ← cat /proc/<pid>/smaps（内核原始 VMA）
├── dynamic_gpuMem/           ← hidumper --mem --gpu（GPU 显存）
├── dynamic_process_dmabuf_info/ ← /proc/<pid>/smaps + dmabuf（进程级 DMA）
├── hilog/                    ← hilog -T <pid>（场景期应用日志，ArkWeb 案例匹配用）
├── window_dump/              ← hidumper WindowManagerService dumpWindow（窗口/组件树，ArkWeb 案例匹配用）
└── 单框架动态内存占用详情.xlsx  ← 外部提供（非脚本生成）
```

> 注意：`dynamic_showmap/` 目录名含"showmap"，但实际存放的是 `hidumper --mem-smaps`（smaps 逐映射 12 列）输出，不是 `hidumper --mem`（showmap 分类汇总）输出。

## 采集产物完整性校验（关键）

单版本采集完成后，**必须立即校验产物是否齐全**。不完整的产物会导致后续分析失败或结果不可信，且切换版本后瞬时数据无法补采。

### 必需产物清单

| 产物 | 路径（相对 `<output>/<app>_<版本号>[_<场景>]/`） | 校验条件 |
|------|---------------------------------------|---------|
| htrace | `*.htrace` | 文件存在且 > 10MB |
| meminfo | `meminfo/dynamic_meminfo/dynamicMem_*.txt` | 文件存在且非空 |
| showmap | `meminfo/dynamic_showmap/*.txt` | 文件存在且非空 |
| dma | `meminfo/dynamic_process_dmabuf_info/process_dmabuf_info_*.txt` | 文件存在且非空 |
| heapsnapshot | `heapsnapshot/hidumper-jsheap-*` | 文件存在且非空 |
| hilog | `meminfo/hilog/hilog_*.txt` | 文件存在且行数 > 0（ArkWeb 案例匹配必需，否则规则 2/3 降级为「无法判定」） |

### 校验与处理流程

1. 采集完成后，逐项检查上表中的产物是否存在且满足校验条件
2. **全部通过**：标记该版本采集成功，继续下一步
3. **任一缺失或异常**：
   - 立即向用户报告缺失项（列出具体缺失的产物和路径）
   - **删除该版本不完整的产物目录**（`rm -rf <output>/<app>_<版本号>[_<场景>]/`），避免后续分析误用残缺数据
   - **立即重新采集该版本**（不需要等待，应用状态仍在内存中，补采比后续发现缺失再补采更可靠）
   - 重新采集后再次校验，若仍失败则停止并提示用户排查环境问题

> **统一用脚本校验**（单一事实来源，勿手写 bash 逐项判断，易与脚本逻辑不同步）：
>
> ```bash
> python scripts/1_collection/verify_collection.py <output>/<app>_<版本号>[_<场景>]
> ```
>
> 退出码：`0` 必需产物齐全；`1` 缺失。AI 在采集完成后应自动执行此命令，依据退出码决定是否继续。

**重要**：双版本采集时，旧版采集完成后**先校验旧版产物**，确认齐全后再安装新版。旧版产物不完整时，删除后立即重新采集旧版，**不要带着残缺数据进入新版采集**。

## htrace→db 转换

trace_streamer 通过 `tool_finder.py` 自动查找（`TRACE_STREAMER_PATH` → DevEco Studio → PATH）。若本机未找到，可从以下地址下载，zip 包包含全平台二进制，解压后按平台选择。

- 下载：`https://gitcode.com/openharmony/developtools_smartperf_host/releases/download/HiSmartPerf_20260730/trace_streamer_binary.zip`
- 兜底（链接失效时找最新版）：`https://gitcode.com/openharmony/developtools_smartperf_host/releases`
- → 详见 references/environment.md

```bash
# 使用脚本（推荐，自动查找 trace_streamer，自动推导输出路径）
python scripts/1_collection/convert_htrace.py <input>.htrace [-o <output>.db]

# 或手动执行
TS="${TRACE_STREAMER_PATH:-trace_streamer}"
"$TS" <input>.htrace -e <output>.db
```
