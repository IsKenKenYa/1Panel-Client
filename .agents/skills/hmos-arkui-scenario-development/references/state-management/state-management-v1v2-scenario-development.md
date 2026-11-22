# 状态管理 V1 & V2 使用场景

## 简介

当前状态管理分为V1、V2两个版本，@Component装饰的struct为V1自定义组件，可以使用状态管理V1版本装饰器的能力。@ComponentV2装饰的struct为V2自定义组件，可以使用状态管理V2版本装饰器的能力。

**注意**
- 根据当前上下文选择对应的版本，即要求或已经使用V1版本，则只能参考V1版本实现方式；要求或已经使用V2版本，则只能参考V2版本实现方式
- 若上下文未明确要使用状态变量版本，并且当前代码环境未使用状态变量，优先使用V2版本环境变量
- 严禁自我推断或决策混用V1和V2状态变量，除用户明确要求混用场景外，禁止在V1中使用V2状态变量，禁止在V2中使用V1状态变量

**状态管理V1与V2能力对比**

| V1能力             | V2能力                | 说明                                 |
| ----------------- | -------------------- | ------------------------------------- |
| \@Component        | \@ComponentV2       | \@Component为搭配V1状态变量使用的自定义组件装饰器。<br/>\@ComponentV2为搭配V2状态变量使用的自定义组件装饰器。 |
| \@State            | 无外部初始化：\@Local<br/>外部初始化一次：\@Param\@Once      | \@State和\@Local类似都是数据源的概念，区别是\@State可以外部传入初始化，而\@Local无法外部传入初始化。 |
| \@Prop             | \@Param            | \@Prop和\@Param类似都是自定义组件参数的概念。当输入参数为复杂类型时，\@Prop为深拷贝，\@Param为引用。 |
| \@Link             | \@Param\@Event     | \@Link是框架自己封装实现的双向同步，对于V2开发者可以通过\@Param\@Event自己实现双向同步。 |
| \@ObjectLink       | \@Param            | 直接兼容，\@ObjectLink需要被\@Observed装饰的class的实例初始化，\@Param没有此限制。 |
| \@Provide          | \@Provider         | 兼容。                                 |
| \@Consume          | \@Consumer         | 兼容。                                 |
| \@Observed         | \@ObservedV2       | 表明当前对象为可观察对象。但两者能力并不相同。<br/>\@Observed可观察第一层的属性，需要搭配\@ObjectLink使用才能生效。 <br/>\@ObservedV2本身无观察能力，仅代表当前class可被观察，如果要观察其属性，需要搭配\@Trace使用。 |
| \@Track            | \@Trace             | V1装饰器\@Track为精确观察，可以不依赖@Observed单独使用。不使用则无法做到类属性的精准观察。<br/>V2\@Trace装饰的属性可以被精确跟踪观察。 |
| \@Watch            | \@Monitor          | \@Watch用于监听V1状态变量的变化，具有监听状态变量本身和其第一层属性变化的能力。状态变量可观察到的变化会触发其\@Watch监听事件。<br/>\@Monitor用于监听V2状态变量的变化，搭配\@Trace使用，可有深层监听的能力。状态变量在一次事件中多次变化时，仅会以最终的结果判断是否触发\@Monitor监听事件。 |
| LocalStorage       | 全局\@ObservedV2\@Trace  | 兼容。                            |
| AppStorage         | AppStorageV2            | 兼容。                            |
| PersistentStorage  | PersistenceV2          | PersistentStorage持久化能力和AppStorage耦合，PersistenceV2持久化能力可独立使用。 |

## 场景目录

1. [父子组件状态同步](#父子组件状态同步)
   - 1.1 [V1状态变量实现父子组件间单向与双向同步](#V1状态变量实现父子组件间单向与双向同步)
   - 1.2 [V2状态变量实现父子组件间单向、回调双向同步与初始化同步](#V2状态变量实现父子组件间单向、回调双向同步与初始化同步)
2. [跨组件层级双向同步](#跨组件层级双向同步)
   - 2.1 [V1状态变量实现跨组件层级双向同步](#V1状态变量实现跨组件层级双向同步)
   - 2.2 [V2状态变量实现跨组件层级双向同步](#V2状态变量实现跨组件层级双向同步)
3. [嵌套类对象属性变化观测](#嵌套类对象属性变化观测)
   - 3.1 [V1状态变量实现嵌套对象监听与属性级更新](#V1状态变量实现嵌套对象监听与属性级更新)
   - 3.2 [V2状态变量实现嵌套对象监听与属性级更新](#V2状态变量实现嵌套对象监听与属性级更新)
4. [状态变量变化监听](#状态变量变化监听)
   - 4.1 [V1状态变量变化监听](#V1状态变量变化监听)
   - 4.2 [V2状态变量变化精准监听与变化前后值获取](#V2状态变量变化精准监听与变化前后值获取)
   - 4.3 [V2状态变量同步监听与通配符监听](#V2状态变量同步监听与通配符监听)
   - 4.4 [V2状态变量动态监听与取消监听](#V2状态变量动态监听与取消监听)
5. [计算属性](计算属性)
   - 5.1 [V2状态变量实现依赖驱动的自动计算](#V2状态变量实现依赖驱动的自动计算)
6. [应用UI状态存储与共享](应用UI状态存储与共享)
   - 6.1 [V1状态变量实现页面级与应用级全局共享](#V1状态变量实现页面级与应用级全局共享)
   - 6.2 [V2状态变量实现应用级class全局共享](#V2状态变量实现应用级class全局共享)
7. [持久化存储UI状态](#持久化存储UI状态)
   - 7.1 [V1状态变量实现UI状态持久化](#V1状态变量实现UI状态持久化)
   - 7.2 [V2状态变量实现UI状态持久化](#V2状态变量实现UI状态持久化)

---

## 父子组件状态同步

V1版本状态变量和V2版本状态变量均可实现父子组件状态同步

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 组件状态 | `@State` | `@Local` |
| 父到子单向 | `@Prop`（可本地修改但不同步回去） | `@Param`（禁止直接修改，编译期报错） |
| 父子双向 | `@Link`（直接双向绑定） | `@Param` + `@Event`（回调模式） |
| 仅初始化同步一次 | V1 无对应能力 | `@Param` + `@Once`（快照初始值，后续不同步） |
| 子组件能否直接修改数据 | `@Prop` 允许 / `@Link` 允许 | `@Param` 均不允许，必须通过 `@Event`；`@Param @Once` 允许本地修改 |

---

### V1状态变量实现父子组件间单向与双向同步

**场景ID：** STATE_SCENE_V1_01

**场景描述：** 仿电商商品详情页，父组件管理商品信息（名称、单价、购买数量、折扣标签），包含两个子组件：商品展示卡片（只读展示名称和折扣）和数量选择器（可修改购买数量）。父组件可随时修改商品名称和折扣，展示卡片跟随更新；数量选择器修改数量后同步回父组件计算总价。

**解决方案：** 使用 **`@State` 管理父组件状态** + **`@Prop` 单向同步只读数据** + **`@Link` 双向同步可修改数据**

```
父组件 @State
  ├── productName, discount ──(@Prop 单向)──→ ProductInfoCard（只读展示）
  │     父组件改名/换折扣 → 自动同步到展示卡片
  │
  └── count ──(@Link 双向)──←→ CounterSelector（可修改数量）
        子组件 +/- → 同步回父组件 → 总价更新
        父组件重置数量 → 同步到子组件
```

#### 1.定义父组件，使用 @State 管理商品数据

```typescript
@Entry
@Component
struct ProductDetailPage {
  // @State 装饰：父组件内部状态，变化触发 UI 刷新
  @State productName: string = '智能手机'
  @State price: number = 2999
  @State count: number = 1
  @State discount: string = '限时8折'

  build() {
    Column({ space: 15 }) {
      // 父组件直接使用 @State 变量
      Text(`商品详情`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // @Prop 单向同步：只读展示，名称和折扣变化时自动更新
      ProductInfoCard({ name: this.productName, discount: this.discount })

      // @Link 双向同步：数量选择器可修改 count，同步回父组件
      Text(`单价: ¥${this.price}  数量: ${this.count}  总价: ¥${this.price * this.count}`)
        .fontSize(18)
      CounterSelector({ count: this.count })

      // 父组件修改 @State，单向同步到 ProductInfoCard，双向同步到 CounterSelector
      Row({ space: 10 }) {
        Button('改名').onClick(() => { this.productName = '旗舰手机' })
        Button('换折扣').onClick(() => { this.discount = '满2000减100' })
        Button('重置数量').onClick(() => { this.count = 1 })
      }
    }
    .padding(20)
  }
}
```

关键点：`@State` 装饰的变量是父组件的数据源，变化时触发自身 UI 刷新，同时同步到所有子组件。

#### 2.商品信息展示组件（只读）- @Prop 单向同步实现

```typescript
@Component
struct ProductInfoCard {
  // @Prop 接收父组件传入的值，父组件变化时自动同步到此处
  // 子组件本地不允许反向修改父组件数据
  @Prop name: string = ''
  @Prop discount: string = ''

  build() {
    Column() {
      Text(`商品名称: ${this.name}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`${this.discount}`)
        .fontColor(Color.Red)
        .fontSize(16)
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

关键点：`@Prop` 建立父到子的单向同步。父组件修改 `productName` 或 `discount` 时自动同步到 `ProductInfoCard`，但 `ProductInfoCard` 不能反向修改父组件数据。适合只读展示场景。

#### 3.商品数量选择组件 - @Link 双向同步实现

```typescript
@Component
struct CounterSelector {
  // @Link 建立双向同步，子组件修改会同步回父组件
  // @Link 禁止本地初始化，必须由父组件传入
  @Link count: number

  build() {
    Row({ space: 15 }) {
      Button('-')
        .onClick(() => {
          if (this.count > 1) this.count--
        })
      Text(`${this.count}`)
        .fontSize(24)
        .width(40)
        .textAlign(TextAlign.Center)
      Button('+')
        .onClick(() => {
          this.count++
        })
    }
  }
}
```

关键点：`@Link` 建立双向同步。子组件点击 +/- 修改 `count`，变化同步回父组件，父组件的总价计算自动更新。同时父组件点击"重置数量"修改 `count`，也会同步到子组件。

### V2状态变量实现父子组件间单向、回调双向同步与初始化同步

**场景ID：** STATE_SCENE_V2_01

**场景描述：** 电商商品详情页场景，父组件管理商品信息，商品展示卡片只读展示，数量选择器可修改购买数量。

**解决方案：** 使用 **`@Local` 管理父组件状态** + **`@Param` 单向同步只读数据** + **`@Param` + `@Event` 回调实现双向同步** + **`@Once` 仅初始化同步一次**

```
父组件 @Local
  ├── productName, discount ──(@Param 单向)──→ V2ProductInfoCard（只读展示）
  │     父组件改名/换折扣 → 自动同步到展示卡片
  │
  ├── count ──(@Param 下发)──→ V2CounterSelector
  │     ↑                             │
  │     └──(@Event 回调)──────────────┘
  │     子组件 +/- → @Event 回调 → 父组件修改 count → @Param 同步回子组件
  │     父组件重置数量 → @Param 同步到子组件
  │
  └── categoryId ──(@Param @Once)──→ V2CategoryTag（初始化快照）
        父组件换类目 → 不同步，子组件保持初始值
```

#### 1.定义父组件，使用 @Local 管理商品数据

```typescript
@Entry
@ComponentV2
struct V2ProductDetailPage {
  // @Local 装饰：V2 中替代 @State，表示组件内部状态
  @Local productName: string = '智能手机'
  @Local price: number = 2999
  @Local count: number = 1
  @Local discount: string = '限时8折'
  @Local categoryId: number = 101  // 商品类目ID

  build() {
    Column({ space: 15 }) {
      Text(`商品详情`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // @Param 单向同步：只读展示
      V2ProductInfoCard({ name: this.productName, discount: this.discount })

      // @Param + @Event 双向同步：数量选择器
      Text(`单价: ¥${this.price}  数量: ${this.count}  总价: ¥${this.price * this.count}`)
        .fontSize(18)
      V2CounterSelector({
        count: this.count,
        onCountChange: (val: number) => { this.count = val }
      })

      // @Once 初始化一次：类目标签，后续 categoryId 变化不再同步
      V2CategoryTag({ categoryId: this.categoryId })

      // 父组件修改 @Local，同步到子组件
      Row({ space: 10 }) {
        Button('改名').onClick(() => { this.productName = '旗舰手机' })
        Button('换折扣').onClick(() => { this.discount = '满2000减100' })
        Button('重置数量').onClick(() => { this.count = 1 })
        Button('换类目').onClick(() => { this.categoryId = 999 })
      }
    }
    .padding(20)
  }
}
```

关键点：`@Local` 替代 V1 的 `@State`，表示组件内部状态，不允许从外部初始化。

#### 2.商品信息展示组件（只读）- @Param 单向同步实现

```ts
@ComponentV2
struct V2ProductInfoCard {
  // @Param 接收父组件传入的值，子组件中不允许直接修改（编译期报错）
  @Param name: string = ''
  @Param discount: string = ''

  build() {
    Column() {
      Text(`商品名称: ${this.name}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`${this.discount}`)
        .fontColor(Color.Red)
        .fontSize(16)
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

关键点：V2 的 `@Param` 比 V1 的 `@Prop` 更严格，子组件中不允许直接修改 `@Param` 变量（编译期报错）。父组件修改 `productName` 或 `discount` 时自动同步到子组件。

#### 3.商品数量选择组件（可修改）- @Param + @Event 双向同步实现

```ts
@ComponentV2
struct V2CounterSelector {
  // @Param 接收当前值（只读），不能直接修改
  @Param count: number = 0
  // @Event 声明回调，通过回调通知父组件修改数据源
  @Event onCountChange: (val: number) => void = (val: number) => {}

  build() {
    Row({ space: 15 }) {
      Button('-')
        .onClick(() => {
          if (this.count > 1) {
            // 不能直接 this.count--，必须通过 @Event 回调
            this.onCountChange(this.count - 1)
          }
        })
      Text(`${this.count}`)
        .fontSize(24)
        .width(40)
        .textAlign(TextAlign.Center)
      Button('+')
        .onClick(() => {
          this.onCountChange(this.count + 1)
        })
    }
  }
}
```

关键点：V2 中 `@Param` 不允许直接修改，必须通过 `@Event` 回调通知父组件修改数据源，再由数据源同步回子组件。相比 V1 的 `@Link` 直接双向绑定，V2 的数据流更加单向可追溯。

#### 4.类目标签（快照）- @Once 仅初始化同步一次

```ts
@ComponentV2
struct V2CategoryTag {
  // @Once 搭配 @Param 使用：仅初始化时同步一次，后续父组件变化不再同步
  // 解除 @Param 不允许本地修改的限制，可以在本地修改并触发 UI 刷新
  @Param @Once categoryId: number = 0

  build() {
    Row() {
      Text(`类目ID: ${this.categoryId}`)
        .fontSize(16)
        .padding(6)
        .backgroundColor('#e0e0e0')
        .borderRadius(4)
    }
  }
}
```

关键点：`@Once` 必须搭配 `@Param` 使用。初始化时从父组件接收 `categoryId = 101`，之后父组件点击"换类目"将 `categoryId` 改为 999，但 `V2CategoryTag` 不会同步更新，仍显示 101。`@Once` 适合需要"快照"初始值、不跟随数据源变化的场景。

## 跨组件层级双向同步

V1版本状态变量和V2版本状态变量均可实现跨组件层级双向同步

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 提供数据 | `@Provide` | `@Provider()` |
| 消费数据 | `@Consume` | `@Consumer()` |
| 后代本地初始化 | 禁止（API 20 前） | **必须**设默认值 |
| 支持类型 | 基本类型、class、数组 | 上述类型 + **Function** |
| 别名绑定 | `@Provide('a')` / `@Consume('a')` | `@Provider('a')` / `@Consumer('a')` |
| 重名处理 | `allowOverride` 参数 | 默认允许重名，自动匹配最近祖先 |
| 使用范围 | 仅 `@Component` | 仅 `@ComponentV2` |


### V1状态变量实现跨组件层级双向同步

**场景ID：** STATE_SCENE_V1_02

**场景描述：** 仿待办事项应用，根组件维护任务计数，中间有一层或多层无关组件，最底层的组件需要直接读写该计数，无需逐层传递参数。

**解决方案：** 使用 **`@Provide` + `@Consume` 跨层级双向同步**，摆脱参数传递机制的束缚，根组件中 `@Provide` 装饰的变量自动对所有后代组件可用，后代组件通过 `@Consume` 按变量名或别名绑定，建立双向同步。

#### 1.根组件提供数据

```ts
@Entry
@Component
struct ToDoPage {
  // @Provide 装饰的变量 count 由根组件提供给所有后代
  @Provide count: number = 0

  build() {
    Column() {
      Button(`根组件 count: ${this.count}, +1`)
        .onClick(() => this.count += 1)

      // 中间层组件，不需要传递 count
      ToDoDemo()
    }
  }
}
```

#### 2.中间层组件无需传递

```ts
@Component
struct ToDoDemo {
  build() {
    // 中间层无需做任何数据传递
    ToDoList()
  }
}

@Component
struct ToDoList {
  build() {
    Row({ space: 5 }) {
      ToDoItem()
      ToDoItem()
    }
  }
}
```

关键点：中间层组件 `ToDoDemo` 和 `ToDoList` 不需要声明任何参数来传递 `count`，数据自动穿透。

#### 3.底层组件消费数据

```ts
@Component
struct ToDoItem {
  // @Consume 通过相同的变量名绑定祖先组件的 @Provide
  @Consume count: number

  build() {
    Column() {
      Text(`count(${this.count})`)
      Button(`count(${this.count}), +1`)
        .onClick(() => this.count += 1)
    }
    .width('50%')
  }
}
```

关键点：`@Consume` 不允许从外部传入初始化，仅通过变量名或别名匹配祖先组件的 `@Provide`。后代组件修改 `@Consume` 变量会同步回祖先组件。

---

### V2状态变量实现跨组件层级双向同步

**场景ID：** STATE_SCENE_V2_02

**场景描述：** 待办事项应用场景，根组件维护状态，底层组件需要跨层级双向同步。

**解决方案：** 使用 **`@Provider` + `@Consumer` 跨层级双向同步**（V2 装饰器），V2中`@Provider`和`@Consumer`只能在`@ComponentV2`中使用，通过`aliasName`匹配建立双向同步。

#### 步骤 1：根组件提供数据

```ts
@Entry
@ComponentV2
struct V2ToDoPage {
  // 未定义 aliasName，使用属性名 'count' 作为 aliasName
  @Provider() count: number = 0

  build() {
    Column() {
      Button(`根组件 count: ${this.count}, +1`)
        .onClick(() => {
          this.count += 1
        })

      // 中间层组件，不需要传递 count
      V2MiddleComp()
    }
  }
}
```

#### 步骤 2：中间层组件

```ts
@ComponentV2
struct V2MiddleComp {
  build() {
    V2ToDoItem()
  }
}
```

#### 步骤 3：底层组件消费数据

```ts
@ComponentV2
struct V2ToDoItem {
  // @Consumer 通过相同的 aliasName 向上查找最近的 @Provider
  @Consumer() count: number = 0

  build() {
    Column() {
      Text(`count(${this.count})`)
      Button(`count(${this.count}), +1`)
        .onClick(() => {
          this.count += 1
        })
    }
  }
}
```

关键点：V2 的 `@Consumer` 必须本地初始化（设默认值），当找不到匹配的 `@Provider` 时使用本地默认值。V1 的 `@Consume` 在 API version 20 前禁止本地初始化。

---

## 嵌套类对象属性变化观测

V1版本状态变量和V2版本状态变量均可实现嵌套类对象属性变化观测

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 观测嵌套对象属性变化 | `@Observed` + `@ObjectLink`（需拆分子组件接收内层对象） | `@ObservedV2` + `@Trace`（直接在父组件中使用，无需拆分子组件） |
| 观测对象数组项属性变化 | `@Observed` + `@ObjectLink` + `ForEach`（每项需子组件） | `@ObservedV2` + `@Trace` + `ForEach`（直接在父组件中观测） |
| 属性级精准更新 | `@Track` 装饰 class 属性（未装饰的属性不能在 UI 中使用） | `@Trace` 自带属性级精准更新能力 |
| 多层嵌套观测 | 逐层拆分子组件，每层用 `@ObjectLink` 接收 | `@Trace` 支持任意深度，直接修改即刷新 |
| 外层类是否需要装饰 | 外层类也需要 `@Observed` | 外层类无需任何装饰器 |

---

### V1状态变量实现嵌套对象监听与属性级更新

**场景ID：** STATE_SCENE_V1_03

**场景描述：** 仿电商订单详情页，订单(Order)包含收货地址(Address)和商品列表(OrderItem[])。`@State` 只能观察第一层变化，无法直接观察嵌套对象的属性变化（如修改收货地址的街道名称、修改某个商品的价格）。需要使用 `@Observed` + `@ObjectLink` 拆分子组件来观测深层属性变化，并使用 `@Track` 实现属性级精准更新。

**解决方案：** 使用 **`@Observed` 装饰内层类** + **`@ObjectLink` 在子组件中接收内层对象** + **`@Track` 实现属性级精准更新**

```
父组件 @State order: Order
  ├── order.address ──(@ObjectLink)──→ AddressCard（观测地址属性变化）
  │     @State 无法观察 address.street 变化 → @ObjectLink 可以
  │
  └── order.items[] ──ForEach──→ OrderItemCard(@ObjectLink)
        @State 无法观察 items[i].price 变化 → @ObjectLink 可以
        @Track 精准更新：改 price 仅刷新价格 UI，不刷新名称 UI
```

#### 1.定义数据类，使用 @Observed 装饰内层类 + @Track 装饰观测属性

```ts
@Observed
class Address {
  @Track public street: string = '中关村大街1号'
  @Track public city: string = '北京'
  public zipCode: string = '100080'  // 非 @Track，不能在 UI 中使用

  constructor(street: string, city: string) {
    this.street = street
    this.city = city
    this.zipCode = '100080'
  }
}

@Observed
class OrderItem {
  @Track public name: string = ''
  @Track public price: number = 0
  @Track public quantity: number = 1
  public id: number = 0  // 非 @Track，不能在 UI 中使用

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
    this.id = Math.floor(Math.random() * 10000)
  }
}

@Observed
class Order {
  public orderNo: string = 'ORD-20240101'
  public address: Address = new Address('中关村大街1号', '北京')
  public items: OrderItem[] = []
}
```

关键点：内层类 `Address` 和 `OrderItem` 都需要 `@Observed` 装饰，外层类 `Order` 也需要 `@Observed`。`@Track` 装饰需要精准观测的属性，被 `@Track` 装饰后，只有使用了该变化属性的 UI 组件才会刷新；未被 `@Track` 装饰的属性不能在 UI 中使用（运行时报错），但可在事件回调中使用。

#### 2.收货地址展示子组件 - @ObjectLink 观测嵌套对象属性变化

```ts
@Component
struct AddressCard {
  // @ObjectLink 接收 @Observed 装饰的 Address 实例
  // 可以观测 Address 的属性变化，与数据源双向同步
  @ObjectLink address: Address

  build() {
    Column() {
      Text(`收货地址: ${this.address.city} ${this.address.street}`)
        .fontSize(18)
        .margin(10)

      Button('修改街道')
        .onClick(() => { this.address.street = '朝阳路88号' })
      Button('修改城市')
        .onClick(() => { this.address.city = '上海' })
    }
    .padding(15)
    .backgroundColor('#f0f8ff')
    .borderRadius(8)
  }
}
```

关键点：`@ObjectLink` 建立与数据源的双向同步，可以观测 `address.street` 和 `address.city` 的变化。`@ObjectLink` 变量本身只读（不允许整体赋值），只能修改其属性。父组件中 `@State` 无法直接观察 `order.address.street` 的变化，但通过传递内层对象给 `@ObjectLink` 子组件，子组件可以观测到变化。

#### 3.商品项展示子组件 - @ObjectLink + @Track 属性级精准更新

```ts
@Component
struct OrderItemCard {
  // @ObjectLink 接收 OrderItem 实例
  // OrderItem 中 @Track 装饰的属性可实现精准刷新
  @ObjectLink item: OrderItem

  build() {
    Row() {
      Text(`商品: ${this.item.name}`)      // 仅 name 变化时刷新
        .fontSize(16)
        .width(120)
      Text(`单价: ¥${this.item.price}`)   // 仅 price 变化时刷新
        .fontSize(16)
        .width(80)
      Text(`数量: ${this.item.quantity}`)  // 仅 quantity 变化时刷新
        .fontSize(16)
        .width(60)

      Button('改价').onClick(() => { this.item.price += 10 })
      Button('改名').onClick(() => { this.item.name += '-新款' })
    }
    .padding(10)
    .margin({ bottom: 5 })
  }
}
```

关键点：`@Track` 与 `@Observed` + `@ObjectLink` 配合使用，既解决了深层属性观测问题，又实现了属性级精准更新。修改 `item.price` 时，仅 `Text(`单价: ¥${this.item.price}`)` 刷新，`Text(`商品: ${this.item.name}`)` 和 `Text(`数量: ${this.item.quantity}`)` 不会冗余刷新。

#### 4.父组件整合 - @State 观察第一层，@ObjectLink 子组件观察深层

```ts
@Entry
@Component
struct OrderDetailPage {
  @State order: Order = new Order()

  aboutToAppear() {
    this.order.items = [
      new OrderItem('智能手机', 2999),
      new OrderItem('无线耳机', 199),
      new OrderItem('充电宝', 89)
    ]
  }

  build() {
    Column({ space: 15 }) {
      Text(`订单号: ${this.order.orderNo}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // 传递内层对象给 @ObjectLink 子组件，观测嵌套属性变化
      AddressCard({ address: this.order.address })

      // ForEach + @ObjectLink：每个数组项由子组件观测属性变化
      ForEach(this.order.items,
        (item: OrderItem) => {
          OrderItemCard({ item: item })
        },
        (item: OrderItem): string => item.id.toString()
      )

      // @State 可以观察第一层变化（数组 push/pop）
      Button('添加商品')
        .onClick(() => { this.order.items.push(new OrderItem('数据线', 29)) })

      // @State 无法观察第二层变化，但 @ObjectLink 子组件可以
      Button('修改第一项价格')
        .onClick(() => { this.order.items[0].price += 100 })
    }
    .padding(20)
  }
}
```

关键点：`@State` 只能观察第一层变化：`order.address` 整体替换、`order.items` 数组增删可以被观察。但 `order.address.street`、`order.items[i].price` 等第二层属性变化，`@State` 无法直接观察，需要通过 `@ObjectLink` 子组件来观测。

---

### V2状态变量实现嵌套对象监听与属性级更新

**场景ID：** STATE_SCENE_V2_03

**场景描述：** 电商订单详情页场景，订单包含收货地址和商品列表，需要观测嵌套对象和数组项的属性变化。

**解决方案：** 使用 **`@ObservedV2` 装饰内层类** + **`@Trace` 装饰需要观测的属性**，直接在父组件中观测多层嵌套属性变化，无需拆分子组件

```
父组件 order: Order（常规变量，非状态变量）
  ├── order.address.street / order.address.city
  │     @Trace 装饰 → 直接观测变化 → UI 刷新
  │     无需拆分子组件
  │
  └── order.items[i].name / order.items[i].price / order.items[i].quantity
  │     @Trace 装饰 → 数组项属性变化直接可观测
  │     @Trace 自带属性级精准更新能力
  │
  └── order.address.region.province（多层嵌套）
      @Trace 支持任意深度 → 直接修改即刷新
```

#### 1.定义数据类，使用 @ObservedV2 + @Trace

```ts
@ObservedV2
class Region {
  // 多层嵌套：Region 作为 Address 的内层对象
  @Trace public province: string = '北京'
  @Trace public city: string = '北京市'

  constructor(province: string, city: string) {
    this.province = province
    this.city = city
  }
}

@ObservedV2
class Address {
  @Trace public street: string = '中关村大街1号'
  @Trace public region: Region = new Region('北京', '北京市')

  constructor(street: string, region: Region) {
    this.street = street
    this.region = region
  }
}

@ObservedV2
class OrderItem {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1
  public id: number = 0  // 非 @Trace 属性

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
    this.id = Math.floor(Math.random() * 10000)
  }
}

class Order {
  // V2：外层类不需要任何装饰器
  public orderNo: string = 'ORD-20240101'
  public address: Address = new Address('中关村大街1号', new Region('北京', '北京市'))
  public items: OrderItem[] = []
}
```

关键点：V2 只需在内层类上使用 `@ObservedV2` + `@Trace`，外层类 `Order` 不需要任何装饰器。`@Trace` 装饰的属性自带属性级精准更新能力（相当于 V1 的 `@Track`），只有使用了该变化属性的 UI 组件才会刷新。对于多层嵌套（如 `Region` 作为 `Address` 的内层对象），只需在最内层的类上使用 `@ObservedV2` + `@Trace` 即可。

#### 2.直接在父组件中观测嵌套属性变化（无需拆分子组件）

```ts
@Entry
@ComponentV2
struct V2OrderDetailPage {
  // order 是常规变量（非状态变量），但内部 @Trace 属性仍可观测
  order: Order = new Order()

  aboutToAppear() {
    this.order.items = [
      new OrderItem('智能手机', 2999),
      new OrderItem('无线耳机', 199),
      new OrderItem('充电宝', 89)
    ]
  }

  build() {
    Column({ space: 15 }) {
      Text(`订单号: ${this.order.orderNo}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // 直接使用嵌套属性，@Trace 使变化可观测
      Text(`收货地址: ${this.order.address.region.province} ${this.order.address.region.city} ${this.order.address.street}`)
        .fontSize(18)
        .margin(10)

      Row({ space: 10 }) {
        Button('修改街道').onClick(() => { this.order.address.street = '朝阳路88号' })
        Button('修改省份').onClick(() => { this.order.address.region.province = '上海' })
      }

      // ForEach + @Trace：数组项属性变化直接可观测，精准刷新
      ForEach(this.order.items, (item: OrderItem, index: number) => {
        Row() {
          Text(`商品: ${item.name}`)      // 仅 name 变化时刷新
            .fontSize(16)
            .width(120)
          Text(`单价: ¥${item.price}`)   // 仅 price 变化时刷新
            .fontSize(16)
            .width(80)
          Text(`数量: ${item.quantity}`)  // 仅 quantity 变化时刷新
            .fontSize(16)
            .width(60)

          Button('改价').onClick(() => { item.price += 10 })
          Button('改名').onClick(() => { item.name += '-新款' })
        }
        .padding(10)
        .margin({ bottom: 5 })
      })

      Button('添加商品')
        .onClick(() => { this.order.items.push(new OrderItem('数据线', 29)) })

      // 直接修改深层嵌套属性，UI 可刷新
      Button('修改第一项价格')
        .onClick(() => { this.order.items[0].price += 100 })
    }
    .padding(20)
  }
}
```

关键点：V2 中 `order` 是常规变量（非状态变量），但 `order.address.street`、`order.address.region.province`、`order.items[i].price` 等 `@Trace` 装饰的属性变化可直接触发 UI 刷新，无需像 V1 那样拆分子组件使用 `@ObjectLink`。`@Trace` 自带属性级精准更新能力，修改 `item.price` 时仅引用 `price` 的 UI 刷新。对于多层嵌套（如 `order.address.region.province`），`@Trace` 支持任意深度观测，V1 中同样的场景需要逐层拆分子组件。

---

## 状态变量变化监听

V1版本状态变量和V2版本状态变量均可实现状态变量变化监听。V2版本还提供 `@SyncMonitor` 同步监听（支持通配符）和 `addMonitor/clearMonitor` 动态监听作为扩展能力

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 监听方式 | `@Watch`（装饰状态变量，指定回调方法名） | `@Monitor`（装饰回调方法，指定监听变量名） / `@SyncMonitor`（同步监听）|
| 监听目标数 | 只能监听单个状态变量 | 能同时监听多个状态变量 |
| 监听深度 | 只能监听状态变量本身（一层） | 支持深层属性路径（如 `'inner.num'`） |
| 获取变化前的值 | 不能 | 能（`monitor.value()?.before`） |
| 通配符支持 | 不支持 | 支持 |
| 回调时机 | 同步（立即触发） | `@Monitor` 异步（事件结束后触发一次）；`@SyncMonitor` 同步（每次变化立即触发） |
| 使用范围 | 仅能在 `@Component` 中使用 | `@Monitor/@SyncMonitor` 在 `@ComponentV2` 和 `@ObservedV2` 类中使用； |
| 多变量共享回调 | 多个变量绑定同一个回调方法名，通过 `propName` 区分 | 直接声明监听多个变量，`monitor.dirty` 返回变化路径 |
| 动态添加/取消 | 不支持 | `addMonitor` 动态添加，`clearMonitor` 动态取消 |

---

### V1状态变量变化监听

**场景ID：** STATE_SCENE_V1_04

**场景描述：** 仿购物车页面，商品数量变化时自动计算总价，购物车列表变化时重新计算优惠后实付金额，且不同商品数量变化时统一判断是否满足满减条件。

**解决方案：** 使用 **`@Watch` 监听状态变量变化并触发回调**，支持与 `@Link` 组合使用，多个变量可绑定同一回调通过 `propName` 区分

```
购物车页面 @State
  ├── appleCount ──(@Watch('onFruitChange'))──→ 统一回调
  ├── orangeCount ──(@Watch('onFruitChange'))──→ 统一回调
  │     苹果/橙子数量变化 → 同一个 onFruitChange → propName 区分来源 → 重算总价和满减
  │
  └── shopBasket ──(@Link + @Watch)──→ CartSummary 子组件
        购物车列表变化 → @Link 双向同步 → @Watch 触发 → 重算优惠后实付
```

#### 1.父组件使用 @Watch 监听状态变量变化 + 多变量共享回调

```ts
@Entry
@Component
struct ShoppingCartPage {
  @State totalQuantity: number = 0
  @State totalPrice: number = 0
  @State isDiscount: boolean = false

  // @Watch 监听状态变量变化，多个变量绑定同一个回调方法名
  @State @Watch('onFruitChange') appleCount: number = 0
  @State @Watch('onFruitChange') orangeCount: number = 0
  @State shopBasket: PurchaseItem[] = []

  // @Watch 回调：苹果或橙子数量变化时，重算总价和满减条件
  // propName 参数区分是哪个变量发生了变化
  onFruitChange(propName: string): void {
    this.totalQuantity = this.appleCount + this.orangeCount
    this.totalPrice = this.appleCount * 5 + this.orangeCount * 3
    this.isDiscount = this.totalPrice >= 100  // 满100享受优惠

    if (propName === 'appleCount') {
      console.info(`苹果数量变化，当前: ${this.appleCount}`)
    } else if (propName === 'orangeCount') {
      console.info(`橙子数量变化，当前: ${this.orangeCount}`)
    }
  }

  build() {
    Column({ space: 15 }) {
      Text(`购物车`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      Text(`总数量: ${this.totalQuantity}  总价: ¥${this.totalPrice}`)
        .fontSize(18)
      if (this.isDiscount) {
        Text(`满100享9折优惠!`)
          .fontColor(Color.Red)
          .fontSize(16)
      }

      Row({ space: 10 }) {
        Button(`苹果(${this.appleCount}) +1`)
          .onClick(() => { this.appleCount++ })
        Button(`橙子(${this.orangeCount}) +1`)
          .onClick(() => { this.orangeCount++ })
      }

      // @Link + @Watch 子组件
      CartSummary({ shopBasket: $shopBasket })

      Button('添加商品到购物车')
        .onClick(() => {
          this.shopBasket.push(new PurchaseItem(Math.round(100 * Math.random())))
        })
    }
    .padding(20)
  }
}
```

关键点：`@Watch` 在第一次初始化时不会被调用，只在后续状态改变时触发。多个状态变量 (`appleCount` 和 `orangeCount`) 绑定同一个回调方法名 `'onFruitChange'`，通过回调参数 `propName` 区分是哪个变量发生了变化，实现不同来源的差异化处理。

#### 2.子组件使用 @Link + @Watch 组合监听

```ts
class PurchaseItem {
  public id: number
  public price: number

  constructor(price: number) {
    this.id = Math.floor(Math.random() * 10000)
    this.price = price
  }
}

@Component
struct CartSummary {
  // @Link 双向同步购物车列表，@Watch 监听列表变化触发回调
  @Link @Watch('onBasketUpdated') shopBasket: PurchaseItem[]
  @State totalPurchase: number = 0

  updateTotal(): number {
    let total = this.shopBasket.reduce((sum, i) => sum + i.price, 0)
    if (total >= 100) {
      total = 0.9 * total  // 满100打9折
    }
    return total
  }

  // @Watch 回调：购物车列表变化时重新计算优惠后实付金额
  onBasketUpdated(propName: string): void {
    this.totalPurchase = this.updateTotal()
  }

  build() {
    Column() {
      ForEach(this.shopBasket, (item: PurchaseItem) => {
        Text(`商品价格: ¥${item.price.toFixed(2)}`)
      })
      Text(`优惠后实付: ¥${this.totalPurchase.toFixed(2)}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Red)
    }
  }
}
```

关键点：`@Watch` 可与 `@Link` 组合使用。`@Link` 建立双向同步获取购物车列表，`@Watch` 监听同步后的变化触发回调重新计算优惠后实付。`@Watch` 回调在状态变量变更之后同步执行，回调参数 `propName` 为变化的属性名字符串。

---

### V2状态变量变化精准监听与变化前后值获取

**场景ID：** STATE_SCENE_V2_04

**场景描述：** 仿购物车页面，商品数量或价格变化时需要自动计算总价并获取变化前的值（如显示"价格从 ¥2999 变为 ¥3099"），商品对象的属性变化需要精准监听，嵌套的商品规格属性变化也需要触发回调。

**解决方案：** 使用 **`@Monitor` 监听状态变量修改**，支持获取变化前后的值、监听 `@ObservedV2` 类属性变化和深层属性路径

```
购物车页面 @ComponentV2
  ├── @Local quantity, price ──(@Monitor('quantity', 'price'))──→ onFieldChange
  │     数量/价格变化 → monitor.dirty 返回变化路径 → monitor.value() 获取前后值
  │     显示 "price 从 2999 变为 3099"
  │
  ├── Product(@ObservedV2) ──@Trace name, price──→ @Monitor('price') onPriceChange
  │     商品对象属性变化 → 类内 @Monitor 触发 → 获取前后值日志
  │
  └── product.specs.weight ──(@Monitor('product.specs.weight'))──→ onSpecsChange
        嵌套规格属性变化 → @Monitor 支持深层路径 → 直接触发回调
```

#### 1.定义数据类，使用 @ObservedV2 + @Trace + @Monitor

```ts
@ObservedV2
class ProductSpecs {
  @Trace public weight: string = '200g'
  @Trace public color: string = '黑色'

  constructor(weight: string, color: string) {
    this.weight = weight
    this.color = color
  }
}

@ObservedV2
class Product {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1
  public specs: ProductSpecs = new ProductSpecs('200g', '黑色')

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
  }

  // @Monitor 在 @ObservedV2 类中监听 @Trace 属性变化
  // 获取变化前后的值
  @Monitor('price')
  onPriceChange(monitor: IMonitor) {
    console.info(`商品价格从 ¥${monitor.value()?.before} 变为 ¥${monitor.value()?.now}`)
  }
}
```

关键点：`@Monitor` 可以在 `@ObservedV2` 装饰的类中使用，监听 `@Trace` 装饰的属性变化。未被 `@Trace` 装饰的属性无法被 `@Monitor` 监听。`monitor.value()` 可获取变化前后的值（`before` 和 `now`），这是 V1 `@Watch` 不具备的能力。V1 的 `@Watch` 只能在 `@Component` 中使用，V2 的 `@Monitor` 可以在 `@ComponentV2` 和 `@ObservedV2` 类中使用。

#### 2.组件中使用 @Monitor 监听多个变量、获取前后值与深层属性路径

```ts
@Entry
@ComponentV2
struct V2ShoppingCartPage {
  @Local quantity: number = 1
  @Local price: number = 2999
  @Local product: Product = new Product('智能手机', 2999)
  @Local changeLog: string = ''

  // @Monitor 同时监听多个变量，获取变化前后的值
  @Monitor('quantity', 'price')
  onFieldChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      const before = monitor.value(path)?.before
      const now = monitor.value(path)?.now
      this.changeLog += `${path} 从 ${before} 变为 ${now}\n`
    })
  }

  // @Monitor 监听深层属性路径
  @Monitor('product.specs.weight')
  onSpecsChange(monitor: IMonitor) {
    this.changeLog += `规格重量从 ${monitor.value()?.before} 变为 ${monitor.value()?.now}\n`
  }

  build() {
    Column({ space: 15 }) {
      Text(`购物车`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(`商品: ${this.product.name}  价格: ¥${this.product.price}  数量: ${this.quantity}`)
        .fontSize(18)

      Text(`总价: ¥${this.price * this.quantity}`)
        .fontSize(20)
        .fontColor(Color.Red)

      Row({ space: 10 }) {
        Button('数量+1').onClick(() => { this.quantity++ })
        Button('涨价100').onClick(() => { this.price += 100 })
        Button('改规格重量').onClick(() => { this.product.specs.weight = '300g' })
      }

      // 显示变化日志，展示前后值
      Text(`变化记录:\n${this.changeLog}`)
        .fontSize(14)
        .fontColor('#666666')
        .maxLines(5)
    }
    .padding(20)
  }
}
```

关键点：V2 的 `@Monitor` 与 V1 的 `@Watch` 有本质区别：(1) `@Monitor` 装饰回调方法，直接声明监听的变量名，而 `@Watch` 装饰状态变量并指定回调方法名；(2) `@Monitor` 能同时监听多个变量，`monitor.dirty` 返回变化的属性路径列表；(3) `@Monitor` 可获取变化前后的值 (`monitor.value(path)?.before/now`)；(4) `@Monitor` 支持深层属性路径监听（如 `'product.specs.weight'`），V1 的 `@Watch` 只能监听状态变量本身的变化，无法监听嵌套属性。

---

### V2状态变量同步监听与通配符监听

**场景ID：** STATE_SCENE_V2_05

**场景描述：** 仿购物车页面，商品数量或价格变化时需要立即同步回调（如连续修改价格时每次变化都立即触发，而非等所有变化结束后才触发一次），购物车对象的任意属性变化都需要触发状态提醒。

**解决方案：** 使用 **`@SyncMonitor` 同步监听状态变量修改**，支持获取变化前后值、通配符模糊监听和深层属性监听

```
购物车页面 @ComponentV2
  ├── @Local quantity, price ──(@SyncMonitor('quantity','price'))──→ onFieldChange（同步回调）
  │     数量/价格变化 → 立即触发回调 → 同步获取前后值
  │     @Monitor 在事件结束后只触发一次，@SyncMonitor 每次变化都触发
  │
  ├── Product(@ObservedV2) ──@SyncMonitor('price')──→ onPriceChange（类内同步监听）
  │     商品价格变化 → 立即触发类内回调 → 获取前后值日志
  │
  └── cartData(CartData) ──@SyncMonitor('cartData.*')──→ 通配符监听
        任意购物车属性变化 → 模糊监听 → 触发状态提醒
```

#### 1.定义数据类，使用 @ObservedV2 + @Trace + @SyncMonitor

```ts
@ObservedV2
class CartData {
  @Trace public totalQuantity: number = 0
  @Trace public totalPrice: number = 0
  @Trace public isDiscount: boolean = false
  public note: string = ''              // 非 @Trace，不可监听

  // @SyncMonitor 在类中监听 @Trace 属性变化
  // 同步回调：每次属性变化立即触发，而非等事件结束
  @SyncMonitor('totalPrice')
  onTotalPriceChange(monitor: IMonitor) {
    console.info(`总价从 ¥${monitor.value()?.before} 变为 ¥${monitor.value()?.now}`)
  }
}

@ObservedV2
class Product {
  @Trace public name: string = ''
  @Trace public price: number = 0
  @Trace public quantity: number = 1

  constructor(name: string, price: number) {
    this.name = name
    this.price = price
  }

  // @SyncMonitor 在 Product 类中监听价格变化，同步触发回调
  // 区别于 @Monitor：同一事件中价格多次变化，每次都立即触发
  @SyncMonitor('price')
  onPriceChange(monitor: IMonitor) {
    console.info(`商品价格从 ¥${monitor.value()?.before} 变为 ¥${monitor.value()?.now}`)
  }
}
```

关键点：`@SyncMonitor` 与 `@Monitor` 在类中的用法相似，都监听 `@Trace` 装饰的属性变化。核心区别在于回调时机：`@SyncMonitor` 在属性变化后立即同步触发回调，同一事件中属性多次变化时每次都触发；`@Monitor` 在状态变更函数结束后异步触发，同一事件中多次变更只触发一次。未被 `@Trace` 装饰的属性无法被 `@SyncMonitor` 监听。

#### 2.组件中使用 @SyncMonitor 同步监听与通配符监听

```ts
@Entry
@ComponentV2
struct SyncMonitorCartPage {
  @Local quantity: number = 1
  @Local price: number = 2999
  @Local product: Product = new Product('智能手机', 2999)
  @Local cartData: CartData = new CartData()
  @Local changeLog: string = ''

  // @SyncMonitor 同步监听数量和价格变化：每次变化都立即触发回调
  // 区别于 @Monitor：如果 price 连续从 2999 变到 3099 再变到 3199
  //   @SyncMonitor 回调2次（2999→3099, 3099→3199），每次立即获取前后值
  //   @Monitor 只回调1次（2999→3199），事件结束后才触发
  @SyncMonitor('quantity', 'price')
  onFieldChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      const before = monitor.value(path)?.before ?? 0
      const now = monitor.value(path)?.now ?? 0
      this.changeLog += `${path}: ¥${before} → ¥${now}\n`
    })
    this.cartData.totalQuantity = this.quantity
    this.cartData.totalPrice = this.price * this.quantity
    this.cartData.isDiscount = this.cartData.totalPrice >= 100
  }

  // @SyncMonitor 通配符监听：购物车任意属性变化都触发提醒
  // 'cartData.*' 监听 cartData 对象的整体赋值或任意 @Trace 属性变化
  @SyncMonitor('cartData.*')
  onCartDataChange(monitor: IMonitor) {
    // 通配符监听时，before 和 now 均为 undefined
    console.info(`购物车数据发生变化，请查看最新状态`)
  }

  build() {
    Column({ space: 15 }) {
      Text(`购物车`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(`数量: ${this.quantity}  单价: ¥${this.price}`)
        .fontSize(18)

      Text(`总价: ¥${this.cartData.totalPrice}  ${this.cartData.isDiscount ? '满100享9折优惠!' : ''}`)
        .fontSize(18)

      Text(this.changeLog)
        .fontSize(14)
        .fontColor(Color.Gray)

      Row({ space: 10 }) {
        Button('数量+1').onClick(() => { this.quantity++ })
        Button('价格+100').onClick(() => { this.price += 100 })
      }

      Row({ space: 10 }) {
        Button('商品价格+100').onClick(() => { this.product.price += 100 })
        Button('商品价格再+100').onClick(() => { this.product.price += 100 })
      }
    }
    .padding(20)
  }
}
```

关键点：

(1) `@SyncMonitor` 与 `@Monitor` 的核心行为差异：`@SyncMonitor` 在状态变量变化后立即同步触发回调，同一事件中多次变化时每次都触发（如价格连续从 2999 变到 3099 再变到 3199，`@SyncMonitor` 回调 2 次：2999→3099、3099→3199）；`@Monitor` 在事件处理函数结束后异步触发，多次变更只触发一次（价格从 2999 变到 3199，只回调 1 次：2999→3199）。需要实时响应每次变化的场景应使用 `@SyncMonitor`。

(2) `@SyncMonitor` 和 `@Monitor` 均支持通配符 `'*'`：路径末尾添加 `*` 可监听对象的任意 `@Trace` 属性变化或数组的任意项变化，便于从 V1 `@Watch` 迁移到 V2。`@SyncMonitor` 直接在路径中使用 `*`（如 `@SyncMonitor('cartData.*')`）；`@Monitor` 从 API 26.0.0 支持通过 `MonitorDecoratorOptions` 的 `enableWildcard` 属性配置通配符（如 `@Monitor({ enableWildcard: true }, 'cartData.*')`），`enableWildcard` 默认值为 `true`。通配符监听时 `monitor.value()` 的 `before` 和 `now` 均为 `undefined`。通配符只能出现在路径末尾，不能出现在开头或中间（如 `*.prop`、`arr.*.prop` 均无效）。

---

### V2状态变量动态监听与取消监听

**场景ID：** STATE_SCENE_V2_06

**场景描述：** 仿运动健身数据监测页面，用户开始运动时需要动态添加心率监听回调（配置同步监听实现实时心率报警），结束运动时需要清除监听，且不同运动模式需要监听不同的数据指标。

**解决方案：** 使用 **`addMonitor` 动态添加监听** + **`clearMonitor` 动态取消监听**，支持配置同步监听和数组路径批量监听

```
运动监测页面 @ComponentV2
  ├── aboutToAppear ──addMonitor(this.workoutData, ['distance','duration'], ...)──→ 类实例监听
  │     组件出现时 → 为 WorkoutData 实例动态添加监听
  │
  ├── 开始运动 ──addMonitor(this, 'heartRate', ..., {isSynchronous:true})──→ 同步监听
  │     动态添加心率监听 → isSynchronous:true 实时报警
  │
  └── 结束运动 ──clearMonitor(this, 'heartRate', ...)──→ 取消监听
        动态清除心率监听 → 不再回调
```

#### 1.定义数据类与动态监听回调方法

```ts
import { UIUtils } from '@kit.ArkUI'

@ObservedV2
class WorkoutData {
  @Trace public distance: number = 0    // 距离（米）
  @Trace public duration: number = 0    // 时长（秒）
  @Trace public calories: number = 0    // 卡路里

  // addMonitor 的回调方法：必须为命名方法，不能为匿名函数
  onWorkoutChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      console.info(`运动数据 ${path} 从 ${monitor.value(path)?.before} 变为 ${monitor.value(path)?.now}`)
    })
  }

  constructor() {
    // 在类构造函数中用 addMonitor 动态添加监听
    // 传入数组路径一次性监听多个属性
    UIUtils.addMonitor(this, ['distance', 'duration'], this.onWorkoutChange)
  }
}
```

关键点：`addMonitor` 在运行时动态添加监听回调，不像 `@Monitor` 装饰器那样在所有实例上共享同一回调。`addMonitor` 的回调函数必须为命名方法，不能为匿名函数。`addMonitor` 支持传入数组路径（如 `['distance', 'duration']`）一次性监听多个属性。

#### 2.组件中使用 addMonitor 动态添加监听与 clearMonitor 动态取消监听

```ts
@Entry
@ComponentV2
struct DynamicMonitorPage {
  @Local heartRate: number = 72
  @Local isWorkoutActive: boolean = false
  workoutData: WorkoutData = new WorkoutData()

  // addMonitor 的回调方法：必须为命名方法
  onHeartRateChange(monitor: IMonitor) {
    const before = monitor.value('heartRate')?.before ?? 0
    const now = monitor.value('heartRate')?.now ?? 0
    console.info(`心率从 ${before} 变为 ${now}`)
    if (now > 150) {
      console.info(`心率过高，请注意休息！`)
    }
  }

  aboutToAppear(): void {
    // addMonitor 动态添加监听：在组件出现时为 workoutData 实例添加监听
    // 注意：addMonitor 仅支持 @ObservedV2 和 @ComponentV2 实例
    UIUtils.addMonitor(this.workoutData, ['distance', 'calories'], this.workoutData.onWorkoutChange)
  }

  build() {
    Column({ space: 15 }) {
      Text(`运动数据监测`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(`心率: ${this.heartRate}  ${this.isWorkoutActive ? '运动中' : '休息中'}`)
        .fontSize(18)

      Text(`距离: ${this.workoutData.distance}m  卡路里: ${this.workoutData.calories}cal`)
        .fontSize(18)

      // 开始/结束运动：动态添加/清除心率监听
      Button(this.isWorkoutActive ? '结束运动' : '开始运动')
        .onClick(() => {
          if (!this.isWorkoutActive) {
            // 开始运动：addMonitor 动态添加心率同步监听
            // isSynchronous: true 配置为同步监听，心率变化立即触发回调
            UIUtils.addMonitor(this, 'heartRate', this.onHeartRateChange, { isSynchronous: true })
            this.isWorkoutActive = true
          } else {
            // 结束运动：clearMonitor 动态清除心率监听
            // clearMonitor 仅可删除 addMonitor 添加的回调，无法删除 @Monitor 的回调
            UIUtils.clearMonitor(this, 'heartRate', this.onHeartRateChange)
            this.isWorkoutActive = false
          }
        })

      Button('心率+10').onClick(() => { this.heartRate += 10 })
      Button('距离+100m').onClick(() => { this.workoutData.distance += 100 })
    }
    .padding(20)
  }
}
```

关键点：

(1) `addMonitor` / `clearMonitor` 动态监听：`addMonitor` 在运行时动态添加监听回调，`clearMonitor` 动态取消。需要导入 `UIUtils`（`import { UIUtils } from '@kit.ArkUI'`）。与 `@Monitor` 装饰器不同，`addMonitor` 可以对不同实例添加不同的监听回调，且可以在运行时根据条件动态添加或取消。

(2) `addMonitor` 支持 `isSynchronous` 参数配置同步监听：`isSynchronous: true` 时行为类似 `@SyncMonitor`（每次变化立即同步触发回调），`isSynchronous: false`（默认）时行为类似 `@Monitor`（异步触发，多次变更只触发一次）。`isSynchronous` 仅第一次设置有效，不能后续更改。

(3) `clearMonitor` 仅可删除 `addMonitor` 添加的回调，无法删除 `@Monitor` 或 `@SyncMonitor` 的回调。可以传入具体回调函数删除指定的监听（`clearMonitor(target, path, callback)`），也可以不传回调函数删除该 path 下所有 `addMonitor` 添加的监听（`clearMonitor(target, path)`）。`addMonitor` 的回调函数不能为匿名函数，必须为命名方法。

---

## 计算属性

仅V2版本状态变量可实现计算属性

### V2状态变量实现依赖驱动的自动计算

**场景ID：** STATE_SCENE_V2_07

**场景描述：** 仿电商购物车页面，购物车包含多个商品（每个商品有单价和数量），需要自动计算每件商品小计、购物车总价和是否满足满减优惠条件，总价变化时记录变化日志，并将计算结果传递给子组件展示。

**解决方案：** 使用 **`@Computed` 装饰 getter 方法实现计算属性**，依赖的状态变量变化时只计算一次

```
购物车页面 @ComponentV2
  ├── Product(@ObservedV2) ──@Trace quantity──→ @Computed subtotal
  │     每件商品小计 = quantity × unitPrice，依赖变化时只算一次
  │
  ├── @Local shoppingBasket ──@Computed──→ totalPrice（购物车总价）
  │     totalPrice = 各商品小计之和，所有 quantity 变化 → 自动重算
  │
  ├── totalPrice ──@Computed──→ qualifiesForDiscount（是否满减）
  │     qualifiesForDiscount = totalPrice >= 100，链式依赖自动求解
  │
  ├── totalPrice, qualifiesForDiscount ──(@Param)──→ CartSummary 子组件
  │     @Computed 结果初始化子组件 @Param
  │
  └── @Monitor('totalPrice') ──→ onTotalChange
        @Computed 属性可被 @Monitor 监听，获取变化前后值
```

#### 1.定义商品数据类，使用 @ObservedV2 + @Trace + @Computed

```ts
@ObservedV2
class Product {
  @Trace public quantity: number = 0
  public unitPrice: number = 0

  constructor(quantity: number, unitPrice: number) {
    this.quantity = quantity
    this.unitPrice = unitPrice
  }

  // @Computed 在 @ObservedV2 类中装饰 getter 方法
  // 依赖 @Trace 属性变化时自动重新计算，计算结果为只读
  @Computed
  get subtotal(): number {
    return this.quantity * this.unitPrice
  }
}
```

关键点：`@Computed` 可以在 `@ObservedV2` 装饰的类中使用，依赖的 `@Trace` 属性变化时触发重新计算。`subtotal` 仅依赖 `quantity`（`unitPrice` 非 `@Trace`，变化不会触发重算），计算结果为只读，不允许赋值。未被 `@Trace` 装饰的属性变化不会触发 `@Computed` 重算。

#### 2.父组件使用 @Computed 计算总价与满减条件 + @Monitor 监听

```ts
@Entry
@ComponentV2
struct ShoppingCartPage {
  @Local shoppingBasket: Product[] = [new Product(1, 20), new Product(5, 2)]

  // @Computed 在组件中装饰 getter 方法，依赖变化时自动重新计算
  // 多处 UI 引用 totalPrice 时只计算一次，读取缓存值
  @Computed
  get totalPrice(): number {
    return this.shoppingBasket.reduce(
      (acc: number, item: Product) => acc + item.subtotal, 0
    )
  }

  // @Computed 支持链式依赖：qualifiesForDiscount 依赖 totalPrice
  // totalPrice 变化 → qualifiesForDiscount 自动重算
  @Computed
  get qualifiesForDiscount(): boolean {
    return this.totalPrice >= 100
  }

  // @Computed 装饰的属性可被 @Monitor 监听
  @Monitor('totalPrice')
  onTotalChange(monitor: IMonitor) {
    console.info(`总价从 ¥${monitor.value()?.before} 变为 ¥${monitor.value()?.now}`)
  }

  build() {
    Column() {
      Text('购物车').fontSize(24).fontWeight(FontWeight.Bold)

      ForEach(this.shoppingBasket, (item: Product) => {
        Row() {
          Text(`单价: ¥${item.unitPrice} `).fontSize(16)
          Button('-').onClick(() => { if (item.quantity > 0) item.quantity-- })
          Text(` 数量: ${item.quantity} `).fontSize(16)
          Button('+').onClick(() => { item.quantity++ })
          Text(` 小计: ¥${item.subtotal}`).fontSize(16).fontColor(Color.Red)
        }
        Divider()
      })

      // @Computed 结果可以初始化子组件 @Param
      CartSummary({ total: this.totalPrice, qualifiesForDiscount: this.qualifiesForDiscount })
    }
    .padding(20)
  }
}
```

关键点：

(1) `@Computed` 在组件中装饰 getter 方法，依赖的 `@Local` 变量或 `@Trace` 属性变化时自动重新计算。即使 UI 中多处引用 `totalPrice`，也只计算一次并读取缓存值。

(2) `@Computed` 支持链式依赖：`qualifiesForDiscount` 依赖 `totalPrice`，当 `totalPrice` 变化时，`qualifiesForDiscount` 自动重算。计算属性链式依赖时按顺序求解。

(3) `@Computed` 装饰的属性可被 `@Monitor` 监听。`totalPrice` 变化 → `@Monitor('totalPrice')` 回调触发，可通过 `monitor.value()` 获取变化前后的值。

(4) `@Computed` 结果可以初始化子组件的 `@Param`，实现父子组件数据同步。

#### 3.子组件使用 @Param 接收 @Computed 计算结果

```ts
@ComponentV2
struct CartSummary {
  @Param total: number = 0
  @Param qualifiesForDiscount: boolean = false

  build() {
    Row() {
      Text(`总价: ¥${this.total}`).fontSize(20).fontWeight(FontWeight.Bold)
      if (this.qualifiesForDiscount) {
        Text(` 满100享9折优惠!`).fontColor(Color.Red).fontSize(16)
      }
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

关键点：`@Computed` 计算结果通过 `@Param` 传入子组件。依赖变化 → `totalPrice` 重算 → `qualifiesForDiscount` 重算 → `@Param` 同步更新子组件 UI。

---

## 应用UI状态存储与共享

V1版本状态变量和V2版本状态变量均可实现应用级全局状态共享。V1提供页面级存储能力（LocalStorage），V2没有专用的页面级存储方案。

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 应用级全局存储 | `AppStorage` + `@StorageLink`（双向）/ `@StorageProp`（单向） | `AppStorageV2.connect`（双向同步 `@Trace` 属性） |
| 页面级存储 | `LocalStorage` + `@LocalStorageLink`（双向）/ `@LocalStorageProp`（单向） | 无专用页面级存储方案 |
| 支持数据类型 | 基本类型、class、Object、数组、Map、Set、Date | 仅 class 类型（不支持基本类型） |
| 同步方式 | key 匹配（字符串 key） | connect 匹配（类构造器或指定 key） |
| 观测属性 | 可观测 class 属性变化 | `@Trace` 属性变化触发同步，非 `@Trace` 属性变化不触发 UI 刷新 |
| 跨页面共享 | 多页面通过同一个 AppStorage 单例共享 | 多页面通过 connect 同一个类获取相同引用 |

---

### V1状态变量实现页面级与应用级全局共享

**场景ID：** STATE_SCENE_V1_05

**场景描述：** 仿即时通讯应用，会话列表页展示未读消息数和当前聊天对象，点击进入聊天详情页后可以发送消息和切换聊天对象，两个页面间实时同步。聊天详情页内部，草稿输入框可修改草稿内容，顶部状态栏只读展示草稿状态和聊天对象名，这些仅在当前聊天页内共享。

**解决方案：** 使用 **`AppStorage` + `@StorageLink` / `@StorageProp` 实现应用级全局共享** + **`LocalStorage` + `@LocalStorageLink` / `@LocalStorageProp` 实现页面级共享**

```
即时通讯应用（多页面场景）
├── 应用级（AppStorage）：跨页面共享
│   ├── @StorageLink('currentContact') ──双向──→ 会话列表页 + 聊天详情页
│   │     任一页面切换聊天对象 → 所有页面同步更新
│   ├── @StorageLink('unreadCount') ──双向──→ 会话列表页 + 聊天详情页
│   │     读取消息 → 未读数减少 → 所有页面同步
│   └── @StorageProp('currentContact') ──单向──→ 聊天状态栏（只读展示）
│
└── 页面级（LocalStorage）：仅聊天详情页内共享
    ├── @LocalStorageLink('draftText') ──双向──→ 草稿输入框（可修改）
    │     输入草稿 → 同步回 LocalStorage → 状态栏更新
    ├── @LocalStorageProp('draftText') ──单向──→ 聊天状态栏（只读展示草稿）
    │     状态栏本地修改不回写，但 LocalStorage 变化会覆盖本地
    └── 页面销毁时 LocalStorage 随页面释放，草稿不残留到全局
```

#### 1.初始化 AppStorage 应用级数据

```ts
// 在应用入口初始化应用级全局状态
AppStorage.setOrCreate('currentContact', '未选择')
AppStorage.setOrCreate('unreadCount', 0)
```

关键点：`AppStorage` 是应用级单例，在应用启动时创建，所有页面共享同一个实例。`setOrCreate` 创建或更新属性，所有绑定该 key 的组件都会同步。

#### 2.会话列表页 - 应用级双向同步（@StorageLink）

```ts
@Entry
@Component
struct ChatListPage {
  // @StorageLink 与 AppStorage 建立双向同步
  // 修改会同步回 AppStorage，其他绑定同一 key 的组件也会更新
  @StorageLink('currentContact') currentContact: string = '未选择'
  @StorageLink('unreadCount') unreadCount: number = 0
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
        Text('即时通讯')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(`当前聊天: ${this.currentContact}`)
          .fontSize(18)
        Text(`未读消息: ${this.unreadCount}`)
          .fontSize(18)

        Row({ space: 10 }) {
          Button('切换聊天对象').onClick(() => { this.currentContact = '小明' })
          Button('标记已读').onClick(() => { this.unreadCount = 0 })
        }

        Button('进入聊天详情')
          .onClick(() => { this.pageStack.pushPathByName('ChatDetail', null) })
      }
      .padding(20)
    }
  }
}
```

关键点：会话列表页使用 `@StorageLink` 双向同步应用级数据，修改 `currentContact` 或 `unreadCount` 后同步回 AppStorage，聊天详情页中绑定同一 key 的组件也会更新。

#### 3.聊天详情页 - 应用级双向 + 页面级共享

```ts
// 创建页面级 LocalStorage 实例，仅在聊天详情页内共享
let chatStorage: LocalStorage = new LocalStorage()
chatStorage.setOrCreate('draftText', '')

@Entry(chatStorage)
@Component
struct ChatDetailPage {
  // 应用级双向同步
  @StorageLink('currentContact') currentContact: string = '未选择'
  @StorageLink('unreadCount') unreadCount: number = 0
  // 页面级双向同步
  @LocalStorageLink('draftText') draftText: string = ''
  pageStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('聊天详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        // 应用级数据展示
        Text(`聊天对象: ${this.currentContact}`)
          .fontSize(20)
        Text(`未读消息: ${this.unreadCount}`)
          .fontSize(20)

        // 页面级数据展示
        Text(`草稿: ${this.draftText}`)
          .fontSize(20)

        // 聊天状态栏（只读展示）
        ChatStatusBar()

        Row({ space: 10 }) {
          Button('切换聊天').onClick(() => { this.currentContact = '小红' })
          Button('标记已读').onClick(() => { this.unreadCount = 0 })
          Button('输入草稿').onClick(() => { this.draftText += '你好' })
        }

        Button('返回会话列表')
          .onClick(() => { this.pageStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
    })
  }
}
```

关键点：同一个页面中可以同时使用 `@StorageLink`（应用级）和 `@LocalStorageLink`（页面级）。`@Entry(chatStorage)` 将 LocalStorage 实例分配给页面根组件，所有子组件自动获得对该实例的访问权限。页面销毁时 LocalStorage 随页面释放，草稿数据不会残留到全局。

#### 4.聊天状态栏子组件 - @StorageProp 单向 + @LocalStorageProp 单向

```ts
@Component
struct ChatStatusBar {
  // @StorageProp 单向同步：AppStorage 变化自动同步，本地修改不回写
  @StorageProp('currentContact') currentContact: string = '未选择'
  @StorageProp('unreadCount') unreadCount: number = 0
  // @LocalStorageProp 单向同步：LocalStorage 变化自动同步，本地修改不回写
  @LocalStorageProp('draftText') draftText: string = ''

  build() {
    Row() {
      Text(`${this.currentContact}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
      Text(`未读${this.unreadCount}`)
        .fontSize(14)
        .fontColor(Color.Red)
      Text(`草稿: ${this.draftText || '无'}`)
        .fontSize(12)
        .fontColor(Color.Gray)
    }
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

关键点：`@StorageProp` 与 AppStorage 建立单向同步，适合只读展示场景，本地修改不会同步回 AppStorage，但 AppStorage 变化会覆盖本地修改。`@LocalStorageProp` 与 LocalStorage 建立单向同步，行为同理。状态栏只需展示数据，不需要修改数据源，因此使用单向同步。
---

### V2状态变量实现应用级class全局共享

**场景ID：** STATE_SCENE_V2_08

**场景描述：** 即时通讯应用场景，会话列表页和聊天详情页跨页面共享聊天数据。

**解决方案：** 使用 **`AppStorageV2.connect` 实现应用级全局 class 共享**

```
即时通讯应用（多页面场景，V2）
├── 应用级（AppStorageV2）：跨页面共享
│   ├── ChatState(@ObservedV2) ──connect──→ 全局单例
│   │     @Trace currentContact, unreadCount → 修改触发 UI 刷新 + 全局同步
│   │
│   ├── @Local chatState ──connect──→ 会话列表页
│   │     切换聊天对象/标记已读 → @Trace 属性变化 → AppStorageV2 同步 → 详情页感知
│   │
│   └── @Local chatState ──connect──→ 聊天详情页
│       connect 同一个类 → 获取相同对象引用 → 双向同步
│
└── 页面级：V2 无专用页面级存储方案（无 LocalStorage 对应物）
    页面内局部状态使用 @Local 管理，不提供类似 LocalStorage 的页面级共享机制
```

#### 1.定义聊天数据类

```ts
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
class ChatState {
  @Trace public currentContact: string = '未选择'
  @Trace public unreadCount: number = 0
  // 非 @Trace 属性：修改不触发 UI 刷新，但已同步回 AppStorageV2
  public lastActiveTime: string = ''

  constructor(currentContact?: string, unreadCount?: number) {
    this.currentContact = currentContact ?? '未选择'
    this.unreadCount = unreadCount ?? 0
  }
}
```

关键点：AppStorageV2 只支持 class 类型，不支持基本类型（string、number、boolean）。`@Trace` 装饰的属性变化会触发 UI 刷新和跨组件同步；非 `@Trace` 属性变化会同步回 AppStorageV2 但不触发 UI 刷新。

#### 2.会话列表页 - 应用级全局共享（connect）

```ts
@Entry
@ComponentV2
struct V2ChatListPage {
  // connect 在 AppStorageV2 中创建或获取 ChatState 对象
  @Local chatState: ChatState = AppStorageV2.connect<ChatState>(
    ChatState, () => new ChatState()
  )!
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
        Text('即时通讯')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        // 修改 @Trace 属性，UI 刷新 + 全局同步
        Text(`当前聊天: ${this.chatState.currentContact}`)
          .fontSize(18)
        Text(`未读消息: ${this.chatState.unreadCount}`)
          .fontSize(18)

        Row({ space: 10 }) {
          Button('切换聊天对象').onClick(() => { this.chatState.currentContact = '小明' })
          Button('标记已读').onClick(() => { this.chatState.unreadCount = 0 })
        }

        Button('进入聊天详情')
          .onClick(() => { this.pageStack.pushPathByName('ChatDetail', null) })
      }
      .padding(20)
    }
  }
}
```

关键点：`AppStorageV2.connect` 创建或获取全局共享对象，`@Local` 接收引用。修改 `@Trace` 属性 `currentContact` 或 `unreadCount` 后，所有 connect 同一 key 的组件自动同步更新。connect 未指定 key 时，默认使用类的构造器作为 key。

#### 3.聊天详情页 - 应用级共享

```ts
@ComponentV2
struct V2ChatDetailPage {
  // connect 同一个 ChatState，获取相同的对象引用
  @Local chatState: ChatState = AppStorageV2.connect<ChatState>(
    ChatState, () => new ChatState()
  )!
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('聊天详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        // 应用级数据：跨页面同步
        Text(`聊天对象: ${this.chatState.currentContact}`)
          .fontSize(20)
        Text(`未读消息: ${this.chatState.unreadCount}`)
          .fontSize(20)

        Row({ space: 10 }) {
          Button('切换聊天').onClick(() => { this.chatState.currentContact = '小红' })
          Button('标记已读').onClick(() => { this.chatState.unreadCount = 0 })
        }

        Button('返回会话列表')
          .onClick(() => { this.pathStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
```

关键点：聊天详情页通过 `connect` 同一个 `ChatState` 获取相同的对象引用，`@Trace` 属性变化双向同步。V2 **没有专用的页面级存储方案**，不提供类似 V1 的 `LocalStorage` + `@LocalStorageLink/@LocalStorageProp` 机制。页面内局部状态（如草稿文本、表情面板开关等）无法通过页面级存储在子组件间自动共享，需要使用父子组件通信（`@Param` + `@Event`）或跨层级通信（`@Provider` + `@Consumer`）等方式手动管理。

---

## 持久化存储UI状态

V1版本状态变量和V2版本状态变量均可实现UI状态持久化。V1使用PersistentStorage持久化AppStorage中的属性，V2使用PersistenceV2持久化@ObservedV2类的@Trace属性。

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 持久化简单类型 | `PersistentStorage.persistProp` / `persistProps` + `@StorageLink` / `@StorageProp` | `PersistenceV2.connect` / `globalConnect` + `@Trace` class 属性 |
| 持久化嵌套对象 | **不支持**（无法检测嵌套对象属性变化） | `@Type` 装饰器标注嵌套 class 类型，确保序列化/反序列化成功 |
| 批量持久化 | `persistProps` 批量声明多个 key | class 中多个 `@Trace` 属性自动持久化 |
| 跨页面共享 | `AppStorage` + `@StorageLink` 跨页面双向同步 | `connect` / `globalConnect` 获取相同引用，跨页面共享 |
| 非观测属性持久化 | `@StorageLink` 可观测 class 属性变化并持久化 | 非 `@Trace` 属性变化不触发自动持久化，需 `save()` 手动持久化 |
| 存储路径 | module 级别（多 module 可能数据不一致） | `connect` module 级别 / `globalConnect` 应用级别（推荐） |
| 支持数据类型 | number, string, boolean, enum, Map, Set, Date | API 23前仅 class 类型；API 23+ 支持集合类型 |
| 调用顺序 | 必须先 `persistProp` 再访问 AppStorage | `connect` / `globalConnect` 自动处理读写顺序 |

---

### V1状态变量实现UI状态持久化

**场景ID：** STATE_SCENE_V1_06

**场景描述：** 仿音乐播放器应用，主播放页面和设置页面共享播放器配置（音量、播放模式、主题色、歌词显示开关），这些配置在应用退出后再次启动时仍然保留。播放模式指示器只读展示当前模式。需要注意 PersistentStorage 的调用顺序和数据大小限制。

**解决方案：** 使用 **`PersistentStorage` + `AppStorage` + `@StorageLink` / `@StorageProp` 实现状态持久化**

```
音乐播放器应用（多页面场景）
├── 应用级（AppStorage + PersistentStorage）：跨页面共享 + 持久化
│   ├── @StorageLink('volume') ──双向──→ 主播放页 + 设置页
│   │     任一页面修改音量 → AppStorage 同步 → PersistentStorage 写磁盘
│   │     重启后从磁盘恢复 → AppStorage → 组件显示上次保存的值
│   │
│   ├── @StorageLink('playMode') ──双向──→ 主播放页 + 设置页
│   │     切换播放模式 → 持久化 → 重启后恢复
│   │
│   ├── @StorageLink('themeColor') ──双向──→ 设置页
│   │     切换主题色 → 持久化 → 重启后恢复
│   │
│   ├── @StorageLink('showLyrics') ──双向──→ 设置页
│   │     切换歌词开关 → 持久化 → 重启后恢复
│   │
│   └── @StorageProp('playMode') ──单向──→ 播放模式指示器（只读）
│         设置页切换模式 → 指示器自动更新，本地修改不回写
│
└── 注意事项
    ├── 必须先 persistProps 再访问 AppStorage（否则丢失上次持久化值）
    └── 持久化数据建议小于 2kb，避免频繁变化的大型数据
```

#### 1.初始化持久化属性

```ts
// 必须在 UI 初始化成功后调用（loadContent 回调中）
// persistProps 批量持久化多个属性
PersistentStorage.persistProps([
  { key: 'volume', defaultValue: 50 },
  { key: 'playMode', defaultValue: 'loop' },
  { key: 'themeColor', defaultValue: '#FF0000' },
  { key: 'showLyrics', defaultValue: true }
])
```

关键点：`persistProps` 可批量声明多个持久化属性。调用时先查询磁盘是否存在对应 key，存在则用磁盘值写入 AppStorage；不存在则用默认值写入 AppStorage 并持久化到磁盘。必须在 UI 初始化成功后（`loadContent` 回调中）调用，早于该时机调用会导致持久化失败。也可使用 `persistProp` 单独持久化单个属性。

#### 2.主播放页面 - @StorageLink 双向同步持久化数据

```ts
@Entry
@Component
struct MusicPlayerPage {
  // @StorageLink 与 AppStorage 建立双向同步
  // 修改会同步回 AppStorage → PersistentStorage 自动写磁盘
  @StorageLink('volume') volume: number = 50
  @StorageLink('playMode') playMode: string = 'loop'
  @StorageLink('themeColor') themeColor: string = '#FF0000'
  @StorageLink('showLyrics') showLyrics: boolean = true
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
        Text('音乐播放器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColor)

        Text(`播放模式: ${this.playMode}  音量: ${this.volume}`)
          .fontSize(18)

        // 播放模式指示器（只读子组件）
        PlayModeIndicator()

        Row({ space: 10 }) {
          Button('音量+10').onClick(() => { this.volume += 10 })
          Button('切换模式').onClick(() => {
            this.playMode = this.playMode === 'loop' ? 'shuffle' : 'loop'
          })
        }

        Button('进入设置页')
          .onClick(() => { this.pageStack.pushPathByName('MusicSettings', null) })
      }
      .padding(20)
    }
  }
}
```

关键点：`@StorageLink` 与 AppStorage 建立双向同步，修改 `volume` 或 `playMode` 后同步回 AppStorage，PersistentStorage 自动将变更写入磁盘。应用退出后再次启动，`persistProps` 从磁盘恢复值写入 AppStorage，组件通过 `@StorageLink` 读取到上次保存的值。

#### 3.播放模式指示器 - @StorageProp 单向同步只读展示

```ts
@Component
struct PlayModeIndicator {
  // @StorageProp 单向同步：AppStorage 变化自动同步，本地修改不回写
  @StorageProp('playMode') playMode: string = 'loop'
  @StorageProp('themeColor') themeColor: string = '#FF0000'

  build() {
    Row() {
      Text(`当前模式: ${this.playMode}`)
        .fontSize(14)
        .fontColor(this.themeColor)
        .fontWeight(FontWeight.Bold)
    }
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}
```

关键点：`@StorageProp` 与 AppStorage 建立单向同步，适合只读展示场景。设置页修改 `playMode` 后，AppStorage 变化自动同步到指示器；但指示器本地修改不会同步回 AppStorage，也不会触发持久化。

#### 4.设置页面 - 多页面共享持久化数据

```ts
@Component
struct MusicSettingsPage {
  // @StorageLink 双向同步：修改后自动持久化，跨页面共享
  @StorageLink('volume') volume: number = 50
  @StorageLink('playMode') playMode: string = 'loop'
  @StorageLink('themeColor') themeColor: string = '#FF0000'
  @StorageLink('showLyrics') showLyrics: boolean = true
  pageStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('播放器设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(`音量: ${this.volume}`)
          .fontSize(18)
        Row({ space: 10 }) {
          Button('音量+10').onClick(() => { this.volume += 10 })
          Button('音量-10').onClick(() => { this.volume -= 10 })
        }

        Text(`播放模式: ${this.playMode}`)
          .fontSize(18)
        Row({ space: 10 }) {
          Button('循环').onClick(() => { this.playMode = 'loop' })
          Button('随机').onClick(() => { this.playMode = 'shuffle' })
          Button('单曲').onClick(() => { this.playMode = 'single' })
        }

        Button('切换主题色')
          .onClick(() => {
            this.themeColor = this.themeColor === '#FF0000' ? '#0000FF' : '#FF0000'
          })

        Button(`歌词显示: ${this.showLyrics ? '开' : '关'}`)
          .onClick(() => { this.showLyrics = !this.showLyrics })

        Button('返回播放页')
          .onClick(() => { this.pageStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
    })
  }
}
```

关键点：设置页面通过 `@StorageLink` 与 AppStorage 双向同步，修改任何设置后自动持久化。主播放页面和设置页面绑定同一 key 的 `@StorageLink`，任一页面修改都会通过 AppStorage 同步到另一页面。应用退出后再次启动，所有设置从磁盘恢复。

#### 5.注意事项 — 调用顺序与数据限制

```ts
// 错误写法：先访问 AppStorage 再持久化，会丢失上次保存的值
let volume = AppStorage.setOrCreate('volume', 50)
PersistentStorage.persistProp('volume', 50)
// AppStorage.setOrCreate 会用 50 覆盖磁盘上的值

// 正确写法：先持久化再按需覆盖
PersistentStorage.persistProps([
  { key: 'volume', defaultValue: 50 },
  { key: 'playMode', defaultValue: 'loop' }
])
// 读取持久化值后，可按需覆盖
if ((AppStorage.get<number>('volume') ?? 0) > 100) {
  // 如果持久化的音量超过100，重置为50
  AppStorage.setOrCreate('volume', 50)
}
```

关键点：必须先调用 `PersistentStorage.persistProp` 或 `persistProps`，再访问 AppStorage，否则会丢失上次的持久化值。持久化数据建议小于 2kb，避免持久化频繁变化的大型数据。PersistentStorage 写入磁盘在 UI 线程同步执行，大量数据本地读写会影响 UI 渲染性能。PersistentStorage 不支持嵌套对象（对象数组、对象的属性是对象等），因为框架无法检测 AppStorage 中嵌套对象值的变化。

---

### V2状态变量实现UI状态持久化

**场景ID：** STATE_SCENE_V2_09

**场景描述：** 仿音乐播放器应用，播放器配置包含嵌套的均衡器设置（低音、高音、声道平衡），需要在应用退出后再次启动时保留。主播放页面和设置页面通过 globalConnect 共享持久化数据，非 @Trace 属性需要手动保存。

**解决方案：** 使用 **`PersistenceV2.connect` / `globalConnect` 实现状态持久化**，配合 **`@Type` 装饰器处理嵌套对象序列化**

```
音乐播放器应用（多页面场景，V2）
├── PlayerConfig(@ObservedV2) ──globalConnect──→ 全局持久化单例
│   ├── @Trace volume, playMode, themeColor, showLyrics → 修改自动持久化
│   ├── @Type(EqualizerSettings) @Trace equalizer → 嵌套对象可序列化/反序列化
│   │     equalizer.bassLevel / trebleLevel / balance → @Trace → 自动持久化
│   └── lastPlayTime → 非 @Trace → 需 PersistenceV2.save() 手动持久化
│
├── @Local config ──connect──→ 主播放页
│     修改音量/模式 → @Trace 变化 → 自动持久化 + 全局同步
│
└── @Local config ──globalConnect──→ 设置页
│     globalConnect 同一个 key → 获取相同引用 → 双向同步 + 自动持久化
│
└── 调用时机：必须在 UI 初始化后（loadContent 回调中）调用 connect/globalConnect
```

#### 1.定义播放配置数据类，使用 @ObservedV2 + @Trace + @Type

```ts
import { PersistenceV2, Type } from '@kit.ArkUI'

@ObservedV2
class EqualizerSettings {
  @Trace public bassLevel: number = 5
  @Trace public trebleLevel: number = 3
  @Trace public balance: number = 0  // -10 到 10 的声道平衡值
}

@ObservedV2
class PlayerConfig {
  @Trace public volume: number = 50
  @Trace public playMode: string = 'loop'
  @Trace public themeColor: string = '#FF0000'
  @Trace public showLyrics: boolean = true
  // 嵌套对象必须用 @Type 修饰，确保序列化/反序列化成功
  @Type(EqualizerSettings)
  @Trace public equalizer: EqualizerSettings = new EqualizerSettings()
  // 非 @Trace 属性：修改不触发自动持久化
  public lastPlayTime: string = ''
}
```

关键点：`@Type` 的参数指定了反序列化时使用的类构造器。如果不加 `@Type`，嵌套对象会被序列化为普通 JSON 对象，反序列化时无法还原为正确的类实例，导致 `equalizer.bassLevel` 等属性访问失败。只有 `@Trace` 装饰的属性变化才会触发自动持久化，非 `@Trace` 属性（如 `lastPlayTime`）变化不会触发 UI 刷新和自动持久化。V1 的 PersistentStorage 不支持嵌套对象持久化，V2 通过 `@Type` 解决了这个问题。

#### 2.主播放页面 - connect 持久化与多页面共享

```ts
@Entry
@ComponentV2
struct V2MusicPlayerPage {
  // connect 在 PersistenceV2 中创建或获取 PlayerConfig 对象
  @Local config: PlayerConfig = PersistenceV2.connect(
    PlayerConfig, () => new PlayerConfig()
  )!
  pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column({ space: 15 }) {
        Text('音乐播放器')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.config.themeColor)

        Text(`播放模式: ${this.config.playMode}  音量: ${this.config.volume}`)
          .fontSize(18)
        Text(`均衡器: 低音${this.config.equalizer.bassLevel} 高音${this.config.equalizer.trebleLevel}`)
          .fontSize(16)

        Row({ space: 10 }) {
          Button('音量+10').onClick(() => { this.config.volume += 10 })
          Button('切换模式').onClick(() => {
            this.config.playMode = this.config.playMode === 'loop' ? 'shuffle' : 'loop'
          })
        }

        Button('进入设置页')
          .onClick(() => { this.pageStack.pushPathByName('V2MusicSettings', null) })
      }
      .padding(20)
    }
  }
}
```

关键点：`PersistenceV2.connect` 创建或从磁盘恢复数据，`@Local` 接收引用。首次启动时 `connect` 使用 `defaultCreator` 创建新实例并持久化；再次启动时从磁盘恢复上次保存的值。修改 `@Trace` 属性（如 `volume`、`playMode`）后自动持久化到磁盘。`connect` 使用 module 级别存储路径，多 module 场景建议使用 `globalConnect`。

#### 3.设置页面 - globalConnect 跨 module 持久化（推荐）+ 非 @Trace 手动保存

```ts
import { contextConstant } from '@kit.AbilityKit'

@ComponentV2
struct V2MusicSettingsPage {
  // globalConnect 使用应用级别存储路径，跨 module 安全（推荐）
  @Local config: PlayerConfig = PersistenceV2.globalConnect({
    type: PlayerConfig,
    key: 'playerConfig',
    defaultCreator: () => new PlayerConfig(),
    areaMode: contextConstant.AreaMode.EL2  // 默认加密级别为 EL2
  })!
  pathStack: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('播放器设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Text(`音量: ${this.config.volume}`)
          .fontSize(18)
        Row({ space: 10 }) {
          Button('音量+10').onClick(() => { this.config.volume += 10 })
          Button('音量-10').onClick(() => { this.config.volume -= 10 })
        }

        Text(`播放模式: ${this.config.playMode}`)
          .fontSize(18)
        Row({ space: 10 }) {
          Button('循环').onClick(() => { this.config.playMode = 'loop' })
          Button('随机').onClick(() => { this.config.playMode = 'shuffle' })
          Button('单曲').onClick(() => { this.config.playMode = 'single' })
        }

        Button('切换主题色')
          .onClick(() => {
            this.config.themeColor = this.config.themeColor === '#FF0000' ? '#0000FF' : '#FF0000'
          })

        Button(`歌词显示: ${this.config.showLyrics ? '开' : '关'}`)
          .onClick(() => { this.config.showLyrics = !this.config.showLyrics })

        // 均衡器设置（嵌套对象，@Type 确保序列化/反序列化成功）
        Text(`低音: ${this.config.equalizer.bassLevel}  高音: ${this.config.equalizer.trebleLevel}`)
          .fontSize(16)
        Row({ space: 10 }) {
          Button('低音+1').onClick(() => { this.config.equalizer.bassLevel += 1 })
          Button('高音+1').onClick(() => { this.config.equalizer.trebleLevel += 1 })
        }

        // 非 @Trace 属性需要手动 save 持久化
        Button('记录播放时间')
          .onClick(() => {
            this.config.lastPlayTime = new Date().toLocaleTimeString()
            // 非 @Trace 属性需要手动调用 save 持久化
            PersistenceV2.save(PlayerConfig)
          })

        Text(`所有持久化key: ${PersistenceV2.keys()}`)
          .fontSize(14)
          .fontColor(Color.Gray)

        Button('返回播放页')
          .onClick(() => { this.pathStack.pop() })
      }
      .padding(20)
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
```

关键点：

(1) `globalConnect` 使用应用级别存储路径，避免 `connect` 的 module 级别路径在多 module 场景下数据不一致的问题。推荐使用 `globalConnect` 替代 `connect`。支持设置加密级别（`areaMode`），默认为 EL2，可设置为 EL1-EL5。

(2) 嵌套对象 `equalizer` 通过 `@Type(EqualizerSettings)` 标注后，可正确序列化/反序列化。修改 `equalizer.bassLevel` 或 `trebleLevel` 时，由于它们是 `@Trace` 属性，自动触发整个 `PlayerConfig` 对象的持久化。

(3) 非 `@Trace` 属性 `lastPlayTime` 修改后不会触发自动持久化，需要调用 `PersistenceV2.save(PlayerConfig)` 手动持久化。也可使用 `PersistenceV2.save('playerConfig')` 指定 key 手动持久化。

(4) `PersistenceV2.keys()` 返回所有 PersistenceV2 中的 key，包括 module 级别和应用级别存储路径中的所有 key。

(5) 两个页面通过 `globalConnect` 同一个 key `'playerConfig'` 获取相同的 `PlayerConfig` 对象引用，`@Trace` 属性变化双向同步且自动持久化。应用退出后再次启动，所有 `@Trace` 属性的值从磁盘恢复。

#### 4.@Type 使用说明

| 场景 | 是否需要 @Type | 说明 |
|------|---------------|------|
| 属性为基本类型（number, string, boolean） | 不需要 | 自动序列化 |
| 属性为自定义 class 类型 | **必须** | 反序列化时需要 `@Type` 指定构造器 |
| 属性为 Array、Map、Set、Date | 不需要（API 23+） | 内置类型自动处理 |
| 属性为嵌套的自定义 class | **必须** | 每层 class 属性都需要 `@Type` |

```ts
// 正确用法：嵌套对象逐层标注 @Type
@ObservedV2
class EqualizerSettings {
  @Trace public bassLevel: number = 5
}

@ObservedV2
class PlayerConfig {
  @Type(EqualizerSettings)
  @Trace public equalizer: EqualizerSettings = new EqualizerSettings()
}
```

关键点：`@Type` 与 `@Trace` 配合使用，`@Type` 确保序列化/反序列化正确，`@Trace` 确保属性变化可观测且自动持久化。`@Type` 只能用在 `@ObservedV2` 装饰的类中，不能用在自定义组件或 `@Observed` 装饰的类中。不支持简单类型（string、number、boolean）和构造函数含参的类。