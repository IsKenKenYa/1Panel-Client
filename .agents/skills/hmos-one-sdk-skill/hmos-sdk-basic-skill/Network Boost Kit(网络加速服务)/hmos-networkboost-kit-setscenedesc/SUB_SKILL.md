---
name: hmos-networkboost-kit-setscenedesc
description: 设置多网并发业务场景,帮助系统进行多网并发管控和业务时长分析,支持登录、秒杀等23种业务场景类型,需要GET_NETWORK_INFO权限,适用于多网并发请求前的场景设置
---

# 业务场景设置技能

## 功能描述

本技能用于在应用发起多网并发请求之前,通过设置业务场景描述信息,帮助系统进行多网并发管控和业务时长分析。应用通过调用`HMS_NetworkBoost_SetSceneDesc`接口,向系统传递业务场景类型、场景事件、预计开始时间和持续时长等信息,系统据此优化多网并发策略,提升用户体验。

**核心功能**:
- 设置23种业务场景类型(登录、秒杀、直播、游戏等)
- 配置场景事件(进入、更新、离开)
- 预测场景开始时间和持续时长
- 支持场景信息的实时更新

**适用范围**:
- 多网并发场景下的业务优化
- 系统网络加速策略的精准管控
- 业务时长分析和网络质量评估

**API版本**: 6.0.2(22)及以上

## 使用场景

### 触发词
- "设置业务场景"
- "多网并发场景设置"
- "SetSceneDesc"
- "NetworkBoost场景描述"
- "登录场景设置"
- "秒杀场景设置"
- "直播场景设置"
- "游戏场景设置"

### 能做
- 在发起多网请求前设置业务场景类型和持续时间
- 帮助系统优化多网并发策略和网络加速决策
- 提供业务时长预测信息,用于系统资源分配
- 支持场景事件的动态更新(进入、更新、离开)
- 支持23种预定义业务场景类型的选择

### 绝不做
- 不用于单网场景下的业务优化
- 不替代网络质量检测功能
- 不直接发起多网并发请求(需配合RequestMultiPath)
- 不处理网络连接迁移事件
- 不用于权限申请流程(需提前配置权限)

### 补充
- 必须在发起多网请求前调用此接口
- 需要提前申请ohos.permission.GET_NETWORK_INFO权限
- 场景设置不影响网络质量,仅用于系统优化决策
- 建议根据实际业务场景选择合适的sceneType和duration
- startTime和duration单位均为秒(s)

## 调用规范和规则

### 输入约束
- **sceneType**: 必须为NetworkBoost_ServiceType枚举值之一(23种预定义场景)
- **sceneEvent**: 必须为NetworkBoost_SceneEvent枚举值之一(ENTER/UPDATE/LEAVE)
- **startTime**: 0表示立即发生,大于0表示预测未来进入时间(单位秒)
- **duration**: 0表示持续时长未知,大于0表示预计持续时长(单位秒)
- **调用时机**: 必须在HMS_NetworkBoost_RequestMultiPath之前调用

### 执行约束
- **最大调用频次**: 每个业务场景周期内建议调用不超过3次(进入/更新/离开)
- **API调用耗时**: 单次调用耗时不超过50ms
- **权限校验**: 必须已获得ohos.permission.GET_NETWORK_INFO权限
- **线程安全**: 支持多线程调用,但建议在主线程调用

### 内容约束
- 禁止传入无效的sceneType枚举值
- 禁止传入负数的startTime和duration值
- 禁止在不具备多网并发条件时设置场景
- 禁止混淆不同业务场景的类型(如将登录场景设为直播场景)
- 禁止使用已废弃的场景类型枚举值

### 降级约束
- **权限未获取**: 提示用户申请GET_NETWORK_INFO权限,跳过场景设置
- **系统不支持**: API版本低于6.0.2(22)时,跳过场景设置,直接发起多网请求
- **参数错误**: 返回错误码401,记录日志并提示开发者检查参数
- **内部错误**: 返回错误码62100001,尝试重试最多3次,仍失败则跳过场景设置
- **并发冲突**: 返回错误码62100002,延迟100ms后重试,最多重试2次

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查API版本是否满足6.0.2(22)及以上
2. 验证是否已申请ohos.permission.GET_NETWORK_INFO权限
3. 确认当前处于多网并发可用的网络环境
4. 确定业务场景类型和预计持续时长

**参数准备**:
```cpp
// C++示例:准备业务场景描述参数
NetworkBoost_SceneDesc sceneDesc;

// 选择业务场景类型(23种预定义类型之一)
sceneDesc.scene = NB_SERVICE_LOGIN; // 登录场景

// 设置场景事件类型
sceneDesc.sceneEvent = SCENE_EVENT_ENTER; // 进入场景

// 设置预计开始时间(单位秒)
sceneDesc.startTime = 0; // 立即开始

// 设置预计持续时长(单位秒)
sceneDesc.duration = 30; // 预计持续30秒
```

### 步骤2: 调用API

**示例代码**:
```cpp
// 导入必要模块
#include "NetworkBoostKit/network_boost.h"
#include <cstdio>
#include <cstring>

// 设置业务场景
int32_t SetSceneDesc()
{
    // 初始化场景描述结构体
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    // 设置登录场景参数
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    // 调用API设置业务场景
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("业务场景设置成功,场景类型: LOGIN, 持续时长: %d秒\n", sceneDesc.duration);
    } else {
        printf("业务场景设置失败,错误码: %d\n", ret);
    }
    
    return ret;
}

// 更新业务场景
int32_t UpdateSceneDesc()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    // 更新场景信息
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_UPDATE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 60; // 更新持续时长为60秒
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    printf("业务场景更新结果: %d\n", ret);
    return ret;
}

// 离开业务场景
int32_t LeaveSceneDesc()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    // 离开场景
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_LEAVE;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 0;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    printf("业务场景离开结果: %d\n", ret);
    return ret;
}
```

### 步骤3: 错误处理

```cpp
// 错误处理代码
#include <cstdio>

int32_t SetSceneDescWithErrorHandling()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    switch (ret) {
        case 0:
            printf("业务场景设置成功\n");
            break;
        case 201:
            printf("权限不足,请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误,请检查sceneType、sceneEvent、startTime、duration是否合法\n");
            break;
        case 801:
            printf("系统能力不支持,API版本需>=6.0.2(22)\n");
            break;
        case 62100001:
            printf("内部错误,建议重试最多3次\n");
            break;
        case 62100002:
            printf("系统服务操作失败,延迟100ms后重试\n");
            break;
        default:
            printf("未知错误: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤4: 降级处理

```cpp
// 降级处理代码
#include <cstdio>
#include <thread>
#include <chrono>

int32_t SetSceneDescWithFallback()
{
    NetworkBoost_SceneDesc sceneDesc;
    memset(&sceneDesc, 0, sizeof(NetworkBoost_SceneDesc));
    
    sceneDesc.scene = NB_SERVICE_LOGIN;
    sceneDesc.sceneEvent = SCENE_EVENT_ENTER;
    sceneDesc.startTime = 0;
    sceneDesc.duration = 30;
    
    // 第一次尝试
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 62100002) {
        // 系统服务操作失败,延迟重试
        printf("系统服务失败,延迟100ms后重试...\n");
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
        
        if (ret != 0) {
            // 重试失败,跳过场景设置
            printf("场景设置重试失败,跳过场景设置,直接发起多网请求\n");
            return -1; // 返回-1表示跳过场景设置
        }
    } else if (ret == 801) {
        // 系统不支持,跳过场景设置
        printf("系统不支持此API,跳过场景设置\n");
        return -1;
    } else if (ret == 201) {
        // 权限不足,提示用户
        printf("请先申请ohos.permission.GET_NETWORK_INFO权限\n");
        return -1;
    }
    
    return ret;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理,继续执行后续流程 |
| 201 | 权限不足 | 在module.json5中申请ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查sceneType、sceneEvent、startTime、duration参数是否合法 |
| 801 | 系统能力不支持 | 检查API版本是否>=6.0.2(22),升级系统或跳过场景设置 |
| 62100001 | 内部错误 | 建议重试最多3次,仍失败则跳过场景设置 |
| 62100002 | 系统服务操作失败 | 延迟100ms后重试最多2次,仍失败则跳过场景设置 |

## 编译和修复问题

### 依赖声明
```cmake
# CMakeLists.txt配置示例
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
)
```

### 环境要求
- **API版本**: 6.0.2(22)及以上
- **开发环境**: DevEco Studio 5.0及以上
- **SDK版本**: HarmonyOS SDK 6.0.2及以上
- **编译工具**: CMake 3.16及以上,Ninja编译器

### 权限配置
```json
// module.json5权限配置示例
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

### 常见编译问题

**问题1: 头文件找不到**
```
fatal error: 'NetworkBoostKit/network_boost.h' file not found
```
**解决方法**: 在CMakeLists.txt中添加头文件路径:
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
```

**问题2: 链接错误**
```
undefined reference to 'HMS_NetworkBoost_SetSceneDesc'
```
**解决方法**: 在CMakeLists.txt中添加动态库链接:
```cmake
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**问题3: 结构体未定义**
```
'NetworkBoost_SceneDesc' was not declared in this scope
```
**解决方法**: 确保正确导入头文件:
```cpp
#include "NetworkBoostKit/network_boost.h"
```

**问题4: 权限未生效**
```
运行时报错: Permission denied (201)
```
**解决方法**: 
1. 在module.json5中配置权限
2. 重新编译和签名应用
3. 如使用LINKTURBO权限,需申请受限ACL权限

## 常见问题与解决方法

### Q1: 如何选择合适的业务场景类型?
**原因**: 23种业务场景类型可能让开发者困惑
**解决方法**:
- 根据应用实际业务场景选择对应的ServiceType
- 常见场景映射:
  - 登录/一键登录: NB_SERVICE_LOGIN
  - 秒杀/抢购/抢票: NB_SERVICE_SECKILL_SERVICE
  - 直播观看: NB_SERVICE_LIVE_STREAMING_WATCHER
  - 直播主播: NB_SERVICE_LIVE_STREAMING_ANCHOR
  - 实时游戏: NB_SERVICE_REAL_TIME_GAME
  - 普通游戏: NB_SERVICE_NORMAL_GAME
  - 短视频: NB_SERVICE_SHORT_VIDEO
  - 长视频: NB_SERVICE_LONG_VIDEO
  - 下载: NB_SERVICE_DOWNLOAD
  - 上传: NB_SERVICE_UPLOAD
  - 浏览器: NB_SERVICE_BROWSER

### Q2: startTime和duration如何设置?
**原因**: 开发者不清楚时间参数的含义和使用
**解决方法**:
- **startTime**: 表示预测未来多长时间进入场景
  - 0: 立即进入场景(最常用)
  - 大于0: 预测未来N秒后进入场景(用于预加载场景)
- **duration**: 表示预计场景持续时长
  - 0: 持续时长未知,以SceneEvent的LEAVE事件表示终止
  - 大于0: 预计持续N秒,帮助系统优化资源分配
- 示例: 秒杀场景预计10秒后开始,持续20秒
  ```cpp
  sceneDesc.startTime = 10;
  sceneDesc.duration = 20;
  ```

### Q3: 什么时候调用场景事件的ENTER/UPDATE/LEAVE?
**原因**: 开发者不清楚场景事件的调用时机
**解决方法**:
- **ENTER**: 进入业务场景时调用(首次设置)
  - 调用时机: 发起多网请求之前
  - 示例: 用户点击登录按钮时
- **UPDATE**: 更新场景信息时调用
  - 调用时机: 场景持续时间或参数发生变化
  - 示例: 登录过程延长,从30秒更新到60秒
- **LEAVE**: 离开业务场景时调用
  - 调用时机: 业务场景结束或用户退出
  - 示例: 登录成功或用户取消登录

### Q4: 场景设置失败如何处理?
**原因**: 多种错误码可能导致设置失败
**解决方法**:
- **权限错误(201)**: 申请GET_NETWORK_INFO权限
- **参数错误(401)**: 检查枚举值和时间参数
- **系统不支持(801)**: 检查API版本,低于6.0.2时跳过
- **内部错误(62100001)**: 重试最多3次
- **系统服务失败(62100002)**: 延迟100ms重试最多2次

### Q5: 场景设置和多网请求的关系?
**原因**: 开发者不理解场景设置的作用时机
**解决方法**:
- **推荐流程**:
  1. 设置业务场景(SetSceneDesc)
  2. 发起多网请求(RequestMultiPath)
  3. 使用多网进行数据传输
  4. 更新场景(可选)
  5. 释放多网(ReleaseMultiPath)
  6. 离开场景(SetSceneDesc with LEAVE)
- **作用**: 场景设置帮助系统优化多网并发策略,不影响网络质量

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "sceneType": "NB_SERVICE_LOGIN",
  "sceneEvent": "SCENE_EVENT_ENTER",
  "startTime": 0,
  "duration": 30,
  "errorCode": 0,
  "message": "业务场景设置成功,帮助系统优化多网并发策略",
  "apiUsed": [
    "HMS_NetworkBoost_SetSceneDesc"
  ],
  "timestamp": "2026-07-03T17:13:00Z",
  "apiVersion": "6.0.2(22)"
}
```

**输出字段说明**:
- **status**: 执行状态(success/failure/skipped)
- **sceneType**: 设置的业务场景类型
- **sceneEvent**: 场景事件类型(ENTER/UPDATE/LEAVE)
- **startTime**: 场景开始时间
- **duration**: 场景持续时长
- **errorCode**: API返回的错误码
- **message**: 执行结果描述
- **apiUsed**: 调用的API列表
- **timestamp**: 执行时间戳
- **apiVersion**: API版本信息

## 参考文档

- [API开发指南](references/networkboost-netmultipath-setscenedesc-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [业务场景结构体定义](references/network-boost-c-struct-scene_desc.md)
- [开发准备](references/networkboost-preparations.md)

## 完整示例代码

- [C++完整示例](assets/example_set_scene_desc.cpp)
- [CMake配置示例](assets/example_cmake.txt)
- [权限配置示例](assets/example_permissions.json)

## 测试用例

### 正向测试用例
- [登录场景设置](tests/test_login_scene.cpp): 测试NB_SERVICE_LOGIN场景设置
- [秒杀场景设置](tests/test_seckill_scene.cpp): 测试NB_SERVICE_SECKILL_SERVICE场景设置
- [直播场景设置](tests/test_live_scene.cpp): 测试NB_SERVICE_LIVE_STREAMING场景设置
- [场景更新](tests/test_scene_update.cpp): 测试SCENE_EVENT_UPDATE事件
- [场景离开](tests/test_scene_leave.cpp): 测试SCENE_EVENT_LEAVE事件

### 边界测试用例
- [startTime边界值](tests/test_starttime_boundary.cpp): 测试startTime=0和最大值
- [duration边界值](tests/test_duration_boundary.cpp): 测试duration=0和最大值
- [所有场景类型遍历](tests/test_all_scene_types.cpp): 测试23种场景类型

### 异常测试用例
- [无效场景类型](tests/test_invalid_scene_type.cpp): 测试传入无效枚举值
- [负数时间参数](tests/test_negative_time.cpp): 测试startTime或duration为负数
- [权限未申请](tests/test_no_permission.cpp): 测试未申请权限时的错误处理
- [系统不支持](tests/test_system_not_support.cpp): 测试API版本低于6.0.2时的降级处理