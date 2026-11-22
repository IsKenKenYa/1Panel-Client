# dispose 防泄漏

## 坑点描述

通过 `createNode` 创建的 `ArkUI_NodeHandle` 在不再使用时**必须调用 `disposeNode` 释放**。未 dispose 的节点不会被自动回收，导致内存泄漏。

## C API 事实

本坑点涉及的 C API（`ArkUI_NodeHandle` / `createNode` / `disposeNode` / `OH_ArkUI_GetModuleInterface`）的完整签名、头文件符号定位与来源核验方式见 `references/api-facts.md`——该文件为本 skill 的 C API 唯一权威源，本文件不在本地重复维护签名表与行号，避免行号漂移与重复维护。

## 错误用法（反模式）

```c
// ❌ 创建节点后未 dispose
ArkUI_NodeHandle textNode = nodeApi->createNode(ARKUI_NODE_TEXT);
nodeApi->addChild(parentNode, textNode);
// ... 组件销毁时未调用 disposeNode(textNode) → 内存泄漏
```

## 正确用法

```c
// ✅ 创建后成对 dispose
ArkUI_NodeHandle textNode = nodeApi->createNode(ARKUI_NODE_TEXT);
nodeApi->addChild(parentNode, textNode);

// 组件销毁时释放
void onNodeDestroy(ArkUI_NodeHandle node) {
    // 先从父节点移除（如果仍挂载）
    // 再 dispose
    nodeApi->disposeNode(node);
}
```

## 注意事项

- `disposeNode` 释放的是 Native 侧 `createNode` 创建的节点
- P2 方向中 `OH_ArkUI_GetNodeHandleFromNapiValue` 产出的 handle **不需要也不应该** 调用 `disposeNode`——该 handle 的生命周期由 ArkTS 侧管理
- 先从父节点移除子节点，再 dispose 子节点，避免释放后父节点仍持有悬垂指针
- 对同一 handle 多次调用 `disposeNode` 是未定义行为

## 风险

- Native 节点不释放 → 每次页面/组件创建都泄漏节点内存
- 释放后继续使用 handle → 悬垂指针导致崩溃
- 双重 dispose → 未定义行为，可能崩溃
