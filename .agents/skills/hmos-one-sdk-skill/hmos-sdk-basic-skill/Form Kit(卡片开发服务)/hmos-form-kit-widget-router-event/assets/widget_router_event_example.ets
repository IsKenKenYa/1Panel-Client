// =====================================================
// 完整示例：动态卡片跳转到应用UIAbility页面（router事件）
// =====================================================

// 1. 卡片页面代码
// 文件路径：src/main/ets/widgeteventrouter/pages/WidgetEventRouterCard.ets

@Entry
@Component
struct WidgetEventRouterCard {
  build() {
    Column() {
      // 卡片标题
      Text($r('app.string.JumpLabel'))
        .fontColor('#FFFFFF')
        .opacity(0.9)
        .fontSize(14)
        .margin({ top: '8%', left: '10%' })
      
      // 按钮容器
      Row() {
        Column() {
          // FunA按钮
          Button() {
            Text($r('app.string.ButtonA_label'))
              .fontColor('#45A6F4')
              .fontSize(12)
          }
          .width(120)
          .height(32)
          .margin({ top: '20%' })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            // 调用postCardAction发送router事件到FunA页面
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetPage: 'funA' }
            });
          })
          
          // FunB按钮
          Button() {
            Text($r('app.string.ButtonB_label'))
              .fontColor('#45A6F4')
              .fontSize(12)
          }
          .width(120)
          .height(32)
          .margin({ top: '8%', bottom: '15vp' })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            // 调用postCardAction发送router事件到FunB页面
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetPage: 'funB' }
            });
          })
        }
      }
      .width('100%')
      .height('80%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundImage($r('app.media.CardEvent'))
    .backgroundImageSize(ImageSize.Cover)
  }
}

// =====================================================

// 2. UIAbility处理代码
// 文件路径：src/main/ets/entryability/EntryAbility.ts

import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  // 保存目标页面参数
  private selectPage: string = 'funA';
  // 保存windowStage实例
  private currentWindowStage: window.WindowStage | null = null;

  // UIAbility首次创建时触发
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, `Ability onCreate, ${JSON.stringify(want)}`);
    
    // 解析router事件传递的参数
    try {
      if (want?.parameters?.params) {
        // want.parameters.params对应postCardAction中的params内容
        let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
        this.selectPage = params.targetPage as string;
        hilog.info(DOMAIN_NUMBER, TAG, `onCreate selectPage: ${this.selectPage}`);
      }
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, 'Failed to parse params: %{public}s', 
        JSON.stringify(error) ?? '');
      this.selectPage = 'funA';
    }
  }

  // UIAbility已在后台运行，收到router事件时触发
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onNewWant Want: ${JSON.stringify(want)}`);
    
    // 解析router事件传递的参数
    try {
      if (want?.parameters?.params) {
        let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
        this.selectPage = params.targetPage as string;
        hilog.info(DOMAIN_NUMBER, TAG, `onNewWant selectPage: ${this.selectPage}`);
      }
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, 'Failed to parse params: %{public}s', 
        JSON.stringify(error) ?? '');
      this.selectPage = 'funA';
    }
    
    // 如果windowStage已创建，重新加载页面
    if (this.currentWindowStage !== null) {
      this.onWindowStageCreate(this.currentWindowStage);
    }
  }

  // 创建窗口时触发
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 根据参数选择目标页面
    let targetPage: string;
    
    switch (this.selectPage) {
      case 'funA':
        targetPage = 'funpages/FunA';
        break;
      case 'funB':
        targetPage = 'funpages/FunB';
        break;
      default:
        targetPage = 'pages/Index';
    }
    
    // 保存windowStage实例（用于onNewWant重新加载）
    if (this.currentWindowStage === null) {
      this.currentWindowStage = windowStage;
    }
    
    // 加载目标页面
    windowStage.loadContent(targetPage, (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load the content. Cause: %{public}s', 
          JSON.stringify(err) ?? '');
        
        // 加载失败时，回退到首页
        windowStage.loadContent('pages/Index', (fallbackErr, fallbackData) => {
          if (fallbackErr.code) {
            hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load fallback page');
          } else {
            hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading fallback page');
          }
        });
        return;
      }
      
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading the content. Data: %{public}s', 
        JSON.stringify(data) ?? '');
    });
  }
}

// =====================================================

// 3. FunA页面代码
// 文件路径：src/main/ets/funpages/FunA.ets

@Entry
@Component
struct FunA {
  build() {
    Column() {
      // 页面标题栏
      Row() {
        Text(($r('app.string.ButtonA_label')))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .margin({
            top: 12,
            bottom: 11,
            right: 24,
            left: 24
          })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      
      // 页面内容（示例为空状态）
      Image($r('app.media.pic_empty'))
        .width(120)
        .height(120)
        .margin({ top: 224 })
      
      Text($r('app.string.NoContentAvailable'))
        .fontSize(14)
        .fontColor($r('app.color.text_color'))
        .opacity(0.4)
        .margin({
          top: 8,
          bottom: 317,
          right: 152,
          left: 152
        })
    }
    .width('100%')
    .height('100%')
  }
}

// =====================================================

// 4. FunB页面代码
// 文件路径：src/main/ets/funpages/FunB.ets

@Entry
@Component
struct FunB {
  build() {
    Column() {
      // 页面标题栏
      Row() {
        Text(($r('app.string.ButtonB_label')))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .margin({
            top: 12,
            bottom: 11,
            right: 24,
            left: 24
          })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      
      // 页面内容（示例为空状态）
      Image($r('app.media.pic_empty'))
        .width(120)
        .height(120)
        .margin({ top: 224 })
      
      Text($r('app.string.NoContentAvailable'))
        .fontSize(14)
        .fontColor($r('app.color.text_color'))
        .opacity(0.4)
        .margin({
          top: 8,
          bottom: 317,
          right: 152,
          left: 152
        })
    }
    .width('100%')
    .height('100%')
  }
}

// =====================================================

// 5. 配置文件：main_pages.json
// 文件路径：src/main/resources/base/profile/main_pages.json

{
  "src": [
    "pages/Index",
    "funpages/FunA",
    "funpages/FunB"
  ]
}

// =====================================================

// 6. 资源文件：string.json（中文）
// 文件路径：src/main/resources/zh_CN/element/string.json

{
  "string": [
    {
      "name": "ButtonA_label",
      "value": "FunA页面"
    },
    {
      "name": "ButtonB_label",
      "value": "FunB页面"
    },
    {
      "name": "JumpLabel",
      "value": "router事件跳转"
    },
    {
      "name": "NoContentAvailable",
      "value": "暂无内容"
    },
    {
      "name": "text_color",
      "value": "#000000"
    }
  ]
}

// =====================================================

// 说明：
// 1. 将卡片代码放在entry模块的widgeteventrouter/pages目录下
// 2. 将UIAbility代码放在entry模块的entryability目录下
// 3. 将页面代码放在entry模块的funpages目录下
// 4. 将main_pages.json放在resources/base/profile目录下
// 5. 将string.json放在resources/zh_CN/element目录下
// 6. 需要在module.json5中配置卡片元数据
// 7. 需要创建FormExtensionAbility作为卡片提供方
// 8. 需要替换示例中的$r资源引用为实际资源文件