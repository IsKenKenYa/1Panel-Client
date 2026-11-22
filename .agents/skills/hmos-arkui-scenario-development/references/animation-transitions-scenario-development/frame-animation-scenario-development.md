# 帧动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 加载/呼吸动画 | `createAnimator` + `onFrame` + `direction:'alternate'` | 需要逐帧计算活跃元素索引；alternate 自动反转 |
| 多段串行动画 | 多个 `AnimatorResult` + `delay` + `onFinish` 链式 | 精确控制每段开始时机和结束时触发下一段 |
| 骨架屏 Shimmer | `iterations:-1` + `linear` + 全局 `onFrame` | 单动画器驱动整页所有占位块同步扫动 |
| 扫描线往复 | `direction:'alternate'` + `onRepeat` 翻转 | 上下往复扫描 + 反转时翻转装饰元素 |
| 复杂展开/收起 | 双向复用 `AnimatorResult` + 自定义 progress 函数 | 8+ 属性分阶段联动，`onFrame` 逐帧精确控制 |

## 核心动画 API 枚举值参考

### createAnimator 参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `duration` | number | 单次动画时长（ms） |
| `iterations` | number | 播放次数，-1 表示无限循环 |
| `begin` | number | 动画起始值 |
| `end` | number | 动画结束值 |
| `easing` | string | 缓动曲线名称 |
| `delay` | number | 动画延迟时间（ms），默认 0 |
| `direction` | string | 动画播放方向，默认 `'normal'` |
| `fill` | string | 动画填充模式，默认 `'none'` |

### direction 播放方向枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `'normal'` | 正向播放（begin→end） | 加载动画、进度条 |
| `'reverse'` | 反向播放（end→begin） | 倒计时效果 |
| `'alternate'` | 正反交替（begin→end→begin） | 脉冲呼吸、扫描线上下往复 |
| `'alternate-reversed'` | 反正交替（end→begin→end） | 从大到小的呼吸效果 |

### fill 填充模式枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `'none'` | 不填充，动画结束后回到初始值 | 一次性动画 |
| `'forwards'` | 保持最后一帧状态 | 骨架屏 Shimmer、交叉淡入 |
| `'backwards'` | 动画延迟期间显示第一帧 | delay 期间保持起始状态 |
| `'both'` | 同时应用 forwards 和 backwards | 完整保留首尾帧 |

### easing 缓动曲线字符串值

| 字符串值 | 说明 | 典型场景 |
|---|---|---|
| `'linear'` | 线性匀速 | 骨架屏高光扫动 |
| `'ease'` | 通用缓动 | 播放器展开/收起 |
| `'ease-in'` | 缓入 | 元素离开 |
| `'ease-out'` | 缓出 | 涟漪扩散、文字上移 |
| `'ease-in-out'` | 缓入缓出 | 通用过渡 |
| `'friction'` | 摩擦减速 | 绿色圆形弹出、勾号弹出 |
| `'extreme-deceleration'` | 极度减速 | 需要强烈减速效果 |
| `'sharp'` | 急剧变化 | 快速进入效果 |
| `'rhythm'` | 节奏弹跳 | 弹跳节奏效果 |
| `'smooth'` | 平滑过渡 | 平滑曲线 |

### AnimatorResult 方法

| 方法 | 说明 |
|---|---|
| `.play()` | 开始播放动画 |
| `.cancel()` | 取消动画并重置到初始状态 |
| `.finish()` | 直接完成动画跳到最终状态 |
| `.pause()` | 暂停动画 |
| `.reset()` | 重置动画到初始状态 |
| `onFrame` 回调 | 每帧触发，参数为当前帧值 |
| `onFinish` 回调 | 动画完全结束时触发 |
| `onRepeat` 回调 | 每次重复播放时触发 |

### Curve 枚举值（帧动画常用）

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `Curve.LinearOutSlowIn` | 出场快入场慢 | 播放器手势释放后的弹动归位 |
| `Curve.Ease` | 通用缓动 | 播放器快速收起 |
| `Curve.EaseInOut` | 慢-快-慢 | 通用过渡 |

---

## 场景1：加载动画

**场景描述：** 三种常见 Loading 样式：① 五个圆点依次弹跳起伏的跳动加载；② 系统圆形进度旋转指示器；③ 脉冲圆环从中心向外扩散的呼吸效果。点击按钮同时启动三种动画。

**解决方案：** 使用 **`AnimatorResult(createAnimator)`** + **`onFrame` 逐帧回调** + **`direction:'alternate'` 反向**

### 步骤 1：圆点跳动 — onFrame 计算活跃点

```ts
const dotAnimator = createAnimator({
  duration: 2000,
  iterations: 1,
  begin: 0,
  end: 1
})
dotAnimator.onFrame = (progress) => {
  const cycleProgress = progress * 4 * 5  // 5 dots * 4 cycles
  const activeIndex = Math.floor(cycleProgress) % 5
  this.dotScales = Array.from({ length: 5 }, (_, i) => i === activeIndex ? 1.5 : 1)
  this.dotOpacities = Array.from({ length: 5 }, (_, i) => i === activeIndex ? 1 : 0.3)
}
```

### 步骤 2：脉冲圆环 — alternate 方向

```ts
const pulseAnimator = createAnimator({
  duration: 1000,
  direction: 'alternate',
  iterations: 6,
  begin: 1,
  end: 1.5
})
pulseAnimator.onFrame = (value) => { this.pulseScale = value }
```

---

## 场景2：成功打勾

**场景描述：** 仿支付成功页，点击按钮后依次出现：绿色圆形从中心弹出 → 勾号在圆中画出 → 一圈涟漪向外扩散 → "支付成功"文字从下方上移淡入，四段动画串行衔接。

**解决方案：** 使用 **四个 `AnimatorResult` 串行 delay + `onFinish` 链式触发** + **`easing:'friction'` 弹出** + **涟漪扩散**

### 步骤 1：绿色圆形弹出

```ts
createAnimator({ duration: 400, easing: 'friction', delay: 100, begin: 0, end: 1 })
.onFrame = (v) => { this.circleScale = v; this.circleOpacity = v }
```

### 步骤 2：勾号弹出（delay 400ms）

```ts
createAnimator({ duration: 300, easing: 'friction', delay: 400, begin: 0, end: 1 })
.onFrame = (v) => { this.checkScale = v; this.checkOpacity = v }
.onFinish = () => { /* 触发涟漪 */ }
```

### 步骤 3：涟漪扩散

```ts
createAnimator({ duration: 600, easing: 'ease-out', begin: 1, end: 1.5 })
.onFrame = (v) => { this.rippleScale = v; this.rippleOpacity = 2 - v }
```

### 步骤 4：文字上移（delay 700ms）

```ts
createAnimator({ duration: 400, easing: 'ease-out', delay: 700, begin: 20, end: 0 })
.onFrame = (v) => { this.textOffsetY = v; this.textOpacity = 1 - v / 20 }
```

---

## 场景3：骨架屏Shimmer

**场景描述：** 仿社交 Feed 流加载占位，数据加载中时显示灰色骨架占位块（头像、标题行、正文行），每个占位块内各有一道高光同步从左到右循环扫过产生闪烁效果；加载完成后骨架与真实内容交叉淡入切换，Shimmer 扫动同步停止。

**解决方案：** 使用 **`AnimatorResult` 无限循环 `linear` 水平扫动驱动全局 `shimmerTranslateX`** + **`linearGradient` 5 档透明度高光条带** + **可复用 `@Builder shimmerLine/shimmerSquare`** + **`.clip(true)` 裁剪防溢出** + **`Stack` 双层交叉淡入 + 独立 `fadeAnimator` 单次驱动**

### 步骤 1：Shimmer 扫动动画 — 无限循环 createAnimator [核心]

> 动画引擎本体。创建 `iterations: -1` 的 `shimmerAnimator`，`onFrame` 驱动全局 `shimmerTranslateX` 供所有占位块共享。

`showLoading()` 创建 `iterations: -1` 的 `shimmerAnimator`，`begin/end` 为 -350/350（超出组件宽度的左右边界），`onFrame` 将值赋给全局 `shimmerTranslateX` 供所有占位块共享。每次调用前先 `cancel` 旧动画器避免叠加。

```ts
@State shimmerTranslateX: number = -350
@State skeletonOpacity: number = 1
@State contentOpacity: number = 0
private shimmerAnimator: AnimatorResult | undefined = undefined

showLoading() {
  if (this.shimmerAnimator) { this.shimmerAnimator.cancel(); }
  this.skeletonOpacity = 1;
  this.contentOpacity = 0;

  this.shimmerAnimator = this.getUIContext().createAnimator({
    duration: 1500, easing: 'linear', fill: 'forwards',
    iterations: -1, begin: -350, end: 350
  });
  this.shimmerAnimator.onFrame = (value: number) => {
    this.shimmerTranslateX = value;
  };
  this.shimmerAnimator.play();
}
```

关键点：
- `iterations: -1` 无限循环 + `easing: 'linear'` 匀速，保证高光扫动节奏均匀无加速/减速感
- `begin: -350, end: 350` 超出组件宽度，使高光从左侧屏外滑入、右侧屏外滑出，避免边缘突现/突消失
- 所有占位块共享同一个 `shimmerTranslateX`，单动画器驱动整页所有占位块同步扫动
- `aboutToDisappear` 中将 `shimmerAnimator` 置为 `undefined`，防止页面销毁后动画器泄漏

### 步骤 2：Shimmer 高光条带 — 可复用 @Builder + linearGradient [辅助]

> 纯 UI 布局。定义 `@Builder shimmerLine/shimmerSquare`，用 `linearGradient` 5 档透明度构造高光条带，`.translate({ x })` 绑定步骤 1 的状态变量。无动画逻辑。

每个骨架占位块是一个 `Stack` 叠加两层：灰色底色层 + 高光渐变层。高光层使用 5 档 `linearGradient`（两侧完全透明、中心半透明白），通过 `.translate({ x: shimmerTranslateX })` 跟随扫动。封装为 `shimmerLine`（矩形）和 `shimmerSquare`（方形/圆形）两个 `@Builder` 复用。

```ts
@Builder shimmerLine(width: Length, height: Length, radius: number) {
  Stack() {
    // 灰色占位底色
    Column().width(width).height(height).borderRadius(radius).backgroundColor('#e0e0e0')

    // 高光渐变层 — 5 档透明度形成窄条高光
    Column()
      .width(width).height(height).borderRadius(radius)
      .linearGradient({
        angle: 90,
        colors: [
          ['#00ffffff', 0],      // 完全透明
          ['#00ffffff', 0.35],   // 过渡起点
          ['#33ffffff', 0.5],    // 高光中心（20% 白）
          ['#00ffffff', 0.65],   // 过渡终点
          ['#00ffffff', 1]       // 完全透明
        ]
      })
      .translate({ x: this.shimmerTranslateX })   // 跟随全局扫动
  }
  .width(width).height(height)
  .clip(true)    // 裁剪：高光超出占位块范围的部分不可见
}
```

骨架布局由多个 `shimmerLine`/`shimmerSquare` 组合而成：

```ts
Column() {
  Row() {
    this.shimmerSquare(60, 30)                    // 头像占位（圆形）
    Column() {
      this.shimmerLine(140, 14, 7)                // 标题占位
      this.shimmerLine(100, 12, 6)               // 副标题占位
    }
  }
  this.shimmerLine('90%', 16, 8)                  // 正文行占位
  this.shimmerLine('75%', 16, 8)
  this.shimmerLine('85%', 16, 8)
  /* ... */
}
.opacity(this.skeletonOpacity)
```

关键点：
- 5 档渐变中 `0.35→0.5→0.65` 构成仅 30% 宽度的窄条高光，两侧 `0→0.35` 和 `0.65→1` 完全透明，使高光看起来像一道光带而非整面发亮
- `angle: 90` 使渐变沿水平方向（从左到右），配合 `translate({ x: shimmerTranslateX })` 产生水平扫动效果
- `.clip(true)` 裁剪 Stack 边界：高光层在 `translate` 过程中超出占位块尺寸的部分被裁掉，保证高光只在占位块范围内可见
- `shimmerLine` 和 `shimmerSquare` 仅参数不同（后者宽高一致），同一套 Stack 双层结构复用于所有占位形状

### 步骤 3：加载完成 — 停止 Shimmer + 交叉淡入 [核心]

> 动画驱动。先 `cancel` 销毁 `shimmerAnimator` 停止扫动，再创建单次 `fadeAnimator`，`onFrame` 中同步驱动双层 opacity 互补变化实现交叉淡入。

`showContent()` 先 `cancel` 并销毁 `shimmerAnimator`（停止扫动），再创建单次 `fadeAnimator` 驱动 `contentOpacity` 从 0→1、`skeletonOpacity` 从 1→0，实现骨架与真实内容的交叉淡入。骨架层和真实内容层在 `Stack` 中叠加，分别绑定各自的 opacity。

```ts
showContent() {
  // 停止 Shimmer 扫动
  if (this.shimmerAnimator) {
    this.shimmerAnimator.cancel();
    this.shimmerAnimator = undefined;
  }

  // 交叉淡入：单次动画器驱动双层 opacity
  this.fadeAnimator = this.getUIContext().createAnimator({
    duration: 400, easing: 'ease-out', fill: 'forwards',
    iterations: 1, begin: 0, end: 1
  });
  this.fadeAnimator.onFrame = (value: number) => {
    this.contentOpacity = value;        // 真实内容 0 → 1
    this.skeletonOpacity = 1 - value;   // 骨架屏 1 → 0
  };
  this.fadeAnimator.play();
}
```

布局上骨架层和真实内容层通过 `Stack` 叠加，分别绑定 opacity：

```ts
Stack() {
  Column() { /* 骨架占位块 */ }.opacity(this.skeletonOpacity)
  Column() { /* 真实内容（头像、文字、图片） */ }.opacity(this.contentOpacity)
}
```

关键点：
- `showContent` 中先 `cancel` + 置 `undefined` 彻底销毁 `shimmerAnimator`，防止交叉淡入期间高光仍在扫动造成视觉干扰
- `fadeAnimator` 使用 `iterations: 1` 单次播放 + `ease-out` 曲线，骨架快速消失、真实内容平滑浮现
- `onFrame` 中 `contentOpacity = value` 和 `skeletonOpacity = 1 - value` 在同一回调中同步更新，保证两层透明度始终互补（和为 1），无缝交叉
- `Stack` 叠加两层而非 `if/else` 条件渲染：交叉淡入期间两层同时可见且 opacity 互补，避免切换瞬间的空白闪烁

---

## 场景4：自定义扫码

**场景描述：** 仿扫码界面，屏幕中央显示方形扫码框，框内一道蓝色扫描线上下往复扫动，扫描线上方有菱形光斑跟随并缩放呼吸，四角有装饰角标标定识别区域。

**解决方案：** 使用 **`AnimatorResult` + `direction:'alternate'` 上下扫动** + **`onRepeat` 翻转阴影** + **`.position()` 扫描线/角标定位**

### 步骤 1：扫描线动画 [核心]

> 动画引擎本体，`onFrame` 逐帧驱动扫描线位置与阴影缩放，`onRepeat` 翻转菱形角度。

```ts
const scanAnimator = createAnimator({
  duration: 2000,
  direction: 'alternate',
  iterations: -1,
  begin: 0,
  end: 100  // SCAN_AREA 高度
})
scanAnimator.onFrame = (value) => {
  const normalized = value / 100
  this.linePosition = SCAN_AREA * normalized
  // 阴影缩放：前半段放大，后半段缩小
  this.shadowScale = normalized < 0.389
    ? 0.5 + normalized * 2
    : 0.5 + (1 - normalized) * 2
}
scanAnimator.onRepeat = () => {
  this.scanAngle = this.scanAngle === 0 ? 180 : 0
}
```

### 步骤 2：布局 — 扫描框 + 角标 + 扫描线 [辅助]

> 纯 UI 布局，`.position()` 定位元素并绑定步骤 1 的状态变量。

```ts
Stack() {
  // 四角角标
  Image($r('app.media.scan_corner')).position({ x: 0, y: 0 })
  // ...
  // 扫描线
  Row().width('80%').height(2)
    .backgroundColor('#4facfe')
    .position({ x: '10%', y: this.linePosition })
  // 阴影菱形
  Text().width(60).height(60)
    .scale({ x: this.shadowScale, y: this.shadowScale })
    .rotate({ angle: this.scanAngle })
    .position({ x: '35%', y: this.linePosition - 30 })
}
.width(200).height(200)
.clip(true)
```

---

## 场景5：迷你播放器

**场景描述：** 仿音乐播放器，页面底部有一条迷你播放器栏显示封面和歌曲名，点击后迷你播放器无缝展开为全屏播放详情页（封面从左上角放大移至屏幕中央、详情页从底部滑入），在详情页向下拖拽可实时跟随收起，松手后根据位置阈值决定弹回或完全收起。

**解决方案：** 使用 **`AnimatorResult` 双向复用 + 自定义 `expandCollapseAnimation(progress)` 逐帧多属性联动** + **双封面图层切换** + **两阶段 opacity 交替** + **`PanGesture.onActionUpdate` 手势实时驱动 + `onActionEnd` + `animateTo` 阈值判断**

### 步骤 0：页面环境与常量体系 [核心]

> 动画距离的基数取决于页面布局。BAR_HEIGHT 是最关键的常量——它决定了迷你播放器悬于底部 Tab 栏之上而非贴底，直接影响 miniDistanceToBottom/miniDistanceToTop/miniImgToDetailsPageImgDistance 三个距离参数的计算。遗漏 BAR_HEIGHT 将导致整个距离体系偏移，动画轨迹与预期不符。

**页面层级（zIndex 从低到高）：**

| 层 | zIndex | 内容 | 高度 |
|---|---|---|---|
| 推荐页 | 0 | Search + Banner + 歌单 Grid | 全屏 |
| 底部 Tabs | 5 | 首页 / 排行 / 我的 | BAR_HEIGHT(56) |
| 迷你播放器 | 10 | 封面 + 歌曲名 + 播放/下一曲控件 | MINI_HEIGHT(56) |
| 详情页 | 20 | 深色背景 + 封面放大 + 播放控件 + PanGesture | 全屏 |

**全部常量：**

| 常量 | 值 | 作用 | 遗漏后果 |
|---|---|---|---|
| MINI_HEIGHT | 56 | 迷你播放器行高 | — |
| **BAR_HEIGHT** | **56** | **底部 Tab 栏高度** | **miniDistanceToBottom 偏移，距离体系崩塌** |
| MINI_IMG_SIZE | 40 | 迷你播放器封面尺寸 | — |
| DETAILS_PAGE_IMG_SIZE | 260 | 详情页封面尺寸 | — |
| MINI_IMG_MARGIN_LEFT | 12 | 封面左边距 | 封面水平偏移计算偏差 |
| MINI_IMG_RADIUS | 4 | 封面圆角 | 迷你/详情圆角不一致 |
| ANIMATION_PROGRESS | 0.3 | 两阶段 opacity 分界 | — |
| stackHeight 初始值 | 800 | onAreaChange 前的合理默认 | 首帧位置异常 |
| stackWidth 初始值 | 360 | onAreaChange 前的合理默认 | 首帧位置异常 |

**距离参数计算（BAR_HEIGHT 的影响）：**

```
miniDistanceToBottom = MINI_HEIGHT + BAR_HEIGHT           // 56 + 56 = 112（两栏高度之和）
miniDistanceToTop    = stackHeight - miniDistanceToBottom  // 展开垂直距离
miniImgToDetailsPageImgDistance = miniDistanceToTop        // AnimatorResult 的 end 值
miniPlayerY          = stackHeight - MINI_HEIGHT - BAR_HEIGHT  // 迷你播放器悬于 Tabs 之上
```

若 `BAR_HEIGHT = 0`：miniDistanceToBottom 从 112 变成 56，迷你播放器贴底而非悬于 Tabs 上方，展开距离基数偏移约 56px，封面放大和详情页上移轨迹与预期不符。

**推荐页必须有真实内容**，为迷你播放器提供视觉锚点：Search 组件 + Banner 图 + 歌单 Grid。Scroll 底部 padding 设为 `MINI_HEIGHT + BAR_HEIGHT`，防止内容被迷你播放器和 Tabs 遮挡。

**详情页必须使用深色主题**（backgroundColor: `#1a1a2e`，文字 fontColor: `Color.White` / `'#cccccc'`）。深色背景让封面、白色文字和图标视觉对比强烈；浅色背景（如 `#f5f5f5`）对比弱，封面放大效果视觉冲击力大打折扣。

### 步骤 1：双图层布局 — Stack 层叠 + 双封面图切换 [核心]

> 整个动画的架构基础。双封面图策略（静态封面 + 动画封面通过 opacity 交叉切换）决定了后续所有动画的状态设计。

使用 `Stack` 将迷你播放器（zIndex 10）和详情页（zIndex 20）叠加在页面内容之上。封面图采用**双实例策略**：迷你播放器内的静态封面（`miniImgOpacity` 控制）和详情页内的动画封面（`miniImgAnimateOpacity` 控制）是两个独立 `Image`，展开时前者淡出、后者淡入并放大，避免同一元素同时绑定两套布局约束。

**收起态下详情页必须定位到屏幕外**（`position y = stackHeight + 100`），而非依赖 `opacity = 0` 隐藏。因为 `zIndex(20)` 的详情页即使 `opacity = 0` 仍参与命中测试，会拦截下方迷你播放器的 `onClick`。将其物理位移到屏幕下方后，两层触摸区域不再重叠，从根本上避免拦截。

```ts
@State miniPlayerOpacity: number = 1
@State miniImgOpacity: number = 1          // 迩你播放器内静态封面
@State miniImgAnimateOpacity: number = 0   // 详情页内动画封面
@State miniImgOffsetX: number = 0          // 封面水平偏移（向屏幕中心靠拢）
@State miniImgOffsetY: number = 0          // 封面垂直偏移（驱动值，0→distance）
@State miniImgOffsetSize: number = 0       // 封面尺寸增量（0→220px）
@State detailsPageOpacity: number = 0
@State detailsPagePositionY: number = 0
@State detailsPageTopOpacity: number = 1   // 详情页顶部导航栏透明度
@State miniPlayerY: number = 0
@State miniChangeHeight: number = 0

// aboutToAppear：首帧前将两层都踢到屏外，等待 onAreaChange 拿到真实尺寸后再归位
aboutToAppear() {
  this.detailsPagePositionY = 9999
  this.miniPlayerY = 9999
}

@Builder miniPlayer() {
  Row() {
    Image(/* 封面 */)
      .width(MINI_IMG_SIZE).height(MINI_IMG_SIZE)
      .opacity(this.miniImgOpacity)       // 静态封面：展开时淡出
      .margin({ left: MINI_IMG_MARGIN_LEFT + this.miniImgOffsetX + this.miniImgOffsetSize })
    /* 歌曲名、控件按钮等 */
  }
  .height(MINI_HEIGHT + this.miniChangeHeight)   // 高度随展开收缩
  .opacity(this.miniPlayerOpacity)
  .position({ x: 0, y: this.miniPlayerY })
  .zIndex(10)
}

@Builder detailsPage() {
  Column() {
    Row() { /* 顶部导航栏 */ }.opacity(this.detailsPageTopOpacity)
    Image(/* 封面 — 动画副本 */)
      .width(MINI_IMG_SIZE + this.miniImgOffsetSize)    // 从 40px 放大到 260px
      .height(MINI_IMG_SIZE + this.miniImgOffsetSize)
      .opacity(this.miniImgAnimateOpacity)               // 展开时淡入
      .margin({ left: MINI_IMG_MARGIN_LEFT + this.miniImgOffsetX })
    /* 歌曲信息、播放控件等 */
  }
  .opacity(this.detailsPageOpacity)
  .position({ x: 0, y: this.detailsPagePositionY })
  .zIndex(20)
}
```

`onAreaChange` 在首次布局后归位两层：

```ts
.onAreaChange((oldValue: Area, newValue: Area) => {
  this.stackHeight = newValue.height as number
  this.stackWidth = newValue.width as number
  if (!this.isExpand && !this.isAnimating) {
    this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT
    this.detailsPagePositionY = this.stackHeight + 100   // 详情页推到屏幕下方100px
  }
})
```

关键点：
- 双封面图策略是本场景的核心：静态封面受 `miniImgOpacity` 控制保持在迷你播放器原位，动画封面受 `miniImgAnimateOpacity` + `miniImgOffsetSize` + `miniImgOffsetX` 驱动进行放大和居中，两者通过 opacity 交叉切换
- `miniImgOffsetSize` 叠加到 `Image` 的 `width`/`height` 上（`MINI_IMG_SIZE + offsetSize`），实现从 40px 到 260px 的连续放大
- `miniImgOffsetX` 叠加到 `margin.left` 上，使封面从左边缘逐渐移动到屏幕水平中心
- `onAreaChange` 在页面首次布局时捕获 `stackHeight`/`stackWidth` 真实尺寸，用于后续所有位置计算
- **收起态详情页定位在屏幕外**（`stackHeight + 100`）：`zIndex(20)` 的详情页即使 `opacity = 0` 仍参与命中测试，若停留在可视区域内会拦截迷你播放器的触摸事件。定位到屏幕下方后两层触摸区域不再重叠，无需 `hitTestBehavior` 或条件渲染即可正常点击
- `aboutToAppear` 中将两层初始 `position` 设为 `9999`（远超屏幕），避免 `onAreaChange` 触发前的首帧出现位置错误的闪烁
- **推荐页 Scroll 底部 padding** 设为 `MINI_HEIGHT + BAR_HEIGHT`，防止内容被迷你播放器和 Tabs 遮挡
- **底部 Tabs 栏**（zIndex:5, barHeight:BAR_HEIGHT）必须存在，迷你播放器定位在其上方而非贴底；忽略 BAR_HEIGHT 将导致距离计算全部偏移
- **详情页深色主题**（`#1a1a2e`）让封面和白色文字对比强烈，浅色主题对比弱、封面放大效果不明显

### 步骤 2：多属性联动动画函数 — expandCollapseAnimation(progress) [核心]

> 动画算法核心。接收 0→1 进度值，单次调用同步更新 8+ 状态变量，在 progress = 0.3 处分两阶段控制 opacity 交替。

该函数接收 0→1 的进度值，在单次调用中同步更新 8+ 个状态变量。核心策略是在 `progress = 0.3` 处分两阶段：前 30% 迷你播放器淡出 + 详情页上移；后 70% 详情页完全可见 + 封面继续放大居中。

```ts
private expandCollapseAnimation(progress: number) {
  // 封面尺寸增量：0 → (260-40) = 220px
  this.miniImgOffsetSize = (DETAILS_IMG_SIZE - MINI_IMG_SIZE) * progress;
  // 封面水平偏移：向屏幕中心靠拢
  this.miniImgOffsetX =
    ((this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2 - MINI_IMG_MARGIN_LEFT) * progress;

  if (progress < ANIMATION_PROGRESS) {   // ANIMATION_PROGRESS = 0.3
    // 阶段 1：迷你播放器淡出，详情页仍不可见但位置已开始上移
    this.detailsPageOpacity = 0;
    this.miniPlayerOpacity = 1 - progress / ANIMATION_PROGRESS;
    this.detailsPagePositionY = this.stackHeight - this.miniImgOffsetY - this.miniDistanceToBottom;
  } else {
    // 阶段 2：迷你播放器完全隐藏，详情页显现并主导
    this.miniPlayerOpacity = 0;
    this.detailsPageOpacity = 1;
    let detailsPageOffsetY = this.miniDistanceToTop * progress -
      (this.miniDistanceToTop - this.miniImgToDetailsPageImgDistance) * ANIMATION_PROGRESS *
      ((1 - ANIMATION_PROGRESS) - (progress - ANIMATION_PROGRESS)) / (1 - ANIMATION_PROGRESS);
    this.detailsPagePositionY = this.stackHeight - detailsPageOffsetY - this.miniDistanceToBottom;
  }
  // 迷你播放器位置与高度跟随
  this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT - this.miniImgOffsetY;
  this.miniChangeHeight = this.miniImgOffsetY;

  // 详情页顶部导航栏：到达屏幕上半部分时淡入
  this.detailsPageTopOpacity =
    this.detailsPagePositionY <= this.stackHeight / 2
      ? 1 - this.detailsPagePositionY / (this.stackHeight / 2) : 0;
}
```

关键点：
- `miniImgOffsetY` 是全局驱动值（由动画器或手势直接赋值），`expandCollapseAnimation` 读取它而非自行计算，保证动画器与手势两条路径的状态一致
- 阶段 1（progress < 0.3）：`miniPlayerOpacity` 从 1 线性降到 0，`detailsPageOpacity` 保持 0（详情页不可见但位置已从屏幕下方开始上移），避免详情页过早显现造成视觉突兀
- 阶段 2（progress >= 0.3）：`miniPlayerOpacity` 锁定为 0，`detailsPageOpacity` 切换为 1（详情页显现），使用独立的 `detailsPageOffsetY` 公式继续上移至 `y = 0`
- `detailsPageTopOpacity` 在详情页进入屏幕上半区时才开始淡入，避免导航栏过早出现造成视觉干扰
- 封面的 `offsetSize` 和 `offsetX` 在整个 0→1 区间线性插值，与两阶段 opacity 无关，保证封面连续平滑放大

### 步骤 3：双向 AnimatorResult — 展开与收起复用同一动画器 [核心]

> 动画驱动入口。创建 `AnimatorResult`，`onFrame` 中通过 `isExpand` 区分方向调用步骤 2 函数，`doExpand()` / `doCollapse()` 计算距离参数并启动动画。**doExpand 和 doCollapse 必须是独立方法**，两者在封面图层切换策略上有本质差异。

单个 `AnimatorResult` 以 `begin: 0, end: miniImgToDetailsPageImgDistance` 创建，`onFrame` 内通过 `isExpand` 标志区分方向：展开时 progress 正向（0→1），收起时反向（1→0）。`onFinish` 根据方向**显式锁定最终状态**。

```ts
private createAnimatorAndPlay() {
  if (this.animatorObject) { this.animatorObject.cancel(); }
  this.animatorObject = this.getUIContext().createAnimator({
    duration: 500, easing: 'ease', fill: 'forwards', iterations: 1,
    begin: 0, end: this.miniImgToDetailsPageImgDistance
  });

  this.animatorObject.onFrame = (value: number) => {
    if (!this.isExpand) {
      let progress: number = value / this.miniImgToDetailsPageImgDistance;
      this.miniImgOffsetY = value;
      this.expandCollapseAnimation(progress);
    } else {
      let progress: number = 1 - value / this.miniImgToDetailsPageImgDistance;
      this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance - value;
      this.expandCollapseAnimation(progress);
    }
  };

  this.animatorObject.onFinish = () => {
    this.isAnimating = false;
    if (!this.isExpand) {
      this.isExpand = true;
      this.detailsPageOpacity = 1;      // 显式锁定：展开完成详情页必须可见
      this.miniPlayerOpacity = 0;       // 显式锁定：展开完成迷你栏必须隐藏
    } else {
      this.isExpand = false;
      this.resetExpandState();
    }
  };

  this.animatorObject.play();
}

private doExpand() {
  if (this.isAnimating || this.isExpand) return;
  this.miniDistanceToBottom = MINI_HEIGHT + BAR_HEIGHT;
  this.miniDistanceToTop = this.stackHeight - this.miniDistanceToBottom;
  this.miniImgToDetailsPageImgDistance = this.miniDistanceToTop;
  this.miniImgOpacity = 0;               // 静态封面淡出
  this.miniImgAnimateOpacity = 1;         // 动画封面淡入
  this.isAnimating = true;
  this.createAnimatorAndPlay();
}

private doCollapse() {
  if (this.isAnimating || !this.isExpand) return;
  this.miniImgAnimateOpacity = 0;         // 动画封面淡出（仅此一项！）
  this.isAnimating = true;
  this.createAnimatorAndPlay();
}
```

关键点：
- 一个动画器同时服务展开和收起：`onFrame` 中 `isExpand` 决定 progress 方向，`onFinish` 中 `isExpand` 决定状态锁定（展开→显式设 `isExpand=true` + `detailsPageOpacity=1` + `miniPlayerOpacity=0`；收起→`resetExpandState()`）
- **onFinish 必须显式锁定终点状态**：展开完成显式设 `detailsPageOpacity=1, miniPlayerOpacity=0`，确保动画终点状态精确；收起完成调用 `resetExpandState()` 重置全部状态（含 `isAnimating=false`）
- **doExpand() 和 doCollapse() 封面图层切换策略不同**：展开时 `miniImgOpacity=0` + `miniImgAnimateOpacity=1`（静态封面淡出、动画封面淡入）；收起时只设 `miniImgAnimateOpacity=0`（动画封面淡出），**不恢复 miniImgOpacity=1**——静态封面由 resetExpandState 统一恢复，收起动画过程中静态封面不应过早出现，否则视觉上封面会"跳回"迷你栏
- `miniImgToDetailsPageImgDistance` 作为动画器 `end` 值，等于封面从迷你位置到详情页位置的垂直距离，所有 progress 计算都以它为分母
- `isAnimating` 防重入锁：动画进行中拒绝新的展开/收起请求

### 步骤 4：手势交互收起 — PanGesture 实时驱动 + animateTo 阈值判断 [辅助]

> 交互增强。依赖步骤 0-3 已建立的架构，增加一条"手势实时拖拽收起"的交互路径。**手势阶段必须区分两阶段**：progress < 0.3 时用 miniImgOffsetY 直接驱动详情页位置，progress >= 0.3 时用 miniDistanceToTop * progress 复合公式，与步骤 2 的动画阶段逻辑保持一致。

详情页绑定 `PanGesture`：`onActionUpdate` 将拖拽距离映射为 progress，**直接操作各状态变量**（非调用 `expandCollapseAnimation`，因为手势阶段详情页始终可见，opacity 逻辑不同）；`onActionEnd` 用 `animateTo` 根据当前位置阈值决定弹回展开或完全收起。

```ts
.gesture(
  PanGesture()
    .onActionUpdate((event?: GestureEvent) => {
      if (this.isAnimating || !event) return
      if (event.offsetY >= 0) {   // 允许 offsetY=0（不忽略零偏移）
        let progress: number = 1 - event.offsetY / this.miniDistanceToTop;
        if (progress < 0) progress = 0;
        // 直接更新状态变量（不调用 expandCollapseAnimation，保持详情页可见）
        this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance * progress;
        this.miniImgOffsetSize = (DETAILS_IMG_SIZE - MINI_IMG_SIZE) * progress;
        this.miniImgOffsetX = ((this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2
          - MINI_IMG_MARGIN_LEFT) * progress;
        this.miniChangeHeight = this.miniImgOffsetY;
        this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT - this.miniImgOffsetY;

        // 手势阶段也必须区分两阶段，与步骤2的动画阶段逻辑一致
        if (progress < ANIMATION_PROGRESS) {
          // 阶段1：迷你播放器淡出，详情页用 miniImgOffsetY 直接驱动位置（紧随封面偏移）
          this.miniPlayerOpacity = 1 - progress / ANIMATION_PROGRESS;
          this.detailsPagePositionY = this.stackHeight - this.miniImgOffsetY
            - this.miniDistanceToBottom;
        } else {
          // 阶段2：迷你播放器隐藏，详情页用复合公式自主上移
          this.miniPlayerOpacity = 0;
          this.detailsPagePositionY = this.stackHeight - this.miniDistanceToTop * progress
            - this.miniDistanceToBottom;
        }
        this.detailsPageOpacity = 1;   // 手势阶段详情页始终可见
        if (this.detailsPagePositionY <= this.stackHeight / 2) {
          this.detailsPageTopOpacity = 1 - this.detailsPagePositionY / (this.stackHeight / 2);
        } else {
          this.detailsPageTopOpacity = 0;
        }
      }
    })
    .onActionEnd(() => {
      if (this.isAnimating) return;
      this.getUIContext().animateTo({
        duration: 200, curve: Curve.LinearOutSlowIn,
        onFinish: () => {
          if (this.detailsPagePositionY > this.stackHeight / 2) {
            this.resetExpandState();   // 超过中线 → 完全收起
          }
        }
      }, () => {
        if (this.detailsPagePositionY <= this.stackHeight / 2) {
          // 弹回展开：恢复到完全展开状态
          this.miniImgOffsetY = this.miniImgToDetailsPageImgDistance;
          this.miniImgOffsetSize = DETAILS_IMG_SIZE - MINI_IMG_SIZE;
          this.miniImgOffsetX = (this.stackWidth - MINI_IMG_SIZE - this.miniImgOffsetSize) / 2
            - MINI_IMG_MARGIN_LEFT;
          this.detailsPageTopOpacity = 1;
          this.miniPlayerOpacity = 0;
          this.detailsPageOpacity = 1;
          this.detailsPagePositionY = 0;
          this.miniPlayerY = 0;
        } else {
          // 收回迷你态：详情页推回屏幕下方，恢复初始状态
          this.miniImgOffsetY = 0;
          this.miniImgOffsetSize = 0;
          this.miniPlayerOpacity = 1;
          this.miniImgOffsetX = 0;
          this.detailsPageOpacity = 0;
          this.miniChangeHeight = 0;
          this.detailsPagePositionY = this.stackHeight;
          this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT;
        }
      });
    })
)
```

关键点：
- **手势阶段必须区分两阶段**：progress < 0.3 时 `detailsPagePositionY = stackHeight - miniImgOffsetY - miniDistanceToBottom`（详情页紧随封面偏移）；progress >= 0.3 时 `detailsPagePositionY = stackHeight - miniDistanceToTop * progress - miniDistanceToBottom`（详情页用复合公式自主上移）。不区分会导致手势拖拽时详情页位移曲线不平滑，与动画阶段逻辑不一致
- `onActionUpdate` 不调用 `expandCollapseAnimation`，而是直接操作状态变量：手势拖拽阶段详情页始终保持 `detailsPageOpacity = 1`（用户正在看着详情页），只有 `miniPlayerOpacity` 仍遵循两阶段策略
- progress 方向：`offsetY` 越大（向下拖拽）progress 越小（趋向 0 = 收起），`event.offsetY < 0`（向上拖拽）时忽略；**允许 `offsetY >= 0`**（含零偏移），与动画阶段判定 `event.offsetY < 0` 的严格忽略不同
- `onActionEnd` 用 `this.getUIContext().animateTo()`（新 API）而非全局 `animateTo()`（已废弃）
- `onActionEnd` 弹回展开分支中必须计算 `miniImgOffsetX`（`stackWidth - MINI_IMG_SIZE - miniImgOffsetSize) / 2 - MINI_IMG_MARGIN_LEFT`），遗漏此值封面水平位置将不正确
- 阈值判断：`detailsPagePositionY > stackHeight / 2`（详情页在屏幕下半区）→ 收起；否则弹回完全展开。`onFinish` 中若判定收起则调用 `resetExpandState()` 重置所有状态
- 收起分支中将 `detailsPagePositionY` 设为 `stackHeight`（屏幕下方），与步骤 0 的初始定位策略一致，确保收起后详情页不会停留在可视区域拦截触摸事件

### 步骤 5：状态机与重置 [辅助]

> 动画终点状态管理。`resetExpandState()` 必须重置**全部**状态变量（含 `isAnimating=false`），遗漏任何一个都会导致后续交互异常。

**完整状态重置列表：**

```ts
private resetExpandState() {
  this.isExpand = false;
  this.isAnimating = false;                // 解锁交互（遗漏将导致状态锁死，无法再次展开）
  this.miniImgOpacity = 1;                 // 静态封面恢复可见
  this.miniImgAnimateOpacity = 0;          // 动画封面恢复隐藏
  this.miniImgOffsetY = 0;                 // 垂直偏移归零
  this.miniImgOffsetX = 0;                 // 水平偏移归零
  this.miniImgOffsetSize = 0;              // 封面尺寸增量归零
  this.miniPlayerOpacity = 1;              // 迷你播放器恢复可见
  this.miniChangeHeight = 0;               // 迷你播放器高度增量归零
  this.detailsPageOpacity = 0;             // 详情页恢复隐藏
  this.detailsPagePositionY = this.stackHeight;   // 详情页推回屏幕下方
  this.detailsPageTopOpacity = 1;          // 导航栏 opacity 重置
  this.miniPlayerY = this.stackHeight - MINI_HEIGHT - BAR_HEIGHT;  // 迷你播放器归位
}
```

**状态机流转图：**

```
初始态 ──doExpand()──→ 展开动画中 ──onFinish──→ 展开态
  ↑                                                      │
  │                     doCollapse()──→ 收起动画中 ──onFinish──→ resetExpandState() ──→ 初始态
  │                                                      │
  └── PanGesture阈值收起 ──→ resetExpandState() ──→ 初始态
```

关键点：
- `isAnimating = false` 是最容易被遗漏的重置项，遗漏将导致防重入锁永久生效，无法再次展开或收起
- `miniImgOpacity = 1` 和 `miniImgAnimateOpacity = 0` 必须在 resetExpandState 中统一恢复，而非在 doCollapse 中提前恢复（原因见步骤 3 关键点）
- `detailsPagePositionY = this.stackHeight`（而非 `stackHeight + 100`）：收起完成后详情页推到屏幕下方，不停留在可视区域，避免 zIndex(20) 拦截触摸

---
