# 读取健康记录
---
# 读取健康记录
#### 场景介绍
读取最新一条健康记录。
#### 约束与限制
从5.1.1(19) Release版本开始支持。
#### 接口说明
| 接口名 | 描述 |
| --- | --- |
| [readData](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)<T extends[HealthSequence](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)>(request:[HealthSequenceReadRequest](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore)): Promise<T[]> | 查询最新一条健康记录。 |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/08/v3/Hfogh_2FTdyeqJuiWofXcw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105210Z&HW-CC-Expire=86400&HW-CC-Sign=7E28D2E228C931AC5770CC7BC9E3EA5CDCD5E24A78C84723963B552C92492B11)
当前HealthSequenceReadRequest里的时间参数暂不生效，仅支持返回手表侧最新一条数据。
#### 开发前检查
-
完成 [申请运动健康服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-apply) 与 [配置Client ID](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-configuration-client-id) 。
-
接口首次调用前，需先使用 [init](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore) 方法进行初始化。
-
需先通过 [用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-add-permissions) 接口引导用户授权，用户授权对应数据类型权限后，才有权限调用接口操作相关数据类型数据。
-
错误码请参考 [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-healthservice) ，常见问题请参考 [Health Service Kit常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-faqs) 。
#### 开发步骤
1.
导入运动健康服务功能模块及相关公共模块。
```typescript
import { healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```
2.
创建查询健康记录请求。
```typescript
let healthSequenceReadRequest: healthStore.HealthSequenceReadRequest = {
  healthSequenceDataType: healthStore.healthSequenceHelper.sleepRecord.DATA_TYPE,
  startTime: 1695740400000,
  endTime: 1695769200000,
  readOptions: {
    withDetails: true
  }
}
```
3.
调用 [readData](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/health-api-healthstore) 方法执行查询请求，并处理返回结果。
```typescript
try {
  const healthSequences = await healthStore.readData(healthSequenceReadRequest);
  hilog.info(0x0000, 'testTag', 'Succeeded in reading data.');
  healthSequences.forEach((healthSequence) => {
    hilog.info(0x0000, 'testTag', `the start time is ${healthSequence.startTime}.`);
    hilog.info(0x0000, 'testTag', `the end time is ${healthSequence.endTime}.`);
    Object.keys(healthSequence.summaries).forEach((key) => {
      hilog.info(0x0000, 'testTag', `the summaries of ${key} is ${healthSequence.summaries[key]}.`);
    });
  });
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to read data. Code: ${err.code}, message: ${err.message}`);
}
```