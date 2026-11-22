---
name: hmos-account-kit-quick-login
description: 实现华为账号一键登录功能,获取手机号和UnionID/OpenID,支持Phone/Tablet/PC/2in1/TV/Car设备,仅限中国境内用户和企业开发者使用,适用于应用登录注册场景
---

# 华为账号一键登录技能

## 功能描述

华为账号一键登录是基于OAuth 2.0和OpenID Connect协议构建的授权登录系统,应用可以通过华为账号一键登录能力快捷获取华为账号用户的身份标识(UnionID/OpenID)和手机号,快速建立应用内用户体系。

**核心能力**:
- 获取华为账号用户匿名手机号(预取号阶段)
- 展示一键登录页面,包含LoginWithHuaweiIDButton组件
- 获取Authorization Code凭证
- 通过Authorization Code获取完整手机号、UnionID、OpenID

**技术特点**:
- 基于OAuth 2.0协议标准和OpenID Connect协议标准
- 利用系统账号安全性和便利性,简化登录步骤
- 提供系统验证过的手机号,关联应用已有用户
- 支持儿童账号一键登录(触发家长验密流程)
- 手机号验证机制:90天内验证通过记录可直接返回,否则触发短信验证

## 使用场景

### 触发词
- "华为账号一键登录"
- "获取手机号登录"
- "一键登录获取UnionID"
- "一键登录获取OpenID"
- "Account Kit一键登录"
- "快速登录"

### 能做
- 实现华为账号一键登录功能,同时获取手机号和UnionID/OpenID
- 获取华为账号用户的匿名手机号用于登录页面展示
- 通过Authorization Code获取用户完整手机号和身份标识
- 支持儿童账号一键登录场景(家长验密流程)
- 支持用户首次登录和非首次登录场景
- 支持获取华为账号风险等级(可选)
- 支持一键登录增强身份验证功能

### 绝不做
- 不支持个人开发者使用(仅支持企业开发者)
- 不支持中国境外用户(香港、澳门、台湾除外)
- 不支持Wearable设备获取匿名手机号
- 不支持海外账号获取匿名手机号
- 不替代静默登录或华为账号登录按钮登录(个人开发者应使用其他登录方式)
- 不直接调用REST API获取手机号(需通过客户端Authorization Code流程)

### 补充
- 仅支持企业开发者使用,个人开发者请使用华为账号登录或静默登录
- 华为账号一键登录服务仅对中国境内(香港、澳门、台湾除外)用户提供
- 应用服务端调用REST API获取手机号时,服务器必须部署在中国境内
- 用户需同意《华为账号用户认证协议》
- 应用需满足《常见类型移动互联网应用程序必要个人信息范围规定》
- 从5.1.1(19)版本开始支持TV设备,从26.0.0版本开始支持Car设备
- 儿童账号一键登录会触发Account Kit默认提供的家长验密流程
- TV设备、Car设备暂不支持儿童账号

## 调用规范和规则

### 输入约束
- **设备类型**: Phone、Tablet、PC/2in1、TV(从5.1.1(19)版本)、Car(从26.0.0版本)
- **API版本**: 起始版本4.0.0(10),元服务支持从4.1.0(11)版本开始
- **账号类型**: 仅支持企业开发者账号
- **地域限制**: 仅限中国境内(香港、澳门、台湾除外)用户
- **权限要求**: 必须申请"华为账号一键登录"权限(quickLoginAnonymousPhone scope)
- **签名要求**: 必须配置应用签名和指纹证书

### 执行约束
- **预取号超时**: 建议设置5秒超时以保证用户体验
- **Authorization Code有效期**: 5分钟,只能使用1次
- **forceAuthorization参数**: 一键登录场景必须设置为false
- **scope参数**: 必须传入'quickLoginAnonymousPhone',且只能与'openid'同时使用
- **协议状态**: 用户未同意协议前必须设置为NOT_ACCEPTED,同意后设置为ACCEPTED
- **代码混淆**: 需将quickLoginAnonymousPhone属性加入混淆白名单

### 内容约束
- **禁止伪造Authorization Code**: 必须通过LoginWithHuaweiIDButton组件真实获取
- **禁止直接使用手机号**: 必须通过服务端REST API验证后使用
- **禁止跳过协议同意**: 用户必须同意《华为账号用户认证协议》
- **禁止自定义验证页面**: Account Kit提供的验证页暂不可自定义
- **禁止使用高危函数**: 示例代码禁止使用eval、exec等高危函数

### 降级约束
- **华为账号未登录**: 展示其他登录方式(错误码1001502001)
- **网络错误**: 提示用户检查网络状态并重试(错误码1001502005)
- **匿名手机号为空**: 展示其他登录方式(华为账号未绑定手机号或权限未生效)
- **不支持scope**: 应用展示其他登录方式(错误码1001500003,海外账号或设备不支持)
- **应用未申请权限**: 参考1001502014错误码解决方法
- **应用指纹证书校验失败**: 参考1001500001错误码解决方法
- **内部错误**: 应用展示其他登录方式(错误码1001502009)
- **系统服务异常**: 应用展示其他登录方式(错误码12300001)
- **用户取消授权**: 无需特别处理(错误码1001502012)

## 调用流程和步骤

### 步骤1: 开发准备(前置校验)

**前提条件检查**:
1. 完成开发准备工作,申请"华为账号一键登录"权限
2. 配置应用签名和指纹证书
3. 确认应用为企业开发者账号
4. 如开启代码混淆,配置混淆白名单

**混淆白名单配置**(obfuscation-rules.txt):
```typescript
# 开发者开启属性混淆需要配置quickLoginAnonymousPhone属性白名单防止其被混淆
-enable-property-obfuscation
-keep-property-name
quickLoginAnonymousPhone
```

### 步骤2: 导入模块

导入Account Kit的authentication模块及相关公共模块:

```typescript
import { authentication } from '@kit.AccountKit';
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';
```

### 步骤3: 获取匿名手机号

调用AuthorizationWithHuaweiIDRequest请求获取华为账号用户的匿名手机号:

**关键参数设置**:
- `scopes`: ['quickLoginAnonymousPhone'] (必须申请该权限)
- `state`: 使用util.generateRandomUUID()生成,用于一致性比对防止跨站攻击
- `forceAuthorization`: false (一键登录场景必须设置为false)

**示例代码**:
```typescript
async getQuickLoginAnonymousPhone(): Promise<string> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['quickLoginAnonymousPhone'];
    authRequest.state = util.generateRandomUUID();
    authRequest.forceAuthorization = false;
    
    const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
    let quickLoginAnonymousPhone: string = '';
    
    try {
        const response = await controller.executeRequest(authRequest) as authentication.AuthorizationWithHuaweiIDResponse;
        quickLoginAnonymousPhone = response.data?.extraInfo?.quickLoginAnonymousPhone as string;
        
        if (quickLoginAnonymousPhone) {
            hilog.info(0x0000, 'testTag', 'Succeeded in getting anonymous phone.');
            return quickLoginAnonymousPhone;
        }
        
        hilog.info(0x0000, 'testTag', 'AnonymousPhone is empty.');
        return quickLoginAnonymousPhone;
    } catch (error) {
        const err = error as BusinessError;
        hilog.error(0x0000, 'testTag', 
            `Failed to get quickLoginAnonymousPhone, errorCode is ${err.code}, errorMessage is ${err.message}`);
        this.dealAllError(err);
        return quickLoginAnonymousPhone;
    }
}
```

**错误码处理**:
| 错误码 | 错误描述 | 处理建议 |
|-------|---------|---------|
| 1001502001 | 用户未登录华为账号 | 应用展示其他登录方式 |
| 1001502005 | 网络错误 | 提示用户检查当前网络状态后重试 |
| 1001502009 | 内部错误 | 应用展示其他登录方式 |
| 1001502014 | 应用未申请scopes或permissions权限 | 参考[account-faq-2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2)解决 |
| 1001500001 | 应用指纹证书校验失败 | 参考[account-faq-1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)解决 |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1001500003 | 不支持该scopes或permissions | 应用展示其他登录方式(海外账号或设备不支持) |
| 12300001 | 系统服务异常 | 应用展示其他登录方式 |

### 步骤4: 展示一键登录页面

创建QuickLoginButtonComponent组件,展示华为账号一键登录按钮:

**组件结构**:
```typescript
@Component
struct QuickLoginButtonComponent {
    @State quickLoginAnonymousPhone: string = '';
    @State isSelected: boolean = false;
    
    privacyText: loginComponentManager.PrivacyText[] = [
        { text: '已阅读并同意', type: loginComponentManager.TextType.PLAIN_TEXT },
        { text: '《用户服务协议》', tag: '用户服务协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '《隐私协议》', tag: '隐私协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '和', type: loginComponentManager.TextType.PLAIN_TEXT },
        { text: '《华为账号用户认证协议》', tag: '华为账号用户认证协议', type: loginComponentManager.TextType.RICH_TEXT },
        { text: '。', type: loginComponentManager.TextType.PLAIN_TEXT }
    ];
    
    controller: loginComponentManager.LoginWithHuaweiIDButtonController =
        new loginComponentManager.LoginWithHuaweiIDButtonController()
            .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
            .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
                this.handleLoginWithHuaweiIDButton(error, response);
            })
            .onClickEvent((error: BusinessError, clickEvent: loginComponentManager.ClickEvent) => {
                if (error) {
                    hilog.error(0x0000, 'testTag', `onClickEvent error. errCode is ${error.code}`);
                    return;
                }
                this.controller.setEnabled(false);
            });
    
    build() {
        Column() {
            Text(this.quickLoginAnonymousPhone)
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
            
            LoginWithHuaweiIDButton({
                params: {
                    style: loginComponentManager.Style.BUTTON_RED,
                    loginType: loginComponentManager.LoginType.QUICK_LOGIN,
                    borderRadius: 24,
                    supportDarkMode: true,
                    extraStyle: {
                        buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({ show: true })
                    }
                },
                controller: this.controller
            })
        }
    }
}
```

### 步骤5: 处理一键登录结果

用户同意协议并点击一键登录按钮后,获取Authorization Code:

```typescript
handleLoginWithHuaweiIDButton(error: BusinessError, response: loginComponentManager.HuaweiIDCredential) {
    if (error) {
        hilog.error(0x0000, 'testTag', 
            `Failed to login. errCode is ${error.code}, errMessage is ${error.message}`);
        
        if (error.code === 1001502005) {
            this.showToast('网络未连接,请检查网络设置');
        } else if (error.code === 1005300001) {
            this.agreementDialog.open();
        } else if (error.code === 1001502001) {
            this.showToast('华为账号未登录,请重试');
        }
        
        this.controller.setEnabled(true);
        return;
    }
    
    if (this.isSelected && response) {
        hilog.info(0x0000, 'testTag', 'Succeeded in clicking LoginWithHuaweiIDButton.');
        const authCode = response.authorizationCode;
        const unionID = response.unionID;
        const openID = response.openID;
        
        this.sendAuthorizationCodeToServer(authCode);
    } else {
        this.agreementDialog.open();
    }
    
    this.controller.setEnabled(true);
}
```

### 步骤6: 服务端获取完整手机号

应用服务端通过Authorization Code调用REST API获取用户完整手机号和UnionID/OpenID:

**接口URL**: `https://account-api.cloud.huawei.com/oauth2/v6/quickLogin/getPhoneNumber`

**请求参数**:
```json
{
    "code": "<Authorization Code>",
    "clientId": "<Client ID>",
    "clientSecret": "<Client Secret>"
}
```

**响应参数**:
```json
{
    "openId": "AQAxrBzThFv*****lv9tV_4rMCc",
    "unionId": "AQAxrB1HNA*****n-IfWRSUVq2M7xU",
    "phoneNumber": "0086191******08",
    "phoneNumberValid": 1,
    "purePhoneNumber": "191******08",
    "phoneCountryCode": "0086"
}
```

**phoneNumberValid说明**:
- 0: 过去90天内无法证明手机号可触达用户,需要验证
- 1: 过去90天内手机号被证明可触达用户,可直接使用

**服务端示例代码**(Java):
```java
public class GetQuickLoginMobilePhoneByCodeDemo {
    public static void main(String[] args) throws IOException {
        String url = "https://account-api.cloud.huawei.com/oauth2/v6/quickLogin/getPhoneNumber";
        String authorizationCode = "<Authorization Code>";
        String clientId = "<Client ID>";
        String clientSecret = "<Client Secret>";
        
        JSONObject result = getQuickLoginMobile(url, authorizationCode, clientId, clientSecret);
        
        String openId = result.getString("openId");
        String unionId = result.getString("unionId");
        String phoneNumber = result.getString("phoneNumber");
        Integer phoneNumberValid = result.getInteger("phoneNumberValid");
    }
    
    private static JSONObject getQuickLoginMobile(String url, String authorizationCode, 
            String clientId, String clientSecret) throws IOException {
        HttpPost httpPost = new HttpPost(url);
        Map<String, Object> reqBody = new HashMap<>();
        reqBody.put("code", authorizationCode);
        reqBody.put("clientId", clientId);
        reqBody.put("clientSecret", clientSecret);
        httpPost.setHeader("Content-Type", "application/json");
        httpPost.setEntity(CallUtils.wrapJsonEntity(reqBody));
        return CallUtils.toJsonObject(CallUtils.remoteCallAccountApi(httpPost));
    }
}
```

### 步骤7: 完成用户登录

应用通过关联用户手机号和UnionID/OpenID完成用户登录:

```typescript
async completeUserLogin(phoneNumber: string, unionID: string, openID: string): Promise<void> {
    try {
        const userAccount = await this.userDatabase.findAccountByUnionID(unionID);
        
        if (userAccount) {
            await this.sessionManager.createSession(userAccount.id);
            hilog.info(0x0000, 'testTag', 'User login succeeded.');
        } else {
            const newUser = await this.userDatabase.createAccount({
                phone: phoneNumber,
                unionID: unionID,
                openID: openID
            });
            await this.sessionManager.createSession(newUser.id);
            hilog.info(0x0000, 'testTag', 'User registration succeeded.');
        }
    } catch (error) {
        hilog.error(0x0000, 'testTag', `Failed to complete login: ${error.message}`);
    }
}
```

## 错误码说明

### 客户端错误码(ArkTS)

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 展示其他登录方式 |
| 1001502005 | 网络错误 | 提示用户检查网络状态并重试 |
| 1001502009 | 内部错误 | 展示其他登录方式 |
| 1001502014 | 应用未申请scopes或permissions权限 | 参考[account-faq-2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2) |
| 1001500001 | 应用指纹证书校验失败 | 参考[account-faq-1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1) |
| 1001500002 | 重复请求 | 应用无需处理 |
| 1001500003 | 不支持该scopes或permissions | 展示其他登录方式(海外账号/设备不支持) |
| 1001502012 | 用户取消授权 | 无需特别处理 |
| 12300001 | 系统服务异常 | 展示其他登录方式 |
| 1005300001 | 用户未同意协议 | 弹出协议弹框 |

### 服务端错误码(REST API)

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 60010002 | 参数不合法 | 检查Request Body参数 |
| 60010012 | code参数不正确 | 检查code是否被篡改 |
| 60010013 | clientSecret参数不正确 | 检查Client Secret参数 |
| 60180003 | code中的client_id和入参不一致 | 检查clientId是否一致 |
| 60180004 | code过期 | 引导用户重新授权获取新code |
| 60180005 | code已使用过 | 重新获取code |
| 60180006 | code授权被取消 | 重新获取code |
| 60180007 | code未授权华为账号一键登录权限 | 完成权限申请 |
| 60180008 | 用户无手机号 | 展示其他登录方式 |
| 60180009 | 手机号信息获取受限 | 确认服务器部署在中国境内 |
| 60010001 | 系统内部错误 | 稍后重试或在线提单 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "HarmonyOS SDK",
    "@kit.ArkTS": "HarmonyOS SDK",
    "@kit.PerformanceAnalysisKit": "HarmonyOS SDK",
    "@kit.BasicServicesKit": "HarmonyOS SDK",
    "@kit.NetworkKit": "HarmonyOS SDK",
    "@kit.ArkWeb": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS SDK: 最低版本4.0.0(10)
- 设备支持: Phone、Tablet、PC/2in1、TV(从5.1.1(19))、Car(从26.0.0)
- 开发者账号类型: 企业开发者
- 服务器部署地域: 中国境内(香港、澳门、台湾除外)

### 常见编译问题

**问题1: quickLoginAnonymousPhone属性被混淆**
```
错误信息: 无法获取到匿名手机号
```
**解决方法**: 在obfuscation-rules.txt中添加混淆白名单配置

**问题2: 应用指纹证书校验失败**
```
错误码: 1001500001
```
**解决方法**: 参考[account-faq-1](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)配置签名和指纹

**问题3: 应用未申请权限**
```
错误码: 1001502014
```
**解决方法**: 完成华为账号一键登录权限申请

## 常见问题与解决方法

### Q1: 个人开发者能否使用华为账号一键登录?
**原因**: 华为账号一键登录仅支持企业开发者使用
**解决方法**:
- 个人开发者使用华为账号登录按钮登录
- 个人开发者使用静默登录

### Q2: 如何处理海外账号一键登录?
**原因**: 华为账号一键登录仅对中国境内用户提供
**解决方法**:
- 检测到海外账号时展示其他登录方式
- 错误码1001500003表示不支持该scope

### Q3: 如何验证手机号有效性?
**原因**: phoneNumberValid字段返回0表示需要验证
**解决方法**:
- LoginPanelParams.verifyPhoneNumber设置为true(默认),华为代为验证
- 设置为false时,根据phoneNumberValid值自行验证

### Q4: 如何支持儿童账号一键登录?
**原因**: 儿童账号会触发家长验密流程
**解决方法**:
- Account Kit自动提供家长验密页面(暂不可自定义)
- 家长验密完成后可获取身份标识和手机号
- TV设备、Car设备暂不支持儿童账号

### Q5: Authorization Code过期如何处理?
**原因**: Code有效期5分钟且只能使用一次
**解决方法**:
- 引导用户重新点击一键登录按钮获取新code
- 服务端收到60180004或60180005错误码时重新获取

### Q6: 用户未同意协议如何处理?
**原因**: 必须同意《华为账号用户认证协议》
**解决方法**:
- 初始设置AgreementStatus为NOT_ACCEPTED
- 用户勾选协议后设置为ACCEPTED
- 点击按钮时弹出协议弹框引导用户同意

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "anonymousPhone": "139******99",
  "authorizationCode": "CFxxxxxxxxxx",
  "unionID": "AQAxrB1HNA*****n-IfWRSUVq2M7xU",
  "openID": "AQAxrBzThFv*****lv9tV_4rMCc",
  "phoneNumber": "0086191******08",
  "phoneNumberValid": 1,
  "purePhoneNumber": "191******08",
  "phoneCountryCode": "0086",
  "apiUsed": [
    "createAuthorizationWithHuaweiIDRequest",
    "executeRequest",
    "LoginWithHuaweiIDButton",
    "onClickLoginWithHuaweiIDButton",
    "setAgreementStatus",
    "/oauth2/v6/quickLogin/getPhoneNumber"
  ]
}
```

## 参考文档

- [华为账号一键登录开发指南](references/account-phone-unionid-login.md)
- [authentication API参考](references/account-api-authentication.md)
- [LoginWithHuaweiIDButton组件参考](references/account-api-huawei-id-button.md)
- [loginComponentManager组件管理](references/account-api-component-manager.md)
- [一键登录REST API参考](references/account-api-get-user-info-quicklogin-by-code.md)

## 完整示例代码

- [ArkTS一键登录示例](assets/quick-login-example.ets)
- [Java服务端示例](assets/server-get-phone-demo.java)
- [协议页面示例](assets/web-page-example.ets)
- [错误处理示例](assets/error-handler-example.ets)

## 测试用例

### 正向测试用例
- [用户首次登录测试](tests/test_first_login.py): 测试用户首次使用一键登录获取手机号和UnionID/OpenID
- [用户非首次登录测试](tests/test_non_first_login.py): 测试已关联用户使用一键登录
- [儿童账号登录测试](tests/test_child_account_login.py): 测试儿童账号家长验密流程

### 边界测试用例
- [90天验证边界测试](tests/test_phone_valid_boundary.py): 测试phoneNumberValid值为0和1的处理
- [Authorization Code有效期测试](tests/test_code_expiry.py): 测试Code过期和重复使用场景
- [设备支持边界测试](tests/test_device_support.py): 测试TV和Car设备支持情况

### 异常测试用例
- [华为账号未登录测试](tests/test_account_not_login.py): 测试用户未登录华为账号时的降级处理
- [网络异常测试](tests/test_network_error.py): 测试网络错误时的提示和重试
- [海外账号测试](tests/test_overseas_account.py): 测试海外账号不支持一键登录的处理
- [权限未申请测试](tests/test_permission_not_applied.py): 测试应用未申请权限时的错误处理
- [用户取消授权测试](tests/test_user_cancel.py): 测试用户取消授权时的处理