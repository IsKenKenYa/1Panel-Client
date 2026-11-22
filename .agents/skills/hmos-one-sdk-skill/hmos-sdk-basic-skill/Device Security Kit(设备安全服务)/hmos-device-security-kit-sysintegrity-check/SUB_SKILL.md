---
name: hmos-device-security-kit-sysintegrity-check
description: 检测设备系统完整性，识别越狱/模拟器/攻击等风险，支持JWS签名验证，适用于风控、安全检测场景
---

# 系统完整性检测技能

## 功能描述

通过调用Device Security Kit的checkSysIntegrity接口获取系统完整性检测结果，用于判断设备环境是否安全，包括检测设备是否被越狱、是否为非真实设备（模拟器）、是否被攻击等风险状态。检测结果以JWS（JSON Web Signature）格式返回，需要在应用服务器端进行签名验证以确保结果不被篡改。

**核心能力**：
- 在线系统完整性检测（端云协同）
- 返回JWS格式签名结果，需服务器验证
- 支持检测越狱、模拟器、攻击等风险类型
- 提供basicIntegrity基础结果和detail详细风险分类

**适用设备**：Phone、Tablet、PC/2in1、Wearable（5.1.0(18)版本起）

**API版本**：5.0.0(12)起支持

## 使用场景

### 触发词
- "系统完整性检测"
- "设备安全检测"
- "越狱检测"
- "模拟器检测"
- "设备环境安全检测"
- "checkSysIntegrity"

### 能做
- 检测设备是否被越狱（jailbreak）
- 检测设备是否为模拟器（emulator）
- 检测设备是否被攻击（attack）
- 获取系统完整性综合评估结果（basicIntegrity）
- 生成带签名的检测结果供服务器验证
- 在业务关键操作前进行设备安全风险评估

### 绝不做
- 不提供本地离线完整性检测（需使用checkSysIntegrityOnLocal接口）
- 不直接判断是否允许业务操作（仅提供检测结果，业务决策由应用自行处理）
- 不替代其他安全措施（应作为整体安全方案的一部分）
- 不在UI线程执行检测（涉及网络耗时操作）

### 补充
- 每个应用在每个设备上每天最多调用1万次，每分钟最多5次
- 每个设备最多支持5个并发调用
- 需要在AppGallery Connect开通"安全检测服务"
- 需要申请Profile文件并配置到项目中
- nonce值必须为16-66字节，有效值为base64编码范围
- 建议每次请求从服务器生成新的nonce值以防重放攻击

## 调用规范和规则

### 输入约束
- nonce长度：16-66字节
- nonce字符：base64编码范围字符
- nonce来源：建议从服务器随机生成
- 设备要求：Phone、Tablet、PC/2in1、Wearable（5.1.0(18)+）
- 网络要求：需要网络连接（端云协同）

### 执行约束
- 最大耗时：网络请求可能耗时，需设置合理超时
- 并发限制：每个设备最多5个并发调用
- 频率限制：每个应用每设备每天最多1万次，每分钟最多5次
- 线程要求：禁止在UI线程执行，必须在后台线程执行
- 重试策略：网络失败时建议指数退避重试，最多3次

### 内容约束
- 禁止使用同步调用方式（必须使用async/await）
- 禁止在主线程直接调用
- 禁止缓存检测结果用于后续请求（每次业务请求应重新检测）
- 禁止忽略错误码直接使用结果

### 降级约束
- 网络失败（错误码1010800002）：提示用户检查网络后重试
- 服务器访问失败（错误码1010800003）：延迟后重试或使用本地检测
- 并发超限（错误码1010800005）：等待后重试
- 频率超限（错误码1010800006）：等待后重试
- 操作超时（错误码1010800007）：检查网络状况后重试
- 流量超限（错误码1010800008）：联系华为技术支持或次日重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置条件**：
1. 已在AppGallery Connect开通"安全检测服务"
2. 已申请并配置Profile文件
3. 项目已导入Device Security Kit模块

**参数准备**：
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SysIntegrityCheck";
const DOMAIN = 0x0000;

// 从服务器获取随机nonce值（推荐做法）
// nonce必须为16-66字节，base64编码字符
const nonce: string = 'imEe1PCRcjGkBCAhOCh6ImADztOZ8ygxlWRs'; // 示例值
```

### 步骤2：调用API

**基本示例代码**：
```typescript
async function checkSystemIntegrity(nonce: string): Promise<string> {
  const req: safetyDetect.SysIntegrityRequest = {
    nonce: nonce
  };
  
  try {
    hilog.info(DOMAIN, TAG, 'CheckSysIntegrity begin.');
    const response: safetyDetect.SysIntegrityResponse = 
      await safetyDetect.checkSysIntegrity(req);
    hilog.info(DOMAIN, TAG, 'Succeeded in checkSysIntegrity');
    return response.result;
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'CheckSysIntegrity failed: %{public}d %{public}s', 
                e.code, e.message);
    throw e;
  }
}
```

**完整检测流程示例**：
```typescript
interface IntegrityCheckResult {
  success: boolean;
  result?: string;
  errorCode?: number;
  errorMessage?: string;
}

async function performIntegrityCheck(nonce: string): Promise<IntegrityCheckResult> {
  // 参数校验
  if (!nonce || nonce.length < 16 || nonce.length > 66) {
    return {
      success: false,
      errorCode: 401,
      errorMessage: 'Invalid nonce length. Must be 16-66 bytes.'
    };
  }

  // 检测nonce是否为base64有效字符
  const base64Regex = /^[A-Za-z0-9+/=]+$/;
  if (!base64Regex.test(nonce)) {
    return {
      success: false,
      errorCode: 401,
      errorMessage: 'Invalid nonce format. Must be base64 encoded.'
    };
  }

  try {
    const req: safetyDetect.SysIntegrityRequest = { nonce };
    const response = await safetyDetect.checkSysIntegrity(req);
    
    return {
      success: true,
      result: response.result
    };
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    return {
      success: false,
      errorCode: e.code,
      errorMessage: e.message
    };
  }
}
```

### 步骤3：错误处理

```typescript
function handleIntegrityCheckError(errorCode: number): string {
  const errorMessages: Record<number, string> = {
    201: 'Permission denied. 请检查是否已开通安全检测服务。',
    401: 'Invalid parameters. 请检查nonce参数是否正确。',
    801: 'API is not supported. 当前设备不支持此API。',
    1010800001: 'Internal error. 内部错误，请稍后重试。',
    1010800002: 'The network is unreachable. 网络不可达，请检查网络连接。',
    1010800003: 'Access cloud server fail. 访问云服务失败，请稍后重试。',
    1010800005: 'The number of calls exceeds the parallel threshold. 并发调用超限，请等待后重试。',
    1010800006: 'The invoking frequency exceeds the threshold. 调用频率超限，请稍后重试。',
    1010800007: 'Operation timeout. 操作超时，请检查网络状况。',
    1010800008: 'The cloud service traffic exceeds the threshold. 云服务流量超限，请联系技术支持。'
  };
  
  return errorMessages[errorCode] || `Unknown error: ${errorCode}`;
}

async function safeIntegrityCheck(nonce: string): Promise<void> {
  try {
    const result = await performIntegrityCheck(nonce);
    if (result.success && result.result) {
      // 将JWS结果发送到服务器验证
      console.log('Integrity check result:', result.result);
    } else {
      console.error('Integrity check failed:', result.errorMessage);
    }
  } catch (error) {
    console.error('Unexpected error:', error);
  }
}
```

### 步骤4：服务器端验证JWS结果

**JWS结构说明**：
```
JWS格式：header.payload.signature
- header：包含签名算法(alg)、类型(typ)、证书链(x5c)
- payload：包含检测结果、nonce、timestamp等
- signature：对header.payload的签名
```

**Payload字段**：
```json
{
  "hapCertificateSha256": "应用签名证书SHA256",
  "hapBundleName": "应用包名",
  "appId": "应用ID",
  "basicIntegrity": false,
  "detail": ["attack", "jailbreak", "emulator"],
  "nonce": "请求时传入的nonce",
  "timestamp": 1604098577327
}
```

**服务器验证步骤**：
1. 解析JWS，获取header、payload、signature
2. 从header中获取证书链，使用[Huawei CBG Root CA G2](https://h5hosting-drcn.dbankcdn.cn/cch5/crl/pki_CA_RootG2Ca/RootG2Ca.cer)验证
3. 校验证书链包含3级证书，x5c[0]域名是否为sysintegrity.platform.hicloud.com
4. 使用证书链验证签名
5. 验证payload中的nonce是否与请求一致
6. 检查basicIntegrity和detail字段做业务决策

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 检查是否已在AppGallery Connect开通安全检测服务 |
| 401 | Invalid parameters | 检查nonce长度(16-66字节)和字符(base64编码范围) |
| 801 | API is not supported | 检查设备是否支持此API，需要HarmonyOS 5.0.0(12)+ |
| 1010800001 | Internal error | 内部错误，稍后重试或联系技术支持 |
| 1010800002 | The network is unreachable | 检查网络连接，确保设备可访问互联网 |
| 1010800003 | Access cloud server fail | 访问云服务失败，稍后重试 |
| 1010800005 | The number of calls exceeds the parallel threshold | 减少并发调用，每个设备最多5个并发 |
| 1010800006 | The invoking frequency exceeds the threshold | 降低调用频率，每天1万次/每分钟5次 |
| 1010800007 | Operation timeout | 检查网络状况，设置合理超时时间 |
| 1010800008 | The cloud service traffic exceeds the threshold | 云服务流量超限，联系华为技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.DeviceSecurityKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)或更高版本
- DevEco Studio：推荐最新版本
- 设备要求：Phone、Tablet、PC/2in1、Wearable（5.1.0(18)+）

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：确保HarmonyOS SDK版本>=5.0.0(12)，并在build-profile.json5中正确配置

**问题2：API不存在**
```
Property 'checkSysIntegrity' does not exist on type 'typeof safetyDetect'
```
**解决方法**：检查SDK版本是否满足要求，清理项目缓存后重新编译

**问题3：类型错误**
```
Type 'BusinessError' is not assignable to type 'Error'
```
**解决方法**：使用类型断言 `err as BusinessError`

## 常见问题与解决方法

### Q1：检测结果basicIntegrity为false，应该如何处理？
**原因**：设备存在安全风险（越狱、模拟器或攻击）
**解决方法**：
- 检查detail字段了解具体风险类型
- 根据业务安全要求决定是否阻断操作
- 可参考提示语："您的设备疑似存在风险或运行在不安全环境中，请谨慎使用此功能"
- 建议作为风险评估因素之一，不作为唯一判断依据

### Q2：调用返回1010800006错误（频率超限）
**原因**：调用频率超过限制
**解决方法**：
- 每个应用每设备每天最多1万次，每分钟最多5次
- 实现调用计数和限流机制
- 避免频繁重复检测，缓存结果需设置合理过期时间

### Q3：如何在服务器验证JWS签名？
**原因**：需要确保检测结果未被篡改
**解决方法**：
- 使用Huawei CBG Root CA G2证书验证签名
- 校验证书链和域名
- 验证nonce和timestamp防重放攻击
- 参考[Java示例代码](https://gitcode.com/HarmonyOS_Samples/device-security-kit-samplecode-safetydetect-serverdemo-java)

### Q4：nonce值如何生成？
**原因**：nonce用于防重放攻击
**解决方法**：
- 推荐从服务器随机生成
- 长度16-66字节
- 使用base64编码字符
- 每次请求使用新nonce，不重复使用

### Q5：检测结果是否可以在客户端直接使用？
**原因**：安全性考虑
**解决方法**：
- 客户端检测结果可能被篡改
- 必须在服务器验证JWS签名后使用
- 业务决策应在服务器端进行
- 客户端仅做展示提示，不作为关键业务判断依据

## 输出结果报告

执行完成后返回以下信息：

```json
{
  "status": "success|failed",
  "result": "JWS格式的检测结果字符串",
  "errorCode": 0,
  "errorMessage": "",
  "timestamp": "检测时间戳",
  "apiUsed": [
    "safetyDetect.checkSysIntegrity"
  ]
}
```

服务器验证后的完整结果：
```json
{
  "basicIntegrity": true|false,
  "detail": ["jailbreak", "emulator", "attack"],
  "nonce": "请求时的nonce值",
  "timestamp": 1604098577327,
  "hapBundleName": "应用包名",
  "appId": "应用ID",
  "hapCertificateSha256": "证书SHA256"
}
```

## 参考文档

- [系统完整性检测开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-sysintegrity-check)
- [SafetyDetect API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-safetydetectenhanced-api)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)
- [申请Profile](https://developer.huawei.com/consumer/cn/doc/app/agc-help-profile-0000002270709473)
- [JSON Web Signature规范](https://www.rfc-editor.org/rfc/rfc7515.html)
- [服务器验证示例代码](https://gitcode.com/HarmonyOS_Samples/device-security-kit-samplecode-safetydetect-serverdemo-java)

## 完整示例代码

- [ArkTS完整示例](assets/sysintegrity_check_example.ets) - 包含完整检测流程和错误处理
- [服务器验证示例](assets/server_verify_example.java) - Java服务器端JWS验证示例

## 测试用例

### 正向测试用例
- [正常检测流程](tests/test_positive.ets)：使用合法nonce调用检测接口，验证返回结果
- [多次调用测试](tests/test_positive.ets)：在频率限制内多次调用，验证稳定性

### 边界测试用例
- [nonce边界测试](tests/test_boundary.ets)：测试nonce长度16字节和66字节的边界情况
- [并发调用测试](tests/test_boundary.ets)：测试5个并发调用的限制

### 异常测试用例
- [无效nonce测试](tests/test_exception.ets)：测试空nonce、超长nonce、非base64字符
- [网络异常测试](tests/test_exception.ets)：模拟网络断开情况
- [频率超限测试](tests/test_exception.ets)：测试调用频率超限的错误处理
- [权限缺失测试](tests/test_exception.ets)：测试未开通服务时的错误处理