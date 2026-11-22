---
name: hmos-map-kit-geocode
description: 地理编码与逆地理编码能力，支持地址转经纬度和经纬度转地址，最多返回10条记录，适用于位置标注、导航定位场景
---

# 地理编码技能

## 功能描述

本技能提供地理编码和逆地理编码能力，是Map Kit地图服务中的位置搜索功能之一。

**核心能力**：
- **正地理编码**：根据结构化地址获取地点的经纬度坐标，最多返回10条记录
- **逆地理编码**：根据经纬度坐标获取对应的地址信息，包括位置描述、区划信息、周边POI等详细信息

**适用场景**：
- 位置标注：将地址转换为地图上的坐标点
- 地址解析：将用户输入的地址转换为经纬度
- 位置描述：根据GPS坐标获取详细的地址信息
- 导航定位：获取目的地的精确坐标
- 位置服务：基于坐标的周边信息查询

**技术特点**：
- 支持多种语言返回
- 支持扩展信息返回（POI、AOI、道路、交叉口等）
- 支持周边AOI查询
- 异步Promise调用模式
- 仅支持Stage模型

## 使用场景

### 触发词
- "地理编码" - 地址转经纬度
- "逆地理编码" - 经纬度转地址
- "地址转坐标" - 地址转经纬度
- "坐标转地址" - 经纬度转地址
- "获取经纬度" - 根据地址查询坐标
- "获取地址信息" - 根据坐标查询地址
- "位置编码" - 地理编码相关功能

### 能做
- 将结构化地址转换为经纬度坐标
- 将经纬度坐标转换为详细地址信息
- 获取地址的行政区划信息（国家、省、市、区等）
- 获取坐标周边的POI信息
- 获取坐标周边的AOI面信息
- 获取坐标附近的道路信息
- 获取坐标附近的交叉口信息
- 支持多语言返回结果

### 绝不做
- 不支持地图渲染和显示
- 不支持路径规划和导航
- 不支持地点搜索（请使用searchByText或nearbySearch）
- 不支持地点详情查询（请使用searchById）
- 不支持自动补全（请使用queryAutoComplete）
- 不处理非Stage模型的应用

### 补充
- 正地理编码最多返回10条记录
- 逆地理编码扩展返回信息时，POI最多展示30个，AOI最多展示10个，Road最多展示3个，交叉口最多展示1个
- 需要申请地图服务权限
- 需要网络连接
- 仅支持HarmonyOS 4.1.0(11)及以上版本

## 调用规范和规则

### 输入约束

**正地理编码输入约束**：
- 地址字符串长度：[1, 512]字符
- 语言代码长度：[1, 16]字符
- bounds参数：有效的经纬度范围对象

**逆地理编码输入约束**：
- 经纬度：有效的LatLng对象，包含latitude和longitude
- 语言代码长度：[1, 16]字符
- 搜索半径：[0, 1000]米，默认1000米
- isExtension：布尔值，是否返回扩展信息
- isNearbyAoi：布尔值，是否返回附近AOI（仅当isExtension=true时生效）
- poiTypes：有效的华为POI分类数组

### 执行约束
- API调用模式：异步Promise
- 最大返回记录数：正地理编码最多10条
- 网络超时：依赖系统默认配置
- 并发限制：避免短时间内大量并发调用
- 重试机制：网络失败时建议延迟重试

### 内容约束
- 禁止使用虚假地址进行测试
- 禁止在高频循环中调用API
- 禁止缓存大量地理编码结果（遵循服务条款）
- 必须处理所有可能的错误码
- 必须验证输入参数的合法性

### 降级约束
- 网络失败：提示用户检查网络连接，延迟重试
- 参数错误：提示用户检查输入参数
- 无结果：提示用户地址或坐标不在服务范围内
- 权限不足：提示用户申请地图服务权限
- 服务不可用：提供备用方案或降级处理

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查应用是否为Stage模型
2. 检查是否已申请地图服务权限
3. 检查网络连接是否正常
4. 验证输入参数的合法性（地址长度、坐标范围等）

**参数准备**：

正地理编码参数：
```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 正地理编码参数
let geocodeParams: site.GeocodeParams = {
  query: 'Piazzale Dante, 41, 55049 Viareggio', // 必填，地址信息
  language: 'en', // 可选，返回结果语言
  bounds: { // 可选，查询结果的搜索范围
    southwest: { latitude: 30.0, longitude: 117.0 },
    northeast: { latitude: 32.0, longitude: 119.0 }
  }
};
```

逆地理编码参数：
```typescript
// 逆地理编码参数
let reverseGeocodeParams: site.ReverseGeocodeParams = {
  location: { // 必填，经纬度坐标
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: 'en', // 可选，返回结果语言
  radius: 200, // 可选，搜索半径，单位：米
  isExtension: true, // 可选，是否返回扩展信息，推荐true
  isNearbyAoi: true, // 可选，是否返回附近AOI，推荐true
  poiTypes: ['RESTAURANT', 'HOTEL'] // 可选，POI类型过滤
};
```

### 步骤2：调用API

**正地理编码示例**：

```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function geocodeAddress(address: string, language?: string): Promise<site.GeocodeResult> {
  try {
    // 参数校验
    if (!address || address.length < 1 || address.length > 512) {
      throw new Error('地址长度必须在1-512字符之间');
    }

    // 构建请求参数
    let params: site.GeocodeParams = {
      query: address,
      language: language || 'zh'
    };

    // 调用正地理编码API
    const result: site.GeocodeResult = await site.geocode(params);
    
    // 结果验证
    if (!result || !result.sites || result.sites.length === 0) {
      console.warn('地理编码成功，但未找到匹配的坐标');
      return result;
    }

    console.info(`地理编码成功，找到${result.sites.length}个结果`);
    result.sites.forEach((site, index) => {
      console.info(`结果${index + 1}: ${site.name}, 经纬度: ${site.location?.latitude}, ${site.location?.longitude}`);
    });

    return result;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`地理编码失败。错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

// 使用示例
geocodeAddress('北京市海淀区中关村', 'zh')
  .then(result => {
    console.info('地理编码结果:', JSON.stringify(result, null, 2));
  })
  .catch(error => {
    console.error('地理编码出错:', error);
  });
```

**逆地理编码示例**：

```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function reverseGeocodeLocation(
  latitude: number,
  longitude: number,
  language?: string,
  radius?: number
): Promise<site.ReverseGeocodeResult> {
  try {
    // 参数校验
    if (latitude < -90 || latitude > 90) {
      throw new Error('纬度必须在-90到90之间');
    }
    if (longitude < -180 || longitude > 180) {
      throw new Error('经度必须在-180到180之间');
    }

    // 构建请求参数
    let params: site.ReverseGeocodeParams = {
      location: {
        latitude: latitude,
        longitude: longitude
      },
      language: language || 'zh',
      radius: radius || 1000,
      isExtension: true, // 推荐开启，获取更多信息
      isNearbyAoi: true  // 推荐开启，获取附近AOI
    };

    // 调用逆地理编码API
    const result: site.ReverseGeocodeResult = await site.reverseGeocode(params);

    // 结果处理
    console.info('逆地理编码成功');
    console.info(`地址: ${result.addressDescription}`);
    console.info(`国家: ${result.addressComponent.countryName}`);
    console.info(`省份: ${result.addressComponent.adminLevel1}`);
    console.info(`城市: ${result.addressComponent.adminLevel2}`);

    if (result.pois && result.pois.length > 0) {
      console.info(`周边POI数量: ${result.pois.length}`);
    }

    if (result.aois && result.aois.length > 0) {
      console.info(`周边AOI数量: ${result.aois.length}`);
    }

    return result;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`逆地理编码失败。错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

// 使用示例
reverseGeocodeLocation(39.9042, 116.4074, 'zh', 500)
  .then(result => {
    console.info('逆地理编码结果:', JSON.stringify(result, null, 2));
  })
  .catch(error => {
    console.error('逆地理编码出错:', error);
  });
```

**带Context上下文的调用示例**（API版本5.0.0(12)及以上）：

```typescript
import { site } from '@kit.MapKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function geocodeWithContext(
  context: common.Context,
  address: string
): Promise<site.GeocodeResult> {
  try {
    let params: site.GeocodeParams = {
      query: address,
      language: 'zh'
    };

    // 使用Context上下文调用（支持API 12及以上）
    const result: site.GeocodeResult = await site.geocode(context, params);
    console.info('带Context的地理编码成功');
    return result;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`地理编码失败。错误码: ${err.code}, 错误信息: ${err.message}`);
    throw error;
  }
}

// 在UIAbility中使用
class MainAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    // 使用this.context调用
    geocodeWithContext(this.context, '上海市浦东新区')
      .then(result => {
        console.info('结果:', JSON.stringify(result));
      });
  }
}
```

### 步骤3：错误处理

```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function geocodeWithErrorHandling(address: string): Promise<site.GeocodeResult | null> {
  try {
    const params: site.GeocodeParams = {
      query: address,
      language: 'zh'
    };

    const result = await site.geocode(params);
    return result;

  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        console.error('参数错误：输入参数无效');
        // 提示用户检查输入
        break;
        
      case 1002600001:
        console.error('系统内部错误');
        // 稍后重试
        break;
        
      case 1002600002:
        console.error('网络错误：无法连接到Map Kit服务器');
        // 检查网络连接后重试
        break;
        
      case 1002600003:
        console.error('认证失败：应用认证未通过');
        // 检查应用配置和权限
        break;
        
      case 1002600004:
        console.error('权限错误：地图权限未启用');
        // 引导用户开启地图权限
        break;
        
      case 1002603001:
        console.warn('查询结果为空：未找到匹配的地址');
        // 提示用户修改查询条件
        return null;
        
      default:
        console.error(`未知错误: ${err.code}, ${err.message}`);
        break;
    }
    
    throw error;
  }
}
```

### 步骤4：降级处理

```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

class GeocodeService {
  // 重试配置
  private static readonly MAX_RETRIES = 3;
  private static readonly RETRY_DELAY = 1000; // 毫秒

  /**
   * 带重试机制的地理编码
   */
  async geocodeWithRetry(
    address: string,
    language?: string,
    retries: number = GeocodeService.MAX_RETRIES
  ): Promise<site.GeocodeResult | null> {
    try {
      const params: site.GeocodeParams = {
        query: address,
        language: language || 'zh'
      };

      return await site.geocode(params);

    } catch (error) {
      const err: BusinessError = error as BusinessError;

      // 网络错误时重试
      if (err.code === 1002600002 && retries > 0) {
        console.warn(`网络错误，${GeocodeService.RETRY_DELAY}ms后重试，剩余重试次数: ${retries}`);
        await this.delay(GeocodeService.RETRY_DELAY);
        return this.geocodeWithRetry(address, language, retries - 1);
      }

      // 无结果时返回null
      if (err.code === 1002603001) {
        console.warn('未找到匹配地址，建议用户修改查询条件');
        return null;
      }

      // 其他错误抛出
      throw error;
    }
  }

  /**
   * 批量地理编码（带限流）
   */
  async batchGeocode(
    addresses: string[],
    language?: string,
    delayBetweenRequests: number = 200
  ): Promise<Map<string, site.GeocodeResult | null>> {
    const results = new Map<string, site.GeocodeResult | null>();

    for (const address of addresses) {
      try {
        const result = await this.geocodeWithRetry(address, language);
        results.set(address, result);
        
        // 限流延迟
        if (addresses.indexOf(address) < addresses.length - 1) {
          await this.delay(delayBetweenRequests);
        }
      } catch (error) {
        console.error(`地址 "${address}" 编码失败:`, error);
        results.set(address, null);
      }
    }

    return results;
  }

  /**
   * 逆地理编码缓存（示例降级方案）
   */
  private reverseGeocodeCache = new Map<string, site.ReverseGeocodeResult>();

  async reverseGeocodeWithCache(
    latitude: number,
    longitude: number
  ): Promise<site.ReverseGeocodeResult> {
    // 生成缓存键（保留4位小数精度）
    const cacheKey = `${latitude.toFixed(4)},${longitude.toFixed(4)}`;

    // 检查缓存
    if (this.reverseGeocodeCache.has(cacheKey)) {
      console.info('使用缓存的逆地理编码结果');
      return this.reverseGeocodeCache.get(cacheKey)!;
    }

    // 调用API
    const params: site.ReverseGeocodeParams = {
      location: { latitude, longitude },
      language: 'zh',
      radius: 200,
      isExtension: true,
      isNearbyAoi: true
    };

    const result = await site.reverseGeocode(params);

    // 存入缓存（限制缓存大小）
    if (this.reverseGeocodeCache.size < 1000) {
      this.reverseGeocodeCache.set(cacheKey, result);
    }

    return result;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// 使用示例
const geocodeService = new GeocodeService();

// 带重试的单次调用
geocodeService.geocodeWithRetry('北京市朝阳区', 'zh')
  .then(result => {
    if (result) {
      console.info('地理编码成功:', result);
    } else {
      console.warn('未找到结果');
    }
  });

// 批量调用
const addresses = ['北京市海淀区', '上海市浦东新区', '广州市天河区'];
geocodeService.batchGeocode(addresses, 'zh')
  .then(results => {
    results.forEach((result, address) => {
      console.info(`${address}: ${result ? '成功' : '失败'}`);
    });
  });
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 输入参数无效 | 检查参数类型、长度、范围是否符合要求 |
| 1002600001 | 系统内部错误 | 稍后重试，如持续出现请联系技术支持 |
| 1002600002 | 无法连接到Map Kit服务器 | 检查网络连接，确认设备可访问互联网 |
| 1002600003 | 应用认证失败 | 检查应用签名、证书配置，确认已在华为开发者平台注册 |
| 1002600004 | 地图权限未启用 | 在AppGallery Connect中启用Map Kit服务 |
| 1002603001 | 查询结果为空 | 修改查询条件，尝试不同的地址或坐标 |

**参数错误详解**：
- 地址字符串长度不在[1, 512]范围内
- 语言代码长度不在[1, 16]范围内
- 经纬度超出有效范围（纬度[-90, 90]，经度[-180, 180]）
- 搜索半径超出[0, 1000]范围
- bounds对象的经纬度无效

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "abilities": [...]
  },
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.AbilityKit": "^4.1.0"
  }
}
```

### 权限配置
在`module.json5`中添加权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason",
        "usedScene": {
          "abilities": ["MainAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:location_permission_reason",
        "usedScene": {
          "abilities": ["MainAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK：4.1.0(11)及以上
- DevEco Studio：3.1及以上
- Stage模型应用
- 网络连接

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.MapKit' or its corresponding type declarations.
```
**解决方法**：
- 确认HarmonyOS SDK版本 >= 4.1.0(11)
- 检查`build-profile.json5`中的SDK版本配置
- 在DevEco Studio中刷新项目依赖

**问题2：类型定义错误**
```
Error: Property 'geocode' does not exist on type 'typeof site'.
```
**解决方法**：
- 确认API版本 >= 4.1.0(11)
- 检查`import { site } from '@kit.MapKit'`语句
- 更新SDK到最新版本

**问题3：Context上下文错误**
```
Error: Cannot find name 'UIAbility'.
```
**解决方法**：
- 添加导入：`import { UIAbility } from '@kit.AbilityKit'`
- 确认应用使用Stage模型

**问题4：异步调用错误**
```
Error: 'await' expression is only allowed within an async function.
```
**解决方法**：
- 确保调用函数标记为`async`
- 使用`.then().catch()`处理Promise

## 常见问题与解决方法

### Q1：地理编码返回结果为空怎么办？
**原因**：
- 地址描述不够准确或不存在
- 地址不在服务覆盖范围内
- 语言参数设置不当

**解决方法**：
- 使用更详细、准确的地址描述
- 尝试不同的地址格式或表达方式
- 添加bounds参数限制搜索范围
- 尝试不同的语言参数

### Q2：逆地理编码结果不准确怎么办？
**原因**：
- 坐标精度不够
- 搜索半径设置不当
- 位置在偏远或未覆盖区域

**解决方法**：
- 提供更精确的经纬度坐标
- 调整搜索半径参数
- 设置isExtension=true获取更多信息
- 设置isNearbyAoi=true获取附近AOI
- 使用poiTypes过滤特定类型的POI

### Q3：API调用频繁失败怎么办？
**原因**：
- 网络连接不稳定
- API调用频率超限
- 服务端临时不可用

**解决方法**：
- 实现重试机制（建议最多3次）
- 在批量调用时添加延迟（建议200ms以上）
- 使用缓存机制减少重复调用
- 实现降级方案（如使用本地缓存或备用服务）

### Q4：应用认证失败如何处理？
**原因**：
- 应用未在AppGallery Connect注册
- 证书配置错误
- Map Kit服务未启用

**解决方法**：
- 在AppGallery Connect中注册应用
- 下载并配置正确的证书文件
- 在AppGallery Connect中启用Map Kit服务
- 检查应用的包名和签名配置

### Q5：如何在元服务中使用地理编码？
**原因**：元服务有特定的API版本要求

**解决方法**：
- 确保API版本 >= 4.1.0(11)
- 使用不带Context参数的API版本
- 如果需要Context版本，确保 >= 5.0.0(12)
- 参考元服务开发文档配置权限

### Q6：批量地理编码如何优化性能？
**原因**：批量调用可能导致性能问题或限流

**解决方法**：
- 使用分批处理，每批控制在合理数量
- 添加请求间延迟（建议200ms以上）
- 使用缓存机制避免重复查询
- 实现本地缓存持久化（遵循服务条款）
- 考虑使用服务端代理批量处理

## 输出结果报告

执行完成后输出以下信息：

```typescript
interface GeocodeResult {
  status: 'success' | 'failed' | 'empty';
  message: string;
  data?: {
    // 正地理编码结果
    geocode?: {
      sites: Array<{
        siteId: string;
        name: string;
        formatAddress: string;
        location: {
          latitude: number;
          longitude: number;
        };
        addressComponent: {
          countryName: string;
          adminLevel1: string;  // 省份
          adminLevel2: string;  // 城市
          adminLevel3: string;  // 区县
          adminLevel4: string;  // 街道
          locality: string;
          postalCode?: string;
        };
      }>;
    };
    
    // 逆地理编码结果
    reverseGeocode?: {
      addressDescription: string;
      addressComponent: {
        countryCode: string;
        countryName: string;
        adminLevel1: string;
        adminLevel2: string;
        adminLevel3: string;
        adminLevel4: string;
        locality: string;
        postalCode?: string;
      };
      pois?: Array<{
        name: string;
        address: string;
        distance: number;
        poiType: string;
        location: {
          latitude: number;
          longitude: number;
        };
      }>;
      aois?: Array<{
        name: string;
        poiType: string;
        distance: number;
        area: number;
      }>;
      roads?: Array<{
        streetName: string;
        distance: number;
        direction: string;
      }>;
    };
  };
  apiUsed: string[];
  timestamp: string;
}

// 示例输出
const resultReport: GeocodeResult = {
  status: 'success',
  message: '地理编码成功，找到1个结果',
  data: {
    geocode: {
      sites: [{
        siteId: 'xxx',
        name: '北京市海淀区中关村',
        formatAddress: '北京市海淀区中关村大街',
        location: {
          latitude: 39.9841,
          longitude: 116.3074
        },
        addressComponent: {
          countryName: '中国',
          adminLevel1: '北京市',
          adminLevel2: '海淀区',
          adminLevel3: '中关村街道',
          adminLevel4: '',
          locality: '中关村',
          postalCode: '100080'
        }
      }]
    }
  },
  apiUsed: ['site.geocode'],
  timestamp: '2026-07-03T10:30:00Z'
};
```

## 参考文档

- [API开发指南 - 地理编码](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-site-geocode)
- [API参考说明 - site模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site)
- [位置搜索支持语言](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-language)
- [华为POI分类体系](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-poi)
- [城市码及区划代码表](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-citycode)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-errorcode)

## 完整示例代码

- [正地理编码示例](assets/geocode_example.ets) - 地址转经纬度的完整示例
- [逆地理编码示例](assets/reverse_geocode_example.ets) - 经纬度转地址的完整示例
- [批量地理编码示例](assets/batch_geocode_example.ets) - 批量处理的完整示例
- [错误处理示例](assets/error_handling_example.ets) - 完整的错误处理和降级方案
- [配置文件示例](assets/module.json5) - 权限和依赖配置示例

## 测试用例

### 正向测试用例
- [正常地址编码](tests/test_geocode_positive.py) - 测试标准地址的地理编码
- [正常坐标解码](tests/test_reverse_geocode_positive.py) - 测试标准坐标的逆地理编码
- [多语言支持](tests/test_multilanguage.py) - 测试不同语言返回结果
- [扩展信息返回](tests/test_extension_info.py) - 测试扩展信息获取

### 边界测试用例
- [最小地址长度](tests/test_min_address_length.py) - 测试1字符地址
- [最大地址长度](tests/test_max_address_length.py) - 测试512字符地址
- [边界坐标值](tests/test_boundary_coordinates.py) - 测试坐标边界值
- [搜索半径边界](tests/test_radius_boundary.py) - 测试半径边界值

### 异常测试用例
- [空地址参数](tests/test_empty_address.py) - 测试空地址处理
- [无效坐标值](tests/test_invalid_coordinates.py) - 测试超出范围的坐标
- [网络异常](tests/test_network_error.py) - 测试网络断开场景
- [权限不足](tests/test_permission_denied.py) - 测试权限缺失场景
- [服务不可用](tests/test_service_unavailable.py) - 测试服务不可用降级