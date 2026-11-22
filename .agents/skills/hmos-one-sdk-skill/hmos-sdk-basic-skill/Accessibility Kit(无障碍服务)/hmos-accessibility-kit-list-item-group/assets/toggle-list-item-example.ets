/**
 * Toggle开关组合列表项无障碍示例
 * 功能：演示如何将Toggle开关和文本标签组合为一个整体进行无障碍聚焦和播报
 */

@Entry
@Component
struct ToggleListItemExample {
  @State isFeatureEnabled: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text("Toggle开关组合无障碍示例")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding(10)

      // 示例1：Toggle开关样式 - 按ID桥接
      Column() {
        Text("示例1：Toggle开关（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("是否开启功能")
              .fontSize(14)
            Toggle({ type: ToggleType.Switch, isOn: this.isFeatureEnabled })
              .selectedColor('#007DFF')
              .switchPointColor('#FFFFFF')
              .onChange((isOn: boolean) => {
                this.isFeatureEnabled = isOn;
                console.info('Feature enabled:', isOn);
              })
              .id("toggleSwitchId") // 设置唯一ID用于桥接
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "toggleSwitchId",   // 指定Toggle控制状态播报
          actionControllerId: "toggleSwitchId"    // 指定Toggle控制点击操作
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例2：Toggle按钮样式 - 按ID桥接
      Column() {
        Text("示例2：Toggle按钮（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("是否改变状态")
              .fontSize(14)
            Toggle({ type: ToggleType.Button, isOn: this.isFeatureEnabled }) {
              Text('状态按钮').fontColor('#182431').fontSize(12)
            }
            .width(106)
            .selectedColor('rgba(0,125,255,0.20)')
            .onChange((isOn: boolean) => {
              this.isFeatureEnabled = isOn;
              console.info('Button toggle changed:', isOn);
            })
            .id("toggleButtonId") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "toggleButtonId",
          actionControllerId: "toggleButtonId"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例3：Toggle复选框样式 - 按ID桥接
      Column() {
        Text("示例3：Toggle复选框（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("是否选中功能")
              .fontSize(14)
            Toggle({ type: ToggleType.Checkbox, isOn: !this.isFeatureEnabled })
              .selectedColor('#007DFF')
              .onChange((isOn: boolean) => {
                this.isFeatureEnabled = !isOn;
                console.info('Checkbox toggle changed:', isOn);
              })
              .id("toggleCheckboxId") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "toggleCheckboxId",
          actionControllerId: "toggleCheckboxId"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}