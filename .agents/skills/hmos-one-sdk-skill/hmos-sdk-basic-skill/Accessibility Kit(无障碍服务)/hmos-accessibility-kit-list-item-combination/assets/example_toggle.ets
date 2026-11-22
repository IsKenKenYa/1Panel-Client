@Entry
@Component
export struct ToggleSwitchExample {
  @State isOn: boolean = false;
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text("Toggle开关组合示例")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Column() {
          Text("基本开关组合")
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
              Text("是否开启通知提醒")
                .fontSize(16)
              Toggle({ type: ToggleType.Switch, isOn: this.isOn })
                .selectedColor('#007DFF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  this.isOn = isOn;
                  console.info('Toggle status changed to:' + isOn);
                  if (isOn) {
                    console.info('Notification enabled');
                  } else {
                    console.info('Notification disabled');
                  }
                })
                .id("toggleSwitch1")
            }
          }
          .width('100%')
          .padding(15)
          .accessibilityGroup(true, {
            stateControllerId: "toggleSwitch1",
            actionControllerId: "toggleSwitch1"
          })
          .border({ color: Color.Blue, width: 2 })
          .borderRadius(8)
        }
        
        Column() {
          Text("多个开关组合")
          Column({ space: 10 }) {
            Row() {
              Text("自动更新")
                .width('40%')
              Toggle({ type: ToggleType.Switch, isOn: false })
                .id("autoUpdate")
                .onChange((isOn: boolean) => {
                  console.info('Auto update:' + isOn);
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "autoUpdate",
              actionControllerId: "autoUpdate"
            })
            .border({ color: Color.Gray, width: 1 })
            
            Row() {
              Text("后台运行")
                .width('40%')
              Toggle({ type: ToggleType.Switch, isOn: true })
                .id("backgroundRun")
                .onChange((isOn: boolean) => {
                  console.info('Background run:' + isOn);
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .accessibilityGroup(true, {
              stateControllerId: "backgroundRun",
              actionControllerId: "backgroundRun"
            })
            .border({ color: Color.Gray, width: 1 })
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(20)
    }
    .title("Toggle开关组合")
  }
}