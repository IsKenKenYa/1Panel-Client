import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';

const TAG: string = 'CustomShortcut';
const DOMAIN: number = 0x0001;

@Entry
@Component
struct CustomShortcutExample {
  @State checkShortcutResult: productViewManager.CheckShortcutResult | null = null;
  @State message: string = '';
  @State shortcutLabel: string = '我的快捷方式';

  build() {
    Column({ space: 16 }) {
      Text('自定义资源方式创建桌面快捷方式')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      TextInput({ placeholder: '快捷方式名称' })
        .width('80%')
        .onChange((value: string) => {
          this.shortcutLabel = value;
        })
      
      Button('校验快捷方式')
        .width('80%')
        .onClick(() => {
          this.checkShortcut();
        })
      
      Button('创建快捷方式')
        .width('80%')
        .enabled(this.checkShortcutResult !== null && this.checkShortcutResult.code === 0)
        .onClick(() => {
          this.createShortcut();
        })
      
      Text(this.message)
        .fontSize(14)
        .fontColor('#333333')
        .width('80%')
    }
    .width('100%')
    .padding(16)
    .justifyContent(FlexAlign.Center)
  }

  prepareIconFile(): string {
    const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const iconPath = uiContext.filesDir + '/shortcut_icon.png';
    
    return iconPath;
  }

  checkShortcut() {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const shortcutId = `shortcut_${Date.now()}`;
      
      const want: Want = {
        bundleName: "com.example.appgallery.kit.demo",
        moduleName: "entry",
        abilityName: "EntryAbility",
        parameters: {
          testKey: "testValue"
        }
      };

      const label = this.shortcutLabel;
      const foregroundIcon = this.prepareIconFile();
      const backgroundIcon = "";

      if (label.length > 255) {
        this.message = '快捷方式名称长度不能超过255个字符';
        return;
      }

      productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, label, foregroundIcon, backgroundIcon)
        .then((result: productViewManager.CheckShortcutResult) => {
          this.checkShortcutResult = result;
          hilog.info(DOMAIN, TAG, `校验成功: ${JSON.stringify(result)}`);
          
          if (result.code === 0) {
            this.message = `校验成功，剩余可添加数量: ${result.limit}\n请点击"创建快捷方式"按钮`;
          } else {
            this.message = `校验失败，错误码: ${result.code}`;
          }
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN, TAG, `校验失败: ${error.code}, ${error.message}`);
          this.message = `校验失败: ${error.message}`;
        });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `异常: ${(err as BusinessError).code}, ${(err as BusinessError).message}`);
      this.message = `异常: ${(err as BusinessError).message}`;
    }
  }

  createShortcut() {
    if (!this.checkShortcutResult) {
      this.message = '请先校验快捷方式';
      return;
    }

    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const tid = this.checkShortcutResult.tid;

      productViewManager.requestNewPinShortcut(uiContext, tid)
        .then(() => {
          hilog.info(DOMAIN, TAG, `快捷方式创建成功`);
          this.message = '快捷方式创建成功！';
          this.checkShortcutResult = null;
        })
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN, TAG, `创建失败: ${error.code}, ${error.message}`);
          
          switch (error.code) {
            case 1006620006:
              this.message = '快捷方式未校验或已过期，请重新校验';
              this.checkShortcutResult = null;
              break;
            case 1006620007:
              this.message = '用户拒绝添加快捷方式';
              break;
            case 1006620004:
              this.message = '快捷方式数量已达上限（最多2个）';
              break;
            default:
              this.message = `创建失败: ${error.message}`;
          }
        });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `异常: ${(err as BusinessError).code}, ${(err as BusinessError).message}`);
      this.message = `异常: ${(err as BusinessError).message}`;
    }
  }
}