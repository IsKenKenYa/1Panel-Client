---
name: hmos-remote-communication-kit-processing-config
description: 定制HTTP响应处理行为+支持响应状态码校验+适用于HTTP请求成功判断场景+从API版本5.0.0(12)开始支持
---

# ProcessingConfiguration：定制处理行为技能

## 功能描述

ProcessingConfiguration是Remote Communication Kit中用于定制HTTP响应处理行为的核心组件。通过ProcessingConfiguration，开发者可以在HTTP响应被处理之前执行自定义校验逻辑，例如验证响应状态码是否为200，检查响应头信息，验证响应体内容等。该功能提供了灵活的响应校验机制，帮助开发者实现更精确的HTTP请求成功判断标准。

主要特性：
- 响应校验回调函数：通过validateResponse回调函数自定义响应校验逻辑
- 异步校验支持：校验函数支持同步和异步两种返回方式
- 状态码校验：可校验响应状态码是否满足特定条件
- 响应头校验：可校验响应头信息是否符合预期
- 响应体校验：可校验响应体内容是否正确

## 使用场景

### 触发词
- "校验HTTP响应状态码"
- "验证响应是否为200"
- "定制响应处理行为"
- "响应校验"
- "ProcessingConfiguration"

### 能做
- 校验HTTP响应状态码是否为200或其他成功状态码范围
- 校验响应头信息，例如Content-Type、Content-Length等
- 校验响应体内容是否符合预期格式或数据结构
- 实现自定义的HTTP请求成功判断标准
- 在响应处理失败时提供明确的错误信息

### 绝不做
- 不修改HTTP请求的发送过程
- 不修改HTTP响应的内容
- 不处理网络连接或超时相关的配置
- 不替代HTTP请求的基本功能（fetch、get、post等）

### 补充
- 支持设备：Phone、2in1、Tablet、Wearable（5.0.0(12)）、TV（5.1.1(19)）、Car（6.1.0(23)）
- API版本要求：从API版本5.0.0(12)开始支持
- ProcessingConfiguration仅用于响应校验，不影响请求发送过程
- 校验失败时，会触发catch方法处理错误，并提供详细的错误信息

## 调用规范和规则

### 输入约束
- URL格式：必须是有效的HTTP/HTTPS URL字符串或URL对象
- 回调函数：validateResponse必须是函数类型，返回boolean或Promise<boolean>
- Response对象：校验函数接收的response参数必须是有效的rcp.Response对象

### 执行约束
- 校验时机：在HTTP响应返回后、被分发到处理器之前执行校验
- 校验耗时：建议校验逻辑耗时不超过1000ms，避免影响请求处理性能
- 异步校验：如果使用异步校验，需确保Promise正确resolve或reject
- 错误处理：校验失败时必须正确处理BusinessError错误对象

### 内容约束
- 禁止修改：禁止在validateResponse回调中修改response对象的内容
- 禁止阻塞：禁止在校验函数中执行长时间阻塞操作
- 禁止网络请求：禁止在校验函数中发起额外的网络请求
- 禁止高危操作：禁止使用eval、exec等高危函数处理响应数据

### 降级约束
- 校验失败：如果validateResponse返回false，请求会触发catch方法处理错误
- 校验超时：如果异步校验Promise未及时返回，可能导致请求挂起
- 异常处理：如果校验函数抛出异常，需要捕获并处理BusinessError

## 调用流程和步骤

### 步骤1：导入必要模块

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：创建HTTP会话和请求对象

```typescript
const session = rcp.createSession();
const request = new rcp.Request('https://www.example.com');
```

### 步骤3：定义ProcessingConfiguration配置

```typescript
const processing: rcp.ProcessingConfiguration = {
  validateResponse: (response: rcp.Response): boolean => {
    return response.statusCode === 200;
  },
};
```

### 步骤4：将ProcessingConfiguration应用到请求配置

```typescript
request.configuration = {
  processing: processing,
};
```

### 步骤5：发送请求并处理响应

```typescript
session.fetch(request).then((response: rcp.Response) => {
  if (response) {
    console.info(`Response received with status code: ${response.statusCode}`);
    console.info(`Response headers: ${JSON.stringify(response.headers)}`);
  } else {
    console.error('No response received');
  }
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

### 步骤6：完整示例（包含响应头和响应体校验）

```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function validateHttpResponse(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com/api/data');
  
  const processing: rcp.ProcessingConfiguration = {
    validateResponse: async (response: rcp.Response): Promise<boolean> => {
      if (response.statusCode !== 200) {
        console.error(`Status code validation failed: ${response.statusCode}`);
        return false;
      }
      
      const contentType = response.headers['content-type'];
      if (!contentType || !contentType.includes('application/json')) {
        console.error('Content-Type validation failed');
        return false;
      }
      
      return true;
    },
  };
  
  request.configuration = {
    processing: processing,
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Response validation succeeded`);
    console.info(`Status code: ${response.statusCode}`);
    console.info(`Response body length: ${response.body?.byteLength || 0}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Request failed with error code: ${error.code}`);
    console.error(`Error message: ${error.data}`);
  } finally {
    session.close();
  }
}

validateHttpResponse();
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，validateResponse回调函数格式不正确 | 确保validateResponse是函数类型，且返回boolean或Promise<boolean> |
| 1007900001 | 网络请求失败 | 检查网络连接状态，确保URL可访问 |
| 1007900002 | 超时错误 | 检查TransferConfiguration的timeout设置，适当增加超时时间 |
| 1007900003 | SSL/TLS证书验证失败 | 检查SecurityConfiguration配置，确保证书验证正确 |
| 1007900004 | HTTP状态码校验失败 | 检查validateResponse回调函数的校验逻辑，确保状态码校验条件正确 |
| 1007900005 | 响应头校验失败 | 检查响应头校验逻辑，确保响应头格式和内容符合预期 |
| 1007900006 | 响应体校验失败 | 检查响应体内容和格式，确保数据结构正确 |
| 1007900994 | Session数量达到上限 | 关闭不再使用的Session实例，确保Session数量不超过1024个 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": ">=5.0.0",
    "@kit.BasicServicesKit": ">=5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：>=5.0.0(12)
- DevEco Studio版本：>=5.0.0
- ArkTS编译器版本：>=5.0.0

### 常见编译问题

**问题1：找不到rcp模块**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：确保项目配置文件中已添加Remote Communication Kit依赖，API版本>=5.0.0(12)

**问题2：ProcessingConfiguration类型错误**
```
Error: Type 'ProcessingConfiguration' is not defined
```
**解决方法**：确保导入rcp模块，并使用rcp.ProcessingConfiguration类型声明

**问题3：validateResponse回调函数返回值类型错误**
```
Error: Type 'void' is not assignable to type 'boolean | Promise<boolean>'
```
**解决方法**：确保validateResponse回调函数明确返回boolean值或Promise<boolean>，不要遗漏return语句

**问题4：BusinessError类型未导入**
```
Error: Cannot find name 'BusinessError'
```
**解决方法**：添加导入语句 `import { BusinessError } from '@kit.BasicServicesKit';`

## 常见问题与解决方法

### Q1：validateResponse回调函数未触发？

**原因**：ProcessingConfiguration未正确应用到请求配置中，或请求配置未传递给fetch方法

**解决方法**：
- 确保ProcessingConfiguration已正确赋值到request.configuration.processing
- 确保request对象已传递给session.fetch方法
- 检查request.configuration是否为undefined

### Q2：校验失败但未触发catch方法？

**原因**：validateResponse回调函数返回了true，但校验逻辑有误

**解决方法**：
- 检查validateResponse回调函数的校验逻辑是否正确
- 添加console.log调试信息，打印response.statusCode和response.headers
- 确保校验条件符合实际业务需求

### Q3：异步校验函数Promise未resolve？

**原因**：异步校验函数中使用了await但未正确处理Promise

**解决方法**：
- 确保async函数明确返回boolean值
- 检查await语句是否正确处理Promise
- 添加try-catch处理异步校验中的异常

### Q4：校验函数执行时间过长影响性能？

**原因**：校验逻辑过于复杂，或在校验函数中执行了耗时操作

**解决方法**：
- 简化校验逻辑，仅校验必要的信息
- 避免在校验函数中执行复杂的计算或数据处理
- 考虑将复杂校验逻辑移到请求成功后的业务处理阶段

### Q5：如何校验响应体的JSON数据格式？

**原因**：需要校验响应体是否为有效的JSON格式数据

**解决方法**：
```typescript
validateResponse: async (response: rcp.Response): Promise<boolean> => {
  try {
    if (response.statusCode !== 200) return false;
    if (!response.body) return false;
    
    const decoder = new TextDecoder('utf-8');
    const jsonString = decoder.decode(response.body);
    JSON.parse(jsonString);
    return true;
  } catch (e) {
    console.error('JSON validation failed:', e);
    return false;
  }
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "statusCode": 200,
  "validationResult": true,
  "responseHeaders": {
    "content-type": "application/json",
    "content-length": "1024"
  },
  "responseBodyLength": 1024,
  "sessionClosed": true,
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "rcp.ProcessingConfiguration",
    "session.fetch",
    "session.close"
  ]
}
```

## 参考文档

- [API开发指南：ProcessingConfiguration定制处理行为](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-customprocessconfig)
- [API参考说明：ProcessingConfiguration](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：ResponseValidationCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：Response](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 完整示例代码

- [ArkTS示例：基础状态码校验](assets/example_basic_status_validation.ets)
- [ArkTS示例：响应头校验](assets/example_header_validation.ets)
- [ArkTS示例：异步校验](assets/example_async_validation.ets)
- [ArkTS示例：完整校验流程](assets/example_complete_validation.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [状态码200校验成功](tests/test_positive_status_200.ets)：验证status code为200时校验成功
- [响应头Content-Type校验](tests/test_positive_content_type.ets)：验证响应头Content-Type为application/json时校验成功
- [异步校验成功](tests/test_positive_async_validation.ets)：验证异步校验函数正确返回Promise<boolean>

### 边界测试用例
- [状态码边界值校验](tests/test_boundary_status_code.ets)：验证状态码为200-299范围内校验成功
- [响应体空值校验](tests/test_boundary_empty_body.ets)：验证响应体为空时的校验逻辑
- [响应头不存在校验](tests/test_boundary_missing_header.ets)：验证响应头不存在时的校验逻辑

### 异常测试用例
- [状态码404校验失败](tests/test_exception_status_404.ets)：验证status code为404时校验失败并触发catch
- [响应头格式错误校验](tests/test_exception_invalid_header.ets)：验证响应头格式不符合预期时校验失败
- [校验函数异常](tests/test_exception_validation_error.ets)：验证校验函数抛出异常时的错误处理
- [网络请求失败](tests/test_exception_network_failure.ets)：验证网络请求失败时的错误处理