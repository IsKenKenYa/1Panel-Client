# 连接迁移通知 (C/C++)
---
# 连接迁移通知 (C/C++)
#### 场景介绍
在弱网环境下，系统发起多网迁移（WiFi<->蜂窝，主卡<->副卡等）的过程中，给应用提供连接迁移开始和完成通知，应用根据连接迁移通知的建议进行网络连接重建，快速恢复业务，给用户带来平滑、高速、低时延的上网体验。
#### 接口说明
具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) 。
| 接口名 | 描述 |
| --- | --- |
| int32_t HMS_NetworkBoost_RegisterHandoverChangeCallback(HMS_NetworkBoost_HandoverCallback* callback, uint32_t* callbackId) | 注册连接迁移回调。 |
| int32_t HMS_NetworkBoost_UnregisterHandoverChangeCallback(uint32_t callbackId) | 取消注册连接迁移回调。 |
#### 开发步骤
1.
导入Network Boost Kit模块。
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
```
2.
CMakeLists.txt中添加以下lib，具体请见 [C API开发准备](D:/code/APIDevice/output/md_output/harmonyos-guides/系统/网络/Network Boost Kit（网络加速服务）/开发准备/networkboost-preparations.md) 。
```cpp
libnetwork_boost.so
```
3.
通过注册回调的方式获取连接迁移信息。
```cpp
uint32_t callbackId = 0;
void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart)
{
    // 连接迁移开始回调，应用按照HandoverStart的建议调整数传策略
}
void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete)
{
    // 连接迁移完成回调，应用按照HandoverComplete的建议进行调速和重建恢复
}
int32_t RegisterNetworkHandoverCallback()
{
    HMS_NetworkBoost_HandoverCallback callback;
    callback.onNetworkHandoverStart = onNetworkHandoverStart;
    callback.onNetworkHandoverComplete = onNetworkHandoverComplete;
    // 注册回调，获取回调Id
    int32_t ret = HMS_NetworkBoost_RegisterHandoverChangeCallback(&callback, &callbackId);
    printf("注册连接迁移结果: %d, Id：%d\n", ret, callbackId);
    return ret;
}
```
4.
当应用业务流程结束，通过取消注册的方式取消监听连接迁移信息。
```cpp
int32_t UnregisterNetworkHandoverCallback() {
    // 使用注册时获取的回调Id取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterHandoverChangeCallback(callbackId);
    printf("取消注册连接迁移结果: %d\n", ret);
    return ret;
}
```