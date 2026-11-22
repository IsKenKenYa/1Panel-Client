// disableAnimation 禁用转场动画配置模板
// 
// 单页禁用（AC-5.1）: NavDestination 上设置 .systemTransition(NavigationSystemTransitionType.NONE)
//   API: systemTransition(type: NavigationSystemTransitionType)
//   @since: 14  来源: nav_destination.d.ts:1145
//   作用域: 仅禁用该 NavDestination 页面的系统转场
//
// 全局禁用（AC-5.2）: NavPathStack.disableAnimation(value: boolean)
//   API: disableAnimation(value: boolean)
//   @since: 11  来源: navigation.d.ts:1280
//   作用域: NavPathStack 级别，影响该 NavPathStack 关联的 Navigation 中所有页面跳转
//
// 单次禁用替代方案: 在 pushPath/pop 等方法中传 animated: false 参数

// ============================================================
// 单页禁用 — NavDestination 级别禁用系统转场（AC-5.1）
// 实现：在 NavDestination 上链式调用 .systemTransition(NavigationSystemTransitionType.NONE)
// ============================================================

@Component
struct QuietDetailPage {
  build() {
    NavDestination() {
      Column() {
        Text('Quiet Detail Page (no system transition)')
          .fontSize(20)
          .margin(20)
      }
      .width('100%')
      .height('100%')
    }
    // 单页禁用 — 设置系统转场类型为 NONE，仅禁用该页面的系统转场
    // 不影响其他页面的转场动画
    .systemTransition(NavigationSystemTransitionType.NONE)
    .title('Quiet Detail')
  }
}

// ============================================================
// 全局禁用 — Navigation 级别禁用所有转场动画（AC-5.2）
// 实现：NavPathStack.disableAnimation(true)
// ============================================================

@Entry
@Component
struct GlobalDisableAnimationPage {
  @State pageStack: NavPathStack = new NavPathStack()
  @State isAnimationDisabled: boolean = false

  build() {
    Navigation(this.pageStack) {
      Column() {
        Button('Push Detail Page (animated)')
          .onClick(() => {
            this.pageStack.pushPath({ name: 'DetailPage' })
          })
          .margin(10)

        Button('Push Detail Page (no animation)')
          .onClick(() => {
            // 单次禁用 — 传 animated: false 参数
            this.pageStack.pushPath({ name: 'DetailPage' }, false)
          })
          .margin(10)

        Button(this.isAnimationDisabled ? 'Enable Animation' : 'Disable Animation')
          .onClick(() => {
            this.isAnimationDisabled = !this.isAnimationDisabled
            // 全局禁用/启用 — 影响 NavPathStack 中所有跳转
            this.pageStack.disableAnimation(this.isAnimationDisabled)
          })
          .margin(10)
      }
    }
    .navDestination(this.navDestinationBuilder)
  }

  @Builder
  navDestinationBuilder(name: string, param: unknown): void {
    if (name === 'DetailPage') {
      DetailPage()
    } else if (name === 'QuietDetailPage') {
      QuietDetailPage()
    }
  }
}

@Component
struct DetailPage {
  build() {
    NavDestination() {
      Column() {
        Text('Detail Page')
          .fontSize(20)
          .margin(20)
      }
      .width('100%')
      .height('100%')
    }
    .title('Detail')
  }
}
