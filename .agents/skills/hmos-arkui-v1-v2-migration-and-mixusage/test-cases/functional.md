# ArkUI V1/V2 功能性测试

用例采用独立代码片段或完整文字诊断输入。各题已包含需要读取的全部本地文件内容，不要求访问外部 Bench、SDK、设备或临时工程。代码答案与语义由独立模型输出，再按各题验证标准静态比对；这里不验证真实编译、运行时调度或真机 UI。

每条题面的输入均可单独发送；不把本文件的预期输出传给被测模型。

---

### 测试用例：FUNC-COMP-LINK-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-COMP-LINK-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 Child 组件到 V2。Parent.ets 中的 ComponentLinkPage 保持 V1。保持点击 Child 后 Parent 文本同步更新。 允许为完成边界契约最小联动父级创建点及必要 import / 回调，父级组件与数据模型保持原体系。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`Child.ets`：

```ts
@Component
export struct Child {
  @Link title: string;

  build() {
    Button(this.title)
      .onClick(() => {
        this.title = 'changed by child';
      })
  }
}
```

`Parent.ets`：

```ts
import { Child } from './Child';

@Entry
@Component
struct ComponentLinkPage {
  @State title: string = 'V1 title';

  build() {
    Column({ space: 16 }) {
      Text('Component Link Case')
      Child({ title: this.title })
      Text(`parent: ${this.title}`)
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- Child 改为 @ComponentV2，以 @Param 接收 title、以 @Event 请求父组件修改，不在 Child 内保留 @Link 或直接给普通 @Param 赋值。
- ComponentLinkPage 保持 @Entry @Component 和 V1 状态；仅联动 Child 的创建点与回调，使点击后父级 title 与 Child 显示都变为 changed by child。
- 无默认值的输入声明 @Require @Param；字符串跨边界直接传值，不引入对象兼容接口。

---

### 测试用例：FUNC-COMPONENT-DECORATORS-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-COMPONENT-DECORATORS-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 DecoratorPage 及其场景内组件到 V2，保持外部一次初始化、本地可写输入、父值后续覆盖和状态变化副作用语义。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`DecoratorPage.ets`：

```ts
@Component
struct OnceValueChild {
  @State value: number = 0;

  build() {
    Column({ space: 4 }) {
      Text(`once child: ${this.value}`)
      Button('once child +1').onClick(() => {
        this.value++;
      })
    }
  }
}

@Component
struct WritablePropChild {
  @Prop value: number;

  build() {
    Column({ space: 4 }) {
      Text(`prop child: ${this.value}`)
      Button('prop child +100').onClick(() => {
        this.value += 100;
      })
    }
  }
}

@Component
struct WatchedCounter {
  @State @Watch('onCountChange') count: number = 0;
  @State observedCount: number = 0;

  onCountChange(): void {
    this.observedCount = this.count;
  }

  build() {
    Column({ space: 4 }) {
      Text(`observed count: ${this.observedCount}`)
      Button(`watched count: ${this.count}`).onClick(() => {
        this.count++;
      })
    }
  }
}

@Entry
@Component
struct DecoratorPage {
  @State seed: number = 30;
  @State propValue: number = 10;

  build() {
    Column({ space: 10 }) {
      Text('Component Decorators Case')
      Text(`parent seed: ${this.seed}`)
      Button('parent seed +10').onClick(() => {
        this.seed += 10;
      })
      OnceValueChild({ value: this.seed })
      Text(`parent prop: ${this.propValue}`)
      Button('parent prop +1').onClick(() => {
        this.propValue++;
      })
      WritablePropChild({ value: this.propValue })
      WatchedCounter()
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- DecoratorPage 及场景内全部组件迁为 @ComponentV2，自有状态使用 @Local，不残留 V1 组件状态装饰器。
- OnceValueChild 的外部输入使用 @Param @Once，初值为 30，子级可自增，后续 seed 增加不覆盖其本地值；保留合法默认值或完整必填声明。
- WritablePropChild 使用持续更新的 @Param 与可写本地副本，首次显示为 10，子级加 100 不回写父级；父级再加 1 时本地显示被新父值覆盖。
- 可写副本在初始化路径正确赋值，并由 @Monitor 同步后续父输入；不能只用 @Once 替代需要持续同步的输入。
- WatchedCounter 用写在方法上的 @Monitor 维护 observedCount，监听参数为状态路径，不把 @Watch 的方法名语法照搬；若使用 IMonitor 值对，应调用 value<T>() 并读取 now 而非 after。

---

### 测试用例：FUNC-PROVIDE-CONSUME-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-PROVIDE-CONSUME-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 ProviderPage 和其子组件到 V2，保持消费方修改后提供方同步更新

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`ProviderPage.ets`：

```ts
@Component
struct ProviderConsumerChild {
  @Consume('benchTheme') childColor: string;

  build() {
    Button(`consumer: ${this.childColor}`)
      .onClick(() => {
        this.childColor = 'blue';
      })
  }
}

@Entry
@Component
struct ProviderPage {
  @Provide('benchTheme') providerColor: string = 'red';

  build() {
    Column({ space: 16 }) {
      Text('Provide Consume Case')
      Text(`provider: ${this.providerColor}`)
      ProviderConsumerChild()
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- ProviderPage 与 ProviderConsumerChild 均迁为 @ComponentV2，整组使用同一个 benchTheme alias 的 @Provider / @Consumer，不以显式参数链无故替换完整可迁移通道。
- V2 Provider/Consumer 使用带括号的声明，Consumer 有合法本地默认值，查找到 Provider 后以 Provider 的 red 作为初值。
- 消费方写入 blue 后提供方与消费方共享同一状态；迁移后该组不残留 @Provide / @Consume。

---

### 测试用例：FUNC-PROVIDE-PARTIAL-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-PROVIDE-PARTIAL-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 ThemeSettingChild 到 V2。ThemeHostPage 与 LegacyThemeBadge 保持 V1，并继续通过原 @Provide/@Consume('benchTheme') 通道同步。保持：页面切换或子组件切换主题后，host、badge、child 三处显示同步更新。 允许最小联动 host 创建点与修改回调，host 的 V1 主题所有权和 badge 的旧通道不变。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`ThemeHostPage.ets`：

```ts
import { ThemeSettingChild } from './ThemeSettingChild';

@Entry
@Component
struct ThemeHostPage {
  @Provide('benchTheme') theme: string = 'light';

  build() {
    Column({ space: 16 }) {
      Text('Provide Partial Case')
      Text(`host theme: ${this.theme}`)
      LegacyThemeBadge()
      ThemeSettingChild()
      Button('host toggle theme')
        .onClick(() => {
          this.theme = this.theme === 'light' ? 'dark' : 'light';
        })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}

@Component
struct LegacyThemeBadge {
  @Consume('benchTheme') theme: string;

  build() {
    Text(`badge theme: ${this.theme}`)
  }
}
```

`ThemeSettingChild.ets`：

```ts
@Component
export struct ThemeSettingChild {
  @Consume('benchTheme') theme: string;

  build() {
    Button(`set theme: ${this.theme}`)
      .onClick(() => {
        this.theme = this.theme === 'light' ? 'dark' : 'light';
      })
  }
}
```

#### 预期输出

**验证标准**：

- 仅 ThemeSettingChild 迁为 @ComponentV2，删除其 @Consume，以 @Param / @Event 接收主题和请求修改。
- ThemeHostPage 与 LegacyThemeBadge 保持 V1，保留 @Provide / @Consume 的 benchTheme 通道，不在 V1 组件中使用 @Provider、@Consumer、@Param 或 @Event。
- 允许联动 host 的 ThemeSettingChild 创建点与回调，host 仍是唯一主题所有者；首次为 light，任一侧切换后 host、badge、child 一致。

---

### 测试用例：FUNC-PROVIDE-DEEP-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-PROVIDE-DEEP-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 ThemePanel 及其全部子组件到 V2，DeepThemePage 保持 V1。原有 @Provide/@Consume('deepTheme') 通道不得保留。保持：页面切换主题后深层叶子刷新；叶子切换后页面刷新。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`DeepThemePage.ets`：

```ts
@Entry
@Component
struct DeepThemePage {
  @Provide('deepTheme') theme: string = 'light';

  build() {
    Column({ space: 16 }) {
      Text('Provide Deep Case')
      Text(`page theme: ${this.theme}`)
      Button('page toggle theme')
        .onClick(() => {
          this.theme = this.theme === 'light' ? 'dark' : 'light';
        })
      ThemePanel()
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}

@Component
struct ThemePanel {
  build() {
    Column({ space: 8 }) {
      Text('panel level')
      ThemeLeaf()
    }
  }
}

@Component
struct ThemeLeaf {
  @Consume('deepTheme') theme: string;

  build() {
    Button(`deep leaf: ${this.theme}`)
      .onClick(() => {
        this.theme = this.theme === 'light' ? 'dark' : 'light';
      })
  }
}
```

#### 预期输出

**验证标准**：

- ThemePanel 与 ThemeLeaf 迁为 @ComponentV2，DeepThemePage 保持 V1；为移除原 alias 通道，可将页面 theme 改为 V1 合法本地状态。
- 移除该场景的 deepTheme @Provide / @Consume，沿 page → panel → leaf 显式传值，并沿反方向逐层回传修改；不能用一半 V1、一半 V2 的同名 alias 假装互通。
- Panel 和 Leaf 的状态输入声明 @Param，修改请求声明 @Event；page 使用 V1 合法字段承接回调。
- 页面切换主题能更新深层叶子，叶子切换能更新页面；不能通过扩大迁移范围把 DeepThemePage 一并改为 V2。

---

### 测试用例：FUNC-NESTED-OBSERVED-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-NESTED-OBSERVED-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 NestedPage 中的完整场景到 V2，保持修改深层 city 属性后页面正确更新。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`NestedPage.ets`：

```ts
@Observed
class Address {
  public city: string;

  constructor(city: string) {
    this.city = city;
  }
}

@Observed
class User {
  public name: string;
  public address: Address;

  constructor(name: string, address: Address) {
    this.name = name;
    this.address = address;
  }
}

@Component
struct AddressView {
  @ObjectLink address: Address;

  build() {
    Column({ space: 8 }) {
      Text(`city: ${this.address.city}`)
      Button('change city')
        .onClick(() => {
          this.address.city += '!';
        })
    }
  }
}

@Entry
@Component
struct NestedPage {
  @State user: User = new User('Alice', new Address('New York'));

  build() {
    Column({ space: 16 }) {
      Text('Nested Observed Case')
      Text(`name: ${this.user.name}`)
      AddressView({ address: this.user.address })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- NestedPage 与 AddressView 迁为 @ComponentV2，User / Address 迁为 @ObservedV2，并对需要保留观察的 name、address、city 属性加 @Trace。
- AddressView 以 @Param 接收 Address，共享同一个对象；无默认值时带 @Require，不保留 @ObjectLink。
- 保留 this.address.city 的原地修改；深层 city 有观察能力，不通过整对象重建掩盖观察缺失，也不无故深拷贝切断原共享行为。

---

### 测试用例：FUNC-API18-COHORT

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-API18-COHORT

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 18。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 Child 到 V2，保持 Api18InteropPage V1。保持点击 Child 后父页面与 Child 显示相同值。 允许为完成边界契约最小联动父级创建点及必要 import / 回调，父级组件与数据模型保持原体系。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`Parent.ets`：

```ts
import { Child } from './Child';
import { Model } from './Model';

@Entry
@Component
struct Api18InteropPage {
  @State model: Model = new Model();

  build() {
    Column({ space: 16 }) {
      Text('API 18 Interop Case')
      Child({ model: this.model })
      Text(`parent value: ${this.model.value}`)
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

`Child.ets`：

```ts
import { Model } from './Model';

@Component
export struct Child {
  @ObjectLink model: Model;

  build() {
    Button(`child value: ${this.model.value}`)
      .onClick(() => {
        this.model.value++;
      })
  }
}
```

`Model.ets`：

```ts
@Observed
export class Model {
  value: number = 0;
}
```

#### 预期输出

**验证标准**：

- Child 迁为 @ComponentV2，Api18InteropPage 与 Model 保持 V1；允许最小联动父级创建点与回调。
- 在父级将 model.value 拆为 number 输入，以 @Param / @Event 建立标量下行与修改请求上行，不把 @Observed Model 作为 V2 的复杂对象输入。
- 点击后通过父级回调修改原 model.value，父子显示一致；不使用 API 19+ 的 enableV2Compatibility 或 makeV1Observed。
- 不擅自提高 API 18 的兼容下限，不将 Model 改为 @ObservedV2，不在 V2 Child 内混用 V1 组件状态装饰器。

---

### 测试用例：FUNC-V1-TO-V2-COMPAT-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-V1-TO-V2-COMPAT-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 V1ToV2Child 到 V2，V1ToV2Page 和其对象模型保持 V1。保持父组件修改对象属性后父子界面同步更新。 允许为完成边界契约最小联动父级创建点及必要 import / 回调，父级组件与数据模型保持原体系。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`V1ToV2Page.ets`：

```ts
@Observed
class V1Profile {
  name: string = 'v1-name';
}

@Component
struct V1ToV2Child {
  @ObjectLink profile: V1Profile;

  build() {
    Text(`v1 to v2 child: ${this.profile.name}`)
  }
}

@Entry
@Component
struct V1ToV2Page {
  @State profile: V1Profile = new V1Profile();

  build() {
    Column({ space: 12 }) {
      Text(`v1 owner: ${this.profile.name}`)
      Button('change v1 owner')
        .onClick(() => {
          this.profile.name = 'changed-by-owner';
        })
      V1ToV2Child({ profile: this.profile })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 仅 V1ToV2Child 迁为 @ComponentV2，以 @Require @Param 接收 profile；V1ToV2Page 与 V1Profile 保持 V1。
- 创建点使用 UIUtils.enableV2Compatibility(this.profile) 传递当前 V1 可观察对象，并从 @kit.ArkUI 导入 UIUtils。
- 保持同一个数据对象及父级 name 的原地修改；不深拷贝、不新增竞争状态、不把 V1Profile 改为 @ObservedV2。

---

### 测试用例：FUNC-V2-TO-V1-COMPAT-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-V2-TO-V1-COMPAT-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 V2ToV1Page 到 V2，LegacyProfileView 保持 V1 且继续接收同一个普通对象。保持父组件修改属性后父子界面同步更新。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`V2ToV1Page.ets`：

```ts
class PlainProfile {
  name: string = 'plain-name';
}

@Component
struct LegacyProfileView {
  @ObjectLink profile: PlainProfile;

  build() {
    Text(`legacy child: ${this.profile.name}`)
  }
}

@Entry
@Component
struct V2ToV1Page {
  @State profile: PlainProfile = new PlainProfile();

  build() {
    Column({ space: 12 }) {
      Text(`future v2 owner: ${this.profile.name}`)
      Button('change future v2 owner')
        .onClick(() => {
          this.profile.name = 'changed-by-owner';
        })
      LegacyProfileView({ profile: this.profile })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- V2ToV1Page 迁为 @ComponentV2，LegacyProfileView 保持 V1 的 @ObjectLink 契约，PlainProfile 保持普通类。
- 在稳定的初始化位置以 UIUtils.enableV2Compatibility(UIUtils.makeV1Observed(new PlainProfile())) 建立唯一可观察对象，或给出等价的先 V1 观察、再启用 V2 兼容的调用顺序。
- 父页与旧子组件读取同一份对象，保留 profile.name 原地修改；不把 @ObservedV2 对象或 makeObserved 结果交给旧 @ObjectLink，也不分别包装两份业务对象。

---

### 测试用例：FUNC-V2-TO-V1-LINK-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-V2-TO-V1-LINK-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 StepperPage 到 V2。LegacyStepper.ets 不得修改，必须保持 @Link 契约。保持页面与 LegacyStepper 的双向同步：任一侧修改步数后两侧显示一致。 允许在 StepperPage.ets 内新增必要的边界组件；只需静态给出代码并保持 LegacyStepper.ets 原代码，不要求做文件字节或设备运行验证。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`StepperPage.ets`：

```ts
import { LegacyStepper } from './LegacyStepper';

@Entry
@Component
struct StepperPage {
  @State step: number = 5;

  build() {
    Column({ space: 16 }) {
      Text('V2 To V1 Link Case')
      Text(`page step: ${this.step}`)
      Button('page step +1')
        .onClick(() => {
          this.step++;
        })
      Button('page step -1')
        .onClick(() => {
          this.step--;
        })
      LegacyStepper({ step: this.step })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

`LegacyStepper.ets`：

```ts
@Component
export struct LegacyStepper {
  @Link step: number;

  build() {
    Column({ space: 8 }) {
      Button(`legacy stepper: ${this.step}`)
        .onClick(() => {
          this.step++;
        })
    }
  }
}
```

#### 预期输出

**验证标准**：

- StepperPage 改为 @ComponentV2，由 @Local step 持有唯一业务状态，初值仍为 5；LegacyStepper.ets 保持原代码和 @Component / @Link 契约。
- 通过新增薄 V1 包装层接入旧 @Link，包装层用 V1 合法输入接收值，以普通回调回传修改；不能在 V2 页面中放入 @State / @Prop / @Link。
- 若用 @Watch 回传，必须写在被监听字段上，参数为回调方法名，不能把它写成方法上的 @Monitor 形式。
- 给出首次显示、父级加减、旧组件自增的完整下行与上行链路，以及避免无效重复回写或回环的处理；不能只读取一次父值，不能用标量调用对象兼容接口。

---

### 测试用例：FUNC-NESTED-CROSS-BOUNDARY-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-NESTED-CROSS-BOUNDARY-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 AddressChild 到 V2，NestedCrossPage 保持 V1、ProfileModels.ets 不得修改。保持原地修改 city、替换 address 后再修改 city 时子组件持续刷新。 允许为完成边界契约最小联动父级创建点及必要 import / 回调，父级组件与数据模型保持原体系。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`NestedCrossPage.ets`：

```ts
import { Address, User } from './ProfileModels';

@Entry
@Component
struct NestedCrossPage {
  @State user: User = new User('Alice', new Address('Paris'));

  build() {
    Column({ space: 16 }) {
      Text('Nested Cross Case')
      Text(`user name: ${this.user.name}`)
      Button('move city')
        .onClick(() => {
          this.user.address.city = 'Lyon';
        })
      Button('replace address')
        .onClick(() => {
          this.user.address = new Address('Rome');
        })
      AddressChild({ address: this.user.address })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}

@Component
struct AddressChild {
  @ObjectLink address: Address;

  build() {
    Text(`city child: ${this.address.city}`)
  }
}
```

`ProfileModels.ets`：

```ts
@Observed
export class Address {
  public city: string;

  constructor(city: string) {
    this.city = city;
  }
}

@Observed
export class User {
  public name: string;
  public address: Address;

  constructor(name: string, address: Address) {
    this.name = name;
    this.address = address;
  }
}
```

#### 预期输出

**验证标准**：

- AddressChild 迁为 @ComponentV2，使用 @Require @Param address；NestedCrossPage 仍为 V1，ProfileModels.ets 原样保留。
- 在 AddressChild 创建点对当前 this.user.address 调用 enableV2Compatibility，而非仅对初始 address 包装一次。
- 保留原地修改 city、整体替换 address 两条路径，替换后继续修改 city 仍有跨边界观察能力；不加 @ObservedV2、不深拷贝共享对象。

---

### 测试用例：FUNC-UNSUPPORTED-SENDABLE-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-UNSUPPORTED-SENDABLE-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 SendableBoundaryPage 到 V2，TaskRecord 和 LegacyTaskView 不在迁移范围内。保持原地修改任务进度后旧组件正确显示。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`SendableBoundaryPage.ets`：

```ts
import { LegacyTaskView, TaskRecord } from './TaskContract';

@Entry
@Component
struct SendableBoundaryPage {
  @State task: TaskRecord = new TaskRecord(1);

  build() {
    Column({ space: 12 }) {
      LegacyTaskView({ progress: this.task.progress })
      Button('advance sendable task')
        .onClick(() => {
          this.task.progress += 1;
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

`TaskContract.ets`：

```ts
@Sendable
export class TaskRecord {
  public progress: number;

  constructor(progress: number) {
    this.progress = progress;
  }
}

@Component
export struct LegacyTaskView {
  @Prop progress: number = 0;

  build() {
    Text(`legacy task progress: ${this.progress}`)
  }
}
```

#### 预期输出

**验证标准**：

- SendableBoundaryPage 迁为 @ComponentV2，在稳定初始化位置用 @Local task 与 UIUtils.makeObserved(new TaskRecord(1)) 建立 V2 本地观察。
- TaskContract.ets 中 @Sendable TaskRecord 和 V1 LegacyTaskView 原样保留；保留 task.progress += 1 的原地修改。
- 向旧组件仅传 progress 标量，不使用 makeV1Observed 或 enableV2Compatibility，不向 @Sendable 类强加 @ObservedV2 / @Trace。

---

### 测试用例：FUNC-STORAGE-PARTIAL-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-STORAGE-PARTIAL-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

只迁移 NewPage 到 V2，保持 NewPage 和其他数据源的双向同步关系。 LegacyPage.ets 不得修改；允许在 Index.ets 或新建薄 V1 包装层中接线，题面给出的三个文件是本用例全部相关读写方。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`Index.ets`：

```ts
import { LegacyPage } from './LegacyPage';
import { NewPage } from './NewPage';

@Entry
@Component
struct StoragePartialPage {
  build() {
    Column({ space: 16 }) {
      Text('Storage Partial Case')
      NewPage()
      LegacyPage()
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

`NewPage.ets`：

```ts
@Component
export struct NewPage {
  @StorageLink('token') token: string = '';

  build() {
    Button(`new: ${this.token}`)
      .onClick(() => {
        this.token = 'new-token';
      })
  }
}
```

`LegacyPage.ets`：

```ts
@Component
export struct LegacyPage {
  @StorageLink('token') token: string = '';

  build() {
    Text(`legacy: ${this.token}`)
  }
}
```

#### 预期输出

**验证标准**：

- NewPage 迁为 @ComponentV2，以 @Param / @Event 接收 token 和请求修改，V2 组件内不残留 @StorageLink。
- LegacyPage 保持 V1 且不修改；可在 Index.ets 或新增薄 V1 包装层中以 @StorageLink 持有 token，由其向 NewPage 传值并处理回写。
- 保留唯一的 V1 AppStorage token 数据源，旧读者持续接收 NewPage 的修改，外部对 token 的修改也持续向下同步。
- 不能仅用 @Local = AppStorage.get(...) 读取初值，也不能再建同名 AppStorageV2 连接冒充同步；说明保留的 V1 storage 所有者。

---

### 测试用例：FUNC-STORAGE-FULL-SWITCH-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-STORAGE-FULL-SWITCH-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 StorageSwitchPage 及其场景内组件到 V2，当前 benchScore key 已无其余地方使用，可以做完整迁移。 题面代码列出了该 key 的全部初始化和读写位置。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`StorageSwitchPage.ets`：

```ts
AppStorage.setOrCreate('benchScore', 7);

@Component
struct ScoreSummary {
  @StorageLink('benchScore') score: number = 0;

  build() {
    Text(`summary score: ${this.score}`)
  }
}

@Component
struct ScoreEditor {
  @StorageLink('benchScore') score: number = 0;

  build() {
    Column({ space: 8 }) {
      Text(`editor score: ${this.score}`)
      Button('increase from editor')
        .onClick(() => {
          this.score++;
        })
    }
  }
}

@Entry
@Component
struct StorageSwitchPage {
  @StorageLink('benchScore') score: number = 0;

  build() {
    Column({ space: 12 }) {
      Text(`page score: ${this.score}`)
      ScoreSummary()
      ScoreEditor()
      Button('reset app score')
        .onClick(() => {
          AppStorage.setOrCreate('benchScore', 7);
        })
      Button('increase from page')
        .onClick(() => {
          const current: number = AppStorage.get<number>('benchScore') ?? 0;
          AppStorage.setOrCreate('benchScore', current + 1);
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面与 ScoreSummary、ScoreEditor 均迁为 @ComponentV2，移除本场景的 @StorageLink 与 AppStorage 命令式调用。
- 使用 @ObservedV2 / @Trace 数据模型，并以 AppStorageV2.connect 的同一类型与连接标识建立唯一共享状态；全部使用者连接同一对象，或由该对象的明确所有者向下传递。
- 保持首次 score 为 7、编辑器加一、页面加一及重置回 7，不能遗留旧 V1 的创建、读取或重置路径。
- connect 提供有效默认创建器，并处理返回 undefined 的情况；不能以静默 new 多份对象或无条件非空断言制造独立的备用数据源。

---

### 测试用例：FUNC-FOREACH-EAGER-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-FOREACH-EAGER-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 EagerListPage 中的完整场景到 V2，保持全量加载、稳定条目身份和动态新增行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`EagerListPage.ets`：

```ts
@Entry
@Component
struct EagerListPage {
  @State values: string[] = ['eager-a', 'eager-b'];

  build() {
    Column({ space: 12 }) {
      Text('Eager List Case')
      Button('add eager item')
        .onClick(() => {
          this.values.push(`eager-${String.fromCharCode(97 + this.values.length)}`);
        })
      ForEach(this.values, (value: string) => {
        Text(value)
      }, (value: string) => value)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面迁为 @ComponentV2，自有数组改为 @Local，以非虚拟滚动的 Repeat 替换 ForEach，不调用 virtualScroll。
- each 回调接收 RepeatItem<string> 并用 item.item 取值；key 回调接收原始字符串，保持唯一稳定的字符串身份，不使用随机 key。
- 保留初始 eager-a / eager-b、全量加载与 push 新条目的行为，不引入懒加载或复用。

---

### 测试用例：FUNC-LAZY-NO-REUSE-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-LAZY-NO-REUSE-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 LazyListPage 中的完整场景到 V2，保持懒加载和动态新增行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`LazyListPage.ets`：

```ts
class LazyTextSource implements IDataSource {
  private values: string[] = ['lazy-a', 'lazy-b'];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.values.length;
  }

  getData(index: number): string {
    return this.values[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index: number = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  add(value: string): void {
    this.values.push(value);
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(this.values.length - 1);
    });
  }
}

@Entry
@Component
struct LazyListPage {
  private source: LazyTextSource = new LazyTextSource();

  build() {
    Column({ space: 12 }) {
      Text('Lazy List Case')
      Button('add lazy item')
        .onClick(() => {
          this.source.add('lazy-c');
        })
      List() {
        LazyForEach(this.source, (value: string) => {
          ListItem() {
            Text(value)
          }
        }, (value: string) => value)
      }
      .height('60%')
    }
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面迁为 @ComponentV2，用可观察数组或数据对象承载原 IDataSource 的条目与新增操作，不只把旧不可观察 source 换成 @Local。
- 使用 Repeat 的 each / key / virtualScroll({ reusable: false })，保留懒加载并明确关闭 item 复用；不误改为全量渲染或默认开启复用。
- each 通过 RepeatItem<string>.item 取值，初始 lazy-a / lazy-b 与新增 lazy-c 的更新路径完整。

---

### 测试用例：FUNC-REPEAT-REUSABLE-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-REPEAT-REUSABLE-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 CardsPage 中的完整场景到 V2，保持懒加载。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`CardsPage.ets`：

```ts
class CardSource implements IDataSource {
  private values: string[] = ['card-a', 'card-b', 'card-c'];

  totalCount(): number {
    return this.values.length;
  }

  getData(index: number): string {
    return this.values[index];
  }

  registerDataChangeListener(_listener: DataChangeListener): void {
  }

  unregisterDataChangeListener(_listener: DataChangeListener): void {
  }
}

@Reusable
@Component
struct ReusableCard {
  @State label: string = '';

  aboutToReuse(params: Record<string, Object>): void {
    this.label = params.label as string;
  }

  build() {
    Text(this.label)
      .height(56)
  }
}

@Entry
@Component
struct CardsPage {
  private source: CardSource = new CardSource();

  build() {
    Column() {
      Text('Repeat Reusable Case')
      List() {
        LazyForEach(this.source, (value: string) => {
          ListItem() {
            ReusableCard({ label: value })
          }
        }, (value: string) => value)
      }
      .height('80%')
    }
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- CardsPage 与场景内 item 迁为 V2，以可观察数组和 Repeat(...).virtualScroll() 替代 IDataSource / LazyForEach，不关闭复用。
- ReusableCard 的 label 由创建点传入，使用 @Param 接收并满足初始化声明要求；后续复用输入持续刷新，不以 @Once 丢弃新条目，也不能声明为接收外部值的 @Local。
- 不依赖原 aboutToReuse(params) 或 V2 aboutToReuse() 在 Repeat 路径中更新 label；说明该路径由 Repeat 管理复用。
- each 使用 RepeatItem<string>.item，保留 card-a / card-b / card-c 与稳定 key；若保留 @ReusableV2，不能宣称 Repeat 会调用其独立复用生命周期。

---

### 测试用例：FUNC-REUSABLE-IF-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-REUSABLE-IF-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 ReusableIfPage 中的完整场景到 V2，保持 if 场景下组件复用与输入刷新行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`ReusableIfPage.ets`：

```ts
@Reusable
@Component
struct ReusableIfCard {
  @State label: string = '';

  aboutToReuse(params: Record<string, Object>): void {
    this.label = params.label as string;
  }

  build() {
    Text(`reusable label: ${this.label}`)
      .padding(12)
  }
}

@Entry
@Component
struct ReusableIfPage {
  @State show: boolean = true;
  @State label: string = 'alpha';

  build() {
    Column({ space: 16 }) {
      Text('Reusable If Case')
      Button('hide reusable').onClick(() => {
        this.show = false;
      })
      Button('show beta').onClick(() => {
        this.label = 'beta';
        this.show = true;
      })
      if (this.show) {
        ReusableIfCard({ label: this.label })
          .reuseId('bench-if-card')
      }
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- ReusableIfPage 改为 @ComponentV2，ReusableIfCard 改为 @ReusableV2 @ComponentV2。
- 创建点 label 是外部输入，以 @Param 接收并满足默认值或 @Require 约束，不能机械改成 @Local。
- 将 reuseId 改为 .reuse({ reuseId: () => ... })；如保留 aboutToReuse，必须无参数，不读取旧 params。
- 保留初始 alpha，隐藏后点击 show beta 再次展示 beta 的输入更新路径；不能只靠自动重置状态猜测外部输入已刷新。

---

### 测试用例：FUNC-ANIMATE-TO-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-ANIMATE-TO-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 AnimatePage 到 V2，保持动画起始状态和结束状态的渲染时序。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`AnimatePage.ets`：

```ts
@Entry
@Component
struct AnimatePage {
  @State boxWidth: number = 80;
  @State phase: string = 'idle';

  build() {
    Column({ space: 16 }) {
      Text(`animation phase: ${this.phase}`)
      Row()
        .id('animation-box')
        .width(this.boxWidth)
        .height(40)
        .backgroundColor('#0A59F7')
      Button('run animation').onClick(() => {
        this.phase = 'prepared';
        this.boxWidth = 120;
        this.getUIContext().animateTo({ duration: 80 }, () => {
          this.phase = 'finished';
          this.boxWidth = 240;
        });
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面改为 @Entry @ComponentV2，boxWidth 与 phase 为组件自有 @Local 状态。
- 从 @kit.ArkUI 导入 UIUtils，把 phase = prepared 和 boxWidth = 120 两项动画前修改一起放入 UIUtils.applySync 闭包，并在其后调用原 animateTo。
- 保留 duration: 80、动画结束 phase = finished 与 boxWidth = 240，不只包装尺寸而漏掉阶段文本，也不把最终状态提前写入同步闭包。

---

### 测试用例：FUNC-API18-ANIMATE-LOW

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-API18-ANIMATE-LOW

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 18。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 AnimateLowPage 到 V2，保持动画起始状态和结束状态的渲染时序。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`AnimateLowPage.ets`：

```ts
@Entry
@Component
struct AnimateLowPage {
  @State boxWidth: number = 80;
  @State phase: string = 'idle';

  build() {
    Column({ space: 16 }) {
      Text(`animation phase: ${this.phase}`)
      Row()
        .id('animation-box')
        .width(this.boxWidth)
        .height(40)
        .backgroundColor('#0A59F7')
      Button('run animation')
        .onClick(() => {
          this.phase = 'prepared';
          this.boxWidth = 120;
          this.getUIContext().animateTo({ duration: 80 }, (): void => {
            this.phase = 'finished';
            this.boxWidth = 240;
          });
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面改为 @Entry @ComponentV2，自有状态迁为 @Local，不提高 API 18 兼容下限。
- 使用全局 animateToImmediately({ duration: 0 }, ...) 同步 phase = prepared 和 boxWidth = 120，之后调用原 getUIContext().animateTo。
- 保留 duration: 80 及 finished / 240 的结束状态；不使用 API 22+ 的 UIUtils.applySync，不虚构 animateToImmediately 的 Kit 导入。

---

### 测试用例：FUNC-LIST-SCROLL-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-LIST-SCROLL-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 ListScrollPage 到 V2，保持列表尺寸更新和滚动定位行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`ListScrollPage.ets`：

```ts
@Entry
@Component
struct ListScrollPage {
  private scroller: ListScroller = new ListScroller();
  @State childrenSize: ChildrenMainSize = new ChildrenMainSize(56);
  @State updateCount: number = 0;

  build() {
    Column({ space: 8 }) {
      Text(`size updates: ${this.updateCount}`)
      Button('increase item size').onClick(() => {
        this.childrenSize.childDefaultSize += 8;
        this.updateCount++;
      })
      Button('scroll to last item').onClick(() => {
        this.scroller.scrollToIndex(3);
      })
      List({ scroller: this.scroller, space: 4 }) {
        ListItem() { Text('list item 0').height('100%') }
        ListItem() { Text('list item 1').height('100%') }
        ListItem() { Text('list item 2').height('100%') }
        ListItem() { Text('list item 3').height('100%') }
      }
      .childrenMainSize(this.childrenSize)
      .height(150)
      .width('80%')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面改为 @Entry @ComponentV2，组件自有 childrenSize 和 updateCount 迁为 @Local；API 26 下保留 ChildrenMainSize 的直接观察使用方式。
- 保留 .childrenMainSize(this.childrenSize)、childDefaultSize += 8 和 updateCount++ 的关联，不用静态尺寸替代尺寸对象更新。
- 保留同一个 ListScroller 与 scrollToIndex(3) 定位行为，不将滚动控制器无故改成需要外部输入的 @Param。

---

### 测试用例：FUNC-CUSTOM-DIALOG-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-CUSTOM-DIALOG-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 DialogPage 到 V2，保持点击按钮打开和关闭自定义弹窗的行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`DialogPage.ets`：

```ts
@CustomDialog
struct BenchDialog {
  controller?: CustomDialogController;

  build() {
    Column({ space: 12 }) {
      Text('migration dialog content')
      Button('close migration dialog').onClick(() => {
        this.controller?.close();
      })
    }
    .padding(20)
  }
}

@Entry
@Component
struct DialogPage {
  private controller: CustomDialogController = new CustomDialogController({
    builder: BenchDialog()
  });

  build() {
    Column({ space: 16 }) {
      Text('Custom Dialog Case')
      Button('open migration dialog').onClick(() => {
        this.controller.open();
      })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- DialogPage 迁为 @ComponentV2，使用 @Builder 与 getUIContext().getPromptAction().openCustomDialog 打开内容，移除 @CustomDialog / CustomDialogController。
- 打开与关闭重载配对：ComponentContent 方式关闭同一内容实例，CustomDialogOptions 方式保存并关闭返回的 dialog id，不能把 Promise<void> 的完成值当成 id。
- 若使用 ComponentContent，第一参数为 UIContext，第二参数使用 wrapBuilder，泛型与实际参数类型一致，不写 ComponentContent<void>。
- 保留打开按钮、migration dialog content 和关闭按钮；句柄生命周期及 Promise 拒绝有合理处理，不仅给出无法关闭的弹窗。

---

### 测试用例：FUNC-MODIFIER-API26

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：B-MODIFIER-API26

#### 输入

这是独立 ArkTS 代码片段，目标和兼容版本均为 API 26。下列代码是全部输入，不依赖外部工程；本地 import 对应的文件均已附在本题。

迁移 ModifierPage 到 V2，保持运行时修改文字样式的行为。

请在回答中按文件名给出迁移后的完整代码和简短语义说明。只做静态分析，无需创建文件、调用构建或运行 UI 测试；不要声称这些验证已经通过。

`ModifierPage.ets`：

```ts
import { TextModifier } from '@kit.ArkUI';

class BenchTextModifier extends TextModifier {
  public useDarkStyle(): void {
    this.fontColor(Color.White);
    this.backgroundColor(Color.Black);
  }

  public useLightStyle(): void {
    this.fontColor(Color.Black);
    this.backgroundColor(Color.White);
  }
}

@Entry
@Component
struct ModifierPage {
  @State modifier: TextModifier = new BenchTextModifier().fontSize(22).padding(12);
  @State mode: string = 'light';

  build() {
    Column({ space: 16 }) {
      Text(`modifier mode: ${this.mode}`)
        .attributeModifier(this.modifier as BenchTextModifier)
      Button('toggle modifier').onClick(() => {
        if (this.mode === 'light') {
          (this.modifier as BenchTextModifier).useDarkStyle();
          this.mode = 'dark';
        } else {
          (this.modifier as BenchTextModifier).useLightStyle();
          this.mode = 'light';
        }
      })
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}
```

#### 预期输出

**验证标准**：

- 页面迁为 @ComponentV2，自有 mode 迁为 @Local，并保留 TextModifier 的正确导入及 BenchTextModifier 方法。
- 在稳定初始化位置使用 UIUtils.makeObserved 包装 modifier，保持 .attributeModifier(...) 读取同一个可观察修饰器。
- 保留原对象上 useDarkStyle / useLightStyle 的修改和 light / dark 状态切换，不通过每次点击重建 modifier 掩盖观察能力缺失。

---

### 测试用例：FUNC-PROP-OBJECT-ISOLATION

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：补充回归：可写 @Prop 对象隔离

#### 输入

下面是需要从 V1 迁为 V2 的独立 API 26 片段。父组件和子组件都在迁移范围内。请给出完整迁移代码：首次显示保持原值，子组件可修改本地草稿而不影响父级；父级随后修改对象属性或替换对象时仍覆盖草稿。只做静态分析，不要求构建。

```ts
class Draft {
  title: string = 'original';
  count: number = 1;
}

@Component
struct DraftEditor {
  @Prop draft: Draft;

  build() {
    Column() {
      Text(`${this.draft.title}: ${this.draft.count}`)
      Button('edit draft').onClick(() => {
        this.draft.title = 'local';
        this.draft.count += 1;
      })
    }
  }
}

@Entry
@Component
struct DraftOwner {
  @State draft: Draft = new Draft();

  build() {
    Column() {
      Text(`owner: ${this.draft.title}: ${this.draft.count}`)
      DraftEditor({ draft: this.draft })
      Button('change owner').onClick(() => { this.draft.title = 'parent'; })
      Button('replace owner').onClick(() => { this.draft = new Draft(); })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 说明 V1 @Prop 对复杂对象深拷贝且本地可写；V2 普通 @Param 接收引用、禁止字段直接重新赋值，但对象属性可被修改，并不是深度只读。
- 父子迁为 @ComponentV2，数据模型以 @ObservedV2 / @Trace 或明确等价方式建立属性观察；输入使用 @Param，草稿使用独立可写本地对象。
- 初始化和后续父更新时按业务类型复制 title / count，草稿与父对象不共享可变状态；不能用 this.localDraft = this.inputDraft 充当复制。
- 既处理父对象替换，也处理 title 等属性的原地修改；不能只监听对象引用而漏掉父属性更新。
- 子级修改不回写父级，父更新会覆盖本地草稿；不以 @Once 丢弃后续同步，不以 @Event 直接修改父对象冒充原 @Prop 行为。

---

### 测试用例：FUNC-PARAM-REQUIRE

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：补充回归：无默认值输入的声明约束

#### 输入

这是从 V1 迁移后产生的独立片段，API 26。编译提示无本地初始化器的 @Param 需要 @Require，但父组件已经传值。title 与 seed 业务上都必须外部提供，没有合法兜底默认值。请说明原因并给出修复后的完整代码，保留只接收 seed 初值、title 持续同步的区别；不用运行编译。

```ts
@ComponentV2
struct Child {
  @Param title: string;
  @Param @Once seed: number;

  build() {
    Button(`${this.title}: ${this.seed}`).onClick(() => { this.seed++; })
  }
}

@ComponentV2
struct Owner {
  @Local title: string = 'parent';
  @Local seed: number = 30;

  build() {
    Child({ title: this.title, seed: this.seed })
  }
}
```

#### 预期输出

**验证标准**：

- 解释声明级约束：调用点传值不能替代无默认值 @Param 的 @Require，@Once 也不能豁免。
- title 修为 @Require @Param，seed 同时声明 @Require / @Param / @Once，装饰器排列顺序不作为判分条件。
- 保留两个必填创建点参数，不新增空字符串或 0 等虚构默认值，不把输入改成禁止外部初始化的 @Local。
- title 持续接收父更新且不可本地重新赋值；seed 仅初次同步并允许本地自增，不声称实际编译通过。

---

### 测试用例：FUNC-MIXED-DECORATOR-ERROR

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：补充回归：组件体系与外部输入错误

#### 输入

以下是一次 V1 → V2 局部迁移的错误结果。只把 Child 修成 V2，Owner 必须保持 V1；允许最小联动 Child 创建点。label 应持续接收父更新。请给出完整修复代码并解释错误原因，不要求构建。

```ts
@Component
struct Child {
  @Local label: string = '';
  build() { Text(this.label) }
}

@Component
struct Owner {
  @State label: string = 'parent';
  build() {
    Column() {
      Child({ label: this.label })
      Button('change').onClick(() => { this.label = 'next'; })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 指出 @Component 中不能使用 V2 组件状态装饰器，且 @Local 不能接收创建点外部初始化。
- 将 Child 改为 @ComponentV2，label 使用有合法默认值的 @Param，或无默认值时使用 @Require @Param。
- Owner 保持 @Component / @State，字符串直接传值；不扩大迁移范围、不使用 @Once 丢弃后续 label 更新、不引入对象兼容接口。

---

### 测试用例：FUNC-STORAGE-DUAL-OWNER

**skill**：hmos-arkui-v1-v2-migration-and-mixusage
**类型**：functional
**素材来源**：补充回归：同名 storage key 不会自动互通

#### 输入

一次局部 V1 → V2 迁移后，V1 页面仍通过 @StorageLink('tenant') 读写 AppStorage 字符串，而 V2 页面另用 AppStorageV2.connect(TenantState, 'tenant', () => new TenantState()) 保存 tenant，结果两边值不同步。V1 页面暂时不能迁移，tenant 必须继续共享。请分析原因，给出最小改造方案、状态所有者和两个方向的验证步骤；不需要完整工程或实际编译。

#### 预期输出

**验证标准**：

- 识别 V1 AppStorage 与 AppStorageV2 是两套独立状态，相同字符串 key 不建立同步，不把问题仅归因于装饰器拼写。
- 保留一个 V1 storage 所有者，使用 @StorageLink 持续接收旧通道更新，V2 以 @Param 接收当前值并通过 @Event 请求写回。
- 删除为同一业务状态建立的独立 V2 存储或明确停用其所有权，不使用两边各自持有真值的双向 Monitor 复制方案。
- 验证步骤覆盖首次显示、V1 / 外部写入向 V2 刷新、V2 回写后旧 V1 读者刷新；不能用 @Local 读取一次 AppStorage.get 代替持续同步。
