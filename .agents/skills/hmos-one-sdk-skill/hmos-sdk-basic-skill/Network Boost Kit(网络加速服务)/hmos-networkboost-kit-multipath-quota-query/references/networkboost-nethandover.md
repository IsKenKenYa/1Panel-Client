# netHandover（连接迁移）

# netHandover（连接迁移）
本模块提供网络连接迁移能力，以便在弱网环境下，系统发起多网迁移（WiFi<->蜂窝，主卡<->副卡等）的过程中，给应用提供连接迁移开始和完成通知，应用根据连接迁移通知的建议进行重建，快速恢复业务，给用户带来平滑、高速、低时延的上网体验。
**起始版本：** 5.0.0(12)
#### 导入模块
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
```

#### netHandover.getMultiPathQuotaStats
getMultiPathQuotaStats(): MultiPathQuota
获取当前应用多网使用的配额，包括已使用的配额信息和剩余配额信息。
**需要权限：** ohos.permission.LINKTURBO
**系统能力：** SystemCapability.Communication.NetworkBoost.Core
**起始版本：** 6.0.0(20)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| MultiPathQuota | 应用配额信息。 |
**错误码：**
以下错误码的详细介绍请参见 [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-arkts-errorcode) 和 [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal) 。
| 错误码 | 说明 |
| --- | --- |
| 201 | 权限校验失败。 |
| 1013600001 | 内部处理异常，例如内部管理状态机异常。 |
| 1013600002 | 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。 |
**示例：**
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { netHandover } from '@kit.NetworkBoostKit';
try {
  let multiquota : netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
  console.info('getMultiPathQuotaStats multiPathQuota.used.count is:' + multiquota.used.count)
  console.info('getMultiPathQuotaStats multiPathQuota.used.duration is:' + multiquota.used.duration)
  console.info('getMultiPathQuotaStats multiPathQuota.remaining.count is:' + multiquota.remaining.count)
  console.info('getMultiPathQuotaStats multiPathQuota.remaining.durationis:' + multiquota.remaining.duration)
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### MultiPathQuota
应用配额使用信息。
**系统能力：** SystemCapability.Communication.NetworkBoost.Core
**起始版本：** 6.0.0(20)
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| used | MultiPathQuotaInfo | 是 | 否 | 应用已使用配额信息。 |
| remaining | MultiPathQuotaInfo | 是 | 否 | 应用剩余使用配额信息。 |

#### MultiPathQuotaInfo
配额信息。
**系统能力：** SystemCapability.Communication.NetworkBoost.Core
**起始版本：** 6.0.0(20)
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| count | number | 否 | 否 | 配额次数信息。 |
| duration | number | 否 | 否 | 配额时长信息，单位为秒。 |