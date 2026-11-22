# SafetyDetect（安全检测）

判断设备环境是否安全，比如是否被越狱、被模拟等，您可基于结果评估如何响应。
判断用户访问的URL是否为恶意网址，对于恶意网址，由您评估提示或拦截用户的访问风险。

**起始版本:** 5.0.0(12)

## 导入模块
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
```

## SysIntegrityRequest
系统完整性检测的请求参数。

**元服务API：** 从版本5.0.2(14)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Security.SafetyDetect
**起始版本：** 5.0.0(12)

| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| nonce | string | 否 | 否 | 开发者应用传入的一个随机生成的nonce值，用于防重放攻击，在检测结果中会包含该值。 |

## SysIntegrityResponse
系统完整性检测返回值。

**元服务API：** 从版本5.0.2(14)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Security.SafetyDetect
**起始版本：** 5.0.0(12)

| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| result | string | 否 | 否 | JWS格式的系统完整性检测结果。JWS内容详见《Device Security Kit开发指南》中的系统完整性检测[开发步骤](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-sysintegrity-check)。 |

## checkSysIntegrity
checkSysIntegrity(req: [SysIntegrityRequest](#section208107205467) ): Promise< [SysIntegrityResponse](#section1584743916458) >

获取本设备的系统完整性的在线检测结果。使用Promise异步回调。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/6e/v3/2RWfVvysQvKXSNp-ZyEM3g/caution_3.0-zh-cn.png)
该接口涉及端云协同，需要联网等耗时操作，因此不要在UI线程中执行，避免阻塞UI线程。

**元服务API：** 从版本5.0.2(14)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Security.SafetyDetect
**起始版本：** 5.0.0(12)

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| req | [SysIntegrityRequest](#section208107205467) | 是 | 请求参数，包含nonce。nonce长度必须16至66字节之间，有效值为base64编码范围。 |

**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SysIntegrityResponse](#section1584743916458)> | Promise对象，返回系统完整性检测结果。 |

**错误码：**

| 错误码ID | 错误信息 |
| --- | --- |
| 201 | Permission denied. |
| 401 | Invalid parameters.Possible causes:1. Mandatory parameters are left unspecified.2. Incorrect parameter types.3. Parameter verification failed. |
| 801 | API is not supported. |
| 1010800001 | Internal error |
| 1010800002 | The network is unreachable. |
| 1010800003 | Access cloud server fail. |
| 1010800005 | The number of calls exceeds the parallel threshold. |
| 1010800006 | The invoking frequency exceeds the threshold. |
| 1010800007 | Operation timeout. |
| 1010800008 | The cloud service traffic exceeds the threshold. |

**示例：**
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError} from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
const TAG = "SafetyDetectJsTest";
// 请求系统完整性检测，并处理结果
let req : safetyDetect.SysIntegrityRequest = {
  nonce : 'imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs' // 从服务器生成的随机的nonce值
};
try {
  hilog.info(0x0000, TAG, 'CheckSysIntegrity begin.');
  const data: safetyDetect.SysIntegrityResponse = await safetyDetect.checkSysIntegrity(req);
  hilog.info(0x0000, TAG, 'Succeeded in checkSysIntegrity: %{public}s', data.result);
} catch (err) {
  let e: BusinessError = err as BusinessError;
  hilog.error(0x0000, TAG, 'CheckSysIntegrity failed: %{public}d %{public}s', e.code, e.message);
}
```

## checkSysIntegrityOnLocal
checkSysIntegrityOnLocal(): Promise<string>

获取本设备的系统完整性的本地检测结果。使用Promise异步回调。

**元服务API：** 从版本5.1.0(18)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Security.SafetyDetect
**起始版本：** 5.1.0(18)

**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<string> | Promise对象，返回JSON格式的系统完整性检测结果。 |

**错误码：**

| 错误码ID | 错误信息 |
| --- | --- |
| 801 | API is not supported. |
| 1010800001 | Internal error |
| 1010800004 | Verify capability fail. |
| 1010800005 | The number of calls exceeds the parallel threshold. |
| 1010800006 | The invoking frequency exceeds the threshold. |
| 1010800007 | Operation timeout. |

## checkSysIntegrityEnhanced
checkSysIntegrityEnhanced(req: [SysIntegrityRequest](#section208107205467) ): Promise< [SysIntegrityResponse](#section1584743916458) >

获取本设备的系统完整性的在线增强检测结果。使用Promise异步回调。

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f9/v3/hqjlia3NRIC8pnQ_tUkTHA/caution_3.0-zh-cn.png)
该接口涉及端云协同，需要联网等耗时操作，因此不要在UI线程中执行，避免阻塞UI线程。

**元服务API：** 从版本6.0.0(20)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Security.SafetyDetect
**起始版本：** 6.0.0(20)

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| req | [SysIntegrityRequest](#section208107205467) | 是 | 请求参数，包含nonce。nonce长度必须16至66字节之间，有效值为base64编码范围。 |

**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[SysIntegrityResponse](#section1584743916458)> | Promise对象，返回系统完整性增强检测结果。 |

**错误码：**

| 错误码ID | 错误信息 |
| --- | --- |
| 801 | API is not supported. |
| 1010800001 | Internal error |
| 1010800002 | The network is unreachable. |
| 1010800003 | Access cloud server fail. |
| 1010800004 | Verify capability fail. |
| 1010800005 | The number of calls exceeds the parallel threshold. |
| 1010800006 | The invoking frequency exceeds the threshold. |
| 1010800007 | Operation timeout. |
| 1010800008 | The cloud service traffic exceeds the threshold. |