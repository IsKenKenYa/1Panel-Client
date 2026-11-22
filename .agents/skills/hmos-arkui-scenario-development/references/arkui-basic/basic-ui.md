
# 基础 UI 场景

## 装饰器选型：局部 UI 用 @LocalBuilder，全局 UI 用 @Builder

**判断依据只有「声明位置」一个维度**，按下表二选一（没有中间地带）：

| 声明位置 | 必须使用 | `this` 绑定 | 适用 |
|---|---|---|---|
| struct **内部**（成员方法） | `@LocalBuilder` | 始终绑定到**所属组件** | 组件内部默认兜底、本组件内 UI 结构化拆分、需要读 `this.xxx`  |
| struct **外部**（全局函数） | `@Builder function` | 无 `this`、无独立状态 | 空态占位、通用标签等**无状态**展示片段，跨组件/跨文件复用 |

**核心规则：**

- 写在 struct **内** → 一律 `@LocalBuilder`。
- 写在 struct **外**、不依赖任何组件 `this` → 一律 `@Builder function`。
- 下文各场景中「组件内部的默认兜底渲染方法」均用 `@LocalBuilder`。

## SCENE-01 组件 UI 占位场景

**适用场景：** 当组件内部某块 UI 区域（如菜单栏、内容区）希望既能在使用方未传入时显示默认样式，又能被使用方按需覆盖时使用。通过 `@BuilderParam` 声明占位符/插槽并在初始化时绑定到组件自身的 `@LocalBuilder` 方法，组件对外暴露「可替换 + 有兜底」的 UI 入口，避免使用方必须显式传入而导致样板代码。

**与普通成员变量的区别：** 普通成员变量只能承载基本数据或对象引用，无法承载 UI 片段；`@BuilderParam` 接收一个返回 UI 的构建函数，使使用方可以传入任意 ArkUI 声明式结构（含状态、事件、子组件）作为组件子树。

**实现步骤：**

1. **声明默认兜底的 `@LocalBuilder` 方法**：在组件内定义作为默认渲染结构的 `@LocalBuilder` 成员方法（如 `titleExpansionMenu` / `titleExpansionContent`），方法体可为空实现（无 UI）或包含占位结构（如 `Text("Text")`），作为使用方未传入占位符/插槽时的兜底渲染
2. **声明 `@BuilderParam` 并绑定默认值**：用 `@BuilderParam` 声明占位符/插槽成员，类型签名统一为 `() => void`，初始化时将默认值赋为步骤 1 中的 `@LocalBuilder` 方法引用（如 `@BuilderParam menu: () => void = this.titleExpansionMenu`），让使用方不传参时自动走兜底逻辑
3. **在 `build()` 中调用占位符/插槽**：通过 `this.menu()` / `this.content()` 直接调用占位符/插槽函数，调用位置即 UI 嵌入位置，语法与普通成员方法调用一致；占位符/插槽内部声明的 UI 树会被嵌入到调用处
4. **使用方按需覆盖**：实例化组件时，不传参则渲染默认 `@LocalBuilder`；若传入新的 `@LocalBuilder`（局部）或全局 `@Builder function`（如 `TitleExpansion({ menu: this.customMenu, content: this.customContent })`）则覆盖默认值，实现「可替换 + 有兜底」的对外接口

```typescript
@Component
export struct TitleExpansion {
  // 主标题及子标题属性、动效属性等普通成员变量略
  titleAttribute: TitleAttribute = new TitleAttribute(Constants.MEMO_TITLE, new TitleAttributeModifier());
  subTitleAttribute: TitleAttribute = new TitleAttribute(Constants.MEMO_SUB_TITLE, new SubTitleAttributeModifier());
  animationAttribute: AnimationAttribute = new AnimationAttribute(Constants.NORMAL_TITLE_HEIGHT,
    Constants.EXPAND_TITLE_HEIGHT, Constants.CONTINUE_PULL_THRESHOLD,
    Constants.TITLE_SCALE_MAX_VALUE, Constants.ANIMATION_DURATION);

  // ① 声明占位符/插槽：以组件内部 @LocalBuilder 作为默认值，使用方未传入时兜底渲染
  @BuilderParam menu: () => void = this.titleExpansionMenu;
  @BuilderParam content: () => void = this.titleExpansionContent;

  build() {
    RelativeContainer() {
      RelativeContainer() {
        Column() {
          Text(this.titleAttribute.text)
            .attributeModifier(this.titleAttribute.attribute)
          Text(this.subTitleAttribute.text)
            .attributeModifier(this.subTitleAttribute.attribute)
        }

        // ② 菜单占位符/插槽：调用 this.menu() 渲染传入或默认的 UI
        Column() {
          this.menu();
        }
        .id("titleImage")
        .height(Constants.ONE_HUNDRED_PERCENT)
      }

      List({ space: Constants.SEARCH_MEMO_SPACE }) {
        ListItem() {
          // ③ 内容占位符/插槽：调用 this.content() 渲染传入或默认的 UI
          this.content();
        }
      }
    }
  }

  /** 默认菜单样式：空实现兜底 */
  @LocalBuilder
  titleExpansionMenu(): void {
  }

  /** 默认内容样式：占位文案兜底 */
  @LocalBuilder
  titleExpansionContent(): void {
    Column() {
      Text("Text")
    }
      .height(Constants.ONE_HUNDRED_PERCENT)
      .width(Constants.ONE_HUNDRED_PERCENT)
  }
}
```

---

## SCENE-02 组件单元封装场景

**适用场景：** 需要把自定义 UI 单元封装成可独立使用的组件或片段的场合。ArkUI 提供三种粒度不同的封装方案，根据"是否有内部状态"和"封装范围"两个维度选择合适的装饰器：

- `@Component` / `@ComponentV2` 适合实现**内部状态管理的组件**——有自己的状态能力，可作为独立功能单元嵌入任意位置（购物车商品项、表单输入项、可展开卡片等）。`@ComponentV2` 的作用与 `@Component` 完全一致，区别仅在于配套的状态装饰器体系不同（V1 用 `@State`/`@Prop`/`@Link`，V2 用 `@Local`/`@Param`/`@Once`/`@Event` 等）
- `@Builder` 适合实现**全局的简单 UI 封装片段**——无独立状态，定义在 struct 外部（`@Builder function xxx`），可跨组件/跨文件使用，用于无状态展示型片段（空态占位、通用价格标签、加载骨架）
- `@LocalBuilder` 适合实现**局部的简单 UI 封装片段**——无独立状态，定义在 struct 内部（成员方法），仅在当前组件内使用，不对外暴露，用于本组件内的小块 UI 结构化拆分

**核心机制：** 三者都能产出可重复调用的 UI 单元，但能力边界不同。`@Builder` 与 `@LocalBuilder` 是平行的"全局 vs 局部"关系——前者声明在 struct 外部可跨文件调用，后者声明在 struct 内部仅当前组件可用；两者都无独立状态，纯粹用于 UI 结构封装。`@Component` 与 `@ComponentV2` 是同一装饰器的两代实现，作用相同、能力对等，但二者**互斥**——同一 struct 只能用其一，且配套状态装饰器不能跨版本混用。

**选型决策树：**

1. **需要内部状态管理？** 是（选中、数量、展开、输入等）→ `@Component` 或 `@ComponentV2`（新项目推荐 V2，旧项目沿用 V1；二者不能混用）
2. **无状态，需跨文件/跨组件封装？** 是 → 全局 `@Builder function`
3. **无状态，仅封装在当前组件内？** 是 → `@LocalBuilder`

**实现步骤：**

1. **按“是否需要内部状态 + 封装范围”选型**：参照上方选型决策树二选一/三选一——需要内部状态用 `@Component` / `@ComponentV2`；无状态且需跨组件、跨文件封装用全局 `@Builder function`；无状态且仅封装在当前组件内用 `@LocalBuilder`
2. **实现状态型封装单元（`@ComponentV2` / `@Component`）**
3. **实现全局无状态片段（`@Builder function`）**：在 struct **外部** 用 `@Builder function xxx()` 声明，可带参数；`export` 后跨文件 `import` 调用，传入不同参数即产出不同 UI
4. **实现局部无状态片段（`@LocalBuilder`）**：在 struct **内部** 声明为成员方法，可直接读 `this.xxx`；带参数的 `@LocalBuilder` 可收敛本组件内多处重复结构
5. **跨文件使用**：状态型组件与全局 `@Builder` 一律 `export` 定义、`import` 使用；`@LocalBuilder` 因绑定 `this` 不跨文件

#### 状态型封装单元：@ComponentV2（V2）

```typescript
// 封装单元：自带状态、可独立嵌入任意父级（V2 写法）
// V1 等价：@Component + @Require @Prop data / @State active / @Watch('externalToggle') + 回调成员变量
@ComponentV2
export struct UnitItem {
  @Require @Param data: ItemData;            // ① 父级必须传入的数据
  @Require @Param externalToggle: boolean;   // ① 父级下发的指令

  @Local active: boolean = false;            // ② 仅组件内部读写
  @Event onStateChange: (id: string, active: boolean) => void = () => {};  // ③ 上报父级

  // ④ V2 用 @Monitor 监听父级指令（V1 用 @Watch）
  @Monitor('externalToggle')
  onExternalToggle(monitor: IMonitor): void {
    this.active = this.externalToggle;
    this.onStateChange(this.data.id, this.active);
  }

  build() {
    Row() {
      Text(this.data.title).fontSize(14).layoutWeight(1)
      Toggle({ type: ToggleType.Checkbox, isOn: this.active })
        .onChange((on: boolean) => {
          this.active = on;
          this.onStateChange(this.data.id, on);
        })
    }
    .padding(12)
  }
}
```

#### 无状态片段：@Builder（全局）与 @LocalBuilder（局部）

```typescript
// 全局无状态片段：定义在 struct 外部，跨文件使用（空态占位、通用标签等）
@Builder
export function EmptyHint(text: ResourceStr) {
  Column() {
    Text(text).fontSize(14).fontColor('#999999')
  }
  .padding(20)
}

@Entry
@ComponentV2
struct HostPage {
  @Local items: ItemData[] = [];

  build() {
    Column() {
      if (this.items.length === 0) {
        EmptyHint('暂无数据')        // 调用全局 @Builder function
      }
      this.Footer()                  // 调用本组件 @LocalBuilder
    }
  }

  // 局部无状态片段：定义在 struct 内部，仅当前组件可用，可直接访问外层 @Local
  @LocalBuilder
  Footer() {
    Text(`共 ${this.items.length} 项`).fontSize(12)
  }
}
```

---

## SCENE-03 组件样式复用场景

**适用场景：** 页面中存在大量重复的样式组合（圆角卡片容器、价格文本的"字号+颜色+粗体+省略号"组合、主按钮的"背景色+字号+圆角"组合等），直接写在每个组件上会导致大量样板代码且后续改样式要逐处修改。用 `AttributeModifier` 把"样式 + 业务逻辑"封装成可复用的 Modifier 对象，支持跨文件导出、传参、多态样式与 `if/else` 业务逻辑——能力优于 `@Styles`/`@Extend`（后者编译期处理、不支持跨文件导出、不支持业务逻辑）。

**核心机制：** 实现 `AttributeModifier<T>` 接口，泛型 `T` 决定样式作用的组件范围。通用样式（容器外观、布局对齐）用 `CommonAttribute`，可挂到任意组件；特定组件专属样式（文本字号、图片缩放、按钮形态）用组件对应的 Attribute 类型（`TextAttribute`/`ImageAttribute`/`ButtonAttribute`）。在 `applyNormalAttribute(instance)` 中通过 `instance` 链式设置属性；需要按参数变化的样式，通过构造函数传参 + 成员变量承载；组件首次初始化或关联状态变量变化时自动重新触发 `applyNormalAttribute`。一个 Modifier 实例可挂到多个组件复用。

**选型决策树：**

1. **样式是否绑定特定组件类型？** 是（仅 Text/Image/Button 等专属属性组合）→ Modifier 的 `T` 设为该组件的 Attribute 类型（如 `TextAttribute`）
2. **是否通用样式（与组件类型无关）？** 是 → Modifier 的 `T` 设为 `CommonAttribute`，可挂任意组件
3. **需要按参数变化？** 是 → 构造函数传参 + 成员变量，`applyNormalAttribute` 内读取（参数化样式天然支持，无需像 `@Styles` 那样受限）
4. **需要跨文件复用？** 是 → `export` Modifier 类（`@Styles`/`@Extend` 无法跨文件）
5. **需要按压/焦点/禁用/选择等多态样式？** 是 → 额外实现 `applyPressedAttribute`/`applyFocusedAttribute` 等

**实现步骤：**

1. **梳理样式复用需求**：先列出页面中所有重复出现的样式单元，逐项判断两个维度——「是否绑定特定组件」（决定 Modifier 的泛型 `T`）与「是否需要传参」（决定是否走构造函数传参）。示例归类如下：

   | 样式单元 | 是否绑定特定组件 | 是否需要传参 |
   |---------|---------------|-----------|
   | 通用卡片容器（白底 / 圆角 / 内边距） | 否（可挂任意容器） | 否（外观固定） |
   | 区块 / 栏背景（底色 + 固定高度） | 否（可挂任意容器） | 否 |
   | 强调文本（字号 + 颜色 + 粗体） | 是（仅 Text） | 是（字号、颜色随场景） |
   | 缩略图（宽高 + 圆角） | 是（仅 Image） | 是（圆角随场景） |
   | 主操作按钮（背景色 + 圆角） | 是（仅 Button） | 是（背景色随场景） |

   由表得出实现方向：**绑定特定组件** → 泛型 `T` 取对应 Attribute 类型（`TextAttribute` / `ImageAttribute` / `ButtonAttribute`）；**不绑定** → `T` 取 `CommonAttribute`，可挂任意组件；**需要传参** → 构造函数传参 + 成员变量承载，**不需要** → 直接实例化复用。

2. **实现 `AttributeModifier<T>`**：在 `applyNormalAttribute(instance)` 内用 `instance` 链式设置属性；需要按参数变化的样式，通过构造函数传参 + 公有成员变量承载，方法内读取
3. **决定作用域**：需跨文件复用 → 在 struct 外部 `export` 定义；仅当前页面使用、无需对外暴露 → 不导出，文件内私有
4. **实例化并挂载**：组件用**成员变量持有 Modifier 实例**（一个实例可挂到多个组件复用），`build()` 中用 `.attributeModifier(this.xxx)` 挂载；参数固定的样式创建一次即可多处复用，参数随调用点不同的样式按需 `new` 多个实例
5. **（可选）多态样式**：按压 / 焦点 / 禁用 / 选择等交互状态，额外实现 `applyPressedAttribute` / `applyFocusedAttribute` / `applyDisabledAttribute` 等方法，框架在各状态下自动调用对应方法

#### 定义 Modifier：通用容器 / 参数化专属 / 页面私有

```typescript
// ① 通用容器样式：T = CommonAttribute，可挂到 Row/Column 等任意组件
export class CardModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor(Color.White).borderRadius(16).padding(12);
  }
}

// ② 参数化专属样式：T = TextAttribute，构造传参（字号、颜色）
export class EmphasizedTextModifier implements AttributeModifier<TextAttribute> {
  public size: number;
  public color: ResourceColor;
  constructor(size: number, color: ResourceColor) {
    this.size = size;
    this.color = color;
  }
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(this.size).fontColor(this.color).fontWeight(FontWeight.Bold);
  }
}

// ③ 页面私有样式：不导出，仅当前文件可用
class SectionModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor('#F5F5F5').height(56);
  }
}
```

#### 成员变量持有实例并复用挂载

```typescript
@Entry
@Component
struct StyleDemoPage {
  // 成员变量持有 Modifier 实例：参数固定，创建一次即可在多个组件上复用
  private cardModifier: CardModifier = new CardModifier();
  private sectionModifier: SectionModifier = new SectionModifier();
  private titleModifier: EmphasizedTextModifier = new EmphasizedTextModifier(16, '#333333');
  private priceModifier: EmphasizedTextModifier = new EmphasizedTextModifier(18, '#FF4D4F');

  @LocalBuilder Item(title: string, price: string) {
    Column() {
      Text(title).attributeModifier(this.titleModifier)   // TextAttribute（复用同一类、不同实例）
      Text(price).attributeModifier(this.priceModifier)   // TextAttribute
    }
    .attributeModifier(this.cardModifier)                 // CommonAttribute 容器
  }

  build() {
    Column() {
      Row() {
        Text('样式复用示例')
      }
      .attributeModifier(this.sectionModifier)            // CommonAttribute 容器

      this.Item('单元 A', '¥99')                          // 同一 Modifier 实例被多次复用
      this.Item('单元 B', '¥199')
    }
  }
}
```

---
