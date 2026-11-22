import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 堆叠页面切换示例
 * 通过改变 Stack 子组件 Z序的方式实现切换页面的效果
 * 并主动通知屏幕朗读服务页面变化，防止焦点丢失
 */
@Entry
@Component
struct StackPageChangeExample {
  title: string = '主动通知页面变化示例';
  
  // 定义状态变量，用于控制顶层显示的层数
  @State topLayer: number = 0;
  
  // 定义自定义页面
  @Builder
  Layer(text: string, index: number) {
    Column() {
      Column() {
        Text(text)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Text(`${text} 测试节点1`)
          .margin({ bottom: 10 })
        
        Text(`${text} 测试节点2`)
          .margin({ bottom: 10 })
        
        Text(`${text} 测试节点3`)
          .margin({ bottom: 10 })
        
        // 创建按钮用于切换页面
        Button(`页面切换${index}`)
          .width('80%')
          .height(50)
          .onClick(() => {
            // 判断当前顶层，在0与1之间切换
            if (this.topLayer === 0) {
              this.topLayer = 1;
            } else {
              this.topLayer = 0;
            }
            
            // 定义事件信息描述，事件类型为pageActive，页面根节点id为`Layer_${this.topLayer}`
            const eventInfo: accessibility.EventInfo = ({
              type: 'pageActive',
              bundleName: 'com.samples.uiextensionandaccessibility',
              triggerAction: 'common',
              customId: `Layer_${this.topLayer}`
            });
            
            // 发送主动通知页面变化的事件
            accessibility.sendAccessibilityEvent(eventInfo).then(() => {
              console.info(`pageActive event send succeeded, customId=Layer_${this.topLayer}`);
            }).catch((err: BusinessError) => {
              console.error(`failed to send pageActive event, code=${err.code}, message=${err.message}`);
            });
          })
      }
      // 指定自定义节点id，用于标识页面根节点
      .id('Layer_' + index)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(index === 0 ? Color.Red : Color.Green)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(16)
    .padding(20)
    // 修改页面Z序，用于实现页面切换效果
    .zIndex(this.topLayer === index ? 1 : 0)
    // 根据当前页面是否顶层显示，指定自定义页面节点是否无障碍可识别
    // 若是顶层，则设置为'no'（可识别），否则设置为'no-hide-descendants'（隐藏子节点）
    .accessibilityLevel(this.topLayer === index ? 'no' : 'no-hide-descendants')
  }
  
  build() {
    NavDestination() {
      Column() {
        Stack() {
          this.Layer('页面0', 0)
          this.Layer('页面1', 1)
        }
      }
    }
    .title(this.title)
  }
}