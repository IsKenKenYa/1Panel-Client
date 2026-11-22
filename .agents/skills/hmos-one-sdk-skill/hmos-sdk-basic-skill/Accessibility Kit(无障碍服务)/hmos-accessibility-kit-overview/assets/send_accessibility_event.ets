/**
 * 发送无障碍事件示例
 * 本示例演示如何使用Accessibility Kit发送无障碍事件（主动聚焦、主动朗读）
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 发送无障碍事件
 * @param eventType 事件类型
 * @param componentId 组件ID
 */
async function sendAccessibilityEvent(
  eventType: string,
  componentId: string
): Promise<void> {
  try {
    const event: accessibility.EventInfo = {
      type: eventType,
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      componentId: componentId
    };
    
    await accessibility.sendEvent(event);
    console.info('无障碍事件已发送:', eventType);
  } catch (error) {
    const businessError = error as BusinessError;
    console.error('发送无障碍事件失败, 错误码:', businessError.code, '错误信息:', businessError.message);
  }
}

/**
 * 发送主动聚焦事件
 * @param componentId 组件ID
 */
async function sendAccessibilityFocusEvent(componentId: string): Promise<void> {
  await sendAccessibilityEvent('accessibilityFocus', componentId);
  console.info('已发送主动聚焦事件');
}

/**
 * 发送主动朗读事件
 * @param text 要朗读的文本
 */
async function announceForAccessibility(text: string): Promise<void> {
  try {
    await accessibility.announceForAccessibility(text);
    console.info('已发送主动朗读事件, 文本:', text);
  } catch (error) {
    const businessError = error as BusinessError;
    console.error('发送主动朗读失败, 错误码:', businessError.code, '错误信息:', businessError.message);
  }
}

/**
 * 主函数
 */
@Entry
@Component
struct SendAccessibilityEventExample {
  @State message: string = '点击按钮发送无障碍事件';
  
  build() {
    Column() {
      Button('发送主动聚焦事件')
        .onClick(() => {
          sendAccessibilityFocusEvent('button1');
        })
        .width('80%')
        .margin(10)
        .id('button1');
      
      Button('发送主动朗读事件')
        .onClick(() => {
          announceForAccessibility('这是一个主动朗读测试文本');
        })
        .width('80%')
        .margin(10)
        .id('button2');
      
      Text(this.message)
        .fontSize(14)
        .textAlign(TextAlign.Center)
        .accessibilityText('无障碍事件发送示例')
        .accessibilityDescription('点击按钮发送不同类型的无障碍事件');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}