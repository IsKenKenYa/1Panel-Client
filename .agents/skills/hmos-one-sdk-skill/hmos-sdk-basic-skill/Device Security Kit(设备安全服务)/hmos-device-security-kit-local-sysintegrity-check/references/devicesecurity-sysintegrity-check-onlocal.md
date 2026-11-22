# 本地系统完整性检测
---
# 本地系统完整性检测
#### 场景介绍
在不接入服务端的场景下，应用通过调用Device Security Kit的checkSysIntegrityOnLocal接口获取系统完整性检测结果，用于判断设备环境是否安全，比如是否被越狱、非真实设备等。
应用可以根据检测结果评估如何进行业务操作。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4/v3/5zlc_naoQw6_h2ucgGZRUA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=D08764FD8821A4B5643EB30331DB9334D755D10140B997BA178B414FBD742F89)
-
系统完整性检测结果可以用作系统整体安全的一个环节，需要考虑检测结果误报带来的风险以及给用户带来的影响，不建议将系统完整性检测结果作为判断当前设备是否安全的唯一依据，更好的做法是通过额外的步骤降低风险。
-
该功能仅在无法接入服务端的场景下使用。
#### 约束与限制
- 本地系统完整性检测能力支持Phone、Tablet、PC/2in1、Wearable设备。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/af/v3/b8AoBnVMQp-UPlzjvp8Bfw/zh-cn_image_0000002659220289.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=83BF5ABEA27D51E0C27FB1A4D3B6C555A8FE5174E0F5B9D0DCFE40C387006A24)
**流程说明：**
1.
开发者应用调用checkSysIntegrityOnLocal接口，发起本地系统完整性检测请求。
2.
Device Security Kit收到请求后，采集系统完整性检测数据，检测系统完整性。
3.
通过checkSysIntegrityOnLocal接口将检测结果返回给开发者应用。
4.
开发者应用可以根据检测结果进行业务处理。当本地系统完整性检测结果为false时，请进一步判断detail中的具体风险分类，您可以根据风险分类以及自身功能对安全的要求决定是否提醒用户。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c3/v3/659i1T6rQseCXuLcverb5w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=82F9B5A1E2F2A01A78C22316B10192FB4E29EFFBBF83BE18490694D3D2700DAC)
-
本地系统完整性检测结果可以用作系统整体安全的一个环节，需要考虑检测结果误报带来的风险以及给用户带来的影响，不建议将本地系统完整性检测结果作为判断当前设备是否安全的唯一依据，更好的做法是通过额外的步骤降低风险。
-
如果需要在应用中提醒用户，为了提升用户体验，建议采用友好的提示语，可参考：
您的设备疑似存在风险或运行在不安全环境中，请谨慎使用xxx功能。
#### 接口说明
以下是系统完整性检测相关接口，包括ArkTS API，更多接口及使用方法请参见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md) 。
| 接口名 | 描述 |
| --- | --- |
| [checkSysIntegrityOnLocal](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md)(): Promise<string> | 检测系统完整性 |
#### 开发步骤
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4f/v3/MrskrI6YR36WytWGfwtbeQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=24809EAAE36AB6CAAC57700ECE2BDF8CA06EF3679BDB9C87BC5CA6CCC3FC6C6E)
请确保已打开“ [安全检测服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/Device Security Kit（设备安全服务）/开发准备/开通Device Security服务/devicesecurity-deviceverify-activateservice.md) ”开关并 [申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-profile-0000002270709473) 。
1.
导入Device Security Kit模块及相关公共模块。
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
调用接口获取系统完整性检测结果。
```typescript
const TAG = "SafetyDetectJsTest";
// 请求本地系统完整性检测，并处理结果
try {
  hilog.info(0x0000, TAG, 'CheckSysIntegrityOnLocal begin.');
  const result: string = await safetyDetect.checkSysIntegrityOnLocal();
  hilog.info(0x0000, TAG, 'Succeeded in checkSysIntegrityOnLocal: %{public}s', result);
} catch (err) {
  let e: BusinessError = err as BusinessError;
  hilog.error(0x0000, TAG, 'CheckSysIntegrityOnLocal failed: %{public}d %{public}s', e.code, e.message);
}
```
3.
开发者应用可以根据检测结果进行业务处理，当本地系统完整性检测结果为false时，您可以根据自身功能对安全的要求决定是否提醒用户。
本地系统完整性检测结果是一个格式为JSON格式的字符串，内容示例如下：
```json
{
  "basicIntegrity": false,
  "detail": [
    "attack",
    "jailbreak",
    "emulator"
  ]
}
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/0C6-IwNjRJWfNZUkt-Pt1w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=87B2830F81F4D22DA56EB1B0ABCDE5C4710E54427196B66A02DC2C7B490B8736)
basicIntegrity：系统完整性检测的结果，true表示检测结果完整，false表示存在风险。
detail：可选字段，当basicIntegrity结果为false时，该字段将提供存在风险的原因，App开发者可以根据不同风险做出不同的决策，详情如下：
-
jailbreak：设备被越狱。
-
emulator：非真实设备。
-
attack：设备被攻击。
-
unlock：设备被解锁。