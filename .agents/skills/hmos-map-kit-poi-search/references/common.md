# Map Kit 通用常量

## 错误码

### SDK错误码

| 错误码        | 说明       |
|------------|----------|
| 1002600001 | 系统内部错误   |
| 1002600002 | 地图服务连接失败 |
| 401        | 无效输入参数   |

### 业务错误码

| 错误码 | 说明      |
|-----|---------|
| 0   | 成功      |
| 其他  | 请参考官方文档 |

## 排序规则 (SortRule)

| 值                  | 说明       |
|--------------------|----------|
| SortRule.COMPOSITE | 综合排序（默认） |
| SortRule.DISTANCE  | 按距离排序    |

## 常用POI类型（poiTypes）

### 餐饮类

| 类型值  | 说明  |
|------|-----|
| 餐饮服务 | 餐厅  |
| 快餐服务 | 快餐  |
| 咖啡厅  | 咖啡厅 |
| 茶馆   | 茶馆  |
| 酒吧   | 酒吧  |

### 住宿类

| 类型值  | 说明    |
|------|-------|
| 住宿服务 | 酒店、旅馆 |

### 交通类

| 类型值  | 说明  |
|------|-----|
| 航空机场 | 机场  |
| 铁路车站 | 火车站 |
| 地铁站  | 地铁站 |
| 汽车站  | 汽车站 |

### 购物类

| 类型值          | 说明 |
|--------------|----|
| 购物服务         | 商店 |
| supermarkets | 超市 |
| 大型商超         | 商场 |

### 景点类

| 类型值  | 说明     |
|------|--------|
| 风景名胜 | 景点     |
| 博物馆  | 博物馆    |
| 影剧院  | 电影院、剧院 |

### 医疗类

| 类型值    | 说明 |
|--------|----|
| 医疗保健服务 | 医院 |
| 药品销售点  | 药店 |

### 银行类

| 类型值   | 说明  |
|-------|-----|
| 金融机构  | 银行  |
| 自动取款机 | ATM |

## 国家代码（countryCodes）

采用ISO 3166-1 alpha-2标准，常用代码：

| 代码 | 国家   |
|----|------|
| CN | 中国   |
| US | 美国   |
| GB | 英国   |
| JP | 日本   |
| KR | 韩国   |
| DE | 德国   |
| FR | 法国   |
| IT | 意大利  |
| AU | 澳大利亚 |
| SG | 新加坡  |

## 语言代码（language）

| 代码    | 语言         |
|-------|------------|
| zh_CN | 简体中文       |
| zh_TW | 繁体中文（中国台湾） |
| zh_HK | 繁体中文（中国香港） |
| en    | 英语         |
| ja    | 日语         |
| ko    | 韩语         |
| fr    | 法语         |
| de    | 德语         |
| es    | 西班牙语       |
| it    | 意大利语       |
| ru    | 俄语         |

## 坐标类型

### LatLng（坐标对象）

| 字段        | 类型     | 是否可选 | 说明 |
|-----------|--------|------|----|
| longitude | number | 否    | 经度 |
| latitude  | number | 否    | 纬度 |

### LatLngBounds（矩形区域）

| 字段        | 类型                    | 是否可选 | 说明    |
|-----------|-----------------------|------|-------|
| southwest | [LatLng](#latlng坐标对象) | 否    | 西南角坐标 |
| northeast | [LatLng](#latlng坐标对象) | 否    | 东北角坐标 |

## 地址组件 (AddressComponent)

| 字段            | 类型              | 是否可选 | 说明         |
|---------------|-----------------|------|------------|
| countryName   | string          | 是    | 国家名称       |
| countryCode   | string          | 是    | 国家代码       |
| adminLevel1   | string          | 是    | 一级行政区（省/州） |
| adminLevel2   | string          | 是    | 二级行政区（市）   |
| adminLevel3   | string          | 是    | 三级行政区      |
| adminLevel4   | string          | 是    | 四级行政区      |
| adminLevel5   | string          | 是    | 五级行政区      |
| locality      | string          | 是    | 城市         |
| subLocality1  | string          | 是    | 区/县        |
| subLocality2  | string          | 是    | 街道/乡镇      |
| neighborhoods | Array\<string\> | 是    | 社区         |
| adminCode     | string          | 是    | 行政区划代码     |
| postalCode    | string          | 是    | 邮政编码       |
| city          | City            | 是    | 城市信息       |
| streetNumber  | StreetNumber    | 是    | 门牌号信息      |

详见 [Site类型](#Site类型) 中的 addressComponent 字段。

---

## 地点信息 (Site)

地点基础信息结构，包含地点名称、地址、坐标等核心数据。

### Site字段说明

| 字段               | 类型                        | 是否可选 | 描述           |
|------------------|---------------------------|------|--------------|
| siteId           | string                    | 否    | 地点唯一标识符      |
| name             | string                    | 是    | 地点名称         |
| formatAddress    | string                    | 是    | 格式化后的完整地址    |
| addressComponent | [AddressComponent](#地址组件) | 否    | 地址组件信息       |
| location         | LatLng                    | 是    | 经纬度坐标        |
| viewport         | LatLngBounds              | 是    | 可视区域边界框      |
| distance         | number                    | 是    | 到搜索中心的距离（米）  |
| utcOffset        | number                    | 是    | UTC时区偏移量（分钟） |
| poi              | Poi                       | 是    | POI详细信息      |

---

## POI详细信息 (Poi)

地点的POI扩展信息，包含电话、评分、营业时间等。

### Poi字段说明

| 字段                 | 类型                 | 是否可选 | 描述                    |
|--------------------|--------------------|------|-----------------------|
| poiTypes           | Array\<string\>    | 是    | POI类型（如"餐饮服务"、"住宿服务"） |
| poiTypeIds         | Array\<string\>    | 是    | POI类型ID               |
| phone              | string             | 是    | 联系电话                  |
| internationalPhone | string             | 是    | 国际联系电话                |
| rating             | number             | 是    | 用户评分（1-5分）            |
| websiteUrl         | string             | 是    | 官方网站URL               |
| openingHours       | OpeningHours       | 是    | 营业时间                  |
| businessStatus     | string             | 是    | 营业状态                  |
| brand              | string             | 是    | 品牌名称                  |
| email              | string             | 是    | 电子邮箱                  |
| starRating         | number             | 是    | 星级评分                  |
| childNodes         | Array\<ChildNode\> | 是    | 子节点列表（大型场所）           |
| icon               | string             | 是    | POI图标                 |
| description        | string             | 是    | POI描述                 |
| abstractText       | string             | 是    | 摘要文本                  |
| comment            | Comment            | 是    | 评论统计信息                |

---

## 营业时间 (OpeningHours)

| 字段      | 类型              | 是否可选 | 说明       |
|---------|-----------------|------|----------|
| texts   | Array\<string\> | 是    | 营业时间文本描述 |
| periods | Array\<Period\> | 是    | 营业时段列表   |

---

## 营业时段 (Period)

| 字段    | 类型         | 是否可选 | 说明   |
|-------|------------|------|------|
| open  | TimeOfWeek | 是    | 开业时间 |
| close | TimeOfWeek | 是    | 歇业时间 |

---

## 每周时间 (TimeOfWeek)

| 字段   | 类型     | 是否可选 | 说明                 |
|------|--------|------|--------------------|
| week | number | 是    | 星期几（0=周日，1=周一，...） |
| time | string | 是    | 时间（HH:mm格式）        |

---

## 子节点 (ChildNode)

大型场所（如商场、机场）的子区域信息。

| 字段            | 类型              | 是否可选 | 说明      |
|---------------|-----------------|------|---------|
| siteId        | string          | 是    | 子区域ID   |
| name          | string          | 是    | 子区域名称   |
| formatAddress | string          | 是    | 格式化地址   |
| location      | LatLng          | 是    | 经纬度坐标   |
| poiTypes      | Array\<string\> | 是    | POI类型列表 |

---

## 评论信息 (Comment)

| 字段            | 类型     | 是否可选 | 说明   |
|---------------|--------|------|------|
| averageRating | number | 是    | 平均评分 |
| total         | number | 是    | 评论总数 |

---

## 城市信息 (City)

| 字段       | 类型     | 是否可选 | 说明   |
|----------|--------|------|------|
| cityCode | string | 是    | 城市编码 |
| cityId   | string | 是    | 城市ID |
| cityName | string | 是    | 城市名称 |

---

## 门牌号信息 (StreetNumber)

| 字段            | 类型     | 是否可选 | 说明       |
|---------------|--------|------|----------|
| direction     | string | 是    | 方向（如"东"） |
| distance      | number | 是    | 距离（米）    |
| location      | LatLng | 是    | 门牌号坐标    |
| streetNumber  | string | 是    | 门牌号      |
| streetName    | string | 是    | 街道名称     |
| formatAddress | string | 是    | 格式化地址    |

---

## AOI (Area of Interest)

逆地理编码返回的兴趣区域信息。

| 字段        | 类型     | 是否可选 | 说明        |
|-----------|--------|------|-----------|
| area      | number | 是    | 区域面积（平方米） |
| distance  | number | 是    | 距离（米）     |
| siteId    | string | 是    | AOI ID    |
| location  | LatLng | 是    | 中心坐标      |
| name      | string | 是    | AOI名称     |
| poiType   | string | 是    | POI类型     |
| direction | string | 是    | 方向        |

---

## 逆地理编码POI (ReverseGeocodePoi)

逆地理编码返回的POI信息。

| 字段        | 类型     | 是否可选 | 说明     |
|-----------|--------|------|--------|
| address   | string | 是    | POI地址  |
| direction | string | 是    | 相对方向   |
| distance  | number | 是    | 距离（米）  |
| siteId    | string | 是    | POI ID |
| location  | LatLng | 是    | POI坐标  |
| name      | string | 是    | POI名称  |
| poiType   | string | 是    | POI类型  |

---

## 道路信息 (Road)

| 字段        | 类型     | 是否可选 | 说明    |
|-----------|--------|------|-------|
| direction | string | 是    | 相对方向  |
| distance  | number | 是    | 距离（米） |
| siteId    | string | 是    | 道路ID  |
| location  | LatLng | 是    | 道路坐标  |
| name      | string | 是    | 道路名称  |

---

## 交叉路口 (Intersection)

| 字段        | 类型     | 是否可选 | 说明     |
|-----------|--------|------|--------|
| direction | string | 是    | 相对方向   |
| distance  | number | 是    | 距离（米）  |
| siteId    | string | 是    | 交叉路口ID |
| location  | LatLng | 是    | 交叉路口坐标 |
| name      | string | 是    | 交叉路口名称 |
