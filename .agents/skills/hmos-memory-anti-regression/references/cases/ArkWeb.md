# ArkWeb 劣化案例模式（libarkweb_engine.so / DMA）

> 本文档定义 ArkWeb 维度劣化的典型案例模式，供劣化点根因匹配使用。匹配到下列案例时：可引用案例的根因推断并标注出处（如「见 ArkWeb.md 一、预启动渲染进程」）；未匹配到时：根因列写「未匹配案例库，需人工核查」，不给修改建议。

## 一、Web离线组件预创建

### 案例模式描述

在未进入 Web 页面时，应用提前创建空 Web 组件（about:blank），启动 Web 的渲染进程，为后续使用做准备。预启动会拉起 ArkWeb 引擎与渲染相关 so，并触发 DMA buffer 分配，表现为：

- 新增 `libEGL.so`、`libjs_environment.z.so` 等 so 库及 `libarkweb_engine.so` 的 native heap 占用增长；
- 因预启动渲染进程，触发 DMA（`libbuffer_handle.z.so`）大幅增长。

这类劣化本质是**在用户尚未访问 Web 页面时提前创建渲染进程**，属时机不当的预启动，而非合理使用增长。

### 匹配规则

1. **`libarkweb_engine.so` 内存堆栈劣化（数据规则）**：A/B 两版 native heap 堆栈分析中，劣化侧 `libarkweb_engine.so` 占用增长。
2. **hilog 日志分析 Web 组件创建/销毁差值（核查规则）**：用 `hilog | grep -E "CreateNWeb|NWebImpl::OnDestroy|::OnActive|::OnInactive"` 分析当前存活 Web 组件数 **a**（`CreateNWeb` 与 `NWebImpl::OnDestroy` 出现次数差值），并与上一版本对比是否增加；组件树当前显示的 Web 组件数记为 **b**，离线组件个数 = a - b。检查要点：
   - hilog 中创建/销毁事件差值得出存活组件数 a，并与上一版本对比；
   - 组件树（arkui dumpview）当前显示的 Web 组件数 b；
   - 离线组件个数 = a - b。
3. **离线组件个数 > 0（数据规则）**：a - b > 0，即存在未挂载到组件树上的离线 Web 组件。

三条规则同时命中即确认：劣化源于 Web 离线组件预创建。规则 2/3 未发现离线组件（a - b ≤ 0）时，仅凭规则 1 不得下此结论，根因列写「未匹配案例库，需人工核查」。

### 问题代码

## 二、预渲染 Web 页面

### 案例模式描述

在未进入 Web 页面时，应用提前创建 Web 组件并加载目标 URL（WEB_PAGE_URL）进行预渲染，为后续页面展示做准备。预渲染拉起 ArkWeb 引擎，`libarkweb_engine.so` 的 native heap 占用增长。这类劣化本质是**在用户尚未访问 Web 页面时提前渲染目标页面**，属时机不当的预渲染，而非合理使用增长。

### 匹配规则

1. **`libarkweb_engine.so` 内存堆栈劣化（数据规则）**：A/B 两版 native heap 堆栈分析中，劣化侧 `libarkweb_engine.so` 占用增长。
2. **源码核查预渲染目标 URL（核查规则）**：检查**劣化后版本**源码中是否新增预渲染目标 URL 的调用——在用户未进入 Web 页面前，提前创建 Web 组件并加载/渲染目标 URL。实现方式包括但不限于：
   - 通过 `Web({ src: url })` 创建 Web 组件并调用 `controller.onActive()` 启动后台渲染；
   - 通过 `controller.loadUrl(url)` 加载目标 URL 到已创建的 Web 组件。
   检查要点：
   - 是否在案例页 `aboutToAppear` 或 ability 启动阶段即创建 Web 组件并加载目标 URL（区别于用户点击进入 Web 页后才加载）；
   - 预渲染的 Web 组件是否在用户真正进入 Web 页面前已走完渲染流程并常驻。
3. **源码扫描劣化后版本未使用 `onInactive` 优化（核查规则）**：检查**劣化后版本**源码中，预渲染的 Web 组件是否未通过 `onInactive` 暂停/停止后台渲染。检查要点：
   - 预渲染完成后是否调用 `controller.onInactive()` 停止后台渲染（预渲染场景的基本优化，劣化后版本缺少该调用即命中）；
   - 页面不可见时是否调用 `controller.onInactive()` 暂停渲染；
   - 与劣化前版本对比，劣化后版本是否移除或缺少 `onInactive` 调用。

三条规则同时命中即确认：劣化源于 ArkWeb 预渲染 Web 页面。规则 2/3 未命中（即未发现预渲染目标 URL 的调用，或劣化后版本已使用 `onInactive` 优化）时，仅凭规则 1 不得下此结论，根因列写「未匹配案例库，需人工核查」。

### 问题代码

## 三、离线 Web 组件未复用/释放

### 案例模式描述

应用使用 `NodeController` + `BuilderNode` 创建离线 Web 组件（`createNWeb`），但在离开 Web 页面时未调用 `WebviewController.loadUrl('about:blank')` 复用组件，也未在应用退后台或长期不使用时调用 `BuilderNode.dispose()` + `rebuild()` 释放组件。多个 UI 页面各自创建独立离线 Web 组件，用后既不复用也不释放，每个 Web 组件约 200MB 内存，组件数量随业务页面线性增长且不回收，表现为：

- `libarkweb_engine.so` 的 native heap 占用增长；
- 源码中离线 Web 组件创建后无复用（`loadUrl('about:blank')`）与释放（`dispose()` + `rebuild()`）逻辑，退后台未释放。

这类劣化本质是**离线 Web 组件未复用/未释放导致的实例累积型增长**，而非合理使用增长。

### 匹配规则

1. **`libarkweb_engine.so` 内存堆栈劣化（数据规则）**：A/B 两版 native heap 堆栈分析中，劣化侧 `libarkweb_engine.so` 占用增长。
2. **源码扫描未使用复用逻辑（核查规则）**：扫描源码中离线 Web 组件的使用点，检查离开 Web 页面时是否未调用 `WebviewController.loadUrl('about:blank')` 为复用做准备。检查要点：
   - `NavDestination` 的 `onWillHide` / 页面的 `onPageHide` / `aboutToDisappear` 回调中是否未调用 `loadUrl('about:blank')`；
   - 多个 UI 页面是否各自创建独立 Web 组件而非复用同一离线组件（`createNWeb` 调用点分散、无统一 `controllerMap` 复用调度）；
   - 离线组件创建后是否无任何复用调度逻辑（页面间跳转后旧组件不 `loadUrl('about:blank')` 清空，直接新建下一个）。
3. **源码扫描未使用释放逻辑（核查规则）**：扫描源码中离线 Web 组件的使用点，检查是否未调用 `BuilderNode.dispose()` + `rebuild()` 释放组件、且应用退后台时未释放离线组件。检查要点：
   - 是否未实现 `dispose()` + `rebuild()` 释放接口（如 `recycleNWeb` / `recycleNWebs`），或已实现但从未被调用；
   - `NodeController` 是否未实现 `onBind` / `onUnbind` 绑定状态跟踪（`isBound()`），无法安全判断释放时机；
   - `UIAbility` 的 `onBackground` 回调中是否未调用释放离线 Web 组件的逻辑（`recycleNWebs`），退后台后组件仍驻留内存；
   - `UIAbility` 的 `onForeground` 回调中是否未实现恢复逻辑（`restoreNWebs`）。

三条规则同时命中即确认：劣化源于离线 Web 组件未复用/未释放。规则 2/3 未命中（即已使用 `loadUrl('about:blank')` 复用，或已使用 `dispose()` + `rebuild()` 释放/退后台释放）时，仅凭规则 1 不得下此结论，根因列写「未匹配案例库，需人工核查」。

### 问题代码

典型反模式（源码检查时按上列检查要点逐项核对）：

```typescript
// 反模式一：多个页面各自创建 Web 组件，离开时不复用（未 loadUrl('about:blank')），组件随页面累积
@Entry
@Component
struct WebPageA {
  aboutToAppear() {
    // 每次进入页面都新建离线 Web 组件，不复用已有组件
    createNWeb(url_A, this.getUIContext());
  }
  // 缺少 onWillHide / aboutToDisappear 中调用 loadUrl('about:blank') 的复用逻辑
}
```

```typescript
// 反模式二：未实现释放逻辑，退后台不释放离线 Web 组件
export default class EntryAbility extends UIAbility {
  onBackground(): void {
    // 缺少 recycleNWebs() 调用，退后台后离线 Web 组件仍驻留内存
  }
  onForeground(): void {
    // 缺少 restoreNWebs() 调用
  }
}
```

```typescript
// 反模式三：创建了离线 Web 组件但从未调用 dispose() + rebuild() 释放
export const createNWeb = (url: ResourceStr, uiContext: UIContext) => {
  let baseNode = new MyNodeController();
  baseNode.initWeb(url, uiContext);
  nodeMap.set(url, baseNode);
  // 缺少对应的 recycleNWeb(url) 释放接口，组件用后不释放
};
```

- 多个 `NavDestination` 页面各自 `createNWeb` 创建独立 Web 组件，页面间跳转后旧组件不复用不释放；
- 未实现 `recycleNWeb` / `recycleNWebs` 释放接口，或已实现但 `onBackground` 中未调用；
- `NodeController` 未实现 `onBind` / `onUnbind` 绑定状态跟踪，无法安全判断释放时机。
