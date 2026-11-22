// 以下示例展示 Navigation 使用 configuration 配置路由栈限制和低内存回收：

@Component
struct MyControlPanel {
  private stack: NavPathStack | undefined = undefined;

  aboutToAppear(): void {
    let info = this.queryNavigationInfo();
    if (info) {
      this.stack = info.pathStack;
    }
  }

  build() {
    Column() {
      Button('push pageOne').onClick(() => {
        this.stack?.pushPath({ name: 'one' })
      }).margin({ top: 25 })
      Button('push pageTwo').onClick(() => {
        this.stack?.pushPath({ name: 'two' })
      }).margin({ top: 25 })
      Button('pop').onClick(() => {
        this.stack?.pop()
      }).margin({ top: 25 })
    }
  }
}

@Component
struct MyPageOne {
  aboutToAppear() {
    console.info('MyPageOne aboutToAppear');
  }
  aboutToDisappear() {
    console.info('MyPageOne aboutToDisappear');
  }

  build() {
    NavDestination() {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('PageOne')
  }
}

@Component
struct MyPageTwo {
  aboutToAppear() {
    console.info('MyPageTwo aboutToAppear');
  }
  aboutToDisappear() {
    console.info('MyPageTwo aboutToDisappear');
  }

  build() {
    NavDestination() {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('PageTwo')
  }
}

// 示例1：组合配置路由栈限制与低内存回收
@Entry
@Component
struct NavigationMemoryOptimizeDemo {
  private stack: NavPathStack = new NavPathStack();

  @Builder
  MyDestMap(name: string) {
    if (name === 'one') {
      MyPageOne()
    } else {
      MyPageTwo()
    }
  }

  build() {
    Navigation(this.stack) {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('NavBar')
    .navDestination(this.MyDestMap)
    .configuration({
      // 限制活跃页面节点数量为5，超过后自动销毁最早入栈的页面实例
      stackSizeLimit: 5,
      // 低内存时自动回收不可见的 NavDestination 页面实例，NavPathInfo 保留
      recyclePagesOnLowMemory: true
    })
  }
}

// 示例2：仅配置低内存回收（不限制路由栈大小）
@Entry
@Component
struct NavigationLowMemoryOnlyDemo {
  private stack: NavPathStack = new NavPathStack();

  @Builder
  MyDestMap(name: string) {
    if (name === 'one') {
      MyPageOne()
    } else {
      MyPageTwo()
    }
  }

  build() {
    Navigation(this.stack) {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('NavBar')
    .navDestination(this.MyDestMap)
    .configuration({
      // 不限制路由栈大小，仅低内存时回收
      recyclePagesOnLowMemory: true
    })
  }
}

// 示例3：开启左起右清栈（Split 模式专用）
@Entry
@Component
struct NavigationClearStackDemo {
  private stack: NavPathStack = new NavPathStack();

  @Builder
  MyDestMap(name: string) {
    if (name === 'one') {
      MyPageOne()
    } else {
      MyPageTwo()
    }
  }

  build() {
    Navigation(this.stack) {
      Column() {
        MyControlPanel()
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .title('NavBar')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Split)
    .navDestination(this.MyDestMap)
    .configuration({
      // 开启左起右清栈：主页侧导航时自动清理旧页面栈
      clearContentStackOnPrimaryNavigation: true
    })
  }
}
