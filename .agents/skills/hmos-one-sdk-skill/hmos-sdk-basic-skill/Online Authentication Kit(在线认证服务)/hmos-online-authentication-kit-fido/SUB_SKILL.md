---
name: hmos-online-authentication-kit-fido
description: 提供FIDO UAF本地免密身份认证能力,支持开通/使用/关闭FIDO免密认证,通过生物特征代替密码,最大支持2048字节UAF报文,适用于免密登录、免密支付场景
---

# FIDO免密身份认证技能

## 功能描述

本技能提供FIDO UAF(Universal Authentication Framework)本地免密身份认证能力,通过用户生物特征(指纹/人脸)代替传统密码认证,支持免密登录、免密支付等业务场景。

核心功能包括:
1. **开通FIDO免密认证**: 使用生物特征开通FIDO认证能力,建立用户与应用的绑定关系
2. **使用FIDO免密认证**: 使用已开通的生物特征进行身份认证,验证用户身份
3. **关闭FIDO免密认证**: 注销FIDO认证能力,解除用户与应用的绑定关系

技术特点:
- 支持UAF协议版本: UAF 1.0
- 认证可信等级: ATL4(最高安全等级)
- 用户验证方式: 指纹(2)、人脸(16)
- 认证算法: ALG_SIGN_SECP256R1_ECDSA_SHA256_RAW
- 秘钥保护: TEE(可信执行环境)
- 设备类型: Phone, PC/2in1, Tablet

## 使用场景

### 触发词
- "FIDO认证" - FIDO UAF免密身份认证
- "免密登录" - 使用生物特征登录应用
- "生物识别认证" - 通过指纹/人脸认证
- "FIDO注册" - 开通FIDO免密认证功能
- "FIDO注销" - 关闭FIDO免密认证功能
- "开通FIDO" - 开启FIDO认证能力
- "关闭FIDO" - 注销FIDO认证能力

### 能做
- 开通FIDO UAF免密身份认证功能
- 使用已开通的FIDO认证进行身份验证
- 关闭/注销FIDO免密认证功能
- 发现设备支持的认证器能力
- 检测用户策略的开启状态
- 处理UAF协议消息(注册/认证/注销)
- 通知FIDO认证结果
- 支持自定义认证方式切换
- 引导用户设置生物特征(可选)

### 绝不做
- 不支持FIDO2协议(仅支持FIDO UAF协议)
- 不支持密码认证方式
- 不支持远程身份认证(仅本地认证)
- 不支持非生物特征认证(如PIN码、图案锁等)
- 不处理超出2048字节的UAF请求报文
- 不在无网络环境下使用(FIDO服务需要联网)
- 不在未获取生物识别权限时调用API

### 补充
- FIDO服务需要联网才能提供完整在线身份校验服务,应用需向用户明示联网行为并取得同意
- FIDO服务会返回匿名化的指纹ID和面容ID等个人信息至三方应用,应用上云前需向用户明示并取得同意
- 移动端设备需支持生物特征(指纹/3D人脸),且支持ATL4认证可信等级
- 需要获取`ohos.permission.ACCESS_BIOMETRIC`权限
- 业务方需自行根据FIDO标准协议部署FIDO服务器
- UAF协议报文由FIDO服务器生成,客户端不自行生成报文

## 调用规范和规则

### 输入约束
- UAF协议报文大小: 最大2048字节(含challenge、transaction等字段)
- context类型: 必须为`common.Context`或`common.UIAbilityContext`
- uafProtocolMessage格式: 必须符合UAF协议规范的JSON字符串
- additionalData格式: 必须为JSON字符串格式`{"key": value}`
- channelBinding参数: 各字段长度由三方服务器限制
- FacetID格式: 必须为`ohos:app-id:<应用签名值>`格式

### 执行约束
- 最大API调用频次: 每次认证流程需要4-5次API调用(discover、checkPolicy、processUAFOperation、notifyUAFResult)
- 最大认证超时: 生物特征认证界面由系统控制,超时时间由系统决定
- 最大重试次数: 认证失败后可重试,建议最多3次
- 网络要求: FIDO服务需要联网,网络超时由服务器配置决定
- 生物特征录入: 用户必须已录入指纹或人脸信息

### 内容约束
- 禁止生成: 不生成UAF协议报文内容(报文由服务器生成)
- 禁止使用高危函数: 不使用root权限、不绕过权限检查
- 禁止操作: 不直接访问生物特征数据、不存储原始生物特征信息
- 禁止硬编码: 不在代码中硬编码FacetID、服务器地址等敏感信息
- 禁止伪造: 不伪造认证结果、不绕过认证流程

### 降级约束
- 网络失败: 提示用户检查网络连接,稍后重试
- 生物特征未录入: 引导用户前往设置录入生物特征(可通过`additionalData`配置)
- 设备不支持: 提示用户设备不支持FIDO认证,建议使用其他认证方式
- 认证失败: 提示用户重试或使用自定义认证方式(可通过错误码1005900017切换)
- FacetID不匹配: 检查应用签名配置,联系服务器管理员修正配置
- 用户取消: 提示用户重新发起认证

## 调用流程和步骤

### 步骤1: 开通FIDO免密身份认证

#### 1.1 前置准备

**环境检查**:
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';

try {
  userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
  console.info('Device supports ATL4 authentication trust level');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Device does not support ATL4. Code: ${err?.code}, message: ${err?.message}`);
}
```

**权限声明**:
在`module.json5`中添加权限:
```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.ACCESS_BIOMETRIC"
    }
  ]
}
```

#### 1.2 发现设备认证能力

**调用discover接口**:
```typescript
import { fido } from '@kit.OnlineAuthenticationKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';

@Entry
@Component
struct FidoRegisterPage {
  private uiContext = this.getUIContext().getHostContext();
  
  private async discoverAuthenticators() {
    try {
      let discoverData: fido.DiscoveryData = await fido.discover(this.uiContext);
      console.info('Discovery succeeded. Authenticators:', discoverData.availableAuthenticators);
      
      discoverData.availableAuthenticators.forEach((authenticator) => {
        console.info(`Authenticator: ${authenticator.title}, AAID: ${authenticator.aaid}`);
        console.info(`User verification: ${authenticator.userVerification}`);
      });
      
      return discoverData;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Discovery failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }
  
  build() {
    Column() {
      Button('Discover Authenticators')
        .onClick(() => this.discoverAuthenticators())
    }
  }
}
```

#### 1.3 检查策略状态

**调用checkPolicy接口**:
```typescript
private async checkRegistrationPolicy(regMessage: string): Promise<boolean> {
  let uafMessage: fido.UAFMessage = {
    uafProtocolMessage: regMessage,
    additionalData: ''
  };
  
  try {
    await fido.checkPolicy(this.uiContext, uafMessage);
    console.info('Policy check succeeded. User is registered.');
    return true;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    if (err.code === 1005900005) {
      console.info('User is not registered. Proceed with registration.');
      return false;
    } else {
      console.error(`Policy check failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }
}
```

#### 1.4 执行FIDO注册

**调用processUAFOperation接口**:
```typescript
private async registerFido(regMessage: string): Promise<string> {
  let uafRegMessage: fido.UAFMessage = {
    uafProtocolMessage: regMessage,
    additionalData: '{"isGuideToSetBiometrics": true}'
  };
  
  let channelBinding: fido.ChannelBinding = {};
  
  try {
    let messageResp: fido.UAFMessage = await fido.processUAFOperation(
      this.uiContext,
      uafRegMessage,
      channelBinding
    );
    console.info('Registration succeeded. Response:', messageResp.uafProtocolMessage);
    return messageResp.uafProtocolMessage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 1005900003:
        console.error('User cancelled registration');
        break;
      case 1005900014:
        console.error('User has not registered biometric features');
        break;
      case 1005900017:
        console.info('Switched to custom authentication process');
        break;
      default:
        console.error(`Registration failed. Code: ${err.code}, message: ${err.message}`);
    }
    
    throw error;
  }
}
```

#### 1.5 通知注册结果

**调用notifyUAFResult接口**:
```typescript
private async notifyRegistrationResult(notifyMessage: string): Promise<void> {
  let uafMessage: fido.UAFMessage = {
    uafProtocolMessage: notifyMessage,
    additionalData: ''
  };
  
  try {
    await fido.notifyUAFResult(this.uiContext, uafMessage);
    console.info('Registration result notification succeeded');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Notification failed. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

#### 1.6 完整注册流程

```typescript
private async completeFidoRegistration() {
  try {
    let discoverData = await this.discoverAuthenticators();
    
    let regMessage = await this.fetchRegistrationMessageFromServer(discoverData);
    
    let isRegistered = await this.checkRegistrationPolicy(regMessage);
    if (isRegistered) {
      console.info('Already registered. No need to register again.');
      return;
    }
    
    let regResponse = await this.registerFido(regMessage);
    
    let notifyMessage = await this.sendRegResponseToServer(regResponse);
    
    await this.notifyRegistrationResult(notifyMessage);
    
    console.info('FIDO registration completed successfully');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Registration flow failed: ${err.message}`);
  }
}

private async fetchRegistrationMessageFromServer(discoverData: fido.DiscoveryData): Promise<string> {
  return JSON.stringify([
    {
      header: {
        upv: { major: 1, minor: 0 },
        op: "Reg",
        appID: "",
        serverData: "test server data"
      },
      challenge: "test challenge",
      username: "test user name",
      policy: {
        accepted: [[{
          aaid: ["001B#1001"],
          attachmentHint: 1,
          authenticationAlgorithms: [1],
          authenticatorVersion: 1
        }]]
      }
    }
  ]);
}

private async sendRegResponseToServer(regResponse: string): Promise<string> {
  return JSON.stringify({
    authenticatorsSucceeded: [{
      description: "Attention completed successfully.",
      aaid: "001B#1001",
      keyID: "test keyID"
    }]
  });
}
```

### 步骤2: 使用FIDO免密身份认证

#### 2.1 发现认证器能力
```typescript
private async discoverForAuthentication() {
  try {
    let discoverData = await fido.discover(this.uiContext);
    console.info('Discovery for authentication succeeded');
    return discoverData;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Discovery failed. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

#### 2.2 检查认证策略
```typescript
private async checkAuthenticationPolicy(authMessage: string): Promise<boolean> {
  let uafMessage: fido.UAFMessage = {
    uafProtocolMessage: authMessage,
    additionalData: ''
  };
  
  try {
    await fido.checkPolicy(this.uiContext, uafMessage);
    console.info('Policy check succeeded. User can authenticate.');
    return true;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    if (err.code === 1005900005) {
      console.error('User is not registered. Need to register first.');
      return false;
    } else {
      console.error(`Policy check failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }
}
```

#### 2.3 执行FIDO认证
```typescript
private async authenticateFido(authMessage: string): Promise<string> {
  let uafAuthMessage: fido.UAFMessage = {
    uafProtocolMessage: authMessage,
    additionalData: '{"navigationButtonText": "使用其他方式验证"}'
  };
  
  let channelBinding: fido.ChannelBinding = {};
  
  try {
    let messageResp: fido.UAFMessage = await fido.processUAFOperation(
      this.uiContext,
      uafAuthMessage,
      channelBinding
    );
    console.info('Authentication succeeded. Response:', messageResp.uafProtocolMessage);
    return messageResp.uafProtocolMessage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 1005900003:
        console.error('User cancelled authentication');
        break;
      case 1005900005:
        console.error('User is not registered');
        break;
      case 1005900014:
        console.error('User has not registered biometric features');
        break;
      case 1005900017:
        console.info('Switched to custom authentication process');
        break;
      default:
        console.error(`Authentication failed. Code: ${err.code}, message: ${err.message}`);
    }
    
    throw error;
  }
}
```

#### 2.4 完整认证流程
```typescript
private async completeFidoAuthentication() {
  try {
    let discoverData = await this.discoverForAuthentication();
    
    let authMessage = await this.fetchAuthenticationMessageFromServer();
    
    let canAuthenticate = await this.checkAuthenticationPolicy(authMessage);
    if (!canAuthenticate) {
      console.error('User needs to register first');
      await this.completeFidoRegistration();
      return;
    }
    
    let authResponse = await this.authenticateFido(authMessage);
    
    await this.sendAuthResponseToServer(authResponse);
    
    console.info('FIDO authentication completed successfully');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Authentication flow failed: ${err.message}`);
  }
}

private async fetchAuthenticationMessageFromServer(): Promise<string> {
  return JSON.stringify([
    {
      header: {
        upv: { major: 1, minor: 0 },
        op: "Auth",
        appID: "",
        serverData: "test server data"
      },
      challenge: "test challenge",
      policy: {
        accepted: [[{
          aaid: ["001B#1001"],
          keyIDs: ["test keyIDs"],
          authenticationAlgorithms: [1]
        }]]
      }
    }
  ]);
}

private async sendAuthResponseToServer(authResponse: string): Promise<void> {
  console.info('Authentication response sent to server:', authResponse);
}
```

### 步骤3: 关闭FIDO免密身份认证

#### 3.1 发现认证器能力
```typescript
private async discoverForDeregistration() {
  try {
    let discoverData = await fido.discover(this.uiContext);
    console.info('Discovery for deregistration succeeded');
    return discoverData;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Discovery failed. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

#### 3.2 执行FIDO注销
```typescript
private async deregisterFido(deregMessage: string): Promise<string> {
  let uafDeregMessage: fido.UAFMessage = {
    uafProtocolMessage: deregMessage,
    additionalData: ''
  };
  
  let channelBinding: fido.ChannelBinding = {};
  
  try {
    let messageResp: fido.UAFMessage = await fido.processUAFOperation(
      this.uiContext,
      uafDeregMessage,
      channelBinding
    );
    console.info('Deregistration succeeded. Response:', messageResp.uafProtocolMessage);
    return messageResp.uafProtocolMessage;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Deregistration failed. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

#### 3.3 完整注销流程
```typescript
private async completeFidoDeregistration() {
  try {
    let discoverData = await this.discoverForDeregistration();
    
    let deregMessage = await this.fetchDeregistrationMessageFromServer();
    
    let deregResponse = await this.deregisterFido(deregMessage);
    
    await this.sendDeregResponseToServer(deregResponse);
    
    console.info('FIDO deregistration completed successfully');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Deregistration flow failed: ${err.message}`);
  }
}

private async fetchDeregistrationMessageFromServer(): Promise<string> {
  return JSON.stringify([
    {
      header: {
        upv: { major: 1, minor: 0 },
        op: "Dereg",
        appID: ""
      },
      authenticators: [{
        aaid: "001B#1001",
        keyID: "test keyID"
      }]
    }
  ]);
}

private async sendDeregResponseToServer(deregResponse: string): Promise<void> {
  console.info('Deregistration response sent to server:', deregResponse);
}
```

### 步骤4: 错误处理

**统一错误处理函数**:
```typescript
private handleFidoError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Check input parameters.');
      break;
    case 801:
      console.error('Device type error. This device does not support FIDO.');
      break;
    case 1005900003:
      console.error('User cancelled operation. Prompt user to retry.');
      break;
    case 1005900005:
      console.error('No authenticator available. User may need to register first.');
      break;
    case 1005900006:
      console.error('UAF protocol error. Check message format from server.');
      break;
    case 1005900007:
      console.error('FacetID mismatch. Check application signature configuration.');
      break;
    case 1005900009:
      console.error('Authenticator denied request. Try deregister and register again.');
      break;
    case 1005900014:
      console.error('User has not registered biometric features. Guide user to settings.');
      break;
    case 1005900015:
      console.error('System interruption. Restart device and retry.');
      break;
    case 1005900016:
      console.error('Unknown error. Restart device and retry.');
      break;
    case 1005900017:
      console.info('Switched to custom authentication. Handle custom auth flow.');
      break;
    default:
      console.error(`Unknown error code: ${error.code}, message: ${error.message}`);
  }
}
```

### 步骤5: 降级处理

**自定义认证降级方案**:
```typescript
private async handleCustomAuthentication() {
  try {
    console.info('Launching custom authentication interface');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Custom authentication failed: ${err.message}`);
  }
}

private async authenticateWithFallback(authMessage: string) {
  try {
    let authResponse = await this.authenticateFido(authMessage);
    await this.sendAuthResponseToServer(authResponse);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    if (err.code === 1005900017) {
      console.info('Switching to custom authentication');
      await this.handleCustomAuthentication();
    } else if (err.code === 1005900005) {
      console.info('User not registered. Launching registration flow');
      await this.completeFidoRegistration();
    } else if (err.code === 1005900014) {
      console.info('Biometric features not registered. Guiding user to settings');
    } else {
      console.error('Authentication failed. Using password fallback');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | Parameter error | 参数类型或格式错误 | 检查输入参数类型和格式是否正确 |
| 801 | Device type error | 设备类型不支持 | 检查设备类型是否为Phone/PC/2in1/Tablet |
| 1005900003 | User cancels | 用户点击关闭按钮 | 提示用户重新发起认证 |
| 1005900005 | No authenticator available | 无可用认证器 | checkPolicy:重新开启FIDO; processUAFOperation:已开启则直接认证,未开启则先注册 |
| 1005900006 | UAF protocol violation | 报文格式或数据错误 | 检查传入报文是否符合UAF协议规范 |
| 1005900007 | FacetID not registered | FacetID与服务器配置不匹配 | 检查应用签名配置,确保FacetID格式为ohos:app-id:<签名值> |
| 1005900009 | Authenticator denied request | KHAccessToken不匹配 | 关闭当前FIDO认证,重新开启 |
| 1005900014 | Biometric features not registered | 用户未录入生物特征 | 引导用户在设置中录入指纹/人脸 |
| 1005900015 | System interruption | 运行环境异常 | 重启设备后重试 |
| 1005900016 | Unknown error | FIDO服务未知异常 | 重试或重启设备后重试 |
| 1005900017 | Switched to custom authentication | 用户认证失败后取消 | 拉起自定义认证界面或重新发起UAF认证 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "fido_authentication_example",
  "version": "1.0.0",
  "dependencies": {
    "@kit.OnlineAuthenticationKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.UserAuthenticationKit": "^4.1.0",
    "@kit.AbilityKit": "^4.1.0",
    "@kit.ArkUI": "^4.1.0"
  }
}
```

### 权限配置
在`module.json5`中添加:
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC",
        "reason": "用于FIDO免密身份认证",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS版本: 4.1.0(11)及以上
- 元服务API: 5.0.0(12)及以上支持元服务使用
- 设备类型: Phone, PC/2in1, Tablet
- 生物特征: 设备需支持指纹识别或3D人脸识别
- 认证可信等级: 设备需支持ATL4级别

### 常见编译问题

**问题1: 找不到@kit.OnlineAuthenticationKit**
```
Error: Cannot find module '@kit.OnlineAuthenticationKit'
```
**解决方法**: 确保HarmonyOS SDK版本≥4.1.0,在DevEco Studio中更新SDK

**问题2: 权限未声明**
```
Error: Permission ohos.permission.ACCESS_BIOMETRIC not granted
```
**解决方法**: 在`module.json5`中添加`ohos.permission.ACCESS_BIOMETRIC`权限声明

**问题3: Context类型错误**
```
Error: Parameter error. Expected common.Context
```
**解决方法**: 使用`this.getUIContext().getHostContext()`获取正确的Context对象

**问题4: UAF报文格式错误**
```
Error: 1005900006 - A violation of the UAF protocol occurred
```
**解决方法**: 检查UAF报文JSON格式是否符合UAF协议规范,确保报文由服务器生成

**问题5: FacetID不匹配**
```
Error: 1005900007 - No Facet_ID is registered
```
**解决方法**: 
1. 使用`bundleManager.getBundleInfoForSelf`获取应用签名信息
2. 提取appId字段并去除包名前缀和末尾"="
3. 拼接为`ohos:app-id:<签名值>`格式
4. 将FacetID配置到FIDO服务器

## 常见问题与解决方法

### Q1: 如何获取应用FacetID?
**原因**: FacetID是应用签名证书的标识,需要配置到FIDO服务器
**解决方法**:
```typescript
import { bundleManager } from '@kit.AbilityKit';

let bundleInfo = await bundleManager.getBundleInfoForSelf(
  bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO
);

let appId = bundleInfo.signatureInfo.appId;
let signature = appId.replace(/^[^_]+_/, '').replace(/=+$/, '');
let facetId = `ohos:app-id:${signature}`;

console.info('FacetID:', facetId);
```

### Q2: 用户未录入生物特征怎么办?
**原因**: 用户设备未设置指纹或人脸
**解决方法**:
1. 在`additionalData`中设置`{"isGuideToSetBiometrics": true}`
2. FIDO服务会自动引导用户前往设置界面
3. 或提示用户手动前往设置录入生物特征

### Q3: 如何实现自定义认证方式切换?
**原因**: 用户生物认证失败后希望使用其他认证方式
**解决方法**:
1. 在`additionalData`中设置`{"navigationButtonText": "使用其他方式验证"}`
2. 认证界面会显示切换按钮
3. 用户点击后返回错误码1005900017
4. 拉起自定义认证界面处理

### Q4: 如何判断用户是否已开通FIDO?
**原因**: 需要检查用户状态决定是注册还是认证
**解决方法**:
调用`checkPolicy`接口:
- 成功返回: 用户已注册,可直接认证
- 返回错误码1005900005: 用户未注册,需先注册

### Q5: 认证报文由谁生成?
**原因**: UAF协议报文格式复杂,客户端不应自行生成
**解决方法**:
- UAF报文由FIDO服务器生成
- 客户端调用`discover`获取设备能力后发送给服务器
- 服务器根据设备能力生成合适的UAF报文
- 客户端接收报文后调用FIDO API处理

### Q6: 如何部署FIDO服务器?
**原因**: FIDO认证需要服务器端配合
**解决方法**:
1. 参考FIDO联盟UAF协议规范: https://fidoalliance.org/specs/uaf/
2. 部署支持UAF 1.0协议的FIDO服务器
3. 配置应用FacetID、服务器地址等参数
4. 实现报文生成、验证、结果处理等逻辑

### Q7: 多个认证器如何选择?
**原因**: 设备可能同时支持指纹和人脸认证
**解决方法**:
- `discover`返回所有可用认证器列表
- UAF报文中的`policy.accepted`字段指定接受的认证器
- 根据业务需求选择合适的认证器AAID
- 用户在认证界面可选择使用哪种生物特征

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "FIDO Authentication",
  "authenticatorUsed": {
    "aaid": "001B#1001",
    "title": "Fingerprint Authenticator",
    "userVerification": 2
  },
  "authenticationResult": "authenticated",
  "apiUsed": [
    "fido.discover",
    "fido.checkPolicy",
    "fido.processUAFOperation",
    "fido.notifyUAFResult"
  ],
  "timestamp": "2026-07-04T10:30:00Z",
  "deviceId": "device-id-hash"
}
```

## 参考文档

- [API开发指南](references/onlineauthentication-fido-guide.md)
- [API参考说明](references/onlineauthentication-fido-api.md)
- [FIDO免密认证错误码](references/onlineauthentication-error-code-fido.md)
- [个人数据处理说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description)
- [UAF协议规范](https://fidoalliance.org/specs/uaf/)

## 完整示例代码

- [ArkTS示例 - 开通FIDO认证](assets/fido_register_example.ets)
- [ArkTS示例 - 使用FIDO认证](assets/fido_authenticate_example.ets)
- [ArkTS示例 - 关闭FIDO认证](assets/fido_deregister_example.ets)
- [ArkTS示例 - 完整流程](assets/fido_complete_flow_example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [开通FIDO认证成功](tests/test_fido_register_positive.ets): 用户已录入生物特征,成功开通FIDO认证
- [使用FIDO认证成功](tests/test_fido_authenticate_positive.ets): 用户已开通FIDO,成功完成认证
- [关闭FIDO认证成功](tests/test_fido_deregister_positive.ets): 用户已开通FIDO,成功注销认证
- [发现认证器成功](tests/test_fido_discover_positive.ets): 设备支持生物特征,成功获取认证器列表

### 边界测试用例
- [最大报文大小测试](tests/test_fido_max_message_size.ets): UAF报文接近2048字节限制
- [多次认证测试](tests/test_fido_multiple_authentications.ets): 连续多次认证操作
- [多认证器选择测试](tests/test_fido_multiple_authenticators.ets): 设备同时支持指纹和人脸

### 异常测试用例
- [用户取消认证](tests/test_fido_user_cancel.ets): 用户点击取消按钮,返回错误码1005900003
- [用户未录入生物特征](tests/test_fido_no_biometrics.ets): 用户未设置指纹/人脸,返回错误码1005900014
- [FacetID不匹配](tests/test_fido_facetid_mismatch.ets): 应用签名与服务器配置不匹配,返回错误码1005900007
- [设备不支持FIDO](tests/test_fido_device_not_support.ets): 设备不支持ATL4认证等级
- [网络异常](tests/test_fido_network_error.ets): FIDO服务网络连接失败
- [参数错误](tests/test_fido_parameter_error.ets): context类型错误或报文格式错误
- [切换自定义认证](tests/test_fido_custom_auth.ets): 用户切换自定义认证方式,返回错误码1005900017