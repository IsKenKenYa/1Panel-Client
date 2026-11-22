# 应用侧 API 参考（窗口悬停态）

依据 foundation/window/window_manager master 分支 NAPI/ANI 实现与 interface_sdk-js 社区 master d.ts 核验（2026-10）。

## 一、API 可用性核验（写代码前必做）

悬停态 API（`WindowPostureMode` 系列）在窗口管理仓已有 NAPI/ANI 绑定实现，但**截至 2026-10 未进入 OpenHarmony 社区 master 的 `@ohos.window.d.ts`**。因此：

1. 在目标工程的 SDK 目录中检索声明：
   ```bash
   # DevEco/SDK 目录下
   grep -r "WindowPostureMode" <SDK路径>/ets/api/  # ArkTS 1.2 模块也可能在 hms 或 arkts-1.2 目录
   ```
2. 找到声明 → 使用"标准路径"（第二节）；未找到 → 使用"降级路径"（第四节）。
3. 真机核验（SDK 有声明但设备系统未必支持）：调用 `isInWindowPostureMode` 前先 `try/catch`，且以 `display.isFoldable()` 为前置条件。

## 二、标准路径：WindowPostureMode 系列

均为 **window 实例方法**（注意：不是 `on(type)` 泛型事件），当前仅支持 `DESKTOP_MODE`。

### 枚举

```typescript
enum WindowPostureMode {
  DESKTOP_MODE = 0  // 桌面/悬停形态（半折叠）
}
```

### 查询当前状态（同步）

```typescript
isInWindowPostureMode(mode: WindowPostureMode): boolean
// 返回 true：窗口当前处于悬停态
// 错误：1300002（窗口未创建/已销毁）、401（参数错误，仅接受 DESKTOP_MODE）
```

### 注册/解注册监听

```typescript
onWindowPostureModeChange(mode: WindowPostureMode, callback: Callback<boolean>): void
offWindowPostureModeChange(mode: WindowPostureMode, callback?: Callback<boolean>): void
// callback 参数 boolean：true 进入悬停态，false 退出
// off 不传 callback 时解注册该 mode 下全部监听
```

### 完整示例（真机打磨版状态机骨架）

```typescript
import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct HoverAdaptPage {
  // ===== 悬停态：单状态源 =====
  @State isInHover: boolean = false;
  @State isFoldable: boolean = false;   // 非折叠屏：不注册监听，保持常规布局
  @State creaseTopVp: number = 0;       // 折痕上沿（vp），内容区封顶线
  @State creaseHeightVp: number = 0;    // 折痕高（vp），推导避让带 max(折痕高/2 + 16, 16)
  @State winHeightVp: number = 640;     // 窗口高度（vp），常规布局参数随窗口重算
  private winWidthVp: number = 360;
  private win?: window.Window;

  // 悬停回调：只切状态位（回调内不做折痕查询等同步重活），布局交给声明式 UI；
  // 折痕缓存复核经 setTimeout(0) 派发为回调外独立任务（不同折叠角度折痕会变）——
  // 回调立即返回不阻塞事件链，状态切换先用缓存值渲染、复核后声明式 UI 自动修正
  private postureCb: (isInHover: boolean) => void = (isInHover: boolean) => {
    if (isInHover === this.isInHover) {
      return; // 幂等守卫
    }
    this.isInHover = isInHover; // 回调内只切状态位
    setTimeout(() => {
      if (isInHover) {
        this.refreshCrease(); // 回调外独立任务里复核折痕缓存
      }
    }, 0);
  };

  // 尺寸回调：旋转/窗口变化重算常规态布局参数（方向无关，宽高比由尺寸自然表达）
  private sizeCb: (size: window.Size) => void = (size: window.Size) => {
    this.applyWindowSize(size.width, size.height);
  };

  aboutToAppear(): void {
    try {
      this.isFoldable = display.isFoldable();
      const d = display.getDefaultDisplaySync();
      this.applyWindowSize(d.width, d.height); // display 兜底初值
      if (this.isFoldable) {
        this.refreshCrease();
      }
    } catch (e) {
      this.isFoldable = false; // display API 不可用：按非折叠屏处理，不劣化
    }
    this.setupWindow();
  }

  aboutToDisappear(): void {
    try {
      this.win?.offWindowPostureModeChange(window.WindowPostureMode.DESKTOP_MODE, this.postureCb);
      this.win?.off('windowSizeChange', this.sizeCb);
    } catch (e) {
      console.error(`unregister failed: ${(e as BusinessError).code}`);
    }
  }

  private async setupWindow(): Promise<void> {
    try {
      // 注意：getLastWindow 需要 BaseContext；严格 ArkTS 下 UIContext 不继承 BaseContext，
      // 必须经 getHostContext() 取宿主 Context，直接传 this.getUIContext() 编译不过
      const ctx = this.getUIContext().getHostContext();
      if (!ctx) {
        return;
      }
      this.win = await window.getLastWindow(ctx);
      // 真实窗口尺寸精确初始化（display 是近似值，可能与窗口差避让区）
      const rect = this.win.getWindowProperties().windowRect;
      this.applyWindowSize(rect.width, rect.height);
      if (this.isFoldable) {
        // 初始状态查询（进入页面时可能已在悬停态）
        try {
          this.isInHover = this.win.isInWindowPostureMode(window.WindowPostureMode.DESKTOP_MODE);
        } catch (e) {
          console.error(`isInWindowPostureMode failed: ${(e as BusinessError).code}`);
        }
        // window 实例方法 onWindowPostureModeChange(mode, cb)，不是 win.on(type, cb)
        this.win.onWindowPostureModeChange(window.WindowPostureMode.DESKTOP_MODE, this.postureCb);
      }
      this.win.on('windowSizeChange', this.sizeCb);
      // 系统栏沉浸式配方与内容避让（avoidAreaChange 动态刷新）：
      // 见 adaptation-patterns.md 第 9 节 —— 沉浸式悬停页必配，勿只做悬停不避让
    } catch (e) {
      const err = e as BusinessError;
      console.error(`setupWindow failed: ${err.code}, ${err.message}`);
    }
  }

  // 常规态布局参数：公式必须竖屏/横屏窗口通用（旋转只重排，不切模式）
  private applyWindowSize(widthPx: number, heightPx: number): void {
    const density: number = this.density();
    this.winWidthVp = widthPx / density;
    this.winHeightVp = heightPx / density;
    // 例：this.normalContentHeightVp = Math.min(this.winWidthVp * 9 / 16, this.winHeightVp * 0.55);
  }

  private density(): number {
    try {
      return display.getDefaultDisplaySync().densityPixels;
    } catch (e) {
      return 3; // 兜底密度：主流设备 3x
    }
  }

  // 折痕：实时（API 20+）→ 静态（API 10+）→ 屏幕中线兜底；px 除以 densityPixels
  private refreshCrease(): void {
    let d: display.Display;
    try {
      d = display.getDefaultDisplaySync();
    } catch (e) {
      return; // 查询失败保持当前值，不劣化
    }
    let crease: display.Rect | undefined = undefined;
    try {
      crease = d.getLiveCreaseRegion().creaseRects[0];
    } catch (e) { /* 801 不支持 */ }
    if (crease === undefined) {
      try {
        crease = display.getCurrentFoldCreaseRegion().creaseRects[0];
      } catch (e) { /* 不支持 */ }
    }
    if (crease !== undefined) {
      this.creaseTopVp = crease.top / d.densityPixels;
      this.creaseHeightVp = crease.height / d.densityPixels;
    } else {
      this.creaseTopVp = d.height / d.densityPixels / 2; // 中线兜底
      this.creaseHeightVp = 0;
    }
  }

  // 悬停布局与窗口方向无关（书本型设备悬停通常即横屏），出口函数不加方向守卫
  private isHoverLayout(): boolean {
    return this.isInHover;
  }

  build() {
    // 三段式布局：内容区（悬停封顶 creaseTopVp）+ 折痕避让带（creaseHeightVp 纯占位）
    // + 操作区（剩余空间），高度计算见 adaptation-patterns.md 第 4 节
  }
}
```

**多页应用归属**：窗口级设置（系统栏/亮屏，见 adaptation-patterns.md 第 9.1 节）由入口页统一做一次；各功能页独立注册/解注册悬停与尺寸监听。router push 时前页不销毁（`aboutToDisappear` 不触发），同窗多组监听并存是安全的——回调只写各自页面状态，无跨页干扰。

### 常见错误

| 现象 | 原因 |
| --- | --- |
| 调用抛 401 | 传了非 DESKTOP_MODE 枚举值，或把方法当 `on(type, cb)` 用 |
| 注册成功但从不回调 | 窗口非全屏/设备非半折叠/系统侧条件不满足（见 wms-internals.md） |
| 回调只在部分折叠角度触发 | 正常现象：fold status 稳定为 HALF_FOLD 才判定 |

## 三、配套 API（社区已公开，API level 以 d.ts 为准）

| API | 版本 | 用途 |
| --- | --- | --- |
| `display.isFoldable(): boolean` | 10 | 前置判断：设备是否折叠屏 |
| `display.getFoldStatus(): FoldStatus` | 10 | 查询折叠状态；`FOLD_STATUS_HALF_FOLDED = 3` |
| `display.on('foldStatusChange', cb)` / `off` | 10 | 折叠状态变化事件 |
| `display.on('foldAngleChange', cb)` / `off` | 12 | 折叠角度变化（角度区间可用于过渡动画） |
| `display.getCurrentFoldCreaseRegion(): FoldCreaseRegion` | 10 | 当前显示模式下的折痕区域 |
| `display.getDefaultDisplaySync().getLiveCreaseRegion(): FoldCreaseRegion` | 20 | 实时折痕区域（悬停判定同源数据，优先用） |
| `win.on('windowSizeChange')` / `off` | — | 窗口尺寸变化：**旋转/全屏的方向感知**（宽高比判定横竖屏）、布局参数重算 |
| `win.getWindowProperties().windowRect` | — | 初始窗口尺寸（px），初始化方向/布局参数用（比 display 尺寸精确） |
| `win.setWindowSystemBarProperties(props)` | 9 | 沉浸式系统栏（透明 + 浅色图标）；仅主窗口全屏/最大化时生效；**2in1 提示 unavailable，运行时 catch** |
| `win.setWindowKeepScreenOn(boolean)` | 9 | 视频/相机类场景保持亮屏 |
| `win.getWindowAvoidArea(type): AvoidArea` | 9 | 查询系统栏避让区（`TYPE_SYSTEM` 状态栏 / `TYPE_NAVIGATION_INDICATOR` 导航指示条），px **除以** density |
| `win.on('avoidAreaChange', cb)` / `off` | 9（回调形态 12 起为 `AvoidAreaOptions { type, area }`） | 避让区变化事件；官方触发场景含**窗口旋转、折叠/展开切换**——一次性查询会过期，须动态刷新（见 adaptation-patterns.md 第 9 节） |
| `win.setPreferredOrientation(orientation)` / `window.Orientation` 枚举 | 9 | 手动全屏/锁定方向（`LANDSCAPE`、`AUTO_ROTATION_RESTRICTED` 等）；**2in1 不可用**，需 deviceType 守卫 |
| `deviceInfo.deviceType`（@kit.BasicServicesKit） | — | 2in1 设备守卫（方向类 API 运行时 no-op） |
| `display.getDefaultDisplaySync().densityPixels` | 7 | px → vp 换算（**除以**） |
| `expandSafeArea`（ArkUI 组件方法） | 10 | 页面铺满 display（内容不被避让区压缩），保证折痕 px 与窗口 vp 坐标可直换 |

`FoldCreaseRegion` 结构：

```typescript
interface FoldCreaseRegion {
  readonly displayId: number;
  readonly creaseRects: Array<Rect>;  // Rect { left, top, width, height }，单位 px
}
```

系统 API（仅系统应用可用，普通应用不要依赖）：`display.setFoldStatusLocked`（11）、`sceneSessionManager.notifyLSStateChange`。

## 四、降级路径（目标 SDK 无 WindowPostureMode 时）

用公开的折叠状态 + 折痕区域 API 自行推断，覆盖大部分场景（差异：无法感知 LS 态等系统侧抑制条件，见 wms-internals.md 第 4 节）。

```typescript
import { display, window } from '@kit.ArkUI';

class HoverDetector {
  private isInHover = false;
  private readonly cbList: Array<(inHover: boolean) => void> = [];

  constructor(win: window.Window) {
    display.on('foldStatusChange', (status: display.FoldStatus) => this.evaluate(status));
    this.evaluate(display.getFoldStatus()); // 启动初始状态查询
    // 全屏自查（降级必备）：应用侧感知不到系统的全屏判定，在 windowSizeChange
    // 回调里复核窗口仍全屏，非全屏时强制清除悬停态，减少误判
    win.on('windowSizeChange', (size: window.Size) => {
      if (this.isInHover &&
        win.getWindowProperties().windowMode !== window.WindowMode.WINDOW_MODE_FULLSCREEN) {
        this.isInHover = false;
        this.cbList.forEach(cb => cb(false));
      }
    });
  }

  private evaluate(status: display.FoldStatus) {
    // 降级推断：半折叠即视为悬停（应用侧无法复现全屏/折痕/LS 的完整系统判定）
    const newHover = status === display.FoldStatus.FOLD_STATUS_HALF_FOLDED;
    if (newHover === this.isInHover) {
      return;
    }
    this.isInHover = newHover;
    this.cbList.forEach(cb => cb(newHover));
  }

  onHoverChange(cb: (inHover: boolean) => void) {
    this.cbList.push(cb);
    cb(this.isInHover);
  }
}
```

降级路径注意事项：

- 折痕区域仍用 `getCurrentFoldCreaseRegion()` / `getLiveCreaseRegion()`（后者 API 20+，需判空降级）获取。
- `getLiveCreaseRegion` 在设备不支持时抛 801，调用需 try/catch。
- 单位为 px，与 vp 布局换算需**除以** `densityPixels`。
- **全屏自查**：`windowSizeChange` 回调里复核窗口仍全屏（`windowMode` 为 `WINDOW_MODE_FULLSCREEN`），非全屏时强制清除悬停态——降级路径感知不到系统侧全屏判定。

## 五、API 声明位置索引（窗口管理仓内）

| 层 | 文件 |
| --- | --- |
| 枚举定义 | `interfaces/innerkits/wm/wm_common.h`（`enum class WindowPostureMode`） |
| Native 接口 | `interfaces/innerkits/wm/window.h`（`GetWindowHoverState`、`IWindowHoverStateChangeListener`） |
| NAPI 绑定 | `interfaces/kits/napi/window_runtime/window_napi/js_window.cpp`（`IsInWindowPostureMode`、`On/OffWindowPostureModeChange`，绑定名 `isInWindowPostureMode` 等） |
| NAPI 监听分发 | `interfaces/kits/napi/window_runtime/window_napi/js_window_register_manager.cpp`（`ProcessWindowPostureModeChangeRegister`） |
| NAPI 回调桥接 | `interfaces/kits/napi/window_runtime/window_napi/js_window_listener.cpp`（`OnWindowHoverStateChange`，JS 事件名 `windowPostureChange`） |
| ANI 绑定 | `interfaces/kits/ani/window_runtime/window_stage_ani/src/ani_window.cpp`（native 函数 `isInWindowPostureMode` 等，模块 `@ohos.window.window`） |
