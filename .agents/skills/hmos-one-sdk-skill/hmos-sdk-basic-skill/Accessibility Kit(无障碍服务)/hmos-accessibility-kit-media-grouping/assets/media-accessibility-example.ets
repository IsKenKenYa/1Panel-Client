import { NavDestination } from '@kit.ArkUI';

@Entry
@Component
export struct MediaAccessibilityExample {
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
            Image($r("app.media.gesture_swipe_left_then_up"))
              .width(200)
              .height(180)
              .objectFit(ImageFit.Contain)
            
            Text(this.description)
              .fontSize(22)
              .fontColor(Color.Red)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }
          .accessibilityGroup(true)
          .accessibilityLevel("yes")
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }
    .title('插画播报示例')
  }
}