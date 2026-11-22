---
name: hmos-performance-analysis-kit-hidebug-ndk-backtrace-cpuusage
description: 获取线程栈回溯和CPU使用率，支持C/C++ NDK接口，最大栈回溯深度256帧，适用于性能分析、调试诊断场景
---

# HiDebug接口使用示例(C/C++)技能

## 功能描述

本技能提供HarmonyOS HiDebug C/C++ NDK接口调用能力，用于获取应用线程栈回溯信息和线程CPU使用率。通过栈回溯可以追踪线程调用栈，通过CPU使用率可以监控线程性能，适用于性能分析、故障诊断、调试优化等场景。

**主要功能**：
- 线程栈回溯：获取当前线程或指定线程的调用栈信息，支持Native和JS栈帧
- 线程CPU使用率：获取应用内所有线程的CPU使用率百分比

**技术特点**：
- 栈回溯接口异步信号安全，可在信号处理函数中使用
- 支持Native和JS栈帧混合解析
- CPU使用率获取涉及跨进程通信，建议异步调用

## 使用场景

### 触发词
- "获取线程栈回溯"
- "抓栈"
- "backtrace"
- "栈追踪"
- "获取线程CPU使用率"
- "线程性能分析"
- "CPU使用率监控"
- "HiDebug NDK"
- "hidebug"

### 能做
- 获取当前线程的完整调用栈信息（Native和JS栈帧）
- 获取应用内所有线程的CPU使用率百分比
- 解析栈帧符号信息（函数名、文件名、行号等）
- 在信号处理函数中进行栈回溯（异步信号安全）
- 输出栈帧详细信息到日志

### 绝不做
- 不在主线程中直接调用耗时接口（OH_HiDebug_GetAppThreadCpuUsage、OH_HiDebug_SymbolicAddress等）
- 不在栈回溯过程中进行资源重复初始化
- 不在自定义内存操作函数中调用libc标准库函数
- 不在异步信号不安全的函数中使用信号处理相关功能
- 不忽略线程安全和资源释放

### 补充
- 栈回溯最大深度建议不超过256帧
- 栈解析接口（OH_HiDebug_SymbolicAddress）耗时较长，避免频繁调用
- 获取线程CPU使用率需要释放资源，防止内存泄漏
- API起始版本：栈回溯功能需要API 20，CPU使用率功能需要API 12

## 调用规范和规则

### 输入约束
- 栈回溯深度：建议最大256帧，可根据业务场景调整
- 栈回溯起始地址：必须是有效的栈帧指针（fp地址）
- 线程安全：同一时刻只能由一个线程使用栈回溯资源

### 执行约束
- 最大耗时：
  - OH_HiDebug_GetAppThreadCpuUsage：跨进程通信，耗时较长
  - OH_HiDebug_SymbolicAddress：多次IO操作，耗时超过1秒
- 调用频次：栈解析接口避免频繁调用
- 异步调用：耗时接口建议在工作线程中调用

### 内容约束
- 禁止在主线程中直接调用耗时接口
- 禁止在栈回溯过程中重复初始化资源
- 禁止在栈解析完成后不释放资源
- 禁止在自定义内存操作函数中使用hilog打印日志

### 降级约束
- 栈回溯失败：检查fp地址有效性，返回空栈或错误码
- 栈解析失败：返回原始pc地址，不提供符号信息
- CPU使用率获取失败：返回null或0值
- 资源创建失败：及时释放已申请资源，返回错误信息

## 调用流程和步骤

### 步骤1：栈回溯功能实现

#### 1.1 创建项目并准备文件

**前置条件**：
1. 使用DevEco Studio创建Native C++工程
2. 新增文件：test_backtrace.cpp和test_backtrace.h
3. 目录结构：
```
entry/src/main/cpp/
  - types/libentry/index.d.ts
  - CMakeLists.txt
  - napi_init.cpp
  - test_backtrace.cpp
  - test_backtrace.h
```

#### 1.2 定义栈回溯封装类

```cpp
// test_backtrace.h
#ifndef MYAPPLICATION_TESTBACKTRACE_H
#define MYAPPLICATION_TESTBACKTRACE_H
void BacktraceCurrentThread();
#endif // MYAPPLICATION_TESTBACKTRACE_H
```

```cpp
// test_backtrace.cpp - 头文件引入和宏定义
#include "test_backtrace.h"
#include <condition_variable>
#include <csignal>
#include <unistd.h>
#include <sys/syscall.h>
#include "hidebug/hidebug.h"
#include "hilog/log.h"

#define MAX_FRAME_SIZE 256 // 最大栈回溯深度

namespace {
    constexpr auto LOG_PRINT_DOMAIN = 0xFF00;
}
```

#### 1.3 创建栈回溯对象封装类

```cpp
// 封装栈回溯资源的单例类（非异步信号安全，需确保线程安全）
class BackTraceObject {
public:
    static BackTraceObject& GetInstance();
    BackTraceObject(const BackTraceObject&) = delete;
    BackTraceObject& operator=(const BackTraceObject&) = delete;
    
    bool Init(uint32_t size);
    void Release();
    int BackTraceFromFp(void* startFp, int size);
    void SymbolicAddress(int index);
    void PrintStackFrame(void* pc, const HiDebug_StackFrame& frame);

private:
    BackTraceObject() = default;
    ~BackTraceObject() = default;
    HiDebug_Backtrace_Object backtraceObject_ = nullptr;
    void** pcs_ = nullptr;
};

// 单例实现
BackTraceObject& BackTraceObject::GetInstance() {
    static BackTraceObject instance;
    return instance;
}
```

#### 1.4 初始化和释放资源

```cpp
bool BackTraceObject::Init(uint32_t size) {
    backtraceObject_ = OH_HiDebug_CreateBacktraceObject();
    if (backtraceObject_ == nullptr || size > MAX_FRAME_SIZE) {
        return false;
    }
    
    pcs_ = new (std::nothrow) void* [size]{nullptr};
    if (pcs_ == nullptr) {
        OH_HiDebug_DestroyBacktraceObject(backtraceObject_);
        backtraceObject_ = nullptr;
        return false;
    }
    
    return true;
}

void BackTraceObject::Release() {
    OH_HiDebug_DestroyBacktraceObject(backtraceObject_);
    backtraceObject_ = nullptr;
    delete[] pcs_;
    pcs_ = nullptr;
}
```

#### 1.5 执行栈回溯

```cpp
int BackTraceObject::BackTraceFromFp(void* startFp, int size) {
    if (size <= MAX_FRAME_SIZE) {
        return OH_HiDebug_BacktraceFromFp(backtraceObject_, startFp, pcs_, size);
    }
    return 0;
}
```

#### 1.6 栈帧符号解析

```cpp
void BackTraceObject::PrintStackFrame(void* pc, const HiDebug_StackFrame& frame) {
    if (frame.type == HIDEBUG_STACK_FRAME_TYPE_JS) {
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "testTag",
            "js stack frame info for pc: %{public}p is "
            "relativePc: %{public}p line: %{public}d column: %{public}d "
            "mapName: %{public}s functionName: %{public}s "
            "url: %{public}s packageName: %{public}s.",
            pc,
            reinterpret_cast<void*>(frame.frame.js.relativePc),
            frame.frame.js.line,
            frame.frame.js.column,
            frame.frame.js.mapName,
            frame.frame.js.functionName,
            frame.frame.js.url,
            frame.frame.js.packageName);
    } else {
        OH_LOG_Print(LOG_APP, LOG_INFO, LOG_PRINT_DOMAIN, "testTag",
            "native stack frame info for pc: %{public}p is "
            "relativePc: %{public}p funcOffset: %{public}p "
            "mapName: %{public}s functionName: %{public}s "
            "buildId: %{public}s reserved: %{public}s.",
            pc,
            reinterpret_cast<void*>(frame.frame.native.relativePc),
            reinterpret_cast<void*>(frame.frame.native.funcOffset),
            frame.frame.native.mapName,
            frame.frame.native.functionName,
            frame.frame.native.buildId,
            frame.frame.native.reserved);
    }
}

void BackTraceObject::SymbolicAddress(int index) {
    if (index < 0 || index >= MAX_FRAME_SIZE) {
        return;
    }
    
    OH_HiDebug_SymbolicAddress(backtraceObject_, pcs_[index], this,
        [] (void* pc, void* arg, const HiDebug_StackFrame* frame) {
            reinterpret_cast<BackTraceObject*>(arg)->PrintStackFrame(pc, *frame);
        });
}
```

#### 1.7 线程栈回溯主函数

```cpp
void BacktraceCurrentThread() {
    if (!BackTraceObject::GetInstance().Init(MAX_FRAME_SIZE)) {
        BackTraceObject::GetInstance().Release();
        OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, "testTag", 
            "failed init backtrace object.");
        return;
    }
    
    int pcSize = BackTraceObject::GetInstance().BackTraceFromFp(
        __builtin_frame_address(0), MAX_FRAME_SIZE);
    
    for (int i = 0; i < pcSize; i++) {
        BackTraceObject::GetInstance().SymbolicAddress(i);
    }
    
    BackTraceObject::GetInstance().Release();
}
```

### 步骤2：线程CPU使用率功能实现

```cpp
napi_value TestGetThreadCpuUsage(napi_env env, napi_callback_info info) {
    HiDebug_ThreadCpuUsagePtr cpuUsage = OH_HiDebug_GetAppThreadCpuUsage();
    
    while (cpuUsage != nullptr) {
        OH_LOG_INFO(LogType::LOG_APP,
            "GetAppThreadCpuUsage: threadId %{public}d, cpuUsage: %{public}f",
            cpuUsage->threadId, cpuUsage->cpuUsage);
        cpuUsage = cpuUsage->next;
    }
    
    OH_HiDebug_FreeThreadCpuUsage(&cpuUsage);
    return nullptr;
}
```

### 步骤3：配置CMake依赖

```cmake
add_library(entry SHARED napi_init.cpp test_backtrace.cpp)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libohhidebug.so)
```

### 步骤4：注册ArkTS接口

```cpp
napi_property_descriptor desc[] = {
    { "testGetThreadCpuUsage", nullptr, TestGetThreadCpuUsage, 
      nullptr, nullptr, nullptr, napi_default, nullptr },
    { "testBackTrace", nullptr, TestBackTrace, 
      nullptr, nullptr, nullptr, napi_default, nullptr },
};
```

### 步骤5：声明ArkTS接口

```typescript
export const testGetThreadCpuUsage: () => void;
export const testBackTrace: () => void;
```

### 步骤6：在ArkTS中调用

```typescript
import testNapi from 'libentry.so';

function testBackTraceJsFrame(i : number) : void {
  if (i > 0) {
    return testBackTraceJsFrame(i-1);
  }
  return testNapi.testBackTrace();
}

function testBackTrace() : void {
  testBackTraceJsFrame(3);
}

function testGetThreadCpuUsage() : void {
  testNapi.testGetThreadCpuUsage();
}
```

### 步骤7：错误处理和异常捕获

```cpp
void SafeBacktraceCurrentThread() {
    try {
        if (!BackTraceObject::GetInstance().Init(MAX_FRAME_SIZE)) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "testTag",
                "Init failed: resource allocation error");
            BackTraceObject::GetInstance().Release();
            return;
        }
        
        int pcSize = BackTraceObject::GetInstance().BackTraceFromFp(
            __builtin_frame_address(0), MAX_FRAME_SIZE);
        
        if (pcSize == 0) {
            OH_LOG_Print(LOG_APP, LOG_WARN, LOG_PRINT_DOMAIN, "testTag",
                "Backtrace failed: no stack frames captured");
        }
        
        for (int i = 0; i < pcSize; i++) {
            BackTraceObject::GetInstance().SymbolicAddress(i);
        }
        
        BackTraceObject::GetInstance().Release();
    } catch (const std::exception& e) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_PRINT_DOMAIN, "testTag",
            "Exception during backtrace: %{public}s", e.what());
        BackTraceObject::GetInstance().Release();
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| HIDEBUG_SUCCESS (0) | 成功 | 无需处理 |
| HIDEBUG_INVALID_ARGUMENT (401) | 无效参数 | 检查参数类型和取值范围 |
| HIDEBUG_INVALID_SYMBOLIC_PC_ADDRESS (11400200) | 无效的pc地址 | 检查pc地址是否有效，确保栈回溯成功 |
| NULL返回值 | 资源创建失败或获取数据失败 | 检查系统资源、权限、API版本 |

**常见错误场景**：

1. **栈回溯对象创建失败**
   - 原因：系统资源不足或API版本不支持
   - 解决：检查API版本（需API 20），及时释放已申请资源

2. **栈回溯返回0帧**
   - 原因：fp地址无效或栈损坏
   - 解决：检查栈帧指针有效性，确保调用栈正常

3. **栈解析失败**
   - 原因：pc地址无效或符号信息不可用
   - 解决：检查pc地址来源，部分栈帧可能无法解析

4. **线程CPU使用率获取失败**
   - 原因：系统权限不足或跨进程通信失败
   - 解决：检查应用权限，确保API版本支持（需API 12）

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

add_library(entry SHARED napi_init.cpp test_backtrace.cpp)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so      # NAPI接口
    libhilog_ndk.z.so     # 日志输出
    libohhidebug.so       # HiDebug接口
)
```

### 环境要求
- HarmonyOS API版本：12（CPU使用率功能），20（栈回溯功能）
- DevEco Studio：支持Native C++工程
- 系统能力：SystemCapability.HiviewDFX.HiProfiler.HiDebug

### 常见编译问题

**问题1：找不到hidebug.h头文件**
```
fatal error: 'hidebug/hidebug.h' file not found
```
**解决方法**：
- 检查SDK版本是否支持API 12及以上
- 在CMakeLists.txt中添加正确的头文件搜索路径

**问题2：链接libohhidebug.so失败**
```
undefined reference to 'OH_HiDebug_CreateBacktraceObject'
```
**解决方法**：
- 在CMakeLists.txt中添加：`target_link_libraries(entry PUBLIC libohhidebug.so)`
- 检查库文件路径是否正确

**问题3：API版本不兼容**
```
'OH_HiDebug_BacktraceFromFp' was not declared in this scope
```
**解决方法**：
- 检查目标API版本，栈回溯功能需要API 20
- 在build-profile.json5中设置正确的compileSdkVersion

### 常见运行时问题

**问题1：栈回溯对象创建返回NULL**
```
backtraceObject_ == nullptr
```
**解决方法**：
- 检查API版本（需API 20）
- 检查系统资源是否充足
- 确保在合适的时机调用（避免在初始化阶段）

**问题2：线程CPU使用率获取耗时过长**
```
主线程阻塞
```
**解决方法**：
- 不要在主线程中直接调用OH_HiDebug_GetAppThreadCpuUsage
- 使用工作线程或异步任务执行

**问题3：栈解析时出现死锁**
```
应用卡死
```
**解决方法**：
- 不要在自定义内存操作函数中调用hilog
- 不要在栈解析回调中调用libc标准库函数

## 常见问题与解决方法

### Q1：栈回溯只能获取Native栈，无法获取JS栈？
**原因**：JS栈帧需要特定的运行环境，部分场景下可能无法解析
**解决方法**：
- 确保应用包含ArkTS代码
- 检查栈帧类型（HIDEBUG_STACK_FRAME_TYPE_JS）
- 部分混合调用场景可能只显示Native栈

### Q2：栈回溯深度设置过小，无法获取完整栈？
**原因**：MAX_FRAME_SIZE设置小于实际栈深度
**解决方法**：
- 根据业务场景调整栈深度（建议256）
- 检查返回的pcSize值，判断是否截断

### Q3：线程CPU使用率数据不准确？
**原因**：采样间隔过短或系统负载变化
**解决方法**：
- 增加采样间隔
- 多次采样取平均值
- 注意：返回值为瞬时CPU使用率

### Q4：栈解析耗时过长影响性能？
**原因**：OH_HiDebug_SymbolicAddress涉及多次IO操作
**解决方法**：
- 减少解析次数，只解析关键栈帧
- 在工作线程中执行解析
- 使用缓存机制避免重复解析

### Q5：在信号处理函数中如何使用栈回溯？
**原因**：需要异步信号安全的函数
**解决方法**：
- 使用OH_HiDebug_BacktraceFromFp（异步信号安全）
- 不使用OH_HiDebug_SymbolicAddress（非异步信号安全）
- 在信号处理函数外进行符号解析

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "stackFrames": {
    "total": 15,
    "native": 10,
    "js": 5,
    "maxDepth": 256
  },
  "cpuUsage": {
    "threadCount": 12,
    "mainThreadUsage": 0.000104,
    "avgUsage": 0.000038
  },
  "apiUsed": [
    "OH_HiDebug_CreateBacktraceObject",
    "OH_HiDebug_BacktraceFromFp",
    "OH_HiDebug_SymbolicAddress",
    "OH_HiDebug_DestroyBacktraceObject",
    "OH_HiDebug_GetAppThreadCpuUsage",
    "OH_HiDebug_FreeThreadCpuUsage"
  ],
  "warnings": [
    "栈解析接口耗时较长，建议在工作线程中调用",
    "获取线程CPU使用率涉及跨进程通信，建议异步调用"
  ]
}
```

## 参考文档

- [HiDebug开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hidebug-guidelines-ndk)
- [HiDebug C API模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug)
- [HiDebug头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug-h)
- [HiDebug类型定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug-type-h)
- [HiDebug_Backtrace_Object结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug-hidebug-backtrace-object--8h)
- [HiDebug_StackFrame结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug-hidebug-stackframe)
- [HiDebug_ThreadCpuUsage结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hidebug-hidebug-threadcpuusage)

## 完整示例代码

- [完整C++示例代码](assets/hidebug_ndk_example.cpp)
- [CMake配置示例](assets/CMakeLists.txt)
- [ArkTS接口示例](assets/index.ets)
- [接口声明示例](assets/index.d.ts)

## 测试用例

### 正向测试用例
- [基本栈回溯测试](tests/test_backtrace_positive.cpp)：测试正常场景的栈回溯功能
- [线程CPU使用率测试](tests/test_cpuusage_positive.cpp)：测试线程CPU使用率获取功能
- [混合栈测试](tests/test_mixed_stack.cpp)：测试Native和JS混合栈帧解析

### 边界测试用例
- [栈深度边界测试](tests/test_stack_depth_boundary.cpp)：测试最大栈深度256帧
- [空栈测试](tests/test_empty_stack.cpp)：测试栈回溯返回0帧的情况
- [单线程测试](tests/test_single_thread.cpp)：测试只有主线程的情况

### 异常测试用例
- [资源创建失败测试](tests/test_resource_failure.cpp)：测试栈回溯对象创建失败
- [无效参数测试](tests/test_invalid_params.cpp)：测试传入无效参数
- [权限不足测试](tests/test_permission_denied.cpp)：测试权限不足场景
- [并发冲突测试](tests/test_concurrent_conflict.cpp)：测试多线程并发使用冲突