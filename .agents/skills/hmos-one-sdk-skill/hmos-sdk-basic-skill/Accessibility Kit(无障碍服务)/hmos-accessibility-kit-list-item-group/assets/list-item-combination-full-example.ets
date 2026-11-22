/**
 * 列表项组合场景完整示例
 * 功能：演示Toggle、Radio、Checkbox等多种组件与文本标签的组合无障碍实现
 */

@Entry
@Component
export struct ListItemCombinationFullExample {
  title: string = '列表项组合场景示例';
  scroller: Scroller = new Scroller();
  @State isToggleSwitch: boolean = false;
  @State isChecked: boolean = false;
  @State isSelected: boolean = false;

  build() {
    NavDestination() {
      Column() {
        Scroll(this.scroller) {
          Column({ space: 30 }) {
            // Toggle开关组合示例
            Column() {
              Text("Toggle开关组合（按ID桥接）")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否开启功能")
                    .fontSize(14)
                  Toggle({ type: ToggleType.Switch, isOn: this.isToggleSwitch })
                    .selectedColor('#007DFF')
                    .switchPointColor('#FFFFFF')
                    .onChange((isOn: boolean) => {
                      this.isToggleSwitch = isOn;
                      console.info('Toggle Switch status:', isOn);
                    })
                    .id("toggletest1") // 关键：设置唯一ID用于桥接
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "toggletest1",   // 指定Toggle控制状态播报
                actionControllerId: "toggletest1"    // 指定Toggle控制点击操作
              })
              .border({ color: Color.Black, width: 2 })
              .padding(10)
            }

            // Toggle按钮组合示例
            Column() {
              Text("Toggle按钮组合（按ID桥接）")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否改变状态")
                    .fontSize(14)
                  Toggle({ type: ToggleType.Button, isOn: this.isToggleSwitch }) {
                    Text('status button').fontColor('#182431').fontSize(12)
                  }
                  .width(106)
                  .selectedColor('rgba(0,125,255,0.20)')
                  .onChange((isOn: boolean) => {
                    this.isToggleSwitch = isOn;
                    console.info('Toggle Button status:', isOn);
                  })
                  .id("toggletest2")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "toggletest2",
                actionControllerId: "toggletest2"
              })
              .border({ color: Color.Black, width: 2 })
              .padding(10)
            }

            // Toggle复选框组合示例
            Column() {
              Text("Toggle复选框组合（按ID桥接）")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否选中功能")
                    .fontSize(14)
                  Toggle({ type: ToggleType.Checkbox, isOn: this.isChecked })
                    .selectedColor('#007DFF')
                    .onChange((isOn: boolean) => {
                      this.isChecked = isOn;
                      console.info('Toggle Checkbox status:', isOn);
                    })
                    .id("toggletest3")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "toggletest3",
                actionControllerId: "toggletest3"
              })
              .border({ color: Color.Black, width: 2 })
              .padding(10)
            }

            // Radio单选框组合示例
            Column() {
              Text("Radio单选框组合（按ID桥接）")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否改变单选框")
                    .fontSize(14)
                  Radio({
                    value: 'Radio2.1',
                    group: 'radioGroup2',
                    indicatorType: RadioIndicatorType.TICK
                  })
                    .radioStyle({
                      checkedBackgroundColor: Color.Pink
                    })
                    .checked(this.isSelected)
                    .height(20)
                    .width(20)
                    .onChange((isChecked: boolean) => {
                      this.isSelected = isChecked;
                      console.info('Radio status:', isChecked);
                    })
                    .id("radiotest1")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "radiotest1",
                actionControllerId: "radiotest1"
              })
              .border({ color: Color.Black, width: 2 })
              .padding(10)

              Radio({ value: 'Radio2.2', group: 'radioGroup2' })
                .checked(!this.isSelected)
                .radioStyle({
                  checkedBackgroundColor: Color.Pink
                })
                .height(20)
                .width(20)
                .onChange((isChecked: boolean) => {
                  this.isSelected = !isChecked;
                  console.info('Radio2 status:', isChecked);
                })
            }

            // Checkbox复选框组合示例
            Column() {
              Text("Checkbox复选框组合（按ID桥接）")
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Column() {
                Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
                  Text("是否改变复选框")
                    .fontSize(14)
                  Checkbox({ name: 'checkbox2', group: 'checkboxGroup2' })
                    .select(this.isChecked)
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .onChange((value: boolean) => {
                      this.isChecked = value;
                      console.info('Checkbox status:', value);
                    })
                    .id("checkboxtest1")
                }
              }
              .width('100%')
              .accessibilityGroup(true, {
                stateControllerId: "checkboxtest1",
                actionControllerId: "checkboxtest1"
              })
              .border({ color: Color.Black, width: 2 })
              .padding(10)
            }
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .friction(0.6)
        .edgeEffect(EdgeEffect.None)
        .width("100%")
      }
      .width("100%")
      .height("100%")
    }
    .title(this.title)
  }
}