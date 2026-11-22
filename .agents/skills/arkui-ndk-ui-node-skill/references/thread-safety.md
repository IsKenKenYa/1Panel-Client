# 子线程调用

## 坑点描述

ArkUI NDK 方法（节点创建、属性设置、挂载等）**必须在 UI 线程（主线程）调用**。在子线程（Worker、TaskPool 等）中调用会触发 abort，导致应用崩溃。

## C API 事实

本坑点涉及的 C API（`OH_ArkUI_InitModuleForArkTSEnv` / `OH_ArkUI_NotifyArkTSEnvDestroy` / `createNode` / `addChild` / `setAttribute` / `disposeNode` / `OH_ArkUI_GetModuleInterface`）的完整签名、头文件符号定位与来源核验方式见 `references/api-facts.md`——该文件为本 skill 的 C API 唯一权威源，本文件不在本地重复维护签名表与行号，避免行号漂移与重复维护。

`<arkui/native_node_napi.h>` 中 `OH_ArkUI_InitModuleForArkTSEnv` / `OH_ArkUI_NotifyArkTSEnvDestroy` 的注释明确标注 "Cannot be called on the non-UI thread."，线程检查失败会 abort。所有节点操作方法（`createNode` / `addChild` / `setAttribute` / `disposeNode`）同样必须在 UI 线程调用。

## 错误用法（反模式）

```c
// ❌ 在 Worker 线程中创建和操作 UI 节点
void workerTask() {
    // 以下调用在子线程中执行，会触发 abort
    ArkUI_NodeHandle node = nodeApi->createNode(ARKUI_NODE_TEXT);
    nodeApi->setAttribute(node, NODE_TEXT_CONTENT, &item);
    nodeApi->addChild(parentNode, node);
}
```

```typescript
// ❌ 在 TaskPool 中调用 ArkUI NDK 方法
@Concurrent
function updateUI() {
    // 在 TaskPool 线程中调用 Native 方法 → 崩溃
    nativeModule.updateNode();
}
taskpool.execute(updateUI);
```

## 正确用法

```typescript
// ✅ 在主线程中调用 ArkUI NDK 方法
// ArkTS 侧直接调用（默认在主线程）
nativeModule.createAndAddNode();

// ✅ 子线程结果通过事件/消息回主线程，主线程操作 UI
import worker from '@ohos.worker';
const workerInstance = worker.createWorker("workers/data.js");
workerInstance.onmessage = (e) => {
    // 在主线程接收消息后操作 UI 节点
    nativeModule.updateNodeWithData(e.data);
};
```

## 风险

- 子线程调用触发 abort → 应用直接崩溃，非偶现而是必现（有线程检查）
- 部分旧版本可能无线程检查，表现为数据竞争和偶现崩溃（更难定位）
- 在 Worker/TaskPool 中操作 UI 是常见误区，尤其是数据处理后直接更新 UI

## 线程安全原则

- 所有 ArkUI NDK 节点操作（创建、属性、挂载、释放）必须在 UI 线程
- 数据处理可在子线程，但 UI 操作结果必须回主线程
- NAPI 回调函数默认在主线程执行，在回调中操作 UI 节点是安全的
