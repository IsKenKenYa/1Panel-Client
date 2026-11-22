---
name: hmos-remote-communication-kit-cancel-request
description: 取消网络请求+支持取消指定请求或所有请求+需要先创建会话+适用于网络请求管理场景
---

# 取消网络请求（ArkTS）技能

## 功能描述

在远场通信服务的框架中，通过调用session.cancel方法，可以取消正在进行的网络请求。支持两种取消方式：
1. **取消所有请求**：不传入参数时，取消该会话下所有正在进行的网络请求
2. **取消指定请求**：传入Request对象或Request数组时，取消指定的网络请求

这样开发者能够根据具体需求，灵活地管理和控制网络请求的执行。

## 使用场景

### 触发词
- "取消请求"
- "取消网络请求"
- "cancel request"
- "停止请求"
- "中断请求"

### 能做
- 取消指定单个网络请求
- 取消指定多个网络请求（传入Request数组）
- 取消会话下所有正在进行的网络请求
- 在请求完成后进行取消操作（虽然请求已完成，但调用不会报错）

### 绝不做
- 不能取消其他会话的请求（只能取消当前会话的请求）
- 不能取消已完成的请求（调用无效但不会报错）
- 不能取消未发起的请求对象
- 不能在没有创建会话的情况下调用cancel方法

### 补充
- 必须先创建会话（Session）才能调用cancel方法
- 建议在请求完成后及时取消不需要的请求，释放资源
- 从API版本4.1.0(11)开始支持
- 设备支持：Phone、2in1、Tablet、Wearable
- 从5.1.1(19)开始支持TV设备
- 从6.1.0(23)开始支持Car设备

## 调用规范和规则

### 输入约束
- **参数类型**：Request对象、Request数组或undefined
- **参数有效性**：传入的Request对象必须是有效的且属于当前会话
- **会话状态**：必须使用已创建的Session实例调用

### 执行约束
- **调用时机**：可以在请求发起后任意时间调用
- **执行速度**：调用后立即生效，无延迟
- **并发限制**：无并发调用限制

### 内容约束
- **禁止操作**：不能传入不属于当前会话的Request对象
- **参数校验**：传入的Request对象必须已创建且有效
- **错误处理**：参数错误会抛出401错误码

### 降级约束
- **请求已完成**：如果请求已完成，取消操作无效但不报错
- **请求未发起**：如果Request对象未发起请求，取消操作无效但不报错
- **会话已关闭**：如果会话已关闭，调用cancel可能失败

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已导入必要的模块：@kit.RemoteCommunicationKit和@kit.BasicServicesKit
2. 确认已创建有效的Session实例
3. 确认Request对象已创建且有效

**参数准备**：
```typescript
// ArkTS示例
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
const session = rcp.createSession();

// 创建Request对象
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");
```

### 步骤2：发起请求

**示例代码**：
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建会话
const session = rcp.createSession();

// 创建request1、request2
let request1 = new rcp.Request("https://www.example.com");
let request2 = new rcp.Request("https://www.example.com");

// 分别发起请求
session.fetch(request1).then((response: rcp.Response) => {
  console.info(`The response1 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request1 error code is ${err.code}, error data is ${err.data}`);
})

session.fetch(request2).then((response: rcp.Response) => {
  console.info(`The response2 code is ${response.statusCode}`);
}).catch((err: BusinessError) => {
  console.error(`Request2 error code is ${err.code}, error data is ${err.data}`);
})
```

### 步骤3：取消单个请求

**示例代码**：
```typescript
// 单独取消Request1
session.cancel(request1);

// 单独取消Request2
session.cancel(request2);
```

### 步骤4：取消所有请求

**示例代码**：
```typescript
// 取消全部request
session.cancel();
```

### 步骤5：错误处理

```typescript
// 错误处理代码
try {
  // 尝试取消请求
  session.cancel(request1);
} catch (error) {
  if (error.code === 401) {
    console.error('参数错误：传入的Request对象无效');
  } else {
    console.error('未知错误:', error.message);
  }
}
```

### 步骤6：降级处理

```typescript
// 降级处理代码
// 如果取消失败，可以等待请求自然完成
session.cancel(request1);

// 或者关闭会话释放资源
session.close();
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误 | 检查传入的Request对象是否有效且属于当前会话 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": ">=4.1.0",
    "@kit.BasicServicesKit": ">=4.1.0"
  }
}
```

### 环境要求
- **API版本**：>=4.1.0(11)
- **系统能力**：SystemCapability.Collaboration.RemoteCommunication
- **设备支持**：Phone、2in1、Tablet、Wearable、TV（>=5.1.1）、Car（>=6.1.0）

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：确保DevEco Studio版本支持HarmonyOS API 4.1.0及以上，检查项目配置

**问题2：Request对象未定义**
```
Property 'Request' does not exist on type 'typeof rcp'
```
**解决方法**：确保已正确导入rcp模块，使用new rcp.Request()创建对象

**问题3：Session实例未创建**
```
Cannot read property 'cancel' of undefined
```
**解决方法**：确保已调用rcp.createSession()创建会话实例

## 常见问题与解决方法

### Q1：取消请求后，请求是否还会继续执行？
**原因**：cancel方法会中断正在进行的请求
**解决方法**：
- 取消操作立即生效
- 如果请求已完成，取消操作无效但不报错
- 建议在请求完成后检查请求状态

### Q2：如何取消多个请求？
**原因**：需要取消多个指定的请求
**解决方法**：
- 传入Request数组：session.cancel([request1, request2])
- 或者多次调用cancel：session.cancel(request1); session.cancel(request2)

### Q3：取消所有请求是否会影响其他会话？
**原因**：担心取消操作影响范围过大
**解决方法**：
- cancel方法只影响当前会话的请求
- 不同会话之间的请求互不影响
- 每个会话独立管理自己的请求队列

### Q4：取消请求后能否重新发起？
**原因**：需要重新执行被取消的请求
**解决方法**：
- Request对象可以重复使用
- 取消后可以再次调用fetch等方法发起请求
- 建议检查Request对象状态后再重新发起

### Q5：会话关闭后能否调用cancel？
**原因**：会话已关闭但需要取消请求
**解决方法**：
- 会话关闭后不应调用cancel方法
- 建议在关闭会话前完成所有请求管理
- 会话关闭会自动清理相关资源

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "cancel_request",
  "session_id": "<session_id>",
  "canceled_requests": ["request1", "request2"],
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "session.fetch",
    "session.cancel"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netcancle-arkts)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [ArkTS示例：取消指定请求](assets/cancel_single_request.ets)
- [ArkTS示例：取消多个请求](assets/cancel_multiple_requests.ets)
- [ArkTS示例：取消所有请求](assets/cancel_all_requests.ets)

## 测试用例

### 正向测试用例
- [取消单个正在进行的请求](tests/test_cancel_single_request.ets)：验证取消单个请求成功
- [取消多个正在进行的请求](tests/test_cancel_multiple_requests.ets)：验证取消多个请求成功
- [取消所有请求](tests/test_cancel_all_requests.ets)：验证取消所有请求成功

### 边界测试用例
- [取消已完成的请求](tests/test_cancel_completed_request.ets)：验证取消已完成请求不报错
- [取消未发起的请求](tests/test_cancel_unsent_request.ets)：验证取消未发起请求不报错
- [空会话调用cancel](tests/test_cancel_empty_session.ets)：验证空会话调用cancel不报错

### 异常测试用例
- [传入无效Request对象](tests/test_cancel_invalid_request.ets)：验证抛出401错误码
- [传入不属于当前会话的Request](tests/test_cancel_other_session_request.ets)：验证抛出401错误码
- [会话关闭后调用cancel](tests/test_cancel_after_session_close.ets)：验证调用失败