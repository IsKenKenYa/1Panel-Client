// 以下示例展示 @Reusable 和 @ReusableV2 使用 ReusableOptions 配置内存优化策略：

// 示例1：@Reusable（V1）使用自动内存优化策略
// 点击 Recycle 按钮触发组件回收进入复用池
// 应用退后台时，复用池中的组件将被自动释放
@Reusable({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@Component
struct ReusableComponent {
  @State message: string = 'ReusableComponent';

  aboutToRecycle() {
    console.info('ReusableComponent aboutToRecycle');
  }

  aboutToReuse(params: Record<string, Object>): void {
    console.info('ReusableComponent aboutToReuse');
    if (params.message !== undefined) {
      this.message = params.message as string;
    }
  }

  aboutToAppear() {
    console.info('ReusableComponent aboutToAppear');
  }

  aboutToDisappear() {
    console.info('ReusableComponent aboutToDisappear');
  }

  build() {
    Text(this.message)
      .fontSize(16)
      .padding(10)
      .backgroundColor('#F1F3F5')
      .borderRadius(8)
  }
}

@Entry
@Component
struct ReusableMemoryOptimizeDemo {
  @State showComponent: boolean = true;
  @State reuseCount: number = 0;

  build() {
    Column({ space: 10 }) {
      Button('Recycle').onClick(() => {
        // 点击按钮触发组件回收，组件进入复用池
        this.showComponent = false;
      })
      Button('Show').onClick(() => {
        // 重新显示，优先从复用池复用
        this.showComponent = true;
        this.reuseCount++;
      })
      if (this.showComponent) {
        ReusableComponent({ message: `item ${this.reuseCount}` })
      }
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }
}

// 示例2：@ReusableV2（V2）使用自动内存优化策略
@ReusableV2({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@ComponentV2
struct ReusableV2Component {
  @Param item: string = '';

  aboutToReuse(): void {
    console.info('ReusableV2Component aboutToReuse');
  }

  aboutToAppear() {
    console.info('ReusableV2Component aboutToAppear');
  }

  aboutToDisappear() {
    console.info('ReusableV2Component aboutToDisappear');
  }

  build() {
    Text(this.item)
      .fontSize(16)
      .padding(10)
      .backgroundColor('#E8EAED')
      .borderRadius(8)
  }
}

@Entry
@ComponentV2
struct ReusableV2MemoryOptimizeDemo {
  @Local data: Array<string> = [];
  @Local toggle: boolean = true;

  aboutToAppear() {
    for (let i = 0; i < 50; i++) {
      this.data.push(`item ${i}`);
    }
  }

  build() {
    Column({ space: 10 }) {
      Button('Toggle Component').onClick(() => {
        // 切换显示/隐藏，隐藏时组件回收进入复用池
        // 退后台时复用池中的组件将被自动释放
        this.toggle = !this.toggle;
      })
      if (this.toggle) {
        ReusableV2Component({ item: this.data[0] })
      }
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }
}

// 示例3：@ReusableV2 配合 Repeat 使用（关闭 Repeat 自身复用，由 @ReusableV2 接管）
@ReusableV2({ memoryOptimizationStrategy: ReusableMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION })
@ComponentV2
struct ListItemComponent {
  @Param item: string = '';

  aboutToReuse(): void {
    console.info('ListItemComponent aboutToReuse');
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
struct ReusableV2WithRepeatDemo {
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
              ListItemComponent({ item: repeatItem.item })
            }
          })
          .virtualScroll({
            // 关闭 Repeat 自身复用，由 @ReusableV2 的复用池接管
            reusable: false
          })
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}
