# NetworkBoost
---
# NetworkBoost
#### 概述
提供网络质量与网络连接迁移相关接口。
- 网络质量模块提供网络质量实时评估、网络场景识别以及弱信号预测等能力，以便应用针对弱网等环境下实现网络自适应，包括缓存、码率、帧率、分辨率等策略的调整。应用也可以通过网络质量中的应用传输体验反馈接口，触发系统进行网络加速。
- 连接迁移模块提供网络连接迁移能力，以便在弱网环境下，系统发起多网迁移（Wi-Fi<->蜂窝，主卡<->副卡等）的过程中，给应用提供连接迁移开始和完成通知，应用根据连接迁移通知的建议进行重建，快速恢复业务，给用户带来平滑、高速、低时延的上网体验。
- 多网并发是系统提供接口可以建立多个网络通路，应用发起多网请求后，系统依据业务场景决定并发组合和实施相应的并发管控，并对并发做收益度量。使用多网并发功能的原则是应用申请（受限权限）、系统管控、最小化使用。
**起始版本：** 5.1.0(18)
#### 汇总
#### 文件
| 名称 | 描述 |
| --- | --- |
| [network_boost_handover.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover) | 声明用于连接迁移的API。提供基本的函数，结构体和const定义。 |
| [network_boost_quality.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-quality) | 声明用于网络质量的API。提供基本的函数，结构体和const定义。 |
| [network_boost.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-boost) | 声明用于网络加速的API。提供基本的函数，结构体和const定义。 |
#### 结构体
| 名称 | 描述 |
| --- | --- |
| struct[NetworkBoost_DataSpeedAction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-data_speed_action) | 发包速率建议。 |
| struct[NetworkBoost_NetHandle](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-net_handle) | NetHandle信息。 |
| struct[NetworkBoost_HandoverStart](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_start) | 连接迁移开始信息。 |
| struct[NetworkBoost_HandoverComplete](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_complete) | 连接迁移完成信息。 |
| struct[HMS_NetworkBoost_HandoverCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_callback) | 连接迁移回调信息。 |
| struct[NetworkBoost_NetworkQos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos) | 单条路径的网络质量回调信息。 |
| struct[NetworkBoost_NetworkQosArray](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos_array) | 多条路径的网络质量回调信息。 |
| struct[NetworkBoost_WeakSignalPrediction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction) | 弱信号预测相关信息。 |
| struct[NetworkBoost_NetworkScene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 网络场景状态变更回调信息。 |
#### 类型定义
| 名称 | 描述 |
| --- | --- |
| typedef void(*[HMS_NetworkBoost_NetQosChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)) ([NetworkBoost_NetworkQosArray](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_qos_array)*networkQosArray) | 网络质量变更回调函数原型。 |
#### 枚举
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_PathType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview){ NB_PATH_CELLULAR_PRIMARY = 0, NB_PATH_CELLULAR_SECONDARY = 1, NB_PATH_WIFI_PRIMARY = 2, NB_PATH_WIFI_SECONDARY = 3 } | 数据路径类型，枚举值。 |
| [NetworkBoost_Scene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview){ NB_SCENE_NORMAL = 0, NB_SCENE_CONGESTION = 1, NB_SCENE_FREQUENT_HANDOVER = 2, NB_SCENE_WEAK_SIGNAL = 3 } | 网络场景类型。 |
#### 函数
| 名称 | 描述 |
| --- | --- |
| int32_t[HMS_NetworkBoost_RegisterNetQosCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)([HMS_NetworkBoost_NetQosChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)callback, uint32_t *callbackId) | 注册网络质量变化回调。 |
| int32_t[HMS_NetworkBoost_UnregisterNetQosCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)(uint32_t callbackId) | 取消注册网络质量变化回调。 |

#### 函数说明
#### HMS_NetworkBoost_RegisterNetQosCallback()
```
int32_t HMS_NetworkBoost_RegisterNetQosCallback (HMS_NetworkBoost_NetQosChange callback, uint32_t * callbackId )
```
**描述**
注册网络质量信息回调。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 网络质量回调函数。 |
| callbackId | 回调函数的ID，由系统分配，用于取消注册回调。 |
**返回：**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
62100003 - 注册请求达到上限。
**权限：**
ohos.permission.GET_NETWORK_INFO
#### HMS_NetworkBoost_UnregisterNetQosCallback()
```
int32_t HMS_NetworkBoost_UnregisterNetQosCallback (uint32_t callbackId)
```
**描述**
取消注册网络质量信息回调。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callbackId | 回调的ID，在注册回调函数时由系统分配。 |
**返回：**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
**权限：**
ohos.permission.GET_NETWORK_INFO