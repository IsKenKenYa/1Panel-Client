// ArkWeb页面组件 - 完整示例
// 文件路径：entry/src/main/ets/pages/ArkWebPage.ets

import web_webview from '@ohos.web.webview';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 用于存储web_id到url的映射
export const webIdToUrlMap = new Map<number, string>();

@Entry
@Component
struct ArkWebPage {
  controller = new web_webview.WebviewController();
  @State pageTitle: string = 'Web Demo';

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.pageTitle)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F1F3F5')

      // Web组件
      Web({ src: 'https://www.baidu.com', controller: this.controller })
        .width('100%')
        .height('100%')
        .onPageBegin((event) => {
          // 每次跳转到新页面都更新webId到url的映射关系，便于后续通过系统侧提供的web_id查询到发生丢帧的网页
          if (event) {
            const newUrl = event.url;
            const webId = this.controller.getWebId();
            webIdToUrlMap.set(webId, newUrl);
            hilog.info(0x0000, 'WebTag', `Web page begin: webId=${webId}, url=${newUrl}`);
          }
        })
        .onPageEnd((event) => {
          if (event) {
            hilog.info(0x0000, 'WebTag', `Web page end: url=${event.url}`);
          }
          
          // 演示：每2s阻塞应用主线程200ms，用于触发丢帧事件（仅用于测试）
          // 在实际应用中不应阻塞主线程
          setInterval(() => {
            const endTime = Date.now() + 200;
            while (Date.now() < endTime) {
              // 模拟耗时任务
            }
          }, 2000);
        })
        .onErrorReceive((event) => {
          if (event) {
            hilog.error(0x0000, 'WebTag', `Web error: ${event.error.getErrorInfo()}`);
          }
        })
        .javaScriptAccess(true)
        .domStorageAccess(true)
    }
    .width('100%')
    .height('100%')
  }
}