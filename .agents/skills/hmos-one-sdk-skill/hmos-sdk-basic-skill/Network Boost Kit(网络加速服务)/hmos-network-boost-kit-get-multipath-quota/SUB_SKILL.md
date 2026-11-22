---
name: hmos-network-boost-kit-get-multipath-quota
description: 获取应用多网并发配额信息，查询已使用配额和剩余配额的次数与时长，API版本6.0.2(22)起支持，适用于多网并发配额管理和使用控制场景
---

# 多网配额查询(C/C++)技能

## 功能描述

本技能提供HarmonyOS多网并发配额查询功能，通过C API获取当前应用的多网并发配额信息，包括已使用的配额（次数和时长）和剩余的配额（次数和时长）。应用配额以24小时为周期进行刷新，配额耗尽后将限制多网功能的使用。

**核心能力**：
- 查询已使用的多网并发配额次数和时长
- 查询剩余的多网并发配额次数和时长
- 支持配额管理和使用控制
- 配额信息自动24小时刷新

**技术特点**：
- C API接口，适用于Native层开发
- 同步调用模式，直接返回结果
- 需要ohos.permission.LINKTURBO权限
- 起始版本：6.0.2(22)

## 使用场景

### 触发词
- "查询多网配额"
- "获取多网并发配额"
- "查询网络加速配额"
- "获取剩余配额"
- "查询已使用配额"
- "多网配额管理"
- "NetworkBoost配额查询"

### 能做
- 获取当前应用的多网并发已使用配额信息（次数和时长）
- 获取当前应用的多网并发剩余配额信息（次数和时长）
- 在发起多网请求前检查配额是否充足
- 实现配额使用情况的监控和统计
- 提供配额不足时的友好提示

### 绝不做
- 不增加或修改配额（配额由系统管理）
- 不清除或重置已使用配额
- 不执行多网请求操作（仅查询配额信息）
- 不处理配额耗尽后的网络切换
- 不替代网络连接管理功能

### 补充
- 配额以24小时为周期自动刷新
- 配额耗尽时请求多网会抛出错误码1013620004
- 需要提前申请ohos.permission.LINKTURBO权限（受限ACL权限）
- API版本要求：6.0.2(22)及以上
- 仅支持多网并发功能已使能的设备

## 调用规范和规则

### 输入约束
- 调用前必须已申请ohos.permission.LINKTURBO权限
- 调用前必须已链接libnetwork_boost.so库
- 调用前必须已包含头文件NetworkBoostKit/network_boost_handover.h
- 入参quota指针不能为空，必须指向有效的内存区域

### 执行约束
- 同步调用，立即返回结果
- 最大耗时：通常在毫秒级别
- API调用频次：无限制，但建议在关键节点查询
- 必须在主线程或具备网络权限的线程调用

### 内容约束
- 禁止传入空指针作为参数
- 禁止在未申请权限的情况下调用
- 禁止在API版本低于6.0.2(22)的设备上调用
- 禁止忽略返回的错误码
- 禁止在配额信息获取失败后继续执行多网请求

### 降级约束
- 权限不足（返回201）：提示用户权限未配置，引导申请权限
- 内部错误（返回1013600001）：记录日志，提示用户稍后重试
- 系统异常（返回1013600002）：检查系统服务状态，建议重启应用或设备
- 参数错误（返回1013600004）：检查指针是否为空，确保内存有效
- 设备不支持（返回801）：提示用户设备不支持多网并发功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否≥6.0.2(22)
2. 检查是否已申请ohos.permission.LINKTURBO权限
3. 检查是否已配置权限声明文件module.json5
4. 检查CMakeLists.txt是否已链接libnetwork_boost.so

**权限配置**：
```typescript
// module.json5
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

**CMake配置**：
```cmake
# CMakeLists.txt
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤2：导入头文件

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>
```

### 步骤3：查询配额信息

**完整示例代码**：
```cpp
/**
 * 查询多网并发配额信息
 * @return 0表示成功，其他值表示错误码
 */
int32_t GetMultiPathQuotaStats()
{
    // 1. 准备配额信息结构体
    NetworkBoost_MultiPathQuota quota = {0};
    
    // 2. 调用API获取配额信息
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    // 3. 处理返回结果
    if (ret == 0) {
        // 成功获取配额信息
        printf("获取多网配额信息成功\n");
        printf("已使用时长: %u 秒\n", quota.used.duration);
        printf("已使用次数: %u 次\n", quota.used.count);
        printf("剩余总时长: %u 秒\n", quota.remaining.duration);
        printf("剩余总次数: %u 次\n", quota.remaining.count);
        
        // 4. 根据配额情况进行业务处理
        if (quota.remaining.count == 0 || quota.remaining.duration == 0) {
            printf("警告: 配额已耗尽，请等待24小时后自动刷新\n");
            return -1;
        }
    } else {
        // 错误处理
        HandleQuotaError(ret);
        return ret;
    }
    
    return 0;
}

/**
 * 错误处理函数
 * @param errorCode 错误码
 */
void HandleQuotaError(int32_t errorCode)
{
    switch (errorCode) {
        case 201:
            printf("错误: 权限不足，请检查是否已申请ohos.permission.LINKTURBO权限\n");
            break;
        case 1013600001:
            printf("错误: 内部错误，请稍后重试\n");
            break;
        case 1013600002:
            printf("错误: 系统处理异常，如IPC跨进程调用失败或网络管理服务启动失败\n");
            break;
        case 1013600004:
            printf("错误: 传入参数有误，请检查参数是否为空指针\n");
            break;
        case 801:
            printf("错误: 系统能力不支持，当前设备不支持多网并发功能\n");
            break;
        default:
            printf("未知错误: %d\n", errorCode);
            break;
    }
}
```

### 步骤4：配额检查与多网请求

**示例代码**：
```cpp
/**
 * 检查配额是否充足
 * @return true表示配额充足，false表示配额不足
 */
bool CheckQuotaAvailable()
{
    NetworkBoost_MultiPathQuota quota = {0};
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret != 0) {
        printf("获取配额信息失败，错误码: %d\n", ret);
        return false;
    }
    
    // 检查剩余配额
    if (quota.remaining.count == 0) {
        printf("配额次数已耗尽\n");
        return false;
    }
    
    if (quota.remaining.duration == 0) {
        printf("配额时长已耗尽\n");
        return false;
    }
    
    printf("配额充足: 剩余次数=%u, 剩余时长=%u秒\n", 
           quota.remaining.count, quota.remaining.duration);
    return true;
}

/**
 * 业务逻辑：发起多网请求前检查配额
 */
void RequestMultiPathWithQuotaCheck()
{
    // 1. 先检查配额
    if (!CheckQuotaAvailable()) {
        printf("配额不足，无法发起多网请求\n");
        printf("配额将在24小时后自动刷新\n");
        return;
    }
    
    // 2. 配额充足，可以发起多网请求
    // ... 调用HMS_NetworkBoost_RequestMultiPath等其他API
}
```

### 步骤5：完整示例

**完整代码示例**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
#include <cstring>

/**
 * 多网配额管理类
 */
class MultiPathQuotaManager {
public:
    /**
     * 获取配额信息
     * @param quota 输出参数，配额信息
     * @return 0表示成功，其他值表示错误码
     */
    int32_t GetQuotaInfo(NetworkBoost_MultiPathQuota& quota)
    {
        memset(&quota, 0, sizeof(quota));
        int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
        
        if (ret == 0) {
            PrintQuotaInfo(quota);
        } else {
            PrintError(ret);
        }
        
        return ret;
    }
    
    /**
     * 打印配额信息
     */
    void PrintQuotaInfo(const NetworkBoost_MultiPathQuota& quota)
    {
        printf("=== 多网配额信息 ===\n");
        printf("已使用:\n");
        printf("  时长: %u 秒\n", quota.used.duration);
        printf("  次数: %u 次\n", quota.used.count);
        printf("剩余:\n");
        printf("  时长: %u 秒\n", quota.remaining.duration);
        printf("  次数: %u 次\n", quota.remaining.count);
        printf("==================\n");
    }
    
    /**
     * 打印错误信息
     */
    void PrintError(int32_t errorCode)
    {
        const char* errorMsg = nullptr;
        switch (errorCode) {
            case 201:
                errorMsg = "权限不足";
                break;
            case 1013600001:
                errorMsg = "内部错误";
                break;
            case 1013600002:
                errorMsg = "系统处理异常";
                break;
            case 1013600004:
                errorMsg = "参数错误";
                break;
            case 801:
                errorMsg = "系统能力不支持";
                break;
            default:
                errorMsg = "未知错误";
                break;
        }
        printf("错误: %s (错误码: %d)\n", errorMsg, errorCode);
    }
    
    /**
     * 检查是否可以发起多网请求
     */
    bool CanRequestMultiPath()
    {
        NetworkBoost_MultiPathQuota quota;
        if (GetQuotaInfo(quota) != 0) {
            return false;
        }
        
        return quota.remaining.count > 0 && quota.remaining.duration > 0;
    }
};

int main()
{
    MultiPathQuotaManager manager;
    
    // 获取配额信息
    NetworkBoost_MultiPathQuota quota;
    int32_t ret = manager.GetQuotaInfo(quota);
    
    if (ret == 0) {
        // 检查是否可以发起多网请求
        if (manager.CanRequestMultiPath()) {
            printf("可以发起多网请求\n");
        } else {
            printf("配额不足，无法发起多网请求\n");
        }
    }
    
    return 0;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 在module.json5中申请ohos.permission.LINKTURBO权限，并通过AGC申请受限ACL权限 |
| 801 | 系统能力不支持 | 当前设备不支持多网并发功能，提示用户更换设备或升级系统 |
| 1013600001 | 内部错误 | 系统内部处理异常，建议记录日志并稍后重试 |
| 1013600002 | 系统处理异常 | IPC跨进程调用失败或网络管理服务启动失败，检查系统服务状态，建议重启应用或设备 |
| 1013600004 | 传入参数有误 | 入参为空指针，检查quota指针是否为有效内存地址 |

## 编译和修复问题

### 依赖声明
```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 设置动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接动态库
target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
)
```

### 环境要求
- HarmonyOS SDK: API版本 ≥ 6.0.2(22)
- NDK版本: 配套HarmonyOS SDK版本
- 编译工具: CMake 3.4.1及以上

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：检查CMakeLists.txt中是否正确设置target_include_directories，确保${HMOS_SDK_NATIVE}环境变量正确指向HarmonyOS SDK路径。

**问题2：链接错误**
```
undefined reference to `HMS_NetworkBoost_GetMultiPathQuotaStats'
```
**解决方法**：检查CMakeLists.txt中是否正确链接libnetwork_boost.so，确保target_link_libraries包含libnetwork_boost.so。

**问题3：权限配置错误**
```
错误: 权限不足 (错误码: 201)
```
**解决方法**：
1. 在module.json5中添加"ohos.permission.LINKTURBO"权限声明
2. 通过AGC申请ohos.permission.LINKTURBO受限ACL权限
3. 配置签名时勾选ohos.permission.LINKTURBO权限

**问题4：结构体初始化错误**
```
error: too many initializers for 'NetworkBoost_MultiPathQuota'
```
**解决方法**：使用`{0}`或`memset(&quota, 0, sizeof(quota))`初始化结构体，不要手动指定成员初始值。

## 常见问题与解决方法

### Q1：获取配额信息返回201错误码
**原因**：未申请ohos.permission.LINKTURBO权限或权限未生效
**解决方法**：
- 检查module.json5中是否已添加权限声明
- 通过AGC申请ohos.permission.LINKTURBO受限ACL权限
- 重新配置签名并勾选该权限
- 卸载重装应用使权限生效

### Q2：配额信息显示为0
**原因**：
- 应用未使用过多网并发功能
- 配额已耗尽且未到刷新时间
- 系统服务异常

**解决方法**：
- 确认应用是否正确使用过多网并发功能
- 检查配额刷新时间（24小时周期）
- 检查系统服务状态，必要时重启设备

### Q3：调用API时应用崩溃
**原因**：传入空指针参数
**解决方法**：
- 确保quota参数不为空指针
- 使用memset初始化结构体
- 检查内存分配是否成功

### Q4：配额耗尽后如何处理
**原因**：配额以24小时为周期，耗尽后会限制使用
**解决方法**：
- 等待24小时后自动刷新配额
- 在应用中友好提示用户配额已耗尽
- 避免频繁调用多网请求
- 实现配额监控，提前预警

### Q5：如何监控配额使用情况
**原因**：需要实时了解配额消耗情况
**解决方法**：
- 定时查询配额信息（建议间隔≥1小时）
- 在发起多网请求前检查配额
- 记录配额使用日志，便于分析
- 提供配额统计功能，帮助用户了解使用情况

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "quotaInfo": {
    "used": {
      "duration": "已使用时长（秒）",
      "count": "已使用次数"
    },
    "remaining": {
      "duration": "剩余时长（秒）",
      "count": "剩余次数"
    }
  },
  "apiUsed": [
    "HMS_NetworkBoost_GetMultiPathQuotaStats"
  ],
  "errorCode": 0,
  "errorMessage": "成功"
}
```

## 参考文档

- [API开发指南](references/networkboost-netmultipath-getmultipathquota-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [结构体说明](references/network-boost-c-struct-multipath_quota.md)
- [配额信息结构体](references/network-boost-c-struct-multipath_quotainfo.md)
- [开发准备](references/networkboost-preparations.md)

## 完整示例代码

- [C++示例](assets/example_multipath_quota.cpp)
- [CMake配置示例](assets/CMakeLists.txt)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常查询配额信息](tests/test_positive.cpp)：验证成功获取配额信息
- [配额充足场景](tests/test_positive.cpp)：验证配额充足时可发起多网请求

### 边界测试用例
- [配额耗尽场景](tests/test_boundary.cpp)：验证配额耗尽时的处理
- [配额即将耗尽场景](tests/test_boundary.cpp)：验证配额即将耗尽时的预警

### 异常测试用例
- [权限不足场景](tests/test_exception.cpp)：验证未申请权限时的错误处理
- [空指针参数](tests/test_exception.cpp)：验证传入空指针时的错误处理
- [系统不支持场景](tests/test_exception.cpp)：验证设备不支持时的降级处理