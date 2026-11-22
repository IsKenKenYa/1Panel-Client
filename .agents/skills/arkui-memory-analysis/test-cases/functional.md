# 功能性测试用例

> 仓库智能检视流水线（hmos-skill-test-runner）识别的固定文件。精简收录源码分析、dump 分析及空输入边界判定。

通用报告判定：有发现时，输出应聚焦相关热点类型、位置、建议与验证，不列出或合并总结未命中类别；整次无明确问题时只简短说明已读范围与限制。

---

### 测试用例：FUNC-SOURCE-001

**skill**：arkui-memory-analysis
**类型**：functional（功能验证）

#### 输入

请分析以下 ArkTS 代码的 ArkUI 内存热点：

```ts
List() {
  ForEach(this.items, (item: string) => {
    ListItem() { Text(item) }
  })
}
```

#### 预期输出

**验证标准**：

- 识别 List 内使用 ForEach 而非 LazyForEach，命中 `list_non_lazy` 热点类型
- 建议将 ForEach 替换为 LazyForEach + IDataSource 实现
- 说明 List 只有配 LazyForEach 才懒加载，ForEach 会一次性全量建好所有子组件、离屏不回收
- 不声称实测内存值或帧率

---

### 测试用例：FUNC-SOURCE-002

**skill**：arkui-memory-analysis
**类型**：functional（功能验证）

#### 输入

请分析以下 ArkTS 代码的 ArkUI 内存热点：

```ts
Tabs() {
  TabContent() { Text('推荐') }.tabBar('推荐')
  TabContent() { Text('科技') }.tabBar('科技')
  TabContent() { Text('体育') }.tabBar('体育')
}
```

#### 预期输出

**验证标准**：

- 识别 Tabs 有 4 个 TabContent 但未设置 cachedMaxCount，命中 `tabs_cache_not_released` 热点类型
- 建议设置 `.cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE)` 限制缓存数量
- 说明不设置时所有已访问页签默认全部缓存不释放

---

### 测试用例：FUNC-DUMP-001

**skill**：arkui-memory-analysis
**类型**：functional（功能验证）

#### 输入

以下是一段 ArkUI inspector dump 片段（文本格式），分析其中是否存在不可见页面冗余加载热点：

```
|-> root childSize:2
  ID: 1
  VisibleAndActive: 1
    |-> Column childSize:1
      ID: 2
      VisibleAndActive: 1
        |-> Text childSize:0
          ID: 3
          VisibleAndActive: 1
          Content: 当前页面
    |-> Column childSize:2
      ID: 10
      VisibleAndActive: 0
      ComponentName: HiddenFeedPage
        |-> Text childSize:0
          ID: 11
          VisibleAndActive: 0
          Content: 隐藏资讯列表
        |-> List childSize:1
          ID: 12
          VisibleAndActive: 0
            |-> ListItem childSize:0
              ID: 13
              VisibleAndActive: 0
              Content: 隐藏资讯 1
            |-> ListItem childSize:0
              ID: 14
              VisibleAndActive: 0
              Content: 隐藏资讯 2
            |-> ListItem childSize:0
              ID: 15
              VisibleAndActive: 0
              Content: 隐藏资讯 3
            |-> ListItem childSize:0
              ID: 16
              VisibleAndActive: 0
              Content: 隐藏资讯 4
            |-> ListItem childSize:0
              ID: 17
              VisibleAndActive: 0
              Content: 隐藏资讯 5
            |-> ListItem childSize:0
              ID: 18
              VisibleAndActive: 0
              Content: 隐藏资讯 6
            |-> ListItem childSize:0
              ID: 19
              VisibleAndActive: 0
              Content: 隐藏资讯 7
            |-> ListItem childSize:0
              ID: 20
              VisibleAndActive: 0
              Content: 隐藏资讯 8
        |-> Column childSize:1
          ID: 21
          VisibleAndActive: 0
            |-> Text childSize:0
              ID: 22
              VisibleAndActive: 0
              Content: 该内容已加载但不应出现在当前页面
```

#### 预期输出

**验证标准**：

- 识别 Column 节点（ComponentName: HiddenFeedPage）VisibleAndActive=0 且有 12 个后代节点（Text/List/ListItem/Column），命中 `invisible_page` 热点类型
- 说明不可见子树被构建但用户看不到，内存 100% 浪费
- 建议使用条件渲染 `if(visible){Page()}` 替代 `visibility(Visibility.Hidden)`，不构建时零成本

---

### 测试用例：FUNC-DUMP-002

**skill**：arkui-memory-analysis
**类型**：functional（功能验证）

#### 输入

以下是一段 ArkUI inspector dump 片段（文本格式），请分析其中是否存在 Tabs 缓存不释放热点：

```
|-> root childSize:1
  ID: 1
  Depth: 1
  VisibleAndActive: 1
  FrameRect: RectT (0.00, 0.00) - [720.00 x 1280.00]
    |-> Tabs childSize:4
      ID: 2
      Depth: 2
      VisibleAndActive: 1
        |-> TabContent childSize:2
          ID: 3
          Depth: 3
          VisibleAndActive: 1
            |-> Column childSize:1
              ID: 4
              Depth: 4
              VisibleAndActive: 1
                |-> Text childSize:0
                  ID: 5
                  Depth: 5
                  VisibleAndActive: 1
                  Content: 推荐
        |-> TabContent childSize:2
          ID: 10
          Depth: 3
          VisibleAndActive: 0
            |-> Column childSize:1
              ID: 11
              Depth: 4
              VisibleAndActive: 0
                |-> Text childSize:0
                  ID: 12
                  Depth: 5
                  VisibleAndActive: 0
                  Content: 科技
        |-> TabContent childSize:2
          ID: 20
          Depth: 3
          VisibleAndActive: 0
            |-> Column childSize:1
              ID: 21
              Depth: 4
              VisibleAndActive: 0
                |-> Text childSize:0
                  ID: 22
                  Depth: 5
                  VisibleAndActive: 0
                  Content: 体育
        |-> TabContent childSize:2
          ID: 30
          Depth: 3
          VisibleAndActive: 0
            |-> Column childSize:1
              ID: 31
              Depth: 4
              VisibleAndActive: 0
                |-> Text childSize:0
                  ID: 32
                  Depth: 5
                  VisibleAndActive: 0
                  Content: 财经
```

#### 预期输出

**验证标准**：

- 识别 4 个 TabContent 同时存活，其中 3 个 VisibleAndActive=0（不可见），命中 `tabs_cache_not_released` 热点类型
- 说明不可见页签仍缓存不释放，内存持续增长
- 建议设置 `Tabs.cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE)`

---

### 测试用例：FUNC-EMPTY-001

**skill**：arkui-memory-analysis
**类型**：functional（功能验证）

#### 输入

请分析以下 ArkTS 代码的 ArkUI 内存热点，给出修改建议。

```ts
@Entry
@Component
struct CleanPage {
  @State count: number = 0;
  build() {
    Column({ space: 10 }) {
      Text('Count: ' + this.count)
      Button('Add').onClick(() => { this.count++; })
    }
    .width('100%').height('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 输出"未发现已知故障"或同等说明，不报错
- 不虚构内存热点或编造性能问题
- 简短说明已分析代码范围和限制
