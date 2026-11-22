---
name: hmos-network-boost-kit-set-handover-mode
description: 设置连接迁移模式，支持委托模式(系统发起)和自主模式(应用发起)，需GET_NETWORK_INFO权限，适用于网络切换场景
---

# 迁移模式设置技能

## 功能描述

本技能用于设置HarmonyOS应用的连接迁移模式，允许应用在网络环境变化时控制迁移行为。支持两种模式：
- **委托模式(NB_MODE_DELEGATION)**：由系统自动发起连接迁移，默认模式
- **自主模式(NB_MODE_DISCRETION)**：由应用主动控制连接迁移，可禁止系统自动迁移

连接迁移功能帮助应用在Wi-Fi和蜂窝网络切换、主卡和副卡切换等场景下快速恢复业务，提供平滑的网络体验。

## 使用场景

### 触发词
- "设置迁移模式"
- "切换迁移模式"
- "设置连接迁移"
- "自主迁移模式"
- "委托迁移模式"
- "Network Boost迁移模式"

### 能做
- 设置连接迁移为委托模式(系统控制)
- 设置连接迁移为自主模式(应用控制)
- 禁止系统自动发起连接迁移
- 在网络切换场景下控制迁移行为

### 绝不做
- 不直接发起连接迁移(仅设置模式)
- 不处理网络质量监测
- 不处理多网并发请求
- 不替代连接迁移回调注册

### 补充
- 默认为委托模式，未调用此接口则系统自动控制迁移
- 自主模式下，应用切换到后台时系统仍可能触发切换
- 需申请ohos.permission.GET_NETWORK_INFO权限
- 仅适用于API版本5.1.0(18)及以上

## 调用规范和规则

### 输入约束
- 迁移模式参数：必须为NetworkBoost_HandoverMode枚举值(NB_MODE_DELEGATION或NB_MODE_DISCRETION)
- 参数有效性：枚举值必须为0(委托)或1(自主)
- 无文件或字符串参数要求

### 执行约束
- 最大耗时：同步调用，预计耗时<10ms
- 无迭代或循环要求
- 单次API调用即可完成设置
- API调用频次：无限制，但建议仅在需要时调用

### 内容约束
- 禁止生成：不生成网络质量监测代码、多网并发代码
- 禁止使用高危函数：无特殊限制
- 禁止操作：不修改系统网络配置、不操作其他应用网络设置

### 降级约束
- 权限不足：提示用户申请GET_NETWORK_INFO权限
- 参数错误：验证枚举值有效性，提示正确取值范围
- 系统不支持：检查API版本，提示最低版本要求
- 内部错误：记录错误码，提示系统服务异常

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本：确保设备支持API 5.1.0(18)及以上
2. 检查权限配置：验证module.json5中已配置ohos.permission.GET_NETWORK_INFO
3. 检查头文件引用：确认已导入NetworkBoostKit/network_boost_handover.h
4. 检查库链接：确认CMakeLists.txt已链接libnetwork_boost.so

**权限配置示例(module.json5)**：
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

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤2：调用API

**导入头文件**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
```

**设置自主模式示例**：
```cpp
int32_t SetHandoverModeToDiscretion()
{
    NetworkBoost_HandoverMode mode = NB_MODE_DISCRETION;
    int32_t ret = HMS_NetworkBoost_SetHandoverMode(mode);
    
    if (ret == 0) {
        printf("设置自主迁移模式成功\n");
    } else {
        printf("设置迁移模式失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

**设置委托模式示例**：
```cpp
int32_t SetHandoverModeToDelegation()
{
    NetworkBoost_HandoverMode mode = NB_MODE_DELEGATION;
    int32_t ret = HMS_NetworkBoost_SetHandoverMode(mode);
    
    if (ret == 0) {
        printf("设置委托迁移模式成功\n");
    } else {
        printf("设置迁移模式失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

**完整示例函数**：
```cpp
int32_t SetHandoverMode(NetworkBoost_HandoverMode mode)
{
    if (mode != NB_MODE_DELEGATION && mode != NB_MODE_DISCRETION) {
        printf("参数错误：无效的迁移模式\n");
        return 401;
    }
    
    int32_t ret = HMS_NetworkBoost_SetHandoverMode(mode);
    
    switch (ret) {
        case 0:
            printf("设置连接迁移模式成功\n");
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误，请检查迁移模式参数\n");
            break;
        case 801:
            printf("系统能力不支持，请检查API版本\n");
            break;
        case 62100001:
            printf("内部错误，系统服务异常\n");
            break;
        case 62100002:
            printf("系统服务操作失败\n");
            break;
        default:
            printf("未知错误: %d\n", ret);
            break;
    }
    
    return ret;
}
```

### 步骤3：错误处理

**错误处理示例**：
```cpp
void HandleSetHandoverModeError(int32_t errorCode)
{
    switch (errorCode) {
        case 201:
            printf("权限不足，请在module.json5中配置权限\n");
            break;
        case 401:
            printf("参数错误，请使用有效枚举值\n");
            break;
        case 801:
            printf("系统能力不支持，最低版本要求5.1.0(18)\n");
            break;
        case 62100001:
            printf("内部错误，请稍后重试\n");
            break;
        case 62100002:
            printf("系统服务失败，请检查网络服务状态\n");
            break;
        default:
            printf("未知错误码: %d\n", errorCode);
            break;
    }
}
```

### 步骤4：降级处理

**权限检查降级**：
```cpp
bool CheckNetworkBoostPermission()
{
    int32_t testRet = HMS_NetworkBoost_SetHandoverMode(NB_MODE_DELEGATION);
    if (testRet == 201) {
        printf("警告：缺少GET_NETWORK_INFO权限，请配置module.json5\n");
        return false;
    }
    return true;
}
```

**API版本兼容性检查**：
```cpp
bool CheckApiVersion()
{
    int32_t testRet = HMS_NetworkBoost_SetHandoverMode(NB_MODE_DELEGATION);
    if (testRet == 801) {
        printf("警告：当前系统不支持Network Boost Kit，最低版本要求5.1.0(18)\n");
        return false;
    }
    return true;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 在module.json5中配置ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 确保mode参数为NB_MODE_DELEGATION(0)或NB_MODE_DISCRETION(1) |
| 801 | 系统能力不支持 | 检查设备API版本，最低要求5.1.0(18) |
| 62100001 | 内部错误 | 系统服务异常，建议稍后重试或检查系统状态 |
| 62100002 | 系统服务操作失败 | 检查网络管理服务是否正常运行 |

## 编译和修复问题

### 依赖声明
**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.16)
project(NetworkBoostDemo)

set(CMAKE_CXX_STANDARD 17)

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
- HarmonyOS SDK：API版本5.1.0(18)及以上
- 编译工具：CMake 3.16+
- C++标准：C++17或更高
- 目标架构：aarch64-linux-ohos

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：在CMakeLists.txt中添加正确的include路径：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
```

**问题2：链接错误**
```
undefined reference to `HMS_NetworkBoost_SetHandoverMode'
```
**解决方法**：在CMakeLists.txt中添加库链接：
```cmake
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**问题3：权限未配置**
```
运行时返回错误码201
```
**解决方法**：在module.json5中添加权限配置：
```json
{
  "name": "ohos.permission.GET_NETWORK_INFO"
}
```

## 常见问题与解决方法

### Q1：设置自主模式后，系统还会自动切换吗？
**原因**：在某些特殊场景下，如应用切换到后台时，系统仍可能触发网络切换
**解决方法**：
- 这是正常行为，自主模式主要控制前台时的迁移行为
- 应用切换到后台时系统为保证用户体验可能仍会触发切换
- 建议注册连接迁移回调监听切换事件

### Q2：调用API返回201错误码？
**原因**：未配置ohos.permission.GET_NETWORK_INFO权限
**解决方法**：
- 检查module.json5中requestPermissions配置
- 确保已添加"ohos.permission.GET_NETWORK_INFO"
- 重新编译并安装应用

### Q3：调用API返回801错误码？
**原因**：当前设备API版本不支持Network Boost Kit
**解决方法**：
- 检查设备系统版本，最低要求API 5.1.0(18)
- 在不支持设备上提供降级方案
- 提示用户升级系统版本

### Q4：设置迁移模式后没有生效？
**原因**：可能未正确设置或系统服务异常
**解决方法**：
- 检查API返回值是否为0(成功)
- 验证参数是否为有效枚举值
- 注册连接迁移回调观察实际迁移行为
- 检查系统网络服务状态

### Q5：如何判断当前迁移模式？
**原因**：API仅提供设置接口，不提供查询接口
**解决方法**：
- 应用内部维护当前模式状态变量
- 默认为委托模式(NB_MODE_DELEGATION)
- 设置成功后更新内部状态

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "mode": "NB_MODE_DISCRETION",
  "errorCode": 0,
  "description": "设置连接迁移模式为自主模式成功",
  "apiUsed": [
    "HMS_NetworkBoost_SetHandoverMode"
  ],
  "permissions": [
    "ohos.permission.GET_NETWORK_INFO"
  ],
  "minApiVersion": "5.1.0(18)"
}
```

## 参考文档

- [迁移模式设置开发指南(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-reporthandovermode-c)
- [Network Boost Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [Network Boost Kit开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
- [连接迁移头文件说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover)

## 完整示例代码

- [C++示例代码](assets/set_handover_mode_example.cpp)
- [CMakeLists.txt示例](assets/cmakelists_example.txt)
- [权限配置示例](assets/module_json5_example.json)

## 测试用例

### 正向测试用例
- [测试委托模式设置](tests/test_set_delegation_mode.cpp)：验证设置委托模式返回成功
- [测试自主模式设置](tests/test_set_discretion_mode.cpp)：验证设置自主模式返回成功

### 边界测试用例
- [测试枚举值边界](tests/test_enum_boundary.cpp)：验证枚举值0和1的正确性

### 异常测试用例
- [测试无效参数](tests/test_invalid_parameter.cpp)：验证无效枚举值返回401错误
- [测试权限缺失](tests/test_permission_denied.cpp)：验证未配置权限返回201错误
- [测试系统不支持](tests/test_system_unsupported.cpp)：验证低版本返回801错误