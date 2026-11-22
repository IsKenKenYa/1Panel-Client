---
name: hmos-remote-communication-kit-transfer-configuration
description: 配置HTTP请求超时重试策略，通过TransferConfiguration精细化控制数据传输行为，支持连接超时和传输超时设置，适用于网络不稳定环境下的可靠数据传输场景
---

# TransferConfiguration：定制数据传输技能

## 功能描述

本技能提供HTTP请求数据传输行为的精细化管理和定制化调整能力。通过TransferConfiguration，开发者可以配置自动重定向策略、超时时间设定等关键功能，实现数据传输策略的个性化定制。特别适用于网络不稳定环境下需要超时重试的场景，确保数据传输的可靠性和高效性。

主要功能：
- 配置连接超时时间（connectMs）
- 配置数据传输超时时间（transferMs）
- 实现超时自动重试机制
- 控制自动重定向行为
- 配置TCP连接选项

## 使用场景

### 触发词
- "HTTP超时重试"
- "配置网络超时"
- "定制数据传输"
- "TransferConfiguration"
- "网络不稳定环境请求"
- "连接超时配置"

### 能做
- 配置HTTP请求的超时参数（连接超时和传输超时）
- 实现超时失败后的自动重试逻辑
- 控制HTTP重定向行为（自动跟随或手动处理）
- 配置TCP连接的保活参数
- 设置HTTP/3功能支持
- 配置网络路径偏好（自动或蜂窝网络）

### 绝不做
- 不处理非HTTP协议的请求
- 不替代业务逻辑层的错误处理
- 不直接处理响应数据的解析
- 不配置代理或DNS相关设置（需要专门的技能）
- 不处理SSL/TLS证书验证（需要专门的技能）

### 补充
- 从API版本4.1.0(11)开始支持
- 从API版本5.1.1(19)开始支持TV设备
- 从API版本6.1.0(23)开始支持Car设备
- 建议在网络请求完成后及时关闭Session，避免资源浪费
- Session实例数量限制：最多1024个（从5.1.0(18)版本开始）

## 调用规范和规则

### 输入约束
- URL格式：必须是合法的HTTP/HTTPS URL
- 超时时间：connectMs建议范围[1000, 60000]毫秒，transferMs建议范围[1000, 60000]毫秒
- 重试次数：建议不超过5次，避免无限重试
- Session实例：不超过1024个并发Session

### 执行约束
- 最大耗时：connectMs + transferMs + (重试次数 × 重试间隔)
- 最大重试次数：建议不超过5次
- Session关闭：请求完成后必须在finally块中关闭Session
- 异步处理：必须使用async/await或Promise处理异步请求

### 内容约束
- 禁止使用：禁止在重试逻辑中使用无限循环
- 禁止忽略：禁止忽略错误码1007900006、1007900007、1007900028等关键错误
- 禁止硬编码：禁止在代码中硬编码敏感信息（用户名、密码等）
- 禁止阻塞：禁止在异步回调中执行长时间同步操作

### 降级约束
- 网络失败：超过最大重试次数后，返回错误信息并建议用户检查网络
- DNS解析失败：提示域名解析错误，建议检查URL或DNS配置
- SSL连接失败：提示SSL证书问题，建议检查证书配置或使用降级方案
- Session创建失败：提示达到Session限制，建议关闭未使用的Session

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证URL格式是否正确（必须是HTTP/HTTPS协议）
2. 验证超时参数是否在合理范围内
3. 检查是否有正在使用的Session，避免超过限制

**参数准备**：
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义会话配置参数
const sessionConfig: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 3000,    // 连接超时时间：3秒
        transferMs: 6000    // 传输超时时间：6秒
      }
    }
  }
};

// 定义请求URL
const URL = 'https://www.example.com';

// 定义重试次数
const retryCount = 3;
```

### 步骤2：创建Session并发起请求

**示例代码**：
```typescript
// 创建会话
const session = rcp.createSession(sessionConfig);

// 定义异步重试函数
async function retryRequest(url: string, retryCount: number, attempt: number): Promise<rcp.Response> {
  try {
    // 发起GET请求
    const response = await session.get(url);
    return Promise.resolve(response);
  } catch (e) {
    const error = e as BusinessError;
    
    // 判断是否为可重试错误（域名解析失败、连接失败、超时、SSL错误）
    if (error.code === 1007900006 || 
        error.code === 1007900005 || 
        error.code === 1007900007 || 
        error.code === 1007900035 ||
        error.code === 1007900028) {
      
      // 检查是否达到最大重试次数
      if (attempt < retryCount) {
        console.warn(`Request failed with error ${error.code}, retrying... (attempt ${attempt + 1}/${retryCount})`);
        // 递归调用进行重试
        return retryRequest(url, retryCount, attempt + 1);
      } else {
        // 达到最大重试次数，返回错误
        console.error(`Max retry count reached (${retryCount}), request failed`);
        return Promise.reject(error);
      }
    } else {
      // 其他错误直接返回
      return Promise.reject(error);
    }
  }
}
```

### 步骤3：调用请求函数并处理响应

```typescript
// 定义当前尝试次数，初始值为1
const attempt = 1;

// 调用retryRequest函数
const responsePromise = retryRequest(URL, retryCount, attempt);

// 处理响应结果
responsePromise.then((res) => {
  console.info(`Request succeeded, status code: ${res.statusCode}`);
  
  // 处理响应数据
  if (res.body) {
    const responseBody = res.body;
    console.info(`Response body length: ${responseBody.byteLength}`);
  }
  
  // 关闭Session
  session.close();
}).catch((err: BusinessError) => {
  console.error(`Request failed: error code ${err.code}, message: ${err.message}`);
  
  // 关闭Session
  session.close();
});
```

### 步骤4：完整的错误处理和资源清理

```typescript
// 完整示例：包含资源清理
async function httpRequestWithRetry(url: string): Promise<void> {
  // 创建会话
  const session = rcp.createSession({
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 3000,
          transferMs: 6000
        }
      }
    }
  });
  
  try {
    // 定义重试函数
    const executeRequest = async (attempt: number): Promise<rcp.Response> => {
      try {
        return await session.get(url);
      } catch (error) {
        const err = error as BusinessError;
        
        // 可重试错误判断
        const retryableErrors = [1007900006, 1007900005, 1007900007, 1007900035, 1007900028];
        
        if (retryableErrors.includes(err.code) && attempt < 3) {
          console.warn(`Retry attempt ${attempt + 1} for error ${err.code}`);
          return executeRequest(attempt + 1);
        }
        
        throw err;
      }
    };
    
    // 执行请求
    const response = await executeRequest(1);
    console.info(`Request succeeded: ${response.statusCode}`);
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Final error: code ${err.code}, message: ${err.message}`);
    
    // 根据错误码提供解决建议
    switch (err.code) {
      case 1007900006:
        console.error('DNS resolution failed, please check URL or DNS configuration');
        break;
      case 1007900007:
        console.error('Cannot connect to server, please check network connection');
        break;
      case 1007900028:
        console.error('Timeout reached, please check network or increase timeout value');
        break;
      case 1007900035:
        console.error('SSL connection error, please check TLS configuration');
        break;
      default:
        console.error('Unknown error occurred');
    }
    
  } finally {
    // 确保关闭Session
    session.close();
    console.info('Session closed');
  }
}

// 调用函数
httpRequestWithRetry('https://www.example.com');
```

### 步骤5：降级处理方案

```typescript
// 降级方案示例：尝试使用不同的超时配置
async function requestWithFallback(url: string): Promise<void> {
  // 第一级：正常超时配置
  const normalTimeout = { connectMs: 3000, transferMs: 6000 };
  
  // 第二级：延长超时配置（网络较差时）
  const extendedTimeout = { connectMs: 10000, transferMs: 15000 };
  
  // 第三级：最大超时配置（极端情况）
  const maxTimeout = { connectMs: 30000, transferMs: 60000 };
  
  const timeoutConfigs = [normalTimeout, extendedTimeout, maxTimeout];
  
  for (let i = 0; i < timeoutConfigs.length; i++) {
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: { timeout: timeoutConfigs[i] }
      }
    });
    
    try {
      console.info(`Attempting with timeout config ${i + 1}: connectMs=${timeoutConfigs[i].connectMs}, transferMs=${timeoutConfigs[i].transferMs}`);
      const response = await session.get(url);
      console.info(`Request succeeded with config ${i + 1}`);
      session.close();
      return;
      
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`Config ${i + 1} failed: error ${err.code}`);
      session.close();
      
      if (i === timeoutConfigs.length - 1) {
        console.error('All fallback attempts failed');
        throw err;
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900006 | 域名解析失败 | 1.检查URL格式是否正确<br>2.检查DNS配置<br>3.检查网络连接状态 |
| 1007900005 | 代理服务器域名解析失败 | 1.检查代理服务器URL<br>2.验证代理配置是否正确 |
| 1007900007 | 无法连接到服务器 | 1.检查网络连接<br>2.验证服务器地址和端口<br>3.检查防火墙设置 |
| 1007900028 | 操作超时 | 1.检查网络稳定性<br>2.增加超时时间配置<br>3.关闭Session后重新创建 |
| 1007900035 | SSL连接错误 | 1.检查TLS版本配置<br>2.验证TLS加密套件<br>3.检查证书有效性 |
| 1007900003 | URL格式错误 | 1.检查URL格式是否符合规范<br>2.确保使用HTTP/HTTPS协议 |
| 1007900994 | Session数量达到限制 | 1.减少创建的Session数量<br>2.及时关闭未使用的Session<br>3.不超过1024个实例 |
| 1007900993 | Session已关闭 | 1.重新创建Session<br>2.检查Session生命周期管理 |
| 401 | 参数错误 | 检查传入的参数是否合法，如timeout值范围 |

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**：
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本"
  }
}
```

**module.json5权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "用于HTTP网络请求"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK版本：≥4.1.0(11)
- DevEco Studio版本：≥4.0
- 设备类型：Phone、2in1、Tablet、Wearable、TV（≥5.1.1(19))、Car（≥6.1.0(23))

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：
1. 检查oh-package.json5是否配置了依赖
2. 运行`ohpm install`安装依赖
3. 检查SDK版本是否≥4.1.0(11)

**问题2：权限未配置**
```
Error: Permission denied
```
**解决方法**：
1. 在module.json5中添加`ohos.permission.INTERNET`权限
2. 如果使用cellular路径，添加`ohos.permission.GET_NETWORK_INFO`权限

**问题3：Session创建失败**
```
Error: Sessions number reached limit (1007900994)
```
**解决方法**：
1. 检查当前创建的Session数量
2. 关闭未使用的Session
3. 确保不超过1024个Session实例

## 常见问题与解决方法

### Q1：请求频繁超时怎么办？

**原因**：
- 网络环境不稳定
- 服务器响应慢
- 超时时间设置过短

**解决方法**：
- 增加超时时间：`connectMs`和`transferMs`设置为更大值（如10000ms）
- 实现重试机制：最多重试3-5次
- 使用降级方案：尝试不同超时配置
- 检查网络状态：在网络稳定后再发起请求

### Q2：如何判断哪些错误可以重试？

**原因**：
不同类型的错误需要不同的处理策略

**解决方法**：
可重试错误包括：
- 1007900006（域名解析失败）- 可能是临时DNS问题
- 1007900007（连接失败）- 可能是临时网络波动
- 1007900028（超时）- 网络延迟可能恢复
- 1007900035（SSL错误）- 可能是临时握手失败
- 1007900005（代理域名解析失败）

不可重试错误：
- 1007900003（URL格式错误）- 需要修正URL
- 1007900994（Session限制）- 需要关闭Session
- 401（参数错误）- 需要修正参数

### Q3：Session什么时候应该关闭？

**原因**：
Session不关闭会占用资源，可能导致Session数量达到限制

**解决方法**：
- 在请求完成后立即关闭（无论成功或失败）
- 使用try-finally确保关闭
- 在页面/组件销毁时关闭所有Session
- 不要在请求未完成时提前关闭Session

示例：
```typescript
try {
  const response = await session.get(url);
  // 处理响应
} finally {
  session.close(); // 确保关闭
}
```

### Q4：如何配置TCP连接保活？

**原因**：
长连接场景需要TCP保活机制防止连接断开

**解决方法**：
从API版本6.0.0(20)开始，可以使用TcpConfiguration：

```typescript
const transferConfig: rcp.TransferConfiguration = {
  timeout: {
    connectMs: 5000,
    transferMs: 10000
  },
  tcp: {
    keepIdleSec: 20,       // 空闲20秒后开始探测
    keepIntervalSec: 30,   // 探测间隔30秒
    keepCnt: 6,            // 探测次数6次
    userTimeoutMs: 3000    // 用户超时3秒
  }
};
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "statusCode": 200,
  "responseSize": "1024 bytes",
  "retryCount": 2,
  "totalTime": "3500 ms",
  "apiUsed": [
    "rcp.createSession",
    "SessionConfiguration",
    "TransferConfiguration",
    "Timeout",
    "session.get"
  ],
  "sessionStatus": "closed"
}
```

失败情况输出：

```json
{
  "status": "failed",
  "errorCode": 1007900007,
  "errorMessage": "Couldn't connect to server",
  "retryAttempts": 3,
  "lastAttemptTime": "2024-01-01T10:30:00Z",
  "suggestion": "Please check network connection and server availability"
}
```

## 参考文档

- [API开发指南](references/remote-communication-customtranferconfig.md)
- [API参考说明](references/remote-communication-rcp.md)

## 完整示例代码

- [ArkTS示例](assets/example_transfer_config.ets)
- [重试机制示例](assets/example_retry_mechanism.ets)
- [降级方案示例](assets/example_fallback.ets)

## 测试用例

### 正向测试用例
- [正常请求成功](tests/test_positive_success.py)：验证正常HTTP请求能够成功返回响应
- [超时重试成功](tests/test_positive_retry.py)：验证超时后重试能够成功
- [自定义超时配置](tests/test_positive_custom_timeout.py)：验证自定义超时参数能够生效

### 边界测试用例
- [最小超时值](tests/test_boundary_min_timeout.py)：验证最小超时值（1000ms）能够正常工作
- [最大超时值](tests/test_boundary_max_timeout.py)：验证最大超时值（60000ms）能够正常工作
- [最大重试次数](tests/test_boundary_max_retry.py)：验证达到最大重试次数后正确返回错误

### 异常测试用例
- [域名解析失败](tests/test_exception_dns_failure.py)：验证DNS解析失败时能够正确重试和报错
- [连接超时](tests/test_exception_connect_timeout.py)：验证连接超时时能够正确重试和报错
- [传输超时](tests/test_exception_transfer_timeout.py)：验证传输超时时能够正确重试和报错
- [SSL错误](tests/test_exception_ssl_error.py)：验证SSL错误时能够正确处理
- [无效URL](tests/test_exception_invalid_url.py)：验证无效URL能够正确报错
- [Session限制](tests/test_exception_session_limit.py)：验证达到Session限制时能够正确报错