---
name: hmos-online-authentication-kit-ifaa
description: 提供IFAA免密身份认证能力，支持指纹/3D人脸生物特征的开通、认证、注销操作，需要设备联网且支持ATL4认证可信等级，适用于金融支付、免密登录等高安全场景
---

# IFAA免密身份认证技能

## 功能描述

本技能提供基于IIFAA（互联网金融身份认证联盟）标准的免密身份认证能力，支持指纹和3D人脸两种生物特征认证方式。通过本技能可以实现：

- **开通认证**：为用户开通指定生物特征类型（指纹/3D人脸）的IFAA免密身份认证能力
- **身份认证**：使用已开通的生物特征进行免密身份认证
- **注销认证**：注销已开通的生物特征类型的IFAA免密身份认证能力
- **状态查询**：查询IFAA免密认证的开通状态
- **获取信息**：获取匿名化ID、版本号、协议版本、支持的证书格式等信息

### 核心特性

- 符合IIFAA联盟技术规范
- 支持ATL4级别的高安全认证可信等级
- 支持同步和异步两种调用方式
- 支持元服务API（从API 12开始）
- 需要生物识别权限：ohos.permission.ACCESS_BIOMETRIC

### 适用设备

- Phone
- PC/2in1
- Tablet

### API版本

- 起始版本：4.1.0(11)
- 元服务支持：5.0.0(12)

## 使用场景

### 触发词
- "IFAA免密认证"
- "生物特征免密登录"
- "指纹免密支付"
- "3D人脸免密认证"
- "IIFAA认证"
- "开通生物特征认证"
- "注销生物特征认证"
- "查询认证状态"

### 能做
- 开通用户的指纹或3D人脸生物特征免密认证能力
- 使用已开通的生物特征进行免密身份认证
- 注销已开通的生物特征免密认证能力
- 查询IFAA免密认证的开通状态
- 获取IFAA认证的匿名化ID（用于服务端交互）
- 获取IFAA接口版本号和协议版本号
- 获取IFAA支持的证书格式
- 获取预认证参数（包含生物认证所需的challenge）

### 绝不做
- 不处理非生物特征的认证方式（如密码、短信验证码等）
- 不直接与IIFAA中心服务器通信（需要应用自行从服务端获取签名数据）
- 不处理用户未开通的生物特征认证（会导致认证失败）
- 不在无网络状态下进行开通/认证/注销操作
- 不处理低于ATL4认证可信等级的设备

### 补充
- 开发者应用需已接入IIFAA联盟，能够从IIFAA中心服务器获取签名数据
- 所有TLV格式数据需按照IIFAA协议规范构造
- 应用将个人信息（匿名化指纹ID/面容ID）上云前，需向用户明示并取得同意
- 移动端设备必须支持生物特征（指纹/3D人脸）且支持ATL4认证可信等级
- 调用认证接口前需先调用用户认证模块获取authToken

## 调用规范和规则

### 输入约束
- userToken参数：必须是符合IIFAA TLV格式的Uint8Array类型数据
- registerData/authData/deregisterData参数：必须是IIFAA服务器下发的TLV格式数据，转换为Uint8Array
- authToken参数：必须通过用户认证模块（@ohos.userIAM.userAuth）获取的有效token
- 参数有效性：所有Uint8Array参数长度必须大于0，不能为空数组

### 执行约束
- 最大耗时：同步接口立即返回，异步接口不超过5秒
- 网络要求：设备必须处于联网状态
- 权限要求：必须申请ohos.permission.ACCESS_BIOMETRIC权限
- 设备要求：设备必须支持ATL4认证可信等级
- 调用顺序：认证前必须先调用preAuthSync获取challenge，并通过用户认证模块获取authToken

### 内容约束
- 禁止使用伪造的TLV数据
- 禁止绕过用户认证直接调用auth接口
- 禁止在未开通状态下直接调用认证接口
- 禁止在无网络环境下调用开通/认证/注销接口
- 禁止使用未通过IIFAA联盟认证的签名数据

### 降级约束
- 网络失败：提示用户检查网络连接，建议连接WiFi或热点后重试
- 设备不支持ATL4：提示用户设备不支持高安全认证，建议使用其他认证方式
- 生物特征未开通：引导用户先开通生物特征认证
- 参数错误：提示参数格式错误，建议检查TLV数据格式
- 服务异常：建议重启系统或稍后重试

## 调用流程和步骤

### 步骤1：环境准备和权限检查

**前置校验**：
1. 检查设备是否联网
2. 检查设备是否支持生物特征（指纹/3D人脸）
3. 查询设备是否支持ATL4认证可信等级
4. 确认应用已申请ohos.permission.ACCESS_BIOMETRIC权限
5. 确认应用已接入IIFAA联盟

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';

// 查询设备是否支持ATL4认证可信等级
try {
  userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
  console.info('Device supports ATL4 authentication');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Device does not support ATL4. Code: ${err?.code}, message: ${err?.message}`);
  // 降级处理：提示用户设备不支持
}
```

### 步骤2：获取IFAA版本和协议信息（可选）

**说明**：在正式使用前，可先获取IFAA接口版本和协议版本信息。

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';

// 获取IFAA接口版本号（同步）
let apiVersion: number = ifaa.getVersionSync();
console.info(`IFAA API version: ${apiVersion}`);

// 获取IFAA协议版本号（同步）
let protocolVersion: Uint8Array = ifaa.getProtocolVersionSync();
console.info(`IFAA protocol version obtained`);

// 获取支持的证书格式（同步）
let certTypes: Uint8Array = ifaa.getSupportedCertTypesSync();
console.info(`Supported certificate types obtained`);
```

### 步骤3：开通IFAA免密身份认证

**流程**：
1. 构造用户标识（userToken）的TLV数据
2. 调用getAnonymousIdSync获取匿名化ID
3. 使用匿名化ID从IIFAA服务端获取签名后的开通数据
4. 构造开通数据的TLV格式
5. 调用register接口开通认证

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 构造用户标识的TLV数据（开发者需按照IIFAA协议构造）
let userToken = new Uint8Array([0]); // 替换为实际TLV数据

// 获取匿名化ID
let anonymousId: Uint8Array;
try {
  anonymousId = ifaa.getAnonymousIdSync(userToken);
  console.info('Successfully obtained anonymous ID');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
  return;
}

// 使用anonymousId从IIFAA服务端获取签名后的开通数据（开发者自行实现）
// let signedRegisterData = fetchFromIIFAAServer(anonymousId);

// 构造开通数据（IIFAA协议的TLV格式）
let registerData = new Uint8Array([0]); // 替换为从服务端获取的签名数据

// 调用register接口开通认证
try {
  let registerPromise: Promise<Uint8Array> = ifaa.register(registerData);
  registerPromise.then(registerResult => {
    console.info('Successfully registered IFAA authentication');
    // 处理开通结果
  }).catch((err: BusinessError) => {
    console.error(`Failed to register. Code: ${err.code}, message: ${err.message}`);
    // 错误处理：检查网络、参数格式等
  });
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to call register. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤4：查询开通状态

**说明**：可随时查询用户是否已开通IFAA免密认证。

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';

// 构造用户标识的TLV数据
let userToken = new Uint8Array([0]); // 替换为实际TLV数据

// 查询开通状态（同步）
try {
  let isRegistered: boolean = ifaa.queryStatusSync(userToken);
  if (isRegistered) {
    console.info('IFAA authentication is registered');
  } else {
    console.info('IFAA authentication is not registered');
  }
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to query status. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤5：使用IFAA免密身份认证

**流程**：
1. 构造用户标识的TLV数据
2. 调用getAnonymousIdSync获取匿名化ID
3. 使用匿名化ID从IIFAA服务端获取签名后的认证数据
4. 调用preAuthSync获取challenge
5. 使用challenge调用用户认证模块进行生物特征认证
6. 获取用户认证的authToken
7. 调用auth接口进行IFAA认证

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 构造用户标识的TLV数据
let userToken = new Uint8Array([0]); // 替换为实际TLV数据

// 获取匿名化ID
let anonymousId: Uint8Array;
try {
  anonymousId = ifaa.getAnonymousIdSync(userToken);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
  return;
}

// 使用anonymousId从IIFAA服务端获取签名后的认证数据（开发者自行实现）
// let signedAuthData = fetchFromIIFAAServer(anonymousId);

// 获取预认证参数（包含challenge）
let ifaaChallenge: Uint8Array;
try {
  ifaaChallenge = ifaa.preAuthSync();
  console.info('Successfully obtained pre-auth challenge');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to pre-auth. Code: ${err.code}, message: ${err.message}`);
  return;
}

// 构造用户认证参数
let authParam: userAuth.AuthParam = {
  challenge: ifaaChallenge,
  authType: [userAuth.UserAuthType.FINGERPRINT], // 或FACE
  authTrustLevel: userAuth.AuthTrustLevel.ATL4
};

// 调用用户认证模块
try {
  let userAuthInstance = userAuth.getUserAuthInstance(authParam, {title: 'IFAA免密认证'});
  
  userAuthInstance.on('result', {
    onResult(result) {
      let authToken = result.token;
      
      // 构造认证数据（IIFAA协议的TLV格式）
      let authData = new Uint8Array([0]); // 替换为从服务端获取的签名数据
      
      // 调用IFAA认证接口
      try {
        let authResult: Uint8Array = ifaa.authSync(authToken, authData);
        console.info('IFAA authentication successful');
        // 处理认证结果
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`Failed to IFAA auth. Code: ${err.code}, message: ${err.message}`);
      }
    }
  });
  
  userAuthInstance.start();
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to user auth. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤6：注销IFAA免密身份认证

**流程**：
1. 构造用户标识的TLV数据
2. 调用getAnonymousIdSync获取匿名化ID
3. 使用匿名化ID从IIFAA服务端获取签名后的注销数据
4. 构造注销数据的TLV格式
5. 调用deregisterSync接口注销认证

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 构造用户标识的TLV数据
let userToken = new Uint8Array([0]); // 替换为实际TLV数据

// 获取匿名化ID
let anonymousId: Uint8Array;
try {
  anonymousId = ifaa.getAnonymousIdSync(userToken);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
  return;
}

// 使用anonymousId从IIFAA服务端获取签名后的注销数据（开发者自行实现）
// let signedDeregisterData = fetchFromIIFAAServer(anonymousId);

// 构造注销数据（IIFAA协议的TLV格式）
let deregisterData = new Uint8Array([0]); // 替换为从服务端获取的签名数据

// 调用deregister接口注销认证
try {
  ifaa.deregisterSync(deregisterData);
  console.info('Successfully deregistered IFAA authentication');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed to deregister. Code: ${err.code}, message: ${err.message}`);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型和格式，确保TLV数据符合IIFAA协议规范 |
| 801 | 设备类型错误 | 确认设备类型为Phone/PC/2in1/Tablet |
| 1006100001 | 系统中断 | 重启系统后重试操作 |
| 1006100002 | 服务异常 | 先重试操作，若仍失败则重启系统后重试 |

**详细错误处理**：

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  // IFAA接口调用
} catch (error) {
  const err: BusinessError = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error('Parameter error: Invalid TLV data format');
      // 检查TLV数据构造是否正确
      break;
    case 801:
      console.error('Device type error: Unsupported device');
      // 提示用户设备不支持
      break;
    case 1006100001:
      console.error('System interruption: Please restart device');
      // 建议用户重启设备
      break;
    case 1006100002:
      console.error('Service abnormal: Please retry or restart');
      // 先重试，若失败则建议重启
      break;
    default:
      console.error(`Unknown error: ${err.message}`);
  }
}
```

## 编译和修复问题

### 依赖声明

**模块导入**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**权限配置**（module.json5）：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC",
        "reason": "用于IFAA免密身份认证",
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
- HarmonyOS API版本：≥4.1.0(11)
- 元服务API支持：≥5.0.0(12)
- 设备类型：Phone, PC/2in1, Tablet
- 网络环境：必须联网
- 生物特征支持：设备需支持指纹或3D人脸，且支持ATL4认证可信等级

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.OnlineAuthenticationKit'
```
**解决方法**：确保项目API版本≥4.1.0(11)，检查build-profile.json5中的compileSdkVersion配置

**问题2：权限未声明**
```
Error: Permission not granted
```
**解决方法**：在module.json5中添加ohos.permission.ACCESS_BIOMETRIC权限声明

**问题3：设备不支持ATL4**
```
Error: Authentication trust level not supported
```
**解决方法**：调用userAuth.getAvailableStatus检查设备是否支持ATL4，若不支持则使用其他认证方式

**问题4：网络连接失败**
```
Error: Network unavailable
```
**解决方法**：提示用户检查网络连接，建议连接WiFi或热点后重试

## 常见问题与解决方法

### Q1：开通IFAA免密认证失败
**原因**：
- 设备未联网
- TLV数据格式错误
- IIFAA服务器签名数据无效
- 设备不支持生物特征或ATL4等级

**解决方法**：
- 检查设备网络连接状态
- 验证TLV数据是否符合IIFAA协议规范
- 确认从IIFAA服务器获取的签名数据有效
- 调用userAuth.getAvailableStatus检查设备支持情况

### Q2：认证时提示生物特征未开通
**原因**：用户未开通对应的生物特征类型认证

**解决方法**：
- 先调用queryStatusSync查询开通状态
- 若未开通，引导用户先调用register接口开通
- 确保开通和认证使用相同的生物特征类型

### Q3：调用auth接口失败
**原因**：
- authToken无效或过期
- 未调用preAuthSync获取challenge
- 用户生物认证未通过
- authData格式错误

**解决方法**：
- 确保先调用preAuthSync获取challenge
- 确保用户生物认证成功后再调用auth接口
- 检查authToken是否有效（result.token）
- 验证authData的TLV格式是否正确

### Q4：注销后仍能查询到开通状态
**原因**：
- 注销数据无效
- 注销操作未成功完成
- 服务端状态未同步

**解决方法**：
- 确认deregisterSync调用无异常抛出
- 验证注销数据是否从IIFAA服务器正确获取
- 稍后重新查询状态，等待服务端同步

### Q5：设备重启后认证失败
**原因**：系统中断导致服务异常

**解决方法**：
- 参考错误码1006100001的处理方法
- 重启系统后重新尝试
- 若持续失败，检查设备生物特征设置是否正常

### Q6：如何选择同步和异步接口
**建议**：
- **同步接口**：适用于快速查询状态、获取版本信息等轻量操作
- **异步接口**：适用于开通、认证、注销等耗时操作，避免阻塞主线程
- 在UI交互场景建议使用异步接口（Promise或Callback）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "register/auth/deregister/query",
  "biometricType": "fingerprint/face",
  "anonymousId": "Uint8Array(获取到的匿名化ID)",
  "apiVersion": "接口版本号",
  "protocolVersion": "协议版本号",
  "isRegistered": "true/false(开通状态)",
  "authResult": "Uint8Array(认证结果TLV数据)",
  "errorHandled": "错误处理状态"
}
```

**API使用列表**：
- ifaa.getVersionSync
- ifaa.getProtocolVersionSync
- ifaa.getSupportedCertTypesSync
- ifaa.getAnonymousIdSync
- ifaa.queryStatusSync
- ifaa.register
- ifaa.preAuthSync
- ifaa.authSync
- ifaa.deregisterSync
- userAuth.getAvailableStatus
- userAuth.getUserAuthInstance

## 参考文档

- [IFAA免密身份认证开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-ifaa)
- [IFAA API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-ifaa-api)
- [IFAA错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-error-code-ifaa)
- [个人数据处理说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description)

## 完整示例代码

- [IFAA开通认证示例](assets/ifaa-register-example.ets)
- [IFAA身份认证示例](assets/ifaa-auth-example.ets)
- [IFAA注销认证示例](assets/ifaa-deregister-example.ets)
- [IFAA状态查询示例](assets/ifaa-query-example.ets)

## 测试用例

### 正向测试用例
- [开通指纹认证测试](tests/test_register_fingerprint.py)：测试正常开通指纹IFAA认证
- [开通人脸认证测试](tests/test_register_face.py)：测试正常开通3D人脸IFAA认证
- [指纹认证测试](tests/test_auth_fingerprint.py)：测试已开通指纹认证的正常流程
- [人脸认证测试](tests/test_auth_face.py)：测试已开通人脸认证的正常流程
- [注销认证测试](tests/test_deregister.py)：测试正常注销已开通的认证

### 边界测试用例
- [网络状态测试](tests/test_network_boundary.py)：测试网络不稳定情况下的降级处理
- [设备兼容性测试](tests/test_device_compatibility.py)：测试不同设备类型和API版本
- [并发操作测试](tests/test_concurrent_operations.py)：测试同时开通多种生物特征认证

### 异常测试用例
- [参数错误测试](tests/test_invalid_parameters.py)：测试空数组、错误TLV格式等异常参数
- [权限缺失测试](tests/test_permission_missing.py)：测试未申请生物识别权限的场景
- [网络断开测试](tests/test_network_failure.py)：测试无网络环境下操作的错误处理
- [未开通认证测试](tests/test_not_registered.py)：测试未开通状态下调用认证接口
- [服务异常测试](tests/test_service_error.py)：测试系统中断和服务异常的错误处理