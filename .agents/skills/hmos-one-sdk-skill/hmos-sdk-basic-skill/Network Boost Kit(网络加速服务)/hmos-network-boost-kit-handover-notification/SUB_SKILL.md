---
name: hmos-network-boost-kit-handover-notification
description: 注册和监听网络连接迁移通知(WiFi/蜂窝切换、主卡/副卡切换)，提供迁移开始和完成事件回调，支持最大1000个并发注册，适用于实时语音、视频通话、游戏等弱网多网切换场景，需要ohos.permission.GET_NETWORK_INFO权限，API版本5.1.0(18)及以上
---

# 连接迁移通知技能(C/C++)

## 功能描述

本技能提供HarmonyOS Network Boost Kit的连接迁移通知能力，通过注册回调函数监听网络连接迁移事件，在弱网环境下系统发起多网迁移(WiFi<->蜂窝，主卡<->副卡等)时，应用可接收迁移开始和完成通知，并根据通知中的建议进行网络连接重建和数传策略调整，快速恢复业务，给用户带来平滑、高速、低时延的上网体验。

核心能力包括:
- **注册监听**: 通过`HMS_NetworkBoost_RegisterHandoverChangeCallback`注册连接迁移回调，获取系统分配的callbackId
- **事件回调**: 接收连接迁移开始(`onNetworkHandoverStart`)和完成(`onNetworkHandoverComplete`)两个回调事件
- **策略建议**: 回调中包含发包速率建议(SUSPEND_DATA/DECREASE_DATA/INCREASE_DATA/KEEP_DATA)、重建建议(REEST_DEFAULT/QUERY_DNS/CHANGE_REMOTE_IP/CHANGE_IP_VERSION/NO_EST)等
- **取消监听**: 通过`HMS_NetworkBoost_UnregisterHandoverChangeCallback`取消注册，释放系统资源

典型应用场景:
- 实时语音/视频通话应用，在WiFi切换到蜂窝时快速重建连接
- 实时游戏应用，在弱网切换时暂停发包避免丢包
- 直播应用，在主卡切换到副卡时调整码率
- 导航应用，在网络切换时保持定位数据连续性

技术特点:
- 语言: C/C++ (Native层)
- 权限: ohos.permission.GET_NETWORK_INFO (必需), ohos.permission.INTERNET (可选)
- API版本: 5.1.0(18)及以上
- 同步调用: 注册和取消注册为同步函数
- 异步回调: 迁移事件通过回调异步通知
- 最大注册数: 1000个并发应用

## 使用场景

### 触发词
- "连接迁移" - 监听网络切换事件
- "多网切换" - WiFi/蜂窝切换通知
- "网络迁移通知" - 注册网络迁移回调
- "弱网切换" - 弱网环境下的网络切换
- "Network Boost连接迁移" - Network Boost Kit的迁移能力
- "主卡副卡切换" - 蜂窝网络主副卡切换
- "WiFi切换蜂窝" - WiFi和蜂窝网络切换
- "C/C++网络迁移" - Native层的网络迁移监听
- "网络重建通知" - 网络连接重建事件

### 能做
- 注册连接迁移回调，监听系统发起的WiFi/蜂窝切换、主卡/副卡切换等迁移事件
- 在连接迁移开始时，根据系统建议调整老链路的发包策略(暂停/降速/加速/保持)
- 在连接迁移完成时，根据重建建议(REEST_DEFAULT/QUERY_DNS/CHANGE_REMOTE_IP/CHANGE_IP_VERSION/NO_EST)快速重建新链路
- 在连接迁移完成时，根据新链路发包建议调整数传策略，快速恢复业务
- 获取迁移结果(NB_ERROR_NONE/NB_ERROR_HANDOVER_TIMEOUT/NB_ERROR_NEW_PATH_ACTIVATION_FAILED/NB_ERROR_ABORT)进行错误处理
- 获取新老链路的NetHandle信息，用于后续网络请求绑定
- 获取老链路剩余生存时长，合理安排数据传输
- 取消注册连接迁移回调，释放系统资源

### 绝不做
- 不主动发起网络迁移(迁移由系统发起，应用仅监听)
- 不在迁移开始回调中直接重建连接(应在迁移完成回调中重建)
- 不忽略迁移结果中的错误码(NB_ERROR_HANDOVER_TIMEOUT/NB_ERROR_NEW_PATH_ACTIVATION_FAILED/NB_ERROR_ABORT需要处理)
- 不在未注册回调的情况下处理迁移事件(必须先注册回调才能接收事件)
- 不超过最大注册数量限制(最多1000个并发注册)
- 不在回调函数中执行耗时操作(回调应快速返回，避免阻塞系统)
- 不在缺少ohos.permission.GET_NETWORK_INFO权限时调用API(会导致201错误)
- 不在API版本低于5.1.0(18)的设备上使用(会导致801错误)

### 补充
- **迁移模式**: 默认为委托模式(NB_MODE_DELEGATION)，由系统发起迁移；可设置为自主模式(NB_MODE_DISCRETION)，由应用控制迁移(通过`HMS_NetworkBoost_SetHandoverMode`)
- **多路径迁移**: 当迁移到多个网络时，会收到多个HandoverComplete回调，通过`handoverContinue`字段判断是否还有后续回调
- **链路类型变更**: 通过`pathTypeChanged`字段判断新老链路类型是否变更(WiFi<->蜂窝)，变更时需要重新DNS查询
- **老链路生存期**: `oldPathLifetime`字段提供老链路剩余生存时长，建议在过期前完成数据传输或重建
- **发包建议**: 系统提供的发包建议包括DO_CACHING(缓存)、SUSPEND_DATA(暂停)、DECREASE_DATA(降速)、INCREASE_DATA(加速)、KEEP_DATA(保持)
- **重建建议**: 系统提供的重建建议包括NB_REEST_DEFAULT(使用原远端IP)、NB_REEST_QUERY_DNS(DNS查询)、NB_REEST_CHANGE_REMOTE_IP(更换远端IP)、NB_REEST_CHANGE_IP_VERSION(更换IP版本IPv4/IPv6)、NB_NO_EST(无需重建，立即重试)
- **线程安全**: 回调函数可能在系统线程中调用，应用需确保回调函数的线程安全
- **权限配置**: 需在module.json5中配置ohos.permission.GET_NETWORK_INFO和ohos.permission.INTERNET权限
- **依赖配置**: CMakeLists.txt需链接libnetwork_boost.so动态库

## 调用规范和规则

### 输入约束
- **权限要求**: 必须配置ohos.permission.GET_NETWORK_INFO权限，否则返回201错误
- **API版本**: 最低API版本5.1.0(18)，否则返回801错误
- **回调函数**: HMS_NetworkBoost_HandoverCallback结构体中的两个回调函数指针不能为空(NULL)
- **callbackId指针**: HMS_NetworkBoost_RegisterHandoverChangeCallback的第二个参数不能为空指针
- **注册上限**: 最多1000个并发应用注册，超过返回62100003错误
- **回调实现**: 回调函数实现必须快速返回，不能执行耗时操作(建议<100ms)

### 执行约束
- **注册耗时**: HMS_NetworkBoost_RegisterHandoverChangeCallback为同步调用，最大耗时<50ms
- **取消注册耗时**: HMS_NetworkBoost_UnregisterHandoverChangeCallback为同步调用，最大耗时<50ms
- **回调响应时间**: 回调函数应在<100ms内返回，避免阻塞系统线程
- **注册次数限制**: 单个应用最多注册1000次(不同callbackId)，取消注册后可重新注册
- **迁移超时时间**: 系统提供的迁移超时时间expires字段，单位秒，应用应在超时前准备好重建
- **老链路生存期**: oldPathLifetime字段提供老链路剩余时间，应用应在此时间内完成传输或重建

### 内容约束
- **禁止空回调**: HMS_NetworkBoost_HandoverCallback结构体中onNetworkHandoverStart和onNetworkHandoverComplete不能为空
- **禁止阻塞回调**: 回调函数中不能执行sleep、wait、耗时计算等阻塞操作
- **禁止递归注册**: 不能在回调函数中再次调用注册函数
- **禁止无效callbackId**: 取消注册时必须使用注册时系统分配的有效callbackId
- **禁止忽略错误码**: 必须处理注册返回的错误码(0/201/401/801/62100001/62100002/62100003)
- **禁止忽略迁移结果**: 必须处理HandoverComplete中的result字段(NB_ERROR_NONE/NB_ERROR_HANDOVER_TIMEOUT等)
- **禁止忽略重建建议**: 必须根据reEstAction字段进行相应的重建操作
- **禁止高危操作**: 回调函数中禁止使用高危函数(exec、system等)

### 降级约束
- **注册失败**: 返回201权限不足时，提示用户检查权限配置；返回62100003注册上限时，等待其他应用取消注册后重试
- **迁移失败**: HandoverComplete返回NB_ERROR_HANDOVER_TIMEOUT时，立即重建连接；返回NB_ERROR_NEW_PATH_ACTIVATION_FAILED时，等待系统重新迁移或主动切换网络；返回NB_ERROR_ABORT时，恢复原有传输策略
- **缺少权限**: 未配置ohos.permission.GET_NETWORK_INFO时，提示用户配置权限或使用其他网络监听方案
- **API版本过低**: API版本低于5.1.0(18)时，提示用户升级系统或使用其他网络监听方案
- **回调超时**: 回调函数执行超过100ms时，系统可能中断回调，应用应将耗时操作放到独立线程
- **网络不可用**: 迁移过程中网络完全不可用时，暂停数据传输，等待网络恢复通知
- **多网迁移**: handoverContinue为true时，继续等待后续HandoverComplete回调，不提前结束迁移流程

## 调用流程和步骤

### 步骤1: 权限配置和依赖准备

**前置校验**:
1. 检查API版本>=5.1.0(18)，可通过系统API获取版本信息
2. 检查是否已配置ohos.permission.GET_NETWORK_INFO权限
3. 检查是否已配置ohos.permission.INTERNET权限(可选，建议配置)
4. 检查CMakeLists.txt是否已链接libnetwork_boost.so

**权限配置(module.json5)**:
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**依赖配置(CMakeLists.txt)**:
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤2: 导入头文件和定义回调函数

**导入头文件**:
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
```

**定义迁移开始回调**:
```cpp
void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart)
{
    if (handoverStart == nullptr) {
        printf("错误: handoverStart为空指针\n");
        return;
    }
    
    uint32_t expires = handoverStart->expires;
    NetworkBoost_DataSpeedAction dataSpeedAction = handoverStart->dataSpeedAction;
    
    printf("连接迁移开始: 超时时间=%u秒\n", expires);
    
    switch (dataSpeedAction.simpleAction) {
        case NB_SIMPLEACTION_SUSPEND_DATA:
            printf("建议: 暂停发包\n");
            break;
        case NB_SIMPLEACTION_DECREASE_DATA:
            printf("建议: 降低发包速率\n");
            break;
        case NB_SIMPLEACTION_INCREASE_DATA:
            printf("建议: 增加发包速率\n");
            break;
        case NB_SIMPLEACTION_KEEP_DATA:
            printf("建议: 保持当前发包速率\n");
            break;
        default:
            printf("建议: 未知发包策略\n");
            break;
    }
}
```

**定义迁移完成回调**:
```cpp
void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete)
{
    if (handoverComplete == nullptr) {
        printf("错误: handoverComplete为空指针\n");
        return;
    }
    
    NetworkBoost_ErrorResult result = handoverComplete->result;
    bool handoverContinue = handoverComplete->handoverContinue;
    uint32_t oldPathLifetime = handoverComplete->oldPathLifetime;
    bool pathTypeChanged = handoverComplete->pathTypeChanged;
    NetworkBoost_ReEstAction reEstAction = handoverComplete->reEstAction;
    
    printf("连接迁移完成: result=%d, handoverContinue=%d\n", result, handoverContinue);
    
    if (result != NB_ERROR_NONE) {
        printf("迁移失败: ");
        switch (result) {
            case NB_ERROR_HANDOVER_TIMEOUT:
                printf("迁移超时\n");
                break;
            case NB_ERROR_NEW_PATH_ACTIVATION_FAILED:
                printf("新链路激活失败\n");
                break;
            case NB_ERROR_ABORT:
                printf("迁移被取消\n");
                break;
            default:
                printf("未知错误\n");
                break;
        }
        return;
    }
    
    printf("老链路剩余生存时长: %u秒\n", oldPathLifetime);
    printf("新老链路类型是否变更: %s\n", pathTypeChanged ? "是" : "否");
    
    switch (reEstAction) {
        case NB_REEST_DEFAULT:
            printf("重建建议: 使用原远端IP重建\n");
            break;
        case NB_REEST_QUERY_DNS:
            printf("重建建议: DNS查询新IP\n");
            break;
        case NB_REEST_CHANGE_REMOTE_IP:
            printf("重建建议: 使用不同的远端IP\n");
            break;
        case NB_REEST_CHANGE_IP_VERSION:
            printf("重建建议: 更换IP版本(IPv4/IPv6)\n");
            break;
        case NB_NO_EST:
            printf("重建建议: 无需重建，立即重试\n");
            break;
        default:
            printf("重建建议: 未知\n");
            break;
    }
    
    NetworkBoost_DataSpeedAction newDataSpeedAction = handoverComplete->newDataSpeedAction;
    switch (newDataSpeedAction.simpleAction) {
        case NB_SIMPLEACTION_SUSPEND_DATA:
            printf("新链路发包建议: 暂停发包\n");
            break;
        case NB_SIMPLEACTION_DECREASE_DATA:
            printf("新链路发包建议: 降低发包速率\n");
            break;
        case NB_SIMPLEACTION_INCREASE_DATA:
            printf("新链路发包建议: 增加发包速率\n");
            break;
        case NB_SIMPLEACTION_KEEP_DATA:
            printf("新链路发包建议: 保持发包速率\n");
            break;
        default:
            printf("新链路发包建议: 未知\n");
            break;
    }
}
```

### 步骤3: 注册连接迁移回调

**注册回调示例**:
```cpp
static uint32_t g_callbackId = 0;

int32_t RegisterNetworkHandoverCallback()
{
    HMS_NetworkBoost_HandoverCallback callback;
    callback.onNetworkHandoverStart = onNetworkHandoverStart;
    callback.onNetworkHandoverComplete = onNetworkHandoverComplete;
    
    int32_t ret = HMS_NetworkBoost_RegisterHandoverChangeCallback(&callback, &g_callbackId);
    
    switch (ret) {
        case 0:
            printf("注册成功: callbackId=%u\n", g_callbackId);
            break;
        case 201:
            printf("注册失败: 权限不足，请检查ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("注册失败: 参数错误，请检查回调函数指针是否为空\n");
            break;
        case 801:
            printf("注册失败: 系统能力不支持，API版本需>=5.1.0(18)\n");
            break;
        case 62100001:
            printf("注册失败: 内部错误\n");
            break;
        case 62100002:
            printf("注册失败: 系统服务操作失败\n");
            break;
        case 62100003:
            printf("注册失败: 注册请求达到上限(最多1000个)\n");
            break;
        default:
            printf("注册失败: 未知错误码%d\n", ret);
            break;
    }
    
    return ret;
}
```

### 步骤4: 处理迁移事件(在回调中)

**迁移开始处理逻辑**:
```cpp
void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart)
{
    if (handoverStart == nullptr) {
        return;
    }
    
    NetworkBoost_DataSpeedAction dataSpeedAction = handoverStart->dataSpeedAction;
    
    if (dataSpeedAction.simpleAction == NB_SIMPLEACTION_SUSPEND_DATA) {
        PauseDataTransmission();
    } else if (dataSpeedAction.simpleAction == NB_SIMPLEACTION_DECREASE_DATA) {
        DecreaseDataRate();
    }
}
```

**迁移完成处理逻辑**:
```cpp
void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete)
{
    if (handoverComplete == nullptr) {
        return;
    }
    
    if (handoverComplete->result != NB_ERROR_NONE) {
        HandleHandoverError(handoverComplete->result);
        return;
    }
    
    NetworkBoost_ReEstAction reEstAction = handoverComplete->reEstAction;
    
    switch (reEstAction) {
        case NB_REEST_DEFAULT:
            ReestablishConnectionWithSameIP();
            break;
        case NB_REEST_QUERY_DNS:
            QueryDNSAndReestablish();
            break;
        case NB_REEST_CHANGE_REMOTE_IP:
            ReestablishConnectionWithNewIP();
            break;
        case NB_REEST_CHANGE_IP_VERSION:
            ReestablishConnectionWithNewIPVersion();
            break;
        case NB_NO_EST:
            RetryImmediatelyOnOldPath();
            break;
    }
    
    if (!handoverComplete->handoverContinue) {
        printf("迁移流程完全结束\n");
    }
}
```

### 步骤5: 取消注册连接迁移回调

**取消注册示例**:
```cpp
int32_t UnregisterNetworkHandoverCallback()
{
    if (g_callbackId == 0) {
        printf("错误: callbackId无效，未注册或已取消\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterHandoverChangeCallback(g_callbackId);
    
    switch (ret) {
        case 0:
            printf("取消注册成功\n");
            g_callbackId = 0;
            break;
        case 201:
            printf("取消注册失败: 权限不足\n");
            break;
        case 401:
            printf("取消注册失败: callbackId参数错误\n");
            break;
        case 801:
            printf("取消注册失败: 系统能力不支持\n");
            break;
        case 62100001:
            printf("取消注册失败: 内部错误\n");
            break;
        case 62100002:
            printf("取消注册失败: 系统服务操作失败\n");
            break;
        default:
            printf("取消注册失败: 未知错误码%d\n", ret);
            break;
    }
    
    return ret;
}
```

## 错误码说明

### 注册API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 注册成功 | 无需处理，保存callbackId用于后续取消注册 |
| 201 | 权限不足 | 在module.json5中配置ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查callback指针和callbackId指针是否为空，回调函数是否为空 |
| 801 | 系统能力不支持 | 检查API版本>=5.1.0(18)，提示用户升级系统 |
| 62100001 | 内部错误 | 系统内部异常，可尝试重新注册或重启应用 |
| 62100002 | 系统服务操作失败 | Network Boost服务异常，可尝试重启应用或等待服务恢复 |
| 62100003 | 注册请求达到上限 | 已有1000个应用注册，等待其他应用取消注册后重试 |

### 取消注册API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 取消注册成功 | 无需处理，清空本地callbackId |
| 201 | 权限不足 | 检查ohos.permission.GET_NETWORK_INFO权限配置 |
| 401 | 参数错误 | 检查callbackId是否有效(注册时分配的值) |
| 801 | 系统能力不支持 | API版本不支持，检查API版本>=5.1.0(18) |
| 62100001 | 内部错误 | 系统内部异常，可忽略(已取消) |
| 62100002 | 系统服务操作失败 | Network Boost服务异常，可忽略(已取消) |

### 迁移结果错误码(HandoverComplete)

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| NB_ERROR_NONE | 连接迁移成功 | 根据reEstAction重建连接，根据newDataSpeedAction调整发包策略 |
| NB_ERROR_HANDOVER_TIMEOUT | 连接迁移超时 | 立即重建连接，尝试使用备用网络或暂停业务 |
| NB_ERROR_NEW_PATH_ACTIVATION_FAILED | 新链路激活失败 | 等待系统重新迁移或主动切换网络，暂停数据传输 |
| NB_ERROR_ABORT | 连接迁移被取消 | 恢复原有传输策略，检查是否手动取消迁移 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**:
```cmake
cmake_minimum_required(VERSION 3.10)
project(NetworkBoostHandover)

set(CMAKE_CXX_STANDARD 14)

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
    libhilog.so
)
```

**环境变量**:
- HMOS_SDK_NATIVE: HarmonyOS Native SDK路径，需在编译环境中配置

### 环境要求
- **API版本**: 最低5.1.0(18)，推荐使用最新API版本
- **编译工具**: CMake 3.10及以上，Clang编译器
- **SDK**: HarmonyOS Native SDK，包含Network Boost Kit头文件和动态库
- **运行环境**: HarmonyOS设备，API版本>=5.1.0(18)

### 常见编译问题

**问题1: 头文件找不到**
```
fatal error: 'NetworkBoostKit/network_boost_handover.h' file not found
```
**解决方法**: 
- 检查HMOS_SDK_NATIVE环境变量是否配置
- 检查${HMOS_SDK_NATIVE}/sysroot/usr/include路径是否存在
- 检查NetworkBoostKit目录是否在include路径中

**问题2: 动态库链接失败**
```
ld: cannot find -lnetwork_boost
```
**解决方法**:
- 检查${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos路径是否存在
- 检查libnetwork_boost.so文件是否存在
- 确认target_link_directories已正确配置

**问题3: 权限未配置导致运行时错误**
```
运行时返回201错误码
```
**解决方法**:
- 在entry/src/main/module.json5中配置ohos.permission.GET_NETWORK_INFO权限
- 检查权限配置格式是否正确(JSON5格式)
- 重新编译和签名应用

**问题4: API版本不支持**
```
运行时返回801错误码
```
**解决方法**:
- 检查设备API版本，通过系统API获取版本信息
- 提示用户升级系统到API 5.1.0(18)及以上
- 提供降级方案，使用其他网络监听机制

## 常见问题与解决方法

### Q1: 注册回调时返回201权限不足错误
**原因**: 未配置ohos.permission.GET_NETWORK_INFO权限
**解决方法**:
- 在entry/src/main/module.json5的requestPermissions中添加ohos.permission.GET_NETWORK_INFO
- 重新编译和签名应用
- 检查权限配置是否生效(可通过系统API查询已授权权限)

### Q2: 回调函数未被调用
**原因**: 回调函数未正确注册或系统未发起迁移
**解决方法**:
- 检查注册返回值是否为0(成功)
- 检查回调函数指针是否为空(NULL)
- 确认设备支持多网切换(WiFi/蜂窝双网)
- 手动切换网络(WiFi开关或飞行模式)触发迁移事件
- 检查回调函数是否阻塞(应在<100ms内返回)

### Q3: HandoverComplete回调中handoverContinue为true，后续未收到回调
**原因**: 多路径迁移过程中，后续迁移失败或系统异常
**解决方法**:
- 设置超时计时器，等待后续回调(建议超时时间=expires字段)
- 如果超时未收到后续回调，主动重建连接
- 检查系统日志是否有Network Boost服务异常
- 监听网络状态变化事件作为备用方案

### Q4: 迁移完成回调中result为NB_ERROR_HANDOVER_TIMEOUT
**原因**: 系统迁移超时，新链路未在expires时间内激活
**解决方法**:
- 立即重建连接，使用reEstAction建议的重建方式
- 如果重建失败，暂停数据传输
- 监听网络恢复事件，等待网络恢复后重试
- 提示用户切换网络或检查网络环境

### Q5: 回调函数执行时间过长导致系统中断
**原因**: 回调函数中执行了耗时操作(如sleep、IO操作、复杂计算)
**解决方法**:
- 回调函数仅做轻量级操作(如标志位设置、日志记录)
- 将耗时操作(如DNS查询、连接重建)放到独立线程执行
- 使用队列机制，回调中仅推送事件，工作线程处理
- 回调函数执行时间建议<100ms

### Q6: 取消注册后仍收到回调
**原因**: 取消注册失败或系统缓存了未处理的迁移事件
**解决方法**:
- 检查取消注册返回值是否为0(成功)
- 取消注册成功后，清空本地callbackId
- 如果仍收到回调，忽略处理(系统可能发送了缓存事件)
- 多次收到无效回调时，重新注册新的callbackId

### Q7: 多个应用注册时callbackId冲突
**原因**: callbackId为全局变量，多个应用实例共享
**解决方法**:
- callbackId应为静态变量或全局变量，每个应用实例独立
- 不同应用实例使用不同的callbackId
- 取消注册时使用对应的callbackId
- 建议使用应用实例ID管理多个callbackId

### Q8: API版本低于5.1.0(18)无法使用
**原因**: 设备API版本不支持Network Boost Kit
**解决方法**:
- 通过系统API查询API版本，提示用户升级系统
- 提供降级方案，使用ConnectivityManager监听网络变化
- 使用NetHandle绑定网络，手动切换网络
- 在不支持的环境下，禁用连接迁移功能，提示用户

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "callbackId": 12345,
  "registered": true,
  "apiUsed": [
    "HMS_NetworkBoost_RegisterHandoverChangeCallback",
    "HMS_NetworkBoost_UnregisterHandoverChangeCallback"
  ],
  "eventsReceived": {
    "handoverStart": 2,
    "handoverComplete": 2
  },
  "migrationResults": [
    {
      "result": "NB_ERROR_NONE",
      "reEstAction": "NB_REEST_QUERY_DNS",
      "pathTypeChanged": true
    }
  ]
}
```

输出字段说明:
- **status**: 执行状态(success/failed)
- **callbackId**: 系统分配的回调ID
- **registered**: 是否已注册(true/false)
- **apiUsed**: 使用的API列表
- **eventsReceived**: 接收的迁移事件统计
- **migrationResults**: 迁移结果详情列表

## 参考文档

- [连接迁移通知开发指南(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-nethandovercallback-c)
- [Network Boost Kit C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [连接迁移回调结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_callback)
- [连接迁移开始结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_start)
- [连接迁移完成结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-handover_complete)
- [Network Boost Kit开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++完整示例](assets/example_handover.cpp): 包含注册、回调处理、取消注册的完整示例代码
- [CMakeLists.txt示例](assets/CMakeLists.txt): 包含依赖配置的编译脚本
- [module.json5示例](assets/module.json5): 包含权限配置的模块配置文件

## 测试用例

### 正向测试用例
- [注册回调成功测试](tests/test_positive.cpp): 测试正常注册回调流程
- [迁移开始回调测试](tests/test_positive.cpp): 测试迁移开始回调触发
- [迁移完成回调测试](tests/test_positive.cpp): 测试迁移完成回调触发
- [取消注册测试](tests/test_positive.cpp): 测试正常取消注册流程

### 边界测试用例
- [最大注册次数测试](tests/test_boundary.cpp): 测试最大1000个注册限制
- [回调超时时间测试](tests/test_boundary.cpp): 测试expires超时处理
- [多路径迁移测试](tests/test_boundary.cpp): 测试handoverContinue为true的多路径迁移
- [老链路生存期测试](tests/test_boundary.cpp): 测试oldPathLifetime边界值

### 异常测试用例
- [权限不足测试](tests/test_exception.cpp): 测试缺少GET_NETWORK_INFO权限
- [参数错误测试](tests/test_exception.cpp): 测试空回调指针和空callbackId指针
- [API版本不支持测试](tests/test_exception.cpp): 测试API版本低于5.1.0(18)
- [迁移失败测试](tests/test_exception.cpp): 测试NB_ERROR_HANDOVER_TIMEOUT等错误处理
- [无效callbackId取消注册测试](tests/test_exception.cpp): 测试使用无效callbackId取消注册