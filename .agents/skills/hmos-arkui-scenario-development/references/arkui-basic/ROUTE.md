# ArkUI 基础语法 — 路由入口

## 路由决策树

```
进入 ArkUI 基础语法场景
│
├── Step 1: 是否涉及 ArkUI 基础ui能力？
│   │
│   │  触发信号（命中任一即路由，并按命中的能力章节定位）：
│   │    · API 关键词：@BuilderParam / @Component / @ComponentV2 / @Builder /
│   │      @LocalBuilder / @Styles / @Extend
│   │    · 交互意图词：UI 占位 / UI 插槽 / 可替换 UI / 兜底渲染 / 自定义组件 /
│   │      有状态组件 / 无状态片段 / 跨文件复用 / 局部复用 / V1 V2 装饰器选型 /
│   │      样式复用 / 通用样式 / 专属样式 / 参数化样式 / 样式组合抽取
│   │    · 场景特征：组件对外暴露可替换 UI 入口；自定义 UI 单元重复使用；
│   │      页面中存在大量重复样式组合需要抽取
│   │
│   ├── 命中任一信号 → 路由到 BASIC-01（基础 UI 场景）
│   └── 未命中 → 不需要 BASIC-01
│   └── 继续 Step 2
│
├── Step 2: 是否涉及基础扩展能力（组件工厂动态分发 / 自定义布局容器）？
│   │
│   │  触发信号（命中任一即路由，并按命中的能力章节定位）：
│   │    · API 关键词：wrapBuilder / WrappedBuilder / onMeasureSize /
│   │      onPlaceChildren / child.measure / child.layout / SizeResult
│   │    · 交互意图词：组件工厂 / 动态分发 / type 渲染 / 多类型 item /
│   │      自定义容器 / 自定义布局 / 拖拽挤位重排
│   │    · 场景特征：同一容器按数据 type 渲染多种变体且需可扩展；
│   │      系统内置容器（Row/Column/Grid/WaterFlow）无法满足，需自定义独有布局
│   │
│   ├── 命中任一信号 → 路由到 BASIC-02（基础扩展场景）
│   └── 未命中 → 不需要 BASIC-02
│   └── 继续 Step 3
│
└── Step 3: 是否涉及基础复用能力（组件复用 / 列表复用 / V1 V2 复用差异）？
    │
    │  触发信号（命中任一即路由，并按命中的能力章节定位）：
    │    · API 关键词：@Reusable / @ReusableV2 / reuseId / reuse /
    │      LazyForEach / IDataSource / Repeat / virtualScroll / cachedCount /
    │      aboutToReuse / aboutToRecycle / BuilderNode / NodeContainer /
    │      NodePool / wrapBuilder / reusePool / poolAccepts
    │    · 交互意图词（用户表达常不带“复用”二字，尤其 if 动态显隐类）：
    │      组件复用 / 列表项复用 / 复用池 / 滚动复用 / 多类型列表项 / 新闻列表 / 信息流 /
    │      跨列表复用 / 全局复用池 / 占位组件 / V1 V2 复用差异
    │      if 动态显隐类：展开收起 / 折叠 / 显示隐藏切换 /
    │      登录态切换 / if 条件渲染 / 频繁切换避免重建
    │    · 场景特征：长列表滚动复用；多类型按 type 分池；跨 Tab 全局复用；
    │      if 控制组件动态显隐（展开收起/登录态切换），节点随条件挂载/卸载
    │
    ├── 命中任一信号 → 路由到 BASIC-03（基础复用场景）
    └── 未命中 → 不需要 BASIC-03
```

## 场景索引

### BASIC-01 ArkUI 基础ui场景

```yaml
scene_id: ARKUI-BASIC
scene_name: ArkUI 基础ui场景
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-ui.md
```

### BASIC-02 基础扩展场景

```yaml
scene_id: ARKUI-BASIC-EXT
scene_name: ArkUI 基础扩展场景
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-extension.md
```

### BASIC-03 基础复用场景

```yaml
scene_id: ARKUI-BASIC-REUSE
scene_name: ArkUI 基础复用场景
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./basic-reuse.md
```
