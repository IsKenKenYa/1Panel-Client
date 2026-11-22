# 状态管理 V1 & V2 相关开发场景

## 目录

1. [状态变量辅助接口](#状态变量辅助接口)
   - 1.1 [使用状态变量辅助接口增强状态管理能力](#使用状态变量辅助接口增强状态管理能力)
   - 1.2 [使用同步刷新接口解决V2版本动效问题](#使用同步刷新接口解决V2版本动效问题)
2. [获取系统环境变量](#获取系统环境变量)
   - 2.1 [通过Environment获取系统环境变量](#通过Environment获取系统环境变量)
   - 2.2 [通过Ability接口获取系统环境变量](#通过ability接口获取系统环境变量)
3. [双向绑定语法糖](#双向绑定语法糖)
   - 3.1 [$$实现系统组件参数双向绑定](#$$实现系统组件参数双向绑定)
   - 3.2 [!!实现自定义组件间双向同步和系统组件参数双向绑定](#!!实现自定义组件间双向同步和系统组件参数双向绑定)
4. [属性动画](#属性动画)
   - 4.1 [V1状态变量实现属性动画](#V1状态变量实现属性动画)
   - 4.2 [V2状态变量实现属性动画](#V2状态变量实现属性动画)
5. [组件复用功能](#组件复用功能)+
   - 5.1 [V1状态变量实现组件复用功能](#V1状态变量实现组件复用功能)
   - 5.2 [V2状态变量实现组件复用功能](#V2状态变量实现组件复用功能)
6. [自定义组件冻结功能](#自定义组件冻结功能)
   - 6.1 [V1状态变量实现自定义组件冻结功能](#V1状态变量实现自定义组件冻结功能)
   - 6.2 [V2状态变量实现自定义组件冻结功能](#V2状态变量实现自定义组件冻结功能)
7. [@Builder支持状态变量刷新](#@Builder支持状态变量刷新)
   - 7.1 [实现@Builder参数传递与UI刷新](#实现@Builder参数传递与UI刷新)
8. [循环渲染](#循环渲染)
   - 8.1 [V1版本的循环渲染](#V1版本的循环渲染)
   - 8.2 [V2版本的循环渲染](#V2版本的循环渲染)

---

## 状态变量辅助接口

`UIUtils` 工具类包含一系列辅助接口用于管理状态变量的观察能力、监听、调试和同步刷新。这些接口弥补了装饰器无法覆盖的场景（如三方类、JSON.parse 返回值），并提供了动态监听、调试定位和动效同步刷新能力。

> **说明：** 使用以下接口需导入：`import { UIUtils } from '@kit.ArkUI'`

**辅助接口总览**

| 接口 | 功能 | API版本 | 使用范围 |
|------|------|---------|----------|
| makeObserved | 将不可观察数据变为可观察 | 12 | @ComponentV2 和 @Component(不能和V1装饰器一起使用) |
| canBeObserved | 判断对象是否可被观察，获取关联组件信息 | 23 | 任意位置 |
| getTarget | 获取代理前的原始对象 | 12 | 任意位置 |
| addMonitor | 动态添加监听函数 | 20 | @ComponentV2 和 @ObservedV2 |
| clearMonitor | 动态取消监听函数 | 20 | @ComponentV2 和 @ObservedV2 |
| applySync | 同步刷新闭包内的修改 | 22 | @ComponentV2 |
| flushUpdates | 同步刷新调用前的所有修改 | 22 | @ComponentV2 |
| flushUIUpdates | 仅同步刷新UI节点 | 22 | @ComponentV2 |

> **说明：** `addMonitor` 和 `clearMonitor` 接口使用参考 ../state-management-v1v2-scenario-development.md中的STATE_SCENE_V2_06

---
### 使用状态变量辅助接口增强状态管理能力

**场景ID：** STATE_RELATIVE_01

**场景描述：** 仿社交应用用户个人主页，管理用户资料信息（姓名、年龄、头像、粉丝数等）。用户数据来源于三方SDK（无法添加 `@Trace`），也支持从服务端 JSON 加载；页面开发中遇到 UI 不刷新问题需要调试定位；需要对用户属性变化做动态监听通知（如粉丝数变化触发徽标更新）；类型判断时需要获取代理前的原始对象。覆盖 `makeObserved`、`canBeObserved`、`getTarget`辅助接口。

**解决方案：** 使用 **`UIUtils` 工具类** 提供的辅助接口管理状态变量的观察能力与监听：`makeObserved` 将三方数据变为可观察 → `canBeObserved` 调试 UI 不刷新 → `getTarget` 获取原始对象做类型判断。

```
社交应用个人主页开发流程：

  ┌──────────────────────────────────────────────────────────┐
  │  1. makeObserved                                         │
  │     三方SDK用户类 / JSON.parse → 可观察数据                │
  │     配合 @Monitor / @Computed / @Param 使用               │
  ├──────────────────────────────────────────────────────────┤
  │  2. canBeObserved                                        │
  │     UI不刷新 → 检查对象是否可观察 → 定位问题原因            │
  ├──────────────────────────────────────────────────────────┤
  │  3. getTarget                                            │
  │     代理对象 → 获取原始对象 → 类型判断 / NAPI调用           │
  └──────────────────────────────────────────────────────────┘
```

#### 1.使用 makeObserved 将第三方用户数据变为可观察

当类的定义在三方包中无法添加 `@Trace`，或 `interface`/`JSON.parse` 返回的匿名对象无法标记 `@Trace` 时，使用 `makeObserved` 使其可观察。

**makeObserved 限制条件**

- 仅支持非空的对象类型传参。不支持 `undefined`、`null`、非 Object 类型。
- 不支持传入 `@ObservedV2`、`@Observed` 装饰的类实例和 `makeObserved` 封装过的代理数据（防止双重代理）。
- 不能和 V1 的状态变量装饰器（如 `@State`）配合使用，否则抛运行时异常。
- 支持 Array、Map、Set、Date、collections.Array/Set/Map、`@Sendable` 装饰的类、JSON.parse 返回的 Object。

##### 第三方class不可添加@Trace的场景

```ts
import { UIUtils } from '@kit.ArkUI'

// 模拟三方包中的class，开发者无法手动添加@Trace
class ThirdPartyUserProfile {
  public userName: string = '张三'
  public age: number = 25
  public avatar: string = 'default.png'
}

@Entry
@ComponentV2
struct UserProfilePage {
  // 使用makeObserved将第三方class实例变为可观察数据
  @Local profile: ThirdPartyUserProfile = UIUtils.makeObserved(new ThirdPartyUserProfile())

  build() {
    Column({ space: 15 }) {
      Text(`用户名: ${this.profile.userName}`)
        .fontSize(20)
        .onClick(() => { this.profile.userName += '!' }) // makeObserved使属性变化可观察

      Text(`年龄: ${this.profile.age}`)
        .fontSize(18)
        .onClick(() => { this.profile.age++ })

      // 整体赋值后需再次调用makeObserved以保持观察能力
      Button('重置用户资料').onClick(() => {
        this.profile = UIUtils.makeObserved(new ThirdPartyUserProfile())
      })
    }
    .padding(20)
  }
}
```

##### JSON.parse返回值变为可观察

```ts
import { UIUtils } from '@kit.ArkUI'

let profileJsonStr: string = '{"userName":"李四","age":30}'

@Entry
@ComponentV2
struct JsonProfilePage {
  // JSON.parse返回的Object无法使用@Trace，用makeObserved转为可观察数据
  profile: Record<string, Object> =
    UIUtils.makeObserved<Record<string, Object>>(JSON.parse(profileJsonStr) as Record<string, Object>)

  build() {
    Column() {
      Text(`用户名: ${this.profile['userName']}`)
        .fontSize(30)
        .onClick(() => { this.profile['userName'] += '!' }) // 可观察，触发刷新

      Text(`年龄: ${this.profile['age']}`)
        .fontSize(30)
        .onClick(() => { (this.profile['age'] as number)++ })
    }
  }
}
```

关键点：`JSON.parse` 返回匿名 `Object`，无法使用 `@Trace` 标记属性，使用 `makeObserved` 使其变为可观察数据。

##### makeObserved 与 V2 装饰器配合使用

```ts
import { UIUtils } from '@kit.ArkUI'

class ProfileInfo {
  public id: number = 0
  public age: number = 20

  constructor(id: number) {
    this.id = id
  }
}

@Entry
@ComponentV2
struct ProfileMonitorPage {
  @Local message: ProfileInfo = UIUtils.makeObserved(new ProfileInfo(20))

  // makeObserved返回值可被@Monitor深度监听
  @Monitor('message.id')
  onIdChange(monitor: IMonitor) {
    console.info(`id change from ${monitor.value()?.before} to ${monitor.value()?.now}`)
  }

  // makeObserved返回值可被@Computed依赖
  @Computed
  get profileLabel(): string {
    return `ID: ${this.message.id} Age: ${this.message.age}`
  }

  build() {
    Column() {
      Text(`id: ${this.message.id}`)
        .fontSize(30)
        .onClick(() => { this.message.id++ })

      Text(`Computed: ${this.profileLabel}`)
        .fontSize(30)

      Button('重置').onClick(() => {
        this.message = UIUtils.makeObserved(new ProfileInfo(200))
      })

      // 可传递给子组件的@Param
      ProfileChild({ message: this.message })
    }
  }
}

@ComponentV2
struct ProfileChild {
  @Param @Require message: ProfileInfo

  build() {
    Text(`Child id: ${this.message.id}`).fontSize(30)
  }
}
```

#### 2.使用 canBeObserved 调试UI不刷新问题

`canBeObserved` 接口判断对象是否为可被观察对象，并获取对象关联的组件信息，帮助开发者定位 UI 不刷新问题。

##### 在个人主页中判断数据是否可观察

```ts
import { UIUtils } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProfileDebug'

@ObservedV2
class UserProfileV2 {
  @Trace public userName: string = '张三'
  @Trace public age: number = 25

  test(): void {
    hilog.info(0x00, TAG, `canBeObserved: ${JSON.stringify(UIUtils.canBeObserved(this))}`)
  }
}

@Entry
@ComponentV2
struct ProfileDebugPage {
  @Local profile: UserProfileV2 = new UserProfileV2()

  build() {
    Column({ space: 15 }) {
      Text(`用户名: ${this.profile.userName}`)
        .fontSize(20)
        .onClick(() => { this.profile.userName += '!' })

      Text(`年龄: ${this.profile.age}`)
        .fontSize(18)
        .onClick(() => { this.profile.age++ })

      Button('检查可观察状态').onClick(() => {
        this.profile.test()
        // 返回结果示例：
        // { "isObserved": true,
        //   "reason": "The object data is decorated with V2 @ObservedV2 and @Trace",
        //   "decoratorInfo": [{
        //     "decoratorName": "@Trace",
        //     "stateVariableName": "userName",
        //     "owningComponentOrClassName": "UserProfileV2",
        //     "owningComponentId": -1,
        //     "dependentInfo": [{ "elementName": "Text", "elementId": 6 }]
        //   }]
        // }
      })
    }
    .padding(20)
  }
}
```

关键点：`canBeObserved` 返回 `ObservedResult` 对象，包含 `isObserved`（是否可观察）、`reason`（原因说明）、`decoratorInfo`（装饰器信息及关联组件）。如果 `reason` 包含 `but not used in UI`，说明对象可观察但没有被UI组件使用，修改值不会触发UI刷新。

##### 定位UI不刷新问题

```ts
import { UIUtils } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ProfileDebug'

class UnobservedProfile {
  public userName: string = '王五'
  public age: number = 30
}

@Entry
@ComponentV2
struct ProfileNotRefreshPage {
  // 普通变量，没有被装饰器装饰，修改不会触发UI刷新
  profile: UnobservedProfile = new UnobservedProfile()

  build() {
    Column() {
      Text(`用户名: ${this.profile.userName}`)
        .fontSize(20)
        .onClick(() => {
          // 修改前检查是否可观察
          hilog.info(0x00, TAG, `res: ${JSON.stringify(UIUtils.canBeObserved(this.profile))}`)
          // 返回结果：{ "isObserved": false, "reason": "The object data is not an observable object", "decoratorInfo": [] }
          this.profile.userName += '!'  // 不可观察，UI不刷新
        })
    }
  }
}
```

#### 3.使用 getTarget 获取代理前的原始对象

状态管理框架会对对象添加代理层，导致类型判断和NAPI调用产生预料之外的结果。`getTarget` 可获取代理前的原始对象。

##### V1中获取原始对象

```ts
import { UIUtils } from '@kit.ArkUI'

@Observed
class ProfileObserved {
  public userName: string = '张三'
}

@Entry
@Component
struct ProfileGetTargetV1 {
  @State profile: ProfileObserved = new ProfileObserved()

  build() {
    Column() {
      Text(`用户名: ${this.profile.userName}`)
        .fontSize(20)
        .onClick(() => { this.profile.userName = 'Alice' })  // 代理对象修改，UI刷新

      Button('获取原始对象修改').onClick(() => {
        let rawProfile: ProfileObserved = UIUtils.getTarget(this.profile)
        rawProfile.userName = 'Bob'  // 原始对象修改，UI不刷新！
      })
    }
  }
}
```

##### V2中获取原始对象

```ts
import { UIUtils } from '@kit.ArkUI'

@ObservedV2
class ProfileV2 {
  @Trace public userName: string = '张三'
}

@Entry
@ComponentV2
struct ProfileGetTargetV2 {
  @Local profile: ProfileV2 = new ProfileV2()  // V2中类对象不被代理
  @Local tags: string[] = ['技术', '社交']  // Array类型被代理

  build() {
    Column() {
      Text(`用户名: ${this.profile.userName}`).fontSize(20)
      Text(`标签: ${this.tags.join(',')}`).fontSize(18)

      Button('获取tags原始对象').onClick(() => {
        let rawTags: string[] = UIUtils.getTarget(this.tags)
        // rawTags 是代理前的原始数组，修改不会触发UI刷新
      })
    }
  }
}
```

### 使用同步刷新接口解决V2版本动效问题

**场景ID：** STATE_RELATIVE_02

**场景描述：** 仿天气预报应用，用户从城市列表点击进入天气详情页时通过共享元素转场实现天气图标平滑放大；详情页中温度变化时温度计动画不显示；批量更新天气数据后展开动画首帧错误。这些问题均源于状态管理V2的异步标脏与 `animateTo`/共享元素转场的立即刷新机制冲突。覆盖 `applySync`、`flushUpdates`、`flushUIUpdates` 三个同步刷新接口。

**解决方案：** 使用 **`UIUtils` 工具类** 提供的同步刷新接口实现V2的同步标脏：`applySync` 同步刷新闭包内的修改 → `flushUpdates` 同步刷新调用前的所有修改 → `flushUIUpdates` 仅同步刷新UI节点。

```
天气预报应用同步刷新流程：

  ┌──────────────────────────────────────────────────────────┐
  │  1. 三接口对比                                            │
  │     批量更新天气数据 → 展开动画 → 对比三种同步刷新方式       │
  ├──────────────────────────────────────────────────────────┤
  │  2. 动效场景                                              │
  │     @Monitor监听温度 → 触发animateTo → applySync解决       │
  ├──────────────────────────────────────────────────────────┤
  │  3. 路由场景                                              │
  │     城市列表→天气详情 → 共享元素转场 → applySync同步name    │
  └──────────────────────────────────────────────────────────┘
```

> **说明：** 使用以下接口需导入：`import { UIUtils } from '@kit.ArkUI'`

#### 1.三种同步刷新接口的使用与区别

状态管理V2修改完状态变量后不会立即标脏，而是抛出Promise微任务，在当前宏任务执行完成后才处理标脏。而 `animateTo` 动效会立刻刷新已标脏节点来决定动效首帧。如果动效中使用了V2状态变量，并且在动效前修改了该状态变量，由于调用 `animateTo` 时状态变量的变化尚未标脏，会导致动效首帧不符合预期。

天气详情页中，点击"刷新数据"按钮批量更新温度、湿度、风速后触发详情卡片展开动画，分别用三种接口实现同步刷新：

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct WeatherDetailPage {
  @Local temp: number = 25
  @Local humidity: number = 60
  @Local windSpeed: number = 10
  @Local cardHeight: number = 80
  @Local status: string = '待刷新'

  @Monitor('status')
  onStatusChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => { console.info(`${path} 从 ${monitor.value(path)?.before} 变为 ${monitor.value(path)?.now}`) })
  }

  build() {
    Column({ space: 15 }) {
      Text(`${this.temp}°C  湿度:${this.humidity}%  风速:${this.windSpeed}m/s`).fontSize(16)

      // 方式1：applySync - 同步刷新闭包内的修改，@Monitor回调两次
      Button('applySync刷新').onClick(() => {
        UIUtils.applySync(() => {
          this.temp = 28; this.humidity = 45; this.status = '已刷新'
        })
        this.getUIContext().animateTo({ duration: 500 }, () => {
          this.cardHeight = 200; this.status = '动画完成'
        })
      })

      // 方式2：flushUpdates - 同步刷新调用前的所有修改，@Monitor回调两次
      Button('flushUpdates刷新').onClick(() => {
        this.temp = 28; this.humidity = 45; this.status = '已刷新'
        UIUtils.flushUpdates()
        this.getUIContext().animateTo({ duration: 500 }, () => {
          this.cardHeight = 200; this.status = '动画完成'
        })
      })

      // 方式3：flushUIUpdates - 仅同步刷新UI节点，不触发@Monitor，回调仅一次
      Button('flushUIUpdates刷新').onClick(() => {
        this.status = '已刷新'
        UIUtils.flushUIUpdates()
        this.status = '动画完成'  // @Monitor回调仅一次
      })

      Column() { Text(this.status).fontSize(14) }
        .height(this.cardHeight).backgroundColor('#f0f8ff').animation({ duration: 500 })
    }
    .padding(20)
  }
}
```

关键点：`applySync` 和 `flushUpdates` 都会同步执行 `@Computed` 计算和 `@Monitor` 回调，上述示例一次点击触发两次 `@Monitor`。`flushUIUpdates` 仅同步刷新UI节点，不执行 `@Computed` 和 `@Monitor` 回调，`@Monitor` 仅触发一次。

| 接口 | 作用 | @Monitor/@Computed | 适用场景 |
|------|------|-------------------|----------|
| applySync | 同步刷新闭包内的修改 | 触发执行 | 动效前有额外修改需要同步生效 |
| flushUpdates | 同步刷新调用前的所有修改 | 触发执行 | 动效前批量修改需要同步生效 |
| flushUIUpdates | 仅同步刷新UI节点 | 不触发 | 动效前只需UI同步，不希望@Monitor多次回调 |

#### 2.动效场景 — @Monitor 触发 animateTo 实现温度变化动画

温度变化时，`@Monitor` 监听温度变化并触发 `animateTo` 实现温度数值位移+渐隐动画。由于V2异步标脏，`animateTo` 闭包内的位移修改尚未标脏，导致动画不显示。在 `animateTo` 闭包内使用 `applySync` 同步刷新解决此问题。

```ts
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct TempAnimationPage {
  @Local temp: number = 25
  @Local offsetY: number = 0
  @Local opacity: number = 1

  @Monitor('temp')
  onTempChange() {
    this.playTempAnimation()
  }

  playTempAnimation() {
    this.getUIContext().animateTo({ duration: 800 }, () => {
      // 调用applySync同步刷新位移和透明度，若不调用则动画不显示
      UIUtils.applySync(() => {
        this.offsetY = 20
        this.opacity = 0.5
      })
    })
  }

  build() {
    Column({ space: 20 }) {
      Text(`${this.temp}°C`)
        .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#ff9800')
        .offset({ y: this.offsetY })
        .opacity(this.opacity)

      Button('温度+1').onClick(() => {
        this.temp += 1  // 触发@Monitor → playTempAnimation
      })
    }
    .padding(20)
  }
}
```

关键点：在 `@Monitor` 回调中触发 `animateTo` 时，V2异步标脏导致 `animateTo` 闭包内的修改尚未标脏，动画不显示。在 `animateTo` 闭包内使用 `applySync` 同步刷新状态变量的修改，确保动画正确显示。

#### 3.路由场景 — 城市列表到天气详情页的共享元素转场

用户从城市列表点击天气图标进入详情页，通过共享元素转场实现图标平滑放大。使用 `applySync` 确保 `sharedTransition` 的 `name` 值在路由跳转前同步刷新生效。列表页跳转时设置不匹配的name（无转场动效），详情页返回时设置匹配的name（有转场动效）。

```ts
import { UIUtils, AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
export class TransitionName {
  @Trace public name: string = ''
}

// 城市列表页：点击天气图标跳转，设置不匹配的name（无转场动效）
@Entry
@ComponentV2
struct CityListTransitionPage {
  @Local tn: TransitionName = AppStorageV2.connect(TransitionName, () => new TransitionName())!

  build() {
    Column() {
      Text('☀').fontSize(40)
        .sharedTransition(this.tn.name, { duration: 500, curve: Curve.EaseInOut })
    }
    .width('100%').height('100%')
    .onClick(() => {
      UIUtils.applySync(() => { this.tn.name = 'list_icon' })  // 与详情页不匹配
      this.getUIContext().getRouter().pushUrl({ url: 'pages/WeatherDetailTransitionPage' })
    })
  }
}

// 天气详情页：点击返回，设置匹配的name（有转场动效）
@Entry
@ComponentV2
struct WeatherDetailTransitionPage {
  build() {
    Stack() {
      Text('☀').fontSize(80)
        .sharedTransition('detail_icon', { duration: 500, curve: Curve.EaseInOut })
        .onClick(() => {
          UIUtils.applySync(() => { AppStorageV2.connect(TransitionName, () => new TransitionName())!.name = 'detail_icon' })
          this.getUIContext().getRouter().back()
        })
    }
    .width('100%').height('100%')
  }
}
```

关键点：列表页跳转时设置 `list_icon` 与详情页的 `detail_icon` 不匹配，无转场动效；详情页返回时通过 `applySync` 将 `name` 同步设置为 `detail_icon`，与列表页的 `sharedTransition(this.tn.name, ...)` 匹配，产生转场动效。`applySync` 确保 `name` 值在路由跳转前同步刷新生效。

#### 4.限制条件

- `applySync` 闭包中嵌套调用 `applySync`，内层将被跳过并返回undefined，同时打印警告信息。
- `applySync` 闭包中调用 `flushUpdates` 或 `flushUIUpdates` 不起作用，同时打印警告信息。
- 不支持在 `@Computed` getter 中调用这三个接口，运行时报错（错误码140001）。
- 不支持在 `@Monitor` 回调中调用 `flushUpdates` 和 `flushUIUpdates`，运行时报错（错误码140002）。

---

## 获取系统环境变量

在状态管理V1中，可以通过Environment来获取环境变量，但Environment获取的结果无法直接使用，需要配合AppStorage才能得到对应环境变量的值。在状态管理V2中，无需再通过Environment来获取环境变量，可以直接通过UIAbilityContext的config属性获取系统环境变量。

**两种方式对比**

| 能力 | 通过 Environment 获取 | 通过 Ability 接口获取 |
|------|---------|---------|
| 起始 API version | 7 | 11 |
| 使用形式 | `envProp` 接口将值写入 AppStorage，组件通过 `@StorageProp` 获取 | `UIAbility.context.config` 读取配置存储获取 |

---

### 通过Environment获取系统环境变量

**Environment 内置参数列表**

| 键 | 数据类型 | 描述 |
|------|---------|------|
| accessibilityEnabled | string | 是否启用无障碍屏幕阅读。'true' 表示启用，'false' 表示不启用 |
| colorMode | ColorMode | 色彩模式（LIGHT/DARK） |
| fontScale | number | 字体大小比例。需配置 configuration 设置 fontSizeScale 为 "followSystem" |
| fontWeightScale | number | 字体粗细程度，不同系统或机型取值范围可能不同 |
| layoutDirection | LayoutDirection | 布局方向（LTR/RTL） |
| languageCode | string | 当前系统语言（如 zh、en），取值为小写字母 |

**Environment 限制条件**

- Environment 和 UIContext 相关联，需要在 UIContext 明确时才可调用 `envProp` 接口，可通过 `runScopedTask` 明确上下文，否则无法查询到设备环境数据。
- Environment 无响应式能力，系统环境变量变化时不会自动通知更新，需要应用重新调用 `envProp` 才能获取新值。
- 应用无法修改环境变量参数，应使用 `@StorageProp` 获取（单向同步），即使组件内修改也不会同步回 AppStorage。
- `envProp` 的默认值仅在 AppStorage 中尚无对应 key 时生效，若 AppStorage 中已有值则不会覆盖（需先删除再重新设置）。

**场景ID：** STATE_RELATIVE_03

**场景描述：** 仿多语言社交应用设置页，需要根据设备环境信息适配界面：根据系统语言显示本地化标签、根据深浅色模式切换页面配色。

**解决方案：** 使用 **`Environment.envProp`** 将设备环境变量存入 AppStorage + **`@StorageProp`** 在组件中单向同步获取（只读）
```
多语言社交应用设置页
  ┌──────────────────────────────────────────────────────────┐
  │  1. EntryAbility 初始化（runScopedTask 明确 UIContext）   │
  │     Environment.envProp('languageCode', 'en')  → AppStorage│
  │     Environment.envProp('colorMode', ...)      → AppStorage│
  ├──────────────────────────────────────────────────────────┤
  │  2. UI 组件（@StorageProp 单向同步，只读）                │
  │     languageCode → 本地化标签（中文/英文）                 │
  │     colorMode → 深色/浅色配色                            │
  └──────────────────────────────────────────────────────────┘
```

#### 1.在 EntryAbility 中初始化 Environment（runScopedTask 明确 UIContext）

`Environment.envProp` 需要在 UIContext 明确时调用，通常在 `EntryAbility` 的 `onWindowStageCreate` 中通过 `runScopedTask` 明确上下文后调用。

```ts
import { UIAbility } from '@kit.AbilityKit';
import { window, Environment } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/SocialSettingsPage');

    windowStage.getMainWindow().then((mainWindow) => {
      let uiContext = mainWindow.getUIContext();
      // 必须在 runScopedTask 中调用，明确 UIContext
      uiContext.runScopedTask(() => {
        // 将 6 个设备环境变量存入 AppStorage，第二个参数为兜底默认值
        Environment.envProp('languageCode', 'en');                        // 系统语言
        Environment.envProp('colorMode', ColorMode.LIGHT);                // 深浅色模式
      });
    });
  }
}
```

#### 2.设置页 UI 适配 — @StorageProp 获取全部环境变量（只读）

组件通过 `@StorageProp` 从 AppStorage 单向同步获取环境变量。应用无法修改环境变量，因此使用 `@StorageProp`（单向）——即使组件内修改也不会同步回 AppStorage。

```ts
@Entry
@Component
struct SocialSettingsPage {
  // @StorageProp 单向同步：从 AppStorage 获取环境变量（只读）
  @StorageProp('languageCode') languageCode: string = 'en';
  @StorageProp('colorMode') colorMode: ColorMode = ColorMode.LIGHT;

  build() {
    Column({ space: 15 }) {
      // 根据系统语言显示本地化标题，字体大小跟随系统缩放
      Text(this.languageCode === 'zh' ? '设置' : 'Settings')
        .fontSize(24 * this.fontScale)
        .fontWeight(this.fontWeightScale > 1.0 ? FontWeight.Bold : FontWeight.Normal)

      // 根据深浅色模式切换配色
      Column({ space: 10 }) {
        Text(this.languageCode === 'zh' ? '通用设置' : 'General')
          .fontSize(18 * this.fontScale)
          .fontColor(this.colorMode === ColorMode.DARK ? Color.White : Color.Black)
      }
    }
    .padding(20)
    .backgroundColor(this.colorMode === ColorMode.DARK ? '#1a1a1a' : '#ffffff')
  }
}
```
---

### 通过Ability接口获取系统环境变量

**Configuration 常见支持参数列表**

| 参数 | 数据类型 | 描述 |
|------|---------|------|
| language | string | 系统语言（如 `zh`、`en`） |
| colorMode | number | 颜色模式：`COLOR_MODE_LIGHT`(0) / `COLOR_MODE_DARK`(1) |
| direction | number | 屏幕方向：竖屏(0) / 横屏(1) |
| screenDensity | number | 屏幕密度 |
| fontSizeScale | number | 字体缩放比例 |
| fontWeightScale | number | 字体粗细程度 |

**场景ID：** STATE_RELATIVE_04

**场景描述：** 仿多语言社交应用设置页，需要根据系统环境信息适配界面：根据系统语言显示本地化标签、根据深浅色模式切换页面配色。

**解决方案：** 使用 **`UIAbility.context.config`** 在 Ability 生命周期中直接读取系统环境变量写入 AppStorage。

```
多语言社交应用设置页
  ┌──────────────────────────────────────────────────────────┐
  │  1. EntryAbility 初始化（onCreate 读取 context.config）   │
  │     config.language → AppStorage('sysLanguage')           │
  │     config.colorMode → AppStorage('sysColorMode')         │
  ├──────────────────────────────────────────────────────────┤
  │  2. UI 组件（@StorageProp + @Watch 单向同步）              │
  │     sysLanguage → 本地化标签（中文/英文）                  │
  │     sysColorMode → 深色/浅色配色                           │
  └──────────────────────────────────────────────────────────┘
```

#### 1.EntryAbility 读取 context.config 并监听变化

在 `UIAbility.onCreate` 中通过 `this.context.config` 读取当前系统环境变量并写入 AppStorage；在 `onConfigurationUpdate` 回调中感知系统配置变化并刷新 AppStorage，从而让绑定的 UI 组件自动更新。

```ts
import { AbilityConstant, UIAbility, Want, Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 通过 context.config 直接读取系统环境变量
    const config = this.context.config;
    AppStorage.setOrCreate('sysLanguage', config.language);
    AppStorage.setOrCreate('sysColorMode', config.colorMode ?? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index');
  }
}
```

#### 2.设置页 UI 适配 — @StorageProp

组件通过 `@StorageProp` 从 AppStorage 单向同步获取环境变量。

```ts
import { ConfigurationConstant } from '@kit.AbilityKit';

@Entry
@Component
struct SettingsPage {
  // @StorageProp 单向同步：从 AppStorage 获取环境变量（只读）
  @StorageProp('sysLanguage')  sysLanguage: string = 'en';
  @StorageProp('sysColorMode') sysColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;

  build() {
    Column({ space: 15 }) {
      Text(`Language: ${this.sysLanguage}`)
        .fontSize(14)
        .fontColor(this.sysColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? Color.Black : Color.White)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}
```
---

## 双向绑定语法糖

`$$` 和 `!!` 是 ArkUI 提供的双向绑定语法糖，用于实现双向数据同步。在状态管理V1中推荐使用 `$$` 实现系统组件与状态变量的双向绑定；在状态管理V2中推荐使用 `!!` 统一处理系统组件参数和自定义组件间的双向绑定。

**`$$`与`!!`对比**

| 能力 | `$$` | `!!` |
|------|-----------|-----------|
| 推荐使用范围 | 状态管理V1 | 状态管理V2 |
| 系统组件双向绑定 | 支持（API 10+） | 支持（API 18+） |
| 自定义组件双向绑定 | 不支持 | 支持（简化 `@Param`+`@Event`） |
| 支持的变量类型 | 基础类型状态变量 | 基础类型状态变量 |
| 多层父子组件传递 | 仅支持系统组件参数 | 不支持自定义组件多层传递 |
---

### $$实现系统组件参数双向绑定

**场景ID：** STATE_RELATIVE_05

**场景描述：** 仿电商商品发布表单页，商家需要填写商品描述等信息，并支持底部高级设置弹窗等交互。需要通过 `$$` 语法糖实现系统组件参数与状态变量的双向同步：用户操作控件时状态变量自动更新，状态变量变化时控件也同步显示最新值。

**解决方案：** 使用 **`$$` 语法糖** 实现系统组件参数与 V1 状态变量（`@State`）的双向绑定，覆盖输入类（TextInput）和弹窗类（bindSheet）。

```
电商商品发布表单页（$$ 双向绑定）

  ┌──────────────────────────────────────────────────────────┐
  │  系统组件参数双向绑定（$$ 统一语法）                      │
  │     TextInput({ text: $$this.description })              │
  │     .bindSheet($$this.showSheet, ...)                    │
  ├──────────────────────────────────────────────────────────┤
  │  ⚠ $$ 仅支持系统组件，不支持自定义组件间双向绑定          │
  │  ⚠ V2 中推荐使用 !! 语法糖替代 $$                        │
  └──────────────────────────────────────────────────────────┘
```

#### 系统组件参数双向绑定（TextInput、bindSheet）

`$$` 运算符为系统组件提供 TS 变量的引用，使得变量与系统组件的内部状态保持同步。在系统组件参数前添加 `$$`，例如 `text: $$this.description`。

```ts
@Entry
@Component
struct ProductPublishPage {
  // 商品描述
  @State description: string = ''
  // 高级设置弹窗显隐
  @State showSheet: boolean = false

  build() {
    Column({ space: 12 }) {
      Text('发布商品').fontSize(24).fontWeight(FontWeight.Bold)

      // $$语法：TextInput的text参数与description双向同步
      TextInput({ text: $$this.description, placeholder: '请输入商品描述' })
        .width('100%')

      // $$语法：bindSheet的isShow参数与showSheet双向同步
      Button('高级设置')
        .onClick(() => { this.showSheet = true })
        .bindSheet($$this.showSheet, {
          builder: () => {
            Column() {
              Text('高级设置').fontSize(20).padding(20)
              Text('运费模板、发货地址等').fontSize(16).padding(10)
              Button('关闭').onClick(() => { this.showSheet = false })
            }
          }
        })

      // 状态变量变化时控件同步更新，控件输入时变量同步更新
      Text(`描述: ${this.description}`)
        .fontSize(14).fontColor(Color.Gray)
    }
    .padding(20)
  }
}
```
---

### !!实现自定义组件间双向同步和系统组件参数双向绑定

**场景ID：** STATE_RELATIVE_06

**场景描述：** 仿电商商品发布表单页，商家需要填写商品名称、商品描述等信息，并支持底部高级设置弹窗等交互。需要通过 `!!` 语法糖实现：自定义组件间双向绑定（商品名称输入组件通过 `@Param`+`@Event` 与父组件双向同步）；系统组件参数双向绑定（TextInput、bindSheet 等）。

**解决方案：** 使用 **`!!` 语法糖** 统一实现自定义组件间（简化 `@Param`+`@Event`）和系统组件参数的双向绑定，覆盖自定义组件双向绑定、系统组件参数双向绑定全部场景。

```
电商商品发布表单页（!! 双向绑定）

  ┌──────────────────────────────────────────────────────────┐
  │  1. 自定义组件间双向绑定（!! 简化 @Param+@Event）         │
  │     ProductNameInput({ productName: this.productName!! })│
  │     父组件修改 → 同步到子组件                             │
  │     子组件修改 → @Event回调 → 同步到父组件                │
  ├──────────────────────────────────────────────────────────┤
  │  2. 系统组件参数双向绑定（!! 统一语法）                   │
  │     TextInput({ text: this.description!! })              │
  │     .bindSheet(this.showSheet!!, ...)                    │
  ├──────────────────────────────────────────────────────────┤
  │  ⚠ !! 不支持多层父子组件传递                              │
  │  ⚠ 不支持与 @Event 混用                                  │
  │  ⚠ 3个或更多感叹号不支持双向绑定                          │
  └──────────────────────────────────────────────────────────┘
```

#### 1.!! 用于自定义组件间双向绑定（商品名称输入）

`!!` 双向绑定语法糖简化了 `@Param` + `@Event` 的双向绑定写法。父组件使用 `!!` 标记的变量变化会同步给子组件，子组件的变化也会同步给父组件。

```ts
@Entry
@ComponentV2
struct ProductPublishPage {
  // 商品名称
  @Local productName: string = ''

  build() {
    Column({ space: 15 }) {
      Text('发布商品').fontSize(24).fontWeight(FontWeight.Bold)

      // !!语法糖：自定义组件间双向绑定
      // 等价于 ProductNameInput({ productName: this.productName, $productName: (val) => { this.productName = val } })
      ProductNameInput({ productName: this.productName!! })

      // 状态变量变化时子组件同步更新
      Text(`商品名: ${this.productName}`)
        .fontSize(14).fontColor(Color.Gray)

      Row({ space: 10 }) {
        Button('设置默认名称').onClick(() => { this.productName = '默认商品' })
      }
    }
    .padding(20)
  }
}

// 商品名称输入组件
@ComponentV2
struct ProductNameInput {
  // @Param 接收父组件传入的值
  @Param productName: string = ''
  // @Event 声明回调，方法名必须为"$" + @Param属性名
  @Event $productName: (val: string) => void = (val: string) => {}

  build() {
    Column() {
      Text('商品名称').fontSize(16)
      // 子组件中也可以使用!!绑定系统组件
      TextInput({ text: this.productName!!, placeholder: '请输入商品名称' })
        .width('100%')
        .onChange((value: string) => {
          // 通过@Event回调通知父组件修改数据源
          this.$productName(value)
        })
    }
  }
}
```

#### 2.!! 用于系统组件参数双向绑定（TextInput、bindSheet）

`!!` 运算符也可为系统组件提供 TS 变量的引用，使得变量和系统组件的内部状态保持同步。在变量名后添加 `!!`，例如 `this.description!!`。

```ts
@Local description: string = ''
@Local showSheet: boolean = false

// !!语法：TextInput的text参数与description双向同步
TextInput({ text: this.description!!, placeholder: '请输入商品描述' })
  .width('100%')

// !!语法：bindSheet的isShow参数与showSheet双向同步
Button('高级设置')
  .onClick(() => { this.showSheet = true })
  .bindSheet(this.showSheet!!, {
    builder: () => {
      Column() {
        Text('高级设置').fontSize(20).padding(20)
        Text('运费模板、发货地址等').fontSize(16).padding(10)
        Button('关闭').onClick(() => { this.showSheet = false })
      }
    }
  })

Text(`描述: ${this.description}`)
  .fontSize(14).fontColor(Color.Gray)
```
---

## 属性动画

V1版本状态变量和V2版本状态变量均可通过 `animateTo` 实现属性动画。由于V2状态变量和animateTo刷新机制不兼容，需要进行额外的处理。

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 状态变量装饰器 | `@State` | `@Local` |
| 标脏机制 | 修改后**立即标脏**（同步） | 修改后**异步标脏**（Promise微任务） |
| 同步刷新接口 | 无需额外处理 | API 22前使用animateToImmediately将额外的修改先刷新再执行动画，API 22及以后可使用 `UIUtils.applySync`接口实现 |

---

### V1状态变量实现属性动画

**场景ID：** STATE_RELATIVE_07

**场景描述：** 仿音乐播放器页面，底部迷你播放器条（显示歌名、歌手）。点击展开按钮时，迷你播放器通过属性动画平滑展开为全屏播放器视图（高度增大、圆角变小、背景色渐变、专辑封面缩放、展开图标旋转180°）。使用 V1 `@State` 管理状态，`animateTo` 驱动属性动画。

**解决方案：** 使用 **`@State` 管理动画状态** + **`animateTo` 闭包内修改状态变量驱动属性动画**。V1 的 `@State` 修改后立即同步标脏，`animateTo` 闭包结束时修改已生效，动画首帧正确渲染，无需额外处理。

```
音乐播放器页面 @Component
  └── @State isExpanded ──animateTo──→ 展开/收起动画
        高度 80→全屏 / 圆角 24→0 / 背景色渐变 / 封面缩放 / 图标旋转180°
        @State 同步标脏 → animateTo 闭包结束时修改立即生效 → 首帧正确
```

#### 1.迷你播放器展开/收起动画 - @State + animateTo

```typescript
@Entry
@Component
struct MusicPlayerPage {
  @State isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景内容区...

      // 迷你播放器 / 全屏播放器
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          // 专辑封面、歌名等子组件根据 isExpanded 变化...

          // 展开/收起按钮：旋转动画
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
              // V1 @State 修改后立即同步标脏，animateTo 闭包内修改直接生效
              animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
                this.isExpanded = !this.isExpanded
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```

关键点：V1 的 `@State` 修改后立即同步标脏，`animateTo` 闭包内修改 `isExpanded` 等状态变量后，闭包结束时标脏立即生效，动画首帧正确渲染。`animateTo` 与 `@State` 配合无需任何额外处理。组件属性动画也可使用 `.animation()` 属性方法，在状态变量变化时自动驱动动画。

---

### V2状态变量实现属性动画

**场景ID：** STATE_RELATIVE_08

**场景描述：** 仿音乐播放器页面，底部迷你播放器条点击展开为全屏播放器视图（高度增大、圆角变小、背景色渐变、专辑封面缩放、展开图标旋转180°）。使用 V2 `@Local` 管理状态，`animateTo` 驱动属性动画，并解决 V2 异步标脏与 `animateTo` 刷新机制不兼容导致的动画首帧问题。

**解决方案：** 使用 **`@Local` 管理动画状态** + **`animateTo` 闭包内使用 `UIUtils.applySync` 同步刷新**（API 22+）或 **`animateToImmediately`**（API 22 前）。V2 的 `@Local` 修改后异步标脏（Promise 微任务），`animateTo` 闭包结束时标脏尚未生效，导致动画首帧不正确。API 22 及以后在 `animateTo` 闭包内调用 `UIUtils.applySync` 将修改同步刷新；API 22 之前使用 `animateToImmediately` 替代 `animateTo`，该接口会先将闭包内的修改同步刷新再执行动画。

```
音乐播放器页面 @ComponentV2
  └── @Local isExpanded ──animateTo──→ 展开/收起动画
        高度 80→全屏 / 圆角 24→0 / 背景色渐变 / 封面缩放 / 图标旋转180°
        ⚠ V2 异步标脏 → animateTo 闭包结束时标脏未生效 → 首帧错误
        ✅ API 22前：使用 animateToImmediately → 自动同步刷新 → 首帧正确
        ✅ API 22+：闭包内调用 UIUtils.applySync → 同步刷新 → 首帧正确
```

#### 1.API 22 前：@Local + animateToImmediately

```typescript
@ComponentV2
struct V2MusicPlayerLegacy {
  @Local isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景内容区...

      // 迷你播放器 / 全屏播放器
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          // 专辑封面、歌名等子组件根据 isExpanded 变化...

          // 展开/收起按钮：旋转动画
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
              // API 22 前：使用 animateToImmediately 替代 animateTo
              // animateToImmediately 会先将闭包内的修改同步刷新，再执行动画
              this.getUIContext().animateToImmediately({ duration: 400, curve: Curve.EaseInOut }, () => {
                this.isExpanded = !this.isExpanded
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```


#### 2.API 22+：@Local + animateTo + UIUtils.applySync

```typescript
import { UIUtils } from '@kit.ArkUI'

@Entry
@ComponentV2
struct V2MusicPlayerPage {
  @Local isExpanded: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景内容区...

      // 迷你播放器 / 全屏播放器
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          // 专辑封面、歌名等子组件根据 isExpanded 变化...

          // 展开/收起按钮：旋转动画
          Image($r('sys.symbol.chevron_up'))
            .rotate({ angle: this.isExpanded ? 180 : 0 })
            .animation({ duration: 400, curve: Curve.EaseInOut })
            .onClick(() => {
              // V2 @Local 修改后异步标脏，直接在 animateTo 闭包内修改会导致首帧错误
              // 需在 animateTo 闭包内使用 applySync 同步刷新
              this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseInOut }, () => {
                UIUtils.applySync(() => {
                  this.isExpanded = !this.isExpanded
                })
              })
            })
        }
      }
      .height(this.isExpanded ? '100%' : 80)
      .backgroundColor(this.isExpanded ? '#1a1a2e' : '#FFFFFF')
      .borderRadius(this.isExpanded ? 0 : 24)
      .animation({ duration: 400, curve: Curve.EaseInOut })
    }
  }
}
```

## 组件复用功能

V1 与 V2 均支持组件复用：V1 基于 `@Reusable` + `@Component`，V2 基于 `@ReusableV2` + `@ComponentV2`。

**V1 与 V2 对比**

| 能力 | V1 实现 | V2 实现 |
|------|---------|---------|
| 装饰器 | `@Reusable` + `@Component` | `@ReusableV2` + `@ComponentV2` |
| aboutToReuse 入参 | 有（`params: Record<string, ESObject>`） | 无（状态变量自动重置） |
| 状态变量重置 | 需在 aboutToReuse 中手动更新 | 自动重置（@Local/@Param/@Event/@Provider/@Consumer/@Computed/@Monitor） |
| reuseId 语法 | `.reuseId('id')` 直接传 string | `.reuse({ reuseId: () => 'id' })` 传回调函数 |
| reuseId 默认值 | 未设置按组件类型复用 | 未设置或空字符串默认用组件名 |
| 列表渲染推荐 | `LazyForEach` | `Repeat` |
| 起始版本 | API 10 | API 18 |

---

### V1状态变量实现组件复用功能

**@Reusable 限制条件**

- 仅用于 `@Component` 自定义组件，不可与 `@Builder` 或 `@ComponentV2` 搭配使用。
- 组件复用前后应保持组件结构不变，结构差异需通过 `.reuseId('id')` 区分。
- 不支持 `ComponentContent` 传入 `@Reusable` 组件，会导致 crash。
- `aboutToReuse` 中子组件修改父组件的状态变量不会生效，需使用 `setTimeout` 移出复用作用范围。
- 不建议嵌套使用 `@Reusable`，会增加内存、降低复用效率。
- `ForEach` 全量展开，正常滑动不触发复用，长列表应优先使用 `LazyForEach`。
- `aboutToReuse` 的参数类型不支持 `any`，需使用 `Record<string, ESObject>` 等明确类型。

**场景ID：** STATE_RELATIVE_9

**场景描述：** 仿新闻资讯App首页信息流，包含新闻信息流长列表（LazyForEach）。新闻卡片有文字、图片、视频三种结构，需通过 reuseId 区分。覆盖 @Reusable 基本使用（aboutToRecycle/aboutToReuse）、LazyForEach 懒加载配合复用、reuseId 区分不同结构。

**解决方案：** 使用 **`@Reusable` 装饰 `@Component` 自定义组件** + **`aboutToRecycle`/`aboutToReuse` 生命周期** + **`.reuseId()` 区分不同结构** + **`LazyForEach` 懒加载配合复用**

```
新闻资讯App首页 (@Entry @Component)
  └─ List 新闻信息流 → NewsCardV1 (@Reusable)
      ├─ .reuseId('textNews')   ── 纯文字新闻
      ├─ .reuseId('imageNews')  ── 图文新闻
      ├─ .reuseId('videoNews')  ── 视频新闻
      └─ LazyForEach 滚动 → aboutToRecycle 回收 → aboutToReuse 复用（手动更新 @State）
   
```

#### 1.@Reusable 基本使用 — 新闻卡片回收与复用（aboutToRecycle/aboutToReuse）

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'

// 新闻数据模型
class NewsItem {
  id: number = 0
  title: string = ''
  source: string = ''
  type: 'text' | 'image' | 'video' = 'text'

  // ... 构造函数字段赋值
}

// 基础复用：@Reusable 新闻卡片组件
@Reusable
@Component
struct NewsCardV1 {
  @State title: string = ''
  @State source: string = ''
  private newsId: number = 0

  // 组件被回收进入复用池时触发
  aboutToRecycle(): void {
    hilog.info(0x0001, 'NewsCardV1', `aboutToRecycle newsId=${this.newsId}`)
  }

  // 组件从复用池中被取出重新使用时触发，需手动更新状态变量
  aboutToReuse(params: Record<string, ESObject>): void {
    const item = params.item as NewsItem
    this.newsId = item.id
    this.title = item.title
    this.source = item.source
    hilog.info(0x0001, 'NewsCardV1', `aboutToReuse newsId=${this.newsId} title=${this.title}`)
  }

  build() {
    Column() {
      Text(this.title).fontSize(16).fontWeight(FontWeight.Bold).maxLines(2)
      Text(this.source).fontSize(12).fontColor('#999999').margin({ top: 4 })
    }
    .width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(8)
  }
}
```
---

#### 2.LazyForEach + @Reusable — 新闻信息流长列表滚动复用

```typescript
// 新闻数据源，实现 IDataSource 接口
class NewsDataSource implements IDataSource {
  private newsList: NewsItem[] = []
  private listeners: DataChangeListener[] = []

  constructor(news: NewsItem[]) { this.newsList = news }
  totalCount(): number { return this.newsList.length }
  getData(index: number): NewsItem { return this.newsList[index] }
  // ... registerDataChangeListener / unregisterDataChangeListener 实现
}

// 新闻信息流入口页面
@Entry
@Component
struct NewsFeedPageV1 {
  private newsData: NewsDataSource = new NewsDataSource([
    // ... 新闻数据条目
  ])

  build() {
    Column() {
      Text('新闻信息流').fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 12 })

      List({ space: 8 }) {
        LazyForEach(this.newsData, (item: NewsItem) => {
          ListItem() {
            NewsCardV1({ item: item })
          }
        }, (item: NewsItem) => item.id.toString())
      }
      .width('100%').height(400)
      .cachedCount(3) // 缓存3屏，配合复用池提升流畅度
    }
    .width('100%').padding(16)
  }
}
```
---

#### 3.reuseId 区分不同结构 — 文字/图片/视频新闻卡片

```typescript
// 多结构新闻卡片：通过 if/else 区分文字、图片、视频三种结构
@Reusable
@Component
struct MultiTypeNewsCardV1 {
  @State title: string = ''
  @State source: string = ''
  @State type: string = 'text'
  private newsId: number = 0

  aboutToRecycle(): void {
    hilog.info(0x0001, 'MultiTypeNewsCardV1', `aboutToRecycle id=${this.newsId} type=${this.type}`)
  }

  aboutToReuse(params: Record<string, ESObject>): void {
    const item = params.item as NewsItem
    this.newsId = item.id
    this.title = item.title
    this.source = item.source
    this.type = item.type
    hilog.info(0x0001, 'MultiTypeNewsCardV1', `aboutToReuse id=${this.newsId} type=${this.type}`)
  }

  build() {
    Column() {
      if (this.type === 'image') {
        // 图文新闻结构
        Image($r('app.media.startIcon')).width('100%').height(120).objectFit(ImageFit.Cover)
        Text(this.title).fontSize(14).padding(8)
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 8, bottom: 8 })
      } else if (this.type === 'video') {
        // 视频新闻结构
        Stack() {
          Image($r('app.media.startIcon')).width('100%').height(120).objectFit(ImageFit.Cover)
          Text('▶').fontSize(32).fontColor('#FFFFFF')
        }
        Text(this.title).fontSize(14).padding(8)
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 8, bottom: 8 })
      } else {
        // 纯文字新闻结构
        Text(this.title).fontSize(16).fontWeight(FontWeight.Bold).padding(12)
        Divider().color('#EEEEEE')
        Text(this.source).fontSize(12).fontColor('#999999').padding({ left: 12, bottom: 12 })
      }
    }
    .width('100%').backgroundColor('#FFFFFF').borderRadius(8)
  }
}

// 使用 reuseId 区分三种结构的入口
@Component
struct MultiTypeNewsListPage {
  private multiTypeData: NewsDataSource = new NewsDataSource([
    // ... 多类型新闻数据条目
  ])

  build() {
    List({ space: 8 }) {
      LazyForEach(this.multiTypeData, (item: NewsItem) => {
        ListItem() {
          MultiTypeNewsCardV1({ item: item })
            // 根据新闻类型使用不同的 reuseId 区分结构
            .reuseId(item.type)
        }
      }, (item: NewsItem) => item.id.toString())
    }
    .width('100%').height(300)
  }
}
```
---

### 组件复用功能V2

**@ReusableV2 限制条件**

- 仅用于 `@ComponentV2` 自定义组件，不可与 `@Component` 或 `@Builder` 搭配使用。
- 组件复用前后应保持组件结构不变，结构差异需通过 `.reuse({ reuseId: () => 'id' })` 区分。
- 不支持 `ComponentContent` 传入 `@ReusableV2` 组件。
- `aboutToReuse` 无入参，状态变量自动重置，不需要手动赋值。
- 不建议嵌套使用 `@ReusableV2`，会增加内存、降低复用效率。
- V2 复用组件不能直接用于 `Repeat` 的 `template` 中，但可以用在 template 中的 V2 自定义组件内部。
- 不建议在 `aboutToRecycle` 中更改状态变量（因冻结机制，修改不会生效）。
- 常量对象（未加装饰器）包含 `@Trace` 属性的写法在复用场景下可能导致 `@Monitor` 的 `before` 值未被重置的异常。

**场景ID：** STATE_RELATIVE_10

**场景描述：** 仿电商商品浏览页，包含商品瀑布流列表（Repeat 懒加载）。覆盖 @ReusableV2 基本使用（无入参 aboutToReuse）、Repeat 懒加载/非懒加载复用、if 条件切换复用。

**解决方案：** 使用 **`@ReusableV2` 装饰 `@ComponentV2` 自定义组件** + **`Repeat` 替代 LazyForEach** 实现懒加载/非懒加载复用与 if 条件切换复用

```
电商商品浏览页 (@Entry @ComponentV2)
  ├─ Repeat virtualScroll 商品列表 → ProductCardV2 (@ReusableV2)
  │   └─ 滚动回收 → aboutToRecycle
  │   └─ 滚动复用 → aboutToReuse（无入参）
  │
  └─ if 条件切换 → 条件渲染触发回收/复用
```

#### 1.@ReusableV2 基本使用 — 商品卡片自动回收与复用（无入参 aboutToReuse）

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'

// 商品数据模型
@ObservedV2
class ProductData {
  @Trace price: number = 0
  constructor(price: number) { this.price = price }
}

// V2 商品卡片：@ReusableV2 + @ComponentV2
@ReusableV2
@ComponentV2
struct ProductCardV2 {
  @Require @Param productId: number = 0
  @Param productName: string = ''
  @Param productPrice: number = 0

  // 组件被回收时触发（自动冻结，@Monitor 不触发）
  aboutToRecycle(): void {
    hilog.info(0x0001, 'ProductCardV2', `aboutToRecycle productId=${this.productId}`)
  }

  // 组件从复用池取出重新使用时触发（无入参，状态变量自动重置）
  aboutToReuse(): void {
    hilog.info(0x0001, 'ProductCardV2', `aboutToReuse productId=${this.productId} name=${this.productName}`)
  }

  build() {
    Column() {
      Text(this.productName)
      Text(`¥${this.productPrice}`)
      Text(`编号: ${this.productId}`)
    }
    // ...样式省略
  }
}

// V2 入口页面：Repeat + @ReusableV2 商品列表
@Entry
@ComponentV2
struct ProductListPageV2 {
  @Local products: Array<{ id: number, name: string, price: number }> = [
    { id: 1, name: '智能手机Pro', price: 2999 },
    // ...其余商品数据省略
  ]

  build() {
    Column() {
      Text('V2 商品列表')
      List({ space: 8 }) {
        Repeat(this.products)
          .each((ri: RepeatItem<typeof this.products[0]>) => {
            ListItem() {
              ProductCardV2({
                productId: ri.item.id,
                productName: ri.item.name,
                productPrice: ri.item.price
              })
            }
          })
          .key((item: typeof this.products[0]) => item.id.toString())
      }
      // ...样式省略
    }
  }
}
```
---

#### 2.Repeat 懒加载 + @ReusableV2 — 商品长列表滚动复用

```typescript
// Repeat virtualScroll 懒加载场景：滚动时触发回收/复用
@Entry
@ComponentV2
struct LazyProductListV2 {
  @Local products: number[] = Array.from({ length: 100 }, (_, i) => i + 1)

  build() {
    Column() {
      Text('懒加载商品列表（100条）')
      List() {
        Repeat(this.products)
          .virtualScroll({
            getTotalCount: () => this.products.length,
            onItemIndexer: (item: number, index: number) => item === this.products[index]
          })
          .each((ri: RepeatItem<number>) => {
            ListItem() {
              ProductCardV2({
                productId: ri.item,
                productName: `商品${ri.item}`,
                productPrice: ri.item * 10
              })
            }
          })
          .key((item: number) => item.toString())
      }
      .cachedCount(3)
      // ...样式省略
    }
  }
}
```
---

#### 3.if 条件切换 + @ReusableV2 — 条件渲染触发复用

```typescript
// if 条件切换场景：通过改变条件控制组件回收/复用
@Entry
@ComponentV2
struct ConditionalReusePageV2 {
  @Local showDetail: boolean = false
  @Local currentProductId: number = 42

  build() {
    Column() {
      Button(this.showDetail ? '返回列表' : '查看详情')
        .onClick(() => { this.showDetail = !this.showDetail })

      if (this.showDetail) {
        // 条件为 true 时创建组件
        ProductCardV2({
          productId: this.currentProductId,
          productName: `商品${this.currentProductId}`,
          productPrice: this.currentProductId * 10
        })
      } else {
        // 条件切换为 false 时，上方组件被回收（aboutToRecycle）
        // 再次切换为 true 时，从复用池取出复用（aboutToReuse），而非 aboutToAppear 重新创建
        Text('组件已回收，点击按钮重新显示')
      }
      // ...样式省略
    }
  }
}
```

---

## 自定义组件冻结功能

V1 与 V2 均通过 `freezeWhenInactive: true` 实现自定义组件冻结。

**V1 与 V2 组件冻结对比**

| 能力 | V1 @Component | V2 @ComponentV2 |
|------|---------------|-----------------|
| 冻结配置 | { freezeWhenInactive: true } | { freezeWhenInactive: true } |
| 变化监听 | @Watch（回调方法名） | @Monitor（可获取变化前后值） |
| 支持场景 | 页面路由、TabContent、LazyForEach、Navigation、组件复用 | 页面路由、TabContent、Navigation、Repeat |
| LazyForEach 支持 | 支持 | 不支持缓存节点冻结 |
| Repeat 支持 | 不支持 | API 18+ |
| 复用组件冻结 | 需手动配置 freezeWhenInactive | @ReusableV2 自动冻结 |
| 解冻刷新范围 | API 17及以下解冻所有子节点 | API 18+只解冻屏上节点 |
| BuilderNode冻结 | API 20+支持 inheritFreezeOptions | API 22+支持 inheritFreezeOptions |

**组件冻结限制条件**

- freezeWhenInactive 仅对自定义组件生效，非自定义组件不受影响。
- 组件 active/inactive 不等同于组件可见性，仅在特定场景（页面路由、TabContent、LazyForEach/Repeat、Navigation、组件复用）下生效。
- V1 组件冻结 + 组件复用混用时，解冻不会触发 @Watch 回调（因复用清空了脏节点列表）。
- V2 @ReusableV2 自动冻结，但 aboutToRecycle 中的修改不会刷新到 UI。
- BuilderNode 无法继承父组件冻结（API 20/22 前），需配置 inheritFreezeOptions 为 true。

---

### V1状态变量实现自定义组件冻结功能

**场景ID：** STATE_RELATIVE_11

**场景描述：** 仿社交应用首页，包含"消息""动态""我的"三个标签页，消息标签页内 Navigation 可跳转聊天详情子页面，聊天列表用 LazyForEach 渲染并配合 @Reusable 复用。标签页切换、页面跳转、列表滚动、组件复用时，非活跃组件的状态变量变化不应触发无效刷新。

**解决方案：** V1 使用 `@Component({ freezeWhenInactive: true })` 装饰自定义组件 + `@Watch` 监听状态变化；非活跃标签页、非栈顶 NavDestination、缓存列表项、复用组件的 `@Watch` 不触发，解冻后触发。

```
SocialHomePageV1 (@Entry @Component freezeWhenInactive:true)  <- 入口始终活跃，@Watch立即触发
  ├─ Tabs
  │   ├─ TabContent 消息 → MessageTabV1 (freezeWhenInactive:true)
  │   │     └─ Navigation → ChatDetailV1 → FreezeNavContentV1 (freezeWhenInactive:true)
  │   │           └─ 推入 SettingsPage → 非栈顶冻结，@Watch不触发；弹出解冻触发
  │   │     └─ List + LazyForEach + cachedCount(3) → ReusableChatItemV1 (@Reusable + freezeWhenInactive)
  │   │           └─ 缓存项冻结，@Watch仅可见项触发；复用解冻@Watch不触发
  │   ├─ TabContent 动态 → FeedTabV1 (freezeWhenInactive:true)  <- 切换走即冻结
  │   └─ TabContent 我的 → ProfileTabV1 (freezeWhenInactive:true) <- 切换走即冻结
  └─ 切回标签页 → 解冻批量触发积压的@Watch
```

#### 1.自定义组件结构V1 — @Component + freezeWhenInactive 基本配置

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'
const DOMAIN = 0xFF00
const TAG = 'FreezeV1'

// 入口组件：@Component + freezeWhenInactive，入口始终活跃，@Watch立即触发
@Entry
@Component({ freezeWhenInactive: true })
struct SocialHomePageV1 {
  @State currentTab: number = 0
  @Provide('unreadCount') @Watch('onUnreadChange') unreadCount: number = 5
  @Provide('sharedMsg') sharedMsg: string = '共享初始消息'

  onUnreadChange() { // 入口始终活跃，@Watch立即触发
    hilog.info(DOMAIN, TAG, `unreadCount → ${this.unreadCount}`)
  }

  build() {
    Column() {
      Text(`未读：${this.unreadCount}`).fontSize(20)
      Button('模拟推送+1').onClick(() => { this.unreadCount++ })
    }
  }
}
```

#### 2.TabContent 标签页冻结

```typescript
// 三个标签页子组件均配置 freezeWhenInactive:true，切换走即冻结，@Watch不触发
@Component({ freezeWhenInactive: true })
struct MessageTabV1 {
  @Prop currentTab: number = 0
  @Consume('unreadCount') @Watch('onUnreadInMessage') unreadCount: number
  @Consume('sharedMsg') @Watch('onSharedMsgInMessage') sharedMsg: string

  onUnreadInMessage() { /* 仅活跃时触发；切走被冻结不触发 */ }
  onSharedMsgInMessage() { /* 同上 */ }

  build() { /* Text('消息列表') ... */ }
}

// FeedTabV1、ProfileTabV1 结构同 MessageTabV1：@Consume('unreadCount') + @Watch + freezeWhenInactive:true
// ...
```

#### 3.Navigation 页面路由冻结

```typescript
// 非栈顶 NavDestination 中的冻结子组件，@Watch不触发；弹出解冻后触发
@Component({ freezeWhenInactive: true })
struct FreezeNavContentV1 {
  @Consume('navStack') navStack: NavPathStack
  @Consume('sharedMsg') @Watch('onSharedMsgInNav') sharedMsg: string
  @State @Watch('onMessageTextChange') messageText: string = '欢迎进入聊天详情'

  onSharedMsgInNav() { /* 非栈顶被冻结不触发；栈顶时正常触发 */ }
  onMessageTextChange() { /* ... */ }

  build() {
    Column({ space: 10 }) {
      // ...
      // 推入设置页后，本 NavDestination 变为非栈顶，FreezeNavContentV1 被冻结
      Button('进入设置页（使本页变为非栈顶）')
        .onClick(() => { this.navStack.pushPathByName('SettingsPage', null) })
    }.padding(20)
  }
}

@Component
struct ChatDetailV1 {
  build() { NavDestination() { FreezeNavContentV1() }.title('聊天详情') }
}
```

#### 4.LazyForEach 缓存节点冻结

```typescript
class ChatItemModel {
  id: number = 0
  name: string = ''
  lastMessage: string = ''
  unread: number = 0
  // constructor ...
}

// IDataSource 实现：totalCount / getData / addDataListener / removeDataChangeListener / notifyDataReload ...
class ChatDataSource implements IDataSource { /* ... */ }

// LazyForEach + cachedCount(3)：缓存项被冻结，@Watch仅在可见项触发
@Component({ freezeWhenInactive: true })
struct MessageListTabV1 {
  @State chatDataSource: ChatDataSource = new ChatDataSource([])

  build() {
    List({ space: 10 }) {
      LazyForEach(this.chatDataSource, (item: ChatItemModel) => {
        ListItem() { ReusableChatItemV1({ chatItem: item }) }
      }, (item: ChatItemModel) => `${item.id}`)
    }
    .cachedCount(3) // 缓存3个节点，缓存项被冻结时@Watch不触发
    .width('100%').layoutWeight(1)
  }
}
```

#### 5.@Reusable + freezeWhenInactive 混用

```typescript
// @Reusable + freezeWhenInactive 混用：复用解冻时 @Watch 不触发（V1关键特性）
@Reusable
@Component({ freezeWhenInactive: true })
struct ReusableChatItemV1 {
  @Prop chatItem: ChatItemModel = new ChatItemModel(0, '', '', 0)
  @Consume('navStack') navStack: NavPathStack
  @State @Watch('onItemStatusChange') itemStatus: string = '正常'

  onItemStatusChange() { /* 可见项触发，缓存项不触发；复用解冻时也不触发 */ }
  aboutToRecycle() { /* 被回收 */ }

  // V1关键特性：aboutToReuse接收params，但复用解冻时修改状态，@Watch不会触发
  // 原因：复用流程先清空脏节点列表，再解冻组件，导致@Watch丢失触发条件
  aboutToReuse(params: Record<string, Object>) {
    this.itemStatus = '复用更新' // 修改itemStatus但@Watch不触发
  }

  build() { /* ... */ }
}
```

---

### V1状态变量实现自定义组件冻结功能

**场景ID：** STATE_RELATIVE_12

**场景描述：** 同一仿社交应用首页场景，V2 使用 @ComponentV2 + @Monitor 替代 V1 的 @Component + @Watch，聊天列表用 Repeat 渲染并配合 @ReusableV2 复用。重点对比 @Monitor 获取变化前后值、Repeat 缓存节点冻结、@ReusableV2 自动冻结与复用解冻 @Monitor 触发、API 18+ 解冻精准刷新。

**解决方案：** V2 使用 `@ComponentV2({ freezeWhenInactive: true })` + `@Monitor` 监听变化；`@Monitor` 可获取变化前后值；`Repeat` + `virtualScroll` + `cachedCount` 配合 API 18+ 缓存节点冻结；`@ReusableV2` 自动冻结且复用解冻时 `@Monitor` 触发；API 18+ 解冻仅刷新屏上可见节点。

```
SocialHomePageV2 (@Entry @ComponentV2 freezeWhenInactive:true)  <- 入口始终活跃，@Monitor立即触发
  ├─ Tabs
  │   ├─ TabContent 消息 → MessageTabV2 (freezeWhenInactive:true)
  │   │     └─ Navigation → ChatDetailV2 → FreezeNavContentV2 (freezeWhenInactive:true)
  │   │           └─ 非栈顶冻结，@Monitor不触发；解冻触发并显示before→now
  │   │     └─ List + Repeat.virtualScroll + cachedCount(3) → ReusableChatItemV2 (@ReusableV2 + freezeWhenInactive)
  │   │           └─ API 18+缓存节点冻结，@Monitor仅可见项触发；复用解冻@Monitor触发
  │   ├─ TabContent 动态 → FeedTabV2 (freezeWhenInactive:true)
  │   └─ TabContent 我的 → ProfileTabV2 (freezeWhenInactive:true)
  └─ API 18+ 解冻仅刷新屏上可见节点（V1解冻所有子节点）
```

#### 1.自定义组件结构V2 — @ComponentV2 + freezeWhenInactive

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit'
const DOMAIN = 0xFF00
const TAG = 'FreezeV2'

// 入口组件：@ComponentV2 + freezeWhenInactive，入口始终活跃，@Monitor立即触发
@Entry
@ComponentV2({ freezeWhenInactive: true })
struct SocialHomePageV2 {
  @Local currentTab: number = 0
  @Local unreadCount: number = 5
  @Provider('sharedMsg') sharedMsg: string = '共享初始消息'

  @Monitor('unreadCount')
  onUnreadChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      hilog.info(DOMAIN, TAG, `${path} 从 ${monitor.value(path)?.before} 变为 ${monitor.value(path)?.now}`)
    })
  }

  build() {
    Column() {
      Text(`未读：${this.unreadCount}`).fontSize(20)
      Button('模拟推送+1').onClick(() => { this.unreadCount++ })
    }
  }
}
```

#### 2.@Monitor 替代 @Watch — 获取变化前后值

```typescript
@ComponentV2({ freezeWhenInactive: true })
struct FeedTabV2 {
  @Param unreadCount: number = 0
  @Consumer('sharedMsg') sharedMsg: string
  @Local feedUpdateCount: number = 0

  // @Monitor 可获取变化前后的值，对比 V1 @Watch 只能拿当前值
  @Monitor('unreadCount', 'feedUpdateCount')
  onStateChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      // monitor.value(path)?.before / ?.now
    })
  }

  build() {
    Column() {
      Text('动态页面').fontSize(20)
      Button('更新动态计数').onClick(() => { this.feedUpdateCount++ })
    }
  }
}
```

#### 3.TabContent + Navigation 冻结

```typescript
@ComponentV2({ freezeWhenInactive: true })
struct MessageTabV2 {
  @Param currentTab: number = 0
  @Param unreadCount: number = 0
  @Consumer('sharedMsg') sharedMsg: string

  @Monitor('unreadCount') // 非活跃标签页时不触发；解冻触发并显示before→now
  onUnreadInMessage(monitor: IMonitor) { /* monitor.dirty.forEach ... */ }

  build() { /* Text('消息列表') ... */ }
}

// 非栈顶 NavDestination 中的冻结子组件，@Monitor不触发；解冻触发并显示before→now
@ComponentV2({ freezeWhenInactive: true })
struct FreezeNavContentV2 {
  @Consumer('navStack') navStack: NavPathStack
  @Consumer('sharedMsg') sharedMsg: string
  @Local messageText: string = '欢迎进入聊天详情'

  @Monitor('sharedMsg')
  onSharedMsgInNav(monitor: IMonitor) { /* 仅栈顶时触发 */ }

  build() {
    Column({ space: 10 }) {
      // ...
      Button('进入设置页（使本页变为非栈顶）')
        .onClick(() => { this.navStack.pushPathByName('SettingsPage', null) })
    }.padding(20)
  }
}
```

#### 4.Repeat 替代 LazyForEach — 缓存节点冻结

```typescript
@ObservedV2
class ChatItemModelV2 {
  id: number = 0
  @Trace name: string = ''
  @Trace lastMessage: string = ''
  @Trace unread: number = 0
  // constructor ...
}

@ComponentV2({ freezeWhenInactive: true })
struct MessageListTabV2 {
  @Local chatList: ChatItemModelV2[] = []

  build() {
    List({ space: 10 }) {
      Repeat<ChatItemModelV2>(this.chatList)
        .each((ri: RepeatItem<ChatItemModelV2>) => {
          ListItem() { ReusableChatItemV2({ chatItem: ri.item }) }
        })
        .virtualScroll({ totalCount: this.chatList.length })
        .cachedCount(3) // API 18+缓存节点冻结，@Monitor仅在可见项触发
        .key((item: ChatItemModelV2) => `${item.id}`)
    }
    .width('100%').layoutWeight(1)
  }
}
```

#### 5.@ReusableV2 自动冻结 — 复用解冻 @Monitor 触发

```typescript
// @ReusableV2 自动冻结回收组件；复用解冻时 @Monitor 会触发（与 V1 @Watch 不触发不同）
@ReusableV2
@ComponentV2({ freezeWhenInactive: true })
struct ReusableChatItemV2 {
  @Param chatItem: ChatItemModelV2 = new ChatItemModelV2(0, '', '', 0)
  @Consumer('navStack') navStack: NavPathStack
  @Local itemStatus: string = '正常'

  @Monitor('itemStatus') // 可见项触发，缓存项不触发；复用解冻时会触发
  onItemStatusChange(monitor: IMonitor) { /* monitor.dirty.forEach ... */ }
  aboutToRecycle() { /* @ReusableV2自动冻结 */ }

  // V2关键特性：aboutToReuse无参数（V1有params）；复用解冻时修改状态@Monitor会触发
  aboutToReuse() {
    this.itemStatus = '复用更新' // @Monitor将触发
  }

  build() { /* ... */ }
}
```

#### 6.API 18+ 解冻精准刷新

```typescript
// API 18+：V2 解冻时只刷新屏上可见节点，比 V1 解冻所有子节点更高效精准
@ComponentV2({ freezeWhenInactive: true })
struct FreezeNavContentV2 {
  @Consumer('sharedMsg') sharedMsg: string
  @Local messageText: string = '欢迎进入聊天详情'

  @Monitor('sharedMsg', 'messageText')
  onThawRefresh(monitor: IMonitor) {
    // 解冻时仅屏上可见节点触发此回调；非屏上节点不刷新（API 18+）
    monitor.dirty.forEach((path: string) => { /* before → now */ })
  }

  build() {
    Column({ space: 10 }) {
      // ...
      Button('更新内容').onClick(() => { this.messageText = `新消息${Date.now()}` })
    }.padding(20)
  }
}
```
---

## @Builder支持状态变量刷新

从API version 20开始，开发者可以通过使用`UIUtils.makeBinding()`函数、`Binding`类和`MutableBinding`类实现@Builder函数中状态变量的刷新。

默认情况下，@Builder按值传递参数时状态变量变化不会触发@Builder内UI刷新；使用`makeBinding`包装状态变量后，可支持@Builder内UI组件刷新，并通过写回调实现@Builder内修改同步回调用方组件。

**Binding 与 MutableBinding 对比**

| 能力 | `Binding<T>` | `MutableBinding<T>` |
|------|-------------|---------------------|
| 读取（`.value`） | 支持 | 支持 |
| 写入（`.value` 赋值） | 不支持（运行时错误） | 支持 |
| @Builder内UI刷新 | 支持 | 支持 |
| @Builder内修改同步回父组件 | 不支持 | 支持 |
| `makeBinding` 参数 | 仅传读回调 | 传读回调 + 写回调 |
| 起始版本 | API 20 | API 20 |

**限制条件**

- `UIUtils.makeBinding()` 从API version 20开始支持，仅支持在 `@ComponentV2` 装饰的组件中使用。
- `Binding<T>` 不支持 `.value` 赋值，触发时会返回错误码 140109（API 23+）。
- `MutableBinding<T>` 必须传入写回调，否则在@Builder内触发 `.value` 赋值会造成运行时错误。
- @Builder函数内使用 `MutableBinding` 修改对象属性时（如 `data.value.distance += 100`），需确保该属性被 `@Trace` 装饰才能触发UI刷新；未被 `@Trace` 装饰的属性修改不触发UI刷新。
- 使用 `makeBinding` 时无法传递对象字面量，需先将字面量对象抽取为状态变量。

---

### 实现@Builder参数传递与UI刷新

**场景ID：** STATE_RELATIVE_13

**场景描述：** 仿运动健康监测应用，页面展示心率、步数等运动数据。页面中多个数据卡片使用@Builder函数封装复用，需要实现：心率数据仅展示（父组件修改→@Builder内刷新），步数数据可在@Builder内点击按钮修改并同步回父组件，运动数据对象（@ObservedV2+@Trace）在@Builder内修改属性并同步。

**解决方案：** 使用 **`UIUtils.makeBinding()`** 包装状态变量传入@Builder函数 + **`Binding<T>`** 实现只读刷新 + **`MutableBinding<T>`** 实现可读可写双向同步

```
运动健康监测页面 @ComponentV2
  ├── @Local heartRate ──makeBinding(读回调)──→ Binding<number> ──→ @Builder 心率卡片
  │     父组件修改心率 → Binding.value 读取 → @Builder内UI刷新
  │     @Builder内不可修改（Binding无写回调）
  │
  ├── @Local stepCount ──makeBinding(读回调+写回调)──→ MutableBinding<number> ──→ @Builder 步数卡片
  │     父组件修改步数 → MutableBinding.value 读取 → @Builder内UI刷新
  │     @Builder内点击+1 → MutableBinding.value 赋值 → 写回调 → 父组件stepCount更新
  │
  └── @Local workoutData(@ObservedV2) ──makeBinding(读回调+写回调)──→ MutableBinding<WorkoutData> ──→ @Builder 运动数据卡片
        workoutData.distance(@Trace)变化 → MutableBinding.value 读取 → @Builder内UI刷新
        @Builder内修改distance → MutableBinding.value 赋值 → 写回调 → 父组件workoutData更新
```

#### 1.使用 Binding 实现只读状态变量刷新（心率展示）

`UIUtils.makeBinding()` 仅传入读回调时返回 `Binding<T>` 类型，支持@Builder内UI组件刷新，但不支持在@Builder内修改参数值。

```typescript
import { Binding, UIUtils } from '@kit.ArkUI'

@Builder
function HeartRateCard(heartRate: Binding<number>) {
  Text(`心率: ${heartRate.value} bpm`)
  // ...样式配置省略
}

@Entry
@ComponentV2
struct HealthMonitorPage {
  @Local heartRate: number = 72

  build() {
    Column() {
      // makeBinding 仅传读回调 → 返回 Binding 类型，支持 @Builder 内 UI 刷新
      HeartRateCard(UIUtils.makeBinding<number>(() => this.heartRate))

      Button('模拟心率变化').onClick(() => {
        this.heartRate = 60 + Math.floor(Math.random() * 80)
      })
    }
    // ...
  }
}
```

#### 2.使用 MutableBinding 实现可读可写双向同步（步数计数器）

`UIUtils.makeBinding()` 同时传入读回调和写回调时返回 `MutableBinding<T>` 类型，既支持@Builder内UI组件刷新，又支持在@Builder内修改参数值并同步回父组件。

```typescript
import { MutableBinding, UIUtils } from '@kit.ArkUI'

@Builder
function StepCountCard(stepCount: MutableBinding<number>) {
  Column() {
    Text(`步数: ${stepCount.value}`)
    Button('步数 +100')
      .onClick(() => {
        // @Builder 内修改 MutableBinding.value → 写回调 → 同步回父组件
        stepCount.value += 100
      })
  }
  // ...样式配置省略
}

@Entry
@ComponentV2
struct StepMonitorPage {
  @Local stepCount: number = 0

  build() {
    Column() {
      Text(`当前总步数: ${this.stepCount}`)

      // makeBinding 传读回调 + 写回调 → 返回 MutableBinding 类型
      StepCountCard(UIUtils.makeBinding<number>(
        () => this.stepCount,
        (val: number) => { this.stepCount = val }
      ))

      Button('父组件重置步数').onClick(() => { this.stepCount = 0 })
    }
    // ...
  }
}
```

#### 3.使用 MutableBinding 传递 @ObservedV2 类对象（运动数据卡片）

`MutableBinding` 也支持传递 `@ObservedV2` + `@Trace` 装饰的类对象，在@Builder内修改对象属性并同步回父组件。

```typescript
import { MutableBinding, UIUtils } from '@kit.ArkUI'

@ObservedV2
class WorkoutData {
  @Trace public distance: number = 0
  @Trace public duration: number = 0
  @Trace public calories: number = 0
  // ...构造函数省略
}

@Builder
function WorkoutDataCard(data: MutableBinding<WorkoutData>) {
  Column() {
    Text(`距离: ${data.value.distance} m`)
    Text(`时长: ${data.value.duration} s`)
    Text(`卡路里: ${data.value.calories} cal`)

    Button('距离 +100m').onClick(() => {
      // @Builder 内修改 @Trace 属性 → 同步回父组件 + 触发 UI 刷新
      data.value.distance += 100
    })
  }
  // ...样式配置省略
}

@Entry
@ComponentV2
struct WorkoutMonitorPage {
  @Local workoutData: WorkoutData = new WorkoutData(1000, 1800, 200)

  build() {
    Column() {
      Text(`父组件数据 - 距离: ${this.workoutData.distance}m`)

      // makeBinding 传递 @ObservedV2 类对象
      WorkoutDataCard(UIUtils.makeBinding<WorkoutData>(
        () => this.workoutData,
        (val: WorkoutData) => { this.workoutData = val }
      ))

      Button('父组件重置数据').onClick(() => {
        this.workoutData = new WorkoutData(0, 0, 0)
      })
    }
    // ...
  }
}
```
---

## 循环渲染

ArkUI 提供 ForEach 和 LazyForEach 两种循环渲染组件（V1），以及 Repeat 组件（V2）。

**V1 与 V2 对比**

| 能力 | V1（ForEach / LazyForEach） | V2（Repeat） |
| --- | --- | --- |
| 渲染方式 | ForEach 全量渲染 / LazyForEach 懒加载（按需渲染可见+缓存区域） | Repeat 虚拟滚动（按需渲染） |
| 数据源 | Array 数组 / IDataSource 接口实现 | Array 或 Iterable |
| 数据更新机制 | ForEach 键值对比增量更新 / LazyForEach notifyData* 方法通知 | Repeat 键值对比增量更新 |
| 多模板 | 不支持，需在 itemGenerator 中手动 if/else 判断类型 | 支持 `.template()` 声明多模板 |
| 节点复用 | 不支持 | 支持 `reusable` + `template` 节点复用 |
| 精准懒加载 | LazyForEach 通过 `cachedCount` 设置缓存数量 | Repeat `.lazyCachedCount()` 精准控制 |
| 拖拽排序 | List `.onMove(from, to)` 回调 | List `.onMove(from, to)` 回调 |
| 组件装饰器 | `@Component` | `@ComponentV2` |
| API支持版本 | 10+ | 12+ |

---

### V1版本的循环渲染

**场景ID：** STATE_RELATIVE_14

**场景描述：** 仿音乐播放器歌单管理页，包含两部分：（1）"我喜欢"歌单——短列表（<100 首），使用 ForEach 全量渲染，支持添加/删除/收藏/拖拽排序；（2）"本地音乐"库——长列表（500+ 首），使用 LazyForEach 懒加载渲染，支持搜索/添加/删除/修改/移动/重载/拖拽排序。两类列表均使用 `@Observed` + `@ObjectLink` 实现歌曲子属性（isFavorite、playCount）的深层观测。

**解决方案：** 短列表使用 **`ForEach`** 全量渲染 + **`@State`** 数组管理 + **`@Observed` + `@ObjectLink`** 子属性观测 + List **`.onMove`** 拖拽排序；长列表使用 **`LazyForEach`** 懒加载 + **`IDataSource`** 实现 + 5 种 **`notifyData*`** 方法通知更新 + **`@Observed` + `@ObjectLink`** 深层属性观测

```
音乐播放器歌单管理页
├── "我喜欢"歌单（短列表 < 100 首）── ForEach 全量渲染
│   ├── @State songs: Song[] ──ForEach(arr, itemGenerator, keyGenerator)──→ SongCard(@ObjectLink)
│   │     push/splice 触发键值对比增量更新    @Observed 子属性变化 → @ObjectLink 自动观测
│   └── List .onMove(from, to) ── 交换数组元素 ── ForEach 键值对比 → 增量更新顺序
└── "本地音乐"库（长列表 500+ 首）── LazyForEach 懒加载
    ├── SongDataSource(IDataSource) ──LazyForEach(ds, itemGenerator, keyGenerator)──→ SongCard(@ObjectLink)
    │     totalCount/getData/register/unregister    cachedCount(5) 缓存
    │     notifyDataAdd/Delete/Change/Move/Reload   仅渲染可见+缓存区域
    └── List .onMove(from, to) ── swapData 内部交换 ── notifyDataMove 通知 UI 更新
```

#### 1.ForEach 基本渲染与键值生成规则 — "喜欢"歌单展示

```typescript
// 歌曲数据模型，使用 @Observed 装饰，支持子属性变化观测
@Observed
class Song {
  id: number = 0
  title: string = ''
  // ...
}

// 歌曲卡片子组件，@ObjectLink 接收 @Observed 装饰的 Song 实例，可观测子属性变化
@Component
struct SongCard {
  @ObjectLink song: Song

  build() {
    Row({ space: 12 }) {
      // ...
      // 收藏按钮：@ObjectLink 观测 isFavorite 变化，图标自动切换
      Button() {
        SymbolGlyph(this.song.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
      }.onClick(() => { this.song.isFavorite = !this.song.isFavorite })
    }
    // ...样式省略
  }
}

@Entry
@Component
struct FavoritesPlaylistPage {
  // @State 装饰歌曲数组，数组变化触发 ForEach 重新渲染
  @State songs: Song[] = [
    new Song(1, '歌名A', '歌手A', 269),
    new Song(2, '歌名B', '歌手B', 223),
    new Song(3, '歌名C', '歌手C', 299)
  ]

  build() {
    Column({ space: 10 }) {
      Text('我喜欢')

      // ForEach 三参数：数组、子项生成函数、键值生成函数
      // keyGenerator 必须返回唯一且稳定的字符串，使用 item.id 作为键值
      ForEach(this.songs, (item: Song) => {
        SongCard({ song: item })
      }, (item: Song): string => item.id.toString())
    }
    // ...样式省略
  }
}
```

#### 2.ForEach 数据增删与 @Observed+@ObjectLink 子属性观测 — 添加/删除/收藏歌曲

```typescript
// 页面结构同步骤1，在 ForEach 下方添加数据操作按钮
// @State songs / nextId 定义同步骤1，nextId 初始值为 4
// SongCard 收藏按钮：@Observed 子属性 isFavorite 变化 → @ObjectLink 自动观测

Row({ space: 10 }) {
  Button('添加歌曲').onClick(() => {
    // push 新歌曲，@State 检测数组变化，ForEach 键值对比增量渲染新项
    this.songs.push(new Song(this.nextId++, `新歌${this.nextId - 1}`, '未知歌手', 200))
  })
  Button('删除最后一首').onClick(() => { if (this.songs.length > 0) this.songs.splice(this.songs.length - 1, 1) })
  Button('删除第一首').onClick(() => { if (this.songs.length > 0) this.songs.shift() })
}
```

#### 3.ForEach 拖拽排序（onMove）— 歌单排序

```typescript
// 页面结构同步骤1，将 ForEach 放入 List 并添加 .onMove 拖拽排序回调
List({ space: 8 }) {
  ForEach(this.songs, (item: Song) => {
    ListItem() { SongCard({ song: item }) }
  }, (item: Song): string => item.id.toString())
}
.onMove((from: number, to: number) => {
  // onMove 回调：from 为起始位置，to 为目标位置
  // 交换数组元素：先从 from 位置取出，再插入到 to 位置
  const moved = this.songs.splice(from, 1)[0]
  this.songs.splice(to, 0, moved)
  // @State 检测数组变化，ForEach 键值对比增量更新顺序
})
```

#### 4.LazyForEach IDataSource 实现与懒加载渲染 — "本地音乐"库长列表

```typescript
// SongDataSource 实现 IDataSource 接口，作为 LazyForEach 的数据源
class SongDataSource implements IDataSource {
  private songs: Song[] = []
  private listeners: DataChangeListener[] = []

  // === IDataSource 必须实现的 4 个方法 ===
  totalCount(): number { return this.songs.length }
  getData(index: number): Song { return this.songs[index] }
  // 注册/注销数据变化监听器（LazyForEach 内部自动调用）
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) === -1) { this.listeners.push(listener) }
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener)
    if (pos >= 0) { this.listeners.splice(pos, 1) }
  }

  // === 5 个通知方法，通知 LazyForEach 更新 UI ===
  notifyDataReload(): void { this.listeners.forEach((l: DataChangeListener) => l.onDataReloaded()) }
  notifyDataAdd(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataAdd(index)) }
  notifyDataDelete(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataDelete(index)) }
  notifyDataChange(index: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataChange(index)) }
  notifyDataMove(from: number, to: number): void { this.listeners.forEach((l: DataChangeListener) => l.onDataMove(from, to)) }

  setSongs(songs: Song[]): void { this.songs = songs }
}

@Entry
@Component
struct LocalMusicLibraryPage {
  private dataSource: SongDataSource = new SongDataSource()

  aboutToAppear() {
    // 生成 500+ 首歌曲模拟本地音乐库
    const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
      new Song(i + 1, `歌曲${i + 1}`, `歌手${(i + 1) % 20}`, 180 + (i + 1) % 120))
    this.dataSource.setSongs(songs)
  }

  build() {
    Column({ space: 10 }) {
      Text('本地音乐')

      // LazyForEach 懒加载渲染，cachedCount(5) 缓存，仅渲染可见+缓存区域
      List({ space: 8 }) {
        LazyForEach(this.dataSource, (item: Song) => {
          ListItem() { SongCard({ song: item }) }
        }, (item: Song): string => item.id.toString())
      }
      .cachedCount(5)
    }
    // ...样式省略
  }
}
```

#### 5.LazyForEach 数据增删改移重载 — 搜索/添加/删除/移动/重载

```typescript
// 在步骤 4 的 SongDataSource 中扩展以下数据操作方法
// 每个方法修改内部数组后必须调用对应的 notifyData* 通知 UI 更新
class SongDataSource implements IDataSource {
  private songs: Song[] = []
  private listeners: DataChangeListener[] = []

  // === IDataSource 接口实现（见步骤 4）===
  // ... totalCount / getData / register / unregister / notifyData* / setSongs

  // === 数据操作方法：修改内部数据 + 调用 notifyData* 通知 UI ===
  addSong(song: Song): void {
    this.songs.push(song)
    this.notifyDataAdd(this.songs.length - 1)
  }
  deleteSong(index: number): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs.splice(index, 1); this.notifyDataDelete(index)
    }
  }
  changeSong(index: number, song: Song): void {
    if (index >= 0 && index < this.songs.length) {
      this.songs[index] = song; this.notifyDataChange(index)
    }
  }
  moveSong(from: number, to: number): void {
    if (from < 0 || from >= this.songs.length || to < 0 || to >= this.songs.length) return
    const moved = this.songs.splice(from, 1)[0]
    this.songs.splice(to, 0, moved)
    this.notifyDataMove(from, to)
  }
  reloadSongs(songs: Song[]): void { this.songs = songs; this.notifyDataReload() }
  swapData(from: number, to: number): void { this.moveSong(from, to) }
  // 搜索过滤：返回符合关键词的歌曲
  searchSongs(keyword: string): Song[] {
    return this.songs.filter((s: Song) =>
      s.title.includes(keyword) || s.artist.includes(keyword))
  }
}

@Entry
@Component
struct LocalMusicLibraryPage {
  private dataSource: SongDataSource = new SongDataSource()
  @State searchKeyword: string = ''
  private nextId: number = 501

  aboutToAppear() {
    const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
      new Song(i + 1, `歌曲${i + 1}`, `歌手${(i + 1) % 20}`, 180 + (i + 1) % 120))
    this.dataSource.setSongs(songs)
  }

  build() {
    Column({ space: 10 }) {
      Text('本地音乐')

      // 搜索框：输入关键词后点击搜索，reloadSongs 重载过滤后的数据
      TextInput({ placeholder: '搜索歌曲或歌手', text: this.searchKeyword })
        .onChange((value: string) => { this.searchKeyword = value })
      Button('搜索').onClick(() => {
        // 搜索过滤后重载数据，notifyDataReload 销毁所有项并重建
        this.dataSource.reloadSongs(this.dataSource.searchSongs(this.searchKeyword))
      })

      List({ space: 8 }) {
        LazyForEach(this.dataSource, (item: Song) => {
          ListItem() { SongCard({ song: item }) }
        }, (item: Song): string => item.id.toString())
      }
      .cachedCount(5)

      // 数据操作按钮：演示 5 种 notifyData* 方法
      Row({ space: 8 }) {
        Button('添加').onClick(() => {
          this.dataSource.addSong(new Song(this.nextId++, `新歌${this.nextId - 1}`, '新歌手', 200))
        })
        Button('删除首项').onClick(() => { this.dataSource.deleteSong(0) })
        Button('改第一首').onClick(() => {
          // 仅修改 @Observed 子属性不需要 notifyDataChange，@ObjectLink 自动观测
          // notifyDataChange 用于替换整个数据项的场景
          this.dataSource.changeSong(0, new Song(9999, '修改后的歌', '修改后的歌手', 300))
        })
        Button('移动').onClick(() => { this.dataSource.moveSong(0, 2) })
        Button('重载').onClick(() => {
          const songs: Song[] = Array.from({ length: 500 }, (_, i) =>
            new Song(i + 1, `重载歌曲${i + 1}`, `歌手${(i + 1) % 20}`, 180 + (i + 1) % 120))
          this.dataSource.reloadSongs(songs)
        })
      }
    }
    // ...样式省略
  }
}
```

#### 6.LazyForEach 拖拽排序与 @Observed+@ObjectLink 深层属性观测

```typescript
// 页面结构同步骤4，在 List 上添加 .onMove 实现长列表拖拽排序
List({ space: 8 }) {
  LazyForEach(this.dataSource, (item: Song) => {
    ListItem() {
      // SongCard 使用 @ObjectLink 观测 isFavorite/playCount 变化
      // 修改 @Observed 子属性 → @ObjectLink 自动刷新，无需 notifyDataChange
      SongCard({ song: item })
    }
  }, (item: Song): string => item.id.toString())
}
.cachedCount(5)
.onMove((from: number, to: number) => {
  // onMove 回调：调用 swapData 交换 IDataSource 内部数据
  // swapData 内部调用 notifyDataMove 通知 UI 更新项的位置
  this.dataSource.swapData(from, to)
})
```
---

### V1版本的循环渲染

**场景ID：** STATE_RELATIVE_15

**场景描述：** 仿音乐播放器歌单管理页，列表中展示不同类型的音乐项目（歌曲、专辑、广告推荐），支持懒加载、节点复用、无限滚动、拖拽排序和精确属性观测。需要通过 V2 的 Repeat 链式 API 实现多类型模板渲染、按需加载和深层属性变化观测，覆盖 .each() 基本渲染、.key() 键值生成、.template()/.templateId() 多模板、.virtualScroll() 懒加载 + @ReusableV2 节点复用、.onLazyLoading() 精准懒加载、.onMove() 拖拽排序 + @ObservedV2+@Trace+@Param 深层属性观测。

**解决方案：** 使用 **`Repeat`** 链式 API 实现循环渲染 + **`@ObservedV2` + `@Trace` + `@Param`** 实现深层属性精确观测 + **`@ReusableV2`** 实现节点复用

```
Repeat<MusicItem>(songs)
  ├── .each() ──────── 基本渲染（类似 ForEach，默认全量渲染）
  ├── .key() ────────── 键值生成（唯一稳定字符串，同 ForEach 规则）
  ├── .templateId() ─── 类型选择器（返回模板名或 undefined）
  │     ├── .template('album') → AlbumCardV2 / .template('ad') → AdCardV2
  │     └── 返回 undefined → .each() 默认渲染（SongCardV2）
  ├── .virtualScroll() ─ 懒加载 + @ReusableV2 节点复用（同模板类型共享复用池）
  ├── .onLazyLoading() ─ 精准懒加载（滚动接近末尾时自动加载，index → 异步请求 → 追加数据）
  └── .onMove() ──────── 拖拽排序 + @ObservedV2 + @Trace + @Param 深层属性精确观测
```

#### 1.Repeat .each() 基本渲染与 .key() 键值生成

```typescript
// 音乐数据模型（V2版本，配合 @ObservedV2 + @Trace 观测深层属性变化）
@ObservedV2
class MusicItem {
  @Trace id: number = 0
  @Trace title: string = ''
  // ...
}

// 歌曲卡片组件 — @Param 接收 @ObservedV2+@Trace 类数据，子属性变化可观测
@ComponentV2
struct SongCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')

  build() {
    Row({ space: 12 }) {
      // ...
      // 收藏按钮 — @Trace 装饰的 isFavorite 变化可被 @Param 观测，触发 UI 刷新
      Image(this.item.isFavorite ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .onClick(() => { this.item.isFavorite = !this.item.isFavorite })
    }
    // ...样式省略
  }
}

@Entry
@ComponentV2
struct PlaylistPage {
  @Local songs: MusicItem[] = [
    new MusicItem(1, '歌名A', '歌手A', 'song'),
    new MusicItem(2, '歌名B', '歌手B', 'song'),
    new MusicItem(3, '歌名C', '歌手C', 'song')
  ]

  build() {
    Column() {
      Text('我的歌单 — Repeat .each() 基本渲染')

      List({ space: 10 }) {
        // Repeat 链式调用：.each() 指定渲染函数 → .key() 指定键值生成器
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { SongCardV2({ item: ri.item }) }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
      }
    }
    // ...样式省略
  }
}
```

#### 2.Repeat .template()/.templateId() 多类型模板渲染（歌曲/专辑/广告）

```typescript
// 音乐数据模型 MusicItem 及 SongCardV2 定义见步骤1

// 专辑卡片组件
@ComponentV2
struct AlbumCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')
  build() { Row({ space: 12 }) { /* ... */ } }
}

// 广告卡片组件（橙色背景区分）
@ComponentV2
struct AdCardV2 {
  @Param item: MusicItem = new MusicItem(0, '', '')
  build() { Row({ space: 10 }) { /* ... */ } }
}

@Entry
@ComponentV2
struct PlaylistTemplatePage {
  @Local songs: MusicItem[] = [
    new MusicItem(1, '歌名A', '歌手A', 'song'),
    new MusicItem(2, '歌名B', '歌手B', 'song'),
    new MusicItem(3, '歌名C', '歌手C', 'song')
  ]

  build() {
    Column() {
      Text('我的歌单 — Repeat .template() 多类型渲染')

      List({ space: 10 }) {
        // Repeat 配合 .template() 实现多类型渲染，.each() 作为默认渲染函数（歌曲类型）
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { SongCardV2({ item: ri.item }) }
          })
          .template('album', (ri: RepeatItem<MusicItem>) => {
            ListItem() { AlbumCardV2({ item: ri.item }) }
          })
          .template('ad', (ri: RepeatItem<MusicItem>) => {
            ListItem() { AdCardV2({ item: ri.item }) }
          })
          // templateId：根据数据项的 type 字段返回模板名称，返回 undefined 时使用 .each() 默认渲染
          .templateId((ri: RepeatItem<MusicItem>) => {
            if (ri.item.type === 'album') return 'album'
            if (ri.item.type === 'ad') return 'ad'
            return undefined
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
      }
    }
    // ...样式省略
  }
}
```

#### 3.Repeat .virtualScroll() 懒加载与 @ReusableV2 节点复用

```typescript
// 音乐数据模型（定义见步骤1）

// 配合 @ReusableV2 实现节点复用 — 滚动时回收不可见组件，复用已回收组件
// SongCardReusableV2 / AlbumCardReusableV2 / AdCardReusableV2 结构同步骤2对应组件，增加 @ReusableV2 装饰器

@Entry
@ComponentV2
struct PlaylistLazyPage {
  @Local songs: MusicItem[] = createLongMusicList()

  build() {
    Column() {
      Text('我的歌单 — Repeat virtualScroll 懒加载 + 节点复用')

      List({ space: 10 }) {
        // 模板配置同步骤2，卡片组件改为 @ReusableV2 版本
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => { ListItem() { SongCardReusableV2({ item: ri.item }) } })
          .template('album', (ri: RepeatItem<MusicItem>) => { ListItem() { AlbumCardReusableV2({ item: ri.item }) } })
          .template('ad', (ri: RepeatItem<MusicItem>) => { ListItem() { AdCardReusableV2({ item: ri.item }) } })
          .templateId((ri: RepeatItem<MusicItem>) => ri.item.type === 'album' ? 'album' : ri.item.type === 'ad' ? 'ad' : undefined)
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
          // virtualScroll：开启懒加载，仅在可视区域和缓存区域渲染组件
          .virtualScroll({ cachedCount: 5 })
      }
    }
    // ...样式省略
  }
}
```

#### 4.Repeat .onLazyLoading() 精准懒加载（滚动到底部自动加载）

```typescript
// 音乐数据模型（定义见步骤1）

let nextLazyId: number = 21

@Entry
@ComponentV2
struct PlaylistOnLazyPage {
  @Local songs: MusicItem[] = []
  @Local isLoading: boolean = false

  aboutToAppear(): void {
    // 初始加载前 20 条数据
    for (let i = 1; i <= 20; i++) {
      let item = new MusicItem(i, `歌曲${i}`, `歌手${i}`, i % 7 === 0 ? 'ad' : 'song')
      item.duration = Math.floor(Math.random() * 300) + 120
      this.songs.push(item)
    }
  }
  build() {
    Column() {
      Text('我的歌单 — Repeat onLazyLoading 精准懒加载')

      if (this.isLoading) {
        LoadingProgress()
      }

      List({ space: 10 }) {
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { /* ... */ }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
          .virtualScroll({ cachedCount: 3 })
          // onLazyLoading：当滚动接近末尾时触发，按需追加数据
          .onLazyLoading((index: number) => {
            this.isLoading = true
            // 模拟异步请求：延迟追加 10 条数据
            setTimeout(() => {
              for (let i = 0; i < 10; i++) {
                let item = new MusicItem(nextLazyId, `懒加载歌曲${nextLazyId}`,
                  `歌手${nextLazyId}`, nextLazyId % 7 === 0 ? 'ad' : 'song')
                item.duration = Math.floor(Math.random() * 300) + 120
                this.songs.push(item)
                nextLazyId++
              }
              this.isLoading = false
            }, 500)
          })
      }
    }
    // ...样式省略
  }
}
```

#### 5.Repeat .onMove() 拖拽排序与 @ObservedV2+@Trace 深层属性观测

```typescript
// 音乐数据模型（定义见步骤1）

// 生成 20 条音乐数据用于拖拽排序
function createDragMusicList(): MusicItem[] {
  return Array.from({ length: 20 }, (_, i) => {
    let item = new MusicItem(i + 1, `歌曲${i + 1}`, `歌手${i + 1}`)
    item.duration = Math.floor(Math.random() * 300) + 120
    return item
  })
}

@Entry
@ComponentV2
struct PlaylistDragSortPage {
  @Local songs: MusicItem[] = createDragMusicList()

  build() {
    Column() {
      Text('我的歌单 — Repeat 拖拽排序 + 深层属性观测')

      Row({ space: 8 }) {
        Button('新增歌曲').onClick(() => {
          let item = new MusicItem(this.songs.length + 1, `新歌${this.songs.length + 1}`, `新歌手`)
          item.duration = Math.floor(Math.random() * 300) + 120
          this.songs.push(item)
        })
        Button('删除末条').onClick(() => {
          if (this.songs.length > 0) { this.songs.pop() }
        })
      }

      List({ space: 10 }) {
        Repeat<MusicItem>(this.songs)
          .each((ri: RepeatItem<MusicItem>) => {
            ListItem() { /* ... */ }
          })
          .key((ri: RepeatItem<MusicItem>) => ri.item.id.toString())
          .virtualScroll({ cachedCount: 5 })
          // onMove 回调：拖拽排序时交换数组中的数据位置
          .onMove((from: number, to: number) => {
            let temp: MusicItem = this.songs[from]
            this.songs[from] = this.songs[to]
            this.songs[to] = temp
          })
      }
    }
    // ...样式省略
  }
}
```
---