---
name: hmos-remote-communication-kit-http-request
description: 发送HTTP网络请求+支持GET/POST/PUT/HEAD/DELETE等方法+最大支持1024个session实例+适用于RESTful API调用、数据提交、文件上传下载场景
---

# 发送网络请求（ArkTS）技能

## 功能描述

本技能提供HarmonyOS Remote Communication Kit的HTTP网络请求功能,支持多种HTTP方法(GET、POST、PUT、HEAD、DELETE)发送网络请求,并返回服务器响应。支持Form和MultipartForm表单数据发送,支持自定义请求头、请求体、Cookie等参数。使用Promise异步回调,适用于RESTful API调用、数据提交、文件上传下载等场景。

**核心能力**:
- 发送HTTP请求(fetch、get、post、put、head、delete方法)
- 创建和管理HTTP会话(Session)
- 配置请求参数(Request对象)
- 处理响应数据(Response对象)
- 发送表单数据(Form、MultipartForm)
- 设置请求拦截器(Interceptor)

## 使用场景

### 触发词
- "发送HTTP请求"
- "发起网络请求"
- "GET请求"
- "POST请求"
- "PUT请求"
- "HEAD请求"
- "DELETE请求"
- "提交表单数据"
- "发送网络数据"
- "调用RESTful API"
- "Remote Communication Kit"

### 能做
- 发送各种HTTP方法请求(GET/POST/PUT/HEAD/DELETE)
- 创建HTTP会话并管理请求生命周期
- 配置请求参数(URL、method、headers、content、cookies)
- 发送表单数据(Form和MultipartForm)
- 处理服务器响应(statusCode、headers、body)
- 设置请求/响应拦截器
- 支持异步请求(Promise回调)
- 支持同步读取队列(NetworkOutputQueue)
- 支持文件上传下载(downloadToFile、uploadFromFile)
- 支持流式传输(downloadToStream、uploadFromStream)

### 绝不做
- 不处理WebSocket通信(需使用WebSocket API)
- 不处理TCP/UDP原始 socket通信(需使用Socket API)
- 不处理蓝牙/NFC等近场通信(需使用相应Kit)
- 不处理超出1024个session实例的并发请求
- 不处理超过系统限制的大文件传输
- 不处理需要特殊权限的网络请求(如蜂窝网络需要GET_NETWORK_INFO权限)

### 补充
- 支持Phone、2in1、Tablet、Wearable设备
- 从5.1.1(19)开始支持TV设备
- 从6.1.0(23)开始支持Car设备
- 需要ohos.permission.INTERNET权限
- 使用蜂窝网络需要ohos.permission.GET_NETWORK_INFO权限
- API起始版本: 4.1.0(11)
- 从5.1.0(18)开始,session实例数量从16增加到1024
- 应用应及时关闭session,保证资源合理利用

## 调用规范和规则

### 输入约束
- URL格式: 必须为有效的HTTP/HTTPS URL字符串或URL对象
- HTTP方法: 必须为'GET'、'POST'、'PUT'、'HEAD'、'DELETE'、'PATCH'、'OPTIONS'之一
- Session数量: 最大1024个并发session实例
- 文件大小: 系统限制范围内(无明确上限,建议不超过100MB)
- 请求头: 符合HTTP协议规范,键值对形式
- 表单数据: Form支持简单键值对,MultipartForm支持多部分数据

### 执行约束
- 最大耗时: 由transfer.timeout配置决定(默认连接5秒,传输10秒)
- 最大重定向次数: 默认50次,最大2147483647次
- 并发连接数: 单主机最大6个,总最大64个TCP连接
- Session生命周期: 需手动创建和关闭
- 异步回调: 使用Promise异步模式

### 内容约束
- 禁止生成: WebSocket、Socket、蓝牙、NFC相关代码
- 禁止高危函数: 不使用eval、exec、系统命令执行
- 禁止操作: 不直接操作底层网络协议
- 必须校验: URL格式、HTTP方法、参数类型
- 必须捕获: 所有异步操作的异常和错误

### 降级约束
- 网络失败: 捕获错误码,提供友好错误提示
- Session超限: 提示关闭已有session或等待
- 文件过大: 建议分片上传或使用流式传输
- 权限不足: 提示申请必要权限(INTERNET、GET_NETWORK_INFO)
- 请求超时: 提示调整timeout配置或检查网络

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 验证设备类型支持(Phone/Tablet/Wearable等)
2. 验证API版本兼容性(最低4.1.0(11))
3. 验证权限配置(ohos.permission.INTERNET)
4. 验证URL格式有效性
5. 验证HTTP方法有效性

**参数准备**:
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 配置请求参数
const requestURL = 'https://www.example.com/api'; // 替换为实际URL
const requestMethod = 'GET'; // 或 'POST', 'PUT', 'HEAD', 'DELETE'
const requestHeaders = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer token'
};
const requestContent = {
  fields: {
    'key1': 'value1',
    'key2': 'value2'
  }
};
```

### 步骤2: 创建HTTP会话

**示例代码**:
```typescript
// 创建会话(简单模式)
const session = rcp.createSession();

// 创建会话(配置模式)
const sessionConfig: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      autoRedirect: true,
      timeout: {
        connectMs: 5000,
        transferMs: 10000
      }
    },
    tracing: {
      verbose: true
    }
  },
  headers: {
    'Authorization': 'Bearer YOUR_ACCESS_TOKEN'
  },
  cookies: {
    'session_id': 'abc123'
  }
};
const session = rcp.createSession(sessionConfig);
```

### 步骤3: 发送HTTP请求

**使用fetch方法**:
```typescript
// 创建Request对象
const request = new rcp.Request(requestURL, requestMethod, requestHeaders, requestContent);

// 发送请求并处理响应
session.fetch(request).then((response: rcp.Response) => {
  console.info(`Response succeeded: statusCode=${response.statusCode}`);
  console.info(`Response headers: ${JSON.stringify(response.headers)}`);
  console.info(`Response body: ${JSON.stringify(response.body)}`);
  
  // 处理响应数据
  if (response.statusCode === 200) {
    // 成功处理
    const data = response.body;
    // 业务逻辑处理
  } else {
    // 错误状态码处理
    console.error(`HTTP error: ${response.statusCode}`);
  }
}).catch((err: BusinessError) => {
  // 错误处理
  console.error(`Request failed: code=${err.code}, message=${err.data}`);
}).finally(() => {
  // 关闭会话
  session.close();
});
```

**使用get方法**:
```typescript
const session = rcp.createSession();
session.get(requestURL).then((response: rcp.Response) => {
  console.info(`GET succeeded: ${JSON.stringify(response)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`GET failed: code=${err.code}, data=${err.data}`);
  session.close();
});
```

**使用post方法**:
```typescript
const session = rcp.createSession();
const postContent: rcp.RequestContent = {
  fields: {
    'username': 'user1',
    'password': 'pass123'
  }
};
session.post(requestURL, postContent).then((response: rcp.Response) => {
  console.info(`POST succeeded: statusCode=${response.statusCode}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`POST failed: code=${err.code}, data=${err.data}`);
  session.close();
});
```

### 步骤4: 发送表单数据

**使用Form表单**:
```typescript
const session = rcp.createSession();

// 创建Form表单数据
const simpleForm = new rcp.Form({
  'key1': 'value1',
  'key2': 'value2'
});

// 指定表单key的发送顺序
simpleForm.keys = ['key2', 'key1'];

// 创建request请求
let req = new rcp.Request('http://example.com');
req.content = simpleForm;

session.fetch(req).then((resp: rcp.Response) => {
  console.info(`Form request succeeded: ${JSON.stringify(resp)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`Form request failed: code=${err.code}, data=${err.data}`);
  session.close();
});
```

**使用MultipartForm表单**:
```typescript
const session = rcp.createSession();

// 创建MultipartForm多部分表单数据
const multiForm = new rcp.MultipartForm({
  'key1': 'value1',
  'key2': 'value2',
  'key3': 'value3'
});

// 定义键的顺序
multiForm.keys = ['key3', 'key1', 'key2'];

// 创建request请求
let req = new rcp.Request('http://example.com');
req.content = multiForm;

session.fetch(req).then((resp: rcp.Response) => {
  console.info(`MultipartForm request succeeded: ${JSON.stringify(resp)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`MultipartForm request failed: code=${err.code}, data=${err.data}`);
  session.close();
});
```

### 步骤5: 错误处理

**错误码处理**:
```typescript
try {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com', 'GET');
  
  await session.fetch(request).then((response) => {
    // 成功处理
  }).catch((err: BusinessError) => {
    // 根据错误码处理
    switch (err.code) {
      case 401:
        console.error('Parameter error: Invalid request parameters');
        break;
      case 1007900994:
        console.error('Sessions number reached limit: Max 1024 sessions');
        break;
      default:
        console.error(`Unknown error: code=${err.code}, message=${err.data}`);
    }
  });
  
  session.close();
} catch (error) {
  console.error(`Exception caught: ${JSON.stringify(error)}`);
}
```

### 步骤6: 降级处理

**网络失败降级**:
```typescript
async function sendRequestWithFallback(url: string): Promise<void> {
  const session = rcp.createSession();
  
  try {
    // 主请求
    const response = await session.get(url);
    console.info('Primary request succeeded');
    session.close();
  } catch (primaryError) {
    console.error(`Primary request failed: ${primaryError.message}`);
    
    // 降级方案1: 增加超时时间
    try {
      const config: rcp.SessionConfiguration = {
        requestConfiguration: {
          transfer: {
            timeout: {
              connectMs: 10000,
              transferMs: 30000
            }
          }
        }
      };
      const retrySession = rcp.createSession(config);
      const retryResponse = await retrySession.get(url);
      console.info('Retry with extended timeout succeeded');
      retrySession.close();
    } catch (retryError) {
      console.error('Retry failed, using offline data');
      // 降级方案2: 使用本地缓存或离线数据
      // loadFromCache();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查请求参数是否正确,验证URL、method、headers等参数格式 |
| 1007900994 | Sessions number reached limit | 关闭不必要的session,或等待其他session释放,最大支持1024个session |
| 网络错误 | 网络连接失败 | 检查网络连接,验证权限配置,调整timeout参数 |
| 超时错误 | 请求超时 | 增加timeout配置,检查服务器响应速度,考虑使用异步处理 |
| SSL错误 | 证书验证失败 | 配置正确的证书,或使用skipCertificatesValidation(仅测试环境) |
| 权限错误 | 缺少必要权限 | 申请ohos.permission.INTERNET权限,如使用蜂窝网络需申请GET_NETWORK_INFO权限 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "4.1.0(11)+",
    "@kit.BasicServicesKit": "4.1.0(11)+"
  }
}
```

### 环境要求
- HarmonyOS API版本: 最低4.1.0(11)
- 设备类型: Phone、Tablet、Wearable、2in1(5.1.1(19)支持TV,6.1.0(23)支持Car)
- 权限配置: ohos.permission.INTERNET
- 开发工具: DevEco Studio 3.1+

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**: 确保HarmonyOS SDK版本>=4.1.0(11),在DevEco Studio中配置正确的SDK路径

**问题2: Session创建失败**
```
Error: Sessions number reached limit (1007900994)
```
**解决方法**: 关闭不必要的session实例,确保session总数不超过1024个,及时调用session.close()

**问题3: 权限不足**
```
Error: Permission denied
```
**解决方法**: 在module.json5中添加权限声明:
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**问题4: 网络请求超时**
```
Error: Timeout exceeded
```
**解决方法**: 调整timeout配置:
```typescript
const config: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 10000,
        transferMs: 60000
      }
    }
  }
};
```

## 常见问题与解决方法

### Q1: Session创建后没有及时关闭导致资源泄漏
**原因**: Session数量有限(最大1024),不及时关闭会占用资源
**解决方法**:
- 在请求完成后调用`session.close()`
- 使用finally块确保session关闭
- 建议封装为工具类统一管理session生命周期

### Q2: 网络请求返回空响应或undefined
**原因**: URL无效、网络不通、服务器无响应
**解决方法**:
- 验证URL格式和可访问性
- 检查网络连接状态
- 使用try-catch捕获异常
- 增加详细的日志输出便于调试

### Q3: Form表单数据发送顺序不符合预期
**原因**: 默认按key的hash顺序发送
**解决方法**:
- 使用`form.keys`属性指定发送顺序
- 从6.0.1(21)开始支持keys顺序配置

### Q4: 大文件上传下载失败
**原因**: 文件过大、内存不足、超时
**解决方法**:
- 使用`downloadToFile`和`uploadFromFile`方法
- 使用流式传输`downloadToStream`和`uploadFromStream`
- 分片处理大文件
- 增加timeout配置

### Q5: HTTPS请求证书验证失败
**原因**: 证书不匹配、自签名证书
**解决方法**:
- 配置正确的CA证书
- 使用`remoteValidation: 'skip'`跳过验证(仅测试环境)
- 配置`CertificateAuthority`指定证书

## 输出结果报告

执行完成后输出以下信息:

```typescript
interface HttpRequestResult {
  status: 'success' | 'failed' | 'timeout' | 'error';
  statusCode?: number;
  headers?: Record<string, string>;
  body?: string | ArrayBuffer | object;
  errorMessage?: string;
  errorCode?: number;
  apiUsed: string[];
  sessionUsed: string;
  requestDuration?: number;
}

// 示例输出
{
  "status": "success",
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json",
    "Server": "nginx"
  },
  "body": "{\"data\": \"success\"}",
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "session.fetch",
    "session.close"
  ],
  "sessionUsed": "session-123",
  "requestDuration": 150
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-netsend-arkts)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [错误码文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 完整示例代码

- [基础HTTP请求示例](assets/basic_http_request.ets)
- [表单数据发送示例](assets/form_data_request.ets)
- [文件上传下载示例](assets/file_transfer.ets)
- [拦截器配置示例](assets/interceptor_example.ets)
- [错误处理示例](assets/error_handling.ets)

## 测试用例

### 正向测试用例
- [GET请求成功测试](tests/test_get_success.ets): 测试正常GET请求返回200响应
- [POST请求成功测试](tests/test_post_success.ets): 测试正常POST请求提交数据
- [Form表单发送测试](tests/test_form_success.ets): 测试Form表单数据正确发送
- [Session管理测试](tests/test_session_management.ets): 测试Session创建和关闭

### 边界测试用例
- [最大Session数量测试](tests/test_max_sessions.ets): 测试1024个session实例限制
- [超时配置测试](tests/test_timeout.ets): 测试不同timeout配置效果
- [大文件上传测试](tests/test_large_file.ets): 测试大文件上传边界

### 异常测试用例
- [无效URL测试](tests/test_invalid_url.ets): 测试无效URL的错误处理
- [网络失败测试](tests/test_network_failure.ets): 测试网络断开的降级处理
- [权限不足测试](tests/test_permission_denied.ets): 测试缺少权限的错误提示
- [参数错误测试](tests/test_parameter_error.ets): 测试401错误码处理