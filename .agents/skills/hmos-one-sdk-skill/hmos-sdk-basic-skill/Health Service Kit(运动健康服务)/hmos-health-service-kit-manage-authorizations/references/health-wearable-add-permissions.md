# 管理用户授权
---
# 管理用户授权
#### 场景介绍
应用拉起华为账号同步和授权界面，由用户授权相应的数据访问权限。用户可以自主选择授权的数据类型，可以只授权部分数据权限。
应用所能操作的用户数据，是用户授权和运动健康服务审批通过的数据权限的交集。
#### 约束与限制
从5.1.1(19) Release版本开始支持。
#### 接口说明
| 接口名 | 描述 |
| --- | --- |
| [requestAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)(context:[common.UIAbilityContext](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-uiabilitycontext.md), request:[AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)): Promise<[AuthorizationResponse](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)> | 用户授权，入参为UIAbility上下文和授权参数[AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)，添加需要读写的数据类型，拉起账号授权页面，引导用户完成授权，返回结果中的数据类型列表，其对应权限在[应用申请权限](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/申请运动健康服务/health-apply.md)和用户授权权限的交集中。 |
| [getAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)(request:[AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)): Promise<[AuthorizationResponse](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)> | 查询用户权限，入参为[AuthorizationRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)，添加需要查询的数据类型，查询传入类型是否有权限，返回结果中的数据类型列表，其对应权限在[应用申请权限](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/申请运动健康服务/health-apply.md)和用户授权权限的交集中。 |
| [cancelAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)(): Promise<void> | 取消用户所有授权。 |
#### 开发前检查
-
完成 [申请运动健康服务](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/申请运动健康服务/health-apply.md) 与 [配置Client ID](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/配置Client ID/health-configuration-client-id.md) 。
-
接口需在页面或自定义组件生命周期内调用。接口首次调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
-
错误码请参考 [ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) ，常见问题请参考 [Health Service Kit常见问题](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/Health Service Kit常见问题/health-faqs.md) 。
#### 开发步骤
#### 用户授权
1.导入运动健康功能模块及相关公共模块。
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.创建授权请求，确保授权参数中的权限已在申请运动健康服务时勾选，权限说明请参考 [权限说明](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/数据类型/权限说明/health-permission-description.md) 。
```typescript
let authorizationParameter: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE],
  writeDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE]
}
```
3.调用 [requestAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法执行登录授权请求，并处理返回结果。
```typescript
try {
  // 请在组件内获取context，确保this.getUIContext().getHostContext()返回结果为UIAbilityContext
  let authorizationResponse = await healthStore.requestAuthorizations(this.getUIContext().getHostContext() as common.UIAbilityContext, authorizationParameter);
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
#### 查询权限
1.导入运动健康服务功能模块及相关公共模块。
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.创建查询权限请求。
```typescript
let queryAuthorizationRequest: healthStore.AuthorizationRequest = {
  readDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE],
  writeDataTypes: [healthStore.exerciseSequenceHelper.DATA_TYPE, healthStore.samplePointHelper.heartRate.DATA_TYPE]
}
```
3.调用 [getAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法执行查询权限请求，并处理返回结果。
```typescript
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
#### 取消授权
1.
导入运动健康服务功能模块及相关公共模块。
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
调用 [cancelAuthorizations](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法执行取消授权，并处理返回结果。
```typescript
try {
  await healthStore.cancelAuthorizations();
  hilog.info(0x0000, 'testTag', 'Succeeded in canceling authorization.');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to cancel authorization. Code: ${err.code}, message: ${err.message}`);
}
```