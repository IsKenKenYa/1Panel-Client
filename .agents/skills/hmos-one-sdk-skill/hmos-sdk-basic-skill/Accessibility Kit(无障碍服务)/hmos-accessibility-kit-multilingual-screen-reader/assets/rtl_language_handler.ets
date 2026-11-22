@Component
export struct RTLLanguageHandler {
  @State isRTL: boolean = false;
  @State currentLanguage: string = 'ar-SA';
  @State messageParts: string[] = [];
  
  aboutToAppear() {
    this.isRTL = this.checkLanguageDirection(this.currentLanguage);
    this.loadMessageParts();
  }
  
  build() {
    Column({ space: 20 }) {
      Text('RTL语言处理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .accessibilityText('从右到左语言场景的屏幕朗读处理示例')
      
      Divider()
      
      Column({ space: 10 }) {
        Text('当前语言方向：' + (this.isRTL ? 'RTL (从右到左)' : 'LTR (从左到右)'))
          .fontSize(18)
          .accessibilityText(`当前语言为${this.isRTL ? '从右到左方向' : '从左到右方向'}`)
        
        Divider()
        
        if (this.isRTL) {
          Column({ space: 15 }) {
            Text('正确处理方式：')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Text($r('app.string.rtl_complete_message'))
              .fontSize(20)
              .fontColor(Color.Blue)
              .accessibilityText($r('app.string.rtl_complete_accessibility'))
              .accessibilityDescription($r('app.string.rtl_description'))
            
            Text('避免的错误方式：')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.Red)
            
            Text('不要拼接RTL和LTR文本')
              .fontSize(16)
              .fontColor(Color.Gray)
              .accessibilityText('警告：直接拼接RTL和LTR语言会导致朗读顺序错误')
              .accessibilityDescription('在阿拉伯语等RTL语言场景下，应使用单一Resource定义完整文本，避免字符串拼接')
          }
        } else {
          Column({ space: 15 }) {
            Text('LTR语言可以安全拼接')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
            
            Text(this.concatLTRMessage())
              .fontSize(20)
              .fontColor(Color.Green)
              .accessibilityText(this.getLTRAccessibilityText())
              .accessibilityDescription('从左到右语言场景下可以安全进行字符串拼接')
          }
        }
        
        Divider()
        
        Row({ space: 10 }) {
          Button('切换到阿拉伯语')
            .onClick(() => {
              this.currentLanguage = 'ar-SA';
              this.isRTL = true;
              this.loadMessageParts();
            })
            .accessibilityText('切换到阿拉伯语按钮')
            .accessibilityDescription('点击后将演示RTL语言的屏幕朗读处理')
          
          Button('切换到中文')
            .onClick(() => {
              this.currentLanguage = 'zh-CN';
              this.isRTL = false;
              this.loadMessageParts();
            })
            .accessibilityText('切换到中文按钮')
            .accessibilityDescription('点击后将演示LTR语言的屏幕朗读处理')
        }
      }
    }
    .width('100%')
    .padding(20)
  }
  
  private checkLanguageDirection(language: string): boolean {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    const langCode = language.split('-')[0];
    return rtlLanguages.includes(langCode);
  }
  
  private loadMessageParts(): void {
    if (this.isRTL) {
      this.messageParts = ['مرحبا', 'بكم', 'في', 'HarmonyOS'];
    } else {
      this.messageParts = ['欢迎', '来到', 'HarmonyOS', '系统'];
    }
  }
  
  private concatLTRMessage(): string {
    return this.messageParts.join(' ');
  }
  
  private getLTRAccessibilityText(): string {
    return '欢迎来到HarmonyOS系统，屏幕朗读功能已启用';
  }
}