# COMMON_EVENT_TIME_CHANGED 公共事件定义

本文档提取了与用户偏好监听相关的公共事件定义。

## COMMON_EVENT_TIME_CHANGED

设置系统时间的公共事件的动作。当设置系统时间时,将会触发事件通知服务发布该系统公共事件。

**系统能力**: SystemCapability.Notification.CommonEvent

**订阅者所需权限**: 无

**取值**: "usual.event.TIME_CHANGED"

### 使用说明

通过监听此事件可以感知系统时制变化。需要通过事件数据区分系统时间变化和系统时制变化:

- 系统时间变化: data.data为其他值或未定义
- 系统时制变化: data.data == '24HourChange'

### 示例代码

```typescript
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

let timeSubscriber: commonEventManager.CommonEventSubscriber;
let timeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_TIME_CHANGED]
};

commonEventManager.createSubscriber(timeSubscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    console.info('CreateSubscriber');
    timeSubscriber = commonEventSubscriber;
    
    commonEventManager.subscribe(timeSubscriber, (err, data) => {
      if (err) {
        console.error(`Failed to subscribe common event. error code: ${err.code}, message: ${err.message}.`);
        return;
      }
      
      // 区分系统时间和系统时制变化
      if (data.data != undefined && data.data == '24HourChange') {
        console.info('System time format changed detected.');
        // 执行时制变化处理逻辑
      } else {
        console.info('System time changed detected.');
        // 执行时间变化处理逻辑
      }
    });
  })
  .catch((err: BusinessError) => {
    console.error(`CreateSubscriber failed, code is ${err.code}, message is ${err.message}`);
  });
```

## 参考文档

- [公共事件完整文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)
- [commonEventManager API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-commoneventmanager)