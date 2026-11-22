/**
 * 应用偏好语言完整示例
 * 功能: 获取、设置和清除应用偏好语言
 * API版本: getAppPreferredLanguage (API 9+), setAppPreferredLanguage (API 11+)
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';

@Entry
@Component
struct AppPreferredLanguageExample {
  @State currentLanguage: string = '';
  @State message: string = '';
  @State supportedLanguages: string[] = [];

  aboutToAppear() {
    // 应用启动时获取当前语言
    this.getCurrentLanguage();
    // 获取系统支持的语言列表
    this.getSupportedLanguages();
  }

  // 获取应用当前偏好语言
  getCurrentLanguage() {
    try {
      this.currentLanguage = i18n.System.getAppPreferredLanguage();
      this.message = `当前应用语言: ${this.currentLanguage}`;
      
      if (this.currentLanguage === 'default') {
        this.message += '\n(跟随系统语言)';
      } else {
        this.message += '\n(应用偏好语言)';
      }
      
      console.info(`[AppLanguage] 当前应用语言: ${this.currentLanguage}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AppLanguage] 获取语言失败, 错误码: ${err.code}, 错误信息: ${err.message}`);
      this.message = `获取失败: ${err.message}`;
    }
  }

  // 设置应用偏好语言
  setLanguage(language: string) {
    try {
      if (!language || language.trim() === '') {
        this.message = '错误: 语言参数不能为空';
        return;
      }

      i18n.System.setAppPreferredLanguage(language);
      console.info(`[AppLanguage] 设置语言成功: ${language}`);
      
      this.message = `设置成功: ${language}`;
      if (language !== 'default') {
        this.message += '\n请重启应用使语言设置生效';
      } else {
        this.message += '\n应用语言将跟随系统语言\n请重启应用生效';
      }
      
      // 刷新当前语言显示
      this.getCurrentLanguage();
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AppLanguage] 设置语言失败, 错误码: ${err.code}, 错误信息: ${err.message}`);
      
      // 错误码处理
      if (err.code === 401) {
        this.message = '参数错误: 请使用合法的语言ID格式\n如: zh-Hans, en-US, default';
      } else if (err.code === 890001) {
        this.message = '语言不支持: 请使用系统支持的语言';
      } else {
        this.message = `设置失败: ${err.message}`;
      }
    }
  }

  // 获取系统支持的语言列表
  getSupportedLanguages() {
    try {
      this.supportedLanguages = i18n.System.getSystemLanguages();
      console.info(`[AppLanguage] 系统支持的语言: ${this.supportedLanguages.join(', ')}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AppLanguage] 获取支持语言失败: ${err.message}`);
    }
  }

  // 清除应用偏好语言(跟随系统)
  clearLanguage() {
    this.setLanguage('default');
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('应用偏好语言管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      // 当前语言显示
      Column({ space: 10 }) {
        Text('当前应用语言')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        
        Text(this.currentLanguage || '未获取')
          .fontSize(16)
          .fontColor('#0066CC')
        
        Text(this.message)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(5)
      }
      .width('90%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)

      // 语言设置按钮
      Column({ space: 10 }) {
        Text('语言设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Row({ space: 10 }) {
          Button('简体中文')
            .onClick(() => this.setLanguage('zh-Hans'))
            .width(100)
          
          Button('英语')
            .onClick(() => this.setLanguage('en-US'))
            .width(100)
          
          Button('跟随系统')
            .onClick(() => this.clearLanguage())
            .width(100)
        }

        Button('刷新当前语言')
          .onClick(() => this.getCurrentLanguage())
          .width('90%')
          .backgroundColor('#4CAF50')
      }
      .width('90%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)

      // 支持的语言列表
      Column({ space: 10 }) {
        Text('系统支持的语言')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        if (this.supportedLanguages.length > 0) {
          List({ space: 5 }) {
            ForEach(this.supportedLanguages.slice(0, 10), (lang: string) => {
              ListItem() {
                Text(lang)
                  .fontSize(14)
                  .onClick(() => this.setLanguage(lang))
                  .padding(10)
                  .backgroundColor('#E8E8E8')
                  .borderRadius(5)
                  .width('100%')
              }
            })
          }
          .width('100%')
          .height(200)
        }
      }
      .width('90%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(10)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}