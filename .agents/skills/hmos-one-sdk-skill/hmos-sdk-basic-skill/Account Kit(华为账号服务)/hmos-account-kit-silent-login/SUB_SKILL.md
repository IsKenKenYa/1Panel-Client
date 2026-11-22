---
name: hmos-account-kit-silent-login
description: 实现华为账号静默登录，获取UnionID/OpenID，支持应用卸载重装和换机场景，无需用户点击登录按钮即可完成登录，适用于快速自动登录场景
---

# 静默登录技能

## 功能描述

静默登录是指在用户已登录华为账号的前提下，应用无需用户点击登录/注册按钮，即可获取用户的身份标识UnionID/OpenID，完成用户的静默登录。适用于应用卸载重装、用户换机等场景，如登录的华为账号与应用重装、换机前一致，应用可通过Account Kit提供的静默登录方式快速完成用户身份验证。

**核心能力**：
- 无需用户交互即可获取Authorization Code
- 获取ID Token用于身份验证
- 获取UnionID/OpenID用于用户身份标识
- 支持跨设备、跨应用版本的用户身份一致性校验

**技术特点**：
- 基于OAuth 2.0协议
- 支持防跨站攻击（state参数校验）
- 支持防重放攻击（nonce参数校验）
- Access Token有效期60分钟，Refresh Token有效期180天

## 使用场景

### 触发词
- "静默登录"
- "华为账号自动登录"
- "获取UnionID"
- "获取OpenID"
- "应用卸载重装登录"
- "用户换机登录"
- "账号身份标识"

### 能做
- 在华为账号已登录时，自动获取Authorization Code和ID Token
- 获取用户的UnionID/OpenID身份标识
- 完成应用卸载重装、换机后的静默登录
- 实现用户身份一致性校验
- 通过服务端解析Access Token获取用户信息
- 处理Access Token和Refresh Token的刷新机制

### 绝不做
- 不能在华为账号未登录时强制拉起登录界面（forceLogin=false时返回错误码）
- 不能在未配置Client ID和签名的情况下使用
- 不能在未申请相关权限的场景下使用
- 不能直接在客户端解析ID Token（需通过服务端或公开公钥验证）

### 补充
- 仅支持Phone、Tablet、PC/2in1设备，从5.1.0(18)版本开始支持Wearable，5.1.1(19)版本开始支持TV，26.0.0版本开始支持Car
- 需要用户已登录华为账号，否则会返回1001502001错误码
- 需要先完成配置签名和指纹、配置Client ID的前置工作
- Authorization Code仅能使用一次，有效期5分钟
- 建议使用generateRandomUUID生成state和nonce参数

## 调用规范和规则

### 输入约束
- 必须提供有效的Client ID（在AppGallery Connect中配置）
- 必须完成签名和指纹配置
- forceLogin参数必须设置为false（静默登录场景）
- state参数长度限制：1-255字符，包含0-9、a-z、A-Z、英文点号、英文冒号、斜杠、下划线
- nonce参数长度限制：1-255字符，包含0-9、a-z、A-Z、点号、冒号、斜杠、下划线

### 执行约束
- Authorization Code获取后必须在5分钟内使用
- Authorization Code仅能使用一次，重复使用会失败
- Access Token有效期60分钟，需要刷新机制
- Refresh Token有效期180天，过期后需重新授权
- 最大请求耗时：建议30秒内完成
- 网络请求建议使用HTTPS协议

### 内容约束
- 禁止在客户端硬编码Client Secret（应保存在服务端）
- 禁止忽略state参数的一致性校验（防止跨站攻击）
- 禁止忽略ID Token的签名验证（防止伪造）
- 禁止在未验证的情况下直接使用Authorization Code
- 禁止将Access Token暴露给客户端应用

### 降级约束
- 华为账号未登录（1001502001）：提示用户使用其他方式登录或引导登录华为账号
- 网络错误（1001502005）：检查网络状态并重试，最多3次
- 内部错误（1001502009）：提示用户稍后重试或使用其他登录方式
- 用户取消授权（1001502012）：提示用户授权后才能继续
- 系统服务异常（12300001）：提示用户稍后重试或使用其他登录方式
- Authorization Code过期：重新发起静默登录请求
- Access Token过期：使用Refresh Token刷新，如Refresh Token也过期则重新登录

## 调用流程和步骤

### 步骤1：准备阶段（前置校验）

**前置条件检查**：
1. 检查是否已配置Client ID和签名指纹
2. 检查用户是否已登录华为账号（可通过getHuaweiIDState接口判断）
3. 检查网络连接状态
4. 准备state和nonce参数（建议使用util.generateRandomUUID生成）

**导入必要模块**：
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：创建登录请求

**创建LoginWithHuaweiIDRequest对象**：
```typescript
// 创建华为账号提供者实例
const huaweiIdProvider = new authentication.HuaweiIDProvider();

// 创建登录请求对象
const loginRequest = huaweiIdProvider.createLoginWithHuaweiIDRequest();

// 设置静默登录参数
loginRequest.forceLogin = false; // 关键参数：false表示静默登录
loginRequest.state = util.generateRandomUUID(); // 用于一致性校验，防止跨站攻击
loginRequest.nonce = util.generateRandomUUID(); // 用于防重放攻击
loginRequest.idTokenSignAlgorithm = authentication.IdTokenSignAlgorithm.PS256; // ID Token签名算法
```

**参数说明**：
- `forceLogin`: 必须设置为false，否则会拉起登录界面（非静默登录）
- `state`: 建议使用随机UUID，用于响应一致性校验
- `nonce`: 建议使用随机UUID，会包含在ID Token中
- `idTokenSignAlgorithm`: 可选，默认PS256

### 步骤3：执行登录请求

**调用executeRequest方法**：
```typescript
// 创建认证控制器
const controller = new authentication.AuthenticationController();

try {
  // 执行登录请求（异步Promise方式）
  controller.executeRequest(loginRequest).then((response: authentication.AuthenticationResponse) => {
    // 类型转换为LoginWithHuaweiIDResponse
    const loginWithHuaweiIDResponse = response as authentication.LoginWithHuaweiIDResponse;
    
    // 校验state参数一致性（防止跨站攻击）
    const responseState = loginWithHuaweiIDResponse.state;
    if (responseState && loginRequest.state !== responseState) {
      hilog.error(0x0000, 'testTag', `Failed to login. State mismatch: expected ${loginRequest.state}, got ${responseState}`);
      return;
    }
    
    hilog.info(0x0000, 'testTag', 'Succeeded in silent login.');
    
    // 获取登录凭证
    const credential = loginWithHuaweiIDResponse.data;
    if (credential) {
      const authorizationCode = credential.authorizationCode; // Authorization Code
      const idToken = credential.idToken; // ID Token
      const unionId = credential.unionId; // UnionID（可选）
      const openId = credential.openId; // OpenID（可选）
      
      // 将Authorization Code发送到服务端处理
      sendAuthorizationCodeToServer(authorizationCode);
    }
  }).catch((error: BusinessError) => {
    handleLoginError(error);
  });
} catch (error) {
  handleLoginError(error as BusinessError);
}
```

**关键校验点**：
- state参数一致性校验（必须）
- authorizationCode有效性判断
- 错误码识别和处理

### 步骤4：服务端处理Authorization Code

**服务端获取Access Token**：

服务端需要调用华为账号REST API，使用Authorization Code换取Access Token。

```typescript
// 服务端代码示例（Node.js）
import axios from 'axios';

async function getAccessToken(authorizationCode: string): Promise<any> {
  const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
  
  const params = new URLSearchParams();
  params.append('grant_type', 'authorization_code');
  params.append('code', authorizationCode);
  params.append('client_id', process.env.CLIENT_ID); // 从AGC获取
  params.append('client_secret', process.env.CLIENT_SECRET); // 从AGC获取
  params.append('supportAlg', 'PS256'); // ID Token签名算法
  
  try {
    const response = await axios.post(url, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    return {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      expiresIn: response.data.expires_in,
      idToken: response.data.id_token,
      scope: response.data.scope
    };
  } catch (error) {
    console.error('Failed to get access token:', error.response?.data);
    throw error;
  }
}
```

**接口参数说明**：
- URL: `https://oauth-login.cloud.huawei.com/oauth2/v3/token`
- grant_type: 固定值`authorization_code`
- code: 客户端传递的Authorization Code
- client_id: AppGallery Connect中的Client ID
- client_secret: AppGallery Connect中的Client Secret（必须保存在服务端）
- supportAlg: ID Token签名算法（PS256或RS256）

### 步骤5：解析Access Token获取用户信息

**调用解析凭证接口**：

```typescript
// 服务端代码示例
async function parseAccessToken(accessToken: string): Promise<any> {
  const url = 'https://oauth-api.cloud.huawei.com/rest.php?nsp_fmt=JSON&nsp_svc=huawei.oauth2.user.getTokenInfo';
  
  const params = new URLSearchParams();
  params.append('access_token', accessToken);
  params.append('open_id', 'OPENID'); // 用于获取OpenID
  
  try {
    const response = await axios.post(url, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    return {
      clientId: response.data.client_id,
      unionId: response.data.union_id,
      openId: response.data.open_id,
      scope: response.data.scope,
      expiresIn: response.data.expire_in,
      projectId: response.data.project_id
    };
  } catch (error) {
    console.error('Failed to parse access token:', error.response?.data);
    throw error;
  }
}
```

**返回字段说明**：
- `union_id`: 用户UnionID，用于跨应用用户身份标识
- `open_id`: 用户OpenID，用于当前应用的用户身份标识
- `client_id`: 应用的Client ID
- `expire_in`: Access Token过期时间（秒）
- `scope`: 用户授权的scope列表

### 步骤6：完成用户登录

**用户身份验证流程**：
```typescript
// 完整的静默登录流程
async function completeSilentLogin(authorizationCode: string): Promise<any> {
  try {
    // 步骤1：获取Access Token
    const tokenInfo = await getAccessToken(authorizationCode);
    
    // 步骤2：解析Access Token获取用户信息
    const userInfo = await parseAccessToken(tokenInfo.accessToken);
    
    // 步骤3：查询应用用户体系，判断用户是否已关联
    const existingUser = await queryUserByUnionId(userInfo.unionId);
    
    if (existingUser) {
      // 用户已存在，完成登录
      const sessionId = generateSessionId();
      await updateUserSession(existingUser.id, sessionId);
      
      return {
        success: true,
        userId: existingUser.id,
        unionId: userInfo.unionId,
        openId: userInfo.openId,
        sessionId: sessionId
      };
    } else {
      // 用户不存在，创建新用户并绑定UnionID
      const newUser = await createNewUser(userInfo.unionId, userInfo.openId);
      const sessionId = generateSessionId();
      await updateUserSession(newUser.id, sessionId);
      
      return {
        success: true,
        userId: newUser.id,
        unionId: userInfo.unionId,
        openId: userInfo.openId,
        sessionId: sessionId
      };
    }
  } catch (error) {
    console.error('Silent login failed:', error);
    throw error;
  }
}
```

### 步骤7：Access Token刷新机制

**处理Access Token过期**：
```typescript
// 使用Refresh Token刷新Access Token
async function refreshAccessToken(refreshToken: string): Promise<any> {
  const url = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';
  
  const params = new URLSearchParams();
  params.append('grant_type', 'refresh_token');
  params.append('refresh_token', refreshToken);
  params.append('client_id', process.env.CLIENT_ID);
  params.append('client_secret', process.env.CLIENT_SECRET);
  
  try {
    const response = await axios.post(url, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    return {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token, // 可能会返回新的Refresh Token
      expiresIn: response.data.expires_in
    };
  } catch (error) {
    console.error('Failed to refresh access token:', error.response?.data);
    throw error;
  }
}
```

**刷新策略**：
- Access Token有效期60分钟，建议在50分钟时预刷新
- Refresh Token有效期180天，过期后需重新授权
- 检查REST API错误码判断Token是否过期

## 错误码说明

### 客户端错误码（ArkTS API）

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 提示用户登录华为账号或使用其他登录方式 |
| 1001502005 | 网络错误 | 检查网络连接状态并重试（最多3次） |
| 1001502009 | 内部错误 | 提示用户稍后重试或使用其他登录方式 |
| 1001502012 | 用户取消授权 | 提示用户需要授权才能继续 |
| 1001500002 | 重复请求 | 应用无需处理，自动忽略 |
| 12300001 | 系统服务异常 | 提示用户稍后重试或使用其他登录方式 |

### 服务端错误码（REST API）

| 错误码/子错误码 | 说明 | 解决方法 |
|----------------|------|---------|
| 1203/12304 | Client Secret无效 | 检查Client Secret配置是否正确 |
| 1203/12302 | Authorization Code无效或过期 | Authorization Code已使用或超过5分钟有效期，需重新获取 |
| 1203/12300 | Authorization Code重复使用 | Authorization Code仅能使用一次，需重新获取 |
| 1102 | Access Token过期 | 使用Refresh Token刷新Access Token |
| 1108 | Refresh Token过期 | Refresh Token超过180天有效期，需重新授权 |

**错误处理示例**：
```typescript
function handleLoginError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Login failed. Code: ${error.code}, message: ${error.message}`);
  
  switch (error.code) {
    case 1001502001: // 用户未登录华为账号
      showUserMessage('请先登录华为账号，或使用其他方式登录');
      break;
      
    case 1001502005: // 网络错误
      showUserMessage('网络连接失败，请检查网络后重试');
      retryLogin(3); // 最多重试3次
      break;
      
    case 1001502009: // 内部错误
      showUserMessage('登录失败，请稍后重试或使用其他方式登录');
      break;
      
    case 1001502012: // 用户取消授权
      showUserMessage('需要授权才能继续使用');
      break;
      
    case 12300001: // 系统服务异常
      showUserMessage('系统服务异常，请稍后重试');
      break;
      
    case 1001500002: // 重复请求
      // 应用无需处理
      break;
      
    default:
      showUserMessage('登录失败，请尝试其他方式');
  }
}
```

## 编译和修复问题

### 依赖声明

**客户端（ArkTS）**：
```json
{
  "dependencies": {
    "@kit.AccountKit": "^4.0.0",
    "@kit.PerformanceAnalysisKit": "^4.0.0",
    "@kit.ArkTS": "^4.0.0",
    "@kit.BasicServicesKit": "^4.0.0"
  }
}
```

**服务端（Node.js）**：
```json
{
  "dependencies": {
    "axios": "^1.6.0"
  }
}
```

### 环境要求

**客户端环境**：
- HarmonyOS SDK版本：4.0.0(10)及以上
- 支持设备：Phone、Tablet、PC/2in1（5.1.0支持Wearable，5.1.1支持TV，26.0.0支持Car）
- 开发模型：Stage模型
- 必须配置签名和指纹

**服务端环境**：
- Node.js版本：14.0.0及以上
- HTTPS协议支持（TLS1.2及以上）
- 网络可访问华为账号服务器域名

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**：确保HarmonyOS SDK版本≥4.0.0(10)，检查项目配置文件中的依赖声明。

**问题2：类型定义错误**
```
Error: Property 'forceLogin' does not exist on type 'LoginWithHuaweiIDRequest'
```
**解决方法**：检查SDK版本是否≥4.0.0(10)，确保导入正确的authentication模块。

**问题3：AuthenticationController构造失败**
```
Error: Cannot create AuthenticationController
```
**解决方法**：确保在Stage模型下使用，检查Context是否正确传递。

**问题4：网络请求失败**
```
Error: Network request failed to oauth-login.cloud.huawei.com
```
**解决方法**：检查网络连接，确保使用HTTPS协议，检查防火墙配置是否允许访问华为服务器。

## 常见问题与解决方法

### Q1：静默登录时返回1001502001错误码怎么办？

**原因**：用户未登录华为账号，forceLogin=false时不会拉起登录界面。

**解决方法**：
- 提示用户登录华为账号后重试
- 提供其他登录方式（如手动登录、账号密码登录）
- 可使用getHuaweiIDState接口提前判断登录状态
- 如需要强制登录，可设置forceLogin=true（但会拉起登录界面，非静默登录）

### Q2：Authorization Code获取后多久会过期？

**原因**：Authorization Code具有时效性和一次性使用限制。

**解决方法**：
- Authorization Code有效期5分钟，必须在此时间内发送到服务端
- Authorization Code仅能使用一次，重复使用会失败
- 建议获取后立即发送到服务端处理
- 如过期或已使用，需重新发起静默登录请求

### Q3：Access Token过期后如何处理？

**原因**：Access Token有效期仅为60分钟。

**解决方法**：
- 使用Refresh Token刷新Access Token（有效期180天）
- 在Access Token即将过期时（50分钟）预刷新
- 如Refresh Token也过期，需重新发起登录请求
- 检查REST API返回的错误码（1102表示Access Token过期）

### Q4：如何验证ID Token的有效性？

**原因**：ID Token包含用户信息，需要验证其真实性防止伪造。

**解决方法**：
- 使用华为账号服务器发布的公钥验证签名
- 验证ID Token中的issuer、audience等字段
- 验证nonce参数的一致性（防止重放攻击）
- 验证过期时间（exp字段）
- 可参考ID Token解析与验证文档

### Q5：state参数校验失败怎么办？

**原因**：响应中的state参数与请求中的不一致，可能是跨站攻击。

**解决方法**：
- 严格校验state参数的一致性
- 如不一致，拒绝登录结果并记录日志
- 使用generateRandomUUID生成state参数
- 每次请求使用不同的state值

### Q6：如何处理换机场景的静默登录？

**原因**：用户换机后，需要判断华为账号是否与之前一致。

**解决方法**：
- 使用UnionID作为用户身份标识（跨应用唯一）
- 在服务端保存用户与UnionID的关联关系
- 换机后静默登录获取UnionID，与之前保存的对比
- 如一致，直接完成登录；如不一致，提示用户账号变化

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "silent_login",
  "data": {
    "authorizationCode": "获取的Authorization Code",
    "idToken": "获取的ID Token",
    "unionId": "用户的UnionID",
    "openId": "用户的OpenID",
    "accessToken": "服务端获取的Access Token",
    "refreshToken": "服务端获取的Refresh Token",
    "expiresIn": "Access Token过期时间（秒）"
  },
  "apiUsed": [
    "createLoginWithHuaweiIDRequest",
    "AuthenticationController.executeRequest",
    "LoginWithHuaweiIDResponse",
    "获取用户级凭证接口",
    "解析凭证接口"
  ],
  "timestamp": "操作完成时间",
  "deviceId": "设备标识"
}
```

## 参考文档

- [API开发指南 - 静默登录](references/account-silent-login-guide.md)
- [API参考 - authentication模块](references/account-api-authentication.md)
- [API参考 - 获取用户级凭证](references/account-api-obtain-user-token.md)
- [API参考 - 解析凭证](references/account-api-get-token-info.md)
- [API参考 - 刷新用户级凭证](references/account-api-obtain-refresh-token.md)
- [错误码参考](references/account-api-error-code.md)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)
- [客户端与服务端交互开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-phone-unionid-login)
- [ID Token解析与验证](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-12)

## 完整示例代码

### 客户端示例（ArkTS）

- [静默登录完整示例](assets/silent_login_example.ets) - 包含完整的客户端静默登录流程
- [错误处理示例](assets/error_handling_example.ets) - 包含完整的错误处理逻辑

### 服务端示例（Node.js）

- [获取Access Token示例](assets/get_access_token.js) - 服务端使用Authorization Code获取Access Token
- [解析Access Token示例](assets/parse_access_token.js) - 服务端解析Access Token获取用户信息
- [刷新Token示例](assets/refresh_token.js) - 使用Refresh Token刷新Access Token

### 配置文件示例

- [Client ID配置示例](assets/client_config.json) - Client ID和Client Secret配置模板
- [请求参数示例](assets/request_params.json) - 登录请求参数配置模板

## 测试用例

### 正向测试用例

- [华为账号已登录静默登录测试](tests/test_positive_1.ts) - 测试在华为账号已登录情况下的静默登录
- [获取Authorization Code测试](tests/test_positive_2.ts) - 测试Authorization Code获取成功
- [state参数一致性校验测试](tests/test_positive_3.ts) - 测试state参数校验通过
- [服务端Token获取测试](tests/test_positive_4.js) - 测试服务端成功获取Access Token
- [用户信息解析测试](tests/test_positive_5.js) - 测试成功解析用户UnionID/OpenID

### 边界测试用例

- [Authorization Code有效期测试](tests/test_boundary_1.ts) - 测试Authorization Code在5分钟内使用
- [Access Token刷新时机测试](tests/test_boundary_2.js) - 测试在60分钟前刷新Access Token
- [Refresh Token有效期测试](tests/test_boundary_3.js) - 测试Refresh Token180天有效期边界
- [state参数长度边界测试](tests/test_boundary_4.ts) - 测试state参数255字符限制
- [nonce参数长度边界测试](tests/test_boundary_5.ts) - 测试nonce参数255字符限制

### 异常测试用例

- [华为账号未登录测试](tests/test_exception_1.ts) - 测试返回1001502001错误码处理
- [网络错误测试](tests/test_exception_2.ts) - 测试返回1001502005错误码处理
- [用户取消授权测试](tests/test_exception_3.ts) - 测试返回1001502012错误码处理
- [Authorization Code过期测试](tests/test_exception_4.js) - 测试Authorization Code超过5分钟失效
- [Authorization Code重复使用测试](tests/test_exception_5.js) - 测试Authorization Code重复使用失败
- [Access Token过期测试](tests/test_exception_6.js) - 测试Access Token过期后的刷新机制
- [Refresh Token过期测试](tests/test_exception_7.js) - 测试Refresh Token过期后重新授权
- [Client Secret无效测试](tests/test_exception_8.js) - 测试Client Secret配置错误
- [state参数不一致测试](tests/test_exception_9.ts) - 测试state参数校验失败处理