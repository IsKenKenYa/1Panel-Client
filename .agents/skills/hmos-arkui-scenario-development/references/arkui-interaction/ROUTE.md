# 手势/键盘交互事件 — 路由入口

## 路由决策树

```
进入手势/键盘交互场景
│
├── Step 1: 默认进入 GESTURE-01（手势绑定方式与优先级）
│   │  说明：手势绑定是手势生效的前提，任何手势交互场景都需要先确认绑定方式
│   │
│   └── 检查是否需要同时进入 GESTURE-02 → 继续 Step 2
│
├── Step 2: 是否涉及具体手势类型的 API 使用？
│   │
│   │  触发信号（命中任一即路由）：
│   │    · API 关键词：TapGesture / LongPressGesture / PanGesture /
│   │      PinchGesture / RotationGesture / SwipeGesture / onClick / onTouch
│   │    · 交互意图词：点击 / 双击 / 长按 / 拖拽 / 捏合缩放 / 旋转 / 滑动
│   │    · 场景特征：为组件添加上述手势交互，或需要了解具体手势 API 的
│   │      参数配置与回调事件（onActionStart / onActionUpdate / onActionEnd）
│   │
│   ├── 命中任一信号 → 路由到 GESTURE-02（手势类型 API 使用）
│   └── 未命中 → 不需要 GESTURE-02
│   └── 继续 Step 3
│
├── Step 3: 是否涉及手势组合（多个手势联动）？
│   │
│   │  触发信号（命中任一即路由）：
│   │    · API 关键词：GestureGroup / GestureMode / Sequence / Parallel / Exclusive
│   │    · 交互意图词：多手势 / 手势组合 / 顺序手势 / 并行手势 / 互斥手势 /
│   │      长按后拖动 / 同时旋转缩放 / 手势联动
│   │    · 场景特征：多个手势需要按顺序触发、同时并行触发、或互斥选择时
│   │
│   ├── 命中任一信号 → 路由到 GESTURE-03（手势组合 GestureGroup）
│   └── 未命中 → 不需要 GESTURE-03
│   └── 继续 Step 4
│
├── Step 4: 是否涉及父子嵌套的手势/触摸事件响应控制，或手势冲突与动态控制？
│   │
│   │  触发信号（命中任一即路由）：
│   │    · API 关键词：hitTestBehavior / responseRegion / onTouchIntercept /
│   │      HitTestMode（Block / None / Transparent / BLOCK_HIERARCHY /
│   │      BLOCK_DESCENDANTS）/ onChildTouchTest / onGestureCollectIntercept /
│   │      monopolizeEvents / onGestureJudgeBegin /
│   │      shouldBuiltInRecognizerParallelWith / onGestureRecognizerJudgeBegin /
│   │      onTouchTestDone / preventBegin / GestureRecognizer /
│   │      GestureJudgeResult / GestureMask.IgnoreInternal / ScrollableTargetInfo
│   │    · 交互意图词：蒙层穿透 / 事件拦截 / 触摸热区 / 父子手势 / 多层级手势 /
│   │      手势竞争 / 事件透传 / 阻止滚动 / 扩大点击范围 / 手势冲突 /
│   │      系统手势抢占 / 多点触控冲突 / 手势拦截 / 手势透传 / 悬浮球禁用 /
│   │      嵌套滚动 / 禁用缩放 / 手势独占 / 动态拒绝手势 / 阻止手势识别
│   │    · 场景特征：父子组件均绑定手势/事件需控制响应；蒙层/遮罩选择性穿透；
│   │      扩大可点击区域；自定义手势与系统内置手势冲突；多指同时操作多处响应；
│   │      动态控制手势是否响应；父组件管理子组件手势识别器；阻止特定类型手势识别
│   │
│   ├── 命中任一信号 → 路由到 GESTURE-04（手势事件响应控制与冲突处理）
│   └── 未命中 → 不需要 GESTURE-04
│
└── 优先级规则：
    · GESTURE-01（绑定方式）> GESTURE-02（手势类型）> GESTURE-03（手势组合）> GESTURE-04（手势事件响应控制与冲突处理）
    · 同时命中多个时，按优先级依次进入，绑定方式是手势生效的前提
```

## 场景索引

### GESTURE-01 手势绑定场景

```yaml
scene_id: ARKUI-02-A
scene_name: 手势绑定方式与优先级
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-bind.md
```

### GESTURE-02 手势类型场景

```yaml
scene_id: ARKUI-02-B
scene_name: 手势类型 API 使用
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-type.md
```

### GESTURE-03 手势组合场景

```yaml
scene_id: ARKUI-02-C
scene_name: 手势组合 GestureGroup 使用
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-group.md
```

### GESTURE-04 手势事件响应控制与冲突处理

```yaml
scene_id: ARKUI-02-D
scene_name: 手势事件响应控制与冲突处理
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./gesture-control.md
```
