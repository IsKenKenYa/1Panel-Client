# XComponent Surface 隐藏释放指南

## 问题

XComponent(type=SURFACE) 不可见时（页面跳转/退后台），surface 的 OHNativeWindow、dmabuf 等图形资源仍驻留内存。页面退出后 native 侧持有 window 引用计数不归零，dmabuf 不释放，多页面 surface 累积导致图形内存峰值过高。

## 两种方案

| 方案 | 原理 | API 版本 | 定位 |
| --- | --- | --- | --- |
| 方案一：NativeObjectReference 引用计数 | OnSurfaceCreated 时增引用计数持有，不可见时减引用计数释放 | API 8+ | **主方案**，适用所有版本 |
| 方案二：SurfaceCallback + Finalize/Initialize | 隐藏回调中销毁 surface，显示回调中重建 | API 20+ | 建议方案，需自动隐藏/显示触发 |

---

## 方案一：NativeObjectReference 引用计数（主方案，API 8+）

适用于传统 `OH_NativeXComponent`（libraryname 注入）方式。在 `OnSurfaceCreated` 时主动增加引用计数持有 window 和 buffer，在需要释放时手动减少引用计数，归零时图形资源释放。

```
OnSurfaceCreated → NativeObjectReference(window) 引用+1，RequestBuffer 取走 buffer
                  → 页面退出后 surface 引用仍驻留（dmabuf 不释放）
手动释放          → NativeObjectUnreference(buffer) + NativeObjectUnreference(window) 引用归零
                  → dmabuf 释放，PSS 回落
```

### 持有引用（OnSurfaceCreated）

```cpp
struct HeldSurface {
    OHNativeWindow* window;
    OHNativeWindowBuffer* buffer;
};

static HeldSurface g_held[MAX_HELD];
static int g_heldCount = 0;

static void OnSurfaceCreatedCB(OH_NativeXComponent* component, void* window)
{
    OHNativeWindow* win = static_cast<OHNativeWindow*>(window);

    // 引用计数 +1：持有 window，页面退出后不随 XComponent 销毁
    if (OH_NativeWindow_NativeObjectReference(win) == 0) {
        g_held[g_heldCount].window = win;

        // 取走一块 buffer 不归还：占住一块 dmabuf
        OHNativeWindowBuffer* buffer = nullptr;
        int fenceFd = -1;
        if (OH_NativeWindow_NativeWindowRequestBuffer(win, &buffer, &fenceFd) == 0) {
            if (fenceFd >= 0) close(fenceFd);
            g_held[g_heldCount].buffer = buffer;
        }
        g_heldCount++;
    }
}
```

### 手动释放（减少引用计数）

```cpp
napi_value ReleaseHeldSurface(napi_env env, napi_callback_info info)
{
    for (int i = 0; i < g_heldCount; i++) {
        if (g_held[i].buffer != nullptr) {
            OH_NativeWindow_NativeObjectUnreference(g_held[i].buffer);   // buffer 引用-1
        }
        if (g_held[i].window != nullptr) {
            OH_NativeWindow_NativeObjectUnreference(g_held[i].window);   // window 引用-1，归零时释放
        }
    }
    g_heldCount = 0;
    return nullptr;
}
```

### 注册回调（libraryname 注入方式）

```cpp
static napi_value Init(napi_env env, napi_value exports)
{
    napi_value exportInstance;
    napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    OH_NativeXComponent* nativeXComponent;
    napi_unwrap(env, exportInstance, reinterpret_cast<void**>(&nativeXComponent));

    static OH_NativeXComponent_Callback callback;
    callback.OnSurfaceCreated = OnSurfaceCreatedCB;
    callback.OnSurfaceChanged = OnSurfaceChangedCB;
    callback.OnSurfaceDestroyed = OnSurfaceDestroyedCB;   // 这里不释放，等手动 unreference
    callback.DispatchTouchEvent = nullptr;
    OH_NativeXComponent_RegisterCallback(nativeXComponent, &callback);
    return exports;
}
```

### ArkTS 侧

```typescript
import entry from 'libentry.so'

build() {
  XComponent({ id: 'xc', type: XComponentType.SURFACE, libraryname: 'entry' })
    .width('90%').height(220)

  Button('释放 surface 引用').onClick(() => entry.releaseHeldSurface())
}

aboutToDisappear(): void {
  entry.releaseHeldSurface()   // 页面退出时手动释放引用
}
```

### 验证

```bash
# 查看引用计数变化前后 dmabuf 占用
hidumper --mem <pid> | grep -i dmabuf
# 释放前 dmabuf 持续偏高，释放后回落
```

---

## 方案二：SurfaceCallback + Finalize/Initialize（建议方案，API 20+）

当 `compatibleSdkVersion` >= 6.1.0(23) 时建议升级使用。通过 C-API Node 创建节点，注册 `OH_ArkUI_SurfaceCallback` 的 hide/show 事件，隐藏时自动 `Finalize` 释放，显示时自动 `Initialize` 重建，无需手动调用释放。

### ⚠️ hide/show 回调触发时机（实测确认，与 API 文档描述不同）

`OnSurfaceHideCB` / `OnSurfaceShowCB` 的实际触发条件如下（2026-09-29 实测验证）：

| 回调 | 触发条件 | 不触发场景 |
|------|---------|-----------|
| `OnSurfaceHideCB` | **应用退后台**（`onBackground`，整个 UIAbility 不可见） | 仅 XComponent 组件被隐藏/可见性切换（`visibility(false)` / `.visible(false)`）**不触发**；页面内 `router.back()` 退出页面**不触发** hide，走的是 `disposeSurfaceNode` 的销毁路径 |
| `OnSurfaceShowCB` | **应用回前台**（`onForeground`，整个 UIAbility 重新可见） | 仅 XComponent 组件恢复可见性**不触发** |

**关键结论**：
1. **hide/show 回调绑定的是应用级前后台生命周期，不是组件级可见性**。仅隐藏 XComponent 组件（如 `.visible(false)`）不会触发 `OnSurfaceHideCB`，因此不会释放 dmabuf。
2. **页面退出（`router.back()` / `aboutToDisappear`）不会触发 hide 回调**。退出页面时应在 `aboutToDisappear` 中调用 `disposeSurfaceNode()`（内部执行 `Finalize` + `disposeNode`），走销毁路径而非 hide 路径。
3. **如需在组件不可见时释放 dmabuf，必须手动调用** `OH_ArkUI_XComponent_Finalize`（如通过 ArkTS 按钮 `entry.setSurfaceVisible(false)`），不能依赖 hide 回调自动触发。
4. hide 回调自动释放的适用场景：应用退后台时自动释放 surface + dmabuf，回前台时自动重建——无需开发者在 `onBackground`/`onForeground` 中手动处理。

```
应用退后台 → OnSurfaceHideCB → OH_ArkUI_XComponent_Finalize → OnSurfaceDestroyed（释放 dmabuf）
应用回前台 → OnSurfaceShowCB → OH_ArkUI_XComponent_Initialize → OnSurfaceCreated（重建 surface）

页面退出（aboutToDisappear）→ disposeSurfaceNode() → Finalize + disposeNode → OnSurfaceDestroyed（释放 dmabuf）
组件可见性切换（.visible(false)）→ ❌ 不触发 hide 回调，需手动调用 Finalize
```

### 创建节点 + 注册回调

```cpp
ArkUI_NativeNodeAPI_1* nodeAPI = nullptr;
OH_ArkUI_GetModuleInterface(ARKUI_NATIVE_NODE, ArkUI_NativeNodeAPI_1, nodeAPI);

ArkUI_NodeHandle node = nodeAPI->createNode(ARKUI_NODE_XCOMPONENT);

// 必须设唯一 ID，否则报 Duplicate identifier
ArkUI_AttributeItem idItem = { nullptr, 0, "surface_xc", nullptr };
nodeAPI->setAttribute(node, NODE_XCOMPONENT_ID, &idItem);

ArkUI_NumberValue typeVal[1] = { { .i32 = ARKUI_XCOMPONENT_TYPE_SURFACE } };
nodeAPI->setAttribute(node, NODE_XCOMPONENT_TYPE, &(ArkUI_AttributeItem){ typeVal, 1, nullptr, nullptr });

OH_ArkUI_XComponent_SetAutoInitialize(node, false);   // 改为手动控制

OH_ArkUI_SurfaceHolder* holder = OH_ArkUI_SurfaceHolder_Create(node);
OH_ArkUI_SurfaceCallback* cb = OH_ArkUI_SurfaceCallback_Create();
OH_ArkUI_SurfaceCallback_SetSurfaceCreatedEvent(cb, OnSurfaceCreatedCB);
OH_ArkUI_SurfaceCallback_SetSurfaceDestroyedEvent(cb, OnSurfaceDestroyedCB);
OH_ArkUI_SurfaceCallback_SetSurfaceHideEvent(cb, OnSurfaceHideCB);   // 核心
OH_ArkUI_SurfaceCallback_SetSurfaceShowEvent(cb, OnSurfaceShowCB);    // 核心
OH_ArkUI_SurfaceHolder_AddSurfaceCallback(holder, cb);

OH_ArkUI_NodeContent_AddNode(content, node);   // 先挂载到 UI 树
OH_ArkUI_XComponent_Initialize(node);           // 再初始化 surface（顺序不能反）
```

### 隐藏释放 / 显示重建回调

```cpp
static void OnSurfaceHideCB(OH_ArkUI_SurfaceHolder*) {
    OH_ArkUI_XComponent_Finalize(g_node);   // 释放 → 触发 OnSurfaceDestroyed
}
static void OnSurfaceShowCB(OH_ArkUI_SurfaceHolder*) {
    OH_ArkUI_XComponent_Initialize(g_node);  // 重建 → 触发 OnSurfaceCreated
}
```

### 清理

```cpp
OH_ArkUI_XComponent_Finalize(node);
OH_ArkUI_SurfaceCallback_Dispose(callback);
OH_ArkUI_SurfaceHolder_Dispose(holder);
nodeAPI->disposeNode(node);
```

### ArkTS 侧

```typescript
private surfaceContent: NodeContent = new NodeContent()

aboutToAppear(): void {
  entry.createSurfaceNode(this.surfaceContent)   // native 创建节点
}

build() {
  Stack() {
    ContentSlot(this.surfaceContent)   // 承载 native 节点
  }.width('90%').height(220).clip(true)

  // 方式一：手动触发隐藏/显示释放（组件级，不依赖应用前后台）
  Button('隐藏释放 surface').onClick(() => entry.setSurfaceVisible(false))  // 手动 Finalize
  Button('显示重建 surface').onClick(() => entry.setSurfaceVisible(true))   // 手动 Initialize
  // 方式二：应用退后台自动触发 hide → Finalize，回前台自动触发 show → Initialize（无需手动调用）
}

aboutToDisappear(): void {
  // 页面退出时必须 dispose，不会触发 hide 回调，走销毁路径
  entry.disposeSurfaceNode()
}
```

### 验证

```bash
hdc hilog | grep XComponentSurface
```

```
OnSurfaceCreated #1            ← 进入页面，createSurfaceNode + Initialize
OnSurfaceHide #1 → Finalize    ← 应用退后台（自动触发）
OnSurfaceDestroyed #1          ← dmabuf 释放
OnSurfaceShow #1 → Initialize  ← 应用回前台（自动触发）
OnSurfaceCreated #2            ← surface 重建
disposeSurfaceNode: Finalize    ← 页面退出（aboutToDisappear，不触发 hide）
OnSurfaceDestroyed #2          ← dmabuf 释放
```

> **注意**：仅隐藏 XComponent 组件可见性（`.visible(false)`）不会出现在上述日志中——hide 回调不触发，需手动调用 `setSurfaceVisible(false)` 才能看到 `OnSurfaceHide → Finalize` 日志。

---

## 方案对比

| 维度 | 方案一：引用计数（主） | 方案二：Finalize/Initialize（建议） |
| --- | --- | --- |
| 释放触发 | 手动调用 `NativeObjectUnreference` | 应用退后台自动触发 hide→Finalize；页面退出走 `disposeSurfaceNode`；组件级隐藏需手动调用 `setSurfaceVisible(false)` |
| 释放粒度 | 仅释放持有的 window/buffer 引用 | 整个 surface 销毁 |
| 恢复方式 | 需重新进入页面触发 OnSurfaceCreated | 应用回前台自动触发 show→Initialize；手动 `setSurfaceVisible(true)` |
| hide/show 回调触发条件 | 无 hide/show 回调 | **仅应用前后台切换触发**；组件可见性切换、页面退出均不触发 hide |
| 页面退出处理 | `aboutToDisappear` 中手动 `releaseHeldSurface()` | `aboutToDisappear` 中 `disposeSurfaceNode()`（Finalize+disposeNode，非 hide 路径） |
| API 版本 | API 8+ | API 20+ |
| 节点创建 | ArkTS 声明式 `libraryname` 注入 | C-API Node `createNode` |
| 回调能力 | 无 hide/show，需手动调用 | 有 hide/show 回调（仅应用前后台级） |
| 适用场景 | 所有版本，传统 XComponent 工程 | API 20+，需应用退后台自动释放 + 手动组件级释放 |

## CMakeLists.txt

```cmake
add_library(entry SHARED napi_init.cpp surface_release.cpp)
target_link_libraries(entry PUBLIC
    libace_napi.z.so libace_ndk.z.so libnative_window.so libhilog_ndk.z.so)
```

## 核心约束

**方案一（引用计数）**：
- `NativeObjectReference` 和 `NativeObjectUnreference` 必须配对，否则引用泄漏或悬垂指针。
- `OnSurfaceDestroyed` 中不要直接 unreference 同一个 window（此时框架可能已在销毁流程中），应在页面退出后单独调用释放。
- 取走的 buffer 必须先 unreference，再 unreference window，顺序不能反。
- 释放后不要继续访问已 unreference 的 window/buffer 指针。

**方案二（Finalize/Initialize）**：
- 必须先 `NodeContent_AddNode` 挂载到 UI 树，再 `Initialize`，否则 surface 创建不成功。
- C-API 创建的 XComponent 必须设 `NODE_XCOMPONENT_ID`，否则报 Duplicate identifier。
- 不要调用 `OH_ArkUI_InitModuleForArkTSEnv`，`GetModuleInterface` 不依赖它。
- 必须关闭自动初始化 `SetAutoInitialize(node, false)`，才能手动控制 Finalize/Initialize。
- **hide/show 回调仅应用前后台切换触发**：仅隐藏 XComponent 组件可见性（`.visible(false)`）不触发 `OnSurfaceHideCB`，需手动调用 `OH_ArkUI_XComponent_Finalize` 释放；页面退出（`aboutToDisappear`）也不触发 hide，必须在 `disposeSurfaceNode()` 中走 Finalize+disposeNode 销毁路径。
- **页面退出必须调用 `disposeSurfaceNode()`**：`aboutToDisappear` 中执行 `Finalize` + `SurfaceCallback_Dispose` + `SurfaceHolder_Dispose` + `disposeNode`，确保 surface 和 dmabuf 释放，避免节点泄漏。
