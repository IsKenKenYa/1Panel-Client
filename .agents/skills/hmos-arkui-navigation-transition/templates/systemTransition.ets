// systemTransition 系统转场动画配置模板
// 归属组件：NavDestination
// API: systemTransition(type: NavigationSystemTransitionType)
// @since: 14 (DEFAULT/NONE/TITLE/CONTENT), 15 (FADE/EXPLODE/SLIDE_RIGHT/SLIDE_BOTTOM)
// 来源: interface_sdk-js/api/@internal/component/ets/nav_destination.d.ts:1145

// NavigationSystemTransitionType 枚举值：
// DEFAULT = 0       — 默认系统转场动画（@since 14）
// NONE = 1          — 无系统转场动画（@since 14）
// TITLE = 2         — 标题栏系统转场动画（@since 14）
// CONTENT = 3       — 内容区系统转场动画（@since 14）
// FADE = 4          — 渐变类型（@since 15）
// EXPLODE = 5       — 中心缩放类型（@since 15）
// SLIDE_RIGHT = 6   — 右侧平移类型（@since 15）
// SLIDE_BOTTOM = 7  — 底部平移类型（@since 15）

@Entry
@Component
struct SystemTransitionPage {
  @State pageStack: NavPathStack = new NavPathStack()

  build() {
    Navigation(this.pageStack) {
      // 导航首页内容
    }
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: unknown): void {
    if (name === 'DetailPage') {
      DetailPage()
    }
  }
}

@Component
struct DetailPage {
  build() {
    NavDestination() {
      Column() {
        Text('Detail Page with System Transition')
          .fontSize(20)
          .margin(20)
      }
      .width('100%')
      .height('100%')
    }
    // 系统转场动画配置 — 在 NavDestination 组件声明上链式调用
    // 根据需求选择枚举值，以下为常用示例：
    .systemTransition(NavigationSystemTransitionType.FADE)       // 渐变转场
    // .systemTransition(NavigationSystemTransitionType.EXPLODE)   // 中心缩放转场
    // .systemTransition(NavigationSystemTransitionType.SLIDE_RIGHT) // 右侧平移转场
    // .systemTransition(NavigationSystemTransitionType.SLIDE_BOTTOM) // 底部平移转场
    // .systemTransition(NavigationSystemTransitionType.DEFAULT)   // 默认转场（默认值）
    // .systemTransition(NavigationSystemTransitionType.NONE)      // 无转场
    // .systemTransition(NavigationSystemTransitionType.TITLE)     // 仅标题栏转场
    // .systemTransition(NavigationSystemTransitionType.CONTENT)   // 仅内容区转场
    .title('Detail')
  }
}
