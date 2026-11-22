/**
 * 选择按钮状态播报示例
 * 实现多选按钮的状态说明标签设置和屏幕朗读状态播报
 */

@Entry
@Component
export struct SelectButtonExample {
  title: string = '选择按钮状态播报示例';
  
  // 多个选项的状态管理
  @State private option1Selected: boolean = false;
  @State private option2Selected: boolean = true;
  @State private option3Selected: boolean = false;
  
  // 状态说明文本
  private selectedText: string = "已选中";
  private unselectedText: string = "未选中";
  
  // 构建单个选项组件
  @Builder
  buildOption(text: string, isSelected: boolean, onSelectChange: () => void) {
    Button() {
      Row({ space: 15 }) {
        // 选中状态图标
        Image(isSelected ? $r('app.media.checkbox_selected') : $r('app.media.checkbox_unselected'))
          .width(24)
          .height(24)
        
        // 选项文本
        Text(text)
          .fontSize(16)
          .fontColor(isSelected ? '#2196F3' : '#333333')
      }
    }
    .width('100%')
    .height(50)
    .backgroundColor(isSelected ? '#E3F2FD' : '#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#E0E0E0' })
    // 设置状态说明标签
    .accessibilityStateDescription(isSelected ? this.selectedText : this.unselectedText)
    // 设置选中状态
    .accessibilitySelected(isSelected)
    // 设置无障碍重要性
    .accessibilityLevel("yes")
    // 设置无障碍文本 - 描述选项内容
    .accessibilityText(`${text}选项`)
    // 点击事件
    .onClick(onSelectChange)
  }
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 标题说明
        Text('请选择以下选项')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        // 选项1
        this.buildOption('选项一: 基础功能', this.option1Selected, () => {
          this.option1Selected = !this.option1Selected;
          console.info(`选项1状态: ${this.option1Selected ? this.selectedText : this.unselectedText}`);
        })
        
        // 选项2
        this.buildOption('选项二: 高级功能', this.option2Selected, () => {
          this.option2Selected = !this.option2Selected;
          console.info(`选项2状态: ${this.option2Selected ? this.selectedText : this.unselectedText}`);
        })
        
        // 选项3
        this.buildOption('选项三: 专业功能', this.option3Selected, () => {
          this.option3Selected = !this.option3Selected;
          console.info(`选项3状态: ${this.option3Selected ? this.selectedText : this.unselectedText}`);
        })
        
        // 已选选项统计
        Column({ space: 10 }) {
          Text('已选选项:')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          
          Text(`已选中 ${this.getSelectedCount()} 个选项`)
            .fontSize(14)
            .fontColor('#666666')
        }
        .margin({ top: 20 })
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .width('100%')
        
        // 使用场景说明
        Column({ space: 10 }) {
          Text('屏幕朗读播报说明:')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          
          Text('聚焦时播报: "选项一:基础功能选项" + "已选中/未选中"')
            .fontSize(12)
            .fontColor('#666666')
          
          Text('双击后播报: 切换后的状态说明"已选中/未选中"')
            .fontSize(12)
            .fontColor('#666666')
          
          Text('注意: accessibilityStateDescription只影响状态播报')
            .fontSize(12)
            .fontColor('#FF9800')
        }
        .margin({ top: 20 })
        .padding(15)
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .width('100%')
      }
      .width('100%')
      .padding(20)
    }
    .title(this.title)
  }
  
  // 获取已选选项数量
  private getSelectedCount(): number {
    let count = 0;
    if (this.option1Selected) count++;
    if (this.option2Selected) count++;
    if (this.option3Selected) count++;
    return count;
  }
}