# 多网状态监听(C/C++)
---
# 多网状态监听(C/C++)
从6.0.2(22)开始，支持多网状态监听。
#### 场景介绍
应用通过监听多网络状态的变化，感知可用网络的变化，从而选择在多网络上传输数据的策略。
#### 接口说明
具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/C API/模块/network-boost-c-overview.md) 。
| 接口名 | 描述 |
| --- | --- |
| int32_t HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(HMS_NetworkBoost_OnMultiPathStateChangecallback, uint32_t *callbackId) | 注册多网状态变化事件。 |
| int32_t HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(uint32_t callbackId) | 去注册多网状态变化事件。 |
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
调用HMS_NetworkBoost_RegisterMultiPathStateChangeCallback接口，获取多网状态变化信息。
```cpp
uint32_t callbackId = 0;
void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* result)
{
    // 多网状态变化回调处理
}
int32_t RegisterMultiPathStateChange()
{
    // 注册回调，获取回调Id
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(onMultiPathStateChangeCallback, &callbackId);
    printf("注册多网状态监听回调结果: %d, Id：%d\n", ret, callbackId);
    return ret;
}
```
4.
当应用业务流程结束，通过取消注册的方式取消多网状态监听。
```cpp
int32_t UnregisterMultiPathStateChange() {
    // 使用注册时获取的回调Id取消注册
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(callbackId);
    printf("取消多网状态监听回调结果: %d\n", ret);
    return ret;
}
```