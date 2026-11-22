@Entry
@Component
export struct CombinedExample {
  @State isToggleOn: boolean = false;
  @State isRadioSelected: boolean = false;
  @State isCheckboxChecked: boolean = false;
  
  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 30 }) {
          Text("多类型组件组合示例")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })
          
          Column() {
            Text("示例1: Toggle开关组合")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                Text("是否开启夜间模式")
                  .fontSize(16)
                Toggle({ type: ToggleType.Switch, isOn: this.isToggleOn })
                  .selectedColor('#007DFF')
                  .switchPointColor('#FFFFFF')
                  .onChange((isOn: boolean) => {
                    this.isToggleOn = isOn;
                    console.info('Night mode status:' + isOn);
                  })
                  .id("toggleNightMode")
              }
            }
            .width('100%')
            .padding(15)
            .accessibilityGroup(true, {
              stateControllerId: "toggleNightMode",
              actionControllerId: "toggleNightMode"
            })
            .border({ color: Color.Blue, width: 2 })
            .borderRadius(8)
          }
          
          Column() {
            Text("示例2: Radio单选框组合")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                Text("选择主题颜色")
                  .fontSize(16)
                Radio({
                  value: 'darkTheme',
                  group: 'themeGroup',
                  indicatorType: RadioIndicatorType.TICK
                })
                  .radioStyle({
                    checkedBackgroundColor: Color.Blue
                  })
                  .checked(this.isRadioSelected)
                  .height(20)
                  .width(20)
                  .onChange((isChecked: boolean) => {
                    this.isRadioSelected = isChecked;
                    console.info('Dark theme selected:' + isChecked);
                  })
                  .id("radioDarkTheme")
              }
            }
            .width('100%')
            .padding(15)
            .accessibilityGroup(true, {
              stateControllerId: "radioDarkTheme",
              actionControllerId: "radioDarkTheme"
            })
            .border({ color: Color.Orange, width: 2 })
            .borderRadius(8)
          }
          
          Column() {
            Text("示例3: Checkbox复选框组合")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                Text("记住登录状态")
                  .fontSize(16)
                Checkbox({ name: 'rememberLogin', group: 'loginGroup' })
                  .select(this.isCheckboxChecked)
                  .selectedColor(0x007DFF)
                  .shape(CheckBoxShape.CIRCLE)
                  .onChange((value: boolean) => {
                    this.isCheckboxChecked = value;
                    console.info('Remember login:' + value);
                  })
                  .id("checkboxRemember")
              }
            }
            .width('100%')
            .padding(15)
            .accessibilityGroup(true, {
              stateControllerId: "checkboxRemember",
              actionControllerId: "checkboxRemember"
            })
            .border({ color: Color.Green, width: 2 })
            .borderRadius(8)
          }
          
          Column() {
            Text("示例4: Toggle按钮样式组合")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                Text("切换显示模式")
                  .fontSize(16)
                Toggle({ type: ToggleType.Button, isOn: false }) {
                  Text('紧凑模式').fontColor('#182431').fontSize(12)
                }
                .width(100)
                .selectedColor('rgba(0,125,255,0.20)')
                .onChange((isOn: boolean) => {
                  console.info('Compact mode:' + isOn);
                })
                .id("toggleCompactMode")
              }
            }
            .width('100%')
            .padding(15)
            .accessibilityGroup(true, {
              stateControllerId: "toggleCompactMode",
              actionControllerId: "toggleCompactMode"
            })
            .border({ color: Color.Purple, width: 2 })
            .borderRadius(8)
          }
          
          Column() {
            Text("示例5: Toggle复选框样式组合")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Column() {
              Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                Text("启用自动保存")
                  .fontSize(16)
                Toggle({ type: ToggleType.Checkbox, isOn: false })
                  .selectedColor('#007DFF')
                  .onChange((isOn: boolean) => {
                    console.info('Auto save:' + isOn);
                  })
                  .id("toggleAutoSave")
              }
            }
            .width('100%')
            .padding(15)
            .accessibilityGroup(true, {
              stateControllerId: "toggleAutoSave",
              actionControllerId: "toggleAutoSave"
            })
            .border({ color: Color.Red, width: 2 })
            .borderRadius(8)
          }
        }
        .width('100%')
        .padding(20)
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.On)
      .width("100%")
    }
    .title("多类型组件组合")
    .width("100%")
    .height("100%")
  }
}