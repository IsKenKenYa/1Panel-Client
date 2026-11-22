---
name: hmos-map-kit-site-search
description: 提供POI搜索能力，支持关键字搜索、周边搜索、自动补全和地点详情查询，适用于地图应用地点搜索场景
---

# POI搜索技能

## 功能描述

本技能提供HarmonyOS Map Kit的POI（Point of Interest）搜索能力，包括：

- **关键字搜索**：通过关键字查询地点列表，支持地理范围限定
- **周边搜索**：基于用户位置返回周边地点，支持类型过滤
- **自动补全**：根据输入关键字提供预测搜索词和地点建议
- **地点详情**：根据地点ID获取详细信息，如地址、经纬度、营业时间等

## 使用场景

### 触发词
- "搜索地点"
- "查找POI"
- "关键字搜索地点"
- "周边搜索"
- "附近搜索"
- "地点自动补全"
- "地点详情查询"
- "Map Kit POI搜索"

### 能做
- 根据关键字搜索旅游景点、企业、学校等地点
- 基于用户位置查找周边POI，支持按类型筛选
- 提供搜索关键字自动补全功能，优化用户输入体验
- 根据地点ID查询详细信息（地址、营业时间、评分等）
- 支持多种语言返回结果
- 支持分页查询和排序

### 绝不做
- 不支持地图渲染和显示
- 不支持导航功能
- 不支持离线搜索
- 不支持地图标注和绘制
- 不处理实时交通信息

### 补充
- 仅支持Stage模型
- 需要申请Map Kit权限
- 需要网络连接
- API版本要求：4.1.0(11)及以上，Context参数版本要求5.0.0(12)及以上

## 调用规范和规则

### 输入约束
- 关键字长度：1-512字符
- 地点ID长度：1-256字符
- 搜索半径：1-50000米（关键字搜索、周边搜索、自动补全），0-1000米（逆地理编码）
- 每页记录数：1-20条
- 页码范围：1-500页（pageIndex * pageSize ≤ 500）
- 国家代码：最多5个，采用ISO 3166-1 alpha-2格式
- 语言代码：1-16字符

### 执行约束
- 最大耗时：单次搜索建议不超过10秒
- API调用频次：遵循华为云服务API调用限制
- 网络要求：必须联网使用
- 并发限制：避免同时发起大量搜索请求

### 内容约束
- 禁止生成虚假地点信息
- 禁止使用硬编码的API密钥
- 禁止返回敏感地理信息（军事区域等）
- 必须使用Promise异步处理结果
- 必须添加错误处理代码

### 降级约束
- 网络失败：提示用户检查网络连接，提供重试机制
- 搜索无结果：建议用户修改关键字或扩大搜索范围
- 权限未开启：引导用户开启Map Kit权限
- API调用失败：记录错误日志，显示友好错误提示

## 调用流程和步骤

### 步骤1：导入模块和准备参数

**导入必要模块**：
```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**参数校验**：
```typescript
function validateSearchParams(params: site.SearchByTextParams): boolean {
  if (!params.query || params.query.length < 1 || params.query.length > 512) {
    console.error('Invalid query: length must be 1-512 characters');
    return false;
  }
  
  if (params.radius && (params.radius < 1 || params.radius > 50000)) {
    console.error('Invalid radius: must be 1-50000 meters');
    return false;
  }
  
  if (params.pageSize && (params.pageSize < 1 || params.pageSize > 20)) {
    console.error('Invalid pageSize: must be 1-20');
    return false;
  }
  
  if (params.pageIndex && (params.pageIndex < 1 || params.pageIndex > 500)) {
    console.error('Invalid pageIndex: must be 1-500');
    return false;
  }
  
  return true;
}
```

### 步骤2：关键字搜索

**功能描述**：通过关键字查询地点，支持地理范围限定

**示例代码**：
```typescript
async function searchByTextExample(): Promise<void> {
  let params: site.SearchByTextParams = {
    query: '故宫',
    location: {
      latitude: 39.9042,
      longitude: 116.4074
    },
    radius: 10000,
    language: 'zh',
    pageSize: 20,
    pageIndex: 1
  };
  
  if (!validateSearchParams(params)) {
    return;
  }
  
  try {
    const result = await site.searchByText(params);
    console.info(`Succeeded in searching by text. Total: ${result.totalCount}`);
    
    if (result.sites && result.sites.length > 0) {
      result.sites.forEach((siteInfo, index) => {
        console.info(`Site ${index + 1}: ${siteInfo.name}`);
        console.info(`  Address: ${siteInfo.formatAddress}`);
        console.info(`  Location: (${siteInfo.location.latitude}, ${siteInfo.location.longitude})`);
      });
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    handleSearchError(err);
  }
}
```

### 步骤3：周边搜索

**功能描述**：基于用户位置查找周边地点，支持类型过滤

**示例代码**：
```typescript
async function nearbySearchExample(): Promise<void> {
  let params: site.NearbySearchParams = {
    location: {
      latitude: 39.9042,
      longitude: 116.4074
    },
    radius: 5000,
    poiTypes: ['RESTAURANT', 'HOTEL', 'SCENIC_SPOT'],
    language: 'zh',
    pageSize: 20,
    pageIndex: 1,
    sortRule: site.SortRule.DISTANCE
  };
  
  try {
    const result = await site.nearbySearch(params);
    console.info(`Succeeded in searching nearby. Total: ${result.totalCount}`);
    
    if (result.sites && result.sites.length > 0) {
      result.sites.forEach((siteInfo, index) => {
        console.info(`Site ${index + 1}: ${siteInfo.name}`);
        console.info(`  Distance: ${siteInfo.distance} meters`);
      });
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    handleSearchError(err);
  }
}
```

### 步骤4：自动补全

**功能描述**：根据输入关键字提供预测搜索词和地点建议

**示例代码**：
```typescript
async function queryAutoCompleteExample(): Promise<void> {
  let params: site.QueryAutoCompleteParams = {
    query: '北京',
    location: {
      latitude: 39.9042,
      longitude: 116.4074
    },
    radius: 50000,
    language: 'zh',
    isChildren: true
  };
  
  try {
    const result = await site.queryAutoComplete(params);
    console.info('Succeeded in querying auto complete.');
    
    if (result.sites && result.sites.length > 0) {
      console.info('Suggestions:');
      result.sites.forEach((siteInfo, index) => {
        console.info(`  ${index + 1}. ${siteInfo.name}`);
      });
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    handleSearchError(err);
  }
}
```

### 步骤5：地点详情

**功能描述**：根据地点ID查询详细信息

**示例代码**：
```typescript
async function searchByIdExample(): Promise<void> {
  let params: site.SearchByIdParams = {
    siteId: '144129739873977856',
    language: 'zh',
    isChildren: true
  };
  
  try {
    const result = await site.searchById(params);
    
    if (result.site) {
      console.info('Site Details:');
      console.info(`  Name: ${result.site.name}`);
      console.info(`  Address: ${result.site.formatAddress}`);
      console.info(`  Location: (${result.site.location.latitude}, ${result.site.location.longitude})`);
      
      if (result.site.poi) {
        console.info(`  Phone: ${result.site.poi.phone}`);
        console.info(`  Rating: ${result.site.poi.rating}`);
        
        if (result.site.poi.openingHours) {
          console.info('  Opening Hours:');
          result.site.poi.openingHours.texts.forEach(text => {
            console.info(`    ${text}`);
          });
        }
      }
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    handleSearchError(err);
  }
}
```

### 步骤6：错误处理

**统一的错误处理函数**：
```typescript
function handleSearchError(err: BusinessError): void {
  switch (err.code) {
    case 401:
      console.error('Invalid input parameter. Please check your parameters.');
      break;
    case 1002600001:
      console.error('System internal error. Please try again later.');
      break;
    case 1002600002:
      console.error('Failed to connect to the Map Kit server. Please check your network.');
      break;
    case 1002600003:
      console.error('App authentication failed. Please check your app configuration.');
      break;
    case 1002600004:
      console.error('The Map permission is not enabled. Please enable Map Kit in app settings.');
      break;
    case 1002603001:
      console.error('Zero result. No matching locations found.');
      break;
    default:
      console.error(`Unknown error: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤7：降级处理

**网络异常降级**：
```typescript
async function searchWithFallback(params: site.SearchByTextParams): Promise<site.SearchByTextResult | null> {
  try {
    return await site.searchByText(params);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    if (err.code === 1002600002) {
      console.warn('Network error, using cached data if available');
      return getCachedSearchResult(params.query);
    }
    
    throw error;
  }
}

function getCachedSearchResult(query: string): site.SearchByTextResult | null {
  // 实现缓存逻辑，返回缓存的搜索结果
  return null;
}
```

**搜索无结果降级**：
```typescript
async function searchWithExpandedScope(params: site.SearchByTextParams): Promise<site.SearchByTextResult> {
  try {
    const result = await site.searchByText(params);
    
    if (result.totalCount === 0 && result.sites?.length === 0) {
      console.warn('No results found, trying with expanded search scope');
      
      // 扩大搜索半径
      const expandedParams = { ...params, radius: (params.radius || 10000) * 2 };
      const expandedResult = await site.searchByText(expandedParams);
      
      if (expandedResult.totalCount > 0) {
        return expandedResult;
      }
      
      // 移除地理限制
      const noLocationParams = { ...params };
      delete noLocationParams.location;
      delete noLocationParams.radius;
      
      return await site.searchByText(noLocationParams);
    }
    
    return result;
  } catch (error) {
    throw error;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数无效 | 检查参数格式、取值范围是否符合要求 |
| 1002600001 | 系统内部错误 | 稍后重试，如持续出现请联系技术支持 |
| 1002600002 | 无法连接地图服务器 | 检查网络连接，确认服务器可访问 |
| 1002600003 | 应用认证失败 | 检查应用配置，确认API密钥是否正确 |
| 1002600004 | 地图权限未开启 | 在应用设置中开启Map Kit权限 |
| 1002603001 | 搜索无结果 | 调整搜索关键字或扩大搜索范围 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：4.1.0(11)及以上
- DevEco Studio：4.0及以上
- API版本：支持Stage模型
- 网络权限：需要配置网络访问权限

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit' or its corresponding type declarations.
```
**解决方法**：
- 确认HarmonyOS SDK版本 ≥ 4.1.0(11)
- 在`build-profile.json5`中配置正确的SDK版本
- 同步项目依赖：`ohpm install`

**问题2：API未定义**
```
Error: Property 'searchByText' does not exist on type 'typeof site'.
```
**解决方法**：
- 检查API版本，确保 ≥ 4.1.0(11)
- 确认使用正确的命名空间：`site.searchByText`
- 重启DevEco Studio并清理缓存

**问题3：类型错误**
```
Error: Type 'LatLng' is missing the following properties from type 'LatLng'
```
**解决方法**：
- 检查location参数格式，确保包含latitude和longitude
- 使用正确的类型定义：`mapCommon.LatLng`

## 常见问题与解决方法

### Q1：搜索返回空结果
**原因**：
- 关键字过于具体或拼写错误
- 地理范围限制过小
- 该地区确实无相关POI

**解决方法**：
- 检查关键字拼写，尝试简化关键字
- 扩大搜索半径或移除地理限制
- 使用自动补全获取建议关键字

### Q2：周边搜索距离不准确
**原因**：
- 未设置sortRule参数
- 定位精度问题

**解决方法**：
- 设置`sortRule: site.SortRule.DISTANCE`按距离排序
- 确保定位权限已开启，获取精确位置

### Q3：地点详情缺少营业信息
**原因**：
- 该地点未提供营业信息
- 未设置`isChildren: true`

**解决方法**：
- 设置`isChildren: true`获取完整信息
- 检查返回的`poi.openingHours`字段

### Q4：自动补全无建议
**原因**：
- 输入关键字过短
- 地理范围限制过严

**解决方法**：
- 确保关键字长度 ≥ 1字符
- 扩大搜索半径或移除location参数

### Q5：API调用频繁报错
**原因**：
- 超过API调用频率限制
- 并发请求过多

**解决方法**：
- 添加请求节流逻辑
- 使用防抖延迟搜索请求
- 实现本地缓存机制

## 输出结果报告

执行完成后输出以下信息：

```typescript
interface SearchResult {
  status: 'success' | 'error';
  totalCount?: number;
  sites?: Array<{
    siteId: string;
    name: string;
    formatAddress: string;
    location: {
      latitude: number;
      longitude: number;
    };
    distance?: number;
    poiTypes?: string[];
  }>;
  error?: {
    code: number;
    message: string;
  };
  apiUsed: string[];
}
```

**示例输出**：
```json
{
  "status": "success",
  "totalCount": 25,
  "sites": [
    {
      "siteId": "144129739873977856",
      "name": "故宫博物院",
      "formatAddress": "北京市东城区景山前街4号",
      "location": {
        "latitude": 39.9163,
        "longitude": 116.3972
      },
      "distance": 500,
      "poiTypes": ["SCENIC_SPOT", "MUSEUM"]
    }
  ],
  "apiUsed": ["site.searchByText"]
}
```

## 参考文档

- [POI搜索开发指南](references/map-site-search-guide.md)
- [site API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site)

## 完整示例代码

- [关键字搜索示例](assets/search-by-text-example.ets)
- [周边搜索示例](assets/nearby-search-example.ets)
- [自动补全示例](assets/auto-complete-example.ets)
- [地点详情示例](assets/search-by-id-example.ets)
- [完整功能示例](assets/site-search-complete-example.ets)

## 测试用例

### 正向测试用例
- [测试关键字搜索基本功能](tests/test-search-by-text-positive.ets)：验证基本搜索功能
- [测试周边搜索基本功能](tests/test-nearby-search-positive.ets)：验证周边搜索功能
- [测试自动补全基本功能](tests/test-auto-complete-positive.ets)：验证自动补全功能
- [测试地点详情基本功能](tests/test-search-by-id-positive.ets)：验证地点详情查询

### 边界测试用例
- [测试关键字长度边界](tests/test-query-length-boundary.ets)：验证1-512字符限制
- [测试搜索半径边界](tests/test-radius-boundary.ets)：验证1-50000米范围
- [测试分页边界](tests/test-pagination-boundary.ets)：验证分页参数限制

### 异常测试用例
- [测试无效关键字](tests/test-invalid-query.ets)：验证错误关键字处理
- [测试网络异常](tests/test-network-error.ets)：验证网络错误降级
- [测试权限未开启](tests/test-permission-error.ets)：验证权限错误处理
- [测试无结果搜索](tests/test-zero-result.ets)：验证零结果降级处理