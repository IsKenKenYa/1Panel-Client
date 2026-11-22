---
name: hmos-account-kit-quicklogin
description: 实现华为账号一键登录获取用户手机号和身份标识(UnionID/OpenID)，支持企业开发者应用的快速用户注册登录，仅限中国境内用户，适用于简化登录流程场景
---

# 华为账号一键登录技能

## 功能描述

本技能提供华为账号一键登录能力的完整实现方案，通过Account Kit获取华为账号用户的匿名手机号和身份标识（UnionID/OpenID），实现应用快速登录注册功能。

**核心能力**：
- 获取华为账号绑定的匿名手机号（用于登录页面展示）
- 获取Authorization Code（临时授权凭证）
- 服务端获取完整手机号、UnionID、OpenID
- 实现用户账号关联和登录状态管理

**技术架构**：
- 客户端：使用ArkTS API调用Account Kit组件
- 服务端：使用REST API向华为账号服务器获取用户信息
- 安全机制：基于OAuth 2.0和OpenID Connect协议标准

**适用场景**：
- 新用户快速注册：利用系统账号安全性和便利性，简化登录步骤
- 已有用户账号关联：通过UnionID/OpenID实现静默登录
- 手机号验证：获取系统验证过的手机号，关联应用已有用户

## 使用场景

### 触发词
- "华为账号一键登录"
- "获取手机号登录"
- "UnionID/OpenID登录"
- "Account Kit一键登录"
- "快速登录注册"

### 能做
- 实现华为账号一键登录完整流程（客户端+服务端）
- 获取华为账号用户的匿名手机号用于展示
- 获取Authorization Code传递给服务端
- 服务端获取完整手机号、UnionID、OpenID
- 实现用户账号关联和登录状态管理
- 处理儿童账号登录的家长验密流程
- 获取用户风险等级进行风控

### 绝不做
- 个人开发者应用的一键登录（仅支持企业开发者）
- 海外用户登录（仅限中国境内用户，香港、澳门、台湾除外）
- Wearable设备一键登录（不支持）
- 使用LoginType.ID或其他登录类型替代QUICK_LOGIN
- 获取非华为账号绑定的手机号
- 绕过华为账号用户认证协议展示

### 补充
- **权限要求**：需要在AGC申请"华为账号一键登录"权限
- **签名配置**：必须配置应用签名和指纹证书
- **协议展示**：必须展示《华为账号用户认证协议》并实现跳转
- **代码混淆**：需要配置quickLoginAnonymousPhone属性白名单
- **设备限制**：支持Phone、Tablet、PC/2in1、TV(5.1.1+)、Car(26.0.0+)
- **用户限制**：仅限企业开发者使用，华为账号必须登录且绑定手机号

## 调用规范和规则

### 输入约束
- **Authorization Code**：
  - 有效期：5分钟
  - 使用次数：仅可使用1次
  - 来源：必须通过华为账号一键登录场景获取
  - 格式：长度限制1-1024字符

- **Client ID/Client Secret**：
  - 来源：AGC分配的OAuth 2.0客户端凭据
  - 配置：Client ID必须与获取code时一致
  - 存储：服务端安全存储，禁止硬编码在客户端

- **匿名手机号**：
  - 格式：中国境内不包含国际区号，其他地区包含国际区号
  - 展示：必须展示在登录页面
  - 时效：获取时建议设置5秒超时

### 执行约束
- **网络要求**：必须使用TLS 1.2及以上协议
- **服务器部署**：必须部署在中国境内（香港、澳门、台湾除外）
- **API调用频次**：Authorization Code只能使用一次
- **用户协议**：用户必须同意《华为账号用户认证协议》才能登录
- **手机号验证**：90天内未验证触发Account Kit短信验证流程

### 内容约束
- **禁止生成**：
  - 伪造或篡改Authorization Code
  - 硬编码Client ID/Client Secret在客户端代码
  - 绕过协议展示直接调用登录API
  - 使用高危函数（eval、exec等）

- **必须包含**：
  - 《华为账号用户认证协议》展示和跳转逻辑
  - 错误码处理和用户友好提示
  - 用户同意协议的状态管理
  - 其他登录方式的降级处理

- **UI规范**：
  - 按钮样式遵循华为账号登录视觉规范
  - 系统深浅色模式适配
  - 协议文本可点击可跳转

### 降级约束
- **华为账号未登录**：
  - 返回错误码1001502001
  - 应用展示其他登录方式
  
- **海外账号不支持**：
  - 返回错误码1001500003
  - 应用展示其他登录方式或华为账号登录按钮

- **匿名手机号为空**：
  - 说明账号未绑定手机号或权限未生效
  - 应用展示其他登录方式

- **网络异常**：
  - 返回错误码1001502005
  - 提示用户检查网络状态后重试

- **服务端获取失败**：
  - code过期/已使用：引导用户重新授权
  - 无手机号：展示其他登录方式
  - 系统错误：稍后重试或使用其他方式

## 调用流程和步骤

### 步骤1：开发准备

**前置校验**：
1. 在AGC申请"华为账号一键登录"权限
2. 配置应用签名和指纹证书
3. 获取Client ID和Client Secret
4. 确认应用为企业开发者应用
5. 确认目标用户为中国境内用户

**权限配置示例**：
```json
// module.json5配置
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

**混淆白名单配置**（obfuscation-rules.txt）：
```
# 开发者开启属性混淆需要配置quickLoginAnonymousPhone属性白名单防止其被混淆
-enable-property-obfuscation
-keep-property-name
quickLoginAnonymousPhone
```

### 步骤2：客户端获取匿名手机号

**API说明**：
使用`AuthorizationWithHuaweiIDRequest`接口，scope传入`quickLoginAnonymousPhone`获取匿名手机号。

**参数准备**：
```typescript
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建授权请求
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
// 设置scope获取匿名手机号
authRequest.scopes = ['quickLoginAnonymousPhone'];
// 使用generateRandomUUID生成state，防止跨站攻击
authRequest.state = util.generateRandomUUID();
// 一键登录场景必须设置为false
authRequest.forceAuthorization = false;
```

**执行请求**：
```typescript
async getQuickLoginAnonymousPhone(): Promise<string> {
  const controller = new authentication.AuthenticationController();
  let quickLoginAnonymousPhone: string = '';
  
  try {
    const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;
    
    // 获取匿名手机号
    quickLoginAnonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;
    
    if (quickLoginAnonymousPhone) {
      hilog.info(0x0000, 'testTag', 'Succeeded in getting anonymous phone.');
      return quickLoginAnonymousPhone;
    }
    
    // 未获取到匿名手机号，展示其他登录方式
    hilog.info(0x0000, 'testTag', 'Anonymous phone is empty.');
    return '';
  } catch (error) {
    this.dealAllError(error as BusinessError);
    return '';
  }
}
```

**错误处理**：
```typescript
dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `errorCode: ${error.code}, message: ${error.message}`);
  
  // 根据错误码进行不同处理
  if (error.code === 1001502001) {
    // 用户未登录华为账号，展示其他登录方式
  } else if (error.code === 1001502005) {
    // 网络错误，提示检查网络状态
  } else if (error.code === 1001502009) {
    // 内部错误，展示其他登录方式
  } else if (error.code === 1001502014) {
    // 应用未申请权限，参考FAQ解决
  } else if (error.code === 1001500001) {
    // 应用指纹证书校验失败，参考FAQ解决
  } else if (error.code === 1001500003) {
    // 不支持该scope（海外账号），展示其他登录方式
  } else if (error.code === 12300001) {
    // 系统服务异常，展示其他登录方式
  }
}
```

### 步骤3：展示一键登录页面并获取Authorization Code

**组件准备**：
使用`LoginWithHuaweiIDButton`组件，设置`loginType`为`QUICK_LOGIN`。

**完整实现**：
```typescript
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
struct QuickLoginButtonComponent {
  @State quickLoginAnonymousPhone: string = ''; // 步骤2获取的匿名手机号
  @State isSelected: boolean = false; // 协议勾选状态
  
  // 华为账号用户认证协议链接
  private static USER_AUTHENTICATION_PROTOCOL: string =
    'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN';
  
  // 定义隐私文本
  privacyText: loginComponentManager.PrivacyText[] = [
    { text: '已阅读并同意', type: loginComponentManager.TextType.PLAIN_TEXT },
    { text: '《用户服务协议》', tag: '用户服务协议', type: loginComponentManager.TextType.RICH_TEXT },
    { text: '《隐私协议》', tag: '隐私协议', type: loginComponentManager.TextType.RICH_TEXT },
    { text: '和', type: loginComponentManager.TextType.PLAIN_TEXT },
    { text: '《华为账号用户认证协议》', tag: '华为账号用户认证协议', type: loginComponentManager.TextType.RICH_TEXT },
    { text: '。', type: loginComponentManager.TextType.PLAIN_TEXT }
  ];
  
  // 构造控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined, 
        response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleLoginError(error);
          return;
        }
        
        if (response) {
          // 获取Authorization Code
          const authCode = response.authorizationCode;
          hilog.info(0x0000, 'testTag', 'Succeeded in getting Authorization Code.');
          
          // 将authCode传给应用服务端
          this.sendAuthCodeToServer(authCode);
        }
      })
      .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
        if (error) {
          hilog.error(0x0000, 'testTag', `onClickEvent error: ${error.message}`);
          return;
        }
        // 设置按钮不可点击态，防止重复点击
        this.controller.setEnabled(false);
      });
  
  build() {
    Column() {
      // 展示匿名手机号
      Text(this.quickLoginAnonymousPhone)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
      
      Text('华为账号绑定号码')
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      
      // 一键登录按钮
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.QUICK_LOGIN,
          supportDarkMode: true,
          extraStyle: {
            buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({ show: true })
          }
        },
        controller: this.controller
      })
      
      // 协议勾选框
      Row() {
        Checkbox({ name: 'privacyCheckbox', group: 'privacyCheckboxGroup' })
          .select(this.isSelected)
          .onChange((value: boolean) => {
            this.isSelected = value;
            this.controller.setAgreementStatus(
              value ? loginComponentManager.AgreementStatus.ACCEPTED : 
                     loginComponentManager.AgreementStatus.NOT_ACCEPTED
            );
          })
        
        // 协议文本（可点击跳转）
        Text() {
          ForEach(this.privacyText, (item: loginComponentManager.PrivacyText) => {
            if (item.type === loginComponentManager.TextType.PLAIN_TEXT) {
              Span(item.text)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            } else {
              Span(item.text)
                .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
                .onClick(() => {
                  if (item.tag === '华为账号用户认证协议') {
                    // 跳转华为账号用户认证协议页面
                    this.jumpToPrivacyWebView();
                  }
                })
            }
          })
        }
      }
    }
  }
  
  // 跳转协议页面
  jumpToPrivacyWebView() {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/WebPage',
      params: { url: QuickLoginButtonComponent.USER_AUTHENTICATION_PROTOCOL }
    });
  }
}
```

### 步骤4：客户端发送Authorization Code到服务端

**使用Remote Communication Kit**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export function sendAuthCodeToServer(authCode: string) {
  const headers: rcp.RequestHeaders = {
    'accept': 'application/json',
    'Content-Type': 'application/json'
  };
  
  const postMessage: Record<string, string> = {
    'authorizationCode': authCode
  };
  
  const securityConfig: rcp.SecurityConfiguration = {
    tlsOptions: { tlsVersion: 'TlsV1.3' }
  };
  
  // 应用服务端地址
  const baseUrl = 'http://localhost:8080/login';
  const req = new rcp.Request(baseUrl, 'POST', headers, postMessage);
  
  try {
    const session = rcp.createSession({ requestConfiguration: { security: securityConfig } });
    
    session.fetch(req).then((response) => {
      if (response.body) {
        const decoder = util.TextDecoder.create('utf-8');
        const result = JSON.parse(decoder.decodeToString(new Uint8Array(response.body)));
        
        // 解析用户信息
        const phoneNumber = result['phone'];
        const unionId = result['unionId'];
        
        // 处理登录成功逻辑
        this.handleLoginSuccess(phoneNumber, unionId);
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', `Request failed: ${err.message}`);
    });
  } catch (err) {
    hilog.error(0x0000, 'testTag', `Session error: ${err}`);
  }
}
```

### 步骤5：服务端获取用户信息

**调用华为账号REST API**：
```typescript
// 接口地址
const phone_number_url = "https://account-api.cloud.huawei.com/oauth2/v6/quickLogin/getPhoneNumber";

// 构建请求体
const token_request_body = {
  "clientId": "<Client ID>",       // AGC分配的Client ID
  "clientSecret": "<Client Secret>", // AGC分配的Client Secret
  "code": authorization_code       // 客户端传来的Authorization Code
};

// 发送POST请求
const response = await fetch(phone_number_url, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(token_request_body)
});

const user_info = await response.json();

// 解析用户信息
if (user_info.resultCode === 0 || !user_info.resultCode) {
  const openId = user_info.openId;
  const unionId = user_info.unionId;
  const phoneNumber = user_info.phoneNumber;      // 完整手机号(含国家码)
  const purePhoneNumber = user_info.purePhoneNumber; // 不含国家码的手机号
  const phoneNumberValid = user_info.phoneNumberValid; // 0:需验证, 1:可直接使用
  
  // 数据库操作：
  // 1. 使用UnionID查询用户，匹配则返回用户信息
  // 2. 未匹配则使用手机号查询，查到则关联UnionID
  // 3. 均未匹配则创建新用户
  
  return {
    code: 200,
    message: 'Login successful',
    data: {
      openId,
      unionId,
      phoneNumber,
      purePhoneNumber,
      phoneNumberValid
    }
  };
} else {
  // 处理错误码
  return {
    code: user_info.resultCode,
    message: user_info.resultDesc,
    data: null
  };
}
```

### 步骤6：错误处理和降级

**客户端错误处理**：
```typescript
handleLoginError(error: BusinessError): void {
  this.controller.setEnabled(true); // 恢复按钮可点击
  
  switch (error.code) {
    case 1001502001: // 用户未登录华为账号
      this.showToast('华为账号未登录，请重试');
      break;
      
    case 1001502005: // 网络错误
      this.showAlertDialog({
        message: '网络未连接，请检查网络设置。',
        confirm: { value: '知道了', action: () => {} }
      });
      break;
      
    case 1005300001: // 未同意协议
      this.agreementDialog.open(); // 弹出协议弹框
      break;
      
    case 1001500003: // 不支持该scope
      this.showToast('该账号不支持一键登录');
      break;
      
    case 1001502012: // 用户取消授权
      // 无需处理
      break;
      
    default:
      this.showToast('服务或网络异常，请稍后重试');
  }
}
```

**服务端错误处理**：
```typescript
// 根据resultCode处理
switch (resultCode) {
  case 60010002: // 参数不合法
    return { code: 400, message: '参数错误' };
    
  case 60010012: // code参数不正确
    return { code: 401, message: 'Authorization Code无效' };
    
  case 60180003: // Client ID不一致
    return { code: 403, message: 'Client ID配置错误' };
    
  case 60180004: // code过期
    return { code: 401, message: 'Authorization Code已过期，请重新授权' };
    
  case 60180005: // code已使用
    return { code: 401, message: 'Authorization Code已使用，请重新授权' };
    
  case 60180008: // 用户无手机号
    return { code: 404, message: '华为账号未绑定手机号' };
    
  case 60180009: // 手机号获取受限
    return { code: 403, message: '服务仅支持中国境内用户' };
    
  default:
    return { code: 500, message: '系统错误' };
}
```

## 错误码说明

### 客户端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001500001 | 应用指纹证书校验失败 | 参考[account-faq-1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)解决 |
| 1001500002 | 重复请求 | 应用无需处理，自动重试 |
| 1001500003 | 不支持该scopes或permissions | 展示其他登录方式（海外账号或设备不支持） |
| 1001502001 | 用户未登录华为账号 | 展示其他登录方式 |
| 1001502002 | 应用未授权 | 检查权限配置 |
| 1001502003 | 输入参数值无效 | 检查参数格式 |
| 1001502005 | 网络错误 | 提示检查网络状态 |
| 1001502009 | 内部错误 | 展示其他登录方式 |
| 1001502012 | 用户取消授权 | 无需处理 |
| 1001502014 | 应用未申请scopes或permissions权限 | 参考[account-faq-2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2)解决 |
| 1005300001 | 用户未同意协议 | 弹出协议弹框 |
| 12300001 | 系统服务异常 | 展示其他登录方式 |

### 服务端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 60010002 | 参数不合法 | 检查请求参数格式 |
| 60010012 | code参数不正确 | code无效或被篡改，重新获取 |
| 60010013 | clientSecret参数不正确 | 检查Client Secret配置 |
| 60180003 | code中的client_id和入参不一致 | 检查Client ID配置一致性 |
| 60180004 | code过期 | 引导用户重新授权（5分钟有效期） |
| 60180005 | code已经被使用过 | 重新获取code（仅可使用一次） |
| 60180006 | code授权被取消 | 用户取消授权，重新获取 |
| 60180007 | code未授权一键登录权限 | 申请华为账号一键登录权限 |
| 60180008 | 用户无手机号 | 华为账号未绑定手机号，展示其他登录方式 |
| 60180009 | 手机号信息获取受限 | 仅支持中国境内用户和服务器 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "华为账号服务Kit",
    "@kit.RemoteCommunicationKit": "远场通信服务Kit",
    "@kit.NetworkKit": "网络服务Kit",
    "@kit.ArkTS": "ArkTS工具库",
    "@kit.PerformanceAnalysisKit": "性能分析Kit",
    "@kit.BasicServicesKit": "基础服务Kit"
  }
}
```

### 权限配置
```json
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_reason_network"
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_reason_internet"
      }
    ]
  }
}
```

### 常见编译问题

**问题1：属性混淆导致匿名手机号获取失败**
```
错误信息：response.data?.extraInfo?.quickLoginAnonymousPhone为undefined
```
**解决方法**：在obfuscation-rules.txt中添加白名单：
```
-enable-property-obfuscation
-keep-property-name
quickLoginAnonymousPhone
```

**问题2：应用指纹证书校验失败**
```
错误信息：errorCode: 1001500001
```
**解决方法**：
1. 在AGC配置应用签名证书指纹
2. 确保应用签名与配置一致
3. 参考[account-faq-1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)

**问题3：未申请权限错误**
```
错误信息：errorCode: 1001502014
```
**解决方法**：
1. 在AGC申请"华为账号一键登录"权限
2. 等待权限审批通过
3. 参考[account-faq-2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2)

**问题4：海外账号不支持**
```
错误信息：errorCode: 1001500003
```
**解决方法**：
- 该账号注册地为中国境外、香港、澳门或台湾
- 应用展示其他登录方式或华为账号登录按钮

## 常见问题与解决方法

### Q1：如何处理用户未同意协议的情况？
**原因**：用户必须同意《华为账号用户认证协议》才能完成登录
**解决方法**：
- 使用`setAgreementStatus`设置协议状态为NOT_ACCEPTED
- 用户勾选协议后设置为ACCEPTED
- 未同意时点击登录按钮返回错误码1005300001
- 弹出协议弹框引导用户同意

### Q2：匿名手机号为空怎么办？
**原因**：华为账号未绑定手机号、权限未申请或未生效、海外账号
**解决方法**：
- 检查权限申请状态
- 确认账号已绑定手机号
- 确认用户为中国境内用户
- 展示其他登录方式

### Q3：Authorization Code过期如何处理？
**原因**：code有效期5分钟，只能使用一次
**解决方法**：
- 引导用户重新点击一键登录按钮
- 获取新的Authorization Code
- 服务端立即使用code调用REST API

### Q4：如何实现用户非首次登录？
**原因**：用户已使用华为账号登录过应用
**解决方法**：
1. 获取Authorization Code
2. 服务端获取UnionID/OpenID
3. 查询数据库判断用户是否已关联
4. 已关联：展示已关联账号或静默登录
5. 未关联：继续一键登录流程创建新用户

### Q5：儿童账号登录如何处理？
**原因**：儿童账号需要家长验密
**解决方法**：
- Account Kit自动触发家长验密流程
- 家长验密完成后可获取用户信息
- TV设备和Car设备暂不支持儿童账号

### Q6：如何实现手机号验证时效性？
**原因**：确保返回的手机号经过验证
**解决方法**：
- 90天内有验证记录：直接返回手机号
- 90天内无验证记录：触发Account Kit短信验证流程
- 设置`verifyPhoneNumber`参数控制是否拉起验证页

### Q7：服务端部署位置有何限制？
**原因**：华为账号一键登录服务地域限制
**解决方法**：
- 服务端必须部署在中国境内（香港、澳门、台湾除外）
- 使用TLS 1.2及以上协议
- 确保网络可访问华为账号服务器

### Q8：如何获取用户风险等级？
**原因**：应用需要进行风控判断
**解决方法**：
- 在LoginPanelParams或LoginWithHuaweiIDButtonParams中设置`riskLevel: true`
- 需要申请获取风险等级权限
- 参考[account-get-risklevel-byquicklogin](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-get-risklevel-byquicklogin)

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "clientResult": {
    "anonymousPhone": "139******99",
    "authorizationCode": "CFxxxxxxxxxx",
    "state": "uuid-xxxx-xxxx"
  },
  "serverResult": {
    "openId": "AQAxrBzThFv*****lv9tV_4rMCc",
    "unionId": "AQAxrB1HNA*****n-IfWRSUVq2M7xU",
    "phoneNumber": "0086191******08",
    "purePhoneNumber": "191******08",
    "phoneNumberValid": 1,
    "phoneCountryCode": "0086"
  },
  "apiUsed": [
    "AuthorizationWithHuaweiIDRequest",
    "LoginWithHuaweiIDButton",
    "/oauth2/v6/quickLogin/getPhoneNumber"
  ],
  "userAction": "一键登录成功",
  "timestamp": "2026-07-04T10:30:00Z"
}
```

## 参考文档

- [API开发指南](references/account-phone-unionid-login.md)
- [ArkTS API参考](references/account-api-authentication.md)
- [ArkTS组件参考](references/account-api-component-manager.md)
- [REST API参考](references/account-api-get-user-info-quicklogin-by-code.md)

## 完整示例代码

- [ArkTS客户端示例](assets/quick-login-client.ets)
- [服务端示例(Java)](assets/quick-login-server.java)
- [服务端示例(Python)](assets/quick-login-server.py)
- [服务端示例(Go)](assets/quick-login-server.go)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [首次用户一键登录](tests/test_first_login.py)：测试新用户完整登录流程
- [已关联用户登录](tests/test_existing_user.py)：测试已关联用户静默登录
- [获取匿名手机号](tests/test_get_anonymous_phone.py)：测试匿名手机号获取

### 边界测试用例
- [Authorization Code过期](tests/test_code_expired.py)：测试code过期处理
- [Authorization Code重复使用](tests/test_code_reuse.py)：测试code重复使用处理
- [协议未勾选](tests/test_agreement_not_accepted.py)：测试协议状态管理

### 异常测试用例
- [华为账号未登录](tests/test_huawei_id_not_login.py)：测试账号未登录处理
- [网络异常](tests/test_network_error.py)：测试网络错误降级
- [海外账号登录](tests/test_overseas_account.py)：测试地域限制处理
- [未绑定手机号](tests/test_no_phone_number.py)：测试账号未绑定手机号处理