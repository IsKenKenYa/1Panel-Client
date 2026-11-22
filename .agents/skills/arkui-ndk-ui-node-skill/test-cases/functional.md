# 功能性测试用例

> 仓库智能检视流水线（hmos-skill-test-runner）识别的固定文件。覆盖方向判定、骨架生成、七类坑点检测等核心能力。

---

### 测试用例：FUNC-DIR-001

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

我在 ArkTS 页面里想用 NodeContent 做个占位，然后 C 侧挂 Native 节点树。

#### 预期输出

**验证标准**：

- 方向判定为 P1（ArkTS→C）
- 给出依据：用户描述"ArkTS 页面""NodeContent""C 侧挂 Native 节点树"→ ArkTS 侧占位 + Native 挂载 = P1
- 指引使用 `OH_ArkUI_GetNodeContentFromNapiValue` 取得 `NodeContentHandle` 后通过 `OH_ArkUI_NodeContent_AddNode` 挂载

---

### 测试用例：FUNC-DIR-002

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

我有一个 Native 创建的父节点，想把 ArkTS 的 ComponentContent 挂到它下面作为 child。

#### 预期输出

**验证标准**：

- 方向判定为 P2（C→ArkTS）
- 给出依据：用户描述"Native 父节点""ArkTS ComponentContent 挂到下面作 child"→ Native 父 + ArkTS child = P2
- 指引使用 `OH_ArkUI_GetNodeHandleFromNapiValue` 将 ComponentContent 的 napi_value 转为 `ArkUI_NodeHandle`，仅作 `addChild` 的 child 参数

---

### 测试用例：FUNC-DIR-003

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

我要做 CAPI 混合开发，ArkTS 和 Native 混用 UI 节点。

#### 预期输出

**验证标准**：

- 方向不明确时追问：ArkTS 侧是占位符（NodeContent）还是 Native 侧是父节点？
- 不直接臆断 P1 或 P2，需据用户回答分流

---

### 测试用例：FUNC-SKEL-001

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

帮我生成 P1 方向的骨架工程。

#### 预期输出

**验证标准**：

- **接入点确认**：用户未指定挂载位置，必须追问开发者 NodeContent 占位符要放在哪个页面的哪个容器组件下，不得随机选择容器挂载
- 生成 P1 骨架产物，至少包含：
  - `ets/pages/Index.ets`：`NodeContent` + `ContentSlot` 占位符
  - `cpp/native_template.cpp`：调用 `OH_ArkUI_GetNodeContentFromNapiValue` + `OH_ArkUI_NodeContent_AddNode`
  - `cpp/CMakeLists.txt`：`target_link_libraries` 同时含 `ace_ndk.z.so` 与 `ace_napi.z.so`
- 节点 API 接口表通过 `OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeApi)` 获取，不使用不存在的 `OH_ArkUI_GetNodeApi`
- 头文件使用 `<arkui/...>` 前缀，不使用旧版 `<ace/xcomponent/native/...>`
- `Index.d.ts` 用 `export const` 声明方法，非 `export interface` + `export default`

---

### 测试用例：FUNC-SKEL-002

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

帮我生成 P2 方向的骨架工程。

#### 预期输出

**验证标准**：

- **接入点确认**：用户未指定挂载位置，必须追问开发者 Native 父节点要挂到哪个页面的哪个 NodeContent 下、ComponentContent 作为 child 放在父节点的什么位置，不得随机选择容器挂载
- 生成 P2 骨架产物，至少包含：
  - `ets/pages/Index.ets`：`@Builder` + `ComponentContent`（构造传 `this.getUIContext()` + `wrapBuilder()` + args 三个参数）+ `NodeContent` 占位符
  - `cpp/native_template.cpp`：`OH_ArkUI_GetNodeContentFromNapiValue` 挂载父节点 + `OH_ArkUI_GetNodeHandleFromNapiValue` 转 handle + `addChild`
  - `cpp/CMakeLists.txt`：同时链接 `ace_ndk.z.so` 与 `ace_napi.z.so`
- `ComponentContent` 构造第一参数为 `UIContext`，第二参数为 `wrapBuilder()` 包装产物
- `napi_property_descriptor` 回调位于 field 3（`method`），非 field 4（`getter`）

---

### 测试用例：FUNC-SKEL-003

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

帮我生成 P1 方向的骨架工程，NodeContent 占位符放在 Index 页面的 Column 顶部。

#### 预期输出

**验证标准**：

- **接入点确认**：用户已明确指定挂载位置（Index 页面 Column 顶部），无需追问
- 生成 P1 骨架产物，`NodeContent` 占位符位于 Index 页面 `Column` 的顶部位置
- 其余产物要求同 FUNC-SKEL-001

---

### 测试用例：FUNC-SKEL-004

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

我要做 CAPI 混合开发，ArkTS 和 Native 混用 UI 节点。

#### 预期输出

**验证标准**：

- **方向判定**：方向不明确，追问 P1 还是 P2
- **接入点确认**：方向未定时不生成骨架；方向确定后若用户仍未提供挂载位置，须追问接入点信息，不得随机选择容器挂载
- 不直接臆断方向或挂载位置

---

### 测试用例：FUNC-PIT-001

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 CAPI 代码是否有问题：

```c
ArkUI_NodeHandle handle;
OH_ArkUI_GetNodeHandleFromNapiValue(env, value, &handle);
nodeApi->setAttribute(handle, NODE_WIDTH, &item);
```

#### 预期输出

**验证标准**：

- 命中"handle 只能当 child"坑点
- 指出 `OH_ArkUI_GetNodeHandleFromNapiValue` 产物仅可作 `addChild` 第二参数，`setAttribute` 不生效
- 建议改属性走 `ComponentContent.update()`
- **不**命中"dispose 防泄漏"坑点：该 handle 由 `OH_ArkUI_GetNodeHandleFromNapiValue` 产出（非 `createNode`），生命周期由 ArkTS 侧管理，不需要也不应调用 `disposeNode`
- 引用 `references/handle-limit.md`

---

### 测试用例：FUNC-PIT-002

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 CAPI 代码是否有问题：

```c
napi_ref ref;
napi_create_reference(env, value, 1, &ref);
```

#### 预期输出

**验证标准**：

- 命中"引用成对"坑点
- 指出 `napi_create_reference` / `napi_delete_reference` 必须配对
- 说明漏释导致泄漏，漏持导致 GC 悬垂崩溃
- 引用 `references/napi-ref-pair.md`

---

### 测试用例：FUNC-PIT-003

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 CAPI 代码是否有问题：

```c
ArkUI_NodeHandle node = nodeApi->createNode(ARKUI_NODE_TEXT);
nodeApi->addChild(parent, node);
```

#### 预期输出

**验证标准**：

- 命中"dispose 防泄漏"坑点
- 指出由 `createNode` 创建的 `ArkUI_NodeHandle` 须在组件销毁时调用 `disposeNode` 防止内存泄漏
- 引用 `references/node-dispose.md`

---

### 测试用例：FUNC-PIT-004

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 CAPI 代码是否有问题：

```c
ArkUI_NodeHandle textNode = nodeApi->createNode(ARKUI_NODE_TEXT);
ArkUI_AttributeItem src = { .string = "image.png" };
nodeApi->setAttribute(textNode, NODE_IMAGE_SRC, &src);
```

#### 预期输出

**验证标准**：

- 命中"节点类型混乱"坑点
- 指出对 TEXT 节点设置 IMAGE 属性不生效
- 引用 `references/node-type-confusion.md`

---

### 测试用例：FUNC-PIT-005

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下代码是否有问题：

```typescript
@Concurrent
function updateUI() {
    nativeModule.createAndAddNode();
}
taskpool.execute(updateUI);
```

#### 预期输出

**验证标准**：

- 命中"子线程调用"坑点
- 指出 ArkUI NDK 方法必须在主线程（UI 线程）调用，子线程调用会触发 abort 崩溃（有线程检查时必现；旧版本无线程检查时偶现）
- 引用 `references/thread-safety.md`

---

### 测试用例：FUNC-PIT-006

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 CAPI 代码是否有问题：

```c
napi_property_descriptor desc[] = {
    { "mountNativeNodes", nullptr, nullptr, MountNativeNodes, nullptr, nullptr, napi_default, nullptr },
};
```

#### 预期输出

**验证标准**：

- 命中"descriptor 字段顺序"坑点
- 指出回调须在 field 3（`method`），当前落入 field 4（`getter`）→ 属性值为 `undefined` → "X is not callable, X is undefined"
- 给出正确写法：`{ "mountNativeNodes", nullptr, MountNativeNodes, nullptr, nullptr, nullptr, napi_default, nullptr }`
- 引用 `references/napi-descriptor-field-order.md`

---

### 测试用例：FUNC-PIT-007

**skill**：arkui-ndk-ui-node-skill
**类型**：functional（功能验证）

#### 输入

请检查以下 ArkTS 代码是否有问题：

```typescript
const content = new ComponentContent(myBuilder, { message: 'hello' });
```

#### 预期输出

**验证标准**：

- 命中"ComponentContent 构造签名"坑点
- 指出构造须传 `UIContext`（`this.getUIContext()`）+ `wrapBuilder()` 包装的 `@Builder` + args 三个参数
- 说明漏传 `UIContext` 或未用 `wrapBuilder()` 导致编译报类型不匹配
- 给出正确写法：`new ComponentContent<string>(this.getUIContext(), wrapBuilder(myBuilder), 'hello')`
- 引用 `references/component-content-constructor.md`

---