# 获取实名年龄段

#### 场景介绍
当应用需要获取用户实名年龄段信息时，可使用Account Kit的年龄段授权能力。用户授权后，应用可快速获取实名年龄段信息。

#### 约束与限制
获取用户实名年龄段能力支持Phone、Tablet、PC/2in1设备。并且从5.1.0(18)版本开始，新增支持Wearable设备；从5.1.1(19)版本开始，新增支持TV设备；从26.0.0版本开始，新增支持Car设备。

#### 业务流程

流程说明：
1. 应用通过传对应scope和permission调用授权API，如果已授权则直接返回临时登录凭证Authorization Code；如果未授权则拉起授权页，在用户确认授权后，返回Authorization Code。
2. 应用将Authorization Code传给应用服务端，使用Client ID、Client Secret、Authorization Code从华为服务器中获取Access Token，再使用Access Token请求获取用户的实名年龄段信息。

#### 接口说明
获取年龄段关键接口如下表所示，具体API说明详见 [API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) 。

| 接口名 | 描述 |
| --- | --- |
| [createAuthorizationWithHuaweiIDRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)():[AuthorizationWithHuaweiIDRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) | 获取授权请求对象接口，通过[AuthorizationWithHuaweiIDRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)传入返回获取用户实名年龄段的scope：realNameAgeRange及返回Authorization Code的permission：serviceauthcode，即可获取到Authorization Code。 |
| [constructor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)(context?:[common.Context](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-common)) | 创建授权请求Controller。 |
| [executeRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)(request:[AuthenticationRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)): Promise<[AuthenticationResponse](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)> | 通过Promise方式执行授权操作。 |

上述接口需在页面或自定义组件生命周期内调用。

#### 开发前提
1、在进行代码开发前，请先确认已完成 [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-config-permissions) 工作。
- 若未配置签名和指纹，将报错 [1001500001 应用指纹证书校验失败](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-1) 。
- 若未完成"获取您的年龄段"权限申请，将报错 [1001502014 应用未申请scopes或permissions权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-2) 。

2、设备需要登录华为账号，若未登录则拉起登录页面。

#### 开发步骤

#### 客户端开发

1. 导入 [authentication](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) 模块及相关公共模块。
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
```

2. 创建授权请求并设置参数。
```typescript
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
authRequest.scopes = ['realNameAgeRange'];
authRequest.permissions = ['serviceauthcode'];
authRequest.forceAuthorization = true;
authRequest.state = util.generateRandomUUID();
```

3. 调用 [AuthenticationController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) 对象的 [executeRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication) 方法执行授权请求，并处理授权结果，从授权结果中解析出Authorization Code，之后将Authorization Code传给应用服务端处理。
```typescript
try {
  const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
  controller.executeRequest(authRequest).then((data) => {
    const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
    const state = authorizationWithHuaweiIDResponse.state;
    if (state && authRequest.state !== state) {
      hilog.error(0x0000, 'testTag', `Failed to authorize. The state is different, response state: ${state}`);
      return;
    }
    hilog.info(0x0000, 'testTag', 'Succeeded in authentication.');
    const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse?.data;
    const authorizationCode = authorizationWithHuaweiIDCredential?.authorizationCode;
  }).catch((err: BusinessError) => {
    dealAllError(err);
  });
} catch (error) {
  dealAllError(error);
}
```

```typescript
function dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to obtain userInfo. Code: ${error.code}, message: ${error.message}`);
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
  } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
  } else {
  }
}

export enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002
}
```

#### 服务端开发

1. 应用服务端使用Client ID、Client Secret、Authorization Code调用 [获取用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token) 向华为账号服务器请求获取Access Token、Refresh Token。

2. 使用Access Token调用 [获取实名年龄段接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-realname-age-range-flag) 获取用户实名年龄段。

**Access Token过期处理**
由于Access Token的有效期仅为60分钟，当Access Token失效或者即将失效时（可通过 [REST API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-user-info-get-nickname-and-avatar) 判断），可以使用Refresh Token（有效期180天）通过 [刷新用户级凭证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token) 向华为账号服务器请求获取新的Access Token。

**Refresh Token过期处理**
由于Refresh Token的有效期为180天，当Refresh Token失效后（可通过 [REST API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token) 判断），应用服务端需要通知客户端，重新调用授权接口，请求用户重新授权。