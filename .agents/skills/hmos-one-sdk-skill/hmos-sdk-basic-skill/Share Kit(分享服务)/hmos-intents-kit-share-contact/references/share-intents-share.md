# 共享联系人信息到分享推荐区
---
# 共享联系人信息到分享推荐区
通过意图框架服务，目标应用可以将联系人信息共享到分享推荐区。参考： [习惯推荐-接入方案](D:/code/APIDevice/output/md_output/harmonyos-guides/AI/Intents Kit（意图框架服务）/习惯推荐方案/接入方案/intents-habit-rec-access-programme.md) 。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/a5/v3/ZRJTkaeJTL6_nNMSu491wA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105317Z&HW-CC-Expire=86400&HW-CC-Sign=93F3929FC141A7D39432D6EA9C2336F7A9295826B878F456F887599DD0E6EDF2)
该示例代码无法直接运行，需要申请意图框架白名单。参见： [Intents Kit接入流程](D:/code/APIDevice/output/md_output/harmonyos-guides/AI/Intents Kit（意图框架服务）/Intents Kit接入流程/intents-access-flow.md) 。
#### 开发步骤
1.
导入相关模块。
```typescript
import BuildProfile from 'BuildProfile';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { insightIntent } from '@kit.IntentsKit';
```
2.
目标应用构造联系人数据。
```typescript
const intent: insightIntent.InsightIntent = {
  intentName: 'SendMessage', // 意图名
  intentVersion: '1.0', // 意图版本
  identifier: util.generateRandomUUID(), // 意图标识符
  intentActionInfo: { // 意图执行信息
    actionMode: 'EXECUTED', // 动作模式
    executedTimeSlots: { // 实际发生时间段
      executedStartTime: new Date().getTime(),
      executedEndTime: new Date().getTime(),
    }
  },
  intentEntityInfo: { // 意图实体信息
    entityId: 'this-is-id', // 实体Id
    entityName: 'Contact', // 实体名称
    name: 'Nickname', // 联系人昵称
    icon: 'data:image/png;base64,...', // 联系人头像
    phoneNumbers: [], // 联系人电话号码
    extras: {
      shareParams: {
        bundleName: BuildProfile.BUNDLE_NAME, // 应用包名
        moduleName: 'entry', // 应用模块名 根据实际填写
        abilityName: 'SampleContactAbility', // 应用ability名 根据实际填写
        action: 'ohos.want.action.sendData', // 标识分享 不可修改
      }
    }
  }
};
```
3.
目标应用共享联系人数据。
```typescript
let uiContext: UIContext = this.getUIContext();
let context: Context = uiContext.getHostContext() as Context;
insightIntent.shareIntent(context, [intent]).then(() => {
  console.info('shareIntent ok');
}).catch((err: BusinessError) => {
  console.error(`shareIntent failed. Code: ${err.code}. message: ${err.message}`);
});
```