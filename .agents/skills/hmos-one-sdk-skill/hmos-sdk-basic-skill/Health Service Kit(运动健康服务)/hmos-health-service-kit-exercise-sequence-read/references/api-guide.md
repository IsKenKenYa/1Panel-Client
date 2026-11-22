# 读取锻炼记录
---
# 读取锻炼记录
#### 场景介绍
读取最新一条锻炼记录。
#### 约束与限制
从5.1.1(19) Release版本开始支持。
#### 接口说明
| 接口名 | 描述 |
| --- | --- |
| [readData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)<T extends[ExerciseSequence](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)>(request:[ExerciseSequenceReadRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md)): Promise<T[]> | 查询最新一条锻炼记录。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d1/v3/1xm97eJTTd-t_n8AF1hNqw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105210Z&HW-CC-Expire=86400&HW-CC-Sign=C81E577C616B199C12D190870F8D99FE7B4FF8797E483643CF27F302EF753ACD)
当前ExerciseSequenceReadRequest里的时间参数暂不生效，仅支持返回手表侧最新一条数据。
#### 开发前检查
-
完成 [申请运动健康服务](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/申请运动健康服务/health-apply.md) 与 [配置Client ID](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/开发准备/配置Client ID/health-configuration-client-id.md) 。
-
接口首次调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
-
需先通过 [用户授权](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/开发接入/Phone_Tablet应用开发/管理用户授权/health-add-permissions.md) 接口引导用户授权，用户授权对应数据类型权限后，才有权限调用接口操作相关数据类型数据。
-
错误码请参考 [ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) ，常见问题请参考 [Health Service Kit常见问题](D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Health Service Kit（运动健康服务）/Health Service Kit常见问题/health-faqs.md) 。
#### 开发步骤
1.
导入运动健康服务功能模块及相关公共模块。
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
创建查询请求。
```typescript
// 查询跑步记录
const sequenceReadRequest:
  healthStore.ExerciseSequenceReadRequest<healthStore.exerciseSequenceHelper.running.DetailFields> = {
  startTime: 1698040800000,
  endTime: 1698042600000,
  exerciseType: healthStore.exerciseSequenceHelper.running.EXERCISE_TYPE,
  count: 1,
  sortOrder: 1,
  readOptions: {
    withPartialDetails: ['exerciseHeartRate', 'altitude']
 }
};
```
3.
调用 [readData](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法执行查询请求，并处理返回结果。
```typescript
try {
  const runningSequences =
    await healthStore.readData<healthStore.exerciseSequenceHelper.running.Model>(sequenceReadRequest);
  hilog.info(0x0000, 'testTag', 'Succeeded in reading data.');
  runningSequences.forEach((runningSequence) => {
    hilog.info(0x0000, 'testTag', `the start time is ${runningSequence.startTime}.`);
    hilog.info(0x0000, 'testTag', `the end time is ${runningSequence.endTime}.`);
    Object.keys(runningSequence.summaries).forEach((key) => {
      Object.keys(runningSequence.summaries[key]).forEach((fieldName) => {
        hilog.info(0x0000, 'testTag',
          `the summaries of ${key} field ${fieldName} is ${runningSequence.summaries[key][fieldName]}.`);
      });
    });
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to read data. Code: ${err.code}, message: ${err.message}`);
}
```