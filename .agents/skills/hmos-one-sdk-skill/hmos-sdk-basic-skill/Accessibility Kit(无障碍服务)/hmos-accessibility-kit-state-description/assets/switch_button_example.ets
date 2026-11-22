/**
 * 开关按钮状态播报示例
 * 实现开关按钮的状态说明标签设置和屏幕朗读状态播报
 */

@Entry
@Component
export struct SwitchButtonExample {
  title: string = '开关按钮状态播报示例';
  
  // 开关状态,表示是否开启
  @State private isOn: boolean = false;
  
  // 状态说明文本(使用Resource类型)
  // 注意: 需要在resources/base/element/string.json中定义对应的字符串资源
  // 或直接使用string类型
  private getSwitchStateText(): string {
    return this.isOn ? "已开启" : "已关闭";
  }
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 标题说明
        Text('开关按钮状态播报演示')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        
        // 使用自定义按钮实现开关
        Button() {
          Row({ space: 10 }) {
            // 开关图标
            Image(this.isOn ? $r('app.media.switch_on') : $r('app.media.switch_off'))
              .width(40)
              .height(40)
            
            // 状态文本显示
            Text(this.getSwitchStateText())
              .fontSize(16)
              .fontColor(this.isOn ? '#4CAF50' : '#9E9E9E')
          }
        }
        .width(200)
        .height(80)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        // 设置状态说明标签 - 屏幕朗读会播报此文本
        .accessibilityStateDescription(this.getSwitchStateText())
        // 设置选中状态 - 影响屏幕朗读的状态播报
        .accessibilitySelected(this.isOn)
        // 设置无障碍重要性
        .accessibilityLevel("yes")
        // 设置无障碍文本 - 描述按钮的功能
        .accessibilityText("开关按钮")
        // 点击事件
        .onClick(() => {
          this.isOn = !this.isOn;
          console.info(`开关状态切换为: ${this.getSwitchStateText()}`);
        })
        
        // 状态指示器
        Row() {
          Text('当前状态:')
            .fontSize(14)
          Text(this.getSwitchStateText())
            .fontSize(14)
            .fontColor(this.isOn ? '#4CAF50' : '#9E9E9E')
            .fontWeight(FontWeight.Bold)
        }
        .margin({ top: 10 })
        
        // 使用场景说明
        Column({ space: 10 }) {
          Text('播报顺序说明:')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          
          Text('1. 聚焦时播报: "开关按钮" + "已开启/已关闭"')
            .fontSize(12)
            .fontColor('#666666')
          
          Text('2. 双击后播报: 新的状态说明"已开启/已关闭"')
            .fontSize(12)
            .fontColor('#666666')
        }
        .margin({ top: 20 })
        .padding(10)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title(this.title)
  }
}