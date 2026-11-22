---
name: hmos-device-security-kit-local-sysintegrity-check
description: 检测设备本地系统完整性，判断是否越狱、模拟器或被攻击，支持Phone/Tablet/PC/2in1/Wearable设备，适用于安全验证场景
---

# 本地系统完整性检测技能

## 功能描述

本技能实现HarmonyOS设备的本地系统完整性检测功能，通过调用Device Security Kit的`checkSysIntegrityOnLocal`接口，在不接入服务端的情况下获取系统完整性检测结果。检测结果以JSON格式返回，包含系统完整性状态和详细风险分类信息。

**核心能力**：
- 检测设备是否越狱（jailbreak）
- 检测设备是否为模拟器（emulator）
- 检测设备是否被攻击（attack）
- 检测设备是否被解锁（unlock）

**适用场景**：
- 金融应用的设备安全验证
- 支付场景的设备环境检测
- 敏感操作前的安全校验
- 离线场景下的设备安全评估

## 使用场景

### 触发词
- "本地系统完整性检测"
- "检测设备是否越狱"
- "检测设备是否为模拟器"
- "检测设备安全状态"
- "离线设备安全检测"
- "checkSysIntegrityOnLocal"

### 能做
- 在不联网的情况下检测设备系统完整性
- 判断设备是否被越狱、是否为模拟器
- 判断设备是否被攻击或解锁
- 返回JSON格式的检测结果和风险详情
- 根据检测结果进行业务逻辑处理

### 绝不做
- 不执行在线系统完整性检测（使用checkSysIntegrity接口）
- 不检测URL威胁（使用checkUrlThreat接口）
- 不执行增强的系统完整性检测（使用checkSysIntegrityEnhanced接口）
- 不替代服务端安全验证
- 不处理超出Device Security Kit范围的请求

### 补充
- 本地检测结果可能存在误报，建议结合其他安全措施降低风险
- 不建议将检测结果作为判断设备安全的唯一依据
- 仅在无法接入服务端的场景下使用本地检测
- 检测结果为false时，应根据风险分类决定是否提醒用户

## 调用规范和规则

### 输入约束
- 无需输入参数
- 仅支持Phone、Tablet、PC/2in1、Wearable设备
- 需要开通"安全检测服务"并申请Profile

### 执行约束
- 最大耗时：5秒
- 最大并发数：5个并发调用（设备级别）
- 调用频率限制：每个应用每天最多1万次，每分钟最多5次
- 支持设备：Phone、Tablet、PC/2in1、Wearable
- API版本要求：5.1.0(18)及以上

### 内容约束
- 禁止将检测结果作为唯一安全依据
- 禁止忽略检测结果中的风险提示
- 禁止在UI线程中调用该接口
- 返回结果必须使用try-catch捕获异常

### 降级约束
- API不支持（错误码801）：提示设备不支持此功能，建议升级系统版本
- 内部错误（错误码1010800001）：优先重试，失败后降级为跳过安全检测并记录日志
- 校验capability失败（错误码1010800004）：提示用户开通安全检测服务
- 调用超限（错误码1010800005/1010800006）：延迟重试或等待下一统计周期
- 操作超时（错误码1010800007）：延迟重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已开通Device Security Kit的"安全检测服务"
2. 确认已申请Profile并配置签名文件
3. 确认API版本为5.1.0(18)及以上
4. 确认不在UI线程中调用

**权限配置**：
无需额外权限配置

### 步骤2：调用API

**示例代码**：

```typescript
import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = "SysIntegrityCheck";

async function checkLocalSysIntegrity(): Promise<void> {
  try {
    hilog.info(0x0000, TAG, 'CheckSysIntegrityOnLocal begin.');
    
    const result: string = await safetyDetect.checkSysIntegrityOnLocal();
    
    hilog.info(0x0000, TAG, 'Succeeded in checkSysIntegrityOnLocal: %{public}s', result);
    
    const integrityResult = JSON.parse(result);
    if (integrityResult.basicIntegrity === false) {
      hilog.warn(0x0000, TAG, 'Device integrity check failed, risks: %{public}s', 
        JSON.stringify(integrityResult.detail));
      
      // 处理风险检测结果
      handleIntegrityRisk(integrityResult.detail);
    } else {
      hilog.info(0x0000, TAG, 'Device integrity check passed.');
    }
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(0x0000, TAG, 'CheckSysIntegrityOnLocal failed: %{public}d %{public}s', 
      e.code, e.message);
    
    // 错误处理
    handleCheckError(e.code, e.message);
  }
}

function handleIntegrityRisk(risks: string[]): void {
  const riskMessages: { [key: string]: string } = {
    'jailbreak': '设备已被越狱',
    'emulator': '设备为模拟器',
    'attack': '设备被攻击',
    'unlock': '设备被解锁'
  };
  
  const messages = risks.map(risk => riskMessages[risk] || risk).join('、');
  hilog.warn(0x0000, TAG, '您的设备疑似存在风险或运行在不安全环境中，请谨慎使用此功能。风险项：%{public}s', messages);
}

function handleCheckError(code: number, message: string): void {
  switch (code) {
    case 801:
      hilog.error(0x0000, TAG, 'API is not supported on this device.');
      break;
    case 1010800001:
      hilog.error(0x0000, TAG, 'Internal error, please retry.');
      break;
    case 1010800004:
      hilog.error(0x0000, TAG, 'Security detection service is not enabled.');
      break;
    case 1010800005:
      hilog.error(0x0000, TAG, 'Too many concurrent calls, please retry later.');
      break;
    case 1010800006:
      hilog.error(0x0000, TAG, 'Calling frequency exceeds threshold.');
      break;
    case 1010800007:
      hilog.error(0x0000, TAG, 'Operation timeout, please retry.');
      break;
    default:
      hilog.error(0x0000, TAG, 'Unknown error: %{public}d %{public}s', code, message);
  }
}

// 调用示例
checkLocalSysIntegrity();
```

### 步骤3：处理检测结果

**检测结果格式**：

```json
{
  "basicIntegrity": false,
  "detail": [
    "attack",
    "jailbreak",
    "emulator"
  ]
}
```

**字段说明**：
- `basicIntegrity`：布尔值，true表示系统完整性检测通过，false表示存在风险
- `detail`：字符串数组，当basicIntegrity为false时返回，包含风险分类：
  - `jailbreak`：设备被越狱
  - `emulator`：非真实设备
  - `attack`：设备被攻击
  - `unlock`：设备被解锁

### 步骤4：降级处理

```typescript
async function checkWithFallback(): Promise<void> {
  try {
    const result = await safetyDetect.checkSysIntegrityOnLocal();
    // 正常处理结果
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    
    if (e.code === 801) {
      // API不支持，降级为跳过检测
      hilog.warn(0x0000, TAG, 'Device integrity check not supported, skipping check.');
      // 继续业务流程
    } else if (e.code === 1010800005 || e.code === 1010800006) {
      // 调用超限，延迟重试
      hilog.warn(0x0000, TAG, 'Rate limit exceeded, retrying in 1 second.');
      await new Promise(resolve => setTimeout(resolve, 1000));
      // 可以重试或跳过检测
    } else {
      // 其他错误，记录日志并继续业务流程
      hilog.error(0x0000, TAG, 'Integrity check failed, but continuing operation: %{public}d', e.code);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 801 | API不支持 | 设备不支持此功能，建议升级系统版本或跳过检测 |
| 1010800001 | 内部异常 | 优先重试，若重试失败则通过在线提单申请帮助 |
| 1010800004 | 校验capability失败 | 开通"安全检测服务"并重新申请Profile |
| 1010800005 | 调用数量超过并行阈值 | 延迟重试（建议延迟1秒） |
| 1010800006 | 调用频率超过阈值 | 控制调用次数，等待下一统计周期 |
| 1010800007 | 操作超时 | 重新发起请求 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.DeviceSecurityKit": "^5.1.0",
    "@kit.PerformanceAnalysisKit": "^5.1.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：5.1.0(18)及以上
- 设备类型：Phone、Tablet、PC/2in1、Wearable
- 开发工具：DevEco Studio 5.1.0及以上

### 常见编译问题

**问题1：找不到DeviceSecurityKit模块**
```
Error: Cannot find module '@kit.DeviceSecurityKit'
```
**解决方法**：确保项目的compileSdkVersion不低于API 12，并在build-profile.json5中配置正确的SDK版本。

**问题2：类型定义错误**
```
Error: Property 'checkSysIntegrityOnLocal' does not exist on type 'typeof safetyDetect'
```
**解决方法**：确认API版本为5.1.0(18)及以上，低于此版本不支持本地检测功能。

**问题3：签名配置错误**
```
Error: The signature is invalid
```
**解决方法**：
1. 在AppGallery Connect开通"安全检测服务"
2. 重新申请Profile并配置签名文件

## 常见问题与解决方法

### Q1：检测结果为false但设备实际安全
**原因**：本地检测存在一定误报率
**解决方法**：
- 不将检测结果作为唯一安全依据
- 结合其他安全措施降低风险
- 可使用在线检测接口`checkSysIntegrity`获取更准确结果

### Q2：提示"校验capability失败"
**原因**：未开通"安全检测服务"或Profile未更新
**解决方法**：
- 在AppGallery Connect开通"安全检测服务"
- 重新申请Profile并配置到工程签名文件

### Q3：调用频率超限
**原因**：单位时间内调用次数超过阈值（每分钟5次）
**解决方法**：
- 控制调用频率，避免频繁调用
- 使用缓存机制，避免重复检测
- 等待下一统计周期再调用

### Q4：API不支持（错误码801）
**原因**：设备系统版本过低或设备类型不支持
**解决方法**：
- 检查设备系统版本是否为5.1.0(18)及以上
- 检查设备类型是否支持（Phone/Tablet/PC/2in1/Wearable）
- 降级处理，跳过安全检测继续业务流程

### Q5：如何区分不同风险类型？
**原因**：需要根据不同风险类型采取不同策略
**解决方法**：
- jailbreak（越狱）：提示用户设备存在安全风险
- emulator（模拟器）：拒绝敏感操作或提示用户
- attack（被攻击）：建议用户使用其他安全设备
- unlock（被解锁）：根据业务场景决定是否继续操作

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "basicIntegrity": true/false,
  "risks": ["jailbreak", "emulator", "attack", "unlock"],
  "apiUsed": [
    "safetyDetect.checkSysIntegrityOnLocal"
  ],
  "timestamp": "2026-07-04T15:30:00Z"
}
```

## 参考文档

- [API开发指南：本地系统完整性检测](references/devicesecurity-sysintegrity-check-onlocal.md)
- [API参考：SafetyDetect](references/devicesecurity-safetydetectenhanced-api.md)
- [错误码说明：SafetyDetect](references/devicesecurity-arktsapi-errcode-safetydetect.md)
- [开通Device Security服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-activateservice)

## 完整示例代码

- [ArkTS完整示例](assets/local_sysintegrity_check.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [正常场景：检测真实设备](tests/test_positive.ts)：测试在真实设备上调用接口
- [安全设备检测](tests/test_positive.ts)：测试系统完整性检测通过的设备

### 边界测试用例
- [模拟器设备检测](tests/test_boundary.ts)：测试在模拟器上调用接口
- [并发调用测试](tests/test_boundary.ts)：测试5个并发调用场景
- [频率限制测试](tests/test_boundary.ts)：测试每分钟5次调用限制

### 异常测试用例
- [未开通服务场景](tests/test_exception.ts)：测试未开通安全检测服务时的错误处理
- [API不支持场景](tests/test_exception.ts)：测试低版本设备上的错误处理
- [网络异常场景](tests/test_exception.ts)：测试离线场景下的调用