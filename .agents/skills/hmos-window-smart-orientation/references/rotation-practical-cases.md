# 旋转策略接入实战案例

## 案例 1：旋转策略配置适配差异化设备

设备形态多样（直板机、折叠机、三折叠、阔折叠、平板），按单一设备适配会导致其他设备体验下降。

**适配思路：**

1. **优先单一策略**：梳理业务诉求，若 `FOLLOW_DESKTOP`、`AUTO_ROTATION_UNSPECIFIED` 等单一策略能满足需求，直接使用，免适配；
2. **单一策略不满足时**：参考断点机制（`WidthBreakpoint`）差异化适配，屏蔽设备差异。

典型需求示例：三折叠设备折叠态/M 态竖屏、G 态横屏；平板横屏；直板机竖屏。用**宽度断点（600 边界值）+ 高宽比断点（0.8 边界值）**区分，折叠设备还需监听折叠状态变化：

```typescript
import { window } from '@kit.ArkUI'
import common from '@ohos.app.ability.common';
import { Callback } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State currentOrientation: string = 'UNSPECIFIED';
  private stage: window.WindowStage = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage;
  private foldDisplayModeCallback: Callback<display.FoldDisplayMode> = (data: display.FoldDisplayMode) => {
    this.getBreakPointAndSetOrientation();
  };

  aboutToAppear() {
    if (display.isFoldable()) {
      display.on('foldDisplayModeChange', this.foldDisplayModeCallback);
    } else {
      this.getBreakPointAndSetOrientation();
    }
  }

  aboutToDisappear() {
    display.off('foldDisplayModeChange', this.foldDisplayModeCallback); // 监听成对注销
  }

  private getBreakPointAndSetOrientation(): void {
    let displayInfo = display.getDefaultDisplaySync();
    let displayWidth = displayInfo.width;
    let displayHeight = displayInfo.height;
    let heightBp = displayHeight / displayWidth;
    if (displayWidth > displayHeight) {  // 统一成"短边为宽"再算断点
      const temp = displayWidth;
      displayWidth = displayHeight;
      displayHeight = temp;
    }
    // 600 为宽度断点边界值，0.8 为高宽比断点边界值
    if (displayWidth >= 600 && heightBp < 0.8) {
      this.stage.getMainWindowSync().setPreferredOrientation(window.Orientation.LANDSCAPE);
      this.currentOrientation = 'LANDSCAPE';
    } else {
      this.stage.getMainWindowSync().setPreferredOrientation(window.Orientation.PORTRAIT);
      this.currentOrientation = 'PORTRAIT';
    }
  }

  build() {
    Column() {
      Text(this.currentOrientation).fontSize(30).textAlign(TextAlign.Center)
    }.height('100%').width('100%')
  }
}
```

> 原则上支持横屏的应用，旋转策略应支持四方向可旋转（如 `AUTO_ROTATION_RESTRICTED`，可同时获得智感旋转体验）；上例固定方向仅为演示断点用法。

## 案例 2：视频类应用横竖屏切换

详情页竖屏显示，点击全屏按钮切横屏。两种实现方式：

**方式一：运行时设置旋转策略（推荐）**

```typescript
// 进入全屏：立即临时旋转到横屏（USER_ROTATION 系列，之后仍跟随传感器，OH 7.0.0+ 支持智感旋转）
mainWindow.setPreferredOrientation(window.Orientation.USER_ROTATION_LANDSCAPE);

// 退出全屏：恢复竖屏或自动旋转
mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED);
```

**方式二：页面跳转**：跳转到 target 页面，在目标页面对应的 module.json5 ability（或页面加载时）配置不同方向，通过页面切换带动横竖屏切换。

## 案例 3：屏幕方向和窗口 orientation 的相互转换

**概念区分（易错点）：**

- 屏幕 orientation（`display.orientation`，逻辑横竖状态）、屏幕 rotation（`display.rotation`，物理角度）、窗口 orientation（`RotationChangeInfo.orientation`）三者关联但不同；
- 多设备形态下（折叠屏、平板、外接显示器）屏幕 rotation 与 orientation 并非一一对应；
- **不能**直接用 `display.rotation`/`display.orientation` 判断窗口实际方向，否则可能显示方向错位。

直板机对应关系：

| 屏幕角度 | 屏幕方向 | 窗口方向 |
| --- | --- | --- |
| 0 | PORTRAIT | PORTRAIT |
| 90 | LANDSCAPE | LANDSCAPE_INVERTED |
| 180 | PORTRAIT_INVERTED | PORTRAIT_INVERTED |
| 270 | LANDSCAPE_INVERTED | LANDSCAPE |

三折叠全展开态对应关系（某些特性下可能不一致，以实际表现为准）：

| 屏幕角度 | 屏幕方向 | 窗口方向 |
| --- | --- | --- |
| 90 | PORTRAIT | PORTRAIT |
| 180 | LANDSCAPE | LANDSCAPE_INVERTED |
| 270 | PORTRAIT_INVERTED | PORTRAIT_INVERTED |
| 0 | LANDSCAPE_INVERTED | LANDSCAPE |

**四步转换法**（如视频播放页锁定当前方向）：

1. `display.getDefaultDisplaySync().orientation` 获取屏幕方向；
2. `convertOrientationAndRotation(DISPLAY_ORIENTATION, WINDOW_ORIENTATION, ...)` 转为窗口方向数字（0竖/1反横/2反竖/3横）；
3. 数字映射为 `window.Orientation` 枚举（0→PORTRAIT，1→LANDSCAPE_INVERTED，2→PORTRAIT_INVERTED，3→LANDSCAPE）；
4. `setPreferredOrientation()` 锁定方向。

```typescript
import { display, window } from '@kit.ArkUI';

setOrientationByDisplay() {
  try {
    // 1.获取当前默认 Display 的屏幕方向
    const disp = display.getDefaultDisplaySync();
    const displayOrientation = disp.orientation;

    // 2.屏幕方向 → 窗口方向数字
    const windowOrientation: number =
      this.mainWindow.convertOrientationAndRotation(
        window.RotationInfoType.DISPLAY_ORIENTATION,
        window.RotationInfoType.WINDOW_ORIENTATION,
        displayOrientation
      );

    // 3.窗口方向数字 → window.Orientation 枚举
    let orientation: window.Orientation = window.Orientation.UNSPECIFIED;
    switch (windowOrientation) {
      case 0: orientation = window.Orientation.PORTRAIT; break;
      case 1: orientation = window.Orientation.LANDSCAPE_INVERTED; break;
      case 2: orientation = window.Orientation.PORTRAIT_INVERTED; break;
      case 3: orientation = window.Orientation.LANDSCAPE; break;
      default: throw new Error('Invalid orientation value');
    }

    // 4.设置旋转策略锁定窗口方向
    this.mainWindow.setPreferredOrientation(orientation, (err) => {
      if (err && err.code) {
        console.error('setPreferredOrientation failed: ' + JSON.stringify(err));
      }
    });
  } catch (exception) {
    console.error('Exception: ' + JSON.stringify(exception));
  }
}
```

## 旋转接口行为限制速查

| 场景 | 行为 |
| --- | --- |
| 主窗口全屏显示 | 改变策略**立即生效**（不满足时立刻触发旋转动效，即使与握持角度不一致） |
| 主窗口未全屏 | 不立即生效，进入全屏后生效（`setPreferredOrientationWithResult` 返回 PENDING） |
| 分屏、智慧多窗悬浮窗 | 系统强制竖屏布局，策略被忽略（接口正常调用、方向不变，返回 IGNORED） |
| 自由多窗 | 强制小窗显示，策略被忽略 |
| 多任务、应用后台 | 策略被忽略，退出该场景后按策略重新调整 |
| 无传感器设备（TV 等） | 接口可调用，方向不变 |
| 非主窗口（子窗口等） | 设置不生效不报错（OH 6.1+ 例外：TYPE_WALLET_SWIPE_CARD 系统窗口） |

## 布局适配提示

- 旋转影响屏幕上**所有可见元素**（桌面、状态栏、下拉控制中心/通知中心等），通过一个旋转动画过渡；
- 应用窗口宽高比与屏幕 Orientation 无直接关系，**布局适配基于窗口尺寸变化**：`on('windowSizeChange')` 或 `@Env` 窗口尺寸变量，勿基于屏幕 Orientation。
