# napi 引用成对

## 坑点描述

在 P2 方向（C→ArkTS）中，ArkTS 侧用 `@Builder` 定义组件后，需要通过 `napi_ref` 将组件创建函数注册给 C 侧。`napi_create_reference` 和 `napi_delete_reference` **必须成对调用**：

- **漏持（未 create_reference）**：napi_value 在函数返回后被 GC 回收，C 侧持有的悬垂指针导致崩溃
- **漏释（未 delete_reference）**：引用计数不归零，内存泄漏

## C API 事实

napi 引用管理是 Node.js N-API 标准接口，在 HarmonyOS NAPI 环境中同样适用：

| API | 用途 |
|-----|------|
| `napi_create_reference(env, value, refcount, &result)` | 创建强引用，refcount=1 时阻止 GC 回收 |
| `napi_delete_reference(env, ref)` | 释放引用，减少引用计数 |
| `napi_get_reference_value(env, ref, &result)` | 从引用取回 napi_value |

## 错误用法（反模式）

```c
// ❌ 漏持：未 create_reference，napi_value 在函数返回后被 GC 回收
napi_value createComponent(napi_env env, napi_callback_info info) {
    napi_value builderFn;
    napi_get_named_property(env, thisArg, "builder", &builderFn);
    // 直接传给 C 侧使用，未创建 reference
    registerBuilder(env, builderFn); // 返回后 builderFn 可能被 GC
    return nullptr;
}
```

```c
// ❌ 漏释：create_reference 后未 delete_reference
napi_ref builderRef;
napi_create_reference(env, builderFn, 1, &builderRef);
// ... 使用 builderRef ...
// 组件销毁时未调用 napi_delete_reference → 内存泄漏
```

## 正确用法

```c
// ✅ 成对：create + delete
napi_ref builderRef = nullptr;

// 注册时创建引用
napi_value createComponent(napi_env env, napi_callback_info info) {
    napi_value builderFn;
    napi_get_named_property(env, thisArg, "builder", &builderFn);
    // 创建强引用，防止 GC 回收
    napi_create_reference(env, builderFn, 1, &builderRef);
    registerBuilder(env, builderFn);
    return nullptr;
}

// 销毁时释放引用
void onDestroy(napi_env env) {
    if (builderRef != nullptr) {
        napi_delete_reference(env, builderRef);
        builderRef = nullptr;
    }
}
```

## 风险

- **漏持**：GC 在任意时机回收 napi_value，C 侧通过 `OH_ArkUI_GetNodeHandleFromNapiValue` 转换时偶现崩溃（悬垂指针）
- **漏释**：每次创建/销毁组件都泄漏一个 napi_ref，长期运行内存持续增长
- 崩溃时机不确定（取决于 GC 触发时机），难以复现和定位
