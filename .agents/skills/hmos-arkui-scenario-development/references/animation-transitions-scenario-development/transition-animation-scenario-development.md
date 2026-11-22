# 转场动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 页面 A↔B 切换 | `TransitionEffect.OPACITY.combine(translate)` + `move(Edge)` | 比 Navigation 更轻量；A 左移淡出 + B 右侧滑入 |
| 侧滑手势返回 | `PanGesture` + `translate({x})` + 阈值判断 | 需要实时跟手；松手后根据偏移决定退出/弹回 |
| 底部抽屉/操作面板 | 条件渲染 + `TransitionEffect.translate({y})` + 遮罩 | 最简方案；遮罩点击即可关闭 |
| 分组列表展开折叠 | 两级转场：容器 `OPACITY` + 行级 `delay` 交错 | 容器控制整体节奏，行级实现瀑布交错 |
| 横竖屏布局适配 | `mediaquery` + `TransitionEffect.OPACITY.combine(scale)` | 竖屏缩小淡出/横屏放大淡入形成视差；公共 Builder 复用 |

## 核心动画 API 枚举值参考

### TransitionEffect 静态属性与方法

| 属性/方法 | 说明 | 典型场景 |
|---|---|---|
| `TransitionEffect.OPACITY` | 透明度转场（1→0→1） | 页面淡入淡出、底部抽屉 |
| `TransitionEffect.IDENTITY` | 无转场效果 | 不需要转场时使用 |
| `TransitionEffect.opacity(value)` | 自定义透明度起始值 | 模态从半透明过渡 |
| `TransitionEffect.translate(offset)` | 平移转场 | 页面滑入/滑出、底部抽屉弹出 |
| `TransitionEffect.scale(scale)` | 缩放转场 | 竖屏 0.96 缩小淡出、横屏 1.04 放大淡入 |
| `TransitionEffect.move(edge)` | 从指定边缘滑入/滑出 | B 页从右侧滑入（END）、退出时从左侧滑出（START） |
| `.combine(effect)` | 组合两个转场效果 | OPACITY + translate 联动 |
| `.animation(params)` | 附加动画参数 | 设置 duration/curve/delay |

### TransitionEdge 边缘方向枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `TransitionEdge.TOP` | 从顶部滑入/滑出 | 下拉通知栏 |
| `TransitionEdge.BOTTOM` | 从底部滑入/滑出 | 底部面板弹入 |
| `TransitionEdge.START` | 从起始端滑入/滑出（通常为左侧） | 页面退出时左移、侧滑返回 |
| `TransitionEdge.END` | 从末端滑入/滑出（通常为右侧） | 新页面从右侧滑入 |

### Curve 枚举值（转场动画常用）

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `Curve.EaseOut` | 快速开始，慢速结束 | 容器级整体淡入淡出 |
| `Curve.EaseInOut` | 慢-快-慢，两端缓动 | 列表页淡出/淡入 |
| `Curve.Sharp` | 急剧变化 | 背景色快速过渡 |

### curves 模块弹簧曲线函数（转场动画常用）

| 函数 | 参数 | 说明 | 典型场景 |
|---|---|---|---|
| `curves.springMotion()` | `(response?, dampingFraction?)` | 弹簧运动曲线 | 页面滑入、底部抽屉弹出、展开折叠 |
| `curves.springMotion(0.6, 0.9)` | response=0.6, damping=0.9 | 适中弹性 | 展开折叠、页面切换 |

### TransitionEffect.animation 参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `duration` | number | 转场动画时长（ms） |
| `curve` | Curve \| ICurve \| string | 动画曲线 |
| `delay` | number | 动画延迟时间（ms） |

---

## 场景1：页面滑动

**场景描述：** 仿页面切换，点击按钮后当前页面向左淡出，新页面从右侧滑入，形成 A→B 的页面跳转过渡。

**解决方案：** 使用 **`TransitionEffect.OPACITY.combine(translate)` 左移淡出** + **`TransitionEffect.move(TransitionEdge.END)` 右侧滑入** + **`curves.springMotion()` 弹性曲线**

### 步骤 1：Page A 退出转场

```ts
if (!showPageB) {
  Column() { /* Page A 内容 */ }
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: 400, curve: curves.springMotion() })
        .combine(TransitionEffect.translate({ x: -100 }))
    )
}
```

### 步骤 2：Page B 进入转场

```ts
if (showPageB) {
  Column() { /* Page B 内容 */ }
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: 400, curve: curves.springMotion() })
        .combine(TransitionEffect.move(TransitionEdge.END))
    )
}
```

### 步骤 3：触发切换

```ts
Button('切换').onClick(() => {
  this.showPageB = !this.showPageB
})
```

---

## 场景2：侧滑返回

**场景描述：** 仿 iOS 手势侧滑返回，手指从屏幕左边缘向右拖拽时顶层页面跟手右移，滑动超过阈值后自动退出，未超过则弹回原位。

**解决方案：** 使用 **`PanGesture` 水平拖拽** + **`translate({x: offsetX})` 跟手** + **松手判断偏移 > 150px 则退出** + **`TransitionEffect` 退出动画**

### 步骤 1：PanGesture 跟手

```ts
.gesture(
  PanGesture({ direction: PanDirection.Horizontal })
    .onActionUpdate((event) => {
      this.offsetX = event.offsetX
    })
    .onActionEnd((event) => {
      if (this.offsetX > 150) {
        // 滑动足够远，退出
        animateTo({ duration: 250, curve: Curve.EaseOut, onFinish }, () => {
          this.offsetX = 300
        })
      } else {
        // 弹回
        animateTo({ duration: 250 }, () => { this.offsetX = 0 })
      }
    })
)
```

### 步骤 2：退出转场效果

```ts
.transition(
  TransitionEffect.OPACITY
    .animation({ duration: 250, curve: curves.springMotion() })
    .combine(TransitionEffect.move(TransitionEdge.START))
)
.translate({ x: this.offsetX })
```

---

## 场景3：底部抽屉

**场景描述：** 仿底部操作面板，点击按钮后从屏幕底部弹出半透明遮罩 + 内容面板，点击遮罩或关闭按钮后面板滑出消失。

**解决方案：** 使用 **条件渲染 + `TransitionEffect.OPACITY.combine(translate({y:400}))`** + **`curves.springMotion()` 弹性曲线** + **半透明遮罩点击关闭**

### 步骤 1：遮罩 + 抽屉布局

```ts
Stack() {
  Column() { /* 主内容 */ }

  if (this.showDrawer) {
    // 半透明遮罩
    Column().width('100%').height('100%')
      .backgroundColor('rgba(0,0,0,0.4)')
      .onClick(() => { this.showDrawer = false })

    // 底部抽屉
    Column() { /* 抽屉内容 */ }
      .width('100%')
      .height(400)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .transition(
        TransitionEffect.OPACITY
          .animation({ duration: 350, curve: curves.springMotion() })
          .combine(TransitionEffect.translate({ y: 400 }))
      )
  }
}.justifyContent(FlexAlign.End)
```

---

## 场景4：展开折叠

**场景描述：** 仿设置页分组列表，每组卡片有图标 + 标题 + 箭头。点击分组标题后箭头旋转 180° 指示展开状态，子选项容器整体淡入、内部各行从左侧依次交错滑入；再次点击折叠收起。卡片使用 `clip(true)` 裁剪，展开内容不会溢出圆角边界。

**解决方案：** 使用 **`animateTo + springMotion` 触发展开** + **箭头 `rotate` 隐式动画** + **容器级 `TransitionEffect.OPACITY` 整体淡入** + **子项级 `OPACITY.combine(translate({x:-30}))` + `delay: index * 30` 交错入场** + **`clip(true)` 裁剪溢出**

### 步骤 1：数据定义

```ts
interface GroupItem {
  title: string
  icon: string
  items: string[]
}

// 示例数据
private groups: GroupItem[] = [
  { title: '个人信息', icon: '👤', items: ['头像设置', '昵称修改', '个人简介', '性别设置'] },
  { title: '通知设置', icon: '🔔', items: ['消息推送', '邮件通知', '短信提醒', '静音时段'] },
  /* ... */
]
@State expandedItems: boolean[] = [false, false, false, false]
```

### 步骤 2：分组标题行（图标 + 箭头旋转 + 点击展开）

```ts
Row() {
  Text(group.icon).fontSize(20).margin({ right: 10 })
  Text(group.title).fontSize(16).layoutWeight(1)

  // 箭头：展开时旋转 180°，使用隐式 animation 保证平滑过渡
  Text('▼')
    .fontSize(12).fontColor('#999999')
    .rotate({ angle: this.expandedItems[index] ? 180 : 0 })
    .animation({ duration: 250, curve: Curve.EaseInOut })
}
.width('100%').height(52)
.padding({ left: 16, right: 16 })
.onClick(() => {
  // 用 animateTo 包裹状态变更，触发 springMotion 弹性动画
  this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion(0.6, 0.9) }, () => {
    this.expandedItems[index] = !this.expandedItems[index]
  })
})
```

### 步骤 3：子项容器 + 行级两级交错转场

```ts
if (this.expandedItems[index]) {
  // ★ 容器级转场：整体 OPACITY 淡入淡出，控制折叠速度
  Column() {
    ForEach(group.items, (subItem: string, subIndex: number) => {
      Row() {
        Text(subItem).fontSize(14).fontColor('#666666').layoutWeight(1)
        Text('›').fontSize(16).fontColor('#cccccc')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      // ★ 行级转场：从左侧 -30px 滑入 + 透明度，delay 实现交错入场
      .transition(
        TransitionEffect.OPACITY
          .animation({
            duration: 300,
            curve: curves.springMotion(0.6, 0.9),
            delay: 30 * subIndex   // 第 0 行立即入场，第 1 行延迟 30ms，依次递增
          })
          .combine(TransitionEffect.translate({ x: -30 }))
      )
    })
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 200, curve: Curve.EaseOut })
  )
}
```

### 步骤 4：卡片容器裁剪（防止展开内容溢出圆角）

```ts
Column() {
  /* 标题行 步骤 2 */
  /* 子项容器 步骤 3 */
}
.width('100%')
.backgroundColor(Color.White)
.borderRadius(12)
.clip(true)                                    // ★ 关键：裁剪子内容在圆角范围内
.shadow({ radius: 2, color: '#1a000000', offsetY: 1 })
```

关键点：
- **两级转场叠加**：容器 `Column` 挂载 `TransitionEffect.OPACITY`（200ms EaseOut）控制整体淡入淡出，内部每行 `Row` 挂载 `OPACITY.combine(translate({x:-30}))`（300ms springMotion）实现从左侧交错滑入
- **`delay: 30 * subIndex`**：子项按索引递增延迟入场，形成从上到下依次展开的瀑布效果；折叠时同样反向逐行退出
- **箭头 `.animation()` 隐式动画**：箭头旋转不放在 `animateTo` 内，而是通过 `.animation()` 属性监听 `rotate` 变化自动补间，与 `animateTo` 触发的展开动画并行播放
- **`clip(true)`**：卡片设为圆角后必须 clip，否则子项从 `translate({x:-30})` 滑入时会超出圆角边界
- **`springMotion(0.6, 0.9)`**：响应参数 0.6 + 阻尼参数 0.9，弹性适中不回弹过度，适合列表展开的手感

---

## 场景5：相册宫格旋转

**场景描述：** 仿相册浏览页，竖屏时宫格列数较少以适配窄屏，横屏时宫格列数自动增多以充分利用宽屏空间，旋转时图片居中缩放、列数平滑过渡。

**解决方案：** 使用 **`GridRow` 断点系统 `{ sm, md, lg, xl }` 自动适配列数** + **`GridCol({ span: 1 })` 均分列宽** + **`.aspectRatio(1)` 正方形缩略图**

### 步骤 1：数据定义

```ts
class PhotoItem {
  id: number = 0
  label: string = ''
  colors: string[] = []

  constructor(id: number, label: string, colors: string[]) {
    this.id = id
    this.label = label
    this.colors = colors
  }
}
```

### 步骤 2：GridRow + GridCol 断点自适应宫格

```ts
Scroll() {
  GridRow({ columns: { sm: 3, md: 4, lg: 5, xl: 6 }, gutter: 4 }) {
    ForEach(this.photos, (photo: PhotoItem, index: number) => {
      GridCol({ span: 1 }) {
        Stack() {
          Column() {}
            .width('100%').height('100%')
            .linearGradient({ angle: 135, colors: [[photo.colors[0], 0], [photo.colors[1], 1]] })
          Text(`${index + 1}`)
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(Color.White)
        }
        .aspectRatio(1)
        .borderRadius(4)
        .clip(true)
      }
    })
  }
  .width('100%')
  .padding(8)
}
```

关键点：
- `GridRow({ columns: { sm: 3, md: 4, lg: 5, xl: 6 } })` 断点系统自动根据屏幕宽度匹配列数，无需手动监听方向变化
- 断点阈值：sm < 520vp、md 520-844vp、lg > 844vp，旋转时自动切换断点并重新排列
- `GridCol({ span: 1 })` 每个缩略图占1列，`gutter: 4` 控制间距
- `.aspectRatio(1)` 保证缩略图为正方形，旋转后图片居中缩放适配
- `module.json5` 需配置 `"orientation": "auto_rotation"`

---

## 场景6：商品详情旋转

**场景描述：** 仿电商商品详情页，竖屏时为单列滚动布局（商品大图 + 价格信息 + 详情描述 + 用户评价 + 底部操作栏），横屏时自动切换为左右分栏（左侧商品大图 + 右侧详情评价 + 右侧底部操作栏），旋转时整体淡入淡出平滑过渡，内容无缝适配。

**解决方案：** 使用 **`mediaquery` 监听方向变化** + **`TransitionEffect.OPACITY.combine(scale)` 缩放淡入淡出** + **`curves.springMotion()` 弹性过渡** + **竖屏 `Scroll` 单列 / 横屏 `Row` 双栏** + **公共 `@Builder` 组件复用**

### 步骤 1：数据定义与 Builder 声明

```ts
// 商品数据模型
class Product { /* name, price, description, reviews[] ... */ }
class ReviewItem { /* user, rating, content, date ... */ }

// 抽取公共 @Builder，竖屏/横屏共用，避免代码重复
@Builder ProductInfoBuilder() { /* 商品名 + 价格 + 标签 + 描述 */ }
@Builder ReviewListBuilder() { /* ForEach 渲染评价列表 */ }
@Builder ActionBarBuilder() { /* 加入购物车 + 立即购买 */ }
```

### 步骤 2：mediaquery 方向监听

```ts
import mediaquery from '@ohos.mediaquery'

@Entry
@Component
struct Scene6ProductDetail {
  @State isPortrait: boolean = true
  private listener?: mediaquery.MediaQueryListener

  aboutToAppear() {
    this.listener = mediaquery.matchMediaSync('(orientation: landscape)')
    this.isPortrait = !this.listener.matches
    this.listener.on('change', (result) => {
      animateTo({ duration: 350, curve: curves.springMotion() }, () => {
        this.isPortrait = !result.matches
      })
    })
  }

  aboutToDisappear() {
    this.listener?.off('change')
  }
}
```

### 步骤 3：竖屏单列布局

```ts
@Builder
PortraitLayout() {
  Column() {
    Scroll() {
      Column() {
        /* 商品大图 */
        /* 商品信息 this.ProductInfoBuilder() */
        /* 用户评价 this.ReviewListBuilder() */
      }
    }.layoutWeight(1)

    /* 底部操作栏 this.ActionBarBuilder() */
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 300, curve: curves.springMotion() })
      .combine(TransitionEffect.scale({ x: 0.96, y: 0.96 }))  // 略微缩小淡出
  )
}
```

### 步骤 4：横屏双栏布局

```ts
@Builder
LandscapeLayout() {
  Row() {
    /* 左侧商品大图 */

    Column() {
      Scroll() {
        Column() {
          /* 商品信息 this.ProductInfoBuilder() */
          /* 用户评价 this.ReviewListBuilder() */
        }
      }.layoutWeight(1)

      /* 底部操作栏 this.ActionBarBuilder() */
    }.layoutWeight(1)
  }
  .transition(
    TransitionEffect.OPACITY
      .animation({ duration: 300, curve: curves.springMotion() })
      .combine(TransitionEffect.scale({ x: 1.04, y: 1.04 }))  // 略微放大淡入
  )
}
```

### 步骤 5：旋转过渡装配

```ts
build() {
  if (this.isPortrait) {
    this.PortraitLayout()
  } else {
    this.LandscapeLayout()
  }
}
```

关键点：
- `mediaquery.matchMediaSync('(orientation: landscape)')` 监听横竖屏切换，`.on('change')` 回调中通过 `animateTo` 包裹 `isPortrait` 状态变更触发转场动画
- 竖屏转场 `scale({ x: 0.96, y: 0.96 })` 略微缩小淡出，横屏转场 `scale({ x: 1.04, y: 1.04 })` 略微放大淡入，形成"推开"视差感
- 商品信息、评价列表、操作栏均抽取为 `@Builder`，竖屏/横屏共用同一套布局逻辑，避免代码重复
- `aboutToDisappear` 中调用 `listener.off('change')` 释放媒体查询监听，防止内存泄漏
- `module.json5` 需配置 `"orientation": "auto_rotation"` 以支持屏幕旋转

---
