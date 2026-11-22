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
| [network_boost_handover.h](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/头文件/network-boost-c-files-handover.md) | 声明用于连接迁移的API。提供基本的函数，结构体和const定义。 |
| [network_boost_quality.h](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/头文件/network-boost-c-files-quality.md) | 声明用于网络质量的API。提供基本的函数，结构体和const定义。 |
| [network_boost.h](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/头文件/network-boost-c-files-boost.md) | 声明用于网络加速的API。提供基本的函数，结构体和const定义。 |
#### 结构体
| 名称 | 描述 |
| --- | --- |
| struct[NetworkBoost_DataSpeedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-data_speed_action.md) | 发包速率建议。 |
| struct[NetworkBoost_NetHandle](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-net_handle.md) | NetHandle信息。 |
| struct[NetworkBoost_HandoverStart](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_start.md) | 连接迁移开始信息。 |
| struct[NetworkBoost_HandoverComplete](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_complete.md) | 连接迁移完成信息。 |
| struct[HMS_NetworkBoost_HandoverCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_callback.md) | 连接迁移回调信息。 |
| struct[NetworkBoost_NetworkQos](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md) | 单条路径的网络质量回调信息。 |
| struct[NetworkBoost_NetworkQosArray](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos_array.md) | 多条路径的网络质量回调信息。 |
| struct[NetworkBoost_WeakSignalPrediction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-weak_signal_prediction.md) | 弱信号预测相关信息。 |
| struct[NetworkBoost_NetworkScene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_scene.md) | 网络场景状态变更回调信息。 |
| struct[NetworkBoost_MultiPathQuotaInfo](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_quotainfo.md) | 配额信息。 |
| struct[NetworkBoost_MultiPathQuota](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_quota.md) | 应用配额使用信息。 |
| struct[NetworkBoost_MultiPathRequestResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_req_result.md) | 多网请求结果。 |
| struct[NetworkBoost_MultiPathStateChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_statechange.md) | 多网状态信息。 |
| struct[NetworkBoost_MultiPathRecommendation](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_reco.md) | 多网推荐信息。 |
| struct[NetworkBoost_SceneDesc](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-scene_desc.md) | 业务场景描述信息。 |
#### 宏定义
| 名称 | 描述 |
| --- | --- |
| [NETBOOST_MAX_PATH_NUM](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)4 | 网络质量变化信息的最大路径数量。 |
| [NB_BPS](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)1 | 1bps |
| [NB_KBPS](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)1000 | 1kbps |
| [NB_MBPS](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)1000000 | 1mbps |
| [NB_GBPS](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)1000000000 | 1gbps |
| [NB_TBPS](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)1000000000000 | 1tbps，请使用uint64_t类型来避免溢出。 |
#### 类型定义
| 名称 | 描述 |
| --- | --- |
| typedef enum[NetworkBoost_DataSpeedSimpleAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_DataSpeedSimpleAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 应用发包策略的建议。 |
| typedef enum[NetworkBoost_ErrorResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_ErrorResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 连接迁移结果枚举。 |
| typedef enum[NetworkBoost_ReEstAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_ReEstAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 重建枚举。 |
| typedef struct[NetworkBoost_DataSpeedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-data_speed_action.md)[NetworkBoost_DataSpeedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 发包速率建议。 |
| typedef struct[NetworkBoost_NetHandle](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-net_handle.md)[NetworkBoost_NetHandle](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | NetHandle信息。 |
| typedef struct[NetworkBoost_HandoverStart](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_start.md)[NetworkBoost_HandoverStart](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 连接迁移开始信息。 |
| typedef struct[NetworkBoost_HandoverComplete](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_complete.md)[NetworkBoost_HandoverComplete](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 连接迁移完成信息。 |
| typedef enum[NetworkBoost_HandoverMode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_HandoverMode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 连接迁移模式枚举。 |
| typedef void(*[HMS_NetworkBoost_OnHandoverStart](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)) ([NetworkBoost_HandoverStart](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_start.md)*handoverStart) | 连接迁移开始的回调函数原型。 |
| typedef void(*[HMS_NetworkBoost_OnHandoverComplete](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)) ([NetworkBoost_HandoverComplete](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_complete.md)*handoverComplete) | 连接迁移结束的回调函数原型。 |
| typedef struct[HMS_NetworkBoost_HandoverCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_callback.md)[HMS_NetworkBoost_HandoverCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 连接迁移回调注册函数的参数，包含连接迁移开始和完成的回调函数。 |
| typedef enum[NetworkBoost_RecommendedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_RecommendedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 应用数传策略建议。 |
| typedef enum[NetworkBoost_PathType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_PathType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 数据路径类型，枚举值。 |
| typedef enum[NetworkBoost_Scene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_Scene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 网络场景类型。 |
| typedef enum[NetworkBoost_ServiceType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_ServiceType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 应用业务类型。 |
| typedef enum[NetworkBoost_QoeType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)[NetworkBoost_QoeType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 应用体验类型。 |
| typedef struct[NetworkBoost_NetworkQos](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos.md)[NetworkBoost_NetworkQos](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 单条路径的网络质量回调信息。 |
| typedef struct[NetworkBoost_NetworkQosArray](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos_array.md)[NetworkBoost_NetworkQosArray](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 多条路径的网络质量回调信息。 |
| typedef struct[NetworkBoost_WeakSignalPrediction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-weak_signal_prediction.md)[NetworkBoost_WeakSignalPrediction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 弱信号预测相关信息。 |
| typedef struct[NetworkBoost_NetworkScene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_scene.md)[NetworkBoost_NetworkScene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) | 网络场景状态变更回调信息。 |
| typedef void(*[HMS_NetworkBoost_NetQosChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)) ([NetworkBoost_NetworkQosArray](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_qos_array.md)*networkQosArray) | 网络质量变更回调函数原型。 |
| typedef void(*[HMS_NetworkBoost_NetSceneChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)) ([NetworkBoost_NetworkScene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-network_scene.md)*networkScene) | 网络场景状态变更回调函数原型。 |
| typedef void (*[HMS_NetworkBoost_OnMultiPathRequestResult](#section1291820306417))([NetworkBoost_MultiPathRequestResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_req_result.md)* result) | 多网请求结果回调函数原型。 |
| typedef void (*[HMS_NetworkBoost_OnMultiPathStateChange](#section192149121805))([NetworkBoost_MultiPathStateChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_statechange.md)* multiPathState) | 多网状态变化回调函数原型。 |
| typedef void (*[HMS_NetworkBoost_OnMultiPathRecommendation](#section198348561206))([NetworkBoost_MultiPathRecommendation](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_reco.md)* recommendation) | 系统多网建议变化回调函数原型。 |
#### 枚举
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_DataSpeedSimpleAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){ NB_SIMPLEACTION_SUSPEND_DATA = 1, NB_SIMPLEACTION_DECREASE_DATA = 2, NB_SIMPLEACTION_INCREASE_DATA = 3, NB_SIMPLEACTION_KEEP_DATA = 4 } | 应用发包策略的建议。 |
| [NetworkBoost_ErrorResult](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){ NB_ERROR_NONE = 0, NB_ERROR_HANDOVER_TIMEOUT = 1, NB_ERROR_NEW_PATH_ACTIVATION_FAILED = 2, NB_ERROR_ABORT = 3 } | 连接迁移结果枚举。 |
| [NetworkBoost_ReEstAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){NB_REEST_DEFAULT = 0, NB_REEST_QUERY_DNS = 1, NB_REEST_CHANGE_REMOTE_IP = 2, NB_REEST_CHANGE_IP_VERSION = 3,NB_NO_EST = 4} | 重建枚举。 |
| [NetworkBoost_HandoverMode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){ NB_MODE_DELEGATION = 0, NB_MODE_DISCRETION = 1 } | 连接迁移模式枚举。 |
| [NetworkBoost_RecommendedAction](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){NB_ACTION_DO_CACHING = 0, NB_ACTION_SUSPEND_DATA = 1, NB_ACTION_DECREASE_DATA = 2, NB_ACTION_INCREASE_DATA = 3,NB_ACTION_KEEP_DATA = 4} | 应用数传策略建议。 |
| [NetworkBoost_PathType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){ NB_PATH_CELLULAR_PRIMARY = 0, NB_PATH_CELLULAR_SECONDARY = 1, NB_PATH_WIFI_PRIMARY = 2, NB_PATH_WIFI_SECONDARY = 3 } | 数据路径类型，枚举值。 |
| [NetworkBoost_Scene](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){ NB_SCENE_NORMAL = 0, NB_SCENE_CONGESTION = 1, NB_SCENE_FREQUENT_HANDOVER = 2, NB_SCENE_WEAK_SIGNAL = 3 } | 网络场景类型。 |
| [NetworkBoost_ServiceType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){NB_SERVICE_DEFAULT = 0, NB_SERVICE_BACKGROUND = 1, NB_SERVICE_REAL_TIME_VOICE = 2, NB_SERVICE_REAL_TIME_VIDEO = 3,NB_SERVICE_CALL_SIGNALING = 4, NB_SERVICE_REAL_TIME_GAME = 5, NB_SERVICE_NORMAL_GAME = 6, NB_SERVICE_SHORT_VIDEO = 7,NB_SERVICE_LONG_VIDEO = 8, NB_SERVICE_LIVE_STREAMING_ANCHOR = 9, NB_SERVICE_LIVE_STREAMING_WATCHER = 10, NB_SERVICE_DOWNLOAD = 11,NB_SERVICE_UPLOAD = 12, NB_SERVICE_BROWSER = 13, NB_SERVICE_BROWSER = 13, NB_SERVICE_TRANSACTION = 14, NB_SERVICE_DETECTION = 15, NB_SERVICE_CLOUDSERVICE = 16, NB_SERVICE_VOICE_CONFERENCE = 17, NB_SERVICE_VIDEO_CONFERENCE = 18, NB_SERVICE_NAVIGATION = 19, NB_SERVICE_SECKILL_SERVICE = 20, NB_SERVICE_LOGIN = 21, NB_SERVICE_AUDIO = 22, NB_SERVICE_SHOPPING = 23} | 应用业务类型。 |
| [NetworkBoost_QoeType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md){NB_QOE_GOOD = 0, NB_QOE_BAD_UNKNOWN = 1, NB_QOE_BAD_SERVER_ERROR = 2, NB_QOE_BAD_NO_DATA = 3,NB_QOE_BAD_PACKET_LOST = 4, NB_QOE_BAD_PACKET_OUT_OF_ORDER = 5, NB_QOE_BAD_HIGH_JITTER = 6, NB_QOE_BAD_HIGH_LATENCY = 7} | 应用体验类型。 |
| [NetworkBoost_PathState](#section1774664693518){NB_PATH_IDLE = 0，NB_PATH_CONNECTED = 1，NB_PATH_SUSPENDED = 2} | 多网链路状态的枚举。 |
| [NetworkBoost_MultiPathErrorResult](#section129101047154112){NB_MULTIPATH_ERROR_NONE = 0，NB_MULTIPATH_ERROR_NETWORK_REFUSED = 1， NB_MULTIPATH_ERROR_TIMEOUT = 2， NB_MULTIPATH_ERROR_LOCAL = 3} | 多网建立结果的枚举。 |
| [NetworkBoost_MultiPathChangeCause](#section19927184203916){NB_MULTIPATH_CAUSE_REQUEST_NORMAL = 0, NB_MULTIPATH_CAUSE_RELEASE_NORMAL = 50, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK = 51, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED = 52, NB_MULTIPATH_CAUSE_RELEASE_NO_QUOTA = 53, NB_MULTIPATH_CAUSE_RELEASE_POWER_CONSUMPTION = 54, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC = 55, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT = 56, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING = 57, NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT = 99, NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER = 100, NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE = 101, NB_MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE = 102} | 多网变化原因的枚举。 |
| [NetworkBoost_MultiPathState](#section12626124820456){NB_MULTIPATH_IDLE = 0, NB_MULTIPATH_CREATEING = 1, NB_MULTIPATH_CREATED = 2, NB_MULTIPATH_RELEASING = 3} | 多网状态的枚举。 |
| [NetworkBoost_MultiPathAction](#section12185112974610){NB_MULTIPATH_ACTION_REQUEST = 0， NB_MULTIPATH_ACTION_RELEASE = 1} | 多网推荐动作的枚举。 |
| [NetworkBoost_SceneEvent](#section9626183119507){NB_SCENE_EVENT_ENTER = 0， NB_SCENE_EVENT_UPDATE = 1，NB_SCENE_EVENT_LEAVE = 2} | 业务事件枚举。 |
#### 函数
| 名称 | 描述 |
| --- | --- |
| int32_t[HMS_NetworkBoost_RegisterHandoverChangeCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)([HMS_NetworkBoost_HandoverCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-handover_callback.md)*callback, uint32_t *callbackId) | 注册连接迁移回调。 |
| int32_t[HMS_NetworkBoost_UnregisterHandoverChangeCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)(uint32_t callbackId) | 取消注册连接迁移回调。 |
| int32_t[HMS_NetworkBoost_SetHandoverMode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)([NetworkBoost_HandoverMode](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)mode) | 应用可通过该接口变更连接迁移模式，包括委托模式(由系统发起连接迁移)，和自主模式(由应用发起连接迁移)，默认为委托模式。 |
| int32_t[HMS_NetworkBoost_RegisterNetQosCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)([HMS_NetworkBoost_NetQosChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)callback, uint32_t *callbackId) | 注册网络质量变化回调。 |
| int32_t[HMS_NetworkBoost_UnregisterNetQosCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)(uint32_t callbackId) | 取消注册网络质量变化回调。 |
| int32_t[HMS_NetworkBoost_RegisterNetSceneCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)([HMS_NetworkBoost_NetSceneChange](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)callback, uint32_t *callbackId) | 注册网络场景变化回调。 |
| int32_t[HMS_NetworkBoost_UnregisterNetSceneCallback](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)(uint32_t callbackId) | 取消注册网络场景变化回调。 |
| int32_t[HMS_NetworkBoost_ReportQoe](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)([NetworkBoost_ServiceType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)serviceType,[NetworkBoost_QoeType](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md)qoeType) | 应用传输体验反馈。 |
| int32_t[HMS_NetworkBoost_GetMultiPathQuotaStats](#section3899010125311)([NetworkBoost_MultiPathQuota](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-multipath_quota.md)*quota) | 获取当前应用多网使用的配额，包括已使用的配额信息和剩余配额信息。 |
| int32_t[HMS_NetworkBoost_RequestMultiPath](#section13240250195914)([HMS_NetworkBoost_OnMultiPathRequestResult](#section1291820306417)result) | 发起多网请求。 |
| int32_t[HMS_NetworkBoost_ReleaseMultiPath](#section58537189614)() | 释放多网请求。 |
| int32_t[HMS_NetworkBoost_RegisterMultiPathStateChangeCallback](#section421172813919)([HMS_NetworkBoost_OnMultiPathStateChange](#section192149121805)callback, uint32_t* callbackId) | 注册多网状态变化事件。 |
| int32_t[HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback](#section52786305915)(uint32_t callbackId) | 去注册多网状态变化事件。 |
| int32_t[HMS_NetworkBoost_RegisterMultiPathRecommendationCallback](#section463012484123)([HMS_NetworkBoost_OnMultiPathRecommendation](#section198348561206)callback, uint32_t* callbackId) | 注册系统多网建议变化事件。 |
| int32_t[HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback](#section18632948201214)(uint32_t callbackId) | 去系统多网建议变化事件。 |
| int32_t[HMS_NetworkBoost_SetSceneDesc](#section1441013415156)([NetworkBoost_SceneDesc](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/头文件和结构体/结构体/network-boost-c-struct-scene_desc.md)sceneDesc) | 设置业务场景。 |
#### 宏定义说明
#### NB_BPS
```
#define NB_BPS   1
```
**描述**
1bps
**起始版本：** 5.1.0(18)
#### NB_GBPS
```
#define NB_GBPS   1000000000
```
**描述**
1gbps
**起始版本：** 5.1.0(18)
#### NB_KBPS
```
#define NB_KBPS   1000
```
**描述**
1kbps
**起始版本：** 5.1.0(18)
#### NB_MBPS
```
#define NB_MBPS   1000000
```
**描述**
1mbps
**起始版本：** 5.1.0(18)
#### NB_TBPS
```
#define NB_TBPS   1000000000000
```
**描述**
1tbps。请使用uint64_t类型来避免溢出。
**起始版本：** 5.1.0(18)
#### NETBOOST_MAX_PATH_NUM
```
#define NETBOOST_MAX_PATH_NUM   4
```
**描述**
网络质量变化的详细信息数组的最大长度值。
**起始版本：** 5.1.0(18)
#### 类型定义说明
#### HMS_NetworkBoost_HandoverCallback
```
typedef struct HMS_NetworkBoost_HandoverCallback HMS_NetworkBoost_HandoverCallback
```
**描述**
连接迁移回调信息。回调中的每个方法都不能为空。
**起始版本：** 5.1.0(18)
#### HMS_NetworkBoost_NetQosChange
```
typedef void(* HMS_NetworkBoost_NetQosChange) (NetworkBoost_NetworkQosArray *networkQosArray)
```
**描述**
回调函数，返回网络质量变化的详细信息。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| networkQosArray | 网络质量变化的详细信息 |
#### HMS_NetworkBoost_NetSceneChange
```
typedef void(* HMS_NetworkBoost_NetSceneChange) (NetworkBoost_NetworkScene *networkScene)
```
**描述**
回调函数，返回网络场景变化的详细信息。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| networkScene | 网络场景变化的详细信息 |
#### HMS_NetworkBoost_OnHandoverComplete
```
typedef void(* HMS_NetworkBoost_OnHandoverComplete) (NetworkBoost_HandoverComplete *handoverComplete)
```
**描述**
回调函数，返回连接迁移完成变化的详细信息。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| handoverComplete | 连接迁移完成的详细信息 |
#### HMS_NetworkBoost_OnHandoverStart
```
typedef void(* HMS_NetworkBoost_OnHandoverStart) (NetworkBoost_HandoverStart *handoverStart)
```
**描述**
回调函数，返回连接迁移开始的详细信息。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| handoverStart | 连接迁移开始的详细信息 |
#### HMS_NetworkBoost_OnMultiPathRequestResult
```
typedef void (*HMS_NetworkBoost_OnMultiPathRequestResult)(NetworkBoost_MultiPathRequestResult* result)
```
**描述**
多网请求结果回调原型。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| result | 发起多网的结果。 |
#### HMS_NetworkBoost_OnMultiPathStateChange
```
typedef void (*HMS_NetworkBoost_OnMultiPathStateChange)(NetworkBoost_MultiPathStateChange* multiPathState)
```
**描述**
多网状态变化回调原型。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| multiPathState | 多网状态信息。 |
#### HMS_NetworkBoost_OnMultiPathRecommendation
```
typedef void (*HMS_NetworkBoost_OnMultiPathRecommendation)(NetworkBoost_MultiPathRecommendation* recommendation)
```
**描述**
多网推荐信息变化回调原型。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| recommendation | 多网推荐信息。 |
#### NetworkBoost_DataSpeedAction
```
typedef struct NetworkBoost_DataSpeedAction NetworkBoost_DataSpeedAction
```
**描述**
发包速率建议。
**起始版本：** 5.1.0(18)
#### NetworkBoost_DataSpeedSimpleAction
```
typedef enum NetworkBoost_DataSpeedSimpleAction NetworkBoost_DataSpeedSimpleAction
```
**描述**
应用发包策略的建议。
**起始版本：** 5.1.0(18)
#### NetworkBoost_ErrorResult
```
typedef enum NetworkBoost_ErrorResult NetworkBoost_ErrorResult
```
**描述**
连接迁移结果。
**起始版本：** 5.1.0(18)
#### NetworkBoost_HandoverComplete
```
typedef struct NetworkBoost_HandoverComplete NetworkBoost_HandoverComplete
```
**描述**
连接迁移完成信息。
**起始版本：** 5.1.0(18)
#### NetworkBoost_HandoverMode
```
typedef enum NetworkBoost_HandoverMode NetworkBoost_HandoverMode
```
**描述**
连接迁移模式。
**起始版本：** 5.1.0(18)
#### NetworkBoost_HandoverStart
```
typedef struct NetworkBoost_HandoverStart NetworkBoost_HandoverStart
```
**描述**
连接迁移开始信息。
**起始版本：** 5.1.0(18)
#### NetworkBoost_NetHandle
```
typedef struct NetworkBoost_NetHandle NetworkBoost_NetHandle
```
**描述**
数据网络的句柄。
**起始版本：** 5.1.0(18)
#### NetworkBoost_NetworkQos
```
typedef struct NetworkBoost_NetworkQos NetworkBoost_NetworkQos
```
**描述**
单条路径的网络质量回调信息。
**起始版本：** 5.1.0(18)
#### NetworkBoost_NetworkQosArray
```
typedef struct NetworkBoost_NetworkQosArray NetworkBoost_NetworkQosArray
```
**描述**
多条路径的网络质量回调信息。
**起始版本：** 5.1.0(18)
#### NetworkBoost_NetworkScene
```
typedef struct NetworkBoost_NetworkScene NetworkBoost_NetworkScene
```
**描述**
网络场景状态变更回调信息。
**起始版本：** 5.1.0(18)
#### NetworkBoost_PathType
```
typedef enum NetworkBoost_PathType NetworkBoost_PathType
```
**描述**
路径类型。
**起始版本：** 5.1.0(18)
#### NetworkBoost_QoeType
```
typedef enum NetworkBoost_QoeType NetworkBoost_QoeType
```
**描述**
应用体验类型。
**起始版本：** 5.1.0(18)
#### NetworkBoost_RecommendedAction
```
typedef enum NetworkBoost_RecommendedAction NetworkBoost_RecommendedAction
```
**描述**
建议的数传策略。
**起始版本：** 5.1.0(18)
#### NetworkBoost_ReEstAction
```
typedef enum NetworkBoost_ReEstAction NetworkBoost_ReEstAction
```
**描述**
路径重建类型。
**起始版本：** 5.1.0(18)
#### NetworkBoost_Scene
```
typedef enum NetworkBoost_Scene NetworkBoost_Scene
```
**描述**
网络场景类型。
**起始版本：** 5.1.0(18)
#### NetworkBoost_ServiceType
```
typedef enum NetworkBoost_ServiceType NetworkBoost_ServiceType
```
**描述**
应用业务类型。
**起始版本：** 5.1.0(18)
#### NetworkBoost_WeakSignalPrediction
```
typedef struct NetworkBoost_WeakSignalPrediction NetworkBoost_WeakSignalPrediction
```
**描述**
弱信号预测相关信息。
**起始版本：** 5.1.0(18)
#### 枚举类型说明
#### NetworkBoost_DataSpeedSimpleAction
```
enum NetworkBoost_DataSpeedSimpleAction
```
**描述**
应用发包策略的建议。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_SIMPLEACTION_SUSPEND_DATA | 停止发包。 |
| NB_SIMPLEACTION_DECREASE_DATA | 降低发包速率。 |
| NB_SIMPLEACTION_INCREASE_DATA | 增加发包速率。 |
| NB_SIMPLEACTION_KEEP_DATA | 保持当前发包速率。 |
#### NetworkBoost_ErrorResult
```
enum NetworkBoost_ErrorResult
```
**描述**
连接迁移结果枚举。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_ERROR_NONE | 连接迁移成功。 |
| NB_ERROR_HANDOVER_TIMEOUT | 连接迁移超时。 |
| NB_ERROR_NEW_PATH_ACTIVATION_FAILED | 连接迁移时新链路激活失败。 |
| NB_ERROR_ABORT | 连接迁移被取消。 |
#### NetworkBoost_HandoverMode
```
enum NetworkBoost_HandoverMode
```
**描述**
连接迁移模式枚举。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_MODE_DELEGATION | 委托模式，表示由系统发起连接迁移。默认为该模式。 |
| NB_MODE_DISCRETION | 自主模式，表示由应用发起连接迁移。应用可以通过该接口禁止系统发起连接迁移。在某些场景下，比如该应用切换到后台时，依旧有可能由系统触发切换。 |
#### NetworkBoost_PathType
```
enum NetworkBoost_PathType
```
**描述**
数据路径类型。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_PATH_CELLULAR_PRIMARY | 蜂窝主卡。 |
| NB_PATH_CELLULAR_SECONDARY | 蜂窝副卡。 |
| NB_PATH_WIFI_PRIMARY | 主Wi-Fi。 |
| NB_PATH_WIFI_SECONDARY | 辅Wi-Fi。 |
#### NetworkBoost_QoeType
```
enum NetworkBoost_QoeType
```
**描述**
应用体验类型。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_QOE_GOOD | 体验良好。 |
| NB_QOE_BAD_UNKNOWN | 体验差：未知原因。 |
| NB_QOE_BAD_SERVER_ERROR | 体验差：服务器异常。 |
| NB_QOE_BAD_NO_DATA | 体验差：无数据。 |
| NB_QOE_BAD_PACKET_LOST | 体验差：丢包。 |
| NB_QOE_BAD_PACKET_OUT_OF_ORDER | 体验差：乱序。 |
| NB_QOE_BAD_HIGH_JITTER | 体验差：高抖动。 |
| NB_QOE_BAD_HIGH_LATENCY | 体验差：高时延。 |
#### NetworkBoost_RecommendedAction
```
enum NetworkBoost_RecommendedAction
```
**描述**
应用数传策略建议。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_ACTION_DO_CACHING | 做缓存动作。 |
| NB_ACTION_SUSPEND_DATA | 停止发包。 |
| NB_ACTION_DECREASE_DATA | 降低发包速率。 |
| NB_ACTION_INCREASE_DATA | 增加发包速率。 |
| NB_ACTION_KEEP_DATA | 保持当前发包速率。 |
#### NetworkBoost_ReEstAction
```
enum NetworkBoost_ReEstAction
```
**描述**
重建枚举。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_REEST_DEFAULT | 应用需要使用同样的远端IP，进行重建链路。 |
| NB_REEST_QUERY_DNS | 数据链路类型发生变化，比如Wi-Fi <-> CELL，或者是数据链路所在的运营商信息等变化。 |
| NB_REEST_CHANGE_REMOTE_IP | 应用需要使用不同的远端IP进行重建。 |
| NB_REEST_CHANGE_IP_VERSION | 应用需要修改IP类型进行重建，比如IPV4 <-> IPV6。 |
| NB_NO_EST | 应用应该在老链路进行立即重试，再次发起网络资源请求和交互，无需重建链路。 |
#### NetworkBoost_Scene
```
enum NetworkBoost_Scene
```
**描述**
网络场景类型。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_SCENE_NORMAL | 正常场景。 |
| NB_SCENE_CONGESTION | 拥塞场景。 |
| NB_SCENE_FREQUENT_HANDOVER | 小区切换频繁场景。 |
| NB_SCENE_WEAK_SIGNAL | 弱信号场景。 |
#### NetworkBoost_ServiceType
```
enum NetworkBoost_ServiceType
```
**描述**
应用业务类型。
**起始版本：** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_SERVICE_DEFAULT | 默认服务类型。 |
| NB_SERVICE_BACKGROUND | 后台类型。 |
| NB_SERVICE_REAL_TIME_VOICE | 实时语音类型。 |
| NB_SERVICE_REAL_TIME_VIDEO | 实时视频类型。 |
| NB_SERVICE_CALL_SIGNALING | 语音信令类型。 |
| NB_SERVICE_REAL_TIME_GAME | 实时游戏类型。 |
| NB_SERVICE_NORMAL_GAME | 普通游戏类型。 |
| NB_SERVICE_SHORT_VIDEO | 短视频类型。 |
| NB_SERVICE_LONG_VIDEO | 长视频类型。 |
| NB_SERVICE_LIVE_STREAMING_ANCHOR | 直播主播类型。 |
| NB_SERVICE_LIVE_STREAMING_WATCHER | 直播观看类型。 |
| NB_SERVICE_DOWNLOAD | 下载类型。 |
| NB_SERVICE_UPLOAD | 上传类型。 |
| NB_SERVICE_BROWSER | 浏览页面类型。 |
| NB_SERVICE_TRANSACTION | 交易支付或者扫码类型。 |
| NB_SERVICE_DETECTION | 探测类型。 |
| NB_SERVICE_CLOUDSERVICE | 云业务、云游戏类型。 |
| NB_SERVICE_VOICE_CONFERENCE | 语音会议类型。 |
| NB_SERVICE_VIDEO_CONFERENCE | 视频会议类型。 |
| NB_SERVICE_NAVIGATION | 导航定位类型。 |
| NB_SERVICE_SECKILL_SERVICE | 秒杀业务类型，如抢票、抢购、抢单、抢红包等。 |
| NB_SERVICE_LOGIN | 登录（含一键登录）类型。 |
| NB_SERVICE_AUDIO | 音乐、音频类型。 |
| NB_SERVICE_SHOPPING | 购物类型。 |
#### NetworkBoost_PathState
```
enum NetworkBoost_PathState
```
**描述**
多网链路状态枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_PATH_IDLE | 多网链路处于空闲状态。 |
| NB_PATH_CONNECTED | 多网链路已连接。 |
| NB_PATH_SUSPENDED | 多网链路处于挂起状态。 |
#### NetworkBoost_MultiPathChangeCause
```
enum NetworkBoost_MultiPathChangeCause
```
**描述**
多网变化原因的枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_MULTIPATH_CAUSE_REQUEST_NORMAL | 正常发起多网请求。 |
| NB_MULTIPATH_CAUSE_RELEASE_NORMAL | 正常释放多网请求。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK | 网络原因释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED | 用户操作开关释放多网。 |
| NB_MULTIPATH_CAUSE_RELEASE_NO_QUOTA | 配额耗尽释放多网。 |
| NB_MULTIPATH_CAUSE_RELEASE_POWER_CONSUMPTION | 功耗原因释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC | 流量原因释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT | 场景冲突释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING | 应用使用不规范，比如长时间拉起多网不释放，系统释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT | 系统网络状态变化释放多网。 |
| NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER | 多网进入挂起状态，此时多网虽未释放，但是实际链路无法传输数据。 |
| NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE | 多网退出挂起状态。 |
| NB_MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE | 多网链路的链接属性信息更新，比如IP地址更新。 |
#### NetworkBoost_MultiPathErrorResult
```
enum NetworkBoost_MultiPathErrorResult
```
**描述**
多网建立结果的枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_MULTIPATH_ERROR_NONE | 多网建立成功。 |
| NB_MULTIPATH_ERROR_NETWORK_REFUSED | 多网请求被网络拒绝。 |
| NB_MULTIPATH_ERROR_TIMEOUT | 多网建立超时。 |
| NB_MULTIPATH_ERROR_LOCAL | 多网建立过程中，本地释放，例如在建立过程中数据开关关闭，或者其他事件发生，已经不满足拉起多网的条件。 |
#### NetworkBoost_MultiPathState
```
enum NetworkBoost_MultiPathState
```
**描述**
多网状态的枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_MULTIPATH_IDLE | 多网处于空闲状态。 |
| NB_MULTIPATH_CREATEING | 多网正在建立中。 |
| NB_MULTIPATH_CREATED | 多网已建立。 |
| NB_MULTIPATH_RELEASING | 多网正在释放中。 |
#### NetworkBoost_MultiPathAction
```
enum NetworkBoost_MultiPathAction
```
**描述**
多网推荐动作的枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_MULTIPATH_ACTION_REQUEST | 建议发起多网请求。 |
| NB_MULTIPATH_ACTION_RELEASE | 建议释放多网请求。 |
#### NetworkBoost_SceneEvent
```
enum NetworkBoost_SceneEvent
```
**描述**
业务事件枚举。
**起始版本：** 6.0.2(22)
| 枚举值 | 描述 |
| --- | --- |
| NB_SCENE_EVENT_ENTER | 进入业务场景。 |
| NB_SCENE_EVENT_UPDATE | 更新上一次的业务事件信息。 |
| NB_SCENE_EVENT_LEAVE | 离开业务场景。 |
#### 函数说明
#### HMS_NetworkBoost_RegisterHandoverChangeCallback()
```
int32_t HMS_NetworkBoost_RegisterHandoverChangeCallback (HMS_NetworkBoost_HandoverCallback * callback, uint32_t * callbackId )
```
**描述**
注册连接迁移信息回调。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 连接迁移回调函数。 |
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
#### HMS_NetworkBoost_RegisterNetSceneCallback()
```
int32_t HMS_NetworkBoost_RegisterNetSceneCallback (HMS_NetworkBoost_NetSceneChange callback, uint32_t * callbackId )
```
**描述**
注册网络场景变化回调。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 网络场景变化回调函数。 |
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
#### HMS_NetworkBoost_ReportQoe()
```
int32_t HMS_NetworkBoost_ReportQoe (NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType )
```
**描述**
应用传输体验反馈。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| serviceType | 应用的业务类型。 |
| qoeType | 应用的网络体验类型。 |
**返回：**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
**权限：**
ohos.permission.GET_NETWORK_INFO
#### HMS_NetworkBoost_SetHandoverMode()
```
int32_t HMS_NetworkBoost_SetHandoverMode (NetworkBoost_HandoverMode mode)
```
**描述**
变更连接迁移模式。
**起始版本：** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| mode | 连接迁移模式。 |
**返回：**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
**权限：**
ohos.permission.GET_NETWORK_INFO
#### HMS_NetworkBoost_UnregisterHandoverChangeCallback()
```
int32_t HMS_NetworkBoost_UnregisterHandoverChangeCallback (uint32_t callbackId)
```
**描述**
取消注册连接迁移信息回调。
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
#### HMS_NetworkBoost_UnregisterNetSceneCallback()
```
int32_t HMS_NetworkBoost_UnregisterNetSceneCallback (uint32_t callbackId)
```
**描述**
取消注册网络场景变化回调。
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
#### HMS_NetworkBoost_GetMultiPathQuotaStats()
```
int32_t HMS_NetworkBoost_GetMultiPathQuotaStats(NetworkBoost_MultiPathQuota* quota)
```
**描述**
获取当前应用多网使用的配额，包括已使用的配额信息和剩余配额信息。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| quota | 获取到的应用配额信息。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部错误。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
1013600041 - 传入参数有误，例如入参为空指针。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_RequestMultiPath()
```
int32_t HMS_NetworkBoost_RequestMultiPath(HMS_NetworkBoost_OnMultiPathRequestResult result)
```
**描述**
发起多网请求。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| result | 发起多网的结果。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
1013600041 - 传入参数有误，例如入参为空指针。
1013620000 - 多网功能没有使能。
1013620001 - 多网已经激活或者是在激活的过程中。
1013620002 - 应用多网请求已经达到上限。
1013620003 - 功耗限制不允许发起多网。
1013620004 - 限额耗尽。
1013620005 - 多网请求场景的冲突。
1013620006 - 多网发起太频繁。
1013620007 - 没有合适的多网链路可用。
1013620008 - 流量不足。
1013620009 - 不支持并发。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_ReleaseMultiPath()
```
int32_t HMS_NetworkBoost_ReleaseMultiPath()
```
**描述**
释放多网请求。
**起始版本：** 6.0.2(22)
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
1013620100 - 多网已经激活状态，但是多网不是当前发起release的应用拉起的。
1013620101 - 多网不在激活态。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_RegisterMultiPathStateChangeCallback()
```
int32_t HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(HMS_NetworkBoost_OnMultiPathStateChange callback, uint32_t* callbackId)
```
**描述**
注册多网状态变化事件。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 网状态变化回调函数。 |
| callbackId | 回调的ID，注册多网状态时由系统分配。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
1013600041 - 传入参数有误，例如入参为空指针。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback()
```
int32_t HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(uint32_t callbackId)
```
**描述**
去注册多网状态变化事件。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callbackId | 回调的ID，注册多网状态时由系统分配。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_RegisterMultiPathRecommendationCallback()
```
int32_t HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(HMS_NetworkBoost_OnMultiPathRecommendation callback, uint32_t* callbackId)
```
**描述**
注册系统多网建议变化事件。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 系统多网建议变化回调函数。 |
| callbackId | 回调的ID，注册多网状态时由系统分配。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
1013600041 - 传入参数有误，例如入参为空指针。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback()
```
int32_t HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(uint32_t callbackId)
```
**描述**
去注册系统多网建议变化事件。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callbackId | 回调的ID，注册多网状态时由系统分配。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
**权限：**
ohos.permission.LINKTURBO
#### HMS_NetworkBoost_SetSceneDesc()
```
int32_t HMS_NetworkBoost_SetSceneDesc(NetworkBoost_SceneDesc sceneDesc)
```
**描述**
设置业务场景。
**起始版本：** 6.0.2(22)
**参数:**
| 名称 | 描述 |
| --- | --- |
| sceneDesc | 要设置的业务场景信息。 |
**返回：**
0 - 成功。
201 - 权限不足。
1013600001 - 内部处理异常，例如内部处理异常，例如内部管理状态机异常，内部消息队列处理阻塞等。
1013600002 - 系统处理异常，例如IPC跨进程调用失败，网络管理服务启动失败。
**权限：**
ohos.permission.INTERNET