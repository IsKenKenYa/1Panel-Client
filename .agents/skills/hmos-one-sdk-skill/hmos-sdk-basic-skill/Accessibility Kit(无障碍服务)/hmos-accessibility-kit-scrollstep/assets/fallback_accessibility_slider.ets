@Entry
@Component
export struct FallbackAccessibilitySlider {
  @State scrollStep: number = 500;
  @State actualScrollStep: number = 1;
  @State fallbackReason: string = '';
  @State sliderValue: number = 40;

  aboutToAppear() {
    this.applyFallbackLogic();
  }

  applyFallbackLogic() {
    const maxScrollStep = Math.floor(100 / 10);
    
    if (this.scrollStep < 1) {
      this.actualScrollStep = 1;
      this.fallbackReason = `scrollStep ${this.scrollStep} 小于最小值，降级为默认值1`;
    } else if (this.scrollStep > maxScrollStep) {
      this.actualScrollStep = 1;
      this.fallbackReason = `scrollStep ${this.scrollStep} 超出最大值${maxScrollStep}，降级为默认值1`;
    } else if (!Number.isInteger(this.scrollStep)) {
      this.actualScrollStep = Math.floor(this.scrollStep);
      this.fallbackReason = `scrollStep ${this.scrollStep} 不是整数，向下取整为${this.actualScrollStep}`;
    } else {
      this.actualScrollStep = this.scrollStep;
      this.fallbackReason = 'scrollStep值有效，无需降级';
    }
    
    console.warn(this.fallbackReason);
  }

  build() {
    NavDestination() {
      Column() {
        Text('降级处理示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(`配置的scrollStep: ${this.scrollStep}`)
          .fontSize(16)
          .margin({ bottom: 10 })

        Text(`实际生效scrollStep: ${this.actualScrollStep}`)
          .fontSize(16)
          .fontColor(this.actualScrollStep !== this.scrollStep ? Color.Red : Color.Green)
          .margin({ bottom: 10 })

        Text(`降级原因: ${this.fallbackReason}`)
          .fontSize(14)
          .margin({ bottom: 20 })

        Slider({
          min: 0,
          max: 100,
          value: this.sliderValue,
          step: 10,
          style: SliderStyle.OutSet
        })
          .accessibilityActionOptions({ scrollStep: this.actualScrollStep })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.sliderValue = value;
            console.info(`Slider value: ${value}, mode: ${mode}`);
          })
          .width('80%')

        Text(`当前值: ${this.sliderValue}`)
          .fontSize(16)
          .margin({ top: 20 })

        Row({ space: 10 }) {
          Button('测试超出范围')
            .onClick(() => {
              this.scrollStep = 500;
              this.applyFallbackLogic();
            })
            .width(120)

          Button('测试非整数')
            .onClick(() => {
              this.scrollStep = 3.7;
              this.applyFallbackLogic();
            })
            .width(120)

          Button('测试负数')
            .onClick(() => {
              this.scrollStep = -5;
              this.applyFallbackLogic();
            })
            .width(120)
        }
        .margin({ top: 20 })

        Button('测试有效值')
          .onClick(() => {
            this.scrollStep = 5;
            this.applyFallbackLogic();
          })
          .width(360)
          .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
    }
    .title('Fallback Accessibility Slider')
  }
}