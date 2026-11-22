---
name: hmos-health-service-kit-manage-authorizations
description: 管理运动健康服务用户授权+支持Wearable应用+需先初始化及完成华为账号登录+适用于健康数据访问权限申请场景
---

# 管理用户授权技能

## 功能描述

本技能用于管理HarmonyOS运动健康服务(Health Service Kit)的用户授权功能,支持Wearable可穿戴设备应用开发。主要功能包括:

1. **用户授权申请**: 拉起华为账号同步和授权界面,引导用户授权相应的数据访问权限
2. **权限查询**: 查询用户已授权的读写数据类型权限
3. **取消授权**: 取消用户所有授权

用户可以自主选择授权的数据类型,应用所能操作的用户数据是用户授权和运动健康服务审批通过的数据权限的交集。

## 使用场景

### 触发词
- "申请运动健康权限"
- "用户授权健康数据"
- "查询健康数据权限"
- "取消健康授权"
- "运动健康授权管理"
- "Health Service Kit授权"

### 能做
- 拉起华为账号授权页面引导用户授权
- 申请指定数据类型的读写权限(如心率、锻炼记录等)
- 查询用户已授权的数据类型权限状态
- 取消用户对所有数据类型的授权
- 处理授权成功/失败的返回结果
- 获取授权成功的读写数据类型列表

### 绝不做
- 不处理未经用户授权的数据访问请求
- 不绕过用户授权流程直接访问健康数据
- 不处理运动健康服务未审批通过的数据权限
- 不在未初始化healthStore前调用授权接口
- 不在非UIAbilityContext环境下调用授权接口

### 补充
- **API版本**: 从API Version 5.1.1(19) Release开始支持Wearable设备
- **前置条件**: 必须先完成运动健康服务申请、配置Client ID、用户登录华为账号
- **调用时机**: 接口需在页面或自定义组件生命周期内调用
- **初始化要求**: 接口首次调用前需先使用healthStore.init()方法初始化
- **权限限制**: 授权参数中的权限必须在申请运动健康服务时已勾选

## 调用规范和规则

### 输入约束
- **数据类型参数**: readDataTypes和writeDataTypes必须为DataType数组,不能为空数组
- **权限要求**: 申请的权限必须在AGC平台申请运动健康服务时已勾选相应权限
- **Context类型**: 必须为UIAbilityContext类型,通过this.getUIContext().getHostContext()获取
- **数据类型有效性**: 数据类型必须是healthStore支持的数据类型(如exerciseSequenceHelper.DATA_TYPE、samplePointHelper.heartRate.DATA_TYPE等)

### 执行约束
- **调用时机**: 必须在页面或自定义组件生命周期内调用
- **初始化检查**: 调用前必须先调用healthStore.init()完成初始化
- **华为账号状态**: 用户必须已登录华为账号
- **隐私协议**: 用户必须在运动健康App中同意隐私协议
- **网络状态**: 需要网络连接才能完成授权流程

### 内容约束
- **禁止生成**: 不生成绕过用户授权的代码、不生成硬编码权限列表
- **禁止高危操作**: 不使用eval、exec等高危函数、不直接操作系统权限文件
- **禁止操作**: 不在非组件生命周期调用、不使用非UIAbilityContext

### 降级约束
- **网络失败**: 提示用户检查网络连接,建议用户稍后重试
- **账号未登录**: 引导用户登录华为账号后重新申请授权
- **隐私未同意**: 引导用户启动运动健康App并同意隐私协议
- **权限未申请**: 提示开发者在AGC平台申请相应权限
- **用户取消授权**: 尊重用户选择,不强制要求授权,提供降级功能体验

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查是否已完成运动健康服务申请和Client ID配置
2. 检查是否已调用healthStore.init()完成初始化
3. 检查用户是否已登录华为账号
4. 检查用户是否已在运动健康App同意隐私协议

**参数准备**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

let authorizationParameter: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE],
  writeDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE]
}
```

### 步骤2: 申请用户授权

**示例代码**:
```typescript
try {
  let authorizationResponse = await healthStore.requestAuthorizations(
    this.getUIContext().getHostContext() as common.UIAbilityContext, 
    authorizationParameter
  );
  hilog.info(0x0000, 'testTag', 'Succeeded in requesting authorization.');
  
  authorizationResponse.writeDataTypes.forEach(dataType => {
    hilog.info(0x0000, 'testTag', `grantedWriteDataType is : ${dataType.name}`);
  });
  
  authorizationResponse.readDataTypes.forEach(dataType => {
    hilog.info(0x0000, 'testTag', `grantedReadDataTypes is : ${dataType.name}`);
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to request authorization. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤3: 查询权限

**示例代码**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

let queryAuthorizationRequest: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE],
  writeDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE]
}

try {
  let queryAuthorizationResponse = await healthStore.getAuthorizations(queryAuthorizationRequest);
  hilog.info(0x0000, 'testTag', 'Succeeded in getting authorization.');
  
  queryAuthorizationResponse.writeDataTypes.forEach(dataType => {
    hilog.info(0x0000, 'testTag', `grantedWriteDataType is : ${dataType.name}`);
  });
  
  queryAuthorizationResponse.readDataTypes.forEach(dataType => {
    hilog.info(0x0000, 'testTag', `grantedReadDataTypes is : ${dataType.name}`);
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to get authorization. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤4: 取消授权

**示例代码**:
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

try {
  await healthStore.cancelAuthorizations();
  hilog.info(0x0000, 'testTag', 'Succeeded in canceling authorization.');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to cancel authorization. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤5: 错误处理

```typescript
try {
  await healthStore.requestAuthorizations(context, authorizationParameter);
} catch (error) {
  switch (error.code) {
    case 201:
      console.error('权限校验失败: 应用指纹配置不正确或缺少权限');
      break;
    case 401:
      console.error('参数错误: 检查参数类型和必填项');
      break;
    case 1001502001:
      console.error('华为账号未登录,请引导用户登录');
      break;
    case 1001502005:
      console.error('网络异常,请检查网络连接');
      break;
    case 1001502012:
      console.error('用户取消授权,尊重用户选择');
      break;
    case 1001502014:
      console.error('应用未申请相应权限,请在AGC平台配置');
      break;
    case 1002701001:
      console.error('网络错误,请检查网络配置');
      break;
    case 1002702001:
      console.error('账号未登录,请引导用户登录华为账号');
      break;
    case 1002702002:
      console.error('账号异常,获取账号信息失败');
      break;
    case 1002703001:
      console.error('用户隐私未同意,请引导用户启动运动健康App');
      break;
    default:
      console.error('未知错误:', error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 1.检查AGC应用指纹证书配置<br/>2.确认用户已授权<br/>3.申请成为测试用户或完成验收<br/>4.联系华为支持 |
| 401 | 参数错误 | 1.检查必填参数是否填写<br/>2.检查参数类型是否正确<br/>3.检查参数取值范围 |
| 1001502001 | 华为账号未登录 | 引导用户登录华为账号后重新调用 |
| 1001502005 | 网络异常 | 检查网络连接状态,提示用户重试 |
| 1001502012 | 用户取消授权 | 尊重用户选择,不强制授权,提供降级功能 |
| 1001502014 | 应用未申请权限 | 在AGC平台申请相应权限 |
| 1002701001 | 网络错误 | 检查网络配置,确保网络可用 |
| 1002702001 | 账号未登录 | 引导用户登录华为账号 |
| 1002702002 | 账号异常 | 获取账号信息失败,联系华为支持 |
| 1002703001 | 用户隐私未同意 | 引导用户启动运动健康App并同意隐私协议 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.HealthServiceKit": "API 12+",
    "@kit.AbilityKit": "API 12+",
    "@kit.PerformanceAnalysisKit": "API 12+"
  }
}
```

### 环境要求
- **HarmonyOS API**: 5.1.1(19) Release或更高版本
- **设备支持**: Wearable可穿戴设备
- **账号要求**: 需登录华为账号
- **应用配置**: 需在AGC平台申请运动健康服务并配置Client ID

### 常见编译问题

**问题1: 找不到healthStore模块**
```
Module '@kit.HealthServiceKit' not found
```
**解决方法**: 确保HarmonyOS SDK版本不低于API 12,在module.json5中添加依赖

**问题2: UIAbilityContext类型错误**
```
Type 'UIAbilityContext' is not assignable to type 'Context'
```
**解决方法**: 使用`this.getUIContext().getHostContext()`获取正确的UIAbilityContext

**问题3: DataType未定义**
```
Property 'DATA_TYPE' does not exist on type 'exerciseSequenceHelper'
```
**解决方法**: 检查数据类型是否正确,参考数据类型常量文档

## 常见问题与解决方法

### Q1: 用户授权后无法访问数据
**原因**: 应用申请的权限与用户授权的权限交集为空
**解决方法**:
- 检查AGC平台申请的权限列表
- 检查AuthorizationRequest中的readDataTypes和writeDataTypes
- 确认用户实际授权的数据类型(通过AuthorizationResponse查看)

### Q2: 调用授权接口返回1002703001错误
**原因**: 用户从未启动过运动健康App,未同意隐私协议
**解决方法**:
- 引导用户手动启动运动健康App
- 用户在运动健康App中同意隐私协议后重新调用

### Q3: 用户取消授权后如何处理
**原因**: 用户主动取消授权流程
**解决方法**:
- 不强制要求用户授权
- 提示用户授权后才能使用完整功能
- 提供不依赖授权的降级功能体验

### Q4: 如何判断用户是否已授权
**原因**: 需要在调用数据接口前检查权限状态
**解决方法**:
- 使用getAuthorizations查询权限状态
- 根据返回的readDataTypes和writeDataTypes判断
- 如果权限为空数组则未授权

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "grantedReadDataTypes": ["exerciseSequence", "heartRate"],
  "grantedWriteDataTypes": ["exerciseSequence", "heartRate"],
  "apiUsed": [
    "healthStore.requestAuthorizations",
    "healthStore.getAuthorizations",
    "healthStore.cancelAuthorizations"
  ],
  "message": "用户授权管理完成"
}
```

## 参考文档

- [管理用户授权开发指南](references/health-wearable-add-permissions.md)
- [healthStore API参考](references/health-api-healthstore.md)
- [运动健康服务错误码](references/errorcode-healthservice.md)
- [申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply)
- [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-configuration-client-id)
- [权限说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-permission-description)
- [Health Service Kit常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-faqs)

## 完整示例代码

- [ArkTS授权申请示例](assets/request_authorizations.ets)
- [ArkTS查询权限示例](assets/query_authorizations.ets)
- [ArkTS取消授权示例](assets/cancel_authorizations.ets)
- [完整授权管理示例](assets/authorization_manager.ets)

## 测试用例

### 正向测试用例
- [测试申请心率读写权限](tests/test_request_heart_rate_permission.ets): 正常申请心率数据读写权限
- [测试查询已授权权限](tests/test_query_granted_permissions.ets): 查询用户已授权的数据类型
- [测试取消授权](tests/test_cancel_authorizations.ets): 正常取消所有授权

### 边界测试用例
- [测试申请空数据类型](tests/test_empty_data_types.ets): 申请空数组数据类型权限
- [测试申请未配置权限](tests/test_unconfigured_permission.ets): 申请AGC未勾选的权限
- [测试多次授权](tests/test_multiple_authorizations.ets): 多次调用授权接口

### 异常测试用例
- [测试未初始化调用](tests/test_without_init.ets): 未调用init()直接授权
- [测试账号未登录](tests/test_account_not_logged_in.ets): 用户未登录华为账号
- [测试网络异常](tests/test_network_error.ets): 网络不可用场景
- [测试用户取消授权](tests/test_user_cancel.ets): 用户主动取消授权流程