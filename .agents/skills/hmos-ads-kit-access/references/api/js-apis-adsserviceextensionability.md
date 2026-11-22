# @ohos.advertising.AdsServiceExtensionAbility(广告扩展服务)

> 文档ID: js-apis-adsserviceextensionability
> 版本: V66
> 更新时间: 2026-06-08 05:39:04

---

# @ohos.advertising.AdsServiceExtensionAbility(广告扩展服务)

 本模块为设备厂商提供广告扩展能力，设备厂商可自主实现请求广告的回调。

 ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/de/v3/trqwkCPIQ1ionjHRMh1HLw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T155224Z&HW-CC-Expire=86400&HW-CC-Sign=CC105A0C3A77D20DAE3C958AEC1B145E523ED69B6BE955A977921A7A8A1AFE3E)  本模块首批接口从API version 11开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。

#### 导入模块

```
import { RespCallback } from '@kit.AdsKit';
```
#### RespCallback

(respData: Map<string, Array<advertising.Advertisement>>): void

 广告请求回调。

 **系统能力：** SystemCapability.Advertising.Ads

 **参数：**


| **参数名** | **类型** | 必填 | 说明 |
| --- | --- | --- | --- |
| respData | Map<string, Array<advertising.[Advertisement](js-apis-advertisement.md)>> | 是 | 广告请求回调数据，是以广告位ID为键，存储请求到的广告内容的映射集合。 |

  **示例：**


```
import { advertising, RespCallback } from '@kit.AdsKit';

function setRespCallback(respCallback: RespCallback) {
  const respData: Map> = new Map();
  // 设置广告返回数据
  // ...
  respCallback(respData);
}
```
