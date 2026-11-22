---
name: hmos-account-kit-get-avatar-nickname
description: 获取华为账号用户头像和昵称+通过Account Kit授权接口实现+支持Phone/Tablet/PC/2in1/Wearable/TV/Car设备+适用于用户信息填写、个人资料设置场景
---

# 获取华为账号用户头像和昵称技能

## 功能描述

本技能用于获取华为账号用户的头像和昵称信息。通过Account Kit提供的头像昵称授权能力,用户允许应用获取头像昵称后,可快速完成个人信息填写。

**核心功能**:
- 获取用户头像URL和昵称
- 支持获取Authorization Code用于服务端开发
- 自动处理用户授权流程
- 支持多种设备类型

**适用范围**:
- Phone、Tablet、PC/2in1设备(基础支持)
- Wearable设备(从5.1.0(18)版本开始支持)
- TV设备(从5.1.1(19)版本开始支持)
- Car设备(从6.1.0(23)版本开始支持)

## 使用场景

### 触发词
- "获取用户头像"
- "获取用户昵称"
- "获取华为账号头像昵称"
- "Account Kit头像昵称授权"
- "用户信息填写"
- "个人资料设置"

### 能做
- 获取华为账号用户的头像URL链接
- 获取华为账号用户的昵称
- 获取Authorization Code用于服务端获取用户信息
- 处理用户授权流程(已授权直接返回,未授权拉起授权页面)
- 在页面或自定义组件生命周期内调用授权接口
- 处理各种授权异常和错误情况

### 绝不做
- 不在非页面组件生命周期外调用授权接口
- 不直接使用高危函数(如eval、exec等)
- 不获取超出授权范围的用户信息
- 不处理儿童账号的头像昵称获取(儿童账号不支持)
- 不在半模态、弹出框、子窗口等非全页面组件中使用UIExtensionContext调用

### 补充
- 头像URL有效期较短,用户更新头像后原链接立即失效,建议先将头像下载保存后再使用
- 未设置昵称默认返回华为账号绑定的匿名手机号/邮箱
- 需要完成开发准备:配置签名和指纹、配置Client ID
- 若未正确配置公钥指纹将报错1001500001
- 此场景无需申请账号权限

## 调用规范和规则

### 输入约束
- Context类型:必须传入有效的Context上下文对象(UIAbilityContext或UIExtensionContext)
- Scope参数:必须传入['profile']获取头像昵称
- Permission参数:可选传入['serviceauthcode']获取Authorization Code
- State参数:必须使用util.generateRandomUUID()生成,长度1-255字符
- 调用位置:必须在页面或自定义组件实例中使用

### 执行约束
- 最大耗时:授权流程取决于用户操作,无硬性限制
- 最大迭代次数:单次调用,不涉及迭代
- API调用频次:避免重复请求(错误码1001500002会拒绝重复请求)
- 必须实现点击控制防止连续点击发起相同请求

### 内容约束
- 禁止生成:超出profile scope的用户信息获取代码
- 禁止使用高危函数:eval、exec、os.system等
- 禁止操作:不混淆代码中的state、nonce等关键字段
- 禁止跳过state一致性校验(防止跨站攻击)

### 降级约束
- 网络失败:提示用户检查网络状态并重试(错误码1001502005)
- 用户未登录:提示用户登录华为账号并重试(错误码1001502001)
- 用户取消授权:记录取消状态,不强制再次请求(错误码1001502012)
- 系统服务异常:提示用户稍后重试(错误码12300001)
- 指纹校验失败:检查签名和指纹配置,参考配置指南(错误码1001500001)

## 调用流程和步骤

### 步骤1:准备阶段(导入模块和参数准备)

**前置校验**:
1. 验证已在开发准备中完成配置签名和指纹
2. 验证已完成配置Client ID
3. 验证当前在页面或自定义组件实例中
4. 验证已获取有效的Context上下文对象

**导入模块**:
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2:创建授权请求并设置参数

**创建请求对象**:
```typescript
// 创建授权请求,并设置参数
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
// 获取头像昵称需要传如下scope
authRequest.scopes = ['profile'];
// 若开发者需要进行服务端开发以获取头像昵称,则需传如下permission获取authorizationCode
authRequest.permissions = ['serviceauthcode'];
// 用户是否需要登录授权,该值为true且用户未登录或未授权时,会拉起用户登录或授权页面
authRequest.forceAuthorization = true;
// 建议使用generateRandomUUID生成state,可用于一致性比对,防止跨站攻击
authRequest.state = util.generateRandomUUID();
```

**参数说明**:
- scopes: ['profile'] - 必传,用于获取头像昵称
- permissions: ['serviceauthcode'] - 可选,用于获取Authorization Code
- forceAuthorization: true - 拉起授权页面
- state: 防止跨站攻击的随机字符串

### 步骤3:调用授权接口并处理结果

**执行授权请求**:
```typescript
// 执行授权请求
try {
  // 此示例为代码片段,实际需在自定义组件实例中使用,并传入有效的Context上下文对象
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  controller.executeRequest(authRequest).then((data) => {
    const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
    const state = authorizationWithHuaweiIDResponse?.state;
    if (state && authRequest.state !== state) {
      hilog.error(0x0000, 'testTag', `Failed to authorize. The state is different, response state: ${state}`);
      return;
    }
    hilog.info(0x0000, 'testTag', 'Succeeded in authentication.');
    const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
    const avatarUri = authorizationWithHuaweiIDCredential?.avatarUri;
    const nickName = authorizationWithHuaweiIDCredential?.nickName;
    // 开发者处理avatarUri, nickName
    const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
    // 涉及服务端开发以获取头像昵称场景,开发者处理authorizationCode
    // ...
  }).catch((err: BusinessError) => {
    // ...
    dealAllError(err);
  });
} catch (error) {
  dealAllError(error);
}
```

**结果解析**:
- avatarUri: 用户头像URL链接,有效期较短,建议下载保存
- nickName: 用户昵称,长度2-20个字符
- authorizationCode: Authorization Code,用于服务端获取Access Token(可选)

### 步骤4:错误处理

**完整错误处理代码**:
```typescript
// 错误处理
function dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to obtain userInfo. Code: ${error.code}, message: ${error.message}`);
  // 在应用获取头像昵称场景下,涉及UI交互时,建议按照如下错误码指导提示用户
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
    // 用户未登录华为账号,请登录华为账号并重试
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
    // 网络错误,请检查当前网络状态并重试
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
    // 用户取消授权
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
    // 系统服务异常,请稍后重试
  } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
    // 重复请求,应用无需处理
  } else {
    // 获取用户信息失败,请稍后重试
  }
}
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
```

### 步骤5:降级处理(可选)

**服务端开发场景**:
如果需要进行服务端开发获取头像昵称:
1. 应用服务端使用Client ID、Client Secret、Authorization Code调用获取用户级凭证接口向华为账号服务器请求获取Access Token
2. 使用Access Token调用获取用户信息接口获取用户信息,从用户信息中获取用户头像昵称

**Access Token过期处理**:
- Access Token有效期仅60分钟
- 可使用Refresh Token(有效期180天)通过刷新用户级凭证接口获取新的Access Token

**详细参考**:
- [获取用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [获取用户信息接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-user-info-get-nickname-and-avatar)
- [刷新用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token)

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 提示用户登录华为账号并重试 |
| 1001502005 | 网络异常 | 提示用户检查网络状态并重试 |
| 1001502012 | 用户取消授权 | 记录取消状态,不强制再次请求 |
| 12300001 | 系统服务异常 | 提示用户稍后重试 |
| 1001500002 | 重复请求被拒绝 | 实现点击控制防止连续点击,应用无需处理此错误 |
| 1001500001 | 应用指纹证书校验失败 | 检查签名和指纹配置,参考[配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints) |
| 1001502003 | 输入参数值无效 | 检查scopes和permissions参数是否正确 |
| 1001500003 | 不支持该scopes或permissions | 检查是否在元服务场景下未设置supportAtomicService=true |
| 401 | 参数检查失败 | 检查Context参数是否正确传入 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AccountKit": "HarmonyOS SDK",
    "@kit.PerformanceAnalysisKit": "HarmonyOS SDK",
    "@kit.ArkTS": "HarmonyOS SDK",
    "@kit.BasicServicesKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS SDK版本: 4.0.0(10)及以上
- 开发工具: DevEco Studio
- 模型约束: Stage模型
- 设备支持: Phone/Tablet/PC/2in1/Wearable/TV/Car

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.AccountKit'
```
**解决方法**: 确保已安装HarmonyOS SDK并正确配置项目依赖

**问题2:Context参数类型错误**
```
Error: Parameter type mismatch
```
**解决方法**: 使用`this.getUIContext().getHostContext()`获取正确的Context对象

**问题3:代码混淆导致字段丢失**
```
Error: Property 'state' not found
```
**解决方法**: 配置混淆白名单防止state、nonce等关键字段被混淆

## 常见问题与解决方法

### Q1:用户头像URL失效怎么办?
**原因**: 头像URL有效期较短,用户更新头像后原链接立即失效
**解决方法**:
- 建议先将头像下载保存到本地后再使用
- 避免因用户头像链接失效而影响业务流程

### Q2:获取不到昵称怎么办?
**原因**: 用户未设置昵称,默认返回华为账号绑定的匿名手机号/邮箱
**解决方法**:
- 正常处理返回的匿名手机号/邮箱作为昵称
- 提示用户设置昵称后再获取

### Q3:报错1001500001应用指纹证书校验失败?
**原因**: 未正确配置公钥指纹
**解决方法**:
- 参考[配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)完成配置
- 参考[1001500001应用指纹证书校验失败的可能原因和解决办法](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1)

### Q4:元服务场景下获取头像昵称失败?
**原因**: 元服务场景下需要设置supportAtomicService=true
**解决方法**:
- 在AuthorizationWithHuaweiIDRequest中设置supportAtomicService=true
- 元服务从5.1.1(19)版本开始支持profile scope

### Q5:头像昵称获取成功但显示异常?
**原因**: 可能是儿童账号或海外账号
**解决方法**:
- 儿童账号不支持获取头像昵称
- 检查账号类型和地区设置

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "avatarUri": "https://xxx/xxx",
  "nickName": "用户昵称",
  "authorizationCode": "Authorization Code(可选)",
  "openID": "用户OpenID",
  "unionID": "用户UnionID",
  "apiUsed": [
    "createAuthorizationWithHuaweiIDRequest",
    "AuthenticationController.constructor",
    "executeRequest"
  ]
}
```

## 参考文档

- [API开发指南-获取头像昵称](references/account-get-avatar-nickname.md)
- [API参考-account-api-authentication](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)
- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id)
- [选择头像Button](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenario-fusion-button-chooseavatar)
- [获取用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token)
- [获取用户信息接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-user-info-get-nickname-and-avatar)
- [刷新用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token)

## 完整示例代码

- [ArkTS完整示例](assets/example_get_avatar_nickname.ets)
- [错误处理示例](assets/error_handling.ets)

## 测试用例

### 正向测试用例
- [正常获取头像昵称](tests/test_positive.ts): 用户已授权场景下获取头像昵称
- [首次授权获取头像昵称](tests/test_first_auth.ts): 用户首次授权场景测试

### 边界测试用例
- [用户未设置昵称](tests/test_boundary.ts): 测试返回匿名手机号/邮箱场景
- [头像URL有效期测试](tests/test_avatar_url_expiry.ts): 测试头像URL失效处理

### 异常测试用例
- [用户未登录测试](tests/test_user_not_login.ts): 测试错误码1001502001处理
- [网络异常测试](tests/test_network_error.ts): 测试错误码1001502005处理
- [用户取消授权测试](tests/test_user_cancel.ts): 测试错误码1001502012处理
- [指纹校验失败测试](tests/test_fingerprint_error.ts): 测试错误码1001500001处理