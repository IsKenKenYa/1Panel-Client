---
name: hmos-location-kit-geocode
description: 将地理编码与经纬度坐标相互转换，支持正地理编码（地址转坐标）和逆地理编码（坐标转地址），需要网络连接和位置服务开启，适用于地址解析、位置描述、地图导航场景
---

# 正地理编码与逆地理编码技能

## 功能描述

本技能提供地理编码与逆地理编码转换能力，实现经纬度坐标与地理描述之间的双向转换：

- **正地理编码**：将地理位置描述（如"上海市浦东新区xx路xx号")转换为具体的经纬度坐标
- **逆地理编码**：将经纬度坐标转换为详细的地理位置描述，包含国家、省市区、街道、门牌号等信息

功能特点：
- 支持多语言描述（中文/英文）
- 支持设置经纬度范围限制查询结果
- 支持批量查询（最多10个结果）
- 需要访问后端服务，要求设备联网
- 仅支持WGS-84坐标系

## 使用场景

### 触发词
- "地址转坐标" - 正地理编码
- "坐标转地址" - 逆地理编码
- "地理编码" - 正地理编码功能
- "逆地理编码" - 逆地理编码功能
- "解析地址" - 获取地址的经纬度坐标
- "位置描述" - 根据坐标获取地址描述

### 能做
- 将详细的地址描述转换为精确的经纬度坐标
- 将经纬度坐标转换为详细的地址描述信息
- 提供多种地址格式输出（国家、省市区、街道等）
- 支持设置查询结果的语言（中文/英文）
- 支持限制查询结果的地理范围
- 支持批量查询多个匹配结果

### 绝不做
- 不执行定位功能（定位需要使用其他Location Kit API）
- 不处理超出WGS-84坐标系范围的坐标转换
- 不在离线状态下执行编码转换（必须联网）
- 不在位置服务不可用时强制执行编码转换
- 不处理超长地址描述（最大100字符）

### 补充
- 需要先调用isGeocoderAvailable()判断服务是否可用
- 需确保设备联网，正地理编码与逆地理编码功能需要访问后端服务
- 建议在真机上验证，X86模拟器不支持地理编码功能
- 地址描述字符串长度不超过100字符
- 经纬度坐标必须在有效范围内：纬度-90到90，经度-180到180
- maxItems参数建议值小于10

## 调用规范和规则

### 输入约束
- **地址描述长度**：正地理编码时，description字符串长度不超过100字符
- **经纬度范围**：纬度取值范围-90到90，经度取值范围-180到180
- **批量查询限制**：maxItems参数建议小于10，取值范围大于等于0
- **语言参数**：locale只支持"zh"(中文)和"en"(英文)
- **国家码参数**：country参数采用ISO 3166-1 alpha-2格式，如"CN"代表中国

### 执行约束
- **网络依赖**：必须确保设备联网，否则返回3301300或3301400错误
- **服务可用性**：必须先调用isGeocoderAvailable()确认服务可用
- **执行次数**：建议增加重试机制，网络异常时可重试最多3次
- **执行超时**：网络请求超时建议设置为10秒

### 内容约束
- **禁止伪造API**：只能使用geoLocationManager模块提供的真实API
- **禁止硬编码坐标**：禁止在代码中硬编码经纬度坐标值
- **禁止敏感信息**：地址描述中禁止包含用户隐私信息
- **禁止错误处理缺失**：所有API调用必须有try-catch错误处理

### 降级约束
- **服务不可用**：当isGeocoderAvailable()返回false时，提示用户地理编码服务不可用
- **网络失败**：网络请求失败时，提示用户检查网络连接并重试
- **查询失败**：查询结果为空时，提示用户地址描述不准确或坐标不在有效范围内
- **模拟器环境**：X86模拟器环境提示用户使用真机验证

## 调用流程和步骤

### 步骤1：准备阶段 - 判断服务可用性

**前置校验**：
1. 检查设备是否联网
2. 检查位置服务是否开启
3. 调用isGeocoderAvailable()判断地理编码服务是否可用

**示例代码**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

function checkGeocoderService(): boolean {
  try {
    let isAvailable = geoLocationManager.isGeocoderAvailable();
    if (!isAvailable) {
      console.warn('地理编码服务不可用，请检查设备是否联网');
      return false;
    }
    console.info('地理编码服务可用');
    return true;
  } catch (err) {
    console.error('检查地理编码服务状态失败: errCode=' + err.code + ', message=' + err.message);
    return false;
  }
}
```

### 步骤2：逆地理编码 - 将坐标转换为地址描述

**功能说明**：将经纬度坐标转换为详细的地理地址描述

**参数准备**：
```typescript
interface ReverseGeoCodeRequest {
  latitude: number;      // 必填，纬度，取值范围-90到90
  longitude: number;     // 必填，经度，取值范围-180到180
  locale?: string;       // 可选，语言，"zh"或"en"
  maxItems?: number;     // 可选，返回结果最大个数，建议<10
  country?: string;      // 可选，国家码，如"CN"
}
```

**Callback方式调用**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

function reverseGeocodeWithCallback(
  latitude: number,
  longitude: number,
  maxItems: number = 1
): void {
  if (!checkGeocoderService()) {
    return;
  }

  let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
    latitude: latitude,
    longitude: longitude,
    maxItems: maxItems,
    locale: 'zh'
  };

  try {
    geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest, (err, data) => {
      if (err) {
        console.error('逆地理编码失败: err=' + JSON.stringify(err));
        return;
      }
      if (data && data.length > 0) {
        console.info('逆地理编码成功，结果数量: ' + data.length);
        data.forEach((address, index) => {
          console.info(`地址${index + 1}:`);
          console.info(`  经纬度: (${address.latitude}, ${address.longitude})`);
          console.info(`  国家: ${address.countryName}`);
          console.info(`  省份: ${address.administrativeArea}`);
          console.info(`  城市: ${address.locality}`);
          console.info(`  区县: ${address.subLocality}`);
          console.info(`  街道: ${address.roadName}`);
          console.info(`  详细地址: ${address.placeName}`);
        });
      } else {
        console.warn('未查询到地址信息，请检查坐标是否有效');
      }
    });
  } catch (err) {
    console.error('逆地理编码调用异常: errCode=' + err.code + ', message=' + err.message);
  }
}
```

**Promise方式调用**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function reverseGeocodeWithPromise(
  latitude: number,
  longitude: number,
  maxItems: number = 1
): Promise<Array<geoLocationManager.GeoAddress> | null> {
  if (!checkGeocoderService()) {
    return null;
  }

  let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
    latitude: latitude,
    longitude: longitude,
    maxItems: maxItems,
    locale: 'zh'
  };

  try {
    const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
    console.info('逆地理编码成功，结果数量: ' + addresses.length);
    return addresses;
  } catch (error) {
    let businessError = error as BusinessError;
    console.error('逆地理编码失败: errCode=' + businessError.code + ', message=' + businessError.message);
    return null;
  }
}
```

### 步骤3：正地理编码 - 将地址描述转换为坐标

**功能说明**：将地理位置描述转换为经纬度坐标列表

**参数准备**：
```typescript
interface GeoCodeRequest {
  description: string;      // 必填，地址描述，如"上海市浦东新区xx路xx号"，长度<=100
  locale?: string;          // 可选，语言，"zh"或"en"
  maxItems?: number;        // 可选，返回结果最大个数，建议<10
  minLatitude?: number;     // 可选，最小纬度，设置范围时必填
  minLongitude?: number;    // 可选，最小经度，设置范围时必填
  maxLatitude?: number;     // 可选，最大纬度，设置范围时必填
  maxLongitude?: number;    // 可选，最大经度，设置范围时必填
}
```

**Callback方式调用**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';

function geocodeWithCallback(
  addressDescription: string,
  maxItems: number = 1
): void {
  if (!checkGeocoderService()) {
    return;
  }

  if (addressDescription.length > 100) {
    console.error('地址描述过长，最大长度100字符');
    return;
  }

  let geocodeRequest: geoLocationManager.GeoCodeRequest = {
    description: addressDescription,
    maxItems: maxItems,
    locale: 'zh'
  };

  try {
    geoLocationManager.getAddressesFromLocationName(geocodeRequest, (err, data) => {
      if (err) {
        console.error('正地理编码失败: err=' + JSON.stringify(err));
        return;
      }
      if (data && data.length > 0) {
        console.info('正地理编码成功，找到' + data.length + '个匹配地址');
        data.forEach((address, index) => {
          console.info(`匹配${index + 1}:`);
          console.info(`  经纬度: (${address.latitude}, ${address.longitude})`);
          console.info(`  详细地址: ${address.placeName}`);
        });
      } else {
        console.warn('未找到匹配地址，请检查地址描述是否准确');
      }
    });
  } catch (err) {
    console.error('正地理编码调用异常: errCode=' + err.code + ', message=' + err.message);
  }
}
```

**Promise方式调用（带经纬度范围限制）**：
```typescript
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function geocodeWithRange(
  addressDescription: string,
  minLat: number,
  minLon: number,
  maxLat: number,
  maxLon: number,
  maxItems: number = 1
): Promise<Array<geoLocationManager.GeoAddress> | null> {
  if (!checkGeocoderService()) {
    return null;
  }

  if (addressDescription.length > 100) {
    console.error('地址描述过长，最大长度100字符');
    return null;
  }

  let geocodeRequest: geoLocationManager.GeoCodeRequest = {
    description: addressDescription,
    maxItems: maxItems,
    locale: 'zh',
    minLatitude: minLat,
    minLongitude: minLon,
    maxLatitude: maxLat,
    maxLongitude: maxLon
  };

  try {
    const addresses = await geoLocationManager.getAddressesFromLocationName(geocodeRequest);
    console.info('正地理编码成功，在指定范围内找到' + addresses.length + '个匹配地址');
    return addresses;
  } catch (error) {
    let businessError = error as BusinessError;
    console.error('正地理编码失败: errCode=' + businessError.code + ', message=' + businessError.message);
    return null;
  }
}
```

### 步骤4：错误处理

**常见错误码处理**：
```typescript
function handleGeocodeError(errorCode: number): string {
  switch (errorCode) {
    case 401:
      return '参数错误，请检查参数类型和取值范围';
    case 801:
      return '设备不支持地理编码功能';
    case 3301000:
      return '位置服务不可用，请检查位置服务是否正常';
    case 3301300:
      return '逆地理编码查询失败，请检查网络连接或使用真机验证';
    case 3301400:
      return '正地理编码查询失败，请检查地址描述参数或网络连接';
    default:
      return '未知错误，错误码: ' + errorCode;
  }
}
```

### 步骤5：降级处理

**网络异常降级方案**：
```typescript
async function geocodeWithRetry(
  addressDescription: string,
  maxRetries: number = 3
): Promise<Array<geoLocationManager.GeoAddress> | null> {
  let retryCount = 0;
  
  while (retryCount < maxRetries) {
    try {
      const addresses = await geocodeWithPromise(addressDescription, 1);
      if (addresses && addresses.length > 0) {
        return addresses;
      }
    } catch (error) {
      retryCount++;
      console.warn(`第${retryCount}次尝试失败，正在重试...`);
      if (retryCount < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  }
  
  console.error('重试' + maxRetries + '次后仍然失败，请检查网络连接');
  return null;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限验证失败 | 申请ohos.permission.APPROXIMATELY_LOCATION权限 |
| 401 | 参数错误 | 检查参数类型、取值范围、必填参数是否完整 |
| 801 | 设备能力不支持 | 检查设备是否支持地理编码功能，建议使用真机验证 |
| 3301000 | 位置服务不可用 | 检查位置服务是否启动异常，建议增加重试机制 |
| 3301300 | 逆地理编码查询失败 | 1.检查网络连接 2.避免使用X86模拟器 3.增加重试机制 |
| 3301400 | 正地理编码查询失败 | 1.检查地址描述参数是否正确 2.检查网络连接 3.重试查询 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocationKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS API Version 9或更高版本
- 设备需要支持SystemCapability.Location.Location.Geocoder能力
- 需要联网环境（真机验证）
- 不支持X86模拟器

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.LocationKit'
```
**解决方法**：确保项目依赖正确配置，检查package.json中是否包含@kit.LocationKit依赖

**问题2：类型定义错误**
```
Error: Property 'getAddressesFromLocation' does not exist on type 'geoLocationManager'
```
**解决方法**：确保使用正确的API版本（API version 9+），检查导入语句是否正确

**问题3：权限配置缺失**
```
Error: Permission verification failed
```
**解决方法**：在module.json5中添加位置权限配置：
```json
{
  "requestPermissions": [
    {
      "name": "ohos.permission.APPROXIMATELY_LOCATION",
      "reason": "用于地理编码功能"
    }
  ]
}
```

## 常见问题与解决方法

### Q1：地理编码服务不可用怎么办？
**原因**：设备未联网或位置服务异常
**解决方法**：
- 检查设备网络连接状态
- 检查位置服务是否开启
- 使用真机验证，避免使用X86模拟器
- 增加重试机制

### Q2：查询结果为空怎么办？
**原因**：地址描述不准确或坐标不在有效范围内
**解决方法**：
- 正地理编码：确保地址描述准确完整，包含省市区街道等信息
- 逆地理编码：确保经纬度坐标在有效范围内（纬度-90到90，经度-180到180）
- 设置合理的maxItems参数（建议小于10）

### Q3：查询失败并返回3301300/3301400错误码？
**原因**：网络请求失败或服务端异常
**解决方法**：
- 检查网络连接状态
- 增加重试机制（建议最多重试3次）
- 设置合理的超时时间（建议10秒）
- 使用真机验证，X86模拟器不支持地理编码功能

### Q4：多地重名如何获取准确结果？
**原因**：相同地址名称可能存在于多个城市
**解决方法**：
- 使用经纬度范围限制查询结果（设置minLatitude、minLongitude、maxLatitude、maxLongitude）
- 地址描述中包含更详细的省市区信息
- 设置合理的maxItems参数获取多个结果进行筛选

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operationType": "geocode|reverseGeocode",
  "inputParams": {
    "description": "地址描述或坐标信息"
  },
  "resultCount": 3,
  "addresses": [
    {
      "latitude": 31.12,
      "longitude": 121.11,
      "countryName": "中国",
      "administrativeArea": "上海市",
      "locality": "上海市",
      "subLocality": "浦东新区",
      "roadName": "XX路",
      "placeName": "详细地址描述"
    }
  ],
  "apiUsed": [
    "geoLocationManager.isGeocoderAvailable",
    "geoLocationManager.getAddressesFromLocation",
    "geoLocationManager.getAddressesFromLocationName"
  ],
  "executionTime": "150ms",
  "networkRequired": true
}
```

## 参考文档

- [正地理编码与逆地理编码开发指导](references/geocode-guidelines.md)
- [@ohos.geoLocationManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-geolocationmanager)
- [位置服务错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-geolocationmanager)

## 完整示例代码

- [ArkTS逆地理编码示例(Callback)](assets/reverse_geocode_callback.ets)
- [ArkTS逆地理编码示例(Promise)](assets/reverse_geocode_promise.ets)
- [ArkTS正地理编码示例(Callback)](assets/geocode_callback.ets)
- [ArkTS正地理编码示例(Promise)](assets/geocode_promise.ets)
- [完整应用示例](assets/geocode_demo.ets)

## 测试用例

### 正向测试用例
- [测试正地理编码基本功能](tests/test_geocode_positive.py)：使用准确地址描述查询坐标
- [测试逆地理编码基本功能](tests/test_reverse_geocode_positive.py)：使用有效坐标查询地址
- [测试批量查询功能](tests/test_batch_query.py)：设置maxItems参数查询多个结果

### 边界测试用例
- [测试地址描述长度边界](tests/test_description_length_boundary.py)：测试100字符长度限制
- [测试经纬度坐标边界](tests/test_coordinate_boundary.py)：测试纬度-90到90，经度-180到180边界值
- [测试批量查询数量边界](tests/test_maxitems_boundary.py)：测试maxItems参数边界值

### 异常测试用例
- [测试服务不可用场景](tests/test_service_unavailable.py)：模拟isGeocoderAvailable返回false
- [测试网络异常场景](tests/test_network_error.py)：模拟网络请求失败
- [测试参数错误场景](tests/test_parameter_error.py)：测试无效参数、缺失必填参数等
- [测试超出范围场景](tests/test_out_of_range.py)：测试坐标超出有效范围