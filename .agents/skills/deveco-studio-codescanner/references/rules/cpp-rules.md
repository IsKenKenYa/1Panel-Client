# C++ 扫描规则说明（C++ Rules）

> 规则清单提取自 cpp-agent `base_rules.json`（部署版本 **26.0.1.272**，共 27 条）。
> 全部规则默认开启（`default: true`），严重级别均为 `error`。
> 检查器：`MemoryAndResourceLeakChecker`（API 配对泄漏）、`ResourceScopeChecker`（NapiScope 作用域）。
> 各规则详细说明见引擎自带文档 `cpp-agent/document/<RuleName>.md`。

## 规则运行前提

1. `--compileCommandsDir <dir>` 指向含 `compile_commands.json` 的目录（cpp-agent 的 `--scope` 输入）。
2. `compile_commands.json` 必须存在、可读、内容为合法 JSON；任一不满足则**跳过 C++ 检查**并打印 `[error]`（不中断整体扫描）。
3. 未传 `--compileCommandsDir` 时同样跳过 C++ 检查（`[warn]`）。
4. `--no-cpp` 显式关闭 C++ 规则。
5. **不传 `-c` 即检测全量规则**（使用 cpp-agent 自带 `base_rules.json`，27 条全开）；传 `-c` 时为**白名单语义**（仅 `skip: false` 规则被检测，未列出自动补 `skip: true`）。格式见 `references/cli-spec.md` §3.5。

## 已知行为要点

- compile_commands.json 是 cpp-agent 的**只读输入**，CLI 从不写它。
- 错误优先级：不可读（EPERM/EACCES）> 非法 JSON——先报"not readable"，后报"not valid JSON"。
- 跨平台：Linux 上 toolchain file 不会自动把 SDK include 路径注入 compile_commands.json 的 `-I` 标志，需在生成阶段保证。
- 模式含义：**"API Not Paired"** = 调用了分配/获取类 API 而未调用对应的释放/配对 API。

## 规则清单（ResourceLeak 组，27 条）

> 表格列：规则 ID | API 配对（分配/创建 → 释放/销毁）| 检查器

### N-API 资源

| 规则 ID | API 配对 | 检查器 |
|---------|----------|--------|
| NapiWrap API Not Paired | `napi_wrap` → `napi_remove_wrap` | MemoryAndResourceLeakChecker |
| NapiPromise API Not Paired | `napi_create_promise` → `napi_resolve_deferred` / `napi_reject_deferred` | MemoryAndResourceLeakChecker |
| NapiReference API Not Paired | `napi_create_reference` → `napi_delete_reference` | MemoryAndResourceLeakChecker |
| NapiScope API Not Enabled Or Paired | 见下注：`napi_get_undefined` 等创建类 API 需在 `napi_open_handle_scope` 作用域内配对关闭 | ResourceScopeChecker |

### Drawing / NativeWindow

| 规则 ID | API 配对 | 检查器 |
|---------|----------|--------|
| DrawingFontCollection API Not Paired | `OH_Drawing_CreateSharedFontCollection` / `OH_Drawing_CreateFontCollection` → `OH_Drawing_DestroyFontCollection` | MemoryAndResourceLeakChecker |
| DrawingTypographyStyle API Not Paired | `OH_Drawing_CreateTypographyStyle` → `OH_Drawing_DestroyTypographyStyle` | MemoryAndResourceLeakChecker |
| NativeWindowBuffer API Not Paired | `OH_NativeWindow_CreateNativeWindowBufferFromNativeBuffer` / `...FromSurfaceBuffer` → `OH_NativeWindow_DestroyNativeWindowBuffer` | MemoryAndResourceLeakChecker |
| NativeObjectReference API Not Paired | `OH_NativeWindow_NativeObjectReference` / `OH_NativeWindow_GetLastFlushedBufferV2` → `OH_NativeWindow_NativeObjectUnreference` | MemoryAndResourceLeakChecker |
| NativeWindow API Not Paired | `OH_NativeWindow_ReadFromParcel` / `OH_NativeWindow_CreateNativeWindowFromSurfaceId` → `OH_NativeWindow_DestroyNativeWindow` | MemoryAndResourceLeakChecker |
| NativeWindowRequestBuffer API Not Paired | `OH_NativeWindow_NativeWindowRequestBuffer` → `OH_NativeWindow_NativeWindowFlushBuffer` | MemoryAndResourceLeakChecker |

### JSVM

| 规则 ID | API 配对 | 检查器 |
|---------|----------|--------|
| JSVM_Reference_Conut API Not Paired | `OH_JSVM_ReferenceRef` → `OH_JSVM_ReferenceUnref` | MemoryAndResourceLeakChecker |
| JSVM_EnvScope API Not Paired | `OH_JSVM_OpenEnvScope` → `OH_JSVM_CloseEnvScope` | MemoryAndResourceLeakChecker |
| JSVM_Env API Not Paired | `OH_JSVM_CreateEnv` → `OH_JSVM_DestroyEnv` | MemoryAndResourceLeakChecker |
| JSVM_Reference API Not Paired | `OH_JSVM_CreateReference` → `OH_JSVM_DeleteReference` | MemoryAndResourceLeakChecker |

### 媒体 / 渲染 / 通用内存

| 规则 ID | API 配对 | 检查器 |
|---------|----------|--------|
| AVBuffer API Not Paired | `OH_AVBuffer_Create` → `OH_AVBuffer_Destroy` | MemoryAndResourceLeakChecker |
| ArkWebResponse API Not Paired | `OH_ArkWeb_CreateResponse` → `OH_ArkWeb_DestroyResponse` | MemoryAndResourceLeakChecker |
| PixelmapNative API Not Paired | `OH_PixelmapNative_CreatePixelmap` → `OH_PixelmapNative_Release` | MemoryAndResourceLeakChecker |
| DDK_Ashmem API Not Paired | `OH_DDK_CreateAshmem` → `OH_DDK_DestroyAshmem` | MemoryAndResourceLeakChecker |
| MemoryMap API Not Paired | `mmap` → `munmap` | MemoryAndResourceLeakChecker |
| GL_Buffer API Not Paired | `glGenBuffers` → `glDeleteBuffers` | MemoryAndResourceLeakChecker |
| VulkanMemory API Not Paired | `vkAllocateMemory` → `vkFreeMemory` | MemoryAndResourceLeakChecker |
| EGLImage API Not Paired | `eglCreateImageKHR` → `eglDestroyImageKHR` | MemoryAndResourceLeakChecker |
| OpenCL_MemObject API Not Paired | `clCreateBuffer` / `clCreateImage` → `clReleaseMemObject` | MemoryAndResourceLeakChecker |
| FileDescriptor API Not Paired | `open` → `close` | MemoryAndResourceLeakChecker |
| Malloc API Not Paired | `malloc` / `calloc` / `realloc` / `realpath` → `free` | MemoryAndResourceLeakChecker |
| New API Not Paired | `operator new`（含 nothrow 变体）→ `operator delete`（含 placement 变体） | MemoryAndResourceLeakChecker |
| NewArray API Not Paired | `operator new[]`（含 nothrow 变体）→ `operator delete[]`（含 placement 变体） | MemoryAndResourceLeakChecker |

### 注：NapiScope API Not Enabled Or Paired

与其它"配对"规则不同，它要求：创建 N-API 值类对象（`napi_get_undefined` / `napi_get_null` / `napi_get_global` / `napi_get_boolean` / `napi_create_object` / `napi_create_array` / `napi_create_string_*` / `napi_create_function` / `napi_create_error` / `napi_coerce_*` / `napi_get_*` / `napi_make_callback` 等）的调用必须发生在已开启的 `napi_open_handle_scope` 作用域内且正确关闭（`napi_close_handle_scope`）。未开启作用域或作用域不配对都会触发。

## 答疑要点

- 命中后先定位是"分配未释放"还是"配对顺序错误"，再按引擎文档的修复建议处理。
- 误报排查：先确认 compile_commands.json 覆盖了该文件的编译单元（未覆盖的文件不会参与分析）。
