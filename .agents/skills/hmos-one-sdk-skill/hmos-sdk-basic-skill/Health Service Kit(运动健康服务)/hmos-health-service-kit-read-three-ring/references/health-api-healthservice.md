# healthService(运动健康联动服务)
---
# healthService(运动健康联动服务)
本模块提供运动健康联动服务。
**起始版本：** 5.0.0(12)
#### 导入模块
```typescript
import { healthService } from '@kit.HealthServiceKit';
```
#### SampleEvent
联动控制事件。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| eventId | number | 否 | 否 | 事件ID。 |
| eventLevel | number | 否 | 否 | 事件等级。取值参考：[0, 255] |
| eventData | string | 否 | 否 | 事件携带的信息。 |
| srcPkgName | string | 否 | 是 | 事件发送源包名，若未填写，默认为空。 |
| destPkgName | string | 否 | 是 | 事件发送目标包名，若未填写，默认为空。 |
#### SampleReal
SampleReal<K extends Record<string, [healthStore.HealthValueType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) > = Record<string, [healthStore.HealthValueType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) >>
联动实时运动数据。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| dataType | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 否 | 否 | 实时融合数据类型。 |
| time | number | 否 | 否 | 实时融合数据产生时间，Unix时间戳，以毫秒为单位。 |
| fields | Pick<K, keyof K> | 否 | 否 | 实时融合数据字段。 |
| deviceUniqueId | string | 否 | 是 | 实时融合数据来源，若未填写，默认为空。 |
#### workout
提供运动健康实时数据。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.0.0(12)
#### ActivityReport
实时三环数据。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.0.0(12)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| steps | number | 否 | 否 | 步数。 |
| stepsGoal | number | 否 | 是 | 步数目标（若未设置过，无法读取到运动健康App中展示的默认目标）。 |
| activeCalories | number | 否 | 否 | 活动热量。单位：卡 |
| activeCaloriesGoal | number | 否 | 是 | 活动热量目标。单位：卡 |
| exercise | number | 否 | 否 | 锻炼时长。单位：分钟 |
| exerciseGoal | number | 否 | 是 | 锻炼时长目标。单位：分钟 |
| activeHours | number | 否 | 否 | 活动小时数。 |
| activeHoursGoal | number | 否 | 是 | 活动小时数目标。 |
#### ConfigType
type ConfigType = number | string | boolean
联动配置项类型。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| 类型 | **说明** |
| --- | --- |
| number | 表示值类型为数字，可取任意值。 |
| string | 表示值类型为字符串，可取任意值。 |
| boolean | 表示值类型为布尔类型，可取true或false，具体含义以实际使用场景为准。 |
#### DeviceState
联动设备状态。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| deviceId | string | 否 | 否 | 设备ID。 |
| state | number | 否 | 否 | 设备状态。 |
| deviceName | string | 否 | 是 | 设备名称，若未填写，默认为空。 |
#### Goal
联动运动目标。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| type | number | 否 | 否 | 目标类型，取值参考：[TargetType](#section7230195122817)。 |
| value | number | 否 | 否 | 目标值。 |
#### LinkageType
联动类型。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| 名称 | 值 | 说明 |
| --- | --- | --- |
| COURSE_LINK | 0 | 课程联动。 |
| ACTIVITY_LINK | 1 | 运动联动。 |
#### StartCode
联动开启结果码。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| 名称 | 值 | 说明 |
| --- | --- | --- |
| SUCCESS | 0 | 联动开启成功。 |
| WORKOUT_WORKING | 1 | 联动已开始。 |
| NO_SUPPORTED_DEVICE | 2 | 无可支持联动的设备。 |
| DEVICE_BUSY | 3 | 联动设备忙碌。 |
#### StartResult
联动开启结果。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| startCode | [StartCode](#section16819124442317) | 否 | 否 | 联动开启结果码。 |
| deviceState | [DeviceState](#section1466304421712)[] | 否 | 否 | 联动设备状态。 |
#### TargetType
联动目标类型。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| 名称 | 值 | 说明 |
| --- | --- | --- |
| NONE | 0 | 无目标。 |
| DISTANCE | 1 | 距离。 |
| CALORIE | 2 | 卡路里。 |
| TIME | 3 | 时长。 |
| SKIPPING_TIMES | 4 | 跳绳次数。 |
#### WorkoutConfig
联动配置项。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
| **名称** | **类型** | 只读 | 可选 | **说明** |
| --- | --- | --- | --- | --- |
| linkageType | [LinkageType](#section15978631122119) | 否 | 否 | 联动类型。 |
| sportType | number | 否 | 否 | 运动类型，参见[锻炼记录类型常量](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-exercisedequencehelper.md)子数据类型id。 |
| activityGoals | [Goal](#section1847017072015)[] | 否 | 是 | 联动运动目标，若未填写，默认为空。 |
| extensionConfig | Record<string,[ConfigType](#section895913201519)> | 否 | 是 | 扩展配置项，若未填写，默认为空。 |
#### workout.config
config(workoutConfig: WorkoutConfig): Promise<void>
配置联动，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| workoutConfig | [WorkoutConfig](#section77282239296) | 是 | 联动配置项。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. |
| [1009104003](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Illegal command. Called when workout not in stoped or idle state. |
| [1009104999](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | System internal error. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/80/v3/SBz3W_GXRUu1kQQtjw9tXg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=C3F8244D32E2DAE9EE27367817A4555049DE8DE69E00AF551C88A13347AFD799)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService, healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  let workoutOptions: healthService.workout.WorkoutConfig = {
    linkageType: healthService.workout.LinkageType.COURSE_LINK,
    sportType: healthStore.exerciseSequenceHelper.running.EXERCISE_TYPE.id
  };
  await healthService.workout.config(workoutOptions);
  hilog.info(0x0000, 'testTag', 'Succeed in configuring workout');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to configure workout. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.start
start(): Promise<StartResult>
开启联动，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[StartResult](#section103341756122412)> | Promise对象，返回联动开启结果。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [1009104001](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Sport service busy. Workout is already started by other application. |
| [1009104002](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Unsupported sport type. |
| [1009104003](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Illegal command. Called when workout in sporting, paused or stoped state. |
| [1009104004](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification error. Application has no permission, such as Motion Permission. |
| [1009104999](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | System internal error. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/64/v3/ayys08qiQuKDglTJXRmhRw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=40FACB6EB69F25F0FE3E77489A323AAA6858F75B2C31617E2FCA89521981C24E)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  await healthService.workout.start();
  hilog.info(0x0000, 'testTag', 'Succeed in starting workout');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to start workout. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.pause
pause(): Promise<void>
暂停联动，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [1009104003](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Illegal command. Called when workout in ready, paused or stoped state. |
| [1009104999](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | System internal error. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/gOKkwCrfT-iV_R-rR6kLBw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=07F8F84639240128371B2DC9595218D3291E1AEC0EC2B03E4E7153D0FF460B11)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  await healthService.workout.pause();
  hilog.info(0x0000, 'testTag', 'Succeed in pausing workout');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to pause workout. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.resume
resume(): Promise<void>
恢复联动，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [1009104003](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Illegal command. Called when workout in ready, sporting or stoped state. |
| [1009104999](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | System internal error. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d5/v3/lVyrzslpRx2s2eRC2sgAXg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=E96E3B45CDEEC19AE78674AF957B5B1D5321CFF04FE6D8ED1F6359B5D0E814BD)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  await healthService.workout.resume();
  hilog.info(0x0000, 'testTag', 'Succeed in resuming workout');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to resume workout. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.stop
stop(): Promise<void>
停止联动，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [1009104003](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Illegal command. Called when workout is not started. |
| [1009104999](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | System internal error. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1f/v3/PDQOPFXgQhiNbs1C5mA5dA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=7B38573CD1AC8A920E62972F174B004782D0DE02604623862832004EEBD0E61F)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  await healthService.workout.stop();
  hilog.info(0x0000, 'testTag', 'Succeed in stopping workout');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to stop workout. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.onData
onData(dataType: healthStore.DataType, listener: Callback<SampleReal[]>): Promise<void>
注册指定联动运动数据监听，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| dataType | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 是 | 联动运动数据类型。 |
| listener | Callback<[SampleReal](#section133382582612)[]> | 是 | 联动运动数据监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;2. Incorrect parameter types. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/df/v3/y53hL2ZrRzeI7HpqIY26CA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=9DFB6C35A72DDDACC459B1928254821064CFEB5D4E37FA9486560A68B4A04D9C)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService, healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleReal[]> = (sampleReals) => {
    hilog.info(0x0000, 'testTag', `Workout onData receive data. The sampleReals size is ${sampleReals.length}`);
  };
  const realTimeMotionDataType: healthStore.DataType = {
    id: 50004
  };
  await healthService.workout.onData(realTimeMotionDataType, callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to onData. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.onData
onData(dataType: undefined, listener: Callback<SampleReal[]>): Promise<void>
注册所有联动运动数据监听，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| dataType | undefined | 是 | 监听所有联动运动数据类型。 |
| listener | Callback<[SampleReal](#section133382582612)[]> | 是 | 联动运动数据监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/b4/v3/q2k6sZduR8iLlqYKKW-aaQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=F41CB8C328B7933356CF848178CA67EBD1EB75F4BB61164069CFE2E0D18B1554)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleReal[]> = (sampleReals) => {
    hilog.info(0x0000, 'testTag', `Workout onData receive data. The sampleReals size is ${sampleReals.length}`);
  };
  await healthService.workout.onData(undefined, callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to onData. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.offData
offData(dataType: healthStore.DataType, listener: Callback<SampleReal[]>): Promise<void>
取消指定联动运动数据的监听，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| dataType | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 是 | 联动运动数据类型。 |
| listener | Callback<[SampleReal](#section133382582612)[]> | 是 | 联动运动数据监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;2. Incorrect parameter types; 3.Parameter verification failed. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/46/v3/3yGI_fxYRPi8G756SBS1lw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=7E3247D4E85837DA3D4C6B04B2A868A7E2953A6F8416A738E4E0B45F164E3B20)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService, healthStore } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleReal[]> = (sampleReals) => {
    hilog.info(0x0000, 'testTag', `Workout offData receive data. The sampleReals size is ${sampleReals.length}`);
  };
  await healthService.workout.offData(healthStore.healthDataTypes.WORKOUT, callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to offData. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.offData
offData(dataType: undefined, listener: Callback<SampleReal[]>): Promise<void>
取消所有联动运动数据的监听，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| dataType | undefined | 是 | 监听所有联动运动数据类型。 |
| listener | Callback<[SampleReal](#section133382582612)[]> | 是 | 联动运动数据监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;2. Parameter verification failed. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/30/v3/W1I4NFKgQPyWdplxW5hTIA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=E5955A62BC9C6C9C2E404DEAB19BBC07C6BE53E318C83F0673A3ED9F0E75D529)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleReal[]> = (sampleReals) => {
    hilog.info(0x0000, 'testTag', `Workout offData receive data. The sampleReals size is ${sampleReals.length}`);
  };
  await healthService.workout.offData(undefined, callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to offData. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.onEvent("*")
onEvent(event: "*", listener: Callback<SampleEvent>): Promise<void>
注册联动设备事件监听，使用Promise异步方式。
**系统能力：** SystemCapability.Health.HealthService
**设备行为差异：** 该接口在Phone、Tablet中可正常调用，在Wearable中返回401错误码。
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| event | string | 是 | 联动设备事件类型，支持的事件为："*"，当联动设备运动状态改变时，触发该事件。 |
| listener | Callback<[SampleEvent](#section599483722019)> | 是 | 联动设备事件监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4c/v3/uXswCSdJTzm9cYnkxPaMkQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=76C55B9F16662E01E08598F0777BD1882AFB3D11288063A2BACD48D20B09AB31)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleEvent> = (event) => {
    hilog.info(0x0000, 'testTag', `Workout onEvent receive event. Event data: ${event.eventData}, event id: ${event.eventId}`);
  };
  await healthService.workout.onEvent('*', callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to onEvent. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.offEvent("*")
offEvent(event: "*", listener: Callback<SampleEvent>): Promise<void>
取消联动设备事件的监听，使用Promise异步方式。
**系统能力：** SystemCapability.Health.HealthService
**设备行为差异：** 该接口在Phone、Tablet中可正常调用，在Wearable中返回401错误码。
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| event | string | 是 | 联动设备事件类型，支持的事件为："*"，当联动设备运动状态改变时，触发该事件。 |
| listener | Callback<[SampleEvent](#section599483722019)> | 是 | 联动设备事件监听回调。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;2. Parameter verification failed. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/e1/v3/UdkK5fmQQvmF6tc-1sJPBQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=63CB98C3C6255C37E1DFB9C84650C492243CC8DC9485C5D5E850A786F479C9B6)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const callback: Callback<healthService.SampleEvent> = (event) => {
    hilog.info(0x0000, 'testTag', `Workout offEvent receive event. Event data: ${event.eventData}, event id: ${event.eventId}`);
  };
  await healthService.workout.offEvent('*', callback);
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to offEvent. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.readActivityReport
readActivityReport(): Promise<ActivityReport>
读取实时三环数据，使用Promise异步方式。
该接口从API 19 Release开始，支持Wearable设备开发。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthService
**起始版本：** 5.0.0(12)
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<[ActivityReport](#section17562157135210)> | Promise对象，返回实时三环数据。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission denied. |
| [14500101](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Service exception. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d1/v3/1rT21OypQN6Oja9iEhWYfA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=BAD41B3D9D945A883F075530070182B701B0FB3EE80D73907455328C4BBD50C9)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const result: healthService.workout.ActivityReport = await healthService.workout.readActivityReport();
  hilog.info(0x0000, 'testTag', 'Succeeded in reading ActivityReport');
  Object.keys(result).forEach(key => {
    hilog.info(0x0000, 'testTag', `the ${key} is ${result[key]}`);
  });
} catch(err) {
  hilog.error(0x0000, 'testTag', `Failed to read ActivityReport. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.sendData
sendData(sampleReal: SampleReal[]): Promise<void>
下发融合运动数据到联动设备，使用Promise异步方式。
**系统能力：** SystemCapability.Health.HealthService
**设备行为差异：** 该接口在Phone、Tablet中可正常调用，在Wearable中返回401错误码。
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| sampleReal | [SampleReal](#section133382582612)[] | 是 | 融合运动数据。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified;2. Incorrect parameter types. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2f/v3/DbxWvpKGT6mC34jBEE_dQw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=B9CEFE9BA2308F56647A1E4598870E4F6853FB8C3EC95244CE253E445E503D74)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const sampleReal: healthService.SampleReal = {
    dataType: { id: 50004 },
    time: 1695740400000, // 2023-09-26 23:00:00,
    fields: {
      hr: 90
    }
  };
  await healthService.workout.sendData([sampleReal]);
  hilog.info(0x0000, 'testTag', 'Succeed in sending data.');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to send data. Code: ${err.code}, message: ${err.message}`);
}
```
#### workout.sendEvent
sendEvent(event: SampleEvent): Promise<void>
下发控制事件到联动设备，使用Promise异步方式。
**系统能力：** SystemCapability.Health.HealthService
**设备行为差异：** 该接口在Phone、Tablet中可正常调用，在Wearable中返回401错误码。
**起始版本：** 5.1.0(18)
**参数：**
| **参数名** | **类型** | 必填 | **说明** |
| --- | --- | --- | --- |
| event | [SampleEvent](#section599483722019) | 是 | 联动控制事件。 |
**返回值：**
| 类型 | 说明 |
| --- | --- |
| Promise<void> | 无结果返回的Promise对象。 |
**错误码：**
以下错误码的详细介绍请参见 [运动健康服务ArkTS API错误码](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) 。
| 错误码ID | 错误信息 |
| --- | --- |
| [201](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Permission verification failed. |
| [401](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/errorcode-healthservice.md) | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/76/v3/wVQNfILdSN-OFmne11bdEg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093814Z&HW-CC-Expire=86400&HW-CC-Sign=2A855E17A09CB72769D05EAD9AF64F4193221B9F2C9E27B433A52BA4B1095248)
上述接口调用前，需先使用 [init](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) 方法进行初始化。
**示例：**
```typescript
import { healthService } from '@kit.HealthServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  const sampleEvent: healthService.SampleEvent = {
    eventId: 800400002,
    eventLevel: 0,
    eventData: 'start'
  };
  await healthService.workout.sendEvent(sampleEvent);
  hilog.info(0x0000, 'testTag', 'Succeed in sending event.');
} catch (err) {
  hilog.error(0x0000, 'testTag', `Failed to send event. Code: ${err.code}, message: ${err.message}`);
}
```