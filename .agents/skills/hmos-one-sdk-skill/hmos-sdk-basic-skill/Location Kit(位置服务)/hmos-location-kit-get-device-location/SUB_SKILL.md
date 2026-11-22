---
name: hmos-location-kit-get-device-location
description: 获取设备位置信息，支持单次定位和持续定位，仅支持WGS-84坐标系，适用于签到打卡、导航、运动轨迹场景
---

# 获取设备的位置信息开发指导(ArkTS)

## 功能描述

通过HarmonyOS Location Kit获取设备的位置信息，包括实时位置、历史位置以及监听设备位置变化。支持单次定位和持续定位两种模式，满足不同场景的位置需求。本模块仅支持WGS-84坐标系，如需其他坐标系需要额外转换。

**核心能力**：
- 单次定位：获取当前位置或最近一次缓存位置
- 持续定位：持续监听位置变化，实时上报位置信息
- 位置开关状态查询：判断位置服务是否开启
- 定位策略配置：支持精度优先和速度优先策略

**适用场景**：
- 单次定位：查看当前位置、签到打卡、服务推荐等
- 持续定位：导航、运动轨迹记录、出行等实时位置场景

## 使用场景

### 触发词
- "获取设备位置"
- "定位当前位置"
- "持续定位"
- "获取地理位置"
- "位置信息"
- "签到打卡定位"
- "导航定位"
- "运动轨迹定位"
- "Location Kit"
- "geoLocationManager"

### 能做
- 获取设备实时位置信息（经纬度、高度、速度、方向等）
- 获取最近一次缓存的定位结果
- 开启持续定位，实时监听位置变化
- 查询位置服务开关状态
- 配置定位策略（精度优先、速度优先）
- 配置定位超时时间
- 配置定位场景（导航、运动、出行等）

### 绝不做
- 不处理坐标系转换（仅返回WGS-84坐标系）
- 不处理地理编码/逆地理编码（坐标与地址互转）
- 不处理地理围栏功能
- 不处理后台定位权限申请（需单独申请）
- 不处理卫星状态信息获取
- 不处理国家码查询

### 补充
- 必须申请位置权限：ohos.permission.APPROXIMATELY_LOCATION（模糊位置）或 ohos.permission.LOCATION（精确位置）
- 位置服务开关必须处于开启状态
- 定位超时建议设置为10秒以上
- 持续定位结束时应及时取消订阅，避免功耗浪费
- API版本要求：首批接口从API version 9开始支持，部分新接口从API version 12开始支持

## 调用规范和规则

### 输入约束
- **定位策略参数**：
  - `locatingPriority`: 必须为 `PRIORITY_ACCURACY` 或 `PRIORITY_LOCATING_SPEED`
  - `locationScenario`: 必须为 `UserActivityScenario` 或 `PowerConsumptionScenario` 的有效枚举值
- **超时参数**：
  - `locatingTimeoutMs`: 最小值为1000毫秒，建议值为10000毫秒
  - `timeoutMs`: 最小值为1000毫秒，默认值为5000毫秒
- **上报间隔参数**：
  - `interval`: 单位为秒，默认值为1秒，取值范围≥0
  - `timeInterval`: 单位为秒，默认值为1秒（GNSS）或20秒（网络定位）
- **精度参数**：
  - `maxAccuracy`: 单位为米，默认值为0，取值范围≥0
  - 精度优先场景建议设置为>10米
  - 低功耗场景建议设置为>100米

### 执行约束
- **单次定位最大耗时**：建议10秒（由`locatingTimeoutMs`参数控制）
- **持续定位上报频率**：默认1秒，可通过`interval`参数调整
- **权限检查时机**：调用API前必须完成权限申请
- **位置开关检查**：调用定位API前必须检查位置开关状态
- **订阅管理**：持续定位时必须保存回调函数引用，用于后续取消订阅

### 内容约束
- **禁止使用**：
  - 禁止在未申请权限时调用定位API
  - 禁止在位置开关关闭时强制调用定位API
  - 禁止使用undefined或null作为回调函数
  - 禁止持续定位后不取消订阅
- **坐标系说明**：
  - 返回坐标均为WGS-84坐标系
  - 不提供坐标系转换功能，需使用Map Kit或其他工具转换
- **参数验证**：
  - 必须验证定位策略参数的有效性
  - 必须验证超时参数的合法性（≥1000毫秒）

### 降级约束
- **网络定位失败**：
  - 当GNSS定位不可用时，系统自动切换到网络定位
  - 若网络定位也失败，返回错误码3301200
- **位置开关关闭**：
  - 提示用户位置服务未开启
  - 引导用户打开位置开关（使用requestGlobalSwitch）
  - 返回错误码3301100
- **权限不足**：
  - 提示用户申请位置权限
  - 返回错误码201或-2/-3（持续定位时）
- **定位超时**：
  - 单次定位超过设定时间未返回结果
  - 建议使用缓存位置getLastLocation作为降级方案
- **缓存位置不可用**：
  - 系统当前没有缓存位置时，getLastLocation返回错误
  - 降级方案：提示用户稍后重试或等待位置开关开启

## 调用流程和步骤

### 步骤1：权限申请（前置准备）

**说明**：定位功能需要申请位置权限，参考申请位置权限开发指导完成权限申请。

**关键权限**：
- `ohos.permission.APPROXIMATELY_LOCATION`：模糊位置权限
- `ohos.permission.LOCATION`：精确位置权限（需要同时申请APPROXIMATELY_LOCATION）
- `ohos.permission.LOCATION_IN_BACKGROUND`：后台定位权限（可选）

**参考文档**：[申请位置权限开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/location-permission-guidelines)

### 步骤2：导入模块

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**说明**：所有与基础定位能力相关的功能API都通过geoLocationManager模块提供。

### 步骤3：检查位置开关状态

**前置校验**：调用定位API前必须检查位置服务开关是否开启。

**示例代码**：
```typescript
try {
    let locationEnabled = geoLocationManager.isLocationEnabled();
    if (!locationEnabled) {
        console.error('位置服务未开启，请打开位置开关');
        // 可引导用户打开位置开关
        return;
    }
    console.info('位置服务已开启');
} catch (err) {
    console.error("检查位置开关失败: errCode:" + err.code + ", message:" + err.message);
}
```

**参数说明**：
- 返回值：boolean类型，true表示位置开关开启，false表示位置开关关闭
- 错误码：
  - 801：设备不支持该能力
  - 3301000：位置服务不可用

**API参考**：[geoLocationManager.isLocationEnabled](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)

### 步骤4：单次定位（方式一：获取缓存位置）

**适用场景**：快速获取最近一次定位结果，减少系统功耗。适合对位置新鲜度要求不高的场景。

**前置校验**：
- 位置开关已开启
- 系统有缓存位置

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

try {
    let location = geoLocationManager.getLastLocation();
    console.info('缓存位置信息: latitude=' + location.latitude + 
                 ', longitude=' + location.longitude + 
                 ', accuracy=' + location.accuracy +
                 ', timeStamp=' + location.timeStamp);
    
    // 可根据时间戳判断位置新鲜度
    let currentTime = Date.now();
    let locationAge = currentTime - location.timeStamp;
    if (locationAge > 60000) { // 超过60秒
        console.warn('缓存位置较旧，建议重新定位');
    }
} catch (err) {
    console.error("获取缓存位置失败: errCode:" + JSON.stringify(err));
    // 降级：使用getCurrentLocation重新定位
}
```

**返回参数说明**：
- `latitude`：纬度，取值范围-90到90，正值表示北纬
- `longitude`：经度，取值范围-180到180，正值表示东经
- `altitude`：高度，单位米
- `accuracy`：精度，单位米
- `speed`：速度，单位米/秒
- `direction`：航向，单位度，取值范围0到360
- `timeStamp`：位置时间戳，UTC格式
- `timeSinceBoot`：获取位置成功的时间戳（纳秒）

**错误码**：
- 201：权限校验失败
- 801：设备不支持该能力
- 3301000：位置服务不可用
- 3301100：位置开关关闭
- 3301200：无法获取地理位置（无缓存位置）

**API参考**：[geoLocationManager.getLastLocation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)

### 步骤5：单次定位（方式二：获取当前位置）

**适用场景**：获取实时位置，适合签到打卡、服务推荐等需要当前位置的场景。

**前置校验**：
- 位置开关已开启
- 定位策略和超时参数已配置

**参数配置**：
```typescript
let request: geoLocationManager.SingleLocationRequest = {
    'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_ACCURACY, // 精度优先
    'locatingTimeoutMs': 10000 // 超时10秒
};
```

**定位策略说明**：
- `PRIORITY_ACCURACY`：精度优先，返回一段时间内精度最好的结果，功耗较高
- `PRIORITY_LOCATING_SPEED`：速度优先，返回最先获取的定位结果，功耗较高
- 两种策略都会同时使用GNSS和网络定位技术

**示例代码（Promise方式）**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

let request: geoLocationManager.SingleLocationRequest = {
    'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_LOCATING_SPEED,
    'locatingTimeoutMs': 10000
};

try {
    geoLocationManager.getCurrentLocation(request).then((result) => {
        console.info('当前位置: latitude=' + result.latitude + 
                     ', longitude=' + result.longitude +
                     ', accuracy=' + result.accuracy +
                     ', speed=' + result.speed);
    }).catch((error: BusinessError) => {
        console.error('定位失败: error=' + JSON.stringify(error));
        // 根据错误码进行降级处理
        switch (error.code) {
            case 3301100:
                console.error('位置开关关闭');
                break;
            case 3301200:
                console.error('无法获取地理位置');
                // 降级：尝试获取缓存位置
                try {
                    let cachedLocation = geoLocationManager.getLastLocation();
                    console.info('使用缓存位置: ' + JSON.stringify(cachedLocation));
                } catch (cacheErr) {
                    console.error('缓存位置也不可用');
                }
                break;
            default:
                console.error('未知错误: ' + error.code);
        }
    });
} catch (err) {
    console.error("调用定位API异常: errCode:" + JSON.stringify(err));
}
```

**示例代码（Callback方式）**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

let request: geoLocationManager.SingleLocationRequest = {
    'locatingPriority': geoLocationManager.LocatingPriority.PRIORITY_ACCURACY,
    'locatingTimeoutMs': 10000
};

let locationCallback = (err: BusinessError, location: geoLocationManager.Location): void => {
    if (err) {
        console.error('定位失败: err=' + JSON.stringify(err));
        return;
    }
    if (location) {
        console.info('当前位置: latitude=' + location.latitude + 
                     ', longitude=' + location.longitude +
                     ', accuracy=' + location.accuracy);
    }
};

try {
    geoLocationManager.getCurrentLocation(request, locationCallback);
} catch (err) {
    console.error("调用定位API异常: errCode:" + JSON.stringify(err));
}
```

**错误码**：
- 201：权限校验失败
- 401：参数错误
- 801：设备不支持该能力
- 3301000：位置服务不可用
- 3301100：位置开关关闭
- 3301200：无法获取地理位置

**API参考**：[geoLocationManager.getCurrentLocation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)

### 步骤6：持续定位

**适用场景**：导航、运动轨迹记录、出行等需要实时位置的场景。

**前置校验**：
- 位置开关已开启
- 定位场景和上报间隔已配置
- 回调函数已定义并保存引用

**参数配置**：
```typescript
let request: geoLocationManager.ContinuousLocationRequest = {
    'interval': 1, // 上报间隔1秒
    'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION // 导航场景
};
```

**定位场景说明**：
- `NAVIGATION`：导航场景，户外实时位置，使用GNSS定位，功耗高
- `SPORT`：运动场景，记录轨迹，使用GNSS定位，功耗高
- `TRANSPORT`：出行场景，打车/公共交通，使用GNSS定位，功耗高
- `DAILY_LIFE_SERVICE`：日常服务场景，不需要精确位置，仅网络定位，功耗低

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

let request: geoLocationManager.ContinuousLocationRequest = {
    'interval': 1,
    'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
};

// 必须保存回调函数引用，用于后续取消订阅
let locationCallback = (location: geoLocationManager.Location): void => {
    console.info('位置更新: latitude=' + location.latitude + 
                 ', longitude=' + location.longitude +
                 ', accuracy=' + location.accuracy +
                 ', speed=' + location.speed +
                 ', direction=' + location.direction);
};

try {
    // 开启持续定位
    geoLocationManager.on('locationChange', request, locationCallback);
    console.info('持续定位已开启');
} catch (err) {
    console.error("开启持续定位失败: errCode:" + JSON.stringify(err));
}
```

**错误码**：
- 201：权限校验失败
- 401：参数错误
- 801：设备不支持该能力
- 3301000：位置服务不可用
- 3301100：位置开关关闭

**API参考**：[geoLocationManager.on('locationChange')](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)

### 步骤7：取消持续定位

**说明**：不需要定位时应及时取消订阅，避免功耗浪费。

**前置条件**：
- 持续定位已开启
- 回调函数引用已保存（必须与开启时传入的回调函数保持一致）

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

// 使用开启持续定位时保存的同一个回调函数引用
try {
    geoLocationManager.off('locationChange', locationCallback);
    console.info('持续定位已取消');
} catch (err) {
    console.error("取消持续定位失败: errCode:" + JSON.stringify(err));
}
```

**重要提示**：
- `off`方法传入的回调函数必须与`on`方法传入的回调函数保持一致
- 若不传入callback参数，则取消所有该类型的订阅

**API参考**：[geoLocationManager.off('locationChange')](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)

### 步骤8：订阅定位错误（可选）

**适用场景**：持续定位过程中需要监听错误状态变化。

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

let locationErrorCallback = (errCode: geoLocationManager.LocationError): void => {
    console.info('定位错误变化: ' + JSON.stringify(errCode));
    
    switch (errCode) {
        case geoLocationManager.LocationError.LOCATING_FAILED_LOCATION_PERMISSION_DENIED:
            console.error('位置权限被拒绝');
            break;
        case geoLocationManager.LocationError.LOCATING_FAILED_BACKGROUND_PERMISSION_DENIED:
            console.error('后台定位权限被拒绝');
            break;
        case geoLocationManager.LocationError.LOCATING_FAILED_LOCATION_SWITCH_OFF:
            console.error('位置开关关闭');
            break;
        case geoLocationManager.LocationError.LOCATING_FAILED_INTERNET_ACCESS_FAILURE:
            console.error('网络访问失败');
            break;
        default:
            console.error('定位失败: ' + errCode);
    }
};

try {
    geoLocationManager.on('locationError', locationErrorCallback);
    console.info('错误订阅已开启');
} catch (err) {
    console.error("订阅定位错误失败: errCode:" + JSON.stringify(err));
}

// 取消订阅
try {
    geoLocationManager.off('locationError', locationErrorCallback);
    console.info('错误订阅已取消');
} catch (err) {
    console.error("取消订阅定位错误失败: errCode:" + JSON.stringify(err));
}
```

**错误类型说明**：
- `LOCATING_FAILED_LOCATION_PERMISSION_DENIED` (-2)：位置权限校验失败
- `LOCATING_FAILED_BACKGROUND_PERMISSION_DENIED` (-3)：后台定位权限校验失败
- `LOCATING_FAILED_LOCATION_SWITCH_OFF` (-4)：位置开关关闭
- `LOCATING_FAILED_INTERNET_ACCESS_FAILURE` (-5)：网络访问失败

**API版本要求**：API version 12及以上

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败，应用没有调用API所需的权限 | 申请ohos.permission.APPROXIMATELY_LOCATION或ohos.permission.LOCATION权限 |
| 401 | 参数错误，可能原因：必填参数未指定、参数类型错误、参数验证失败 | 检查参数类型和取值范围，确保必填参数已填写 |
| 801 | 设备能力不支持，无法调用API | 检查设备是否支持位置服务能力 |
| 3301000 | 位置服务不可用 | 检查位置服务是否正常启动 |
| 3301100 | 位置开关关闭 | 引导用户打开位置开关，使用requestGlobalSwitch拉起设置界面 |
| 3301200 | 无法获取地理位置 | 检查网络连接，尝试使用缓存位置getLastLocation作为降级方案 |
| -2 | 持续定位时位置权限被拒绝（LOCATING_FAILED_LOCATION_PERMISSION_DENIED） | 申请位置权限 |
| -3 | 持续定位时后台定位权限被拒绝（LOCATING_FAILED_BACKGROUND_PERMISSION_DENIED） | 申请后台定位权限ohos.permission.LOCATION_IN_BACKGROUND |
| -4 | 持续定位时位置开关关闭（LOCATING_FAILED_LOCATION_SWITCH_OFF） | 引导用户打开位置开关 |
| -5 | 持续定位时网络访问失败（LOCATING_FAILED_INTERNET_ACCESS_FAILURE） | 检查网络连接状态 |

## 编译和修复问题

### 依赖声明

**module.json5权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:location_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:precise_location_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**导入依赖**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- **HarmonyOS版本**：API version 9及以上（部分接口需要API version 12及以上）
- **开发环境**：DevEco Studio 3.0及以上
- **设备要求**：支持位置服务的HarmonyOS设备
- **系统能力**：SystemCapability.Location.Location.Core

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocationKit'
```
**解决方法**：确保DevEco Studio版本支持HarmonyOS API 9及以上，检查SDK配置。

**问题2：类型定义错误**
```
Error: Property 'SingleLocationRequest' does not exist on type 'geoLocationManager'
```
**解决方法**：SingleLocationRequest需要API version 12及以上，检查API版本配置。

**问题3：权限未配置**
```
Error: Permission verification failed
```
**解决方法**：在module.json5中配置位置权限，并确保用户已授权。

**问题4：回调函数类型不匹配**
```
Error: Type 'void' is not assignable to type 'Callback<Location>'
```
**解决方法**：确保回调函数参数和返回类型与API定义一致，参考API文档中的类型定义。

## 常见问题与解决方法

### Q1：定位返回坐标是什么坐标系？
**原因**：Location Kit仅支持WGS-84坐标系。
**解决方法**：
- 如需GCJ-02坐标系（火星坐标系），使用Map Kit提供的坐标转换工具
- 参考文档：[坐标转换工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-convert-coordinate)

### Q2：定位失败，提示位置开关关闭？
**原因**：设备位置服务未开启。
**解决方法**：
- 使用geoLocationManager.isLocationEnabled()检查开关状态
- 引导用户打开位置开关，可使用requestGlobalSwitch拉起设置界面
- 监听位置开关状态变化，订阅'locationEnabledChange'事件

### Q3：持续定位功耗过高？
**原因**：GNSS定位功耗较高，特别是精度优先策略。
**解决方法**：
- 根据场景选择合适的定位策略：
  - 导航/运动/出行：使用UserActivityScenario（功耗高）
  - 日常服务：使用DAILY_LIFE_SERVICE（功耗低）
  - 无功耗场景：使用NO_POWER_CONSUMPTION（被动定位）
- 及时取消持续定位订阅
- 调整上报间隔interval参数，降低上报频率

### Q4：单次定位超时，未返回结果？
**原因**：定位超时设置过短或定位条件不佳（室内、无网络等）。
**解决方法**：
- 增加定位超时时间locatingTimeoutMs，建议10秒以上
- 检查网络连接状态
- 尝试使用缓存位置getLastLocation作为降级方案
- 判断缓存位置新鲜度，若不满足需求再重新定位

### Q5：后台定位失败？
**原因**：应用在后台时位置权限不足。
**解决方法**：
- 申请后台定位权限ohos.permission.LOCATION_IN_BACKGROUND
- 参考文档：[申请位置权限开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/location-permission-guidelines)
- 监听定位错误事件，处理LOCATING_FAILED_BACKGROUND_PERMISSION_DENIED错误

### Q6：如何选择定位策略？
**原因**：不同场景需要不同的定位策略。
**解决方法**：
- **精度要求高**：使用PRIORITY_ACCURACY，返回精度最好的结果
- **速度要求快**：使用PRIORITY_LOCATING_SPEED，返回最先获取的结果
- **功耗敏感**：使用网络定位或低功耗场景，避免GNSS定位
- **根据场景选择**：
  - 导航：NAVIGATION（户外实时位置）
  - 运动：SPORT（轨迹记录）
  - 出行：TRANSPORT（打车/公交）
  - 日常：DAILY_LIFE_SERVICE（不需要精确位置）

### Q7：如何判断缓存位置是否可用？
**原因**：缓存位置可能较旧，不满足业务需求。
**解决方法**：
- 使用getLastLocation获取缓存位置
- 对比时间戳timeStamp与当前时间，判断位置新鲜度
- 若新鲜度不满足要求，使用getCurrentLocation重新定位
- 示例代码见步骤4

### Q8：取消持续定位时回调函数不匹配？
**原因**：off方法传入的回调函数与on方法传入的回调函数不一致。
**解决方法**：
- 使用同一个回调函数引用（变量）
- 不要在off时重新定义回调函数
- 示例代码见步骤7

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "location": {
    "latitude": 31.12,
    "longitude": 121.11,
    "altitude": 10.5,
    "accuracy": 15.0,
    "speed": 0.0,
    "direction": 180.0,
    "timeStamp": 1672531200000,
    "timeSinceBoot": 1234567890123456
  },
  "coordinateSystem": "WGS-84",
  "apiUsed": [
    "geoLocationManager.isLocationEnabled",
    "geoLocationManager.getLastLocation",
    "geoLocationManager.getCurrentLocation",
    "geoLocationManager.on('locationChange')",
    "geoLocationManager.off('locationChange')"
  ],
  "locationMode": "single or continuous",
  "timestamp": "2026-07-03T10:00:00Z"
}
```

**字段说明**：
- `status`：定位状态，success或failed
- `location`：位置信息对象
- `coordinateSystem`：坐标系类型（固定为WGS-84）
- `apiUsed`：使用的API列表
- `locationMode`：定位模式（single或continuous）
- `timestamp`：获取位置的时间戳

## 参考文档

- [API开发指南](references/location-guidelines.md)
- [API参考说明](references/js-apis-geolocationmanager.md)
- [申请位置权限开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/location-permission-guidelines)
- [坐标转换工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-convert-coordinate)

## 完整示例代码

- [ArkTS单次定位示例](assets/single_location_example.ets)
- [ArkTS持续定位示例](assets/continuous_location_example.ets)
- [ArkTS完整定位流程示例](assets/full_location_example.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [单次定位成功](tests/test_single_location_success.py)：测试正常单次定位流程
- [持续定位成功](tests/test_continuous_location_success.py)：测试正常持续定位流程
- [缓存位置获取成功](tests/test_cached_location_success.py)：测试缓存位置获取

### 边界测试用例
- [定位超时边界测试](tests/test_timeout_boundary.py)：测试最小超时时间1000ms
- [上报间隔边界测试](tests/test_interval_boundary.py)：测试上报间隔0秒和1秒
- [精度参数边界测试](tests/test_accuracy_boundary.py)：测试精度参数取值范围

### 异常测试用例
- [位置开关关闭测试](tests/test_location_switch_off.py)：测试位置开关关闭时的错误处理
- [权限不足测试](tests/test_permission_denied.py)：测试权限不足时的错误处理
- [网络定位失败测试](tests/test_network_failure.py)：测试网络定位失败时的降级处理
- [参数错误测试](tests/test_parameter_error.py)：测试参数错误时的错误处理