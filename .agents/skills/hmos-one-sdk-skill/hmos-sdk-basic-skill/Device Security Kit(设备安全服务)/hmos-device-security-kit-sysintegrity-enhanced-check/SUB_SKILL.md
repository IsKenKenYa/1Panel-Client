---
name: hmos-device-security-kit-sysintegrity-enhanced-check
description: 检测设备系统完整性增强版，识别越狱/模拟器/攻击/解锁等风险，返回JWS签名结果需服务端验证，适用于高安全级别业务场景的风控检测
---

# 系统完整性增强检测技能

## 功能描述

本技能提供HarmonyOS设备系统完整性增强检测能力，通过调用Device Security Kit的`checkSysIntegrityEnhanced`接口获取设备安全状态检测结果。该检测能够识别设备是否存在越狱、模拟器运行、被攻击、解锁等安全风险，并返回JWS（JSON Web Signature）格式的签名结果，需要在应用服务器端验证签名后使用。

**核心能力**：
- 检测设备是否被越狱
- 检测设备是否为模拟器（非真实设备）
- 检测设备是否被攻击
- 检测设备是否被解锁
- 提供防重放攻击的nonce机制
- 返回JWS签名格式的可信结果

**技术特点**：
- 端云协同检测机制
- 基于证书链的签名验证
- 支持服务端完整性验证
- 实时风险评估

## 使用场景

### 触发词
- "系统完整性检测"
- "设备安全检测"
- "越狱检测"
- "模拟器检测"
- "设备风控"
- "安全环境验证"
- "设备真实性验证"
- "checkSysIntegrityEnhanced"

### 能做
- 在应用启动或关键操作前检测设备安全状态
- 识别设备是否被越狱、Root或解锁
- 判断设备是否为模拟器或被攻击
- 提供JWS格式的可信检测结果供服务端验证
- 结合业务场景实施安全策略（如限制高风险操作）
- 为金融、支付、隐私数据访问等高安全场景提供设备可信度评估

### 绝不做
- 不直接阻止用户操作（检测结果是参考依据，应由业务层决策）
- 不在UI线程执行检测（会阻塞界面）
- 不在无网络环境下使用（需要端云协同）
- 不忽略检测结果的服务端验证（必须验证签名）
- 不作为设备安全的唯一判断依据（需结合其他安全措施）
- 不在短时间内频繁调用（受频次限制）

### 补充
- **频次限制**：每个应用在每个设备上每天最多调用1万次，每分钟最多5次，最多5个并发
- **设备支持**：Phone、Tablet、PC/2in1、Wearable
- **API版本**：起始版本6.0.0(20)
- **前置条件**：需开通Device Security服务并申请Profile
- **服务端验证**：检测结果必须通过服务端验证签名后才可使用
- **用户体验**：建议采用友好的提示语，如"您的设备疑似存在风险或运行在不安全环境中，请谨慎使用此功能"

## 调用规范和规则

### 输入约束
- **nonce长度**：必须为16至66字节之间
- **nonce编码**：有效值为base64编码范围（A-Z, a-z, 0-9, +, /, =）
- **nonce来源**：推荐从服务器随机生成，每次请求使用新nonce
- **nonce用途**：用于防重放攻击，检测结果中会包含此值供验证

### 执行约束
- **最大耗时**：网络请求约2-5秒，建议设置超时时间10秒
- **并发限制**：每个设备最多5个并发调用
- **调用频次**：每个应用每个设备每天最多1万次，每分钟最多5次
- **执行线程**：必须在非UI线程执行（推荐使用TaskPool或Worker）
- **网络要求**：需要联网，设备网络状态良好

### 内容约束
- **禁止UI线程调用**：会导致界面卡顿甚至ANR
- **禁止本地验证结果**：必须将JWS结果发送到服务端验证签名
- **禁止忽略错误**：所有错误必须捕获并处理
- **禁止明文存储结果**：检测结果不应本地持久化存储
- **禁止绕过签名验证**：直接使用未验证的结果存在安全风险

### 降级约束
- **网络不可达**：提示用户检查网络连接，延迟或取消操作
- **服务不可用**：记录日志，降级到基础检测或提示用户稍后重试
- **频次超限**：记录日志，使用本地缓存策略或引导用户等待
- **验证失败**：拒绝高风险操作，提示用户设备环境不安全
- **设备不支持**：根据业务需求决定是否继续操作

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持该API（API版本>=6.0.0(20)）
2. 检查网络连接状态
3. 确认已开通Device Security服务并配置Profile
4. 从服务器获取随机nonce值（16-66字节的base64字符串）

**参数准备**：
```typescript
// ArkTS示例
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SysIntegrityEnhancedCheck";
const DOMAIN = 0x0000;

// 从服务器获取的随机nonce值
const nonce: string = 'imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs'; // 实际应从服务器获取

// 构造请求参数
const request: safetyDetect.SysIntegrityRequest = {
  nonce: nonce
};
```

### 步骤2：调用API

**示例代码**：
```typescript
// 完整的系统完整性增强检测函数
async function checkSysIntegrityEnhanced(nonce: string): Promise<string> {
  const TAG = "SysIntegrityEnhancedCheck";
  const DOMAIN = 0x0000;
  
  try {
    // 参数校验
    if (!nonce || nonce.length < 16 || nonce.length > 66) {
      hilog.error(DOMAIN, TAG, 'Invalid nonce length: must be 16-66 bytes');
      throw new Error('Invalid nonce length');
    }
    
    // 构造请求
    const request: safetyDetect.SysIntegrityRequest = {
      nonce: nonce
    };
    
    hilog.info(DOMAIN, TAG, 'Start checkSysIntegrityEnhanced');
    
    // 调用API（必须在非UI线程执行）
    const response: safetyDetect.SysIntegrityResponse = 
      await safetyDetect.checkSysIntegrityEnhanced(request);
    
    hilog.info(DOMAIN, TAG, 'checkSysIntegrityEnhanced succeeded');
    
    // 返回JWS格式的检测结果
    return response.result;
    
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 
      'checkSysIntegrityEnhanced failed: code=%{public}d, message=%{public}s', 
      error.code, error.message);
    throw error;
  }
}

// 在TaskPool中执行检测（推荐方式）
import taskpool from '@ohos.taskpool';

@Concurrent
function integrityCheckTask(nonce: string): Promise<string> {
  return checkSysIntegrityEnhanced(nonce);
}

async function executeIntegrityCheck(): Promise<void> {
  try {
    // 从服务器获取nonce
    const nonce = await getNonceFromServer();
    
    // 在TaskPool中执行检测
    const jwsResult = await taskpool.execute(integrityCheckTask, nonce);
    
    // 将结果发送到服务器验证
    await sendResultToServerForVerification(jwsResult, nonce);
    
  } catch (err) {
    hilog.error(0x0000, "IntegrityCheck", 'Failed: %{public}s', err.message);
  }
}
```

### 步骤3：错误处理

```typescript
// 错误处理代码
async function handleIntegrityCheckError(error: BusinessError): Promise<void> {
  const TAG = "IntegrityCheckError";
  const DOMAIN = 0x0000;
  
  switch (error.code) {
    case 801:
      // API不支持
      hilog.error(DOMAIN, TAG, 'API not supported on this device');
      // 降级处理：使用其他检测方案或跳过检测
      await fallbackToBasicCheck();
      break;
      
    case 1010800001:
      // 内部错误
      hilog.error(DOMAIN, TAG, 'Internal error: %{public}s', error.message);
      // 提示用户稍后重试
      showToast('检测服务暂时不可用，请稍后重试');
      break;
      
    case 1010800002:
      // 网络不可达
      hilog.error(DOMAIN, TAG, 'Network unreachable');
      showToast('请检查网络连接');
      break;
      
    case 1010800003:
      // 访问云服务失败
      hilog.error(DOMAIN, TAG, 'Failed to access cloud server');
      showToast('服务暂时不可用，请稍后重试');
      break;
      
    case 1010800004:
      // 验证能力失败
      hilog.error(DOMAIN, TAG, 'Verify capability failed');
      showToast('设备不支持此检测能力');
      break;
      
    case 1010800005:
      // 并发调用超限
      hilog.error(DOMAIN, TAG, 'Parallel calls exceed threshold');
      // 等待一段时间后重试
      await delay(1000);
      await retryIntegrityCheck();
      break;
      
    case 1010800006:
      // 调用频率超限
      hilog.error(DOMAIN, TAG, 'Invoking frequency exceeds threshold');
      showToast('操作过于频繁，请稍后再试');
      break;
      
    case 1010800007:
      // 操作超时
      hilog.error(DOMAIN, TAG, 'Operation timeout');
      showToast('检测超时，请重试');
      break;
      
    case 1010800008:
      // 云服务流量超限
      hilog.error(DOMAIN, TAG, 'Cloud service traffic exceeds threshold');
      showToast('服务已达上限，请联系管理员');
      break;
      
    default:
      hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d', error.code);
      showToast('检测失败，请稍后重试');
      break;
  }
}

// 辅助函数
async function fallbackToBasicCheck(): Promise<void> {
  // 使用基础的本地检测作为降级方案
  try {
    const result = await safetyDetect.checkSysIntegrityOnLocal();
    // 处理本地检测结果
  } catch (err) {
    hilog.error(0x0000, "Fallback", 'Local check also failed');
  }
}

function showToast(message: string): void {
  // 实现Toast提示
  hilog.info(0x0000, "Toast", message);
}

async function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function retryIntegrityCheck(): Promise<void> {
  // 实现重试逻辑
}
```

### 步骤4：服务端验证

```typescript
// 服务端验证代码示例（Node.js）
import * as crypto from 'crypto';
import * as jwt from 'jsonwebtoken';

interface JWSHeader {
  alg: string;
  typ: string;
  x5c: string[]; // 证书链
}

interface JWSPayload {
  hapCertificateSha256: string;
  hapBundleName: string;
  appId: string;
  basicIntegrity: boolean;
  version: number;
  detail?: string[]; // ['attack', 'jailbreak', 'emulator', 'unlock']
  nonce: string;
  timestamp: number;
}

class IntegrityResultVerifier {
  // 华为根证书（从华为官方获取）
  private readonly ROOT_CA_CERT = `-----BEGIN CERTIFICATE-----
MIICuzCCAmOgAwIBAgIJAKUAAAAAAAAAMA0GCSqGSIb3DQEBCwUAMB4xCzAJBgNV
...（省略证书内容）
-----END CERTIFICATE-----`;
  
  /**
   * 验证JWS格式的检测结果
   * @param jwsResult JWS格式的检测结果
   * @param expectedNonce 预期的nonce值
   * @param expectedBundleName 预期的应用包名
   * @param expectedAppId 预期的应用ID
   * @returns 验证结果
   */
  async verifyIntegrityResult(
    jwsResult: string,
    expectedNonce: string,
    expectedBundleName: string,
    expectedAppId: string
  ): Promise<{ isValid: boolean; payload?: JWSPayload; error?: string }> {
    try {
      // 1. 解析JWS
      const parts = jwsResult.split('.');
      if (parts.length !== 3) {
        return { isValid: false, error: 'Invalid JWS format' };
      }
      
      // 2. 解码Header和Payload
      const header: JWSHeader = JSON.parse(
        Buffer.from(parts[0], 'base64').toString('utf8')
      );
      const payload: JWSPayload = JSON.parse(
        Buffer.from(parts[1], 'base64').toString('utf8')
      );
      
      // 3. 验证证书链
      if (!header.x5c || header.x5c.length !== 3) {
        return { isValid: false, error: 'Invalid certificate chain' };
      }
      
      // 验证证书链是否包含3级证书
      const leafCert = `-----BEGIN CERTIFICATE-----\n${header.x5c[0]}\n-----END CERTIFICATE-----`;
      const intermediateCert = `-----BEGIN CERTIFICATE-----\n${header.x5c[1]}\n-----END CERTIFICATE-----`;
      const rootCert = `-----BEGIN CERTIFICATE-----\n${header.x5c[2]}\n-----END CERTIFICATE-----`;
      
      // 验证签名证书的Common Name
      const leafCertObj = new crypto.X509Certificate(leafCert);
      const cn = leafCertObj.subject.split('\n').find(s => s.includes('CN='));
      if (!cn || !cn.includes('Harmony OS Device Attestation Service')) {
        return { isValid: false, error: 'Invalid certificate CN' };
      }
      
      // 4. 验证签名
      const signature = Buffer.from(parts[2], 'base64');
      const dataToSign = `${parts[0]}.${parts[1]}`;
      
      // 使用叶子证书的公钥验证签名
      const isValidSignature = crypto.verify(
        'RSA-SHA256',
        Buffer.from(dataToSign),
        leafCertObj.publicKey,
        signature
      );
      
      if (!isValidSignature) {
        return { isValid: false, error: 'Invalid signature' };
      }
      
      // 5. 验证nonce值
      if (payload.nonce !== expectedNonce) {
        return { isValid: false, error: 'Nonce mismatch' };
      }
      
      // 6. 验证包名和应用ID
      if (payload.hapBundleName !== expectedBundleName) {
        return { isValid: false, error: 'Bundle name mismatch' };
      }
      
      if (payload.appId !== expectedAppId) {
        return { isValid: false, error: 'App ID mismatch' };
      }
      
      // 7. 验证时间戳（可选：检查是否过期）
      const now = Date.now();
      const maxAge = 10 * 60 * 1000; // 10分钟有效期
      if (now - payload.timestamp > maxAge) {
        return { isValid: false, error: 'Result expired' };
      }
      
      // 验证成功
      return { isValid: true, payload: payload };
      
    } catch (error) {
      return { isValid: false, error: `Verification failed: ${error.message}` };
    }
  }
  
  /**
   * 根据检测结果决定业务策略
   */
  evaluateRisk(payload: JWSPayload): {
    risk: 'high' | 'medium' | 'low';
    reasons: string[];
    suggestion: string;
  } {
    if (payload.basicIntegrity === true) {
      return {
        risk: 'low',
        reasons: [],
        suggestion: '设备环境安全，可以正常使用'
      };
    }
    
    const reasons: string[] = [];
    if (payload.detail) {
      if (payload.detail.includes('jailbreak')) {
        reasons.push('设备已越狱');
      }
      if (payload.detail.includes('emulator')) {
        reasons.push('设备为模拟器');
      }
      if (payload.detail.includes('attack')) {
        reasons.push('设备已被攻击');
      }
      if (payload.detail.includes('unlock')) {
        reasons.push('设备已解锁');
      }
    }
    
    // 根据风险类型评估等级
    if (payload.detail?.includes('attack') || payload.detail?.includes('jailbreak')) {
      return {
        risk: 'high',
        reasons: reasons,
        suggestion: '存在高风险，建议限制敏感操作'
      };
    } else if (payload.detail?.includes('emulator') || payload.detail?.includes('unlock')) {
      return {
        risk: 'medium',
        reasons: reasons,
        suggestion: '存在中等风险，建议谨慎操作'
      };
    } else {
      return {
        risk: 'medium',
        reasons: ['检测到未知风险'],
        suggestion: '建议谨慎操作'
      };
    }
  }
}

// 使用示例
const verifier = new IntegrityResultVerifier();
const result = await verifier.verifyIntegrityResult(
  jwsResult,
  expectedNonce,
  'com.example.myapp',
  '1234567890'
);

if (result.isValid) {
  const risk = verifier.evaluateRisk(result.payload);
  if (risk.risk === 'high') {
    // 限制高风险操作
    console.warn('High risk detected:', risk.reasons);
  }
} else {
  console.error('Verification failed:', result.error);
}
```

## 错误码说明

| 错误码 | 错误信息 | 说明 | 解决方法 |
|-------|---------|------|---------|
| 801 | API is not supported | API不支持 | 检查设备API版本是否>=6.0.0(20)，降级使用本地检测 |
| 1010800001 | Internal error | 内部错误 | 记录日志，提示用户稍后重试 |
| 1010800002 | The network is unreachable | 网络不可达 | 检查网络连接，提示用户开启网络 |
| 1010800003 | Access cloud server fail | 访问云服务失败 | 检查网络连接，稍后重试，检查服务状态 |
| 1010800004 | Verify capability fail | 验证能力失败 | 设备不支持此检测能力，使用其他检测方案 |
| 1010800005 | The number of calls exceeds the parallel threshold | 并发调用超限 | 减少并发调用数量，等待队列完成后重试 |
| 1010800006 | The invoking frequency exceeds the threshold | 调用频率超限 | 降低调用频率，实现调用限流机制 |
| 1010800007 | Operation timeout | 操作超时 | 检查网络状况，设置合理的超时时间并重试 |
| 1010800008 | The cloud service traffic exceeds the threshold | 云服务流量超限 | 联系管理员申请提升配额，优化调用策略 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "myapp",
  "version": "1.0.0",
  "dependencies": {
    "@kit.DeviceSecurityKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0",
    "@kit.PerformanceAnalysisKit": "^6.0.0"
  }
}
```

### 环境要求
- **HarmonyOS API版本**：>=6.0.0(20)
- **DevEco Studio版本**：>=4.0
- **设备类型**：Phone、Tablet、PC/2in1、Wearable
- **网络环境**：需要联网
- **服务配置**：已开通Device Security服务并配置Profile

### 常见编译问题

**问题1：找不到模块'@kit.DeviceSecurityKit'**
```
Error: Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：
- 确认HarmonyOS SDK版本>=6.0.0(20)
- 在`build-profile.json5`中配置正确的SDK版本
- 在DevEco Studio中：File > Settings > SDK > 检查SDK版本

**问题2：API版本不兼容**
```
Error: Property 'checkSysIntegrityEnhanced' does not exist on type 'typeof safetyDetect'
```
**解决方法**：
- 检查`build-profile.json5`中的`compileSdkVersion`是否>=20
- 检查设备的系统版本是否支持该API
- 使用条件编译或运行时检查API版本

**问题3：权限未配置**
```
Error: Permission denied
```
**解决方法**：
- 检查`module.json5`中是否配置了必要权限
- 确认已开通Device Security服务
- 确认已申请并配置正确的Profile

**问题4：在UI线程调用导致ANR**
```
Application Not Responding (ANR)
```
**解决方法**：
- 使用TaskPool或Worker在后台线程执行检测
- 参考示例代码中的`@Concurrent`装饰器和`taskpool.execute()`

## 常见问题与解决方法

### Q1：nonce值应该如何生成？
**原因**：nonce用于防重放攻击，必须确保唯一性和随机性。
**解决方法**：
- 从服务器端随机生成nonce，每次请求使用新值
- 使用加密安全的随机数生成器
- 确保长度在16-66字节之间
- 使用base64编码字符集（A-Z, a-z, 0-9, +, /, =）

### Q2：检测结果必须发送到服务器验证吗？
**原因**：客户端的检测结果可能被篡改，无法保证可信性。
**解决方法**：
- 必须将JWS结果发送到应用服务器验证签名
- 使用华为提供的根证书验证证书链
- 验证签名、nonce、时间戳、包名、appId等字段
- 参考示例代码中的`IntegrityResultVerifier`类

### Q3：如何处理检测失败的情况？
**原因**：检测可能因网络、服务、设备等各方面原因失败。
**解决方法**：
- 根据错误码进行分类处理
- 网络问题：提示用户检查网络，稍后重试
- 服务问题：记录日志，降级到本地检测或其他方案
- 频率限制：实现调用限流，引导用户等待
- 设备不支持：使用其他检测方案或提示用户

### Q4：检测结果显示设备有风险，应该如何处理？
**原因**：设备可能存在越狱、模拟器、攻击、解锁等风险。
**解决方法**：
- 根据业务场景评估风险等级
- 高风险操作（支付、转账等）：禁止或限制操作，提示用户
- 中风险操作：警告用户，记录日志，加强验证
- 低风险操作：允许操作，提示用户注意安全
- 不要直接阻止用户操作，提供友好的提示语

### Q5：调用频率超限怎么办？
**原因**：API有调用频率限制（每天1万次，每分钟5次，最多5个并发）。
**解决方法**：
- 实现本地调用限流机制，控制调用频率
- 使用本地缓存策略，避免重复检测
- 在关键业务节点调用，减少不必要的调用
- 实现队列机制，避免并发超限

### Q6：如何在多线程环境中使用？
**原因**：API涉及网络请求，不应在UI线程执行。
**解决方法**：
- 使用TaskPool在后台线程执行检测
- 使用Worker进行异步处理
- 参考示例代码中的`integrityCheckTask`
- 确保回调在正确的线程处理结果

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "apiUsed": [
    "safetyDetect.checkSysIntegrityEnhanced"
  ],
  "result": {
    "jws": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXUyIsIng1YyI6Wy...（JWS签名结果）",
    "basicIntegrity": false,
    "detail": ["jailbreak", "emulator"],
    "nonce": "imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs",
    "timestamp": 1604098577327,
    "hapBundleName": "com.example.myapp",
    "appId": "1234567890"
  },
  "verification": {
    "isValid": true,
    "riskLevel": "high",
    "riskReasons": ["设备已越狱", "设备为模拟器"]
  }
}
```

## 参考文档

- [API开发指南](references/devicesecurity-sysintegrityenhanced-check.md)
- [API参考说明](references/devicesecurity-safetydetectenhanced-api.md)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)

## 完整示例代码

- [ArkTS示例（TaskPool）](assets/example_arkts_taskpool.ets)
- [ArkTS示例（Worker）](assets/example_arkts_worker.ets)
- [服务端验证示例（Node.js）](assets/server_verification.js)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [正常检测流程](tests/test_positive.py)：在支持的设备上成功调用API并验证结果
- [nonce边界值测试](tests/test_positive.py)：测试16字节和66字节的nonce值
- [服务端签名验证](tests/test_positive.py)：验证JWS签名和服务端验证流程

### 边界测试用例
- [并发调用测试](tests/test_boundary.py)：测试5个并发调用
- [频率限制测试](tests/test_boundary.py)：测试每分钟5次的频率限制
- [网络超时测试](tests/test_boundary.py)：测试网络请求超时处理

### 异常测试用例
- [无效nonce测试](tests/test_exception.py)：测试长度不足或超长的nonce
- [网络异常测试](tests/test_exception.py)：测试无网络环境下的错误处理
- [API不支持测试](tests/test_exception.py)：测试在不支持的设备上的降级处理
- [签名验证失败测试](tests/test_exception.py)：测试篡改JWS结果的处理