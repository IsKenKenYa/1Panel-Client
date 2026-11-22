# 实时三环数据
---
# 实时三环数据
#### 场景介绍
实时三环数据，包括实时步数，活动热量，锻炼时长，活动小时数以及目标类数据。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4d/v3/ENm7vCdGSVOK7e9-CmyZ9w/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105210Z&HW-CC-Expire=86400&HW-CC-Sign=7761C340A189CC25C779CDF33D37E88991B078ED8F85922E6C0BDB996910F3B8)
此接口使用日常活动数据类型读权限，参考 [权限说明](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/数据类型/权限说明/health-permission-description.md) 。
#### 约束与限制
从5.1.1(19) Release版本开始支持。
#### OAuth权限
联盟卡片申请的权限名称：日常活动 > 日常活动数据（读）
#### 接口说明
| 接口名 | 描述 |
| --- | --- |
| [readActivityReport](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthservice.md)(): Promise<[ActivityReport](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthservice.md)> | 读取实时三环数据。 |
#### 开发前检查
-
完成 [申请运动健康服务](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/申请运动健康服务/health-apply.md) 与 [配置Client ID](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/配置Client ID/health-configuration-client-id.md) 。
-
接口首次调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
-
需先通过 [用户授权](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/Phone_Tablet应用开发/管理用户授权/health-add-permissions.md) 接口引导用户授权，用户授权日常活动数据类型读权限（参考 [权限说明](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/数据类型/权限说明/health-permission-description.md) ）后，才有权限读取实时三环数据。
-
错误码请参考 [ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) ，常见问题请参考 [Health Service Kit常见问题](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/Health Service Kit常见问题/health-faqs.md) 。
#### 开发步骤
1.
导入运动健康服务功能模块及相关公共模块。
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
调用 [readActivityReport](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthservice.md) 方法读取实时三环数据，并处理返回结果。
```typescript
try {
  const result: healthService.workout.ActivityReport = await healthService.workout.readActivityReport();
  hilog.info(0x0000, 'testTag', 'Succeeded in reading ActivityReport');
  Object.keys(result).forEach(key => {
    hilog.info(0x0000, 'testTag', `the ${key} is ${result[key]}`);
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to read ActivityReport. Code: ${err.code}, message: ${err.message}`);
}
```