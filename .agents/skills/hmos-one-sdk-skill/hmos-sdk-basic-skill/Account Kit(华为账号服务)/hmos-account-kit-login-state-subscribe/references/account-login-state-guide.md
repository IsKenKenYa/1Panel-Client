# 订阅华为账号的登录/登出事件 - API开发指南

#### 场景介绍
应用在前台时可以订阅Account Kit提供的华为账号登录/登出广播事件，来感知华为账号的登录状态，实现用户登录/登出应用的逻辑。应用也可通过 [getHuaweiIDState](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) 实时查询华为账号登录状态。

#### 事件说明
以下是华为账号登录/登出发送的广播事件。

| 事件名称 | 描述 |
| --- | --- |
| [COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions) | 表示分布式账号登录成功的动作。华为账号登录成功也会发这个广播事件。 |
| [COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions) | 表示分布式账号登出成功的动作。华为账号登出成功也会发这个广播事件。 |

#### 开发前提
在进行代码开发前，请确保已按照"开发准备"章节中的指导完成 [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints) 、 [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id) 。此场景无需申请账号权限。

#### 开发步骤

1. 导入 [commonEventManager](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-commoneventmanager) 模块及相关公共模块。

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```

2. 创建订阅者，并处理订阅结果。

```typescript
// 订阅者信息
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT]
};

// 定义订阅者，如开发者使用await改写createSubscriber方法，需要把此变量定义到全局(struct外层)
let subscriber: commonEventManager.CommonEventSubscriber | null = null;

// 创建订阅者
commonEventManager.createSubscriber(subscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    subscriber = commonEventSubscriber;
    // 订阅公共事件
    commonEventManager.subscribe(subscriber,
      (error: BusinessError, data: commonEventManager.CommonEventData) => {
        if (error) {
          hilog.error(0x0000, 'testTag',
            `Failed to subscribe, code is ${error.code}, message is ${error.message}`);
        } else {
          hilog.info(0x0000, 'testTag', 'Succeeded in subscribing.');
          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
            // 订阅到华为账号登录事件
          }
          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
            // 订阅到华为账号登出事件
          }
        }
      });
  })
  .catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `Failed to createSubscriber. Code: ${err.code}, message: ${err.message}`);
  });
```

#### 参考链接
- [API参考：commonEventManager公共事件模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-commoneventmanager)
- [API参考：authentication账号认证服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)
- [系统定义的公共事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)