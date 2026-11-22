# 登记归因来源及转化
---
# 登记归因来源及转化
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ba/v3/nxh-awY7Qy-oNtKy3Pj_jQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105138Z&HW-CC-Expire=86400&HW-CC-Sign=FB24005D7CCFB851C3A5CA92922D3FC18FB10B2D27697264B0B850F624F19037)
6.0.2(22)版本开始，登记归因转化接口新增属性timestamp、serviceTag，支持设置转化事件时间及开发者关注的业务信息。
#### 场景介绍
应用归因服务为媒体App、分发平台提供向端侧应用归因服务登记归因来源（即应用曝光点击事件）、开发者应用登记转化事件的能力。
端侧应用归因服务根据媒体应用登记的归因来源，以及开发者应用登记的转化事件，按照系统规则，在端侧完成归因计算。
#### 接口说明
应用归因服务场景提供以下接口，具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-attributionmanager.md) 。
| 接口名 | 描述 |
| --- | --- |
| registerSource(adSourceInfo: AdSourceInfo): Promise<void> | 登记归因来源信息接口。 |
| registerTrigger(adTriggerInfo: AdTriggerInfo): Promise<void> | 登记归因转化信息接口。 |
#### 开发步骤
#### 登记归因来源
1.
导入相关模块。
```typescript
import { attributionManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError,deviceInfo } from '@kit.BasicServicesKit';
```
2.
构造参数 [AdSourceInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-attributionmanager.md) 。
```typescript
const adSourceInfo: attributionManager.AdSourceInfo = {
  // 在应用归因云侧注册应用生态伙伴角色时，由应用归因服务分配
  adTechId: '20****e8',
  campaignId: '',
  // 开发者应用上架华为应用市场的appId，不带C
  destinationId: '10******',
  sourceType: attributionManager.SourceType.IMPRESSION,
  // 归因监测平台id
  mmpIds: ['2f****5','2f7***5'],
  // 分发平台关注的业务信息
  serviceTag: '123***2',
  // 用于计算签名的随机数，不带'-'
  nonce: '123***2',
  timestamp: Date.now(),
  // 签名值
  signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg=='
};
let osApiVersion: number = deviceInfo.sdkApiVersion;
if (osApiVersion >= 22) {
  adSourceInfo.campaignId = '1*******9';
} else {
  adSourceInfo.campaignId = '1****6';
}
```
3.
调用 [attributionManager.registerSource](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-attributionmanager.md) 方法登记归因来源信息。
```typescript
try {
  attributionManager.registerSource(adSourceInfo).then(() => {
    hilog.info(0, 'TAG', 'Succeeded in registering source.');
  }).catch((error: BusinessError) => {
    hilog.error(0, 'TAG', `registerSource error.code is ${error.code}, message is ${error.message}`);
  })
} catch (error) {
  hilog.error(0, 'TAG', `registerSource error.code is ${error.code}, message is ${error.message}`);
}
```
#### 登记归因转化
1.
导入相关模块。
```typescript
import { attributionManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError,deviceInfo } from '@kit.BasicServicesKit';
```
2.
构造参数 [AdTriggerInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-attributionmanager.md) 。
```typescript
const adTriggerInfo: attributionManager.AdTriggerInfo = {
  businessScene: 5,
  // 转化事件编码，从应用归因云端管理平台获取
  triggerData: 123
};
let osApiVersion: number = deviceInfo.sdkApiVersion;
if (osApiVersion >= 22) {
  // Since API 22, added the actual occurrence time parameter.
  adTriggerInfo.timestamp = Date.now();
  adTriggerInfo.serviceTag = 'testServiceTag';
}
```
3.
调用 [attributionManager.registerTrigger](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/AppGallery Kit（应用市场服务）/ArkTS API/store-attributionmanager.md) 方法登记转化信息。
```typescript
try {
  attributionManager.registerTrigger(adTriggerInfo).then(() => {
    hilog.info(0, 'TAG', 'Succeeded in registering triggerdata.');
  }).catch((error: BusinessError) => {
    hilog.error(0, 'TAG', `registerTrigger error.code is ${error.code}, message is ${error.message}`);
  })
} catch (error) {
  hilog.error(0, 'TAG', `registerTrigger error.code is ${error.code}, message is ${error.message}`);
}
```