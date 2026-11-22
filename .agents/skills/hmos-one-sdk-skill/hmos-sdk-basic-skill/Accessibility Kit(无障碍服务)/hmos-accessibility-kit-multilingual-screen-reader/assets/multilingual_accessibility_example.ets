@Entry
@Component
export struct MultilingualAccessibilityExample {
  @State currentLanguage: string = 'zh-CN';
  @State isRTL: boolean = false;
  @State messageCount: number = 3;
  
  aboutToAppear() {
    this.isRTL = this.checkLanguageDirection(this.currentLanguage);
  }
  
  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text('多语种屏幕朗读示例')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .accessibilityText('多语种屏幕朗读功能演示标题')
          .accessibilityDescription('本页面展示如何在多语言环境下正确配置屏幕朗读无障碍功能')
        
        Divider()
        
        Column({ space: 15 }) {
          Text('示例1：使用Resource引用')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
          
          Text($r('app.string.multilingual_message'))
            .fontSize(18)
            .fontColor(Color.Blue)
            .accessibilityText($r('app.string.accessibility_multilingual_message'))
            .accessibilityDescription($r('app.string.description_multilingual'))
        }
        
        Divider()
        
        Column({ space: 15 }) {
          Text('示例2：中英文混合')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
          
          Text('欢迎使用 Welcome to HarmonyOS')
            .fontSize(18)
            .fontColor(Color.Green)
            .accessibilityText('中英文混合文本：欢迎使用，欢迎来到HarmonyOS系统')
            .accessibilityDescription('演示中英文混合文本的屏幕朗读处理')
        }
        
        Divider()
        
        Column({ space: 15 }) {
          Text('示例3：避免拼接')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
          
          if (this.isRTL) {
            Text($r('app.string.rtl_safe_message'))
              .fontSize(18)
              .fontColor(Color.Orange)
              .accessibilityText($r('app.string.rtl_accessibility'))
              .accessibilityDescription('RTL语言场景使用单一Resource，避免拼接错误')
          } else {
            Text('屏幕朗读已开启，当前支持' + this.messageCount + '条消息')
              .fontSize(18)
              .fontColor(Color.Purple)
              .accessibilityText('屏幕朗读功能已激活，系统显示当前支持3条消息朗读')
              .accessibilityDescription('LTR语言场景可安全拼接数字信息')
          }
        }
        
        Divider()
        
        Button('切换语言')
          .onClick(() => {
            this.toggleLanguage();
          })
          .accessibilityText('切换应用语言按钮')
          .accessibilityDescription('点击此按钮可切换应用界面语言，无障碍文本将同步更新')
        
        Text(`当前语言：${this.currentLanguage} (${this.isRTL ? 'RTL' : 'LTR'})`)
          .fontSize(16)
          .fontColor(Color.Gray)
          .accessibilityText(`当前应用语言为${this.currentLanguage}，文本方向为${this.isRTL ? '从右到左' : '从左到右'}`)
      }
      .width('100%')
      .padding(20)
    }
    .title('多语种无障碍示例')
    .mode(NavDestinationMode.STANDARD)
  }
  
  private checkLanguageDirection(language: string): boolean {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    const langCode = language.split('-')[0];
    return rtlLanguages.includes(langCode);
  }
  
  private toggleLanguage(): void {
    const languages = ['zh-CN', 'en-US', 'ar-SA'];
    const currentIndex = languages.indexOf(this.currentLanguage);
    const nextIndex = (currentIndex + 1) % languages.length;
    this.currentLanguage = languages[nextIndex];
    this.isRTL = this.checkLanguageDirection(this.currentLanguage);
    
    console.info(`Language switched to ${this.currentLanguage}, RTL: ${this.isRTL}`);
  }
}