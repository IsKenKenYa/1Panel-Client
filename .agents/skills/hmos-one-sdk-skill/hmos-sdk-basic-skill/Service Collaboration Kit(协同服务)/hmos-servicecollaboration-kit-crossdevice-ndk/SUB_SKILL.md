---
name: hmos-servicecollaboration-kit-crossdevice-ndk
description: 跨设备互通能力调用相机扫描图库功能，支持TV/Phone/Tablet/PC设备协同，需同账号且开启WLAN蓝牙，适用于拍照扫描选择图片视频场景
---

# 跨设备互通NDK开发技能

## 功能描述

本技能实现跨设备互通NDK开发，通过调用远端设备的相机、扫描和图库功能实现跨设备协同。支持TV、Tablet、PC/2in1设备调用Phone的相机、扫描、图库功能，从API 6.1.0(23)开始支持TV、Phone、Tablet或PC/2in1设备调用支持相应能力的各类设备。提供拍照（TAKE_PHOTO）、扫描文档（SCAN_DOCUMENT）、从图库选择图片视频（IMAGE_PICKER）三种跨设备互通能力类型。

**核心能力**：
- 获取支持跨设备互通能力的设备列表
- 拉起远端设备的相机、扫描、图库功能
- 接收远端设备回传的图片和视频数据
- 主动取消跨设备互通会话

## 使用场景

### 触发词
- "跨设备互通"
- "跨设备调用相机"
- "跨设备扫描文档"
- "跨设备选择图片"
- "跨设备选择视频"
- "ServiceCollaboration NDK"
- "协同服务跨设备"

### 能做
- 获取支持拍照、扫描、图库选择能力的远端设备列表
- 拉起远端Phone或Tablet的相机进行拍照并回传图片
- 拉起远端设备的扫描功能进行文档扫描并回传图片
- 拉起远端设备的图库选择图片或视频并回传数据
- 监听跨设备互通的事件状态和数据回调
- 主动取消正在进行的跨设备互通会话

### 绝不做
- 不支持本端设备调用本端设备的功能（必须是跨设备）
- 不支持未登录同一华为账号的设备协同
- 不支持未开启WLAN和蓝牙的设备协同
- 不支持HarmonyOS版本低于5.0的设备
- 不处理超出设备能力范围的请求

### 补充
- 双端设备需登录同一华为账号且开启WLAN和蓝牙开关
- 接入同一局域网可提升唤醒相机的速度
- API 6.1.0(23)后支持更多设备类型互调用
- TV/PC/2in1可调用Tablet和Phone，Tablet可调用Phone
- 需使用C/C++开发，依赖libservice_collaboration_ndk.z.so库

## 调用规范和规则

### 输入约束
- 设备能力类型：必须为TAKE_PHOTO(1)、SCAN_DOCUMENT(2)、IMAGE_PICKER(3)之一或组合
- 设备网络ID长度：最大65字符（COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH）
- 设备名称长度：最大128字符（COLLABORATIONDEVICEINFO_DEVICENAME_MAXLENGTH）
- 回调函数：必须提供OnEvent和OnDataCallback两个回调函数
- CMake配置：必须正确链接libservice_collaboration_ndk.z.so库

### 执行约束
- 最大等待时间：无明确限制，建议设置超时取消机制（示例为3秒）
- 设备发现：调用GetCollaborationDeviceInfos前需确保远端设备已登录同账号并开启WLAN/蓝牙
- 会话管理：每个StartCollaboration调用返回唯一collaborationId用于取消操作
- 回调处理：需正确处理所有事件码和数据类型

### 内容约束
- 禁止使用：禁止在未获取设备列表的情况下直接调用StartCollaboration
- 禁止忽略：禁止忽略错误码和异常事件回调
- 禁止硬编码：禁止硬编码设备网络ID，必须从GetCollaborationDeviceInfos动态获取
- 安全处理：回调接收的图片和视频数据需安全存储和清理

### 降级约束
- 无设备可用：提示用户检查远端设备是否满足条件（同账号、WLAN/蓝牙开启、HarmonyOS 5+）
- 网络异常（NETWORK_ERROR）：提示用户检查网络连接，建议接入同一局域网
- 对端取消（PEER_CANCEL）：提示用户对端已取消操作，可重新尝试
- WLAN未开启：提示用户开启本端或对端WLAN开关
- 链路冲突：提示用户关闭热点或停止其他互联操作
- 数据读取失败：建议重新尝试或检查存储权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认本端设备为TV、Phone、Tablet或PC/2in1，且HarmonyOS版本≥5.0
2. 确认远端设备为Phone、Tablet或PC/2in1，且HarmonyOS版本≥5.0，具备相应能力
3. 确认双端设备已登录同一华为账号
4. 确认双端设备已开启WLAN和蓝牙开关
5. 建议双端设备接入同一局域网以提升性能

**引入头文件**：
```cpp
#include "service_collaboration/service_collaboration_api.h"
#include <thread>
#include <cstring>
```

**配置CMakeLists.txt**：
```cmake
find_library(
    service_collaboration-lib
    libservice_collaboration_ndk.z.so
)

target_link_libraries(entry PUBLIC
    ${service_collaboration-lib}
)
```

### 步骤2：获取设备列表

**示例代码**：
```cpp
ServiceCollaborationFilterType serviceFilterTypes[3] = {
    TAKE_PHOTO,      // 拍照能力
    SCAN_DOCUMENT,   // 扫描能力
    IMAGE_PICKER     // 图库选择能力
};

ServiceCollaboration_CollaborationDeviceInfoSets* deviceInfoSets = 
    HMS_ServiceCollaboration_GetCollaborationDeviceInfos(3, serviceFilterTypes);

if (deviceInfoSets == nullptr || deviceInfoSets->size == 0) {
    printf("未找到支持跨设备互通能力的设备\n");
    return;
}

printf("找到 %d 个支持跨设备互通的设备\n", deviceInfoSets->size);
for (uint32_t i = 0; i < deviceInfoSets->size; i++) {
    ServiceCollaboration_CollaborationDeviceInfo* deviceInfo = 
        &(deviceInfoSets->deviceInfoSets[i]);
    printf("设备 %d: 网络ID=%s, 设备类型=%d, 支持能力数=%d\n", 
        i, deviceInfo->deviceNetworkId, deviceInfo->deviceType, deviceInfo->filterTypesNum);
}
```

### 步骤3：创建回调函数

**事件回调函数**：
```cpp
static int32_t OnEventProc(ServiceCollaborationEventCode code, uint32_t extraCode) {
    switch (code) {
        case LAST_DATA_BACK:
            printf("已收到最后一个数据包\n");
            break;
        case PEER_CANCEL:
            printf("对端设备已取消操作\n");
            break;
        case NETWORK_ERROR:
            printf("网络异常，错误码：%d\n", extraCode);
            break;
        case DATA_BACK_START:
            printf("开始回传数据\n");
            break;
        case TIMEOUT_AUTO_CANCEL:
            printf("接收数据超时自动取消\n");
            break;
        case LINK_SHUTDOWN:
            printf("链路断开\n");
            break;
        default:
            printf("收到事件码：%d，额外码：%d\n", code, extraCode);
    }
    return 0;
}
```

**数据回调函数**：
```cpp
static int32_t OnDataCallbackProc(
    ServiceCollaborationEventCode code,
    ServiceCollaborationDataType dataType,
    uint32_t dataSize,
    char* data) {
    
    if (dataType == IMAGE) {
        printf("收到图片数据，大小：%d 字节\n", dataSize);
        // 处理图片数据：保存到文件或进行其他操作
        // 注意：需确保有足够的存储空间和权限
    }
    
    return 0;
}
```

### 步骤4：选择设备并启动协同

**构造选择信息**：
```cpp
ServiceCollaboration_SelectInfo taskInfo = { TAKE_PHOTO, { 0 } };

// 选择第一个支持拍照能力的设备
for (uint32_t i = 0; i < deviceInfoSets->size; i++) {
    ServiceCollaboration_CollaborationDeviceInfo* deviceInfo = 
        &(deviceInfoSets->deviceInfoSets[i]);
    
    // 检查设备是否支持拍照能力
    for (uint32_t j = 0; j < deviceInfo->filterTypesNum; j++) {
        if (deviceInfo->filterTypes[j] == TAKE_PHOTO) {
            taskInfo.serviceFilterType = TAKE_PHOTO;
            std::memcpy(taskInfo.deviceNetworkId, deviceInfo->deviceNetworkId, 
                COLLABORATIONDEVICEINFO_DEVICENETWORKID_MAXLENGTH - 1);
            break;
        }
    }
}
```

**启动跨设备互通**：
```cpp
ServiceCollaborationCallback callback = {
    .OnEvent = OnEventProc,
    .OnDataCallback = OnDataCallbackProc
};

uint32_t collaborationId = HMS_ServiceCollaboration_StartCollaboration(&taskInfo, &callback);

if (collaborationId == 0) {
    printf("启动跨设备互通失败\n");
    return;
}

printf("跨设备互通已启动，会话ID：%d\n", collaborationId);
```

### 步骤5：错误处理

```cpp
try {
    // 获取设备列表
    ServiceCollaboration_CollaborationDeviceInfoSets* deviceInfoSets = 
        HMS_ServiceCollaboration_GetCollaborationDeviceInfos(3, serviceFilterTypes);
    
    if (deviceInfoSets == nullptr) {
        throw std::runtime_error("获取设备列表失败");
    }
    
    if (deviceInfoSets->size == 0) {
        throw std::runtime_error("无可用设备");
    }
    
    // 启动协同
    uint32_t collaborationId = HMS_ServiceCollaboration_StartCollaboration(&taskInfo, &callback);
    
    if (collaborationId == 0) {
        throw std::runtime_error("启动协同失败");
    }
    
} catch (const std::exception& e) {
    printf("错误：%s\n", e.what());
    
    // 降级处理：提示用户检查条件并重试
    printf("请检查：\n");
    printf("1. 远端设备是否已登录同一华为账号\n");
    printf("2. 双端设备是否已开启WLAN和蓝牙\n");
    printf("3. 远端设备HarmonyOS版本是否≥5.0\n");
}
```

### 步骤6：取消协同（可选）

```cpp
// 等待3秒后主动取消
std::this_thread::sleep_for(std::chrono::seconds(3));

int32_t result = HMS_ServiceCollaboration_StopCollaboration(collaborationId);

if (result == 0) {
    printf("跨设备互通已成功取消\n");
} else {
    printf("取消失败，错误码：%d\n", result);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| LAST_DATA_BACK (1001202000) | 已收到最后一个数据包 | 正常结束，处理完整数据 |
| PEER_CANCEL (1001202001) | 对端设备取消操作 | 提示用户对端已取消，可重新尝试 |
| NETWORK_ERROR (1001202002) | 网络异常 | 检查网络连接，建议接入同一局域网 |
| PEER_WIFI_NOT_OPEN (1001202004) | 对端WLAN未开启 | 提示用户开启对端WLAN开关 |
| LOCAL_WIFI_NOT_OPEN (1001202005) | 本端WLAN未开启 | 提示用户开启本端WLAN开关 |
| DATA_BACK_START (1001202006) | 开始回传数据 | 准备接收数据，确保存储空间 |
| MIDDLE_DATA_BACK (1001202007) | 收到中间数据包 | 持续接收数据，等待LAST_DATA_BACK |
| TIMEOUT_AUTO_CANCEL (1001202008) | 接收数据超时取消 | 增加等待时间或检查网络稳定性 |
| DATA_READ_FAILED (1001202009) | 数据读取失败 | 检查存储权限和空间，重新尝试 |
| LINK_SHUTDOWN (1001202011) | 链路断开 | 检查设备连接状态，重新尝试 |
| REMOTE_HOTSPOT_CONFLICT (1001202013) | 对端开启热点导致链路冲突 | 提示用户关闭对端热点 |
| REMOTE_DISTRIBUTED_SERVICES_CONFLICT (1001202014) | 对端与其他设备互联导致冲突 | 提示用户停止其他互联操作 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(service_collaboration_example)

find_library(
    service_collaboration-lib
    libservice_collaboration_ndk.z.so
)

add_executable(entry main.cpp)

target_link_libraries(entry PUBLIC
    ${service_collaboration-lib}
)
```

### 环境要求
- HarmonyOS SDK：版本≥5.0.0(12)
- NDK：支持C/C++开发
- 设备：TV、Phone、Tablet或PC/2in1，HarmonyOS≥5.0

### 常见编译问题

**问题1：找不到libservice_collaboration_ndk.z.so**
```
CMake Error: Could not find libservice_collaboration_ndk.z.so
```
**解决方法**：
- 确认HarmonyOS SDK已正确安装
- 检查CMakeLists.txt中的find_library配置
- 确认SDK版本≥5.0.0(12)

**问题2：头文件路径错误**
```
fatal error: 'service_collaboration/service_collaboration_api.h' file not found
```
**解决方法**：
- 确认include路径正确：`#include "service_collaboration/service_collaboration_api.h"`
- 检查HarmonyOS NDK include目录配置

**问题3：结构体未定义**
```
error: 'ServiceCollaboration_SelectInfo' was not declared in this scope
```
**解决方法**：
- 确认已正确引入头文件
- 检查结构体名称拼写（注意大小写）

## 常见问题与解决方法

### Q1：GetCollaborationDeviceInfos返回空列表
**原因**：
- 远端设备未登录同一华为账号
- 远端设备未开启WLAN或蓝牙
- 远端设备HarmonyOS版本低于5.0
- 远端设备不具备所需能力（如相机）

**解决方法**：
- 确认双端设备登录同一华为账号
- 确认双端设备已开启WLAN和蓝牙开关
- 确认远端设备HarmonyOS版本≥5.0
- 确认远端设备支持所需能力类型

### Q2：StartCollaboration返回collaborationId为0
**原因**：
- 设备网络ID无效或未正确复制
- 回调函数未正确设置
- 设备不支持指定的能力类型

**解决方法**：
- 确保从GetCollaborationDeviceInfos动态获取设备网络ID
- 确保回调函数正确设置：OnEvent和OnDataCallback
- 确保设备支持指定的serviceFilterType

### Q3：数据回调未触发或数据不完整
**原因**：
- 网络不稳定导致数据传输中断
- 对端设备取消操作
- 接收超时

**解决方法**：
- 检查网络连接状态
- 接入同一局域网提升稳定性
- 正确处理LAST_DATA_BACK事件码确认数据完整
- 增加超时等待时间或实现重试机制

### Q4：如何判断数据接收完整
**原因**：数据分多个包传输，需等待最后一个包

**解决方法**：
- 监听DATA_BACK_START事件开始接收
- 监听MIDDLE_DATA_BACK事件持续接收中间数据
- 监听LAST_DATA_BACK事件确认接收完成
- 在LAST_DATA_BACK后处理完整数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "collaborationId": "会话唯一标识",
  "deviceInfo": {
    "networkId": "设备网络ID",
    "deviceType": "设备类型",
    "filterType": "能力类型（TAKE_PHOTO/SCAN_DOCUMENT/IMAGE_PICKER）"
  },
  "dataReceived": {
    "dataType": "IMAGE",
    "dataSize": "接收数据大小（字节）",
    "eventCode": "最终事件码"
  },
  "apiUsed": [
    "HMS_ServiceCollaboration_GetCollaborationDeviceInfos",
    "HMS_ServiceCollaboration_StartCollaboration",
    "HMS_ServiceCollaboration_StopCollaboration"
  ]
}
```

## 参考文档

- [跨设备互通NDK开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/servicecollaboration-servicendk-guide)
- [ServiceCollaboration C API模块参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/servicecollaboration-capi-module)

## 完整示例代码

- [C++完整示例](assets/example_crossdevice_collaboration.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)

## 测试用例

### 正向测试用例
- [获取设备列表成功](tests/test_positive.cpp)：验证GetCollaborationDeviceInfos正常返回设备列表
- [启动拍照协同成功](tests/test_positive.cpp)：验证StartCollaboration正常启动拍照并回传图片
- [启动扫描协同成功](tests/test_positive.cpp)：验证StartCollaboration正常启动扫描并回传图片
- [启动图库选择成功](tests/test_positive.cpp)：验证StartCollaboration正常启动图库选择并回传数据

### 边界测试用例
- [最大设备数量](tests/test_boundary.cpp)：测试获取大量设备时性能
- [最大数据包大小](tests/test_boundary.cpp)：测试接收大图片或视频数据
- [超时取消](tests/test_boundary.cpp)：测试长时间等待后的自动取消机制

### 异常测试用例
- [无可用设备](tests/test_exception.cpp)：测试GetCollaborationDeviceInfos返回空列表的处理
- [网络异常](tests/test_exception.cpp)：测试NETWORK_ERROR错误码处理
- [对端取消](tests/test_exception.cpp)：测试PEER_CANCEL错误码处理
- [WLAN未开启](tests/test_exception.cpp)：测试WLAN_NOT_OPEN错误码处理
- [链路冲突](tests/test_exception.cpp)：测试REMOTE_HOTSPOT_CONFLICT和REMOTE_DISTRIBUTED_SERVICES_CONFLICT处理