---
name: hmos-apifault-analysis
description: "定位开发者问题。当遇到 API 调用失败或报错、错误码（如 5400xxx、801、9200 等）、crash/freeze 日志（hilog、HiviewDFX）、或需要根据日志与源码定位问题根因时使用——即使用户没明说要做诊断也应触发。输出结构化诊断报告（错误码映射 + 根因候选 + 代码修改建议）。"
metadata:
   version: 1.1.0
---
# 问题定位 Skill

帮助开发者诊断问题的 Agent Skill。接收问题描述和故障日志，通过环境发现+项目代码分析+两阶段分级诊断，输出结构化诊断报告。

## 执行承诺（无论怎么触发都要遵守）

**无论用户输入多简单——哪怕只给一个错误码或一句话描述——都必须尝试执行下方的 6 阶段流程，不要只凭训练记忆直接回答错误码含义。**

原因：同一个错误码在不同模块、不同调用方式、不同设备日志下根因可能完全不同；凭记忆给的根因经常是错的，会误导开发者。只有走「线索提取 → 模块识别 → 知识库/文档 → 源码 → 报告」才能给出靠谱结论。

**关键原则：尝试执行，而非按输入完备度跳过。** 不再按"有没有设备/有没有项目"分档跳过阶段——阶段 0、1、2、3、5、6 都要真正走一遍：

- 缺前置条件（无设备、无项目源码、无 hilogtool 等）时，**不得直接跳过该阶段**。先尝试执行该阶段的每一个步骤；当某一步确实因缺前置条件无法完成时，在报告里如实记录"该步骤未能执行 + 原因 + 对诊断置信度的影响"，然后继续下一阶段。
- 缺设备/缺日志：阶段2 仍要尝试（检查用户提供的日志、尝试 hdc 连接），采集不到则记录"无法采集运行时日志，结论仅基于静态分析"，并在报告置信度中体现。
- 缺项目源码：阶段5 仍要尝试（在 cwd 下 Glob/Grep 搜索），搜不到相关源码则记录"项目内未找到相关代码"，并基于已有线索给出修改建议方向。

**唯一例外——阶段4（深潜分析）按置信度跳过：** 阶段4 是否执行由阶段3.3 的置信度评估决定——**高置信度跳过阶段4，低置信度执行阶段4**（保持现有机制不变）。除阶段4 外，其余阶段无论输入多简单、是否有设备/项目，都要尝试执行。

> **为什么"尝试"而非"跳过"：** 跳过会让 agent 误以为某条证据链已闭合、给出过于自信的根因；而"尝试后记录缺失"能在报告里诚实暴露证据缺口，让开发者知道结论的边界（哪些是实锤、哪些是推断），这才是负责任的诊断。

唯一可以只答错误码、不跑流程的情况：用户**明确**说"只解释这个错误码/只想知道含义，不用诊断"。

## 参数

| 参数                | 必填 | 说明                                            |
| ------------------- | ---- | ----------------------------------------------- |
| problem_description | 是   | 开发者对问题的文字描述                          |
| log_content         | 否   | 故障日志原文（hilog、HiviewDFX crash/freeze等） |
| log_content_file    | 否   | 日志文件路径（当日志较长时优先于log_content）   |
| code_snippet        | 否   | 相关代码片段                                    |

## 参考文件

- `references/log_patterns.md` - 日志解析模式（HiviewDFX 格式、字段含义、提取规则）
- `references/module_mapping.md` - 模块映射表（错误码/DOMAIN/.so/API→模块，含代码仓/文档仓URL）
- `references/platform_config.md` - 平台配置速查表（命令映射、路径规则、SDK提取）
- `references/tool_mapping.md` - 工具映射（CodeGenie↔终端Agent 工具名、降级方案W/E）
- `references/execution_rules.md` - 细节查阅（脚本输出JSON字段、hilogtool候选路径、媒体分析矩阵、子Agent返回契约等），非工作流重述
- `references/report_template.md` - 结构化诊断报告模板
- `references/knowledge/{module_name}/` - 知识库（error_codes.json、api_chain.json、common_issues.md等）
- `references/scripts/` - 辅助脚本（hilog_collector.py、media_file_analyzer.py）

**工具名映射：** 见`references/tool_mapping.md`。下文统一用CodeGenie的`builtin_*`工具名描述；终端Agent执行时按该表替换。

## 执行流程（6阶段）

### 阶段0：环境发现

**目标：** 探测宿主平台与运行环境，确定项目根目录、SDK路径，发现hilogtool，创建输出目录。

**执行步骤：**

1. **平台探测：** 按下表探测OS和Shell，记录host_os、host_shell、py_cmd

   ```
   OS探测: python3 -c "import platform; print(platform.system())"
           └ 失败改python，输出Windows→host_os=windows, Darwin→host_os=macos
   Shell探测: uname -s
              └ 退出码0→host_shell=bash, 非0→host_shell=powershell
   ```
2. **确定项目根目录：** 当前工作目录即为项目根目录。读取`local.properties`提取`sdk.dir=`获取SDK路径（备用：`build-profile.json5`）。
3. **创建输出目录：** 按host_shell分支（见`platform_config.md`表2）创建`diagnosis/`目录。
4. **发现hilogtool（必须执行）：** 在SDK路径下查找（见`platform_config.md`表3），记录hilogtool_path。**这是阶段2 步骤A 解码日志的前提**——没有 hilogtool，脚本只能 gzip 降级、日志含乱码，错误码/domain/crash 标记无法提取，根因分析失效。必须认真搜索两个候选路径；只有确实都不存在时才记 null（并在报告中注明降级），不得图省事直接跳过。
5. **记录路径：** host_os、host_shell、py_cmd、project_root、sdk_path、hilogtool_path、output_dir。

---

### 阶段1：线索提取与模块识别

**目标：** 从输入中提取所有可用线索，识别涉及的模块。

**步骤1：解析输入（按优先级）**

- 有`log_content_file`：Read文件→按`log_patterns.md`解析
- 有`log_content`：直接按`log_patterns.md`解析
- 有`problem_description`：提取错误码、API名称、功能关键词
- 有`code_snippet`：提取API调用和错误处理逻辑

**步骤2：模块识别** 读取`module_mapping.md`，用提取的线索匹配（按优先级：错误码前缀 > DOMAIN标识 > .so库名 > API名称前缀 > hilog domain_id）。

**步骤3：Kit名推断**

- 错误码前缀匹配成功 → 从表1"Kit名"列提取
- 模块名识别成功 → 用模块名反查表1"Kit名"列
- 记录到`clues.kit_names`

**步骤4：线索汇总**

```json
clues = {
  error_codes: [], event_names: [], domains: [],
  call_stack_highlights: [], so_libraries: [],
  modules: [], api_names: [], hilog_domain_ids: [], kit_names: [],
  state_transitions: []  // 日志分析后添加
}
```

---

### 阶段2：日志采集与解析

**目标：** 采集设备日志（落盘 + 内存缓冲区）、解析、做相关性检查与状态机追踪，为后续诊断提供证据。

**强制执行：** ⚠️ **日志是诊断核心依据，必须执行。除非用户明确要求跳过，否则不得省略。** 若无设备且无用户日志，见开头「执行承诺」——注明后继续后续阶段，不阻塞。

⚠️ **采集工具约束：** 所有日志采集（步骤A 的 `hilog_collector.py`、步骤C 的 `hilog -x`）必须通过 execute_command 执行本 skill 规定的命令，**禁止用 agent 自带的日志采集工具替代**。脚本负责：①用 hilogtool+字典解码二进制 hilog（否则乱码）；②产出 JSON `status` 驱动步骤B/C 分支；③产出 `parsed_files` 供相关性检查。自带工具做不到这三点，且会让 agent 误以为"采集完成"而跳过脚本，导致后续无文本可分析。

**优先级1 - 用户提供的日志（入口线索）：** 若有`log_content`或`log_content_file`，先按`log_patterns.md`解析作为入口线索。但用户粘贴的静态日志可能不全或非当前复现——**若相关性检查未命中`clues.error_codes`和`clues.api_names`（即没提取到关键线索），降级到优先级2 用 hdc 补采集（步骤A/C）**，避免漏掉设备上的当前错误。

**优先级2 - hdc读取设备落盘日志：**

**步骤A - 使用脚本采集：**

```bash
{py_cmd} "{skill_dir}/references/scripts/hilog_collector.py" \
  --output-dir diagnosis \
  {若hilogtool_path非null则添加: --hilogtool "{hilogtool_path}"} \
  --time-window 10
```

**脚本输出status处理：**

- `success`：执行步骤C采集内存缓冲区，再进入相关性检查
- `partial`：注明"日志采集部分超时/不完整"后执行步骤C，再继续分析parsed_files
- `no_logs`：进入步骤B开启落盘（不执行步骤C）
- `no_device/error`：注明"hdc日志采集失败"后继续后续阶段（不执行步骤C）

**步骤C - 采集内存中未落盘日志（步骤A未进入步骤B时执行）：**
当步骤A status 为 `success`/`partial` 时执行（设备可达、已拿到落盘日志）。落盘日志有滞后，最新错误可能仍在内存缓冲区未刷盘，用 `hilog -x` 一次性全量转储内存缓冲区（不做级别过滤，避免漏掉 Warning 铺垫或任何级别线索，由相关性检查再筛）：

```bash
hdc shell "hilog -x"
```

将输出保存到 `diagnosis/mem_buffer_<时间戳>.txt`。输出超过 5M（参照步骤B 的 `-l 5M`）时只保留**最近 5M**——`hilog -x` 按时间从旧到新输出，最新未落盘的错误在缓冲区末尾，取尾部：

- bash：`hdc shell hilog -x | tail -c 5M > diagnosis/mem_buffer_<时间戳>.txt`
- powershell：对应重定向写法见 `platform_config.md §2`

（可选：按 `clues` 用 `-D <domain>` / `-T <tag>` 进一步定位。）

生成的 `mem_buffer_*.txt` 与步骤A 的 `parsed_files` 合并，一起进入下面的相关性检查与后续分析。

**问题相关性检查：** 按步骤A 的 `parsed_files`（从旧到新）+ 步骤C 的 `mem_buffer_*.txt` 读取日志，检查：

1. 精确匹配：搜索clues.error_codes、clues.api_names、clues.so_libraries、clues.domains
2. 模糊匹配：在hilog Error/Fatal行搜索problem_description关键词
3. 崩溃标记：检查"Generated by HiviewDFX@OpenHarmony"

**步骤B - 无落盘日志时开启落盘：**

```bash
# 1. 开启落盘
hdc shell "hilog -w start -f diag -l 5M -n 10 -m zlib -j 11"

# 2. 中断执行，输出提示
> 日志落盘已开启。请在设备上操作触发错误，完成后回复 **"OK"** 继续诊断。

# 3. 用户回复"OK"后停止落盘
hdc shell "hilog -w stop -j 11"

# 4. 重新执行步骤A（重跑后直接进入相关性检查，跳过步骤C——落盘已捕获复现的错误）
```

**状态机转换序列追踪** 当日志中包含stateChange/reset/stop/prepare等状态事件时：

1. 按时间轴排列所有状态转换事件
2. 计数关键操作调用次数
3. 标记异常状态转换
4. 记录到`clues.state_transitions`

---

### 阶段3：分诊查询

**目标：** 快速查询知识库和文档，评估是否可直接诊断或需深潜。

> 即使错误码看起来已知，也要查知识库——模块特定的 `error_codes.json` 含精确含义/常见原因/修复提示，是训练记忆里没有的；跳过这步给的根因多半是泛泛而谈。

#### 3.1 知识库查询（模块已识别时执行）

**步骤1 - 错误码精确匹配：** Read `references/knowledge/{module_name}/error_codes.json`，按错误码查找。

**步骤2 - API调用链匹配：** Read `references/knowledge/{module_name}/api_chain.json`，按API名称查找。

**步骤3 - 故障案例匹配（强制执行）：** 若`clues.kit_names`非空，对每个KitName查找案例：

```bash
# 列举fault-cases目录（用{skill_dir}absolute path！）
bash: ls "{skill_dir}/references/knowledge/fault-cases/"
powershell: Get-ChildItem "{skill_dir}/references/knowledge/fault-cases/" -Name

# 筛选文件名：{KitName}-Fault-Cases-*.md（忽略大小写）
# Read匹配文件的absolute path："{skill_dir}/references/knowledge/fault-cases/{filename}"
```

⚠️ **关键陷阱：** fault-cases目录在skill内，与项目cwd相对关系不固定。必须用`{skill_dir}`absolute path，禁止裸glob。

**步骤4 - 常见问题匹配：** Read `references/knowledge/{module_name}/common_issues.md`，搜索匹配模式。

**步骤5 - 额外知识文件搜索（条件执行）：** 当「模块已识别但步骤1-4不足」或「模块未识别」时，用clues关键词递归搜索整个`references/knowledge/`（同样用`{skill_dir}`absolute path）。

**步骤6 - 媒体文件分析（条件执行）：** 错误码含5400103/5400106/5400102且日志涉及文件路径时：

1. 确认文件路径（用户提供→glob搜索→询问）
2. 执行脚本：`{py_cmd} "{skill_dir}/references/scripts/media_file_analyzer.py" --file "{path}" --json`
3. 解析结果并交叉验证hilog

#### 3.2 文档仓查询

1. `builtin_web_rag`查询官方文档（终端Agent见`tool_mapping.md`降级方案W）
2. `curl`获取Gitee文档：`curl -sL "https://gitee.com/openharmony/docs/raw/master/{errorcode_path}"`
3. 均未命中→在对话中说明并继续

#### 3.3 置信度评估

**高置信度（跳过阶段4）：**

- 故障案例匹配成功（相同错误码+相似现象）
- 模块错误码精确匹配+知识库/文档信息充分
- 媒体文件分析确认格式不支持/损坏+错误码匹配

**低置信度（进入阶段4）：**

- 仅通用错误码，无模块特定信息
- 知识库/文档信息不足
- 模块未识别
- 媒体文件正常+错误码5400103/5400106

**⚠️ 无论置信度高低，阶段5和阶段6都必须执行**（阶段5 把根因落到具体代码、阶段6 是契约化交付，省任一个报告都不完整）。

---

### 阶段4：深潜分析（仅低置信度执行）

**目标：** 深入分析代码实现和文档，构建完整证据链。

**执行方式分流：**

- **终端Agent：** 主Agent用Task工具委派子Agent执行（4.1→4.5为子Agent内部步骤），返回结构化结论
- **CodeGenie：** 无子Agent能力→主上下文内顺序执行4.1→4.5

**步骤4.1 - API链路追踪（有知识库时）：** Read `api_chain.json`按调用栈C++函数名反向追踪。

**步骤4.2 - 代码仓搜索：**

1. Read `module_mapping.md`表6获取代码仓URL
2. `curl`获取Gitee源文件，搜索错误头文件
3. `builtin_glob`在SDK中搜索`.d.ts`文件

**步骤4.3 - 文档深度查询：** `builtin_web_rag`查询开发指南/FAQ + `curl`读取Gitee文档目录。

**步骤4.4 - 证据交叉验证：** 对比知识库/文档/代码仓结果，矛盾时以代码仓实现为准，按证据充分度排序根因候选。

**步骤4.5 - 根因层级追溯（阶段4 执行时必做）：** ⚠️ **不停留在框架机制层，必须追溯到应用侧具体操作。** （阶段4 被高置信度跳过时本步也跳过；应用侧根因要求由阶段5 步骤4 兜底，仍始终生效。）

追溯规则：

1. 框架防御性代码本身不是bug，不应作为最终根因
2. 最终根因必须是应用侧具体操作
3. 在证据链中区分"拦截机制"和"触发行为"
4. 结合阶段2状态转换时间线确认异常操作

示例追溯链：

```
现象：seekDone回调未送达
  <- 框架拦截：isloaded_==false
    <- 触发原因：ResetTask()被调用
      <- 应用侧操作：多次调用reset()
        <- 真正根因：开发者未正确管理播放器状态
```

---

### 阶段5：项目源码分析（始终执行）

**目标：** 分析项目源码，定位具体代码问题并给出修改建议。

**步骤1：扫描源码文件** Glob搜索：`**/*.ets`、`**/*.ts`、`**/*.c`、`**/*.cpp`、`**/*.h`

**步骤2：读取项目配置**

- Read `entry/src/main/module.json5`（权限声明）
- Read `build-profile.json5`（SDK版本）

**步骤3：定位问题相关源码** Grep搜索API名称/问题模式/C++函数名，Read相关代码段。

**步骤4：源码问题分析**

- API调用时序是否正确（对照api_chain.json）
- 权限声明是否完整（对照module.json5与API要求）
- 语法检查（`builtin_check_editor_errors`或降级方案E）
- 结合诊断结论定位错误用法
- **确保rank-1 根因表述为应用侧具体操作**

**步骤5：生成修改建议** 针对定位的问题给出可直接应用的代码修改方案。

**步骤6：汇总结果** 记录到报告"项目上下文"章节。

---

### 阶段6：结果输出（始终执行）

**目标：** 构建结构化诊断报告并写入文件。

**步骤1：获取时间戳**

```bash
bash: date +%Y%m%d_%H%M%S
powershell: Get-Date -Format 'yyyyMMdd_HHmmss'
```

**步骤2：写入报告** Write到`diagnosis/diagnosis_{timestamp}.md`，严格遵循`references/report_template.md`模板、诊断置信度标准与关键要求——以保证报告字段一致、下游可程序化解析。

**关键要求：**

- 阶段5与阶段6无论置信度都必须执行
- rank-1 根因必须表述为应用侧具体操作
- 明确区分"框架拦截机制"与"应用侧触发行为"

---

## 重要提示

1. **全流程强制执行：** 无论输入多简单、是否有设备/项目，阶段 0、1、2、3、5、6 都要尝试执行——缺前置条件时"尝试后记录缺口"，绝不直接跳过（除非用户明确要求跳过）
2. **阶段4 按置信度跳过：** 阶段4（深潜分析）是唯一按置信度决定是否执行的阶段——高置信度跳过、低置信度执行（见阶段3.3），不受输入完备度影响
3. **absolute path定位：** 访问skill目录内文件时必须用`{skill_dir}`absolute path
4. **阶段5/6必须执行：** 无论置信度高低，项目源码分析和结果输出都必须执行
5. **根因层级追溯：** 最终根因必须是应用侧具体操作，不得停留在框架机制层
6. **平台命令分支：** 所有平台相关命令按host_shell选择bash或powershell分支
