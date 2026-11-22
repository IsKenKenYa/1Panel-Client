// 以下示例展示 Repeat 使用 VirtualScrollOptions 配置内存优化策略：

// 子组件：展示 aboutToAppear / aboutToDisappear 生命周期回调
// 节点释放和恢复时会触发这些回调
@ComponentV2
struct ChildComponent {
  @Param item: string = '';

  aboutToAppear() {
    console.info('ChildComponent aboutToAppear, item = ' + this.item);
  }

  aboutToDisappear() {
    console.info('ChildComponent aboutToDisappear, item = ' + this.item);
  }

  build() {
    Column() {
      Text(this.item)
        .fontSize(16)
        .margin(10)
    }
    .width('100%')
    .height(60)
    .backgroundColor('#F1F3F5')
    .borderRadius(8)
  }
}

// 示例1：仅启用自动内存优化策略
// 前提：使用 Repeat 自身复用能力（reusable 默认为 true，未显式关闭）
// 退后台/低内存/组件不可见时自动释放缓存池节点，回前台/恢复显示时自动恢复
// 注意：释放的是 Repeat 缓存池中的节点，与 LazyForEach 释放预加载区域节点不同
@Entry
@ComponentV2
struct RepeatMemoryOptimizeDemo {
  @Local data: Array<string> = [];
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    for (let i = 0; i < 100; i++) {
      this.data.push(`item ${i}`);
    }
  }

  build() {
    Column() {
      Button('Scroll').onClick(() => {
        // 点击按钮触发列表跳转，旧组件进入缓存池
        this.scroller.scrollToIndex(30);
      })
      List({ scroller: this.scroller }) {
        Repeat<string>(this.data)
          .each((repeatItem: RepeatItem<string>) => {
            ListItem() {
              ChildComponent({ item: repeatItem.item })
            }
          })
          // 使用自动内存优化策略
          .virtualScroll({
            memoryOptimizationStrategy: RepeatMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION
          })
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}

// 示例2：组合配置内存优化策略 + 复用功能 + template 缓存池
// 注意：reusable: true 是内存优化策略生效的前提，不可设置为 false
@Entry
@ComponentV2
struct RepeatCombinedOptimizeDemo {
  @Local data: Array<string> = [];

  aboutToAppear() {
    for (let i = 0; i < 500; i++) {
      this.data.push(`item ${i}`);
    }
  }

  build() {
    Column() {
      List() {
        Repeat<string>(this.data)
          // each 属性必须有，否则运行时报错
          .each((repeatItem: RepeatItem<string>) => {})
          .virtualScroll({
            // 启用自动内存优化策略：退后台/低内存时释放缓存池节点
            memoryOptimizationStrategy: RepeatMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION,
            // 开启复用功能
            reusable: true,
            // 数据项总数
            totalCount: this.data.length
          })
          // 创建模板，设置缓存池大小为 2
          .template('temp', (repeatItem: RepeatItem<string>) => {
            ListItem() {
              ChildComponent({ item: repeatItem.item })
            }
          }, { cachedCount: 2 })
          // 所有数据项都使用 temp 模板
          .templateId((item: string, index: number) => { return 'temp' })
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}

// 示例3：配合 @ReusableV2 使用时关闭 Repeat 自身复用
// 注意：reusable: false 时节点不进入 Repeat 缓存池，
// Repeat 的 memoryOptimizationStrategy 不生效（没有可释放的对象）。
// 此场景下如需内存优化，必须改用 @ReusableV2 的 ReusableOptions 配置其自身的内存优化策略（见示例4）。
@ComponentV2
@ReusableV2
struct ReusableChildComponent {
  @Param item: string = '';

  aboutToReuse(): void {
    console.info('ReusableChildComponent aboutToReuse');
  }

  build() {
    Text(this.item)
      .fontSize(16)
      .margin(10)
      .width('100%')
      .height(60)
  }
}

@Entry
@ComponentV2
struct RepeatWithReusableV2Demo {
  @Local data: Array<string> = [];

  aboutToAppear() {
    for (let i = 0; i < 500; i++) {
      this.data.push(`item ${i}`);
    }
  }

  build() {
    Column() {
      List() {
        Repeat<string>(this.data)
          .each((repeatItem: RepeatItem<string>) => {
            ListItem() {
              ReusableChildComponent({ item: repeatItem.item })
            }
          })
          .virtualScroll({
            // 关闭 Repeat 自身复用，由 @ReusableV2 接管复用
            // 注意：此配置下 Repeat 的 memoryOptimizationStrategy 不生效，勿在此配置
            reusable: false
          })
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}

// 示例4：@ReusableV2 接管复用时，通过 ReusableOptions 启用可复用组件自身的内存优化策略
// 退后台/低内存/组件不可见时释放的是 @ReusableV2 复用池中的组件，
// 与 Repeat 缓存池释放（示例1、2）、LazyForEach 预加载区域释放的作用对象均不同。
@ComponentV2
@ReusableV2({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
struct ReusableMemOptChildComponent {
  @Param item: string = '';

  aboutToReuse(): void {
    console.info('ReusableMemOptChildComponent aboutToReuse');
  }

  build() {
    Text(this.item)
      .fontSize(16)
      .margin(10)
      .width('100%')
      .height(60)
  }
}

@Entry
@ComponentV2
struct RepeatWithReusableV2MemOptDemo {
  @Local data: Array<string> = [];

  aboutToAppear() {
    for (let i = 0; i < 500; i++) {
      this.data.push(`item ${i}`);
    }
  }

  build() {
    Column() {
      List() {
        Repeat<string>(this.data)
          .each((repeatItem: RepeatItem<string>) => {
            ListItem() {
              ReusableMemOptChildComponent({ item: repeatItem.item })
            }
          })
          .virtualScroll({
            // 关闭 Repeat 自身复用，由 @ReusableV2 接管复用
            reusable: false
            // 内存优化改由 ReusableMemOptChildComponent 上的 @ReusableV2({ memoryOptimizationStrategy: ... }) 承担
          })
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}
