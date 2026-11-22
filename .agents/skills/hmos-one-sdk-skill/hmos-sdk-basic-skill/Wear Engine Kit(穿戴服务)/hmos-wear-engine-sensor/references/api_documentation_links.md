# API文档链接说明

本文档说明原始API文档的位置和在线链接转换规则。

## 原始开发指南文档

**本地路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\硬件\Wear Engine Kit（穿戴服务）\手机侧应用开发\应用开发\穿戴设备传感器获取\device_sensor.md`

**在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/device_sensor

## 原始API参考文档

**本地路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\系统\硬件\Wear Engine Kit（穿戴服务）\ArkTS API\wearengine_api.md`

**在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

## 链接转换规则

根据用户要求,文档中的md链接需要按照以下规则转换:

1. **只保留md文件名**: 从完整路径中提取文件名部分(去掉.md后缀)
2. **判断文档类型**:
   - 如果原始路径包含 `harmonyos-guides`,则替换为: `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}`
   - 如果原始路径包含 `harmonyos-references`,则替换为: `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}`
3. **去掉.md后缀**: 最终链接不包含.md后缀

## 示例转换

### 示例1: harmonyos-guides文档

**原始链接**: `D:/code/APIDevice/output/md_output/harmonyos-guides/系统/硬件/Wear Engine Kit（穿戴服务）/手机侧应用开发/应用开发/请求用户授权/request_user_authorization.md`

**转换后链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization

### 示例2: harmonyos-references文档

**原始链接**: `D:/code/APIDevice/output/md_output/harmonyos-references/系统/硬件/Wear Engine Kit（穿戴服务）/ArkTS API/wearengine_api.md`

**转换后链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

## 关键API文档链接

以下是与穿戴设备传感器获取相关的关键API文档链接(已按规则转换):

- **请求用户授权**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization
- **已连接穿戴设备查询**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices
- **目标设备选择**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection
- **申请接入Wear Engine服务**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply
- **wearEngine API参考**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api
- **Wear Engine错误码**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code

## 技能文档中的链接处理

在生成的SKILL.md文件中,所有参考文档链接已按照上述规则转换,确保链接指向正确的在线文档位置。

**注意**: 实际使用时,请确保这些在线文档链接可访问。如果链接失效,请访问华为开发者官网搜索相关文档。