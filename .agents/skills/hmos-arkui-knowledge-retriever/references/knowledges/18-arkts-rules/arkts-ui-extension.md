# @Builder/@LocalBuilder/@BuilderParam UI 复用装饰器约束

## 1. 核心禁止项（共用）

**@Builder / @LocalBuilder 严格禁止在其内部定义状态变量或使用自定义组件的生命周期函数。**

- 仅用于封装可复用的 UI 结构，内部 UI 结构固定，通过参数传递或访问所属组件的状态变量完成数据交互。
- 禁止在函数内声明 `@State`、`@Prop`、`@Link`、`@Local` 等状态变量。
- 禁止在函数内使用 `aboutToAppear`、`aboutToDisappear`、`aboutToReuse` 等生命周期回调。
- 如需使用状态变量或生命周期，应使用 `@Component` 装饰器定义自定义组件。

---

## 2. @Builder vs @LocalBuilder 全面对比

### 2.1 基本特性对比

| 对比项 | @Builder                            | @LocalBuilder |
|--------|-------------------------------------|---------------|
| 最低 API 版本 | 7                                   | 12 |
| 声明位置 | 全局或组件内部                             | **仅**组件内部（禁止全局声明） |
| 全局自定义构建函数 | 支持                                  | 禁止 |
| 装饰静态函数 | —                                   | 禁止 |
| 与其他装饰器组合 | 禁止                                  | 禁止 |
| this 指向 | 指向**实际调用点**的组件（可能被 .bind() 改变）      | 始终指向**声明该函数**的组件，无法被改变 |
| 组件父子关系 | 跨组件传递时 .bind(this) 可能导致父子关系与状态管理不一致 | 无论是否 .bind(this)，父子关系始终一致 |
| 设计目的 | 轻量 UI 复用                            | 维持确定的组件父子关系 |

### 2.2 跨组件传递行为差异

父组件将函数通过 `@BuilderParam` 传递给子组件时：

```typescript
@Component
struct Child {
  @BuilderParam customBuilderParam: () => void;
  build() {
    Column() {
      this.customBuilderParam()  // 调用点在 Child 中
    }
  }
}

@Entry
@Component
struct Parent {
  label: string = 'Parent';

  @Builder componentBuilder() {
    Text(`${this.label}`)  // this 指向调用点 Child → 显示 Child 的 label
  }

  @LocalBuilder componentLocalBuilder() {
    Text(`${this.label}`)  // this 始终指向声明组件 Parent → 显示 "Parent"
  }

  build() {
    Column() {
      Child({ customBuilderParam: this.componentBuilder })         // @Builder → "Child"
      Child({ customBuilderParam: this.componentLocalBuilder })    // @LocalBuilder → "Parent"
      Child({ customBuilderParam: () => { this.componentBuilder() } })  // 箭头函数 → "Parent"
    }
  }
}
```

| 传递写法 | @Builder this 指向 | @LocalBuilder this 指向 |
|----------|-------------------|----------------------|
| `this.componentBuilder` | 调用点组件（Child） | 声明组件（Parent） |
| `() => { this.componentBuilder() }` | 声明组件（Parent） | 声明组件（Parent） |

### 2.3 跨页面传递行为差异

@Builder 跨页面传递时，this 指向**声明页面**，以声明页面的参数为准。

| 对比项 | 跨组件传递 | 跨页面传递 |
|--------|-----------|-----------|
| this 指向 | 调用点组件（可被 .bind 改变） | **声明页面**，固定不变 |
| 箭头函数传参 | 允许，可绑定回声明组件 | **禁止**，不允许通过箭头函数传参 |
| 参数来源 | 调用点组件的状态变量 | 以**声明页面**的参数为准 |

### 2.4 推荐使用场景

| 位置 | 推荐装饰器 | 原因 |
|------|-----------|------|
| **自定义组件内部**（`@Component` / `@ComponentV2` 装饰的 struct 内） | **@LocalBuilder** | this 始终绑定声明组件，父子关系确定，避免跨组件传递时 this 漂移导致的刷新异常 |
| **自定义组件外部**（全局作用域、跨文件复用） | **@Builder** | 支持全局声明，可被任意组件引用；配合 `wrapBuilder` / `mutableBuilder` 赋值给变量传递 |

**判定原则**：

- 函数需要被**多个组件/页面共享**、跨文件复用 → **@Builder**（全局声明）。
- 函数仅服务于**当前组件内部** UI 片段封装，且需通过 `@BuilderParam` 暴露给子组件 → **@LocalBuilder**（保证 this 与父子关系稳定）。

**反例与修正**：

```typescript
// ❌ 组件内部使用 @Builder：跨组件传递时 this 指向调用点，状态变量可能不刷新
@Component
struct Parent {
  @Builder itemBuilder() { Text(`${this.label}`) }  // 传给 Child 后 this 指向 Child
}

// ✅ 组件内部使用 @LocalBuilder：this 始终绑定 Parent，刷新行为可预期
@Component
struct Parent {
  @LocalBuilder itemBuilder() { Text(`${this.label}`) }
}

// ❌ 在组件内部声明本应全局复用的 @LocalBuilder：无法跨文件复用
// ✅ 全局共享 UI 片段使用 @Builder
@Builder
function GlobalCard(title: string) { /* ... */ }
```

---

## 3. 限制条件对比

### 3.1 共用限制

| # | 限制 | 说明 |
|---|------|------|
| 1 | 禁止修改参数值 | 未使用 MutableBinding 时，修改参数值不触发 UI 刷新；按引用传递单参数时修改属性抛运行时错误（API 23 起错误码 140109）。 |
| 2 | 按引用传递仅单参数有效 | 仅传**一个 `{}` 对象字面量参数**时可触发动态渲染。 |
| 3 | 多参数不触发刷新 | 两个及以上参数且未使用按回调传递时，不触发动态渲染。 |
| 4 | 混合传递不触发刷新 | 同时包含按值和按引用传递时，不触发动态渲染。 |
| 5 | 禁止修改参数属性 | 否则抛运行时错误（API 23 起错误码 140109）。使用 MutableBinding 可安全修改。 |

### 3.2 @LocalBuilder 独有限制

| # | 限制 | 说明 |
|---|------|------|
| 1 | 禁止全局声明 | 只能在所属组件内声明。 |
| 2 | 禁止组合装饰器 | 不能与其他内置/自定义装饰器一起使用。 |
| 3 | 禁止装饰静态函数 | 不能用来装饰 static 方法。 |
| 4 | 传递方式建议 | 优先传递**函数本身**（`this.myBuilder`），或 `() => { 函数调用 }`，避免传递执行结果赋值给变量。 |

---

## 4. 参数传递规则对比

### 4.1 通用规则（共用）

- 参数类型**不允许**为 `undefined`、`null` 或返回 `undefined`/`null` 的表达式。
- 函数内部**不允许改变参数值**（不使用 MutableBinding 时）。
- 内部 UI 语法遵循 UI 语法规则。
- 无装饰器修饰的普通变量整体赋值不会触发刷新。
- 多层嵌套时，若要实现最内层的动态 UI 刷新，**每层调用都必须使用按引用传递**；任意一层改为按值传递，则从该层往内层刷新失效。
- 联合 V2 装饰器（`@ComponentV2` + `@ObservedV2`/`@Trace`）：必须使用**按值传递**（按引用传递会被 ArkTS 语法拦截），修改 `@Trace` 属性可触发 UI 刷新；简单类型按值传递不触发刷新；`@Local` 装饰对象引用传递时整体赋值可触发刷新。

### 4.2 三种传递方式对比

| 传递方式 | 语法形式 | UI 刷新 | 适用场景 |
|----------|---------|---------|---------|
| **按回调传递**（API 20+） | `UIUtils.makeBinding(() => val)` | 支持 | 需要读写同步的场景 |
| **按引用传递** | `builder({ key: this.state })` — **必须 `{}` 对象字面量** | 支持（仅单参数时） | 需要监听状态变量变化的场景 |
| **按值传递**（默认） | `builder(this.state)` 或 `builder(someObj)` | **不支持** | 不涉及状态变量的纯静态 UI |

**关键区分：** 必须使用 `{}` 对象字面量形式传参才属于按引用传递，否则一律视为按值传递。

```typescript
// 按引用传递 — {} 对象字面量，状态变量变化可触发 UI 刷新
overBuilder({ paramA1: this.label })

// 按值传递 — 非 {} 形式，状态变量变化不触发 UI 刷新
overBuilder(this.label)
overBuilder(someObj)
```

### 4.3 按回调传递参数（共用，API 20+）

使用 `UIUtils.makeBinding()` 包装读写回调：

| 类型 | 传入 | 效果 |
|------|------|------|
| **Binding\<T\>** | 仅读回调 | 支持 @Builder 内 UI 组件刷新 |
| **MutableBinding\<T\>** | 读回调 + 写回调 | 支持 UI 刷新 + 属性修改同步回父组件 |

```typescript
customButton(
  UIUtils.makeBinding<number>(() => this.number1),                              // Binding — 只读
  UIUtils.makeBinding<number>(() => this.number2, val => { this.number2 = val; }) // MutableBinding — 读写
)
```

### 4.4 @LocalBuilder 按引用传递的额外约束

当**子组件**调用父组件的 @LocalBuilder 函数并传入状态变量时，子组件参数变化**不会**引起 @LocalBuilder 内 UI 刷新：

| 场景 | @Builder | @LocalBuilder |
|------|----------|---------------|
| 子组件传入参数变化 | 触发 UI 刷新（this 指向子组件） | **不触发** UI 刷新（this 指向父组件） |

**解决方式：** 在声明 @LocalBuilder 的父组件内维护状态变量，通过 `this` 访问；子组件通过 `@Link` 双向绑定修改父组件状态变量来驱动刷新。

---

## 5. @BuilderParam 传递方式与限制

### 5.1 三种传递方式对比

| 传递方式 | 语法形式 | this 指向 | UI 刷新感知                   |
|----------|---------|----------|---------------------------|
| **参数传递** | `Child({ param: this.componentBuilder })` | 指向**子组件**（调用点） | 父组件状态变量变化时**不感知**，子组件无法刷新 |
| **箭头函数传递** | `Child({ param: () => { this.componentBuilder() } })` | 指向**父组件**（宿主对象） | 父组件状态变量变化时**可感知**，UI 正常刷新 |
| **尾随闭包传递** | `Child({ header: this.text }) { this.componentBuilder() }` | 指向**父组件** | -                         |

### 5.2 尾随闭包特殊规则

- 子组件内**有且仅有一个** `@BuilderParam`。
- 接收尾随闭包的 `@BuilderParam` **不能有参数**。
- 尾随闭包场景下，子组件**不支持通用属性**(如：onClick等)。

### 5.3 限制条件

| # | 限制                               | 说明 |
|---|----------------------------------|------|
| 1 | 必须由 @Builder / @LocalBuilder 初始化 | @BuilderParam 装饰的变量只能通过 @Builder / @LocalBuilder 函数初始化，传入非 @Builder / @LocalBuilder 值（如 @State 变量、普通字符串等）会导致编译报错。 |
| 2 | 参数类型必须匹配                         | @BuilderParam 为有参数形式时，指向的 @Builder / @LocalBuilder 方法也必须有参数；无参数同理。 |
| 3 | 尾随闭包仅单 @BuilderParam             | 使用尾随闭包初始化时，子组件只能有一个 @BuilderParam 且不能有参数。 |
| 4 | @Require 联用必须初始化                 | `@Require` 与 `@BuilderParam` 一起使用时，必须从外部显式初始化 @BuilderParam，否则编译报错。 |

---

## 6. wrapBuilder / mutableBuilder 封装全局 @Builder

> wrapBuilder：API 11+ | mutableBuilder：API 22+
> 用途：将全局 @Builder 赋值给变量/数组，解决 @Builder 方法赋值给变量后在 UI 方法中无法使用的问题。

### 6.1 基本特性对比

| 对比项 | wrapBuilder | mutableBuilder |
|--------|-------------|----------------|
| 返回类型 | `WrappedBuilder<Args>` | `MutableBuilder<Args>`（继承自 WrappedBuilder） |
| 最低 API 版本 | 11 | 22 |
| 二次赋值（动态切换 @Builder） | **不支持**，再次赋值不会生效 | **支持**，赋值后 UI 自动刷新 |
| 放入数组 | 支持 | 支持 |
| 作为类/接口属性 | 支持 | 支持 |
| 配合 @Monitor 监听变化 | 不支持 | 支持，切换 @Builder 时触发回调 |

### 6.2 引用传递

wrapBuilder / mutableBuilder 均支持按引用传递参数，状态变量的改变会引起 @Builder 方法内的 UI 刷新：

```typescript
// 按引用传递 — {} 对象字面量，状态变量变化触发 UI 刷新
wBuilder.builder({ paramA2: this.label.paramA2 })
```

### 6.3 限制条件对比

| # | 限制 | wrapBuilder          | mutableBuilder                              |
|---|------|----------------------|---------------------------------------------|
| 1 | 只能传入全局 @Builder | 传入局部 @Builder 无法正常工作 | 传入局部 @Builder **编译报错**                      |
| 2 | builder 方法仅限 struct 内使用 | -                    | -                                           |
| 3 | 二次赋值 | **不支持**，赋值后不生效，UI 不变 | **支持**，`mutableBuilder(otherBuilder)` 赋值后生效 |
| 4 | 禁止赋值为 undefined/null | —                    | 会导致**运行时崩溃**                                |
| 5 | 混合使用 | —                    | **不建议**与 wrapBuilder 混用，类型不匹配会导致不符合预期的更新    |

```typescript
// wrapBuilder 二次赋值不生效（反例）
@State builderObj = { globalBuilder: wrapBuilder(myBuilderFirst) };
this.builderObj.globalBuilder = wrapBuilder(myBuilderSecond); // 不生效

// mutableBuilder 二次赋值生效（正例）
@Local switchingBuilder: MutableBuilder<[TextContent]> = mutableBuilder(textBuilder);
this.switchingBuilder = mutableBuilder(buttonBuilder); // 生效，UI 刷新

// mutableBuilder 错误用法
@Local switchingBuilder: MutableBuilder<[TextContent]> | undefined = null; // 运行时崩溃
this.switchingBuilder = wrapBuilder(buttonBuilder); // 不建议，类型不匹配
```

---

## 7. 常见问题（约束与要求）

### 7.1 @Builder 两个及以上参数不触发刷新

- **禁止**：两个及以上参数时，即使通过对象字面量形式传递，值的改变也不会触发 UI 刷新。
- **正确做法**：将多个参数合并为一个对象，只传一个参数。

### 7.2 @ComponentV2 中简单类型不触发刷新

- 使用**简单数据类型**（number、string）按值传递，**不可以**触发 UI 刷新。
- 必须使用 `@ObservedV2` + `@Trace` 装饰的类对象，或 `@Local` 装饰的集合类型（Map、Set、Array）。

### 7.3 @Builder 内创建自定义组件传递对象不刷新

- **禁止**：引用传递直接传递 class 对象作为参数，修改对象属性不会触发 UI 刷新。
- **正确做法**：将对象拆分为简单类型属性逐个传递。

```typescript
// 传入 class 对象，无法刷新内部UI
HelloComponent1({ info: params })

// 可以刷新内部UI
HelloComponent2({ childName: params.name, childAge: params.age })
```

### 7.4 禁止在 UI 语句外调用 @Builder 函数

- **禁止**：将 @Builder 方法赋值给变量或数组后在 UI 方法中使用，会导致刷新时节点显示异常。
- **正确做法**：直接在 UI 方法中调用（`this.myBuilder()` 或 `this.myBuilder`）。

```typescript
// 错误
private bgList: Array<CustomBuilder> = [this.myImages(), this.myImages2()];

// 正确 — 直接在 build 中使用
Text('2').background(this.myImages)
Text('3').background(this.myImages())
```

### 7.5 MutableBinding 必须传递 set 访问器

- **禁止**：使用 MutableBinding 类型参数时，构造时未传写回调（SetterCallback），触发 set 会造成运行时错误。
- **正确做法**：`UIUtils.makeBinding()` 必须同时传入写回调。

```typescript
// 错误 — 未传写回调
UIUtils.makeBinding<number>(() => this.num)

// 正确 — 传入写回调
UIUtils.makeBinding<number>(() => this.num, val => { this.num = val; })
```

### 7.6 禁止在 @Builder 函数内部修改入参

不使用 MutableBinding 时，修改参数值不会生效：

| 修改类型 | 行为 |
|----------|------|
| 简单类型赋值 | 不闪退，UI 不刷新 |
| 对象类型属性修改 | 抛运行时错误（API 23 起错误码 140109） |
| 对象类型引用修改 | 不闪退，UI 不刷新 |

**正确做法**：使用 `MutableBinding` 安全修改参数值。

```typescript
// 错误写法，不允许在@Builder装饰的函数内部修改对象类型参数的属性，闪退且UI不刷新
@Builder
function overBuilderMod1(param: TempMod1) {
  param.paramA = 'Yes';
}

// 错误写法，不允许在@Builder装饰的函数内部修改对象类型参数的引用，不闪退但UI不刷新
@Builder
function overBuilderMod1(param: TempMod1) {
  param = { paramA: 'change trial' };
}
```

### 7.7 禁止在 @Watch 函数中执行 @Builder 函数

- **禁止**：在 `@Watch` 回调中执行 @Builder 函数，会导致 UI 刷新异常。
- **正确做法**：@Watch 回调中仅做数据处理或日志记录。
