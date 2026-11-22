/**
 * 收藏按钮状态播报示例
 * 实现收藏按钮的状态说明标签设置和屏幕朗读状态播报
 */

@Entry
@Component
export struct FavoriteButtonExample {
  title: string = '收藏按钮状态播报示例';
  
  // 收藏按钮状态,表示是否被选中
  @State private isSelected: boolean = false;
  
  // 状态说明文本
  private selectedText: string = "已收藏";
  private unselectedText: string = "未收藏";
  
  build() {
    NavDestination() {
      Column() {
        // 标题说明
        Text('点击按钮切换收藏状态')
          .fontSize(16)
          .margin({ bottom: 20 })
        
        // 收藏按钮
        Button() {
          // 根据状态显示不同的图标
          Image(this.isSelected ? $r('app.media.favorIcon') : $r('app.media.unfavorIcon'))
            .width(30)
            .height(30)
        }
        .width(60)
        .height(60)
        // 指定按钮的状态说明标签
        .accessibilityStateDescription(this.isSelected ? this.selectedText : this.unselectedText)
        // 设置按钮的选中状态
        .accessibilitySelected(this.isSelected)
        // 设置无障碍重要性为yes,确保可被无障碍服务识别
        .accessibilityLevel("yes")
        // 按钮点击事件处理程序,切换选中状态
        .onClick(() => {
          this.isSelected = !this.isSelected;
          console.info(`收藏状态切换为: ${this.isSelected ? this.selectedText : this.unselectedText}`);
        })
        
        // 显示当前状态
        Text(`当前状态: ${this.isSelected ? this.selectedText : this.unselectedText}`)
          .fontSize(14)
          .margin({ top: 20 })
          .fontColor('#666666')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .title(this.title)
  }
}