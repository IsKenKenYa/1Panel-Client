// customNavContentTransition Navigation 整体可交互转场框架模板
// 归属组件：Navigation
// API: customNavContentTransition(delegate: (from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation) => NavigationAnimatedTransition | undefined)
// @since: 11
// 来源: interface_sdk-js/api/@internal/component/ets/navigation.d.ts:2868
//
// NavigationAnimatedTransition 接口:
//   transition: (transitionProxy: NavigationTransitionProxy) => void  — 执行转场动画的回调（proxy 含 from/to 页面信息）
//   onTransitionEnd?: (success: boolean) => void                     — 转场完成回调
//   timeout?: number                                                 — 超时时间（毫秒）
//   isInteractive?: boolean                                          — 是否可交互（默认 false）
//
// NavigationTransitionProxy 接口:
//   from: NavContentInfo          — 退出页信息
//   to: NavContentInfo            — 进入页信息
//   isInteractive?: boolean       — 是否可交互
//   finishTransition(): void      — 结束转场（必须手动调用）→ 必填方法
//   cancelTransition?(): void     — 取消交互式转场 → 可选方法，调用时用 proxy.cancelTransition?.()
//   updateTransition?(progress: number): void — 更新交互式转场进度 [0, 1] → 可选方法，调用时用 proxy.updateTransition?.(progress)
//
// ⚠️ 编译错误防护（ArkTS:10605999 — Cannot invoke an object which is possibly 'undefined'）:
//   第一层: 类属性 proxy 类型含 | undefined，if (!this.proxy) 守卫后 this.proxy 仍 possibly undefined。
//           修复: let proxy = this.proxy; if (!proxy) return; 在局部变量 proxy 上调用。
//   第二层: cancelTransition / updateTransition 是接口可选方法（签名带 ?），类型含 | undefined。
//           即使 proxy 已收窄，直接 proxy.updateTransition(progress) 仍报 10605999。
//           修复: 用可选链 proxy.updateTransition?.(progress) / proxy.cancelTransition?.()。
//           finishTransition 是必填方法，proxy 收窄后可直接 proxy.finishTransition()。
//
// 注册建议:
//   方式1 — 全局注册: 在 Navigation 上直接配置 customNavContentTransition，所有页面共用
//   方式2 — 单例可访问: 用单例工具类管理各页面动画回调（onReady 注册、aboutToDisappear 注销）

// ============================================================
// 方式1: 全局注册 — 在 Navigation 组件上直接配置
// ============================================================

@Entry
@Component
struct GlobalNavContentTransitionPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column() {
        Button('Push Detail Page')
          .onClick(() => {
            this.pageStack.pushPath({ name: 'AnimatedDetailPage' })
          })
      }
    }
    .navDestination(this.navDestinationBuilder)
    // 整体可交互转场 — 在 Navigation 组件上配置
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation): NavigationAnimatedTransition | undefined => {
      // 返回 undefined 时使用系统默认转场
      if (!from || !to) {
        return undefined
      }
      // 返回可交互转场配置
      return {
        timeout: 2000,
        isInteractive: true,
        // transition 回调接收 NavigationTransitionProxy，proxy 含 from/to 页面信息
        transition: (transitionProxy: NavigationTransitionProxy): void => {
          // 从 proxy.from / proxy.to 获取退出页和进入页信息
          // 在此实现自定义转场动画逻辑
          // 调用 animateTo 执行动画，动画完成后调用 finishTransition()
          this.getUIContext()?.animateTo({
            duration: 300,
            curve: Curve.EaseInOut,
            onFinish: () => {
              // 必须手动调用 finishTransition 结束转场
              transitionProxy.finishTransition()
            }
          }, () => {
            // 修改组件 UI 状态生成转场动画
          })
        },
        onTransitionEnd: (success: boolean): void => {
          // 转场完成回调
        }
      }
    })
  }

  @Builder
  navDestinationBuilder(name: string, param: unknown): void {
    if (name === 'AnimatedDetailPage') {
      AnimatedDetailPage()
    }
  }
}

// ============================================================
// 方式2: 单例可访问 — 单例工具类管理各页面动画回调
// ============================================================

// 单例工具类 — 管理各页面注册的转场回调
class CustomTransitionUtils {
  private static instance: CustomTransitionUtils | null = null
  private callbackMap: Map<string, AnimateCallback> = new Map<string, AnimateCallback>()

  static getInstance(): CustomTransitionUtils {
    if (CustomTransitionUtils.instance === null) {
      CustomTransitionUtils.instance = new CustomTransitionUtils()
    }
    return CustomTransitionUtils.instance
  }

  // 页面 onReady 时注册回调
  registerCallback(name: string, callback: AnimateCallback): void {
    this.callbackMap.set(name, callback)
  }

  // 页面 aboutToDisappear 时注销回调
  unregisterCallback(name: string): void {
    this.callbackMap.delete(name)
  }

  getCallback(name: string): AnimateCallback | undefined {
    return this.callbackMap.get(name)
  }
}

interface AnimateCallback {
  timeout?: number
  animation?: (proxy: NavigationTransitionProxy) => void
}

@Entry
@Component
struct SingletonNavContentTransitionPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      Column() {
        Button('Push Detail Page')
          .onClick(() => {
            this.pageStack.pushPath({ name: 'SingletonDetailPage' })
          })
      }
    }
    .navDestination(this.navDestinationBuilder)
    // 整体可交互转场 — 通过单例查找分发
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation): NavigationAnimatedTransition | undefined => {
      if (!from || !to) {
        return undefined
      }
      let fromCallback: AnimateCallback | undefined = CustomTransitionUtils.getInstance().getCallback(from.name ? from.name : '')
      let toCallback: AnimateCallback | undefined = CustomTransitionUtils.getInstance().getCallback(to.name ? to.name : '')
      if (!fromCallback || !toCallback) {
        return undefined
      }
      return {
        timeout: toCallback.timeout,
        isInteractive: true,
        transition: (transitionProxy: NavigationTransitionProxy): void => {
          // 根据 operation 和 proxy.from/to 调用对应页面的动画回调
          toCallback?.animation?.(transitionProxy)
        }
      }
    })
  }

  @Builder
  navDestinationBuilder(name: string, param: unknown): void {
    if (name === 'SingletonDetailPage') {
      SingletonDetailPage()
    }
  }
}

@Component
struct SingletonDetailPage {
  @State pathStack: NavPathStack = new NavPathStack()

  aboutToDisappear(): void {
    // 页面销毁时注销回调
    CustomTransitionUtils.getInstance().unregisterCallback('SingletonDetailPage')
  }

  build() {
    NavDestination() {
      Column() {
        Text('Singleton Transition Detail Page')
          .fontSize(20)
          .margin(20)
      }
      .width('100%')
      .height('100%')
    }
    .title('Singleton Detail')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack ? context.pathStack : new NavPathStack()
      // 页面 onReady 时注册动画回调
      CustomTransitionUtils.getInstance().registerCallback('SingletonDetailPage', {
        timeout: 2000,
        animation: (proxy: NavigationTransitionProxy): void => {
          this.getUIContext()?.animateTo({
            duration: 300,
            curve: Curve.EaseInOut,
            onFinish: () => {
              proxy.finishTransition()
            }
          }, () => {
            // 页面入场/退场动画
          })
        }
      })
    })
  }
}

// ============================================================
// 方式3: 手势驱动可交互转场 — NavDestination 通过 PanGesture 触发
// ============================================================
//
// 与方式1/2 的关键区别:
//   isInteractive: true 时，transition 回调不再用 animateTo 播放完整动画，
//   而是将 proxy 存入单例，由 NavDestination 页面的 PanGesture 驱动:
//     onActionStart → pushPath / pop 触发转场
//     onActionUpdate → proxy.updateTransition(progress) 逐帧更新进度 [0,1]
//     onActionEnd → proxy.finishTransition() 或 proxy.cancelTransition() 完成或取消
//
// 文件结构（实际项目中拆分为独立 .ets 文件）:
//   Index.ets                  — Navigation 入口 + customNavContentTransition
//   InteractivePageOne.ets     — NavDestination 页面1，含 PanGesture
//   InteractivePageTwo.ets     — NavDestination 页面2，含 PanGesture
//   InteractiveTransition.ets  — 单例工具类
//   resources/base/profile/router_map.json — 路由表

// --- InteractiveTransition.ets ---

export interface InteractiveAnimateCallback {
  start?: (isPush: boolean, isExit: boolean) => void
  finish?: (isPush: boolean, isExit: boolean) => void
  onFinish?: (isPush: boolean, isExit: boolean) => void
  interactive?: (operation: NavigationOperation) => void
  timeout?: number
}

export class InteractiveTransition {
  private static delegate: InteractiveTransition = new InteractiveTransition()
  private callbackMap: Map<string, InteractiveAnimateCallback> = new Map<string, InteractiveAnimateCallback>()
  interactive: boolean = false
  proxy: NavigationTransitionProxy | undefined = undefined
  operation: NavigationOperation = NavigationOperation.PUSH

  static getInstance(): InteractiveTransition {
    return InteractiveTransition.delegate
  }

  registerCallback(id: string, callback: InteractiveAnimateCallback): void {
    this.callbackMap.set(id, callback)
  }

  unregisterCallback(id: string): void {
    this.callbackMap.delete(id)
  }

  getCallback(id: string): InteractiveAnimateCallback {
    return this.callbackMap.get(id) ?? {}
  }

  fireInteractiveAnimation(id: string, operation: NavigationOperation): void {
    let callback = this.callbackMap.get(id)
    callback?.interactive?.(operation)
  }

  updateProgress(progress: number): void {
    let proxy = this.proxy
    if (!proxy) {
      return
    }
    progress = this.operation == NavigationOperation.PUSH ? 1 - progress : progress
    proxy.updateTransition?.(progress)
  }

  finishInteractiveAnimation(rate: number): void {
    let proxy = this.proxy
    if (!proxy) {
      return
    }
    let shouldCancel = (this.operation == NavigationOperation.PUSH) ? (rate > 0.5) : (rate <= 0.5)
    if (shouldCancel) {
      proxy.cancelTransition?.()
    } else {
      proxy.finishTransition()
    }
  }

  recoverState(): void {
    let proxy = this.proxy
    if (!proxy) {
      return
    }
    let fromCallback = this.callbackMap.get(proxy.from.navDestinationId ?? '')
    fromCallback?.onFinish?.(false, false)
    let toCallback = this.callbackMap.get(proxy.to.navDestinationId ?? '')
    toCallback?.onFinish?.(true, true)
  }
}

// --- Index.ets ---

@Entry
@Component
struct InteractiveNavigationEntry {
  pageStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    this.pageStack.pushPath({ name: 'interactivePageOne' })
  }

  build() {
    Navigation(this.pageStack) {
    }
    .title('Interactive Transition')
    .hideNavBar(true)
    .customNavContentTransition((from: NavContentInfo, to: NavContentInfo, operation: NavigationOperation): NavigationAnimatedTransition | undefined => {
      if (from.mode == NavDestinationMode.DIALOG || to.mode == NavDestinationMode.DIALOG) {
        return undefined
      }
      if (from.index === -1 || to.index === -1) {
        return undefined
      }

      InteractiveTransition.getInstance().operation = operation

      if (InteractiveTransition.getInstance().interactive) {
        return {
          onTransitionEnd: (isSuccess: boolean): void => {
            InteractiveTransition.getInstance().recoverState()
            InteractiveTransition.getInstance().proxy = undefined
          },
          transition: (transitionProxy: NavigationTransitionProxy): void => {
            InteractiveTransition.getInstance().proxy = transitionProxy
            let targetId: string | undefined = operation == NavigationOperation.PUSH
              ? to.navDestinationId
              : from.navDestinationId
            if (targetId) {
              InteractiveTransition.getInstance().fireInteractiveAnimation(targetId, operation)
            }
          },
          isInteractive: true
        }
      }

      return {
        onTransitionEnd: (isSuccess: boolean): void => {
        },
        timeout: 7000,
        transition: (transitionProxy: NavigationTransitionProxy): void => {
          if (!from.navDestinationId || !to.navDestinationId) {
            return
          }
          let fromCallback = InteractiveTransition.getInstance().getCallback(from.navDestinationId)
          let toCallback = InteractiveTransition.getInstance().getCallback(to.navDestinationId)
          if (operation == NavigationOperation.PUSH) {
            toCallback.start?.(true, false)
            this.getUIContext()?.animateTo({
              duration: 500, onFinish: () => {
                transitionProxy.finishTransition()
              }
            }, () => {
              toCallback.finish?.(true, false)
            })
          } else {
            fromCallback.start?.(true, true)
            this.getUIContext()?.animateTo({
              duration: 500, onFinish: () => {
                transitionProxy.finishTransition()
              }
            }, () => {
              fromCallback.finish?.(true, true)
            })
          }
        }
      }
    })
  }
}

// --- InteractivePageOne.ets ---

@Component
export struct InteractivePageOne {
  pageStack: NavPathStack = new NavPathStack()
  @State pageOneTranslateX: string = '0'
  pageId: string = ''
  pageWidth: number = 0

  private registerCallback(): void {
    InteractiveTransition.getInstance().registerCallback(this.pageId, {
      start: (isPush: boolean, isExit: boolean): void => {
        this.pageOneTranslateX = isPush ? '100%' : '0'
      },
      finish: (isPush: boolean, isExit: boolean): void => {
        this.pageOneTranslateX = isPush ? '0' : '100%'
      },
      onFinish: (isPush: boolean, isExit: boolean): void => {
        this.pageOneTranslateX = '0'
      },
      interactive: (operation: NavigationOperation): void => {
        if (operation == NavigationOperation.PUSH) {
          this.pageOneTranslateX = '100%'
          this.getUIContext()?.animateTo({
            duration: 1000,
            onFinish: () => {
              this.pageOneTranslateX = '0'
            }
          }, () => {
            this.pageOneTranslateX = '0'
          })
        } else {
          this.pageOneTranslateX = '0'
          this.getUIContext()?.animateTo({
            duration: 1000,
            onFinish: () => {
              this.pageOneTranslateX = '0'
            }
          }, () => {
            this.pageOneTranslateX = '100%'
          })
        }
      },
      timeout: 200
    })
  }

  build() {
    NavDestination() {
      Column() {
        Button('Toggle Interactive')
          .onClick(() => {
            InteractiveTransition.getInstance().interactive = !InteractiveTransition.getInstance().interactive
          })

        Button('Push PageTwo')
          .width('80%')
          .height(40)
          .margin(20)
          .onClick(() => {
            this.pageStack.pushPath({ name: 'interactivePageTwo' })
          })
      }
      .size({ width: '100%', height: '100%' })
    }
    .title('PageOne')
    .translate({ x: this.pageOneTranslateX })
    .backgroundColor('#F1F3F5')
    .gesture(PanGesture()
      .onActionStart((event: GestureEvent) => {
        this.pageWidth = event.target.area.width as number
        if (event.offsetX < 0) {
          this.pageStack.pushPath({ name: 'interactivePageTwo' })
        } else {
          this.pageStack.pop()
        }
      })
      .onActionUpdate((event: GestureEvent) => {
        let rate = event.fingerList[0].localX / this.pageWidth
        InteractiveTransition.getInstance().updateProgress(rate)
      })
      .onActionEnd((event: GestureEvent) => {
        let rate: number = event.fingerList[0].localX / this.pageWidth
        InteractiveTransition.getInstance().finishInteractiveAnimation(rate)
      }))
    .onDisAppear(() => {
      InteractiveTransition.getInstance().unregisterCallback(this.pageId)
    })
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
      if (context.navDestinationId) {
        this.pageId = context.navDestinationId
        this.registerCallback()
      }
    })
  }
}

// --- InteractivePageTwo.ets ---

@Component
export struct InteractivePageTwo {
  pageStack: NavPathStack = new NavPathStack()
  @State pageTwoTranslateX: string = '0'
  pageId: string = ''
  pageWidth: number = 0

  private registerCallback(): void {
    InteractiveTransition.getInstance().registerCallback(this.pageId, {
      start: (isPush: boolean, isExit: boolean): void => {
        this.pageTwoTranslateX = isPush ? '100%' : '0'
      },
      finish: (isPush: boolean, isExit: boolean): void => {
        this.pageTwoTranslateX = isPush ? '0' : '100%'
      },
      onFinish: (isPush: boolean, isExit: boolean): void => {
        this.pageTwoTranslateX = '0'
      },
      interactive: (operation: NavigationOperation): void => {
        if (operation == NavigationOperation.PUSH) {
          this.pageTwoTranslateX = '100%'
          this.getUIContext()?.animateTo({
            duration: 500,
            onFinish: () => {
              this.pageTwoTranslateX = '0'
            }
          }, () => {
            this.pageTwoTranslateX = '0'
          })
        } else {
          this.pageTwoTranslateX = '0'
          this.getUIContext()?.animateTo({
            duration: 500,
            onFinish: () => {
              this.pageTwoTranslateX = '0'
            }
          }, () => {
            this.pageTwoTranslateX = '100%'
          })
        }
      },
      timeout: 2000
    })
  }

  build() {
    NavDestination() {
      Column() {
        Button('Push PageOne')
          .width('80%')
          .height(40)
          .margin(20)
          .onClick(() => {
            this.pageStack.pushPath({ name: 'interactivePageOne' })
          })
      }
      .size({ width: '100%', height: '100%' })
    }
    .title('PageTwo')
    .translate({ x: this.pageTwoTranslateX })
    .backgroundColor(Color.Yellow)
    .gesture(PanGesture()
      .onActionStart((event: GestureEvent) => {
        this.pageWidth = event.target.area.width as number
        if (event.offsetX < 0) {
          this.pageStack.pushPath({ name: 'interactivePageOne' })
        } else {
          this.pageStack.pop()
        }
      })
      .onActionUpdate((event: GestureEvent) => {
        let rate = event.fingerList[0].localX / this.pageWidth
        InteractiveTransition.getInstance().updateProgress(rate)
      })
      .onActionEnd((event: GestureEvent) => {
        let rate: number = event.fingerList[0].localX / this.pageWidth
        InteractiveTransition.getInstance().finishInteractiveAnimation(rate)
      }))
    .onDisAppear(() => {
      InteractiveTransition.getInstance().unregisterCallback(this.pageId)
    })
    .onReady((context: NavDestinationContext) => {
      this.pageStack = context.pathStack
      if (context.navDestinationId) {
        this.pageId = context.navDestinationId
        this.registerCallback()
      }
    })
  }
}

// --- router_map.json (src/main/resources/base/profile/router_map.json) ---
//
// {
//   "routerMap": [
//     {
//       "name": "interactivePageOne",
//       "pageSourceFile": "src/main/ets/pages/InteractivePageOne.ets",
//       "buildFunction": "InteractivePageOneBuilder"
//     },
//     {
//       "name": "interactivePageTwo",
//       "pageSourceFile": "src/main/ets/pages/InteractivePageTwo.ets",
//       "buildFunction": "InteractivePageTwoBuilder"
//     }
//   ]
// }
//
// module.json5 中 module 字段需配置: "routerMap": "$profile:router_map"
//
// @Builder 工厂函数（写在各页面 .ets 文件顶部）:
//
//   // InteractivePageOne.ets
//   @Builder
//   export function InteractivePageOneBuilder(name: string, param: Object) {
//     InteractivePageOne()
//   }
//
//   // InteractivePageTwo.ets
//   @Builder
//   export function InteractivePageTwoBuilder(name: string, param: Object) {
//     InteractivePageTwo()
//   }
