# 状态管理 — 路由入口

## 路由目标

进入 `ARKUI-03` 后，继续判断用户问题属于状态管理基础使用、V1/V2 混用，还是状态变量相关扩展能力，并读取对应资源文件。子场景不互斥；混用问题通常需要同时读取基础使用与混用文档。

输出建议：

```yaml
parent_scene: ARKUI-03
primary_sub_scene: 最核心子场景 ID
secondary_sub_scenes: [其他命中子场景 ID]
next_scene_refs:
  - 命中的叶子文档路径
```

## 路由决策树

```text
进入状态管理场景
│
├── Step 1: 建立候选子场景
│   ├── 不在决策树中维护子场景描述；所有具体描述以下方"场景索引"为准
│   ├── 从用户提示词、代码、报错中提取装饰器、数据流、状态来源、监听/计算需求和迁移信号
│   ├── 并行对照所有子场景的 intent_signals，形成 matched_sub_scenes 候选集
│   └── 明确装饰器、状态 API、混用/迁移表述等强信号优先；"状态管理"这类泛化词只作辅助
│
├── Step 2: 用 applies_when 确认状态边界
│   ├── 对每个候选子场景检查 applies_when 是否覆盖真实状态来源、数据流向和同步/监听边界
│   ├── 多个 applies_when 同时成立时全部保留，基础使用、混用和扩展能力可以同时命中
│   └── 未明确混用、迁移或跨版本桥接时，不得只凭 V1/V2 关键词选择混用方案
│
├── Step 3: 用 not_applies_when 修正误命中
│   ├── 若 not_applies_when 表明问题不属于状态管理，应回退到父级场景或其他一级场景
│   ├── 若混用只是排查背景而非核心诉求，将混用相关场景降为 secondary_sub_scenes
│   └── 父场景已命中但子场景不明确时，选择场景索引中基础状态使用场景兜底
│
├── Step 4: 用 decisions 协助阶段决策
│   ├── REQ：读取 decisions.REQ 明确状态版本、状态来源、数据流向、监听/计算、持久化和迁移范围
│   ├── DEV：读取 decisions.DEV 确定装饰器选型、组件间传值、跨层级共享、应用级状态或桥接方案
│   ├── FIX：读取 decisions.FIX 检查可观测性、父子/跨层级链路、监听清理、刷新时机和跨版本边界
│   └── VAL：读取 decisions.VAL 形成同步、监听、计算、持久化、混用桥接和迁移前后验证项
│
└── Step 5: 读取命中资源
    ├── primary_sub_scene 取状态问题核心且 applies_when 最完整的子场景
    ├── secondary_sub_scenes 记录基础依赖、混用链路、扩展能力或回归相关场景
    ├── 按命中子场景的 resource_ref / resource_refs 收集 next_scene_refs
    └── resource_refs 含多个文档时全部读取；混用或跨版本桥接场景必须同时读取基础使用文档
```

## 场景索引

### ARKUI-03-01 状态管理 V1&V2 使用

```yaml
scene_name: 状态管理V1&V2使用
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./state-management/state-management-v1v2-scenario-development.md
intent_signals:
  - "@State" / "@Prop" / "@Link" / "@Provide" / "@Consume"
  - "@Watch" / "@Local" / "@Param" / "@Event" / "@Monitor"
  - "@Computed" / "@ObservedV2" / "@Trace" / 状态管理 / V2状态管理
applies_when:
  - 需要在组件间传递和共享状态数据
  - 需要使用V1状态管理（@State/@Prop/@Link/@Provide/@Consume）
  - 需要使用V2状态管理（@Local/@Param/@Event/@Monitor/@Computed）
  - 需要监听状态变化并执行回调
not_applies_when:
  - 涉及V1和V2状态管理同时使用（属于ARKUI-03-02）
  - 不涉及状态管理（属于其他场景）
decisions:
  REQ:
    - 确定状态管理版本：V1（@State/@Prop/@Link）vs V2（@Local/@Param/@Event）
    - 确定数据流向：父子组件单向/双向绑定、跨层级传递
    - 确定监听需求：是否需要监听状态变化
  DEV:
    - V1方案：@State(组件内) + @Prop(父传子单向) + @Link(父子双向) + @Provide/@Consume(跨层级)
    - V2方案：@Local(组件内) + @Param(父传子) + @Event(子传父) + @Monitor(监听变化) + @Computed(计算属性)
    - 选择策略：新项目推荐V2，已有项目按需选择
  FIX:
    - 检查装饰器版本匹配：V1和V2装饰器不能混用在同一组件
    - 检查数据流向：@Prop单向/@Link双向是否使用正确
    - 检查@Watch/@Monitor回调：是否正确监听状态变化
  VAL:
    - 状态同步验证：父子组件状态是否正确同步
    - 监听回调验证：状态变化时回调是否正确触发
```

### ARKUI-03-02 状态管理混用与迁移

```yaml
scene_name: 状态管理混用
phase_tags: [REQ, DEV, FIX, VAL]
resource_refs:
  - ./state-management/state-management-v1v2-scenario-development.md
  - ./state-management/state-management-mixed-scenario-development.md
intent_signals:
  - 状态管理混用 / V1V2混用
  - 装饰器冲突
applies_when:
  - 项目中需要同时使用V1和V2状态管理
  - 遇到V1/V2状态管理混用导致的编译或运行时问题
not_applies_when:
  - 仅使用V1或仅使用V2状态管理（属于ARKUI-03-01）
  - 不涉及状态管理（属于其他场景）
decisions:
  REQ:
    - 确定混用范围：哪些组件使用V1，哪些使用V2
    - 确定兼容边界：V1/V2组件间数据传递方案
  DEV:
    - 隔离原则：同一组件树层级内不混用V1和V2装饰器
    - 桥接方案：通过@Provide/@Consume或AppStorage/AppStorageV2作为跨版本数据桥梁
  FIX:
    - 检查装饰器混用：同一组件是否混用V1/V2装饰器
    - 检查数据传递：V1组件和V2组件之间的数据传递是否正确
    - 检查观察机制：@ObservedV2 + @Trace是否正确使用
  VAL:
    - 混用验证：V1/V2组件间数据传递是否正确
```

### ARKUI-03-03 状态管理相关扩展能力

```yaml
scene_name: 状态管理相关扩展能力
phase_tags: [REQ, DEV, FIX, VAL]
resource_ref: ./state-management/state-management-relative-scenario-development.md
intent_signals:
  - UIUtils / makeObserved / canBeObserved / getTarget / addMonitor / clearMonitor
  - applySync / flushUpdates / flushUIUpdates / Environment / "$$" / "!!"
  - 属性动画 / 自定义组件冻结 / "@Builder刷新" / 循环渲染
applies_when:
  - 需要使用状态变量辅助接口判断、转换、监听或同步刷新状态
  - 需要接入系统环境变量或应用级环境状态
  - 需要使用双向绑定语法糖、非空断言或状态驱动动画
  - 需要处理自定义组件冻结、@Builder 刷新或循环渲染与状态更新问题
not_applies_when:
  - 只是基础 V1/V2 状态传递（属于ARKUI-03-01）
  - 涉及 V1/V2 混用、跨版本桥接（属于ARKUI-03-02）
decisions:
  REQ:
    - 确定扩展能力类型：UIUtils / Environment / 双向绑定语法糖 / 状态驱动动画 / 复用冻结 / Builder刷新 / 循环渲染
    - 确定是否需要强制同步刷新或跨层级监听状态变化
    - 确定状态更新是否影响组件复用、冻结、条件渲染或循环渲染
  DEV:
    - 使用 UIUtils makeObserved/canBeObserved/getTarget/addMonitor/clearMonitor/applySync/flushUpdates/flushUIUpdates 处理状态辅助能力
    - 使用 Environment 接入系统环境变量或全局环境状态
    - 使用 $$ / !! 等语法处理双向绑定和非空场景
    - 按状态驱动动画、冻结组件、@Builder刷新、循环渲染规则组织状态变更
  FIX:
    - 检查状态辅助接口调用对象是否可被观测、监听是否及时清理
    - 检查同步刷新接口是否被过度使用或导致刷新时机异常
    - 检查 Environment、$$、!! 与状态生命周期是否匹配
    - 检查属性动画、冻结组件、Builder 与循环渲染的刷新边界
  VAL:
    - 状态辅助接口监听、同步刷新和清理验证
    - 系统环境变量更新与 UI 刷新验证
    - 双向绑定语法糖、属性动画、冻结/复用和循环渲染验证
```
