# 焦点事件 — 路由入口

## 路由决策树

```
进入焦点场景
│
├── Step 1: 是否涉及焦点事件基础能力（激活/获焦/失焦/焦点框/主动焦点控制）？
│   │
│   │  触发信号（命中任一即路由）：
│   │    · API 关键词：focusable / defaultFocus / requestFocus / clearFocus /
│   │      focusOnTouch / focusBox / stateStyles / outline / onFocus / onBlur /
│   │      FocusPriority / onKeyEvent / HitTestMode / FocusController
│   │    · 交互意图词：焦点 / 获焦 / 失焦 / 焦点框 / 焦点组 /
│   │      默认焦点 / 激活态 / 层级页面焦点
│   │    · 场景特征：组件焦点能力配置、焦点转移与走焦算法、焦点框显示、
│   │      自定义焦点框样式、焦点与按键事件交互、主动获焦/失焦
│   │
│   ├── 命中任一信号 → 路由到 FOCUS-01（焦点事件全场景）
│   └── 未命中 → 不需要 FOCUS-01
│   └── 继续 Step 2
│
└── Step 2: 是否涉及自定义走焦 / Snackbar Tab 闭环 / List 循环走焦？
    │
    │  触发信号（命中任一即路由）：
    │    · API 关键词：nextFocus（自定义走焦）/ textButtonId / nextFocusId /
    │      HdsSnackBar / SnackBarStyleOptions / SnackBarOperationOptions /
    │      List + nextFocus / ListItem 循环走焦 / focusScopeId / tabStop / tabIndex
    │    · 交互意图词：循环走焦 / 首尾互指 / 环形导航 / Snackbar Tab 走焦 /
    │      常驻通知焦点闭环 / List 列表项循环 / 方向键循环 / Tab 键循环
    │    · 场景特征：方向键到达边界后循环回到另一端、Snackbar 与宿主页面
    │      建立 Tab 闭环、List 项之间焦点环形导航
    │
    ├── 命中任一信号 → 路由到 FOCUS-02（自定义走焦场景）
    └── 未命中 → 不需要 FOCUS-02
```

## 场景索引

### FOCUS-01 焦点事件全场景

```yaml
scene_id: ARKUI-FOCUS-01
scene_name: 焦点事件全场景
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./focus-event.md
```

### FOCUS-02 自定义走焦场景

```yaml
scene_id: ARKUI-FOCUS-02
scene_name: 自定义走焦场景
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./focus-move.md
```
