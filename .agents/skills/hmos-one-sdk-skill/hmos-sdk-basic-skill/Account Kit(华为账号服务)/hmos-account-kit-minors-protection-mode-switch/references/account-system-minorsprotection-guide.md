# 应用与系统联动切换未成年人模式
---
# 应用与系统联动切换未成年人模式
#### 场景介绍
在未成年人模式下，应用可通过以下两种方式获取系统未成年人模式状态，与系统未成年人模式进行联动：
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c1/v3/I5gDhzrnTKCgy3zcoNYh3Q/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105123Z&HW-CC-Expire=86400&HW-CC-Sign=658FA5B13E07293E647869FD3319915F6702E911480A79A2FD78AD41ECF8F50F)
以下两种方式都需要应用实现，如开发者不实现订阅系统未成年人模式公共事件，则应用无法实时感知系统未成年人模式的变化。
示例：当应用处于前台时，若开发者未实现订阅系统未成年人模式公共事件，用户从控制中心开启未成年人模式后，当前应用将无法实时感知系统未成年人模式的变化。
1.
查询系统的未成年人模式是否开启：应用启动时，可调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 接口，主动查询系统的未成年人模式状态；如系统未成年人模式为开启状态，则应自动开启应用的未成年人模式；如系统未成年人模式为关闭状态，则应自动关闭应用的未成年人模式。
2.
订阅 [系统未成年人模式公共事件](#事件说明) 感知系统的未成年人模式状态：应用进程存在时，可订阅系统的未成年人模式公共事件，当订阅到系统未成年人模式开启或关闭时，应用可自动进行未成年人模式状态切换。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9f/v3/qP0BqeGDQbi0g8-DOdgwiA/zh-cn_image_0000002659100779.png?HW-CC-KV=V1&HW-CC-Date=20260701T105123Z&HW-CC-Expire=86400&HW-CC-Sign=751A4A6C8FCDBF2A62790BD3A6D0A3299EBC0575E1115D580920C0CE52D648C0)
流程说明：
1.
用户打开应用时，应用通过订阅 [系统未成年人模式公共事件](#事件说明) 感知系统未成年人模式的状态变化。如果订阅到系统未成年人模式开启事件，则开启应用的未成年人模式，如果订阅到系统未成年人模式关闭事件，则展示内容不做限制，并关闭应用的未成年人模式。
2.
调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 或 [getMinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 获取系统未成年人模式的开启状态和年龄段信息，如果系统未成年人模式未开启，则展示内容不做限制。如果系统未成年人模式已开启，则需要根据返回的年龄段做内容分级，而且需开启应用的未成年人模式。
#### 接口说明
以下是应用与系统联动切换未成年人模式的相关接口说明，更多接口及使用方法请参见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 。
| 接口名 | 描述 |
| --- | --- |
| [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)():[MinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) | 同步接口，获取系统未成年人模式的开启状态，以及年龄段信息。 |
| [getMinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)(): Promise<[MinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)> | 异步接口，获取系统未成年人模式的开启状态，以及年龄段信息。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/61/v3/JqwtBxGIQvS4g63S1aRpOQ/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105123Z&HW-CC-Expire=86400&HW-CC-Sign=362EB76EE88CA542C468827BA29EFA24CE180C999A3280412D487195FA9B4290)
1.
当未成年人模式开启时，当前设备的开发者调试模式会被禁用，开发者可以进入设置-系统-开发者选项，点击USB调试开关，会校验健康使用设备密码，校验成功后可解除开发者调试模式限制。
2.
如开发者重新开启USB调试开关后，发现DevEco Studio工具上hilog日志未恢复到断连之前，请执行“hdc shell hilog -G 16M”来扩大hilog日志缓存区，若hilog日志仍无法完全展示，可取出hilog日志本地查看。更多命令请参见 [hilog](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/调测调优/调试命令/hilog/hilog.md) 。
3.
如开发者需要频繁使用未成年人模式开启状态或者年龄段信息，建议在获取结果后进行缓存，并通过订阅 [系统未成年人模式公共事件](#事件说明) 来刷新未成年人模式开启状态或者年龄段信息，避免重复调用接口带来的性能损耗。
4.
当设备处于开机未解锁状态下，开发者调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 接口时，其返回的minorsProtectionMode字段为false。
#### 事件说明
以下是系统未成年人模式开启或关闭发送的广播事件。
| 事件名称 | 值 | 描述 |
| --- | --- | --- |
| [COMMON_EVENT_MINORSMODE_ON](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/进程线程通信/commoneventmanager-definitions.md) | usual.event.MINORSMODE_ON | 表示系统未成年人模式开启事件。 |
| [COMMON_EVENT_MINORSMODE_OFF](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/进程线程通信/commoneventmanager-definitions.md) | usual.event.MINORSMODE_OFF | 表示系统未成年人模式关闭事件。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/15/v3/QQqrDgWeRJ-e0KiJsSIrIw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105123Z&HW-CC-Expire=86400&HW-CC-Sign=83D278D32083B1560C0409CE371482BC55595864718C6D5C1D904D091593378F)
未成年人模式开启事件触发时机：
主动开启系统未成年人模式（PC/2in1设备暂不支持从控制中心开启未成年人模式），当前设备会发送未成年人模式开启事件。
#### 开发前提
请先参考“开发准备”的 [配置签名和指纹](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/开发准备/配置签名和指纹/account-sign-fingerprints.md) 章节，通过自动签名方式完成签名信息的配置。请注意，该接口无需配置公钥指纹、Client ID，也无需申请账号权限。
#### 开发步骤
1.
导入 [minorsProtection](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 模块及相关公共模块。
```typescript
import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```
2.
创建订阅者，订阅系统未成年人模式开启或关闭事件。推荐在应用Ability的 [onCreate](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 生命周期中调用。
```typescript
// 订阅者信息
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON,
    commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF]
};
// 定义订阅者，如开发者使用await改写createSubscriber方法，需要把此变量定义到全局(struct外层)
let subscriber: commonEventManager.CommonEventSubscriber | null = null;
// 创建订阅者
commonEventManager.createSubscriber(subscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    // 这里获取到commonEventSubscriber对象需要暂存，用于后续事件回调。不可直接使用，否则会出现事件回调不生效的情况
    subscriber = commonEventSubscriber;
    // 订阅公共事件
    commonEventManager.subscribe(subscriber,
      (error: BusinessError, data: commonEventManager.CommonEventData) => {
        if (error) {
          dealCommonEventAllError(error);
          return;
        }
        if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON) {
          // 订阅到开启事件，可以调用获取年龄段的接口，根据年龄段刷新内容展示，同时如开发者有缓存年龄段或未成年人模式开启状态，则需要刷新缓存
          return;
        }
        if (data.event === commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF) {
          // 订阅到关闭事件，关闭当前应用的未成年人模式，刷新应用内容展示，取消年龄限制，如开发者有缓存未成年人模式开启状态，则需要刷新缓存
        }
      });
  })
  .catch((error: BusinessError) => {
    dealCommonEventAllError(error);
  });
```
```typescript
function dealCommonEventAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to subscribe. Code: ${error.code}, message: ${error.message}`);
}
```
3.
选择以下一种方式获取未成年人模式的开启状态，以及年龄段信息。当应用期望立即获取结果，推荐使用同步方式，当应用期望使用非阻塞的方式调用接口，推荐使用Promise异步回调方式。推荐在自定义组件的 [aboutToAppear](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/ArkUI（方舟UI框架）/ArkTS组件/自定义组件/ts-custom-component-lifecycle.md) 生命周期或者应用Ability的 [onCreate](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md) 生命周期中调用，如开发者有频繁使用到未成年人模式开启状态或年龄段信息，开发者则需把获取到的系统未成年人模式开启状态或年龄段缓存下来，通过订阅 [系统未成年人模式公共事件](#事件说明) 来刷新未成年人模式开启状态或年龄段。
-
通过同步方式，调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 获取系统未成年人模式的开启状态，以及年龄段信息。
```
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    // 查询是否支持系统未成年人模式
    if (minorsProtection.supportMinorsMode()) {
      const minorsProtectionInfo: minorsProtection.MinorsProtectionInfo =
        minorsProtection.getMinorsProtectionInfoSync();
      // 获取未成年人模式开启状态
      const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
      // 如开发者有频繁使用到未成年人模式开启状态，这里则需缓存未成年人模式开启状态
      hilog.info(0x0000, 'testTag',
        `Succeeded in getting minorsProtectionMode is: ${minorsProtectionMode.valueOf()}`);
      // 未成年人模式已开启，获取年龄段信息
      // ...
      if (minorsProtectionMode) {
        const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          hilog.info(0x0000, 'testTag', `Succeeded in getting lowerAge is: ${ageGroup.lowerAge}`);
          hilog.info(0x0000, 'testTag', `Succeeded in getting upperAge is: ${ageGroup.upperAge}`);
          // 根据年龄段刷新内容展示。如开发者有频繁使用到年龄段信息，这里则需缓存年龄段信息
          // ...
        }
      } else {
        // 未成年人模式未开启，应用需跟随系统未成年人模式，展示内容不做限制
        // ...
      }
    } else {
      hilog.info(0x0000, 'testTag',
        'The current device environment does not support the youth mode, please check the current device environment.');
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to invoke supportMinorsMode or getMinorsProtectionInfoSync. errCode: ${error.code},
      errMessage: ${error.message}`);
  }
} else {
  hilog.info(0x0000, 'testTag',
    'The current device does not support the invoking of the getMinorsProtectionInfoSync interface.');
}
```
-
通过Promise异步回调方式，调用 [getMinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 获取系统未成年人模式的开启状态，以及年龄段信息。
```typescript
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    // 查询是否支持系统未成年人模式
    if (minorsProtection.supportMinorsMode()) {
      minorsProtection.getMinorsProtectionInfo()
        .then((minorsProtectionInfo: minorsProtection.MinorsProtectionInfo) => {
          // 获取未成年人模式开启状态
          const minorsProtectionMode: boolean = minorsProtectionInfo.minorsProtectionMode;
          // 如开发者有频繁使用到未成年人模式开启状态，这里则需缓存未成年人模式开启状态
          hilog.info(0x0000, 'testTag',
            `Succeeded in getting minorsProtectionMode is: ${minorsProtectionMode.valueOf()}`);
          // 未成年人模式已开启，获取年龄段信息
          if (minorsProtectionMode) {
            const ageGroup: minorsProtection.AgeGroup | undefined = minorsProtectionInfo.ageGroup;
            if (ageGroup) {
              hilog.info(0x0000, 'testTag', `Succeeded in getting lowerAge is: ${ageGroup.lowerAge}`);
              hilog.info(0x0000, 'testTag', `Succeeded in getting upperAge is: ${ageGroup.upperAge}`);
              // 根据年龄段刷新内容展示。如开发者有频繁使用到年龄段信息，这里则需缓存年龄段信息
            }
          } else {
            // 未成年人模式未开启，应用需跟随系统未成年人模式，展示内容不做限制
          }
        })
        .catch((error: BusinessError<Object>) => {
          dealGetMinorsInfoAllError(error);
        });
    } else {
      hilog.info(0x0000, 'testTag',
        'The current device environment does not support the youth mode, please check the current device environment.');
    }
  } catch (error) {
    hilog.error(0x0000, 'testTag',
      `Failed to invoke supportMinorsMode. errCode: ${error.code}, errMessage: ${error.message}`);
  }
} else {
  hilog.info(0x0000, 'testTag',
    'The current device does not support the invoking of the getMinorsProtectionInfo interface.');
}
```
```typescript
function dealGetMinorsInfoAllError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', `Failed to getMinorsProtectionInfo. Code: ${error.code}, message: ${error.message}`);
}
```