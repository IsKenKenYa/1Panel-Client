# ArkUI API 参数速查索引

> 各分类独立文件，按需读取。每个组件以"卡片"形式呈现，包含构造签名、参数表、属性方法表和事件表。

## 检索方式（避免整读大文件）

**查具体组件 API**（Row / List / Text / Navigation 等）：
- **大文件**（01-layout 24KB / 02-basic 28KB）：在「组件索引」查组件所在文件，再 `Grep "^#{3,4} 组件名" <文件> -A 45 -n` 取卡片（卡片 30–50 行）。**勿整读**，整读只为一张卡片浪费 10×+ token。
- **小文件**（<5KB，如 03/04/05/07/11/12）：直接 Read 整个分类文件即可，比走索引更省。
- **已知组件所在文件**：直接 `Grep "^#{3,4} 组件名" <文件> -A 45 -n` 取卡片，可跳过本索引。

**查主题 / 枚举 / 资源名**（动画 / 手势 / 装饰器 / 枚举 / sys.symbol）：
- 08/09/10/14/16 文件较小（<5KB），直接 Read 或 Grep 主题词
- 17-resources（50KB sys.symbol / sys.color 名称表）：`Grep "图标名或颜色名" 17-resources.md` 定位，勿整读

## 分类文件

| 文件 | 分类 | 大小 |
|------|------|------|
| [01-layout.md](01-layout.md) | 1. 布局容器 | 24KB |
| [02-basic-components.md](02-basic-components.md) | 2. 基础组件 | 28KB |
| [03-data-display.md](03-data-display.md) | 3. 数据展示组件 | 3KB |
| [04-selectors.md](04-selectors.md) | 4. 选择器组件 | 2KB |
| [05-media.md](05-media.md) | 5. 媒体与绘图组件 | 3KB |
| [06-advanced.md](06-advanced.md) | 6. 高级/组合组件 | 2KB |
| [07-security.md](07-security.md) | 7. 安全组件 | <1KB |
| [08-state-decorators.md](08-state-decorators.md) | 8. 状态管理装饰器 | 5KB |
| [09-animation.md](09-animation.md) | 9. 动画 API | 5KB |
| [10-gesture.md](10-gesture.md) | 10. 手势与事件 | 3KB |
| [11-dialog-menu.md](11-dialog-menu.md) | 11. 弹窗/菜单/模态 | 5KB |
| [12-navigation.md](12-navigation.md) | 12. 导航与路由 | 3KB |
| [13-rendering.md](13-rendering.md) | 13. 渲染控制 | <1KB |
| [14-extension.md](14-extension.md) | 14. 自定义扩展 | 1KB |
| [15-theme-style.md](15-theme-style.md) | 15. 主题与样式 | <1KB |
| [16-enums.md](16-enums.md) | 16. 枚举类型速查 | 4KB |
| [17-resources.md](17-resources.md) | 17. 系统资源名称（sys.symbol / sys.color） | 50KB |
| [18-error-code.md](18-error-code.md) | 18. 错误码速查 | <1KB |

## 组件索引（按组件名定位卡片所在文件）

> 用 `Grep "^#{3,4} 组件名" <文件> -A 45 -n` 取卡片。

**01-layout.md** — 布局容器
Row / Column / Flex / Stack / List / ListItem / ListItemGroup / Grid / GridRow / GridCol / WaterFlow / Scroll / Tabs / TabContent / Swiper / RelativeContainer（含核心用法） / SideBarContainer / Panel / Refresh / Badge / Counter / AlphabetIndexer

**02-basic-components.md** — 基础组件
Text / Span / ImageSpan / SymbolSpan·SymbolGlyph / TextInput / TextArea / Button / Image / Slider / Toggle / Radio / Checkbox / CheckboxGroup / Progress / Rating / LoadingProgress / Search / Select

**03-data-display.md** — 数据展示
Gauge / DataPanel / QRCode / CalendarPicker·TextClock·TextTimer

**04-selectors.md** — 选择器
DatePicker / TimePicker / TextPicker / PatternLock

**05-media.md** — 媒体与绘图
Video / Canvas·Shape

**07-security.md** — 安全
SaveButton / PasteButton

**11-dialog-menu.md** — 弹窗/菜单/模态
AlertDialog / ActionSheet / CustomDialogController / 菜单 / Popup / bindSheet（模态）

**12-navigation.md** — 导航与路由
Navigation / NavPathStack / NavDestination / Router

## 主题类文件（按主题词检索，无单组件卡片）

| 文件 | 主题 |
|------|------|
| 08-state-decorators.md | V1/V2 装饰器、全局状态 API |
| 09-animation.md | 属性动画 / 动画曲线 / 转场动画 / TransitionEffect / PageTransition / 帧动画 |
| 10-gesture.md | 基础手势 / 组合手势 / 手势绑定 / 通用事件 / 拖拽事件 |
| 14-extension.md | Modifier 系列 / 自定义节点 |
| 16-enums.md | 布局 / 组件 / 手势 / 动画 / 效果 枚举 |
| 17-resources.md | sys.symbol 各类图标 / sys.color 128 色（Grep 名称定位） |
