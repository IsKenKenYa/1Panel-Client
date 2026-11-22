// 以下示例展示 LazyForEach 使用 LazyForEachOptions 配置内存优化策略：

// BasicDataSource 基础数据源实现（参考 LazyForEach 开发者指南）
export class BasicDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: string[] = [];

  public totalCount(): number {
    return this.originDataArray.length;
  }

  public getData(index: number): string {
    return this.originDataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataReloaded();
    });
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataDelete(index);
    });
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataChange(index);
    });
  }
}

class DataSource extends BasicDataSource {
  public dataArray: string[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): string {
    return this.dataArray[index];
  }

  public pushData(data: string): void {
    this.dataArray.push(data);
    this.notifyDataAdd(this.dataArray.length - 1);
  }
}

// 子组件：展示 aboutToAppear / aboutToDisappear 生命周期回调
// 节点释放和恢复时会触发这些回调
@Component
struct ChildComponent {
  @Prop item: string = '';

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
// 退后台/低内存时自动释放预加载节点，回前台/滑动时自动恢复
@Entry
@Component
struct MemoryOptimizeDemo {
  private data: DataSource = new DataSource();

  aboutToAppear() {
    for (let i = 0; i < 100; i++) {
      this.data.pushData(`item ${i}`);
    }
  }

  build() {
    Column() {
      List() {
        LazyForEach(this.data,
          (item: string, index: number) => {
            ListItem() {
              ChildComponent({ item: item })
            }
          },
          (item: string, index: number) => item,
          // 使用自动内存优化策略
          { memoryOptimizationStrategy: LazyForEachMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION }
        )
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}

// 示例2：组合配置内存优化策略 + 资源释放策略 + 自定义组件冻结
@Entry
@Component
struct CombinedOptimizeDemo {
  private data: DataSource = new DataSource();

  aboutToAppear() {
    for (let i = 0; i < 500; i++) {
      this.data.pushData(`item ${i}`);
    }
  }

  build() {
    Column() {
      List() {
        LazyForEach(this.data,
          (item: string, index: number) => {
            ListItem() {
              ChildComponent({ item: item })
            }
          },
          // 使用 LazyForEachOptions 时必须设置 keyGenerator，否则编译失败
          (item: string, index: number) => item,
          {
            // 启用自动内存优化策略：退后台/低内存时释放预加载节点
            memoryOptimizationStrategy: LazyForEachMemOptStrategy.ENABLE_AUTO_CACHE_OPTIMIZATION,
            // 使用渐进式释放策略：避免大量节点释放导致超大帧
            releaseStrategy: LazyForEachReleaseStrategy.PROGRESSIVE,
            // 使能自定义组件冻结：不可见时暂停状态变量更新
            customComponentFreezeMode: LazyForEachCustomComponentFreezeMode.ENABLED
          }
        )
      }
      .cachedCount(2)
      .width('100%')
      .height('100%')
    }
  }
}
