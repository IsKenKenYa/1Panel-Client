## 13. 渲染控制

| 语法 | 签名 | 说明 |
|------|------|------|
| **if/else** | `if (condition) {} else if {} else {}` | 条件渲染 |
| **ForEach** | `ForEach(arr, (item, index?) => void, keyGen?)` | 迭代渲染 |
| **LazyForEach** | `LazyForEach(dataSource, (item, index?) => void, keyGen?)` | 懒加载迭代 |
| **Repeat** | `Repeat<T>(arr)` | API 12+ V2 版渲染控制 |

**Repeat 方法链：**

| 方法 | 签名 | 说明 |
|------|------|------|
| .each | `.each((ri: RepeatItem<T>) => void)` | 渲染每项 |
| .key | `.key((item, index) => string)` | 生成 key |
| .virtualScroll | `.virtualScroll(options?)` | 虚拟滚动 |
| .template | `.template(name, itemGen, options?)` | 模板化 |
| .cachedCount | `.cachedCount(value: number)` | 缓存数 |
| .totalCount | `.totalCount(value: number)` | 总数 |
| .onRequestItem | `.onRequestItem((index, key) => void)` | 请求数据 |

### 典型用法

#### ForEach 必须有 key

```ts
// ✅ 正确：第三个参数为 keyGenerator，用业务 ID
ForEach(this.list, (item: Item) => { Text(item.name) }, (item: Item) => item.id.toString())

// ❌ 错误：缺 key 或用索引做 key
ForEach(this.list, item => { Text(item.name) })                               // 缺 key
ForEach(this.list, item => { Text(item.name) }, (item, idx) => idx)            // 索引做 key
```

#### Repeat virtualScroll cachedCount 位置

```ts
// ✅ 正确：cachedCount 在滚动容器上
List() { Repeat(this.list).virtualScroll({ totalCount: this.list.length }) }.cachedCount(3)

// ❌ 错误：cachedCount 在 Repeat 链上 → 10505001
List() { Repeat(this.list).virtualScroll({ totalCount: this.list.length }).cachedCount(3) }
```

#### LazyForEach 数据更新

```ts
// dataSource 不可重新赋值，必须用 DataChangeListener 通知
// 替换数组项后调 dataSource.notifyDataChanged(index)
```

---
