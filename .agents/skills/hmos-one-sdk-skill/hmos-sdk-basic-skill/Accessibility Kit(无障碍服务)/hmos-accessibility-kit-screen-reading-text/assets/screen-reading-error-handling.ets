/**
 * 错误处理示例：处理无障碍文本设置过程中的错误
 * 本示例演示常见错误场景及其处理方法
 */

import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ScreenReadingErrorHandlingExample {
  @State accessibilityText: string = '';
  @State errorMessage: string = '';
  
  build() {
    Column({ space: 20 }) {
      Text('错误处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      // 显示错误信息
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin({ bottom: 10 })
      }
      
      // 示例1：文本长度校验
      Button('设置过长文本')
        .onClick(() => {
          try {
            const longText = '这是一个非常长的无障碍文本内容，超过了推荐的50个字符长度，可能会影响用户的朗读体验和操作效率';
            if (longText.length > 50) {
              console.warn('警告：无障碍文本过长（长度: ' + longText.length + '），建议不超过50个字符');
              this.errorMessage = '文本过长警告';
            }
            this.accessibilityText = longText;
          } catch (error) {
            const businessError: BusinessError = error as BusinessError;
            console.error(`设置失败: ${businessError.message}`);
            this.errorMessage = `错误: ${businessError.message}`;
          }
        })
      
      // 示例2：空字符串处理
      Button('设置空文本')
        .onClick(() => {
          try {
            this.accessibilityText = '';
            if (this.accessibilityText === '') {
              console.warn('警告：设置了空字符串，屏幕朗读可能无法播报');
              this.errorMessage = '空文本警告';
            }
          } catch (error) {
            const businessError: BusinessError = error as BusinessError;
            console.error(`设置失败: ${businessError.message}`);
            this.errorMessage = `错误: ${businessError.message}`;
          }
        })
      
      // 示例3：Resource引用错误处理
      Button('错误Resource引用')
        .accessibilityText($r('app.string.non_existent_resource'))
        .onClick(() => {
          try {
            // Resource引用可能失败的情况
            console.info('尝试引用不存在的资源');
          } catch (error) {
            const businessError: BusinessError = error as BusinessError;
            if (businessError.code === 100001) {
              console.error('Resource引用失败，请检查资源文件');
              this.errorMessage = '资源引用错误';
            }
          }
        })
      
      // 示例4：组件不支持错误
      Column() {
        Text('测试组件')
      }
      .accessibilityLevel('yes')
      .onClick(() => {
        try {
          // 检查组件是否支持无障碍属性
          console.info('检查组件支持情况');
        } catch (error) {
          const businessError: BusinessError = error as BusinessError;
          if (businessError.code === 100002) {
            console.error('当前组件不支持accessibilityText属性');
            this.errorMessage = '组件不支持错误';
          }
        }
      })
      
      // 示例5：正常设置
      Button('正确设置')
        .accessibilityText('这是一个标准的无障碍文本')
        .onClick(() => {
          this.errorMessage = '';
          console.info('成功设置无障碍文本');
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}