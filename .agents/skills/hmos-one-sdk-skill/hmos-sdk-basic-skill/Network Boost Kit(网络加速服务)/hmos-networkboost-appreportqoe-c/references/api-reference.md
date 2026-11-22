# HMS_NetworkBoost_ReportQoe API参考

## 概述

**API名称**：HMS_NetworkBoost_ReportQoe

**功能**：应用传输体验反馈

**起始版本**：5.1.0(18)

**系统能力**：SystemCapability.Communication.NetworkBoost.Core

**头文件**：NetworkBoostKit/network_boost_quality.h

**库文件**：libnetwork_boost.so

## 函数定义

```cpp
int32_t HMS_NetworkBoost_ReportQoe(NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType)
```

## 参数说明

| 参数名 | 类型 | 说明 |
|-------|------|------|
| serviceType | NetworkBoost_ServiceType | 应用的业务类型 |
| qoeType | NetworkBoost_QoeType | 应用的网络体验类型 |

## 返回值

| 返回值 | 说明 |
|-------|------|
| 0 | 成功 |
| 201 | 权限不足 |
| 401 | 参数错误 |
| 801 | 系统能力不支持 |
| 62100001 | 内部错误 |
| 62100002 | 系统服务操作失败 |

## 权限要求

- **必需权限**：ohos.permission.GET_NETWORK_INFO

## 参数枚举说明

### NetworkBoost_ServiceType（业务类型）

| 枚举值 | 数值 | 说明 |
|-------|------|------|
| NB_SERVICE_DEFAULT | 0 | 默认服务类型 |
| NB_SERVICE_BACKGROUND | 1 | 后台类型 |
| NB_SERVICE_REAL_TIME_VOICE | 2 | 实时语音类型 |
| NB_SERVICE_REAL_TIME_VIDEO | 3 | 实时视频类型 |
| NB_SERVICE_CALL_SIGNALING | 4 | 语音信令类型 |
| NB_SERVICE_REAL_TIME_GAME | 5 | 实时游戏类型 |
| NB_SERVICE_NORMAL_GAME | 6 | 普通游戏类型 |
| NB_SERVICE_SHORT_VIDEO | 7 | 短视频类型 |
| NB_SERVICE_LONG_VIDEO | 8 | 长视频类型 |
| NB_SERVICE_LIVE_STREAMING_ANCHOR | 9 | 直播主播类型 |
| NB_SERVICE_LIVE_STREAMING_WATCHER | 10 | 直播观看类型 |
| NB_SERVICE_DOWNLOAD | 11 | 下载类型 |
| NB_SERVICE_UPLOAD | 12 | 上传类型 |
| NB_SERVICE_BROWSER | 13 | 浏览页面类型 |
| NB_SERVICE_TRANSACTION | 14 | 交易支付或扫码类型 |
| NB_SERVICE_DETECTION | 15 | 探测类型 |
| NB_SERVICE_CLOUDSERVICE | 16 | 云业务、云游戏类型 |
| NB_SERVICE_VOICE_CONFERENCE | 17 | 语音会议类型 |
| NB_SERVICE_VIDEO_CONFERENCE | 18 | 视频会议类型 |
| NB_SERVICE_NAVIGATION | 19 | 导航定位类型 |
| NB_SERVICE_SECKILL_SERVICE | 20 | 秒杀业务类型 |
| NB_SERVICE_LOGIN | 21 | 登录（含一键登录）类型 |
| NB_SERVICE_AUDIO | 22 | 音乐、音频类型 |
| NB_SERVICE_SHOPPING | 23 | 购物类型 |

### NetworkBoost_QoeType（体验类型）

| 枚举值 | 数值 | 说明 |
|-------|------|------|
| NB_QOE_GOOD | 0 | 体验良好 |
| NB_QOE_BAD_UNKNOWN | 1 | 体验差：未知原因 |
| NB_QOE_BAD_SERVER_ERROR | 2 | 体验差：服务器异常 |
| NB_QOE_BAD_NO_DATA | 3 | 体验差：无数据 |
| NB_QOE_BAD_PACKET_LOST | 4 | 体验差：丢包 |
| NB_QOE_BAD_PACKET_OUT_OF_ORDER | 5 | 体验差：乱序 |
| NB_QOE_BAD_HIGH_JITTER | 6 | 体验差：高抖动 |
| NB_QOE_BAD_HIGH_LATENCY | 7 | 体验差：高时延 |

## 参考链接

- [NetworkBoost模块概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [network_boost_quality.h头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-quality)