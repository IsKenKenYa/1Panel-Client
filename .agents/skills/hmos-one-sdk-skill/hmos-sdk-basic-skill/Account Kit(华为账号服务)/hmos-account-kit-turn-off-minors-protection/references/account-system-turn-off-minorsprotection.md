# 关闭系统的未成年人模式
---
# 关闭系统的未成年人模式
#### 场景介绍
系统的未成年人模式已开启。用户打开应用，在应用内关闭系统未成年人模式。
应用可调用系统的未成年人模式关闭接口 [leadToTurnOffMinorsMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) ，验证家长密码后关闭系统的未成年人模式。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/63/v3/Xkq0T3xkRC2XJLQDK4w17g/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105124Z&HW-CC-Expire=86400&HW-CC-Sign=8EF3C2D54F827078378E04291AA6A1468B28E996FDA1FAB1A408AA759639D793)
用户在应用内操作时，预期可能是关闭应用的未成年人模式，而非关闭整个系统的未成年人模式（其他应用/元服务的未成年人模式也会随之关闭）。如果开发者选择这种接入方式，建议在界面上告知用户即将关闭系统的未成年人模式。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/08/v3/-i2ruy9MRNicTGBnFuBP5w/zh-cn_image_0000002628701552.png?HW-CC-KV=V1&HW-CC-Date=20260701T105124Z&HW-CC-Expire=86400&HW-CC-Sign=FB735C0F039A35330043DE9E21C89F97EFEA99F949409A66CB6AC77F179AC9DE)
流程说明：
1.
用户打开应用时，应用通过订阅 [系统未成年人模式公共事件](#事件说明) 感知未成年人模式的状态变化。可以调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 或 [getMinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 获取系统未成年人模式信息。
2.
当系统未成年人模式已开启，且用户需要在应用内关闭未成年人模式时，应用可调用 [leadToTurnOffMinorsMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 引导关闭系统未成年人模式流程，关闭整个系统的未成年人模式。
#### 接口说明
以下是关闭系统的未成年人模式相关接口说明，更多接口及使用方法请参见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 。
| 接口名 | 描述 |
| --- | --- |
| [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)():[MinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) | 同步接口，获取系统未成年人模式的开启状态，以及年龄段信息。 |
| [getMinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)(): Promise<[MinorsProtectionInfo](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)> | 异步接口，获取系统未成年人模式的开启状态，以及年龄段信息。 |
| [leadToTurnOffMinorsMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md)(context:[common.Context](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-common.md)): Promise<void> | 调用该方法进行关闭系统未成年人模式流程。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ce/v3/5FRhff0vSAm4T_hO-f7HQA/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105124Z&HW-CC-Expire=86400&HW-CC-Sign=261DEF1E91F220113BA20155AA2C3A6BB2C141F371BD12A51857DEE02DA1BFA5)
1.
[leadToTurnOffMinorsMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 接口需在页面或自定义组件生命周期内调用。
2.
当未成年人模式开启时，当前设备的开发者调试模式会被禁用，开发者可以进入设置-系统-开发者选项，点击USB调试开关，会校验健康使用设备密码，校验成功后可解除开发者调试模式限制。
3.
如开发者重新开启USB调试开关后，发现DevEco Studio工具上hilog日志未恢复到断连之前，请执行“hdc shell hilog -G 16M”来扩大hilog日志缓存区，若hilog日志仍无法完全展示，可取出hilog日志本地查看。更多命令请参见 [hilog](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/调测调优/调试命令/hilog/hilog.md) 。
4.
在应用内调用开启或关闭系统未成年人模式接口，如应用需弹出toast或弹框告知用户“未成年人模式已开启或关闭”，须在接口执行完成之后，在接口的then方法里面弹出toast或弹框，否则可能出现因系统页面未完全关闭，导致toast无法正常展示的情况。
5.
如开发者需要频繁使用未成年人模式开启状态或者年龄段信息，建议在获取结果后进行缓存，并通过订阅 [系统未成年人模式公共事件](#事件说明) 来刷新未成年人模式开启状态或者年龄段信息，避免重复调用接口带来的性能损耗。
6.
当设备处于开机未解锁状态下，开发者调用 [getMinorsProtectionInfoSync](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 接口时，其返回的minorsProtectionMode字段为false。
#### 事件说明
以下是系统未成年人模式开启或关闭发送的广播事件。
| 事件名称 | 值 | 描述 |
| --- | --- | --- |
| [COMMON_EVENT_MINORSMODE_ON](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/进程线程通信/commoneventmanager-definitions.md) | usual.event.MINORSMODE_ON | 表示系统未成年人模式开启事件。 |
| [COMMON_EVENT_MINORSMODE_OFF](D:/code/APIDevice/output/md_output/harmonyos-references/系统/基础功能/Basic Services Kit（基础服务）/ArkTS API/进程线程通信/commoneventmanager-definitions.md) | usual.event.MINORSMODE_OFF | 表示系统未成年人模式关闭事件。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/47/v3/fuv5IksBRCmesSpkl3tcSA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105124Z&HW-CC-Expire=86400&HW-CC-Sign=343FBC5534DDE1D6EA8D53E70FD204EDF51E2C4836A659BBF12C737E0903CBDF)
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
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
订阅系统未成年人模式开启或关闭事件、获取未成年人模式的开启状态，以及年龄段信息请参考应用与系统联动切换未成年人模式章节的 [开发步骤](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/未成年人模式/应用与系统实现未成年人模式联动/应用与系统联动切换未成年人模式/account-system-minorsprotection.md) 。
3.
当系统未成年人模式已开启，且用户主动关闭应用内未成年人模式时，应用需要调用 [leadToTurnOffMinorsMode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-minorsprotection.md) 引导用户关闭系统的未成年人模式。
```typescript
if (canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
  try {
    // 查询是否支持系统未成年人模式
    if (minorsProtection.supportMinorsMode()) {
      // 此示例为代码片段，实际需在自定义组件实例中使用，并传入有效的Context上下文对象
      minorsProtection.leadToTurnOffMinorsMode(this.getUIContext().getHostContext())
        .then(() => {
          // 接口调用完成，如需显示弹窗，请在此处处理
        })
        .catch((error: BusinessError<Object>) => {
          dealTurnOffAllError(error);
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
    'The current device does not support the invoking of the leadToTurnOffMinorsMode interface.');
}
```
```typescript
function dealTurnOffAllError(error: BusinessError<Object>): void {
  hilog.error(0x0000, 'testTag', `Failed to leadToTurnOffMinorsMode. Code: ${error.code}, message: ${error.message}`);
}
```