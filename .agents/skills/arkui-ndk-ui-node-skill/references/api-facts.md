# ArkUI NDK UI 节点 API 事实表

> 本表是 `arkui-ndk-ui-node-skill` 所有 references 与 templates 中引用的 ArkUI C/ArkTS API 事实的**唯一权威源**。SKILL.md、各 reference 文件、各模板 README 引用 API 时一律回链本表，不在他处重复维护完整签名表。
>
> **定位方式**：本表只列头文件名 / 符号名 / .d.ts 路径，**不写精确行号**——SDK 版本演进会导致行号漂移，行号无法稳定维护与验证。需定位时按符号名（如 `ArkUI_NativeNodeAPI_1`）在对应头文件中检索。
>
> **所依据 SDK 版本**：HarmonyOS NEXT 原生 SDK（API 12+，DevEco Studio 5.0+）。若 SDK 升级后符号位置或签名变化，按本表「来源核验方式」列增量核验并更新本表；SKILL.md 与 templates 输出与本表冲突时以本表为准并回溯修订。
>
> **头文件根路径**（C API）：`${OHOS_SDK_NATIVE}/sysroot/usr/include/arkui/`（由 OHOS CMake 工具链自动加入 include）。
>
> **.d.ts 根路径**（ArkTS API）：`${OHOS_SDK}/ets/`。

## 一、关键约束（先读）

- 头文件前缀一律使用 `arkui/`（如 `<arkui/native_node.h>`），**不得**使用旧版 `<ace/xcomponent/native/...>` 路径。
- 节点 API 接口表类型为 `ArkUI_NativeNodeAPI_1`（**非**旧版 `ArkUI_NodeApi`），通过 `OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi)` 宏获取，需 `#include <arkui/native_interface.h>`。旧版 `OH_ArkUI_GetNodeApi` / `ArkUI_NodeApi` 在 HarmonyOS NEXT SDK 中**不存在**，不得使用。
- `OH_ArkUI_GetNodeHandleFromNapiValue` 产出的 handle **仅可作 `addChild` 的 child 参数**；对该 handle 调用 `setAttribute` / `resetAttribute` 不生效（详见 `references/handle-limit.md`）。
- 由 `createNode` 创建的 `ArkUI_NodeHandle` 须调用 `disposeNode` 释放（详见 `references/node-dispose.md`）；P2 中由 `OH_ArkUI_GetNodeHandleFromNapiValue` 产出的 handle **不适用本条**，其生命周期由 ArkTS 侧管理。
- 所有 ArkUI NDK 方法须在主线程调用（详见 `references/thread-safety.md`）。

## 二、C API 事实表（ArkUI NDK）

| API | 头文件（符号名检索） | 类型/签名要点 | 用途 | 来源核验方式 |
|-----|----------------------|---------------|------|--------------|
| `ArkUI_NodeHandle` | `arkui/common_type.h`（符号 `ArkUI_NodeHandle`） | `typedef struct ArkUI_Node* ArkUI_NodeHandle;` — opaque 节点指针类型 | 节点句柄 | 在 `common_type.h` 中检索 `ArkUI_NodeHandle` |
| `ArkUI_NodeContentHandle` | `arkui/common_type.h`（符号 `ArkUI_NodeContentHandle`） | `typedef struct ArkUI_NodeContent* ArkUI_NodeContentHandle;` — opaque NodeContent 指针 | NodeContent 句柄 | 在 `common_type.h` 中检索 `ArkUI_NodeContentHandle` |
| `ArkUI_AttributeItem` | `arkui/common_type.h`（符号 `ArkUI_AttributeItem`，字段 `.string`） | 属性参数结构体，含 `.string` 等字段 | 节点属性设置入参 | 在 `common_type.h` 中检索 `ArkUI_AttributeItem` |
| `ArkUI_NativeNodeAPI_1` | `arkui/native_node.h`（符号 `ArkUI_NativeNodeAPI_1`） | struct 接口表，含 `createNode` / `setAttribute` / `addChild` / `disposeNode` 等函数指针成员 | 节点 API 接口表 | 在 `native_node.h` 中检索 `ArkUI_NativeNodeAPI_1` |
| `OH_ArkUI_GetModuleInterface` | `arkui/native_interface.h`（符号 `OH_ArkUI_GetModuleInterface`） | 宏：`OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi)` 获取接口表指针 | 获取节点 API 接口表 | 在 `native_interface.h` 中检索 `OH_ArkUI_GetModuleInterface` |
| `OH_ArkUI_GetNodeHandleFromNapiValue` | `arkui/native_node_napi.h`（符号 `OH_ArkUI_GetNodeHandleFromNapiValue`） | `int32_t OH_ArkUI_GetNodeHandleFromNapiValue(napi_env env, napi_value value, ArkUI_NodeHandle* handle);` | P2：napi_value → `ArkUI_NodeHandle` | 在 `native_node_napi.h` 中检索符号名 |
| `OH_ArkUI_GetNodeContentFromNapiValue` | `arkui/native_node_napi.h`（符号 `OH_ArkUI_GetNodeContentFromNapiValue`） | `int32_t OH_ArkUI_GetNodeContentFromNapiValue(napi_env env, napi_value value, ArkUI_NodeContentHandle* content);` | P1：napi_value → `ArkUI_NodeContentHandle` | 在 `native_node_napi.h` 中检索符号名 |
| `OH_ArkUI_InitModuleForArkTSEnv` | `arkui/native_node_napi.h`（符号 `OH_ArkUI_InitModuleForArkTSEnv`） | `ArkUI_ErrorCode OH_ArkUI_InitModuleForArkTSEnv(napi_env env);`（API 20+；头文件注释标注 "Cannot be called on the non-UI thread."，线程检查失败 abort） | 初始化指定 env 的 ArkUI 模块（须在 UI 线程调用，详见 `references/thread-safety.md`） | 在 `native_node_napi.h` 中检索符号名 |
| `OH_ArkUI_NotifyArkTSEnvDestroy` | `arkui/native_node_napi.h`（符号 `OH_ArkUI_NotifyArkTSEnvDestroy`） | `void OH_ArkUI_NotifyArkTSEnvDestroy(napi_env env);`（API 20+；头文件注释标注不可在非 UI 线程调用，否则 abort） | 通知指定 env 环境已销毁（须在 UI 线程调用，详见 `references/thread-safety.md`） | 在 `native_node_napi.h` 中检索符号名 |
| `OH_ArkUI_NodeContent_AddNode` | `arkui/native_node.h`（符号 `OH_ArkUI_NodeContent_AddNode`） | 挂载 node 到 content | P1：将 Native 节点挂到 NodeContent | 在 `native_node.h` 中检索符号名 |
| `createNode` | `arkui/native_node.h`（`ArkUI_NativeNodeAPI_1` 成员 `createNode`） | `ArkUI_NodeHandle (*createNode)(ArkUI_NodeType type);` | 创建 Native 节点 | 在 `native_node.h` 中检索 `ArkUI_NativeNodeAPI_1` 结构体定义 |
| `addChild` | `arkui/native_node.h`（`ArkUI_NativeNodeAPI_1` 成员 `addChild`） | `int32_t (*addChild)(ArkUI_NodeHandle parent, ArkUI_NodeHandle child);` | P2：挂载 child 节点到 parent | 同上 |
| `setAttribute` | `arkui/native_node.h`（`ArkUI_NativeNodeAPI_1` 成员 `setAttribute`） | `int32_t (*setAttribute)(ArkUI_NodeHandle node, ArkUI_NodeAttributeType attribute, const ArkUI_AttributeItem* item);` | 设置节点属性（P2 handle 限制：不生效） | 同上 |
| `disposeNode` | `arkui/native_node.h`（`ArkUI_NativeNodeAPI_1` 成员 `disposeNode`） | `void (*disposeNode)(ArkUI_NodeHandle node);` | 释放 Native 节点防内存泄漏 | 同上 |

## 三、ArkTS API 事实表（P2 方向 ComponentContent 相关）

| API | .d.ts 路径（符号名检索） | 签名要点 | 用途 | 来源核验方式 |
|-----|--------------------------|----------|------|--------------|
| `ComponentContent<T>` | `ets/api/arkui/ComponentContent.d.ts`（符号 `class ComponentContent`） | `class ComponentContent<T extends Object> extends Content`；**单泛型参数**（非 `Object, Object` 两个） | 实体封装组件 | 在 `ComponentContent.d.ts` 中检索 `class ComponentContent` |
| `ComponentContent` 构造 | `ets/api/arkui/ComponentContent.d.ts`（重载 `constructor`） | `constructor(uiContext: UIContext, builder: WrappedBuilder<[T]>, args: T)`（三参数，API 12+） | 构造 ComponentContent 实例 | 在 `ComponentContent.d.ts` 中检索 `constructor` |
| `getUIContext()` | `ets/component/common.d.ts`（符号 `getUIContext`） | `getUIContext(): UIContext;` — 自定义组件内置方法，API 11+ | 获取当前组件所属 UIContext | 在 `common.d.ts` 中检索 `getUIContext` |
| `wrapBuilder()` | ArkTS 全局内置函数（无需 import） | 将 `@Builder` 函数包装为 `WrappedBuilder<[T]>` | 包装 builder 供 ComponentContent 构造使用 | ArkTS 语言内置，参考 ArkTS 官方文档 |

> **重要**：`ComponentContent` 构造函数第一参数为 `UIContext`（通过 `this.getUIContext()` 获取），第二参数须为 `wrapBuilder()` 包装产物（非 `@Builder` 函数本身）。漏传 `UIContext` 或未用 `wrapBuilder()` 均导致编译失败（详见 `references/component-content-constructor.md`）。

## 四、事实冲突处理

- SKILL.md、templates、各 reference 文件中如出现与本表冲突的 API 描述，以本表为准并回溯修订冲突处。
- 发现本表与最新 SDK 头文件 / .d.ts 冲突时，停止输出，提示维护者按「来源核验方式」列更新本表后再继续。
- 本表增量更新时只需在对应头文件 / .d.ts 中按符号名重新检索定位，无需依赖行号对照。
