# napi_property_descriptor 字段顺序错误

## 坑点描述

在 NAPI 模块注册（`Init` 函数）中，`napi_property_descriptor` 用于把 C 函数暴露为 ArkTS 可调用的方法。该结构体有 8 个字段，回调函数须放在 **field 3（`method`）**，而非 field 4（`getter`）。

若在 field 3 多写一个 `nullptr`，回调会落入 field 4（`getter`）。运行时访问该属性会触发 getter（返回 `nullptr` → `undefined`），而非得到可调用方法，导致 ArkTS 侧报 **"X is not callable, X is undefined"**。此错误极难定位：.so 正常编译打包、构造函数与 NAPI 注册符号均存在，仅在运行时属性值为 `undefined`。

## C API 事实

头文件位于 `${OHOS_SDK_NATIVE}/sysroot/usr/include/` 下。

`napi_property_descriptor` 结构体定义（`node_ext.h` / `js_native_api.h`）字段顺序：

| 字段序号 | 字段名 | 类型 | 用途 |
|----------|--------|------|------|
| 1 | `utf8name` | `const char*` | 属性名（UTF-8 字符串） |
| 2 | `name` | `napi_value` | 属性名（napi_value，可 nullptr） |
| 3 | `method` | `napi_callback` | **方法回调**（作为函数调用时触发） |
| 4 | `getter` | `napi_callback` | getter 回调（属性读取时触发） |
| 5 | `setter` | `napi_callback` | setter 回调（属性写入时触发） |
| 6 | `value` | `napi_value` | 属性静态值 |
| 7 | `attributes` | `napi_property_attributes` | 属性特性（如 `napi_default`） |
| 8 | `data` | `void*` | 透传给回调的 data 指针 |

关键区别：
- `method`（field 3）：属性作为函数调用时触发，`nativeModule.foo(args)` 即调用此回调
- `getter`（field 4）：属性被**读取**时触发，返回值成为属性值；`nativeModule.foo` 先触发 getter，再对返回值调用

## 错误用法（反模式）

```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // ❌ 错误：field 3 (method) = nullptr，回调落入 field 4 (getter)
        { "mountNativeNodes", nullptr, nullptr, MountNativeNodes, nullptr, nullptr, napi_default, nullptr },
        //   field1            field2  field3   field4          field5  field6  field7         field8
        //                           method    getter
        //                           =nullptr  =MountNativeNodes  ← 位置错误！
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

运行时行为：
1. `method = nullptr` → 属性不可作为函数调用
2. `getter = MountNativeNodes` → 访问 `nativeModule.mountNativeNodes` 触发 getter，返回 `nullptr`（即 `undefined`）
3. `nativeModule.mountNativeNodes(...)` → "mountNativeNodes is not callable, mountNativeNodes is undefined"

## 正确用法

```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // ✅ 正确：回调在 field 3 (method)
        { "mountNativeNodes", nullptr, MountNativeNodes, nullptr, nullptr, nullptr, napi_default, nullptr },
        //   field1            field2  field3           field4  field5  field6  field7         field8
        //                           method            getter
        //                           =MountNativeNodes =nullptr  ← 正确
        { "disposeNodes", nullptr, DisposeNodes, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

记忆口诀：**名称、name值、回调方法、getter、setter、value、attributes、data**——回调是第 3 个位置参数，紧跟在 `nullptr`（name 的 napi_value）之后，前面只有两个值。

## 风险

- `method = nullptr` + `getter = callback` 时，属性被读取触发 getter 返回 `undefined`，调用即崩溃
- 编译期无任何警告（8 个字段类型部分兼容，C 聚合初始化不报错）
- 运行时报错信息（"X is not callable, X is undefined"）具有误导性，易被误判为 .so 未打包或模块未注册
- 定位成本高：需对照正确工程逐字段比对 `napi_property_descriptor` 初始化列表才能发现
