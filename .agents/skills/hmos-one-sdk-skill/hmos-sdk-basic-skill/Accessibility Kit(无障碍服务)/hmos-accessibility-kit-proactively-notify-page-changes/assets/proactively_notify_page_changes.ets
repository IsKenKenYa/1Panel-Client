import { accessibility } from '@kit.AccessibilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * 主动通知页面变化示例
 * 功能：通过改变Stack子组件Z序实现页面切换，并发送无障碍事件通知屏幕朗读聚焦
 * 适用场景：自定义页面堆叠覆盖、Z序切换导致的焦点丢失
 */

@Entry
@Component
export struct ProactivelyNotifyPageChanges {
  // 定义状态变量，控制顶层显示的页面索引
  @State topLayer: number = 0;
  
  /**
   * 自定义页面Builder
   * @param text 页面标题文本
   * @param index 页面索引，用于标识和Z序控制
   */
  @Builder
  Layer(text: string, index: number) {
    Column() {
      Column() {
        // 页面标题
        Text(text)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        // 页面内容节点（屏幕朗读可识别）
        Text(`${text} 测试节点1`)
        Text(`${text} 测试节点2`)
        Text(`${text} 测试节点3`)
        
        // 页面切换按钮
        Button(`页面切换${index}`)
          .onClick(() => {
            // 执行页面切换逻辑：在0与1之间切换
            if (this.topLayer === 0) {
              this.topLayer = 1;
            } else {
              this.topLayer = 0;
            }
            
            // 构造无障碍事件信息
            const eventInfo: accessibility.EventInfo = {
              type: 'pageActive',              // 事件类型：页面激活
              bundleName: 'com.samples.uiextensionandaccessibility',  // 应用包名
              triggerAction: 'common',         // 触发动作：通用动作
              customId: `Layer_${this.topLayer}`  // 自定义页面根节点ID
            };
            
            // 发送主动通知页面变化的事件（Promise模式）
            accessibility.sendAccessibilityEvent(eventInfo).then(() => {
              console.info(`pageActive event send Successed, customId=Layer_${this.topLayer}.`);
            }).catch((err: BusinessError) => {
              // 错误处理：记录失败信息但不影响页面切换功能
              console.error(`Failed to send pageActive event, Code: ${err.code}, Message: ${err.message}`);
              
              // 根据错误码进行针对性处理
              switch (err.code) {
                case 401:
                  console.error('Parameter error. Please check EventInfo parameters.');
                  break;
                case 9300003:
                  console.error('No accessibility permission to perform the operation.');
                  break;
                case 9300004:
                  console.error('Property does not exist. Check customId validity.');
                  break;
                case 9300006:
                  console.error('Connection failed. Try again later.');
                  break;
                default:
                  console.error('Unknown error occurred.');
              }
            });
          })
      }
      // 设置组件id，用于标识页面根节点（与customId对应）
      .id('Layer_' + index)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(index === 0 ? Color.Red : Color.Green)  // 不同页面使用不同背景色
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(16)
    .padding(20)
    // 控制页面Z序：顶层页面zIndex=1，其他页面zIndex=0
    .zIndex(this.topLayer === index ? 1 : 0)
    // 根据是否为顶层页面设置无障碍可见性
    // 顶层：'no'（可识别但子节点不自动隐藏）
    // 非顶层：'no-hide-descendants'（隐藏所有子节点）
    .accessibilityLevel(this.topLayer === index ? 'no' : 'no-hide-descendants')
  }
  
  build() {
    NavDestination() {
      Column() {
        Stack() {
          // 堆叠两个页面组件
          this.Layer('页面0', 0)
          this.Layer('页面1', 1)
        }
      }
    }
  }
}

/**
 * 使用说明：
 * 1. 页面切换原理：通过改变Stack子组件的zIndex值实现页面切换效果
 * 2. 无障碍优化：
 *    - 使用accessibilityLevel控制非顶层页面的可见性
 *    - 通过id属性标识页面根节点
 *    - 切换后发送pageActive事件通知屏幕朗读
 * 3. customId参数：
 *    - 必须与目标组件的id属性值一致
 *    - 用于屏幕朗读精准定位到新页面的根节点
 *    - 若不指定customId，屏幕朗读将从窗口根节点开始寻找焦点
 * 4. 错误处理：
 *    - 使用Promise.catch捕获错误
 *    - 根据错误码进行针对性处理
 *    - 即使发送失败也不影响页面切换功能
 */