# 共享元素动画案例集

## 适用场景

| 场景 | 推荐方案 | 选型理由 |
|---|---|---|
| 缩略图→全屏图片 | `geometryTransition(id)` + `animateTo` | 系统自动插值位置和尺寸，最简方案 |
| 瀑布流卡片→详情页 | `geometryTransition` + `TransitionEffect.OPACITY` | 封面共享元素过渡 + 详情页整体淡入 |
| 搜索框展开全屏 | `geometryTransition(id, {follow:true})` + `bindContentCover(NONE)` | 非 Image 组件用 follow；禁用系统模态动画避免干扰 |
| 同页面卡片展开详情 | `NodeController` + `position/translate/height` | 需要控制封面图尺寸变化和圆角变化 |
| 跨页面新闻转场 | `Navigation.customNavContentTransition` + `CoverNodeController` | 跨 NavDestination 共享节点；需自定义转场回调编排 |

## 核心动画 API 枚举值参考

### geometryTransition 参数

| 参数 | 类型 | 说明 |
|---|---|---|
| `id` | string | 共享元素配对 ID，相同 ID 的两个组件会建立过渡关系 |
| `{ follow: true }` | object | 组件跟随共享元素运动（适用于非 Image 组件间的过渡） |

### geometryTransition ID 配对策略

| 策略 | 说明 | 适用场景 |
|---|---|---|
| 缩略图条件置空 | 命中时 `ID = ''`（隐藏），否则保持 ID | 图片浏览、卡片转场 |
| 详情页始终持有 | 不附加任何条件保持 ID | 所有共享元素场景 |
| 动态设置 ID | 打开/关闭时统一赋值 `geometryId` | 一镜到底搜索 |

### ModalTransition 模态转场枚举值

| 枚举值 | 说明 | 典型场景 |
|---|---|---|
| `ModalTransition.DEFAULT` | 系统默认转场 | 常规模态弹窗 |
| `ModalTransition.NONE` | 禁用系统动画 | 共享元素一镜到底 |
| `ModalTransition.ALPHA` | 透明度淡入淡出 | 纯淡入淡出 |

### curves 模块弹簧曲线函数（共享元素常用）

| 函数 | 参数 | 说明 | 典型场景 |
|---|---|---|---|
| `curves.springMotion()` | `(response?, dampingFraction?)` | 弹簧运动曲线 | 图片浏览放大/缩小、卡片转场 |
| `curves.interpolatingSpring()` | `(velocity, mass, stiffness, damping)` | 插值弹簧曲线 | 一镜到底搜索展开/收起、新闻封面展开 |

### TransitionEffect 方法（共享元素常用）

| 方法 | 说明 | 典型场景 |
|---|---|---|
| `TransitionEffect.OPACITY` | 透明度转场 | 详情页整体淡入淡出 |
| `TransitionEffect.asymmetric(enter, exit)` | 非对称转场 | 返回按钮进入有 delay，退出无 delay |
| `.animation(params)` | 附加动画参数 | 搜索框淡出 200ms |

---

## 场景1：朋友圈图片浏览

**场景描述：** 仿朋友圈图片浏览，点击九宫格中的小图后图片放大过渡到全屏大图预览，点击图片反向缩小回缩略图位置。

**解决方案：** 使用 **`geometryTransition` 共享元素过渡** + **`animateTo` 驱动过渡** + **`curves.springMotion` 弹性曲线**

> **完整源文件：** `AnimationCases/entry/src/main/ets/pages/sharedanimation/ImageBrowsePage.ets`

### 步骤 0：数据模型与状态变量

```ts
// 数据模型（字段省略构造器）
class MomentPost { id: string; userName: string; avatarSrc: Resource; text: string; time: string; images: Resource[] }

@Entry
@Component
struct ImageBrowsePage {
  @State showViewer: boolean = false       // Viewer 是否显示
  @State viewerPostIndex: number = -1      // 当前浏览的帖子索引
  @State viewerImageIndex: number = -1     // 当前浏览的图片索引

  private posts: MomentPost[] = [ /* 帖子数据 */ ]
}
```

> **图片资源：** 必须使用 JPG/PNG 等非正方形栅格图片（不能用 SVG）。缩略图用 `objectFit(Cover)` + `aspectRatio(1)` 裁切为正方形，Viewer 用 `objectFit(Contain)` 完整显示，`geometryTransition` 在两者间插值——只有图片本身宽高比 ≠ 1 时 Cover 与 Contain 才产生差异，过渡才有缩放效果。参考实现使用 `transitionanimation_image1~6.jpg`。

### 步骤 1：九宫格缩略图 — geometryTransition 条件置空

缩略图使用 **条件 ID**：当 Viewer 打开且命中当前图片时，ID 置空（隐藏该缩略图），否则保持 `moment_{postIndex}_{imgIndex}`。这样 Viewer 中的配对图片才能从缩略图位置放大到全屏。

```ts
@Builder
momentItem(post: MomentPost, postIndex: number) {
  Row() {
    // 头像
    Column() {
      Image(post.avatarSrc)
        .width(44)
        .height(44)
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
    }
    .margin({ top: 14 })

    Column() {
      // 用户名
      Text(post.userName)
        .fontSize(16)
        .fontColor('#576b95')
        .fontWeight(FontWeight.Medium)

      // 正文
      Text(post.text)
        .fontSize(15)
        .fontColor('#333333')
        .lineHeight(22)
        .margin({ top: 6 })

      GridRow({ columns: 3, gutter: { x: this.GRID_GAP, y: this.GRID_GAP } }) {
        ForEach(post.images, (img: Resource, imgIndex: number) => {
          GridCol() {
            Image(img)
              .width('100%').aspectRatio(1).objectFit(ImageFit.Cover).borderRadius(2)
              .geometryTransition(this.showViewer &&
                this.viewerPostIndex === postIndex && this.viewerImageIndex === imgIndex ?
                '' : `moment_${postIndex}_${imgIndex}`)
              .onClick(() => { this.openViewer(postIndex, imgIndex) })
          }
        }, (img: Resource, imgIndex: number) => `${postIndex}_${imgIndex}`)
      }
      .width(this.GRID_WIDTH).margin({ top: 8 })

      // 时间、点赞、转发
      Row() {
        Text(post.time)
          .fontSize(12)
          .fontColor('#999999')

        Blank()

        Row() {
          Text('♡')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ right: 16 })
          Text('⤴')
            .fontSize(16)
            .fontColor('#999999')
        }
      }
      .width('100%')
      .margin({ top: 8, bottom: 14 })
    }
    .layoutWeight(1)
    .margin({ left: 12 })
    .alignItems(HorizontalAlign.Start)
  }
  .width('100%')
  .alignItems(VerticalAlign.Top)
  .padding({ left: 16, right: 16 })
}
```

> **关键点：**
> - ID 必须包含 `postIndex` 和 `imgIndex` 两个维度，保证跨帖子图片 ID 全局唯一。
> - **不要加 `{ follow: true }`**：缩略图和 Viewer 都是 Image 组件，无需 follow，加上反而改变过渡行为。

### 步骤 2：全屏大图预览 — geometryTransition 始终保持 ID

Viewer 图片**始终持有**对应的 ID，不附加任何条件：

```ts
@Builder
imageViewer() {
  Image(this.posts[this.viewerPostIndex].images[this.viewerImageIndex])
    .width('100%')
    .height('100%')
    .objectFit(ImageFit.Contain)
    .backgroundColor('#0a0a0a')
    .id('viewer_image')
    .geometryTransition(`moment_${this.viewerPostIndex}_${this.viewerImageIndex}`)  // 始终持有 ID
    .onClick(() => {
      this.closeViewer()
    })
}
```

> **关键点：**
> - Viewer 图片的 `geometryTransition` 使用 `moment_${this.viewerPostIndex}_${this.viewerImageIndex}`，**不附加任何条件**——如果关闭时 ID 变空，将无法与缩略图配对，失去缩小回原位的动画。
> - Viewer 必须是单张裸 `Image`，**不要用 Swiper 包裹**（多张 Image 同时持有不同 ID 会配对混乱），**不要添加额外 `@State`/`.transition()`**（干扰进入/退出配对时序）。

### 步骤 3：打开/关闭 Viewer — animateTo 驱动

```ts
private openViewer(postIndex: number, imgIndex: number) {
  this.viewerPostIndex = postIndex
  this.viewerImageIndex = imgIndex
  this.getUIContext()?.animateTo({ duration: 350, curve: curves.springMotion(0.6, 0.8) }, () => {
    this.showViewer = true
  })
}

private closeViewer() {
  this.getUIContext()?.animateTo({ duration: 350, curve: curves.springMotion(0.6, 0.8) }, () => {
    this.showViewer = false
  })
}
```

> **关键点：** 打开和关闭使用相同的 `curves.springMotion(0.6, 0.8)` 弹性曲线，保证正向/反向动画风格一致。

### 步骤 4：布局结构 — Stack 叠加

```ts
build() {
  Stack() {
    Column() {
      // 导航栏
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#333333')
          .margin({ right: 8 })
        Text('朋友圈图片浏览')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .padding({ left: 16, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      // 帖子列表
      List({ space: 0 }) {
        ForEach(this.posts, (post: MomentPost, postIndex: number) => {
          ListItem() {
            this.momentItem(post, postIndex)
          }
        }, (post: MomentPost) => post.id)
      }
      .layoutWeight(1)
      .width('100%')
      .divider({ strokeWidth: 0.5, color: '#eeeeee', startMargin: 76, endMargin: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)

    // 顶层：全屏 Viewer（条件渲染）
    if (this.showViewer && this.viewerPostIndex >= 0 && this.viewerImageIndex >= 0) {
      this.imageViewer()
    }
  }
  .width('100%')
  .height('100%')
}
```

### geometryTransition ID 配对规则总结

| 时机 | 缩略图 ID | Viewer 图片 ID | 效果 |
|---|---|---|---|
| Viewer 关闭（初始） | `moment_X_Y` | 不存在 | 缩略图正常显示 |
| Viewer 打开 | 匹配项 `''`（隐藏），其余保留 | `moment_X_Y`（始终） | 匹配图片从缩略图位置放大到全屏 |
| Viewer 关闭 | 匹配项恢复 `moment_X_Y` | `moment_X_Y`（始终持有） | 图片从全屏缩小回缩略图位置 |

---

## 场景2：卡片转场一镜到底

**场景描述：** 仿电商瀑布流，点击瀑布流卡片后卡片封面图放大过渡到全屏详情页，返回时详情页缩小回原卡片封面位置。

**解决方案：** 使用 **`WaterFlow` 瀑布流** + **`geometryTransition('cardImg_${index}')` 共享元素过渡** + **`curves.springMotion(0.6, 0.9)` 弹性曲线** + **`TransitionEffect.OPACITY` 详情页淡入淡出** + **`clip(true)` 裁剪**

> **核心原理：** 卡片封面图与详情页封面图通过相同的 `geometryTransition` ID 配对。点击卡片时缩略图 ID 置空，详情页封面图接管共享元素，实现从卡片位置到全屏的无缝放大过渡。

### 步骤 0：数据模型与状态变量

```ts
import { curves } from '@kit.ArkUI'

// 数据模型（id, title, content, authorName, imageSrc, avatorSrc，构造器省略）
class CardItemData { /* ... */ }

@Entry
@Component
struct CardTransitionPage {
  @State isDetailShow: boolean = false     // 详情页是否显示
  @State selectedIndex: number = 0         // 选中的卡片索引

  private dataSource: CardItemData[] = [ /* 卡片数据 */ ]
}
```

### 步骤 1：瀑布流卡片封面图 — geometryTransition 条件 ID

卡片封面图使用**条件 ID**：当选中该卡片且详情页显示时 ID 置空，否则保持 `cardImg_${index}`。

```ts
WaterFlow() {
  ForEach(this.dataSource, (item: CardItemData, index: number) => {
    FlowItem() {
      Column() {
        Image(item.imageSrc)
          .width('100%').objectFit(ImageFit.Cover)
          .geometryTransition(
            this.isDetailShow && this.selectedIndex === index ? '' : `cardImg_${index}`)
          .onClick(() => {
            if (this.isDetailShow) return          // 防重复点击
            this.selectedIndex = index
            this.getUIContext().animateTo({
              duration: 400, curve: curves.springMotion(0.6, 0.9)
            }, () => { this.isDetailShow = true })
          })

        // ... 标题、作者信息（普通 UI，省略）
      }.backgroundColor(Color.White).borderRadius(8)
    }.width('100%')
  })
}
.columnsTemplate('1fr 1fr').columnsGap(8).rowsGap(8)
```

> **关键点：**
> - 卡片封面图的 `geometryTransition` 使用条件三元：命中时置空 `''`，否则保持 `cardImg_${index}`
> - `if (this.isDetailShow) return` 防止详情页已显示时重复点击触发动画异常
> - `id('card_image_${index}')` 用于调试定位（非必须）

### 步骤 2：详情页封面图 — geometryTransition 始终持有 ID

详情页封面图**始终持有** `cardImg_${this.selectedIndex}`，不附加条件：

```ts
if (this.isDetailShow) {
  Scroll() {
    Column() {
      // 导航栏（返回按钮 onClick → animateTo springMotion → isDetailShow=false）
      // ...

      // 封面图 — 始终持有 ID
      Image(this.dataSource[this.selectedIndex].imageSrc)
        .width('100%').objectFit(ImageFit.Cover)
        .geometryTransition(`cardImg_${this.selectedIndex}`)   // 始终持有 ID
        .clip(true)

      // ... 标题、正文、作者信息（普通 UI，省略）
    }
  }
  .width('100%')
  .height('100%')
}
```

> **关键点：** 必须用 `List` + `ListItem` + `.divider()` 构建帖子列表，**不要用 `Scroll` + `Column` 替代**，否则可能影响 `geometryTransition` 的位置计算。

关键点：
- 详情页封面图 `geometryTransition` 使用 `cardImg_${this.selectedIndex}`，**不附加任何条件**
- **`.clip(true)`** 确保封面图在过渡过程中不溢出详情页边界
- **`TransitionEffect.OPACITY`** 让详情页整体（导航栏、标题、正文）淡入淡出，仅封面图通过 `geometryTransition` 实现共享元素过渡
- 返回按钮使用与打开时相同的 `springMotion(0.6, 0.9)` 曲线

### 步骤 3：布局结构 — Stack 叠加

```ts
build() {
  Stack() {
    // 底层：瀑布流列表
    Column({ space: 2 }) {
      WaterFlow() {
        // 步骤1中的卡片
      }
      .columnsTemplate('1fr 1fr')
      // ...
    }

    // 顶层：详情页（条件渲染）
    if (this.isDetailShow) {
      // 步骤2中的详情页
    }
  }
  .width('100%')
  .height('100%')
}
```

### geometryTransition ID 配对规则总结

| 时机 | 卡片封面 ID | 详情页封面 ID | 效果 |
|---|---|---|---|
| 详情页关闭（初始） | `cardImg_${index}` | 不存在 | 瀑布流卡片正常显示 |
| 详情页打开 | 选中项 `''`（隐藏），其余保留 | `cardImg_${selectedIndex}`（始终） | 封面图从卡片位置放大到全屏 |
| 详情页关闭 | 选中项恢复 `cardImg_${index}` | `cardImg_${selectedIndex}`（始终持有） | 封面图从全屏缩小回卡片位置 |

---

## 场景3：一镜到底搜索

**场景描述：** 仿搜索一镜到底，点击首页搜索框后搜索框无缝放大过渡为全屏搜索页，输入关键词后点击结果返回首页，搜索框缩小回原位。

**解决方案：** 使用 **`geometryTransition(id, {follow:true})`** + **`bindContentCover(modalTransition:NONE)`** + **`curves.interpolatingSpring` 插值弹簧** + **`TransitionEffect.asymmetric` 非对称转场**

### 步骤 0：状态变量与持久化

```ts
import { curves, promptAction } from '@kit.ArkUI'
import { inputMethod } from '@kit.IMEKit'

interface SearchItem {
  id: number
  name: string
  category: string
}

PersistentStorage.persistProp('searchHistoryData', '[]')

@Entry
@Component
struct GeometrySearchPage {
  @State isSearchPageShow: boolean = false   // 搜索页是否显示
  @State geometryId: string = ''             // geometryTransition 配对 ID
  @State searchText: string = ''             // 搜索页 Search 组件的 value
  @State searchInput: string = ''            // 实际搜索词（与 searchText 分离避免频繁触发）
  @State searchResults: SearchItem[] = []    // 搜索结果
  @StorageLink('searchHistoryData') searchHistoryData: string = '[]'  // 持久化搜索历史
  @State classifyIndex: number = -1          // 分类筛选索引
  @State categoryName: string = ''           // 分类名称

  private allItems: SearchItem[] = [
    { id: 1, name: '心跳点赞动画', category: '动效' },
    { id: 2, name: '水波纹特效', category: '动效' },
    { id: 6, name: 'Flex弹性布局', category: 'UI布局' },
    // ... 更多数据
  ]
  private searchClassifyData: string[] = ['UI布局', '动效', '三方库', 'Native', '性能示例', '其他']
}
```

> **关键点：** `searchText` 与 `searchInput` 分离 —— `searchText` 绑定 Search 组件的 `value`（含光标位置），`searchInput` 用于实际搜索逻辑，避免光标跳动。

### 步骤 1：首页搜索框 — geometryTransition + bindContentCover

```ts
Search({ placeholder: '搜索动画场景...' })
  .width('80%')
  .height(40)
  .backgroundColor('#E7E9E8')
  .borderRadius(20)
  // 禁止首页搜索框获焦弹键盘
  .focusOnTouch(false)
  .focusable(false)
  .enableKeyboardOnFocus(false)
  .geometryTransition(this.geometryId, { follow: true })
  .transition(TransitionEffect.OPACITY.animation({
    duration: 200,
    curve: curves.cubicBezierCurve(0.33, 0, 0.67, 1)
  }))
  .onClick(() => {
    this.onSearchClicked()
  })
  .bindContentCover(this.isSearchPageShow, this.searchPage(), {
    modalTransition: ModalTransition.NONE,     // 核心：禁用系统模态动画
    onDisappear: () => {
      this.onArrowClicked()                    // 处理系统手势返回
      this.searchText = ''
    }
  })
```

关键点：
- **`ModalTransition.NONE`** 禁用系统模态动画，仅保留 `geometryTransition` 实现一镜到底
- **`{follow: true}`** 让组件跟随共享元素运动
- `focusOnTouch(false)` + `focusable(false)` + `enableKeyboardOnFocus(false)` 三重保险阻止首页搜索框获焦弹出键盘
- `onDisappear` 处理系统手势返回，确保状态重置

### 步骤 2：搜索页 Search — geometryTransition 配对

```ts
@Builder
searchPage() {
  Column() {
    Row() {
      // 返回按钮 — asymmetric 非对称转场（进入 delay:150，退出无延迟）
      Text('←').onClick(() => { this.onArrowClicked() })
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.opacity(0).animation({ duration: 200, delay: 150 }),
          TransitionEffect.opacity(0).animation({ duration: 200 }),
        ))

      // 搜索框 — 与首页搜索框配对
      Search({ value: this.searchText, placeholder: '搜索动画场景...' })
        .defaultFocus(true)                                      // 自动获焦弹键盘
        .geometryTransition(this.geometryId, { follow: true })   // 与首页搜索框配对
        .onChange((value: string) => {
          this.searchText = value; this.searchInput = value
          this.doSearch(value, this.categoryName)
        })
    }.margin({ top: 50 })

    // 分类筛选区域（Grid + toggle 点击逻辑，普通 UI 省略）

    // 搜索历史区域（visibility + asymmetric + translate({ y: 30 }) 滑入/滑出）
    // .visibility(searchText.length === 0 && searchResults.length === 0 ? Visible : None)
    // .transition(TransitionEffect.asymmetric(...))

    // 搜索结果列表（List + ForEach → onClick 调用 onItemClicked）
    // .transition({ opacity: 0 })
  }
  .backgroundColor(Color.White)
  .transition(TransitionEffect.opacity(0))    // 模态整体淡出
}
```

关键点：
- 搜索页 Search 使用 **相同的 `geometryId`** 与首页搜索框配对，形成共享元素过渡
- **`defaultFocus(true)`** 搜索页打开后自动获焦弹出键盘
- **返回按钮 `asymmetric` 转场**：进入 `delay: 150`（等搜索框先过渡完成），退出无延迟
- 搜索历史区域使用 `visibility` + `TransitionEffect.asymmetric` + `translate({ y: 30 })` 实现滑入/滑出

### 步骤 3：打开搜索页 — interpolatingSpring 触发

```ts
private onSearchClicked(): void {
  this.geometryId = 'search'            // 设置配对 ID
  this.getUIContext()?.animateTo({
    duration: 100,                       // 极短时长（弹簧参数控制实际时长）
    curve: curves.interpolatingSpring(0, 1, 324, 38)  // stiffness=324, damping=38
  }, () => {
    this.isSearchPageShow = true
  })
}
```

### 步骤 4：关闭搜索页 — 三种关闭路径

> **核心原则：所有关闭路径都必须设置 `this.geometryId = 'search'`，确保 `geometryTransition` 配对生效，搜索框能缩小回原位。**

```ts
// 路径1：点击返回箭头 — 弹簧动画 + 完整重置
private onArrowClicked(): void {
  this.geometryId = 'search'
  this.getUIContext()?.animateTo({
    curve: curves.interpolatingSpring(0, 1, 342, 38)
  }, () => {
    this.searchResults = []
    this.isSearchPageShow = false
    this.classifyIndex = -1
    this.searchInput = ''
    this.categoryName = ''
    this.searchText = ''
  })
}

// 路径2：点击搜索结果 — 极短动画快速关闭 + 保存搜索历史
private onItemClicked(item: SearchItem): void {
  // 保存到搜索历史（去重、限20条、PersistentStorage 持久化）
  let history = this.getHistoryList()
  const idx = history.indexOf(item.name)
  if (idx !== -1) history.splice(idx, 1)
  history.unshift(item.name)
  if (history.length > 20) history = history.slice(0, 20)
  this.saveHistory(history)

  this.geometryId = 'search'
  this.getUIContext()?.animateTo({
    curve: Curve.Ease,
    duration: 20                          // 极短时长，快速收起
  }, () => {
    this.searchResults = []
    this.isSearchPageShow = false
  })
}

// 路径3：系统手势返回 — bindContentCover 的 onDisappear 回调（步骤1中配置）
```

### geometryTransition 一镜到底原理总结

| 组件 | geometryTransition | 作用 |
|---|---|---|
| 首页搜索框 | `this.geometryId, { follow: true }` | 源端：搜索框缩小消失 |
| 搜索页 Search | `this.geometryId, { follow: true }` | 目标端：搜索框放大出现 |
| `bindContentCover` | `modalTransition: ModalTransition.NONE` | 禁用系统模态动画，仅保留几何过渡 |
| `animateTo` | `interpolatingSpring(0, 1, 324, 38)` | 弹簧曲线驱动状态变化 |

首页搜索框与搜索页 Search 通过相同 `geometryId` 配对。打开时搜索框放大为全屏搜索页 Search，关闭时搜索页 Search 缩小回搜索框位置。`ModalTransition.NONE` 确保无系统默认的上下滑入动画干扰一镜到底效果。

### 关闭路径对比

| 关闭路径 | 动画曲线 | duration | 特殊处理 |
|---|---|---|---|
| 点击返回箭头 | `interpolatingSpring(0,1,342,38)` | 弹簧自决 | 重置所有搜索状态 |
| 点击搜索结果 | `Curve.Ease` | 20ms | 保存搜索历史，快速收起 |
| 系统手势返回 | `interpolatingSpring(0,1,342,38)` | 弹簧自决 | 走 `onArrowClicked()`，重置状态 |

---

## 场景4：卡片展开详情

**场景描述：** 仿商品卡片展开，点击列表中的卡片后封面图从卡片位置展开为全屏详情页，封面图节点在卡片和详情页之间复用，返回时收起回卡片。

**解决方案：** 使用 **`NodeController` + `BuilderNode` 封面图节点复用** + **`getComponentUtils().getRectangleById()` 获取位置** + **`curves.springMotion(0.6,0.9)` 弹性展开** + **`position` / `translate` / `height` 属性插值动画**

> **核心原理：** `NodeController` 封装的 `BuilderNode` 节点可以在不同父容器间迁移（从卡片容器移到展开页容器），实现封面图节点的**真正复用**（而非销毁重建）。配合 `position` / `translate` / `height` 三属性动画，实现"卡片从原位展开为全屏"的一镜到底效果。

### 步骤 0：数据模型与 Builder 定义 [辅助]

> 纯数据结构定义和基础 Builder，为后续步骤提供类型基础。

```ts
import { NodeController, BuilderNode, FrameNode, UIContext, curves } from '@kit.ArkUI'

// 数据模型（id, coverSrc, title, source, time, summary, tag，构造器省略）
class FeedCard { /* ... */ }

interface CardNodeData {
  coverSrc: Resource
  isExpand: boolean           // 控制封面图尺寸：展开 220vp / 收起 80vp
}

// 封面图 Builder — 根据 isExpand 切换尺寸和圆角
@Builder
function cardCoverBuilder(data: CardNodeData) {
  Image(data.coverSrc)
    .width('100%')
    .height(data.isExpand ? 220 : 80)
    .objectFit(ImageFit.Cover)
    .borderRadius(data.isExpand ? 0 : 6)
    .syncLoad(true)
}
```

### 步骤 1：CardNodeCtrl — NodeController 封装 [核心]

> 整个场景的核心机制。封装 `BuilderNode` 实现节点在不同容器间的迁移（`onRemove`/`makeNode`/`update`），没有它节点复用无法实现。

```ts
class RectResult {
  left: number = 0
  top: number = 0
  width: number = 0
  height: number = 0
}

class CardNodeCtrl extends NodeController {
  private node: BuilderNode<CardNodeData[]> | null = null
  private isRemove: boolean = false
  private data: CardNodeData | null = null
  private callback: Function | undefined = undefined

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.isRemove) return null
    if (this.node != null) return this.node.getFrameNode()
    return null
  }

  init(uiContext: UIContext, coverSrc: Resource, isExpand: boolean) {
    if (this.node != null) return               // 防重复初始化
    this.node = new BuilderNode(uiContext)
    this.data = { coverSrc: coverSrc, isExpand: isExpand }
    this.node.build(wrapBuilder<CardNodeData[]>(cardCoverBuilder), this.data)
  }

  update(isExpand: boolean) {
    if (this.node !== null && this.data !== null) {
      this.data.isExpand = isExpand
      this.node.update(this.data)               // 更新 BuilderNode 数据触发重渲染
    }
  }

  setCallback(cb: Function | undefined) {
    this.callback = cb                           // 收起完成后回调（恢复卡片中的 NodeContainer）
  }

  callCallback() {
    if (this.callback != undefined) this.callback()
  }

  onRemove() {
    this.isRemove = true
    this.rebuild()                               // 触发 makeNode 返回 null → 卡片中 NodeContainer 消失
    this.isRemove = false
  }
}

// 全局节点映射表 — 通过卡片 ID 获取对应 NodeController
let gNodeMap: Map<string, CardNodeCtrl> = new Map()

function createCardNode(id: string): CardNodeCtrl {
  let node = new CardNodeCtrl()
  gNodeMap.set(id, node)
  return node
}

function getCardNode(id: string): CardNodeCtrl | undefined {
  return gNodeMap.get(id)
}
```

> **关键点：**
> - `onRemove()` 通过 `isRemove` 标志让 `makeNode` 返回 `null`，实现从卡片容器中"移除"节点，但 `BuilderNode` 实例本身仍然存活，可以被展开页的 `NodeContainer` 接管
> - `update(isExpand)` 更新 `BuilderNode` 的数据，封面图在 80vp ↔ 220vp 之间切换
> - 全局 `gNodeMap` 确保展开页能通过卡片 ID 拿到同一个 `NodeController` 实例

### 步骤 2：AnimationProps — 动画属性与位置计算 [核心]

> 展开动画的驱动逻辑。`expandAnimation`/`collapseAnimation` 通过 `animateTo` + `springMotion` 驱动 `position`/`translate`/`height` 三属性，`calculateData` 通过 `getRectangleById` 计算位移量。

```ts
@Observed
class AnimationProps {
  isExpandPageShow: boolean = false
  isEnabled: boolean = true                  // 动画期间禁用交互
  curIndex: number = -1
  translateX: number = 0
  translateY: number = 0
  positionX: number = 0                      // 初始位置（卡片位置）
  positionY: number = 0
  changedHeight: boolean = false             // 控制 height 在全屏/卡片尺寸间切换
  private calculatedTranslateX: number = 0   // 展开目标 translate（归零到全屏）
  private calculatedTranslateY: number = 0
  private uiContext: UIContext | null = null

  setUIContext(ctx: UIContext) {
    this.uiContext = ctx
  }

  expandAnimation(index: number) {
    if (index != undefined) this.curIndex = index
    this.calculateData(index.toString())     // 读取卡片在屏幕上的位置
    this.isExpandPageShow = true
    this.uiContext?.animateTo({ curve: curves.springMotion(0.6, 0.9) }, () => {
      this.translateX = this.calculatedTranslateX   // 平移到全屏原点
      this.translateY = this.calculatedTranslateY
      this.changedHeight = true                      // height 从卡片高度 → 100%
    })
  }

  collapseAnimation(onFinish: () => void) {
    this.uiContext?.animateTo({
      curve: curves.springMotion(0.6, 0.9),
      onFinish: onFinish
    }, () => {
      this.translateX = 0                    // 平移回卡片原位
      this.translateY = 0
      this.changedHeight = false             // height 从 100% → 卡片高度
    })
  }

  calculateData(key: string) {
    if (this.uiContext === null) return
    // 通过 key（卡片 ID）获取卡片在屏幕上的位置
    let clickedInfo = this.getRectInfoById(this.uiContext, key)
    let rootInfo = this.getRectInfoById(this.uiContext, 'rootStack')
    // position: 展开页初始放在卡片位置
    this.positionX = this.uiContext.px2vp(clickedInfo.left - rootInfo.left)
    this.positionY = this.uiContext.px2vp(clickedInfo.top - rootInfo.top)
    // translate: 展开动画的位移量（从卡片位置 → 全屏原点）
    this.calculatedTranslateX = this.uiContext.px2vp(rootInfo.left - clickedInfo.left)
    this.calculatedTranslateY = this.uiContext.px2vp(rootInfo.top - clickedInfo.top)
  }

  private getRectInfoById(ctx: UIContext, id: string): RectResult {
    let info = ctx.getComponentUtils().getRectangleById(id)
    let wGap = info.size.width * (1 - info.scale.x) / 2
    let hGap = info.size.height * (1 - info.scale.y) / 2
    let rst = new RectResult()
    rst.left = info.translate.x + info.windowOffset.x + wGap
    rst.top = info.translate.y + info.windowOffset.y + hGap
    rst.width = info.size.width - wGap * 2
    rst.height = info.size.height - hGap * 2
    return rst
  }
}
```

> **关键点：** `position` 和 `translate` 配合使用 —— 展开页初始通过 `position` 定位在卡片位置，动画通过 `translate` 平移到全屏原点（0,0）。`changedHeight` 控制 `height` 在卡片高度（~100vp）和 100% 之间切换。

### 步骤 3：卡片列表 — 点击触发节点迁移 [核心]

> 展开动画的触发入口。`onClick` 中调用 `onRemove()` 从卡片移除节点 + 调用 `expandAnimation` 启动展开动画。

```ts
@Component
struct CardItem {
  @Prop index: number = 0
  @Prop card: FeedCard | null = null
  @Link animationProps: AnimationProps
  @State nodeController: CardNodeCtrl | undefined = undefined

  aboutToAppear() {
    if (this.card != null) {
      let node = createCardNode(this.card.id)
      node.init(this.getUIContext(), this.card.coverSrc, false)
      node.setCallback(() => {                          // 收起完成后恢复卡片中的 NodeContainer
        this.nodeController = getCardNode(this.card!.id)
      })
      this.nodeController = node
    }
  }

  build() {
    Row() {
      Stack() {
        NodeContainer(this.nodeController)               // 封面图节点
      }
      .width(110).height(80)
      .key(this.card?.id ?? '')                          // key 用于 getRectangleById 定位

      // ... 标题、标签、来源、时间（普通 UI，省略）
    }
    .onClick(() => {
      this.nodeController?.onRemove()                    // 从卡片移除节点
      this.animationProps.isEnabled = false              // 禁用交互
      this.animationProps.expandAnimation(this.index)
    })
  }
}
```

### 步骤 4：展开页 — 接管节点 + 展开内容 [核心]

> 节点迁移的目标端。`aboutToAppear` 中通过 `getCardNode` 获取同一 NodeController + `update(true)` 切换展开尺寸，配合步骤 2 的动画属性绑定实现展开效果。

```ts
@Component
struct ExpandPage {
  @Link animationProps: AnimationProps
  @Prop cards: FeedCard[] = []
  @State nodeController: CardNodeCtrl | undefined = undefined

  aboutToAppear() {
    let card = this.cards[this.animationProps.curIndex]
    this.nodeController = getCardNode(card.id)        // 获取同一个 NodeController
    this.nodeController?.update(true)                  // 切换为展开尺寸（220vp）
  }

  build() {
    Column() {
      // 导航栏（返回按钮 onClick → update(false) + collapseAnimation(onFinish)）
      Row() {
        Text('‹').onClick(() => {
          this.nodeController?.update(false)           // 先切换为收起尺寸
          this.animationProps.collapseAnimation(() => {
            this.nodeController?.callCallback()        // 通知卡片恢复 NodeContainer
            this.nodeController?.onRemove()            // 从展开页移除节点
            this.animationProps.isExpandPageShow = false
            this.animationProps.isEnabled = true       // 恢复交互
          })
        })
      }

      Scroll() {
        Column() {
          Stack() {
            NodeContainer(this.nodeController)          // 同一个节点实例
          }.width('100%').height(220)

          // ... 详情标题、作者信息、正文（普通 UI，省略）
        }
      }.layoutWeight(1)
    }
    .height(this.animationProps.changedHeight ? '100%' : 100)  // 全屏 ↔ 卡片高度
    .translate({ x: this.animationProps.translateX, y: this.animationProps.translateY })
    .position({ x: this.animationProps.positionX, y: this.animationProps.positionY })
    .transition(TransitionEffect.OPACITY)
  }
}
```

### 步骤 5：主页面布局 [辅助]

> 纯页面布局，Stack 叠加卡片列表和展开页，绑定 `isExpandPageShow` 条件渲染。无动画逻辑。

```ts
@Entry
@Component
struct CardExpandPage {
  @State animationProps: AnimationProps = new AnimationProps()

  aboutToAppear() { this.animationProps.setUIContext(this.getUIContext()) }

  build() {
    Stack() {
      Column() {
        // ... 导航栏 + List（ForEach → CardItem）
      }

      if (this.animationProps.isExpandPageShow) {
        ExpandPage({ animationProps: this.animationProps, cards: this.cards })
      }
    }
    .key('rootStack')                          // 供 calculateData 定位参考原点
    .enabled(this.animationProps.isEnabled)    // 动画期间禁用交互
  }
}
```

### 节点迁移流程总结

```
卡片列表                    展开页
┌─────────────┐            ┌─────────────────┐
│ NodeContainer│            │                 │
│  (节点在此)  │  onRemove  │                 │
│      ↓      │ ─────────→ │  (节点迁移至此)  │
│  (空)       │            │  NodeContainer  │
│             │            │  update(true)   │
│             │            │  height: 220vp  │
└─────────────┘            └─────────────────┘
                                ←── collapseAnimation(onFinish)
                                │
                                ↓ onRemove + callCallback
┌─────────────┐            ┌─────────────────┐
│ NodeContainer│  callback  │                 │
│  (节点恢复)  │ ←───────── │    (空)          │
│  update(false)│           │                 │
│  height: 80vp │           │                 │
└─────────────┘            └─────────────────┘
```

| 阶段 | 节点位置 | isExpand | 封面高度 | 展开页 height | 展开页 position |
|---|---|---|---|---|---|
| 初始 | 卡片 | false | 80vp | 不存在 | 不存在 |
| 点击卡片 | 卡片 → 展开页 | false → true | 80vp → 220vp | 100vp | 卡片位置 |
| 展开动画中 | 展开页 | true | 220vp | 100vp → 100% | 卡片位置 → 原点（via translate） |
| 展开完成 | 展开页 | true | 220vp | 100% | (0, 0) |
| 点击返回 | 展开页 | true → false | 220vp → 80vp | 100% → 100vp | 原点 → 卡片位置（via translate） |
| 收起完成 | 展开页 → 卡片 | false | 80vp | 不存在 | 不存在 |

---

## 场景5：新闻封面→详情

**场景描述：** 仿新闻 Feed 流转场，点击新闻列表中的卡片后封面图从卡片位置展开为全屏新闻详情页，列表页同步淡出，返回时封面图缩小回列表中的卡片位置。

**解决方案：** 使用 **`Navigation.customNavContentTransition`** + **`CustomTransition` 单例注册转场回调** + **`CoverNodeController` 跨页面共享封面** + **`interpolatingSpring` + `scale/translate/clip` 组合动画**

> **与场景5的区别：** 场景5是在同一页面内的 Stack 叠加层之间迁移节点；场景6是在 Navigation 的两个 NavDestination 页面之间迁移节点，需要通过 `customNavContentTransition` 自定义转场动画来协调跨页面的节点共享和动画时序。

### 步骤 0：数据模型、工具类与路由配置 [辅助]

> 纯数据模型定义、`ComponentAttrUtils` 位置获取工具类和 **`route_map.json` 路由配置**，为后续步骤提供数据和路由基础。

> **⚠️ 关键配置：`route_map.json` 必须存在！**
>
> 跨页面转场使用 `Navigation.customNavContentTransition`，其回调参数 `NavContentInfo.name` 需要通过 `route_map.json` 注册的页面名称来获取。如果缺少此配置文件，`from.name`/`to.name` 将为空字符串，导致 `isCustomTransitionEnabled` 返回 `false`，`customNavContentTransition` 返回 `undefined`，系统将使用**默认的水平滑入动画**（平移效果），而不是我们期望的**缩放+裁剪+偏移组合动画**。
>
> 文件路径：`entry/src/main/resources/base/profile/route_map.json`
>
> ```json
> {
>   "routerMap": [
>     {
>       "name": "NewsList",
>       "pageSourceFile": "src/main/ets/pages/sharedanimation/newsdetail/NewsListPage.ets",
>       "buildFunction": "NewsListBuilder"
>     },
>     {
>       "name": "NewsDetailContent",
>       "pageSourceFile": "src/main/ets/pages/sharedanimation/newsdetail/NewsDetailContent.ets",
>       "buildFunction": "NewsDetailBuilder"
>     }
>   ]
> }
> ```
>
> 每个 NavDestination 页面文件必须导出对应的 `@Builder` 函数：
> ```ts
> // NewsListPage.ets
> @Builder
> export function NewsListBuilder() {
>   NewsListPage()
> }
>
> // NewsDetailContent.ets
> @Builder
> export function NewsDetailBuilder() {
>   NewsDetailContent()
> }
> ```
>
> **缺少 `route_map.json` 的后果**：`customNavContentTransition` 无法匹配页面名称，始终返回 `undefined`，转场动画退化为系统默认的水平滑入（平移效果），完全丧失缩放展开的视觉效果。

```ts
// NewsData.ets
export class NewsItem {
  id: string
  coverSrc: Resource
  avatarSrc: Resource
  title: string
  author: string
  time: string
  summary: string
  category: string
  // constructor...
}

export const NEWS_DATA: NewsItem[] = [
  new NewsItem('1', $r('app.media.transitionanimation_image1'), $r('app.media.transitionanimation_avator1'),
    '云南大理：苍山洱海间的诗意栖居', '旅行者小王', '2小时前', '...', '旅行'),
  // ... 更多新闻数据
]
```

```ts
// ComponentAttrUtils.ets — 组件位置获取工具
import { UIContext } from '@kit.ArkUI'

export class RectInfoInPx {
  left: number = 0
  top: number = 0
  right: number = 0
  bottom: number = 0
  width: number = 0
  height: number = 0
}

export class ComponentAttrUtils {
  public static getRectInfoById(context: UIContext, id: string): RectInfoInPx {
    let componentInfo = context.getComponentUtils().getRectangleById(id)
    let rstRect = new RectInfoInPx()
    let widthScaleGap = componentInfo.size.width * (1 - componentInfo.scale.x) / 2
    let heightScaleGap = componentInfo.size.height * (1 - componentInfo.scale.y) / 2
    rstRect.left = componentInfo.translate.x + componentInfo.windowOffset.x + widthScaleGap
    rstRect.top = componentInfo.translate.y + componentInfo.windowOffset.y + heightScaleGap
    rstRect.right = componentInfo.translate.x + componentInfo.windowOffset.x + componentInfo.size.width - widthScaleGap
    rstRect.bottom = componentInfo.translate.y + componentInfo.windowOffset.y + componentInfo.size.height - heightScaleGap
    rstRect.width = rstRect.right - rstRect.left
    rstRect.height = rstRect.bottom - rstRect.top
    return rstRect
  }
}
```

### 步骤 1：CustomTransition 单例 — 跨页面转场回调注册 [核心]

> 跨页面转场的调度中枢。`CustomTransition` 单例用 `Map<pageId, AnimateCallback>` 存储回调，`Navigation.customNavContentTransition` 通过它查找并触发转场动画。

```ts
// CustomNavigationUtils.ets
export interface AnimateCallback {
  animation: ((isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void) | undefined
  timeout: number | undefined
}

const customTransitionMap: Map<number, AnimateCallback> = new Map()

export class CustomTransition {
  private constructor() {}
  static delegate: CustomTransition = new CustomTransition()
  static getInstance(): CustomTransition { return CustomTransition.delegate }

  registerNavParam(id: number,
    animationCallback: (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => void,
    timeout: number): void {
    if (customTransitionMap.has(id)) {
      let param = customTransitionMap.get(id)
      if (param != undefined) {
        param.animation = animationCallback
        param.timeout = timeout
        return
      }
    }
    customTransitionMap.set(id, { timeout: timeout, animation: animationCallback })
  }

  unRegisterNavParam(id: number): void {
    customTransitionMap.delete(id)
  }

  getAnimateParam(id: number): AnimateCallback {
    return {
      animation: customTransitionMap.get(id)?.animation,
      timeout: customTransitionMap.get(id)?.timeout,
    }
  }
}
```

> **关键点：** 单例 `CustomTransition` 用 `Map<pageId, AnimateCallback>` 存储每个 NavDestination 注册的转场回调。`Navigation.customNavContentTransition` 回调中通过 `from.index` 和 `to.index`（页面在 NavPathStack 中的位置）查找对应回调。

### 步骤 2：CoverNodeController — 跨页面封面节点共享 [核心]

> 跨页面共享封面节点的封装。`NodeController` 封装 `BuilderNode`，支持 `updateSize` 动态切换封面尺寸，实现跨 NavDestination 页面的节点复用。

```ts
// CoverNodeController.ets
import { NodeController, BuilderNode, FrameNode, UIContext } from '@kit.ArkUI'

interface CoverNodeData {
  imageSrc: Resource
  width: number | string
  height: number | string
  borderRadius: number
  objectFit: ImageFit
}

@Builder
function coverBuilder(data: CoverNodeData) {
  Image(data.imageSrc)
    .width(data.width)
    .height(data.height)
    .borderRadius(data.borderRadius)
    .objectFit(data.objectFit)
    .syncLoad(true)
}

export class CoverNodeController extends NodeController {
  private cardNode: BuilderNode<CoverNodeData[]> | null = null
  private isRemove: boolean = false
  private data: CoverNodeData | null = null

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.isRemove) return null
    if (this.cardNode != null) return this.cardNode.getFrameNode()
    return null
  }

  init(uiContext: UIContext, imageSrc: Resource, width: number | string, height: number | string,
       borderRadius: number, objectFit: ImageFit) {
    if (this.cardNode != null) return
    this.cardNode = new BuilderNode(uiContext)
    this.data = { imageSrc, width, height, borderRadius, objectFit }
    this.cardNode.build(wrapBuilder<CoverNodeData[]>(coverBuilder), this.data)
  }

  updateSize(width: number | string, height: number | string, borderRadius: number) {
    if (this.cardNode !== null && this.data !== null) {
      this.data.width = width
      this.data.height = height
      this.data.borderRadius = borderRadius
      this.cardNode.update(this.data)
    }
  }

  onRemove() {
    this.isRemove = true
    this.rebuild()
    this.isRemove = false
  }
}
```

### 步骤 3：AnimationProperties — 展开/收起动画计算 [核心]

> 动画算法核心。`doAnimation` 计算缩放比例、偏移量、裁剪尺寸，用 `interpolatingSpring` 驱动进入动画、`EaseInOut` 驱动退出动画。

```ts
// AnimationProperties.ets
import { curves, UIContext } from '@kit.ArkUI'
import { RectInfoInPx } from './ComponentAttrUtils'

@Observed
export class AnimationProperties {
  navDestinationBgColor: ResourceColor = Color.Transparent
  translateX: number = 0
  translateY: number = 0
  scaleValue: number = 1        // 封面缩放比例
  clipWidth: Dimension = '100%'  // 裁剪宽度
  clipHeight: Dimension = '100%' // 裁剪高度
  showDetailContent: boolean = false
  private uiContext: UIContext

  constructor(uiContext: UIContext) {
    this.uiContext = uiContext
  }

  public doAnimation(
    cardItemInfoPx: RectInfoInPx,
    isPush: boolean,
    isExit: boolean,
    transitionProxy: NavigationTransitionProxy,
    prePageOnFinish: () => void
  ): void {
    // 获取屏幕尺寸（通过 newsRoot 容器的位置）
    let winRect = this.uiContext.getComponentUtils().getRectangleById('newsRoot')
    let winW = winRect.size.width
    let winH = winRect.size.height

    // 计算缩放比例：取宽高比中较大的值
    let widthScaleRatio = cardItemInfoPx.width / winW
    let heightScaleRatio = cardItemInfoPx.height / winH
    let isUseWidthScale = widthScaleRatio > heightScaleRatio
    let initScale: number = isUseWidthScale ? widthScaleRatio : heightScaleRatio

    // 计算初始偏移量和裁剪尺寸
    let initTranslateX: number = 0
    let initTranslateY: number = 0
    let initClipWidth: Dimension = '100%'
    let initClipHeight: Dimension = '100%'

    if (isUseWidthScale) {
      initClipHeight = this.uiContext.px2vp(cardItemInfoPx.height / initScale)
      initTranslateX = this.uiContext.px2vp(cardItemInfoPx.left - (winW - cardItemInfoPx.width) / 2)
      initTranslateY = this.uiContext.px2vp(cardItemInfoPx.top) - initClipHeight * (1 - initScale) / 2
    } else {
      initClipWidth = this.uiContext.px2vp(cardItemInfoPx.width / initScale)
      initTranslateY = this.uiContext.px2vp(cardItemInfoPx.top - (winH - cardItemInfoPx.height) / 2)
      initTranslateX = this.uiContext.px2vp(cardItemInfoPx.left) - initClipWidth * (1 - initScale) / 2
    }

    if (isPush && !isExit) {
      // 进入动画：从卡片尺寸展开到全屏
      this.scaleValue = initScale
      this.translateX = initTranslateX
      this.translateY = initTranslateY
      this.clipWidth = initClipWidth
      this.clipHeight = initClipHeight

      this.uiContext.animateTo({
        curve: curves.interpolatingSpring(0, 1, 328, 36),
        onFinish: () => { transitionProxy?.finishTransition() }
      }, () => {
        this.scaleValue = 1.0
        this.translateX = 0
        this.translateY = 0
        this.clipWidth = '100%'
        this.clipHeight = '100%'
        this.showDetailContent = true    // 展开完成后显示详情内容
      })

      // 背景色从透明过渡到不透明白色
      this.uiContext.animateTo({
        duration: 100, curve: Curve.Sharp
      }, () => {
        this.navDestinationBgColor = '#00ffffff'
      })
    } else if (!isPush && isExit) {
      // 退出动画：从全屏缩小回卡片尺寸
      this.uiContext.animateTo({
        duration: 350, curve: Curve.EaseInOut,
        onFinish: () => {
          transitionProxy?.finishTransition()
          prePageOnFinish()
        }
      }, () => {
        this.scaleValue = initScale
        this.translateX = initTranslateX
        this.translateY = initTranslateY
        this.clipWidth = initClipWidth
        this.clipHeight = initClipHeight
        this.showDetailContent = false   // 收起时隐藏详情内容
      })

      this.uiContext.animateTo({
        duration: 200, delay: 150, curve: Curve.Friction
      }, () => {
        this.navDestinationBgColor = Color.Transparent
      })
    }
  }
}
```

> **关键点：**
> - **缩放计算**：取卡片宽高比与屏幕宽高比中差异较大的方向作为缩放基准，确保封面图完整填充
> - **偏移修正公式**：`initTranslateY` 和 `initTranslateX` 必须减去 `clipHeight/clipWidth * (1 - initScale) / 2`。这是因为 scale 缩放从中心点开始，而 translate 需要补偿缩放产生的中心偏移，否则封面图在展开/收起过程中会偏离卡片位置。遗漏此修正项会导致封面图垂直/水平方向偏移约半屏距离，效果严重崩塌。
> - **进入动画用 `interpolatingSpring`**（弹性展开），**退出动画用 `EaseInOut`**（平滑收起）
> - `showDetailContent` 控制详情文字内容的显隐，仅在全屏展开后才显示
> - `navDestinationBgColor` 从透明渐变到不透明白色，防止收起时露出底层内容

### 步骤 4：NewsDetailPage — Navigation 宿主 [辅助]

> Navigation 容器配置。将 `customNavContentTransition` 连接到 CustomTransition 单例，做路由判断和回调分发。无动画计算逻辑。

```ts
// NewsDetailPage.ets — @Entry 页面，承载 Navigation
@Entry
@Component
struct NewsDetailPage {
  private pageInfos: NavPathStack = new NavPathStack()
  private allowedFromPage: string[] = ['NewsList']
  private allowedToPage: string[] = ['NewsDetailContent']

  aboutToAppear(): void {
    this.pageInfos.pushPath({ name: 'NewsList' })
  }

  // 仅允许 NewsList ↔ NewsDetailContent 之间使用自定义转场
  private isCustomTransitionEnabled(fromName: string, toName: string): boolean {
    if ((this.allowedFromPage.includes(fromName) && this.allowedToPage.includes(toName)) ||
      (this.allowedFromPage.includes(toName) && this.allowedToPage.includes(fromName))) {
      return true
    }
    return false
  }

  build() {
    Navigation(this.pageInfos)
      .hideNavBar(true)
      .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => {
        if (!from || !to || !from.name || !to.name) return undefined
        if (!this.isCustomTransitionEnabled(from.name, to.name)) return undefined

        let fromParam = CustomTransition.getInstance().getAnimateParam(from.index)
        let toParam = CustomTransition.getInstance().getAnimateParam(to.index)
        if (!fromParam.animation || !toParam.animation) return undefined

        let customAnimation: NavigationAnimatedTransition = {
          onTransitionEnd: (_isSuccess: boolean) => {},
          timeout: 2000,
          transition: (transitionProxy: NavigationTransitionProxy) => {
            // from 页面执行退出动画（列表淡出）
            if (fromParam.animation) {
              fromParam.animation(operation === NavigationOperation.PUSH, true, transitionProxy)
            }
            // to 页面执行进入动画（封面展开）
            if (toParam.animation) {
              toParam.animation(operation === NavigationOperation.PUSH, false, transitionProxy)
            }
          }
        }
        return customAnimation
      })
  }
}
```

> **关键点：**
> - `customNavContentTransition` 的回调参数 `from.index` / `to.index` 是页面在 NavPathStack 中的索引，与 `onReady` 中 `context.pathStack.getAllPathName().length - 1` 的值一致。
> - **`route_map.json` 必须在 `entry/src/main/resources/base/profile/` 目录下存在**（见步骤0）。缺少此文件会导致 `from.name`/`to.name` 为空字符串，`isCustomTransitionEnabled` 返回 `false`，`customNavContentTransition` 返回 `undefined`，转场退化为系统默认的水平滑入动画（平移效果）。
> - `customNavContentTransition` 回调中的三个返回 `undefined` 的条件都必须避免：① `!from || !to` ② `!from.name || !to.name`（需要 route_map.json）③ `!fromParam.animation || !toParam.animation`（需要 onReady 中注册回调）。

### 步骤 5：NewsListPage — 列表页注册淡出动画 [辅助]

> 列表页 UI + 注册 `listOpacity` 淡出回调 + 点击跳转传参。列表本身为普通 List 布局，动画仅为整体 opacity 变化。

```ts
// NewsListPage.ets
@Component
export struct NewsListPage {
  pageInfos: NavPathStack = new NavPathStack()
  pageId: number = -1
  @State listOpacity: number = 1

  private doFinishTransition(): void {}

  private registerCustomTransition(): void {
    CustomTransition.getInstance().registerNavParam(this.pageId,
      (isPush: boolean, isExit: boolean, transitionProxy: NavigationTransitionProxy) => {
        // 列表页仅在 push+退出(opacity→0) 和 pop+不退出(opacity→1) 时参与
        if (isPush && isExit) {
          this.getUIContext().animateTo({
            duration: 350, curve: Curve.EaseInOut,
            onFinish: () => { transitionProxy?.finishTransition() }
          }, () => { this.listOpacity = 0 })
        } else if (!isPush && !isExit) {
          this.getUIContext().animateTo({
            duration: 350, curve: Curve.EaseInOut,
            onFinish: () => { transitionProxy?.finishTransition() }
          }, () => { this.listOpacity = 1 })
        }
      }, 500)
  }

  build() {
    NavDestination() {
      Column() {
        // ... 导航栏
        List() {
          ForEach(NEWS_DATA, (item: NewsItem, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(item.summary)
                      .fontSize(13)
                      .fontColor('#999999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 6 })
                    Row() {
                      Image(item.avatarSrc)
                        .width(18).height(18).borderRadius(9).objectFit(ImageFit.Cover)
                      Text(item.author)
                        .fontSize(12).fontColor('#888888').margin({ left: 6 })
                      Text(item.category)
                        .fontSize(11).fontColor('#ff6b35')
                        .backgroundColor('#fff3ed').borderRadius(3)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                        .margin({ left: 10 })
                      Blank()
                      Text(item.time).fontSize(11).fontColor('#cccccc')
                    }
                    .margin({ top: 10 }).width('100%')
                  }
                  .layoutWeight(1).margin({ right: 12 }).alignItems(HorizontalAlign.Start)

                  Image(item.coverSrc)
                    .width(110).height(76).borderRadius(6)
                    .key(`card_${index}`)     // 供 ComponentAttrUtils 定位
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .onClick(() => {
                  // 获取卡片位置 + 传递参数到详情页
                  let cardItemInfo = ComponentAttrUtils.getRectInfoById(
                    this.getUIContext(), `card_${index}`)
                  let param: Record<string, Object> = {}
                  param['cardItemInfo'] = cardItemInfo
                  param['cardIndex'] = index
                  param['coverSrc'] = item.coverSrc
                  param['doDefaultTransition'] = () => { this.doFinishTransition() }
                  this.pageInfos.pushPath({ name: 'NewsDetailContent', param: param })
                })
              }
              .alignItems(HorizontalAlign.Start)
            }
          }, (item: NewsItem) => item.id)
        }
        .divider({ strokeWidth: 0.5, color: '#f0f0f0', startMargin: 16, endMargin: 16 })
        .opacity(this.listOpacity)          // 列表整体淡入淡出
      }
      .key('newsRoot')                      // 供 AnimationProperties 获取屏幕尺寸
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.pageId = this.pageInfos.getAllPathName().length - 1
      this.registerCustomTransition()
    })
    .onDisAppear(() => { CustomTransition.getInstance().unRegisterNavParam(this.pageId) })
  }
}
```

> **关键点：**
> - **registerCustomTransition 必须严格区分条件分支**：`isPush && isExit`（push 时列表淡出）和 `!isPush && !isExit`（pop 时列表淡入），不能简化为 `isPush ? 0 : 1`。简化版会在 push+不退出（列表作为目标页进入）和 pop+退出（列表作为源页退出）时也触发动画，产生意外的 opacity 变化。
> - **pushPath 传参必须包含 `doDefaultTransition` 回调**：`param['doDefaultTransition'] = () => { this.doFinishTransition() }`。详情页在 `onReady` 中接收此回调并传给 `AnimationProperties.doAnimation` 的 `prePageOnFinish` 参数，pop 退出时 `onFinish` 调用 `prePageOnFinish()` 完成列表页恢复。遗漏此传参会导致列表页 pop 后 opacity 不恢复。
> - **卡片底部信息行**：头像(18x18, borderRadius=9) + 作者(fontSize=12, #888888) + 分类标签(fontSize=11, #ff6b35, backgroundColor=#fff3ed, borderRadius=3) + 时间(fontSize=11, #cccccc)。
> - **列表必须用 `divider` 配置 `startMargin: 16, endMargin: 16`**，使分隔线与卡片内容对齐。
> - **列表页背景色用 `Color.White`**，不要用 `#f0f0f0` 等灰色调，否则与卡片圆角裁切区域产生视觉差异。

### 步骤 6：NewsDetailContent — 详情页注册展开/收起动画 [核心]

> 转场动画的实际执行者。`onReady` 中创建 CoverNode + 注册转场回调，build 中绑定 `scale`/`translate`/`clip` 动画属性，是步骤 1-3 的落地汇聚点。

```ts
// NewsDetailContent.ets
@Component
export struct NewsDetailContent {
  @State animProps: AnimationProperties = new AnimationProperties(this.getUIContext())
  @State coverNode: CoverNodeController | undefined = undefined
  pageId: number = -1
  prePageDoFinishTransition: () => void = () => {}
  cardItemInfo: RectInfoInPx = new RectInfoInPx()
  cardIndex: number = 0
  coverSrc: Resource = $r('app.media.transitionanimation_image1')

  private onBackPressed(): boolean {
    if (this.coverNode != undefined) {
      this.coverNode.updateSize(110, 76, 6)   // 先恢复卡片尺寸封面
    }
    this.pageInfos.pop()
    return true
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        Stack({ alignContent: Alignment.TopStart }) {
          Column() {
            Stack() {
              if (this.coverNode != undefined) {
                NodeContainer(this.coverNode)   // 跨页面共享的封面节点
              }
            }.width('100%').height(240)

            if (this.animProps.showDetailContent) {
              Scroll() {
                Column() {
                  Text(NEWS_DATA[this.cardIndex]?.title ?? '')
                    .fontSize(22).fontWeight(FontWeight.Bold)
                    .fontColor('#333333').lineHeight(30)

                  Row() {
                    Image(NEWS_DATA[this.cardIndex]?.avatarSrc ?? $r('app.media.icon'))
                      .width(32).height(32).borderRadius(16).objectFit(ImageFit.Cover)
                    Column() {
                      Text(NEWS_DATA[this.cardIndex]?.author ?? '')
                        .fontSize(14).fontColor('#333333').fontWeight(FontWeight.Medium)
                      Text(NEWS_DATA[this.cardIndex]?.time ?? '')
                        .fontSize(12).fontColor('#999999').margin({ top: 2 })
                    }
                    .alignItems(HorizontalAlign.Start).margin({ left: 10 })
                    Blank()
                    Button('关注')
                      .fontSize(13).fontColor(Color.White)
                      .backgroundColor('#ff6b35').borderRadius(16)
                      .height(30).padding({ left: 16, right: 16 })
                  }
                  .width('100%').margin({ top: 20 })

                  Text(NEWS_DATA[this.cardIndex]?.summary ?? '')
                    .fontSize(16).fontColor('#555555').lineHeight(26).margin({ top: 24 })

                  Row() {
                    Text('赞 128').fontSize(13).fontColor('#999999')
                    Text('评论 56').fontSize(13).fontColor('#999999').margin({ left: 20 })
                    Text('收藏').fontSize(13).fontColor('#999999').margin({ left: 20 })
                  }
                  .margin({ top: 30 }).padding({ bottom: 40 })
                }
                .padding({ left: 20, right: 20, top: 16 }).alignItems(HorizontalAlign.Start)
              }
              .layoutWeight(1)
              .transition(TransitionEffect.OPACITY)
            }
          }
          .width('100%').height('100%')
        }
        .width('100%').height('100%')
        .scale({ x: this.animProps.scaleValue, y: this.animProps.scaleValue })
        .translate({ x: this.animProps.translateX, y: this.animProps.translateY })
        .width(this.animProps.clipWidth)
        .height(this.animProps.clipHeight)
        .clip(true)

        // 导航栏（仅展开后显示）— 白色文字，悬浮于封面图上方
        if (this.animProps.showDetailContent) {
          Row() {
            Text('‹')
              .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
              .margin({ right: 8 })
              .onClick(() => { this.onBackPressed() })
            Blank()
            Text('⋯')
              .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12 })
          .transition(TransitionEffect.OPACITY)
        }
      }
    }
    .backgroundColor(this.animProps.navDestinationBgColor)
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
      this.pageId = this.pageInfos.getAllPathName().length - 1

      // 接收列表页传递的参数（含 doDefaultTransition 回调）
      let param = context.pathInfo.param as Record<string, Object>
      this.prePageDoFinishTransition = param['doDefaultTransition'] as () => void
      this.cardItemInfo = param['cardItemInfo'] as RectInfoInPx
      this.cardIndex = param['cardIndex'] as number
      this.coverSrc = param['coverSrc'] as Resource

      // 创建封面节点（全屏尺寸）— 使用接收到的 coverSrc
      let node = new CoverNodeController()
      node.init(this.getUIContext(), this.coverSrc, '100%', 240, 0, ImageFit.Cover)
      this.coverNode = node

      // 注册转场回调 — prePageOnFinish 传给 doAnimation
      CustomTransition.getInstance().registerNavParam(this.pageId,
        (isPush, isExit, proxy) => {
          this.animProps.doAnimation(this.cardItemInfo, isPush, isExit, proxy,
            this.prePageDoFinishTransition)
        }, 1500)
    })
    .onBackPressed(() => { return this.onBackPressed() })
    .onDisAppear(() => { CustomTransition.getInstance().unRegisterNavParam(this.pageId) })
  }
}
```

> **关键点：**
> - **导航栏文字必须用 `Color.White`**：导航栏悬浮于封面图上方，封面图通常是深色图片。使用 `#333333` 深色文字在深色背景上几乎不可见，这是效果崩塌的常见原因。原版用 `fontColor(Color.White)` + `fontWeight(FontWeight.Bold)`。
> - **导航栏右侧必须有 `⋯` 更多按钮**，不要只显示返回箭头。原版布局为 `Text('‹') + Blank() + Text('⋯')`，padding 为 `{ left: 16, right: 16, top: 12 }`（无 bottom）。
> - **导航栏不设 `backgroundColor(Color.White)`**：导航栏是透明的，文字白色悬浮在封面图上。设置白色背景会破坏"一镜到底"无缝展开效果。
> - **详情页内容必须包含**：标题(fontSize=22, lineHeight=30) → 作者信息行(头像32x32 + 作者名 + 时间 + 关注Button) → 正文(fontSize=16, lineHeight=26, #555555) → 互动栏(赞/评论/收藏)。不能用简化版只有标题+摘要+分类标签，否则视觉效果与原版差距太大。
> - **onReady 必须接收 `doDefaultTransition` 回调**：`this.prePageDoFinishTransition = param['doDefaultTransition'] as () => void`，并将其传给 `doAnimation` 的 `prePageOnFinish` 参数。pop 退出时 `onFinish` 调用 `prePageOnFinish()`，触发列表页恢复。如果传空函数 `() => {}`，列表页 pop 后不会恢复 opacity=1。
> - **onBackPressed 中 `coverNode.updateSize(110, 76, 6)` 前必须判空**：`if (this.coverNode != undefined)`。直接 `this.coverNode?.updateSize(...)` 的可选链调用在 ArkTS 中可能不被支持。

### 跨页面转场动画时序总结

| 阶段 | 列表页 (NewsListPage) | 详情页 (NewsDetailContent) | 封面节点 | proxy |
|---|---|---|---|---|
| 初始 | opacity=1, 正常显示 | 不存在 | 不存在 | — |
| 点击卡片，push | 注册回调，开始淡出 | 创建 CoverNode，注册回调 | 详情页创建（240vp全屏尺寸） | — |
| push 转场开始 | listOpacity → 0 | scale/translate/clip 从卡片值展开到全屏 | NodeContainer 显示 | — |
| push 转场完成 | finishTransition() | showDetailContent=true, 显示导航栏和详情 | 全屏封面 | finishTransition() |
| 点击返回，pop | 注册回调，准备淡入 | coverNode.updateSize(110,76,6) 恢复卡片封面 | 卡片尺寸 | — |
| pop 转场开始 | listOpacity → 1 | scale/translate/clip 从全屏收起到卡片值 | 卡片尺寸 | — |
| pop 转场完成 | finishTransition(), 恢复显示 | 页面销毁，unRegisterNavParam | 页面销毁 | finishTransition() |

---
