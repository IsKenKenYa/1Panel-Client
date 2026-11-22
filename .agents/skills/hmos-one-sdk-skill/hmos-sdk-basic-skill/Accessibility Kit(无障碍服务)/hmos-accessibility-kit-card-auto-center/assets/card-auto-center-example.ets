/**
 * 卡片自动居中完整示例
 * 功能：横向滚动容器中卡片无障碍聚焦时自动居中显示
 * Kit: Accessibility Kit
 */

import { IDataSource, DataChangeListener } from '@ohos.arkui';

/**
 * 数据源实现类
 * 实现IDataSource接口，用于LazyForEach懒加载
 */
class ListDataSource implements IDataSource {
  private list: number[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  /**
   * 获取数据总数
   */
  totalCount(): number {
    return Math.max(0, this.list.length);
  }
  
  /**
   * 根据索引获取数据
   * @param index 数据索引
   * @returns 数据项，异常时返回默认值0
   */
  getData(index: number): number {
    try {
      if (index < 0 || index >= this.list.length) {
        console.warn('getData: Invalid index ' + index + ', returning default value');
        return 0;
      }
      return this.list[index];
    } catch (error) {
      console.error('getData error:', error.message);
      return 0;
    }
  }
  
  /**
   * 注册数据变化监听器（可选实现）
   */
  registerDataChangeListener(listener: DataChangeListener): void {
    // 数据变化监听器注册逻辑
  }
  
  /**
   * 注销数据变化监听器（可选实现）
   */
  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 数据变化监听器注销逻辑
  }
}

/**
 * 卡片自动居中示例组件
 */
@Entry
@Component
struct CardAutoCenterExample {
  @State title: string = '卡片自动居中示例';
  
  // 初始化数据源（10个卡片）
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  
  // 初始化Scroller滚动控制器
  private scrollerForList: Scroller = new Scroller();
  
  build() {
    NavDestination() {
      Column() {
        // 横向滚动List容器
        List({ 
          space: 20,           // 卡片间距20vp
          initialIndex: 0,     // 初始索引0
          scroller: this.scrollerForList  // 绑定Scroller控制器
        }) {
          // 使用LazyForEach懒加载渲染卡片
          LazyForEach(this.arr, (index: number) => {
            ListItem() {
              // 卡片内容
              Text('' + index)
                .width('100%')
                .height(100)
                .fontSize(16)
                .textAlign(TextAlign.Center)
                .borderRadius(10)
                .backgroundColor(0xFFFFFF)
            }
            .width('60%') // 卡片宽度占比60%
            .onClick(() => {
              // 点击事件（使卡片可被无障碍聚焦）
              console.info('Card clicked: ' + index);
            })
            .onAccessibilityFocus((isFocus: boolean) => {
              // 无障碍聚焦回调
              if (isFocus) {
                // 卡片获得焦点时，自动滚动到居中位置
                this.scrollToCenter(index);
              } else {
                // 卡片失去焦点（可选处理）
                console.info('Card lost focus: ' + index);
              }
            })
          }, (item: string) => item.toString()) // 键值生成函数
        }
        .width('90%')
        .scrollBar(BarState.Off)                 // 隐藏滚动条
        .scrollSnapAlign(ScrollSnapAlign.CENTER) // 居中对齐（关键配置）
        .listDirection(Axis.Horizontal)          // 横向滚动（关键配置）
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xDCDCDC)
      .padding({ top: 5 })
    }
    .title(this.title)
  }
  
  /**
   * 滚动到指定卡片并居中显示
   * @param index 卡片索引
   */
  private scrollToCenter(index: number): void {
    try {
      // 参数校验
      if (index < 0 || index >= this.arr.totalCount()) {
        console.warn('scrollToCenter: Invalid index ' + index + ', scrollToIndex skipped');
        return;
      }
      
      // 执行滚动：使用scrollToIndex居中对齐
      // 参数说明：
      // - index: 目标卡片索引
      // - smooth: false（不使用平滑动画，避免性能问题）
      // - align: ScrollAlign.CENTER（居中对齐）
      this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER);
      
      console.info('Accessibility focus: Card ' + index + ' centered successfully');
      
    } catch (error) {
      // 错误码处理
      if (error.code === 100004) {
        console.error('Error 100004: Scroller not bound to component');
      } else if (error.code === 401) {
        console.error('Error 401: Parameter error - ' + error.message);
      } else {
        console.error('Unknown error:', error.message);
      }
    }
  }
}