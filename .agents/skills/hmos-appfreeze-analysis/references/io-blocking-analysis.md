# 主线程同步 I/O 与文件系统阻塞分析参考

> 适用：故障目标线程为应用主线程，调用栈或采样栈命中同步 I/O、路径解析、文件系统元数据或路径创建操作。
> 配套故障模式库条目：`fault-mode-library.md` → 三级根因「阻塞 IO 操作」与「IO 操作繁忙」。

---

## 一、核心判定原则

I/O 相关函数名只表示**可能阻塞**，不能单独证明 AppFreeze 根因。必须结合目标线程、完整调用链、重复抓栈或采样占比，以及 I/O 对象和调用模式定性：

1. 单次栈命中只输出「主线程同步 I/O 风险」，不得直接匹配「阻塞 IO 操作」。
2. 同一主线程的 3s、6s 栈稳定停留在同一 I/O 或文件系统调用链，且调用方链能够解释超时，才可判为「阻塞 IO 操作」。
3. 多份采样栈在同一 I/O 业务调用链的占比 **>30%**，且栈在不同执行阶段持续推进，才可判为「IO 操作繁忙」。
4. 必须定位同步调用的实际实现模块与业务调用方；不得把 `libc.so`、`ld-musl`、`libuv.so` 或文件系统框架直接作为责任模块。
5. 无法确定 I/O 对象、文件描述符模式或调用方时，降低可信度并保留「可能阻塞」表述，不得补造 `O_NONBLOCK`、超时、挂载类型或文件路径。

## 二、可能阻塞的函数与条件

下表用于检索调用栈。函数命中后仍需按第三节完成证据校验。

| 类别 | 常见符号或封装 | 可能阻塞的条件 |
|------|----------------|----------------|
| 文件/路径打开 | `open` / `openat` / `creat` / `fopen` / `freopen` | 路径逐级解析、符号链接或挂载点访问、FIFO/设备等待、权限/安全检查、远端或用户态文件系统响应；普通文件和块设备即使设置 `O_NONBLOCK`，设备访问仍可能短暂等待 |
| 文件读取 | `read` / `pread` / `readv` / `preadv` / `fread` / `fgets` | 缓存未命中后的存储访问；管道、终端、设备或 socket 无数据且未使用非阻塞模式；网络/用户态文件系统等待 |
| 文件写入 | `write` / `pwrite` / `writev` / `pwritev` / `fwrite` / `fflush` | pipe/socket 缓冲区满、设备或文件系统回写压力、同步挂载、`O_SYNC` / `O_DSYNC`、远端文件系统提交 |
| 同步落盘 | `fsync` / `fdatasync` / `syncfs` / `msync`（`MS_SYNC`） | 等待文件数据、元数据和设备缓存完成同步；属于主线程高风险同步操作 |
| 网络连接/接收 | `connect` / `accept` / `accept4` / `recv` / `recvfrom` / `recvmsg` | 阻塞 socket 等待连接建立、连接到达或数据到达；非阻塞模式通常以 `EINPROGRESS`、`EAGAIN` 或 `EWOULDBLOCK` 返回 |
| 网络发送 | `send` / `sendto` / `sendmsg` | socket 发送缓冲区不足且未启用非阻塞模式，或设置了同步等待语义 |
| 路径/目录创建 | `mkdir` / `mkdirat` / `mkdtemp` / `std::filesystem::create_directory` / `std::filesystem::create_directories` / `mkdirSync` | 路径解析、父目录独占锁、inode/块或配额分配、文件系统日志事务、NFS/FUSE 等远端或用户态响应；`mkdir`/`mkdirat` 没有通用非阻塞选项 |
| 文件或节点创建 | `open` / `openat`（`O_CREAT`、`O_TMPFILE`、`O_TRUNC`）/ `creat` / `mkstemp` / `tmpfile` / `mknod` / `mknodat` / `mkfifo` / `mkfifoat` / `bind(AF_UNIX)` | 父目录锁、路径解析、inode/块分配、设备或文件系统事务；文件系统路径形式的 Unix Domain Socket 还会创建 socket 节点 |
| 链接与路径替换 | `link` / `linkat` / `symlink` / `symlinkat` / `rename` / `renameat` / `renameat2` | 一个或多个父目录/文件系统锁、路径解析、跨层文件系统处理、远端或用户态文件系统响应 |
| 路径查询/遍历 | `stat` / `lstat` / `fstatat` / `access` / `realpath` / `readlink` / `opendir` / `readdir` | 虽不创建路径，但可能发生逐级解析、目录锁竞争、缓存未命中或远端/用户态文件系统等待 |
| 条件性关闭 | `close` / `fclose` / `shutdown` | 不能只凭函数名定性；socket 启用 `SO_LINGER`、远端文件系统提交、缓冲刷新或具体文件系统实现时才可能明显等待 |
| 事件等待 | `poll` / `ppoll` / `select` / `pselect` / `epoll_wait` / `uv__io_poll` | 这些接口本来就用于等待事件；主事件循环空闲等待通常是正常状态，只有业务错误地同步等待或事件循环无法推进时才是根因候选 |
| 实现相关接口 | `ioctl`、同步数据库接口、压缩/加密文件封装、自定义 VFS/FUSE/NFS 客户端 | 是否阻塞取决于具体实现，必须沿调用链确认等待对象和责任实现 |

### 路径创建操作的特别说明

- Linux VFS 创建目录、文件、节点或链接时需要对父目录加独占锁；并发修改同一目录可能使目标线程等待。
- `mkdir -p`、`create_directories` 等递归封装会对每一级路径执行查询和创建，风险是多次路径解析与元数据操作的叠加，不能只记录最外层函数名。
- 本地文件系统上的一次快速 `mkdir` 很常见，不应自动视为异常；只有稳定重复栈、长耗时或采样占比证据才能定性。
- NFS、FUSE、网络盘、加密层、overlay 等文件系统可能把一次路径操作扩展为远端、用户态或下层文件系统请求，阻塞风险更高。

## 三、证据校验流程

### 3.1 确认线程与调用方

1. 确认命中函数位于应用主线程；业务线程事件仍按事件 TID 分析，不得用主线程 I/O 代替业务线程根因。
2. 从系统调用或 libc 包装帧向栈底追踪，找到直接调用它的应用或系统组件函数。
3. 记录完整链路，例如：`页面回调 → 配置保存 → create_directories → mkdirat → syscall`，不能只摘录 `mkdirat`。

### 3.2 区分阻塞、繁忙与风险提示

| 证据 | 结论 |
|------|------|
| 仅一份栈命中 I/O/文件系统函数；缺少等待条件或调用方 | 只提示「主线程同步 I/O 风险」，线程状态保持「无法判定」或沿用其他证据 |
| 3s、6s 同一目标 TID 稳定停留在同一有效 I/O/文件系统调用链，且链路可解释超时 | 主线程阻塞 →「阻塞 IO 操作」 |
| 两次栈顶不同，但都位于同一个同步 I/O 调用及其内部阶段，业务调用方稳定 | 仍可判阻塞；不得仅因栈顶变化改判繁忙 |
| 多份采样栈显示同一 I/O 业务链持续执行，占比 >30%，且没有稳定等待点 | 主线程繁忙 →「IO 操作繁忙」 |
| 证据显示非阻塞调用立即以 `EAGAIN` / `EWOULDBLOCK` / `EINPROGRESS` 返回 | 不判为该次 I/O 阻塞；继续分析重试循环、回调过重或其他等待点 |

### 3.3 尽可能确认运行条件

日志或源码可达时，检查以下信息；缺失时明确标注未知：

- I/O 对象：普通文件、目录、FIFO、pipe、socket、终端、块/字符设备、数据库或自定义文件系统。
- 文件系统：本地文件系统、NFS/网络盘、FUSE/用户态文件系统、overlay/加密层。
- 调用模式：同步或异步，`O_NONBLOCK` / `SOCK_NONBLOCK` / `MSG_DONTWAIT`，连接/收发超时，`O_SYNC` / `O_DSYNC`，`SO_LINGER`。
- 调用规模：单次还是循环，数据量，`mkdir -p`/递归创建的路径层数，是否伴随 `stat/access` 预检查。
- 责任实现：应用直接调用、系统 NAPI/框架同步封装，或系统服务/文件系统内部等待。

## 四、误报防护

1. **事件循环正常等待不是冻屏根因**：`poll` / `epoll_wait` / `uv__io_poll` 位于 Looper/EventLoop 空闲路径时，不得匹配「阻塞 IO 操作」。必须证明待处理任务无法推进或业务代码主动同步等待。
2. **`close` 不是无条件阻塞接口**：只有调用链或运行条件能证明 `SO_LINGER`、同步提交、缓冲刷新等等待语义时才匹配；否则仅作为上下文。
3. **`O_NONBLOCK` 不是普通文件的异步保证**：它能改变 pipe/socket 等对象的等待行为，但普通文件、块设备和路径解析仍可能等待设备或文件系统处理。
4. **函数名不等于等待状态**：栈停留在 `open/read/write/mkdir` 可能只是抓栈瞬间经过该函数；需要重复栈、耗时或采样占比闭环。
5. **用户态栈看不到全部 I/O**：内存映射文件的缺页、文件系统内部回写或内核等待未必直接显示为上述函数，不能因函数表未命中就排除所有 I/O 影响。

## 五、修复建议规则

先按实际调用实现确定责任领域，再输出建议：

- 应用在 UI 主线程直接执行同步 I/O 或路径创建：移到 worker/taskpool 或使用异步 API；初始化所需目录可在非交互阶段预创建；批量或递归操作应拆分并避免在每次 UI 回调重复执行。
- 应用需要强一致落盘：把 `fsync/fdatasync` 等持久化等待移出主线程，并在业务上明确完成回调；不得用删除同步语义来掩盖数据一致性要求。
- 系统 NAPI、框架或服务在调用方无法规避的同步接口内阻塞：修改实际系统责任模块，提供异步契约、超时或后台执行；不得把系统缺陷转嫁给应用。
- 仅命中风险而未形成根因证据：报告风险和待补充条件，不输出假定性的代码修复。

根因确认为应用主线程同步 I/O 时，报告至少包含以下提示：

> 该同步接口可能等待路径解析、目录锁、存储设备、管道或网络/用户态文件系统响应，不建议在 UI 主线程直接调用。请使用异步 API 或移至 worker/taskpool，并异步回传结果。

## 六、语义依据

- Linux `mkdir(2)`：https://man7.org/linux/man-pages/man2/mkdir.2.html
- Linux 路径解析： https://man7.org/linux/man-pages/man7/path_resolution.7.html
- Linux VFS 目录锁： https://docs.kernel.org/filesystems/directory-locking.html
- Linux 文件系统锁与「all may block」： https://docs.kernel.org/filesystems/locking.html
- Linux `open(2)` / `read(2)` / `write(2)`：
  - https://man7.org/linux/man-pages/man2/open.2.html
  - https://man7.org/linux/man-pages/man2/read.2.html
  - https://man7.org/linux/man-pages/man2/write.2.html
- Linux `fsync(2)`： https://man7.org/linux/man-pages/man2/fsync.2.html
- Linux socket `connect(2)` / `accept(2)` / `recv(2)` / `send(2)`：
  - https://man7.org/linux/man-pages/man2/connect.2.html
  - https://man7.org/linux/man-pages/man2/accept.2.html
  - https://man7.org/linux/man-pages/man2/recv.2.html
  - https://man7.org/linux/man-pages/man2/sendmsg.2.html
- Linux FUSE： https://docs.kernel.org/filesystems/fuse/fuse.html
