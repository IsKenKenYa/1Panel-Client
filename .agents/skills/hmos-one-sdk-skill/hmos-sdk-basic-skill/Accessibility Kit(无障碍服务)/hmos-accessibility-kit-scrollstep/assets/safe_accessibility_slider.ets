@Entry
@Component
export struct SafeAccessibilitySlider {
  @State scrollStep: number = 3;
  @State sliderValue: number = 10;
  @State errorMessage: string = '';
  private min: number = 0;
  private max: number = 100;
  private step: number = 10;

  getScrollStepMax(): number {
    return Math.floor((this.max - this.min) / this.step);
  }

  validateScrollStep(value: number): number {
    const maxScrollStep = this.getScrollStepMax();
    
    if (value < 1) {
      this.errorMessage = `scrollStep ${value} 小于最小值1，已调整为1`;
      console.warn(this.errorMessage);
      return 1;
    }
    
    if (value > maxScrollStep) {
      this.errorMessage = `scrollStep ${value} 超出最大值${maxScrollStep}，已调整为1`;
      console.warn(this.errorMessage);
      return 1;
    }
    
    if (!Number.isInteger(value)) {
      const flooredValue = Math.floor(value);
      this.errorMessage = `scrollStep ${value} 不是整数，已调整为${flooredValue}`;
      console.warn(this.errorMessage);
      return flooredValue;
    }
    
    this.errorMessage = '';
    return value;
  }

  build() {
    NavDestination() {
      Column() {
        Text('参数校验示例')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text(`scrollStep取值范围: [1, ${this.getScrollStepMax()}]`)
          .fontSize(16)
          .margin({ bottom: 10 })

        TextInput({ placeholder: '输入scrollStep值' })
          .type(InputType.Number)
          .onChange((value: string) => {
            const numValue = parseFloat(value);
            if (!isNaN(numValue)) {
              this.scrollStep = this.validateScrollStep(numValue);
            }
          })
          .width('80%')
          .margin({ bottom: 10 })

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(Color.Red)
            .margin({ bottom: 10 })
        }

        Slider({
          min: this.min,
          max: this.max,
          value: this.sliderValue,
          step: this.step,
          style: SliderStyle.OutSet
        })
          .accessibilityActionOptions({ 
            scrollStep: this.validateScrollStep(this.scrollStep) 
          })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.sliderValue = value;
            console.info(`Value: ${value}, Mode: ${mode}`);
          })
          .width('80%')

        Text(`当前值: ${this.sliderValue}`)
          .fontSize(16)
          .margin({ top: 20 })

        Text(`实际scrollStep: ${this.scrollStep}`)
          .fontSize(16)
          .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
    }
    .title('Safe Accessibility Slider')
  }
}