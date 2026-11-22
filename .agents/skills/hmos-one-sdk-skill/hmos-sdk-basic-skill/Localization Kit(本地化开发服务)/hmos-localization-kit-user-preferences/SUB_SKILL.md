---
name: hmos-localization-kit-user-preferences
description: 获取和监听系统用户偏好设置,包括本地数字使用状态和时制模式,支持24小时制判断和时制变化监听,适用于应用国际化场景
---

# 用户偏好设置技能

## 功能描述

本技能提供HarmonyOS系统用户偏好设置的获取和监听能力,包括:
- 判断系统当前是否使用本地数字
- 判断系统当前是否使用24小时制
- 监听系统时制变化事件

用户偏好设置会保存到系统区域及应用偏好语言中,最终体现在用户界面的国际化特性上。当前支持本地数字和时制两种偏好。

## 使用场景

### 触发词
- "获取用户偏好"
- "判断本地数字"
- "判断24小时制"
- "监听时制变化"
- "用户偏好设置"

### 能做
- 获取系统当前是否使用本地数字的状态
- 获取系统当前是否使用24小时制的状态
- 监听系统时制变化事件并响应
- 区分系统时间和系统时制变化

### 绝不做
- 修改用户偏好设置(仅读取和监听)
- 监听其他类型的系统事件
- 处理超出用户偏好范围的请求

### 补充
- 监听时制变化需要使用公共事件订阅机制
- 需要区分系统时间变化和系统时制变化(通过事件数据判断)
- 适用于需要根据用户偏好调整界面显示的场景

## 调用规范和规则

### 输入约束
- 无需输入参数(获取用户偏好状态)
- 监听事件需要正确配置订阅信息
- 事件订阅需要正确的权限配置

### 执行约束
- API调用为同步调用,立即返回结果
- 事件订阅需要在应用生命周期内正确管理
- 最大监听时长:应用运行期间
- 建议在应用启动时创建订阅者,在应用退出时取消订阅

### 内容约束
- 禁止使用高危函数(如eval、exec等)
- 禁止硬编码事件名称
- 必须使用官方定义的事件常量
- 禁止在回调函数中执行耗时操作

### 降级约束
- API调用失败:记录错误日志,使用默认值(false)
- 事件订阅失败:记录错误日志,提示用户手动刷新
- 事件监听异常:取消订阅并重新订阅

## 调用流程和步骤

### 步骤1: 准备阶段

**导入必要模块**:
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';
```

**前置校验**:
1. 确认应用已获得必要权限(监听公共事件无需特殊权限)
2. 确认运行环境为HarmonyOS设备
3. 确认API版本符合要求(API version 9+)

### 步骤2: 获取用户偏好状态

**获取本地数字使用状态**:
```typescript
// 判断系统当前是否使用本地数字
let usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
console.info(`System using local digit: ${usingLocalDigit}`);
```

**获取时制状态**:
```typescript
// 判断系统当前是否使用24小时制
let is24HourClock: boolean = i18n.System.is24HourClock();
console.info(`System using 24 hour clock: ${is24HourClock}`);
```

### 步骤3: 监听时制变化事件

**创建事件订阅者**:
```typescript
let timeSubscriber: commonEventManager.CommonEventSubscriber;
let timeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
  events: [commonEventManager.Support.COMMON_EVENT_TIME_CHANGED]
};

commonEventManager.createSubscriber(timeSubscribeInfo)
  .then((commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    console.info('CreateSubscriber successfully');
    timeSubscriber = commonEventSubscriber;
    
    commonEventManager.subscribe(timeSubscriber, (err, data) => {
      if (err) {
        console.error(`Failed to subscribe common event. error code: ${err.code}, message: ${err.message}.`);
        return;
      }
      
      // 区分系统时间和系统时制变化
      if (data.data != undefined && data.data == '24HourChange') {
        console.info('System time format changed detected.');
        // 重新获取时制状态
        let newIs24HourClock: boolean = i18n.System.is24HourClock();
        console.info(`New 24 hour clock status: ${newIs24HourClock}`);
        // 执行界面更新逻辑
        updateTimeFormatDisplay(newIs24HourClock);
      } else {
        console.info('System time changed detected.');
      }
    });
  })
  .catch((err: BusinessError) => {
    console.error(`CreateSubscriber failed, code is ${err.code}, message is ${err.message}`);
  });
```

### 步骤4: 取消事件订阅

**在应用退出时取消订阅**:
```typescript
// 取消订阅
if (timeSubscriber != undefined) {
  commonEventManager.unsubscribe(timeSubscriber)
    .then(() => {
      console.info('Unsubscribe successfully');
    })
    .catch((err: BusinessError) => {
      console.error(`Unsubscribe failed, code is ${err.code}, message is ${err.message}`);
    });
}
```

### 步骤5: 错误处理

**完整的错误处理代码**:
```typescript
try {
  let usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
  let is24HourClock: boolean = i18n.System.is24HourClock();
  
  console.info(`Local digit: ${usingLocalDigit}, 24Hour: ${is24HourClock}`);
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Get user preferences failed, error code: ${err.code}, message: ${err.message}.`);
  
  // 降级处理:使用默认值
  let usingLocalDigit = false;
  let is24HourClock = true;
  console.warn(`Using default values: Local digit: ${usingLocalDigit}, 24Hour: ${is24HourClock}`);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. | 检查参数类型和必填参数是否正确 |
| 1500004 | CreateSubscriber failed. | 检查订阅信息配置是否正确 |
| 1500007 | Subscribe failed. | 检查事件名称是否正确,权限是否配置 |
| 1500008 | Unsubscribe failed. | 检查订阅者对象是否有效 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "API version 9+",
    "@kit.BasicServicesKit": "API version 9+"
  }
}
```

### 环境要求
- HarmonyOS API version: 9及以上
- 开发环境: DevEco Studio 3.1及以上
- 运行环境: HarmonyOS设备

### 常见编译问题

**问题1: 导入模块失败**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**: 确认API版本符合要求,在module.json5中配置正确的依赖

**问题2: 事件订阅失败**
```
Error: Subscribe failed, code is 1500007
```
**解决方法**: 检查事件名称是否使用官方常量,确认订阅信息配置正确

**问题3: 权限不足**
```
Error: Permission denied
```
**解决方法**: COMMON_EVENT_TIME_CHANGED无需特殊权限,检查其他权限配置

## 常见问题与解决方法

### Q1: 如何区分系统时间变化和系统时制变化?
**原因**: COMMON_EVENT_TIME_CHANGED事件会同时触发系统时间和系统时制变化
**解决方法**: 通过事件数据(data.data)判断,值为'24HourChange'表示时制变化

### Q2: 监听事件后应用退出需要取消订阅吗?
**原因**: 未取消订阅会导致资源泄漏
**解决方法**: 在应用退出或页面销毁时调用unsubscribe取消订阅

### Q3: API调用失败如何处理?
**原因**: 可能是API版本不支持或系统异常
**解决方法**: 使用try-catch捕获异常,使用默认值作为降级方案

### Q4: 本地数字功能具体是什么?
**原因**: 需要理解本地数字的含义
**解决方法**: 本地数字指使用本地语言的数字显示方式,如阿拉伯语使用东阿拉伯数字

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "usingLocalDigit": false,
  "is24HourClock": true,
  "eventSubscription": "active",
  "apiUsed": [
    "i18n.System.getUsingLocalDigit",
    "i18n.System.is24HourClock",
    "commonEventManager.createSubscriber",
    "commonEventManager.subscribe",
    "commonEventManager.unsubscribe"
  ],
  "timestamp": "2026-07-04T10:00:00Z"
}
```

## 参考文档

- [API开发指南](references/i18n-user-preferences.md)
- [API参考说明](references/js-apis-i18n.md)
- [公共事件参考](references/commoneventmanager-definitions.md)

## 完整示例代码

- [ArkTS示例](assets/example_user_preferences.ets)
- [完整应用示例](assets/complete_example.ets)

## 测试用例

### 正向测试用例
- [获取本地数字状态](tests/test_positive.py): 测试getUsingLocalDigit正常调用
- [获取时制状态](tests/test_positive.py): 测试is24HourClock正常调用
- [监听时制变化](tests/test_positive.py): 测试事件订阅和回调正常触发

### 边界测试用例
- [连续多次调用](tests/test_boundary.py): 测试API连续调用稳定性
- [并发订阅](tests/test_boundary.py): 测试多个订阅者并发订阅
- [长时间监听](tests/test_boundary.py): 测试长时间运行稳定性

### 异常测试用例
- [API调用异常](tests/test_exception.py): 测试API调用失败处理
- [订阅失败](tests/test_exception.py): 测试事件订阅失败处理
- [取消订阅异常](tests/test_exception.py): 测试取消订阅异常处理