# FD Leak 故障模式库

## 一级：句柄泄露

> 适用故障类型：FD Leak、文件描述符泄漏、句柄数持续增长或资源超限。
>
> 一级判定：存在应用进程内句柄总数超限，或应用通过 RenderService 持有的句柄数超限证据。

### 二级：应用进程内句柄泄漏

> 判定特征：后台应用进程句柄总数超过 20000。
>
> 分析入口：结合 `leaked fd nums`、`Leaked fd Top 10`、`Dir Type Top 10`、专项维测明细和 FdTrack 申请栈进行定界。

| 三级根因 | 判定规则 |
|---|---|
| 文件句柄泄漏（open/fopen，基础库函数） | 文件操作打开的句柄未释放。通用分析逻辑：1. 找到相关文件打开操作；2. 找到文件路径的上下文使用位置；3. 检查句柄使用完成后是否及时关闭。分析时查看 Top 句柄或 Top 路径；如果占用最高的是 `/data/storage/el2/database/rdb` 等目录，或 `/data/storage/el2/database/rdb/transferlist.db35744` 等具体文件，则判定为文件句柄泄漏。结合 profiler/FdTrack 申请栈定位具体代码段，再结合代码上下文分析根因。 |
| 共享内存 Ashmem 的关联句柄泄漏 | Ashmem 相关操作的句柄未释放。分析时查看 Top 句柄或 Top 路径；如果占用最高的类型为 `ashmem`，则判定为共享内存 Ashmem 关联句柄泄漏。继续检查 ashmem 维测部分，按 `buf_type` 对 `size_bytes` 聚合并降序排列，找到占用最大的 Buffer，再根据 `ashmemname` 定位；当前 FD 日志字段为 `Ashmem_name`、`Size` 时，按对应字段执行相同聚合。可结合 Ashmem 内存泄漏知识进一步定界。 |
| Socket 句柄泄漏 | Socket 相关操作的句柄未释放。通用分析逻辑：1. 根据 Socket 申请栈找到打开操作；2. 找到相关网络操作的上下文使用位置；3. 确认连接正常结束、异常、超时和重试路径的关闭规则；4. 检查使用完成后是否及时关闭。Top 句柄中 `socket` 占用最高时，判定为 Socket 句柄泄漏，再结合栈和代码确认具体泄漏位置。 |
| 图形数据流 dmabuf 泄漏 | dmabuf 相关操作的句柄未释放。Top 句柄中 `dmabuf` 占用最高时，判定为图形数据流 dmabuf 泄漏。继续检查 ION/dma_heap 维测部分，按 `buf_type` 对 `size_bytes` 聚合并降序排列，根据 `buffername` 和 `leaktype` 定位；当前 FD 日志字段为 `size`、`magic`、`buf->pid`、`buf->task_comm` 时，按对应字段识别占用最大的 Buffer 和申请方。可结合 ION/dmabuf 内存泄漏知识进一步定界。 |
| 管道通信 Pipe 泄漏 | Pipe 相关操作的句柄未释放。Top 句柄或 Top 路径中 `pipe` 占用最高时，判定为管道通信 Pipe 泄漏；结合 Pipe 申请栈、`PipeName`、inode 和代码中的创建/关闭配对定位具体泄漏位置。 |
| 设备节点事件通知 eventpoll 泄漏 | epoll 相关操作的句柄未释放。Top 句柄或 Top 路径中 `eventpoll` 占用最高时，判定为设备节点事件通知 eventpoll 泄漏；结合申请栈检查 epoll 实例创建和关闭是否配对。 |
| 事件描述符 eventfd 句柄泄漏 | eventfd 相关操作的句柄未释放。Top 句柄或 Top 路径中 `eventfd` 占用最高时，判定为事件描述符 eventfd 句柄泄漏；结合申请栈检查事件描述符创建和关闭是否配对。 |

上述三级根因的责任定界和修复方向继承“应用进程内句柄泄漏”二级根因。

### 二级：应用通过 RS 持有的句柄过多

> 判定特征：应用进程在 RenderService 侧持有句柄超过 25000（后台），导致系统查杀；同时存在 RS 向 Hiview 打点的 `RENDER_MEMORY_OVER_WARNING` 事件。
>
> 缺少 `RENDER_MEMORY_OVER_WARNING` 或 RS 侧句柄计数证据时，不得命中该二级根因。

| 三级根因 | 判定规则 |
|---|---|
| Ashmem 节点句柄泄漏 | 通用分析逻辑：1. 根据 Ashmem 节点信息遍历应用相关句柄打开信息；2. 找到数量较大的节点；3. 参照应用进程内 Ashmem 句柄泄漏方法继续分析。检查 ashmem 维测部分，按 `buf_type` 对 `size_bytes` 聚合并降序排列，找到占用最大的 Buffer，再根据 `ashmemname` 定位；当前日志使用 `Ashmem_name`、`Size` 时按对应字段处理。 |
| ION 节点句柄泄漏 | 通用分析逻辑：1. 根据 ION 节点信息遍历应用相关句柄打开信息；2. 找到数量较大的节点；3. 参照应用进程内 dmabuf 句柄泄漏方法继续分析。检查 ION/dma_heap 维测部分，按 `buf_type` 对 `size_bytes` 聚合并降序排列，再根据 `buffername` 和 `leaktype` 定位；当前日志使用 `size`、`magic`、`buf->pid`、`buf->task_comm` 时按对应字段处理。 |

上述三级根因的责任定界和修复方向继承“应用通过 RS 持有的句柄过多”二级根因。

## 匹配顺序

1. 先确认应用处于后台，并提取应用进程内句柄总数、RS 侧句柄总数和 `RENDER_MEMORY_OVER_WARNING` 事件。
2. 应用进程内句柄总数超过 20000 时，匹配“应用进程内句柄泄漏”。
3. RS 侧句柄总数超过 25000 且存在 `RENDER_MEMORY_OVER_WARNING` 时，匹配“应用通过 RS 持有的句柄过多”。
4. 两类证据同时存在时分别分析，不用其中一类替代另一类。
5. 进入对应二级根因后，再按 Top 句柄、Top 路径和专项维测信息匹配三级根因。
6. FdTrack 栈包含已经关闭的 FD，只用于定位申请热点和代码位置，不单独作为阈值或泄漏判定依据。
