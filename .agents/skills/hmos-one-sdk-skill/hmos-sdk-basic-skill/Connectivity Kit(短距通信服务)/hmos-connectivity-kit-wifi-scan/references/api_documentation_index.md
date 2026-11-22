# 参考文档索引

本技能参考以下HarmonyOS官方文档：

## API开发指南

- [Wi-Fi扫描开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-development-guide)
  - 原始路径: `D:\code\APIDevice\output\md_output\harmonyos-guides\系统\网络\Connectivity Kit（短距通信服务）\WLAN\Wi-Fi扫描开发指南\scan-development-guide.md`
  - 内容涵盖: Wi-Fi扫描、PNO扫描、周期扫描、扫描管控

## API参考文档

- [WLAN API参考 (@ohos.wifiManager)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
  - 原始路径: `D:\code\APIDevice\output\md_output\harmonyos-references\系统\网络\Connectivity Kit（短距通信服务）\ArkTS API\js-apis-wifimanager.md`
  - 主要API:
    - `wifiManager.isWifiActive()` - 检查WiFi状态
    - `wifiManager.getScanInfoList()` - 获取扫描结果
    - `wifiManager.on('wifiScanStateChange')` - 注册扫描事件
    - `wifiManager.off('wifiScanStateChange')` - 取消注册事件

- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)
  - 原始路径: `D:\code\APIDevice\output\md_output\harmonyos-references\系统\网络\Connectivity Kit（短距通信服务）\错误码\errorcode-wifi.md`
  - 错误码范围: 2401000-2801000
  - 主要错误码:
    - 2501000: STA内部异常
    - 2501001: STA功能未打开
    - 2501003/2501004: 服务状态异常

## 数据结构

### WifiScanInfo

扫描结果数据结构包含以下字段：

| 字段名 | 类型 | 说明 |
|-------|------|------|
| ssid | string | 网络名称（SSID），最大32字节UTF-8编码 |
| bssid | string | 网络地址（BSSID），格式如00:11:22:33:44:55 |
| bssidType | DeviceAddressType | BSSID类型（真实/随机） |
| capabilities | string | 网络能力 |
| securityType | number | 安全类型（0-10） |
| rssi | number | 信号强度（负值，单位dBm） |
| band | number | 频段（1:2.4GHz, 2:5GHz, 3:6GHz） |
| frequency | number | 频率（MHz） |
| channelWidth | number | 信道宽度 |
| timestamp | number | 时间戳 |
| supportedWifiCategory | number | WiFi类别（1-5） |
| isHiLinkNetwork | boolean | 是否HiLink网络 |

## 相关权限

### 必需权限
- `ohos.permission.GET_WIFI_INFO` - 获取WiFi基本信息

### 可选权限
- `ohos.permission.GET_WIFI_PEERS_MAC` - 获取真实BSSID
- `ohos.permission.SET_WIFI_INFO` - 触发扫描（系统应用）

## 系统要求

- **API版本**: HarmonyOS API version 9+（getScanInfoList从API 10开始）
- **系统能力**: `SystemCapability.Communication.WiFi.STA`
- **设备类型**: 支持WiFi功能的设备
- **运行状态**: 应用需在前台运行

## 文档更新说明

以上文档链接为HarmonyOS官方在线文档，会随HarmonyOS版本更新而更新。
本地文档副本位于 `D:\code\APIDevice\output\md_output\` 目录下，仅供开发参考使用。