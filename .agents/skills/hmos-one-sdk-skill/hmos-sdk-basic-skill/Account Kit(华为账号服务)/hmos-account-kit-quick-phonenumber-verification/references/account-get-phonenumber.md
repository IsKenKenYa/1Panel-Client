# 快速验证
---
# 快速验证
#### 场景介绍
当应用对获取的手机号时效性要求不高时，可使用Account Kit提供的手机号授权与快速验证能力，向用户发起手机号授权申请，经用户同意授权后，获取到手机号并为用户提供相应服务。以下对Account Kit提供的手机号授权与快速验证能力进行介绍，快速验证手机号功能还可使用场景化控件 [快速验证手机号Button](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Scenario Fusion Kit（融合场景服务）/场景化Button/快速验证手机号Button/scenario-fusion-button-getphonenumber.md) 进行实现。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/7d/v3/jdGO5EdmRRCfPgqjLWcEeg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=D4B1C33E9EC9D97505294B5A8A8AF99E8E06A9D44487896EB50C9DE45F17F477)
对用户选择的华为账号绑定的手机号或者新增的手机号进行验证， **不保证是实时的验证** ， **仅首次需要用户授权** 。
**图1** 手机端快速验证手机号（请以实际效果为准）
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/5f/v3/I1VlJzp9TF-YKcsJHvOTYA/zh-cn_image_0000002659100773.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=E9E9D0D69AAADBA150481EC8843BC34F59381D0941A2F1F17D23DDB244A1B081)
**图2** Wearable设备快速验证手机号（请以实际效果为准）
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4d/v3/YAyQ_xbfTs-3O4OIkn5LEw/zh-cn_image_0000002628861424.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=A6E8C7413A7A4805F121693E4261E4F8DBB27C9D9D0DD9464878689D548C3C1C)
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/75/v3/ubslMQ1jQTKoqoAvqOJpsg/zh-cn_image_0000002659220737.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=303ECA408119BA8F581ABD06947D4F897C11376379C069F2A91F3157C9D93732)
流程说明：
1.
应用通过传对应scope和permission调用授权API，如果已授权则直接返回临时登录凭证Authorization Code；如果未授权则拉起授权页，在用户确认授权后，返回Authorization Code。
2.
将Authorization Code传给应用服务端，使用Client ID、Client Secret、Authorization Code从华为服务器中获取Access Token，再使用Access Token请求获取用户信息。
3.
从用户信息中获取到手机号、UnionID、OpenID。
#### 接口说明
获取快速验证手机号关键接口如下表所示，具体API说明详见 [API参考](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md) 。
| 接口名 | 描述 |
| --- | --- |
| [createAuthorizationWithHuaweiIDRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)():[AuthorizationWithHuaweiIDRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md) | 获取授权接口，通过[AuthorizationWithHuaweiIDRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)传入返回手机号的scope：phone及返回Authorization Code的permission：serviceauthcode，即可获取到Authorization Code。 |
| [constructor](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)(context?:[common.Context](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-common.md)) | 创建授权请求Controller。 |
| [executeRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)(request:[AuthenticationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)): Promise<[AuthenticationResponse](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md)> | 通过Promise方式执行授权操作。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b4/v3/RkYfKmIeRoSCb7Ukwzmrgw/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=B551C18BDCF57552BDC49C203AAD36BF1FA8E13CB8E00C5A1A5FC2E620A14002)
上述接口需在页面或自定义组件生命周期内调用。
#### 开发前提
1、在进行代码开发前，请先确认您已完成 [开发准备](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/开发准备/申请账号权限/account-config-permissions.md) 工作。
-
若未配置签名和指纹，将报错 [1001500001 应用指纹证书校验失败](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/Account Kit常见问题/1001500001 应用指纹证书校验失败的可能原因和解决办法/account-faq-1.md) 。
-
若未完成“获取您的手机号”权限申请，将报错 [1001502014 应用未申请scopes或permissions权限](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/Account Kit常见问题/1001502014 应用未申请scopes或permissions权限的可能原因和解决方法/account-faq-2.md) 。
2、设备需要登录华为账号，若未登录则拉起登录页面。
#### 开发步骤
#### 客户端开发
1.
导入 [authentication](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md) 模块及相关公共模块。
```typescript
import { authentication } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
创建授权请求并设置参数。
```typescript
// 创建授权请求，并设置参数
const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
// 获取手机号需要传如下scope，传参数之前需要先申请对应scope权限，否则会返回1001502014错误码
authRequest.scopes = ['phone'];
// 获取authorizationCode需传如下permission
authRequest.permissions = ['serviceauthcode'];
// 用户是否需要登录授权，该值为true且用户未登录或未授权时，会拉起用户登录或授权页面
authRequest.forceAuthorization = true;
// 建议使用generateRandomUUID生成state，可用于一致性比对，防止跨站攻击
authRequest.state = util.generateRandomUUID();
```
3.
调用 [AuthenticationController](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md) 对象的 [executeRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/ArkTS API/account-api-authentication.md) 方法执行授权请求，并处理授权结果，从授权结果中解析出Authorization Code，之后将Authorization Code传给应用服务端处理。
```
// 执行请求
try {
  // 此示例为代码片段，实际需在自定义组件实例中使用，并传入有效的Context上下文对象
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
    // 开发者处理authorizationCode
    // ...
  }).catch((err: BusinessError) => {
    // ...
    dealAllError(err);
  });
} catch (error) {
  dealAllError(error);
}
```
```
// 错误处理
function dealAllError(error: BusinessError): void {
  hilog.error(0x0000, 'testTag', `Failed to obtain userInfo. Code: ${error.code}, message: ${error.message}`);
  // 在应用快速验证手机号场景下，涉及UI交互时，建议按照如下错误码指导提示用户
  if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
    // 用户未登录华为账号，请登录华为账号并重试
  } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
    // 网络错误，请检查当前网络状态并重试
  } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
    // 用户取消授权
  } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
    // 系统服务异常，请稍后重试
  } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
    // 重复请求，应用无需处理
  } else {
    // 获取用户信息失败，请尝试使用其他方式登录
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
#### 服务端开发
1.
应用服务端使用Client ID、Client Secret、Authorization Code调用 [获取用户级凭证接口](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/REST API/开放接口调用凭证/account-api-obtain-user-token.md) 向华为账号服务器请求获取Access Token、Refresh Token。
2.
使用Access Token调用 [获取用户信息接口](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/REST API/获取用户信息/account-api-get-user-info-get-phone.md) 获取用户信息，从用户信息中获取用户手机号、UnionID、OpenID。
**Access Token过期处理**
由于Access Token的有效期仅为60分钟，当Access Token失效或者即将失效时（可通过 [REST API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/REST API/获取用户信息/account-api-get-user-info-get-nickname-and-avatar.md) 判断），可以使用Refresh Token（有效期180天）通过 [刷新用户级凭证接口](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/REST API/开放接口调用凭证/account-api-obtain-refresh-token.md) 向华为账号服务器请求获取新的Access Token。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c4/v3/nf3RH7WeSFa6JLPAALkHtA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105122Z&HW-CC-Expire=86400&HW-CC-Sign=A305C9DE3D3330D27FB634BFE4CC9A03ECEFB43DF89ECE6EADF33A7F3ACB7F31)
1.
当Access Token失效时，若您不使用Refresh Token向账号服务器请求获取新的Access Token，账号的授权信息将会失效，导致使用Access Token的功能都会失败。
2.
当Access Token非正常失效（如修改密码、退出账号、删除设备）时，业务可重新登录授权获取Authorization Code，向账号服务器请求获取新的Access Token。
**Refresh Token过期处理**
由于Refresh Token的有效期为180天，当Refresh Token失效后（可通过 [REST API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Account Kit（华为账号服务）/REST API/开放接口调用凭证/account-api-obtain-refresh-token.md) 判断），应用服务端需要通知客户端，重新调用授权接口，请求用户重新授权。