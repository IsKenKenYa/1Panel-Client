---
name: hmos-remote-communication-kit-custom-processconfig
description: 定制HTTP响应处理行为，通过ProcessingConfiguration配置validateResponse回调函数对响应进行校验，支持自定义响应状态码验证逻辑，适用于需要自定义响应验证规则的HTTP请求场景
---

# ProcessingConfiguration定制处理行为技能

## 功能描述

ProcessingConfiguration是Remote Communication Kit中用于定制HTTP响应处理行为的配置组件。它允许开发者通过validateResponse回调函数自定义响应验证逻辑，在消息被分发到处理器之前或之后执行自定义校验。典型应用场景包括验证HTTP状态码是否为200、检查响应头是否包含特定字段、验证响应体格式是否符合预期等。

该功能支持Phone、2in1、Tablet、Wearable设备，从API 5.1.1(19)开始支持TV设备，从API 6.1.0(23)开始支持Car设备。

## 使用场景

### 触发词
- "定制HTTP响应处理"
- "ProcessingConfiguration配置"
- "自定义响应校验"
- "validateResponse回调"
- "HTTP响应验证"
- "响应状态码校验"

### 能做
- 创建ProcessingConfiguration配置对象
- 定义validateResponse回调函数验证响应
- 将ProcessingConfiguration应用到Request或Session配置中
- 根据validateResponse返回值决定请求成功或失败流程
- 实现自定义的响应验证逻辑（状态码、响应头、响应体等）

### 绝不做
- 不处理与HTTP响应验证无关的请求配置
- 不替代HTTP拦截器功能（Interceptor）
- 不处理请求发送前的预处理逻辑
- 不用于修改请求参数或URL

### 补充
- validateResponse返回true时执行then方法处理成功响应
- validateResponse返回false时执行catch方法处理错误
- ProcessingConfiguration可通过Request.configuration或SessionConfiguration.requestConfiguration配置
- 支持同步和异步（Promise）两种验证方式

## 调用规范和规则

### 输入约束
- URL格式：必须为有效的HTTP/HTTPS URL字符串
- 回调函数：validateResponse必须为函数类型，返回boolean或Promise<boolean>
- Response对象：回调函数接收完整的rcp.Response对象作为参数

### 执行约束
- API版本：最低要求API 5.0.0(12)
- Session数量：最多可创建1024个session实例（API 5.1.0+）
- 请求超时：默认连接超时60000ms，传输超时60000ms
- 必须在请求完成后关闭session释放资源

### 内容约束
- 禁止在validateResponse中执行耗时操作（建议<100ms）
- 禁止在回调中修改Response对象内容
- 禁止使用高危函数（eval、exec等）
- 回调函数必须明确返回boolean值

### 降级约束
- validateResponse未配置时使用默认行为（不验证）
- 校验失败时进入catch流程，需提供友好的错误提示
- 网络异常时自动触发错误处理流程
- Session创建失败时需检查数量限制（最多1024个）

## 调用流程和步骤

### 步骤1：导入必要模块

**前置校验**：
1. 确认项目支持API 5.0.0(12)及以上版本
2. 确认设备类型在支持范围内
3. 确认已配置ohos.permission.INTERNET权限

**参数准备**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：创建Session和Request对象

**示例代码**：
```typescript
const session = rcp.createSession();
const request = new rcp.Request('https://www.example.com/api/data');

request.headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer your_token_here'
};
```

### 步骤3：定义ProcessingConfiguration配置

**示例代码**：
```typescript
const processing: rcp.ProcessingConfiguration = {
  validateResponse: (response: rcp.Response): boolean => {
    return response.statusCode === 200;
  },
};

request.configuration = {
  processing: processing,
};
```

### 步骤4：发送请求并处理响应

**示例代码**：
```typescript
session.fetch(request).then((response: rcp.Response) => {
  if (response) {
    console.info(`Response received with status code: ${response.statusCode}`);
    console.info(`Response headers: ${JSON.stringify(response.headers)}`);
    if (response.body) {
      console.info(`Response body length: ${response.body.byteLength}`);
    }
  } else {
    console.error('No response received');
  }
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

### 步骤5：错误处理和降级方案

**示例代码**：
```typescript
async function fetchWithValidation(url: string): Promise<void> {
  let session: rcp.Session | null = null;
  try {
    session = rcp.createSession();
    const request = new rcp.Request(url);
    
    request.configuration = {
      processing: {
        validateResponse: (response: rcp.Response): boolean => {
          if (response.statusCode !== 200) {
            console.warn(`Unexpected status code: ${response.statusCode}`);
            return false;
          }
          if (!response.body || response.body.byteLength === 0) {
            console.warn('Empty response body');
            return false;
          }
          return true;
        }
      }
    };
    
    const response = await session.fetch(request);
    console.info('Validation passed, processing response data');
    
  } catch (error) {
    const err = error as BusinessError;
    if (err.code === 1007900994) {
      console.error('Session limit reached, close existing sessions');
    } else if (err.code === 401) {
      console.error('Parameter error, check request configuration');
    } else {
      console.error(`Network error: ${err.message}`);
    }
  } finally {
    if (session) {
      session.close();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，Request或ProcessingConfiguration配置不正确 | 检查URL格式、回调函数类型、配置对象结构 |
| 1007900994 | Session数量达到上限（1024个） | 关闭不用的session释放资源，减少并发session数量 |
| validateResponse返回false | 响应验证失败 | 检查validateResponse逻辑，确认响应是否符合预期 |
| 网络超时 | 连接或传输超时（默认60000ms） | 增加timeout配置或检查网络连接状态 |
| 权限不足 | 缺少ohos.permission.INTERNET权限 | 在module.json5中添加权限配置 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "5.0.0(12)+",
    "@kit.BasicServicesKit": "5.0.0(12)+"
  }
}
```

### 环境要求
- DevEco Studio: 5.0+
- HarmonyOS SDK: API 12+
- 目标设备: Phone, 2in1, Tablet, Wearable (TV from API 19, Car from API 23)

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：确保项目SDK版本≥API 12，在build-profile.json5中配置正确的compileSdkVersion

**问题2：ProcessingConfiguration类型错误**
```
Type 'ProcessingConfiguration' is not defined
```
**解决方法**：确认导入语句正确，检查SDK版本是否支持该类型（需要API 12+）

**问题3：validateResponse回调类型错误**
```
Type '(response: Response) => void' is not assignable to type 'ResponseValidationCallback'
```
**解决方法**：确保回调函数返回boolean或Promise<boolean>类型

**问题4：Session创建失败**
```
Error code: 1007900994 - Sessions number reached limit
```
**解决方法**：检查并关闭未使用的session，确保同时运行的session数量<1024

## 常见问题与解决方法

### Q1：validateResponse返回false但请求实际成功
**原因**：validateResponse逻辑判断条件过于严格或错误
**解决方法**：
- 检查statusCode判断逻辑，确认预期值
- 检查Response对象其他字段是否需要验证
- 添加日志输出response内容便于调试

### Q2：响应验证逻辑过于复杂导致性能问题
**原因**：在validateResponse中执行了耗时操作
**解决方法**：
- 简化验证逻辑，只检查必要字段
- 将复杂验证逻辑移到then回调中处理
- 避免在回调中进行大量数据解析

### Q3：Session未关闭导致资源泄漏
**原因**：忘记调用session.close()释放资源
**解决方法**：
- 在finally块中确保session.close()被调用
- 使用try-catch-finally完整处理异常流程
- 建议每个请求完成后立即关闭session

### Q4：异步validateResponse处理不当
**原因**：使用Promise返回值但未正确处理异步流程
**解决方法**：
- 确保async函数正确返回Promise<boolean>
- 使用await或.then()处理异步验证结果
- 注意async回调的异常处理

### Q5：多个请求共用同一ProcessingConfiguration
**原因**：希望复用配置但担心状态管理问题
**解决方法**：
- ProcessingConfiguration可安全复用，无状态依赖
- 建议为不同验证需求创建不同配置对象
- 可通过SessionConfiguration统一配置多个请求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "validationPassed": true,
  "statusCode": 200,
  "responseHeaders": {
    "Content-Type": "application/json",
    "Content-Length": "1024"
  },
  "responseBodySize": 1024,
  "sessionClosed": true,
  "apiUsed": [
    "rcp.createSession()",
    "rcp.Request",
    "rcp.ProcessingConfiguration",
    "session.fetch()",
    "session.close()"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-customprocessconfig)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [ArkTS示例](assets/example_custom_processing.ets)
- [配置示例](assets/config_example.json)

## 测试用例

### 正向测试用例
- [状态码200验证](tests/test_status_200.ets)：验证HTTP 200响应成功处理
- [响应体非空验证](tests/test_body_not_empty.ets)：验证响应体不为空的场景
- [多条件验证](tests/test_multiple_conditions.ets)：同时验证状态码和响应头

### 边界测试用例
- [状态码边界值](tests/test_status_boundary.ets)：测试非200状态码处理（201, 204等）
- [空响应体](tests/test_empty_body.ets)：测试空响应体验证逻辑
- [超大响应](tests/test_large_response.ets)：测试大响应体验证性能

### 异常测试用例
- [网络异常](tests/test_network_error.ets)：测试网络失败时的错误处理
- [参数错误](tests/test_param_error.ets)：测试错误的配置参数处理
- [Session限制](tests/test_session_limit.ets)：测试Session数量达到上限的情况