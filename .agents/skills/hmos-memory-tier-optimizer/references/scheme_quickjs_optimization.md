# 方案八：QuickJS 引擎内存优化

**适用场景**：鸿蒙应用通过 NAPI 嵌入 QuickJS 引擎，Native 内存占用过高、存在跨引擎泄漏、引擎内存未按设备分档限制。

**方案原理**：ArkTS 的 GC 与 QuickJS 的 GC 完全独立，NAPI 桥接层的数据在两个堆之间传递时容易产生泄漏。通过引擎初始化分档、按需加载内置对象、预编译字节码、引用计数配对、生命周期对齐、退后台主动 GC 等手段，系统性地降低 QuickJS 引擎的内存占用。

## 架构概览

```
┌──────────────────────────────────────────────┐
│           ArkTS 应用层                        │
│  UIAbility / ArkUI 组件 / 业务逻辑            │
│  管理状态变量(@State)、资源、UI节点            │
├──────────────────────────────────────────────┤
│           NAPI 桥接层                         │
│  napi_value ↔ JSValue 类型转换                │
│  napi_ref 引用管理 / ArrayBuffer 传递         │
├──────────────────────────────────────────────┤
│           QuickJS 引擎层 (C)                  │
│  JSRuntime / JSContext / 字节码 / GC 堆       │
│  引用计数 + 循环检测 / Atom 表 / Shape 缓存    │
└──────────────────────────────────────────────┘
```

## 设备分档策略

QuickJS 引擎的内存上限和 GC 阈值需根据设备分档动态配置：

| 参数 | low（低端机 ≤8GB） | medium（中端机） | high（高端机 >8GB） |
|------|-------------------|-----------------|-------------------|
| MemoryLimit | 64 MB | 128 MB | 256 MB |
| GCThreshold | 64 KB | 128 KB | 256 KB |
| 栈大小 | 512 KB | 768 KB | 1 MB |
| 内置对象加载 | 仅 BaseObjects | + JSON + RegExp | 全量按需 |
| 退后台 GC 阈值 | 32 KB | 64 KB | 128 KB |

## 代码修改模板

### 1. 引擎初始化分档配置（C 侧）

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

#include <napi/native_api.h>
#include "quickjs.h"

/* ======================== 全局状态 ======================== */

static JSRuntime *g_rt = NULL;
static JSContext  *g_ctx = NULL;

/* 缓存的 Atom（高频属性名，避免反复创建销毁） */
static struct {
    JSAtom name;
    JSAtom type;
    JSAtom value;
    JSAtom length;
    JSAtom handleEvent;
} g_atoms;

/*
 * 引擎初始化：从 ArkTS 侧接收设备分档参数
 * memoryLimit: 内存上限（字节）
 * gcThreshold: GC 触发阈值（字节）
 * stackSize:   栈大小（字节）
 * features:    需要加载的内置对象列表，逗号分隔
 */
static napi_value qjs_init(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, NULL, NULL);

    /* 读取配置参数 */
    napi_value val;
    int32_t memoryLimit = 64 * 1024 * 1024;   // 默认 64MB
    int32_t gcThreshold = 64 * 1024;           // 默认 64KB
    int32_t stackSize = 512 * 1024;            // 默认 512KB

    napi_get_named_property(env, args[0], "memoryLimit", &val);
    napi_get_value_int32(env, val, &memoryLimit);
    napi_get_named_property(env, args[0], "gcThreshold", &val);
    napi_get_value_int32(env, val, &gcThreshold);
    napi_get_named_property(env, args[0], "stackSize", &val);
    napi_get_value_int32(env, val, &stackSize);

    char features[256] = {0};
    napi_value feat_val;
    napi_get_named_property(env, args[0], "features", &feat_val);
    napi_get_value_string_utf8(env, feat_val, features, sizeof(features), NULL);

    /* 如果已有引擎实例，先销毁 */
    if (g_rt) {
        if (g_ctx) { JS_FreeContext(g_ctx); g_ctx = NULL; }
        JS_FreeRuntime(g_rt);
        g_rt = NULL;
    }

    /* 创建 Runtime 并设置内存限制 */
    g_rt = JS_NewRuntime();
    JS_SetMemoryLimit(g_rt, (size_t)memoryLimit);
    JS_SetGCThreshold(g_rt, (size_t)gcThreshold);
    JS_SetMaxStackSize(g_rt, (size_t)stackSize);
    JS_SetStripInfo(g_rt, JS_STRIP_DEBUG);  /* 生产环境剥离调试信息 */

    /* 按需创建最小化 Context */
    g_ctx = JS_NewContextRaw(g_rt);
    JS_AddIntrinsicBaseObjects(g_ctx);  /* 必须：Object/Array/Function 等 */

    if (strstr(features, "json"))
        JS_AddIntrinsicJSON(g_ctx);
    if (strstr(features, "regexp"))
        JS_AddIntrinsicRegExp(g_ctx);
    if (strstr(features, "promise"))
        JS_AddIntrinsicPromise(g_ctx);
    if (strstr(features, "eval"))
        JS_AddIntrinsicEval(g_ctx);
    if (strstr(features, "date"))
        JS_AddIntrinsicDate(g_ctx);
    if (strstr(features, "typedarray"))
        JS_AddIntrinsicTypedArrays(g_ctx);
    if (strstr(features, "mapset"))
        JS_AddIntrinsicMapSet(g_ctx);
    if (strstr(features, "proxy"))
        JS_AddIntrinsicProxy(g_ctx);

    /* 缓存高频 Atom */
    g_atoms.name        = JS_NewAtom(g_ctx, "name");
    g_atoms.type        = JS_NewAtom(g_ctx, "type");
    g_atoms.value       = JS_NewAtom(g_ctx, "value");
    g_atoms.length      = JS_NewAtom(g_ctx, "length");
    g_atoms.handleEvent = JS_NewAtom(g_ctx, "handleEvent");

    return NULL;
}
```

### 2. ArkTS 侧封装（按设备分档初始化）

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范

import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';
import qjs from 'libqjs.so';

export class QjsEngine {
  private initialized: boolean = false;

  /**
   * 初始化引擎，建议在 UIAbility.onCreate 中调用
   * 根据设备分档自动配置内存参数
   */
  init(options?: { extraFeatures?: string }): void {
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();

    let memoryLimit: number;
    let gcThreshold: number;
    let stackSize: number;
    let features: string;

    if (level === DeviceLevel.TIER_LOW) {
      memoryLimit = 64 * 1024 * 1024;   // 64 MB
      gcThreshold = 64 * 1024;          // 64 KB
      stackSize = 512 * 1024;           // 512 KB
      features = '';                     // 仅 BaseObjects
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      memoryLimit = 128 * 1024 * 1024;  // 128 MB
      gcThreshold = 128 * 1024;         // 128 KB
      stackSize = 768 * 1024;           // 768 KB
      features = 'json,regexp';
    } else {
      memoryLimit = 256 * 1024 * 1024;  // 256 MB
      gcThreshold = 256 * 1024;         // 256 KB
      stackSize = 1024 * 1024;          // 1 MB
      features = 'json,regexp,promise' + (options?.extraFeatures ? ',' + options.extraFeatures : '');
    }

    qjs.init({
      memoryLimit: memoryLimit,
      gcThreshold: gcThreshold,
      stackSize: stackSize,
      features: features,
    });
    this.initialized = true;
  }

  eval(script: string): string {
    if (!this.initialized) {
      return '';
    }
    return qjs.eval(script);
  }

  triggerGC(): void {
    if (this.initialized) {
      qjs.triggerGC();
    }
  }

  getMemoryStats(): QjsMemoryStats {
    return qjs.memstats() as QjsMemoryStats;
  }

  destroy(): void {
    if (this.initialized) {
      qjs.destroy();
      this.initialized = false;
    }
  }
}

export interface QjsMemoryStats {
  totalBytes: number;
  limitBytes: number;
  objectCount: number;
  stringBytes: number;
}
```

### 3. 退后台主动 GC（生命周期对齐）

```typescript
// ⚠️ 以下代码必须符合 ArkTS 编码规范

import qjs from 'libqjs.so';
import { DeviceLevelDecisionCenter, DeviceLevel } from '../../utils/DeviceLevelDecisionCenter';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class EntryAbility extends UIAbility {
  private qjsReady: boolean = false;

  onCreate(): void {
    const engine = new QjsEngine();
    engine.init();
    this.qjsReady = true;
  }

  /**
   * 【关键】应用退后台时主动 GC，降低内存水位
   *
   * 鸿蒙系统根据后台应用的内存占用决定是否终止进程：
   * - 内存占用低 → 保持存活，用户回来可秒开
   * - 内存占用高 → 被 LMK 终止，用户回来需冷启动
   */
  onBackground(): void {
    if (!this.qjsReady) return;

    // 触发 QuickJS GC
    const stats = qjs.triggerBackgroundGC();
    hilog.info(0x0001, 'QjsGC',
      `Background GC: ${stats.beforeBytes} -> ${stats.afterBytes} (freed ${stats.freedBytes} bytes)`);

    // 根据设备分档动态调整 GC 阈值
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      qjs.setGCThreshold(32 * 1024);   // 低端机退后台降至 32KB，更积极回收
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      qjs.setGCThreshold(64 * 1024);
    }
  }

  /**
   * 回到前台时恢复正常 GC 阈值
   */
  onForeground(): void {
    if (!this.qjsReady) return;
    let level: string = DeviceLevelDecisionCenter.getDeviceLevel();
    if (level === DeviceLevel.TIER_LOW) {
      qjs.setGCThreshold(64 * 1024);
    } else if (level === DeviceLevel.TIER_MEDIUM) {
      qjs.setGCThreshold(128 * 1024);
    } else {
      qjs.setGCThreshold(256 * 1024);
    }
  }

  onDestroy(): void {
    if (this.qjsReady) {
      qjs.destroy();
      this.qjsReady = false;
    }
  }
}
```

### 4. 退后台 GC C 侧实现

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

/*
 * NAPI 接口：退后台 GC
 * 触发 GC 后返回释放的内存量，方便 ArkTS 侧监控
 */
static napi_value trigger_background_gc(napi_env env, napi_callback_info info)
{
    if (!g_rt) return NULL;

    /* GC 前记录内存 */
    JSMemoryUsage before;
    JS_ComputeMemoryUsage(g_rt, &before);

    /* 触发 GC */
    JS_RunGC(g_rt);

    /* GC 后记录内存 */
    JSMemoryUsage after;
    JS_ComputeMemoryUsage(g_rt, &after);

    /* 计算释放量 */
    int64_t freed = before.malloc_size - after.malloc_size;

    /* 返回统计信息给 ArkTS */
    napi_value result;
    napi_create_object(env, &result);

    napi_value val;
    napi_create_int64(env, before.malloc_size, &val);
    napi_set_named_property(env, result, "beforeBytes", val);

    napi_create_int64(env, after.malloc_size, &val);
    napi_set_named_property(env, result, "afterBytes", val);

    napi_create_int64(env, freed, &val);
    napi_set_named_property(env, result, "freedBytes", val);

    return result;
}

/*
 * NAPI 接口：动态调整 GC 阈值
 */
static napi_value set_gc_threshold(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, NULL, NULL);

    int32_t threshold;
    napi_get_value_int32(env, args[0], &threshold);

    if (g_rt) {
        JS_SetGCThreshold(g_rt, (size_t)threshold);
    }
    return NULL;
}
```

### 5. 预编译字节码加载

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

#include <rawfile/raw_file_manager.h>

/*
 * 从鸿蒙 rawfile 加载预编译字节码
 * 消除编译期内存峰值，字节码体积比源码小 20-40%
 *
 * 构建阶段（CI 中完成）：
 *   qjsc --output app.qbc -e app.js
 */
static JSValue load_bytecode_from_rawfile(JSContext *ctx,
                                           NativeResourceManager *mgr,
                                           const char *path)
{
    RawFile *raw = OpenRawFile(mgr, path);
    if (!raw) return JS_EXCEPTION;

    size_t size = GetRawFileSize(raw);
    uint8_t *buf = (uint8_t *)malloc(size);
    ReadRawFile(raw, buf, size);
    CloseRawFile(raw);

    JSValue obj = JS_ReadObject(ctx, buf, size, JS_READ_OBJ_BYTECODE);
    free(buf);

    return obj;
}
```

### 6. 引用计数配对与错误处理

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

/*
 * NAPI 桥接函数模板：所有 JSValue 初始化为 JS_UNDEFINED
 * 使用 goto done 统一清理，确保错误路径也释放资源
 */
static napi_value napi_call_qjs_function(napi_env env, napi_callback_info info)
{
    JSValue js_result = JS_UNDEFINED;
    JSValue js_func = JS_UNDEFINED;
    JSValue js_global = JS_UNDEFINED;
    napi_value napi_result = NULL;

    /* 获取参数 */
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, NULL, NULL);

    char func_name[256];
    size_t name_len;
    napi_get_value_string_utf8(env, args[0], func_name, sizeof(func_name), &name_len);

    char param[1024];
    size_t param_len;
    napi_get_value_string_utf8(env, args[1], param, sizeof(param), &param_len);

    /* QuickJS 侧调用 */
    js_global = JS_GetGlobalObject(g_ctx);
    JSAtom atom_func = JS_NewAtom(g_ctx, func_name);
    js_func = JS_GetProperty(g_ctx, js_global, atom_func);
    JS_FreeAtom(g_ctx, atom_func);

    if (JS_IsException(js_func)) goto done;

    JSValue js_param = JS_NewStringLen(g_ctx, param, param_len);
    js_result = JS_Call(g_ctx, js_func, JS_UNDEFINED, 1, &js_param);
    JS_FreeValue(g_ctx, js_param);

    if (JS_IsException(js_result)) goto done;

    /* 转换结果回 NAPI */
    const char *result_str = JS_ToCString(g_ctx, js_result);
    napi_create_string_utf8(env, result_str, NAPI_AUTO_LENGTH, &napi_result);
    JS_FreeCString(g_ctx, result_str);

done:
    JS_FreeValue(g_ctx, js_result);
    JS_FreeValue(g_ctx, js_func);
    JS_FreeValue(g_ctx, js_global);

    return napi_result;
}
```

### 7. NAPI 模块注册汇总

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

static napi_value qjs_exports(napi_env env, napi_value exports)
{
    static napi_property_descriptor desc[] = {
        DECLARE_NAPI_FUNCTION("init",              qjs_init),
        DECLARE_NAPI_FUNCTION("eval",              qjs_eval),
        DECLARE_NAPI_FUNCTION("triggerGC",         qjs_gc),
        DECLARE_NAPI_FUNCTION("triggerBackgroundGC", trigger_background_gc),
        DECLARE_NAPI_FUNCTION("setGCThreshold",    set_gc_threshold),
        DECLARE_NAPI_FUNCTION("memstats",          qjs_memstats),
        DECLARE_NAPI_FUNCTION("destroy",           qjs_destroy),
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(qjs, qjs_exports)
```

### 8. 内存监控接口

```c
// ⚠️ 以下代码必须符合 ArkTS 编码规范中 C-API 部分

/*
 * NAPI 接口：获取 QuickJS 引擎内存使用详情
 * 用于开发/调试阶段定位内存热点
 */
static napi_value qjs_memstats(napi_env env, napi_callback_info info)
{
    if (!g_rt) return NULL;

    JSMemoryUsage u;
    JS_ComputeMemoryUsage(g_rt, &u);

    napi_value obj;
    napi_create_object(env, &obj);

    napi_value v;
    napi_create_int64(env, u.malloc_size, &v);
    napi_set_named_property(env, obj, "totalBytes", v);
    napi_create_int64(env, u.malloc_limit, &v);
    napi_set_named_property(env, obj, "limitBytes", v);
    napi_create_int64(env, u.obj_count, &v);
    napi_set_named_property(env, obj, "objectCount", v);
    napi_create_int64(env, u.str_size, &v);
    napi_set_named_property(env, obj, "stringBytes", v);
    napi_create_int64(env, u.atom_count, &v);
    napi_set_named_property(env, obj, "atomCount", v);

    return obj;
}
```

## QuickJS 引用计数规则速查

| 操作 | 是否需要释放 | 释放方式 |
|------|------------|---------|
| `JS_NewString` | 是 | `JS_FreeValue(ctx, val)` |
| `JS_GetProperty` | 是 | `JS_FreeValue(ctx, val)` |
| `JS_GetGlobalObject` | 是 | `JS_FreeValue(ctx, val)` |
| `JS_DupValue` | 是（增加一次引用） | `JS_FreeValue(ctx, val)` |
| `JS_ToCString` | 是（借用指针） | `JS_FreeCString(ctx, cstr)` |
| `JS_NewAtom` | 是 | `JS_FreeAtom(ctx, atom)` |
| `JS_DupAtom` | 是 | `JS_FreeAtom(ctx, atom)` |
| 整数/布尔/null/undefined | 否（无堆分配） | `JS_FreeValue` 安全但无操作 |

## 内存泄漏定位代码扫描模式

| 泄漏类型 | 搜索关键词 | 定位文件方式 | 确认方式 |
|----------|-----------|-------------|----------|
| NAPI 引用未释放 | `napi_create_reference` | 搜索 .cpp 文件 | 检查是否有 `napi_delete_reference` |
| QuickJS 引用未释放 | `JS_NewString`, `JS_GetProperty` | 搜索 .c/.cpp 文件 | 检查同函数是否有对应 `JS_FreeValue` |
| Atom 未释放 | `JS_NewAtom` | 搜索 .c/.cpp 文件 | 检查是否有对应 `JS_FreeAtom` |
| 引擎未销毁 | `JS_NewRuntime`, `JS_NewContext` | 搜索 .c/.cpp 文件 | 检查是否有 `JS_FreeRuntime` / `JS_FreeContext` |
| 退后台未 GC | `onBackground` | 搜索 .ets/.ts 文件 | 检查是否调用 `triggerGC` / `triggerBackgroundGC` |

## 适用组件

### ArkTS
- UIAbility（生命周期对齐：onCreate → init，onBackground → GC，onDestroy → destroy）
- Worker（生命周期对齐：线程创建 → init，线程销毁 → destroy）

### C-API（NDK）
- NAPI 模块（Register → 引擎初始化，桥接函数 → 引用计数配对）

## 注意事项

- **QuickJS GC 与 ArkTS GC 完全独立**：NAPI 桥接层是最容易泄漏的环节，必须确保引用计数配对
- **所有 JSValue 初始化为 JS_UNDEFINED**：`JS_FreeValue(JS_UNDEFINED)` 是安全的空操作
- **错误处理路径必须释放资源**：使用 `goto done` 统一清理模式
- **退后台主动 GC 是关键保活手段**：鸿蒙 LMK 会根据后台内存占用决定是否终止进程
- **预编译字节码消除编译期峰值**：CI 中使用 `qjsc` 编译，运行时通过 rawfile 加载
- **Atom 缓存复用**：高频属性名应在模块初始化时创建为全局 Atom，避免每次创建/销毁
- **按需加载内置对象**：`JS_NewContextRaw` + 按需添加可节省 50-70% 基础开销
- **多 Context 共享 Runtime**：多沙箱场景共享 Atom 表、Shape 缓存，节省基础结构内存
