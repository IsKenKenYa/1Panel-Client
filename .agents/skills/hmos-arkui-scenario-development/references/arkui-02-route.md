# 基于 UI 框架构建基础代码逻辑 — 路由入口

## 路由目标

进入 `ARKUI-02` 后，继续判断用户问题命中的二级子场景，并读取对应资源文件。二级子场景不互斥；同一问题涉及多个能力时，必须全部命中并读取全部资源。

输出建议：

```yaml
parent_scene: ARKUI-02
primary_sub_scene: 最核心子场景 ID
secondary_sub_scenes: [其他命中子场景 ID]
next_scene_refs:
  - 命中的叶子文档路径
```

## 路由决策树

```text
进入基于 UI 框架构建基础代码逻辑场景
│
├── Step 1: 建立候选子场景
│   ├── 不在决策树中维护子场景描述；所有具体描述以下方"场景索引"为准
│   ├── 从用户提示词、代码、截图和报错中提取组件名、API、交互对象、UI 行为和异常现象
│   ├── 并行对照所有子场景的 intent_signals，形成 matched_sub_scenes 候选集
│   └── 明确 API / 组件 / 回调 / 异常信号优先；页面、组件、交互等泛化词只用于辅助判断
│
├── Step 2: 用 applies_when 确认适用范围
│   ├── 对每个候选子场景检查 applies_when 是否覆盖真实需求、实现对象和验收重点
│   ├── 多个 applies_when 同时成立时全部保留，不能因为已命中一个子场景就排除其他子场景
│   └── 如果只有 intent_signals 命中但 applies_when 不成立，不作为 primary_sub_scene
│
├── Step 3: 用 not_applies_when 修正边界
│   ├── 若 not_applies_when 指向其他子场景，将该场景降级或移交到更合适的子场景
│   ├── 若一个能力只是辅助效果，归入 secondary_sub_scenes，并说明它和主诉求的依赖关系
│   └── 父场景已命中但子场景不明确时，选择场景索引中最通用的页面/组件子场景兜底
│
├── Step 4: 用 decisions 协助阶段决策
│   ├── REQ：读取 decisions.REQ 明确页面结构、交互对象、导航关系、临时 UI、动效、焦点和验收重点
│   ├── DEV：读取 decisions.DEV 确定组件结构、API 选型、事件链路、生命周期和代码骨架
│   ├── FIX：读取 decisions.FIX 定位异常所属能力、参数配置、事件分发、资源约束和回归检查点
│   └── VAL：读取 decisions.VAL 生成渲染、导航、交互、弹窗、动画、焦点、布局、图像、列表和文本验证项
│
└── Step 5: 读取命中资源
    ├── primary_sub_scene 取核心诉求最强且 applies_when 最完整的子场景
    ├── secondary_sub_scenes 记录依赖、联动和回归相关子场景
    ├── 按命中子场景的 resource_ref / resource_refs / resource_files 收集 next_scene_refs
    └── resource_ref 指向 ROUTE.md 时继续展开；resource_files 存在多个类型时按用户目标选择，必要时读取多个
```

## 场景索引

### ARKUI-02-01 手势/键盘等交互事件

```yaml
scene_name: 添加手势/键盘等交互事件，实现用户交互
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./arkui-interaction/ROUTE.md
intent_signals:
  - 手势 / 手势绑定 / 手势组合 / 手势冲突 / 双击 / 长按 / 拖拽 / 惯性滑动 / 捏合缩放 / 跟手缩放 / 蒙层穿透 / 触摸热区 / 嵌套滚动
  - onClick / onTouch / TapGesture / LongPressGesture / PanGesture / PinchGesture / RotationGesture / SwipeGesture / gesture / priorityGesture / parallelGesture / GestureGroup / GestureMode
  - responseRegion / hitTestBehavior / HitTestMode / onTouchIntercept / onChildTouchTest / onGestureCollectIntercept / monopolizeEvents / onGestureJudgeBegin / shouldBuiltInRecognizerParallelWith / onGestureRecognizerJudgeBegin / onTouchTestDone / nestedScroll
applies_when:
  - 需要为组件绑定手势，或控制父子组件同类型手势的识别优先级（默认子优先 / 父优先 / 父子并行）
  - 需要实现点击、双击、多次点击、长按、拖动、捏合、旋转、快速滑动等基础手势交互
  - 需要将多个单一手势组合为复合交互（顺序识别 / 并行识别 / 互斥识别）
  - 需要处理父子组件嵌套场景下的触摸分发与手势竞争（含触摸热区调整、触摸测试模式、默认响应顺序）
  - 需要在手势识别期间动态判定是否响应手势，或解决多点触控、内置手势与自定义手势的冲突
not_applies_when:
  - 仅涉及组件布局不涉及交互（属于ARKUI-02-03）
  - 交互引发的动画效果是核心需求（属于ARKUI-02-05）
decisions:
  REQ:
    - 确定父子组件同类型手势的期望识别结果（子优先 / 父优先 / 父子同时响应）
    - 确定基础手势类型与触发参数（TapGesture 点击次数、LongPressGesture duration/repeat、PanGesture fingers/direction/distance、PinchGesture distance、RotationGesture angle、SwipeGesture 滑动距离与方向）
    - 确定多手势的组合模式（Sequence 顺序 / Parallel 并行 / Exclusive 互斥）及衍生规则（如双击前置、单击延迟 ~300ms）
    - 确定父子嵌套下触摸事件的分发策略（默认透传 / 阻塞子节点 / 阻塞兄弟 / 透传父节点 / 扩展或缩小热区）
    - 确定是否需要在识别阶段动态拦截或放行手势（onGestureJudgeBegin / onTouchIntercept / onChildTouchTest / onGestureCollectIntercept），以及是否需要让组件独占多点触控（monopolizeEvents）
  DEV:
    - 选择手势绑定方式：gesture（默认子优先）/ priorityGesture（父优先）/ parallelGesture（父子并行），并用 GestureMask.Normal/IgnoreInternal 屏蔽子组件内置手势
    - 选择单一手势 API 并按业务配置参数：TapGesture / LongPressGesture / PanGesture / PinchGesture / RotationGesture / SwipeGesture
    - 使用 GestureGroup 按模式声明组合手势（Sequence / Parallel / Exclusive），保证声明顺序符合互斥/顺序规则，配合 onCancel 兜底重置
    - 配置 responseRegion({ x, y, width, height }) 调整触摸热区（支持负值扩展、超出布局区域）
    - 配置 hitTestBehavior（Default / None / Block / Transparent / BLOCK_HIERARCHY / BLOCK_DESCENDANTS）控制触摸分发，或用 onTouchIntercept 按坐标动态返回 HitTestMode
    - 配置父子手势冲突解决方案
    - 配置多点触控独占、手势动态判定与内置识别器并行控制
  FIX:
    - 检查父子组件同类型手势绑定方式与 GestureMask 配置是否匹配竞争需求
    - 检查单一手势参数（次数/时长/距离/手指数/角度）与回调时机是否符合预期
    - 检查组合手势 GestureGroup 模式与子手势声明顺序（含双击前置规则与 onCancel 兜底）
    - 检查多层嵌套下 responseRegion 范围、hitTestBehavior 模式与触摸转发链路
    - 检查手势冲突解决配置（多点触控独占、动态判定回调返回值、内置识别器并行控制）
  VAL:
    - 父子组件同类型手势的识别优先级验证（gesture 默认子优先 / priorityGesture / parallelGesture）
    - 各类单一手势触发条件与回调参数验证（含惯性滑动 velocityY/velocityX、跟手缩放偏移公式、旋转 90° 吸附）
    - 组合手势在 Sequence / Parallel / Exclusive 模式下的整体联动行为验证（含 onCancel 兜底）
    - 多层级嵌套下触摸分发与手势响应链路验证（responseRegion / hitTestBehavior / onChildTouchTest / onGestureCollectIntercept）
    - 自定义手势判定的拦截 / 放行与多点触控行为验证（monopolizeEvents / onGestureJudgeBegin / shouldBuiltInRecognizerParallelWith）
```

### ARKUI-02-02 多页面路由与导航

```yaml
scene_name: 多页面路由与导航
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./routing-navigation-scenario-development.md
intent_signals:
  - Navigation / NavDestination / NavRouter / 页面跳转 / 页面路由 / 页面栈
  - pushPath / popPath / 页面转场 / 深度链接 / 拦截 / setInterception
  - 动态路由 / queryNavDestinationInfo / NavDestinationSwitch / 无感监听 / 路由动画
applies_when:
  - 多页面跳转、返回与页面栈管理（Navigation/Router）
  - 页面间参数传递与结果回调
  - 路由拦截与重定向（权限校验/登录拦截/页面下线/AB测试）
  - NavDestination页面级配置（方向控制/沉浸式）与跨模块动态路由
  - 启动闪屏页、多端分栏适配（单栏/双栏/三分栏）
  - 页面生命周期管理（前后台刷新/返回拦截/单例刷新）与无感监听（埋点/页面信息查询）
  - 页面转场动画（与ARKUI-02-05联动）
not_applies_when:
  - 单页面应用不涉及页面跳转
decisions:
  REQ:
    - 确定导航方案：首选 Navigation（推荐）；Router 为历史遗留方案，仅限已有 Router 的旧项目延续使用，新项目不采用
    - 确定页面流：跳转流程、参数传递、返回值
    - 确定路由拦截/鉴权/重定向需求与多端分栏适配策略
    - 确定生命周期需求（刷新/返回确认）与转场需求（与ARKUI-02-05联动）
  DEV:
    - 基础：Navigation + NavDestination + router_map.json；参数传参与返回用pushPathByName第三参onPop + pop(result)
    - 拦截/重定向：setInterception用willShow（可读data，非interception），router_map.json的data声明规则，getConfigInRouteMap()读取
    - 页面级配置：preferredOrientation声明式方向控制（系统自动恢复）；跨模块用RouterModule+动态import
    - 分栏适配：分栏replacePathByName（避免栈爆炸）/单栏pushPathByName，onNavigationModeChange同步，onNewParam+hideBackButton
    - 生命周期选型：onShown（前后台刷新）/onBackPressed（返回拦截）/onNewParam（单例刷新）；无感监听用navDestinationSwitch/queryNavDestinationInfo
    - 转场：systemTransition/customTransition/customNavContentTransition（须finishTransition）/geometryTransition（animateTo内+关默认转场）
  FIX:
    - 检查路由配置/页面栈/参数传递
    - 拦截异常：误用interception读不到data/登录页标requireAuth致无限循环
    - 方向/分栏：Navigation未铺满致preferredOrientation失效/分栏误用push致栈爆炸
    - 生命周期：误用onWillShow（前后台不触发）/onBackPressed未返回true
    - 转场：geometryTransition未在animateTo内或未关默认转场/未调finishTransition致卡住
  VAL:
    - 跳转/返回/参数传递验证
    - 拦截验证（未登录跳登录页、登录后回跳不回退）
    - 方向/分栏验证（方向自动恢复、栈不增长、断点同步）
    - 生命周期/转场验证（刷新触发、返回拦截、动画不卡顿）
```

### ARKUI-02-03 组件构建基础页面

```yaml
scene_name: 利用组件构建基础页面
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - Column / Row / List / Grid / Scroll
  - Tabs / Stack / Flex / 布局 / 页面搭建
  - 组件使用 / WaterFlow / Swiper
applies_when:
  - 需要使用ArkUI内置组件构建页面布局
  - 需要实现列表、网格、瀑布流等常见UI模式
  - 需要使用Tabs、Navigation等容器组件组织页面结构
  - 需要实现滚动、刷新、懒加载等列表功能
not_applies_when:
  - 涉及自定义组件定义（属于ARKUI-01）
  - 核心需求是交互事件而非布局（属于ARKUI-02-01）
  - 核心需求是动画效果而非布局（属于ARKUI-02-05）
decisions:
  REQ:
    - 确定页面结构：单列/多列/网格/瀑布流/标签页
    - 确定滚动需求：纵向/横向/嵌套滚动
    - 确定数据量级：少量静态/中量动态/大量懒加载
  DEV:
    - 布局组件：Column/Row/Stack/Flex/RelativeContainer
    - 列表组件：List + ListItem + LazyForEach（大量数据）
    - 网格组件：Grid + GridItem / GridRow + GridCol
    - 瀑布流：WaterFlow + FlowItem
    - 滚动组件：Scroll/Scroller控制
    - 标签页：Tabs + TabContent
  FIX:
    - 检查布局嵌套：布局是否合理，是否存在不必要的嵌套
    - 检查列表性能：是否使用LazyForEach、是否设置合理缓存
    - 检查滚动冲突：嵌套滚动是否正确处理
  VAL:
    - 布局验证：页面布局是否符合设计稿
    - 滚动验证：滚动是否流畅、是否有卡顿
    - 数据加载验证：列表数据加载和刷新是否正确
```

### ARKUI-02-04 弹窗/菜单/临时 UI

```yaml
scene_name: 添加弹窗/菜单等临时交互/提示界面
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./dialog-menu-scenario-development.md
intent_signals:
  - AlertDialog / bindSheet / bindContentCover / bindPopup / bindMenu
  - bindContextMenu / Toast / PromptAction / CustomDialog / 弹窗
  - 菜单 / 下拉菜单 / 半模态 / 全模态
applies_when:
  - 需要弹出确认对话框、提示信息
  - 需要显示半模态/全模态面板
  - 需要绑定弹出菜单或上下文菜单
  - 需要显示Toast提示
not_applies_when:
  - 弹窗的核心需求是转场动画效果（属于ARKUI-02-05）
  - 临时UI不涉及弹窗/菜单（如通知栏）
decisions:
  REQ:
    - 确定弹窗类型：确认弹窗/半模态/全模态/菜单/Toast
    - 确定触发方式：点击/长按/手势/条件触发
    - 确定交互需求：确认/取消/选择/输入
  DEV:
    - 确认弹窗：AlertDialog / 自定义弹窗（CustomDialog）
    - 半模态：bindSheet 配置高度、拖拽条
    - 全模态：bindContentCover
    - 弹出菜单：bindMenu（下拉菜单）/ bindContextMenu（长按菜单）
    - 提示弹出：bindPopup / PromptAction.showToast
  FIX:
    - 检查弹窗绑定：bindSheet/bindContentCover是否正确绑定
    - 检查状态控制：弹窗显示/隐藏状态是否正确管理
    - 检查z-index层级：弹窗是否被其他组件遮挡
  VAL:
    - 弹窗显示验证：弹窗是否正确弹出和关闭
    - 交互验证：弹窗内交互是否正常
    - 遮罩验证：背景遮罩是否正确显示
```

### ARKUI-02-05 动画与页面转场

```yaml
scene_name: 接入系统能力，实现应用动画和页面转场动画效果
phase_tags: [REQ, DEV, FIX, VAL]
resource_files:
  - file: ./animation-transitions-scenario-development/property-animation-scenario-development.md
    type: 属性动画
  - file: ./animation-transitions-scenario-development/custom-property-animation-scenario-development.md
    type: 自定义属性动画
  - file: ./animation-transitions-scenario-development/transition-animation-scenario-development.md
    type: 转场动画
  - file: ./animation-transitions-scenario-development/modal-transition-animation-scenario-development.md
    type: 模态转场动画
  - file: ./animation-transitions-scenario-development/shared-element-animation-scenario-development.md
    type: 共享元素动画
  - file: ./animation-transitions-scenario-development/component-animation-scenario-development.md
    type: 组件动画
  - file: ./animation-transitions-scenario-development/frame-animation-scenario-development.md
    type: 帧动画
intent_signals:
  - animateTo / animation / TransitionEffect / "@AnimatableExtend"
  - geometryTransition / createAnimator / AnimatorResult / curves
  - springMotion / 动画 / 转场
applies_when:
  - 需要实现属性动画、转场动画、共享元素动画、模态转场、组件动画或帧动画
  - 涉及 @AnimatableExtend 自定义可动画属性
  - 涉及 createAnimator 逐帧控制
not_applies_when:
  - 不涉及动画效果
  - 仅涉及模态弹出逻辑不涉及转场动画（属于ARKUI-02-04）
decisions:
  REQ:
    - 确定动画类型：属性动画/自定义属性动画/转场动画/模态转场动画/共享元素动画/组件动画/帧动画
    - 确定动画目标属性和参数（时长/曲线/延迟/重复次数）
  DEV:
    - 属性动画：animateTo / .animation() / curves.springMotion()
    - 自定义属性动画：@AnimatableExtend + 自定义类型（plus/subtract/multiply/equals）
    - 转场动画：TransitionEffect（OPACITY/SLIDE/MOVE/ROTATE/SCALE）+ animateTo 触发
    - 模态转场：bindSheet / bindContentCover + TransitionEffect
    - 共享元素：geometryTransition / NodeController / customNavContentTransition
    - 组件动画：TransitionEffect + delay交错 / AttributeModifier / Grid.editMode
    - 帧动画：createAnimator + onFrame/onFinish/onRepeat 逐帧控制
  FIX:
    - 检查动画触发：回调内是否有状态变化、transition是否绑定到条件渲染组件
    - 检查性能：动画是否导致卡顿
  VAL:
    - 动画效果、流畅性和交互是否正常
```

### ARKUI-02-06 焦点事件与走焦控制

```yaml
scene_name: 焦点事件与走焦控制
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./arkui-focus/ROUTE.md
intent_signals:
  - 焦点 / 走焦 / 获焦 / 失焦 / 焦点框 / 默认焦点 / 循环走焦
  - 主动获焦 / onFocus / onBlur / focusable / defaultFocus / requestFocus / clearFocus
  - focusOnTouch / focusBox / stateStyles / outline / nextFocus / FocusController
applies_when:
  - 需要控制焦点激活态、配置组件获焦能力与焦点框样式，或监听获焦/失焦事件联动 UI 表现
  - 需要处理层级页面切换时的焦点抢占与跟随，或设置默认焦点与焦点组获焦优先级
  - 需要控制焦点移动行为，含按键/点击/被动走焦、走焦算法选择、自定义走焦顺序与主动跳焦/失焦
not_applies_when:
  - 仅涉及点击/触摸事件不涉及焦点（属于ARKUI-02-01）
  - 焦点变化引发的动画效果是核心需求（属于ARKUI-02-05）
decisions:
  REQ:
    - 确定组件获焦能力（focusable 三类组件默认差异）与获焦前提条件（enabled / visibility / focusOnTouch）
    - 确定焦点激活态进入方式（focusOnTouch 点击/触摸主动获焦 vs FocusController.activate(true) API 18+）
    - 确定焦点框方案（focusBox 调整系统默认 vs stateStyles + outline 完全自定义）与显示时机
    - 确定获焦/失焦事件监听需求（onFocus / onBlur）与联动 UI 表现（如浮动标签动画、多输入框焦点追踪）
    - 确定走焦生效的层级页面范围（Page / Dialog / Menu / Popup / NavBar / NavDestination）与层级切换时的焦点抢占策略
    - 确定默认焦点节点（defaultFocus）与容器首次获焦时的子节点优先级
    - 确定走焦算法（Column / Row / Flex 线性走焦 vs RelativeContainer 投影走焦）
    - 确定自定义走焦顺序（nextFocus 六方向 / tabIndex / 循环走焦）与主动获焦/失焦时机（requestFocus / clearFocus）
  DEV:
    - 配置组件获焦能力：focusable（三类组件默认获焦差异）+ enabled / visibility / focusOnTouch 前提条件 + 容器绘制焦点框前提
    - 配置焦点激活态：focusOnTouch 点击/触摸主动获焦，或 FocusController.activate(true)（API 18+）
    - 配置焦点框样式：focusBox 调整系统默认焦点框，或 stateStyles + outline 完全自定义
    - 绑定 onFocus / onBlur 事件回调，联动 UI 表现（浮动标签动画、多输入框焦点追踪）
    - 配置层级页面焦点跟随：Page / Dialog / Menu / Popup / NavBar / NavDestination 切换时的焦点抢占与默认焦点
    - 配置 defaultFocus 层级页面首次展示生效，及焦点组 / 获焦优先级
    - 选择走焦算法：Column / Row / Flex 线性走焦 vs RelativeContainer 投影走焦
    - 配置 nextFocus（forward / backward / up / down / left / right）自定义走焦方向，或 tabIndex
    - 调用 FocusController.requestFocus / clearFocus 主动获焦/失焦，并配置获焦组件响应回车/空格触发点击
  FIX:
    - 检查焦点激活态与焦点框显示配置（focusable / enabled / visibility / focusOnTouch 是否失效、容器绘制焦点框前提）
    - 检查组件获焦能力（三类组件默认获焦能力差异、容器绘制焦点框前提条件）
    - 检查 onFocus / onBlur 回调是否触发及联动 UI 是否正常
    - 检查默认焦点与焦点组配置（defaultFocus 层级页面首次展示时机、焦点组与获焦优先级冲突）
    - 检查 requestFocus / clearFocus 调用（目标 id 是否存在、是否跨层级页面限制）
    - 检查层级页面切换时焦点跟随（Page / Dialog / Menu / Popup / NavBar / NavDestination 焦点抢占与丢失）
    - 检查按键走焦与走焦算法选型（方向键走焦卡住、投影走焦顺序异常）
    - 检查 nextFocus / tabIndex 配置（首尾互指、Snackbar 三件套对齐、循环走焦是否断开）
    - 检查被动走焦场景（组件删除 / 属性变更 / 层级页面切换导致的焦点丢失）
  VAL:
    - 焦点激活态进入/退出、焦点框显示与样式验证（focusBox 调整 vs stateStyles + outline 自定义）
    - 各类组件获焦能力与焦点唯一性验证（三类组件默认获焦能力 + enabled / visibility / focusOnTouch 前提）
    - onFocus / onBlur 事件回调与联动 UI 表现验证
    - 层级页面焦点跟随与默认焦点生效时机验证（Page / Dialog / Menu / Popup / NavBar / NavDestination）
    - 走焦算法行为验证（Column / Row / Flex 线性走焦 vs RelativeContainer 投影走焦）
    - nextFocus / tabIndex 自定义走焦顺序验证（Snackbar Tab 闭环 + List 循环走焦 + 方向键/Tab 键循环）
    - FocusController.requestFocus / clearFocus 主动获焦/失焦验证
    - 获焦组件响应回车/空格触发点击与按键事件冒泡验证
```

### ARKUI-02-07 综合应用页面骨架

```yaml
scene_name: 综合应用页面骨架
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./app-skeleton-scenario-development.md
intent_signals:
  - 垂类App骨架 / 多设备适配 / 断点响应 / WidthBreakpoint / HeightBreakpoint
  - BreakpointType / 地图导航 / Stack层叠 / 浮动面板 / 抽屉面板
  - 响应式布局 / NavigationMode / BarPosition
applies_when:
  - 需要构建资讯/社交/电商垂类App基础页面骨架（多设备适配、断点响应、分栏布局）
  - 需要构建地图导航类综合页面（层叠浮层、抽屉面板、手势交互）
  - 需要根据设备类型（手机/平板/折叠屏）动态调整页面结构
not_applies_when:
  - 单页面无导航的简单应用（属于ARKUI-02-03）
  - 仅涉及单一布局组件选型（属于ARKUI-02-10）
decisions:
  REQ:
    - 确定页面骨架类型：垂类App基础骨架 vs 地图导航综合页面
    - 确定设备适配策略：断点系统（WidthBreakpoint/HeightBreakpoint）+ BreakpointType 缩放
    - 确定导航模式：NavigationMode.Stack（手机）/ Split（平板）/ Auto（跨设备）
  DEV:
    - 垂类App骨架：Navigation + 断点 + Tabs（底部Tab↔侧边栏）+ Row/Column + 内容区响应式布局（GridRow/List/WaterFlow）
    - 地图导航页面：Stack 层叠 + 地图底层 + 浮动面板（Column/List/RelativeContainer）+ 控制按钮组 + 抽屉面板（手势拖拽+吸附）
    - 断点回调：onBreakpointChange 双向映射 + BreakpointType 字体/图标/边距/列数缩放
  FIX:
    - 检查断点回调是否覆盖宽高双向变化（折叠屏展开↔折叠）
    - 检查 Tabs barPosition/barWidth/barHeight 是否按断点切换
    - 检查抽屉面板手势拖拽与吸附逻辑
  VAL:
    - 多设备适配验证：手机底部Tab↔平板侧边栏切换
    - 地图浮层显隐与手势交互验证
    - 抽屉面板拖拽吸附验证
```

### ARKUI-02-08 自定义组件（FrameNode）

```yaml
scene_name: 自定义组件（FrameNode）
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./custom-component-scenario-development.md
intent_signals:
  - DrawModifier / AttributeModifier / GestureModifier / ContentModifier / FrameNode / RenderNode
  - BuilderNode / XComponent / drawBehind / drawFront / applyGesture / applyContent
  - typeNode.createNode / NodeController / NodeContainer / lockCanvas / 自定义绘制 / 多态样式
applies_when:
  - 需要自定义绘制（DrawModifier 渐变边框/外发光/霓虹灯/图案背景）
  - 需要封装多态按钮样式（AttributeModifier 四态：正常/按压/焦点/禁用）
  - 需要动态切换手势（GestureModifier 运行时切换手势类型）
  - 需要替换组件内容区（ContentModifier Button图标+文字/Checkbox收藏切换）
  - 需要 JSON 驱动动态表单（FrameNode + typeNode.createNode 运行时增删节点）
  - 需要手写签名实时绘制（RenderNode + drawing.Path 逐帧重绘）
  - 需要信息流穿插广告（BuilderNode + NodeController 占位先行内容后填）
  - 需要 XComponent Surface 自定义绘制（lockCanvas/unlockCanvasAndPost）
not_applies_when:
  - 仅使用系统组件的标准属性配置（属于ARKUI-02-03）
  - 不涉及 FrameNode/Modifier/XComponent 等高级自定义能力
decisions:
  REQ:
    - 确定自定义能力类型：DrawModifier（绘制）/ AttributeModifier（属性）/ GestureModifier（手势）/ ContentModifier（内容）/ FrameNode（动态节点）/ RenderNode（渲染）/ BuilderNode（混合构建）/ XComponent（Surface）
    - 确定自定义绘制层级：drawBehind（背景层）vs drawFront（前景层）
    - 确定动态节点管理策略：appendChild/removeChild（保留状态）vs rebuild（重建整树）
  DEV:
    - DrawModifier：drawBehind/drawFront + drawing.Brush/Pen + canvas.drawRect/drawCircle（vp2px转换）
    - AttributeModifier：applyNormalAttribute/applyPressedAttribute/applyFocusedAttribute/applyDisabledAttribute 四态
    - GestureModifier：applyGesture + PanGestureHandler/PinchGestureHandler/RotationGestureHandler 动态切换
    - ContentModifier：applyContent 返回 WrappedBuilder + ButtonConfiguration/CheckBoxConfiguration
    - FrameNode：typeNode.createNode(ctx, 'Column') 根容器 + appendChild/removeChild 动态增删
    - RenderNode：重写 draw + drawing.Path + invalidate() 逐帧重绘
    - BuilderNode：build(wrappedBuilder, params) + rebuild() 动态更新
    - XComponent：SURFACE 类型 + lockCanvas/unlockCanvasAndPost + drawing.Brush
  FIX:
    - 检查 DrawModifier 坐标单位（context.size 返回 vp，canvas 需 px，用 vp2px 转换）
    - 检查 ContentModifier 自定义属性是否触发刷新（需用 config.selected 驱动）
    - 检查 FrameNode 根容器是否用 typeNode.createNode（普通 new FrameNode 无布局策略）
    - 检查 RenderNode Path 坐标是否用 px（需 vp2px 转换）
    - 检查 XComponent 每次绘制前是否 clear 清除上一帧
  VAL:
    - 自定义绘制效果验证（渐变边框/外发光/霓虹灯）
    - 多态样式四态切换验证
    - 动态节点增删与状态保留验证
    - 手写签名笔迹与撤销/清除验证
    - 信息流广告占位先行内容后填验证
```

### ARKUI-02-09 弹窗菜单进阶案例

```yaml
scene_name: 弹窗菜单进阶案例
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./dialog-menu-scenario-development.md
intent_signals:
  - levelOrder / focusable / autoCancel / isModal / maskRect / openCustomDialog
  - ComponentContent / showDialog / showActionMenu / ActionSheet / DatePickerDialog / TimePickerDialog
  - TextPickerDialog / CalendarPickerDialog / transition弹窗动画 / 弹窗层级 / 蒙层控制
applies_when:
  - 需要弹窗层级管理（levelOrder 控制多弹窗覆盖顺序）
  - 需要蒙层控制（autoCancel/isModal/maskRect 显隐/交互/区域控制）
  - 需要动态更新弹窗内容（ComponentContent.update）
  - 需要不获取焦点的弹窗（focusable:false 搜索建议/联想词）
  - 需要弹窗过渡动画（transition TransitionEffect）
  - 需要选择器弹窗（DatePickerDialog/TimePickerDialog/TextPickerDialog/CalendarPickerDialog）
  - 需要异步确认对话框（showDialog Promise）或操作菜单（showActionMenu Promise）
not_applies_when:
  - 仅需基础弹窗确认/菜单且不涉及层级/蒙层/动态更新/焦点/动画等进阶能力（属于ARKUI-02-04）
  - 弹窗核心需求是转场动画效果（属于ARKUI-02-05）
decisions:
  REQ:
    - 确定弹窗类型：AlertDialog/ActionSheet/选择器弹窗/showDialog/showActionMenu/openCustomDialog/@CustomDialog
    - 确定进阶需求：层级管理/蒙层控制/动态更新/焦点控制/弹窗动画
    - 确定弹窗位置与交互方式
  DEV:
    - 层级管理：levelOrder: LevelOrder.clamp(n) 控制弹窗覆盖顺序
    - 蒙层控制：autoCancel（蒙层关闭）/ isModal（模态/非模态）/ maskRect（局部蒙层）
    - 动态更新：ComponentContent + openCustomDialog + content.update(newParams)
    - 焦点控制：focusable:false 弹窗不获取焦点不收键盘
    - 弹窗动画：transition: TransitionEffect.OPACITY/translate/scale + .animation({ duration })
    - 选择器：DatePickerDialog/TimePickerDialog/TextPickerDialog/CalendarPickerDialog
    - 异步确认：showDialog/showActionMenu + Promise 返回 result.index
  FIX:
    - 检查 levelOrder 值是否正确（高层级覆盖低层级）
    - 检查 autoCancel/isModal/maskRect 配置是否符合蒙层需求
    - 检查 ComponentContent.update 是否正确更新弹窗内容
    - 检查 focusable:false 是否保持软键盘不收起
    - 检查 transition 动画参数配置
    - 检查 ComponentContent.dispose() 是否释放资源
  VAL:
    - 弹窗层级覆盖验证
    - 蒙层显隐/交互/区域控制验证
    - 动态更新内容验证
    - 焦点保持验证
    - 弹窗动画效果验证
```

### ARKUI-02-10 布局组件搭建页面框架

```yaml
scene_name: 布局组件搭建页面框架
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - Column / Row / Stack / Flex / RelativeContainer / GridRow
  - GridCol / DynamicLayout / Tabs / alignRules / chainMode / 布局选型
  - 线性布局 / 层叠布局 / 弹性布局 / 相对布局 / 栅格布局
applies_when:
  - 需要选择布局组件（线性/层叠/弹性/相对/栅格/动态/选项卡）搭建页面框架
  - 需要对比布局方案选型
  - 需要实现响应式栅格布局（GridRow/GridCol 多设备列数适配）
  - 需要扁平化复杂二维布局（RelativeContainer 锚点定位）
  - 需要同数据源切换布局形式且保持状态（DynamicLayout）
not_applies_when:
  - 仅使用单一布局组件且不涉及布局选型对比（属于ARKUI-02-03）
  - 涉及综合应用页面骨架（属于ARKUI-02-07）
decisions:
  REQ:
    - 确定布局类型：线性（Column/Row）/ 层叠（Stack）/ 弹性（Flex）/ 相对（RelativeContainer）/ 栅格（GridRow/GridCol）/ 动态（DynamicLayout）/ 选项卡（Tabs）
    - 确定是否需要响应式布局（多设备列数适配）
    - 确定是否需要扁平化布局（减少嵌套层级）
  DEV:
    - 线性布局：Column/Row + space + layoutWeight + Blank + justifyContent/alignItems
    - 层叠布局：Stack + alignContent 九宫格对齐
    - 弹性布局：Flex + direction/wrap + flexShrink(0) 防压缩
    - 相对布局：RelativeContainer + alignRules 锚点定位 + chainMode 链式布局
    - 栅格布局：GridRow({ columns }) + GridCol({ span }) 24栅格系统
    - 动态布局：DynamicLayout + ColumnLayoutAlgorithm/GridLayoutAlgorithm/CustomLayoutAlgorithm
    - 选项卡：Tabs + TabContent + TabsController + scrollable
  FIX:
    - 检查布局嵌套是否合理（是否存在不必要的嵌套）
    - 检查 Flex 标签是否设置 flexShrink(0) 防压缩
    - 检查 RelativeContainer 组件是否设 id + alignRules 锚点正确
    - 检查 GridRow/GridCol span 值是否符合目标列数
  VAL:
    - 布局效果验证（是否符合设计稿）
    - 响应式列数验证（多设备列数切换）
    - 布局切换状态保持验证（DynamicLayout）
```

### ARKUI-02-11 图形组件图像展示

```yaml
scene_name: 图形组件图像展示
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./media-image-scenario-development.md
intent_signals:
  - Image / ImageAnimator / objectFit / alt
  - ImageFrameInfo / AnimationStatus / FillMode / 图片展示
  - 帧动画 / 序列帧
applies_when:
  - 需要展示静态图片（本地资源/网络URL/PixelMap）
  - 需要图片加载失败占位图
  - 需要播放序列帧动画（直播礼物特效/动画表情/引导动画）
not_applies_when:
  - 需要在 Surface 上自定义绘制（属于ARKUI-02-08 XComponent）
  - 不涉及图片或帧动画展示
decisions:
  REQ:
    - 确定图形组件类型：Image（静态图片）vs ImageAnimator（序列帧动画）
    - 确定图片数据源：本地资源/网络URL/PixelMap
    - 确定填充方式：Contain/Cover/Fill/ScaleDown
  DEV:
    - Image：src + objectFit + alt（占位图）+ onError/onComplete
    - ImageAnimator：images（ImageFrameInfo[]）+ state + iterations + reverse + fillMode
    - 帧动画资源：$rawfile('xxx.png') 返回 Resource 类型
  FIX:
    - 检查 Image objectFit 是否符合填充需求
    - 检查 ImageAnimator images 是否支持动态更新（不支持，需条件渲染）
    - 检查序列帧资源引用是否使用 $rawfile()
  VAL:
    - 图片展示与占位图验证
    - 帧动画播放/暂停/停止控制验证
    - 帧动画循环与填充模式验证
```

### ARKUI-02-12 滚动组件列表展示

```yaml
scene_name: 滚动组件列表展示
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./component-page-building-scenario-development.md
intent_signals:
  - List / ListItemGroup / ArcList / ArcListItem / Grid
  - GridItem / WaterFlow / FlowItem / sticky / swipeAction
  - columnsTemplate / 分组吸顶 / 滑动删除 / 瀑布流
applies_when:
  - 需要实现单列列表（分组吸顶/滑动删除/拖拽排序）
  - 需要实现弧形列表（智能手表圆形屏幕适配）
  - 需要实现网格（九宫格/固定行列等高）
  - 需要实现瀑布流（等宽不等高错落排列）
not_applies_when:
  - 不涉及列表/网格/瀑布流等滚动组件（属于ARKUI-02-03）
  - 涉及综合应用页面骨架（属于ARKUI-02-07）
decisions:
  REQ:
    - 确定滚动组件类型：List（单列线性）/ ArcList（弧形）/ Grid（多列等高）/ WaterFlow（多列不等高）
    - 确定列表功能需求：分组吸顶/滑动删除/拖拽排序/懒加载
    - 确定网格列数与间距
  DEV:
    - List：ListItemGroup（分组）+ sticky（吸顶）+ swipeAction（滑动操作）+ divider
    - ArcList：ArcListItem + 圆形屏幕适配 + initialIndex
    - Grid：columnsTemplate（'1fr 1fr 1fr'）+ rowsGap/columnsGap
    - WaterFlow：columnsTemplate + FlowItem 自动放最短列
  FIX:
    - 检查 List sticky 是否正确吸顶
    - 检查 Grid columnsTemplate 是否符合目标列数
    - 检查 WaterFlow 是否正确放置最短列
  VAL:
    - 分组吸顶/滑动删除验证
    - 网格列数与间距验证
    - 瀑布流错落排列验证
```

### ARKUI-02-13 文本组件文字展示

```yaml
scene_name: 文本组件文字展示
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./text-component-scenario-development.md
intent_signals:
  - Text / TextInput / RichEditor / SymbolGlyph / MutableStyledString
  - Span / ImageSpan / setTypingStyle / replaceStyle / ImageSpanAlignment
  - 富文本 / 关键字高亮 / 图文混排 / 系统图标
applies_when:
  - 需要文本显示（自定义样式/超长省略/展开收起）
  - 需要文本输入（多种输入类型/对应键盘/表单验证）
  - 需要富文本编辑（加粗/斜体/颜色/图文混合编辑）
  - 需要系统图标（SymbolGlyph 系统级动效）
  - 需要属性字符串高亮（关键字多色高亮）
  - 需要图文混排（Text + Span + ImageSpan）
not_applies_when:
  - 不涉及文本组件（属于ARKUI-02-03）
decisions:
  REQ:
    - 确定文本组件类型：Text（只读展示）/ TextInput（单行输入）/ RichEditor（富文本编辑）/ SymbolGlyph（系统图标）/ MutableStyledString（属性字符串）/ Text+Span+ImageSpan（图文混排）
    - 确定文本样式需求：字体大小/粗细/行高/字间距/对齐/装饰线
    - 确定输入类型：Normal/Password/Email/Number/PhoneNumber
  DEV:
    - Text：fontSize/fontWeight/lineHeight/letterSpacing/maxLines/textOverflow/decoration
    - TextInput：type（InputType）+ placeholder + onChange + maxLength
    - RichEditor：RichEditorController + setTypingStyle（加粗/斜体/颜色/字号）
    - SymbolGlyph：fontColor + renderingStrategy + symbolEffect（BounceSymbolEffect）
    - MutableStyledString：replaceStyle + StyledStringKey.FONT + TextController.setStyledString
    - 图文混排：Text + Span（文本片段）+ ImageSpan（行内图片）+ verticalAlign
  FIX:
    - 检查 Text maxLines + textOverflow 是否正确省略
    - 检查 TextInput type 是否对应正确键盘
    - 检查 RichEditor setTypingStyle 是否正确应用样式
    - 检查 MutableStyledString replaceStyle 范围是否正确
    - 检查 ImageSpan verticalAlign 是否对齐
  VAL:
    - 文本样式与省略验证
    - 输入类型与键盘验证
    - 富文本编辑样式验证
    - 系统图标动效验证
    - 关键字高亮验证
    - 图文混排验证
```
