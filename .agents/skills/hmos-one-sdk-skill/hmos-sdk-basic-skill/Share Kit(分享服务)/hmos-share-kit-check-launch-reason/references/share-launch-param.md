# 判断应用是否被系统分享拉起
---
# 判断应用是否被系统分享拉起
从5.1.0(18)版本开始，支持应用判断是否被系统分享拉起。
作为目标应用接入系统分享时，当应用被拉起，需要判断本次启动原因是被系统分享拉起的，以便处理对应的分享业务。
-
通过 [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 处理分享内容时，可使用 [onCreate](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 或 [onNewWant](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 的 [LaunchParam.launchReasonMessage](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-abilityconstant.md) 字段是否为'ReasonMessage_SystemShare'判断。
-
通过 [UIExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md) 处理分享内容时，可使用 [onCreate](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md) 的 [LaunchParam.launchReasonMessage](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-abilityconstant.md) 字段是否为'ReasonMessage_SystemShare'判断。
#### 示例代码
-
通过 [UIAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 处理分享内容。
```typescript
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
export default class ShareUIAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      console.info('被拉起原因：系统分享');
    }
  }
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      console.info('被拉起原因：系统分享');
    }
  }
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/ShareUIPage'); // 此路径仅为示例 请替换实际路径
  }
}
```
-
通过 [UIExtensionAbility](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md) 处理分享内容。
```typescript
import { AbilityConstant, ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      console.info('被拉起原因：系统分享');
    }
  }
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    session.loadContent('pages/ShareExtDialog'); // 此路径仅为示例 请替换实际路径
  }
}
```