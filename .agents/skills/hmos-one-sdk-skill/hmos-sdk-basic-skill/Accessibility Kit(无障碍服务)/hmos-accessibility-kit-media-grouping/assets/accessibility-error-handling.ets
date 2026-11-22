import { NavDestination } from '@kit.ArkUI';

@Entry
@Component
export struct AccessibilityErrorHandling {
  @State hasImageError: boolean = false;
  @State accessibilityText: string = '';
  
  build() {
    NavDestination() {
      Column() {
        if (!this.hasImageError) {
          Image($r("app.media.example_image"))
            .width(100)
            .height(100)
            .onError(() => {
              this.hasImageError = true;
              this.accessibilityText = '图片加载失败，功能描述：示例功能';
              console.warn('Image load failed, using fallback text');
            })
        }
        
        Text(this.accessibilityText || "示例文本")
          .fontSize(16)
      }
      .accessibilityGroup(true)
      .accessibilityLevel("yes")
      .accessibilityText(this.accessibilityText || "示例文本")
    }
    .title('错误处理示例')
  }
}