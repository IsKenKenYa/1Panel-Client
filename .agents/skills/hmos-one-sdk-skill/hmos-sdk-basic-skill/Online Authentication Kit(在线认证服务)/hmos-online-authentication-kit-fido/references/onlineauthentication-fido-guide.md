# FIDO免密身份认证
---
# FIDO免密身份认证
#### 场景介绍
-
开通FIDO免密身份认证功能，使用用户已有的生物特征开通FIDO免密身份认证能力。
-
使用FIDO免密身份认证功能，使用用户已开通的生物特征进行FIDO免密身份认证。
-
关闭FIDO免密身份认证功能，使用用户已开通的生物特征注销FIDO免密身份认证能力。
#### 基本概念
在开发FIDO免密身份认证功能前，开发者应了解以下基本概念：
-
FIDO协议
FIDO（Fast Identity Online）是一套身份认证框架协议，它由FIDO联盟推出并持续维护。FIDO规范定义了一套在线身份认证的技术架构。
-
UAF身份认证框架
UAF（Universal Authentication Framework）意为通用身份认证框架，目的是通过生物识别（如指纹识别）和加密技术方式，为用户提供无密码的身份认证体验。
#### 相关权限
获取生物识别权限：ohos.permission.ACCESS_BIOMETRIC。
#### 约束与限制
需满足以下条件，才能使用该功能。
-
移动端设备需要支持生物特征（指纹/3D人脸），查询当前移动端设备是否支持ATL4级别的认证可信等级。
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';
try {
  // 示例，查询设备人脸识别是否支持ATL4级别的认证可信等级
  userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
  console.info('current auth trust level is supported');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`current auth trust level is not supported. Code is ${err?.code}, message is ${err?.message}`);
}
```
-
FIDO服务需要联网，以便提供完整的在线身份校验服务。应用在调用本服务API前，需将FIDO服务联网行为向用户明示，并且取得用户同意。
-
FIDO服务会将匿名化的指纹ID和面容ID等个人信息返回至三方应用，以提供绑定具体生物特征的免密认证能力。应用将个人信息上云前，需要向用户明示并且取得同意，详细请参考 [个人数据处理说明](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/安全/Online Authentication Kit（在线认证服务）/个人数据处理说明/onlineauthentication-personal-data-processing-description.md) 。
#### 业务流程
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/49/v3/AMYLw8wCRb-WTnTD3cYODw/zh-cn_image_0000002628860998.png?HW-CC-KV=V1&HW-CC-Date=20260701T104824Z&HW-CC-Expire=86400&HW-CC-Sign=647F5E0415CEDC729658387345FAB012986692B50A17A762033CAACF41D9663F)
#### 接口说明
业务进行FIDO免密身份认证功能的开通、使用和关闭。
**表1** FIDO免密身份认证接口功能介绍
| 接口名 | 描述 |
| --- | --- |
| [discover](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)(context: common.Context): Promise<[DiscoveryData](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)> | 发现设备的认证能力，返回当前设备软件支持的认证器数据。 |
| [checkPolicy](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)(context: common.Context, uafRequest:[UAFMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)): Promise<void> | 检测用户策略的开启状态。 |
| [processUAFOperation](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)(context: common.Context, uafRequest:[UAFMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md), channelBindings?:[ChannelBinding](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)): Promise<[UAFMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)> | 用户UAF操作接口，处理UAF协议消息。 |
| [notifyUAFResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)(context: common.Context, uafResponse:[UAFMessage](D:/code/APIDevice/output/md_output/harmonyos-references/系统/安全/Online Authentication Kit（在线认证服务）/ArkTS API/onlineauthentication-fido-api.md)): Promise<void> | 开通结果通知接口。 |
#### 开发步骤
1.
需要业务方自行根据FIDO标准协议部署FIDO服务器。
2.
导入相关模块。
```typescript
import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
3.
开通FIDO免密身份认证。
1.
```typescript
@Entry
@Component
struct FidoInvokePage {
  private uiContext = this.getUIContext().getHostContext();
  private async invokeDiscover() {
    try {
      // 初始化认证器信息
      let discoverData = await fido.discover(this.uiContext);
      // 业务处理discoverData
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to call discover. Code is ${err.code}, message is ${err.message}`);
      // 业务根据错误码判断异常类型，进行相应处理，详见错误码参考
    }
  }
  build() {
    // 业务UI界面
  }
}
```
2.
```typescript
// uafMessage为FIDO服务端获取的策略检查报文
let uafAuthMessage: fido.UAFMessage = {
  /*
   * 策略检查报文格式: [{"header":{"upv":{"major":1,"minor":0},"op":"Auth","appID":"","serverData":"test server data"},"challenge":"test challenge","policy":{"accepted":[[{"aaid":["001B#1001"],"keyIDs":["test keyIDs"],"authenticationAlgorithms":[1]}]]}}]
   */
  uafProtocolMessage: uafMessage, // 从服务端获取的检查策略报文
  additionalData: '' // 附加信息（可选）
};
let isRegistered: boolean = true;
try {
  // 检查是否已经开启FIDO认证
  await fido.checkPolicy(this.uiContext, uafAuthMessage);
} catch (error) {
  isRegistered = false;
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call checkPolicy. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断状态，进行相应处理
}
if (isRegistered) {
  console.info('has registered, no need to register again.');
  // 已注册，业务根据需要执行后续流程
}
```
3.
```typescript
// regMessage为从FIDO服务端获取的注册报文
let uafRegMessage: fido.UAFMessage = {
 /*
  * 注册报文格式: [{"header":{"upv":{"major":1,"minor":0},"op":"Reg","appID":"","serverData":"test server data"},"challenge":"test challenge","username":"test user name","policy":{"accepted":[[{"aaid":["001B#1001"],"attachmentHint":1,"authenticationAlgorithms":[1],"authenticatorVersion":1}]]}}]
  */
  uafProtocolMessage: regMessage, // 从服务端获取的注册报文
  additionalData: '' // 附加信息（可选）
};
// 传递通道绑定参数（可选）
let channelBinding: fido.ChannelBinding = {};
try {
  // 调用processUAFOperation接口进行FIDO注册
  let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call processUAFOperation. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
```
4.
```typescript
// notifyMessage为从FIDO服务端获取的注册结果报文
let notifyMessage: string = '';
let notifyUafMessage: fido.UAFMessage = {
  /*
   * 响应报文格式: {"authenticatorsSucceeded":[{"description":"Attention completed successfully.","aaid":"001B#1001","keyID":"test keyID"}]}
   */
  uafProtocolMessage: notifyMessage, // 从服务端获取的注册结果报文
  additionalData: '' // 附加信息（可选）
};
```
5.
```typescript
try {
  // 调用notifyUAFResult进行结果通知
  await fido.notifyUAFResult(this.uiContext, uafMessage).then(() => {
    console.info('Succeeded in doing notifyUAFResult.');
  });
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call notifyUAFResult. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
```
4.
使用FIDO免密身份认证。
1.
```typescript
// 获取当前界面的context
try {
  // 调用discover方法初始化认证器信息
  let discoverData = await fido.discover(this.uiContext);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call discover. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
```
2.
```typescript
// uafMessage为从FIDO服务器获取的策略检查报文
let uafAuthMessage: fido.UAFMessage = {
  /*
   * 策略检查报文格式: [{"header":{"upv":{"major":1,"minor":0},"op":"Auth","appID":"","serverData":"test server data"},"challenge":"test challenge","policy":{"accepted":[[{"aaid":["001B#1001"],"keyIDs":["test keyIDs"],"authenticationAlgorithms":[1]}]]}}]
   */
  uafProtocolMessage: uafMessage, // 从服务端获取的检查策略报文
  additionalData: '' // 附加信息（可选）
};
let isRegistered: boolean = true;
try {
  // 检查是否已经开启FIDO认证
  await fido.checkPolicy(this.uiContext, uafAuthMessage);
} catch (error) {
  isRegistered = false;
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call checkPolicy. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断状态，进行相应处理
}
if (isRegistered) {
  console.info('has registered, no need to register again.');
  // 已注册，业务根据需要执行后续流程
}
```
3.
```typescript
// regMessage为从FIDO服务器获取的认证报文
let uafRegMessage: fido.UAFMessage = {
  /*
   * 认证报文格式: [{"header":{"upv":{"major":1,"minor":0},"op":"Auth","appID":"","serverData":"test server data"},"challenge":"test challenge","policy":{"accepted":[[{"aaid":["001B#1001"],"keyIDs":["test keyIDs"],"authenticationAlgorithms":[1]}]]}}]
   */
  uafProtocolMessage: regMessage, // 从服务端获取的认证报文
  additionalData: '' // 附加信息（可选）
};
// 传递通道绑定参数（可选）
let channelBinding: fido.ChannelBinding = {};
try {
  // 调用processUAFOperation接口进行FIDO认证
  let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call processUAFOperation. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
 // 发送认证响应报文至FIDO服务端进行验证并返回认证结果
```
5.
关闭FIDO免密身份认证。
1.
```typescript
try {
  // 调用discover方法初始化认证器信息
  let discoverData = await fido.discover(this.uiContext);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call discover. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
```
2.
```typescript
// deregMessage为从FIDO服务器获取的注销报文
let uafRegMessage: fido.UAFMessage = {
  /*
   * 注销报文格式:  [{"header":{"upv":{"major":1,"minor":0},"op":"Dereg","appID":""},"authenticators":[{"aaid":"001B#1001","keyID":"test keyID"}]}]
   */
  uafProtocolMessage: deregMessage, // 从服务端获取的注销报文
  additionalData: '' // 附加信息（可选）
};
// 传递通道绑定参数（可选）
let channelBinding: fido.ChannelBinding = {};
try {
  // 调用processUAFOperation接口进行FIDO注销
  let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call processUAFOperation. Code is ${err.code}, message is ${err.message}`);
  // 业务根据错误码判断异常类型，进行相应处理
}
 // 发送认证响应报文至FIDO服务端进行验证并返回认证结果
```