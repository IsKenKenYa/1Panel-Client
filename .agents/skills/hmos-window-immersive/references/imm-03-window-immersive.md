# 窗口级沉浸实现（IMM-03）

## 场景一：沉浸式布局，不隐藏避让区

设置沉浸式布局（`setWindowLayoutFullScreen(true)`），布局不再避让状态栏和导航区域，界面元素延伸到状态栏和导航区域。通过 `getWindowAvoidArea()` 获取避让区域**初始值**，通过 `on('avoidAreaChange')` **动态监听**避让区域变化，两者配合用 padding 避让。

> **注意**：`setWindowLayoutFullScreen` 只改变布局是否避让系统栏，**不会改变窗口模式（全屏/悬浮/分屏），也不会改变窗口大小**。

> **推荐模式**：`getWindowAvoidArea()` 仅用于获取页面加载时的初始避让区高度；避让区会随窗口模式切换、旋转、折叠态变化等动态改变，必须用 `on('avoidAreaChange')` 监听并实时更新布局，否则旋转或折叠后会出现内容重叠。

### 步骤 1：设置沉浸式布局

```typescript
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return;
      }
      const mainWindow = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
      });
      // 后续步骤 2-3
    });
  }
}
```

### 步骤 2：获取避让区域初始值

```typescript
// getWindowAvoidArea 仅用于获取初始避让区高度，后续变化需靠 on('avoidAreaChange') 监听
// 获取导航条避让高度
let avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
const bottomRectHeight = avoidArea.bottomRect.height;
AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);

// 获取状态栏避让高度
avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
const topRectHeight = avoidArea.topRect.height;
AppStorage.setOrCreate('topRectHeight', topRectHeight);
```

### 步骤 3：动态监听避让区变化

避让区会随窗口模式切换、旋转、折叠态切换等动态改变，仅靠步骤 2 的初始值不够，必须注册监听实时更新。

```typescript
// on('avoidAreaChange') 是避让区变化时实时更新布局的关键
mainWindow.on('avoidAreaChange', (data) => {
  if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
    AppStorage.setOrCreate('topRectHeight', data.area.topRect.height);
  } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height);
  }
});
```

### 步骤 4：布局中避让

```typescript
@Entry
@Component
struct Index {
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageProp('topRectHeight') topRectHeight: number = 0;

  build() {
    Column() {
      // 页面内容
    }
    .width('100%').height('100%')
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)
    })
  }
}
```

### 步骤 5：设置系统栏样式（可选）

状态栏和导航区域默认透明，透传应用界面背景色。可按需设置文字颜色、背景色。

```typescript
mainWindow.setWindowSystemBarProperties({
  statusBarColor: '#00000000',           // 透明
  statusBarContentColor: '#FFFFFF',      // 状态栏文字/图标颜色
  navigationBarColor: '#00000000',
  navigationBarContentColor: '#FFFFFF',
}).catch((err: BusinessError) => {
  console.error(`Failed to set system bar properties. Code: ${err.code}, message: ${err.message}`);
});
```

### 步骤 6：查询是否处于沉浸式布局（可选）

通过 `isImmersiveLayout()` 查询当前窗口是否处于沉浸式布局：

```typescript
try {
  const isImmersive = mainWindow.isImmersiveLayout();
  console.info(`Is immersive layout: ${isImmersive}`);
} catch (exception) {
  console.error(`Failed to check immersive layout. Code: ${exception.code}, message: ${exception.message}`);
}
```

> `isImmersiveLayout()` 为同步接口，返回 boolean。API 20+，系统能力 SystemCapability.Window.SessionManager。

> 上述示例仅适配状态栏和导航条。如需适配挖孔、三键导航等更多避让区，或需按需选择适配组合，详见 [imm-04-avoid-area-handling.md](imm-04-avoid-area-handling.md) 中的"按需适配避让区"。

## 场景二：隐藏系统栏（游戏/视频全屏）

适用于游戏、电影等应用场景，只需隐藏状态栏和导航条，无需调用 `setWindowLayoutFullScreen`。用户可通过从底部上滑唤出导航条或三键导航。

```typescript
// 隐藏状态栏（无需 setWindowLayoutFullScreen）
mainWindow.setSpecificSystemBarEnabled('status', false).then(() => {
  console.info('Succeeded in setting the status bar to be invisible.');
}).catch((err: BusinessError) => {
  console.error(`Failed: Code is ${err.code}, message is ${err.message}`);
});

// 隐藏导航条
mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false).then(() => {
  console.info('Succeeded in setting the navigation indicator to be invisible.');
}).catch((err: BusinessError) => {
  console.error(`Failed: Code is ${err.code}, message is ${err.message}`);
});
```

隐藏后无需在界面中进行避让操作。

## 系统栏控制 API

| 接口 | 说明 | API 版本 |
| --- | --- | --- |
| setWindowLayoutFullScreen(isLayoutFullScreen: boolean): Promise\<void\> | 设置沉浸式布局（布局是否避让系统栏，不改变窗口模式和大小） | API 9+ |
| setImmersiveModeEnabledState(enabled: boolean): void | 同步设置沉浸式布局（与 setWindowLayoutFullScreen 结果一致） | API 12+ |
| setWindowSystemBarEnable(names: Array\<'status' \| 'navigation'\>): Promise\<void\> | 批量设置系统栏显隐（'navigation' 实际无效） | API 9+ |
| setSpecificSystemBarEnabled(name, enable, enableAnimation?): Promise\<void\> | 精细设置单个系统栏（'status'/'navigationIndicator'，enableAnimation API 12+） | API 11+ |
| setWindowSystemBarProperties(properties: SystemBarProperties): Promise\<void\> | 设置系统栏颜色、内容色 | API 9+ |

### setWindowSystemBarEnable vs setSpecificSystemBarEnabled

| 对比 | setWindowSystemBarEnable | setSpecificSystemBarEnabled |
| --- | --- | --- |
| 参数 | `Array<'status' \| 'navigation'>`（批量） | `(name: SpecificSystemBar, enable: boolean, enableAnimation?: boolean)`（单个） |
| 隐藏全部 | `setWindowSystemBarEnable([])` | 需调用两次（status + navigationIndicator） |
| 'navigation' 参数 | 无效 | 不支持该值（用 'navigationIndicator' 替代） |
| 动画控制 | 不支持 | `enableAnimation`（API 12+，默认 false） |
| API 版本 | API 9+ | API 11+ |
| 推荐场景 | 简单批量控制 | 精细控制单个系统栏（推荐） |

## 避让区变化触发场景

以下场景避让区会发生变化，需通过 `on('avoidAreaChange')` 动态监听：

- 应用窗口在全屏模式、悬浮模式、分屏模式之间切换
- 应用窗口旋转
- 多折叠设备在屏幕折叠态和展开态之间切换
- 应用窗口在多设备之间流转

> **可能收不到回调的场景**：
> - 避让区数据未变化时不重复回调（变化前后避让区数据相同则不触发）
> - 某些场景被解注册了（如组件销毁时 off 被调用）
> - 自由多窗模式下窗口不随屏幕旋转，旋转时避让区不变，不触发回调
> - 折叠开合过程中窗口模式未变化时（如始终分屏），避让区可能不变，不触发回调
> - 全局悬浮窗、模态窗、系统窗口未调用 `setSystemAvoidAreaEnabled(true)` 使能，收不到回调

## on/off 成对调用

> **注册时机**：建议在 `onWindowStageCreate` 中 `loadContent` 回调后注册监听，此时 window 对象已就绪。避免在组件生命周期（`aboutToAppear`/`aboutToDisappear`）中注册/注销，因为组件销毁时窗口可能也正在销毁，window 对象可能已无效，导致 `off` 调用失败或异常。

```typescript
// onWindowStageCreate 中注册（loadContent 回调后，window 对象已就绪）
onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', (err) => {
    if (err.code) return;
    const mainWindow = windowStage.getMainWindowSync();
    mainWindow.on('avoidAreaChange', onAvoidAreaChange);
  });
}

// onWindowStageDestroy 中注销（窗口销毁前，window 对象仍有效）
onWindowStageDestroy(): void {
  mainWindow?.off('avoidAreaChange', onAvoidAreaChange);
}
```

> 避让区返回值单位为 px，布局中使用需通过 `getUIContext().px2vp()` 转换为 vp。

> **避让区为 0 的场景**：系统栏被隐藏时 `getWindowAvoidArea()` 返回 0（需用 `getWindowAvoidAreaIgnoringVisibility()` API 22+ 获取隐藏状态下的避让区）；自由多窗模式下状态栏避让区为 0（分屏、智慧多窗悬浮窗不为 0）；全局悬浮窗需先调用 `setSystemAvoidAreaEnabled(true)` 使能后才能获取避让区。

> **三键导航避让区前置条件**：查询/监听 `TYPE_FLOAT_NAVIGATION` 避让区前，必须先调用 `setFloatNavigationAvoidAreaEnabled(true)`（API 26.0.0+，仅 Stage 模型），否则返回空。

> **setWindowLayoutFullScreen 不生效场景**：仅对主窗口和应用子窗口生效，其余窗口不生效也不报错。HarmonyOS 5.0.2 ~ 5.1.1 之前在自由窗口状态下不生效；5.1.1 起 PC/2in1 设备、电脑模式下不生效。返回成功不代表布局已变更完成。该接口只改变布局是否避让系统栏，不改变窗口模式和大小。

> **非全屏模式失效**：`setWindowSystemBarEnable`、`setSpecificSystemBarEnabled`、`setWindowSystemBarProperties` 在非全屏/最大化模式（自由悬浮窗、分屏等）下不生效，进入全屏后才生效。
