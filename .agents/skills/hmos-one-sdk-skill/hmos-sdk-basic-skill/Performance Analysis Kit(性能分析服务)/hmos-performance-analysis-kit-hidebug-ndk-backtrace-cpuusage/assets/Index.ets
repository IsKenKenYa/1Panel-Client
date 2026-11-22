import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  @State message: string = 'HiDebug NDK Example';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 });

        Button('Test Stack Backtrace')
          .fontSize(16)
          .width('80%')
          .height(50)
          .margin({ top: 30 })
          .onClick(() => {
            this.testBackTrace();
          });

        Button('Test Thread CPU Usage')
          .fontSize(16)
          .width('80%')
          .height(50)
          .margin({ top: 20 })
          .onClick(() => {
            testNapi.testGetThreadCpuUsage();
          });
      }
      .width('100%')
    }
    .height('100%');
  }

  function testBackTraceJsFrame(i: number): void {
    if (i > 0) {
      testBackTraceJsFrame(i - 1);
      return;
    }
    testNapi.testBackTrace();
  }

  function testBackTrace(): void {
    testBackTraceJsFrame(3);
  }
}