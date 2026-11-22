# Storage 和应用状态

即使只迁移一个组件，也可能改变 storage key 的数据所有权。因此不能只改组件声明，必须把同一 key 的所有读写找全。

## 先梳理状态 key 的读写关系

每个受影响的 key 记录：

| 命名空间/实例 | 解析后的 key | 声明/默认值 | 读取方 | 写入方 | Link/Prop 行为 | 持久化/Environment 关系 | 剩余 V1 用户 | 决定 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

在所有自有源码中搜索：

- `@StorageLink`、`@StorageProp`、`@LocalStorageLink`、`@LocalStorageProp`；
- `AppStorage.*`、`LocalStorage.*`、LocalStorage 实例方法、`PersistentStorage.*`、`Environment.*`；必要时忽略大小写；
- `setOrCreate`、`getOrCreate`、`set`、`get`、`has`、`delete`、`keys`、link/prop/ref API，以及创建和默认值路径；
- `@Entry` 的 storage 传参、`@Entry({ storage: ... })`、`@Entry({ useSharedStorage: true })`、`loadContent` 的 storage 参数，以及页面/组件树中的 LocalStorage 传递；
- key 使用的字符串、常量、枚举值和简单别名。

解析字符串、常量、枚举和简单别名。解析不了的表达式标记为动态 key，并追踪它的构造路径。同名 key 在 AppStorage、不同 LocalStorage 实例中都可能是不同状态；梳理时必须记录命名空间和实例。

## 决定迁移整个 key 集合，还是保留边界

### 完整切换

一起迁移该 key 的初始化、读写方、装饰器、命令式 API、持久化和清理逻辑。根据官方文档建立单一 V2 数据源，例如定义 `@ObservedV2`/`@Trace` 数据类并通过 AppStorageV2 连接共享数据对象，或由明确的所有者持有并向下传递。

迁移 `@StorageLink(key)` 时，也要迁移同 key 的 `AppStorage.SetOrCreate`、`setOrCreate`、`get` 等调用。只有搜索确认没有 V1 使用者，并且 V2 初始化位置已明确，才能删除旧的创建/初始化代码。

V1 和 V2 使用同一字符串 key，不代表两套状态会自动同步。

## 局部迁移必须保留持续更新

同一 AppStorage key 仍有 V1 使用者时，由 V1 组件通过 `@StorageLink` 继续管理该状态。V2 组件用 `@Param` 接收当前值，用 `@Event` 请求修改；V1 组件收到事件后更新 `@StorageLink`。不要在 V2 中为同一状态再创建一份独立存储。若已获授权，也可以迁移整个 key 的读写集合。

不能把 `@StorageLink` 替换为 `@Local token = AppStorage.get(...)`，再只在点击时调用 `AppStorage.set(...)`：这只读取初值，无法持续接收其他使用者的更新，不保留 Link 的双向同步语义。验证时既要测试 V2 写入，也要测试存储拥有者从外部修改后 V2 是否刷新。

完整迁移应用状态时，使用 `@ObservedV2` 类、`@Trace` 字段和 `AppStorageV2.connect`，所有需要共享的使用者使用同一个数据类和同一个连接标识，连接到同一份数据对象。连接标识的作用是让 AppStorageV2 找到并复用同一个 `MyStorage` 实例；真正被读写的业务字段是该实例上的属性（例如 `storage.token`），属性不会自动变成互相独立的连接。只有用户明确要求拆成独立状态时，才可让迁移后的 V2 存储与旧 V1 数据各自独立；这时必须更新共享行为的约定，不能称为原有共享语义不变。

Link 的本地写入应回写存储，存储更新也应刷新组件。Prop 的本地写入不应回写，后续存储更新应覆盖本地值；需要保持 Prop 行为时，使用本地副本及明确的输入更新路径，不要直接改成可写的共享字段。

## AppStorageV2、PersistenceV2 和 Environment

- `AppStorageV2`、`PersistenceV2` 从 `@kit.ArkUI` 导入。下面给出已核实的连接形状；出现其他重载、版本冲突或相关编译错误时再定向查询，不重复核实已有示例。
- `PersistentStorage` 到 `PersistenceV2` 涉及数据格式和生命周期，不只是改 API 名称。检查旧数据读取、默认值、版本升级、清理时机和异常回退。
- 迁移 `Environment` 时，按原场景要求区分进入时采集和持续响应配置变化；需要持续更新时，确认变化如何进入新的 V2 数据源。
- 对 `Environment.envProp` + `@StorageProp` 的 V1 组合，V2 应按应用迁移文档直接读取 `UIAbilityContext.config`（通常在 Ability 生命周期中采集并注入/共享），不要保留隐式的 Environment→AppStorage 链路。若页面需要响应配置变化，定义重新采集或显式更新路径，并验证首次值和后续刷新。
- 只有确认没有任何 V1 路径依赖旧 key，才能删除旧持久化或环境映射。

本节覆盖常见连接和连接集合管理；其他持久化专用接口、版本差异和错误处理细节按 [official-doc-routing.md](official-doc-routing.md) 定向核对，不为本节已有调用重复查询。

### Environment 的最小导入与读取示例

在 API 12+ 的 Stage UIAbility 页面中，`common` 从 `@kit.AbilityKit` 导入；通过 `this.getUIContext().getHostContext()` 获取宿主上下文，再使用 `common.UIAbilityContext.config.language` 读取语言。宿主上下文可能为 undefined，language 也可能未提供，不能用非空断言或写死 'en' 冒充当前环境。下面的空字符串仅表示未取得语言，不是默认环境值。

```ts
import { common } from '@kit.AbilityKit';

@Entry
@ComponentV2
struct EnvironmentPage {
  @Local languageCode: string = '';

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      console.error('UIAbilityContext is unavailable');
      return;
    }
    this.languageCode = context.config.language ?? '';
  }

  build() {
    Text(`language: ${this.languageCode}`)
  }
}
```

本例只适用于已确认宿主为 UIAbility 的页面；类型断言不会把卡片或 ExtensionAbility 的上下文变成 UIAbilityContext。这些宿主应按其实际上下文或已有注入路径获取配置。`UIContext` 用于 ArkUI 操作，`UIAbilityContext` 用于 Ability 配置，不能混用。

示例只演示进入时读取，不会自动订阅后续配置变化。如果原场景要求持续更新，应在获准范围内通过 Ability 配置回调更新共享数据，或在所需时机重新采集；不凭空新增 refresh 按钮，不擅自扩大到范围外的 EntryAbility。多组件共享时保持一个采集/状态所有者。

以上导入、上下文获取及 language 读取已覆盖；除非出现版本冲突、相关编译错误或未覆盖的配置字段/宿主，不重复检索 AbilityKit 的 common 导出或这些已有成员。

### 已核实的连接形状

来源：API 26 SDK `ets/api/@ohos.arkui.StateManagement.d.ts` 与 `ets/kits/@kit.ArkUI.d.ts`。`AppStorageV2.connect` 的该重载从 API 12 起可用，参数依次是类型、连接标识、默认创建器，返回 `T | undefined`；`PersistenceV2` 继承该连接形式。业务应处理连接失败，不能仅因类型含 `undefined` 就无条件加非空断言。

AppStorageV2 静态方法声明节选（均标记 API 12+）：

```ts
static connect<T extends object>(type: TypeConstructorWithArgs<T>,
  keyOrDefaultCreator?: string | StorageDefaultCreator<T>,
  defaultCreator?: StorageDefaultCreator<T>): T | undefined;
static remove<T>(keyOrType: string | TypeConstructorWithArgs<T>): void;
static keys(): Array<string>;
```

TypeConstructorWithArgs 表示数据类构造器，StorageDefaultCreator 表示返回 T 的无参创建器；这些名称用于读懂声明，不要求应用额外导入辅助类型。以下两种调用均被覆盖：显式标识 `connect(Model, 'key', () => new Model())`；省略标识 `connect(Model, () => new Model())`，后者按类型名称连接。首次连接提供有效创建器，不依赖省略参数猜默认值。

remove 接收标识或数据类构造器；keys 返回连接标识集合，不是数据对象的字段集合。不能直接把 PersistentStorage 的清理行为套到 PersistenceV2：持久化删除、保存、错误回调及 globalConnect 等专用接口未在此展开，仅实际需要时核对其声明和生命周期。

```ts
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';

@ObservedV2
class SharedState {
  @Trace score: number = 0;
}

const state = AppStorageV2.connect(SharedState, 'sharedState', () => new SharedState());
// 需要持久化时，将上一行替换为 PersistenceV2.connect(...)，仍只保留一个所有者。
if (state !== undefined) {
  state.score += 1;
} else {
  // 在真实业务中明确记录/展示连接失败，或中止依赖该连接的流程。
  // 不静默 new 一份共享数据对象继续运行，否则会产生第二数据源。
}
```

连接标识不是数据对象中的属性名；各消费者必须使用同一标识与数据类连接，才能共享同一份状态。示例不意味着旧 PersistentStorage 格式会自动升级为新格式。

`@ObservedV2` 数据类通过 `@Trace` 观察实例属性的变化。对象属性修改与对象引用替换是两种不同的更新：组件自有字段需要响应对象引用替换时使用 `@Local`；外部传入且需要持续接收更新的字段使用 `@Param`。`@Local` 不是 `@Trace` 属性观察生效的前提。按实际更新路径验证属性修改和必要的引用替换是否刷新 UI。
