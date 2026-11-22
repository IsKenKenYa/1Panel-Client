# wearEngine服务连接状态管理API

## wearEngine.on
on(type: 'serviceDie', callback: Callback<void>): void

订阅服务端消亡事件,调用wearEngine.destroy接口主动发起的消亡事件不会触发执行回调函数。

**模型约束:** 此接口仅可在Stage模型下使用。
**系统能力:** SystemCapability.Health.WearEngine
**起始版本:** 5.0.0(12)

**参数:**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 监听的事件类型,仅支持serviceDie(服务端消亡事件)。 |
| callback | Callback<void> | 是 | 回调函数。 |

**错误码:**
以下错误码的详细介绍请参见[Wear Engine ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. 2. Incorrect parameter types. |
| 1008500012 | Too many callbacks of the same type. |
| 1008509999 | Internal error. |

**示例:**
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
let callback = () => {
  console.info(`The service destruction event`);
}
try {
  wearEngine.on('serviceDie', callback);
  console.info(`Succeeded in subscribing the service destruction event.`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to subscribe the service destruction event. Code is ${err.code}, message is ${err.message}.`);
}
```

## wearEngine.off
off(type: 'serviceDie', callback?: Callback<void>): void

取消订阅服务端消亡事件。

**模型约束:** 此接口仅可在Stage模型下使用。
**系统能力:** SystemCapability.Health.WearEngine
**起始版本:** 5.0.0(12)

**参数:**
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 监听的事件类型,仅支持serviceDie(服务端消亡事件)。 |
| callback | Callback<void> | 否 | 回调函数,需要同订阅监听时的回调函数为同一个对象。当该参数为空时,会取消掉之前所有的订阅。 |

**错误码:**
以下错误码的详细介绍请参见[Wear Engine ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. 2. Incorrect parameter types. |
| 1008509999 | Internal error. |

**示例:**
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
let callback = () => {
  console.info(`The service destruction event`);
}
wearEngine.on('serviceDie', callback);
try {
  wearEngine.off('serviceDie', callback);
  console.info(`Succeeded in unsubscribing the service destruction event.`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to unsubscribe the service destruction event. Code is ${err.code}, message is ${err.message}.`);
}
```

## wearEngine.destroy
destroy(): Promise<void>

主动销毁服务端,使用Promise异步回调。

**模型约束:** 此接口仅可在Stage模型下使用。
**系统能力:** SystemCapability.Health.WearEngine
**起始版本:** 5.0.0(12)

**返回值:**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | Promise对象。无结果返回的Promise对象。 |

**错误码:**
以下错误码的详细介绍请参见[Wear Engine ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)。

| 错误码ID | 错误信息 |
| --- | --- |
| 1008509999 | Internal error. |

**示例:**
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
wearEngine.destroy().then(() => {
  console.info(`Succeeded in destroying wear engine channel.`);
}).catch((error: BusinessError) => {
  console.error(`Failed to destroy wear engine channel. Code is ${error.code}, message is ${error.message}.`);
})
```