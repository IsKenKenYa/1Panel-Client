---
name: hmos-network-kit-http-request
description: 发起HTTP网络请求，支持GET/POST/OPTIONS/HEAD/PUT/DELETE/TRACE/CONNECT方法，支持数据请求、流式传输、WebDAV协议、证书校验和拦截器，适用于网络数据传输、文件上传下载场景
---

# 使用HTTP访问网络技能

## 功能描述

本技能提供HTTP网络请求能力，应用可以通过HTTP发起数据请求，支持常见的GET、POST、OPTIONS、HEAD、PUT、DELETE、TRACE、CONNECT方法。当前提供了2种HTTP请求方式：
- **HttpRequest.request**：适用于请求发送或接收的数据量较少的场景
- **HttpRequest.requestInStream**：适用于大文件的上传或下载，且关注数据发送和接收进度的场景

从API version 22开始，支持HTTP拦截器，可以在"HTTP请求-响应"生命周期中的关键节点插入自定义逻辑。

从API version 23开始，支持WebDAV协议的文件访问，支持对远程服务器上的文件进行创建、读取、更新、删除、移动、复制等操作。

HTTP模块提供了标准的HTTP网络服务能力，Remote Communication Kit（远场通信服务）提供了场景化的网络服务能力，应用可根据自己的需要选择使用。

## 使用场景

### 触发词
- "HTTP请求" - 发起HTTP数据请求
- "发起HTTP请求" - 创建HttpRequest对象并发起请求
- "HTTP数据请求" - 使用request方法进行数据请求
- "HTTP流式传输" - 使用requestInStream方法进行流式传输
- "HTTP上传文件" - 使用multiFormDataList上传文件
- "HTTP下载文件" - 使用流式传输下载文件
- "WebDAV请求" - 发起WebDAV协议请求
- "HTTP拦截器" - 使用拦截器在请求生命周期中插入自定义逻辑
- "证书校验" - 配置HTTPS证书校验和证书锁定
- "网络请求" - 通用的网络请求场景

### 能做
- 发起HTTP/HTTPS数据请求（GET/POST/PUT/DELETE等）
- 发起HTTP流式传输请求（支持进度回调）
- 上传文件（支持multipart/form-data）
- 下载文件（支持流式接收和进度监控）
- 发起WebDAV协议请求（PUT/GET/MKCOL/DELETE/MOVE/COPY/LOCK/UNLOCK等）
- 配置证书校验和证书锁定
- 配置HTTP拦截器（INITIAL_REQUEST/NETWORK_CONNECT/CACHE_CHECKED/REDIRECTION/FINAL_RESPONSE）
- 订阅HTTP响应头事件
- 配置代理设置（HTTP代理/SOCKS5代理）
- 配置DNS解析（HTTPS DNS/指定DNS服务器）
- 配置超时时间、缓存策略、协议版本等请求参数

### 绝不做
- 不处理WebSocket通信（使用WebSocket模块）
- 不处理Socket通信（使用Socket模块）
- 不处理超出100MB的响应数据（需要拆分或使用流式传输）
- 不处理非HTTP/HTTPS/WebDAV协议的请求
- 不在UI线程中执行长时间的网络请求操作

### 补充
- 每一个HttpRequest对象对应一个HTTP请求任务，不可复用
- 使用完毕后务必调用destroy()方法释放资源，避免内存泄漏
- 需要申请ohos.permission.INTERNET权限
- URL包含中文或其他语言时，需先调用encodeURL(URL)编码
- request方法默认仅支持接收5MB以内的数据，超过5MB需设置maxLimit或使用requestInStream
- HTTP错误码映射关系：2300000 + curl错误码

## 调用规范和规则

### 输入约束
- URL长度：最大2048字符
- 响应数据大小：request方法默认最大5MB，可通过maxLimit设置为100MB，超过100MB需使用requestInStream
- 文件大小：上传/下载文件最大100MB
- 超时时间：默认60000ms，最大可设置为600000ms（10分钟）
- 并发优先级：范围[1,1000]，默认为1
- DNS服务器：最多3个
- 证书锁定：最多配置多个证书PIN码
- 多部分表单：支持多个文件和数据字段

### 执行约束
- 最大耗时：600000ms（10分钟）
- 最大迭代次数：无限制
- API调用频次：无限制，但每个HttpRequest对象只能使用一次
- 必须先创建HttpRequest对象才能发起请求
- 必须在请求完成后调用destroy()方法释放资源
- 必须订阅事件后才能接收回调
- 拦截器必须在发起请求前配置

### 内容约束
- 禁止生成：不生成WebSocket、Socket相关代码
- 禁止使用高危函数：不使用eval、exec等高危函数
- 禁止操作：不在UI线程执行长时间网络操作、不复用HttpRequest对象
- 禁止硬编码：URL、证书路径等不应硬编码，应从配置文件或参数获取
- 禁止明文传输敏感信息：敏感数据应加密后传输

### 降级约束
- 网络失败：提供重试机制或切换备用URL
- 文件过大：使用流式传输或分片上传
- 权限不足：提示用户申请ohos.permission.INTERNET权限
- 超时：调整超时时间或使用流式传输
- 证书校验失败：提供证书锁定配置指导或降级为系统预设证书
- 数据超过5MB：使用requestInStream或设置maxLimit

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否已申请ohos.permission.INTERNET权限
2. 检查URL是否有效（格式正确、协议支持）
3. 检查URL是否包含中文或其他语言，如有则调用encodeURL编码
4. 检查是否需要配置证书校验（HTTPS请求）
5. 检查是否需要配置代理
6. 检查是否需要配置拦截器

**参数准备**：
```typescript
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
```

### 步骤2：创建HttpRequest对象

调用createHttp()方法创建HttpRequest对象。

```typescript
let httpRequest = http.createHttp();
```

### 步骤3：订阅HTTP响应头事件（可选）

调用on()方法订阅HTTP响应头事件，此接口会比request请求先返回。

```typescript
httpRequest.on('headersReceive', (header: Object) => {
  hilog.info(0x0000, 'testTag', `header: ${JSON.stringify(header)}`);
});
```

### 步骤4：配置拦截器（可选，API 22+）

如果需要在HTTP请求-响应生命周期中插入自定义逻辑，可以配置拦截器。

```typescript
let chain: http.HttpInterceptorChain = new http.HttpInterceptorChain();

class CustomInterceptor implements http.HttpInterceptor {
  interceptorType: http.InterceptorType = http.InterceptorType.INITIAL_REQUEST;
  result: boolean = true;
  
  interceptorHandle(reqContext: http.HttpRequestContext, rspContext: http.HttpResponse): Promise<http.ChainContinue> {
    hilog.info(0xFF00, 'customInterceptor', `Original req: ${JSON.stringify(reqContext)}`);
    reqContext.header = { 'content-type': 'application/json' };
    return Promise.resolve(this.result);
  }
}

chain.addChain([new CustomInterceptor(http.InterceptorType.INITIAL_REQUEST, true)]);
chain.apply(httpRequest);
```

### 步骤5：配置请求参数

根据业务需求配置HttpRequestOptions参数。

```typescript
let options: http.HttpRequestOptions = {
  method: http.RequestMethod.POST,
  header: {
    'Content-Type': 'application/json'
  },
  extraData: 'data to send',
  expectDataType: http.HttpDataType.STRING,
  usingCache: true,
  priority: 1,
  connectTimeout: 60000,
  readTimeout: 60000,
  usingProtocol: http.HttpProtocol.HTTP1_1,
  usingProxy: false,
  caPath: '/path/to/cacert.pem',
  clientCert: {
    certPath: '/path/to/client.pem',
    keyPath: '/path/to/client.key',
    certType: http.CertType.PEM,
    keyPassword: 'passwordToKey'
  },
  multiFormDataList: [
    {
      name: 'Part1',
      contentType: 'text/plain',
      data: 'Example data',
      remoteFileName: 'example.txt'
    },
    {
      name: 'Part2',
      contentType: 'text/plain',
      filePath: `${context.filesDir}/fileName.txt`,
      remoteFileName: 'fileName.txt'
    }
  ]
};
```

### 步骤6：发起HTTP请求

#### 6.1 发起HTTP数据请求（使用request方法）

调用request()方法，传入URL地址和可选参数，发起网络请求。

```typescript
httpRequest.request('EXAMPLE_URL', options, (err: BusinessError, data: http.HttpResponse) => {
  if (!err) {
    hilog.info(0x0000, 'testTag', `Result: ${JSON.stringify(data.result)}`);
    hilog.info(0x0000, 'testTag', `code: ${JSON.stringify(data.responseCode)}`);
    hilog.info(0x0000, 'testTag', `header: ${JSON.stringify(data.header)}`);
    hilog.info(0x0000, 'testTag', `cookies: ${JSON.stringify(data.cookies)}`);
    httpRequest.destroy();
  } else {
    hilog.error(0x0000, 'testTag', `error: ${JSON.stringify(err)}`);
    httpRequest.off('headersReceive');
    httpRequest.destroy();
  }
});
```

#### 6.2 发起HTTP流式传输请求（使用requestInStream方法）

适用于大文件的上传或下载，支持进度回调。

```typescript
let res = new ArrayBuffer(0);

httpRequest.on('dataReceive', (data: ArrayBuffer) => {
  const newRes = new ArrayBuffer(res.byteLength + data.byteLength);
  const resView = new Uint8Array(newRes);
  resView.set(new Uint8Array(res));
  resView.set(new Uint8Array(data), res.byteLength);
  res = newRes;
  hilog.info(0x0000, 'testTag', `res length: ${res.byteLength}`);
});

httpRequest.on('dataEnd', () => {
  hilog.info(0x0000, 'testTag', 'No more data in response, data receive end');
});

httpRequest.on('dataReceiveProgress', (data: http.DataReceiveProgressInfo) => {
  hilog.info(0x0000, 'testTag', 'dataReceiveProgress receiveSize:' + data.receiveSize + ', totalSize:' + data.totalSize);
});

httpRequest.on('dataSendProgress', (data: http.DataSendProgressInfo) => {
  hilog.info(0x0000, 'testTag', 'dataSendProgress receiveSize:' + data.sendSize + ', totalSize:' + data.totalSize);
});

let streamInfo: http.HttpRequestOptions = {
  method: http.RequestMethod.POST,
  header: {
    'Content-Type': 'application/json'
  },
  extraData: 'data to send',
  expectDataType: http.HttpDataType.STRING,
  usingCache: true,
  priority: 1,
  connectTimeout: 60000,
  readTimeout: 60000,
  usingProtocol: http.HttpProtocol.HTTP1_1
};

httpRequest.requestInStream('EXAMPLE_URL', streamInfo)
  .then((data: number) => {
    hilog.info(0x0000, 'testTag', `requestInStream OK!`);
    hilog.info(0x0000, 'testTag', `ResponseCode : ${JSON.stringify(data)}`);
    httpRequest.destroy();
  }).catch((err: Error) => {
    hilog.error(0x0000, 'testTag', `requestInStream ERROR : err = ${JSON.stringify(err)}`);
    httpRequest.destroy();
  });
```

#### 6.3 发起WebDAV请求（API 23+）

WebDAV是基于HTTP协议的扩展，支持对远程服务器上的文件进行创建、读取、更新、删除、移动、复制等操作。

```typescript
let httpRequest = http.createHttp();
let file = 'example';

httpRequest.request('EXAMPLE_URL' + 'example.txt',
  {
    expectDataType: http.HttpDataType.STRING,
    extraData: file,
    header: { 'Content-Type': 'text/plain; charset=utf-8', 'Content-Length': file.length.toString() },
    customMethod: 'PUT'
  },
  (err: Error, data: http.HttpResponse) => {
    if (!err) {
      hilog.info(0x0000, 'testTag', 'Result:' + data.result);
      hilog.info(0x0000, 'testTag', 'code:' + data.responseCode);
      hilog.info(0x0000, 'testTag', 'header:' + JSON.stringify(data.header));
      httpRequest.destroy();
    } else {
      hilog.error(0x0000, 'testTag', 'error:' + JSON.stringify(err));
      httpRequest.destroy();
    }
  });
```

### 步骤7：取消订阅事件

调用off()方法取消订阅HTTP响应头事件。

```typescript
httpRequest.off('headersReceive');
```

### 步骤8：销毁HttpRequest对象

当请求使用完毕时，调用destroy()方法销毁HttpRequest对象，释放资源。

```typescript
httpRequest.destroy();
```

### 步骤9：错误处理

处理常见的HTTP错误码。

```typescript
try {
  await httpRequest.request('EXAMPLE_URL', options);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error');
      break;
    case 201:
      hilog.error(0x0000, 'testTag', 'Permission denied');
      break;
    case 2300001:
      hilog.error(0x0000, 'testTag', 'Unsupported protocol');
      break;
    case 2300003:
      hilog.error(0x0000, 'testTag', 'Invalid URL format or missing URL');
      break;
    case 2300007:
      hilog.error(0x0000, 'testTag', 'Failed to connect to the server');
      break;
    case 2300028:
      hilog.error(0x0000, 'testTag', 'Operation timeout');
      break;
    case 2300997:
      hilog.error(0x0000, 'testTag', 'Cleartext traffic not permitted');
      break;
    default:
      hilog.error(0x0000, 'testTag', 'Unknown error: ' + err.message);
  }
}
```

### 步骤10：降级处理

针对异常情况提供降级方案。

```typescript
async function httpRequestWithFallback(url: string, options: http.HttpRequestOptions): Promise<http.HttpResponse> {
  try {
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(url, options);
    httpRequest.destroy();
    return response;
  } catch (error) {
    const err = error as BusinessError;
    if (err.code === 2300007) {
      hilog.warn(0x0000, 'testTag', 'Connection failed, trying alternate URL');
      const alternateUrl = getAlternateUrl(url);
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(alternateUrl, options);
      httpRequest.destroy();
      return response;
    } else if (err.code === 2300028) {
      hilog.warn(0x0000, 'testTag', 'Timeout, adjusting timeout settings');
      options.readTimeout = 120000;
      options.connectTimeout = 120000;
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, options);
      httpRequest.destroy();
      return response;
    } else {
      throw error;
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查参数类型和格式是否正确 |
| 201 | Permission denied | 申请ohos.permission.INTERNET权限 |
| 2300001 | Unsupported protocol | 使用支持的协议（HTTP/HTTPS） |
| 2300003 | Invalid URL format or missing URL | 检查URL格式，对中文URL进行编码 |
| 2300005 | Failed to resolve the proxy name | 检查代理配置是否正确 |
| 2300006 | Failed to resolve the host name | 检查域名是否有效，检查DNS配置 |
| 2300007 | Failed to connect to the server | 检查网络连接，尝试备用URL，增加重试机制 |
| 2300008 | Invalid server response | 检查服务器返回的数据格式 |
| 2300009 | Access to the remote resource denied | 检查认证信息和权限 |
| 2300025 | Upload failed | 检查上传数据和服务器配置 |
| 2300026 | Failed to open or read local data from the file or application | 检查文件路径和访问权限 |
| 2300027 | Out of memory | 减少数据大小，使用流式传输 |
| 2300028 | Operation timeout | 增加超时时间设置 |
| 2300047 | The number of redirections reaches the maximum allowed | 检查重定向配置，减少重定向次数 |
| 2300052 | The server returned nothing (no header or data) | 检查服务器响应 |
| 2300058 | Local SSL certificate error | 检查本地证书配置 |
| 2300060 | Invalid SSL peer certificate or SSH remote key | 检查服务器证书，配置证书锁定 |
| 2300063 | Maximum file size exceeded | 减小文件大小，使用流式传输，设置maxLimit |
| 2300077 | The SSL CA certificate does not exist or is inaccessible | 检查CA证书路径和访问权限 |
| 2300078 | Remote file not found | 检查文件路径 |
| 2300094 | Authentication error | 检查认证信息 |
| 2300997 | Cleartext traffic not permitted | 使用HTTPS或配置明文传输权限 |
| 2300998 | It is not allowed to access this domain | 检查域名访问权限 |
| 2300999 | Internal error | 查看详细错误信息，联系技术支持 |

HTTP错误码映射关系：2300000 + curl错误码。更多错误码可参考：https://curl.se/libcurl/c/libcurl-errors.html

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkKit": "API version 6+",
    "@kit.BasicServicesKit": "API version 6+",
    "@kit.AbilityKit": "API version 6+",
    "@kit.PerformanceAnalysisKit": "API version 6+"
  }
}
```

### 权限配置
在module.json5中配置权限：
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

### 环境要求
- HarmonyOS API version 6+（基础功能）
- HarmonyOS API version 9+（expectDataType、priority、usingCache、usingProtocol）
- HarmonyOS API version 10+（usingProxy、caPath）
- HarmonyOS API version 11+（clientCert、multiFormDataList、caData）
- HarmonyOS API version 12+（certificatePinning）
- HarmonyOS API version 15+（addressFamily）
- HarmonyOS API version 18+（remoteValidation、cleartextTrafficPermitted）
- HarmonyOS API version 22+（HTTP拦截器）
- HarmonyOS API version 23+（WebDAV、SOCKS5代理）

### 常见编译问题

**问题1：缺少权限声明**
```
Permission denied. Need ohos.permission.INTERNET permission.
```
**解决方法**：在module.json5中添加ohos.permission.INTERNET权限声明

**问题2：HttpRequest对象未销毁**
```
Memory leak detected: HttpRequest object not destroyed
```
**解决方法**：在请求完成后调用httpRequest.destroy()方法释放资源

**问题3：URL编码错误**
```
Invalid URL format or missing URL
```
**解决方法**：对包含中文或其他语言的URL调用encodeURL进行编码

**问题4：证书路径错误**
```
The SSL CA certificate does not exist or is inaccessible
```
**解决方法**：检查CA证书路径是否正确，确保应用有访问权限

**问题5：响应数据超过5MB**
```
Maximum file size exceeded
```
**解决方法**：使用requestInStream流式传输，或在HttpRequestOptions中设置maxLimit参数

**问题6：超时错误**
```
Operation timeout
```
**解决方法**：增加readTimeout和connectTimeout参数值

**问题7：明文传输被禁止**
```
Cleartext traffic not permitted
```
**解决方法**：使用HTTPS协议，或在network_config.json中配置cleartextTrafficPermitted为true

**问题8：拦截器配置错误**
```
Interceptor must be configured before request
```
**解决方法**：在调用request方法前配置拦截器链

## 常见问题与解决方法

### Q1：HttpRequest对象可以复用吗？
**原因**：每一个HttpRequest对象对应一个HTTP请求任务，不可复用
**解决方法**：
- 每次请求都创建新的HttpRequest对象
- 使用完毕后调用destroy()方法释放资源
- 避免在多个请求中共享HttpRequest对象

### Q2：如何处理大文件上传或下载？
**原因**：request方法默认仅支持5MB以内数据
**解决方法**：
- 使用requestInStream方法进行流式传输
- 订阅dataReceiveProgress和dataSendProgress事件监控进度
- 订阅dataReceive和dataEnd事件处理流式数据
- 设置较大的readTimeout值

### Q3：如何配置证书锁定？
**原因**：需要锁定特定证书，只信任开发者指定的证书
**解决方法**：
- 使用certificatePinning参数动态设置证书PIN码
- 在network_config.json中预置证书或证书公钥哈希值
- 计算证书公钥的SHA256哈希值并转换为base64编码
- 配置domains和pin-set

### Q4：如何配置HTTP代理？
**原因**：需要通过代理服务器访问网络
**解决方法**：
- 设置usingProxy为true使用系统默认代理
- 配置HttpProxy自定义HTTP代理
- 配置Socks5Proxy使用SOCKS5代理（API 26+）

### Q5：如何处理URL中的中文或特殊字符？
**原因**：URL格式不符合规范
**解决方法**：
- 使用encodeURL函数对URL进行编码
- 对URL参数进行URL编码
- 确保URL格式符合RFC 3986标准

### Q6：如何配置DNS解析？
**原因**：需要自定义DNS解析服务器
**解决方法**：
- 设置dnsOverHttps使用HTTPS协议的DNS服务器
- 设置dnsServerIp指定DNS服务器IP地址（最多3个）

### Q7：如何使用WebDAV协议？
**原因**：需要对远程服务器上的文件进行管理操作
**解决方法**：
- 设置customMethod为WebDAV方法（PUT/GET/MKCOL/DELETE/MOVE/COPY/LOCK/UNLOCK/PROPFIND/PROPPATCH）
- 配置相应的header字段（如Destination、Depth、Lock-Token等）
- 处理XML格式的请求和响应

### Q8：如何配置HTTP拦截器？
**原因**：需要在请求-响应生命周期中插入自定义逻辑
**解决方法**：
- 创建HttpInterceptorChain对象
- 实现HttpInterceptor接口，定义拦截器逻辑
- 在拦截器中修改请求头/请求体或响应数据
- 使用addChain方法添加拦截器到拦截器链
- 使用apply方法将拦截器链附加到HttpRequest对象
- 在发起请求前配置拦截器

### Q9：如何处理网络请求失败？
**原因**：网络不稳定或服务器异常
**解决方法**：
- 实现重试机制，设置最大重试次数
- 提供备用URL，在主URL失败时切换
- 增加超时时间设置
- 使用流式传输处理大文件
- 在失败回调中记录错误日志

### Q10：如何配置响应数据类型？
**原因**：需要指定HTTP响应数据的解析类型
**解决方法**：
- 设置expectDataType参数
- 支持的类型：STRING、OBJECT、ARRAY、BUFFER
- 根据业务需求选择合适的数据类型

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "requestMethod": "POST",
  "url": "EXAMPLE_URL",
  "responseCode": 200,
  "responseHeader": {
    "Content-Type": "application/json"
  },
  "responseData": "响应数据内容",
  "cookies": "Cookie信息",
  "apiUsed": [
    "http.createHttp",
    "http.HttpRequest.request",
    "http.HttpRequest.on",
    "http.HttpRequest.off",
    "http.HttpRequest.destroy"
  ]
}
```

## 参考文档

- [API开发指南：使用HTTP访问网络](references/http-request-guide.md)
- [API参考说明：@ohos.net.http](references/js-apis-http.md)
- [Remote Communication Kit简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-introduction)
- [获取UIAbility的上下文信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/uiability-usage)
- [网络连接安全配置](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-network-ca-security)
- [HTTP错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-net-http)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [curl错误码](https://curl.se/libcurl/c/libcurl-errors.html)

## 完整示例代码

- [ArkTS示例：HTTP数据请求](assets/http-request-example.ets)
- [ArkTS示例：HTTP流式传输](assets/http-stream-example.ets)
- [ArkTS示例：WebDAV请求](assets/webdav-example.ets)
- [ArkTS示例：HTTP拦截器](assets/http-interceptor-example.ets)
- [ArkTS示例：证书锁定配置](assets/certificate-pinning-example.ets)
- [配置文件示例：网络安全配置](assets/network_config.json)

## 测试用例

### 正向测试用例
- [test_http_request_positive](tests/test_http_request_positive.ets)：发起正常的HTTP GET请求
- [test_http_post_positive](tests/test_http_post_positive.ets)：发起正常的HTTP POST请求
- [test_http_stream_positive](tests/test_http_stream_positive.ets)：发起HTTP流式传输请求
- [test_webdav_positive](tests/test_webdav_positive.ets)：发起WebDAV请求
- [test_interceptor_positive](tests/test_interceptor_positive.ets)：配置HTTP拦截器

### 边界测试用例
- [test_timeout_boundary](tests/test_timeout_boundary.ets)：测试超时时间边界值
- [test_large_file_boundary](tests/test_large_file_boundary.ets)：测试大文件上传/下载（接近100MB）
- [test_concurrent_priority_boundary](tests/test_concurrent_priority_boundary.ets)：测试并发优先级边界值（1和1000）
- [test_dns_servers_boundary](tests/test_dns_servers_boundary.ets)：测试DNS服务器数量边界值（最多3个）

### 异常测试用例
- [test_invalid_url](tests/test_invalid_url.ets)：测试无效URL格式
- [test_permission_denied](tests/test_permission_denied.ets)：测试缺少INTERNET权限
- [test_connection_failed](tests/test_connection_failed.ets)：测试连接失败
- [test_timeout_error](tests/test_timeout_error.ets)：测试超时错误
- [test_certificate_error](tests/test_certificate_error.ets)：测试证书校验失败
- [test_cleartext_traffic](tests/test_cleartext_traffic.ets)：测试明文传输被禁止