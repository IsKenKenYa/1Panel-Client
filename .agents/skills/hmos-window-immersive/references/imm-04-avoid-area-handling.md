# 安全区域避让处理（IMM-04）

## 避让区类型（AvoidAreaType）

| 枚举值 | 说明 | 前置条件 | 获取方式 |
| --- | --- | --- | --- |
| TYPE_SYSTEM | 状态栏区域 | 无 | `getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)` |
| TYPE_NAVIGATION_INDICATOR | 底部导航区域。三键导航显示时始终存在，可通过 `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏 | 无 | `getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)` |
| TYPE_CUTOUT | 挖孔/刘海区域 | 无 | `getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT)` |
| TYPE_KEYBOARD | 软键盘区域 | 无 | `getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD)` |
| TYPE_FLOAT_NAVIGATION | 三键导航区域 | 需先调用 `setFloatNavigationAvoidAreaEnabled(true)` 启用，否则返回空（API 26.0.0+，仅 Stage 模型） | `getWindowAvoidArea(window.AvoidAreaType.TYPE_FLOAT_NAVIGATION)` |

### 底部导航与三键导航的关系

系统导航模式由用户在 **设置 > 系统 > 系统导航 > 更多设置** 中切换：

- **默认模式**：底部导航表现为**导航条**（底部小灰条），三键导航为关闭状态，此时三键导航区域不存在。
- **切换为三键导航栏模式**：三键导航区域存在（底部三个导航按键：返回、主页、最近任务），导航条隐藏，但**底部导航区域仍然存在**。

### 避让区返回 0 的场景

`getWindowAvoidArea()` 在以下场景返回 0：

| 场景 | 原因 | 解决方案 |
| --- | --- | --- |
| 系统栏被隐藏 | `setSpecificSystemBarEnabled('status', false)` 后状态栏避让区为 0 | 使用 `getWindowAvoidAreaIgnoringVisibility()`（API 22+）获取隐藏状态下的避让区 |
| 自由多窗模式 | 自由多窗模式下状态栏避让区为 0（分屏、智慧多窗悬浮窗不为 0） | 正常现象，无需处理 |
| 全局悬浮窗未使能 | 全局悬浮窗/模态窗/系统窗口未调用 `setSystemAvoidAreaEnabled(true)` | 先调用 `setSystemAvoidAreaEnabled(true)`（API 18+）使能 |

### getWindowAvoidAreaIgnoringVisibility（API 22+）

获取当前应用窗口的避让区域，**即使避让区域当前处于不可见状态**（系统栏被隐藏时仍可获取）。

```typescript
let type = window.AvoidAreaType.TYPE_SYSTEM;
try {
  let avoidArea = mainWindow.getWindowAvoidAreaIgnoringVisibility(type);
  // 即使状态栏已被 setSpecificSystemBarEnabled('status', false) 隐藏，
  // 仍可获取到状态栏的避让区高度
  const topHeight = avoidArea.topRect.height;
} catch (exception) {
  console.error(`Failed to obtain the area. Code: ${exception.code}, message: ${exception.message}`);
}
```

| 项 | 说明 |
| --- | --- |
| API 版本 | API 22+ |
| 系统能力 | SystemCapability.Window.SessionManager |
| 参数 | `type: AvoidAreaType`，不支持 `TYPE_KEYBOARD`（传入返回 1300016 错误码） |
| 返回值 | `AvoidArea`，窗口内容避让区域 |
| 全局悬浮窗/模态窗/系统窗口 | 需先调用 `setSystemAvoidAreaEnabled(true)` 使能后才能获取 |
| TV 设备 | 不显示状态栏，但调用该接口仍可获取状态栏对应的避让区域 |

> `getWindowAvoidArea()` 在系统栏隐藏时返回 0；`getWindowAvoidAreaIgnoringVisibility()` 在系统栏隐藏时仍返回实际避让区高度。

### TYPE_NAVIGATION_INDICATOR vs TYPE_FLOAT_NAVIGATION

| 对比维度 | TYPE_NAVIGATION_INDICATOR | TYPE_FLOAT_NAVIGATION |
| --- | --- | --- |
| 含义 | 底部导航区域 | 三键导航区域 |
| 外观 | 默认表现为底部导航条（小灰条）；切换三键导航后导航条隐藏但该区域仍存在 | 底部三个导航按键（返回、主页、最近任务） |
| 是否始终存在 | 三键导航显示时始终存在；可通过 `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏 | 默认关闭；切换三键导航后才存在；可通过 `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏 |
| 旋转跟随 | 跟随窗口/屏幕旋转，始终位于屏幕底部 | 某些设备上不跟随旋转（如直板机、部分可折叠设备的折叠形态） |
| 前置条件 | 无，直接可查询/监听 | 必须先调用 `setFloatNavigationAvoidAreaEnabled(true)`，否则返回空 |
| 系统能力 | SystemCapability.WindowManager.WindowManager.Core | SystemCapability.Window.SessionManager |
| 模型约束 | 无 | 仅 Stage 模型 |
| API 版本 | API 9+ | API 26.0.0+ |
| 典型用法 | 全屏沉浸式时避让底部导航区域 | 悬浮窗/自由窗应用避让底部三键 |
| 旋转适配 | 无需特殊处理，旋转后仍在底部 | 需注意旋转后三键可能不在底部，避让方向可能变化 |

### 导航条与三键不在同一方向时的避让

旋转后导航条始终在底部，但三键可能出现在左侧/右侧/顶部，两者可能**同时存在于不同方向**。此时不能简单取较大值，需独立计算各方向的 padding 后**合并**。

```typescript
import { window } from '@kit.ArkUI';

// 分别记录两种导航避让区的四个方向
interface AvoidPadding {
  top: number;
  bottom: number;
  left: number;
  right: number;
}

// 从 AvoidArea 提取四个方向的避让值（px）
// 统一采用「屏幕边缘到避让区内边缘」的计算方式，确保同方向多个避让区
// （如三键导航避让挖孔后位于挖孔外侧）Math.max 能正确取到更靠中心的值
const extractPadding = (area: window.AvoidArea): AvoidPadding => {
  const w = display.getDefaultDisplaySync().width;
  const h = display.getDefaultDisplaySync().height;
  return {
    top: area.topRect.height > 0 ? area.topRect.height + area.topRect.top : 0,
    bottom: area.bottomRect.height > 0 ? h - area.bottomRect.top : 0,
    left: area.leftRect.width > 0 ? area.leftRect.left + area.leftRect.width : 0,
    right: area.rightRect.width > 0 ? w - area.rightRect.left : 0,
  };
};

// 合并两个避让区：各方向取较大值
const mergePadding = (a: AvoidPadding, b: AvoidPadding): AvoidPadding => ({
  top: Math.max(a.top, b.top),
  bottom: Math.max(a.bottom, b.bottom),
  left: Math.max(a.left, b.left),
  right: Math.max(a.right, b.right),
});

// 监听变化，分别处理两种导航避让区
let navIndicatorPadding: AvoidPadding = { top: 0, bottom: 0, left: 0, right: 0 };
let floatNavPadding: AvoidPadding = { top: 0, bottom: 0, left: 0, right: 0 };

const onAvoidAreaChange = (data: window.AvoidAreaOptions): void => {
  if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    // 导航条：通常只有 bottomRect 有值，旋转后仍在底部
    navIndicatorPadding = extractPadding(data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_FLOAT_NAVIGATION) {
    // 三键：旋转后可能在 leftRect/rightRect/topRect，需全部检查
    floatNavPadding = extractPadding(data.area);
  }

  // 合并两种导航避让区 + 状态栏避让区，各方向独立取较大值
  const merged = mergePadding(navIndicatorPadding, floatNavPadding);
  // 还需合并 TYPE_SYSTEM 避让区（此处省略，同理 extractPadding）
  AppStorage.setOrCreate('avoidPadding', merged);
};
```

布局中使用合并后的 padding：

```typescript
@Entry
@Component
struct Index {
  @StorageProp('avoidPadding') avoidPadding: AvoidPadding = { top: 0, bottom: 0, left: 0, right: 0 };

  build() {
    Column() {
      // 页面内容
    }
    .padding({
      top: this.getUIContext().px2vp(this.avoidPadding.top),
      bottom: this.getUIContext().px2vp(this.avoidPadding.bottom),
      left: this.getUIContext().px2vp(this.avoidPadding.left),
      right: this.getUIContext().px2vp(this.avoidPadding.right),
    })
  }
}
```

> **关键要点**：导航条和三键可能同时存在于不同方向（如导航条在底部、三键在右侧），必须**独立提取各方向避让值后合并**（取较大值），不能简单只处理 bottom 方向。

## 查询避让区域

> `getWindowAvoidArea()` 返回的是调用时刻的避让区**快照**，不随窗口/设备状态变化自动更新。仅用于获取页面加载时的初始值；避让区变化必须通过 `on('avoidAreaChange')` 动态监听。

```typescript
const mainWindow = windowStage.getMainWindowSync();

// 查询状态栏避让区
const systemArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
const topHeight = systemArea.topRect.height;  // 状态栏高度（px）

// 查询导航条避让区
const navArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
const bottomHeight = navArea.bottomRect.height;  // 导航条高度（px）
```

### AvoidArea 结构

```typescript
interface AvoidArea {
  visible: boolean;
  leftRect: Rect;     // 左侧避让区
  topRect: Rect;       // 顶部避让区
  rightRect: Rect;     // 右侧避让区
  bottomRect: Rect;    // 底部避让区
}

interface Rect {
  left: number;    // px
  top: number;     // px
  width: number;   // px
  height: number;  // px
}
```

## 动态监听避让区变化

> **必须使用**：`getWindowAvoidArea()` 仅返回初始快照，避让区随窗口模式切换、旋转、折叠态切换等动态变化，必须通过 `on('avoidAreaChange')` 实时监听并更新布局。

```typescript
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

interface MainWindowInfo {
  avoidSystem: window.AvoidArea | null = null;
  avoidCutout: window.AvoidArea | null = null;
  avoidNavigationIndicator: window.AvoidArea | null = null;
  avoidKeyboard: window.AvoidArea | null = null;
  avoidFloatNavigation: window.AvoidArea | null = null;
}

const onAvoidAreaChange = (avoidOptions: window.AvoidAreaOptions): void => {
  if (avoidOptions.type === window.AvoidAreaType.TYPE_SYSTEM) {
    mainWindowInfo.avoidSystem = avoidOptions.area;
  } else if (avoidOptions.type === window.AvoidAreaType.TYPE_CUTOUT) {
    mainWindowInfo.avoidCutout = avoidOptions.area;
    updateAvoidPadding(avoidOptions.area);
  } else if (avoidOptions.type === window.AvoidAreaType.TYPE_KEYBOARD) {
    mainWindowInfo.avoidKeyboard = avoidOptions.area;
  } else if (avoidOptions.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    mainWindowInfo.avoidNavigationIndicator = avoidOptions.area;
  } else if (avoidOptions.type === window.AvoidAreaType.TYPE_FLOAT_NAVIGATION) {
    // 三键导航区域，需先调用 setFloatNavigationAvoidAreaEnabled(true) 启用（API 26.0.0+，仅 Stage 模型）
    mainWindowInfo.avoidFloatNavigation = avoidOptions.area;
  }
};

// 注册监听
mainWindow.on('avoidAreaChange', onAvoidAreaChange);

// 注销监听（必须成对调用）
mainWindow.off('avoidAreaChange', onAvoidAreaChange);
```

## 避让区变化触发场景

| 触发场景 | 说明 |
| --- | --- |
| 窗口模式切换 | 全屏 → 悬浮窗 / 分屏等 |
| 窗口旋转 | 设备方向变化导致避让区位置变化 |
| 折叠态切换 | 折叠 → 展开，屏幕尺寸变化 |
| 多设备流转 | 应用流转到不同设备 |

## 挖孔区避让

挖孔区尺寸可能随设备旋转、窗口模式切换等变化，需动态监听并避让。

### 挖孔方位计算

```typescript
import { display } from '@kit.ArkUI';

const updateAvoidPadding = (area: window.AvoidArea): void => {
  const avoidAreaPadding: Padding = {};
  try {
    // 顶部挖孔：顶部避让 = 挖孔区距屏幕顶部距离 + 挖孔区高度
    if (area.topRect.height > 0) {
      avoidAreaPadding.top = uiContext?.px2vp(area.topRect.height + area.topRect.top);
    }
    // 左侧挖孔：左侧避让 = 挖孔区距屏幕左侧距离 + 挖孔区宽度
    if (area.leftRect.width > 0) {
      avoidAreaPadding.left = uiContext?.px2vp(area.leftRect.left + area.leftRect.width);
    }
    // 右侧挖孔：右侧避让 = 屏幕宽度 - 挖孔区距屏幕左侧距离
    if (area.rightRect.width > 0) {
      avoidAreaPadding.right = uiContext?.px2vp(display.getDefaultDisplaySync().width - area.rightRect.left);
    }
    // 底部挖孔：底部避让 = 屏幕高度 - 挖孔区距屏幕顶部距离
    if (area.bottomRect.height > 0) {
      avoidAreaPadding.bottom = uiContext?.px2vp(display.getDefaultDisplaySync().height - area.bottomRect.top);
    }
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to set avoid padding. Code: ${err.code}, message: ${err.message}`);
  }
  mainWindowInfo.avoidAreaPadding = avoidAreaPadding;
};
```

### 挖孔避让完整流程

1. 使用 `ignoreLayoutSafeArea()` + `height(LayoutPolicy.matchParent)` 实现页面沉浸
2. 使用 `setSpecificSystemBarEnabled('status', false)` + `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏状态栏和导航条
3. 使用 `on('avoidAreaChange')` 监听 `TYPE_CUTOUT` 获取挖孔区域信息
4. 根据挖孔方位计算避让 padding
5. 设置组件 padding 进行避让

## 按需适配避让区

并非所有场景都需要适配全部避让区，开发者可按需只查询/监听某一个或某几个避让区类型。

### 场景一：只适配导航条避让区

常见于沉浸式布局，页面内容只需避让底部导航条。

```typescript
import { window } from '@kit.ArkUI';

const mainWindow = windowStage.getMainWindowSync();

// 1. 获取初始值（仅 TYPE_NAVIGATION_INDICATOR）
const navArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
AppStorage.setOrCreate('bottomHeight', navArea.bottomRect.height);

// 2. 监听导航条变化
mainWindow.on('avoidAreaChange', (data) => {
  if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    AppStorage.setOrCreate('bottomHeight', data.area.bottomRect.height);
  }
});
```

```typescript
@Entry
@Component
struct Index {
  @StorageProp('bottomHeight') bottomHeight: number = 0;

  build() {
    Column() {
      // 页面内容
    }
    .padding({
      bottom: this.getUIContext().px2vp(this.bottomHeight)  // 仅避让底部导航条
    })
  }
}
```

### 场景二：适配状态栏 + 导航条避让区

最常见的组合，页面顶部避让状态栏，底部避让导航条。

```typescript
// 1. 获取初始值
const systemArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
AppStorage.setOrCreate('topHeight', systemArea.topRect.height);

const navArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
AppStorage.setOrCreate('bottomHeight', navArea.bottomRect.height);

// 2. 监听两个避让区变化
mainWindow.on('avoidAreaChange', (data) => {
  if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
    AppStorage.setOrCreate('topHeight', data.area.topRect.height);
  } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    AppStorage.setOrCreate('bottomHeight', data.area.bottomRect.height);
  }
});
```

```typescript
@Entry
@Component
struct Index {
  @StorageProp('topHeight') topHeight: number = 0;
  @StorageProp('bottomHeight') bottomHeight: number = 0;

  build() {
    Column() {
      // 页面内容
    }
    .padding({
      top: this.getUIContext().px2vp(this.topHeight),       // 避让状态栏
      bottom: this.getUIContext().px2vp(this.bottomHeight)  // 避让导航条
    })
  }
}
```

### 场景三：适配状态栏 + 导航条 + 挖孔避让区

挖孔屏设备需要额外避让挖孔区域，挖孔方位随旋转变化。

```typescript
import { window, display } from '@kit.ArkUI';

interface AvoidPadding {
  top: number; bottom: number; left: number; right: number;
}

const EMPTY: AvoidPadding = { top: 0, bottom: 0, left: 0, right: 0 };

// 统一提取函数：所有避让区类型共用，采用「屏幕边缘到避让区内边缘」的计算方式
const extractPadding = (area: window.AvoidArea): AvoidPadding => {
  const w = display.getDefaultDisplaySync().width;
  const h = display.getDefaultDisplaySync().height;
  return {
    top: area.topRect.height > 0 ? area.topRect.height + area.topRect.top : 0,
    bottom: area.bottomRect.height > 0 ? h - area.bottomRect.top : 0,
    left: area.leftRect.width > 0 ? area.leftRect.left + area.leftRect.width : 0,
    right: area.rightRect.width > 0 ? w - area.rightRect.left : 0,
  };
};

const mergePadding = (a: AvoidPadding, b: AvoidPadding): AvoidPadding => ({
  top: Math.max(a.top, b.top),
  bottom: Math.max(a.bottom, b.bottom),
  left: Math.max(a.left, b.left),
  right: Math.max(a.right, b.right),
});

// 初始值
let systemP = extractPadding(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM));
let navP = extractPadding(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR));
let cutoutP = extractPadding(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT));
let floatNavP = extractPadding(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_FLOAT_NAVIGATION));

// 监听四种避让区（统一用 extractPadding 提取，mergePadding 各方向取较大值合并）
mainWindow.on('avoidAreaChange', (data) => {
  if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
    systemP = extractPadding(data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    navP = extractPadding(data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_CUTOUT) {
    cutoutP = extractPadding(data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_FLOAT_NAVIGATION) {
    floatNavP = extractPadding(data.area);
  }
  // 各方向取较大值合并
  const merged = mergePadding(mergePadding(mergePadding(systemP, navP), cutoutP), floatNavP);
  AppStorage.setOrCreate('avoidPadding', merged);
});
```

### 场景四：适配全部避让区

需同时处理状态栏、导航条、挖孔、键盘、三键导航，详见上文"导航条与三键不在同一方向时的避让"和"动态监听避让区变化"中的完整代码模板。

### 按需适配选型建议

| 需求 | 需查询/监听的避让区 | 适配方向 |
|------|-------------------|---------|
| 只避让底部 | TYPE_NAVIGATION_INDICATOR | bottom |
| 顶部 + 底部 | TYPE_SYSTEM + TYPE_NAVIGATION_INDICATOR | top + bottom |
| 挖孔屏设备 | TYPE_SYSTEM + TYPE_NAVIGATION_INDICATOR + TYPE_CUTOUT | top + bottom + left + right |
| 含三键导航设备 | 上述 + TYPE_FLOAT_NAVIGATION | top + bottom + left + right |
| 全部 | 所有 5 种 | top + bottom + left + right |

> **原则**：只查询/监听需要的避让区类型，避免不必要的监听开销。但只要监听了，`on/off` 就必须成对调用。

### 旋转等场景的避让区适配

旋转、折叠开合等场景下多种避让区会同时变化。`on('avoidAreaChange')` 每次回调只返回一种避让区类型，多次回调之间存在时间差，直接在每次回调中更新布局可能产生中间态。系统将在 7.1 版本提供一次性获取所有避让区变化的监听接口，届时可原生解决该问题。在此之前，推荐以下方式。

#### 方式一：通过 windowSizeChange 一次性获取全部避让区（推荐）

旋转和折叠开合会触发窗口尺寸变化，在 `on('windowSizeChange')` 回调中一次性查询所有避让区类型，合并后更新布局，确保各方向避让值同步更新。

```typescript
const types: window.AvoidAreaType[] = [
  window.AvoidAreaType.TYPE_SYSTEM,
  window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
  window.AvoidAreaType.TYPE_CUTOUT,
];

const refreshAllAvoidAreas = () => {
  let merged: AvoidPadding = { ...EMPTY };
  for (const type of types) {
    const area = mainWindow.getWindowAvoidArea(type);
    const padding = extractPadding(type, area);
    merged = mergePadding(merged, padding);
  }
  AppStorage.setOrCreate('avoidPadding', merged);
};

// 初始值
refreshAllAvoidAreas();

// 监听窗口尺寸变化（旋转、折叠开合、窗口模式切换等场景触发）
// 在回调中一次性查询全部避让区，确保各方向同步更新
mainWindow.on('windowSizeChange', () => {
  refreshAllAvoidAreas();
});
```

> `on('windowSizeChange')`（API 7+）在窗口拖动、缩放、旋转、折叠开合时触发，此时避让区已更新完毕，一次性查询可获取全部最新值。

#### 方式二：avoidAreaChange 回调中重新查询全部

对于非旋转场景的避让区变化（如系统栏显隐切换），使用 `on('avoidAreaChange')` 监听单个类型变化，在回调中重新查询全部避让区合并更新。

```typescript
mainWindow.on('avoidAreaChange', () => {
  refreshAllAvoidAreas();  // 同方式一的 refreshAllAvoidAreas
});
```

> 与方式一的区别：`avoidAreaChange` 在避让区变化时触发，但每次只通知一种类型，需重新查询；`windowSizeChange` 在窗口尺寸变化时触发，天然适合旋转/折叠场景。

#### 方式三：延迟合并更新

收到回调后不立即更新布局，用延时收齐同一批次的所有变化后合并更新。

```typescript
let updateTimer: number | null = null;

mainWindow.on('avoidAreaChange', (data) => {
  // 更新对应类型的缓存
  if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
    systemP = extractPadding(data.type, data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    navP = extractPadding(data.type, data.area);
  } else if (data.type === window.AvoidAreaType.TYPE_CUTOUT) {
    cutoutP = extractPadding(data.type, data.area);
  }

  // 延迟合并更新，收齐同一批次的所有变化
  if (updateTimer !== null) {
    clearTimeout(updateTimer);
  }
  updateTimer = setTimeout(() => {
    const merged = mergePadding(systemP, navP, cutoutP);
    AppStorage.setOrCreate('avoidPadding', merged);
    updateTimer = null;
  }, 50);  // 50ms 内收齐同一批次变化
});
```

> **推荐顺序**：
> - **方式一**（推荐）：通过 `windowSizeChange` 触发，天然适合旋转/折叠场景，一次查询确保各方向同步更新；
> - **方式二**：通过 `avoidAreaChange` 触发，每次回调查询全部类型，适合非旋转场景的避让区变化（如系统栏显隐切换）；
> - **方式三**：用延时收齐变化，避免重复查询但引入延迟。

#### 不使用以上方案的替代思路

**改用组件级方案（无需手动监听避让区）**

组件级方案（`.expandSafeArea()`、`.ignoreLayoutSafeArea()`）由系统自动处理避让，**完全不需要手动查询/监听避让区**，不存在中间态问题：

```typescript
// expandSafeArea：背景延伸，内容自动在安全区，系统自动适配旋转
Column() {
  Row() { Text('Top').width('100%') }
    .backgroundColor('#2786d9')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  // 中间内容...
  Row() { Text('Bottom').width('100%') }
    .backgroundColor('#96dffa')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
}
```

> 旋转时系统自动重新计算 expandSafeArea 的延伸区域，无需开发者监听。

**等待 7.1 版本原生接口**

系统将在 **7.1 版本**提供一次性获取所有避让区变化的监听接口，届时可原生解决中间态问题，无需任何额外处理。

**旋转期间锁定布局，旋转完成后一次性更新**

监听窗口尺寸变化，在旋转完成后再更新避让区：

```typescript
let isRotating = false;

mainWindow.on('windowSizeChange', () => {
  if (!isRotating) {
    isRotating = true;
    // 旋转过程中不更新布局，等待尺寸稳定后更新
    setTimeout(() => {
      refreshAllAvoidAreas();
      isRotating = false;
    }, 300);  // 等待旋转动画结束
  }
});
```

## 单一避让区 padding 避让方式

```typescript
@Entry
@Component
struct Index {
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;

  build() {
    Column() {
      // 页面内容
    }
    .padding({
      top: this.getUIContext().px2vp(this.topRectHeight),       // 避让状态栏
      bottom: this.getUIContext().px2vp(this.bottomRectHeight)  // 避让导航条
    })
  }
}
```

> 避让区返回值单位为 px，布局中使用需通过 `getUIContext().px2vp()` 转换为 vp。
> 避让区可能为 0，获取到 0 时需针对性处理，避免贴边/裁剪。
