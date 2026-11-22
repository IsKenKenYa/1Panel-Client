---
name: arkui-ndk-ui-node-skill
description: 识别 CAPI 混合开发方向（P1 ArkTS→C 或 P2 C→ArkTS）并生成可运行工程骨架，同时检测七类常见坑点（handle 只能当 child、napi 引用成对、dispose 防泄漏、节点类型混乱、子线程调用、descriptor 字段顺序、ComponentContent 构造签名）。适用于"ArkTS 挂 Native""Native 挂 ArkTS""CAPI 混合""NodeContent""ContentSlot""ComponentContent""OH_ArkUI_GetNodeHandleFromNapiValue""addChild""ArkUI_NodeHandle""ArkUI_NodeContentHandle"等关键词触发的跨语言 UI 节点接入场景。
license: MIT
metadata:
  author: ArkUI-SEG
  version: "1.0.0"
---

# ArkUI NDK 接入 UI 节点

帮助开发者使用 ArkUI C 接口（NDK）构建 UI 节点并挂载到 ArkTS 侧，或将 ArkTS 组件挂载到 C 侧 Native 节点下。覆盖两个方向的接入模式骨架生成和七类常见坑点提示。

## Workflow

### Input

用户输入跨语言 UI 接入需求，通常包含以下信号之一：

- 方向线索："ArkTS 挂 Native""Native 挂 ArkTS""CAPI 混合""NodeContent""ContentSlot""ComponentContent""addChild""OH_ArkUI_GetNodeHandleFromNapiValue" 等
- 待审查的 CAPI 代码片段（C / ArkTS）
- 骨架生成诉求（如"生成 P1/P2 方向骨架工程"）

### Process

1. **方向判定**：按「[方向判定决策树](#方向判定决策树)」识别 P1（ArkTS→C）或 P2（C→ArkTS）；方向不明时追问"ArkTS 侧是占位符还是 Native 侧是父节点"，据答分流 P1/P2
2. **接入点确认**：据方向执行「[接入点确认](#接入点确认)」，检查用户输入是否已明确新增组件在组件树中的挂载位置；**缺失时必须追问开发者**，不得随机选择容器组件挂载新增节点
3. **骨架生成**：据方向执行「[P1 方向骨架生成](#p1-方向骨架生成arktsc)」或「[P2 方向骨架生成](#p2-方向骨架生成carkts)」，从 `templates/P{1,2}/` 复制可编译工程骨架（ArkTS + Native + CMake），并遵守「[骨架生成工程约束](#骨架生成工程约束)」六条；**接入点须与上一步开发者确认结果一致**
4. **代码扫描**：使用 `deveco-studio-codelinter` skill 扫描生成的工程骨架代码，识别 ArkTS / C/C++ 代码规范与潜在质量问题。若该 skill 已安装，按其扫描结果输出问题清单（含问题位置、类别与修复建议）；若该 skill 未安装，提示开发者从 `https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills/tree/main/04-tools/deveco/deveco-studio-codelinter` 获取并安装后重试扫描
5. **坑点检测**：扫描用户代码或生成骨架，按「[坑点检测规则](#坑点检测规则)」逐类匹配七类坑点；命中即读取对应 `references/*.md` 摘要输出风险提示，并在风险提示中**显式标注该 reference 文件路径**（如 `references/node-dispose.md`，须逐字出现在输出文本中，不得仅转述内容而省略路径），同类不重复（可用「[Checklist](#checklist)」逐项核对）

### Output

- **方向判定依据**：P1 / P2 选择理由
- **接入点确认结果**：开发者确认的挂载位置（页面、容器组件、在组件树中的层级），或缺失时向开发者追问的问题
- **可编译工程骨架**：含 `ets/pages/Index.ets` + `cpp/`（`CMakeLists.txt` + `native_template.cpp` + `types/`）的 P1 或 P2 方向工程
- **代码扫描结果**：`deveco-studio-codelinter` skill 扫描输出的代码问题清单（含问题位置、类别与修复建议）；若该 skill 未安装，输出安装提示与获取地址 `https://gitcode.com/HarmonyOS_Skills/harmonyos-agent-skills/tree/main/04-tools/deveco/deveco-studio-codelinter`
- **风险提示**：命中的坑点类别 + 位置 + 原因 + 修复建议 + **对应 reference 文件路径**（如「详见 `references/node-dispose.md`」，路径须逐字出现在输出中，不得仅转述内容而省略路径）

## 方向判定决策树

根据用户描述识别混合开发方向，明确二选一并给出依据：

```
用户输入
├─ 描述含"ArkTS 侧占位""ArkTS 页面挂 Native""NodeContent""ContentSlot"
│  → P1 方向（ArkTS→C）
│    ArkTS 创建占位符（NodeContent+ContentSlot），Native 侧经 OH_ArkUI_GetNodeContentFromNapiValue 取得 NodeContentHandle 后通过 OH_ArkUI_NodeContent_AddNode 挂载节点树
│
├─ 描述含"Native 父节点""C 侧挂 ArkTS""ComponentContent""getHandle""addChild"
│  → P2 方向（C→ArkTS）
│    ArkTS 用 @Builder+ComponentContent 封装组件，C 侧经 GetNodeHandleFromNapiValue 转 handle 后仅作 addChild child 挂到 Native 父节点
│
└─ 描述含"CAPI 混合""跨语言 UI"但无明确方向
   → 追问：ArkTS 侧是占位符还是 Native 侧是父节点？据答分流 P1/P2
```

## 接入点确认

骨架生成前，**必须确认新增组件在组件树中的挂载位置**。不得在用户未指定时随机选择容器组件（如随意用 `Column`/`Row`/`Stack`）挂载新增节点——错误挂载位置会导致 UI 布局不符合预期、后续返工成本高。

### 确认内容（按方向）

| 方向 | 须确认的接入点信息 | 追问示例 |
|------|-------------------|---------|
| P1（ArkTS→C） | `NodeContent` 占位符放在 ArkTS 页面组件树中的哪个位置（哪个页面、哪个容器组件下、第几个子节点位置） | "NodeContent 占位符要放在哪个页面的哪个容器下？例如 Index 页面的 Column 顶部，还是某个 Row 中间？" |
| P2（C→ArkTS） | Native 父节点通过哪个 `NodeContent` 挂载到 ArkTS 页面（哪个页面、哪个容器组件下），以及 ArkTS `ComponentContent` 作为 child 挂到 Native 父节点的什么位置 | "Native 父节点要挂到哪个页面的哪个 NodeContent 下？ComponentContent 作为 child 放在父节点的什么位置？" |

### 判定规则

1. **用户输入已明确挂载位置**（如"放在 Index 页面的 Column 顶部""挂到 Native 父节点的第一个子节点位置"）→ 直接采用，无需追问
2. **用户输入未明确挂载位置**（如只说"生成 P1 骨架""帮我把 Native 节点挂上去"但没说挂在哪里）→ **必须追问**上述对应方向的问题，得到开发者确认后再生成骨架
3. **不得的行为**：随机选择 `Column`/`Row`/`Stack` 等容器作为挂载点；默认放在页面根部；臆断开发者意图

### 与方向判定追问的区别

方向判定追问（决策树末尾）解决"P1 还是 P2"的问题；接入点确认追问解决"挂在哪里"的问题。两者独立，可能都需要追问。

## P1 方向骨架生成（ArkTS→C）

选定 P1 后，按以下结构生成可编译工程骨架：

1. ArkTS 侧：`NodeContent` + `ContentSlot` 创建占位符，`NodeContent` 经 napi 传入 C 侧；占位符的挂载位置须与「[接入点确认](#接入点确认)」中开发者确认的位置一致
2. Native 侧：调用 `OH_ArkUI_GetNodeContentFromNapiValue` 取得 `ArkUI_NodeContentHandle`，通过 `OH_ArkUI_NodeContent_AddNode` 挂载 Native 节点树
3. CMake 配置：标准 HarmonyOS Native 模块构建配置

模板详见 `templates/P1/`。

## P2 方向骨架生成（C→ArkTS）

选定 P2 后，按以下结构生成可编译工程骨架：

1. ArkTS 侧：`@Builder` 定义组件 + `ComponentContent` 封装（须传 `UIContext` + `wrapBuilder` + args 三个参数）+ `NodeContent` 占位符挂载 Native 父节点；占位符与父节点的挂载位置须与「[接入点确认](#接入点确认)」中开发者确认的位置一致
2. Native 侧：调用 `OH_ArkUI_GetNodeContentFromNapiValue` 取得 `NodeContentHandle` 挂载父节点，再调用 `OH_ArkUI_GetNodeHandleFromNapiValue` 将 ComponentContent 的 napi_value 转为 `ArkUI_NodeHandle`，仅作 `addChild` 的 child 参数挂到 Native 父节点
3. CMake 配置：标准 HarmonyOS Native 模块构建配置

模板详见 `templates/P2/`。

## 坑点检测规则

当用户提供的代码命中以下任一条件时，输出对应风险提示（读取对应 reference 文件摘要），并**在风险提示末尾显式标注 reference 文件路径**（如「参考：`references/node-dispose.md`」，路径须逐字出现，不得省略）。下表合并了检测条件、坑点类别、Reference 文件与摘要，为七类坑点的唯一权威清单：

| 检测条件 | 坑点类别 | Reference | 摘要 |
|----------|----------|-----------|------|
| `OH_ArkUI_GetNodeHandleFromNapiValue` 产物被 `setAttribute` 调用 | handle 只能当 child | `references/handle-limit.md` | 产物仅可作 addChild 第二参数；setAttribute 等不生效；改属性走 ComponentContent.update() |
| `napi_create_reference` 后无对应 `napi_delete_reference` | 引用成对 | `references/napi-ref-pair.md` | create/delete 必须配对；漏持→GC 悬垂崩溃；漏释→泄漏 |
| 由 `createNode` 创建的 `ArkUI_NodeHandle` 无对应 `disposeNode` 调用 | dispose 防泄漏 | `references/node-dispose.md` | 须调用 disposeNode 防止内存泄漏；P2 中 `OH_ArkUI_GetNodeHandleFromNapiValue` 产出的 handle 不适用本条（其生命周期由 ArkTS 侧管理，不需要也不应调用 disposeNode） |
| 对一种节点类型设置另一种节点类型的属性 | 节点类型混乱 | `references/node-type-confusion.md` | 跨类型属性不生效（如对 TEXT 节点设 IMAGE 属性） |
| 在非主线程（子线程/Worker/TaskPool）调用 ArkUI NDK 方法 | 子线程调用 | `references/thread-safety.md` | 子线程调用会触发 abort 崩溃（有线程检查时必现；旧版本无线程检查时偶现）；须在主线程操作 UI 节点 |
| `napi_property_descriptor` 初始化中回调位于 field 4（`getter`）而非 field 3（`method`）（如 `{ "foo", nullptr, nullptr, FooCallback, ... }`） | descriptor 字段顺序 | `references/napi-descriptor-field-order.md` | 回调须在 field 3；误入 field 4→属性值为 `undefined`→"X is not callable, X is undefined" |
| `new ComponentContent(...)` 构造未传 `UIContext` 作为第一参数，或未用 `wrapBuilder()` 包装 `@Builder` 函数（如 `new ComponentContent(builder, args)`） | ComponentContent 构造签名 | `references/component-content-constructor.md` | 构造须传 UIContext + wrapBuilder 包装的 @Builder + args；漏传→编译报类型不匹配 |

七类坑点各独立触发，同类不重复输出。

## Checklist

逐项核验以下七类坑点（命中即按上方「[坑点检测规则](#坑点检测规则)」表输出对应风险提示，并**显式标注 reference 文件路径**，路径须逐字出现在输出中）：

- [ ] 是否对 `OH_ArkUI_GetNodeHandleFromNapiValue` 产物调用了 `setAttribute`？
- [ ] 每个 `napi_create_reference` 是否都有对应的 `napi_delete_reference`？
- [ ] 由 `createNode` 创建的 `ArkUI_NodeHandle` 是否都有对应 `disposeNode` 调用？
- [ ] 是否对一种节点类型设置了另一种节点类型的属性？
- [ ] 是否在非主线程（子线程/Worker/TaskPool）调用了 ArkUI NDK 方法？
- [ ] `napi_property_descriptor` 初始化中回调是否位于 field 3（`method`）而非 field 4（`getter`）？
- [ ] `new ComponentContent(...)` 构造是否传了 `UIContext` 作为第一参数且用 `wrapBuilder()` 包装了 `@Builder` 函数？

## C/ArkTS API 权威源

所有 references 和 templates 中引用的 ArkUI C API 与 ArkTS API 事实以 **HarmonyOS NEXT 原生 SDK 实际头文件 / .d.ts 文件**为权威源（C API：`arkui/` 命名空间，位于 `${OHOS_SDK_NATIVE}/sysroot/usr/include/arkui/`；ArkTS：`${OHOS_SDK}/ets/`），不得凭空发明签名或沿用旧版 `ace/xcomponent/native/` 路径。

完整 API 事实表（含头文件 / 符号名 / 签名要点 / 用途 / 来源核验方式）集中维护于 **`references/api-facts.md`**，作为唯一权威源，不在本文件重复。需引用或核验具体 API 时回链该文件，不在此处复制表项。

核心约束摘要（细节见 `references/api-facts.md`「关键约束」）：

- 头文件前缀一律 `arkui/`（如 `<arkui/native_node.h>`），**不得**使用旧版 `<ace/xcomponent/native/...>` 路径
- 节点 API 接口表类型为 `ArkUI_NativeNodeAPI_1`（**非**旧版 `ArkUI_NodeApi`），通过 `OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi)` 宏获取，需 `#include <arkui/native_interface.h>`；旧版 `OH_ArkUI_GetNodeApi` / `ArkUI_NodeApi` 在 HarmonyOS NEXT SDK 中**不存在**
- `ComponentContent` 构造须传 `UIContext`（`this.getUIContext()`）+ `wrapBuilder()` 包装的 `@Builder` + args 三参数（API 12+）；漏传 UIContext 或未 wrapBuilder → 编译失败（详见 `references/component-content-constructor.md`）

## 骨架生成工程约束

生成可编译工程骨架时，除上述 C/ArkTS API 权威源外，须遵守以下六条工程构建约束（来源：真实工程编译验证）：

1. **CMake 链接库须同时含 `ace_ndk.z.so` 与 `ace_napi.z.so`**
   - `ace_ndk.z.so` 提供 ArkUI NDK 符号（`OH_ArkUI_*` / `ArkUI_NativeNodeAPI_1` 等）
   - `ace_napi.z.so` 提供 NAPI 符号（`napi_get_cb_info` / `napi_module_register` / `napi_define_properties` / `napi_create_reference` 等，来自 `<napi/native_api.h>`）
   - 缺 `ace_napi.z.so` 会链接报未定义符号；`target_link_libraries` 必须同时列出两者。

2. **`ContentSlot` 不支持通用属性修饰符**（P1/P2 方向）
   - `ContentSlot` 是占位组件，不接受 `.width()/.height()/.margin()/.backgroundColor()` 等通用属性。
   - 需约束占位区域尺寸时，用带尺寸的容器（如 `Column`）包裹 `ContentSlot`，再在容器上设置尺寸，**不得**直接对 `ContentSlot` 链式调用通用属性。

3. **`napi_property_descriptor` 回调须在 field 3（`method`）**
   - 生成 `Init` 函数的 `napi_property_descriptor` 初始化时，回调函数必须放在 field 3（`method`），不得落入 field 4（`getter`）。
   - 错误/正确写法与风险详见「[坑点检测规则](#坑点检测规则)」表「descriptor 字段顺序」行及 `references/napi-descriptor-field-order.md`，此处不重复。

4. **`Index.d.ts` 类型声明须用 `export const`（非 `export interface` + `export default`）**
   - ArkTS 侧 `import nativeModule from 'libarkui_ndk_pN.so'` 后，`nativeModule` 是模块对象本身，其上各方法须以 `export const` 顶层声明导出。
   - 错误写法：`export interface ArkUINdk { mountNativeNodes(...): void; }` + `export default ArkUINdk;` → `nativeModule` 解析为类型而非值 → 编译期或运行时 "X is not callable / X is undefined"。
   - 正确写法：`export const mountNativeNodes: (nodeContent: NodeContent) => void;`
   - 模板已提供 `templates/P{1,2}/cpp/types/libarkui_ndk_p{1,2}/Index.d.ts`，直接复制使用，**不得**自行改写为 interface 形式。
   - 此 bug 编译期可能不报错（取决于 ArkTS 类型检查严格度），运行时 `nativeModule` 为 `undefined` 或类型不可调用，定位成本高（来源：真实工程编译运行验证）。

5. **`ComponentContent` 构造须传 `UIContext` + `wrapBuilder`（P2 方向）**
   - 生成 P2 骨架时，`ComponentContent` 构造须传 `UIContext`（`this.getUIContext()`，**不得**在组件外部全局函数创建）+ `wrapBuilder()` 包装的 `@Builder` + args 三个参数；`ComponentContent` 只有一个泛型参数 `T extends Object`，`Index.d.ts` 类型声明须匹配。
   - 错误/正确写法与风险详见「[坑点检测规则](#坑点检测规则)」表「ComponentContent 构造签名」行及 `references/component-content-constructor.md`，此处不重复。
   - 模板已提供 `templates/P2/ets/pages/Index.ets`，直接复制使用。

6. **`Init` 函数须用 `EXTERN_C_START` / `EXTERN_C_END` 包裹**
   - `Init`（`napi_module.nm_register_func` 指向的注册回调）须以 C 链接编译，须用 `EXTERN_C_START` / `EXTERN_C_END` 包裹（宏定义于 `<napi/native_api.h>`，展开为 `extern "C" {` / `}`）。
   - 缺失包裹会导致符号链接/注册异常，与标准 Native C++ 模板工程（DevEco Studio `napi_init.cpp`）保持一致。
   - 正确写法：
     ```cpp
     EXTERN_C_START
     static napi_value Init(napi_env env, napi_value exports) {
         napi_property_descriptor desc[] = {
             { "mountNativeNodes", nullptr, MountNativeNodes, nullptr, nullptr, nullptr, napi_default, nullptr },
         };
         napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
         return exports;
     }
     EXTERN_C_END
     ```
   - 模板已提供 `templates/P{1,2}/cpp/native_template.cpp`，`Init` 已按此约束包裹，直接复制使用，**不得**移除 `EXTERN_C_START` / `EXTERN_C_END`（来源：标准 Native C++ 模板工程 `napi_init.cpp`）。
