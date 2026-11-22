/**
 * Index.ets - HiCollie定时器检测UI示例
 * 提供按钮触发Native测试函数
 */

import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  @State message: string = 'HiCollie Timer Test';
  @State testResult: string = '';

  build() {
    Column() {
      // 标题
      Text(this.message)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 });

      // 测试结果显示
      if (this.testResult) {
        Text(this.testResult)
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 20 });
      }

      // 测试按钮区域
      Column({ space: 15 }) {
        // 基本超时触发
        Button("Test Timeout (2s > 1s)")
          .width('80%')
          .height(50)
          .fontSize(18)
          .onClick(() => {
            this.testResult = 'Testing timeout scenario...';
            testNapi.TestHiCollieTimerNdk();
            setTimeout(() => {
              this.testResult = 'Timeout test completed. Check logs.';
            }, 3000);
          });

        // 正常执行
        Button("Test Normal (1s < 2s)")
          .width('80%')
          .height(50)
          .fontSize(18)
          .onClick(() => {
            this.testResult = 'Testing normal execution...';
            testNapi.TestNormalExecution();
            setTimeout(() => {
              this.testResult = 'Normal execution completed.';
            }, 2000);
          });

        // 带回调测试
        Button("Test With Callback")
          .width('80%')
          .height(50)
          .fontSize(18)
          .onClick(() => {
            this.testResult = 'Testing with callback...';
            testNapi.TestHiCollieWithCallback();
            setTimeout(() => {
              this.testResult = 'Callback test completed. Check logs.';
            }, 3000);
          });

        // 错误场景测试
        Button("Test Error Cases")
          .width('80%')
          .height(50)
          .fontSize(18)
          .onClick(() => {
            this.testResult = 'Testing error scenarios...';
            testNapi.TestErrorCases();
            setTimeout(() => {
              this.testResult = 'Error test completed. Check logs.';
            }, 1000);
          });

        // 连续多次测试
        Button("Test Multiple Timeout")
          .width('80%')
          .height(50)
          .fontSize(18)
          .onClick(() => {
            this.testResult = 'Testing multiple timeouts...';
            testNapi.TestMultipleTimeouts();
            setTimeout(() => {
              this.testResult = 'Multiple test completed. 2 timeout events expected.';
            }, 6000);
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.Center);

      // 说明文本
      Text('Click buttons to trigger HiCollie timer tests.\nCheck hilog for APP_HICOLLIE events.')
        .fontSize(14)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .margin({ top: 30, bottom: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start);
  }
}