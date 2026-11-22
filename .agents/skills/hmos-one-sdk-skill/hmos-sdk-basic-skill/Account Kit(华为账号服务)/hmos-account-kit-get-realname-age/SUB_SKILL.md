---
name: hmos-account-kit-get-realname-age
description: 获取华为账号用户实名年龄段信息，需要用户授权后通过Authorization Code获取，支持Phone/Tablet/PC/2in1设备，适用于需要年龄段验证的应用场景
---

# 获取实名年龄段技能

## 功能描述

本技能实现华为账号用户实名年龄段信息的获取功能。通过Account Kit的授权能力，应用在用户授权后可快速获取用户的实名年龄段信息。该功能需要客户端获取Authorization Code，服务端使用Access Token调用REST API获取年龄段标识。

**核心能力**：
- 客户端获取Authorization Code（需要用户授权）
- 服务端获取Access Token
- 服务端查询用户实名年龄段信息

**适用设备**：
- Phone、Tablet、PC/2in1：全版本支持
- Wearable：从API 5.1.0(18)开始支持
- TV：从API 5.1.1(19)开始支持
- Car：从API 26.0.0开始支持

**API版本要求**：
- 起始版本：4.0.0(10)
- 实名年龄段功能：需要申请相应scope权限

## 使用场景

### 触发词
- "获取实名年龄段"
- "年龄段验证"
- "实名年龄段查询"
- "用户年龄段信息"
- "Account Kit 年龄段"

### 能做
- 获取华为账号用户的实名年龄段标识
- 通过Authorization Code进行安全授权
- 客户端请求用户授权年龄段信息
- 服务端查询用户年龄段标识
- 处理授权失败、网络错误等异常情况

### 绝不做
- 不直接获取用户的真实年龄信息（仅返回年龄段标识）
- 不绕过用户授权流程直接获取信息
- 不处理年龄段以外的用户信息（如姓名、身份证号等）
- 不在未配置签名和指纹的应用中使用
- 不在未申请"获取您的年龄段"权限的应用中使用

### 补充
- 必须先完成开发准备工作（配置签名、指纹、申请权限）
- 设备需登录华为账号，未登录会拉起登录页面
- 用户可取消授权，应用需处理取消场景
- Authorization Code有效期5分钟且只能使用1次
- Access Token有效期60分钟
- Refresh Token有效期180天

## 调用规范和规则

### 输入约束
- **设备要求**：必须使用支持的设备类型
- **权限要求**：必须申请"realNameAgeRange" scope权限
- **账号状态**：设备必须登录华为账号
- **签名配置**：应用必须配置签名和指纹证书
- **参数格式**：
  - scopes: 必须包含'realNameAgeRange'
  - permissions: 必须包含'serviceauthcode'
  - state: 必须符合^[0-9a-zA-Z:/\.\-_]{1,255}$格式
  - forceAuthorization: boolean类型

### 执行约束
- **授权超时**：用户授权操作最长等待时间由系统决定
- **网络请求**：客户端API调用依赖网络状态
- **并发限制**：Authorization Code只能使用1次
- **重试机制**：建议在网络失败时进行有限次重试

### 内容约束
- **禁止硬编码**：禁止在代码中硬编码Client Secret等敏感信息
- **禁止明文存储**：禁止明文存储Authorization Code、Access Token
- **禁止绕过授权**：禁止尝试绕过用户授权流程
- **日志脱敏**：日志中禁止输出Authorization Code、Access Token等敏感信息

### 降级约束
- **网络失败**：提示用户检查网络并重试
- **用户取消**：提示用户授权后才能使用相关功能
- **未登录**：引导用户登录华为账号
- **权限不足**：引导用户联系开发者或检查权限配置
- **设备不支持**：提示用户更换设备或升级系统版本

## 调用流程和步骤

### 步骤1：开发准备（前置条件）

**1.1 申请权限**
- 在AppGallery Connect中申请"获取您的年龄段"权限
- 审批通过后才能使用该功能

**1.2 配置签名和指纹**
- 配置应用签名证书
- 在AppGallery Connect中配置证书指纹
- 未配置将报错：1001500001 应用指纹证书校验失败

**1.3 检查设备登录状态**
- 确保设备已登录华为账号
- 未登录时会自动拉起登录页面

### 步骤2：客户端获取Authorization Code

**2.1 导入必要模块**
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
```

**2.2 创建授权请求对象**
```typescript
// 创建授权请求，并设置参数
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();

// 设置scope：获取用户实名年龄段需要传realNameAgeRange
// 传参数之前需要先申请对应scope权限，否则会返回1001502014错误码
authRequest.scopes = ['realNameAgeRange'];

// 设置permission：获取authorizationCode需传serviceauthcode
authRequest.permissions = ['serviceauthcode'];

// 设置是否强制授权：true表示用户未登录或未授权时会拉起登录或授权页面
authRequest.forceAuthorization = true;

// 设置state：建议使用generateRandomUUID生成，用于一致性比对，防止跨站攻击
authRequest.state = util.generateRandomUUID();

// 设置ID Token签名算法（可选）
authRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256;
```

**2.3 执行授权请求并处理结果**
```typescript
// 执行请求
try {
  // 此示例为代码片段，实际需在自定义组件实例中使用，并传入有效的Context上下文对象
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  
  controller.executeRequest(authRequest).then((data) => {
    const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
    
    // 验证state一致性，防止跨站攻击
    const state = authorizationWithHuaweiIDResponse.state;
    if (state && authRequest.state !== state) {
      hilog.error(0x0000, 'testTag', `Failed to authorize. The state is different, response state: ${state}`);
      return;
    }
    
    hilog.info(0x0000, 'testTag', 'Succeeded in authentication.');
    
    // 获取Authorization Code
    const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
    const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
    
    // 将Authorization Code发送到应用服务端处理
    sendAuthorizationCodeToServer(authorizationCode);
    
  }).catch((err: BusinessError) => {
    handleClientError(err);
  });
} catch (error) {
  handleClientError(error);
}
```

**2.4 客户端错误处理**
```typescript
// 错误处理
function handleClientError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to obtain authorization. Code: ${error.code}, message: ${error.message}`);
  
  // 在应用获取用户实名年龄段标识场景下，涉及UI交互时，建议按照如下错误码指导提示用户
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
    // 用户未登录华为账号，请登录华为账号并重试
    showError('请先登录华为账号');
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
    // 网络错误，请检查当前网络状态并重试
    showError('网络异常，请检查网络连接');
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
    // 用户取消授权
    showError('您已取消授权');
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
    // 系统服务异常，请稍后重试
    showError('系统服务异常，请稍后重试');
  } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
    // 重复请求，应用无需处理
    hilog.warn(0x0000, 'testTag', 'Duplicate authorization request');
  } else {
    // 获取用户信息失败，请尝试使用其他方式
    showError('授权失败，请重试');
  }
}

// 错误码枚举
export enum ErrorCode {
  // 账号未登录
  ERROR_CODE_LOGIN_OUT = 1001502001,
  // 网络错误
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  // 用户取消授权
  ERROR_CODE_USER_CANCEL = 1001502012,
  // 系统服务异常
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  // 重复请求
  ERROR_CODE_REQUEST_REFUSE = 1001500002
}

function showError(message: string): void {
  // 实现错误提示UI
  hilog.error(0x0000, 'testTag', message);
}
```

### 步骤3：服务端获取Access Token

**3.1 使用Authorization Code换取Access Token**
```typescript
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

async function getAccessToken(authorizationCode: string): Promise<TokenResponse> {
  const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
  
  const requestBody = {
    grant_type: 'authorization_code',
    code: authorizationCode,
    client_id: '<YOUR_CLIENT_ID>',
    client_secret: '<YOUR_CLIENT_SECRET>',
    redirect_uri: '<YOUR_REDIRECT_URI>'
  };
  
  try {
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      extraData: requestBody
    });
    
    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as TokenResponse;
      return result;
    } else {
      throw new Error(`Failed to get access token: ${response.responseCode}`);
    }
  } catch (error) {
    const err = error as BusinessError;
    throw new Error(`Network error: ${err.message}`);
  }
}
```

### 步骤4：服务端获取实名年龄段

**4.1 调用REST API获取年龄段标识**
```typescript
interface AgeRangeResponse {
  ageRange: number;
  // 其他字段根据实际API返回补充
}

async function getRealNameAgeRange(accessToken: string): Promise<number> {
  const url = 'https://account-api.huawei.com/rest.php?nsp_svc=HUAWEI_EXTERNAL_IDENTITY.getRealNameAgeRange';
  
  try {
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as AgeRangeResponse;
      return result.ageRange;
    } else {
      throw new Error(`Failed to get age range: ${response.responseCode}`);
    }
  } catch (error) {
    const err = error as BusinessError;
    throw new Error(`Network error: ${err.message}`);
  }
}
```

### 步骤5：Access Token过期处理

**5.1 使用Refresh Token刷新Access Token**
```typescript
async function refreshAccessToken(refreshToken: string): Promise<TokenResponse> {
  const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
  
  const requestBody = {
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: '<YOUR_CLIENT_ID>',
    client_secret: '<YOUR_CLIENT_SECRET>'
  };
  
  try {
    const httpRequest = http.createHttp();
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      extraData: requestBody
    });
    
    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as TokenResponse;
      return result;
    } else {
      throw new Error(`Failed to refresh token: ${response.responseCode}`);
    }
  } catch (error) {
    const err = error as BusinessError;
    throw new Error(`Network error: ${err.message}`);
  }
}
```

**5.2 Token过期判断逻辑**
```typescript
// 根据API错误码判断Token是否过期
function isTokenExpired(errorCode: number): boolean {
  // 根据REST API错误码判断
  // 具体错误码请参考REST API文档
  return errorCode === 401 || errorCode === 403;
}

// 自动刷新Token的封装函数
async function getAgeRangeWithTokenRefresh(accessToken: string, refreshToken: string): Promise<number> {
  try {
    return await getRealNameAgeRange(accessToken);
  } catch (error) {
    const err = error as BusinessError;
    if (isTokenExpired(err.code)) {
      // Token过期，使用Refresh Token刷新
      const newToken = await refreshAccessToken(refreshToken);
      return await getRealNameAgeRange(newToken.access_token);
    }
    throw error;
  }
}
```

### 步骤6：完整集成示例

```typescript
// 完整的年龄段获取流程
async function getRealNameAgeRangeComplete(authorizationCode: string): Promise<number> {
  try {
    // 步骤1：使用Authorization Code获取Access Token
    const tokenResponse = await getAccessToken(authorizationCode);
    
    // 步骤2：使用Access Token获取年龄段
    const ageRange = await getRealNameAgeRange(tokenResponse.access_token);
    
    // 步骤3：保存Refresh Token用于后续刷新
    saveRefreshToken(tokenResponse.refresh_token);
    
    return ageRange;
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'testTag', `Failed to get age range: ${err.message}`);
    throw error;
  }
}

function saveRefreshToken(refreshToken: string): void {
  // 安全存储Refresh Token
  // 建议使用加密存储或安全存储组件
}

function sendAuthorizationCodeToServer(authorizationCode: string): void {
  // 将Authorization Code发送到应用服务端
  // 服务端调用getRealNameAgeRangeComplete完成后续流程
}
```

## 错误码说明

### 客户端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 引导用户登录华为账号 |
| 1001502005 | 网络错误 | 检查网络连接并重试 |
| 1001502012 | 用户取消授权 | 提示用户需要授权才能使用功能 |
| 1001502014 | 应用未申请scopes或permissions权限 | 检查权限配置，申请相应权限 |
| 1001500001 | 应用指纹证书校验失败 | 检查签名配置和证书指纹 |
| 1001500002 | 重复请求 | 应用无需处理，可忽略 |
| 12300001 | 系统服务异常 | 稍后重试或联系技术支持 |

### 服务端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Access Token无效或过期 | 使用Refresh Token刷新或重新授权 |
| 403 | 权限不足 | 检查scope权限配置 |
| 400 | 请求参数错误 | 检查请求参数格式 |
| 500 | 服务器内部错误 | 稍后重试或联系技术支持 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**
```json
{
  "dependencies": {
    "@kit.AccountKit": "^1.0.0",
    "@kit.NetworkKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

**module.json5权限配置**
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API版本：>= 4.0.0(10)
- DevEco Studio版本：>= 3.1
- ArkTS语言支持

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：
- 检查DevEco Studio版本是否>= 3.1
- 检查oh-package.json5中是否配置了依赖
- 执行ohpm install重新安装依赖

**问题2：类型定义错误**
```
Error: Property 'createAuthorizationWithHuaweiIDRequest' does not exist on type 'HuaweiIDProvider'
```
**解决方法**：
- 检查API版本是否>= 4.0.0(10)
- 更新SDK到最新版本
- 检查import语句是否正确

**问题3：Context上下文错误**
```
Error: Cannot read property 'getHostContext' of undefined
```
**解决方法**：
- 确保在自定义组件实例中调用
- 使用this.getUIContext().getHostContext()获取正确的Context

**问题4：权限错误1001502014**
```
Error: The app does not have the required scopes or permissions
```
**解决方法**：
- 在AppGallery Connect中申请"获取您的年龄段"权限
- 等待权限审批通过
- 检查scope参数是否正确设置为['realNameAgeRange']

## 常见问题与解决方法

### Q1：如何判断用户是否已授权年龄段信息？
**原因**：应用需要检查授权状态以决定是否需要重新授权
**解决方法**：
- 调用executeRequest时，如果已授权会直接返回Authorization Code
- 如果未授权且forceAuthorization为true，会自动拉起授权页面
- 如果未授权且forceAuthorization为false，会返回错误码1001502002

### Q2：Authorization Code使用失败怎么办？
**原因**：Authorization Code有效期短且只能使用一次
**解决方法**：
- Authorization Code必须在5分钟内使用
- 每个Code只能使用一次，使用后立即失效
- 如果使用失败，需要重新获取新的Authorization Code
- 建议获取后立即发送到服务端处理

### Q3：Access Token过期如何处理？
**原因**：Access Token有效期仅60分钟
**解决方法**：
- 使用Refresh Token刷新Access Token
- Refresh Token有效期180天
- 检测到401或403错误时自动刷新Token
- 如果Refresh Token也过期，需要重新授权

### Q4：如何在服务端安全存储Token？
**原因**：Token是敏感信息，需要安全存储
**解决方法**：
- 使用加密存储方案
- 不要明文存储Access Token和Refresh Token
- 定期更换加密密钥
- 建议使用安全存储组件或密钥管理服务

### Q5：年龄段标识如何解析？
**原因**：API返回的是年龄段标识而非具体年龄
**解决方法**：
- 年龄段标识为数字，具体含义需参考华为文档
- 常见年龄段：0-17岁、18-25岁、26-35岁、36-45岁、46-55岁、56岁以上
- 根据业务需求进行年龄段判断和限制

### Q6：应用未上线能否测试该功能？
**原因**：开发阶段需要测试功能
**解决方法**：
- 使用调试证书进行签名
- 在AppGallery Connect配置调试证书指纹
- 使用测试账号进行授权测试
- 确保测试账号已实名认证

### Q7：如何处理设备不支持的情况？
**原因**：部分设备可能不支持该功能
**解决方法**：
- 检查API版本是否满足要求
- 检查设备类型是否在支持列表中
- 提供友好的错误提示
- 提供降级方案（如手动输入年龄）

## 输出结果报告

执行完成后输出以下信息：

```typescript
interface AgeRangeResult {
  status: 'success' | 'failed';
  ageRange?: number;  // 年龄段标识
  errorMessage?: string;
  authorizationCode?: string;  // 客户端返回
  accessToken?: string;  // 服务端返回
  apiUsed: string[];
}

// 成功示例
const successResult: AgeRangeResult = {
  status: 'success',
  ageRange: 3,  // 例如：26-35岁
  authorizationCode: 'CF%xxxxxxxx',
  accessToken: 'accessTokenString',
  apiUsed: [
    'authentication.HuaweiIDProvider.createAuthorizationWithHuaweiIDRequest',
    'authentication.AuthenticationController.executeRequest',
    'REST API: HUAWEI_EXTERNAL_IDENTITY.getRealNameAgeRange'
  ]
};

// 失败示例
const failedResult: AgeRangeResult = {
  status: 'failed',
  errorMessage: '用户取消授权',
  apiUsed: [
    'authentication.HuaweiIDProvider.createAuthorizationWithHuaweiIDRequest',
    'authentication.AuthenticationController.executeRequest'
  ]
};
```

## 参考文档

- [API开发指南：获取实名年龄段](references/api-guide.md)
- [API参考：authentication模块](references/api-reference.md)
- [开发准备：申请账号权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions)
- [Account Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
- [获取用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [获取实名年龄段接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-realname-age-range-flag)
- [刷新用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token)

## 完整示例代码

- [客户端示例：ArkTS](assets/example-client.ets)
- [服务端示例：ArkTS](assets/example-server.ets)
- [错误处理示例：ArkTS](assets/error-handling.ets)

## 测试用例

### 正向测试用例
- [成功获取年龄段](tests/test_positive.py)：用户已登录且授权，成功获取年龄段
- [自动刷新Token](tests/test_positive.py)：Access Token过期后自动刷新

### 边界测试用例
- [Token即将过期](tests/test_boundary.py)：Access Token有效期不足5分钟
- [网络超时](tests/test_boundary.py)：网络请求超时处理
- [并发请求](tests/test_boundary.py)：多个并发请求获取年龄段

### 异常测试用例
- [用户未登录](tests/test_exception.py)：设备未登录华为账号
- [用户取消授权](tests/test_exception.py)：用户点击取消授权
- [网络异常](tests/test_exception.py)：网络连接失败
- [权限不足](tests/test_exception.py)：未申请realNameAgeRange权限
- [证书校验失败](tests/test_exception.py)：应用签名证书不匹配