# POI搜索开发指南

参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-site-search

## 场景介绍

提供多种查询POI信息的能力：

- 关键字搜索：通过用户输入的关键字，返回地点列表。
- 周边搜索：基于用户设备位置进行地点查找。
- 自动补全：根据输入的关键字返回预测的输入关键字和地点查询建议。
- 地点详情：查询某个地点更详细的信息。

## 接口说明

以下是POI搜索相关接口，主要由 site 命名空间下的方法提供，更多接口及使用方法请参见 [site API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site)。

| 接口名 | 描述 |
| --- | --- |
| searchByText(searchByTextParams: SearchByTextParams): Promise<SearchByTextResult> | 关键字搜索。 |
| searchByText(context: common.Context, searchByTextParams: SearchByTextParams): Promise<SearchByTextResult> | 关键字搜索。支持上传Context上下文。 |
| nearbySearch(nearbySearchParams: NearbySearchParams): Promise<NearbySearchResult> | 周边搜索。 |
| nearbySearch(context: common.Context, nearbySearchParams: NearbySearchParams): Promise<NearbySearchResult> | 周边搜索。支持上传Context上下文。 |
| queryAutoComplete(queryAutoCompleteParams: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult> | 自动补全。 |
| queryAutoComplete(context: common.Context, queryAutoCompleteParams: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult> | 自动补全。支持上传Context上下文。 |
| searchById(searchByIdParams: SearchByIdParams): Promise<SearchByIdResult> | 地点详情。 |
| searchById(context: common.Context, searchByIdParams: SearchByIdParams): Promise<SearchByIdResult> | 地点详情。支持上传Context上下文。 |

## 开发步骤

导入相关模块。

```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

## 关键字搜索

通过指定的关键字和可选的地理范围，查询诸如旅游景点、企业和学校之类的地点。

```typescript
let params: site.SearchByTextParams = {
  query: '故宫',
  location: {
    latitude: 39.9042,
    longitude: 116.4074
  },
  radius: 10000,
  language: 'zh'
};

try {
  const result = await site.searchByText(params);
  console.info(`Succeeded in searching by text. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in searching by text. Code is ${err.code}, message is ${err.message}`);
}
```

## 周边搜索

通过用户传入自己的位置，可以返回周边地点列表。您可以通过提供关键字或指定要搜索的地点的类型来优化搜索结果。

```typescript
let params: site.NearbySearchParams = {
  location: {
    latitude: 39.9042,
    longitude: 116.4074
  },
  poiTypes: [
    'RESTAURANT',
    'HOTEL',
    'SCENIC_SPOT'
  ]
};

try {
  const result = await site.nearbySearch(params);
  console.info(`Succeeded in searching nearby. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in searching nearby. Code is ${err.code}, message is ${err.message}`);
}
```

## 自动补全

根据输入的关键字，将最有可能的搜索词呈现给用户，以减少用户输入信息，提升用户体验。如：输入"北京"，提示"北京市"、"北京站"、"北京西站"等。

```typescript
let params: site.QueryAutoCompleteParams = {
  query: '北京',
  location: {
    latitude: 39.9042,
    longitude: 116.4074
  },
  language: 'zh',
  isChildren: true
};

try {
  const result = await site.queryAutoComplete(params);
  console.info(`Succeeded in querying. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in querying. Code is ${err.code}, message is ${err.message}`);
}
```

## 地点详情

根据地点的唯一主键地点ID（siteId）获取地点详情。地点详细信息请求返回有关指定地点的更全面的信息，如地点名称、地址详细信息、经纬度等。siteId可通过其他接口（关键字搜索、周边搜索、地点详情、自动补全、正地理编码）的返回结果中获取。

```typescript
let params: site.SearchByIdParams = {
  siteId: '144129739873977856',
  language: 'zh',
  isChildren: true
};

try {
  const result = await site.searchById(params);
  console.info(`Succeeded in searching. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in searching. Code is ${err.code}, message is ${err.message}`);
}
```