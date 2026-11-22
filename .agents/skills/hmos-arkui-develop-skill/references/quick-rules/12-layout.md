# 16. 布局容器约束

## 规则

### 容器直接子组件约束

| 容器 | 只接受直接子组件 |
|------|----------------|
| `List` | `ListItem`（或 `ListItemGroup`） |
| `Grid` | `GridItem` |
| `Tabs` | `TabContent` |
| `WaterFlow` | `FlowItem` |
| `Shape` | `Rect`/`Path`/`Circle`/`Ellipse`/`Shape`/`Polyline`/`Polygon`/`Image`/`Text`/`Column`/`Row` |

```ts
// ❌ WRONG
List() { Text('item') }
Grid() { Text('cell') }
Tabs() { Text('tab') }

// ✅ RIGHT
List() { ListItem() { Text('item') } }
Grid() { GridItem() { Text('cell') } }
Tabs() { TabContent() { Text('tab') } }
```

`if/else` 是"透明"的：即使条件分支，`Grid` 内仍只能出现 `GridItem`。

### List / Grid / WaterFlow / Swiper

| 规则 | 说明 |
|------|------|
| 使用 LazyForEach 时子组件尺寸不能缺失 | 否则懒加载失效 |
| 同一容器内不建议同时使用 ForEach 和 LazyForEach | |
| 设置 cachedCount 可优化懒加载性能 | |

### Flex

| 规则 | 说明 |
|------|------|
| 注意 flexWrap 默认值和主轴方向的对齐方式 | |
| 嵌套过深可能导致性能问题 | |

### RelativeContainer

| 规则 | 说明 |
|------|------|
| 锚点规则需正确设置 | |
| center/middle 等对齐规则需指定 anchor 和 align | |

### Scroll

| 规则 | 说明 |
|------|------|
| 嵌套滚动场景注意滚动冲突 | |
| Scroll 内不支持 LazyForEach | 仅 List/Grid/WaterFlow/Swiper 支持懒加载 |

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `List()` 内直接放非 `ListItem` | `List() { ListItem() { Text('...') } }` | List 仅接受 ListItem 作为直接子组件 |
| `Tabs()` 内直接放非 `TabContent` | `Tabs() { TabContent() { Text('...') } }` | Tabs 仅接受 TabContent |
| `Grid()` 内直接放非 `GridItem` | `Grid() { GridItem() { Text('...') } }` | Grid 仅接受 GridItem |
| `WaterFlow()` 内直接放非 `FlowItem` | `WaterFlow() { FlowItem() { Text('...') } }` | WaterFlow 仅接受 FlowItem |

## 参考

- 渲染控制（LazyForEach/Repeat）见 [08-rendering](06-rendering.md)