/**
 * Resource引用示例：使用资源文件设置无障碍文本
 * 本示例演示如何使用Resource格式引用资源文件中的文本
 * 注意：需要API version ≥ 12
 */

@Entry
@Component
struct ScreenReadingResourceExample {
  @State message: string = '示例页面';
  
  build() {
    Column({ space: 20 }) {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      // 示例1：为按钮引用Resource文本
      Button('提交')
        .accessibilityText($r('app.string.submit_button_accessibility'))
        .onClick(() => {
          console.info('Submit button clicked');
        })
      
      // 示例2：为输入框引用Resource文本
      TextInput({ placeholder: '请输入内容' })
        .width('80%')
        .accessibilityText($r('app.string.input_field_accessibility'))
        .onChange((value: string) => {
          this.message = value;
        })
      
      // 示例3：为开关引用Resource文本
      Toggle({ type: ToggleType.Switch, isOn: false })
        .accessibilityText($r('app.string.toggle_switch_accessibility'))
        .onChange((isOn: boolean) => {
          console.info(`Toggle changed to ${isOn}`);
        })
      
      // 示例4：为图片引用Resource文本
      Image($r('app.media.example_image'))
        .width(100)
        .height(100)
        .accessibilityText($r('app.string.example_image_accessibility'))
      
      // 示例5：动态切换Resource
      Button('切换语言')
        .onClick(() => {
          // Resource会自动根据当前语言环境加载对应文本
          console.info('Language switched');
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}

/**
 * 资源文件配置示例（resources/base/element/string.json）：
 * {
 *   "string": [
 *     {
 *       "name": "submit_button_accessibility",
 *       "value": "提交表单的按钮，点击后提交数据"
 *     },
 *     {
 *       "name": "input_field_accessibility",
 *       "value": "文本输入框，请输入相关信息"
 *     },
 *     {
 *       "name": "toggle_switch_accessibility",
 *       "value": "开关控件，可开启或关闭功能"
 *     },
 *     {
 *       "name": "example_image_accessibility",
 *       "value": "示例图片，展示了应用的功能"
 *     }
 *   ]
 * }
 */