# API参考文档链接

本技能涉及的API参考文档链接如下：

## 主要API

### MapCircleOptions
- **文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common
- **说明**: 圆形参数配置，用于设置圆心、半径、颜色、边框等属性
- **起始版本**: 4.1.0(11)

### addCircle
- **文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller
- **说明**: 在地图上添加圆形的异步方法
- **返回值**: Promise<MapCircle>
- **错误码**: 401（参数无效）、1002601001（对象不存在）
- **起始版本**: 4.1.0(11)

### MapCircle
- **文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcircle
- **说明**: 圆形对象实例，支持更新和查询圆形属性
- **主要方法**:
  - getCenter(): 获取圆心坐标
  - getRadius(): 获取半径
  - setCenter(): 设置圆心坐标
  - setRadius(): 设置半径
  - setFillColor(): 设置填充颜色
  - setStrokeColor(): 设置边框颜色
  - setStrokeWidth(): 设置边框宽度
  - setClickable(): 设置可点击性
- **起始版本**: 4.1.0(11)

## 相关API

### LatLng
- **说明**: 经纬度坐标对象
- **属性**:
  - latitude: 纬度，取值范围[-90, 90]
  - longitude: 经度，取值范围[-180, 180)

### PatternItem
- **说明**: 边框样式配置
- **属性**:
  - type: 样式类型（SOLID/DASH/GAP）
  - length: 样式长度

### BaseOverlayOptions
- **说明**: 覆盖物基础属性
- **属性**:
  - visible: 是否可见
  - zIndex: 层级顺序