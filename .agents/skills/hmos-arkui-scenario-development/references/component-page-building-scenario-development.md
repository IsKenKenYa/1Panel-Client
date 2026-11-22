# 组件构建基础页面案例集

---

## 布局组件搭建页面框架

## 功能点典型使用场景对比

| 布局组件 | 典型使用场景 | 核心能力 | 不适用场景 |
|---------|------------|---------|-----------|
| Column / Row | 设置页设置项垂直排列、导航栏水平排列 | 简单线性排列 | 需要换行、层叠覆盖、二维定位 |
| Stack | 列表+悬浮按钮、视频+控制栏、图片+角标 | 层叠覆盖+九宫格对齐 | 并排定位关系 |
| Flex | 搜索历史标签、筛选条件标签、属性标签 | 不等宽元素自适应换行 | 固定行列比例 |
| RelativeContainer | 社交动态卡片、复杂表单、仪表盘 | 扁平化锚点定位 | 简单线性排列 |
| GridRow / GridCol | 电商商品列表多设备适配、响应式卡片 | 根据设备宽度动态调整列数 | 固定行列网格 |
| DynamicLayout | 文件管理器视图切换（列表/网格/瀑布流） | 同数据源切换布局且保持状态 | 页签切换、条件渲染 |
| Tabs | 新闻频道切换、商品分类页签 | 多分类视图切换不销毁 | 页面级导航跳转 |

---

## 场景一：设置页设置项垂直排列，每项内图标+标题+开关水平排列

**场景示例描述**：设置页面中，多个设置项（WiFi、蓝牙、显示、声音等）垂直排列，每个设置项内图标+标题+开关按钮水平排列。

**解决方案**：外层 Column 排列设置项，每个设置项 Row 内通过 space 属性设置图标与标题的等间距，开关按钮通过 Blank 组件推到右侧。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 层叠布局（Stack） | 设置项之间是线性排列关系，不需要层叠覆盖 |
| 相对布局（RelativeContainer） | 布局结构简单明确，相对布局引入锚点规则会增加不必要的复杂度 |

```typescript
// 外层 Column 垂直排列所有设置项,space 统一设行间距
Column({ space: 12 }) {
  // 设置项1:WLAN — 右侧 Toggle 开关
  Row() {
    Text('📶').fontSize(24).width(40)
    Text('WLAN').fontSize(16).layoutWeight(1)  // 撑满中间空白,将 Toggle 推到右侧
    Toggle({ type: ToggleType.Switch, isOn: this.wifiEnabled })
      .selectedColor('#007DFF')
      .onChange((isOn: boolean) => { this.wifiEnabled = isOn; })
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })

  // 设置项2:蓝牙 — 右侧 Toggle 开关
  Row() {
    Text('🔵').fontSize(24).width(40)
    Text('蓝牙').fontSize(16).layoutWeight(1)
    Toggle({ type: ToggleType.Switch, isOn: this.bluetoothEnabled })
      .selectedColor('#007DFF')
      .onChange((isOn: boolean) => { this.bluetoothEnabled = isOn; })
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })

  // 设置项3:亮度 — 右侧 Text 副文本(非开关场景,需区分内容类型)
  Row() {
    Text('🔆').fontSize(24).width(40)
    Text('亮度').fontSize(16).layoutWeight(1)
    Text(`${this.brightness}%`).fontSize(14).fontColor('#999')
  }
  .width('100%').height(56).padding({ left: 16, right: 16 })
}
```

### 关键 API

| 属性 | 作用 | 示例 |
|------|-----|------|
| `space` | 子组件间距 | `Column({ space: 10 })` |
| `layoutWeight` | 按比例分配剩余空间 | `.layoutWeight(1)` |
| `Blank()` | 占据剩余空间 | 将后面的组件推到右侧 |
| `justifyContent` | 主轴对齐 | `FlexAlign.Center` / `SpaceBetween` |
| `alignItems` | 交叉轴对齐 | `HorizontalAlign.Center` |

### 禁止写法

| 禁止写法 | 原因 |
|---------|------|
| 用 margin 硬编码每行间距代替 Column space | space 统一管理行间距;margin 硬编码维护困难且容易不一致 |
| 用 Position 绝对定位钉 Toggle 右对齐 | 脱离文档流,窗口尺寸变化时位置错乱;应使用 layoutWeight/Blank |
| Toggle 不绑定 @State 状态变量 | 点击开关无响应,状态不更新 |
| 所有右侧统一用 Text 不区分 Toggle 场景 | 开关场景必须用 Toggle 组件,Text 无法交互切换 |

---

## 场景二：长列表页面右下角悬浮"返回顶部"按钮覆盖在列表之上

**场景示例描述**：长列表页面右下角悬浮"返回顶部"按钮，始终覆盖在列表内容之上，列表滚动时按钮位置不变。

**解决方案**：使用 Stack 层叠布局，List 组件作为底层占满全屏，悬浮 Button 作为上层子组件，通过 alignContent 设置为 BottomEnd 定位在右下角。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 相对布局（RelativeContainer） | 悬浮按钮需要绝对定位在容器角落，Stack 的对齐方式更直观 |
| 线性布局（Column/Row） | 按钮需要覆盖在列表上方而非与列表并排 |

```typescript
Stack({ alignContent: Alignment.BottomEnd }) {
  // 底层：长列表
  List({ scroller: this.scroller }) {
    ForEach(this.items, (item: string, index: number) => {
      ListItem() {
        Row() {
          Text(`#${index + 1}`).fontSize(14).fontColor('#999').width(40)
          Text(item).fontSize(16).layoutWeight(1)
        }
        .width('100%').height(56).padding({ left: 16, right: 16 })
      }
    })
  }
  .width('100%').height('100%')
  .onScrollIndex((index: number) => { this.showBackButton = index > 3; })

  // 顶层：悬浮返回顶部按钮
  Button('返回顶部 ↑')
    .fontSize(14).fontColor(Color.White)
    .backgroundColor('#007DFF').borderRadius(24)
    .margin({ right: 16, bottom: 16 })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 2 })
    .onClick(() => { this.scroller.scrollToIndex(0); })
}
.clip(true)
```

### alignContent 对齐方式枚举

| 枚举值 | 对齐位置 |
|--------|---------|
| `Alignment.TopStart` | 左上角 |
| `Alignment.Top` | 顶部居中 |
| `Alignment.TopEnd` | 右上角 |
| `Alignment.Start` | 左侧居中 |
| `Alignment.Center` | 正中心 |
| `Alignment.End` | 右侧居中 |
| `Alignment.BottomStart` | 左下角 |
| `Alignment.Bottom` | 底部居中 |
| `Alignment.BottomEnd` | 右下角 |

---

## 场景三：搜索页历史搜索词标签自适应宽度并自动换行

**场景示例描述**：搜索页面中，用户历史搜索词以标签形式展示，标签宽度随文本长度自适应，一行排满后自动换行到下一行。

**解决方案**：使用 Flex 布局，设置 direction 为 Row、wrap 为 Wrap 启用换行，每个标签设置 flexShrink 为 0 防止被压缩。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 线性布局 Row | Row 不支持自动换行，标签过多会溢出或被压缩 |
| Grid | Grid 是固定行列的二维布局，无法实现标签宽度不等的自适应排列 |

```typescript
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
  ForEach(this.searchHistory, (tag: string) => {
    Text(tag)
      .fontSize(14).fontColor('#333')
      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      .backgroundColor('#F1F3F5').borderRadius(16)
      .flexShrink(0)  // 关键：防止标签被压缩
      .margin({ right: 10, bottom: 10 })
  })
}
```

### Flex 关键枚举

| 枚举类型 | 枚举值 | 说明 |
|---------|--------|------|
| FlexDirection | `Row` / `Column` / `RowReverse` / `ColumnReverse` | 排列方向 |
| FlexWrap | `NoWrap` / `Wrap` / `WrapReverse` | 是否换行 |
| FlexAlign | `Start` / `Center` / `End` / `SpaceBetween` / `SpaceAround` / `SpaceEvenly` | 主轴对齐 |
| ItemAlign | `Start` / `Center` / `End` / `Stretch` / `Baseline` | 交叉轴对齐 |

---

## 场景四：社交动态卡片中头像、用户名、正文、按钮等元素复杂定位

**场景示例描述**：社交 App 动态卡片中，头像（左上）、用户名（头像右侧）、发布时间（用户名下方）、正文（跨整行）、点赞/评论/分享按钮（底部均匀分布）等元素位置复杂，如果用 Row/Column 嵌套需要 3-4 层包裹影响长列表性能。

**解决方案**：使用 RelativeContainer，通过 alignRules 设置各元素相对于容器和兄弟元素的锚点定位，扁平化布局结构减少嵌套层级。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 线性布局（Column/Row） | 元素间存在二维定位关系，Row/Column 嵌套层数过深（3-4层） |
| 层叠布局（Stack） | 元素间不是覆盖关系而是并排定位关系 |

```typescript
RelativeContainer() {
  // 头像 - 左上角，锚定容器左边
  Stack() { Text('👤').fontSize(28) }
    .width(48).height(48).borderRadius(24)
    .alignRules({ left: { anchor: '__container__', align: HorizontalAlign.Start } })
    .id('avatar')

  // 用户名 - 锚定头像右侧
  Text('张三丰').fontSize(16).fontWeight(FontWeight.Medium)
    .alignRules({ left: { anchor: 'avatar', align: HorizontalAlign.End } })
    .margin({ left: 12, top: 4 }).id('username')

  // 关注按钮 - 锚定容器右上角(top + right 同时锚定 __container__)
  Button('关注')
    .fontSize(12).fontColor(Color.White)
    .backgroundColor('#007DFF').borderRadius(14)
    .height(28).padding({ left: 12, right: 12 })
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    })
    .margin({ top: 8, right: 0 })
    .id('followBtn')

  // 发布时间 - 锚定用户名下方
  Text('2小时前').fontSize(12).fontColor('#999')
    .alignRules({
      left: { anchor: 'avatar', align: HorizontalAlign.End },
      top: { anchor: 'username', align: VerticalAlign.Bottom }
    }).id('postTime')

  // 正文 - 锚定发布时间下方，左右锚定容器撑满宽度
  Text('今天学习了 RelativeContainer...')
    .alignRules({
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      top: { anchor: 'postTime', align: VerticalAlign.Bottom },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    }).id('content')

  // 点赞/评论/分享 - 锚定分隔线下方
  Row() { Text('❤️'); Text(` ${this.likeCount}`) }
    .alignRules({
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      top: { anchor: 'divider', align: VerticalAlign.Bottom }
    })
    .chainMode(Axis.Horizontal, ChainStyle.SPREAD_INSIDE)
    .id('likeBtn')
  // ...评论、分享按钮类似
}
```

### alignRules 锚定规则

| anchor 取值 | 含义 |
|-------------|------|
| `'__container__'` | 相对于父容器 |
| `'组件id名'` | 相对于同级的另一个子组件 |
| top + right 同时锚定 `__container__` | 定位到容器右上角(如关注按钮) |

| align 取值（水平） | 含义 |
|-------------------|------|
| `HorizontalAlign.Start` | 锚定目标左边缘 |
| `HorizontalAlign.Center` | 锚定目标中心 |
| `HorizontalAlign.End` | 锚定目标右边缘 |

| align 取值（垂直） | 含义 |
|-------------------|------|
| `VerticalAlign.Top` | 锚定目标上边缘 |
| `VerticalAlign.Center` | 锚定目标中心 |
| `VerticalAlign.Bottom` | 锚定目标下边缘 |

### chainMode 链式布局枚举

| 枚举值 | 排列方式 |
|--------|---------|
| `ChainStyle.SPREAD_INSIDE` | 首尾贴边，中间均匀分布 |
| `ChainStyle.SPREAD` | 所有元素均匀分布（含首尾间距） |
| `ChainStyle.PACKED` | 所有元素紧凑排列，居中分布 |

---

## 场景五：电商商品列表在不同设备上显示不同列数

**场景示例描述**：电商 App 首页，手机端显示 2 列商品网格，平板端显示 4 列商品网格，2in1 设备端显示 6 列商品网格，内容相同但列数随设备宽度变化。

**解决方案**：使用 GridRow 定义栅格容器（默认 12 栅格），GridCol 子组件通过 span 属性在不同断点下设置不同的栅格占比，实现自适应列数。

| 备选方案 | 不适合的理由 |
|---------|------------|
| Grid 组件 | Grid 是固定行列的二维网格，无法根据设备宽度动态调整列数 |
| Flex 布局 | Flex 适合一维排列和换行，无法精确控制不同设备下的列数比例 |

```typescript
GridRow({
  columns: 12,
  breakpoints: {
    value: ['100vp', '200vp', '300vp'],
    reference: BreakpointsReference.WindowSize
  }
}) {
  ForEach(this.products, (product: Product) => {
    GridCol({
      xs: { span: 6 },
      sm: { span: 6 },
      md: { span: 3 },
      lg: { span: 2 }
    }) {
      Column() {
        Stack() { Text(product.emoji).fontSize(40) }
          .width('100%').aspectRatio(1)
          .backgroundColor(product.color).borderRadius(8)
        Text(product.name).fontSize(13).maxLines(1)
        Text(product.price).fontSize(14).fontColor('#E53935')
      }
      .padding(8).backgroundColor(Color.White).borderRadius(8)
    }
  })
}
```

### 栅格计算速查（12 栅格系统）

| 目标列数 | span 值 |
|---------|---------|
| 1 列 | 12 |
| 2 列 | 6 |
| 3 列 | 4 |
| 4 列 | 3 |
| 6 列 | 2 |
| 12 列 | 1 |

---

## 场景六：文件管理器在列表/网格/瀑布流视图间切换且保持状态

**场景示例描述**：文件管理器 App 中，用户点击切换按钮，文件列表在"列表视图（单列）""网格视图（多列）""瀑布流视图（不等高多列）"之间动态切换，切换时保留当前选中文件和滚动位置的状态不丢失。

**解决方案**：使用 DynamicLayout 组件，内置 ColumnLayoutAlgorithm（列表）、GridLayoutAlgorithm（网格）等布局算法，还可自定义 CustomLayoutAlgorithm（如瀑布流），切换算法时子组件状态自动保持。

| 备选方案 | 不适合的理由 |
|---------|------------|
| 条件渲染（if/else） | 切换不同组件会销毁重建，丢失选中状态和滚动位置 |
| Tabs | Tabs 是页签切换，不适合在同一数据源的多种布局形式间切换 |

```typescript
import {
  ColumnLayoutAlgorithm, CustomLayoutAlgorithm, DynamicLayout,
  GridLayoutAlgorithm, LayoutAlgorithm, LayoutConstraint, LengthMetrics
} from '@kit.ArkUI';

// 自定义瀑布流布局算法
class WaterfallLayout extends CustomLayoutAlgorithm {
  onMeasure(self: FrameNode, constraint: LayoutConstraint): void {
    // ...测量每列宽度，将子组件放到最短列
  }
  onLayout(self: FrameNode, position: LayoutPosition): void {
    // ...按测量结果设置每个子组件位置
  }
}

@Local algorithm: LayoutAlgorithm = new ColumnLayoutAlgorithm({ space: LengthMetrics.vp(5) });

private switchLayout(mode: number): void {
  if (mode === 0) {
    this.algorithm = new ColumnLayoutAlgorithm({ space: LengthMetrics.vp(5) });
  } else if (mode === 1) {
    this.algorithm = new GridLayoutAlgorithm({
      columnsTemplate: '1fr 1fr 1fr',
      rowsGap: LengthMetrics.vp(10), columnsGap: LengthMetrics.vp(10)
    });
  } else {
    this.algorithm = new WaterfallLayout();
  }
}

// 使用 DynamicLayout - 子组件在布局切换时保持状态
DynamicLayout(this.algorithm) {
  ForEach(this.files, (file: FileItem, index: number) => {
    this.buildFileCard(file, index)
  })
}
```

### DynamicLayout 布局算法枚举

| 算法类 | 说明 | 关键参数 |
|--------|------|---------|
| `ColumnLayoutAlgorithm` | 单列/多列线性排列 | `{ space: LengthMetrics.vp(5) }` |
| `GridLayoutAlgorithm` | 网格排列 | `{ columnsTemplate: '1fr 1fr 1fr', rowsGap, columnsGap }` |
| `RowLayoutAlgorithm` | 单行水平排列 | `{ space: LengthMetrics.vp(5) }` |
| `CustomLayoutAlgorithm` | 自定义布局（如瀑布流） | 需实现 `onMeasure` + `onLayout` |

---

## 场景七：新闻App顶部分类页签切换对应频道内容

**场景示例描述**：新闻 App 首页顶部有"推荐/热点/科技/娱乐/体育"等多个分类页签，用户点击页签切换对应频道的新闻列表内容，页签支持左右滑动查看更多分类。

**解决方案**：使用 Tabs 组件，每个 TabContent 对应一个分类的新闻列表，通过 TabsController 控制页签切换，index 双向绑定实现程序化切页。

| 备选方案 | 不适合的理由 |
|---------|------------|
| Navigation | Navigation 用于页面级导航跳转，页签切换是同一页面内的视图切换 |
| 条件渲染（if/else） | 每次切换会重建组件，已加载的列表数据会丢失；Tabs 已加载的 TabContent 不会销毁 |

```typescript
Tabs({ barPosition: BarPosition.Start, controller: this.tabsController, index: this.currentIndex }) {
  TabContent() { this.buildNewsList(this.recommendNews) }.tabBar('推荐')
  TabContent() { this.buildNewsList(this.hotNews) }.tabBar('热点')
  TabContent() { this.buildNewsList(this.techNews) }.tabBar('科技')
  // ...更多频道
}
.scrollable(true)   // 内容区支持左右滑动切换
.barHeight(44)
.onChange((index: number) => { this.currentIndex = index; })
```

### Tabs 关键枚举

| 枚举类型 | 枚举值 | 说明 |
|---------|--------|------|
| BarPosition | `Start` / `End` | 页签栏位置（顶部/底部） |
| ScrollableBarModeOptions | `Fixed` / `Scrollable` / `Marquee` | 页签栏模式 |

---

## 布局选型速查对比表

| 布局组件 | 排列方式 | 核心能力 | 典型场景 | 关键限制 |
|---------|---------|---------|---------|---------|
| **Column / Row** | 单方向线性 | 简单垂直/水平排列 | 设置页、表单、导航栏 | 不支持换行，不支持二维定位 |
| **Stack** | 层叠覆盖 | 子组件叠加+九宫格对齐 | 悬浮按钮、视频+控制栏、水印 | 无法表达并排定位关系 |
| **Flex** | 弹性+换行 | 不等宽元素自适应换行 | 标签云、搜索历史、筛选条件 | 无法精确控制行列比例 |
| **RelativeContainer** | 锚点相对定位 | 扁平化复杂二维布局 | 社交卡片、复杂表单、仪表盘 | 需要给组件设 id，锚点规则较复杂 |
| **GridRow / GridCol** | 响应式栅格 | 根据设备宽度动态调整列数 | 电商商品列表、多设备适配 | 基于固定栅格数（12/24），非像素级精确 |
| **DynamicLayout** | 可切换算法 | 同数据源切换不同布局形式 | 文件管理器视图切换 | 需要@ObservedV2和@ComponentV2 |
| **Tabs** | 页签切换 | 多分类视图切换，已加载不销毁 | 新闻频道、商品分类Tab | 是视图切换非页面跳转 |


---

## 滚动组件列表展示

## 功能点典型使用场景对比

| 滚动组件 | 典型使用场景 | 核心能力 | 不适用场景 |
|---------|------------|---------|-----------|
| List + ListItemGroup | 通讯录分组吸顶、消息列表左滑删除、设置项列表 | 分组+吸顶+滑动操作+拖拽排序 | 多列网格、不等高排列 |
| ArcList | 智能手表圆弧菜单、可穿戴设备设置列表 | 圆形屏幕适配+动态缩放 | 手机端直线列表 |
| Grid + GridItem | 相册九宫格、应用宫格、照片选择器 | 固定行列等高网格 | 不等高排列、响应式列数 |
| WaterFlow + FlowItem | 商品推荐瀑布流、Pinterest错落排列、小红书信息流 | 等宽不等高+自动放最短列 | 等高网格、单列列表 |

---

## 场景一：通讯录按首字母分组，标题吸顶，支持左滑删除

**场景示例描述**：通讯录 App 中，联系人按首字母分组（A/B/C...），每个分组标题吸顶显示，列表支持按姓名搜索过滤、左滑删除操作。

**解决方案**：使用 List 组件，子组件为 ListItemGroup（分组），设置 sticky 属性实现分组标题吸顶，swipeAction 实现左滑操作按钮。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Grid | 通讯录每列等宽单列显示，不需要网格的二维布局 |
| WaterFlow | 通讯录列表项高度一致，不需要瀑布流的错落排列 |

```typescript
List({ space: 0 }) {
  ForEach(this.getFilteredGroups(), (group: ContactGroup) => {
    ListItemGroup({ header: this.groupHeader(group.letter) }) {
      ForEach(group.contacts, (contact: Contact) => {
        ListItem() {
          Row() {
            // 头像
            Column() { Text(contact.avatar) }
              .width(44).height(44).borderRadius(22)
            // 姓名+手机号
            Column() {
              Text(contact.name).fontSize(16)
              Text(contact.phone).fontSize(12).fontColor('#999')
            }.layoutWeight(1)
          }
          .width('100%').height(64).padding({ left: 16, right: 16 })
        }
        .swipeAction({ end: this.deleteButton(contact.name) })
      })
    }
  })
}
.sticky(StickyStyle.Header)  // 分组标题吸顶
.divider({ strokeWidth: 0.5, color: '#f0f0f0', startMargin: 72 })
```

### List 关键 API

| 属性 | 作用 | 示例 |
|------|-----|------|
| `sticky` | 分组标题吸顶 | `StickyStyle.Header` / `StickyStyle.None` |
| `ListItemGroup` | 分组容器 | `ListItemGroup({ header: builder })` |
| `swipeAction` | 滑动操作按钮 | `{ end: builder }` / `{ start: builder, end: builder }` |
| `divider` | 分割线 | `{ strokeWidth, color, startMargin }` |
| `onReachEnd` | 滚动到底部回调 | 用于加载更多 |
| `EditMode` | 拖拽排序模式 | 启用后 ListItem 可长按拖拽排序 |

### StickyStyle 枚举

| 枚举值 | 行为 |
|--------|------|
| `Header` | 分组标题吸顶 |
| `Footer` | 分组底部吸底 |
| `None` | 不吸顶 |

---

## 场景二：智能手表圆形屏幕菜单项沿圆弧排列，中心项最大

**场景示例描述**：智能手表的圆形表盘上，设置菜单项沿圆弧排列，列表项接近圆形屏幕上下边缘时自动缩小，居中的列表项最大最突出。

**解决方案**：使用 ArcList 组件，子组件为 ArcListItem，列表项根据与屏幕中心的距离自动缩放，通过 initialIndex 设置初始显示的列表项。

| 备选组件 | 不适合的理由 |
|---------|------------|
| List | 是直线排列的列表，无法适配圆形屏幕的弧形交互 |
| Grid | 是二维网格布局，不支持弧形排列和动态缩放效果 |

```typescript
ArcList({ initialIndex: 0 }) {
  ForEach(this.menuItems, (item: ArcMenuItem) => {
    ArcListItem() {
      // 列表项内容，自动根据位置缩放
      // ...
    }
  })
}
```

> 注：ArcList 主要适配圆形屏幕设备（智能手表），手机端可使用 List + scale/opacity 动画模拟类似效果。

---

## 场景三：聊天照片九宫格，每行3张等宽等高正方形图片

**场景示例描述**：微信聊天界面中，用户发送 9 张照片组成的九宫格，每行 3 张等宽等高的正方形图片，图片间有固定间距。

**解决方案**：使用 Grid 组件，通过 columnsTemplate 设置列数（如 `'1fr 1fr 1fr'` 三列等宽），rowsGap/columnsGap 设置间距。

| 备选组件 | 不适合的理由 |
|---------|------------|
| List | 是单列线性排列，无法实现多列网格 |
| WaterFlow | 九宫格图片等高排列，不需要瀑布流的错落效果 |
| GridRow/GridCol | 用于响应式布局适配，九宫格是固定行列结构 |

```typescript
Grid() {
  ForEach(this.photos, (photo: PhotoItem) => {
    GridItem() {
      Image(photo.url)
        .objectFit(ImageFit.Cover)  // 关键:防止照片变形
        .aspectRatio(1)              // 固定宽高比,保证网格整齐
        .onClick(() => { this.openPhotoPreview(photo.url); })  // 点击预览大图
    }
  })
}
.columnsTemplate('1fr 1fr 1fr')  // 3列等宽
.rowsGap(8).columnsGap(8)
.padding({ left: 16, right: 16 })
```

### columnsTemplate 模板语法

| 语法 | 含义 | 示例 |
|------|------|------|
| `1fr` | 等比例分配 | `'1fr 1fr 1fr'` = 3等分 |
| `100vp` | 固定宽度 | `'100vp 1fr 1fr'` = 首列固定+后2列等分 |
| `auto` | 按内容自适应 | `'auto 1fr'` = 首列按内容，次列占满 |

### 不同照片数量的布局规则

| 照片数 | columnsTemplate | 布局效果 |
|--------|----------------|---------|
| 1 张 | 动态切 `'1fr'` 或 GridItem 跨 3 列 | 单张大图占满整行 |
| 2-3 张 | `'1fr 1fr 1fr'` | 一行排列,末位留空 |
| 4 张 | `'1fr 1fr 1fr'` | 2×2 排列(末位留空) |
| 5-6 张 | `'1fr 1fr 1fr'` | 2 行排列 |
| 7-9 张 | `'1fr 1fr 1fr'` | 3×3 完整九宫格 |

> 注:1 张照片时可条件渲染切换为单列大图,或令 GridItem 跨 3 列(`.columnStart(0).columnEnd(2)`)。

---

## 场景四：商品推荐瀑布流，卡片高度不等错落排列

**场景示例描述**：小红书/Pinterest 类 App 的商品推荐主页，每个商品卡片宽度相同但高度不等（因图片和描述长度不同），新卡片自动放在当前最短列下方，形成错落有致的瀑布流效果。

**解决方案**：使用 WaterFlow 组件，通过 columnsTemplate 设置列数，子节点 FlowItem 自动放置在当前总高度最小的列。

| 备选组件 | 不适合的理由 |
|---------|------------|
| Grid | Grid 每行等高，无法实现不同高度的错落排列 |
| List | 是单列等宽等高排列，无法实现多列不等高的瀑布流效果 |

```typescript
WaterFlow() {
  ForEach(this.products, (product: ProductCard) => {
    FlowItem() {
      Column() {
        // 图片区：高度不一，形成错落效果
        Stack() {
          Column().height(product.height - 80)
            .backgroundColor(product.color)
          Text(product.icon).fontSize(40)
        }
        // 商品信息
        Column() {
          Text(product.name).maxLines(2)
          Text(product.price).fontColor('#e74c3c')
        }.padding(10)
      }
      .height(product.height)
      .backgroundColor(Color.White).borderRadius(10)
    }
  })
}
.columnsTemplate('1fr 1fr')  // 双列瀑布流
.columnsGap(8).rowsGap(8)
.onReachEnd(() => { /* 加载更多 */ })
```

### 瀑布流 vs 网格 核心区别

| 特征 | Grid（网格） | WaterFlow（瀑布流） |
|------|------------|-------------------|
| 行高 | 每行等高 | 每行不等高 |
| 排列方式 | 按行列顺序填充 | 新项自动放最短列 |
| 适用场景 | 相册九宫格、固定网格 | 商品推荐、Pinterest |
| 子组件 | GridItem | FlowItem |

---

## 滚动组件选型速查对比表

| 组件 | 排列方式 | 核心能力 | 典型场景 | 关键限制 |
|------|---------|---------|---------|---------|
| **List** | 单列线性 | 分组+吸顶+滑动操作+拖拽排序 | 通讯录、消息列表、设置项 | 仅单列，不支持多列 |
| **ArcList** | 弧形排列 | 圆形屏幕适配+动态缩放 | 智能手表菜单 | 主要适配圆形屏幕设备 |
| **Grid** | 多列等高 | 固定行列网格布局 | 相册九宫格、应用宫格 | 每行等高，不支持错落 |
| **WaterFlow** | 多列不等高 | 自动放最短列+错落排列 | 商品推荐、Pinterest | 无法精确控制行列位置 |
