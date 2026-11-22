---
name: hmos-arkui-develop-skill
description: REQUIRED before writing the first .ets file of a session. Fatal gotchas list + API quick-reference for HarmonyOS ArkTS/ArkUI development. Load this skill when writing or modifying .ets files, porting TypeScript to ArkTS, or building any ArkUI page, component, layout, navigation, dialog, state-driven UI, or animation. Covers ArkTS linter rules, forbidden syntax, null safety, struct/@Component constraints, V1/V2 state management, rendering control, API parameter correctness, and UI quality. Triggers — .ets, ArkTS, ArkUI, HarmonyOS, struct, @Component, TS-to-ArkTS migration, ArkUI build error, runtime crash.
---

# ArkTS/ArkUI 编码约束

为 agent 写 ArkTS/ArkUI 代码提供致命陷阱清单和准确的 API 参考入口。

## API 和约束查表优先

1. **写任何组件前，必须同时查两类文件**：
   - **API 签名**：在 `references/quick-apis/_index.md` 定位组件所在文件，用 Grep 取卡片（勿整读大文件）。签名必须照搬，不得凭记忆改写、增减参数或改变参数类型
   - **约束规则**：在 `references/quick-rules/_index.md` 按任务特征查对应规则文件，提前预防错误
2. **组件→规则文件交叉索引**（写某组件时，必查对应的规则文件）：

| 写这些组件/功能时 | 必查 API 文件 | 必查规则文件 |
|---|---|---|
| List / Grid / WaterFlow / Tabs / Scroll | 01-layout | 12-layout（子组件约束）+ 06-rendering（ForEach/LazyForEach/Repeat） |
| Navigation / NavDestination | 12-navigation | 08-navigation（路由栈、pushPath param） |
| @State/@Link/@Prop/@Local/@Param 等 | 08-state-decorators | 05-state（V1/V2 混用、@Builder 传参、@ObjectLink 限制） |
| Button / Text / Image / TextInput | 02-basic-components | 07-attribute-params（臆造 API 清单） |
| DatePicker / TimePicker / TextPicker | 04-selectors | 07-attribute-params（构造参数字段名高发错） |
| AlertDialog / ActionSheet / bindSheet | 11-dialog-menu | 09-dialog（堆叠规则） |
| animateTo / transition | 09-animation | 07-attribute-params（curve 必须枚举等） |
| 手势 / 拖拽 | 10-gesture | 11-extension（手势绑定、拖拽冲突） |
| import / router / promptAction | — | 01-import（kit 路径）+ 02-uicontext（全局接口替换） |

## 高频错误及约束

### ArkTS 语法

1. 不使用 any/unknown 类型、以及...解构赋值
2. 从回调 / Map.get / Array.find / 可选属性取值时做空安全处理（`??` 默认值或判空）
3. 函数与箭头函数参数必须显式标注类型；泛型函数调用必须显式指定类型参数——`arr.map(x => x.id)` ❌、`arr.map((x: Item): string => x.id)` ✅；`new Map()` ❌、`new Map<string, number>()` ✅；`arr.find(x => x.id === 1)` ❌、`arr.find((x: Item): boolean => x.id === 1)` ✅（依赖推断会报 `arkts-no-any-unknown` 或 `arkts-no-inferred-generic-params`）

### 命名与作用域

4. ArkTS 不支持声明合并（arkts-no-decl-merging），同一项目中不同文件的顶层 interface/class/struct 名不能重复，也不能与系统组件/全局类型重名——自定义名称一律加业务前缀
    - WRONG: 文件A声明 `interface Item`，文件B也声明 `interface Item`
    - RIGHT: 文件A用 `interface CartItem`，文件B用 `interface OrderItem`，按业务语义区分命名
5. 变量名/参数名/方法名避开框架保留字（如 `builder`/`create`/`value`），否则报 `arkts-unique-names` 或 `10505001`——见 `references/quick-rules/03-component.md` 保留字全表
6. **@State/@Prop/@Local 等成员名禁止与链式方法重名**——`value`/`width`/`height`/`margin`/`padding`/`offset`/`position`/`border`/`backgroundColor`/`opacity`/`visibility`/`scale`/`rotate`/`size`/`direction`/`enabled`/`zIndex`/`layoutWeight`/`alignItems`/`justifyContent`/`alignContent` 等通用属性名均为禁区 → **10505001**。用业务前缀消歧义：`currentValue` 而非 `value`

### build() 与组件结构

7. @Entry 根节点必须是单个容器组件（Column/Row/Stack 等）；@Component 根节点可为非容器，但必须是唯一节点，但 **`ForEach` 仍不可作为根节点**
8. build() 中不声明本地变量、不用 console、不直接改变状态变量
9. ForEach / LazyForEach / Repeat 必须显式提供 key（用业务 ID 不用索引）；省略时 ForEach 默认 `JSON.stringify`（bigint/循环引用会 jscrash），Repeat 生成随机值（每次更新全量重建）
10. `@Entry` 不能用 `@ObjectLink`，必须抽子组件
11. **Button('label') 与子组件互斥**——`Button('OK') { Text('x') }` ❌ → **10905202**；`Button('OK')` ✅ 或 `Button() { Text('x') }` ✅
12. **@Builder 返回 void，调用处不可链式**——`myBuilder().onClick(...)` ❌
13. **嵌套 ForEach 参数名必须不同**——外层 `row` 内层 `cell`，不用 `item`/`item`

### 状态管理

14. V1/V2 状态管理不混用——@Component 内只能用 @State/@Prop/@Link/@Provide/@Consume/@Watch/@ObjectLink/@Observed；@ComponentV2 内只能用 @Local/@Param/@Provider/@Consumer/@Monitor/@Computed/@ObservedV2/@Trace；AppStorageV2/PersistenceV2 只能在@ComponentV2 内使用；@Link/@ObjectLink 不本地初始化（值从父组件传入）
15. `@State` 只代理第一层；嵌套属性变化不刷新，需 `@Observed` 类 + 子组件 `@ObjectLink` 逐层代理
16. `@Builder` 按引用传递：形参用 `$$: InterfaceType` 接收，调用时传单参数对象字面量 `myBuilder({ key: this.val })`；多参数不刷新；@Builder 方法定义在 build() 之前；参数类型必须用显式声明的 interface/class，禁止内联对象字面量类型 → **10605040**
17. **@Param 只读**——`this.x = ...` 在 @ComponentV2 内报 `Cannot assign to 'x' because it is a read-only property`；@Local 只能内部初始化，调用处传值不生效
18. **@ObjectLink 禁止整体赋值**——`this.objLink = new Info()` ❌，只能改属性

### 布局与渲染

19. 部分容器组件内部只允许放对应的子组件，如`List与ListItem、Grid与GridItem`等
20. `ForEach`/`LazyForEach`/`Repeat` **不是真实组件**，返回的 `ForEachAttribute` 等不支持 `.layoutWeight()`/`.width()` 等通用布局属性
21. Repeat (V2)设置了virtualScroll懒加载情况下仅 `@ComponentV2` 内可用
22. **Repeat 的 cachedCount 放滚动容器上**——`Repeat(arr).cachedCount(3)` ❌ → **10505001**；`List() { Repeat(arr) }.cachedCount(3)` ✅
23. **LazyForEach 的 dataSource 不可重新赋值**，修改数据后必须通过 DataChangeListener 通知更新

### API 参数（编译必挂高频）

24. 传给组件构造/API 的对象字面量，字段名与 Options 类型逐字一致
25. 回调参数类型用编译器声明的联合类型，不自行收窄（如 `onChange(index: number)` → 实际签名是 `onChange(index: number | string)`）
26. **构造参数字段名不能凭记忆编造**——实测高发：`TimePicker({ useMilitaryTime: true })` ❌（useMilitaryTime 是 TimePickerDialog 的字段）；`Tabs(this.tabsController)` ❌（构造参数是 `{ controller: ... }`）；`MenuItem({ value: '复制', icon: $r(...) })` ❌（正确字段是 content + startIcon）；`Shape({ viewPort: {...} })` ❌（viewPort 是链式方法）；`PersistentStorage.persistProps([{ key: 'k', default: 'v' }])` ❌（正确字段是 defaultValue）

详细规则文件索引见 `references/quick-rules/_index.md`。
