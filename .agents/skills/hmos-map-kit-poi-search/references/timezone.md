# 获取时区 API

## 服务概述

获取指定位置的时区信息，包括当前时间、UTC偏移量、夏令时信息等。

- **版本**: 1.0
- **服务标识**: `timezone`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 说明

**当前Map Kit SDK暂未提供时区查询接口**，如需获取时区信息，需调用华为地图Web API：

**端点**:

```
POST https://siteapi.cloud.huawei.com/mapApi/v1/timezoneService/getTimezone?key=API_KEY
```

### Web API 输入参数

| 参数        | 是否必选 | 参数类型         | 描述            | 示例                                   |
|-----------|------|--------------|---------------|--------------------------------------|
| location  | 是    | Coordinate   | 经纬度坐标         | {"lng": 116.397428, "lat": 39.90923} |
| timestamp | 是    | long         | 时间戳（秒），默认当前时间 | 1640995200                           |
| language  | 否    | String(<=16) | 返回结果的语言       | "zh-CN"                              |

### Web API 响应结果

| 字段路径         | 类型     | 说明                    |
|--------------|--------|-----------------------|
| returnCode   | String | 返回码，"0"表示成功           |
| returnDesc   | String | 返回值描述                 |
| dstOffset    | int    | 夏令时的偏移量，单位：秒          |
| rawOffset    | int    | 给定位置与UTC的偏移量（单位：秒）    |
| timezoneId   | String | 时区ID，如"Asia/Shanghai" |
| timeZoneName | String | 时区名称                  |

### curl 示例

```bash
curl -X POST "https://siteapi.cloud.huawei.com/mapApi/v1/timezoneService/getTimezone?key=$HUAWEI_MAP_WEBAPI_AK" \
  -H "Content-Type: application/json" \
  -d '{
    "location": {"lng": 116.397428, "lat": 39.90923},
    "timestamp": 1640995200
  }'
```

### 常见问题

**Q: 如何获取特定时间点的时区信息？**

A: 通过timestamp参数指定时间戳，API会返回该时间点对应的时区信息。

**Q: utcOffset和dstOffset有什么区别？**

A: rawOffset是标准UTC偏移量，dstOffset是夏令时期间的额外偏移量。总偏移量 = rawOffset + dstOffset。

**Q: 时区信息有什么用途？**

A: 可用于跨时区业务的时间转换，如航班时刻表、跨国会议时间安排等。
