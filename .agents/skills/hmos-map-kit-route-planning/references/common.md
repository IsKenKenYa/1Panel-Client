# 华为Site Kit 通用常量

## 返回码（returnCode）

| 返回码 | 说明             |
|-----|----------------|
| 0   | 成功             |
| 1   | 系统内部错误         |
| 2   | 请求参数非法         |
| 3   | 权限校验失败         |
| 4   | 配额校验失败         |
| 5   | API Key 不存在或非法 |
| 6   | 请求方法错误         |
| 7   | 请求超时           |
| 8   | 服务不可用          |

## 常用POI类型（hwPoiType）

### 餐饮类

| 类型值                 | 说明   |
|---------------------|------|
| CHINESE_RESTAURANT  | 中餐厅  |
| WESTERN_RESTAURANT  | 西餐厅  |
| JAPANESE_RESTAURANT | 日本料理 |
| KOREAN_RESTAURANT   | 韩国料理 |
| FAST_FOOD           | 快餐   |
| CAFE                | 咖啡厅  |
| BAR                 | 酒吧   |

### 住宿类

| 类型值    | 说明 |
|--------|----|
| HOTEL  | 酒店 |
| HOSTEL | 旅舍 |

### 交通类

| 类型值                      | 说明    |
|--------------------------|-------|
| AIRPORT                  | 机场    |
| RAILWAY_STATION          | 火车站   |
| SUBWAY_STATION           | 地铁站   |
| BUS_STATION              | 汽车站   |
| NATIONAL_RAILWAY_STATION | 国家铁路站 |

### 购物类

| 类型值         | 说明 |
|-------------|----|
| SHOP        | 商店 |
| SUPERMARKET | 超市 |
| MALL        | 商场 |

### 景点类

| 类型值         | 说明  |
|-------------|-----|
| SCENIC_SPOT | 景点  |
| MUSEUM      | 博物馆 |
| CINEMA      | 电影院 |
| THEATER     | 剧院  |

### 医疗类

| 类型值      | 说明 |
|----------|----|
| HOSPITAL | 医院 |
| PHARMACY | 药店 |

### 银行类

| 类型值  | 说明  |
|------|-----|
| BANK | 银行  |
| ATM  | ATM |

## 常用POI类型（poiType）

| 类型值            | 说明  |
|----------------|-----|
| RESTAURANT     | 餐厅  |
| LODGING        | 住宿  |
| TRAIN_STATION  | 火车站 |
| AIRPORT        | 机场  |
| BUS_STATION    | 汽车站 |
| SUBWAY_STATION | 地铁站 |
| STORE          | 商店  |
| SUPERMARKET    | 超市  |
| MALL           | 商场  |
| HOSPITAL       | 医院  |
| BANK           | 银行  |
| ATM            | ATM |
| SCENIC_SPOT    | 景点  |
| MUSEUM         | 博物馆 |
| CINEMA         | 电影院 |

## 国家代码（countryCode）

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
| zh    | 简体中文       |
| zh-TW | 繁体中文（中国台湾） |
| zh-HK | 繁体中文（中国香港） |
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

## 路线信息（Route）

路线结果，包含路线详情、距离、耗时等。

| 字段                            | 类型                                        | 是否可选 | 说明           |
|-------------------------------|-------------------------------------------|------|--------------|
| steps                         | [RouteStep](#路线步骤RouteStep)[]             | 否    | 路线步骤列表       |
| overviewPolyline              | [LatLng](#latlng坐标对象)[]                   | 否    | 路线概览坐标点      |
| optimizedWaypoints            | number[]                                  | 否    | 优化后的途经点索引    |
| bounds                        | [CoordinateBound](#路线边界CoordinateBound)[] | 否    | 路线边界框        |
| trafficLightCount             | number                                    | 否    | 红绿灯数量        |
| isDestinationInRestrictedArea | boolean                                   | 否    | 目的地是否在限行区域   |
| isDestinationInDiffTimeZone   | boolean                                   | 否    | 目的地时区是否与起点不同 |
| isCrossCountry                | boolean                                   | 否    | 是否跨越国界       |
| isCrossMultiCountries         | boolean                                   | 否    | 是否跨越多个国家     |
| hasRestrictedRoad             | boolean                                   | 否    | 是否包含限行道路     |
| hasRoughRoad                  | boolean                                   | 否    | 是否包含颠簸道路     |
| hasFerry                      | boolean                                   | 否    | 是否包含轮渡       |
| hasTolls                      | boolean                                   | 否    | 是否包含收费站点     |
| hasStairs                     | boolean                                   | 否    | 是否包含台阶       |

## 路线边界（CoordinateBound）

路线边界框坐标。

| 字段           | 类型     | 是否可选 | 说明   |
|--------------|--------|------|------|
| minLatitude  | number | 否    | 最小纬度 |
| minLongitude | number | 否    | 最小经度 |
| maxLatitude  | number | 否    | 最大纬度 |
| maxLongitude | number | 否    | 最大经度 |

## 路线步骤（RouteStep）

路线的每个步骤，包含具体的导航指示。

| 字段                           | 类型                            | 是否可选 | 说明          |
|------------------------------|-------------------------------|------|-------------|
| roads                        | [RouteRoad](#路线道路RouteRoad)[] | 否    | 道路段列表       |
| startLocation                | [LatLng](#latlng坐标对象)         | 否    | 步骤起点坐标      |
| startAddress                 | string                        | 否    | 起点地址        |
| endLocation                  | [LatLng](#latlng坐标对象)         | 否    | 步骤终点坐标      |
| endAddress                   | string                        | 否    | 终点地址        |
| viaWaypoints                 | [Waypoint](#途经点Waypoint)[]    | 否    | 途经点信息       |
| distance                     | number                        | 否    | 本步骤距离（米）    |
| distanceDescription          | string                        | 否    | 距离描述        |
| duration                     | number                        | 否    | 本步骤预计时间（秒）  |
| durationDescription          | string                        | 否    | 时间描述        |
| durationInTraffic            | number                        | 否    | 实时路况下的时间（秒） |
| durationInTrafficDescription | string                        | 否    | 实时路况时间描述    |

## 路线道路（RouteRoad）

路线的每段道路。

| 字段                  | 类型                      | 是否可选 | 说明       |
|---------------------|-------------------------|------|----------|
| startLocation       | [LatLng](#latlng坐标对象)   | 否    | 道路段起点坐标  |
| endLocation         | [LatLng](#latlng坐标对象)   | 否    | 道路段终点坐标  |
| polyline            | [LatLng](#latlng坐标对象)[] | 否    | 道路段坐标点列表 |
| distance            | number                  | 否    | 道路段距离（米） |
| distanceDescription | string                  | 否    | 距离描述     |
| duration            | number                  | 否    | 道路段时间（秒） |
| durationDescription | string                  | 否    | 时间描述     |
| roadName            | string                  | 否    | 道路名称     |

## 途经点（Waypoint）

路线途经点信息。

| 字段       | 类型                    | 是否可选 | 说明    |
|----------|-----------------------|------|-------|
| location | [LatLng](#latlng坐标对象) | 否    | 途经点坐标 |
| name     | string                | 否    | 途经点名称 |

## 矩阵结果（MatrixResult）

批量算路返回结果。

| 字段                   | 类型                           | 是否可选 | 说明     |
|----------------------|------------------------------|------|--------|
| originAddresses      | string[]                     | 否    | 起点地址列表 |
| destinationAddresses | string[]                     | 否    | 终点地址列表 |
| rows                 | [MatrixRow](#矩阵行MatrixRow)[] | 否    | 矩阵行列表  |

## 矩阵行（MatrixRow）

矩阵结果中的一行。

| 字段    | 类型                               | 是否可选 | 说明      |
|-------|----------------------------------|------|---------|
| cells | [MatrixCell](#矩阵单元格MatrixCell)[] | 否    | 矩阵单元格列表 |

## 矩阵单元格（MatrixCell）

矩阵结果中的单个单元格。

| 字段                  | 类型     | 是否可选 | 说明      |
|---------------------|--------|------|---------|
| distance            | number | 否    | 距离（米）   |
| distanceDescription | string | 否    | 距离描述    |
| duration            | number | 否    | 预计时间（秒） |
| durationDescription | string | 否    | 时间描述    |

## 纠偏点（SnappedPoint）

轨迹纠偏后的坐标点。

| 字段        | 类型     | 是否可选 | 说明   |
|-----------|--------|------|------|
| latitude  | number | 否    | 纬度   |
| longitude | number | 否    | 经度   |
| roadId    | string | 否    | 道路ID |

## 地址结构（AddressDetail）

| 字段           | 是否可选 | 说明     |
|--------------|------|--------|
| country      | 是    | 国家/地区名 |
| countryCode  | 是    | 国家/地区码 |
| adminArea    | 是    | 省/州    |
| subAdminArea | 是    | 市      |
| locality     | 是    | 城市     |
| subLocality  | 是    | 区/县    |
| thoroughfare | 是    | 街道     |
| streetNumber | 是    | 门牌号    |
| postalCode   | 是    | 邮政编码   |