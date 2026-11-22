# 9. 属性与 API 参数约束

## 规则

### 属性命名

| 规则 | 说明 |
|------|------|
| **禁止捏造不存在的属性名** | 不确定时必须检索确认 |
| **禁止使用缩写属性** | 无 `.bgColor()`、`.radius()`、`.textSize()` 等缩写 |
| **属性归属组件需匹配** | `.textOverflow()` 仅 Text 支持，`.objectFit()` 仅 Image 等媒体组件支持 |
| **Button 文字样式通过子组件设置** | 不直接支持 `.fontColor()` |

### 枚举值

| 规则 | 说明 |
|------|------|
| **禁止用字符串代替枚举** | `.textAlign(TextAlign.Center)`，不能写 `'center'` |
| **枚举值大小写必须精确** | `FlexAlign.Start` 不能写 `FlexAlign.start` |
| **禁止猜测不存在的枚举** | 不确定时检索确认 |

### 参数格式

| 规则 | 说明 |
|------|------|
| margin/padding 不支持多参数简写 | 用 `.margin({ top: 10, right: 20 })`，不写 `.margin(10, 20)` |
| Row/Column space 在构造器传入 | `Row({ space: 16 })`，不写 `Row().space(16)` |
| Stack 居中用 alignContent | `Stack().alignContent(Alignment.Center)`，不用 `.justifyContent()` |
| Flex 无 space | 用子组件 margin 替代 |
| 禁止借用其他框架写法 | 不用 `match_parent`/`wrap_content`，用 `'100%'`/`'auto'` |
| animateTo curve 必须为枚举 | `curve: Curve.Ease`，不写 `curve: 'ease'` |

### 组件构造器

| 规则 | 说明 |
|------|------|
| Badge 必须包含 style | `Badge({ count: 5, style: { badgeSize: 16, badgeColor: Color.Red } })` |
| Badge 的 count 和 value 二选一 | 不能同时传 |
| Select 直接传数组 | `Select([{ value: 'A' }])`，不是嵌套 `{ options: [...] }` |
| bindPopup 需要 2 个参数 | `.bindPopup(this.show, { message: 'text' })` |
| WaterFlow 不接受 controller | `WaterFlow()` 空构造 |
| RichEditor 必须传 controller | `RichEditor({ controller: this.editor })` |
| overlay 必须传 CustomBuilder | 不能直接 `.overlay(Text('x'))`，需 @Builder 包装 |
| Scroll 传实例不传类 | `Scroll(new Scroller())`，不能 `Scroll(Scroller)` |
| ListItemGroup 无 divider 属性 | 用 List 的 `.divider()` 统一设置 |
| Refresh 构造器传 refreshing | `Refresh({ refreshing: this.isRefreshing })`，状态变化通过 `.onStateChange()` / `.onRefreshing()` 监听，非链式方法 |

### 构造参数字段实测高发错

```ts
// ❌ WRONG -- 凭记忆加错字段
TimePicker({ selected: new Date(), useMilitaryTime: true })    // useMilitaryTime 是 TimePickerDialog.show 的字段
PersistentStorage.persistProps([{ key: 'k', value: 'v' }])    // 正确字段是 defaultValue
PersistentStorage.persistProps([{ key: 'k', default: 'v' }])  // default 也错，是 defaultValue
Tabs(this.tabsController) { TabContent() {} }                 // 构造器参数是对象 { controller: ... }
MenuItem({ value: '复制', icon: $r('app.media.x') })          // 正确字段是 content + startIcon
Shape({ viewPort: {...} })                                     // Shape 构造参数是 PixelMap，viewPort 是链式方法

// ✅ RIGHT -- 拿不准时先声明带类型变量（编译器逐字段报错）
const opt: TimePickerOptions = { selected: new Date() }
TimePicker(opt)
```

### 回调参数类型

| 规则 | 说明 |
|------|------|
| 参数类型必须精确 | `onClick` 参数是 `ClickEvent`，不是 `GestureEvent` |
| 回调参数多为对象而非原始类型 | Video `onUpdate` 返回 `PlaybackInfo` 对象 |
| bindPopup onStateChange 参数是对象 | `{ isVisible }`，不是 `boolean` |
| TextPickerResult.index 是数组 | `result.index[0]`，不是 `result.index` |
| curves.springCurve 需要 4 个参数 | `curves.springCurve(10, 1, 228, 30)` |
| **选择器回调参数是联合类型** | 勿收窄，照编译器声明抄（见下方"常见错误"） |

### 资源名称

| 规则                         | 说明                                                         |
| ---------------------------- | ------------------------------------------------------------ |
| 禁止猜测系统符号名           | 系统符号名与直觉不同，必须查验证列表                         |
| `$r('sys.color.*')` 多数无效 | 优先用 hex 如 `'#FFE84026'`                                  |
| 媒体资源必须用 `$r`          | `Image($r('app.media.icon'))`，禁止裸字符串路径              |
| sys.symbol 名不要猜          | `share→upload`、`settings→gearshape`、`search→magnifyingglass`、`home→house` |

---

## 臆造 API / 不存在的 API 清单

### 实测高发臆造清单（写属性/方法名时默认怀疑，看到 `Did you mean` 直接采纳）

| 组件/类型                         | ❌ 臆造的                                                     | ✅ 正确写法                                                   |
| --------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Swiper                            | `.previousMargin(40)`                                        | `.prevMargin(40)`                                            |
| RefreshStatus                     | `.InActive` / `.OverRefresh`                                 | `.Inactive` / `.OverDrag`                                    |
| ModalTransition                   | `.FULLSCREEN` / `.FULL`                                      | 仅 `DEFAULT` / `NONE` / `ALPHA`                              |
| BlurStyle                         | `.BackgroundRegular`（驼峰）                                 | `BACKGROUND_REGULAR`（SNAKE_CASE）或 `Thin`/`Regular`/`Thick` |
| Navigation                        | `.subtitle('...')`                                           | Navigation 无 subtitle，用 `.title()`                        |
| Search                            | `.caretColor('#...')`                                        | 不存在于 SearchAttribute                                     |
| Text                              | `.alignItems(VerticalAlign.Bottom)`                          | alignItems 是容器方法；Text 用 `.textAlign()`                |
| Radio / TextPicker                | `.selectedColor('#...')`                                     | 不存在于对应 Attribute                                       |
| DatePicker                        | `.onDateAccept(...)`                                         | 用 `.onChange` / `.onDateChange`                             |
| ColorFilter                       | `ColorFilter.matrix([...])`                                  | 不存在于 typeof ColorFilter                                  |
| DataChangeListener                | `l.onDataReload()`                                           | 用编译器建议方法名                                           |
| IMonitor                          | `monitor.before(path)` / `after(path)`                       | 不存在                                                       |
| Shape 构造                        | `Shape({ viewPort: {...} })`                                 | `Shape()` + `.viewPort({...})` 链式                          |
| Line 起点/终点                    | `.startPoint({ x: 10, y: 20 })`                              | `.startPoint([10, 20])` 参数是 `Array<number>`               |
| Search 搜索按钮                   | `searchButton('搜索', { fontSize, color })`                  | `fontColor` 非 `color`                                       |
| Text 文本溢出                     | `.textOverflow(TextOverflow.Ellipsis)`（直传枚举）           | 形参是 `TextOverflowOptions` 对象                            |
| TextInput/TextArea 文本溢出       | `.textOverflow({ overflow: TextOverflow.Ellipsis })`（照搬 Text 写法） | 形参是 `TextOverflow` 枚举直传                               |
| Search 占位符                     | `.placeholder('请输入')`（当方法调）                         | 占位文本走构造器 `Search({ placeholder: '' })`               |
| Radio 选中色                      | `.selectedColor(Color.Red)`                                  | `.radioStyle({ checkedBackgroundColor: Color.Red })`         |
| Row/Column alignItems 轴          | Row 用 `HorizontalAlign.*` / Column 用 `VerticalAlign.*`     | **交叉轴反直觉**：`Row().alignItems(VerticalAlign.Center)`   |
| GestureGroup 子手势               | `GestureGroup(mode).children([tap, pan])`                    | 构造器变参：`GestureGroup(GestureMode.Sequence, tap, pan)`   |
| NavigationOperation               | `NavigationOperation.CANCEL` / `.process()`                  | 仅 `PUSH`/`POP`/`REPLACE`，无 CANCEL/PROCESS                 |
| Text.selection                    | `.selection([start, end])`（传数组）                         | 两个位置参数：`.selection(start, end)`                       |
| ButtonMode                        | `.displayMode(ButtonMode.NORMAL)`                            | `ButtonMode` 枚举不存在                                      |
| PanelType                         | `.MiniCard` / `.HalfCard`                                    | `PanelType.Minibar` / `.Foldable`                            |
| ImageRenderMode                   | `ImageRenderingMode.ORIGINAL`                                | `ImageRenderMode.Original`                                   |
| DataPanelType                     | `DataPanelType.Close` / `.Ring`                              | `DataPanelType.Circle` / `.Line`                             |
| **Stack**                         | `.justifyContent()` / `.alignItems()` 在 Stack 上            | Stack 对齐**只在构造器**：`Stack({ alignContent: Alignment.TopStart })`，无 `.justifyContent()` 也无 `.alignItems()` |
| **Flex space**                    | `Flex({ space: 10 })`                                        | Flex 的 `space` 是 `{ main: LengthMetrics.vp(8) }`，不是数字 |
| **Switch**                        | `Switch(...)` 组件                                           | ArkUI 无 `Switch` 组件，用 `Toggle({ type: ToggleType.Switch, isOn })` |
| **ScrollAlign** vs **EdgeEffect** | `ScrollAlign.Start` 用于 `.edgeEffect()` 等混用              | `ScrollAlign` 用于 `scrollToIndex()`（Start/Center/End/Auto）；`EdgeEffect` 用于 `.edgeEffect()`（Spring/Fade/None）— 两者不可混用 |
| **Canvas Settings**               | `CanvasRenderingContext2DSettings`                           | 正确名字：`RenderingContextSettings`（`new CanvasRenderingContext2D(new RenderingContextSettings(true))`） |
| **List .alignList()**             | `.alignList(ListItemAlign.X)`                                | List 无此属性，不存在                                        |
| **vp2px/px2vp**                   | 全局调用 `vp2px(20)`                                         | 已废弃；用 `this.getUIContext().vp2px(20)` 或 `display.getDefaultDisplaySync().densityPixels` 换算 |
| **NavPathStack import**           | `import { NavPathStack } from '@kit.ArkUI'`                  | NavPathStack 是全局类型，不需要 import                       |
| **onSizeChange 参数**             | `.onSizeChange((w, h) => {})`                                | 签名：`(oldValue: SizeOptions, newValue: SizeOptions) => void` |
| **List .alignListItem()**         | `.alignListItem(ListItemAlign.Center)`                        | 正确名是 `ListAlign` 不是 `ListItemAlignment`；List 属性是 `.alignListItem(ListItemAlign)` |
| **Slider .onGesture()**           | `.onGesture()`                                                | Slider 用 `.gesture()` 不是 `.onGesture()` |
| **TimePicker .fontSize()**        | `.fontSize(16)`                                               | `TimePicker` 用 `.textStyle(PickerTextStyle)` 不是 `.fontSize()` |
| **SaveButton .margin()**          | `SaveButton().margin(8)`                                      | 安全组件（SaveButton/PasteButton）接受 `.padding()` 但不接受 `.margin()` |
| **Tabs .barActiveColor()**        | `.barActiveColor(Color.Blue)`                                 | 不存在；用 `BottomTabBarStyle`/`SubTabBarStyle` 通过 `TabContent.tabBar()` 自定义 |
| **Navigation .onReady()**         | `.onReady(() => {})`                                          | Navigation 无 `.onReady()`，用 `.navDestination(builder)` 注册目标 |
| **$r('app.media.app_icon')**      | `$r('app.media.app_icon')`                                    | `app_icon` 非默认资源名；用 `$r('app.media.startIcon')` 或确认 resources/base/media 下实际文件名 |
| **.minWidth() / .minHeight()**    | `.minWidth(100)`                                              | 最小尺寸约束用 `.constraintSize({ minWidth: 100 })`，不是 `.minWidth()` |
| **.hideNavBar() 位置**            | `NavDestination().hideNavBar(true)`                           | `.hideNavBar()` 属于 **Navigation** 非 NavDestination |

### 其他已知不存在（禁止使用）

| 名称                                                  | 说明                                                         |
| ----------------------------------------------------- | ------------------------------------------------------------ |
| `WaterFlowController`                                 | WaterFlow 无控制器                                           |
| `StarStyle` 枚举                                      | Rating starStyle 只接受自定义图片对象                        |
| `SnapAlign` / `SnapPagination`                        | scrollSnap 不可用                                            |
| `curves.easeInOut()`                                  | 用 `curves.initCurve(Curve.EaseInOut)`                       |
| `LengthMetrics.vp()`                                  | LengthMetrics 是类型不能当值用                               |
| `GradientDirection.BottomRight`                       | 正确名是 `RightBottom`（仅 TopLeft/TopRight/BottomLeft/RightBottom/LeftBottom）                               |
| `TextInputStyle.Normal`                               | 不存在，不调 `.style()`                                      |
| `Curve.springMotion` / `Curve.responsiveSpringMotion` | 这些是 `curves` 命名空间**函数**，非 `Curve.*` 枚举成员      |
| `CircleShape`/`RectShape` 当组件用                    | 这些是 shape 描述符类，非 UI 容器组件；画图形用 `Circle`/`Rect` 组件 |

---

## 常见错误对比

### 参数名捏造

| ❌ 错误写法              | ✅ 正确写法                    |
| ----------------------- | ----------------------------- |
| `.bgColor('#ff0000')`   | `.backgroundColor('#ff0000')` |
| `.radius(8)`            | `.borderRadius(8)`            |
| `.textSize(16)`         | `.fontSize(16)`               |
| `.textColor(Color.Red)` | `.fontColor(Color.Red)`       |
| `List({ gap: 10 })`     | `List({ space: 10 })`         |

### 枚举值错误

| ❌ 错误写法                    | ✅ 正确写法                     |
| ----------------------------- | ------------------------------ |
| `.textAlign('center')`        | `.textAlign(TextAlign.Center)` |
| `.fontWeight('bold')`         | `.fontWeight(FontWeight.Bold)` |
| `PanelType.MiniCard`          | `PanelType.Minibar`            |
| `ImageRenderingMode.ORIGINAL` | `ImageRenderMode.Original`     |

**Color 枚举仅 12 色**：`White`/`Black`/`Blue`/`Brown`/`Gray`/`Green`/`Grey`/`Orange`/`Pink`/`Red`/`Yellow`/`Transparent`。**不存在 `Gold`**，用 hex 字符串 `'#FFD700'` 或 `$r('sys.color.xxx')`。

**AppStorage API 签名**：`setOrCreate(key, value)` / `get(key)` / `set(key, value)` / `has(key)`，**没有 `.put()`**。

### 回调参数类型错误

| ❌ 错误写法                                                  | ✅ 正确写法                                                   |
| ----------------------------------------------------------- | ------------------------------------------------------------ |
| `.onClick((event: GestureEvent) => {})`                     | `(event: ClickEvent) => {}`                                  |
| `Video.onTimeUpdate((time: number) => {})`                  | `Video.onUpdate((data: PlaybackInfo) => { data.time })`      |
| `Video.onPrepared((duration: number) => {})`                | `Video.onPrepared((data: PreparedInfo) => { data.duration })` |
| `bindPopup onStateChange((vis: boolean) => {})`             | `onStateChange((e: PopupStateEvent) => { e.isVisible })`     |
| `curves.springCurve(0.3, 1.0)`                              | `curves.springCurve(10, 1, 228, 30)`（4 参数）               |
| `TextPicker.onChange((value: string, index: number) => {})` | `(value: string \| string[], index: number \| number[]) => {}`（联合类型） |

### 资源名称错误

| ❌ 错误写法                                | ✅ 正确写法                         |
| ----------------------------------------- | ---------------------------------- |
| `$r('sys.symbol.share')`                  | `$r('sys.symbol.upload')`          |
| `$r('sys.symbol.settings')`               | `$r('sys.symbol.gearshape')`       |
| `$r('sys.symbol.search')`                 | `$r('sys.symbol.magnifyingglass')` |
| `$r('sys.symbol.home')`                   | `$r('sys.symbol.house')`           |
| `$r('sys.color.ohos_id_color_emergency')` | `'#FFE84026'`（hex）               |
| `$r('app.media.app_icon')`                 | 资源名 `app_icon` 不存在；用 `$r('app.media.startIcon')` 或实际存在的资源名 |

---

## 元规则：编译器是唯一真相

1. **模型记忆不可靠**：22 处臆造 API 证明模型会自信地编造属性名
2. **本地文档也可能滞后**：`quick-apis` 表可能与实际 d.ts 签名不一致
3. **SDK 版本差异**：兼容 SDK 6.0.0(20) 时部分 API 需 26.0.0

**流程**：写 → 编译 → 看错误 → 按 `Did you mean` 修 → 再编译。拿不准的 API，先写最小调用让编译器报真实签名，再据此完善。

**泛型重载匹配**：调用 API 时确认参数数量和类型匹配某个已存在的重载，不要编造参数或传不存在的泛型类型参数。

## 参考

- 类型注解见 [00-arkts-syntax](00-arkts-syntax.md)
- 空安全规则见 [00-arkts-syntax](00-arkts-syntax.md)
- @Extend/@Styles 返回类型见 [10-style](10-style.md)
- 废弃 API 替换见 [14-deprecated](14-deprecated.md)
- 相关错误码：**10505001**（属性不存在）、**10605038**（无类型对象字面量）