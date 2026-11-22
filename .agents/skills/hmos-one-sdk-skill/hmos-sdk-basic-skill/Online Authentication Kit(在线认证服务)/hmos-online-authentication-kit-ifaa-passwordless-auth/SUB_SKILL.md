---
name: hmos-online-authentication-kit-ifaa-passwordless-auth
description: 提供IFAA免密身份认证能力，包括开通、认证、注销三种场景，支持指纹/3D人脸生物特征，需要设备联网和接入IIFAA联盟，适用于免密登录、免密支付等业务场景
---

# IFAA免密身份认证技能

## 功能描述

本技能提供移动端IFAA免密身份认证能力，实现接入IIFAA（互联网金融身份认证联盟）的业务免密登录、免密支付等场景。支持三种核心场景：

1. **开通场景**：开通用户生物特征（指纹/3D人脸）的IFAA免密身份认证能力
2. **认证场景**：使用已开通的生物特征进行IFAA免密身份认证
3. **注销场景**：注销用户已开通的生物特征IFAA免密身份认证能力

基于IIFAA联盟技术规范，通过TLV（Tag-Length-Value）格式数据交互，实现安全的生物特征免密认证。

## 使用场景

### 触发词
- "开通IFAA免密认证"
- "注册IFAA"
- "IFAA免密登录"
- "IFAA免密支付"
- "认证IFAA"
- "注销IFAA"
- "IFAA免密身份认证"
- "生物特征免密认证"

### 能做
- 开通用户的指纹/3D人脸IFAA免密身份认证能力
- 使用生物特征进行IFAA免密身份认证
- 注销已开通的IFAA免密身份认证能力
- 查询IFAA免密认证的开通状态
- 获取IFAA匿名化ID用于服务端交互
- 获取IFAA版本信息和协议版本
- 查询设备支持的生物特征认证可信等级

### 绝不做
- 不处理未接入IIFAA联盟的应用场景
- 不支持设备离线状态下的IFAA认证
- 不处理超出指纹/3D人脸范围的生物特征认证
- 不处理未获得用户授权的生物特征数据
- 不处理非ATL4认证可信等级的场景
- 不处理不支持生物特征的设备场景

### 补充
- 应用需已接入IIFAA联盟，可从IIFAA中心服务器获取签名数据
- 设备需支持生物特征（指纹/3D人脸）且支持ATL4认证可信等级
- 设备需处于联网状态
- IFAA服务会将匿名化的指纹ID和面容ID等个人信息返回至三方应用，应用将个人信息上云前需向用户明示并获得同意
- 需申请ohos.permission.ACCESS_BIOMETRIC权限
- 支持设备类型：Phone, PC/2in1, Tablet
- 起始版本：4.1.0(11)，元服务API从5.0.0(12)开始支持

## 调用规范和规则

### 输入约束
- **用户标识（userToken）**：Uint8Array类型，必须按照IIFAA协议TLV格式构造
- **开通数据（registerData）**：Uint8Array类型，必须为IIFAA服务器下发的TLV格式开通数据
- **认证数据（authData）**：Uint8Array类型，必须为IIFAA服务器下发的TLV格式认证数据
- **注销数据（deregisterData）**：Uint8Array类型，必须为IIFAA服务器下发的TLV格式注销数据
- **认证令牌（authToken）**：Uint8Array类型，必须通过用户认证模块获取（调用userAuth.getUserAuthInstance）

### 执行约束
- **网络要求**：设备必须处于联网状态
- **设备能力**：设备必须支持生物特征认证且支持ATL4认证可信等级
- **IIFAA接入**：应用必须已接入IIFAA联盟
- **权限要求**：必须申请ohos.permission.ACCESS_BIOMETRIC权限
- **服务端交互**：开通、认证、注销流程需与服务端交互获取签名数据

### 内容约束
- **禁止使用**：未经用户授权的生物特征数据
- **禁止操作**：离线状态下执行IFAA认证
- **禁止生成**：不符合IIFAA协议规范的TLV数据
- **禁止调用**：未开通场景直接调用认证接口

### 降级约束
- **网络失败**：提示用户检查网络连接，引导连接WIFI或热点后重试
- **设备不支持**：提示用户当前设备不支持生物特征认证，引导使用其他认证方式
- **未接入IIFAA**：提示开发者应用需接入IIFAA联盟，引导查看IIFAA接入文档
- **权限不足**：提示申请ohos.permission.ACCESS_BIOMETRIC权限，引导查看权限配置
- **服务异常**：重试操作，若持续失败则重启系统后重试

## 调用流程和步骤

### 步骤1：设备能力校验

**前置校验**：
1. 检查设备是否支持生物特征认证（指纹/3D人脸）
2. 检查设备是否支持ATL4认证可信等级
3. 检查网络连接状态
4. 检查应用是否已申请ohos.permission.ACCESS_BIOMETRIC权限

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';

function checkDeviceCapability(): boolean {
  try {
    // 查询设备人脸识别是否支持ATL4级别的认证可信等级
    userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
    console.info('Device supports ATL4 face authentication');
    return true;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Device does not support ATL4 authentication. Code: ${err?.code}, message: ${err?.message}`);
    return false;
  }
}

// 调用校验
if (!checkDeviceCapability()) {
  console.error('Device capability check failed, IFAA authentication unavailable');
  return;
}
```

### 步骤2：开通IFAA免密身份认证

**流程说明**：
1. 构造用户标识（userToken）TLV数据
2. 获取IFAA匿名化ID
3. 从服务端获取签名后的开通数据
4. 调用register接口开通IFAA免密认证

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function registerIFAA(): Promise<void> {
  // 构造用户标识TLV数据（开发者需按IIFAA协议构造）
  let userToken = new Uint8Array([0]); // 替换为实际用户标识TLV数据
  
  // 步骤1：获取匿名化ID
  let getAnonIdResult: Uint8Array;
  try {
    getAnonIdResult = ifaa.getAnonymousIdSync(userToken);
    console.info('Successfully obtained anonymous ID');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤2：开发者使用getAnonIdResult从服务端获取签名后的开通数据
  // 此处需开发者与服务端交互，获取registerData
  
  // 步骤3：调用register接口开通IFAA
  let registerData = new Uint8Array([0]); // 替换为服务端返回的开通数据TLV
  try {
    let registerPromise: Promise<Uint8Array> = ifaa.register(registerData);
    registerPromise.then(registerResult => {
      console.info('Succeeded in registering IFAA.');
      // 开通成功，处理registerResult
    }).catch((err: BusinessError) => {
      console.error(`Failed to register IFAA. Code: ${err.code}, message: ${err.message}`);
      // 开通失败，处理错误
    });
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to call register. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤3：使用IFAA进行免密身份认证

**流程说明**：
1. 获取匿名化ID
2. 从服务端获取认证数据
3. 获取IFAA预认证challenge
4. 调用用户认证模块进行生物特征认证
5. 获取认证令牌（authToken）
6. 调用IFAA认证接口

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function authenticateWithIFAA(): Promise<void> {
  // 构造用户标识TLV数据
  let userToken = new Uint8Array([0]); // 替换为实际用户标识TLV数据
  
  // 步骤1：获取匿名化ID
  let getAnonIdResult: Uint8Array;
  try {
    getAnonIdResult = ifaa.getAnonymousIdSync(userToken);
    console.info('Successfully obtained anonymous ID');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤2：开发者使用getAnonIdResult从服务端获取认证数据
  // 此处需开发者与服务端交互，获取authData
  
  // 步骤3：获取IFAA预认证challenge
  let ifaaChallenge: Uint8Array;
  try {
    ifaaChallenge = ifaa.preAuthSync();
    console.info('Successfully obtained IFAA challenge');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to get IFAA challenge. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤4：构造用户认证参数
  let authParam: userAuth.AuthParam = {
    challenge: ifaaChallenge,
    authType: [userAuth.UserAuthType.FINGERPRINT], // 或 userAuth.UserAuthType.FACE
    authTrustLevel: userAuth.AuthTrustLevel.ATL4
  };
  
  // 步骤5：调用用户认证模块进行生物特征认证
  try {
    let userAuthInstance = userAuth.getUserAuthInstance(authParam, {title: 'IFAA免密认证'});
    userAuthInstance.on('result', {
      onResult(result) {
        let authToken = result.token;
        
        // 步骤6：生物特征认证成功后，调用IFAA认证
        console.info('User authentication succeeded, starting IFAA auth');
        
        let authData = new Uint8Array([0]); // 替换为服务端返回的认证数据TLV
        
        try {
          // 使用同步接口进行IFAA认证
          let authResult: Uint8Array = ifaa.authSync(authToken, authData);
          console.info('IFAA authentication succeeded');
          // 处理authResult
        } catch (error) {
          const err: BusinessError = error as BusinessError;
          console.error(`Failed to call IFAA auth. Code: ${err.code}, message: ${err.message}`);
        }
      }
    });
    userAuthInstance.start();
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to start user authentication. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤4：注销IFAA免密身份认证

**流程说明**：
1. 构造用户标识（userToken）TLV数据
2. 获取匿名化ID
3. 从服务端获取签名后的注销数据
4. 调用deregisterSync接口注销IFAA

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function deregisterIFAA(): Promise<void> {
  // 构造用户标识TLV数据
  let userToken = new Uint8Array([0]); // 替换为实际用户标识TLV数据
  
  // 步骤1：获取匿名化ID
  let getAnonIdResult: Uint8Array;
  try {
    getAnonIdResult = ifaa.getAnonymousIdSync(userToken);
    console.info('Successfully obtained anonymous ID');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to get anonymous ID. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
  
  // 步骤2：开发者使用getAnonIdResult从服务端获取签名后的注销数据
  // 此处需开发者与服务端交互，获取deregisterData
  
  // 步骤3：调用deregisterSync接口注销IFAA
  let deregisterData = new Uint8Array([0]); // 替换为服务端返回的注销数据TLV
  try {
    ifaa.deregisterSync(deregisterData);
    console.info('Succeeded in deregistering IFAA.');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to deregister IFAA. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤5：查询IFAA开通状态

**示例代码**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function queryIFAAStatus(): boolean {
  // 构造用户标识TLV数据
  let userToken = new Uint8Array([0]); // 替换为实际用户标识TLV数据
  
  try {
    let status: boolean = ifaa.queryStatusSync(userToken);
    if (status) {
      console.info('IFAA is registered');
    } else {
      console.info('IFAA is deregistered');
    }
    return status;
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to query IFAA status. Code: ${err.code}, message: ${err.message}`);
    return false;
  }
}
```

### 步骤6：错误处理

**通用错误处理模式**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

function handleIFAAError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error: Invalid TLV data format');
      // 处理参数错误：检查TLV数据格式是否符合IIFAA协议
      break;
    case 801:
      console.error('Device type error: Current device does not support IFAA');
      // 处理设备类型错误：引导用户使用支持的设备类型
      break;
    case 1006100001:
      console.error('System interruption: System exception occurred');
      // 处理系统中断：重启系统后重试
      break;
    case 1006100002:
      console.error('Service abnormal: IFAA service is abnormal');
      // 处理服务异常：重试操作，若持续失败则重启系统
      break;
    default:
      console.error(`Unknown error: Code ${error.code}, message: ${error.message}`);
      // 处理未知错误：记录日志并提示用户
      break;
  }
}
```

### 步骤7：降级处理

**网络失败降级**：
```typescript
function handleNetworkFailure(): void {
  console.warn('Network connection failed, IFAA authentication requires network');
  console.info('Please connect to WIFI or hotspot and retry');
  // 引导用户连接网络后重试
}
```

**设备不支持降级**：
```typescript
function handleDeviceUnsupported(): void {
  console.warn('Current device does not support biometric authentication or ATL4 level');
  console.info('Please use alternative authentication method');
  // 引导用户使用其他认证方式（如密码认证）
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | TLV数据格式不符合IIFAA协议规范 | 检查TLV数据构造是否符合IIFAA协议，确保参数类型为Uint8Array |
| 801 | 设备类型错误 | 当前设备不支持IFAA功能 | 使用支持的设备类型（Phone, PC/2in1, Tablet），检查设备是否支持生物特征 |
| 1006100001 | 系统中断 | 系统运行环境异常 | 重启系统，重试操作 |
| 1006100002 | 服务异常 | IFAA服务异常 | 重试操作，若持续失败则重启系统后重试 |

**通用错误码参考**：
- 其他通用错误码请参见HarmonyOS通用错误码文档

## 编译和修复问题

### 依赖声明

**module.json5配置**：
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": [
      "default",
      "tablet",
      "2in1"
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC",
        "reason": "$string:biometric_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "description": "$string:entry_ability_desc",
        "icon": "$media:icon",
        "label": "$string:entry_ability_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background"
      }
    ]
  }
}
```

**导入模块**：
```typescript
import { ifaa } from '@kit.OnlineAuthenticationKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- **HarmonyOS版本**：4.1.0(11)及以上
- **元服务API**：5.0.0(12)及以上
- **设备类型**：Phone, PC/2in1, Tablet
- **系统能力**：SystemCapability.Security.Ifaa
- **网络状态**：必须联网
- **生物特征**：设备需支持指纹或3D人脸识别
- **认证可信等级**：支持ATL4级别

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.OnlineAuthenticationKit' or its corresponding type declarations.
```
**解决方法**：
- 检查HarmonyOS SDK版本是否为4.1.0(11)及以上
- 确认项目配置中已正确引用HarmonyOS SDK
- 更新DevEco Studio和SDK到最新版本

**问题2：权限配置错误**
```
Error: Permission ohos.permission.ACCESS_BIOMETRIC is not granted.
```
**解决方法**：
- 在module.json5中正确配置ohos.permission.ACCESS_BIOMETRIC权限
- 添加权限申请理由和使用场景说明
- 确保用户已授权生物特征访问权限

**问题3：设备不支持错误**
```
Error: Device type error. Code: 801
```
**解决方法**：
- 检查设备类型是否为Phone、PC/2in1或Tablet
- 确认设备支持生物特征认证功能
- 在支持的设备上运行应用

**问题4：类型错误**
```
Error: Argument of type 'number[]' is not assignable to parameter of type 'Uint8Array'.
```
**解决方法**：
- 将数组转换为Uint8Array类型：`new Uint8Array([0])`
- 确保所有参数类型符合API规范

## 常见问题与解决方法

### Q1：开通IFAA免密身份认证失败
**原因**：
- 设备未联网
- IIFAA服务器返回的开通数据格式错误
- 用户标识TLV数据构造不符合协议规范
- 设备不支持生物特征认证

**解决方法**：
- 检查设备网络连接，确保设备联网状态
- 连接WIFI或热点后重试
- 验证服务端返回的开通数据是否符合IIFAA协议TLV格式
- 检查用户标识TLV数据构造是否正确
- 确认设备支持生物特征认证（指纹/3D人脸）

### Q2：IFAA认证时生物特征认证失败
**原因**：
- 用户未开通对应的生物特征类型
- 用户使用未开通的生物特征进行认证
- 设备不支持ATL4认证可信等级

**解决方法**：
- 先查询IFAA开通状态，确认用户已开通
- 使用已开通的生物特征类型进行认证
- 检查设备是否支持ATL4认证可信等级
- 引导用户开通对应生物特征的IFAA免密认证

### Q3：注销IFAA后无法重新开通
**原因**：
- 注销数据格式错误
- 服务端注销状态未同步
- 网络连接中断

**解决方法**：
- 验证注销数据TLV格式是否符合IIFAA协议
- 确认服务端已完成注销状态同步
- 检查网络连接状态后重新尝试开通流程

### Q4：IFAA服务返回系统中断错误（1006100001）
**原因**：
- 系统运行环境异常
- 生物特征服务异常

**解决方法**：
- 重启系统后重试
- 检查系统生物特征服务是否正常运行
- 若持续失败，联系系统运维人员排查

### Q5：获取匿名化ID失败
**原因**：
- 用户标识TLV数据格式错误
- 系统服务异常

**解决方法**：
- 检查用户标识TLV数据构造是否符合IIFAA协议
- 确保参数类型为Uint8Array
- 重试获取操作，若持续失败则重启系统

### Q6：应用未接入IIFAA联盟如何使用IFAA
**原因**：
- IFAA功能要求应用已接入IIFAA联盟

**解决方法**：
- 联系IIFAA联盟获取接入文档和接入流程
- 完成IIFAA联盟接入审核和配置
- 从IIFAA中心服务器获取签名数据生成能力
- 参考IIFAA联盟技术规范文档进行开发

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "IFAA免密身份认证",
  "scenario": "开通/认证/注销",
  "biometricType": "指纹/3D人脸",
  "authTrustLevel": "ATL4",
  "anonymousId": "Uint8Array数据",
  "authResult": "Uint8Array认证结果",
  "apiUsed": [
    "ifaa.getAnonymousIdSync",
    "ifaa.register",
    "ifaa.preAuthSync",
    "ifaa.authSync",
    "ifaa.deregisterSync",
    "ifaa.queryStatusSync",
    "userAuth.getAvailableStatus",
    "userAuth.getUserAuthInstance"
  ],
  "permissions": [
    "ohos.permission.ACCESS_BIOMETRIC"
  ],
  "deviceCapability": {
    "biometricSupported": true,
    "atl4Supported": true,
    "networkConnected": true
  }
}
```

## 参考文档

- [IFAA免密身份认证开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-ifaa)
- [IFAA API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-ifaa-api)
- [IFAA错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-error-code-ifaa)
- [个人数据处理说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description)

## 完整示例代码

- [开通IFAA示例](assets/register_ifaa_example.ets)
- [认证IFAA示例](assets/auth_ifaa_example.ets)
- [注销IFAA示例](assets/deregister_ifaa_example.ets)
- [查询IFAA状态示例](assets/query_ifaa_status_example.ets)
- [完整IFAA流程示例](assets/ifaa_complete_flow_example.ets)

## 测试用例

### 正向测试用例
- [开通指纹IFAA认证测试](tests/test_register_fingerprint_positive.ets) - 测试正常开通指纹IFAA免密认证
- [认证指纹IFAA测试](tests/test_auth_fingerprint_positive.ets) - 测试正常使用指纹进行IFAA认证
- [开通人脸IFAA认证测试](tests/test_register_face_positive.ets) - 测试正常开通3D人脸IFAA免密认证
- [认证人脸IFAA测试](tests/test_auth_face_positive.ets) - 测试正常使用3D人脸进行IFAA认证
- [注销IFAA认证测试](tests/test_deregister_positive.ets) - 测试正常注销IFAA免密认证

### 边界测试用例
- [最大TLV数据长度测试](tests/test_max_tlv_length_boundary.ets) - 测试TLV数据最大长度限制
- [ATL4认证可信等级测试](tests/test_atl4_level_boundary.ets) - 测试ATL4认证可信等级边界
- [多次开通注销循环测试](tests/test_register_deregister_cycle_boundary.ets) - 测试多次开通注销循环场景

### 异常测试用例
- [网络断开异常测试](tests/test_network_failure_exception.ets) - 测试网络断开时的错误处理
- [参数错误异常测试](tests/test_parameter_error_exception.ets) - 测试参数格式错误的错误处理
- [设备不支持异常测试](tests/test_device_unsupported_exception.ets) - 测试设备不支持生物特征的错误处理
- [服务异常测试](tests/test_service_abnormal_exception.ets) - 测试IFAA服务异常的错误处理
- [未开通认证异常测试](tests/test_unregistered_auth_exception.ets) - 测试未开通场景调用认证的错误处理