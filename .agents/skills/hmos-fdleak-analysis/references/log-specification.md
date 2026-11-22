# FD Leak 日志规格

## 文件名

- `[pid]_fd_leak.txt`
- `RESOURCE_OVERLIMIT_[TIMESTAMP]_[PID].log`

## 日志头

| 字段 | 含义 |
|---|---|
| `time` | 故障发生时间 |
| `pid` | 发生故障的进程 PID |
| `process` | 应用进程名或包名 |
| `leaked fd nums` | 判定泄漏时抓取的句柄存量快照 |

示例：

```text
time: 2024/06/27 11:55:28
pid: 1380
process: process1
leaked fd nums: 1831
```

## 句柄分布

### Leaked fd Top 10

按文件描述符名称或类型聚类。第一列是存量数量，第二列是句柄类型或实际路径。

```text
Leaked fd Top 10:
1337    ashmem
259     socket
119     dmabuf
48      eventfd
42      sync_file
17      eventpoll
3       /dev/null
```

Top 列表可能只展示前十项，合计值不一定等于 `leaked fd nums`。

### Dir Type Top 10

对普通文件句柄按目录聚类，用于识别数据库、缓存、设备节点等集中打开位置。

```text
Dir Type Top 10:
6175 /data/storage/el2/database/rdb
5    /dev/urandom
3    /dev/null
```

该区段主要解释普通文件句柄，不能代替 socket、ashmem 等专项资源分析。

## 特殊句柄明细

当 Top 句柄属于 `ashmem`、`socket`、`pipe`、`sync_file`、`dmabuf` 且数量超过 1000 时，日志会增加整机专项维测信息。

### ashmem

标记：`Process ashmem detail info:`

| 字段 | 含义 |
|---|---|
| `Process_name` | 持有共享内存的进程名 |
| `Process_ID` | 持有进程 PID |
| `Fd` | 进程持有的文件描述符 |
| `Cnode_idx` | ashmem 节点索引 |
| `Applicant_Pid` | 申请共享内存的进程 PID |
| `Ashmem_name` | 用户态设置的共享内存名称，可辅助判断资源用途 |
| `Size` | 单个 ashmem 块大小，单位 B |

### socket

标记：`Process socket info:`

| 字段 | 含义 |
|---|---|
| `ProcessName` | 持有 socket 的进程名 |
| `ProcessID` | 持有进程 PID |
| `Fd` | 文件描述符 |
| `inode` | 文件系统对象标识 |
| `PeerTid` | 对端 TID；无连接时通常为 0 |

### pipe

标记：`Process pipe info:`

| 字段 | 含义 |
|---|---|
| `ProcessName` / `ProcessID` | 持有进程及 PID |
| `Fd` | 文件描述符 |
| `PipeName` | 管道名称 |
| `inode` | 文件系统对象标识 |
| `MaxUsage` | 最大使用量 |
| `NumAccounted` | 累计计量值 |
| `RingSize` | Ring Buffer 大小 |

### sync_file

标记：`Process fence info:`

| 字段 | 含义 |
|---|---|
| `ProcessName` / `ProcessID` | 持有进程及 PID |
| `Fd` | 文件描述符 |
| `FenceName` | sync_file 名称 |
| `inode` | 文件系统对象标识 |
| `FenceNum` | Fence 数量 |
| `TimelineName` | Fence 时间线名称 |
| `DriverName` | 驱动名称 |
| `Status` | Fence 状态 |
| `Timestamp` | Fence 时间戳 |

### dmabuf

标记：`Process dma_heap info:`

| 字段 | 含义 |
|---|---|
| `Process name` / `Process ID` | 持有进程及 PID |
| `fd` | 文件描述符 |
| `size` | Buffer 大小，单位 B |
| `magic` | Buffer 唯一标识；相同值表示指向同一 Buffer |
| `buf->pid` | Buffer 申请者 PID |
| `buf->task_comm` | Buffer 申请进程名 |

专项明细是整机信息。必须通过进程名、PID、申请方 PID 等字段确认记录与故障进程之间的关系。

## FdTrack 申请栈

区段标记：`LOGGER_MEMCHECK_FD_STACK_INFO`

```text
pid: 12326
get stack time: 2024/06/17 19:16:48
==============================FdTrack Stack==============================
num 8272 bt [/system/lib64/libfdleak_tracker.so+0x1fb58] [/system/lib/ld-musl-aarch64.so.1+0x1d3154]
```

| 字段 | 含义 |
|---|---|
| `pid` | 被跟踪进程 PID |
| `get stack time` | 栈采集时间 |
| `num` | 10 分钟内该调用栈对应的 FD 申请次数 |
| `bt` | 原始调用栈，通常为 `so+offset` |

调用顺序为从右向左。需要使用与日志 BuildID 匹配的符号文件和 addr2line 将偏移反解为函数及源码行。

## 使用限制

1. FdTrack 统计的是 10 分钟内所有 pipe/open 等 FD 申请，已经 close 的 FD 不会从统计中移除。
2. 因此 `num` 表示申请热点，不等于当前泄漏数量，也不能单独证明某条栈泄漏。
3. log 版本通常直接包含栈；nolog 版本未开启开发者模式时可能不抓取栈。
4. 没有栈时仍可依据存量类型、目录和专项明细进行初步定界，但应降低可信度。
