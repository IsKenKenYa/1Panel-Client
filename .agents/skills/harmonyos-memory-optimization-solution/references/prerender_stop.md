# 预渲染停止渲染指南

## 目录

1. [预渲染概述](#预渲染概述)
2. [预渲染实现](#预渲染实现)
3. [渲染完成后停止渲染](#渲染完成后停止渲染)
4. [常见问题排查](#常见问题排查)

---

## 预渲染概述

预渲染Web页面优化方案适用于Web页面启动和跳转场景。例如，进入首页后，跳转到其他子页。建议在高命中率的页面使用该方案。

预渲染Web页面的实现是提前创建离线Web组件，设置Web为Active状态来开启渲染引擎，进行后台渲染。

### 注意事项

1. 预渲染Web页面时，需要明确加载的资源。
2. 由于该方案会将不可见的后台Web设置为Active状态，建议不要预渲染包含自动播放音视频的页面。应用开发者请自行检查和管理页面行为。
3. 预渲染的网页会在后台不断进行渲染，建议在预渲染完成后立即停止渲染，以防止发热和功耗问题。

---

## 预渲染实现

### 基本架构

定义一个自定义组件以封装Web组件，此Web组件在离线状态下被创建，封装于无状态的 `NodeContainer` 节点中，并与相应的 `NodeController` 组件绑定。Web组件在后台预渲染完毕后，当需要展示时，通过 `NodeController` 将其挂载到ViewTree的 `NodeContainer` 中。

### 创建离线Web组件

在 `EntryAbility` 的 `onWindowStageCreate` 中创建离线Web组件：

```typescript
import { createNWeb } from "../pages/Common";
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

// ...
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err && err.code) {
        console.info('loadContent failed. errorCode: ' + err.code);
        return;
      }
      let windowClass: window.Window = windowStage.getMainWindowSync();
      if (!windowClass) {
        console.info('windowClass is null');
        return;
      }
      // 创建Web动态组件（需传入UIContext），loadContent之后的任意时机均可创建
      createNWeb('www.example.com', windowClass.getUIContext());
    });
  }
```

### 在页面中绑定显示

```typescript
import { getNWeb } from './Common'

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        // NodeContainer用于与NodeController节点绑定，rebuild会触发makeNode
        NodeContainer(getNWeb('www.example.com'))
          .height('90%')
          .width('100%')
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

参考[预渲染停止示例](../assets/PrerenderStopExample.ets)

---

## 渲染完成后停止渲染

### 核心原理

使用 `onFirstMeaningfulPaint` 事件检测Web页面首次有意义渲染完成的时机，在回调中调用 `onInactive()` 停止后台渲染，从而防止发热和功耗问题。

> **说明：**
> `onFirstMeaningfulPaint` 接口适用于http和https网页。

### 实现步骤

1. 定义布尔变量 `shouldInactive` 控制是否需要停止渲染
2. 在 `onPageBegin` 中调用 `onActive()` 开启渲染
3. 在 `onFirstMeaningfulPaint` 回调中检查 `shouldInactive`，调用 `onInactive()` 停止渲染
4. 在 `aboutToAppear` 中将 `shouldInactive` 设为 `false`，防止切换到前台后停止渲染

### 示例代码

```typescript
// 通过布尔变量shouldInactive控制网页在后台完成预渲染后停止渲染
let shouldInactive: boolean = true;

@Builder
function webBuilder(data: Data) {
  Column() {
    Web({ src: data.url, controller: data.controller })
      .onPageBegin(() => {
        // 调用onActive，开启渲染
        data.controller.onActive();
      })
      .onFirstMeaningfulPaint(() => {
        if (!shouldInactive) {
          return;
        }
        // 在预渲染完成时触发，停止渲染
        data.controller.onInactive();
        shouldInactive = false;
      })
      .width('100%')
      .height('100%')
  }
}
```

### NodeController 中的 aboutToAppear 处理

当组件挂载到UI树（即切换到前台显示）后，不需要停止渲染：

```typescript
export class MyNodeController extends NodeController {
  // 当controller对应的NodeContainer在Appear的时候进行回调
  aboutToAppear() {
    console.info('aboutToAppear');
    // 切换到前台后，不需要停止渲染
    shouldInactive = false;
  }
}
```

---

## 常见问题排查

### 预渲染不停止导致发热

**现象**：预渲染后设备发热严重，功耗偏高。

**原因**：`onFirstMeaningfulPaint` 回调未正确触发，或 `shouldInactive` 变量逻辑错误。

**解决方案**：
1. 检查 `onFirstMeaningfulPaint` 是否正确注册。
2. 确认 `shouldInactive` 初始值为 `true`。
3. 确认 `onInactive()` 在回调中正确调用。
4. 确认页面使用的是http或https协议。

### 预渲染页面切换前台后不渲染

**现象**：预渲染完成后切换到前台，页面不再继续渲染。

**原因**：`shouldInactive` 未在 `aboutToAppear` 中重置为 `false`。

**解决方案**：在 `NodeController` 的 `aboutToAppear` 回调中将 `shouldInactive` 设为 `false`。

## 核心约束

- 预渲染完成后必须立即停止渲染，以防止发热和功耗问题。
