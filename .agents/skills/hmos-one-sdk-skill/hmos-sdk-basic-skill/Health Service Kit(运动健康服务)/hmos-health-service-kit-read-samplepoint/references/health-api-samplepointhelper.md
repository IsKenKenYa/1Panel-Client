# samplePointHelper(采样数据类型常量)
---
# samplePointHelper(采样数据类型常量)
本模块提供采样数据类型常量及数据模型。
**起始版本：** 5.0.0(12)
#### 导入模块
```typescript
import { healthStore } from '@kit.HealthServiceKit';
```
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/d9/v3/RWscX89wQBeaXSjPH3kZYw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093815Z&HW-CC-Expire=86400&HW-CC-Sign=29A90B58718F682BC59A8A700406016922F111960F6439CF167AC4A738EE597A)
此模块为healthStore子模块，需通过healthStore.samplePointHelper方式使用。
#### bloodOxygenSaturation
血氧数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 血氧数据类型。 |
#### Model
type Model = healthModels.BloodOxygenSaturation
血氧采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BloodOxygenSaturation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 血氧采样数据模型。 |
#### Fields
type Fields = healthFields.BloodOxygenSaturation
血氧采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.BloodOxygenSaturation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 血氧采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.BloodOxygenSaturationAggregateResult
血氧采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BloodOxygenSaturationAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 血氧采样数据聚合统计结果模型 |
#### AggregateRequest
type AggregateRequest = healthModels.BloodOxygenSaturationAggregateRequest
血氧采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BloodOxygenSaturationAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 血氧采样数据聚合统计请求模型 |
#### AggregateFields
type AggregateFields = healthFields.BloodOxygenSaturationAggregation
血氧采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.BloodOxygenSaturationAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 血氧采样数据支持的聚合统计字段列表。 |
#### bloodPressure
血压数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 血压数据类型。 |
#### Model
type Model = healthModels.BloodPressure
血压采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BloodPressure](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 血压采样数据模型。 |
#### Fields
type Fields = healthFields.BloodPressure
血压采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.BloodPressure](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 血压采样数据字段列表。 |
#### bodyTemperature
体温数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 体温数据类型。 |
#### Model
type Model = healthModels.BodyTemperature
体温采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BodyTemperature](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 体温采样数据模型。 |
#### Fields
type Fields = healthFields.BodyTemperature
体温采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.BodyTemperature](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 体温采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.BodyTemperatureAggregateResult
体温采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BodyTemperatureAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 体温采样数据聚合统计结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.BodyTemperatureAggregateRequest
体温采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.BodyTemperatureAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 体温采样数据聚合统计请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.BodyTemperatureAggregation
体温采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.BodyTemperatureAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 体温采样数据支持的聚合统计字段列表。 |
#### dailyActivities
日常活动数据类型常量及数据模型。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 日常活动数据类型。 |
#### Model
type Model = healthModels.DailyActivities
日常活动采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.DailyActivities](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 日常活动采样数据模型。 |
#### Fields
type Fields = healthFields.DailyActivities
日常活动采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.DailyActivities](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 日常活动采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.DailyActivitiesAggregateResult
日常活动采样数据聚合统计结果模型。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.DailyActivitiesAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 日常活动采样数据聚合结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.DailyActivitiesAggregateRequest
日常活动采样数据聚合统计请求模型。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.DailyActivitiesAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 日常活动采样数据聚合请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.DailyActivitiesAggregation
日常活动采样数据支持的聚合统计字段列表。
**元服务API：** 从版本5.0.0(12)开始，该接口支持在元服务中使用。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.DailyActivitiesAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 日常活动采样数据支持的聚合统计字段列表。 |
#### emotion
情绪数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 情绪数据类型。 |
#### Model
type Model = healthModels.Emotion
情绪采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 类型 | **说明** |
| --- | --- |
| [healthModels.Emotion](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 情绪采样数据模型。 |
#### Fields
type Fields = healthFields.Emotion
情绪采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 类型 | **说明** |
| --- | --- |
| [healthFields.Emotion](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 情绪采样数据字段列表。 |
#### heartRate
动态心率数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 动态心率数据类型。 |
#### Model
type Model = healthModels.HeartRate
动态心率采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.HeartRate](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 动态心率采样数据模型。 |
#### Fields
type Fields = healthFields.HeartRate
动态心率采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.HeartRate](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 动态心率采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.HeartRateAggregateResult
动态心率采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.HeartRateAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 动态心率采样数据聚合统计结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.HeartRateAggregateRequest
动态心率采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.HeartRateAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 动态心率采样数据聚合统计请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.HeartRateAggregation
动态心率采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.HeartRateAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 动态心率采样数据支持的聚合统计字段列表。 |
#### heartRateVariability
心率变异性数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 心率变异性数据类型。 |
#### Model
type Model = healthModels.HeartRateVariability
心率变异性采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 类型 | **说明** |
| --- | --- |
| [healthModels.HeartRateVariability](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 心率变异性采样数据模型。 |
#### Fields
type Fields = healthFields.HeartRateVariability
心率变异性采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.1.0(18)
| 类型 | **说明** |
| --- | --- |
| [healthFields.HeartRateVariability](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 心率变异性采样数据字段列表。 |
#### height
身高数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 身高数据类型。 |
#### Model
type Model = healthModels.Height
身高采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.Height](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 身高采样数据模型。 |
#### Fields
type Fields = healthFields.Height
身高采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.Height](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 身高采样数据字段列表。 |
#### restingHeartRate
静息心率数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 静息心率数据类型。 |
#### Model
type Model = healthModels.RestingHeartRate
静息心率采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.RestingHeartRate](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 静息心率采样数据模型。 |
#### Fields
type Fields = healthFields.RestingHeartRate
静息心率采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.RestingHeartRate](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 静息心率采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.RestingHeartRateAggregateResult
静息心率采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.RestingHeartRateAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 静息心率采样数据聚合统计结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.RestingHeartRateAggregateRequest
静息心率采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.RestingHeartRateAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 静息心率采样数据聚合统计请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.RestingHeartRateAggregation
静息心率采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.RestingHeartRateAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 静息心率采样数据支持的聚合统计字段列表。 |
#### skinTemperature
皮肤体温数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 皮肤体温数据类型。 |
#### Model
type Model = healthModels.SkinTemperature
皮肤体温采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.SkinTemperature](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 皮肤体温采样数据模型。 |
#### Fields
type Fields = healthFields.SkinTemperature
皮肤体温采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.SkinTemperature](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 皮肤体温采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.SkinTemperatureAggregateResult
皮肤体温采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.SkinTemperatureAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 皮肤体温采样数据聚合统计结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.SkinTemperatureAggregateRequest
皮肤体温采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.SkinTemperatureAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 皮肤体温采样数据聚合统计请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.SkinTemperatureAggregation
皮肤体温采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.SkinTemperatureAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 皮肤体温采样数据支持的聚合统计字段列表。 |
#### stress
压力数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 压力数据类型。 |
#### Model
type Model = healthModels.Stress
压力采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.Stress](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 压力采样数据模型。 |
#### Fields
type Fields = healthFields.Stress
压力采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.Stress](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 压力采样数据字段列表。 |
#### AggregateResult
type AggregateResult = healthModels.StressAggregateResult
压力采样数据聚合统计结果模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.StressAggregateResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 压力采样数据聚合统计结果模型。 |
#### AggregateRequest
type AggregateRequest = healthModels.StressAggregateRequest
压力采样数据聚合统计请求模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.StressAggregateRequest](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 压力采样数据聚合统计请求模型。 |
#### AggregateFields
type AggregateFields = healthFields.StressAggregation
压力采样数据支持的聚合统计字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.StressAggregation](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 压力采样数据支持的聚合统计字段列表。 |
#### weight
体重数据类型常量及数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
#### 常量
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 名称 | 类型 | 说明 |
| --- | --- | --- |
| DATA_TYPE | [healthStore.DataType](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/health-api-healthstore.md) | 体重数据类型。 |
#### Model
type Model = healthModels.Weight
体重采样数据模型。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthModels.Weight](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthmodels.md) | 体重采样数据模型。 |
#### Fields
type Fields = healthFields.Weight
体重采样数据字段列表。
**系统能力：** SystemCapability.Health.HealthStore
**起始版本：** 5.0.0(12)
| 类型 | **说明** |
| --- | --- |
| [healthFields.Weight](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Health Service Kit（运动健康服务）/ArkTS API/运动健康数据类型常量及模型定义/health-api-healthfields.md) | 体重采样数据字段列表。 |