# 属性动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 水波纹/呼吸灯 | `animateTo` + `iterations:-1` + `delay` | 无限循环 + 多层 delay 错开是唯一方案 |
| 侧边栏/面板切换 | `animateTo` 驱动 `showSideBar` | 容器属性联动需要显式闭包包裹 |
| 数字滚动 | `translate({y})` + `clip(true)` + 按差值算 duration | 差值越大滚动越久，模拟真实翻滚节奏 |
| 投票/进度条 | `animateTo` 驱动 width + `.animation()` 驱动 opacity | 显式 + 隐式混合驱动，宽度和高亮同步过渡 |
| 悬浮窗拖拽吸附 | `responsiveSpringMotion()` + `springMotion()` | 跟手需响应式弹簧，吸附需物理弹簧 |
| 边缘渐变提示 | `.overlay()` + `.animation()` 隐式驱动 | 滚动回调仅改布尔状态，隐式动画自动过渡 |
| 抖动/振动反馈 | `keyframeAnimateTo` + `vibrator` | 多段关键帧精确控制偏移方向 |

## 核心动画 API 枚举值参考

### animateTo 参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `duration` | number | 动画持续时间（ms），默认 1000 |
| `curve` | Curve \| ICurve \| string | 动画曲线，默认 `Curve.EaseInOut` |
| `delay` | number | 动画延迟时间（ms），默认 0 |
| `iterations` | number | 播放次数，-1 表示无限循环，默认 1 |
| `playMode` | PlayMode | 动画播放模式，默认 `PlayMode.Normal` |
| `finishCallback` | () => void | 动画完成回调 |

### Curve 枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `Curve.Linear` | 线性，匀速变化 | 匀速旋转、进度条 |
| `Curve.Ease` | 快速开始，慢速结束 | 通用过渡 |
| `Curve.EaseIn` | 慢速开始，加速结束 | 元素离开屏幕 |
| `Curve.EaseOut` | 快速开始，慢速结束 | 元素进入屏幕、投票 PK |
| `Curve.EaseInOut` | 慢-快-慢，两端缓动 | 通用过渡、水波纹扩散 |
| `Curve.FastOutSlowIn` | 标准 Material 曲线 | Material 风格动画 |
| `Curve.LinearOutSlowIn` | 出场快入场慢 | 数字滚动 |
| `Curve.FastOutLinearIn` | 出场慢入场快 | 元素消失 |
| `Curve.ExtremeDeceleration` | 极度减速 | 需要强烈减速效果 |
| `Curve.Sharp` | 急剧变化 | 邻居项收缩比例计算 |
| `Curve.Rhythm` | 节奏曲线 | 弹性节奏效果 |
| `Curve.Smooth` | 平滑曲线 | 平滑过渡 |
| `Curve.Friction` | 阻尼摩擦曲线 | 侧边栏切换、卡片浮起 |

### curves 模块弹簧曲线函数

| 函数 | 参数 | 说明 | 典型场景 |
|---|---|---|---|
| `curves.springMotion()` | `(response?, dampingFraction?)` | 物理弹簧运动曲线 | 松手吸附、弹性归位 |
| `curves.responsiveSpringMotion()` | `(response?, dampingFraction?)` | 响应式弹簧曲线，有延迟跟手感 | 拖拽跟手、悬浮球移动 |
| `curves.interpolatingSpring()` | `(velocity, mass, stiffness, damping)` | 插值弹簧曲线 | 需要精确控制弹簧参数的归位 |
| `curves.initCurve()` | `(curve: Curve)` | 初始化曲线用于 `interpolate()` | 进度-比例映射计算 |

### PlayMode 枚举值

| 枚举值 | 说明 |
|---|---|
| `PlayMode.Normal` | 正向播放一次（默认） |
| `PlayMode.Reverse` | 反向播放一次 |
| `PlayMode.Alternate` | 正反交替播放 |
| `PlayMode.AlternateReverse` | 反正交替播放 |

---

## 场景1：水波纹特效

**场景描述：** 仿听歌识曲的涟漪扩散效果，点击按钮启动后产生连续向外扩散的水波纹动画，再次点击立即停止归位。

**解决方案：** 使用 **`animateTo` + `iterations: -1` 无限循环** + **delay 错开两层涟漪** + **scale + opacity 双属性联动**

### 步骤 1：定义涟漪状态变量

```ts
@State isListening: boolean = false
@State immediatelyOpacity: number = 0.8
@State immediatelyScaleX: number = 1
@State immediatelyScaleY: number = 1
@State delayOpacity: number = 0.8
@State delayScaleX: number = 1
@State delayScaleY: number = 1
```

两层涟漪各维护 opacity 和 scale 两组状态。

### 步骤 2：启动涟漪 — 两组 animateTo + delay 错开

```ts
// 第一层：立即开始
animateTo({
  duration: 1300,
  iterations: -1,
  curve: Curve.EaseInOut
}, () => {
  this.immediatelyOpacity = 0
  this.immediatelyScaleX = 6
  this.immediatelyScaleY = 6
})

// 第二层：200ms 延迟开始
animateTo({
  duration: 1300,
  iterations: -1,
  curve: Curve.EaseInOut,
  delay: 200
}, () => {
  this.delayOpacity = 0
  this.delayScaleX = 6
  this.delayScaleY = 6
})
```

关键点：`iterations: -1` 实现无限循环，`delay: 200` 错开两层涟漪产生水波扩散视觉。

### 步骤 3：停止涟漪 — duration:0 瞬间归零

```ts
animateTo({ duration: 0 }, () => {
  this.immediatelyOpacity = 0.8
  this.immediatelyScaleX = 1
  // ... 重置所有状态
})
```

### 步骤 4：布局 — Stack 叠加两层 Circle

```ts
Stack() {
  Circle().width(96).height(96).fill(Color.White)
    .opacity(this.immediatelyOpacity)
    .scale({ x: this.immediatelyScaleX, y: this.immediatelyScaleY })
  Circle()  // 第二层涟漪
    .opacity(this.delayOpacity)
    .scale({ x: this.delayScaleX, y: this.delayScaleY })
  Button()  // 触发按钮，zIndex: 1
}.width('100%').height('100%')
```

---

## 场景2：侧边栏淡入淡出

**场景描述：** 仿群聊信息面板，点击侧边按钮后右侧滑出群成员列表面板，再次点击收起。

**解决方案：** 使用 **`SideBarContainer(Embed)` + `animateTo` 驱动 `showSideBar`** + **`Curve.Friction` 摩擦曲线** + **内容区 opacity 联动**

### 步骤 1：切换侧边栏

```ts
switchTabBar() {
  animateTo({ duration: 500, curve: Curve.Friction }, () => {
    this.isShowSideBar = !this.isShowSideBar
  })
}
```

### 步骤 2：布局 — SideBarContainer + 条件 opacity

```ts
SideBarContainer(SideBarContainerType.Embed) {
  // 侧边栏内容
  Column() {
    Text('群聊信息')
    List() { LazyForEach(this.memberArray, ...) }
  }
  .opacity(this.isShowSideBar ? 1 : 0)  // 联动透明度

  // 主内容区（含切换按钮）
  Stack() {
    Column() { /* 聊天内容 */ TextInput() }
    Text(this.isShowSideBar ? '▶' : '◀')  // 切换按钮
      .onClick(() => this.switchTabBar())
  }
  .alignContent(Alignment.End)
}
.sideBarPosition(SideBarPosition.End)
.showSideBar(this.isShowSideBar)
.showControlButton(false)
.sideBarWidth(200)
.autoHide(false)
```

关键点：Embed 模式下内容区自动缩进，按钮在 `Alignment.End` 自然跟随内容区右边缘，无需额外 translate。

---

## 场景3：数字滚动

**场景描述：** 仿抢票/库存数字刷新，下拉页面后多位数字各自滚动到新的随机值，变化量越大的数字滚动越久。

**解决方案：** 使用 **父子组件拆分** + **双重 ForEach 横向/纵向渲染数字** + **translate({y}) 偏移 + clip(true) 裁剪** + **animateTo 按差值计算 duration**

### 步骤 0：组件拆分结构

此场景需要拆分为两个组件，职责分离：

- **子组件（数字滚动区）**：负责数字渲染和滚动动画逻辑，通过 `@Prop @Watch` 监听刷新状态
- **父组件（Refresh 容器）**：持有 `isRefresh` 状态，包裹 Refresh 组件提供下拉刷新能力

```ts
// 子组件：监听 isRefresh 变化触发动画
@Component
struct DigitalScrollDetail {
  @Prop @Watch('onDataRefresh') isRefresh: boolean = false
  @State scrollYList: number[] = []
  private currentData: number[] = new Array(7).fill(0)
  private preData: number[] = new Array(7).fill(0)
  private dataItem: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

  onDataRefresh() {
    if (!this.isRefresh) {
      this.refreshData()
    }
  }
  // ... 其余步骤在子组件中实现
}

// 父组件：Refresh 容器
@Entry
@Component
struct DigitalScrollPage {
  @State isRefresh: boolean = false

  build() {
    Refresh({ refreshing: $$this.isRefresh }) {
      // 页面内容
      DigitalScrollDetail({ isRefresh: this.isRefresh })
    }
    .onRefreshing(() => {
      setTimeout(() => { this.isRefresh = false }, 1000)
    })
  }
}
```

关键点：子组件通过 `@Prop @Watch('onDataRefresh')` 监听父组件 `isRefresh` 的变化。当 Refresh 的 `onRefreshing` 回调将 `isRefresh` 设为 `false` 时，子组件的 `onDataRefresh` 被触发，开始数字滚动动画。

### 步骤 1：数据结构与常量

```ts
private readonly ITEM_HEIGHT: number = 26
private readonly FONT_SIZE: number = 22
private readonly DURATION_TIME: number = 200
private readonly NUMBER_LEN: number = 7
private readonly MILLENNIAL_LEN: number = 3  // 千分位间隔

@State scrollYList: number[] = []                         // 每位数字的 Y 偏移
private currentData: number[] = new Array(7).fill(0)      // 当前数字
private preData: number[] = new Array(7).fill(0)          // 上一次数字
private dataItem: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]  // 0-9 固定数组
```

### 步骤 2：初始化偏移量

`scrollYList` 必须在组件出现时就初始化，否则首次渲染时所有数字堆叠在 y=0 位置，无法正确显示。

```ts
aboutToAppear() {
  const initialData: number[] = []
  for (let i = 0; i < this.NUMBER_LEN; i++) {
    initialData.push(Math.floor(Math.random() * 10))
  }
  this.currentData = initialData
  this.preData = [...initialData]
  // 关键：根据初始数字计算初始偏移
  this.scrollYList = initialData.map((v: number) => -v * this.ITEM_HEIGHT)
}
```

关键点：`scrollYList` 初始值必须与 `currentData` 对应，每个数字的偏移 = `-数字值 × ITEM_HEIGHT`。

### 步骤 3：生成随机数并逐位动画

```ts
refreshData() {
  const tempArr: number[] = []
  for (let i = 0; i < this.NUMBER_LEN; i++) {
    tempArr.push(Math.floor(Math.random() * 10))
  }
  this.currentData = tempArr

  this.currentData.forEach((item: number, index: number) => {
    // 推荐使用 getUIContext()?.animateTo，animateTo 已废弃
    this.getUIContext()?.animateTo({
      duration: Math.abs(item - this.preData[index]) * this.DURATION_TIME,
      curve: Curve.LinearOutSlowIn,
      onFinish: () => {
        this.preData = [...this.currentData]  // 展开运算符创建新数组确保状态更新
      }
    }, () => {
      this.scrollYList[index] = -item * this.ITEM_HEIGHT
    })
  })
}
```

关键点：
- `duration = 差值 × DURATION_TIME`，差值越大动画越长，模拟真实数字翻滚节奏
- `onFinish` 中只更新 `preData`，不设置 `isRefresh`（由父组件控制 Refresh 状态归位）
- `preData` 赋值使用 `[...this.currentData]` 展开运算符，确保 ArkUI 检测到数组引用变化

### 步骤 4：布局 — 双重 ForEach + clip

```ts
Row() {
  ForEach(this.currentData, (item: number, index: number) => {
    // 千分位逗号
    if ((this.NUMBER_LEN - index) % this.MILLENNIAL_LEN === 0 && index !== 0) {
      Text(',')
        .fontWeight(FontWeight.Bold)
        .fontSize(this.FONT_SIZE)
    }
    Column() {
      ForEach(this.dataItem, (subItem: number) => {
        Text(subItem.toString())
          .fontWeight(FontWeight.Bold)
          .fontSize(this.FONT_SIZE)
          .height('100%')               // 必须撑满 Column 高度，确保数字等间距排列
          .textAlign(TextAlign.Center)
          .translate({ y: this.scrollYList[index] })  // translate 必须在 Text 上
      })
    }
    .height(this.ITEM_HEIGHT)
    .clip(true)
  })
}
```

关键点：
- **FONT_SIZE 必须 ≤ ITEM_HEIGHT**，否则字符超出 clip 裁剪区导致数字底部截断、顶部溢出到相邻区域。推荐 FONT_SIZE 比 ITEM_HEIGHT 小 4px（如 22 vs 26）以保证字形完整显示
- **translate 必须应用在每个 Text 上**，而非外层 Column。Column 设置 `clip(true)` 裁剪的是子元素相对 Column 的溢出，translate 在 Text 上才能让 0-9 数字在裁剪区域内正确滚动。若 translate 放在 Column 上，clip 裁剪的是 Column 本身相对父容器的溢出，数字滚动效果失效
- 每个 Text 需设置 `.height('100%')` 和 `.textAlign(TextAlign.Center)`，否则数字垂直排列不均匀
- 0-9 数字数组建议定义为组件私有字段 `private dataItem: number[]`，避免在模板中硬编码

---

## 场景4：投票PK

**场景描述：** 仿投票PK，投票前左右双方各占一半，投票后双方宽度按实际得票比例平滑过渡，所选一方高亮显示。

**解决方案：** 使用 **animateTo 驱动 width 百分比字符串** + **Curve.EaseOut 减速曲线**

### 步骤 1：状态定义

```ts
@State leftWidth: string = '50%'
@State rightWidth: string = '50%'
@State selectedOption: string = ''      // 记录用户选择的一方 ('left' | 'right' | '')
```

> **关键点：** 用 `selectedOption` 区分选中方与未选中方。投票前为空字符串，投票后记录用户的选择，驱动高亮与变暗的差异化样式。

### 步骤 2：投票动画 — 宽度过渡 + 记录选中方

```ts
doVote(option: string) {
  this.selectedOption = option           // 记录用户选择
  animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
    this.leftWidth = (leftPercent).toFixed(0) + '%'
    this.rightWidth = (rightPercent).toFixed(0) + '%'
  })
}
```

> **关键点：** `selectedOption` 在 `animateTo` 外部赋值，使高亮样式变化与宽度动画同步触发。选中方 `opacity: 1`（完整高亮），未选中方 `opacity: 0.5`（变暗衬托），两侧差异由 `.animation()` 隐式动画平滑过渡。

### 步骤 3：布局 — Flex 两段 Stack + 选中方高亮 / 未选中方变暗

```ts
Flex() {
  Stack() {
    Text(leftLabel).fontColor(Color.White)
  }
  .width(this.leftWidth)
  .backgroundColor('#ff6b6b')
  .opacity(this.selectedOption === '' ? 1 : (this.selectedOption === 'left' ? 1 : 0.5))
  .animation({ duration: 600, curve: Curve.EaseOut })

  Stack() {
    Text(rightLabel).fontColor(Color.White)
  }
  .width(this.rightWidth)
  .backgroundColor('#4ecdc4')
  .opacity(this.selectedOption === '' ? 1 : (this.selectedOption === 'right' ? 1 : 0.5))
  .animation({ duration: 600, curve: Curve.EaseOut })
}
```

> **关键点：**
> - **三级 opacity 逻辑**：投票前 `selectedOption === ''` 时双方 `opacity: 1`；投票后选中方 `opacity: 1`（高亮），未选中方 `opacity: 0.5`（变暗），形成视觉对比突出用户选择
> - **`.animation()` 隐式动画**：opacity 变化通过 `.animation({ duration: 600 })` 自动补间，与宽度过渡同步进行，高亮与宽度变化一气呵成
> - 移除了原有的全局 `fillOpacity`，改为每侧独立 opacity，实现差异化高亮

---

## 场景5：悬浮窗拖拽吸附

**场景描述：** 仿客服悬浮球，手指拖拽时悬浮窗弹性跟手移动，松手后自动弹性吸附到最近的屏幕左/右边缘。

**解决方案：** 使用 **`curves.responsiveSpringMotion()` 拖拽跟手** + **`curves.springMotion()` 松手吸附** + **`.position()` 绝对定位 + `onTouch` 事件**

### 步骤 1：onTouch 拖拽跟手

```ts
.onTouch((event) => {
  if (event.type === TouchType.Move) {
    animateTo({ curve: curves.responsiveSpringMotion() }, () => {
      // 更新 edge.left/right/top
      this.edge = { top: newY, left: newX }
    })
  }
})
```

### 步骤 2：松手吸附到最近边缘

```ts
if (event.type === TouchType.Up) {
  const snapX = currentX < containerWidth / 2 ? margin : containerWidth - windowWidth - margin
  animateTo({ curve: curves.springMotion() }, () => {
    this.edge = { top: clampY, left: snapX }
  })
}
```

关键点：`responsiveSpringMotion` 提供弹性延迟跟手感，`springMotion` 提供弹性回弹吸附。

---

## 场景6：边缘渐变

**场景描述：** 仿应用推荐页的水平滑动列表，列表内容超出可视区域时可水平滚动，当滚动到起始/末尾位置时，对应边缘渐变淡出提示已达边界；滚动到中间位置时，两端同时显示渐变遮罩提示两侧还有更多内容，遮罩显隐带有平滑过渡。

**解决方案：** 使用 **两个独立 opacity 状态分别控制左右遮罩** + **`.overlay()` 叠加渐变遮罩** + **`linearGradient({ angle: 90 })` 左右渐变** + **`.animation()` 隐式动画平滑过渡** + **`Scroller` + `onReachStart/onReachEnd/onDidScroll` 精确检测滚动位置**

### 步骤 0：常量定义与状态初始化

```ts
const GRADIENT_COLOR: string = '#fff5f5f5'     // 背景色的不透明版本，用于形成遮罩
const GRADIENT_DURATION: number = 220          // 遮罩显隐动画时长（ms）

@State showStartFade: boolean = false   // 是否显示左端遮罩（初始在起始位置，不显示）
@State showEndFade: boolean = true      // 是否显示右端遮罩（初始在起始位置，提示右侧还有内容）
private scroller: Scroller = new Scroller()
```

关键点：
- 使用两个 `boolean` 状态 `showStartFade`/`showEndFade` 分别控制左右遮罩，比直接操作渐变颜色字符串更清晰、不易出错
- 初始状态：左端不显示（已在最左侧，无更多内容），右端显示（提示右侧还有内容）

### 步骤 1：监听滚动状态

三个回调各自更新两端遮罩的布尔状态，逻辑清晰互不冲突：

```ts
List({ scroller: this.scroller })
  .onReachStart(() => {
    this.showStartFade = false
    this.showEndFade = true
  })
  .onReachEnd(() => {
    this.showStartFade = true
    this.showEndFade = false
  })
  .onDidScroll(() => {
    if (!this.scroller.isAtStart() && !this.scroller.isAtEnd()) {
      this.showStartFade = true
      this.showEndFade = true
    }
  })
```

关键点：
- `onReachStart`：滚到最左侧 → 左端隐藏（已到头），右端显示（还有内容）
- `onReachEnd`：滚到最右侧 → 左端显示（前面有内容），右端隐藏（已到头）
- `onDidScroll`：在中间位置时两端都显示。使用 `isAtStart()` / `isAtEnd()` 判断边界，比 `currentOffset().xOffset !== 0` 更语义化且适配不同设备方向
- `onDidScroll` 中必须加边界判断，否则会覆盖 `onReachStart`/`onReachEnd` 的设置导致遮罩闪烁

### 步骤 2：渐变遮罩 — @Builder + overlay + linearGradient + animation

将 overlay 内容封装为 `@Builder`，通过布尔状态计算颜色数组，保持代码清晰：

```ts
@Builder
fadingOverlay() {
  Column()
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 90,    // 必须设置：90° = 左→右方向，不设置默认上→下
      colors: [
        [this.showStartFade ? GRADIENT_COLOR : '#00000000', 0.0],
        ['#00000000', 0.15],
        ['#00000000', 0.85],
        [this.showEndFade ? GRADIENT_COLOR : '#00000000', 1.0]
      ]
    })
    .animation({ curve: Curve.Ease, duration: GRADIENT_DURATION })
    .hitTestBehavior(HitTestMode.Transparent)
}
```

在 List 上通过 `.overlay()` 绑定：

```ts
List({ scroller: this.scroller }) {
  // ... ListItem 内容
}
.listDirection(Axis.Horizontal)
.overlay(this.fadingOverlay())
.edgeEffect(EdgeEffect.None)
.scrollBar(BarState.Off)
.onReachStart(() => { /* 步骤1 */ })
.onReachEnd(() => { /* 步骤1 */ })
.onDidScroll(() => { /* 步骤1 */ })
```

关键点：
- **布尔状态 → 颜色映射**：`showStartFade` 为 true 时左端用 `GRADIENT_COLOR`（有色遮罩），false 时用 `'#00000000'`（完全透明），右端同理。避免了颜色交换逻辑，降低出错概率
- **必须设置 `angle: 90`**：`linearGradient` 默认方向为上→下（angle: 180），不设置会导致遮罩出现在上下边缘而非左右边缘。90° = 左→右方向
- 使用 `.overlay()` 绑定遮罩，而非用 Stack 叠加。overlay 直接附着在 List 上，尺寸自动匹配
- **必须设置 `.edgeEffect(EdgeEffect.None)`**：默认的弹簧弹跳效果会在边界处产生回弹，导致 `onReachStart/onReachEnd` 触发后立即被 `onDidScroll` 覆盖，遮罩闪烁
- `.animation()` 让布尔状态切换引起的颜色变化自动产生 220ms 平滑过渡，`hitTestBehavior(Transparent)` 使遮罩不拦截触摸
- overlay 的 Column 需设置 `.width('100%')` 和 `.height('100%')` 以覆盖整个 List 区域
- 中间区域（`0.15 ~ 0.85`）保持完全透明，不影响列表内容的正常显示

---

## 场景7：振动抖动

**场景描述：** 仿登录页，未勾选协议时点击一键登录，手机产生振动反馈的同时"请阅读并勾选协议"提示文本左右抖动。

**解决方案：** 使用 **`vibrator.startVibration` 硬件振动** + **`keyframeAnimateTo` 关键帧抖动** + **`translateX` 位移动画**

### 步骤 1：触发硬件振动

```ts
import { vibrator } from '@kit.SensorServiceKit'

startVibrate() {
  try {
    vibrator.startVibration({
      type: 'time',
      duration: 600
    }, { id: 0, usage: 'alarm' }, (error) => { /* ... */ })
  } catch (err) { /* ... */ }
}
```

### 步骤 2：关键帧抖动动画

```ts
startAnimation() {
  this.translateX = 0
  this.getUIContext()?.keyframeAnimateTo({ iterations: 2 }, [
    {
      duration: 100,
      event: () => { this.translateX = 5 }
    },
    {
      duration: 100,
      event: () => { this.translateX = 0 }
    }
  ])
}
```

关键点：`iterations: 2` 抖动 2 轮（0→5→0→5→0），`keyframeAnimateTo` 支持精确的关键帧控制。需 `ohos.permission.VIBRATE` 权限。

---
