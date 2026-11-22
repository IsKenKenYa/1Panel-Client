# 悬停态 UI 适配模式

悬停形态的物理布局：上半屏（面向用户，适合内容展示）+ 折痕（不可交互带）+ 下半屏（近水平，适合操作区）。适配目标是**用最小状态切换实现上下分区的自然过渡**。

**方向无关性**：上下分区由折痕坐标锚定，适用于任何窗口方向。书本型折叠屏的悬停（笔记本形态）通常出现在**横屏窗口**（见第 8 节），不要把悬停布局写死为"仅竖屏"。

## 1. 通用设计原则

1. **单状态源**：一个 `@State isInHover` 驱动全部布局变化；回调只写状态位，不做布局计算（折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务，见第 4 节）。
2. **进出对称**：进入悬停态的过渡动画与退出动画互为逆过程，时长/曲线对称，避免"进去一种效果、出来另一种"的割裂感。
3. **状态幂等**：回调可能连续多次同值到达前做去抖（应用侧不依赖系统去重，虽然系统侧有状态翻转判断）。
4. **不可用不劣化**：非折叠屏、API 缺失、事件未触发时，保持原有单屏布局。
5. **下半屏人机工学**：下半屏近水平（桌面视角），操作元素按"桌面可达"设计——主按钮加大（demo 实测：快门 74→84vp）、点击区外扩、字号与间距上调一档。

## 2. 折痕区域处理（所有场景的公共前提）

```typescript
import { display } from '@kit.ArkUI';

// 优先 API 20+ 实时折痕，降级到静态折痕
function getCreaseRects(): Array<display.Rect> {
  try {
    const d = display.getDefaultDisplaySync();
    if (typeof d.getLiveCreaseRegion === 'function') {
      return d.getLiveCreaseRegion().creaseRects;
    }
  } catch (_) { /* 801 不支持 */ }
  try {
    return display.getCurrentFoldCreaseRegion().creaseRects;
  } catch (_) {
    return [];
  }
}
```

- 布局用 vp，折痕 `Rect` 是 px：`vp = px / display.getDefaultDisplaySync().densityPixels`（是**除以**，不是乘）。
- **坐标对齐前提**：折痕 rect 是 display 坐标，若窗口内容未铺满 display（如被状态栏避让区压缩），display 坐标 ≠ 窗口坐标。页面根组件用 `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` 铺满 display 后两者才可直换；否则需叠加避让区偏移。
- **存量页副作用警告**：给页面加 `expandSafeArea` 求坐标对齐的同时，会关掉系统对内容的自动避让——原本"自动让开状态栏/导航条"的存量 UI 会钻到系统栏下面。两者必须成对处理：加 `expandSafeArea` 就要按第 9 节补手动避让。
- 折痕 rect 取垂直中轴区域，可推导上下屏分界线：`creaseTop = creaseRects[0].top`，`creaseBottom = creaseRects[0].top + creaseRects[0].height`。
- 无折痕数据时按屏幕高度 50% 兜底。
- **折痕避让几何（真机三轮打磨定稿）**：
  - **内容封顶折痕区域上沿**（`contentHeight = creaseTop`），严格不进折痕区域——"内容延伸至折痕中心"实测会被用户视为压折痕，回退；
  - **避让带 = `max(折痕高/2 + 16, 16)`vp**：整段折痕区域做留白实测过大，折中为"覆盖折痕上半段 + 折痕中心线下方 16vp"——操作区从折痕中心线下方 16vp 起，落在下屏平缓区起点；
  - 带内不放可点击元素、不放文字（显示畸变区）。

## 3. 场景模式

### 3.1 视频/播放器（最常见）

- 悬停态：上半屏视频画面（等比缩放，居中于上屏），下半屏控制条 + 进度 + 选集。
- 实现：`Column` 两个具权重区块，`isInHover` 切换 layoutWeight 与对齐方式；播放器组件用 `objectFit: Contain` 防拉伸。
- 细节：进悬停态时若全屏手势布局，同步收起手势条；`window.setWindowKeepScreenOn` 保持亮屏。
- **需要横竖屏切换时**：按第 8 节实现布局状态（悬停上下分区 / 全屏浮层 / 常规），视频节点跨态复用不重建。

### 3.2 相机（悬停拍摄）

- 悬停态：上半屏取景器/成片预览，下半屏快门 + 模式切换；进入悬停可提示"设备已放稳，触控或定时拍摄"。
- **主按钮人机工学（下半屏近水平视角，必做）**：快门、录像/模式切换等主按钮在下半屏**加大并外扩点击区**——下半屏近水平、用户俯视触控，精度低于常规持握（真机实测：快门 74→84vp）；按钮间距同步上调，交互元素一律避开折痕避让带与系统栏。
- 细节：上半屏实时预览对分辨率敏感，切布局时避免销毁重建 XComponent/Surface——渲染节点进 if/else 分支会被销毁重建、Surface 重挂导致**预览黑屏**（真机踩坑）；保持同一渲染节点常驻，仅改布局参数（高度/`layoutWeight`）。
- 回调纪律：`postureCb` 内只切 `isInHover` 状态位，折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务，布局交给声明式 UI。

### 3.3 阅读/文档

- 上半屏正文，下半屏翻页控制/目录/进度；或上半屏文档、下半屏笔记输入（配合输入法避让 `avoidAreaChange`）。

### 3.4 通话/会议

- 上半屏对方画面/头像，下半屏静音、挂断、摄像头开关等大按钮（下半屏视角接近桌面，按钮可适当加大）。

### 3.5 通用内容型应用

- 不确定场景时，保守方案：上半屏内容不变，下半屏把原本悬浮/底部的操作区迁入，并隐藏不适用的全屏手势提示。

## 4. 布局实现骨架（ArkUI 声明式）

```typescript
@State isInHover: boolean = false;
@State creaseTopVp: number = 0;    // 折痕上沿（vp），内容封顶线
@State creaseHeightVp: number = 0; // 折痕高（vp），推导避让带

build() {
  // 三段式：高度全部由状态推导（函数见下方"三段式高度计算"）——渲染节点（Video/XComponent）
  // 不进 if/else 分支，跨态复用仅改数值化布局参数，形态切换不重建（见 8.5 与 10.1 审计第 2 条）
  Column() {
    // 上半屏：内容区（悬停 = 封顶折痕区域上沿；常规/全屏按产品形态）
    this.ContentArea()
      .height(this.contentHeightVp())
    // 折痕避让带：悬停 = max(折痕高/2 + 16, 16) 纯占位、不放交互/文字；其余 = 0
    Blank()
      .height(this.bandHeightVp())
    // 下半屏：操作区，layoutWeight(1) 吃掉剩余高度（等价 winHeight − 前两项）。
    // 主按钮（快门/播放/挂断等）悬停态加大并外扩点击区、间距上调——下半屏近水平视角
    // 触控精度低于常规持握（真机实测快门 74→84vp）
    this.ControlArea()
      .layoutWeight(1)
  }
  .width('100%').height('100%')
  .animation({ duration: 250, curve: Curve.EaseInOut }) // 进出对称过渡
}
```

要点：

- 形态切换用数值化布局参数 + 声明式 `animation` 过渡（勿用显式定时器；`animateTo` 也可，但 `animation` 修饰更易保证进出对称）；**渲染节点不进 if/else 分支**——进分支销毁重建 Surface 导致预览黑屏/播放中断（3.2 相机真机踩坑），确需结构差异（悬停固定坞 vs 常规 `Scroll` 兜底）时 if/else 只包非渲染节点。相机/自拍场景同时核对 3.2 人机工学：快门等主按钮加大并外扩点击区（真机实测 74→84vp），交互元素避开折痕避让带与系统栏。
- 事件回调里只改状态位（`isInHover`）；折痕/避让缓存复核经 `setTimeout(0)` 派发为回调外独立任务，布局交给声明式 UI。
- 折痕分界在进入悬停态后复核查询一次（不同折叠角度折痕区域可能变化；派发任务里做，不在回调内联查询）。

**三段式高度计算**（真机打磨版：全部由状态推导，布局函数内部做"悬停 > 产品状态"判断，无中间态特判）：

```typescript
// 内容区：悬停 = 封顶折痕区域上沿（内容避开折痕区域）；其余按产品形态（如 全屏 = winHeightVp、常规 = min(宽×比例, 高×比例)）
private contentHeightVp(): number {
  if (this.isHoverLayout()) {
    return this.creaseTopVp;
  }
  /* 产品自定义形态 */
}
// 折痕避让带：悬停 = max(折痕高/2 + 16, 16)；其余 = 0
// （整段折痕区域留白实测过大；折中覆盖折痕上半段 + 中心线下方 16vp，操作区落在下屏平缓区）
private bandHeightVp(): number {
  return this.isHoverLayout() ? Math.max(this.creaseHeightVp * 0.5 + 16, 16) : 0;
}
// 操作区：winHeightVp 减前两项，逐形态给值（悬停 = 折痕下方；常规 = 内容下方；全屏 = 0 由浮层替代）；
// 根容器 height('100%') 时可用 .layoutWeight(1) 吃掉剩余高度替代显式计算，二者等价
private controlHeightVp(): number { /* ... */ }
```

配套的完整状态机（`isFoldable` 门控、幂等回调、初始双查询、对称生命周期）见 `api-reference.md` 第二节完整示例；系统栏沉浸式与内容避让见第 9 节。

### 4.1 悬停操作区形态：固定操作坞，不是可滚动列表（真机定稿）

悬停态下半屏是**近水平的操作仪表盘**，用户视线在上屏、手在下屏——**固定呈现，不要上下拖动**：

- 悬停态渲染**独立固定操作坞**：控制元素一次性全部呈现（压缩垂直占用：砍元信息行、合并标题行，主操作行 + 横滚卡片两三行内搞定）；仅横向滚动（选集胶囊）可滚。
- 常规态保留 `Scroll` 兜底（横屏等紧凑场景内容可滚动）。
- 固定坞的成立前提是**内容预算不溢出**——见下条教训。

**溢出穿透 padding 教训（必看）**：固定高度的 `Column` 子项溢出时，**会穿过底部 padding 渲染到组件边缘（= 屏幕底边）**——`padding` 不是裁剪边界，溢出的元素照样可见且压住导航条。所以：

1. 固定坞内容行数做减法（能并一行不拆两行），确保总高 < 操作区高度；
2. 兜底方案：内容包 `Scroll`（溢出时可滚）+ 底部 `padding = 安全区 + 导航条高度`，此时 padding 是内容流内的间距，真实生效。

**HUD/徽标放置**：悬停状态徽标、折痕参数等验证性 HUD 放到**内容区左上角**（叠加在视频/取景器上，`position` 定位 + 状态栏高度避让），不占固定坞垂直空间。

**HUD 手势教训**：全高透明 HUD 容器（如 `Stack` 铺满视频区叠提示层）会**拦截手势**，导致底下 Swiper/Video 拖不动——HUD 用**小容器**（`position` 定位的胶囊/徽标）叠加，不要整面铺透明层。

## 5. 过渡与动画细节

- 推荐时长 200–300ms，`EaseInOut`；与系统布局动画叠加时取略短时长，避免"追不上"系统。
- `foldAngleChange`（API 12+）可用于角度驱动的连续过渡（可选增强，勿作为状态判据）。
- 退出悬停态若发生在动画中途，直接切换目标状态，不要队列化中间状态。

## 6. 降级模式下的行为差异

| 事项 | 标准路径 | 降级路径 |
| --- | --- | --- |
| 状态判据 | 系统综合判定（全屏/折痕/LS） | 仅 `HALF_FOLD` 折叠状态 |
| 非全屏窗口 | 不进入悬停态 | 可能误判进入 → 自查窗口属性再置位 |
| LS 态抑制 | 自动退出 | 感知不到 → 接受误差 |
| 初始状态 | `isInWindowPostureMode` 查询 | 启动时 `getFoldStatus()` 查询 |

降级路径下建议在 `windowSizeChange` 回调里复核"窗口仍全屏"，非全屏时强制清掉悬停态，减少误判。

## 7. 性能与体验红线

- 悬停回调、折痕查询都不要触发网络/磁盘/大量对象创建。
- 折痕 `Rect` 结果建议缓存，仅在状态切换后复核刷新（经 `setTimeout(0)` 派发为回调外独立任务，不在回调内联查询）。
- 避免在 `aboutToAppear` 之外重复注册监听；页面栈返回复用时确认监听仍有效。
- 不要用 hidumper/系统参数改变设备状态来实现"适配"效果——调试命令仅用于验证。

## 8. 窗口方向与三态布局（旋转策略）

真实设备形态空间是 `窗口方向 × 折叠姿态` 的组合。**悬停态的进入/退出与窗口方向相关（折痕方向性决定），但悬停布局本身与方向无关（由折痕坐标锚定）**。

### 8.1 折痕方向性（必读）

`DESKTOP_MODE` 要求折痕**横向**（creaseRect 宽 > 高，依据 `@ohos.window.d.ts` 枚举注释）：

- **书本型折叠屏**（Mate X / Z Fold 类，合上为竖长条）：折痕在**竖屏**方向为纵向、**横屏**方向为横向 → 悬停（笔记本形态，铰链水平）通常出现在**横屏窗口**。
- 推论：竖屏半折叠（书本形态，折痕纵向）系统**不会**进入悬停态——这是预期行为，应用侧不要自行推断"左右分区悬停"与系统判定打架（如确需适配该形态，走降级路径并明确告知用户风险）。

### 8.2 布局状态优先级

```
悬停（系统回调，最高） > 其余布局状态（按产品定义：全屏 > 常规，或 横屏全屏 > 竖屏常规）
```

```typescript
// 正确：悬停布局由系统状态一票决定，任何窗口方向下都生效
private isHoverLayout(): boolean {
  return this.isInHover;   // ✅
}

// 反模式（真机已踩坑）：按方向压制系统悬停状态
private isHoverLayout(): boolean {
  return this.isInHover && !this.isLandscape;  // ❌ 书本型设备悬停即横屏，此守卫导致横屏悬停布局永不切换
}
```

组合状态（`isInHover` × `isLandscape`）只用于**选择布局形态**（如横屏常规态收起底部控制区改浮层），不得用于**否定系统悬停状态**。

### 8.3 旋转的使能与感知（分离实现）

**使能**（允许窗口旋转）：

- 跟随系统旋转开关：`module.json5` → `"orientation": "auto_rotation_restricted"`。
- 2in1 设备方向 API 不可用：`deviceInfo.deviceType === '2in1'` 守卫（静态检查提示 "unavailable to 2in1"，运行时 no-op + catch）。

**全屏 × 旋转的两种产品形态（按需求选择，勿混用）**：

- **耦合模式**（常见于长视频应用）：全屏按钮调 `win.setPreferredOrientation(window.Orientation.LANDSCAPE)` 强制横屏，退出恢复 `AUTO_ROTATION_RESTRICTED`；横屏 = 全屏布局。
- **解耦模式**：全屏是纯布局状态位 `isFullscreen`（视频铺满 + 浮层控制），按钮只切状态、**不调方向 API**；旋转由系统开关驱动，只重排常规布局（视频高度按 `min(宽 × 9/16, 高 × 45%)` 适配任意方向），**不切全屏模式**。
- 两种模式下悬停态优先级均最高（见 8.2），悬停进出不改变用户的全屏偏好；悬停态下隐藏全屏入口（系统姿态优先）。

**感知**（应用侧知道当前方向）：

- 监听 `win.on('windowSizeChange')`，用**宽高比**判定：`isLandscape = widthVp > heightVp`（不要依赖方向事件——布局真正关心的是尺寸）。
- 初始值用 `win.getWindowProperties().windowRect`（真实窗口），而非 display 尺寸（近似值，可能与窗口差避让区）。

### 8.4 瞬态与双回调时序

旋转与折叠常同时发生，`windowSizeChange` 与 `postureModeChange` 的到达顺序**不保证**：

- 状态各自独立更新，以终态组合渲染，声明式 UI 自动收敛，不做中间态特判。
- 回调内只更新状态位；折痕缓存复核经 `setTimeout(0)` 派发为回调外独立任务；不做中间态特判、不排队布局状态。
- 退出悬停发生在过渡动画中途时直接切目标状态（见第 5 节）。

### 8.5 组件复用

各布局状态（常规 / 全屏 / 悬停）共用**同一**核心组件（Video / XComponent 等），仅改数值化的布局参数（高度/宽度 + `animation` 过渡），避免 if/else 分支重建导致播放中断或 Surface 销毁（与 3.2 相机场景"保持同一渲染节点"同源）。

## 9. 沉浸式系统栏与内容避让（悬停页工程配套）

折痕坐标对齐（`expandSafeArea`）只是前提；能上真机的悬停页还需要系统栏配方与内容避让，**两者成对出现**。

### 9.1 沉浸式配方（窗口级，整个应用设一次）

```typescript
// 深色沉浸式：系统栏透明 + 浅色图标；内容经 expandSafeArea 铺到系统栏下方
this.win.setWindowSystemBarProperties({
  statusBarColor: '#00000000',
  navigationBarColor: '#00000000',
  isStatusBarLightIcon: true,
  isNavigationBarLightIcon: true
}).catch(/* 运行时兜底日志 */);
this.win.setWindowKeepScreenOn(true); // 视频/相机类场景保持亮屏
```

- **归属**：这是窗口级设置，多页应用由入口页统一设置（同一主窗口持续生效），子页面不重复依赖设置顺序。
- 该 API 仅主窗口全屏/最大化时生效，子窗口不生效；2in1 设备静态检查提示 unavailable，运行时 catch 兜底即可。

### 9.2 内容避让原则：内容可沉浸，交互必须避让

- **内容区**（视频画面、相机取景器）允许延伸到系统栏下方——沉浸主体，`expandSafeArea` 铺满即可。
- **交互/HUD 元素**（返回键、快门、进度条、模式切换、标题）必须避让：顶部叠加状态栏高度，底部叠加导航指示条高度；px **除以** `densityPixels`。

```typescript
const sys = this.win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
this.statusBarHeightVp = sys.topRect.height / this.density();          // HUD 顶部避让
const nav = this.win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
this.navBarHeightVp = nav.bottomRect.height / this.density();          // 操作区底部避让
// 用法：HUD .padding({ top: 12 + statusBarHeightVp })；操作区 .padding({ bottom: 12 + navBarHeightVp })
```

### 9.3 避让高度必须动态刷新（一次性查询会过期，真机踩坑）

旋转、折叠/展开、进出悬停、全屏/分屏切换都会改变避让区尺寸（`avoidAreaChange` 官方触发场景即包含这些）——仅进页面时查询一次，之后内容会钻到系统栏下面。三层保险：

```typescript
private avoidCb: (opts: window.AvoidAreaOptions) => void = (opts: window.AvoidAreaOptions) => {
  if (opts.type === window.AvoidAreaType.TYPE_SYSTEM) {
    this.statusBarHeightVp = opts.area.topRect.height / this.density();
  } else if (opts.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
    this.navBarHeightVp = opts.area.bottomRect.height / this.density();
  }
};
// ① aboutToAppear（setupWindow）：getWindowAvoidArea 初始查询（见 9.2 代码，首帧避让依据）+ this.win.on('avoidAreaChange', this.avoidCb)
// ② windowSizeChange 触发的复核刷新经 setTimeout(0) 派发（旋转必触发）
// ③ postureCb 悬停触发的复核刷新经 setTimeout(0) 派发（进出悬停可能伴随系统栏变化）
// aboutToDisappear：this.win.off('avoidAreaChange', this.avoidCb) —— 与注册对称
```

- 横屏时导航指示条若在侧边无需处理：`expandSafeArea` 只展开上下边时，左右方向自动避开（页面宽度即窗口内容宽度）。

## 10. 存量页面适配工作流（改造既有页面）

对已存在的页面，**先审计再动手**；悬停是叠加态，适配后原有形态行为必须不变。

### 10.1 审计清单（写代码前逐项确认）

1. **结构切分点**：找到现有 UI 的"内容区 / 操作区"边界。不确定时用 3.5 保守方案：上半屏保留内容，把底部/悬浮操作区迁入下半屏。
2. **不可重建节点**：盘点 Video / XComponent / Canvas / WebView 等渲染节点。**不得把它们包进悬停的 if/else 分支**——分支切换即销毁重建（播放中断、Surface 闪黑）。正确做法：同一节点，仅高度/`layoutWeight` 等布局参数随状态变化（见 8.5）。
3. **既有布局状态**：盘点产品自有状态（手动全屏、横屏形态、弹层）。融合机制：`isHoverLayout()` 作为唯一出口函数（直接返回 `isInHover`），全部布局计算函数内部做"悬停 > 产品状态"的判断；**不得**在出口函数叠加方向等产品条件（8.2 反模式）。
4. **生命周期合并**：把悬停/尺寸/避让监听的注册与解注册并入已有 `aboutToAppear` / `aboutToDisappear`，保留原有清理逻辑（定时器、播放器释放等），不要整体覆盖。
5. **系统栏回归**：页面原本若靠系统自动避让（未铺满），加 `expandSafeArea` 后自动避让失效——必须成对补第 9 节手动避让，否则存量 UI 钻到系统栏下。

### 10.2 回归要求

- 常规/全屏/横屏等原有形态行为不变；悬停进出不影响用户已有偏好（如全屏状态位）。
- 产品侧布局参数可独立微调（如常规态内容高度比例），但悬停高度只认折痕，不与其他形态联动。
