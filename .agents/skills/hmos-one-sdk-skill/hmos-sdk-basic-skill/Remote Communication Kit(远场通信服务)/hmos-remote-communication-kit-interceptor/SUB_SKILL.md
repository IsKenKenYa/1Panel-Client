---
name: hmos-remote-communication-kit-interceptor
description: 创建和使用HTTP拦截器修改请求和响应，支持拦截器链式调用，可自定义请求URL修改和响应头处理逻辑，适用于网络质量优化、响应数据过滤、缓存控制等场景
---

# HTTP拦截器定制能力技能

## 功能描述

本技能提供HTTP拦截器的创建和配置能力。拦截器允许开发者对HTTP请求和响应进行自定义修改，通过实现Interceptor接口并在SessionConfiguration中配置拦截器链，可以在请求发送前修改请求内容（如URL、headers），或在响应返回后处理响应数据（如过滤响应头）。支持创建多个拦截器按顺序执行，形成拦截器链。

### 核心能力
- 实现自定义Interceptor接口拦截HTTP请求和响应
- 在请求阶段修改URL、headers等请求参数
- 在响应阶段过滤、修改响应头和响应体
- 配置拦截器链实现多拦截器顺序执行
- 支持网络质量自适应请求优化

### 适用范围
- Remote Communication Kit模块的HTTP请求定制
- Session创建时的拦截器配置
- 需要请求/响应预处理的场景

### 限制条件
- API版本要求：5.0.0(12)及以上
- 设备支持：Phone、2in1、Tablet、Wearable（5.1.1(19)开始支持TV，6.1.0(23)开始支持Car）
- 拦截器必须实现rcp.Interceptor接口
- intercept方法必须返回Promise<Response>

### 典型场景
- 网络质量不佳时自动切换低分辨率资源URL
- 响应头过滤和敏感信息移除
- 响应缓存实现
- 请求日志记录和性能监控

## 使用场景

### 触发词
- "HTTP拦截器"
- "拦截器配置"
- "请求拦截"
- "响应拦截"
- "拦截器链"
- "修改HTTP请求"
- "修改HTTP响应"
- "网络请求定制"

### 能做
- 创建实现Interceptor接口的自定义拦截器类
- 在拦截器中修改请求URL、headers、请求体
- 在拦截器中处理响应headers、响应体
- 配置SessionConfiguration的interceptors数组
- 创建拦截器链实现多个拦截器顺序执行
- 实现请求缓存拦截器
- 实现网络质量自适应拦截器

### 绝不做
- 不处理非HTTP协议的请求拦截
- 不替代Session的创建和关闭操作
- 不处理网络连接底层配置（如TLS、DNS）
- 不修改拦截器接口定义（必须遵循rcp.Interceptor规范）
- 不在拦截器中执行耗时超过10秒的操作

### 补充
- 拦截器执行顺序：按interceptors数组顺序依次执行
- 每个拦截器必须调用next.handle(context)继续链式调用
- 拦截器可以提前返回响应（不继续链式调用）
- 建议在拦截器中添加错误处理和日志记录
- 拦截器不应修改RequestContext的session属性

## 调用规范和规则

### 输入约束
- 拦截器类必须实现rcp.Interceptor接口
- intercept方法签名：async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response>
- SessionConfiguration.interceptors类型：Interceptor[]
- 拦截器数量建议不超过10个（避免性能影响）
- 拦截器代码行数建议不超过200行

### 执行约束
- 单个拦截器最大执行时间：3秒
- 拦截器链总执行时间：10秒
- intercept方法必须为async函数或返回Promise
- 必须调用next.handle(context)继续链式调用（除非提前返回）
- 拦截器中禁止执行阻塞操作（如同步文件读写）

### 内容约束
- 禁止在拦截器中使用eval、Function构造器等高危函数
- 禁止在拦截器中修改RequestContext.session
- 禁止在拦截器中进行无限循环或递归调用
- 禁止在拦截器中访问本地敏感文件路径
- 响应修改时必须保持Response结构完整性

### 降级约束
- 拦截器执行失败：记录错误日志，继续执行下一个拦截器或返回原始响应
- 拦截器超时：跳过当前拦截器，继续链式调用
- 网络质量检测失败：使用默认网络状态（isNetworkFast=true）
- URL解析失败：保持原始URL不变

## 调用流程和步骤

### 步骤1：导入必要模块

**前置准备**：
1. 确认项目已配置Remote Communication Kit依赖
2. 确认API版本≥5.0.0(12)
3. 确认设备类型支持拦截器功能

**模块导入**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';
```

### 步骤2：定义拦截器类

**实现Interceptor接口**：

```typescript
// 示例1：请求URL修改拦截器（网络质量自适应）
export class NetworkQualityProvider {
  isNetworkFast: boolean = true;
  
  public constructor(isNetworkFast: boolean) {
    this.isNetworkFast = isNetworkFast;
  }
}

export class RequestUrlChangeInterceptor implements rcp.Interceptor {
  private readonly networkQualityProvider: NetworkQualityProvider;
  
  constructor(networkQualityProvider: NetworkQualityProvider) {
    this.networkQualityProvider = networkQualityProvider;
  }
  
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      // 检查请求方法和网络质量
      if (context.request.method === 'GET' && !this.networkQualityProvider.isNetworkFast) {
        console.info('[RequestUrlChangeInterceptor]: Slow network detected');
        
        // 解析URL并修改路径
        const parts = context.request.url.pathname.split('.');
        if (parts.length === 2) {
          const changed = url.URL.parseURL(context.request.url.href);
          changed.pathname = parts[0] + '_small.' + parts[1];
          console.info(`[RequestUrlChangeInterceptor]: URL changed from '${context.request.url.href}' to '${changed}'`);
          context.request.url = changed;
        }
      } else {
        console.info('[RequestUrlChangeInterceptor]: Network is fast, no changes');
      }
      
      // 继续拦截器链
      return next.handle(context);
    } catch (error) {
      console.error('[RequestUrlChangeInterceptor]: Error occurred:', error);
      // 降级处理：继续执行链式调用
      return next.handle(context);
    }
  }
}
```

```typescript
// 示例2：响应头过滤拦截器
export class ResponseHeaderRemoveInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      // 先执行请求获取响应
      const response = await next.handle(context);
      
      // 过滤响应头
      const toReturn: rcp.Response = {
        request: response.request,
        statusCode: response.statusCode,
        httpVersion: response.httpVersion,
        headers: {
          'content-range': response.headers['content-range']
        },
        effectiveUrl: response.effectiveUrl,
        timeInfo: response.timeInfo,
        toJSON: () => null
      };
      
      console.info('[ResponseHeaderRemoveInterceptor]: Response headers filtered');
      return toReturn;
    } catch (error) {
      console.error('[ResponseHeaderRemoveInterceptor]: Error occurred:', error);
      // 降级处理：返回原始响应
      const response = await next.handle(context);
      return response;
    }
  }
}
```

```typescript
// 示例3：响应缓存拦截器
export class ResponseCache {
  private readonly cache: Record<string, rcp.Response> = {};
  
  getResponse(url: string): rcp.Response | undefined {
    return this.cache[url];
  }
  
  setResponse(url: string, response: rcp.Response): void {
    this.cache[url] = response;
  }
}

export class ResponseCachingInterceptor implements rcp.Interceptor {
  private readonly cache: ResponseCache;
  
  constructor(cache: ResponseCache) {
    this.cache = cache;
  }
  
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    const url = context.request.url.href;
    
    // 检查缓存
    const cachedResponse = this.cache.getResponse(url);
    if (cachedResponse) {
      console.info('[ResponseCachingInterceptor]: Returning cached response');
      return Promise.resolve(cachedResponse);
    }
    
    // 执行请求并缓存响应
    const response = await next.handle(context);
    this.cache.setResponse(url, response);
    console.info('[ResponseCachingInterceptor]: Response cached for', url);
    
    return response;
  }
}
```

### 步骤3：配置Session拦截器

**创建SessionConfiguration**：
```typescript
function createSessionWithInterceptors(networkStateSimulator: NetworkQualityProvider, cache: ResponseCache) {
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [
      new RequestUrlChangeInterceptor(networkStateSimulator),
      new ResponseHeaderRemoveInterceptor(),
      new ResponseCachingInterceptor(cache)
    ],
    requestConfiguration: {
      security: {
        tlsOptions: {
          tlsVersion: 'TlsV1.3'
        }
      }
    }
  };
  
  const session = rcp.createSession(sessionConfig);
  return session;
}
```

### 步骤4：使用拦截器Session发送请求

**发送HTTP请求**：
```typescript
async function sendRequestWithInterceptor() {
  const networkStateSimulator = new NetworkQualityProvider(false); // 模拟慢速网络
  const cache = new ResponseCache();
  
  const session = createSessionWithInterceptors(networkStateSimulator, cache);
  
  try {
    // 发送GET请求
    const response = await session.get('https://example.com/image.jpg');
    console.info('Request succeeded:', response.statusCode);
    
    // 解析响应数据
    if (response.body) {
      console.info('Response body length:', response.body.byteLength);
    }
    
  } catch (error) {
    console.error('Request failed:', error.message);
  } finally {
    // 关闭Session释放资源
    session.close();
  }
}
```

### 步骤5：错误处理和降级

**完整的错误处理流程**：
```typescript
async function robustRequestWithInterceptor() {
  const networkStateSimulator = new NetworkQualityProvider(true);
  const cache = new ResponseCache();
  
  try {
    // 创建Session
    const sessionConfig: rcp.SessionConfiguration = {
      interceptors: [
        new RequestUrlChangeInterceptor(networkStateSimulator),
        new ResponseCachingInterceptor(cache)
      ]
    };
    
    const session = rcp.createSession(sessionConfig);
    
    // 发送请求
    const request = new rcp.Request('https://example.com/api/data', 'GET');
    const response = await session.fetch(request);
    
    // 验证响应
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.info('Request successful');
      return response;
    } else {
      console.warn('Request returned non-success status:', response.statusCode);
      return null;
    }
    
  } catch (error) {
    // 错误分类处理
    if (error.code === 401) {
      console.error('Parameter error in interceptor configuration');
    } else if (error.code === 1007900994) {
      console.error('Session limit reached');
    } else {
      console.error('Unknown error:', error.message);
    }
    
    // 降级方案：使用无拦截器Session重新请求
    console.info('Fallback: creating session without interceptors');
    const fallbackSession = rcp.createSession();
    try {
      const fallbackResponse = await fallbackSession.get('https://example.com/api/data');
      return fallbackResponse;
    } finally {
      fallbackSession.close();
    }
    
  } finally {
    // 确保Session关闭
    if (session) {
      session.close();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，拦截器配置不正确 | 检查Interceptor实现是否符合接口规范，确保intercept方法返回Promise |
| 1007900994 | Session数量达到上限（1024个） | 关闭不再使用的Session，确保及时调用session.close() |
| TypeError | 拦截器未正确实现Interceptor接口 | 确保类implements rcp.Interceptor，并实现intercept方法 |
| NetworkError | 网络请求失败 | 检查网络连接状态，拦截器中添加网络错误处理逻辑 |
| TimeoutError | 拦截器执行超时 | 减少拦截器中的耗时操作，优化拦截器逻辑 |
| URLParseError | URL解析失败 | 检查URL格式，添加URL解析错误捕获 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^5.0.0",
    "@kit.ArkTS": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK版本：5.0.0(12)及以上
- DevEco Studio版本：5.0及以上
- ArkTS编译器：支持async/await和Promise
- 运行设备：Phone、2in1、Tablet、Wearable（TV从5.1.1(19)，Car从6.1.0(23)）

### 常见编译问题

**问题1：Interceptor接口未正确实现**
```
Error: Class 'CustomInterceptor' incorrectly implements interface 'Interceptor'.
Property 'intercept' is missing in type 'CustomInterceptor'.
```
**解决方法**：确保类正确implements rcp.Interceptor，并实现intercept方法：
```typescript
export class CustomInterceptor implements rcp.Interceptor {
  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    // 实现逻辑
    return next.handle(context);
  }
}
```

**问题2：url模块导入失败**
```
Error: Cannot find module '@kit.ArkTS' or its corresponding type declarations.
```
**解决方法**：确认项目已配置ArkTS Kit依赖，检查module.json5中的依赖配置。

**问题3：async/await语法错误**
```
Error: 'await' expressions are only allowed within async functions.
```
**解决方法**：确保intercept方法声明为async：
```typescript
async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response>
```

**问题4：SessionConfiguration类型错误**
```
Error: Type 'Interceptor[]' is not assignable to type 'never'.
```
**解决方法**：确认API版本≥5.0.0(12)，interceptors属性从5.0.0(12)开始支持。

## 常见问题与解决方法

### Q1：拦截器没有被执行
**原因**：拦截器未正确配置到SessionConfiguration，或API版本过低
**解决方法**：
- 确认interceptors数组已正确配置
- 检查API版本是否≥5.0.0(12)
- 确认拦截器类正确implements rcp.Interceptor
- 添加日志验证拦截器是否被调用

### Q2：拦截器链执行顺序不符合预期
**原因**：拦截器数组顺序决定执行顺序
**解决方法**：
- 检查interceptors数组顺序
- 请求拦截：按数组顺序执行
- 响应拦截：按数组逆序执行
- 在拦截器中添加执行顺序日志

### Q3：拦截器修改请求后请求失败
**原因**：URL格式错误或请求参数不合法
**解决方法**：
- 添加URL修改后的格式验证
- 使用url.URL.parseURL正确解析URL
- 在拦截器中捕获错误并降级处理

### Q4：响应拦截器返回的Response结构不完整
**原因**：Response对象缺少必需字段
**解决方法**：
- 确保返回的Response包含所有必需字段
- 参考rcp.Response接口定义
- 使用Object.assign复制原始Response再修改

### Q5：拦截器中无法访问响应体数据
**原因**：响应体为ArrayBuffer，需要正确解码
**解决方法**：
- 使用TextDecoder解码ArrayBuffer
- 检查response.body是否存在
- 添加body类型判断逻辑

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "sessionCreated": true,
  "interceptorsConfigured": [
    "RequestUrlChangeInterceptor",
    "ResponseHeaderRemoveInterceptor",
    "ResponseCachingInterceptor"
  ],
  "requestSent": true,
  "responseReceived": true,
  "interceptorExecuted": true,
  "apiUsed": [
    "rcp.createSession",
    "rcp.SessionConfiguration",
    "rcp.Interceptor",
    "rcp.RequestContext",
    "rcp.RequestHandler",
    "rcp.Response",
    "url.URL.parseURL"
  ]
}
```

## 参考文档

- [API开发指南：拦截器定制能力](references/remote-communication-interceptconfig.md)
- [API参考说明：SessionConfiguration](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：Interceptor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：intercept方法](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [ArkTS示例：请求URL修改拦截器](assets/request-url-change-interceptor.ets)
- [ArkTS示例：响应头过滤拦截器](assets/response-header-remove-interceptor.ets)
- [ArkTS示例：响应缓存拦截器](assets/response-caching-interceptor.ets)
- [ArkTS示例：拦截器Session完整配置](assets/interceptor-session-complete.ets)

## 测试用例

### 正向测试用例
- [测试请求拦截器修改URL](tests/test_request_interceptor.ts)：验证拦截器能正确修改请求URL
- [测试响应拦截器过滤headers](tests/test_response_interceptor.ts)：验证拦截器能正确过滤响应头
- [测试拦截器链顺序执行](tests/test_interceptor_chain.ts)：验证多个拦截器按顺序执行

### 边界测试用例
- [测试空拦截器数组](tests/test_empty_interceptors.ts)：验证无拦截器时Session正常工作
- [测试拦截器数量上限](tests/test_max_interceptors.ts)：验证配置10个拦截器的性能
- [测试网络质量切换](tests/test_network_quality_switch.ts)：验证网络质量变化时拦截器行为

### 异常测试用例
- [测试拦截器未实现接口](tests/test_invalid_interceptor.ts)：验证拦截器类未正确实现接口时的错误处理
- [测试拦截器执行超时](tests/test_interceptor_timeout.ts)：验证拦截器超时的降级处理
- [测试URL解析失败](tests/test_url_parse_error.ts)：验证URL修改失败时的降级方案