// customTransition 页面级自定义转场动画框架模板
// 归属组件：NavDestination
// API: customTransition(delegate: NavDestinationTransitionDelegate)
// @since: 15
// 来源: interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:1274
// 官方示例: developer.huawei.com/.../navdestination 示例2（设置NavDestination自定义转场）
//
// NavDestinationTransitionDelegate 签名:
//   (operation: NavigationOperation, isEnter: boolean) => Array<NavDestinationTransition> | undefined
//
// 注意: customTransition 是页面级转场，无法在转场过程中响应交互。
//       如需交互（如手势返回），请使用 customNavContentTransition（Navigation 整体级）。
//
// ⚠️ 编译错误防护（ArkTS:10505001）：
// customTransition 是 NavDestination 的链式属性方法，delegate 作为参数传入。
// 不要在 struct 中定义名为 pageTransition 的方法并使用 NavDestinationTransitionDelegate 签名。
// pageTransition 是 CustomComponent 的生命周期方法（签名 () => void），与 customTransition 无关。
// 错误写法会导致编译报错：Property 'pageTransition' in type 'X' is not assignable
//   to the same property in base type 'CustomComponent'.
//
// ⚠️ 动画赋值模式（核心规则，违反则动画不生效或行为错误）：
// 1. 动画【初始值】必须在 customTransition 回调体内【同步赋值】——即 delegate 执行时、
//    返回 NavDestinationTransition 数组之前，直接对驱动动画的 @State 变量赋初值。
// 2. 动画【结束值】必须在 event 闭包内【直接赋值】——event 本身就运行在动画执行上下文中，
//    系统会根据闭包中对组件 UI 状态的修改生成过渡动画（等价于 animateTo 的 event 闭包语义）。
// 3. event 内【禁止】再调用 animateTo —— 二次包裹会破坏系统转场动画上下文，导致动画异常。
//    官方文档：event = "指定转场动效的闭包函数，系统会根据闭包中对组件UI状态的修改，
//              生成对应的过渡动画。参见 animateTo 中的 event。"

declare type voidFunc = () => void;

@Entry
@Component
struct CustomTransitionPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      // 导航首页内容
      Column() {
        Button('Push Detail Page')
          .onClick(() => {
            this.pageStack.pushPath({ name: 'CustomDetailPage' })
          })
      }
    }
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: unknown): void {
    if (name === 'CustomDetailPage') {
      CustomDetailPage()
    }
  }
}

@Component
struct CustomDetailPage {
  // 驱动转场动画的 @State 变量；注意避开通用属性保留名（translate 是保留名，故加业务前缀）
  @State cardTranslateY: string = '0'

  build() {
    NavDestination() {
      Column() {
        Text('Custom Transition Page')
          .fontSize(20)
          .margin(20)
      }
      .width('100%')
      .height('100%')
    }
    .title('Custom Detail')
    // 将动画驱动变量绑定到组件属性，系统据此生成过渡动画
    .translate({ y: this.cardTranslateY })
    // 自定义转场动画 — 代理函数按 operation(PUSH/POP) × isEnter(入场/退场) 返回动画配置
    .customTransition(this.customTransitionDelegate)
  }

  // NavDestinationTransitionDelegate:
  // (operation: NavigationOperation, isEnter: boolean) => Array<NavDestinationTransition> | undefined
  private customTransitionDelegate = (op: NavigationOperation, isEnter: boolean):
    Array<NavDestinationTransition> | undefined => {
    let transitionEvent: voidFunc = () => {}

    if (op === NavigationOperation.PUSH) {
      if (isEnter) {
        // PUSH 入场：初始值在回调内同步赋值（动画起点）
        this.cardTranslateY = '100%'
        // event 内直接赋结束值（动画终点），系统自动在此上下文生成过渡动画
        transitionEvent = () => {
          this.cardTranslateY = '0'
        }
      } else {
        // PUSH 退场（被新页面覆盖）
        this.cardTranslateY = '0'
        transitionEvent = () => {
          this.cardTranslateY = '0'
        }
      }
    } else if (op === NavigationOperation.POP) {
      if (isEnter) {
        // POP 入场（回到本页面）
        this.cardTranslateY = '0'
        transitionEvent = () => {
          this.cardTranslateY = '0'
        }
      } else {
        // POP 退场（本页面被弹出）
        this.cardTranslateY = '0'
        transitionEvent = () => {
          this.cardTranslateY = '100%'
        }
      }
    }

    const transition: NavDestinationTransition = {
      duration: 500,
      delay: 0,
      curve: Curve.EaseInOut,
      event: transitionEvent,
      onTransitionEnd: () => {
        // 转场动画结束回调
      }
    }

    return [transition]
  }
}
