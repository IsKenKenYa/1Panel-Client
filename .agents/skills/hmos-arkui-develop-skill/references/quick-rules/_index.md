# ArkUI 编码规范统一索引

> **定位**：编码规范、错误预防、编译错误码三位一体。每个文件包含"规则（正面规范）→ 常见错误（错误对照）→ 参考（错误码/版本）"三层。
>
> **使用时机**：
> 1. **编码前**：扫 00-arkts-syntax（ArkTS 语法规则）和 01-import / 02-uicontext（最高频错误）
> 2. **编码中**：写属性参数对照 07-attribute-params；状态管理看 05-state；列表渲染看 06-rendering；视图架构看 08-navigation/12-layout；@Builder 看 05-state；@Observed 看 05-state
> 3. **多页面/多文件生成时**：必扫 03-component（跨文件接口重名——单类实测毁掉 11/44 失败用例）
> 4. **检视时**：逐条对照下方检视清单

## 文件索引

| 文件 | 主题 | 覆盖范围 |
|------|------|---------|
| [00-arkts-syntax](00-arkts-syntax.md) | ArkTS 语法规则 | 83 条 `arkts-*` 规则索引、TS→ArkTS 改写表、空安全、export/import、类型注解 |
| [01-import](01-import.md) | 模块导入 | import 规则、kit 速查表、全局内置、常见错误对照 |
| [02-uicontext](02-uicontext.md) | UIContext 全局接口 | 全局接口 → UIContext 替换表、常见错误 |
| [03-component](03-component.md) | 自定义组件与命名 | 组件基本约束、保留字全表、框架方法名冲突(10505001)、跨文件重名(arkts-no-decl-merging) |
| [04-build](04-build.md) | build() 函数约束 | 根节点约束、禁止项（变量/console/switch/三元）、sort/filter 陷阱 |
| [05-state](05-state.md) | 状态管理（V1+V2+混用） | @State/@Prop/@Link/@ObjectLink/@Observed/@Provide/@Consume/@Watch、@Builder、@Observed 不刷新排查、@Local/@Param/@Once/@Event/@Monitor/@Computed/@ObservedV2/@Trace、V1/V2 混用桥接 |
| [06-rendering](06-rendering.md) | 渲染控制 | ForEach/LazyForEach/Repeat、if/else、key 生成器、DataChangeListener |
| [07-attribute-params](07-attribute-params.md) | 属性与 API 参数 | 属性命名、枚举值、参数格式、构造器参数、回调参数类型、空安全、臆造 API 清单、不存在的 API |
| [08-navigation](08-navigation.md) | 导航与路由 | Navigation+NavDestination、多文件路由方案、pushPath param、转场约束 |
| [09-dialog](09-dialog.md) | 对话框与半模态 | AlertDialog/ActionSheet/bindSheet/bindContextMenu、堆叠规则 |
| [10-style](10-style.md) | 样式与主题 | @Extend/@Styles/stateStyles、模糊效果、clipShape、深色模式、@Extend 返回类型陷阱 |
| [11-extension](11-extension.md) | 扩展能力与交互 | DrawModifier/GestureModifier/AttributeUpdater/NodeContainer/FrameNode、手势绑定、拖拽冲突、事件规则 |
| [12-layout](12-layout.md) | 布局容器 | List/Grid/Tabs/WaterFlow 直接子组件约束、容器用法 |
| [13-performance](13-performance.md) | 性能与可见性 | 状态变更、@Reusable/@Track、freeze、长列表策略、onVisibleAreaChange、渲染状态≠可见性 |
| [14-deprecated](14-deprecated.md) | 废弃接口替换 | CustomDialogController/pageTransition/@ohos.*/static {} 替换 |

## 编码检视清单

### import 和模块
- [ ] 所有 import 使用 `@kit.*` 路径（见 01-import）
- [ ] import 的符号名和所属 kit 正确（见 01-import Kit导入速查表）
- [ ] 不存在 import 了但未使用的模块
- [ ] 不存在遗漏的 import

### UIContext 和全局接口
- [ ] router、promptAction、AlertDialog、animateTo、vp2px 等全局接口均通过 `this.getUIContext()` 调用（见 02-uicontext）

### 状态管理
- [ ] 所有状态变量声明了类型（见 00-arkts-syntax Types 节）
- [ ] 每个装饰器用在正确的位置（见 05-state）
- [ ] 避免 V1 与 V2 混用（见 05-state 混用节）
- [ ] @Link / @ObjectLink 不存在本地初始化（见 05-state）
- [ ] @Builder 按引用传递用单参数对象字面量；@Builder 内不修改入参（见 05-state）

### 渲染控制
- [ ] ForEach / LazyForEach 有第三个参数作为 key，且用业务 ID 不用索引（见 06-rendering）
- [ ] dataSource 不重新赋值，通过 DataChangeListener 更新（见 06-rendering）

### build() 函数
- [ ] build() 中不存在本地变量声明、console.info、switch、三元表达式（见 04-build）
- [ ] build() 中不直接改变状态变量（见 04-build）

### 命名和嵌套
- [ ] 变量名避开框架保留字（见 03-component 保留字全表）
- [ ] 组件和变量命名避开框架内置组件和属性名（见 03-component）
- [ ] 组件嵌套符合约束（List 内必须用 ListItem，Tabs 内必须用 TabContent）（见 12-layout）
- [ ] **多页面生成时，所有顶层 interface/class 名必须带用例 ID 或页面名前缀**（防 arkts-no-decl-merging，见 03-component）

### 属性参数
- [ ] 不捏造属性名/枚举值（见 07-attribute-params 臆造API清单）
- [ ] 回调参数类型用编译器声明的联合类型，不自行收窄（见 07-attribute-params）
- [ ] 从回调 result/Map.get/Array.find/可选属性取值时做了空安全处理（?? 默认值或判空）（见 07-attribute-params / 00-arkts-syntax）
- [ ] 传给组件构造/API 的对象字面量，字段名与 Options 类型逐字一致（见 07-attribute-params）

### 导航
- [ ] 路由跳转使用 Navigation 实现，不使用 Router（见 08-navigation）
- [ ] pushPath 的 param 先声明 interface 类型变量，不内联字面量（见 08-navigation）

### 废弃接口
- [ ] 不使用 CustomDialogController、pageTransition、@ohos.* 导入（见 14-deprecated）

### 代码风格
- [ ] 组件/变量命名遵循 PascalCase/camelCase
- [ ] 组件内部结构顺序：状态定义 → 属性 → 私有成员 → 生命周期 → 私有方法 → build()
- [ ] 链式调用每个方法一行；逻辑语句加分号，UI 语句不加分号