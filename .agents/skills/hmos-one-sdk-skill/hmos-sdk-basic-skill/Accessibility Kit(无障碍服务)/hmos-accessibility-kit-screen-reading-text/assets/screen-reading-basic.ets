/**
 * 基础示例：设置无障碍文本
 * 本示例演示如何使用string格式设置组件的无障碍文本
 */

@Entry
@Component
struct ScreenReadingBasicExample {
  build() {
    Column({ space: 20 }) {
      // 示例1：为按钮设置无障碍文本
      Button('确定')
        .accessibilityText('确认提交按钮，点击后将提交表单')
        .onClick(() => {
          console.info('Submit button clicked');
        })
      
      // 示例2：为图标设置无障碍文本
      Image($r('app.media.icon'))
        .width(50)
        .height(50)
        .accessibilityText('应用图标')
      
      // 示例3：为颜色元素补充说明
      Text('红色')
        .fontColor(Color.Red)
        .fontSize(20)
        .accessibilityText('红色文本，表示警告信息')
      
      // 示例4：为无文本组件设置朗读内容
      Row() {
        Blank()
        Blank()
      }
      .width(100)
      .height(50)
      .backgroundColor(Color.Blue)
      .accessibilityText('蓝色分隔区域')
      
      // 示例5：为列表项设置无障碍文本
      List() {
        ListItem() {
          Text('选项1')
            .accessibilityText('列表项1，点击查看详情')
        }
        ListItem() {
          Text('选项2')
            .accessibilityText('列表项2，点击查看详情')
        }
      }
      .width('100%')
      .height(100)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}