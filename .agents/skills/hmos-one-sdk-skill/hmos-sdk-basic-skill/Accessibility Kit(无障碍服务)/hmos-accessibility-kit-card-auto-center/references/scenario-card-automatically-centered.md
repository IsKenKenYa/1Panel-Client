# 卡片自动居中的场景
---
# 卡片自动居中的场景
#### 设计场景
在横向滚动容器中，通过居中限位来突出中心卡片的详细信息和操作选项。为了确保屏幕朗读场景下聚焦卡片的可访问性，需要将获得焦点的卡片自动居中显示，以凸显其重要性。为此，需要应用通过 [ForEach](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/状态管理与渲染控制/ts-rendering-control-foreach.md) 或 [LazyForEach](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/状态管理与渲染控制/ts-rendering-control-lazyforeach.md) 获取卡片索引，在可聚焦的卡片控件上注册无障碍聚焦回调函数 [onAccessibilityFocus](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/通用事件/无障碍相关/ts-universal-accessibility-event.md) ，在回调函数中调用滚动容器的 [scrollToIndex](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-scroll-V5#scrolltoindex) 接口并指定卡片索引，将聚焦的卡片控件居中显示。
#### 开发实例
如下示例实现一个横向滚动容器，卡片被聚焦时自动居中显示：
```
class ListDataSource implements IDataSource {
  private list: number[] = [];
  constructor(list: number[]) {
    this.list = list;
  }
  totalCount(): number {
    return this.list.length;
  }
  getData(index: number): number {
    return this.list[index];
  }
  registerDataChangeListener(listener: DataChangeListener): void {
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
  }
}
@Entry
@Component
export struct Rule_2_1_18 {
  title: string = 'Rule 2.1.18';
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  private scrollerForList: Scroller = new Scroller();
  build() {
    NavDestination() {
      Column() {
        List({ space: 20, initialIndex: 0, scroller: this.scrollerForList }) {
          LazyForEach(this.arr, (index: number) => {
            ListItem() {
              Text('' + index)
                .width('100%')
                .height(100)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
            }
            .width('60%') // 设置高占比item。
            .onClick( () => {
              // 设置点击事件，使组件可被无障碍聚焦。
            })
            // 设置无障碍聚焦回调。
            .onAccessibilityFocus((isFocus: boolean) => {
              if (isFocus) {
                // 如果聚焦则滚动List，使当前的ListItem居中。
                this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER)
              }
            })
          }, (item: string) => item)
        }
        .width('90%')
        .scrollBar(BarState.Off)
        .scrollSnapAlign(ScrollSnapAlign.CENTER) // 设置居中对齐。
        .listDirection(Axis.Horizontal) // 设置横向list。
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xDCDCDC)
      .padding({ top: 5 })
    }
    .title(this.title)
  }
}
```