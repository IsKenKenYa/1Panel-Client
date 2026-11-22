@Entry
@Component
export struct RadioExample {
  @State selectedOption: string = 'option1';
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text("Radio单选框组合示例")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Column() {
          Text("基本单选框组合")
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
              Text("请选择支付方式")
                .fontSize(16)
              Radio({
                value: 'option1',
                group: 'paymentGroup',
                indicatorType: RadioIndicatorType.TICK
              })
                .radioStyle({
                  checkedBackgroundColor: Color.Pink
                })
                .checked(this.selectedOption === 'option1')
                .height(20)
                .width(20)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedOption = 'option1';
                    console.info('Selected: Alipay');
                  }
                })
                .id("radioPayment1")
            }
          }
          .width('100%')
          .padding(15)
          .accessibilityGroup(true, {
            stateControllerId: "radioPayment1",
            actionControllerId: "radioPayment1"
          })
          .border({ color: Color.Blue, width: 2 })
          .borderRadius(8)
        }
        
        Column() {
          Text("多选项单选框组合")
          Column({ space: 10 }) {
            Row() {
              Text("支付宝")
                .width('70%')
              Radio({
                value: 'alipay',
                group: 'paymentMethod',
                indicatorType: RadioIndicatorType.TICK
              })
                .id("alipayRadio")
                .checked(this.selectedOption === 'alipay')
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedOption = 'alipay';
                    console.info('Payment method: Alipay');
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "alipayRadio",
              actionControllerId: "alipayRadio"
            })
            .border({ color: Color.Gray, width: 1 })
            
            Row() {
              Text("微信支付")
                .width('70%')
              Radio({
                value: 'wechat',
                group: 'paymentMethod',
                indicatorType: RadioIndicatorType.TICK
              })
                .id("wechatRadio")
                .checked(this.selectedOption === 'wechat')
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedOption = 'wechat';
                    console.info('Payment method: WeChat Pay');
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "wechatRadio",
              actionControllerId: "wechatRadio"
            })
            .border({ color: Color.Gray, width: 1 })
            
            Row() {
              Text("银行卡")
                .width('70%')
              Radio({
                value: 'bank',
                group: 'paymentMethod',
                indicatorType: RadioIndicatorType.TICK
              })
                .id("bankRadio")
                .checked(this.selectedOption === 'bank')
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedOption = 'bank';
                    console.info('Payment method: Bank Card');
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "bankRadio",
              actionControllerId: "bankRadio"
            })
            .border({ color: Color.Gray, width: 1 })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(20)
    }
    .title("Radio单选框组合")
  }
}