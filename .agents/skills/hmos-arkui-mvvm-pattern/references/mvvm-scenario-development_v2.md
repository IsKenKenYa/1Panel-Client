# 状态管理V2版本下MVVM架构开发场景示例和开发方案

## 简介

MVVM（Model-View-ViewModel）架构模式在V2版本下通过`@ComponentV2`、`@Local`、`@Param`、`@Event`、`@ObservedV2`、`@Trace`、`@Computed`、`@Monitor`、`@Type`、`PersistenceV2`等V2装饰器及工具实现View层与ViewModel层的数据驱动更新与分层解耦。相比V1，V2提供更深层的属性观测能力、更严格的数据流单向性，并原生支持数组操作观测，无需子类化数组。

**注意**
- 本文档仅适用于V2版本状态管理场景，所有代码必须使用`@ComponentV2`配套V2装饰器套件，禁止混用V1装饰器（`@Component`、`@State`、`@Prop`、`@Link`、`@ObjectLink`、`@Observed`、`@Track`等）
- 若项目已使用V1版本状态变量，请参考[mvvm-scenario-development_v1.md](./mvvm-scenario-development_v1.md)
- MVVM分层架构与状态管理版本相互独立，V1/V2均可实现完整的MVVM分层，区别在于数据观测与同步机制的实现方式

## V1版本下MVVM架构场景开发：以待办事项应用为例

通过MVVM模式实现待办事项（todolist）应用，将数据（Model）、视图（View）、视图模型（ViewModel）三层分离，使用V2状态管理装饰器实现数据驱动UI更新。相比V1版本，V2无需子类化数组即可观测`push`/`splice`操作，`@Trace`支持任意深度嵌套属性观测，`@Param`+`@Event`实现更严格单向数据流，`@Computed`提供计算属性能力，`PersistenceV2`实现持久化存储。

**V2 MVVM 装饰器职责**

| MVVM分层 | V2装饰器 | 职责 |
|----------|----------|------|
| View - 页面组件 | `@Entry` + `@ComponentV2` + `@Local` | 绑定ViewModel作为数据源，组织页面结构 |
| View - 业务组件 | `@Param` + `@Event` | 接收父组件数据（只读），通过回调通知父组件修改数据源 |
| View - 共享组件 | 无状态装饰器 | 纯展示组件，不关联ViewModel数据 |
| ViewModel | `@ObservedV2` + `@Trace` | 可观察对象，属性级精准更新，支持任意深度嵌套观测 |
| ViewModel - 计算属性 | `@Computed` | 依赖驱动的自动计算，只计算一次并读取缓存 |
| ViewModel - 监听 | `@Monitor` | 深度监听状态变量变化，获取变化前后值 |
| ViewModel - 持久化 | `PersistenceV2.connect` | 持久化存储ViewModel，应用重启后数据恢复 |
| ViewModel - 嵌套序列化 | `@Type` | 标注嵌套class类型，确保PersistenceV2序列化/反序列化成功 |
| View - 循环渲染 | `Repeat` | 组件复用渲染，非懒加载场景高效更新变化部分 |
| Model | 普通class | 原始数据结构定义与数据获取/存储 |

**场景ID：** MVVM_SCENE_V2

**注意**：本文档中只介绍关键核心逻辑和代码，完整工程结构和代码实现：../assets/V2MVVM

**场景描述：** 仿待办事项应用，页面展示标题与未完成任务数量统计、任务列表（支持切换完成状态、删除任务）、底部操作区（全部完成/全部未完成、添加新任务）。待办数据从rawfile的JSON文件加载，并通过PersistenceV2持久化存储，应用重启后数据自动恢复。要求按照MVVM分层组织代码：Model层负责原始数据结构与JSON加载，ViewModel层负责页面数据管理与业务逻辑（含计算属性），View层负责UI展示与用户交互。View层通过`@Param`接收ViewModel数据（只读），通过`@Event`回调通知父组件修改数据源，不直接修改数据，实现严格单向数据流。

**解决方案：** 使用 **`@ObservedV2` + `@Trace` 装饰ViewModel类实现深度属性观测** + **`@Computed` 实现依赖驱动的计算属性** + **`@Param` + `@Event` 实现父子组件单向数据流与回调双向同步** + **`@Local` 在页面组件管理内部状态** + **`PersistenceV2.connect` + `@Type` 实现持久化存储与嵌套对象序列化** + **`Repeat` 实现组件复用渲染** + **`@Builder` 复用UI结构**

```
View层                            ViewModel层                  Model层
┌───────────────────────────┐    ┌──────────────────────┐    ┌────────────────────┐
│ TodoListPage (页面组件)     │    │ TaskListViewModel     │    │ TaskListModel       │
│  @Local taskList ──────────┼──→│  @ObservedV2          │    │  tasks: TaskModel[] │
│   PersistenceV2.connect    │    │  @Trace tasks         │    │  loadTasks(context)  │
│   持久化存储/恢复           │    │  @Type(TaskViewModel) │    │   └─ 读取JSON        │
│                            │    │  loadTasks(context)   │    │      反序列化        │
│  @Computed tasksUnfinished │    │  finishAll(ifFinish)  │    └────────────────────┘
│   依赖taskList自动计算      │    │  addTask(task)        │           ↑
│                            │    │  removeTask(task)     │    ViewModel调用Model
│  ┌───────────────────┐     │    └──────────────────────┘    加载数据后转换
│  │ TitleView          │     │           ↑
│  │ @Param unfinished  │←────┼─── @Computed结果传入（只读）
│  │ (共享组件-纯展示)   │     │
│  └───────────────────┘     │    ┌──────────────────────┐
│                            │    │ TaskViewModel         │
│  ┌───────────────────┐     │    │  @ObservedV2          │
│  │ ListView           │     │──→│  @Trace taskName      │
│  │ @Param taskList    │←────┼──→│  @Trace isFinish      │
│  │ Repeat渲染列表      │     │    │  updateIsFinish()    │
│  │  └─ TaskItem       │     │    └──────────────────────┘
│  │     @Param task    │←────┼──→  TaskViewModel实例
│  │     @Event deleteTask│   │      @Trace属性变化深度感知
│  │     回调通知父组件修改  │   │
│  └───────────────────┘     │
│                            │
│  ┌───────────────────┐     │
│  │ BottomView         │     │
│  │ @Param taskList    │←────┼──→  TaskListViewModel引用
│  │ @Local newTaskName │     │
│  │ 调用 finishAll()    │     │
│  │ 调用 addTask()      │     │
│  │ @Builder ActionButton│   │
│  └───────────────────┘     │
└───────────────────────────┘

数据流向：
1. 页面加载 → PersistenceV2.connect恢复数据 → 无数据时ViewModel.loadTasks() → Model.loadTasks()读取JSON
2. 全部完成 → @Param传入ViewModel → 调用finishAll(true) → @Trace isFinish变化 → 深度感知刷新UI
3. 切换状态 → TaskItem点击 → 调用task.updateIsFinish() → @Trace isFinish变化 → 精准刷新
4. 删除任务 → TaskItem @Event回调 → 父组件调用removeTask() → @Trace数组splice可观察 → Repeat更新
5. 添加任务 → BottomView输入 → 调用addTask() → @Trace数组push可观察 → Repeat新增项
6. 未完成统计 → @Computed依赖tasks → 任意isFinish变化 → 自动重算 → TitleView刷新
7. 持久化 → @Trace属性变化 → PersistenceV2自动写磁盘 → 重启后connect恢复
```

### 1.Model层 - 定义原始数据结构与数据加载

```typescript
// TaskModel.ets - 单个任务的基本数据结构
export default class TaskModel {
  public taskName: string = 'Todo';
  public isFinish: boolean = false;
}
```

```typescript
// TaskListModel.ets - 数据访问层，负责从rawfile加载JSON数据
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import TaskModel from './TaskModel';

export default class TaskListModel {
  public tasks: TaskModel[] = [];

  constructor(tasks: TaskModel[]) {
    this.tasks = tasks;
  }

  // 从rawfile读取defaultTasks.json并反序列化为TaskModel数组
  async loadTasks(context: common.UIAbilityContext) {
    let getJson = await context.resourceManager.getRawFileContent('defaultTasks.json');
    let textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    let result = textDecoder.decodeToString(getJson);
    this.tasks = JSON.parse(result).map((task: TaskModel) => {
      let newTask = new TaskModel();
      newTask.taskName = task.taskName;
      newTask.isFinish = task.isFinish;
      return newTask;
    });
  }
}
```

```json
// resources/rawfile/defaultTasks.json
[
  {"taskName": "学习ArkTS开发", "isFinish": false},
  {"taskName": "健身", "isFinish": false},
  {"taskName": "买水果", "isFinish": true},
  {"taskName": "取快递", "isFinish": true},
  {"taskName": "刷题", "isFinish": true}
]
```

关键点：Model层是应用的原始数据提供者，使用普通class定义数据结构，不与UI交互，不包含任何V2状态管理装饰器。`TaskListModel`负责数据获取（从rawfile读取JSON并反序列化为`TaskModel`数组），`TaskModel`定义单条任务的数据结构。Model层仅关注数据本身，符合MVVM中"Model层不直接与用户界面交互"的原则。

### 2.ViewModel层 - 使用 @ObservedV2 + @Trace 实现深度属性观测

```typescript
// TaskViewModel.ets - 单个任务的ViewModel
import TaskModel from '../model/TaskModel';

@ObservedV2
export default class TaskViewModel {
  // @Trace：属性变化时可被深度观测，触发绑定的UI组件刷新
  @Trace public taskName: string = 'Todo';
  @Trace public isFinish: boolean = false;

  updateTask(task: TaskModel) {
    this.taskName = task.taskName;
    this.isFinish = task.isFinish;
  }

  // View层点击任务时调用，切换完成状态
  updateIsFinish(): void {
    this.isFinish = !this.isFinish;
  }
}
```

```typescript
// TaskListViewModel.ets - 任务列表的ViewModel
import { common } from '@kit.AbilityKit';
import { Type } from '@kit.ArkUI';
import TaskListModel from '../model/TaskListModel';
import TaskViewModel from './TaskViewModel';

@ObservedV2
export default class TaskListViewModel {
  // @Type：标注嵌套class类型，确保PersistenceV2序列化/反序列化成功
  // @Trace：V2中@Trace装饰的数组直接支持push/splice等操作观测，无需子类化数组
  @Type(TaskViewModel)
  @Trace public tasks: TaskViewModel[] = [];

  // 加载任务数据：调用Model层获取原始数据，转换为ViewModel层对象
  async loadTasks(context: common.UIAbilityContext) {
    let taskList = new TaskListModel([]);
    await taskList.loadTasks(context);
    for (let task of taskList.tasks) {
      let taskViewModel = new TaskViewModel();
      taskViewModel.updateTask(task);
      this.tasks.push(taskViewModel);
    }
  }

  // 全部完成/全部未完成：批量更新所有任务状态
  finishAll(ifFinish: boolean): void {
    for (let task of this.tasks) {
      task.isFinish = ifFinish;
    }
  }

  addTask(newTask: TaskViewModel): void {
    this.tasks.push(newTask);
  }

  removeTask(removedTask: TaskViewModel): void {
    this.tasks.splice(this.tasks.indexOf(removedTask), 1);
  }
}
```

关键点：ViewModel层不只是存放数据，同时提供数据的服务及处理。`loadTasks`调用Model层加载数据并转换为ViewModel对象，`finishAll`处理批量更新逻辑，`addTask`和`removeTask`处理任务增删。View层通过调用这些方法完成用户操作响应，不直接操作Model层数据，符合MVVM架构核心原则。

### 3.View层 - 共享组件使用 @Param 接收只读数据

```typescript
// TitleView.ets - 标题展示组件，接收计算属性结果只读展示
@ComponentV2
export default struct TitleView {
  // @Param 接收父组件传入的值，子组件中不允许直接修改（编译期报错）
  @Param tasksUnfinished: number = 0;

  build() {
    Column() {
      Text('To do')
      Text(`Not Completed: ${this.tasksUnfinished}`)
    }
  }
}
```

### 4.View层 - 业务组件使用 @Param + @Event 实现单向数据流与回调双向同步

```typescript
// ListView.ets - 任务列表组件，包含TaskItem子组件
import TaskViewModel from '../viewmodel/TaskViewModel';
import TaskListViewModel from '../viewmodel/TaskListViewModel';
import { ActionButton } from './BottomView';

@ComponentV2
struct TaskItem {
  // @Param 接收TaskViewModel实例（只读引用，V2为引用传递）
  @Param task: TaskViewModel = new TaskViewModel();
  // @Event 声明回调，通过回调通知父组件修改数据源
  @Event deleteTask: () => void = () => {};

  build() {
    Row() {
      // Checkbox展示完成状态，onChange调用ViewModel方法切换状态
      Checkbox({ name: 'task', group: 'taskGroup' })
        .select(this.task.isFinish)
        .onChange(() => this.task.updateIsFinish())
      Text(this.task.taskName)
      // 点击Delete按钮，通过@Event回调通知父组件删除任务
      ActionButton('Delete', () => this.deleteTask());
    }
  }
}

@ComponentV2
export default struct ListView {
  // @Param 接收TaskListViewModel引用，只读访问其属性
  @Param taskList: TaskListViewModel = new TaskListViewModel();

  build() {
    // Repeat非懒加载场景：数据变化时仅更新变化部分
    Repeat<TaskViewModel>(this.taskList.tasks)
      .each((obj: RepeatItem<TaskViewModel>) => {
        TaskItem({
          task: obj.item,
          // @Event回调：子组件通知父组件，父组件调用ViewModel方法修改数据源
          deleteTask: () => this.taskList.removeTask(obj.item)
        })
      })
  }
}
```

### 5.View层 - 业务组件使用 @Builder 复用UI结构

```typescript
// BottomView.ets - 底部操作区组件
import TaskViewModel from '../viewmodel/TaskViewModel';
import TaskListViewModel from '../viewmodel/TaskListViewModel';

// @Builder 全局构建函数：复用按钮UI结构
@Builder
export function ActionButton(text: string | Resource, onClick: () => void) {
  Button(text, { buttonStyle: ButtonStyleMode.NORMAL })
    .onClick(onClick)
}

@ComponentV2
export default struct BottomView {
  // @Param 接收TaskListViewModel引用，调用其方法处理用户操作
  @Param taskList: TaskListViewModel = new TaskListViewModel();
  // @Local 管理组件内部状态：新任务名称输入框的值
  @Local newTaskName: string = '';

  build() {
    Column() {
      Row() {
        // 全部完成/全部未完成：调用ViewModel层方法处理批量更新
        ActionButton('All Completed', (): void => this.taskList.finishAll(true))
        ActionButton('All Not Completed', (): void => this.taskList.finishAll(false))
      }

      Row() {
        TextInput({ placeholder: 'Add new tasks', text: this.newTaskName })
          .onChange((value) => this.newTaskName = value)
        // 添加新任务：创建TaskViewModel，调用ViewModel层方法添加
        ActionButton('+', (): void => {
          let newTask = new TaskViewModel();
          newTask.taskName = this.newTaskName;
          this.taskList.addTask(newTask);
          this.newTaskName = '';
        })
      }
    }
  }
}
```

关键点：`BottomView`通过`@Param`接收`TaskListViewModel`引用，调用其`finishAll`、`addTask`等方法处理用户操作。View层不直接操作数据，而是通过ViewModel提供的方法间接操作，符合MVVM架构核心原则——View层不直接调用Model层数据，只能通过ViewModel提供的方法调用。

### 6.View层 - 页面组件使用 @Local + PersistenceV2 + @Computed 整合分层

```typescript
// TodoListPage.ets - 页面入口组件
import TaskListViewModel from '../viewmodel/TaskListViewModel';
import { common } from '@kit.AbilityKit';
import { PersistenceV2 } from '@kit.ArkUI';
import TitleView from '../view/TitleView';
import ListView from '../view/ListView';
import BottomView from '../view/BottomView';

@Entry
@ComponentV2
struct TodoList {
  // @Local + PersistenceV2.connect：从持久化存储创建或恢复ViewModel，重启后数据自动恢复
  @Local taskList: TaskListViewModel = PersistenceV2.connect(
    TaskListViewModel, 'TaskList', () => new TaskListViewModel()
  )!;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  // 页面出现时加载任务数据（仅在持久化数据为空时加载默认任务）
  async aboutToAppear() {
    if (this.taskList.tasks.length === 0) {
      await this.taskList.loadTasks(this.context);
    }
  }

  // @Computed 计算属性：依赖taskList.tasks，任意isFinish变化时自动重算
  @Computed
  get tasksUnfinished(): number {
    return this.taskList.tasks.filter(task => !task.isFinish).length;
  }

  build() {
    Column() {
      // 共享组件：@Param传入@Computed计算结果，只读展示
      TitleView({ tasksUnfinished: this.tasksUnfinished })
      // 业务组件：@Param传入ViewModel引用，Repeat渲染任务列表
      ListView({ taskList: this.taskList });
      // 业务组件：@Param传入ViewModel引用，提供操作按钮和添加任务
      BottomView({ taskList: this.taskList });
    }
    .height('100%')
    .width('100%')
  }
}
```

### 7.MVVM文件结构组织

```txt
├── src
│   ├── main
│   │   ├── ets
│   │   │   ├── model                    Model层：原始数据结构
│   │   │   │   ├── TaskModel.ets         单个任务数据结构
│   │   │   │   └── TaskListModel.ets     任务列表数据加载
│   │   │   ├── pages                    View层：页面组件
│   │   │   │   └── TodoListPage.ets     页面入口，绑定ViewModel + 持久化
│   │   │   ├── view                     View层：业务组件与共享组件
│   │   │   │   ├── TitleView.ets         共享组件：标题与未完成统计展示
│   │   │   │   ├── ListView.ets          业务组件：任务列表（含TaskItem）
│   │   │   │   └── BottomView.ets        业务组件：操作按钮与添加任务（含ActionButton）
│   │   │   ├── viewmodel               ViewModel层：数据服务
│   │   │   │   ├── TaskViewModel.ets     单个任务ViewModel
│   │   │   │   └── TaskListViewModel.ets 任务列表ViewModel
│   │   └── resources
│   │       └── rawfile
│   │           └── defaultTasks.json     任务初始数据
```