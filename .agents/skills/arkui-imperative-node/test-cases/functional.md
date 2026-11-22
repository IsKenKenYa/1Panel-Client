# 功能性测试用例

> 本文件是功能用例的唯一来源，供仓库智能检视流水线（hmos-skill-test-runner）及人工验证共用。覆盖场景判断、骨架生成、代码排障和池管理，共 18 条用例。每个用例以 **类别** 标注所属模块。

---

### 测试用例：FUNC-07

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：skeleton

#### 输入

我需要使用 BuilderNode 接入命令式节点。请帮我生成一个最小可运行的骨架代码，包含创建、build(wrapBuilder)、getFrameNode 挂载、NodeContainer 占位、dispose 释放。API 版本：12+。

#### 预期输出

**验证标准**：

- 应生成包含 BuilderNode 创建的代码
- 应包含 build(wrapBuilder) 调用
- 应包含 getFrameNode 挂载到 NodeContainer
- 应包含 dispose 释放逻辑
- 应使用 NodeController 作为控制器

**应包含**：BuilderNode, wrapBuilder, getFrameNode, NodeContainer, dispose  

---

### 测试用例：FUNC-08

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：skeleton

#### 输入

我需要使用 FrameNode 接入命令式节点。请帮我生成一个最小可运行的骨架代码，包含创建、NodeController makeNode 挂载、NodeContainer 占位、dispose 释放。API 版本：12+。

#### 预期输出

**验证标准**：

- 应生成包含 FrameNode 创建的代码
- 应包含 NodeController makeNode 挂载
- 应包含 NodeContainer 占位
- 应包含 dispose 释放逻辑

**应包含**：FrameNode, NodeController, makeNode, NodeContainer, dispose  

---

### 测试用例：FUNC-09

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：skeleton

#### 输入

我需要使用 RenderNode 接入命令式节点。请帮我生成一个最小可运行的骨架代码，包含创建、通过 FrameNode.getRenderNode 挂载、draw 绘制、dispose 释放。API 版本：12+。

#### 预期输出

**验证标准**：

- 应生成包含 RenderNode 创建的代码
- 应包含通过 FrameNode.getRenderNode 挂载
- 应包含 draw 绘制方法
- 应包含 dispose 释放逻辑

**应包含**：RenderNode, getRenderNode, draw, dispose  

---

### 测试用例：FUNC-13

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 创建使用后，点击 Release 按钮释放节点，但内存未释放。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Builder
function buildText(params: Params) {
  Text(params.text).fontSize(20)
}

class MemoryLeakController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }

  release() {
    this.builderNode = null;
  }
}

@Entry
@Component
struct DisposeMemoryBad {
  private controller: MemoryLeakController = new MemoryLeakController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
      Button('Release')
        .onClick(() => { this.controller.release(); })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应识别 release() 方法只置 null 未调用 dispose
- 应指出 BuilderNode 需调用 dispose() 释放后端实体节点
- 应给出修改建议：调用 this.builderNode?.dispose()

**应包含**：dispose  

---

### 测试用例：FUNC-14

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
同一个 controller 绑定到两个 NodeContainer，第二个抢走 FrameNode 后第一个不显示。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Builder
function buildText(params: Params) {
  Text(params.text).fontSize(20)
}

class DoubleMountController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;
  private cachedFrameNode: FrameNode | null = null;

  makeNode(context: UIContext): FrameNode | null {
    if (this.cachedFrameNode !== null) {
      return this.cachedFrameNode;
    }
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    this.cachedFrameNode = this.builderNode.getFrameNode();
    return this.cachedFrameNode;
  }
}

@Entry
@Component
struct NodeNotDisplayBad {
  private controller: DoubleMountController = new DoubleMountController();

  build() {
    Column({ space: 16 }) {
      Text('上方应显示 Hello，但被下方抢走').fontSize(14)
      NodeContainer(this.controller).width('100%').height(80)
      Text('下方同一个 controller，双挂').fontSize(14)
      NodeContainer(this.controller).width('100%').height(80)
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应识别同一个 controller 绑定到两个 NodeContainer 导致双挂
- 应指出同一个 FrameNode 被第二个 NodeContainer 抢走后第一个不显示
- 应建议每个 NodeContainer 使用独立的 controller

**应包含**：双挂, controller, NodeContainer


---

### 测试用例：FUNC-15

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 与 @Reusable 联用后 JSCrash。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Reusable
@Component
struct ReusableChild {
  @Prop text: string = '';
  build() { Text(this.text).fontSize(20) }
}

@Builder
function buildText(params: Params) {
  ReusableChild({ text: params.text })
}

class CrashController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }
}

@Entry
@Component
struct ReusableConflictBad {
  private controller: CrashController = new CrashController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应识别 @Reusable 装饰器直接用于 BuilderNode 的 @Builder 内部组件导致 JSCrash
- 应指出 @Reusable 和 @ReusableV2 都不能作为 BuilderNode 直接子组件
- 应建议用普通 @Component 包裹 @Reusable 组件

**应包含**：@Reusable, JSCrash  

---

### 测试用例：FUNC-16

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 内部组件的 aboutToDisappear 没有触发，开发者期望在 aboutToDisappear 中清理资源。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Component
struct MyComponent {
  @Prop text: string = '';
  aboutToDisappear() {
    console.log('清理资源')
  }
  build() { Text(this.text).fontSize(20) }
}

@Builder
function buildText(params: Params) {
  MyComponent({ text: params.text })
}

class LifecycleController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }

  release() {
    this.builderNode?.dispose();
    this.builderNode = null;
  }
}

@Entry
@Component
struct AboutToDisappearBad {
  private controller: LifecycleController = new LifecycleController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
      Button('Release')
        .onClick(() => { this.controller.release(); })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应说明 BuilderNode 内部 @Builder 组件的 aboutToDisappear 不自动触发
- 应指出 BuilderNode 持有后端节点强引用，需主动调用 dispose 释放
- 应建议在释放时调用 dispose() 而非依赖 aboutToDisappear
- 应将清理逻辑移到 dispose 前显式执行（NodeController 释放方法中），并在宿主 aboutToDisappear 中兜底调用

**应包含**：aboutToDisappear, dispose  

---

### 测试用例：FUNC-17

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 所在 NavDestination 被覆盖（不活跃）时调用 update，页面不更新，@Watch 不触发。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Builder
function buildText(params: Params) {
  FreezeContent({ text: params.text })
}

// BuilderNode 内部组件：用 @Watch 观测 update 是否生效
@Component
struct FreezeContent {
  @Prop @Watch('onTextChange') text: string = '';
  onTextChange(): void {
    hilog.info(0xF811, 'testTag', 'FreezeContent onTextChange: %{public}s', this.text);
  }
  build() { Text(this.text).fontSize(20) }
}

class FreezeUpdateController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.inheritFreezeOptions(true);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }

  updateText(text: string) {
    this.builderNode?.update(new Params(text));
  }
}

const freezeController: FreezeUpdateController = new FreezeUpdateController();

// NodeContainer 宿主：开启冻结，位于 NavDestination(pageOne) 内
@Component({ freezeWhenInactive: true })
struct FrozenHost {
  build() {
    Column() {
      NodeContainer(freezeController).width('100%').height(100)
    }
  }
}

@Component
struct PageOne {
  @Consume('pathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('pageOne：活跃时点 Update，hilog 有 onTextChange').fontSize(14)
        FrozenHost()
        Button('Update')
          .onClick(() => { freezeController.updateText('Update@pageOne'); })
        Button('Go to pageTwo')
          .onClick(() => { this.pathStack.pushPathByName('pageTwo', null); })
      }
    }.title('pageOne')
  }
}

@Component
struct PageTwo {
  @Consume('pathStack') pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('pageTwo：pageOne 已被覆盖冻结，点 Update 看 hilog 无 onTextChange').fontSize(14)
        Button('Update (frozen)')
          .onClick(() => { freezeController.updateText('Update@pageTwo'); })
        Button('Back')
          .onClick(() => { this.pathStack.pop(); })
      }
    }.title('pageTwo')
  }
}

@Entry
@Component
struct FreezeUpdateBad {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name === 'pageOne') {
      PageOne()
    } else if (name === 'pageTwo') {
      PageTwo()
    }
  }

  build() {
    Navigation(this.pathStack) {
      Column({ space: 16 }) {
        Text('首页：Go to pageOne 开始验证').fontSize(14)
        Button('Go to pageOne')
          .onClick(() => { this.pathStack.pushPathByName('pageOne', null); })
      }
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
  }
}
```

#### 预期输出

**验证标准**：

- 应识别 BuilderNode 处于冻结态时 update 不生效（@Watch 回调不触发，数据被缓存）
- 应指出冻结链需同时满足：NodeContainer 宿主（向上第一个自定义组件）设置 `freezeWhenInactive: true` 且处于不活跃状态（NavDestination 被覆盖）+ BuilderNode 调用 `inheritFreezeOptions(true)`
- 应指出冻结态下 update 不刷新 UI，是设计行为；回到前台后自动解冻并应用缓存数据
- 应建议如需冻结期间也能更新，用 `inheritFreezeOptions(false)` 关闭冻结继承

**应包含**：freeze, update, inheritFreezeOptions, freezeWhenInactive  

---

### 测试用例：FUNC-18

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：file-input

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
开发者提供了不存在的文件路径，期望 Skill 读取文件并分析组件上下文。

```
我有一个列表页面，想在列表条目中动态挂载 BuilderNode。文件路径：test-cases/NonExistentPage.ets，组件信息：页面包含 List + LazyForEach + 自定义 ListItem。
```

#### 预期输出

**验证标准**：

- 应提示文件路径不存在
- 不应生成代码修改方案
- 应建议开发者确认文件路径


---

### 测试用例：FUNC-19

**skill**：arkui-imperative-node  
**类型**：bench（代码分析）  
**类别**：file-input

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
开发者提供的文件中不含 ArkUI 组件（只有普通 TypeScript 代码）。

```
我有一个列表页面，想在列表条目中动态挂载 BuilderNode。文件路径：test-cases/DataHelper.ts，组件信息：页面包含 List + LazyForEach + 自定义 ListItem。
```

#### 预期输出

**验证标准**：

- 应提示文件不含 ArkUI 组件（无 @Component）
- 不应生成命令式节点代码修改方案
- 应建议开发者提供含 ArkUI 组件的文件


---

### 测试用例：FUNC-21

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：pool-management

#### 输入

我通过BuilderNode创建了多个节点，需要在不同位置动态挂载和卸载，帮我生成管理框架。

**业务场景与成立条件**：
标准模板工程+多个NodeContainer占位。需要统一创建/挂载/卸载/dispose生命周期管理，支持运行时动态将BuilderNode从一个NodeContainer转移到另一个。

#### 预期输出

**验证标准**：

- 应生成 NodePool + NodeItem 架构的池管理框架
- 应包含 getNode（获取或新建）和 recycleNode（回收）方法
- 应包含 disposeAll（统一销毁）方法
- 应说明动态转移需先解绑旧容器再绑定新容器
- 应说明每个 NodeContainer 绑定独立 controller

**应包含**：NodePool, NodeItem, getNode, recycleNode, disposeAll  

---

### 测试用例：FUNC-22

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 的 @Builder 内直接使用了 Repeat 组件，运行时 crash。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  items: string[] = [];
  constructor(items: string[]) { this.items = items; }
}

@Builder
function buildList(params: Params) {
  List() {
    Repeat(params.items)
      .each((ri: RepeatItem<string>) => {
        ListItem() {
          Text(ri.item).fontSize(16)
        }
      })
  }
  .width('100%')
  .height(200)
}

class RepeatBadController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildList), new Params(['A', 'B', 'C']));
    return this.builderNode.getFrameNode();
  }
}

@Entry
@Component
struct RepeatInBuilderBad {
  private controller: RepeatBadController = new RepeatBadController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(200)
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应识别 @Builder 内直接使用 Repeat 导致运行时 crash
- 应指出 Repeat 仅支持在自定义组件中使用，不能直接在 @Builder 函数体内使用
- 应建议将 Repeat 放在 @Component 自定义组件内部，再在 @Builder 中使用该组件
- 不应建议任何其他修改（修复方向唯一且明确）

**应包含**：Repeat, 自定义组件

---

### 测试用例：FUNC-23

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
开发者对 BuilderNode 对象调用 JSON.stringify，导致 JSCrash。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Builder
function buildText(params: Params) {
  Text(params.text).fontSize(20)
}

class JsonSerializeBadController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }

  serializeNode(): string {
    return JSON.stringify(this.builderNode);  // JSCrash！循环引用
  }
}

@Entry
@Component
struct JsonSerializeBad {
  private controller: JsonSerializeBadController = new JsonSerializeBadController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
      Button('Serialize')
        .onClick(() => {
          const json = this.controller.serializeNode();
          console.info(json);
        })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应识别 JSON.stringify(builderNode) 导致 JSCrash
- 应指出 BuilderNode 对象不支持 JSON 序列化（内部含循环引用）
- 应建议只序列化业务数据参数，不序列化 BuilderNode 对象
- 不应建议任何其他修改（修复方向唯一且明确）

**应包含**：JSON.stringify, 序列化

---

### 测试用例：FUNC-24

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：scene-judgment

#### 输入

页面打开太慢，我想提前创建一些组件缓存起来，页面显示时直接挂载，能实现吗？

#### 预期输出

**验证标准**：

- 应识别为预创建组件场景
- 应推荐使用 BuilderNode 预创建 + NodeContainer 挂载
- 应说明预创建的组件在未挂载前不参与渲染

**应包含**：BuilderNode, 预创建, NodeContainer

---

### 测试用例：FUNC-25

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
@Reusable 组件被复用时，复用事件可传递给直接子组件，但无法传递给 BuilderNode 内部的组件（BuilderNode 隔断）。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@Component
struct ChildComponent2 {
  @Prop text: string = '';
  aboutToReuse(params: object): void {
    console.info('ChildComponent2 aboutToReuse triggered');
  }
  aboutToRecycle(): void {
    console.info('ChildComponent2 aboutToRecycle triggered');
  }
  build() {
    Text('[BuilderNode内] ' + this.text).fontSize(16)
  }
}

@Component
struct ChildComponent3 {
  @Prop text: string = '';
  aboutToReuse(params: object): void {
    console.info('ChildComponent3 aboutToReuse triggered');
  }
  aboutToRecycle(): void {
    console.info('ChildComponent3 aboutToRecycle triggered');
  }
  build() {
    Text('[直接子] ' + this.text).fontSize(16)
  }
}

@Builder
function buildChild2(params: Params) {
  ChildComponent2({ text: params.text })
}

class ChildNodeController extends NodeController {
  builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    if (this.builderNode == null) {
      this.builderNode = new BuilderNode(context);
      this.builderNode.build(wrapBuilder<[Params]>(buildChild2), new Params('Hello'));
    }
    return this.builderNode.getFrameNode();
  }
}

@Reusable
@Component
struct ReusableChildComponent {
  @Prop text: string = '';
  private controller: ChildNodeController = new ChildNodeController();

  aboutToReuse(params: object): void {
    console.info('ReusableChildComponent aboutToReuse triggered');
  }

  aboutToRecycle(): void {
    console.info('ReusableChildComponent aboutToRecycle triggered');
  }

  build() {
    Row({ space: 8 }) {
      ChildComponent3({ text: this.text })
      NodeContainer(this.controller)
    }
  }
}

@Entry
@Component
struct ReuseFailBad {
  @State show: boolean = true;
  @State count: number = 0;

  build() {
    Column({ space: 16 }) {
      if (this.show) {
        ReusableChildComponent({ text: 'Item ' + this.count })
      }
      Button('Hide')
        .onClick(() => { this.show = false; })
      Button('Show')
        .onClick(() => {
          this.count++;
          this.show = true;
        })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应指出 BuilderNode 隔断复用事件，@Reusable 组件的 aboutToReuse/aboutToRecycle 可传递给直接子组件（ChildComponent3），但无法传递给 BuilderNode 内部的组件（ChildComponent2）
- 应建议在 aboutToReuse 中调用 builderNode.reuse(params)，在 aboutToRecycle 中调用 builderNode.recycle() 手动转发
- 应说明 reuse/recycle 接口需显式手动调用传递复用事件

**应包含**：reuse, recycle, 复用

---

### 测试用例：FUNC-26

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 内部自定义组件使用 @Link 同步外界数据，但状态不更新。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  count: number = 0;
  constructor(count: number) { this.count = count; }
}

@Component
struct ChildComponent {
  @Link count: number;
  build() { Text(`${this.count}`).fontSize(20) }
}

@Component
struct HostComponent {
  @State count: number = 0;
  build() {
    ChildComponent({ count: $count })
  }
}

@Builder
function buildContent(_params: Params) {
  HostComponent()
}

class LinkFailController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder(buildContent), new Params(0));
    return this.builderNode.getFrameNode();
  }

  updateCount(count: number) {
    this.builderNode?.update(new Params(count));
  }

  disposeNode() {
    this.builderNode?.dispose();
    this.builderNode = null;
  }
}

@Entry
@Component
struct LinkFailBad {
  @State count: number = 0;
  private controller: LinkFailController = new LinkFailController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
      Button('Add').onClick(() => {
        this.count++;
        this.controller.updateCount(this.count);
      })
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应指出 BuilderNode 不支持 @Link 跨越 BuilderNode 同步外界数据和状态
- 应说明 BuilderNode 隔断声明式状态树的父子双向同步链路
- 应建议改用 @Prop（V1）或 @Param（V2）单向传递，或通过 update 接口传值

**应包含**：@Link, @Prop, 不支持

---

### 测试用例：FUNC-27

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 内部组件使用 @Consume 接收外部 @Provide 数据，但拿不到值。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  constructor() {}
}

@Component
struct InnerComponent {
  @Consume('themeColor') themeColor: number;
  build() { Text('color').fontColor(this.themeColor) }
}

@Builder
function buildContent(_params: Params) {
  InnerComponent()
}

class ConsumeFailController extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder(buildContent), new Params());
    return this.builderNode.getFrameNode();
  }
}

@Entry
@Component
struct ConsumeFailBad {
  @Provide('themeColor') themeColor: number = 0xFF0000FF;
  private controller: ConsumeFailController = new ConsumeFailController();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应指出默认情况下 BuilderNode 隔断 @Consume/@Provide 跨边界传递
- 应说明从 API 20 开始可通过配置 BuildOptions 的 enableProvideConsumeCrossing=true 开启支持
- 未配置时建议改用 @Prop/@Param 参数传递

**应包含**：@Consume, @Provide, enableProvideConsumeCrossing

---

### 测试用例：FUNC-28

**skill**：arkui-imperative-node  
**类型**：functional（功能验证）  
**类别**：troubleshooting

#### 输入

请分析以下代码的命令式节点使用问题，给出修改建议。

**业务场景与成立条件**：
BuilderNode 内第一个子组件标注 @ReusableV2（V2 组件），运行时 JSCrash。

```ts
import { BuilderNode, FrameNode, NodeController, UIContext } from '@kit.ArkUI';

class Params {
  text: string = '';
  constructor(text: string) { this.text = text; }
}

@ReusableV2
@ComponentV2
struct ReusableV2Child {
  @Param text: string = '';
  build() { Text(this.text).fontSize(20) }
}

@Builder
function buildText(params: Params) {
  ReusableV2Child({ text: params.text })
}

class CrashV2Controller extends NodeController {
  private builderNode: BuilderNode<[Params]> | null = null;

  makeNode(context: UIContext): FrameNode | null {
    this.builderNode = new BuilderNode(context);
    this.builderNode.build(wrapBuilder<[Params]>(buildText), new Params('Hello'));
    return this.builderNode.getFrameNode();
  }
}

@Entry
@Component
struct ReusableV2CrashBad {
  private controller: CrashV2Controller = new CrashV2Controller();

  build() {
    Column() {
      NodeContainer(this.controller).width('100%').height(100)
    }
  }
}
```

#### 预期输出

**验证标准**：

- 应指出 @ReusableV2 同样不能作为 BuilderNode 直接子组件，与 @Reusable（V1）行为一致，都会 JSCrash
- 应说明 API 文档标注从 API 26 开始 BuilderNode 支持 V2 组件复用（指 reuse/recycle 接口），但实测 @ReusableV2 直接子组件仍会 JSCrash
- 应建议用普通 @ComponentV2 包裹 @ReusableV2 组件

**应包含**：@ReusableV2, JSCrash, @ComponentV2

---

