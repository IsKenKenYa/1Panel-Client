---
name: hmos-performance-analysis-kit-address-sanitizer-watcher
description: 订阅地址越界事件，实时监听Native C++应用中的数组越界等内存访问错误，获取错误详情、堆栈信息和页面切换日志，最大支持事件实时回调，适用于Native应用内存安全检测和性能分析场景
---

# 订阅地址越界事件技能

## 功能描述

本技能用于订阅HarmonyOS系统生成的地址越界事件（ADDRESS_SANITIZER），实时监听Native C++代码中的内存访问错误，包括数组越界写入、缓冲区溢出等。当应用发生地址越界错误时，系统会自动生成事件，开发者通过订阅可获取详细的错误信息，包括错误类型、堆栈追踪、进程信息、日志文件路径等。支持配置页面切换日志记录，帮助定位错误发生时的页面上下文。

**核心能力**：
- 实时订阅地址越界系统事件
- 获取错误详情（错误类型、堆栈、进程信息）
- 支持页面切换日志记录（API 24+）
- Native C++代码内存安全检测

**适用范围**：
- Native C++工程应用
- 需要检测内存访问错误的应用
- 性能调优和崩溃分析场景

**限制条件**：
- 必须使用Native C++工程
- 需在DevEco Studio启用Address Sanitizer
- API version 12+支持地址越界事件
- API version 24+支持页面切换日志

## 使用场景

### 触发词
- "订阅地址越界事件" - 监听Native代码内存错误
- "检测数组越界" - 检测数组访问越界
- "Address Sanitizer" - 启用地址越界检测
- "内存安全检测" - Native应用内存安全
- "订阅系统事件" - HiAppEvent订阅系统事件

### 能做
- 实时订阅并处理ADDRESS_SANITIZER系统事件
- 获取地址越界错误的详细信息（错误类型、堆栈、进程信息）
- 配置页面切换日志，记录错误发生时的页面上下文
- 通过回调函数自定义事件处理逻辑
- 将错误信息记录到日志文件或上报到服务器

### 绝不做
- 不订阅其他类型的系统事件（如崩溃事件、冻屏事件）
- 不处理应用自定义事件
- 不用于生产环境的长期监控（仅用于开发调试）
- 不替代专业的内存检测工具（如Valgrind）
- 不在没有Native代码的纯ArkTS应用中使用

### 补充
- 需要在DevEco Studio中启用Address Sanitizer诊断选项
- 地址越界错误会导致应用崩溃，事件在崩溃后上报
- 页面切换日志需要API version 24+支持
- 建议在开发调试阶段使用，生产环境关闭Address Sanitizer

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符为数字/字母/下划线，结尾为数字/字母，长度1-32字符
- 事件领域：必须使用hiAppEvent.domain.OS（系统领域）
- 事件名称：必须使用hiAppEvent.event.ADDRESS_SANITIZER
- 页面切换日志：仅API version 24+支持，需校验sdkApiVersion

### 执行约束
- 最大回调耗时：建议不超过100ms（避免阻塞事件处理）
- 最大日志文件大小：系统默认限制，单个日志文件不超过5MB
- 事件处理时机：崩溃后重新进入应用时触发回调
- Address Sanitizer启用：必须在DevEco Studio配置中勾选

### 内容约束
- 禁止在回调中执行removeWatcher（会导致订阅失效）
- 禁止在回调中执行耗时操作（建议异步处理）
- 禁止修改事件params中的系统字段
- 禁止使用高危函数（如eval、exec）
- 必须对事件数据进行异常捕获处理

### 降级约束
- API version < 12：不支持地址越界事件，提示用户升级API
- API version < 24：不支持页面切换日志，跳过配置
- Address Sanitizer未启用：提示用户在DevEco Studio中启用
- 回调函数异常：记录错误日志但不影响系统事件上报

## 虚用流程和步骤

### 步骤1：新建Native C++工程

**前置校验**：
1. 确认使用DevEco Studio创建Native C++工程
2. 验证工程目录结构包含cpp目录
3. 确认已安装HarmonyOS SDK API version 12+

**工程结构**：
```
entry:
  src:
    main:
      cpp:
        - types:
            libentry:
              - index.d.ts
        - CMakeLists.txt
        - napi_init.cpp
      ets:
        - entryability:
            - EntryAbility.ets
        - pages:
            - Index.ets
```

### 步骤2：导入依赖模块

**示例代码**：
```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
```

**说明**：
- hiAppEvent：事件订阅核心模块
- hilog：日志输出模块
- deviceInfo：设备信息模块，用于API版本校验
- BusinessError：错误处理类型

### 步骤3：配置地址越界日志策略（可选）

**前置校验**：
1. 校验API版本：deviceInfo.sdkApiVersion >= 24
2. 确认需要启用页面切换日志记录

**示例代码**：
```typescript
// API Version 24+支持页面切换日志
if (deviceInfo.sdkApiVersion >= 24) {
  // 配置页面切换日志策略
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "addressSanitizerPolicy": {
      "pageSwitchLogEnable": true  // 启用页面切换日志
    }
  };
  
  // 调用配置接口
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'testTag', 'HiAppEvent success to config event policy.');
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

**错误处理**：
```typescript
// 降级处理：API version < 24时跳过配置
if (deviceInfo.sdkApiVersion < 24) {
  hilog.warn(0x0000, 'testTag', 'API version < 24, page switch log not supported.');
}
```

### 步骤4：添加观察者订阅事件

**参数准备**：
```typescript
// 定义观察者配置
const watcherConfig: hiAppEvent.Watcher = {
  name: "address_sanitizer_watcher",  // 观察者名称（唯一标识）
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,  // 系统事件领域
      names: [hiAppEvent.event.ADDRESS_SANITIZER]  // 订阅地址越界事件
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 自定义回调处理逻辑
  }
};
```

**示例代码**：
```typescript
// 在onCreate函数中添加订阅
hiAppEvent.addWatcher({
  name: "address_sanitizer_watcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.ADDRESS_SANITIZER]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 处理事件数据
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
        
        // 获取错误详情参数
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.type=${eventInfo.params['type']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
        
        // 获取页面切换日志（API 24+）
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.page_switch_log=${JSON.stringify(eventInfo.params['page_switch_log'])}`);
      }
    }
  }
});
```

### 步骤5：构造地址越界错误（测试）

**Native C++代码**：
```cpp
// entry/src/main/cpp/napi_init.cpp
#include "napi/native_api.h"

static napi_value Test(napi_env env, napi_callback_info info)
{
    int a[10];
    // 构造数组越界写入（触发地址越界错误）
    a[10] = 1;  // 越界访问
    return {};
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "test", nullptr, Test, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 }
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}
```

**类型声明**：
```typescript
// entry/src/main/cpp/types/libentry/index.d.ts
export const test: () => void;
```

**ArkTS调用代码**：
```typescript
// entry/src/main/ets/pages/Index.ets
import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  build() {
    Row() {
      Column() {
        Button("address-sanitizer").onClick(() => {
          testNapi.test();  // 触发地址越界错误
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### 步骤6：启用Address Sanitizer诊断

**配置步骤**：
1. 在DevEco Studio中点击"entry"
2. 点击"Edit Configurations"
3. 点击"Diagnostics"选项卡
4. 勾选"Address Sanitizer"
5. 保存设置并运行应用

**运行验证**：
- 点击按钮触发地址越界错误
- 应用崩溃后重新进入应用
- 在Log窗口查看订阅回调输出的错误信息

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误 | 检查Watcher配置参数，确保name、appEventFilters等参数正确 |
| 11102001 | 观察者名称无效。可能原因：包含非法字符、长度无效 | 使用合法的观察者名称：首字母为字母，中间为数字/字母/下划线，结尾为数字/字母，长度1-32字符 |
| 11102002 | 事件领域过滤无效。可能原因：包含非法字符、长度无效 | 使用系统事件领域：hiAppEvent.domain.OS |
| 11102003 | row值无效。row值小于0 | 设置合法的row值（正整数） |
| 11102004 | size值无效。size值小于0 | 设置合法的size值（正整数） |
| 11102005 | timeout值无效。timeout值小于0 | 设置合法的timeout值（正整数） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API 12+",
    "@kit.BasicServicesKit": "API 12+"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 12+（支持地址越界事件）
- HarmonyOS SDK：API version 24+（支持页面切换日志）
- DevEco Studio：3.1+
- Native C++工程模板

### 常见编译问题

**问题1：找不到hiAppEvent模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保HarmonyOS SDK API version >= 12，在ohpm.json中添加依赖

**问题2：ADDRESS_SANITIZER事件未定义**
```
Error: Property 'ADDRESS_SANITIZER' does not exist on type 'event'
```
**解决方法**：升级HarmonyOS SDK到API version 12+

**问题3：configEventPolicy接口未定义**
```
Error: Property 'configEventPolicy' does not exist on type 'hiAppEvent'
```
**解决方法**：升级HarmonyOS SDK到API version 22+

**问题4：页面切换日志未生效**
```
page_switch_log字段为空
```
**解决方法**：
- 检查API版本：deviceInfo.sdkApiVersion >= 24
- 确认已调用configEventPolicy配置
- 确认addressSanitizerPolicy.pageSwitchLogEnable设置为true

**问题5：Address Sanitizer未触发事件**
```
未收到ADDRESS_SANITIZER事件回调
```
**解决方法**：
- 在DevEco Studio的Edit Configurations中勾选Address Sanitizer
- 确认Native C++代码确实存在地址越界错误
- 应用崩溃后重新进入应用才能收到事件回调

## 常见问题与解决方法

### Q1：订阅后没有收到事件回调
**原因**：
- Address Sanitizer未在DevEco Studio中启用
- Native代码未发生地址越界错误
- 应用未崩溃或崩溃后未重新进入

**解决方法**：
- 在DevEco Studio的Diagnostics中勾选Address Sanitizer
- 在Native代码中构造数组越界等错误
- 触发错误后等待应用崩溃，然后重新启动应用

### Q2：页面切换日志字段为空
**原因**：
- API version < 24不支持页面切换日志
- 未调用configEventPolicy配置
- addressSanitizerPolicy配置错误

**解决方法**：
- 校验API版本：deviceInfo.sdkApiVersion >= 24
- 调用configEventPolicy配置addressSanitizerPolicy
- 设置pageSwitchLogEnable为true

### Q3：如何获取完整的堆栈信息
**原因**：堆栈信息存储在external_log字段中

**解决方法**：
- 从eventInfo.params['external_log']获取日志文件路径
- 日志文件存储在/data/storage/el2/log/hiappevent/目录
- 使用文件IO接口读取日志文件内容
- 或通过hilog查看系统日志

### Q4：能否在回调中移除观察者
**原因**：在回调中执行removeWatcher会导致订阅失效

**解决方法**：
- 不要在onReceive回调中调用removeWatcher
- 如需移除观察者，应在应用生命周期结束时调用
- 或在独立的按钮点击事件中调用

### Q5：地址越界错误导致应用崩溃，如何避免
**原因**：Address Sanitizer检测到错误会终止应用进程

**解决方法**：
- Address Sanitizer仅用于开发调试阶段
- 生产环境应关闭Address Sanitizer
- 修复Native代码中的内存访问错误
- 使用边界检查和安全的数组访问方式

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "address_sanitizer_watcher",
  "subscriptionType": "real-time",
  "eventDomain": "OS",
  "eventName": "ADDRESS_SANITIZER",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.configEventPolicy",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.ADDRESS_SANITIZER"
  ],
  "eventInfoFields": [
    "domain",
    "name",
    "eventType",
    "params.time",
    "params.bundle_version",
    "params.bundle_name",
    "params.pid",
    "params.uid",
    "params.type",
    "params.external_log",
    "params.log_over_limit",
    "params.page_switch_log"
  ],
  "addressSanitizerEnabled": true,
  "pageSwitchLogEnabled": true,
  "apiVersion": 24
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-address-sanitizer-events-arkts.md)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS示例](assets/address_sanitizer_watcher_example.ets) - 完整的订阅示例代码
- [Native C++示例](assets/napi_init.cpp) - 地址越界错误构造代码
- [类型声明](assets/index.d.ts) - NAPI接口类型声明
- [页面示例](assets/Index.ets) - 触发错误的页面代码

## 测试用例

### 正向测试用例
- [正常订阅地址越界事件](tests/test_positive_subscription.ets)：验证订阅成功并收到事件回调
- [配置页面切换日志](tests/test_page_switch_log.ets)：验证API 24+页面切换日志配置成功

### 边界测试用例
- [API版本校验](tests/test_api_version_check.ets)：验证API < 12和API < 24的降级处理
- [观察者名称边界](tests/test_watcher_name_boundary.ets)：验证名称长度32字符限制

### 异常测试用例
- [参数错误处理](tests/test_invalid_params.ets)：验证非法参数的错误码返回
- [Address Sanitizer未启用](tests/test_asan_disabled.ets)：验证未启用诊断时的提示信息
- [回调异常处理](tests/test_callback_exception.ets)：验证回调函数异常时的降级处理