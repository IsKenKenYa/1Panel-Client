# netHandover.on('multiPathRecommendation')

订阅系统多网建议变化事件。

## 接口声明

```typescript
on(type: 'multiPathRecommendation', callback: Callback<MultiPathRecommendationInfo>): void
```

## 需要权限

**ohos.permission.LINKTURBO**

## 系统能力

SystemCapability.Communication.NetworkBoost.Core

## 起始版本

6.0.0(20)

## 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 固定填写"multiPathRecommendation"字符串，表示系统多网建议变化事件。 |
| callback | Callback<[MultiPathRecommendationInfo](#multipathrecommendationinfo)> | 是 | 回调函数，返回多网建议变化信息。 |

## 错误码

以下错误码的详细介绍请参见 ArkTS API错误码和通用错误码。

| 错误码 | 说明 |
| --- | --- |
| 201 | 权限校验失败。 |
| 401 | 参数检查失败。 |
| 801 | 设备不支持该API。 |
| 1013600001 | 内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。 |
| 1013600002 | 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。 |

## 示例

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { netHandover } from '@kit.NetworkBoostKit';

try {
  netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
    // 回调信息处理
    console.info("on multiPathRecommendation: " + JSON.stringify(data));
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

# netHandover.off('multiPathRecommendation')

取消订阅系统多网建议变化事件。

## 接口声明

```typescript
off(type: 'multiPathRecommendation', callback?: Callback<MultiPathRecommendationInfo>): void
```

## 需要权限

**ohos.permission.LINKTURBO**

## 系统能力

SystemCapability.Communication.NetworkBoost.Core

## 起始版本

6.0.0(20)

## 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 固定填写"multiPathRecommendation"字符串，表示系统多网建议变化事件。 |
| callback | Callback<[MultiPathRecommendationInfo](#multipathrecommendationinfo)> | 否 | 需要取消注册的回调函数，需与订阅时传入的回调函数是同一个。若无此参数，则取消注册所有的回调函数。 |

## 错误码

以下错误码的详细介绍请参见 ArkTS API错误码和通用错误码。

| 错误码 | 说明 |
| --- | --- |
| 201 | 权限校验失败。 |
| 401 | 参数检查失败。 |
| 801 | 设备不支持该API。 |
| 1013600001 | 内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。 |
| 1013600002 | 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。 |

## 示例

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { netHandover } from '@kit.NetworkBoostKit';

try {
  netHandover.off('multiPathRecommendation');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

# MultiPathRecommendationInfo

多网推荐信息。

## 系统能力

SystemCapability.Communication.NetworkBoost.Core

## 起始版本

6.0.0(20)

## 属性

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| action | [MultiPathAction](#multipathaction) | 是 | 否 | 多网推荐动作。 |

# MultiPathAction

多网推荐动作的枚举。

## 系统能力

SystemCapability.Communication.NetworkBoost.Core

## 起始版本

6.0.0(20)

## 枚举值

| 名称 | 值 | 说明 |
| --- | --- | --- |
| MULTIPATH_ACTION_REQUEST | 0 | 建议发起多网请求。 |
| MULTIPATH_ACTION_RELEASE | 1 | 建议释放多网请求。 |