---
name: hmos-fdleak-analysis
description: DFX Skills，分析 FD Leak、句柄泄漏和文件描述符泄漏日志，提取泄漏快照、句柄类型与目录分布、专项维测明细及 FdTrack 申请栈热点，并依据证据链定位根因。当用户提供 `[pid]_fd_leak.txt`、`RESOURCE_OVERLIMIT_[TIMESTAMP]_[PID].log`，或输入包含 `leaked fd nums`、`Leaked fd Top 10`、`LOGGER_MEMCHECK_FD_STACK_INFO`、`FdTrack Stack` 时使用。
metadata:
  author: Huawei Reliability Technology Lab
  version: 1.4.0
---

# FD Leak 分析 Skill

## 分析目标

从 FD Leak 日志中识别泄漏规模、主要句柄类型、集中目录、专项资源明细和句柄申请热点，结合故障模式库输出可核验的三级根因、证据链和修复建议。

## 强制约束

1. 日志原文是事实来源，不补造缺失字段、调用栈、模块或函数。
2. `leaked fd nums` 是判定时刻的存量快照；`FdTrack Stack` 是 10 分钟内的全量申请统计，两者口径不同。
3. FdTrack 不剔除已关闭的 FD。申请次数高只能作为热点证据，不能单独证明该调用栈发生泄漏。
4. 调用栈原始顺序为从右向左调用。未完成符号表反解时，只能定位到 `so+offset`，不得虚构函数名。
5. `ashmem`、`socket`、`pipe`、`sync_file`、`dmabuf` 的数量超过 1000 时才预期出现对应专项明细；明细缺失时如实说明。
6. 无栈信息不等于无泄漏。nolog 版本未开启开发者模式时可能不采集 FdTrack 栈。
7. 三级根因使用 Markdown 通用表格，不输出内部故障编码或出现频率。

## 前置环境检查

1. 确认 Python 3 可执行：

   ```bash
   python --version
   ```

2. 确认解析脚本存在：

   ```text
   <skill-root>/scripts/fd_leak_parser.py
   ```

3. 脚本仅使用 Python 标准库，无需安装第三方依赖。
4. 确认输入为日志文件或包含日志的目录，且当前用户具有读取权限。

## 输入识别

支持以下标准日志名：

- `[pid]_fd_leak.txt`
- `RESOURCE_OVERLIMIT_[TIMESTAMP]_[PID].log`

目录输入默认分析修改时间最新的标准日志；需要分析目录内全部日志时增加 `--all`。如果用户直接粘贴日志文本，可跳过脚本并按相同字段手工提取。

## 解析命令

单个文件或目录中的最新日志：

```bash
python "<skill-root>/scripts/fd_leak_parser.py" -p "<FD Leak日志文件或目录>"
```

分析目录内全部标准日志：

```bash
python "<skill-root>/scripts/fd_leak_parser.py" -p "<日志目录>" --all
```

输出结构化 JSON：

```bash
python "<skill-root>/scripts/fd_leak_parser.py" -p "<日志文件或目录>" --format json
```

脚本报错时先根据错误信息修正路径、文件名或编码问题，不要绕过失败后继续生成结论。

## 分析流程

### 第一步：提取故障快照

运行解析脚本，确认以下字段：

- 故障时间、PID、进程名。
- `leaked fd nums` 句柄存量。
- `Leaked fd Top 10` 是否存在。
- `Dir Type Top 10`、专项明细和 FdTrack 栈是否存在。

缺少 `leaked fd nums` 时不得声称泄漏规模；日志不像 FD Leak 规格时，停止并要求正确日志。

### 第二步：分析句柄类型分布

以 `Leaked fd Top 10` 为主证据，计算各项占 `leaked fd nums` 的比例。优先分析数量最多且占比显著的句柄类型，但不要把 Top 列表合计强行等同于总句柄数。

常见类型包括 `ashmem`、`socket`、`pipe`、`sync_file`、`dmabuf`、`eventfd`、`eventpoll` 和普通文件路径。

### 第三步：分析目录分布

读取 `Dir Type Top 10`。当类型 Top 只能显示文件路径或无法区分业务用途时，利用目录聚类定位数据库、缓存、配置、设备节点等集中打开位置。

目录 Top 是文件类句柄的补充证据，不能用于解释 socket、ashmem 等非普通文件句柄。

### 第四步：按需分析专项明细

当主要句柄属于以下类型且数量超过 1000 时，读取对应明细：

| 句柄类型 | 重点字段 | 分析作用 |
|---|---|---|
| ashmem | `Applicant_Pid`、`Ashmem_name`、`Size` | 定位共享内存申请方和资源用途 |
| socket | `inode`、`PeerTid` | 判断连接对象及重复连接特征 |
| pipe | `PipeName`、`inode`、`MaxUsage`、`RingSize` | 判断管道端点和缓冲区使用情况 |
| sync_file | `FenceName`、`TimelineName`、`DriverName`、`Status` | 定位图形 Fence 生命周期 |
| dmabuf | `size`、`magic`、`buf->pid`、`buf->task_comm` | 识别共享 buffer、申请进程和重复持有 |

相同 `magic` 的 dmabuf 指向同一 buffer。专项明细是整机维测信息，归因前必须用 PID、进程名或申请方字段确认与故障进程的关系。

### 第五步：分析 FdTrack 申请热点

1. 按 `num` 从高到低查看调用栈。
2. 按最右帧到最左帧还原调用方向。
3. 优先跳过 tracker、libc 等公共封装帧，寻找首个业务或领域模块。
4. 有匹配符号文件时使用 addr2line 反解 `so+offset`；未反解时将建议中的第一项设为“使用匹配 BuildID 的符号文件反解后重新分析”。
5. 将栈热点与句柄类型、目录或专项明细交叉验证。只有证据收敛时才能给出高可信度根因。

### 第六步：匹配故障模式库

读取 [fault-mode-library.md](references/fault-mode-library.md)，先判定二级根因：

- 后台应用进程内句柄总数超过 20000 时，匹配“应用进程内句柄泄漏”。
- RS 侧持有句柄超过 25000，且存在 `RENDER_MEMORY_OVER_WARNING` 时，匹配“应用通过 RS 持有的句柄过多”。
- 缺少后台状态、对应计数或 RS 事件时，不得直接命中相关二级根因，应明确缺失证据。

二级根因确定后，再结合 Top 句柄、Top 路径、专项字段和符号化申请栈选择三级根因。两类二级根因证据同时存在时分别分析。

可信度标准：

- `HIGH`：存量类型/目录、专项明细和符号化申请栈指向同一资源生命周期。
- `MEDIUM`：存量分布明确，且目录或未符号化申请栈提供一致旁证。
- `LOW`：只有存量快照，或申请热点与存量类型无法建立对应关系。

日志字段定义和采集限制见 [log-specification.md](references/log-specification.md)。

## 输出模板

严格按以下结构输出，不增加无法从日志支撑的字段：

```markdown
# FD Leak 问题综合分析报告

## 故障基本信息

| 字段 | 内容 |
|---|---|
| 故障时间 | <time> |
| 故障进程 | <process / pid> |
| 故障类型 | FD Leak（文件描述符泄漏） |
| 泄漏快照数量 | <leaked fd nums> |

## 句柄分布

| 排名 | 句柄类型或路径 | 数量 | 占泄漏快照比例 |
|---|---|---:|---:|
| 1 | <类型> | <数量> | <比例> |

## 目录与专项明细

<目录 Top、专项记录数量及能够支撑定界的关键字段；不存在时明确写未获取>

## 申请栈热点

| 排名 | 10 分钟内申请次数 | 调用链（从右向左） | 证据作用 |
|---|---:|---|---|
| 1 | <num> | <调用栈或 so+offset> | <热点旁证，不单独作为泄漏实锤> |

## 三级根因定位

| 层级 | 根因 | 匹配依据 |
|---|---|---|
| 一级根因 | 句柄泄露 | <进程内或 RS 侧句柄超限原始日志> |
| 二级根因 | <应用进程内句柄泄漏/应用通过 RS 持有的句柄过多> | <后台状态、句柄计数和 RS 事件证据> |
| 三级根因 | <故障模式库中的具体句柄泄漏类型> | <Top 句柄、目录、专项明细和符号化栈证据> |

## 根因结论

- 诊断结果：<一句话结论>
- 根因模块：<应用/三方库/系统/证据不足>
- 可信度：<HIGH/MEDIUM/LOW>

## 证据链

1. <泄漏存量与类型分布证据>
2. <目录或专项明细证据>
3. <申请栈热点及其局限>

## 修复建议

1. <针对生命周期配对的可执行建议>
2. <符号反解、复现或补充日志建议>

## 分析限制

- FdTrack 统计包含已关闭 FD，不能与泄漏快照数量直接对应。
- <其余缺失信息和结论边界>
```
