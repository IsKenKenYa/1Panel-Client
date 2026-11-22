# 状态管理 V1 & V2 混用场景

## 简介

在API version 19之前，混用场景有相对严格的校验。从API version 19开始，减少了对状态管理V1和V2混用场景的约束，同时提供新的方法enableV2Compatibility和makeV1Observed来帮助解决混用问题。

在未明确要求混用V1和V2状态变量时，禁止自我决策和推断使用混用方案，优先采用迁移的方案。

> **说明：**
> 本文使用"→"表示变量的传递，如"V1→V2"，表示V1状态变量向V2状态变量传递。

## 目录

1. [V1中使用V2的自定义组件](#V1中使用V2的自定义组件)
   - 1.1 [V1中使用V2组件-API19前](#V1中使用V2组件-API19前)
   - 1.2 [V1中使用V2组件 - API19及以后](#V1中使用V2组件-API19及以后)

2. [V2中使用V1的自定义组件](#V2中使用V1的自定义组件)
   - 2.1 [V2中使用V1组件-API19前](#V2中使用V1组件-API19前)
   - 2.2 [V2中使用V1组件 API19及以后](#V2中使用V1组件-API19及以后)

---

## V1中使用V2的自定义组件

**API19前后对比**

| 能力 | API19前 | API19及以后 |
|------|---------|-------------|
| V1→V2简单类型 | `@Param`直接接收 | `@Param`直接接收（不变） |
| V1→V2普通class | 编译报错，需桥接组件 | `enableV2Compatibility`直接传递，可观察第一层 |
| V1→V2 @Observed+@Track class | 编译报错，需桥接组件 | `enableV2Compatibility`直接传递（无需`makeV1Observed`） |
| V1→V2内置类型(Array) | 编译报错，仅普通变量传递 | `makeV1Observed`+`enableV2Compatibility` |
| V1→V2二维数组 | 编译报错 | `makeV1Observed`逐层包装内层+`enableV2Compatibility` |
| V1→V2嵌套类型 | 仅@ObjectLink拆分 | `makeV1Observed`逐层包装+`enableV2Compatibility`深度观测+`@ObjectLink`拆分 |
| 新增接口 | 无 | `enableV2Compatibility`、`makeV1Observed` |
| 双重代理问题 | 不使用接口不存在此问题 | 不使用接口会产生双重代理，必须配合使用 |

### V1中使用V2组件-API19前

**场景ID：** STATE_MIXED_V1V2_01

**场景描述：** 电商商品详情页中，V1父组件管理商品信息（商品名、评分、作者详情、商品标签），需要嵌入多个V2子组件展示不同维度的信息。由于API19前V1→V2传递数据存在类型限制，需针对不同数据类型采用不同的适配方案：简单类型直接传递、@ObservedV2类作为普通变量传递、@Observed类通过桥接组件中转、嵌套对象通过@ObjectLink拆分、内置类型只能去掉装饰器作为普通变量传递。

**解决方案：** API19前V1→V2仅支持简单类型（boolean、number、string、null、undefined）直接传递给@Param；@ObservedV2+@Trace装饰的class需去掉V1装饰器作为普通变量传递给@Param；@Observed装饰的class需通过桥接组件模式中转（V1 @Watch → V2 @ObservedV2单例 → V2组件使用单例）；嵌套对象通过@ObjectLink拆分子组件，内层@ObservedV2+@Trace对象传递给V2 @Param实现深度观测；内置类型（Array、Map、Set、Date）去掉V1装饰器作为普通变量传递，V2无法观测变化。

```
V1父组件 @State / 普通变量
  ├── 不传递变量 ──→ V2 ProductStatusBadge（无限制）
  │     V1中使用V2组件不传递变量时无任何限制
  │
  ├── 简单类型(productName, rating) ──(@Param)──→ V2 ProductRatingView
  │     仅支持 boolean/number/string/null/undefined
  │     @State等V1装饰器装饰的class类型和内置类型会编译报错
  │
  ├── @ObservedV2+@Trace(AuthorDetail) ──(普通变量)──→ V2 AuthorDetailView(@Param)
  │     V1中不能用@State装饰，需作为普通变量
  │     @Trace属性变化可被V2 @Param深度观测
  │
  ├── @Observed(ProductModelV1) ──(桥接组件)──→ V2 ProductModelV2 单例
  │     三步：定义V2单例 → @Watch监听同步 → V2组件使用单例
  │     不能直接用@Param接收@Observed的class
  │
  ├── 嵌套对象(ProductInfo.author) ──(@ObjectLink拆分)──→ V2 AuthorV2View(@Param)
  │     @State仅观察第一层 → @ObjectLink观察内层
  │     @Param深度观测内层@Trace属性，@ObjectLink和@Param引用同一对象
  │
  └── 内置类型(Array<number> ratings) ──(普通变量)──→ V2 ProductRatingListV2(@Param)
        API19前编译报错，去掉@State后传递
        V2无法观测变化（push/修改数组项不触发刷新）
```

#### 1.定义数据类 — 商品信息、作者详情与标签列表

```ts
// 商品主信息：@Observed装饰，用于V1组件和嵌套对象场景
@Observed
class ProductInfo {
  @Track public productName: string = '智能手机Pro'   // 商品名
  @Track public rating: number = 4.5                  // 评分
  @Track public author: AuthorDetail = new AuthorDetail() // 内层嵌套作者详情
}

// 作者详情：@ObservedV2+@Trace装饰，用于V2深度观测场景
@ObservedV2
class AuthorDetail {
  @Trace public authorName: string = '李明'        // 作者名
  @Trace public authorLevel: number = 5             // 影响力指数
  public biography: string = '资深数码博主'          // 非@Trace，无法观测
}

// 桥接模式V1侧：@Observed装饰，用于桥接组件中的V1数据源
@Observed
class ProductModelV1 {
  @Track public productName: string = '智能手机Pro'
  @Track public rating: number = 4.5

  constructor(productName: string, rating: number) {
    this.productName = productName
    this.rating = rating
  }
}

// 桥接模式V2侧：@ObservedV2单例，用于桥接组件中的V2接收端
@ObservedV2
class ProductModelV2 {
  private static singleton_: ProductModelV2
  @Trace public productName: string = ''
  @Trace public rating: number = 0

  private constructor() {}

  static instance(): ProductModelV2 {
    if (!ProductModelV2.singleton_) {
      ProductModelV2.singleton_ = new ProductModelV2()
    }
    return ProductModelV2.singleton_
  }
}
```

关键点：`ProductInfo`使用`@Observed`+`@Track`装饰，适配V1观测体系；`AuthorDetail`使用`@ObservedV2`+`@Trace`装饰，适配V2深度观测能力。`ProductModelV1`是桥接模式的V1数据源，`ProductModelV2`是桥接模式的V2单例接收端。两种装饰器体系不能混用：V1装饰器（`@State`等）不能和`@ObservedV2`一起使用（编译报错），V2装饰器（`@Local`等）不能和`@Observed`一起使用（编译报错）。

#### 2.不传递变量与传递简单类型 — V2状态徽章组件与评分展示

```ts
// V2组件：不传递变量时无限制，可独立管理内部状态
@ComponentV2
struct ProductStatusBadge {
  @Local status: string = '在售'

  build() {
    Text(`商品状态: ${this.status}`)
      .fontSize(16)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.status === '在售' ? '#4CAF50' : '#F44336')
      .fontColor(Color.White)
      .borderRadius(12)
      .onClick(() => {
        this.status = this.status === '在售' ? '缺货' : '在售'
      })
  }
}

// V2组件：接收V1传递的简单类型状态变量
@ComponentV2
struct ProductRatingView {
  @Param productName: string = ''
  @Param rating: number = 0

  build() {
    Column() {
      Text(`V2商品: ${this.productName}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Row() {
        Text(`V2评分: ${this.rating}`)
          .fontSize(18)
          .fontColor('#FF9800')
        Text('/ 5.0')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

// V1父组件：使用V2子组件展示状态徽章和评分
@Entry
@Component
struct ProductDetailPageV1Simple {
  @State productName: string = '智能手机Pro'
  @State rating: number = 4.5

  build() {
    Column({ space: 15 }) {
      Text(`商品详情页`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // 不传递变量：V1中使用V2组件无任何限制
      ProductStatusBadge()

      // 传递简单类型：V1 @State → V2 @Param，可直接传递
      ProductRatingView({ productName: this.productName, rating: this.rating })

      // 父组件修改简单类型，V2子组件同步更新
      Row({ space: 10 }) {
        Button('修改评分').onClick(() => { this.rating++ })
        Button('改名').onClick(() => { this.productName = '旗舰手机Max' })
      }
    }
    .padding(20)
  }
}
```

关键点：V1中使用V2组件不传递变量时，无任何限制，包括导入第三方的`@ComponentV2`装饰的组件。传递简单类型状态变量（boolean、number、string、null、undefined）时，V2使用`@Param`接收即可。但API19前，传递`@State`装饰的class类型或内置类型（Array、Map、Set、Date）会导致编译报错；`@Prop`、`@Link`、`@ObjectLink`、`@Provide`、`@Consume`等V1装饰器的行为与`@State`一致。

#### 3.传递@ObservedV2+@Trace装饰的class — 作者详情作为普通变量传递

`@ObservedV2`+`@Trace`的观测能力独立于V1/V2装饰器，在V1和V2中均受支持。但在V1中不能与V1装饰器（如`@State`）一起使用，需作为普通变量传递给V2的`@Param`。

```ts
// AuthorDetail已在步骤1中定义（@ObservedV2 + @Trace）

// V2组件：接收@ObservedV2+@Trace装饰的class，@Param深度观测@Trace属性变化
@ComponentV2
struct AuthorDetailView {
  @Param author: AuthorDetail = new AuthorDetail()

  build() {
    Column() {
      Text(`V2作者: ${this.author.authorName}`)
        .fontSize(18)
        .onClick(() => { this.author.authorName += '!' }) // @Trace可观测，触发刷新
      Text(`V2影响力: ${this.author.authorLevel}`)
        .fontSize(16)
        .onClick(() => { this.author.authorLevel++ }) // @Trace可观测，触发刷新
      // biography未被@Trace装饰，修改不触发刷新
      Text(`简介: ${this.author.biography}`)
        .fontSize(14)
        .onClick(() => { this.author.biography += '!' }) // 不触发刷新
    }
    .padding(10)
    .backgroundColor('#e3f2fd')
    .borderRadius(8)
  }
}

// V1父组件：@ObservedV2+@Trace的class需作为普通变量传递
@Entry
@Component
struct ProductDetailPageV1ObservedV2 {
  // @State author: AuthorDetail = new AuthorDetail()  // 编译报错！V1装饰器不能和@ObservedV2一起使用
  author: AuthorDetail = new AuthorDetail()  // 正确：作为普通变量传递

  build() {
    Column({ space: 15 }) {
      Text(`商品详情页 - 作者信息`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // V1中作为普通变量，@Trace属性变化可观测（依赖@ObservedV2+@Trace自身能力）
      Text(`V1父组件作者: ${this.author.authorName}`)
        .fontSize(20)
        .onClick(() => { this.author.authorName += '!' })

      // 传递给V2的@Param，@Trace属性变化可被深度观测
      AuthorDetailView({ author: this.author })

      Button('修改作者名').onClick(() => {
        this.author.authorName = '王芳'  // V1和V2组件都刷新
      })
    }
    .padding(20)
  }
}
```

关键点：V1装饰器（`@State`等）不能和`@ObservedV2`一起使用（编译报错），需去掉V1装饰器作为普通变量。`@ObservedV2`+`@Trace`的观测能力独立于V1/V2装饰器，在V1中作为普通变量使用时，`@Trace`属性变化仍可触发UI刷新。传递给V2的`@Param`后，`@Trace`属性变化可被V2深度观测。

#### 4.传递@Observed装饰的class — 桥接组件模式中转

V1传递`@Observed`装饰的class给V2时，不能直接用`@Param`接收。需要通过桥接组件模式：V1桥接组件用`@Watch`监听数据变化，将数据同步到V2的`@ObservedV2`单例，V2组件直接使用单例实例。

```ts
// ProductModelV1 和 ProductModelV2 已在步骤1中定义

// V1桥接组件：监听V1数据变化，同步到V2单例
@Component
struct ProductBridgeComponent {
  @State @Watch('onProductChange') productV1: ProductModelV1 = new ProductModelV1('智能手机Pro', 4.5)

  onProductChange() {
    // 将V1的数据同步到V2单例
    ProductModelV2.instance().productName = this.productV1.productName
    ProductModelV2.instance().rating = this.productV1.rating
  }

  build() {
    Column({ space: 15 }) {
      Text(`V1原始数据: ${this.productV1.productName} - 评分${this.productV1.rating}`)
        .fontSize(18)

      Button('V1修改商品名').onClick(() => {
        this.productV1.productName = '旗舰手机Max' // 触发@Watch → V2单例更新 → V2组件刷新
      })

      Button('V1修改评分').onClick(() => {
        this.productV1.rating = 5.0 // 触发@Watch → V2单例更新 → V2组件刷新
      })

      // V2业务组件使用单例数据
      ProductV2Comp()
    }
    .padding(20)
  }
}

// V2业务组件：直接使用V2单例实例
@ComponentV2
struct ProductV2Comp {
  private v2Model: ProductModelV2 = ProductModelV2.instance()

  build() {
    Column() {
      Text(`V2组件: ${this.v2Model.productName} - 评分${this.v2Model.rating}`)
        .fontSize(18)

      Button('V2修改评分').onClick(() => {
        this.v2Model.rating = 5.0 // V2组件刷新（@Trace可观测）
      })
    }
    .padding(10)
    .backgroundColor('#e8f5e9')
    .borderRadius(8)
  }
}

// V1入口组件
@Entry
@Component
struct ProductDetailPageV1Bridge {
  build() {
    Column({ space: 15 }) {
      Text(`商品详情页 - 桥接模式`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // V1组件直接引入桥接组件
      ProductBridgeComponent()
    }
    .padding(20)
  }
}
```

关键点：API19前V1传递`@Observed`装饰的class给V2时，需通过桥接组件模式中转，分三步：1）定义V2单例ViewModel（`@ObservedV2`+`@Trace`），私有构造器确保单例；2）V1桥接组件用`@Watch`监听V1数据变化，将数据赋值给V2单例属性；3）V2业务组件直接使用V2单例实例，`@Trace`属性变化可观测。数据流向：V1修改数据 → 桥接组件`@Watch`触发 → V2单例属性赋值 → V2组件刷新。

#### 5.传递嵌套对象 — @ObjectLink拆分配合@ObservedV2+@Trace

嵌套对象场景中，V1的`@State`只能观察第一层变化，深层变化需通过`@ObjectLink`拆分子组件。内层`@ObservedV2`+`@Trace`对象传递给V2的`@Param`可被深度观测。

```ts
// ProductInfo(@Observed) 和 AuthorDetail(@ObservedV2) 已在步骤1中定义

// V2组件：接收内层@ObservedV2+@Trace对象，@Param深度观测@Trace属性变化
@ComponentV2
struct AuthorV2View {
  @Param author: AuthorDetail = new AuthorDetail()

  build() {
    Column() {
      Text(`V2-作者: ${this.author.authorName}`)
        .fontSize(18)
        .onClick(() => { this.author.authorName += '!' })  // @Trace可观测，触发刷新
      Text(`V2-影响力: ${this.author.authorLevel}`)
        .fontSize(16)
        .onClick(() => { this.author.authorLevel++ })  // @Trace可观测，触发刷新
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

// V1组件：@ObjectLink拆分，观察内层属性变化
@Component
struct ProductV1DetailView {
  @ObjectLink product: ProductInfo

  build() {
    Column() {
      Text(`V1-商品名: ${this.product.productName}`)
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })
      Text(`V1-评分: ${this.product.rating}`)
        .fontSize(16)
        .onClick(() => { this.product.rating++ })

      // 将内层@ObservedV2对象传递给V2组件，@Param深度观测
      AuthorV2View({ author: this.product.author })
    }
    .padding(10)
    .backgroundColor('#e3f2fd')
    .borderRadius(8)
  }
}

// V1父组件：@State仅观察第一层，深层变化需@ObjectLink拆分
@Entry
@Component
struct ProductDetailPageV1Nested {
  @State product: ProductInfo = new ProductInfo()

  build() {
    Column({ space: 15 }) {
      Text(`商品详情页 - 嵌套对象`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      // @State只能观察第一层变化：productName整体赋值可刷新此处
      // author.authorName变化不刷新此处（第二层）
      Text(`父组件-商品名: ${this.product.productName}`)
        .fontSize(20)

      // 通过@ObjectLink拆分，可观察内层变化
      ProductV1DetailView({ product: this.product })

      Button('修改作者名').onClick(() => {
        this.product.author.authorName += '!'
        // @State不刷新父组件此处，但@ObjectLink和@Param可观测并刷新子组件
      })

      Button('修改商品名').onClick(() => {
        this.product.productName += '!'
        // @State可观察第一层，父组件和@ObjectLink子组件都刷新
      })
    }
    .padding(20)
  }
}
```

关键点：嵌套对象场景中，`@State`仅能观察第一层变化（如`product.productName`），深层变化（如`product.author.authorName`）需通过`@ObjectLink`拆分子组件来观测。内层`@ObservedV2`+`@Trace`对象（`AuthorDetail`）传递给V2的`@Param`后可被深度观测。`@ObjectLink`和`@Param`引用同一对象，修改会互相刷新——V1组件修改`author.authorName`，V2的`AuthorV2View`也会刷新；V2组件修改`author.authorName`，V1的`ProductV1DetailView`也会刷新。

#### 6.传递内置类型 — API19前不支持

API19前，V1→V2传递内置类型（Array、Map、Set、Date）的状态变量会导致编译报错。只能去掉V1装饰器作为普通变量传递，但V2中无法观测其变化。

```ts
// V2组件：接收普通变量传递的内置类型，无法观测变化
@ComponentV2
struct ProductRatingListV2 {
  @Param ratings: Array<number> = []

  build() {
    Column() {
      Text('历史评分列表（V2组件）')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      ForEach(this.ratings, (item: number, index: number) => {
        Text(`评分${index + 1}: ${item} ⭐`)
          .fontSize(14)
      })
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}

// V1父组件：内置类型只能去掉@State作为普通变量传递
@Entry
@Component
struct ProductDetailPageV1BuiltIn {
  @State productName: string = '智能手机Pro'
  // @State ratings: Array<number> = [4.5, 4.0, 5.0]  // 编译报错！API19前内置类型不支持传递给V2
  ratings: Array<number> = [4.5, 4.0, 5.0]  // 正确：去掉@State作为普通变量

  build() {
    Column({ space: 15 }) {
      Text(`商品详情页 - 内置类型`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(`商品: ${this.productName}`)
        .fontSize(20)

      // 作为普通变量传递给V2，V2无法观测ratings的变化
      ProductRatingListV2({ ratings: this.ratings })

      // 以下操作不会触发V2组件刷新（ratings是普通变量，无观测能力）
      Row({ space: 10 }) {
        Button('新增评分').onClick(() => {
          this.ratings.push(4.8)
          // V2组件不会刷新，因为ratings不是状态变量
        })
        Button('修改第一项').onClick(() => {
          this.ratings[0]++
          // V2组件不会刷新
        })
      }
    }
    .padding(20)
  }
}
```

关键点：API19前，V1→V2传递内置类型（Array、Map、Set、Date）的状态变量会导致编译报错。只能去掉V1装饰器（如`@State`）作为普通变量传递给V2的`@Param`，但V2中无法观测其内部变化（push、修改数组项等操作不会触发V2组件刷新）。如需观测内置类型变化，需等到API19及以后使用`makeV1Observed`+`enableV2Compatibility`。

#### 数据流向总结

```
V1父组件 @State / 普通变量
  ├── 不传递变量 ──→ V2 ProductStatusBadge（无限制）
  │     V1中使用V2组件不传递变量时无任何限制
  │
  ├── 简单类型(productName, rating) ──(@Param)──→ V2 ProductRatingView
  │     仅支持 boolean/number/string/null/undefined
  │     @State等V1装饰器装饰的class类型和内置类型会编译报错
  │
  ├── @ObservedV2+@Trace(AuthorDetail) ──(普通变量)──→ V2 AuthorDetailView(@Param)
  │     V1中不能用@State装饰，需作为普通变量
  │     @Trace属性变化可被V2 @Param深度观测
  │
  ├── @Observed(ProductModelV1) ──(桥接组件)──→ V2 ProductModelV2 单例
  │     三步：定义V2单例 → @Watch监听同步 → V2组件使用单例
  │     不能直接用@Param接收@Observed的class
  │
  ├── 嵌套对象(ProductInfo.author) ──(@ObjectLink拆分)──→ V2 AuthorV2View(@Param)
  │     @State仅观察第一层 → @ObjectLink观察内层
  │     @Param深度观测内层@Trace属性，@ObjectLink和@Param引用同一对象
  │
  └── 内置类型(Array<number> ratings) ──(普通变量)──→ V2 ProductRatingListV2(@Param)
        API19前编译报错，去掉@State后传递
        V2无法观测变化（push/修改数组项不触发刷新）
```

---

### V1中使用V2组件-API19及以后

**场景ID：** STATE_MIXED_V1V2_02

**场景描述：** 电商商品详情页，V1父组件管理商品信息（商品名、评分、作者详情、标签组），需要使用V2子组件展示商品详情和作者信息。与API19前相同场景，但API19后通过`enableV2Compatibility`和`makeV1Observed`简化了V1→V2的数据传递，无需桥接组件。

**解决方案：** 使用 **`enableV2Compatibility`使V1状态变量在V2中可观察** + **`makeV1Observed`将普通对象包装为V1可观察对象**，直接传递给V2的`@Param`，无需桥接组件模式中转。

> **说明：**
> 从API version 19开始，开发者可以使用`UIUtils.enableV2Compatibility`和`UIUtils.makeV1Observed`接口解决V1→V2混用问题。`enableV2Compatibility`使V1状态变量兼容V2观察能力；`makeV1Observed`将不可观察的对象包装为V1可观察对象，其返回值可初始化`@ObjectLink`。

```
V1父组件 @State
  ├── ProductClass(普通class) ──(enableV2Compatibility)──→ V2 @Param（可观察第一层）
  │     建议在V2组件构造处调用: SubCompV2({param: UIUtils.enableV2Compatibility(this.product)})
  │
  ├── ProductObservedClass(@Observed+@Track) ──(enableV2Compatibility)──→ V2 @Param（无需makeV1Observed）
  │     @Track属性V1/V2均可观察，非@Track属性V1 UI运行时报错、V2不报错但不响应更新
  │
  ├── ratings(Array<number>) ──(makeV1Observed+enableV2Compatibility)──→ V2 @Param
  │     makeV1Observed包装为V1状态变量 → enableV2Compatibility使V2可观察 → 避免双重代理
  │
  ├── tagGroups(Array<Array<string>>) ──(makeV1Observed逐层+enableV2Compatibility)──→ V2 @Param
  │     内层数组逐层makeV1Observed → ForEach中enableV2Compatibility → 新增需makeV1Observed包装
  │
  └── ProductDetail(嵌套class) ──(makeV1Observed逐层+enableV2Compatibility)──→ V2 @Param + V1 @ObjectLink
        逐层makeV1Observed保证每层都是V1状态变量 → enableV2Compatibility深度观测
        @State仅观察第一层 → @ObjectLink拆分观察内层 → @Param深度观测
        新增数据需makeV1Observed包装
```

#### 1.定义数据类 — 商品信息、评分项、作者详情与标签组

在电商商品详情页场景中，需要定义五种数据类，覆盖普通class、@Observed+@Track装饰的class、内置类型、二维数组和嵌套类型的传递场景。

```ts
import { UIUtils } from '@kit.ArkUI'

// 知识点1：普通class，无任何装饰器
class ProductClass {
  public productName: string = '智能手机Pro'
  public rating: number = 4.5
  public price: number = 3999
}

// 知识点2：@Observed+@Track装饰的class
@Observed
class ProductObservedClass {
  @Track public productName: string = '智能手机Pro'
  @Track public rating: number = 4.5
  public commentCount: number = 0 // 非@Track属性
}

// 知识点5嵌套类型：评分项（最内层普通class）
class RatingItem {
  public value: number = 0
  constructor(value: number) {
    this.value = value
  }
}

// 知识点5嵌套类型：作者详情（中间层普通class，包含RatingItem数组）
class AuthorDetail {
  public authorName: string = '李明'
  public ratings: Array<RatingItem>
  constructor(ratings: Array<RatingItem>) {
    this.ratings = ratings
  }
}

// 知识点5嵌套类型：商品详情（外层class，包含@Track属性和嵌套AuthorDetail）
class ProductDetail {
  @Track public productName: string = '智能手机Pro'
  @Track public author: AuthorDetail
  constructor(author: AuthorDetail) {
    this.author = author
  }
}
```

关键点：数据类设计覆盖了五种传递场景：(1)`ProductClass`为普通class无任何装饰器；(2)`ProductObservedClass`使用`@Observed`+`@Track`装饰；(3)内置类型`Array<number>`无需定义数据类；(4)二维数组`Array<Array<string>>`无需定义数据类；(5)嵌套类型`ProductDetail`包含`AuthorDetail`包含`RatingItem[]`，三层嵌套结构展示逐层包装的必要性。

#### 2.传递普通class — enableV2Compatibility使V2可观察

V1的`@State`装饰的普通class传递给V2时，调用`enableV2Compatibility`使V1状态变量在V2的`@Param`中可观察第一层属性变化，无需桥接组件。

```ts
import { UIUtils } from '@kit.ArkUI'

class ProductClass {
  public productName: string = '智能手机Pro'
  public rating: number = 4.5
  public price: number = 3999
}

// V2子组件：接收普通class
@ComponentV2
struct ProductV2DetailView {
  @Param product: ProductClass = new ProductClass()

  build() {
    Column() {
      // enableV2Compatibility使V1状态变量在V2中可观察第一层属性变化
      Text(`V2商品: ${this.product.productName} - 评分${this.product.rating} - ¥${this.product.price}`)
        .fontSize(18)
        .onClick(() => {
          // V1状态变量在V2中可观察，修改第一层属性可触发刷新
          this.product.productName += '!'
        })
    }
  }
}

// V1父组件：使用@State管理普通class
@Entry
@Component
struct ProductDetailPageV1Api19 {
  @State product: ProductClass = new ProductClass()

  build() {
    Column({ space: 15 }) {
      // V1中@State可观察第一层属性变化
      Text(`V1商品: ${this.product.productName} - 评分${this.product.rating}`)
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

      // 调用enableV2Compatibility使V1状态变量在V2中有观察能力
      // 建议在V2组件构造处调用，而非@State初始化时调用
      ProductV2DetailView({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

关键点：`enableV2Compatibility`使V1的`@State`变量在V2的`@Param`中可观察第一层属性变化。建议在V2组件构造处调用`enableV2Compatibility`（如`SubCompV2({param: UIUtils.enableV2Compatibility(this.state)})`），而非在`@State`初始化时调用，避免变量整体赋值时需再次手动调用。

#### 3.传递@Observed+@Track装饰的class — enableV2Compatibility无需makeV1Observed

`@Observed`装饰的class传递给V2时，使用`enableV2Compatibility`即可（无需`makeV1Observed`）。`@Track`属性在V1和V2中均可观察；非`@Track`属性在V1的UI中使用会运行时报错，在V2中不报错但不响应更新。

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProductObservedClass {
  @Track public productName: string = '智能手机Pro'
  @Track public rating: number = 4.5
  public commentCount: number = 0 // 非@Track属性
}

// V2子组件：接收@Observed+@Track装饰的class
@ComponentV2
struct ProductV2ObservedView {
  @Param product: ProductObservedClass = new ProductObservedClass()

  build() {
    Column() {
      // @Track属性在V2中可观察，修改可触发刷新
      Text(`V2书名: ${this.product.productName} - 评分${this.product.rating}`)
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })

      // 非@Track属性在V2中不会崩溃，但不响应更新
      Text(`评论数: ${this.product.commentCount}`)
        .fontSize(16)
        .onClick(() => { this.product.commentCount++ }) // 不触发刷新
    }
  }
}

// V1父组件：使用@State管理@Observed+@Track装饰的class
@Entry
@Component
struct ProductDetailPageV1ObservedApi19 {
  @State product: ProductObservedClass = new ProductObservedClass()

  build() {
    Column({ space: 15 }) {
      // V1中：@Track属性可观察，非@Track属性在UI中运行时报错
      Text(`V1商品: ${this.product.productName} - 评分${this.product.rating}`)
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

      // @Observed装饰的class，直接enableV2Compatibility即可，无需makeV1Observed
      ProductV2ObservedView({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

关键点：`@Observed`装饰的class无需再调用`makeV1Observed`，直接`enableV2Compatibility`即可。`@Track`属性在V1和V2中均可观察。非`@Track`属性：V1中UI使用运行时报错，V2中不报错但不响应更新。

#### 4.传递内置类型(Array) — makeV1Observed + enableV2Compatibility

V1向V2传递内置类型（Array）时，使用`makeV1Observed`将Array包装为V1状态变量，再`enableV2Compatibility`使V2可观察，避免双重代理问题。

```ts
import { UIUtils } from '@kit.ArkUI'

// V2子组件：接收Array类型
@ComponentV2
struct ProductRatingV2View {
  @Param ratings: Array<number> = [0]

  build() {
    Column() {
      // V2中可观察Array内部元素变化
      Text(`V2第一个评分: ${this.ratings[0]}`)
        .fontSize(18)
        .onClick(() => {
          // 修改触发V1和V2变化
          this.ratings[0]++
        })

      Button('V2新增评分').onClick(() => {
        this.ratings.push(4.8)
      })
    }
  }
}

// V1父组件：使用@State管理Array，makeV1Observed包装为V1状态变量
@Entry
@Component
struct ProductRatingPageV1Api19 {
  // makeV1Observed将Array包装为V1状态变量，其返回值可初始化@ObjectLink
  @State ratings: Array<number> = UIUtils.makeV1Observed([4.5, 4.0, 5.0])

  build() {
    Column({ space: 15 }) {
      Text(`V1第一个评分: ${this.ratings[0]}`)
        .fontSize(20)
        .onClick(() => { this.ratings[0]++ })

      // 传递给V2时，调用enableV2Compatibility避免双重代理
      ProductRatingV2View({ ratings: UIUtils.enableV2Compatibility(this.ratings) })
    }
    .padding(20)
  }
}
```

关键点：使用`makeV1Observed`将Array包装为V1状态变量，其返回值可初始化`@ObjectLink`。再`enableV2Compatibility`使V2可观察，避免双重代理。不使用`enableV2Compatibility`和`makeV1Observed`会导致双重代理问题，使同一状态对象被V1和V2两套状态管理体系同时生成代理对象，引起监听逻辑冲突。

#### 5.传递二维数组 — makeV1Observed逐层包装 + enableV2Compatibility

二维数组需用`makeV1Observed`将内层数组逐层包装为V1状态变量，传递给V2时调用`enableV2Compatibility`避免双重代理，新增数组元素需`makeV1Observed`包装。

```ts
import { UIUtils } from '@kit.ArkUI'

// V2子组件：接收一维数组（二维数组的内层）
@ComponentV2
struct ProductTagItem {
  @Require @Param tagArr: Array<string>

  build() {
    Row() {
      ForEach(this.tagArr, (item: string, index: number) => {
        Text(`${index}: ${item}  `)
          .fontSize(16)
      })
      Button('@Param新增标签').onClick(() => {
        // V2中可观察数组变化
        this.tagArr.push('新标签')
      })
    }
    .padding(8)
    .backgroundColor('#f0f0f0')
    .borderRadius(4)
  }
}

// V1父组件：使用@State管理二维数组，内层数组逐层makeV1Observed包装
@Entry
@Component
struct ProductTagPageV1Api19 {
  // makeV1Observed逐层包装内层数组为V1状态变量
  @State tagGroups: Array<Array<string>> = [
    UIUtils.makeV1Observed(['技术', '编程']),
    UIUtils.makeV1Observed(['畅销', '热门']),
    UIUtils.makeV1Observed(['推荐', '入门'])
  ]

  build() {
    Column({ space: 15 }) {
      Text(`标签组数量: ${this.tagGroups.length}`)
        .fontSize(20)

      // ForEach遍历二维数组，内层数组传递给V2时调用enableV2Compatibility
      ForEach(this.tagGroups, (tagArr: Array<string>) => {
        ProductTagItem({ tagArr: UIUtils.enableV2Compatibility(tagArr) })
      })

      // 新增数组元素需用makeV1Observed包装
      Button('@State新增标签组').onClick(() => {
        // 新增的内层数组必须用makeV1Observed包装，确保V2可观察
        this.tagGroups.push(UIUtils.makeV1Observed(['新品', '首发']))
      })

      Button('@State修改第一个标签').onClick(() => {
        // 修改内层数组元素，V1和V2均可观察
        this.tagGroups[0][0] = 'TECH'
      })
    }
    .padding(20)
  }
}
```

关键点：二维数组场景需用`makeV1Observed`包装内层数组为V1状态变量，传递给V2时在ForEach中调用`enableV2Compatibility`避免双重代理。`makeV1Observed`不会递归执行，仅包装第一层，因此内层数组需逐层手动包装。新增数组元素必须用`makeV1Observed`包装以确保V2可观察。

#### 6.传递嵌套类型 — makeV1Observed逐层包装 + enableV2Compatibility深度观测

嵌套类型需保证每一层都是V1的状态变量（`makeV1Observed`逐层包装），传递给V2时调用`enableV2Compatibility`实现深度观测。`@State`仅能观察第一层变化，深层需`@ObjectLink`拆分或`@Param`配合`enableV2Compatibility`深度观测。新增数据需`makeV1Observed`包装。

```ts
import { UIUtils } from '@kit.ArkUI'

// RatingItem、AuthorDetail、ProductDetail已在步骤1中定义

// V1子组件：@ObjectLink拆分观察内层属性变化
@Component
struct ProductNestedV1ObjectLink {
  @ObjectLink author: AuthorDetail

  build() {
    Column() {
      // @ObjectLink可观察内层属性变化
      Text(`@ObjectLink作者: ${this.author.authorName}`)
        .fontSize(18)
        .onClick(() => { this.author.authorName += '!' })
    }
  }
}

// V2子组件：@Param配合enableV2Compatibility实现深度观测
@ComponentV2
struct ProductNestedV2View {
  @Require @Param product: ProductDetail

  build() {
    Column() {
      // @Param可观察第一层变化
      Text(`@Param商品名: ${this.product.productName}`)
        .fontSize(18)
        .onClick(() => { this.product.productName += '!' })

      // @Param配合enableV2Compatibility可深度观测第二层变化
      Text(`@Param作者: ${this.product.author.authorName}`)
        .fontSize(16)
        .onClick(() => { this.product.author.authorName += '!' })

      Button('@Param新增评分').onClick(() => {
        // 新增数据需用makeV1Observed包装，确保V2可观察
        this.product.author.ratings.push(UIUtils.makeV1Observed(new RatingItem(3)))
      })

      Button('@Param修改评分').onClick(() => {
        // 修改最内层属性，V2可深度观测
        this.product.author.ratings[this.product.author.ratings.length - 1].value++
      })
    }
  }
}

// V1父组件：逐层makeV1Observed包装，保证每层都是V1状态变量
@Entry
@Component
struct ProductNestedPageV1Api19 {
  // 需保证每一层都是V1的状态变量：逐层makeV1Observed包装
  // makeV1Observed不会递归执行，仅包装第一层
  @State product: ProductDetail =
    UIUtils.makeV1Observed(new ProductDetail(
      UIUtils.makeV1Observed(new AuthorDetail(UIUtils.makeV1Observed([
        UIUtils.makeV1Observed(new RatingItem(4)),
        UIUtils.makeV1Observed(new RatingItem(5))
      ])))
    ))

  build() {
    Column({ space: 15 }) {
      // @State可以观察第一层的变化
      Text(`@State商品名: ${this.product.productName}`)
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

      // @State无法观察第二层的变化，但会被@ObjectLink和@Param观察到
      Text(`@State作者: ${this.product.author.authorName}`)
        .fontSize(18)
        .onClick(() => { this.product.author.authorName += '!' })

      // @State仅观察第一层，深层变化需@ObjectLink拆分
      ProductNestedV1ObjectLink({ author: this.product.author })

      // 传递给V2时调用enableV2Compatibility实现深度观测
      ProductNestedV2View({ product: UIUtils.enableV2Compatibility(this.product) })
    }
    .padding(20)
  }
}
```

关键点：嵌套类型需逐层用`makeV1Observed`包装为V1状态变量，`makeV1Observed`不会递归执行仅包装第一层。传递给V2时调用`enableV2Compatibility`实现深度观测。`@State`仅能观察第一层变化，深层变化需`@ObjectLink`拆分或`@Param`配合`enableV2Compatibility`深度观测。`@ObjectLink`和`@Param`引用同一对象，修改会互相刷新。新增数据需用`makeV1Observed`包装以确保V2可观察。

---

## V2中使用V1的自定义组件

**API19前后对比**

| 能力 | API19前 | API19及以后 |
|------|---------|-------------|
| V2→V1简单类型 | `@State`/`@Prop`/`@Provide`接收 | 同API19前（不变） |
| V2→V1普通class | `@State`接收（仅一层观测） | `enableV2Compatibility`+`makeV1Observed`+`@ObjectLink`（双向联动） |
| V2→V1 @ObservedV2 class | V1不能用装饰器，普通变量+`@Trace` | 同API19前（@ObservedV2不能用V1装饰器） |
| V2→V1 @Observed class | 不支持 | `enableV2Compatibility`+`@ObjectLink` |
| V2→V1内置类型 | V2去掉@Local，V1@Provide接收 | `makeV1Observed`+`enableV2Compatibility`+`@ObjectLink` |
| V2→V1嵌套类型 | 仅V1@ObjectLink拆分 | `makeV1Observed`逐层+`enableV2Compatibility`（V2深度观测）+V1多层@ObjectLink |
| 新增接口 | 无 | `enableV2Compatibility`、`makeV1Observed` |


### V2中使用V1组件-API19前

**场景ID：** STATE_MIXED_V1V2_03

**场景描述：** 外卖订单页，V2父组件管理订单信息（支付状态、商品信息、订单详情、配送标签），需要使用V1第三方组件展示订单详情。需解决V2向V1传递不同类型数据时的限制和适配方案。

**解决方案：** API19前V2→V1传递简单类型状态变量，V1仅能通过`@State`、`@Prop`、`@Provide`接收；传递普通class可被V1`@State`接收，可观测一层类属性变化；传递`@ObservedV2`+`@Trace`装饰的class，V1不能用装饰器接收（编译报错），需作为普通变量，依赖`@Trace`独立观测能力；传递内置类型（Set等），V2装饰器和V1接收装饰器互斥，需去掉`@Local`作为普通变量传递；传递`@Observed`装饰的class不支持，V2装饰器不能和`@Observed`一起使用（编译报错）。

```
外卖订单页 V2父组件 @Local
  ├── isPaid(boolean) ──(@State)──→ V1 OrderStatusComp（支付状态）
  │     简单类型，V1仅可通过@State/@Prop/@Provide接收
  │     不支持@Link/@ObjectLink/@Consume
  │
  ├── product(ProductInfo普通class) ──(@State)──→ V1 ProductDetailComp（商品详情）
  │     V1使用@State接收，可观测一层类属性变化
  │
  ├── order(OrderInfo @ObservedV2+@Trace) ──(普通变量)──→ V1 OrderDetailComp（订单详情）
  │     V1不能用@State接收（编译报错），需作为普通变量
  │     依赖@Trace独立观测能力刷新UI
  │     @Trace属性可观测，非@Trace属性不刷新
  │
  ├── tags(Set<string>内置类型) ──(普通变量)──→ V1 OrderTagComp(@Provide)
  │     V2去掉@Local，作为普通变量传递
  │     V1用@Provide接收，V2无法观测变化
  │
  └── productObserved(ProductObserved @Observed) ──(不支持)──→ V1
        V2装饰器不能和@Observed一起使用（编译报错）
        只能作为普通变量，无法实现数据联动
```

#### 1.定义数据类 — 订单信息、商品信息与配送标签

```ts
// 订单详情类：使用@ObservedV2+@Trace装饰
@ObservedV2
class OrderInfo {
  @Trace public orderId: string = 'ORD-20250101' // @Trace装饰，变化可观测
  @Trace public totalPrice: number = 36.8        // @Trace装饰，变化可观测
  @Trace public deliveryFee: number = 5.0        // @Trace装饰，变化可观测
  public notes: string = '请少放辣'              // 非@Trace，无法观测变化
}

// 商品信息类：普通class，未使用任何装饰器
class ProductInfo {
  public productName: string = '黄焖鸡米饭'
  public price: number = 28.8
  public quantity: number = 1

  constructor(productName?: string, price?: number, quantity?: number) {
    this.productName = productName ?? '黄焖鸡米饭'
    this.price = price ?? 28.8
    this.quantity = quantity ?? 1
  }
}

// 商品类：使用@Observed装饰（V1装饰器）
@Observed
class ProductObserved {
  public productName: string = '麻辣香锅'
  public price: number = 35.0
}
```

关键点：`OrderInfo`使用`@ObservedV2`+`@Trace`装饰，`@Trace`属性变化可被独立观测；`ProductInfo`为普通class，无装饰器；`ProductObserved`使用`@Observed`装饰，属于V1装饰器，不能与V2装饰器一起使用。

#### 2.传递简单类型状态变量 — @State/@Prop/@Provide接收

V2向V1传递简单类型状态变量（boolean、number、string、null、undefined）时，V1仅能通过`@State`、`@Prop`、`@Provide`装饰器接收。

```ts
// 模拟三方库导入的V1组件：展示支付状态
@Component
struct OrderStatusComp {
  // V1从V2接收的简单类型状态变量，仅可使用@State、@Prop、@Provide接收
  @State isPaid: boolean = false // 可以观测到变化

  build() {
    Column() {
      Text(`支付状态: ${this.isPaid ? '已支付' : '待支付'}`)
        .fontSize(18)
        .fontColor(this.isPaid ? Color.Green : Color.Red)
      // 不支持@Link/@ObjectLink/@Consume接收V2的状态变量
    }
  }
}

@Entry
@ComponentV2
struct FoodOrderPage {
  @Local isPaid: boolean = false // V2支付状态

  build() {
    Column({ space: 12 }) {
      Text(`外卖订单 - 支付状态: ${this.isPaid ? '已支付' : '待支付'}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      // V2简单类型状态变量传递给V1组件，V1通过@State接收
      OrderStatusComp({ isPaid: this.isPaid })

      Button('模拟支付').onClick(() => { this.isPaid = true })
      Button('取消支付').onClick(() => { this.isPaid = false })
    }
    .padding(20)
  }
}
```

关键点：V2→V1传递简单类型状态变量时，V1仅可通过`@State`、`@Prop`、`@Provide`接收，不支持`@Link`、`@ObjectLink`、`@Consume`接收V2的状态变量。`@Link`遵循其原本初始化规则，只能被V1状态变量初始化。

#### 3.传递普通class — @State接收

V2向V1传递普通class（未被`@ObservedV2`或`@Observed`装饰）时，V1可以使用`@State`接收，可观测一层类属性变化。

```ts
// 模拟三方库导入的V1组件：展示商品详情
@Component
struct ProductDetailComp {
  // V1使用@State接收普通class，可观测一层类属性变化
  @State product: ProductInfo = new ProductInfo()

  build() {
    Column() {
      Text(`商品: ${this.product.productName}`)
        .fontSize(18)
      Text(`价格: ¥${this.product.price}`)
        .fontSize(16)
      Text(`数量: ${this.product.quantity}`)
        .fontSize(16)

      // 修改第一层属性，@State可观测并刷新
      Button('改名').onClick(() => { this.product.productName = '红烧排骨饭' })
      Button('改价').onClick(() => { this.product.price = 32.0 })
    }
    .padding(10)
    .backgroundColor('#f5f5f5')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageProduct {
  @Local product: ProductInfo = new ProductInfo('黄焖鸡米饭', 28.8, 1)

  build() {
    Column({ space: 12 }) {
      Text(`外卖订单 - 商品信息`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Text(`V2商品: ${this.product.productName} ¥${this.product.price}`)
        .fontSize(18)

      // V2普通class传递给V1的@State
      ProductDetailComp({ product: this.product })
    }
    .padding(20)
  }
}
```

关键点：V2→V1传递普通class时，V1使用`@State`接收，观测能力为数据本身赋值和第一层属性的赋值。修改`product.productName`或`product.price`等第一层属性时，V1组件UI可刷新。

#### 4.传递@ObservedV2+@Trace装饰的class — V1不能用装饰器接收

V1装饰器不能和`@ObservedV2`一起使用（编译报错）。V1组件接收`@ObservedV2`+`@Trace`装饰的class时，不能使用V1装饰器，需作为普通变量接收，依赖`@Trace`的独立观测能力刷新UI。

```ts
// 模拟三方库导入的V1组件：展示订单详情
@Component
struct OrderDetailComp {
  // @State order: OrderInfo = new OrderInfo() // 编译报错！V1装饰器不能和@ObservedV2一起使用
  order: OrderInfo = new OrderInfo() // 正确：作为普通变量接收，依赖@Trace独立观测

  build() {
    Column() {
      // @Trace属性可观测，修改触发UI刷新
      Text(`订单号: ${this.order.orderId}`)
        .fontSize(18)
        .onClick(() => { this.order.orderId = 'ORD-20250102' }) // @Trace可观测，刷新
      Text(`总价: ¥${this.order.totalPrice}`)
        .fontSize(16)
        .onClick(() => { this.order.totalPrice += 1 }) // @Trace可观测，刷新
      Text(`配送费: ¥${this.order.deliveryFee}`)
        .fontSize(14)
        .onClick(() => { this.order.deliveryFee = 6.0 }) // @Trace可观测，刷新

      // 非@Trace属性，修改不触发UI刷新
      Text(`备注: ${this.order.notes}`)
        .fontSize(14)
        .onClick(() => { this.order.notes = '多加辣椒' }) // 不刷新！notes非@Trace
    }
    .padding(10)
    .backgroundColor('#e8f5e9')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageDetail {
  @Local order: OrderInfo = new OrderInfo()

  build() {
    Column({ space: 12 }) {
      Text(`外卖订单 - 订单详情`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      // V2中@Local可观测@Trace属性变化
      Text(`V2订单号: ${this.order.orderId}`)
        .fontSize(18)
      Text(`V2总价: ¥${this.order.totalPrice}`)
        .fontSize(16)

      // V2状态变量传递给V1，V1作为普通变量接收，依赖@Trace观测
      OrderDetailComp({ order: this.order })
    }
    .padding(20)
  }
}
```

关键点：V1装饰器不能和`@ObservedV2`一起使用（编译报错），V1组件需将`@ObservedV2`类作为普通变量接收。`@ObservedV2`+`@Trace`的观测能力独立生效：`@Trace`属性（`orderId`、`totalPrice`、`deliveryFee`）的变化在V1和V2中均可观测并刷新UI；非`@Trace`属性（`notes`）的变化无法触发UI刷新。

#### 5.传递内置类型 — 限制条件

V2→V1传递内置类型（Array、Set、Map、Date）时，V2的状态变量装饰器和V1的接收装饰器互斥。V1使用装饰器接收时，内置类型不支持在V2中用装饰器修饰。

```ts
// 模拟三方库导入的V1组件：展示配送标签
@Component
struct OrderTagComp {
  // V1使用@Provide接收内置类型Set
  @Provide tags: Set<string> = new Set()

  build() {
    Column() {
      Text(`配送标签:`)
        .fontSize(16)
      ForEach(Array.from(this.tags.values()), (item: string) => {
        Text(`${item}`).fontSize(14).margin(4)
      })
    }
    .padding(10)
    .backgroundColor('#fff3e0')
    .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct FoodOrderPageTag {
  // @Local tags: Set<string> = new Set(['热销', '新品', '满减']) // 编译报错！V2装饰器和V1接收装饰器对内置类型互斥
  tags: Set<string> = new Set(['热销', '新品', '满减']) // 正确：去掉@Local作为普通变量传递

  build() {
    Column({ space: 12 }) {
      Text(`外卖订单 - 配送标签`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      // V2中作为普通变量传递给V1，V1用@State/@Prop/@Provide接收
      // 但V2中无法观测tags的变化
      OrderTagComp({ tags: this.tags })
    }
    .padding(20)
  }
}
```

关键点：V2→V1传递内置类型时，V2的状态变量装饰器（`@Local`等）和V1的接收装饰器（`@State`、`@Prop`、`@Provide`）互斥。解决方案：V2去掉`@Local`作为普通变量传递，V1使用`@State`/`@Prop`/`@Provide`接收。但V2中无法观测该变量的变化。

#### 6.传递@Observed装饰的class — 不支持

V2状态变量不支持传递`@Observed`装饰的class给V1。V2的`@Local`等装饰器不能装饰`@Observed`类（编译报错），V2装饰器不能和`@Observed`一起使用。

```ts
@Entry
@ComponentV2
struct FoodOrderPageObservedErr {
  // @Local productObserved: ProductObserved = new ProductObserved() // 编译报错！V2装饰器不能和@Observed一起使用
  productObserved: ProductObserved = new ProductObserved() // 只能作为普通变量，无法实现数据联动

  build() {
    Column({ space: 12 }) {
      Text(`外卖订单 - @Observed商品`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      // productObserved只能作为普通变量使用
      // 无法传递给V1组件实现数据联动（V2装饰器不能和@Observed一起使用）
      Text(`商品: ${this.productObserved.productName}`)
        .fontSize(18)
      Text(`价格: ¥${this.productObserved.price}`)
        .fontSize(16)
    }
    .padding(20)
  }
}
```

关键点：V2装饰器不能和`@Observed`一起使用（编译报错）。API19前，V2→V1传递`@Observed`装饰的class无法实现数据联动，只能作为普通变量传递，修改属性不会触发UI刷新。

#### 数据流向总结

```
V2父组件 @Local
  ├── 简单类型(isPaid) ──(@State/@Prop/@Provide)──→ V1 OrderStatusComp
  │     仅支持 boolean/number/string/null/undefined
  │     V1不支持@Link/@ObjectLink/@Consume接收
  │     @Link遵循其原本初始化规则，只能被V1状态变量初始化
  │
  ├── 普通class(ProductInfo) ──(@State)──→ V1 ProductDetailComp
  │     V1使用@State接收，可观测一层类属性变化
  │     观测能力：数据本身赋值 + 第一层属性赋值
  │
  ├── @ObservedV2+@Trace class(OrderInfo) ──(普通变量)──→ V1 OrderDetailComp
  │     V1不能用@State接收（编译报错），需作为普通变量
  │     依赖@Trace独立观测能力：@Trace属性可观测，非@Trace不刷新
  │     @ObservedV2+@Trace的观测能力独立生效
  │
  ├── 内置类型(Set<string>) ──(普通变量)──→ V1 OrderTagComp(@Provide)
  │     V2去掉@Local，作为普通变量传递
  │     V1用@State/@Prop/@Provide接收
  │     V2中无法观测变化
  │
  └── @Observed class(ProductObserved) ──(不支持)──→ V1
        V2装饰器不能和@Observed一起使用（编译报错）
        只能作为普通变量，API19前无法实现数据联动
```

---

### V2中使用V1组件-API19及以后

**场景ID：** STATE_MIXED_V1V2_04

**场景描述：** 外卖订单页，V2父组件管理订单信息（订单号、商品详情、配送标签、价格列表），需要使用V1第三方组件展示订单详情。API19及以后通过`enableV2Compatibility`和`makeV1Observed`简化了V2→V1的数据传递，实现双向数据联动。

**解决方案：** 使用 **`enableV2Compatibility`+`makeV1Observed`** 将数据同时具备V1和V2的观察能力。V2→V1传递普通class时，`enableV2Compatibility(makeV1Observed())`使双方可观察，V1用`@ObjectLink`接收；传递`@Observed`class时，`enableV2Compatibility`使V2可观察，V1用`@ObjectLink`接收；传递内置类型时，`makeV1Observed`+`enableV2Compatibility`避免双重代理，V1用`@ObjectLink`接收；传递二维数组时，`makeV1Observed`逐层包装内层数组，V1用`@ObjectLink`接收内层；传递嵌套类型时，`makeV1Observed`逐层包装保证每层都是V1状态变量，`enableV2Compatibility`实现V2深度观测，V1需多层`@ObjectLink`拆分实现深度观测。

> **说明：**
> `enableV2Compatibility`使V1状态变量兼容V2观察能力；`makeV1Observed`将不可观察的对象包装为V1可观察对象，返回值可初始化`@ObjectLink`。

### 场景：外卖订单页（V2中使用V1组件 - API19及以后）

```
外卖订单页 V2父组件 @Local
  ├── OrderClass(普通class) ──(enableV2Compatibility+makeV1Observed)──→ V1 @ObjectLink
  │     双向数据联动，V1用@ObjectLink接收makeV1Observed的返回值
  │     建议在@Local初始化时调用: UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new OrderClass()))
  │
  ├── ProductObservedClass(@Observed+@Track) ──(enableV2Compatibility)──→ V1 @ObjectLink
  │     @Observed class无需makeV1Observed，直接enableV2Compatibility
  │     @Track属性V1/V2均可观察，非@Track属性V1 UI运行时报错、V2不报错但不响应更新
  │
  ├── prices(Array<number>) ──(makeV1Observed+enableV2Compatibility)──→ V1 @ObjectLink
  │     makeV1Observed包装为V1状态变量 → enableV2Compatibility使V2可观察 → 避免双重代理
  │     V1用@ObjectLink接收makeV1Observed的返回值
  │
  ├── tagGroups(Array<Array<string>>) ──(makeV1Observed逐层+enableV2Compatibility)──→ V1 @ObjectLink(内层)
  │     内层数组逐层makeV1Observed包装 → 外层makeV1Observed+enableV2Compatibility
  │     V1用@ObjectLink接收内层数组
  │     新增数组元素需makeV1Observed包装
  │
  └── OrderNested(嵌套class) ──(makeV1Observed逐层+enableV2Compatibility)──→ V1多层@ObjectLink拆分
        逐层makeV1Observed保证每层都是V1状态变量 → enableV2Compatibility实现V2深度观测
        V1仅观察第一层 → 多层@ObjectLink拆分实现深度观测
        新增数据需makeV1Observed包装
```

#### 1.定义数据类 — 订单信息、商品详情与配送标签

在外卖订单页场景中，需要定义五种数据类，覆盖普通class、@Observed+@Track装饰的class、内置类型、二维数组和嵌套类型的传递场景。

```ts
import { UIUtils } from '@kit.ArkUI'

// 知识点1：普通class，无任何装饰器
class OrderClass {
  public orderId: string = 'ORD001'
  public totalPrice: number = 2999
}

// 知识点2：@Observed+@Track装饰的class
@Observed
class ProductObservedClass {
  @Track public productName: string = '智能手机'
  @Track public price: number = 2999
  public stock: number = 100 // 非@Track属性
}

// 知识点5嵌套类型：订单项（最内层普通class）
class OrderItem {
  public value: number = 0
  constructor(value: number) {
    this.value = value
  }
}

// 知识点5嵌套类型：商品详情（中间层普通class，包含OrderItem数组）
class ProductDetail {
  public productName: string = '智能手机'
  public items: Array<OrderItem>
  constructor(items: Array<OrderItem>) {
    this.items = items
  }
}

// 知识点5嵌套类型：嵌套订单（外层class，包含@Track属性和嵌套ProductDetail）
class OrderNested {
  @Track public orderId: string = 'ORD001'
  @Track public product: ProductDetail
  constructor(product: ProductDetail) {
    this.product = product
  }
}
```

关键点：数据类设计覆盖了五种传递场景：(1)`OrderClass`为普通class无任何装饰器；(2)`ProductObservedClass`使用`@Observed`+`@Track`装饰；(3)内置类型`Array<number>`无需定义数据类；(4)二维数组`Array<Array<string>>`无需定义数据类；(5)嵌套类型`OrderNested`包含`ProductDetail`包含`OrderItem[]`，三层嵌套结构展示逐层包装的必要性。

#### 2.传递普通class — enableV2Compatibility + makeV1Observed

V2→V1传递普通class时，需调用`enableV2Compatibility(makeV1Observed())`使数据同时具备V1和V2的观察能力，V1用`@ObjectLink`接收，实现双向数据联动。

```ts
import { UIUtils } from '@kit.ArkUI'

class OrderClass {
  public orderId: string = 'ORD001'
  public totalPrice: number = 2999
}

@Entry
@ComponentV2
struct OrderPageV2Api19 {
  // 使用enableV2Compatibility+makeV1Observed使数据同时具备V1和V2观察能力
  @Local order: OrderClass = UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new OrderClass()))

  build() {
    Column() {
      // @Local原本仅可观察自身，但调用makeV1Observed使其变成V1状态变量
      // 又调用enableV2Compatibility使其在V2中可观察，所以可观察第一层属性变化
      Text(`V2订单号: ${this.order.orderId}`)
        .fontSize(20)
        .onClick(() => { this.order.orderId += '!' })

      // @ObjectLink可接收makeV1Observed的返回值
      OrderV1DetailView({ order: this.order })
    }
  }
}

@Component
struct OrderV1DetailView {
  @ObjectLink order: OrderClass

  build() {
    Column() {
      Text(`V1订单号: ${this.order.orderId}`)
        .fontSize(18)
        .onClick(() => { this.order.orderId += '!' })
      Text(`V1总价: ¥${this.order.totalPrice}`)
        .fontSize(16)
        .onClick(() => { this.order.totalPrice++ })
    }
  }
}
```

关键点：V2→V1传递普通class时，使用`UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new Class()))`使数据同时具备V1和V2的观察能力。V1用`@ObjectLink`接收（`makeV1Observed`的返回值可初始化`@ObjectLink`），V2用`@Local`管理，双方修改都可观察并互相刷新。

#### 3.传递@Observed+@Track装饰的class — enableV2Compatibility

`@Observed`装饰的class传递给V1时，`enableV2Compatibility`无需再调用`makeV1Observed`。`@Track`属性在V1和V2中均可观察；非`@Track`属性在V1中UI使用运行时报错，在V2中不报错但不响应更新。

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProductObservedClass {
  @Track public productName: string = '智能手机'
  @Track public price: number = 2999
  public stock: number = 100 // 非@Track
}

@Entry
@ComponentV2
struct OrderPageV2ObservedApi19 {
  // @Observed装饰的class，直接enableV2Compatibility即可
  @Local product: ProductObservedClass = UIUtils.enableV2Compatibility(new ProductObservedClass())

  build() {
    Column() {
      Text(`V2商品: ${this.product.productName} - ¥${this.product.price}`)
        .fontSize(20)
        .onClick(() => { this.product.productName += '!' })

      // 非@Track属性在V2中不会崩溃，但不响应更新
      Text(`库存: ${this.product.stock}`)
        .onClick(() => { this.product.stock++ }) // 不触发刷新

      ProductV1DetailView({ product: this.product })
    }
  }
}

@Component
struct ProductV1DetailView {
  @ObjectLink product: ProductObservedClass

  build() {
    Column() {
      // @Track属性在V1中可观察
      Text(`V1商品: ${this.product.productName}`)
        .onClick(() => { this.product.productName += '!' })
    }
  }
}
```

关键点：`@Observed`装饰的class无需调用`makeV1Observed`，直接`enableV2Compatibility`即可。V1用`@ObjectLink`接收。`@Track`属性在V1和V2中均可观察。非`@Track`属性在V1中UI使用运行时报错，在V2中不报错但不响应更新。

#### 4.传递内置类型(Array) — makeV1Observed + enableV2Compatibility

V2→V1传递内置类型时，使用`makeV1Observed`包装为V1状态变量，再`enableV2Compatibility`使V2可观察，V1用`@ObjectLink`接收。

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct OrderPageV2ArrayApi19 {
  // 使用makeV1Observed包装为V1状态变量，enableV2Compatibility使V2可观察
  @Local prices: Array<number> = UIUtils.enableV2Compatibility(UIUtils.makeV1Observed([2999, 199, 49]))

  build() {
    Column() {
      Text(`V2第一个价格: ¥${this.prices[0]}`)
        .fontSize(20)
        .onClick(() => { this.prices[0]++ })

      // @ObjectLink可接收makeV1Observed的返回值
      OrderV1PriceList({ prices: this.prices })
    }
  }
}

@Component
struct OrderV1PriceList {
  @ObjectLink prices: Array<number>

  build() {
    Column() {
      Text(`V1第一个价格: ¥${this.prices[0]}`)
        .fontSize(18)
        .onClick(() => { this.prices[0]++ }) // 双向同步
    }
  }
}
```

关键点：V2→V1传递内置类型时，使用`makeV1Observed`包装为V1状态变量，`enableV2Compatibility`使V2可观察，避免双重代理。V1用`@ObjectLink`接收`makeV1Observed`的返回值。双方修改双向同步。

#### 5.传递二维数组 — makeV1Observed逐层包装 + enableV2Compatibility

```ts
import { UIUtils } from '@kit.ArkUI'

@Component
struct OrderTagItem {
  @ObjectLink tagArr: Array<string>

  build() {
    Row() {
      ForEach(this.tagArr, (item: string, index: number) => {
        Text(`${index}: ${item}`)
      })
      Button('@ObjectLink新增').onClick(() => {
        this.tagArr.push('ObjectLink')
      })
    }
  }
}

@Entry
@ComponentV2
struct OrderTagPageV2Api19 {
  @Local tagGroups: Array<Array<string>> =
    UIUtils.enableV2Compatibility(UIUtils.makeV1Observed([
      UIUtils.makeV1Observed(['热销']),
      UIUtils.makeV1Observed(['新品']),
      UIUtils.makeV1Observed(['推荐'])
    ]))

  build() {
    Column() {
      ForEach(this.tagGroups, (tagArr: Array<string>) => {
        OrderTagItem({ tagArr: tagArr })
      })

      Button('@Local新增标签组').onClick(() => {
        this.tagGroups.push(UIUtils.makeV1Observed(['新书']))
      })
      Button('@Local修改第一个标签').onClick(() => {
        this.tagGroups[0][0] = 'HOT'
      })
    }
  }
}
```

关键点：二维数组需用`makeV1Observed`包装内层数组为V1状态变量，外层也用`makeV1Observed`+`enableV2Compatibility`包装。V1用`@ObjectLink`接收内层数组。新增数组元素需用`makeV1Observed`包装。

#### 6.传递嵌套类型 — makeV1Observed逐层包装 + enableV2Compatibility深度观测

嵌套类型需保证每一层都是V1的状态变量（`makeV1Observed`包装），V2调用`enableV2Compatibility`实现深度观测。V1需多层组件配合`@ObjectLink`实现深度观测。

```ts
import { UIUtils } from '@kit.ArkUI'

class OrderItem {
  public value: number = 0
  constructor(value: number) { this.value = value }
}

class ProductDetail {
  public productName: string = '智能手机'
  public items: Array<OrderItem>
  constructor(items: Array<OrderItem>) { this.items = items }
}

class OrderNested {
  @Track public orderId: string = 'ORD001'
  @Track public product: ProductDetail
  constructor(product: ProductDetail) { this.product = product }
}

@Entry
@ComponentV2
struct OrderNestedPageV2Api19 {
  // 需保证每一层都是V1的状态变量
  @Local order: OrderNested = UIUtils.enableV2Compatibility(
    UIUtils.makeV1Observed(new OrderNested(
      UIUtils.makeV1Observed(new ProductDetail(UIUtils.makeV1Observed([
        UIUtils.makeV1Observed(new OrderItem(1)),
        UIUtils.makeV1Observed(new OrderItem(2))
      ])))
    )))

  build() {
    Column() {
      Text(`@Local订单号: ${this.order.orderId}`)
        .fontSize(20)
        .onClick(() => { this.order.orderId += '!' })

      Text(`@Local商品名: ${this.order.product.productName}`)
        .fontSize(18)
        .onClick(() => { this.order.product.productName += '!' })

      // 将product传递给@ObjectLink可观察内层属性变化
      OrderNestedV1ObjectLink({ product: this.order.product })
    }
  }
}

@Component
struct OrderNestedV1ObjectLink {
  @ObjectLink product: ProductDetail

  build() {
    Column() {
      Text(`@ObjectLink商品: ${this.product.productName}`)
        .onClick(() => { this.product.productName += '!' })

      // 继续拆解一层子组件
      OrderNestedV1Array({ items: this.product.items })
    }
  }
}

@Component
struct OrderNestedV1Array {
  @ObjectLink items: Array<OrderItem>

  build() {
    Column() {
      ForEach(this.items, (item: OrderItem, index: number) => {
        OrderNestedV1Item({ item: item })
      })

      Button('@ObjectLink新增').onClick(() => {
        this.items.push(UIUtils.makeV1Observed(new OrderItem(20)))
      })
    }
  }
}

@Component
struct OrderNestedV1Item {
  @ObjectLink item: OrderItem

  build() {
    Text(`项: ${this.item.value}`)
  }
}
```

关键点：V2→V1传递嵌套类型时，需逐层用`makeV1Observed`包装为V1状态变量，外层调用`enableV2Compatibility`实现V2深度观测。V1中仅能观察第一层变化，需多层`@ObjectLink`组件拆分实现深度观测。V2中`enableV2Compatibility`可直接深度观测。新增数据需用`makeV1Observed`包装。

---