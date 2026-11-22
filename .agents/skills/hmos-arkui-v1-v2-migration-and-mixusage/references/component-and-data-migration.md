# 组件与数据迁移

以下规则描述开始编辑前必须完成的语义决策，并给出迁移所需的最小调用契约。已覆盖的调用不重复查询；未覆盖的重载、对象类型、版本冲突及相关编译错误按 [official-doc-routing.md](official-doc-routing.md) 核对。装饰器语义以匹配版本迁移文档和行为验证为依据，不从 `.d.ts` 猜测。

## 组件契约矩阵

| V1 写法 | V2 方向 | V1/V2 差异分析 | 必要分析 |
| --- | --- | --- | --- |
| `@Component` | `@ComponentV2` | V1 与 V2 组件分别使用各自体系的状态装饰器；组件装饰器变化会同时改变字段的初始化、读写和同步契约，不能只替换组件名称。 | 将组件字段和所有创建位置视为一次契约变更共同迁移；适用时保留 `@Entry`。 |
| `@State` | `@Local` | 两者均本地可写。V1 `@State` 允许外部初始化，并能观察普通 class 对象第一层属性变化；V2 `@Local` 禁止外部初始化，对类对象仅观察整体赋值，属性变化需另行建立观察能力。 | 仅当字段完全属于组件本地且不会被外部初始化时使用。普通 class 的属性不会仅因字段改成 `@Local` 就可观察；按数据类是否可修改及数据对象的支持范围选择 `@ObservedV2`/`@Trace` 或 `UIUtils.makeObserved`。 |
| 创建点传入且需要随父级或复用输入刷新的字段 | `@Param` | V1 的外部输入是否持续同步取决于原装饰器和复用更新逻辑，`@State` 的外部初始化本身不建立持续同步。V2 `@Param` 明确表示父到子单向输入，字段在子组件内不可直接重新赋值；复杂对象传递引用，不做深拷贝。 | 保持父到子更新；保留合法默认值，无默认值时必须加 `@Require`。 |
| 仅由外部初始化一次、后续由组件本地维护的 `@State` | `@Param @Once` | V1 `@State` 接收外部初值后可本地修改；V2 `@Param @Once` 也允许本地修改，但不再接收父级对该字段的后续同步。`@Once` 不做深拷贝，复杂对象仍可能与父级共享引用。 | 只有确认后续父级变化不应覆盖本地值时才使用 `@Once`。 |
| 只读 `@Prop` | `@Param` | V1 `@Prop` 是父到子单向同步，复杂对象深拷贝、本地可写；此行“只读”仅指业务未在本地写入。V2 `@Param` 同样单向同步，但复杂对象采用引用拷贝（共享引用），字段在本地不可直接重新赋值。 | 保留必填/默认初始化和父到子更新。 |
| 本地可写 `@Prop` | `@Param` + `@Local` + `@Monitor` | V1 `@Prop` 的本地修改不回写父级，后续父更新覆盖本地值，复杂对象通过深拷贝隔离。V2 普通 `@Param` 不允许本地重新赋值，也不提供深拷贝隔离，需由 `@Local` 承接可写副本、`@Monitor` 承接后续输入更新。 | 保持子组件本地写入及后续父更新覆盖。只有明确要求忽略后续父更新时，才改为 `@Param @Once`。复杂对象还须保持原有深拷贝隔离。 |
| `@Link` | `@Param` + `@Event` | V1 `@Link` 自动双向同步，子组件可直接赋值并更新父级。V2 将输入和修改请求拆开：`@Param` 单向接收且不可本地重新赋值，`@Event` 回调由父级处理写入；不会自动把子级赋值转成父级更新。 | 值向下传递，显式修改回调向上传递；更新每个调用点。 |
| `@ObjectLink` | `@Param` | 两者接收共享对象引用，子组件不能整体重新赋值，但可修改对象属性并影响数据源。V1 `@ObjectLink` 依赖 `@Observed` 类；V2 `@Param` 不要求输入类必须可观察，但属性变化能否刷新 UI 取决于 `@ObservedV2`/`@Trace` 或 `UIUtils.makeObserved`。 | 先迁移底层可观察类/嵌套对象，并保留整对象替换和属性修改行为。 |
| `@Provide` / `@Consume` | `@Provider` / `@Consumer` | 两组均支持跨层级双向同步。V1 可按 alias 或属性名匹配；V2 指定 alias 后仅按该 key 匹配，默认绑定最近的同名 Provider，且禁止外部初始化 Provider。V2 Consumer 必须有本地默认值；V1 Consume 在 API 20 前禁止本地初始化，API 20+ 才支持设置默认值。 | 同时迁移连通 alias 集合；不能一起迁移时建立显式边界。V2 装饰器后必须带调用括号，见下文专节。 |
| `@Watch` | `@Monitor` | V1 `@Watch` 写在字段上，以回调方法名为参数，同步触发且不直接提供新旧值。V2 `@Monitor` 写在方法上，以状态路径为参数，异步处理同一事件内的变更，按初值与最终值比较，并可取得 `before`/`now`；支持监听多个路径。 | 重新评估回调时序、监听路径、新旧值以及同一事件内的多次变更。 |

这里的 `@Param`“本地不可写”指不能直接给字段重新赋值（例如 `this.info = other`），不代表对象深度只读。复杂对象按引用传递时，`this.info.name = 'new'` 可以修改共享对象并影响父级数据；UI 是否刷新仍取决于该属性的观察能力。需要保持 V1 `@Prop` 的单向隔离时，应显式创建业务类型适用的独立副本，不能仅依赖 `@Param` 或 `@Once`。

差异依据：[OpenHarmony 组件内状态变量迁移](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-component.md)、[@Prop](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-prop.md)、[@Param](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-param.md)、[@Provider / @Consumer](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-provider-and-consumer.md) 和 [@Monitor](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-monitor.md) 文档；涉及版本分界时按目标 API 核对。

### Param 的声明与调用必须同时成立

`@Param` 没有本地初始化器时，声明上必须同时有 `@Require`。这适用于简单值、复杂对象及 `@Param @Once`；父组件传值不能替代子组件的声明要求。

```ts
// 必填输入：每个创建点必须传值。
@Require @Param label: string;
// 可选输入：保留业务上合法的默认值。
@Param optionalLabel: string = '';
// 首次输入也必须满足初始化要求。
@Require @Param @Once initialLabel: string;
```

`@Param label: string;` 缺少初始化器和 `@Require`，不能使用。V1 `@Link`/`@ObjectLink` 没有本地默认值时，迁为 `@Require @Param`；不要为了通过编译虚构对象或无意义的默认值。迁移后逐项检查声明和全部创建点。

依据：[OpenHarmony @Param 文档](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-new-param.md)的初始化约束；目标 SDK 的编译诊断仍须核对。

### Provider / Consumer 迁移必须带调用括号

V1 `@Provide varName: string = 'hello'` 未指定 alias 时可直接使用；V2 `@Provider` 是装饰器工厂，API 声明为 `const Provider: (aliasName?: string) => PropertyDecorator`，无论有无 alias，装饰器后必须跟随调用括号：

```ts
// V1：@Provide message: string = 'hello';
// V2：无 alias 也必须带 ()，不能只把装饰器改名为 @Provider
@Provider() message: string = 'hello';
// V2：指定 alias
@Provider('text') parentMessage: string = 'Hello World';
```

只把 `@Provide` 逐字改名成 `@Provider`（不带括号）无法通过编译，`@Consumer` 同理。迁移时按调用形态改写，不以“名称相似”直接替换装饰器。

依据：[组件内状态变量迁移](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-component.md)——“不管有无指定 alias 后面需要必须跟随 `()`”；[@Provider API 参考](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-state-management-provider.md)的函数声明。

### Monitor 的取值方式

先按组件体系区分装饰器位置：V1 `@Watch('callbackName')` 写在被监听的状态字段上，参数是回调方法名；V2 `@Monitor('fieldPath')` 写在方法上，参数是状态路径。保留的 V1 桥接组件仍遵循 V1 规则，不能把 Watch 按 Monitor 的位置写到方法上。Watch 初始化时不触发，因此桥接的初始下行值也必须正确传入。

```ts
// V1 @Component 内：监听字段，调用方法。
@Prop @Watch('onValueChange') value: number = 0;
onValueChange(): void { this.onChange(this.value); }
// onChange 是该 V1 组件声明的普通回调字段。
```

`IMonitor` 是全局声明类型，不需要从 Kit 导入。已核实的 API 12+ 形式是 `monitor.value<T>(path?)` 方法，返回 `IMonitorValue<T> | undefined`；值对包含 `before`、`now` 和 `path`，没有 `after` 字段。只需要当前组件状态时可以直接读取 `this.count`，不必强行使用值对。

最小声明节选（无需在应用中重复定义）：

```ts
interface IMonitor {
  dirty: Array<string>;
  value<T>(path?: string): IMonitorValue<T> | undefined;
}
interface IMonitorValue<T> {
  before: T;
  now: T;
  path: string;
}
```

`path` 不存在时返回 undefined；省略 path 时取 dirty 中第一条变化路径。监听多条路径时应明确所需路径，不把省略参数理解为返回全部变化。

```ts
@Monitor('count')
onCountChange(monitor: IMonitor): void {
  const change = monitor.value<number>('count');
  if (change !== undefined) {
    this.observedCount = change.now;
  }
}
```

来源：API 26 SDK `ets/component/common.d.ts` 的 `IMonitor`/`IMonitorValue`（`@since 12`）。该示例说明调用形状；同一事件多次写入的回调时序仍按迁移文档与行为测试确认。

## 先从创建点识别输入

迁移字段前，搜索组件的全部创建位置。对于 `Child({ field: value })` 中的状态输入，V2 声明必须包含 `@Param`；无本地默认值时必须加 `@Require`，仅接收首次输入时再加 `@Once`，修改请求回调用 `@Event`。不要把事件字段也机械声明为 Param。`@Local` 只用于完全由组件内部初始化和维护的状态，不能接收创建点传值，否则会直接编译失败。

```ts
// 错误：label 在创建点传入，却声明为 @Local。
@ComponentV2
struct Child {
  @Local label: string = '';
}

// 正确：label 要持续接收父组件或复用路径的新值。
@ComponentV2
struct Child {
  @Require @Param label: string;
}

// 创建点
Child({ label: this.label })
```

需要持续随父组件更新时使用 `@Param`；只保留首次传入值时使用 `@Param @Once`；子组件还要修改父级数据时使用 `@Param` + `@Event`。不要因为 V1 字段写成 `@State`，就跳过创建点分析并机械替换为 `@Local`。

### Local / Param / Event 的最小双向契约

这些是核心状态语义，不是必须查 SDK 的函数签名。父组件持有可写状态，子组件接收输入并请求父级修改；普通 `@Param` 不做直接赋值。`@Param @Once` 是允许本地维护、但不持续接收父级更新的另一种契约，不能用于替代本例的同步要求。

```ts
@ComponentV2
struct TokenEditor {
  @Require @Param token: string;
  @Event onTokenChange: (next: string) => void = () => {};

  build() {
    Button(this.token).onClick(() => this.onTokenChange('new-token'))
  }
}

@ComponentV2
struct TokenOwner {
  @Local token: string = 'old-token';

  build() {
    TokenEditor({
      token: this.token,
      onTokenChange: (next: string) => { this.token = next; }
    })
  }
}
```

这是纯 V2 的最小示例，不要求把范围外 V1/AppStorage 所有者迁为 Local。实际所有者保持 V1 时仍使用其合法状态和普通回调承接修改；数据归属按 interop/storage reference 决定。

### 本地可写输入仍接受后续父更新

V1 `@Prop` 的子组件本地写入不会回写父组件，但后续父值变化仍覆盖本地值。保持这个契约时，普通 `@Param` 接收父输入，`@Local` 保存可写镜像；首次显示在 `aboutToAppear` 初始化，后续输入变化由 `@Monitor` 同步。仅在要求忽略后续父更新时使用 `@Once`。

```ts
@ComponentV2
struct DraftEditor {
  @Require @Param inputValue: number;
  @Local draftValue: number = 0;

  aboutToAppear(): void { this.draftValue = this.inputValue; }

  @Monitor('inputValue')
  onInputChanged(): void { this.draftValue = this.inputValue; }

  build() {
    Button(`draft: ${this.draftValue}`).onClick(() => { this.draftValue += 1; })
  }
}
```

此例只处理简单值。复杂对象若原先依赖 `@Prop` 的深拷贝隔离，应在初始化及父更新路径进行业务类型适用的复制，不能直接共享引用。验证首次显示、子本地写入、父值不被回写及后续父更新覆盖。

## 可观察数据类

- `@Observed` 加 `@Track` 通常迁移为 `@ObservedV2`，并在对应属性上使用 `@Trace`。
- 如果`@Observed`中的属性没有任何一个加`@Track` ，则是全部需要观察，则迁移为`@ObservedV2`时，需要给每个属性加上`@Trace`。

### 普通 class 与 `@Sendable`

先区分“字段替换”和“对象属性修改”：`@Local task` 能跟踪 `this.task = other`，但不会仅凭 `@Local` 让普通 class 的 `this.task.progress += 1` 获得 V2 观察能力。

- 数据类源码可迁移时，优先按语义使用 `@ObservedV2` 和 `@Trace`。
- 数据类不能添加 V2 装饰器时，按 [interop.md](interop.md) 的 makeObserved 调用契约、版本和已列对象支持范围，在稳定的初始化位置创建一次 V2 代理，例如 `@Local task: TaskRecord = UIUtils.makeObserved(new TaskRecord(1))`，后续通过该代理读写属性。仅未覆盖的对象类型、版本冲突或相关编译错误才查询。
- 当前 SDK 的 `makeObserved` 支持未加 `@Observed`/`@ObservedV2` 的普通 class、`JSON.parse` 对象和 `@Sendable` class；`makeV1Observed` 则是另一套 V1 观察工具，不支持 `@Sendable`。不要因名称相近而把两者互换。
- 如果 V2 组件只把 `number`、`string`、`boolean` 等简单值传给 V1 子组件，直接传递该属性即可；这不是复杂对象跨 V1/V2 边界，不需要 `makeV1Observed` 或 `enableV2Compatibility`。

```ts
import { UIUtils } from '@kit.ArkUI';

@Sendable
class TaskRecord {
  progress: number = 1;
}

@ComponentV2
struct TaskPage {
  @Local task: TaskRecord = UIUtils.makeObserved(new TaskRecord());

  build() {
    Button(`progress: ${this.task.progress}`).onClick(() => {
      this.task.progress += 1;
    })
  }
}
```

不要把原来的属性原地修改改写成整对象替换来掩盖观察能力缺失；对象身份属于原行为的一部分。

## 输出与清理

即使 V1 通过 `@Link` 隐藏了子组件写入，也要把每次写操作视为输出，优先用 `@Event` 表达。

## 特殊迁移

以下特殊场景先使用本 reference 或链接的主题 reference；未覆盖语义、版本冲突或具体签名缺口，再按 official-doc-routing 定向阅读对应官方资料：

- 自定义弹窗和基于控制器的 builder：先用下文已列的重载配对；
- 卡片/widget：先读 [card-migration.md](card-migration.md)，仅未覆盖能力或版本差异再核对官方专题文档；
- `animateTo` 行为，尤其是 API 22 分界；
- 滚动状态对象、modifier、`AttributeUpdater` 及其他内置对象；
- Environment 与持久化；
- 组件冻结和可复用生命周期方法。

### 独立场景的语义检查

内置对象的迁移依据：[OpenHarmony 内置对象的迁移](https://gitcode.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-v1-v2-migration-inner-object.md)。区分框架内置对象与普通 class，不把一种类型的观察限制推广到所有对象。

- **`@Reusable`：** 先按组件的每个创建位置判断实际复用路径。item 由未关闭复用的 `Repeat(...).virtualScroll()` 生成时，回收和复用由 Repeat 管理；子组件可以声明为 `@ReusableV2`，但该路径不会调用组件自己的 `aboutToReuse()`，不能把业务更新依赖在这个回调上。组件还存在 if/else 等非 Repeat 创建路径，并需要独立复用生命周期时，才依赖 `@ReusableV2`、无参 `aboutToReuse()` 和 `.reuse({ reuseId: () => 'groupA' })`。无论哪条路径，复用前自动重置的组件自有状态都不能替代外部输入；旧 `params` 或创建点传入的数据应按语义迁移为 `@Param` 或 `@Param @Once`，不能写成 `@Local`。
- **`animateTo`：** 检查回调中受影响的状态变量；如果在动画开始前修改了这些变量，API 22+ 将这些修改一起包进 `UIUtils.applySync`，API 12–21 使用全局 `animateToImmediately({ duration: 0 }, ...)`，然后再调用原动画。最小示例见 [animation-state-migration.md](animation-state-migration.md)。
- **滚动组件内置对象：** `ChildrenMainSize` 从 API 22 起可直接通过 `@Local` 使用，保留 `.childrenMainSize(this.childrenSize)` 绑定及 `this.childrenSize.childDefaultSize += ...` 等原地修改；更低 API 使用文档要求的 `UIUtils.makeObserved`。不要为了触发刷新把原地修改改成每次 `new ChildrenMainSize(...)`，也不要把该类型的支持分界推广到其他滚动内置对象。其他类型按对象专题核对；仅缺少实际调用所需签名时定向查询，同时验证可见 UI 结果。
- **自定义弹窗：** V1 `@CustomDialog`/`CustomDialogController` 迁移为 V2 `PromptAction.openCustomDialog` 与 `@Builder`。按下文已列重载配对打开和关闭；其他重载或版本差异才定向查询。并验证打开、内容和关闭路径。
- **Environment：** 不要把 `Environment.envProp` 与 `@StorageProp` 原样搬到 V2；按 Ability 迁移文档从 `UIAbilityContext.config` 读取，并定义配置变化的刷新路径。
- **Modifier/AttributeUpdater：** 按对象类型选择 `UIUtils.makeObserved` 或 `@ObservedV2`/`@Trace`。`.attributeModifier(...)` 绑定的内置修饰器及其自定义子类（如 `TextModifier`、`ButtonModifier` 的子类）自身不具备 V2 观察能力，不能以“内置 modifier 已具备属性刷新能力”为由省略包装：在稳定初始化位置用 `UIUtils.makeObserved` 包装一次（`UIUtils` 从 `@kit.ArkUI` 导入），由 `@Local` 持有包装后的同一实例，`.attributeModifier(...)` 读取该实例，并保留原对象上的属性/方法原地修改。不要在每次点击时重建 modifier 代替观察，验证原地修改确实刷新组件。


### 自定义弹窗的相关重载配对

通过 `this.getUIContext().getPromptAction()` 获取 PromptAction 实例；使用 ComponentContent 时从 `@kit.ArkUI` 导入 ComponentContent。来源：API 26 SDK `ets/api/@ohos.arkui.UIContext.d.ts`，下面四个重载均标记 API 12+，为实例方法声明节选：

```ts
openCustomDialog<T extends Object>(dialogContent: ComponentContent<T>,
  options?: promptAction.BaseDialogOptions): Promise<void>;
closeCustomDialog<T extends Object>(dialogContent: ComponentContent<T>): Promise<void>;
openCustomDialog(options: promptAction.CustomDialogOptions): Promise<number>;
closeCustomDialog(dialogId: number): void;
```

| 打开方式 | 返回值 | 关闭方式 |
| --- | --- | --- |
| 传 ComponentContent 实例 | Promise<void> | 保存并传入同一个内容实例；关闭也返回 Promise<void> |
| 传 CustomDialogOptions | Promise<number> | 保存返回 id，按 id 关闭；关闭返回 void |

不能把内容重载 `.then()` 的参数当 id。Promise 的拒绝需要业务处理。完整样式选项、控制器和其他构造重载未在此展开；实际需要时只查询相关声明，不连带扫描全部弹窗 API。

### ComponentContent 的最小构造与关闭示例

下面的构造重载从 API 12 起可用；`wrapBuilder` 是全局函数，无需 Kit 导入。

```ts
// ComponentContent<T extends Object> 的构造声明节选，不是应用内定义
constructor(uiContext: UIContext, builder: WrappedBuilder<[]>);
constructor(uiContext: UIContext, builder: WrappedBuilder<[T]>, args: T);
```

第一参数是 `this.getUIContext()` 获取的 UIContext，不是组件实例 `this`；第二参数是 `wrapBuilder(...)` 包装的 Builder，不是未包装的 Builder 方法。带参 Builder 的参数类型、args 和 ComponentContent 泛型必须一致；`T extends Object` 不能写成 `void`。无参 Builder 可以选择无参构造重载，但“不传参数”不等于 `ComponentContent<void>`。

下例使用模块级 `@Builder` 与显式参数/回调，避免误把组件方法的 this 当成 Builder 上下文。内容句柄不参与 UI 渲染，不必加 `@Local`；打开和关闭传同一个实例，成功关闭后再释放。示例只演示按钮关闭，因此关闭自动取消；真实迁移应保留原有取消、页面销毁和业务更新路径，并在这些路径正确清理句柄与资源，不机械照搬示例选项。

```ts
import { ComponentContent } from '@kit.ArkUI';

class DialogArgs {
  message: string;
  onClose: () => void;

  constructor(message: string, onClose: () => void) {
    this.message = message;
    this.onClose = onClose;
  }
}

@Builder
function dialogBody(args: DialogArgs) {
  Column() {
    Text(args.message)
    Button('Close').onClick(() => args.onClose())
  }
  .padding(16)
}

@Entry
@ComponentV2
struct ContentDialogPage {
  private content: ComponentContent<DialogArgs> | undefined = undefined;

  private async openDialog(): Promise<void> {
    if (this.content !== undefined) {
      return;
    }
    const context = this.getUIContext();
    const content = new ComponentContent(
      context, wrapBuilder(dialogBody),
      new DialogArgs('Dialog content', () => { this.closeDialog(); })
    );
    this.content = content;
    try {
      await context.getPromptAction().openCustomDialog(content, { autoCancel: false });
    } catch (error) {
      this.content = undefined;
      content.dispose();
      console.error(`Open dialog failed: ${error}`);
    }
  }

  private async closeDialog(): Promise<void> {
    const content = this.content;
    if (content === undefined) {
      return;
    }
    try {
      await this.getUIContext().getPromptAction().closeCustomDialog(content);
      this.content = undefined;
      content.dispose();
    } catch (error) {
      console.error(`Close dialog failed: ${error}`);
    }
  }

  build() {
    Button('Open').onClick(() => { this.openDialog(); })
  }
}
```

这个示例覆盖构造、包装、内容与关闭契约，不表示普通 DialogArgs 的属性自动可观察；需要持续更新弹窗数据时，按实际状态归属建立 V2 观察与更新路径。
