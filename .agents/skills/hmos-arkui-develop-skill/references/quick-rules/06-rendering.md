# 8. 渲染控制约束

## ForEach

| 规则 | 说明 | 错误码 |
|------|------|--------|
| **必须有第三个参数（keyGenerator）** | 缺少 key 生成器导致渲染异常 | — |
| key 用业务 ID，不用索引 | `(item, index) => index` 导致渲染不正确和性能差 | — |
| key 必须唯一 | 重复键值导致渲染异常 | — |
| 默认 key 有性能隐患 | 默认使用 `index + '__' + JSON.stringify(item)`，复杂对象 JSON 序列化占用大量内存 | — |
| bigint 等不可序列化类型会导致 jscrash | 必须提供自定义 key | — |
| 不建议与 LazyForEach 同时使用 | 同一滚动容器内不应混用 | — |
| 不建议用内容相同的数组项替换旧项 | 键值未变时数据变化不渲染 | — |
| **ForEach/LazyForEach 不是真实组件** | 不支持 `.layoutWeight()`/`.width()` 等通用布局属性（需包进容器再对容器设属性） | — |

### LazyForEach

| 规则 | 说明 |
|------|------|
| 仅特定容器支持懒加载 | 仅 List/ListItemGroup/Grid/Swiper/WaterFlow 支持 |
| 容器内只能有一个 LazyForEach | 不建议同时包含 ListItem/ForEach/LazyForEach 或多个 LazyForEach |
| 每次迭代只产出一个根子组件 | 子组件生成函数有且只有一个根组件 |
| 子组件尺寸不能缺失 | 否则懒加载失效 |
| **dataSource 不可重新赋值** | 也不要用状态变量装 dataSource 再改它（不刷新） |
| **必须通过 DataChangeListener 更新** | `notifyDataChanged/notifyDataAdd/notifyDataDelete/notifyDatasetChange` |
| **Scroll 内放 LazyForEach 无效** | Scroll 不支持懒加载 |

### Repeat (V2)

| 规则 | 说明 | 错误码 |
|------|------|--------|
| 仅在 @ComponentV2 中使用 | V1 用会错 | — |
| virtualScroll 模式需设 totalCount | `virtualScroll({ totalCount: arr.length })` | — |
| cachedCount 设在**滚动容器**上 | 不在 Repeat 链上（否则 **10505001**） | **10505001** |
| key() 必须唯一 | | — |

```ts
// ❌ WRONG -- cachedCount 放 Repeat 链
List() { Repeat(this.list).virtualScroll({ totalCount: this.list.length }).cachedCount(3) }
// ✅ RIGHT
List() { Repeat(this.list).virtualScroll({ totalCount: this.list.length }) }.cachedCount(3)
```

### if/else

| 规则 | 说明 |
|------|------|
| 条件渲染"透明" | 父子组件之间的条件渲染不影响父组件对子组件的限制（如 Grid 内 if 内仍只能 GridItem） |
| 分支必须创建组件 | 空分支会语法错 |
| 分支切换不保留状态 | 旧子组件销毁、新建，不保留状态。需将状态提升到父组件 |
| 条件中不得改变应用状态 | 构造函数中的表达式不得更改应用程序状态 |

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `ForEach(this.list, item => { ... })` 缺第三个参数 | `(item: Item) => Text(item.name), (item: Item) => item.id.toString()` | 必须提供 keyGenerator |
| `(item, index) => index` 做 key | `(item: Item) => item.id.toString()` | 索引做 key 导致渲染不正确 |
| `LazyForEach` 的 dataSource 用状态变量并重新赋值 | 必须用 DataChangeListener 通知 | 重新赋值 dataSource 异常 |
| `LazyForEach` 放在 Scroll 里 | 仅 List/Grid/WaterFlow/Swiper 支持 | Scroll 不支持懒加载 |
| 同一容器内混用 ForEach 和 LazyForEach | 容器内只能有一个 LazyForEach | 不建议混用 |
| Repeat 链上 `.cachedCount(3)` | `.cachedCount(3)` 放在滚动容器上 | 10505001 |

## 参考

- 容器直接子组件约束见 [16-layout](12-layout.md)
- @Observed 嵌套数组不刷新见 [05-state-v1](05-state.md)