@Entry
@Component
export struct CheckboxExample {
  @State isChecked1: boolean = false;
  @State isChecked2: boolean = true;
  @State isChecked3: boolean = false;
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text("Checkbox复选框组合示例")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Column() {
          Text("基本复选框组合")
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
              Text("同意服务条款")
                .fontSize(16)
              Checkbox({ name: 'agreement', group: 'agreementGroup' })
                .select(this.isChecked1)
                .selectedColor(0xed6f21)
                .shape(CheckBoxShape.CIRCLE)
                .onChange((value: boolean) => {
                  this.isChecked1 = value;
                  console.info('Agreement checkbox changed to:' + value);
                  if (value) {
                    console.info('User agreed to terms');
                  } else {
                    console.info('User disagreed to terms');
                  }
                })
                .id("checkboxAgreement")
            }
          }
          .width('100%')
          .padding(15)
          .accessibilityGroup(true, {
            stateControllerId: "checkboxAgreement",
            actionControllerId: "checkboxAgreement"
          })
          .border({ color: Color.Blue, width: 2 })
          .borderRadius(8)
        }
        
        Column() {
          Text("多选项复选框组合")
          Column({ space: 10 }) {
            Row() {
              Text("接收推送通知")
                .width('70%')
              Checkbox({ name: 'push', group: 'settingsGroup' })
                .select(this.isChecked2)
                .selectedColor(0x007DFF)
                .id("pushCheckbox")
                .onChange((value: boolean) => {
                  this.isChecked2 = value;
                  console.info('Push notification:' + value);
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "pushCheckbox",
              actionControllerId: "pushCheckbox"
            })
            .border({ color: Color.Gray, width: 1 })
            
            Row() {
              Text("接收邮件通知")
                .width('70%')
              Checkbox({ name: 'email', group: 'settingsGroup' })
                .select(this.isChecked3)
                .selectedColor(0x007DFF)
                .id("emailCheckbox")
                .onChange((value: boolean) => {
                  this.isChecked3 = value;
                  console.info('Email notification:' + value);
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "emailCheckbox",
              actionControllerId: "emailCheckbox"
            })
            .border({ color: Color.Gray, width: 1 })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(20)
    }
    .title("Checkbox复选框组合")
  }
}