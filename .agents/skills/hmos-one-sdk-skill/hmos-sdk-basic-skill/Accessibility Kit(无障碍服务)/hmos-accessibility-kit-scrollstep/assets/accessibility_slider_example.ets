@Entry
@Component
export struct AccessibilitySliderExample {
  @State scrollStep: number = 3;
  @State currentValue: number = 10;

  build() {
    NavDestination() {
      Column() {
        Text('无障碍滚动步数示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(`当前scrollStep: ${this.scrollStep}`)
          .fontSize(16)
          .margin({ bottom: 10 })

        Text(`实际步长: ${this.scrollStep * 10}`)
          .fontSize(16)
          .margin({ bottom: 20 })

        Slider({
          min: 0,
          max: 100,
          value: this.currentValue,
          step: 10,
          style: SliderStyle.OutSet
        })
          .accessibilityActionOptions({ scrollStep: this.scrollStep })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.currentValue = value;
            console.info(`Slider value changed: ${value}, mode: ${mode}`);
          })
          .width('80%')

        Text(`当前值: ${this.currentValue}`)
          .fontSize(16)
          .margin({ top: 20 })

        Row({ space: 10 }) {
          Button('scrollStep + 1')
            .onClick(() => {
              if (this.scrollStep < 10) {
                this.scrollStep++;
              }
            })
            .width(120)

          Button('scrollStep - 1')
            .onClick(() => {
              if (this.scrollStep > 1) {
                this.scrollStep--;
              }
            })
            .width(120)
        }
        .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .title('Accessibility Slider')
  }
}