# 测试提示词

## 基础功能测试

### 测试场景 1：Tabs 缓存不释放（源码分析）

**提示词**：我的 ArkUI 页面有 4 个 TabContent 的 Tabs 组件，没有设置 cachedMaxCount。帮分析是否有内存问题并给出修改建议。

**预期输出**：
- 命中 tabs_cache_not_released (High)
- 建议设置 .cachedMaxCount(1, TabsCacheMode.CACHE_BOTH_SIDE)

### 测试场景 2：不可见页面冗余加载（Dump 分析）

**提示词**：以下是一段 ArkUI inspector dump 片段（文本格式），分析其中是否存在不可见页面冗余加载热点：

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

**预期输出**：
- 命中 invisible_page (Medium)
- Column (ComponentName: HiddenFeedPage) VisibleAndActive=0 且有 12 个后代节点
- 建议使用条件渲染 if(visible){Page()} 替代 visibility(Hidden)

## 边界条件测试

### 测试场景 3：空输入（无反模式代码）

**提示词**：请分析以下 ArkTS 代码的 ArkUI 内存热点，给出修改建议。

```ts
List() {
  ForEach(this.items, (item: string) => {
    ListItem() { Text(item) }
  })
}
```

**预期输出**：
- 命中 list_non_lazy (High) — List 内使用 ForEach 而非 LazyForEach

### 测试场景 4：无命中代码

**提示词**：请分析以下 ArkTS 代码的 ArkUI 内存热点，给出修改建议。

```ts
@Component
struct CleanPage {
  @State count: number = 0;
  build() {
    Column({ space: 10 }) {
      Text('Count: ' + this.count)
      Button('Add').onClick(() => { this.count++; })
    }
  }
}
```

**预期输出**：
- 输出"未发现已知故障"而非报错

## 错误处理测试

### 测试场景 5：无有效输入

**提示词**：帮我在 ArkUI 页面中实现一个下拉刷新功能，刷新时显示加载动画。

**预期输出**：
- 不触发内存热点分析（非内存问题诉求）
