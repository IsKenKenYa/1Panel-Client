# HiProfiler Config 参考

> Windows 路径转换 + heredoc 禁用规则 → `references/collection-workflow.md` "Windows 环境注意事项"
>
> hiprofiler_cmd 命令参数（-c/-o/-t/-s/-k）→ `references/collection-workflow.md` 引用

## 推荐采集配置

### 1. 启动阶段采集 (startup_mode: true + 多restrace_tag)

核心思路：先后台启动hiprofiler → sleep 3 → 启动应用 → wait等采集完成

```bash
hdc shell "hiprofiler_cmd -c - -o /data/local/tmp/startup.htrace -t 180 -s -k <<CONFIG &
request_id: 1
session_config {
  buffers {
    pages: 131072
  }
}
plugin_configs {
  plugin_name: \"nativehook\"
    sample_interval: 4096
  is_protobuf_serialize:true
  config_data {
    save_file: false
    filter_size: 1024
    smb_pages: 16384
    max_stack_depth: 30
    process_name: \"com.xxx.yyy\"
    string_compressed: true
    fp_unwind: true
    blocked: true
    callframe_compress: true
    record_accurately: true
    offline_symbolization: true
    statistics_interval: 0
    startup_mode: true
    js_stack_report: 1
    max_js_stack_depth: 30
    malloc_disable: false
    memtrace_enable: true
    async_stack_enable: true
    async_type: ALL_ASYNC_TYPE
    restrace_tag: \"RES_DMABUF_MASK\"
    restrace_tag: \"RES_FD_ALL\"
    restrace_tag: \"RES_ARKTS_HEAP_MASK\"
    restrace_tag: \"RES_JS_HEAP_MASK\"
    restrace_tag: \"RES_GPU_GLES_IMAGE\"
    restrace_tag: \"RES_GPU_VK\"
    restrace_tag: \"RES_GPU_GLES_BUFFER\"
    restrace_tag: \"RES_GPU_CL_BUFFER\"
    restrace_tag: \"RES_GPU_CL_IMAGE\"
    unique_stack_table_size:256
    use_file_cache_mode:true
  }
}
CONFIG
sleep 3
aa start -a <ability> -b <bundle>
wait"
```

### 2. 运行阶段采集 (startup_mode: false)

将上方配置中 `startup_mode: true` 改为 `startup_mode: false`，去掉 `sleep 3` 和 `aa start` 行。

```bash
hdc shell "hiprofiler_cmd -c - -o /data/local/tmp/runtime.htrace -t 30 -s -k <<CONFIG &
request_id: 2
session_config {
  buffers {
    pages: 131072
  }
}
plugin_configs {
  plugin_name: \"nativehook\"
    sample_interval: 4096
  is_protobuf_serialize:true
  config_data {
    save_file: false
    filter_size: 1024
    smb_pages: 16384
    max_stack_depth: 30
    process_name: \"com.xxx.yyy\"
    string_compressed: true
    fp_unwind: true
    blocked: true
    callframe_compress: true
    record_accurately: true
    offline_symbolization: true
    statistics_interval: 0
    startup_mode: false
    js_stack_report: 1
    max_js_stack_depth: 30
    malloc_disable: false
    memtrace_enable: true
    async_stack_enable: true
    async_type: ALL_ASYNC_TYPE
    restrace_tag: \"RES_DMABUF_MASK\"
    restrace_tag: \"RES_FD_ALL\"
    restrace_tag: \"RES_ARKTS_HEAP_MASK\"
    restrace_tag: \"RES_JS_HEAP_MASK\"
    restrace_tag: \"RES_GPU_GLES_IMAGE\"
    restrace_tag: \"RES_GPU_VK\"
    restrace_tag: \"RES_GPU_GLES_BUFFER\"
    restrace_tag: \"RES_GPU_CL_BUFFER\"
    restrace_tag: \"RES_GPU_CL_IMAGE\"
    unique_stack_table_size:256
    use_file_cache_mode:true
  }
}
CONFIG
wait"
```

## nativehook 关键参数

| 参数 | 值 | 说明 |
|------|---|------|
| `startup_mode` | `true` | 应用尚未启动，从启动瞬间开始采集 |
| `startup_mode` | `false` | 应用已运行，直接挂载hook |
| `statistics_interval` | `0` | 详细模式，记录每条事件 (推荐，数据精准) |
| `statistics_interval` | `>0` (如 `5`) | 统计模式，每N秒聚合 (数据量小，长时间采集) |
| `malloc_disable` | `false` | 采集native heap + restrace_tag类型 (推荐) |
| `malloc_disable` | `true` | 只采集restrace_tag指定类型 |
| `memtrace_enable` | `true` | 启用内存追踪 (配合restrace_tag) |
| `blocked` | `true` | 阻塞模式 (配合后台&使用) |
| `is_protobuf_serialize` | `true` | protobuf序列化 (推荐) |
| `use_file_cache_mode` | `true` | 文件缓存模式 (推荐) |
| `async_stack_enable` | `true` | 异步调用栈 (推荐) |
| `async_type` | `ALL_ASYNC_TYPE` | 所有异步类型 |
| `unique_stack_table_size` | `256` | 唯一栈表大小 |
| `filter_size` | `1024` | 过滤大小阈值 |

**警告**: 应用已运行时必须设 `startup_mode: false`；应用未启动时必须设 `startup_mode: true`。

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

推荐在**一个配置**中使用多个 restrace_tag，同时采集多种资源类型。

## 执行流程

**复现时机（关键）**：hiprofiler_cmd 一旦启动即进入 trace 采集状态，用户必须在精确时刻开始操作场景。AI 必须在执行 collect.py 前，**使用 AskUserQuestion 工具**向用户明确告知复现时机并取得确认（详见 `collection-workflow.md` 阶段二）：
- 冷启动（`startup_mode: true`）：profiler 启动 → sleep 3 → `aa start` 拉起应用，**应用拉起后请立即开始操作/复现问题**，整个采集期间请持续操作
- 运行态（`startup_mode: false`）：profiler 启动后**立即**开始操作/复现问题，与 hiprofiler_cmd 执行间隔越短越好，整个采集期间请持续操作

### 方式1: stdin管道 (仅 Linux/macOS, 无需临时文件; Windows 禁用, 见顶部警告)

```bash
HDC="${HDC_PATH:-hdc}"

# 直接通过hdc shell执行hiprofiler_cmd -c -, 配置通过stdin传入
$HDC shell "hiprofiler_cmd -c - -o /data/local/tmp/output.htrace -t 30 -s -k <<CONFIG &
... config ...
CONFIG
wait"

# 拉取到本地
$HDC file recv /data/local/tmp/output.htrace ./output/output.htrace
```

### 方式2: 配置文件推送

```bash
# 1. 写入配置到本地
cat > config.txt <<'EOF'
... protobuf config ...
EOF

# 2. 推送到设备
$HDC file send config.txt /data/local/tmp/config.txt

# 3. 在设备上执行采集
$HDC shell "hiprofiler_cmd -c /data/local/tmp/config.txt -o /data/local/tmp/output.htrace -t 30 -s -k"

# 4. 拉取htrace到本地
$HDC file recv /data/local/tmp/output.htrace ./output/output.htrace
```
