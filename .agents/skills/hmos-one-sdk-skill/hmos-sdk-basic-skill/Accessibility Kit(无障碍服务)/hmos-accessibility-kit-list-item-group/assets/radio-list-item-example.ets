/**
 * Radio单选框组合列表项无障碍示例
 * 功能：演示如何将Radio单选框和文本标签组合为一个整体进行无障碍聚焦和播报
 */

@Entry
@Component
struct RadioListItemExample {
  @State selectedOption: string = '';

  build() {
    Column({ space: 20 }) {
      Text("Radio单选框组合无障碍示例")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding(10)

      // 示例1：Radio单选框 - 按ID桥接
      Column() {
        Text("示例1：Radio单选框（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("选项A")
              .fontSize(14)
            Radio({
              value: 'OptionA',
              group: 'radioGroup1',
              indicatorType: RadioIndicatorType.TICK
            })
              .radioStyle({
                checkedBackgroundColor: Color.Pink
              })
              .checked(this.selectedOption === 'OptionA')
              .height(20)
              .width(20)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedOption = 'OptionA';
                  console.info('Selected OptionA');
                }
              })
              .id("radioOptionA") // 设置唯一ID用于桥接
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "radioOptionA",   // 指定Radio控制状态播报
          actionControllerId: "radioOptionA"    // 指定Radio控制点击操作
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例2：Radio单选框 - 按ID桥接
      Column() {
        Text("示例2：Radio单选框（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("选项B")
              .fontSize(14)
            Radio({
              value: 'OptionB',
              group: 'radioGroup1',
              indicatorType: RadioIndicatorType.TICK
            })
              .radioStyle({
                checkedBackgroundColor: Color.Blue
              })
              .checked(this.selectedOption === 'OptionB')
              .height(20)
              .width(20)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedOption = 'OptionB';
                  console.info('Selected OptionB');
                }
              })
              .id("radioOptionB") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "radioOptionB",
          actionControllerId: "radioOptionB"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例3：Radio单选框 - 按ID桥接
      Column() {
        Text("示例3：Radio单选框（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("选项C")
              .fontSize(14)
            Radio({
              value: 'OptionC',
              group: 'radioGroup1'
            })
              .checked(this.selectedOption === 'OptionC')
              .height(20)
              .width(20)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedOption = 'OptionC';
                  console.info('Selected OptionC');
                }
              })
              .id("radioOptionC") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "radioOptionC",
          actionControllerId: "radioOptionC"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 显示当前选中状态
      Text(`当前选中: ${this.selectedOption || '未选择'}`)
        .fontSize(16)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}