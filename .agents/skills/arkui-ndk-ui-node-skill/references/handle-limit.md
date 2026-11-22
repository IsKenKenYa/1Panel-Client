# handle 只能当 child

## 坑点描述

在 P2 方向（C→ArkTS）中，`OH_ArkUI_GetNodeHandleFromNapiValue` 将 ArkTS 侧的组件 napi_value 转换为 Native 侧的 `ArkUI_NodeHandle`。该 handle **仅可作 `addChild` 的第二参数（child）**，用于将 ArkTS 组件挂到 Native 父节点下。

对该 handle 调用 `setAttribute` 等节点操作方法**不生效**——该 handle 是 ArkTS 组件在 Native 侧的只读引用，不具备 Native 自建节点的完整能力。

## C API 事实

本坑点涉及的 C API（`OH_ArkUI_GetNodeHandleFromNapiValue` / `ArkUI_NodeHandle` / `addChild` / `setAttribute` / `OH_ArkUI_GetModuleInterface`）的完整签名、头文件符号定位与来源核验方式见 `references/api-facts.md`——该文件为本 skill 的 C API 唯一权威源，本文件不在本地重复维护签名表与行号，避免行号漂移与重复维护。

## 错误用法（反模式）

```c
// P2 方向：从 ArkTS 组件获取 handle
ArkUI_NodeHandle handle = nullptr;
OH_ArkUI_GetNodeHandleFromNapiValue(env, arktsValue, &handle);

// ❌ 错误：对 P2 转换的 handle 调用 setAttribute 不生效
// 该 handle 是 ArkTS 组件的只读引用，setAttribute 会被静默忽略
nodeApi->setAttribute(handle, NODE_WIDTH, &widthItem);

// ❌ 错误：对该 handle 调用 resetAttribute 同样不生效
nodeApi->resetAttribute(handle, NODE_WIDTH);
```

## 正确用法

```c
// P2 方向：handle 仅作 addChild 的 child 参数
ArkUI_NodeHandle handle = nullptr;
OH_ArkUI_GetNodeHandleFromNapiValue(env, arktsValue, &handle);

// ✅ 正确：作为 child 挂到 Native 父节点下
ArkUI_NodeHandle parentNode = nodeApi->createNode(ARKUI_NODE_STACK);
nodeApi->addChild(parentNode, handle);
```

如需修改 ArkTS 组件的属性，在 ArkTS 侧通过 `ComponentContent.update()` 更新（须在组件内创建 ComponentContent，详见 `component-content-constructor.md`）：

```typescript
// ArkTS 侧：在组件内创建 ComponentContent 并通过 update() 改属性
@Component
struct Index {
  private content: ComponentContent<Params> | null = null;

  aboutToAppear() {
    this.content = new ComponentContent<Params>(
      this.getUIContext(),
      wrapBuilder(myBuilder),
      { width: '100vp' }
    );
  }

  updateWidth() {
    this.content?.update({ width: '200vp' }); // 在 ArkTS 侧更新属性
  }
}
```

## 风险

- 对 P2 handle 调用 `setAttribute` / `resetAttribute` 不会报错，但属性设置不生效，导致 UI 表现与预期不一致
- 开发者误以为属性已设置，实际未生效，增加调试成本
