/**
 * 页面示例：触发地址越界错误
 * 用于演示如何通过按钮触发Native层的地址越界错误
 */

import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        // 触发地址越界错误的按钮
        Button("Trigger Address Sanitizer")
          .width('80%')
          .height(50)
          .onClick(() => {
            // 调用Native接口触发数组越界写入
            testNapi.test();
          })
        
        // 提示信息
        Text("Click button to trigger address sanitizer error")
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 20 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
    }
    .height('100%')
  }
}