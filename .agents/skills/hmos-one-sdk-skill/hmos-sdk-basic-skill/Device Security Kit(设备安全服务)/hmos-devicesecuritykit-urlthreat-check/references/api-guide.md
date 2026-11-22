# URL检测
---
# URL检测
#### 场景介绍
应用通过调用Device Security Kit的checkUrlThreat接口检测URL是否为恶意的，并且根据检测结果来提示或拦截该URL。
典型场景：用户访问网址时，判断用户访问的URL是否为恶意网址，对于恶意网址，提示或拦截用户的访问风险。
#### 约束与限制
-
URL检测能力支持Phone、Tablet、PC/2in1设备。并且从5.1.0(18)版本开始，新增支持Wearable设备。
-
每个应用在每个设备上每天最多可以调用1万次接口；每个设备上最多支持5个并发调用。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/nmc959J2QlGNtMUP4GJfmg/zh-cn_image_0000002628860974.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=42390AF0ED905533F71ABBB1B37CB200C85197FCF8E15B584B3349B4F936CB83)
**流程说明：**
1.
开发者应用调用URL检测（checkUrlThreat）接口，传入待检测的URL，并获得URL检测结果。
Device Security Kit将请求发送到华为服务器检测URL风险，并将检测结果返回给开发者应用（NORMAL、PHISHING、MALWARE、OTHERS）。
2.
开发者应用可以根据检测结果来决定业务处理策略。
#### 接口说明
以下是URL检测相关接口，包括ArkTS API，更多接口及使用方法请参见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md) 。
| 接口名 | 描述 |
| --- | --- |
| [checkUrlThreat](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md)(req:[UrlCheckRequest](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md)): Promise<[UrlCheckResponse](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Device Security Kit（设备安全服务）/ArkTS API/devicesecurity-safetydetectenhanced-api.md)> | 检测URL风险 |
#### 开发步骤
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fe/v3/P1z23foERLS0MnnOniHZkA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=88A5CB6B8C7B255F3B7D709003B448F011F892E369C53B49D8321270CA2C104F)
请确保已打开“ [安全检测服务](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/Device Security Kit（设备安全服务）/开发准备/开通Device Security服务/devicesecurity-deviceverify-activateservice.md) ”开关并 [申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-profile-0000002270709473) 。
1.
导入Device Security Kit模块及相关公共模块。
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError} from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
调用接口获取URL检测结果。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e3/v3/t3F765x9SOGqplpt9xzT3g/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104810Z&HW-CC-Expire=86400&HW-CC-Sign=78D0B0C7691777BC7AB88D5F88BA3066AB6F530D7E25E046393C0F84DE00BF15)
该接口涉及端云协同，需要联网等耗时操作，因此不要在UI线程中执行，避免阻塞UI线程。
```typescript
const TAG = "SafetyDetectJsTest";
// 请求URL检测，并处理结果
let req : safetyDetect.UrlCheckRequest = {
  urls : ['https://test1.com']
};
try {
  hilog.info(0x0000, TAG, 'CheckUrlThreat begin.');
  const data: safetyDetect.UrlCheckResponse = await safetyDetect.checkUrlThreat(req);
  hilog.info(0x0000, TAG, 'Succeeded in checkUrlThreat: %{public}s %{public}d', data.results[0].url, data.results[0].threat);
} catch (err) {
  let e: BusinessError = err as BusinessError;
  hilog.error(0x0000, TAG, 'CheckUrlThreat failed: %{public}d %{public}s', e.code, e.message);
}
```