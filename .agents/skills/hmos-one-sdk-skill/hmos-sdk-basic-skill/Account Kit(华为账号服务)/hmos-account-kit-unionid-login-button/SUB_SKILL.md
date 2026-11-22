---
name: hmos-account-kit-unionid-login-button
description: 使用华为账号登录按钮组件实现账号登录并获取UnionID/OpenID，支持Phone/Tablet/PC/2in1/TV/Car设备，适用于用户身份识别、账号绑定、跨应用登录场景
---

# 使用"华为账号登录"按钮登录技能

## 功能描述

本技能提供华为账号登录按钮组件的完整实现方案，通过Account Kit提供的LoginWithHuaweiIDButton组件实现华为账号登录，获取用户身份标识UnionID和OpenID，完成用户登录或账号绑定功能。

华为账号登录按钮包含文本、标志和文本+标志三种样式，以满足应用对界面风格一致性和灵活性的要求。支持Phone、Tablet、PC/2in1、TV（5.1.1(19)及以上）、Car（26.0.0及以上）设备。

## 使用场景

### 触发词
- "使用华为账号登录按钮"
- "LoginWithHuaweiIDButton"
- "华为账号登录组件"
- "UnionID登录"
- "OpenID登录"
- "华为账号按钮登录"

### 能做
- 实现华为账号登录按钮UI组件
- 获取Authorization Code和ID Token
- 通过服务端获取UnionID和OpenID
- 完成用户身份识别和账号绑定
- 支持多种设备类型（Phone/Tablet/PC/TV/Car）
- 提供三种按钮样式（纯文本/纯标志/文本+标志）

### 绝不做
- 不直接获取用户敏感信息（手机号、实名信息等）
- 不替代应用自身的账号系统
- 不处理除登录外的其他账号功能（如修改密码、注销账号）
- 不支持未配置Client ID的应用

### 补充
- 需要先配置签名证书指纹和Client ID
- 登录按钮需符合UX设计规范
- 建议通过Authorization Code获取用户信息，避免黑客攻击
- ID Token需验证签名以确保未被篡改

## 调用规范和规则

### 输入约束
- Client ID：必须在AppGallery Connect中配置
- 登录类型：LoginType.ID（获取UnionID/OpenID）
- 按钮样式：Style.BUTTON_RED、Style.BUTTON_WHITE、Style.BUTTON_CUSTOM
- 协议状态：如需用户同意协议，需设置为NOT_ACCEPTED

### 执行约束
- 最大耗时：用户登录授权不超过30秒
- API调用频次：无限制
- 设备支持：Phone/Tablet/PC/2in1/TV(5.1.1+)/Car(26.0.0+)
- 页面生命周期：组件必须在页面或自定义组件生命周期内调用

### 内容约束
- 禁止生成：不含Client ID的登录代码、不含错误处理的登录逻辑
- 禁止使用高危函数：无特殊限制
- 禁止操作：跳过用户授权直接获取凭证、伪造Authorization Code

### 降级约束
- 华为账号未登录：引导用户登录华为账号并重试
- 网络失败：提示检查网络状态并重试
- 权限不足：检查Client ID配置并提示用户
- 用户取消授权：尊重用户选择，不强制授权

## 调用流程和步骤

### 步骤1：开发准备

**前置校验**：
1. 检查是否已配置签名证书指纹
2. 检查是否已配置Client ID
3. 检查设备类型是否符合要求（Phone/Tablet/PC/2in1/TV/Car）

**参数准备**：
```typescript
// 导入必要模块
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：创建登录按钮组件

**示例代码**：
```typescript
@Entry
@Component
struct LoginButtonPage {
  // 构造LoginWithHuaweiIDButton组件的控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.dealAllError(error);
          return;
        }
        if (response) {
          hilog.info(0x0000, 'testTag', 'Succeeded in getting response.');
          const authorizationCode = response.authorizationCode;
          // 开发者处理authorizationCode，发送到服务端获取UnionID/OpenID
        }
      });

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          // 按钮样式：红色背景
          style: loginComponentManager.Style.BUTTON_RED,
          // 边框圆角半径
          borderRadius: 24,
          // 登录类型：获取UnionID/OpenID
          loginType: loginComponentManager.LoginType.ID,
          // 支持深色模式
          supportDarkMode: true
        },
        controller: this.controller
      })
    }
    .height(40)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ left: 16, right: 16 })
  }
}
```

### 步骤3：错误处理

```typescript
// 错误处理函数
dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag',
    `Failed to login, errorCode is ${error.code}, errorMessage is ${error.message}`);
  
  // 根据错误码提示用户
  switch (error.code) {
    case 1001502001:  // ERROR_CODE_LOGIN_OUT
      // 用户未登录华为账号，请登录华为账号并重试
      break;
    case 1001502005:  // ERROR_CODE_NETWORK_ERROR
      // 网络错误，请检查当前网络状态并重试
      break;
    case 1001502009:  // ERROR_CODE_INTERNAL_ERROR
      // 登录失败，请尝试使用其他方式登录
      break;
    case 1001502012:  // ERROR_CODE_USER_CANCEL
      // 用户取消授权
      break;
    case 12300001:    // ERROR_CODE_SYSTEM_SERVICE
      // 系统服务异常，请稍后重试
      break;
    case 1001500002:  // ERROR_CODE_REQUEST_REFUSE
      // 重复请求，应用无需处理
      break;
    case 1005300001:  // ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED
      // 用户未同意协议
      break;
    default:
      // 应用登录失败，请尝试使用其他方式登录
      break;
  }
}
```

### 步骤4：服务端处理（获取UnionID）

**服务端流程**：
1. 使用Client ID、Client Secret、Authorization Code调用获取用户级凭证接口
2. 获取Access Token和Refresh Token
3. 使用Access Token调用解析凭证接口获取UnionID
4. 将UnionID/OpenID与业务账号绑定

```typescript
// 服务端示例代码（Node.js）
const axios = require('axios');

async function getUnionID(authorizationCode) {
  // 步骤1：获取Access Token
  const tokenResponse = await axios.post('https://oauth-login.cloud.huawei.com/oauth2/v2/token', {
    grant_type: 'authorization_code',
    code: authorizationCode,
    client_id: 'YOUR_CLIENT_ID',
    client_secret: 'YOUR_CLIENT_SECRET'
  });
  
  const accessToken = tokenResponse.data.access_token;
  
  // 步骤2：解析凭证获取UnionID
  const userInfoResponse = await axios.get('https://account-api.huawei.com/v2/userInfo', {
    headers: { Authorization: `Bearer ${accessToken}` }
  });
  
  return {
    unionID: userInfoResponse.data.unionID,
    openID: userInfoResponse.data.openID
  };
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 账号未登录 | 提示用户登录华为账号并重试 |
| 1001502005 | 网络错误 | 检查网络连接状态并重试 |
| 1001502009 | 内部错误 | 提示用户使用其他登录方式 |
| 1001502012 | 用户取消授权 | 尊重用户选择，不强制授权 |
| 12300001 | 系统服务异常 | 稍后重试或使用其他登录方式 |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1005300001 | 用户未同意协议 | 提示用户同意协议 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.PerformanceAnalysisKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0及以上
- DevEco Studio：3.1及以上
- 设备支持：Phone/Tablet/PC/2in1/TV(5.1.1+)/Car(26.0.0+)

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.AccountKit'
```
**解决方法**：检查DevEco Studio版本和HarmonyOS SDK版本，确保已安装Account Kit

**问题2：Client ID未配置**
```
Login failed: client_id not found
```
**解决方法**：在AppGallery Connect中配置Client ID并下载agconnect-services.json文件

**问题3：签名证书未配置**
```
Authentication failed: invalid signature
```
**解决方法**：在AppGallery Connect中配置签名证书指纹（SHA256）

## 常见问题与解决方法

### Q1：如何获取Client ID？
**原因**：Client ID是华为账号服务的唯一标识，必须在AppGallery Connect中配置
**解决方法**：
1. 登录AppGallery Connect
2. 选择项目和应用
3. 在"项目设置 > API管理"中启用Account Kit
4. 在"项目设置 > 常规"中查看Client ID
5. 下载agconnect-services.json文件并添加到应用

### Q2：Access Token过期如何处理？
**原因**：Access Token有效期仅为60分钟
**解决方法**：
1. 使用Refresh Token（有效期180天）获取新的Access Token
2. 或重新调用登录接口获取新的Authorization Code

### Q3：如何验证ID Token的签名？
**原因**：防止ID Token被篡改或伪造
**解决方法**：
1. 从华为账号服务官网获取公钥
2. 使用公钥验证ID Token中的签名
3. 检查iss、aud、exp等字段是否正确

### Q4：按钮样式不符合需求怎么办？
**原因**：默认样式可能不满足应用的UI设计
**解决方法**：
1. 使用Style.BUTTON_CUSTOM自定义按钮样式
2. 通过extraStyle设置文本颜色、背景颜色
3. 确保符合UX设计规范

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "authorizationCode": "用户授权码",
  "unionID": "用户唯一标识（跨应用）",
  "openID": "应用内用户唯一标识",
  "loginType": "LoginType.ID",
  "deviceType": "Phone/Tablet/PC/2in1/TV/Car",
  "apiUsed": [
    "LoginWithHuaweiIDButton",
    "onClickLoginWithHuaweiIDButton",
    "获取用户级凭证接口",
    "解析凭证接口"
  ]
}
```

## 参考文档

- [API开发指南](references/account-unionid-login-button.md)
- [LoginWithHuaweiIDButton组件](references/account-api-huawei-id-button.md)
- [组件管理器](references/account-api-component-manager.md)
- [获取用户级凭证](references/account-api-obtain-user-token.md)
- [解析凭证接口](references/account-api-get-token-info.md)
- [华为账号登录UX设计规范](https://developer.huawei.com/consumer/cn/doc/design-guides/id-0000001880001344#section2624430102713)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)

## 完整示例代码

- [ArkTS示例代码](assets/login-button-example.ets)
- [配置文件示例](assets/module.json5)
- [服务端示例(Node.js)](assets/server-example.js)

## 测试用例

### 正向测试用例
- [正常登录流程](tests/test_positive_login.ets)：测试完整的登录流程
- [获取UnionID/OpenID](tests/test_positive_get_id.ets)：测试成功获取身份标识

### 边界测试用例
- [Access Token过期](tests/test_boundary_token_expire.ets)：测试Token过期处理
- [多设备登录](tests/test_boundary_multi_device.ets)：测试不同设备类型

### 异常测试用例
- [未配置Client ID](tests/test_exception_no_client_id.ets)：测试配置缺失场景
- [用户取消授权](tests/test_exception_user_cancel.ets)：测试用户取消场景
- [网络错误](tests/test_exception_network_error.ets)：测试网络异常场景
