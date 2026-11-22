---
name: hmos-networkboost-kit-set-scene-desc
description: 设置多网并发业务场景描述信息，包括业务场景类型、事件类型、开始时间和持续时长，支持登录、直播、游戏等23种业务场景，适用于多网并发前的场景声明和系统管控优化，需API 6.0.2(22)及以上
---

# 业务场景设置(C/C++)技能

## 功能描述

本技能提供Network Boost Kit多网并发业务场景设置能力，通过调用`HMS_NetworkBoost_SetSceneDesc`接口，向系统声明业务场景描述信息，帮助系统进行多网并发管控和业务时长分析。支持23种业务场景类型（如登录、直播、游戏、视频会议等），可声明进入、更新、离开三种场景事件，并可预测场景开始时间和持续时长，从而优化系统对多网资源的分配策略。

**核心能力**：
- 声明业务场景类型（实时语音、视频、游戏、登录等）
- 设置场景事件（进入、更新、离开）
- 预测场景开始时间和持续时长
- 辅助系统进行多网并发管控

**起始版本**：6.0.2(22)

## 使用场景

### 触发词
- "设置业务场景"
- "多网并发场景声明"
- "登录场景设置"
- "直播场景设置"
- "游戏场景设置"
- "NetworkBoost场景描述"
- "多网业务时长设置"

### 能做
- 在发起多网并发请求前，声明业务场景类型和事件
- 设置场景的开始时间（立即或预测未来时间）
- 设置场景预计持续时长
- 更新已声明的业务场景信息
- 声明离开业务场景，释放多网资源优化

### 绝不做
- 不直接发起多网并发请求（需配合RequestMultiPath接口）
- 不替代网络质量监测或连接迁移回调注册
- 不处理超出Network Boost Kit范围的请求
- 不在未配置权限的情况下调用

### 补充
- 必须在发起多网并发请求前调用，帮助系统优化管控策略
- 需申请ohos.permission.GET_NETWORK_INFO权限
- 建议在业务场景进入时设置ENTER事件，离开时设置LEAVE事件
- duration为0表示持续时长未知，以LEAVE事件终止

## 调用规范和规则

### 输入约束
- scene参数：必须使用NetworkBoost_ServiceType枚举值，支持23种场景类型
- sceneEvent参数：必须使用NetworkBoost_SceneEvent枚举值（ENTER/UPDATE/LEAVE）
- startTime参数：uint32_t类型，单位为秒，0表示立即，>0表示预测未来时间
- duration参数：uint32_t类型，单位为秒，0表示未知时长
- 参数校验：scene和sceneEvent必须为有效枚举值，不能为空或越界

### 执行约束
- 调用时机：必须在多网并发请求前或场景变化时调用
- 最大调用频次：建议不超过每秒10次（避免频繁切换）
- 执行超时：接口为同步调用，预计耗时<10ms
- 权限检查：调用前必须确保已获取ohos.permission.GET_NETWORK_INFO权限

### 内容约束
- 禁止使用无效的枚举值（超出定义范围的值）
- 禁止在未声明ENTER前直接声明UPDATE或LEAVE
- 禁止传入负数或超大的startTime/duration值（合理范围0-3600秒）
- 禁止在后台场景使用实时性要求高的场景类型（如实时游戏）

### 降级约束
- 权限未获取：提示用户申请ohos.permission.GET_NETWORK_INFO权限
- API版本不支持：提示需API 6.0.2(22)及以上版本
- 参数错误：返回错误码并提示具体错误字段
- 系统服务异常：返回错误码62100002，建议稍后重试或降级为不设置场景

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否>=6.0.2(22)
2. 检查是否已申请ohos.permission.GET_NETWORK_INFO权限
3. 确定业务场景类型（登录、直播、游戏等）
4. 确定场景事件类型（ENTER/UPDATE/LEAVE）

**参数准备**：
```cpp
#include "NetworkBoostKit/network_boost.h"
#include <cstdio>

struct SceneParams {
    NetworkBoost_ServiceType scene;
    NetworkBoost_SceneEvent sceneEvent;
    uint32_t startTime;
    uint32_t duration;
};

SceneParams params;
params.scene = NB_SERVICE_LOGIN;           // 登录场景
params.sceneEvent = SCENE_EVENT_ENTER;     // 进入事件
params.startTime = 0;                      // 立即开始
params.duration = 0;                       // 持续时长未知
```

### 步骤2：调用API

**示例代码**：
```cpp
int32_t SetSceneDesc(SceneParams params)
{
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = params.scene;
    sceneDesc.sceneEvent = params.sceneEvent;
    sceneDesc.startTime = params.startTime;
    sceneDesc.duration = params.duration;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    if (ret == 0) {
        printf("业务场景设置成功: scene=%d, event=%d\n", 
               params.scene, params.sceneEvent);
    } else {
        printf("业务场景设置失败: 错误码=%d\n", ret);
        HandleSceneError(ret);
    }
    
    return ret;
}

void HandleSceneError(int32_t errorCode)
{
    switch (errorCode) {
        case 201:
            printf("权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误，请检查scene和sceneEvent是否为有效枚举值\n");
            break;
        case 801:
            printf("系统能力不支持，需API 6.0.2(22)及以上版本\n");
            break;
        case 62100001:
            printf("内部错误，请稍后重试\n");
            break;
        case 62100002:
            printf("系统服务操作失败，网络管理服务可能异常\n");
            break;
        default:
            printf("未知错误码: %d\n", errorCode);
    }
}
```

### 步骤3：错误处理

```cpp
int32_t SafeSetSceneDesc(NetworkBoost_ServiceType scene, 
                         NetworkBoost_SceneEvent event,
                         uint32_t startTime, 
                         uint32_t duration)
{
    if (scene < NB_SERVICE_DEFAULT || scene > NB_SERVICE_SHOPPING) {
        printf("错误: scene参数无效，范围应为0-23\n");
        return 401;
    }
    
    if (event < NB_SCENE_EVENT_ENTER || event > NB_SCENE_EVENT_LEAVE) {
        printf("错误: sceneEvent参数无效，范围应为0-2\n");
        return 401;
    }
    
    if (startTime > 3600 || duration > 3600) {
        printf("警告: startTime或duration过大，建议在0-3600秒范围内\n");
    }
    
    NetworkBoost_SceneDesc sceneDesc;
    sceneDesc.scene = scene;
    sceneDesc.sceneEvent = event;
    sceneDesc.startTime = startTime;
    sceneDesc.duration = duration;
    
    int32_t ret = HMS_NetworkBoost_SetSceneDesc(sceneDesc);
    
    switch (ret) {
        case 0:
            printf("业务场景设置成功\n");
            break;
        case 201:
            printf("权限不足: 请在module.json5中配置ohos.permission.GET_NETWORK_INFO\n");
            break;
        case 401:
            printf("参数错误: 检查枚举值是否正确\n");
            break;
        case 801:
            printf("系统能力不支持: 需升级到API 6.0.2(22)\n");
            break;
        case 62100001:
        case 62100002:
            printf("系统服务异常: 建议稍后重试或降级处理\n");
            break;
    }
    
    return ret;
}
```

### 步骤4：降级处理

```cpp
int32_t SetSceneDescWithFallback(SceneParams params)
{
    int32_t ret = SetSceneDesc(params);
    
    if (ret != 0) {
        printf("场景设置失败，执行降级策略\n");
        
        if (ret == 201) {
            printf("降级: 不设置业务场景，直接使用默认系统策略\n");
            return 0;
        }
        
        if (ret == 801) {
            printf("降级: API版本不支持，使用传统网络请求方式\n");
            return 0;
        }
        
        if (ret == 62100001 || ret == 62100002) {
            printf("降级: 系统服务异常，延迟3秒后重试\n");
            sleep(3);
            ret = SetSceneDesc(params);
            if (ret != 0) {
                printf("重试失败，放弃场景设置，使用默认策略\n");
            }
        }
    }
    
    return ret;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 在module.json5中配置ohos.permission.GET_NETWORK_INFO权限，重新签名应用 |
| 401 | 参数错误 | 检查scene和sceneEvent是否为有效枚举值，确保startTime和duration在合理范围 |
| 801 | 系统能力不支持 | 升级设备系统到API 6.0.2(22)及以上版本 |
| 62100001 | 内部错误 | 系统内部状态异常，建议稍后重试或重启应用 |
| 62100002 | 系统服务操作失败 | 网络管理服务异常，检查系统服务状态或重启设备 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**权限配置**（module.json5）：
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

### 环境要求
- HarmonyOS API版本：>=6.0.2(22)
- 开发工具：DevEco Studio 3.1及以上
- SDK：HarmonyOS Native SDK包含NetworkBoostKit模块
- 目标设备：支持Network Boost Kit的HarmonyOS设备

### 常见编译问题

**问题1：找不到network_boost.h头文件**
```
fatal error: NetworkBoostKit/network_boost.h: No such file or directory
```
**解决方法**：
1. 检查${HMOS_SDK_NATIVE}环境变量是否正确设置
2. 在CMakeLists.txt中添加target_include_directories指向sysroot/usr/include
3. 确认SDK版本>=6.0.2(22)，NetworkBoost Kit从该版本开始提供

**问题2：链接libnetwork_boost.so失败**
```
cannot find -lnetwork_boost
```
**解决方法**：
1. 检查target_link_directories路径是否正确
2. 确认SDK中存在libnetwork_boost.so文件（路径：sysroot/usr/lib/aarch64-linux-ohos/）
3. 确认编译目标架构为aarch64-linux-ohos

**问题3：枚举值未定义**
```
error: 'NB_SERVICE_LOGIN' was not declared in this scope
```
**解决方法**：
1. 确保正确引入头文件：`#include "NetworkBoostKit/network_boost.h"`
2. 检查API版本是否>=6.0.2(22)，NetworkBoost_SceneDesc和SceneEvent从该版本引入
3. 使用正确的枚举名称，参考NetworkBoost_ServiceType和NetworkBoost_SceneEvent定义

**问题4：权限运行时错误**
```
运行时报错: Permission Denial: requires ohos.permission.GET_NETWORK_INFO
```
**解决方法**：
1. 在module.json5的requestPermissions中添加权限声明
2. 重新签名应用（自动签名或手动签名）
3. 对于受限ACL权限，需要在AGC中申请Profile

## 常见问题与解决方法

### Q1：什么时候应该调用SetSceneDesc？
**原因**：开发者不清楚调用时机
**解决方法**：
- 在发起多网并发请求（RequestMultiPath）前调用，声明ENTER事件
- 在业务场景信息变化时调用，声明UPDATE事件（如登录成功、直播切换清晰度）
- 在退出业务场景时调用，声明LEAVE事件（如关闭直播、退出游戏）

### Q2：duration设置为0有什么影响？
**原因**：duration为0表示持续时长未知
**解决方法**：
- duration=0时，系统将依赖LEAVE事件来判断场景结束
- 建议在可预测时长场景（如10秒登录、20秒秒杀）设置具体duration值
- 无法预测时长场景（如直播观看）设置为0，并在退出时调用LEAVE事件

### Q3：startTime大于0如何使用？
**原因**：startTime用于预测未来场景
**解决方法**：
- startTime=0表示立即进入场景（最常见用法）
- startTime>0用于预测未来多长时间后进入场景（如10秒后进入秒杀场景）
- 系统可提前优化网络资源分配策略

### Q4：是否必须调用SetSceneDesc才能使用多网并发？
**原因**：开发者误以为必须调用
**解决方法**：
- SetSceneDesc为可选接口，帮助系统优化管控策略
- 不调用时，系统将使用默认策略处理多网并发
- 建议在高价值场景（直播、游戏、秒杀）调用，获得更优网络体验

### Q5：如何选择正确的业务场景类型？
**原因**：23种场景类型容易混淆
**解决方法**：
- 实时交互场景：NB_SERVICE_REAL_TIME_VOICE（实时语音）、NB_SERVICE_REAL_TIME_VIDEO（实时视频）
- 流媒体场景：NB_SERVICE_LIVE_STREAMING_ANCHOR（直播主播）、NB_SERVICE_LIVE_STREAMING_WATCHER（直播观看）
- 游戏场景：NB_SERVICE_REAL_TIME_GAME（实时游戏）、NB_SERVICE_NORMAL_GAME（普通游戏）
- 登录场景：NB_SERVICE_LOGIN（一键登录、账号登录）
- 秒杀场景：NB_SERVICE_SECKILL_SERVICE（抢票、抢购、抢单）
- 其他场景：参考NetworkBoost_ServiceType枚举完整定义

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success|failed",
  "errorCode": 0,
  "sceneType": "NB_SERVICE_LOGIN",
  "sceneEvent": "SCENE_EVENT_ENTER",
  "startTime": 0,
  "duration": 0,
  "apiUsed": [
    "HMS_NetworkBoost_SetSceneDesc"
  ],
  "message": "业务场景设置成功，系统将优化多网并发管控策略"
}
```

## 参考文档

- [API开发指南](references/networkboost-netmultipath-setscenedesc-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [NetworkBoost_SceneDesc结构体](references/network-boost-c-struct-scene_desc.md)
- [开发准备](references/networkboost-preparations.md)

## 完整示例代码

- [登录场景示例](assets/example_login.cpp)
- [直播场景示例](assets/example_live_streaming.cpp)
- [游戏场景示例](assets/example_game.cpp)

## 测试用例

### 正向测试用例
- [登录场景设置测试](tests/test_positive.cpp)：测试NB_SERVICE_LOGIN场景ENTER事件设置
- [直播场景设置测试](tests/test_positive.cpp)：测试NB_SERVICE_LIVE_STREAMING_WATCHER场景设置
- [游戏场景设置测试](tests/test_positive.cpp)：测试NB_SERVICE_REAL_TIME_GAME场景设置

### 边界测试用例
- [startTime边界测试](tests/test_boundary.cpp)：测试startTime=0和startTime=3600边界值
- [duration边界测试](tests/test_boundary.cpp)：测试duration=0和duration=3600边界值
- [枚举值边界测试](tests/test_boundary.cpp)：测试scene和sceneEvent的边界枚举值

### 异常测试用例
- [权限缺失测试](tests/test_exception.cpp)：测试未配置权限时的错误处理
- [参数错误测试](tests/test_exception.cpp)：测试无效枚举值的错误处理
- [API版本不支持测试](tests/test_exception.cpp)：测试API版本低于6.0.2(22)的错误处理
- [系统服务异常测试](tests/test_exception.cpp)：测试系统服务异常时的降级处理