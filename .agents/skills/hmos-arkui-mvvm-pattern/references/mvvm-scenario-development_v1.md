# 状态管理V1版本下MVVM架构开发场景示例和开发方案

## 简介

MVVM（Model-View-ViewModel）架构模式在V1版本下通过`@Component`、`@State`、`@Prop`、`@Link`、`@ObjectLink`、`@Observed`、`@Track`等V1装饰器实现View层与ViewModel层的双向绑定和数据驱动更新。

**注意**
- 本文档仅适用于V1版本状态管理场景，所有代码必须使用`@Component`配套V1装饰器套件，禁止混用V2装饰器（`@ComponentV2`、`@Local`、`@Param`、`@ObservedV2`、`@Trace`等）
- 若项目已使用V2版本状态变量，请参考[mvvm-scenario-development_V2.md](./mvvm-scenario-development_V2.md)
- MVVM分层架构与状态管理版本相互独立，V1/V2均可实现完整的MVVM分层，区别在于数据观测与同步机制的实现方式

## V1版本下MVVM架构场景开发：以备忘录应用为例

通过MVVM模式实现备忘录应用，将数据（Model）、视图（View）、视图模型（ViewModel）三层分离，使用V1状态管理装饰器实现数据驱动UI更新。

**V1 MVVM 装饰器职责**

| MVVM分层 | V1装饰器 | 职责 |
|----------|----------|------|
| View - 页面组件 | `@Entry` + `@State` | 绑定ViewModel作为数据源，组织页面结构 |
| View - 业务组件 | `@Link` / `@ObjectLink` | 与ViewModel双向同步，调用ViewModel方法处理用户操作 |
| View - 共享组件 | 无状态装饰器 | 纯展示组件，不关联ViewModel数据 |
| ViewModel | `@Observed` + `@Track` | 可观察对象，属性级精准更新，向上刷新UI向下更新数据 |
| ViewModel - 数组 | `@Observed extends Array` | 子类化数组，使push/splice等操作可被观察 |
| Model | 普通class | 原始数据结构定义与数据获取/存储 |

**场景ID：** MVVM_SCENE_V1

**注意**：本文档中只介绍关键核心逻辑和代码，完整工程结构和代码实现：../assets/V1MVVM

**场景描述：** 仿备忘录应用，页面展示全部待办标题与待办列表，支持全选/取消全选切换所有待办的完成状态，点击待办图标切换完成状态，点击待办文本追加后缀。待办数据从rawfile的JSON文件加载。要求按照MVVM分层组织代码：Model层负责原始数据结构与JSON加载，ViewModel层负责页面数据管理与业务逻辑，View层负责UI展示与用户交互。View层不可直接操作Model层数据，只能通过ViewModel提供的方法调用；Model层不能直接操作UI，只能通知ViewModel层数据有更新。

**解决方案：** 使用 **`@Observed` + `@Track` 装饰ViewModel类实现可观察** + **`@Observed extends Array` 子类化数组使数组操作可观察** + **`@State` 在页面组件绑定ViewModel** + **`@Link` / `@ObjectLink` 在业务组件中与ViewModel双向同步** + **`@Builder` 复用UI结构**

```
View层                          ViewModel层                    Model层
┌─────────────────────────┐    ┌──────────────────────┐    ┌────────────────────┐
│ Index (页面组件)         │    │ TodoListViewModel     │    │ TodoListModel       │
│  @State todoListVM ──────┼──→│  @Observed            │    │  things: ThingModel[]│
│  aboutToAppear           │    │  @Track isChosen      │    │  loadTasks(context)  │
│   └─ loadTasks(context)  │    │  @Track things        │    │   └─ 读取JSON        │
│                          │    │  chooseAll()          │    │      反序列化        │
│  ┌─────────────────┐     │    │  loadTasks(context)   │    └────────────────────┘
│  │ TodoComponent    │     │    │                       │           ↑
│  │ (共享组件-纯展示) │     │    │  ┌─────────────────┐ │    ViewModel调用Model
│  └─────────────────┘     │    │  │ ThingViewModel   │ │    加载数据后转换
│                          │    │  │ @Observed        │ │
│  ┌─────────────────┐     │    │  │ @Track thingName │ │
│  │ AllChooseComponent│   │    │  │ @Track isFinish  │ │
│  │ @Link todoListVM  │←──┼──→│  │ updateIsFinish() │ │
│  │ 调用 chooseAll()   │   │    │  │ addSuffixes()    │ │
│  └─────────────────┘     │    │  └─────────────────┘ │
│                          │    └──────────────────────┘
│  ┌─────────────────┐     │
│  │ TodoListComponent │     │
│  │ @ObjectLink array │←──┼──→  ThingViewModelArray
│  │ ForEach渲染列表    │     │      (@Observed extends Array)
│  │  └─ ThingComponent │     │
│  │     @ObjectLink thing│←──┼──→  ThingViewModel实例
│  │     调用 updateIsFinish()│ │      属性变化精准刷新
│  │     调用 addSuffixes()   │ │
│  └─────────────────┘     │
└─────────────────────────┘

数据流向：
1. 页面加载 → ViewModel.loadTasks() → Model.loadTasks() 读取JSON → 转换为ThingViewModel
2. 全选按钮 → @Link同步 → ViewModel.chooseAll() → 遍历things修改isFinish → @Track精准刷新
3. 待办图标 → @ObjectLink同步 → ViewModel.updateIsFinish() → @Track刷新图标UI
4. 待办文本 → @ObjectLink同步 → ViewModel.addSuffixes() → @Track刷新文本UI
```

### 1.Model层 - 定义原始数据结构与数据加载

```typescript
// ThingModel.ets - 待办事项原始数据结构
export default class ThingModel {
  public thingName: string = 'Todo';
  public isFinish: boolean = false;
}
```

```typescript
// TodoListModel.ets - 数据访问层，负责从rawfile加载JSON数据
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import ThingModel from './ThingModel';

export default class TodoListModel {
  public things: Array<ThingModel> = [];

  constructor(things: Array<ThingModel>) {
    this.things = things;
  }

  // 从rawfile读取default_tasks.json并反序列化为ThingModel数组
  async loadTasks(context: common.UIAbilityContext) {
    let getJson = await context.resourceManager.getRawFileContent('default_tasks.json');
    let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    let result = textDecoder.decodeToString(getJson, { stream: false });
    this.things = JSON.parse(result);
  }
}
```

```json
// resources/rawfile/default_tasks.json
[
  {"thingName": "7.30起床", "isFinish": false},
  {"thingName": "8.30早餐", "isFinish": false},
  {"thingName": "11.30中餐", "isFinish": false},
  {"thingName": "17.30晚餐", "isFinish": false},
  {"thingName": "21.30夜宵", "isFinish": false},
  {"thingName": "22.30洗澡", "isFinish": false},
  {"thingName": "1.30睡觉", "isFinish": false}
]
```

关键点：Model层是应用的原始数据提供者，使用普通class定义数据结构，不与UI交互。`TodoListModel`负责数据获取（从rawfile读取JSON并反序列化），`ThingModel`定义单条待办的数据结构。Model层不包含任何V1状态管理装饰器，仅关注数据本身。

### 2.ViewModel层 - 使用 @Observed + @Track 实现可观察的数据服务层

```typescript
// ThingViewModel.ets - 单条待办的ViewModel
import ThingModel from '../model/ThingModel';

@Observed
export default class ThingViewModel {
  // @Track：属性级精准更新，仅刷新引用该属性的UI
  @Track public thingName: string = 'Todo';
  @Track public isFinish: boolean = false;

  updateTask(thing: ThingModel) {
    this.thingName = thing.thingName;
    this.isFinish = thing.isFinish;
  }

  // View层点击图标时调用，切换完成状态
  updateIsFinish(): void {
    this.isFinish = !this.isFinish;
  }

  // View层点击文本时调用，追加后缀
  addSuffixes(): void {
    this.thingName += 'la';
  }
}
```

```typescript
// TodoListViewModel.ets - 待办列表的ViewModel
import ThingViewModel from './ThingViewModel';
import { common } from '@kit.AbilityKit';
import TodoListModel from '../model/TodoListModel';

// @Observed 子类化数组：使push/splice等数组操作可被@ObjectLink观察
@Observed
export class ThingViewModelArray extends Array<ThingViewModel> {
}

@Observed
export default class TodoListViewModel {
  @Track public isChosen: boolean = true;
  @Track public things: ThingViewModelArray = new ThingViewModelArray();

  // 加载待办数据：调用Model层获取原始数据，转换为ViewModel层对象
  async loadTasks(context: common.UIAbilityContext) {
    let todoList = new TodoListModel([]);
    await todoList.loadTasks(context);
    for (let thing of todoList.things) {
      let thingViewModel = new ThingViewModel();
      thingViewModel.updateTask(thing);
      this.things.push(thingViewModel);
    }
  }

  // 全选/取消全选：遍历所有待办设置完成状态
  chooseAll(): void {
    for (let thing of this.things) {
      thing.isFinish = this.isChosen;
    }
    this.isChosen = !this.isChosen;
  }
}
```

#### 3.View层 - 共享组件（纯展示，不关联ViewModel）

```typescript
// TodoComponent.ets - 共享组件：展示标题，不包含任何业务数据
@Component
export struct TodoComponent {
  build() {
    Row() {
      Text('全部待办')
    }
  }
}
```

关键点：共享组件不关联ViewModel数据，不使用任何状态管理装饰器，所需数据从外部传入或写死。这类组件可跨越多个项目共享，完成比较通用的功能。与业务组件的区别在于：业务组件包含ViewModel数据，没有ViewModel不能运行；共享组件只要外部参数满足就可以工作。

#### 4.View层 - 业务组件使用 @Link 与ViewModel双向同步

```typescript
// AllChooseComponent.ets - 全选按钮组件
import TodoListViewModel from '../viewmodel/TodoListViewModel';

@Component
export struct AllChooseComponent {
  // @Link 双向同步：与父组件的todoListViewModel建立双向绑定
  @Link todoListViewModel: TodoListViewModel;

  build() {
    Row() {
      Button('全选', { type: ButtonType.Capsule })
        .onClick(() => {
          // View层点击事件触发，调用ViewModel层方法处理逻辑
          this.todoListViewModel.chooseAll();
        })
    }
    // isChosen变化时自动刷新padding
    .padding({ left: this.todoListViewModel.isChosen ? 15 : 0 })
  }
}
```

关键点：`@Link`建立父子组件间的双向同步，子组件获取ViewModel引用后，调用其方法（如`chooseAll()`）处理用户操作，符合MVVM架构核心原则——View层不直接调用Model层数据，只能通过ViewModel提供的方法调用。`@Link`禁止本地初始化，必须由父组件传入。点击全选按钮后，`chooseAll()`遍历`things`修改每个`thing.isFinish`，由于`isFinish`被`@Track`装饰，引用该属性的UI会精准刷新。

#### 5.View层 - 业务组件使用 @ObjectLink + @Builder 观测数组项属性变化

```typescript
// TodoListComponent.ets - 待办列表组件
import ThingViewModel from '../viewmodel/ThingViewModel';
import { ThingViewModelArray } from '../viewmodel/TodoListViewModel';
import { ThingComponent } from './ThingComponent';

@Component
export struct TodoListComponent {
  // @ObjectLink 接收@Observed装饰的ThingViewModelArray实例
  @ObjectLink thingViewModelArray: ThingViewModelArray;

  build() {
    Column() {
      List() {
        // ForEach循环渲染：数组增删可观察
        ForEach(this.thingViewModelArray, (item: ThingViewModel) => {
          ListItem() {
            ThingComponent({ thing: item })
          }
        }, (item: ThingViewModel) => item.thingName)
      }
    }
  }
}
```

```typescript
// ThingComponent.ets - 单条待办组件
import ThingViewModel from '../viewmodel/ThingViewModel';

@Component
export struct ThingComponent {
  // @ObjectLink 接收@Observed装饰的ThingViewModel实例
  @ObjectLink thing: ThingViewModel;

  // @Builder 方法：组件内复用UI结构
  @Builder
  displayIcon(icon: Resource) {
    Image(icon)
      .onClick(() => {
        // View层点击图标触发，调用ViewModel层方法处理逻辑
        this.thing.updateIsFinish();
      })
  }

  build() {
    Row({ space: 15 }) {
      // isFinish变化时切换图标，@Track精准刷新此UI
      if (this.thing.isFinish) {
        this.displayIcon($r('app.media.finished'));
      } else {
        this.displayIcon($r('app.media.unfinished'));
      }

      // thingName变化时刷新文本，@Track精准刷新此UI
      Text(`${this.thing.thingName}`)
        .onClick(() => {
          // View层点击文本触发，调用ViewModel层方法处理逻辑
          this.thing.addSuffixes();
        })
    }
  }
}
```

关键点：View层通过事件监听用户行为（`onClick`），在回调中调用ViewModel层的方法（`updateIsFinish`、`addSuffixes`）处理用户操作，这是MVVM中View和ViewModel的"方法调用"通信方式。View层不直接修改数据，而是通过ViewModel提供的方法间接操作，符合MVVM架构核心原则。

#### 6.View层 - 页面组件使用 @State 绑定ViewModel作为数据源

```typescript
// Index.ets - 页面入口组件
import { common } from '@kit.AbilityKit';
import TodoListViewModel from '../viewmodel/TodoListViewModel';
import { TodoComponent } from '../view/TodoComponent';
import { AllChooseComponent } from '../view/AllChooseComponent';
import { TodoListComponent } from '../view/TodoListComponent';

@Entry
@Component
struct TodoList {
  // @State 绑定ViewModel：View层绑定ViewModel层的数据
  @State todoListViewModel: TodoListViewModel = new TodoListViewModel();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  // 页面出现时加载待办数据
  async aboutToAppear() {
    await this.todoListViewModel.loadTasks(this.context);
  }

  build() {
    Column() {
      Row({ space: 40 }) {
        // 共享组件：纯展示，不关联ViewModel
        TodoComponent()
        // 业务组件：@Link双向同步ViewModel
        AllChooseComponent({ todoListViewModel: this.todoListViewModel })
      }

      Column() {
        // 业务组件：@ObjectLink接收数组，ForEach渲染每条待办
        TodoListComponent({ thingViewModelArray: this.todoListViewModel.things })
      }
    }
    .height('100%')
    .width('100%')
  }
}
```

关键点：页面组件作为View层的入口，使用`@State`绑定ViewModel作为数据源。`@State`是父组件的数据源，变化时触发自身UI刷新，同时同步到所有`@Link`和`@ObjectLink`子组件。`aboutToAppear`生命周期中调用`loadTasks`加载待办数据，数据加载完成后ViewModel的`things`数组变化，触发`TodoListComponent`刷新列表。`build`函数仅负责组织组件结构，如同搭积木，不处理业务逻辑，符合MVVM中View层"不包含任何业务逻辑"的原则。

#### 7.MVVM文件结构组织

```txt
├── src
│   ├── ets
│   │   ├── model                    Model层：原始数据结构
│   │   │   ├── ThingModel.ets        单条待办数据结构
│   │   │   └── TodoListModel.ets     待办列表数据加载
│   │   ├── pages                    View层：页面组件
│   │   │   └── Index.ets            页面入口，绑定ViewModel
│   │   ├── view                     View层：业务组件与共享组件
│   │   │   ├── AllChooseComponent.ets  业务组件：全选按钮
│   │   │   ├── ThingComponent.ets      业务组件：单条待办
│   │   │   ├── TodoComponent.ets       共享组件：标题展示
│   │   │   └── TodoListComponent.ets   业务组件：待办列表
│   │   ├── viewmodel               ViewModel层：数据服务
│   │   │   ├── ThingViewModel.ets     单条待办ViewModel
│   │   │   └── TodoListViewModel.ets  待办列表ViewModel
│   └── resources
│       ├── rawfile
│       │   └── default_tasks.json     待办初始数据
```