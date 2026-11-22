/**
 * Checkbox复选框组合列表项无障碍示例
 * 功能：演示如何将Checkbox复选框和文本标签组合为一个整体进行无障碍聚焦和播报
 */

@Entry
@Component
struct CheckboxListItemExample {
  @State isChecked1: boolean = false;
  @State isChecked2: boolean = true;
  @State isChecked3: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text("Checkbox复选框组合无障碍示例")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding(10)

      // 示例1：Checkbox复选框 - 按ID桥接（圆形）
      Column() {
        Text("示例1：Checkbox圆形（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("功能1")
              .fontSize(14)
            Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
              .select(this.isChecked1)
              .selectedColor(0xed6f21)
              .shape(CheckBoxShape.CIRCLE)
              .onChange((value: boolean) => {
                this.isChecked1 = value;
                console.info('Checkbox1 changed:', value);
              })
              .id("checkbox1Id") // 设置唯一ID用于桥接
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "checkbox1Id",   // 指定Checkbox控制状态播报
          actionControllerId: "checkbox1Id"    // 指定Checkbox控制点击操作
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例2：Checkbox复选框 - 按ID桥接（方形）
      Column() {
        Text("示例2：Checkbox方形（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("功能2")
              .fontSize(14)
            Checkbox({ name: 'checkbox2', group: 'checkboxGroup' })
              .select(this.isChecked2)
              .selectedColor('#007DFF')
              .shape(CheckBoxShape.SQUARE)
              .onChange((value: boolean) => {
                this.isChecked2 = value;
                console.info('Checkbox2 changed:', value);
              })
              .id("checkbox2Id") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "checkbox2Id",
          actionControllerId: "checkbox2Id"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 示例3：Checkbox复选框 - 按ID桥接
      Column() {
        Text("示例3：Checkbox默认（按ID桥接）")
          .fontSize(16)
          .margin({ bottom: 10 })

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
            Text("功能3")
              .fontSize(14)
            Checkbox({ name: 'checkbox3', group: 'checkboxGroup' })
              .select(this.isChecked3)
              .selectedColor(Color.Green)
              .onChange((value: boolean) => {
                this.isChecked3 = value;
                console.info('Checkbox3 changed:', value);
              })
              .id("checkbox3Id") // 设置唯一ID
          }
        }
        .width('100%')
        .accessibilityGroup(true, {
          stateControllerId: "checkbox3Id",
          actionControllerId: "checkbox3Id"
        })
        .border({ color: Color.Black, width: 2 })
        .padding(10)
      }

      // 显示当前选中状态
      Column({ space: 10 }) {
        Text(`功能1: ${this.isChecked1 ? '已选择' : '未选择'}`)
          .fontSize(14)
        Text(`功能2: ${this.isChecked2 ? '已选择' : '未选择'}`)
          .fontSize(14)
        Text(`功能3: ${this.isChecked3 ? '已选择' : '未选择'}`)
          .fontSize(14)
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .padding(20)
  }
}