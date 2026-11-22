---
name: hmos-devicesecuritykit-queryriskfactors
description: 查询设备风控因子数据及安全证明，支持VPN状态、开发者模式、调试状态等12种风控因子查询，限制每分钟5次每天20次并发10个，适用于风控检测、安全评估场景
---

# 查询设备风控因子技能

## 功能描述

本技能提供统一的系统风控因子查询能力，通过queryRiskFactors接口获取设备风控因子数据及安全证明。支持查询VPN连接状态、开发者模式、HDC调试状态、ODID重置次数、屏幕获取状态等12种风控因子。返回JWS格式的安全证明数据，开发者可在应用服务器端验证结果完整性并基于风控因子数据进行风险控制。

**核心能力**：
- 统一风控因子查询接口，一次调用可获取多个风控因子数据
- 返回JWS格式的安全证明，确保数据完整性和防篡改
- 支持12种风控因子类型查询
- 提供nonce防重放攻击机制

**适用版本**：从API version 26.0.0开始支持

## 使用场景

### 触发词
- "查询风控因子"
- "获取设备风控数据"
- "统一风控凭证"
- "queryRiskFactors"
- "设备安全检测"
- "风控因子查询"

### 能做
- 查询VPN连接状态（IS_VPN_STATUS）
- 查询网络代理状态（IS_NET_PROXY_STATUS）
- 查询ODID重置次数（ODID_RESET_CNT）
- 查询当前应用ODID值（ODID）
- 查询开发者模式状态（IS_DEVELOPER_MODE）
- 查询HDC调试状态（HDC_DEBUG_STATE）
- 查询OOBE操作次数（OOBE_CNT）
- 查询SIM卡数量（SIM_CNT）
- 查询屏幕获取状态（IS_DISPLAY_CAPTURED）
- 查询前台窗口模式（GLOBAL_WINDOW_STATE）
- 查询电池充电状态（BATTERY_CHARGE_STATE）
- 查询电池健康状态（BATTERY_HEALTH_STATE）
- 查询通话状态（ON_CALL_STATE）
- 在应用服务器端验证JWS签名和数据完整性

### 绝不做
- 不在UI线程中调用queryRiskFactors接口（会阻塞UI响应）
- 不使用少于16字节或超过66字节的nonce值
- 不跳过JWS签名验证直接使用返回数据
- 不跳过证书链验证
- 不在调用频次超限情况下强制调用
- 不处理超出Device Security Kit范围的安全检测

### 补充
- 支持Phone、Tablet、PC/2in1设备
- 每分钟最多调用5次，每天最多20次，最多10个并发调用
- 必须已开通"安全检测服务"开关并申请Profile
- queryRiskFactors接口涉及多项数据采集及网络请求等耗时操作
- 需要在开发者应用服务器中验证JWS签名和证书链

## 调用规范和规则

### 输入约束
- nonce值长度：16至66字节之间
- nonce值有效范围：base64编码范围
- queries数组：最多包含12种风控因子类型
- nonce生成方式：推荐每次请求从服务器随机生成新的nonce值

### 执行约束
- 调用频次限制：每分钟最多5次
- 调用频次限制：每天最多20次
- 并发调用限制：最多10个并发调用
- 执行线程：必须在非UI线程中调用（如TaskPool、Worker线程）
- 最大耗时：涉及网络请求和多项数据采集，预计耗时数秒

### 内容约束
- 禁止生成：虚假的风控因子数据、伪造的JWS签名
- 禁止操作：跳过签名验证、跳过证书链验证、跳过appId校验
- 禁止使用高危函数：eval、exec等动态执行函数

### 降级约束
- 网络失败：提示用户检查网络连接，使用本地缓存的风控因子数据（如有）
- 调用频次超限：提示用户稍后再试，使用上次查询结果（需验证时效性）
- 并发超限：等待其他调用完成后再尝试，或降级为本地简单检测
- JWS验证失败：不使用返回数据，提示用户设备安全状态未知，建议谨慎操作

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已开通"安全检测服务"开关
2. 确认已申请Profile
3. 确认设备类型为Phone、Tablet或PC/2in1
4. 确认API版本≥26.0.0
5. 确认当前调用频次未超限（每分钟<5次，每天<20次，并发<10个）

**参数准备**：
```typescript
// 准备nonce值（从服务器随机生成）
const nonce: string = generateNonceFromServer(); // 16-66字节的base64字符串

// 准备查询的风控因子列表
const queries: Array<safetyDetect.RiskFactorQuery> = [
    { factor: safetyDetect.RiskFactorType.HDC_DEBUG_STATE },
    { factor: safetyDetect.RiskFactorType.IS_DEVELOPER_MODE },
    { factor: safetyDetect.RiskFactorType.ODID_RESET_CNT }
];

// 构造请求参数
const request: safetyDetect.RiskFactorRequest = {
    nonce: nonce,
    queries: queries
};
```

### 步骤2：导入模块并调用API

**导入模块**：
```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**调用queryRiskFactors接口**：
```typescript
const TAG = "RiskFactorsQuery";
const DOMAIN = 0x0000;

async function queryRiskFactors(request: safetyDetect.RiskFactorRequest): Promise<safetyDetect.RiskFactorResponse> {
    try {
        hilog.info(DOMAIN, TAG, 'QueryRiskFactors begin.');
        
        // 在非UI线程中调用接口
        const response: safetyDetect.RiskFactorResponse = await safetyDetect.queryRiskFactors(request);
        
        hilog.info(DOMAIN, TAG, 'Succeeded in QueryRiskFactors: %{public}s', response.result);
        
        return response;
    } catch (err) {
        let e: BusinessError = err as BusinessError;
        hilog.error(DOMAIN, TAG, 'QueryRiskFactors failed: %{public}d %{public}s', e.code, e.message);
        throw e;
    }
}
```

**完整调用示例**：
```typescript
// 导入必要模块
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SafetyDetectJsTest";
const DOMAIN = 0x0000;

// 请求风控因子数据
const request: safetyDetect.RiskFactorRequest = {
    nonce: 'a1b2c3d4e5f6g7hfsdfxvsdae8', // 16-66字节的防重放随机数
    queries: [
        { factor: safetyDetect.RiskFactorType.HDC_DEBUG_STATE },
        { factor: safetyDetect.RiskFactorType.IS_DEVELOPER_MODE },
        { factor: safetyDetect.RiskFactorType.ODID_RESET_CNT }
    ]
};

try {
    hilog.info(DOMAIN, TAG, 'QueryRiskFactors begin.');
    const response: safetyDetect.RiskFactorResponse = await safetyDetect.queryRiskFactors(request);
    hilog.info(DOMAIN, TAG, 'Succeeded in QueryRiskFactors: %{public}s', response.result);
} catch (err) {
    let e: BusinessError = err as BusinessError;
    hilog.error(DOMAIN, TAG, 'QueryRiskFactors failed: %{public}d %{public}s', e.code, e.message);
}
```

### 步骤3：错误处理

```typescript
try {
    const response = await queryRiskFactors(request);
    // 处理成功结果
    await verifyAndProcessRiskFactors(response.result);
} catch (err) {
    let e: BusinessError = err as BusinessError;
    
    switch (e.code) {
        case 201:
            hilog.error(DOMAIN, TAG, 'Permission denied. 请检查权限配置');
            // 提示用户权限不足
            break;
        case 401:
            hilog.error(DOMAIN, TAG, 'Invalid parameters. 请检查参数格式');
            // 检查nonce长度和queries数组
            break;
        case 801:
            hilog.error(DOMAIN, TAG, 'API is not supported. 当前API版本不支持');
            // 提示用户升级API版本
            break;
        case 1010800001:
            hilog.error(DOMAIN, TAG, 'Internal error. 内部错误');
            // 建议用户重启应用或稍后再试
            break;
        case 1010800002:
            hilog.error(DOMAIN, TAG, 'The network is unreachable. 网络不可达');
            // 提示用户检查网络连接
            break;
        case 1010800003:
            hilog.error(DOMAIN, TAG, 'Access cloud server fail. 云服务访问失败');
            // 提示用户稍后再试
            break;
        case 1010800005:
            hilog.error(DOMAIN, TAG, 'The number of calls exceeds the parallel threshold. 并发超限');
            // 等待其他调用完成后再尝试
            break;
        case 1010800006:
            hilog.error(DOMAIN, TAG, 'The invoking frequency exceeds the threshold. 调用频次超限');
            // 提示用户稍后再试
            break;
        case 1010800007:
            hilog.error(DOMAIN, TAG, 'Operation timeout. 操作超时');
            // 检查网络状态或使用降级方案
            break;
        case 1010800008:
            hilog.error(DOMAIN, TAG, 'The cloud service traffic exceeds the threshold. 云服务流量超限');
            // 提示用户稍后再试
            break;
        default:
            hilog.error(DOMAIN, TAG, 'Unknown error: %{public}d %{public}s', e.code, e.message);
            // 使用降级方案
            break;
    }
}
```

### 步骤4：服务器端JWS验证

**解析JWS字符串**：
```typescript
function parseJWS(jwsString: string): { header: object, payload: object, signature: string } {
    const parts = jwsString.split('.');
    if (parts.length !== 3) {
        throw new Error('Invalid JWS format');
    }
    
    // Base64URL解码
    const header = JSON.parse(base64UrlDecode(parts[0]));
    const payload = JSON.parse(base64UrlDecode(parts[1]));
    const signature = parts[2];
    
    return { header, payload, signature };
}

function base64UrlDecode(str: string): string {
    // Base64URL解码实现
    // 注意：Base64URL使用'-'和'_'替代'+'和'/'
    let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
    // 添加填充字符
    while (base64.length % 4) {
        base64 += '=';
    }
    return atob(base64);
}
```

**验证证书链**：
```typescript
async function verifyCertificateChain(x5c: Array<string>): Promise<boolean> {
    // 1. 验证证书链包含3级证书
    if (x5c.length !== 3) {
        throw new Error('Certificate chain must contain 3 certificates');
    }
    
    // 2. 验证x5c[0]证书Common Name是否为"Harmony OS Device Attestation Service"
    const leafCert = parseCertificate(x5c[0]);
    if (leafCert.commonName !== 'Harmony OS Device Attestation Service') {
        throw new Error('Invalid leaf certificate CN');
    }
    
    // 3. 使用Root CA证书验证证书链
    const rootCACert = await loadRootCACert(); // 从 https://pki.consumer.huawei.com/ca/cer/Huawei_CBG_ECC_Device_Attestation_Root_CA.cer 加载
    const isValid = await verifyCertChain(x5c, rootCACert);
    
    return isValid;
}
```

**验证签名和Payload**：
```typescript
async function verifyJWS(jwsString: string): Promise<object> {
    const { header, payload, signature } = parseJWS(jwsString);
    
    // 1. 验证证书链
    const x5c = header.x5c as Array<string>;
    await verifyCertificateChain(x5c);
    
    // 2. 验证签名
    const publicKey = extractPublicKeyFromCert(x5c[0]);
    const isValidSignature = verifySignature(
        header,
        payload,
        signature,
        publicKey,
        header.alg // 'ES256'
    );
    
    if (!isValidSignature) {
        throw new Error('Invalid JWS signature');
    }
    
    // 3. 校验appId是否正确
    if (payload.appId !== getCurrentAppId()) {
        throw new Error('Invalid appId in payload');
    }
    
    // 4. 校验nonce值与请求时传入的一致
    if (payload.nonce !== requestNonce) {
        throw new Error('Nonce mismatch');
    }
    
    // 5. 校验时间戳（可选，防重放攻击）
    const timestamp = payload.timestamp;
    const currentTime = Date.now();
    if (currentTime - timestamp > MAX_TIMESTAMP_DIFF) {
        throw new Error('Timestamp too old');
    }
    
    return payload;
}
```

### 步骤5：降级处理

```typescript
async function fallbackRiskFactorsDetection(): Promise<void> {
    try {
        // 降级方案1：使用本地简单检测
        hilog.warn(DOMAIN, TAG, 'Using local simple detection as fallback');
        
        // 可根据业务需求实现本地简单检测逻辑
        // 例如：检查开发者模式设置、检查USB调试状态等
        
        // 降级方案2：提示用户稍后再试
        hilog.warn(DOMAIN, TAG, 'Network or service unavailable, please try again later');
        
        // 降级方案3：使用上次缓存的风控因子结果（需验证时效性）
        const cachedResult = getCachedRiskFactors();
        if (cachedResult && isResultValid(cachedResult)) {
            hilog.info(DOMAIN, TAG, 'Using cached risk factors result');
            await processRiskFactorsData(cachedResult);
        }
    } catch (error) {
        hilog.error(DOMAIN, TAG, 'Fallback detection failed: %{public}s', error.message);
        // 最终降级：提示用户设备安全状态未知
        showSecurityWarningToUser();
    }
}
```

## 支持的风控因子项

| 风控因子枚举 | 因子类型 | 结果说明 |
| --- | --- | --- |
| IS_VPN_STATUS | boolean | VPN连接状态。true：已连接VPN；false：未连接VPN |
| IS_NET_PROXY_STATUS | boolean | 网络代理状态。true：已设置代理；false：未设置代理 |
| ODID_RESET_CNT | number | 当前应用ODID重置次数 |
| ODID | string | 当前应用的ODID值 |
| IS_DEVELOPER_MODE | boolean | 开发者模式状态。true：已开启开发者模式；false：未开启开发者模式 |
| HDC_DEBUG_STATE | number | HDC调试状态。返回值按位或运算结果：0：未处于调试模式；1(1<<0)：处于USB调试模式；2(1<<1)：处于Wi-Fi调试模式；值为3时表示同时处于USB和Wi-Fi调试模式 |
| OOBE_CNT | number | 当前设备OOBE操作次数 |
| SIM_CNT | number | 当前设备插入的SIM卡数量 |
| IS_DISPLAY_CAPTURED | boolean | 屏幕获取状态（录屏、投屏、屏幕共享）。true：正在被获取；false：未被获取 |
| GLOBAL_WINDOW_STATE | number | 前台窗口模式。返回值为按位或运算结果：1(1<<0)：FULLSCREEN（全屏窗口）；2(1<<1)：SPLIT（分屏窗口）；4(1<<2)：FLOAT（悬浮窗）；8(1<<3)：PIP（画中画）；可通过多个值按位或运算获取当前窗口模式组合 |
| BATTERY_CHARGE_STATE | number | 电池充电状态。0：未充电（NONE）；1：使能状态（ENABLE）；2：停止状态（DISABLE）；3：已充满（FULL） |
| BATTERY_HEALTH_STATE | number | 电池健康状态。0：未知（UNKNOWN）；1：正常（GOOD）；2：过热（OVERHEAT）；3：过压（OVERVOLTAGE）；4：低温（COLD）；5：僵死状态（DEAD） |
| ON_CALL_STATE | number | 通话状态。0：未通话；1：语音通话中；2：视频通话中；当前只覆盖运营商通话 |

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied. 权限被拒绝 | 检查是否已开通"安全检测服务"开关，是否申请了Profile，检查权限配置 |
| 401 | Invalid parameters. 参数无效 | 检查nonce长度是否在16-66字节之间，检查nonce是否为base64编码范围，检查queries数组格式 |
| 801 | API is not supported. API不支持 | 确认API版本≥26.0.0，检查设备是否支持此API |
| 1010800001 | Internal error. 内部错误 | 重启应用或稍后再试，检查日志获取详细错误信息 |
| 1010800002 | The network is unreachable. 网络不可达 | 检查网络连接状态，提示用户检查网络设置，使用降级方案 |
| 1010800003 | Access cloud server fail. 云服务访问失败 | 稍后再试，检查云服务状态，使用降级方案 |
| 1010800005 | The number of calls exceeds the parallel threshold. 并发调用超限 | 等待其他调用完成后再尝试，控制并发调用数量≤10个 |
| 1010800006 | The invoking frequency exceeds the threshold. 调用频次超限 | 控制调用频次：每分钟≤5次，每天≤20次 |
| 1010800007 | Operation timeout. 操作超时 | 检查网络状态，稍后再试，使用降级方案 |
| 1010800008 | The cloud service traffic exceeds the threshold. 云服务流量超限 | 稍后再试，控制调用频次 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.DeviceSecurityKit": "^26.0.0",
    "@kit.BasicServicesKit": "^26.0.0",
    "@kit.PerformanceAnalysisKit": "^26.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version: ≥26.0.0
- 设备类型: Phone、Tablet、PC/2in1
- DevEco Studio: ≥5.0
- Node.js: ≥14.0.0

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：
- 确认HarmonyOS API版本≥26.0.0
- 在module.json5中添加依赖声明
- 检查DevEco Studio版本是否≥5.0

**问题2：API不存在**
```
Error: Property 'queryRiskFactors' does not exist on type 'safetyDetect'
```
**解决方法**：
- 确认API版本≥26.0.0
- 更新SDK到最新版本
- 检查设备是否支持此API

**问题3：权限配置错误**
```
Error: Permission denied
```
**解决方法**：
- 确认已开通"安全检测服务"开关
- 确认已申请Profile
- 在module.json5中配置必要权限

**问题4：UI线程阻塞**
```
Error: Cannot call async API on UI thread
```
**解决方法**：
- 在TaskPool或Worker线程中调用queryRiskFactors
- 使用async/await确保异步调用
- 不要在主线程中直接调用

## 常见问题与解决方法

### Q1：nonce值生成有什么要求？
**原因**：nonce值用于防重放攻击，必须满足特定格式要求
**解决方法**：
- nonce长度必须在16至66字节之间
- nonce值必须为base64编码范围（A-Za-z0-9+/）
- 推荐每次请求从服务器随机生成新的nonce值
- 不要重复使用同一个nonce值

### Q2：为什么不能在UI线程调用？
**原因**：queryRiskFactors涉及多项数据采集及网络请求等耗时操作
**解决方法**：
- 使用TaskPool线程池执行调用
- 使用Worker线程执行调用
- 使用async/await确保异步调用
- 在调用前检查是否在UI线程，如是在则切换到后台线程

### Q3：JWS验证失败怎么办？
**原因**：签名验证失败可能是证书链问题、签名算法问题或数据被篡改
**解决方法**：
- 检查证书链是否包含3级证书
- 验证x5c[0]证书CN是否为"Harmony OS Device Attestation Service"
- 使用正确的Root CA证书验证证书链
- 检查签名算法是否为ES256
- 验证appId是否正确
- 验证nonce是否与请求一致
- 验证时间戳是否在有效范围内

### Q4：调用频次超限如何处理？
**原因**：API调用频次限制：每分钟5次、每天20次、并发10个
**解决方法**：
- 控制调用频次，记录调用次数和时间戳
- 使用调用队列管理并发请求
- 当频次超限时，提示用户稍后再试
- 使用本地缓存的风控因子结果（需验证时效性）
- 实现降级方案，如本地简单检测

### Q5：如何解析风控因子结果？
**原因**：JWS Payload中的风控因子结果为JSON格式，每个因子包含status和result字段
**解决方法**：
- 解析JWS Payload获取风控因子JSON数据
- 根据风控因子类型（boolean/number/string）解析result字段
- 检查status字段：0表示成功获取数据，-1表示获取数据失败
- 对于按位或运算的数值（如HDC_DEBUG_STATE、GLOBAL_WINDOW_STATE），需按位解析
- 参考支持的风控因子项表格了解每个因子的具体含义

### Q6：如何实现防重放攻击？
**原因**：需要确保请求的唯一性和时效性
**解决方法**：
- 每次请求使用服务器随机生成的新nonce值
- 在服务器端验证返回的nonce与请求的nonce一致
- 验证JWS中的timestamp时间戳，确保请求时效性（建议设置最大时间差，如5分钟）
- 记录已使用的nonce值，拒绝重复的nonce请求
- 实现nonce过期机制，超过一定时间的nonce视为无效

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "apiUsed": [
    "queryRiskFactors"
  ],
  "riskFactors": {
    "nonce": "a1b2c3d4e5f6g7hfsdfxvsdae8",
    "timestamp": 1776911534738,
    "appId": "xxx",
    "factors": {
      "HDC_DEBUG_STATE": {
        "status": 0,
        "result": "0"
      },
      "IS_DEVELOPER_MODE": {
        "status": 0,
        "result": "false"
      },
      "ODID_RESET_CNT": {
        "status": 0,
        "result": "1"
      }
    }
  },
  "jwsVerified": true,
  "certificateChainValid": true,
  "signatureValid": true,
  "appIdValid": true,
  "nonceValid": true
}
```

## 参考文档

- [API开发指南 - 统一风控凭证](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-safetydetect-queryriskfactors)
- [API参考说明 - SafetyDetect增强](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/devicesecurity-safetydetectenhanced-api)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)
- [JSON Web Signature规范](https://www.rfc-editor.org/rfc/rfc7515.html)
- [Root CA证书](https://pki.consumer.huawei.com/ca/cer/Huawei_CBG_ECC_Device_Attestation_Root_CA.cer)

## 完整示例代码

- [ArkTS示例代码](assets/example_queryriskfactors.ets)
- [JWS验证示例](assets/jws_verification.ts)
- [服务器端验证示例](assets/server_verification.ts)
- [降级处理示例](assets/fallback_handler.ts)

## 测试用例

### 正向测试用例
- [测试正常查询风控因子](tests/test_positive.py)：测试正常调用queryRiskFactors并验证返回结果
- [测试多因子查询](tests/test_multiple_factors.py)：测试查询多个风控因子类型
- [测试JWS验证](tests/test_jws_verification.py)：测试JWS签名和证书链验证

### 边界测试用例
- [测试nonce长度边界](tests/test_nonce_boundary.py)：测试nonce长度16字节和66字节的边界情况
- [测试调用频次边界](tests/test_frequency_boundary.py)：测试每分钟5次和每天20次的调用频次边界
- [测试并发调用边界](tests/test_concurrency_boundary.py)：测试10个并发调用的边界情况

### 异常测试用例
- [测试nonce长度错误](tests/test_invalid_nonce.py)：测试nonce长度小于16字节或大于66字节
- [测试权限不足](tests/test_permission_denied.py)：测试未开通安全检测服务的情况
- [测试网络失败](tests/test_network_failure.py)：测试网络不可达或云服务访问失败的情况
- [测试频次超限](tests/test_frequency_exceeded.py)：测试调用频次超限的情况
- [测试并发超限](tests/test_concurrency_exceeded.py)：测试并发调用超限的情况
- [测试JWS验证失败](tests/test_jws_verification_failure.py)：测试签名验证、证书链验证失败的情况