# @ohos.identifier.oaid (开放匿名设备标识服务)

> 文档ID: js-apis-oaid
> 版本: V66
> 更新时间: 2026-06-08 05:39:01

---

# @ohos.identifier.oaid (开放匿名设备标识服务)

 本模块提供开放匿名设备标识符（Open Anonymous Device Identifier, OAID，以下简称OAID）的获取和重置能力。

 ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/21/v3/j79-XROcRtabUdIZmf6FkQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T155230Z&HW-CC-Expire=86400&HW-CC-Sign=D66A32A6152B81DF5C2739CE75DC2112A1FD3DE3A60D90930E9C9A22D9B9CCF5)  本模块首批接口从API version 10开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。

  使用获取开放匿名设备标识符接口，需[向用户申请授权](../request-user-authorization.md)（默认开启权限）：ohos.permission.APP_TRACKING_CONSENT。

#### 导入模块

```
import { identifier } from '@kit.AdsKit';
```
#### identifier.getOAID

getOAID(): Promise<string>

 获取开放匿名设备标识符（OAID）。使用Promise异步回调。

 **需要权限：** ohos.permission.APP_TRACKING_CONSENT

 **系统能力：** SystemCapability.Advertising.OAID

 **返回值：**


| 类型 | 说明 |
| --- | --- |
| Promise<string> | Promise对象，返回开放匿名设备标识符（OAID）。 |

 1.如应用已配置ohos.permission.APP_TRACKING_CONSENT权限，且“跨应用关联访问权限”为“允许”，则返回OAID。

 2.如应用已配置ohos.permission.APP_TRACKING_CONSENT权限，且“跨应用关联访问权限”为“禁止”，则返回00000000-0000-0000-0000-000000000000。

 3.如应用未配置ohos.permission.APP_TRACKING_CONSENT权限，则返回00000000-0000-0000-0000-000000000000。


  ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d0/v3/9NsKN_z2Tz-c6kiJyJZPvw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T155230Z&HW-CC-Expire=86400&HW-CC-Sign=0F4848E6C9218890F849408FA161419F304223F0CEA23AD0314A48BDD9D1FBBC)  设置项“跨应用关联访问权限”在HarmonyOS NEXT Developer Beta5及更早版本名称为“应用跟踪访问权限”。

   **错误码：**

 以下错误码的详细介绍请参见[开放匿名设备标识服务错误码参考](errorcode-oaid.md)。


| 错误码ID | 错误信息 |
| --- | --- |
| 17300001 | System internal error. |

  **示例：**


```
import { identifier } from '@kit.AdsKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

void identifier.getOAID().then((data: string) => {
  const oaid: string = data;
}).catch((error: BusinessError) => {
  hilog.error(0x0000, 'testTag', `Failed to get oaid. Code is ${error.code}, message is ${error.message}`);
});
```
#### identifier.getOAID

getOAID(callback: AsyncCallback<string>): void

 获取开放匿名设备标识符（OAID）。使用callback异步回调。

 **需要权限：** ohos.permission.APP_TRACKING_CONSENT

 **系统能力：** SystemCapability.Advertising.OAID

 **参数：**


| **参数**名 | **类型** | 必填 | 说明 |
| --- | --- | --- | --- |
| callback | AsyncCallback<string> | 是 | 回调函数，返回开放匿名设备标识符（OAID）。 |

 1.如应用已配置ohos.permission.APP_TRACKING_CONSENT权限，且“跨应用关联访问权限”为“允许”，则返回OAID。

 2.如应用已配置ohos.permission.APP_TRACKING_CONSENT权限，且“跨应用关联访问权限”为“禁止”，则返回00000000-0000-0000-0000-000000000000。

 3.如应用未配置ohos.permission.APP_TRACKING_CONSENT权限，则返回00000000-0000-0000-0000-000000000000。


  ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f3/v3/taIi_jWaRaanNznetatyAA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T155230Z&HW-CC-Expire=86400&HW-CC-Sign=0469807BF20CAA5EE2CBA63164AA8140A2DBB92786E0B48E2F456E8D49F947E8)  设置项“跨应用关联访问权限”在HarmonyOS NEXT Developer Beta5及更早版本名称为“应用跟踪访问权限”。

   **错误码：**

 以下错误码的详细介绍请参见[开放匿名设备标识服务错误码参考](errorcode-oaid.md)。


| 错误码ID | 错误信息 |
| --- | --- |
| 17300001 | System internal error. |

  **示例：**


```
import { identifier } from '@kit.AdsKit';
import { BusinessError } from '@kit.BasicServicesKit';

identifier.getOAID((err: BusinessError, data: string) => {
  if (err.code) {
    return;
  }
  const oaid: string = data;
});
```
