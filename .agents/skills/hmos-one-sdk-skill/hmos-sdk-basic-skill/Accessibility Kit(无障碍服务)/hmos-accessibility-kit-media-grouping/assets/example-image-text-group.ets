/**
 * 示例1：图片与文本组合播报
 * 功能：将插画图片与功能描述文本组合为一个焦点，通过accessibilityGroup(true)实现
 * 适用场景：手势提示、功能图标展示等
 */

@Entry
@Component
export struct ImageTextGroupExample {
  title: string = '图片+文本组合示例';
  private description: string = 'gesture swipe left then up';
  
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Column() {
            // 图片组件
            Image($r("app.media.gesture_swipe_left_then_up"))
              .width(200)
              .height(180)
              .objectFit(ImageFit.Contain)
              .alt('手势示意图') // 图片无障碍备用文本
            
            // 描述文本
            Text(this.description)
              .fontSize(22)
              .fontColor(Color.Red)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }
          .accessibilityGroup(true) // 核心设置：将图片和文本合并为一个辅助功能对象
          .accessibilityLevel("yes") // 确保可被屏幕朗读识别
          .accessibilityText("手势提示：向左然后向上滑动") // 自定义播报文本
          .accessibilityDescription("该组合表示一个手势操作提示")
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }
    .title(this.title)
  }
}

/**
 * 使用说明：
 * 1. accessibilityGroup(true)：将Column及其子组件（Image、Text）组合为一个整体
 * 2. 屏幕朗读选中时，会自动拼接播报："手势提示：向左然后向上滑动"
 * 3. 如不设置accessibilityText，会自动拼接子组件文本："gesture swipe left then up"
 * 4. 建议为图片设置alt属性，作为备用无障碍文本
 */