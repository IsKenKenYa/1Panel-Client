import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 弹窗切换示例
 * 通过控制弹窗显示/隐藏实现页面切换效果
 * 并主动通知屏幕朗读服务页面变化
 */
@Entry
@Component
struct DialogChangeExample {
  @State showDialog: boolean = false;
  @State dialogContent: string = '弹窗内容';
  
  /**
   * 主页面
   */
  @Builder
  MainPage() {
    Column() {
      Text('主页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Text('主页面内容区域1')
        .margin({ bottom: 10 })
      
      Text('主页面内容区域2')
        .margin({ bottom: 10 })
      
      Button('打开弹窗')
        .width('60%')
        .height(50)
        .onClick(() => {
          this.showDialog = true;
          
          // 弹窗显示后，主动通知页面变化
          const eventInfo: accessibility.EventInfo = ({
            type: 'pageActive',
            bundleName: 'com.example.dialogapp',
            triggerAction: 'common',
            customId: 'dialog_root'
          });
          
          accessibility.sendAccessibilityEvent(eventInfo).then(() => {
            console.info('Dialog pageActive event sent successfully');
          }).catch((err: BusinessError) => {
            console.error(`Failed to send dialog event: ${err.message}`);
          });
        })
    }
    .id('main_page_root')
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .accessibilityLevel('no')
  }
  
  /**
   * 弹窗页面
   */
  @Builder
  DialogPage() {
    Column() {
      Text('弹窗标题')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })
      
      Text(this.dialogContent)
        .fontSize(16)
        .margin({ bottom: 10 })
      
      Text('弹窗测试节点1')
        .margin({ bottom: 10 })
      
      Text('弹窗测试节点2')
        .margin({ bottom: 15 })
      
      Button('关闭弹窗')
        .width('50%')
        .height(40)
        .onClick(() => {
          this.showDialog = false;
          
          // 弹窗关闭后，通知返回主页面
          const eventInfo: accessibility.EventInfo = ({
            type: 'pageActive',
            bundleName: 'com.example.dialogapp',
            triggerAction: 'common',
            customId: 'main_page_root'
          });
          
          accessibility.sendAccessibilityEvent(eventInfo).then(() => {
            console.info('Main pageActive event sent successfully');
          }).catch((err: BusinessError) => {
            console.error(`Failed to send main page event: ${err.message}`);
          });
        })
    }
    .id('dialog_root')  // 弹窗根节点ID
    .width('80%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 20, color: '#000000', offsetX: 0, offsetY: 5 })
    .accessibilityLevel('no')  // 弹窗可识别
  }
  
  build() {
    Stack() {
      // 主页面
      this.MainPage()
      
      // 弹窗层（通过visibility控制显示）
      if (this.showDialog) {
        Column() {
          this.DialogPage()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')  // 半透明背景
        .zIndex(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}