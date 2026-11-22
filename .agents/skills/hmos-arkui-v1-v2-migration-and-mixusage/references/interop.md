# V1/V2 混用时怎么连接

组件级迁移，或存在尚未迁移的 V1 依赖时，都要读这份说明。先确认工程的目标/兼容 API、SDK 和工具链版本。

## 总体决策顺序

1. **边界**：迁移范围由开发者指定，不悄悄扩大；联动代码明显超出范围时，先列出并征求是否扩大。如果开发者已授予权限，则使用建议选项。
2. **能整组迁就整组迁**：同一状态相连的组件整组迁成 V2，得到纯 V2 结果，不需要任何桥。Provide/Consume 整组在范围内时，保留原 alias 通道并迁为 Provider/Consumer；显式参数链是实际混用边界的备选方案，不是整组迁移的默认改写。
3. **出现真实边界后，按数据形态选连法**：
   - 简单值（string/number/boolean 等）：直接用 `@Param` 或普通属性传递；
   - 复杂对象、API 19 及以上：用兼容接口包装，让两侧看到同一个对象；
   - 复杂对象、API 19 之前：双 ViewModel 加桥接层组件——这是最重的桥；
   - Provide/Consume 不能一起迁移时：若能修改 consumer 及其完整组件创建链，就删除 `@Consume`，逐层显式传值和回调；V2 组件用 `@Param` 接收、`@Event` 回传。若仍需保留 V1 `@Consume`，或无法修改完整链路，则保留 V1 `@Provide` 桥接。
4. **贯穿原则**：一条连接只保留一份真实数据；每条桥按本文件末尾的清单登记，当最后一个 V1 组件也迁移后，拆除中间的桥接。

桥只对已经出现的边界建：不要为了预先满足目标形态而改写 V1 基线。

## 先区分 V2 观察与 V1/V2 桥接

这三个名称相近的接口用途不同，不能互换：

| 接口 | 作用 | `@Sendable` |
| --- | --- | --- |
| `UIUtils.makeObserved` | 将未观察对象包装成 V2 可观察代理，供 `@ComponentV2` 使用 | 支持；当前 SDK 明确包含 `@Sendable` class |
| `UIUtils.makeV1Observed` | 将受支持的普通对象包装成 V1 可观察对象，可供 `@ObjectLink` 使用 | 不支持 |
| `UIUtils.enableV2Compatibility` | 让已经属于 V1 状态的数据可由 V2 观察 | 入参必须先是 V1 可观察数据 |

### 已核实的观察/兼容调用契约

用于选择本地观察工具及实现复杂对象边界。导入：`import { UIUtils } from '@kit.ArkUI';`。以下为 UIUtils 静态方法声明节选，不是需要写入应用的定义：

```ts
static makeObserved<T extends object>(source: T): T;
static makeV1Observed<T extends object>(source: T): T;
static enableV2Compatibility<T extends object>(source: T): T;
```

| 方法 | 最低 API | 参数与返回值的必要判断 |
| --- | --- | --- |
| `makeObserved` | 12 | 接收未观察的普通 class、JSON.parse 对象、Sendable class；返回类型仍为 T，但读取/写入应通过返回的 V2 可观察包装结果。 |
| `makeV1Observed` | 19 | 接收受支持的普通对象；返回类型为 T。未支持的输入可能原样返回，不代表已经获得 V1 观察能力。 |
| `enableV2Compatibility` | 19 | 接收 V1 状态数据；返回类型为 T。非 V1 状态可能原样返回，不能只凭编译通过判断桥接成功。 |

来源：API 26 SDK `ets/api/@ohos.arkui.StateManagement.d.ts` 与 `ets/kits/@kit.ArkUI.d.ts`。版本是该声明的最低 API 标记，不表示已在所有历史 SDK/设备实测。普通 class、Sendable 及下文列出的混用对象限制可以直接按本 reference 使用；其他容器、特殊对象及版本冲突按 [official-doc-routing.md](official-doc-routing.md) 定向核对，不为已覆盖的调用重新查询。SDK 签名中的 `T extends object` 不是“所有对象都支持”的承诺。

如果迁移后的 V2 组件自己持有普通 class 或 `@Sendable` 对象，且对象没有 `@ObservedV2`/`@Trace`，这是 V2 本地观察问题，不是混用桥接问题。目标 SDK 支持时使用稳定的 `@Local field = UIUtils.makeObserved(source)`。如果范围外 V1 子组件只接收该对象的简单属性，例如 `progress: number`，直接传递代理的属性即可，不要为了这个标量调用 `makeV1Observed` 或 `enableV2Compatibility`。

## 按 API 版本选桥接方式

只有平台支持时才能使用 `UIUtils.makeV1Observed` 和 `UIUtils.enableV2Compatibility`；本 reference 已确认其为 API 19+ 能力。先对照工程目标及兼容 API；匹配时无需每次调用都重新查询。出现版本冲突、签名缺口或相关编译错误时，按 [official-doc-routing.md](official-doc-routing.md) 定向核对。

### API 19 及以上

两个接口用途不同：

- `UIUtils.makeV1Observed(object)`：把普通对象包装成 V1 可观察对象，能力接近 `@Observed`。只接受受支持的对象类型，且只观察第一层；返回值可用于初始化 V1 `@ObjectLink`。
- `UIUtils.enableV2Compatibility(v1State)`：让 V2 读取已经属于 V1 状态的数据。传入值必须是 V1 可观察数据。

两个方向的最小用例均使用 `import { UIUtils } from '@kit.ArkUI';`。兼容接口的版本门槛与对象限制按本节判断，不用为了已给出的导入和规则重复查询 SDK。

V1 → V2，V1 持有复杂状态，V2 子组件读取：

```ts
@Observed
class User {
  name: string;
  age: number;

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }
}

@Component                     // V1 数据所有者
struct V1Parent {
  @State user: User = new User('Li', 20);

  build() {
    Column() {
      // 在创建 V2 子组件的边界表达式上包装当前对象；
      // 整对象被替换后，新对象也要经过同样包装
      V2Child({ user: UIUtils.enableV2Compatibility(this.user) })
      Button('V1 侧改名').onClick(() => {
        this.user.name = 'Wang';   // V2 子组件的 Text 会刷新
      })
    }
  }
}

@ComponentV2                    // V2 侧只读消费；要回写就加 @Event
struct V2Child {
  @Require @Param user: User;

  build() {
    Text(this.user.name)
  }
}
```

V2 → V1，V2 持有普通对象，V1 子组件用 `@ObjectLink` 消费：

```ts
class User {                    // 普通类，没有 @Observed
  name: string;
  age: number;

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }
}

@ComponentV2                    // V2 数据所有者
struct V2Parent {
  // 先 makeV1Observed 成为 V1 可观察对象（只观察第一层），
  // 再 enableV2Compatibility 让 V2 侧观察同一份，不建立第二数据源
  @Local user: User =
    UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new User('Li', 20)));

  build() {
    Column() {
      // @ObjectLink 收到的必须是 V1 可观察对象
      V1Child({ user: this.user })
      Button('V2 侧加一岁').onClick(() => {
        this.user.age += 1;     // V1 子组件的 Text 会刷新
      })
    }
  }
}

@Component                      // V1 侧消费
struct V1Child {
  @ObjectLink user: User;

  build() {
    Text(`age: ${this.user.age}`)
  }
}
```

简单值（string/number/boolean 等）不经过这两个接口，按方向直接用 `@Param` 或普通属性传入。

按 API 19+ 规则，`makeV1Observed` 和 `enableV2Compatibility` 都不接受非对象、`undefined` 或 `null`，也不能用于 `@ObservedV2`、`makeObserved` 的结果或已经由 V2 观察的内置对象。`makeV1Observed` 还不支持 ArkTS `collections` 和 `@Sendable` 类；它可以包装受支持的普通类以及 Array/Map/Set/Date，但只处理第一层，嵌套对象必须各自具备 V1 观察能力。这里的限制不适用于 V2 的 `makeObserved`；后者正是当前 SDK 支持观察 `@Sendable` class 的接口。

桥接接口不会改变组件装饰器体系：`@ComponentV2` 内不能使用 V1 组件状态装饰器，`@Component` 内不能使用 V2 组件状态装饰器。

### API 19 之前

兼容接口不可用，复杂混合状态的限制更多。
- 简单值通常可以通过允许的参数形式传递，但不能把带装饰器的复杂对象混用。
- 建议开发者优先升级到 API 19 及以上。
- 如果一定要在 API 19 之前混用复杂对象，需要同时构建 V1 ViewModel（`@Observed` 类）和 V2 ViewModel（`@ObservedV2` 类），并在桥接层组件中做单向数据转换：其中一个 ViewModel 是唯一写入方，另一个只是它的投影；按本文件末尾的清单登记为桥接，随迁移推进删除。具体编译限制以对应版本文档为准。

## API 19+ 的传递方向

### V1 父组件/数据源 → V2 组件

- 简单不可变值：使用 V2 `@Param`；需要子到父修改时，再加 `@Event`。
- 复杂 V1 状态：在创建 V2 组件的边界表达式上调用 `UIUtils.enableV2Compatibility`。优先在边界包装，而不是只包装初始化器；整对象替换后仍要让当前对象经过兼容处理。
- 嵌套对象：每个需要观察的层级都必须已参与 V1 观察（`@Observed` 或受支持的 `makeV1Observed` 结果）。遇到非 V1 可观察分支时，兼容遍历会停止。
- Array/Map/Set/Date：遵循官方混用模式，避免两个代理系统同时观察同一对象。除了初始集合，还要验证后续插入项和替换值。
- `@Track` 数据：只有被 `@Track` 的属性才有预期的跨系统观察效果；不要假设未 `@Track` 属性会刷新 V2 UI。如果 V1 需要所有属性都能刷新，则需要给其他未加 `@Track` 的属性加上 `@Track`，或一个 `@Track` 都不要加。

### V2 父组件/数据源 → V1 组件

- 需要 `@Link` 的 V1 子组件不能由任意 V2 状态初始化。范围允许时一起迁移，否则使用下述薄 V1 桥接；不要在 V2 组件中声明 V1 状态装饰器。
- 需要 `@ObjectLink` 的 V1 子组件必须接收 V1 可观察对象。对于边界所有的普通受支持对象，文档模式是 `UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(value))`。如果类已有 `@Observed`，不要再次 `makeV1Observed`，直接在 V1 可观察实例上启用 V2 兼容。
- 不要把 `@ObservedV2`/`@Trace` 对象交给带 V1 装饰器的接收方；改用桥接数据类及相应数据对象，或迁移接收方。
- 嵌套数据的每个相关层级都要保持 V1 可观察，新插入的元素也一样。

### 简单值连接保留的 V1 `@Link`

V2 所有者向薄 V1 包装层传值和回调；包装层用 V1 `@Prop` 接收，作为旧组件 `@Link` 的合法初始化来源，字段上的 `@Watch` 回传变化。推荐 `LegacyChild({ value: this.value })`，不需要另外维护一个 `@State` 镜像，也不需要为了绑定改用 `$`。若业务确实需要镜像，必须说明初始化、下行更新、上行回传及防回环策略。

```ts
// LegacyChild 是保留的 @Component，具有 @Link value: number。
@Component
struct LinkBridge {
  @Prop @Watch('onValueChange') value: number = 0;
  @Require onChange: (next: number) => void;

  onValueChange(): void { this.onChange(this.value); }

  build() {
    LegacyChild({ value: this.value })
  }
}

@ComponentV2
struct Owner {
  @Local value: number = 0;

  build() {
    Column() {
      LinkBridge({
        value: this.value,
        onChange: (next: number) => {
          if (this.value !== next) { this.value = next; }
        }
      })
      Button('increment').onClick(() => { this.value++; })
    }
  }
}
```

这里 `@Prop` 是边界投影，V2 所有者仍是业务真值。必须验证父到子、子到父及首次显示；不能只检查存在桥接或 Watch。Watch 写在字段上、参数为回调名，与方法上的 V2 Monitor 不同。

## 一条连接只保留一个真实数据源

V1 和 V2 交互时，只保留一份真实数据。不要分别包装两份逻辑相同的状态，也不要用相互竞争的 `Monitor` 双向复制。所有者集合变成纯 V2 之前，兼容机制应让 V2 看到同一个 V1 可观察对象。

在稳定的所有者中持有真实状态和桥接生命周期，不在渲染或修改时反复创建独立的真实数据源。API19+ 在组件创建点对当前 V1 对象启用兼容，不复制业务对象；对象替换后仍包装当前对象。API19 前的只读 V2 投影可以随 V1 输入生成新快照，但 V1 仍是唯一写入方，投影不得自行写回或竞争所有权。不要为了得到包装对象而修改源数据。

## Provide/Consume 和 storage 不会自动互通

V1 `@Provide`/`@Consume` 与 V2 `@Provider`/`@Consumer`不会因 alias 相同而互通；alias 通道不能一半 V1 一半 V2。同一 alias 连接的组件按以下优先级处理：

1. 首选整组迁移 `@Provide` 和全部相连的 `@Consume`。
2. 如果能修改 consumer 及从数据所有者到 consumer 的完整组件创建链，删除相应 `@Consume`，把状态和修改回调逐层传递；V2 组件用 `@Param` 接收状态、用 `@Event` 回传修改。consumer 可以保持 V1：此时使用 V1 合法输入（例如简单值 `@Prop`）和普通回调字段，不能在 `@Component` 中添加 `@Param`/`@Event`。这是用显式数据流替换原 alias 通道，不是让 V1/V2 两套通道互通。
3. 如果仍需保留 V1 `@Consume`，或无法修改完整创建链，抽一个薄 V1 包装层持有 `@Provide`，继续服务 V1 consumer；包装层与 V2 组件之间再用参数和回调传递同一份状态。若后续不再有 V1 `@Consume`，再删除包装层。

V1 AppStorage/LocalStorage 与 V2 AppStorageV2也不会因 key 文本相同而同步。按 [storage-and-application-state.md](storage-and-application-state.md) 记录数据源和 key 集合。

## 记录桥接，满足条件后再删除

为每条桥接记录：

- 谁拥有桥接、数据往哪个方向传；
- 跨边界的字段和类型；
- 需要的 API 版本；
- 仍在使用的 V1 消费方；
- 删除桥接的条件。

只有搜索结果、构建和测试都表明最后一个 V1 消费方已迁移，才能删除桥接。
