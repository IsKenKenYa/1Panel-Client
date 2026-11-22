---
name: hmos-account-kit-login-state-subscribe
description: 订阅华为账号登录/登出广播事件，感知账号登录状态变化，支持登录和登出两种事件类型，仅限前台应用使用，适用于账号状态同步、自动登录/登出场景
---

# 订阅华为账号的登录/登出事件技能

## 功能描述

本技能用于订阅华为账号登录/登出的广播事件，使应用在前台时能够感知华为账号的登录状态变化。通过订阅系统公共事件，实现用户登录/登出应用的逻辑处理。

### 核心能力
- 订阅华为账号登录成功事件（COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN）
- 订阅华为账号登出成功事件（COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT）
- 处理登录/登出事件回调
- 可配合getHuaweiIDState接口实时查询登录状态

### 技术特点
- 使用CommonEventManager公共事件管理器
- 异步回调处理事件
- 仅限前台应用使用
- 无需申请账号权限

## 使用场景

### 触发词
- "订阅账号登录事件"
- "监听账号登出"
- "账号状态变化通知"
- "华为账号登录监听"
- "账号登出事件订阅"
- "Account Kit 登录状态"

### 能做
- 在应用前台订阅华为账号登录/登出广播事件
- 接收并处理账号登录成功事件
- 接收并处理账号登出成功事件
- 根据事件类型执行相应业务逻辑
- 配合getHuaweiIDState接口查询当前登录状态

### 绝不做
- 不在后台应用中使用（仅限前台）
- 不订阅其他应用账号的事件
- 不替代账号登录/登出的主动操作
- 不处理非华为账号的登录事件
- 不在元服务中使用（元服务不支持）

### 补充
- 应用需完成开发准备（配置签名和指纹、配置Client ID）
- 此场景无需申请账号权限
- 可通过getHuaweiIDState实时查询登录状态
- 分布式账号登录成功时也会触发此事件

## 调用规范和规则

### 输入约束
- 应用必须在前台运行
- 需导入@kit.BasicServicesKit模块
- 需导入@kit.PerformanceAnalysisKit模块（hilog）
- 订阅事件列表必须包含登录或登出事件常量

### 执行约束
- 创建订阅者对象需定义在全局作用域（struct外层）
- 使用Promise异步回调处理事件
- 事件回调需处理BusinessError错误对象
- 事件处理需在回调中判断事件类型

### 内容约束
- 禁止订阅未定义的系统事件
- 禁止在订阅回调中执行耗时操作
- 禁止遗漏错误处理逻辑
- 禁止硬编码事件名称字符串

### 降级约束
- 订阅失败：记录错误日志，提示用户稍后重试
- 事件接收失败：检查订阅状态，必要时重新订阅
- 系统服务异常：等待服务恢复后重新订阅
- 无法创建订阅者：检查参数有效性

## 调用流程和步骤

### 步骤1：导入必要模块

**前置校验**：
1. 确认项目已配置@kit.BasicServicesKit依赖
2. 确认项目已配置@kit.PerformanceAnalysisKit依赖
3. 确认应用在前台运行状态

**导入模块代码**：
```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```

### 步骤2：定义订阅者信息和订阅者对象

**参数准备**：
```typescript
// 订阅者信息配置
const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN,
    commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT]
};

// 定义订阅者对象（必须定义在全局作用域）
let subscriber: commonEventManager.CommonEventSubscriber | null = null;
```

### 步骤3：创建订阅者并订阅事件

**示例代码**：
```typescript
// 创建订阅者并订阅公共事件
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
          // 处理不同事件类型
          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN) {
            // 华为账号登录成功事件处理
            handleAccountLogin(data);
          }
          if (data.event === commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT) {
            // 华为账号登出成功事件处理
            handleAccountLogout(data);
          }
        }
      });
  })
  .catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `Failed to createSubscriber. Code: ${err.code}, message: ${err.message}`);
  });
```

### 步骤4：实现事件处理函数

**事件处理代码**：
```typescript
// 处理账号登录事件
function handleAccountLogin(data: commonEventManager.CommonEventData): void {
  hilog.info(0x0000, 'testTag', 'Account login event received.');
  // 执行登录后业务逻辑
  // 例如：更新UI状态、同步用户数据、启动登录后服务
}

// 处理账号登出事件
function handleAccountLogout(data: commonEventManager.CommonEventData): void {
  hilog.info(0x0000, 'testTag', 'Account logout event received.');
  // 执行登出后业务逻辑
  // 例如：清理用户数据、停止相关服务、更新UI状态
}
```

### 步骤5：取消订阅（可选）

**取消订阅代码**：
```typescript
// 取消订阅公共事件
function unsubscribeAccountEvents(): void {
  if (subscriber) {
    try {
      commonEventManager.unsubscribe(subscriber, (err: BusinessError) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 
            `Failed to unsubscribe. Code: ${err.code}, message: ${err.message}`);
          return;
        }
        subscriber = null;
        hilog.info(0x0000, 'testTag', 'Succeeded in unsubscribing.');
      });
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'testTag', 
        `Failed to unsubscribe. Code: ${err.code}, message: ${err.message}`);
    }
  }
}
```

### 步骤6：实时查询登录状态（可选）

**查询状态代码**：
```typescript
import { authentication } from '@kit.AccountKit';

// 实时查询华为账号登录状态
async function checkLoginState(): Promise<void> {
  const stateRequest: authentication.StateRequest = {
    idType: authentication.IdType.UNION_ID,
    idValue: '<UnionID值>' // 通过华为账号登录接口获取
  };
  
  try {
    const result = await new authentication.HuaweiIDProvider().getHuaweiIDState(stateRequest);
    hilog.info(0x0000, 'testTag', `Login state: ${result.state}`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0000, 'testTag', 
      `Failed to get login state. Code: ${err.code}, message: ${err.message}`);
  }
}
```

## 错误码说明

### CommonEventManager错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，必填参数未指定或类型错误 | 检查subscribeInfo参数是否正确配置 |
| 801 | 能力不支持，设备不支持此功能 | 检查设备是否支持公共事件订阅 |
| 1500007 | 发送消息到公共事件服务失败 | 检查系统服务状态，稍后重试 |
| 1500008 | 初始化公共事件服务失败 | 检查系统服务是否正常运行 |
| 1500010 | 订阅者数量超出系统规格 | 取消其他订阅或等待系统释放资源 |

### Account Kit错误码（getHuaweiIDState）

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 12300001 | 系统服务异常 | 稍后重试或检查系统状态 |
| 1001502001 | 用户未登录华为账号 | 引导用户登录华为账号 |
| 1001502003 | 输入参数值无效 | 检查StateRequest参数 |
| 1001502005 | 网络错误 | 检查网络连接状态 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0",
    "@kit.AccountKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 9及以上
- Stage模型应用
- 应用在前台运行

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.BasicServicesKit'
```
**解决方法**：确保项目已配置HarmonyOS SDK依赖，检查ohpm.json配置

**问题2：订阅者对象未定义**
```
TypeError: Cannot read property 'subscribe' of null
```
**解决方法**：确保subscriber变量定义在全局作用域（struct外层）

**问题3：事件常量未找到**
```
Property 'COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN' does not exist
```
**解决方法**：使用正确的commonEventManager.Support枚举访问事件常量

## 常见问题与解决方法

### Q1：无法接收到账号登录事件
**原因**：应用不在前台或订阅者创建失败
**解决方法**：
- 确认应用在前台运行
- 检查createSubscriber是否成功执行
- 验证subscribeInfo配置是否正确
- 检查系统公共事件服务状态

### Q2：订阅后立即收到错误回调
**原因**：订阅者数量超出限制或系统服务异常
**解决方法**：
- 取消其他不必要的订阅
- 等待系统释放订阅者资源
- 检查系统服务是否正常运行
- 使用createSubscriberSync同步创建订阅者

### Q3：事件回调中data.event为空
**原因**：事件数据解析失败或订阅的事件类型不匹配
**解决方法**：
- 检查订阅的事件列表是否包含目标事件
- 验证CommonEventData数据结构
- 使用hilog打印完整的data对象进行调试

### Q4：取消订阅失败
**原因**：订阅者对象已失效或系统服务异常
**解决方法**：
- 确认subscriber对象不为null
- 检查订阅者是否已被其他地方取消
- 等待系统服务恢复后重新尝试
- 将subscriber置为null避免内存泄漏

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "订阅成功",
  "events": [
    "COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN",
    "COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT"
  ],
  "subscriberCreated": true,
  "subscriptionActive": true,
  "apiUsed": [
    "commonEventManager.createSubscriber",
    "commonEventManager.subscribe",
    "commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGIN",
    "commonEventManager.Support.COMMON_EVENT_DISTRIBUTED_ACCOUNT_LOGOUT"
  ]
}
```

## 参考文档

- [API开发指南：订阅华为账号的登录/登出事件](references/account-login-state-guide.md)
- [API参考说明：commonEventManager公共事件模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-commoneventmanager)
- [API参考说明：系统定义的公共事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)
- [API参考说明：authentication账号认证服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)
- [开发指南：配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [开发指南：配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)

## 完整示例代码

- [ArkTS完整示例](assets/account-login-state-subscribe.ets)
- [事件处理示例](assets/event-handler.ets)
- [取消订阅示例](assets/unsubscribe-example.ets)

## 测试用例

### 正向测试用例
- [成功订阅账号登录事件](tests/test_positive_login.ts)：验证订阅登录事件成功并接收到事件
- [成功订阅账号登出事件](tests/test_positive_logout.ts)：验证订阅登出事件成功并接收到事件
- [同时订阅登录和登出事件](tests/test_positive_both.ts)：验证订阅两个事件都成功

### 边界测试用例
- [应用切换到前台时订阅](tests/test_boundary_foreground.ts)：验证前台状态订阅成功
- [重复订阅同一事件](tests/test_boundary_duplicate.ts)：验证重复订阅的处理

### 异常测试用例
- [应用在后台订阅失败](tests/test_exception_background.ts)：验证后台订阅失败
- [订阅者参数为空](tests/test_exception_empty_params.ts)：验证参数校验
- [系统服务异常时订阅](tests/test_exception_service_error.ts)：验证系统异常处理