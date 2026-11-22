---
name: hmos-performance-analysis-kit-watch-web-fling-jank-events
description: 订阅ArkWeb抛滑丢帧事件，实时获取web页面性能数据和丢帧详情，支持web_id到url映射查询，适用于Web性能调优、丢帧分析、卡顿检测场景
---

# 订阅ArkWeb抛滑丢帧事件技能

## 功能描述

本技能提供订阅和监听ArkWeb抛滑丢帧事件的能力。当Web页面在抛滑过程中发生卡顿50ms及以上时，系统会自动触发SCROLL_ARKWEB_FLING_JANK事件，通过HiAppEvent的订阅机制实时获取事件数据，包括丢帧时间、持续时间、web_id、最大帧时长等信息，并支持通过web_id映射到具体的页面URL，帮助开发者快速定位性能问题。

**核心能力**：
- 实时监听ArkWeb抛滑丢帧事件
- 获取详细丢帧数据（开始时间、持续时间、web_id、最大帧时长）
- 支持web_id到URL的映射查询
- 自动触发事件回调，无需主动轮询

**适用场景**：
- Web页面性能调优
- 抛滑卡顿问题定位
- 丢帧频率统计分析
- Web组件性能监控

## 使用场景

### 触发词
- "订阅ArkWeb抛滑丢帧事件"
- "监听Web丢帧"
- "检测Web页面卡顿"
- "Web性能分析"
- "ArkWeb丢帧监控"
- "抛滑丢帧事件订阅"

### 能做
- 订阅ArkWeb抛滑丢帧系统事件（SCROLL_ARKWEB_FLING_JANK）
- 实时接收丢帧事件回调通知
- 获取丢帧事件的详细参数（start_time、duration、web_id、max_app_frame_time）
- 实现web_id到页面URL的映射查询
- 在日志中输出丢帧事件数据
- 移除事件观察者取消订阅

### 绝不做
- 不订阅其他系统事件类型（仅针对ArkWeb抛滑丢帧事件）
- 不修改系统事件的数据结构
- 不处理应用自定义事件
- 不替代Web组件的性能优化方案
- 不执行耗时阻塞操作在回调函数中

### 补充
- 仅在抛滑过程中发生卡顿50ms及以上时触发事件
- 需配合Web组件使用，实现web_id到URL的映射
- 回调函数在主线程执行，避免阻塞操作
- 事件domain固定为hiAppEvent.domain.OS
- 支持多个Web组件，每个组件有独立的web_id

## 调用规范和规则

### 输入约束
- 观察者名称：长度1-32字符，首字符必须是字母，中间字符必须是数字/字母/下划线，结尾字符必须是数字/字母
- domain：固定为hiAppEvent.domain.OS（系统事件领域）
- 事件名称：固定为hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK
- Web组件数量：无限制，每个Web组件独立web_id
- 触发阈值：卡顿时长>=50ms

### 执行约束
- 最大回调执行时间：建议<100ms（避免阻塞主线程）
- 最大订阅观察者数量：无限制（但建议根据业务需要控制）
- API调用模式：异步回调（onReceive实时触发）
- 日志输出频率：每次事件触发时输出

### 内容约束
- 禁止在回调函数中执行移除观察者操作（会造成订阅失效）
- 禁止在回调中执行耗时阻塞操作（如while循环、sleep等）
- 禁止修改事件数据的原始结构
- 禁止使用高危函数（eval、exec等）
- 禁止访问本地高权限路径

### 降级约束
- Web组件未加载：事件不会触发，无需降级
- 回调执行失败：捕获异常并记录日志，不影响后续事件订阅
- web_id映射失败：输出警告日志，返回null或默认值
- 观察者添加失败：返回null，记录错误日志，可重试添加

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证开发环境：DevEco Studio已安装，工程已创建
2. 验证依赖模块：PerformanceAnalysisKit已导入
3. 验证Web组件：Web页面已实现并可访问
4. 验证网络权限：ohos.permission.INTERNET已配置

**参数准备**：
```typescript
// 导入必要模块
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { webIdToUrlMap } from '../pages/ArkWebPage';

// 定义观察者配置
const watcherConfig = {
  name: 'webJankWatcher',  // 观察者名称
  domain: hiAppEvent.domain.OS,  // 系统事件领域
  eventName: hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK  // ArkWeb抛滑丢帧事件
};
```

### 步骤2：添加事件观察者

**示例代码**：
```typescript
// 导入必要模块
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { webIdToUrlMap } from '../pages/ArkWebPage';

// 添加ArkWeb抛滑丢帧事件观察者
hiAppEvent.addWatcher({
  // 开发者可以自定义观察者名称，系统会使用名称来标识不同的观察者
  name: 'webJankWatcher',
  // 开发者可以订阅感兴趣的系统事件，此处是订阅了ArkWeb抛滑丢帧事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK]
    }
  ],
  // 开发者可以自行实现订阅实时回调函数，以便对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      // 开发者可以根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 开发者可以对事件集合中的事件数据进行自定义处理，此处是将事件数据打印在日志中
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        // 开发者可以获取到开始抛滑事件的时间戳
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.start_time=${eventInfo.params['start_time']}`);
        // 开发者可以获取到抛滑动效持续的时间长度
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.duration=${eventInfo.params['duration']}`);
        // 开发者可以获取到发生卡顿的的web页面对应的Id
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.web_id=${eventInfo.params['web_id']}`);
        // 开发者可以获取抛滑阶段发生丢帧的最大时长
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.max_app_frame_time=${eventInfo.params['max_app_frame_time']}`);
        const webId: number = eventInfo.params['web_id'];
        //webIdToUrlMap是一个定义的变量，用于实现webId到url的映射，通过系统侧获取的web_id查询到发生丢帧的网页
        const currentUrl = webIdToUrlMap.get(webId);
        // 开发者可以获取到发生卡顿的页面
        hilog.info(0x0000, 'testTag', `HiAppEvent get currentUrl=${currentUrl}`);
      }
    }
  }
});
```

### 步骤3：实现Web组件和映射

**示例代码**：
```typescript
import web_webview from '@ohos.web.webview';
// 用于存储web_id到url的映射
export const webIdToUrlMap = new Map<number, string>();

@Entry
@Component
struct ArkWebPage {
  controller = new web_webview.WebviewController();
  
  build() {
    Column() {
      Web({ src: 'https://baidu.com',
        controller: this.controller
      })
        .height('100%')
        .onPageBegin((event) => {
          // 每次跳转到新页面都更新webId到url的映射关系，便于后续通过系统侧提供的web_id查询到发生丢帧的网页
          if (event) {
            const newUrl = event.url;
            const webId = this.controller.getWebId();
            webIdToUrlMap.set(webId, newUrl);
          }
        })
    }
  }
}
```

### 步骤4：错误处理

```typescript
// 错误处理代码
import { BusinessError } from '@kit.BasicServicesKit';

try {
  const holder = hiAppEvent.addWatcher({
    name: 'webJankWatcher',
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件数据
    }
  });
  
  if (holder === null) {
    hilog.error(0x0000, 'testTag', 'Failed to add watcher');
  }
} catch (error) {
  const err = error as BusinessError;
  hilog.error(0x0000, 'testTag', `Error code: ${err.code}, message: ${err.message}`);
  
  // 根据错误码处理
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Check watcher configuration.');
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', 'Invalid watcher name. Check name format.');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', 'Invalid filtering event domain. Check domain value.');
      break;
    default:
      hilog.error(0x0000, 'testTag', 'Unknown error occurred.');
  }
}
```

### 步骤5：移除观察者（可选）

```typescript
// 移除观察者代码
const watcher: hiAppEvent.Watcher = {
  name: 'webJankWatcher',
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK]
    }
  ]
};

// 添加观察者
hiAppEvent.addWatcher(watcher);

// 在需要时移除观察者
hiAppEvent.removeWatcher(watcher);
hilog.info(0x0000, 'testTag', 'Watcher removed successfully');
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，必填参数未指定或参数类型错误 | 检查watcher配置参数，确保name、domain、names字段正确 |
| 11102001 | 观察者名称无效，包含非法字符或长度不合法 | 检查name字段格式：首字符必须是字母，中间字符必须是数字/字母/下划线，结尾字符必须是数字/字母，长度1-32字符 |
| 11102002 | 事件过滤domain无效，包含非法字符或长度不合法 | 检查domain字段，系统事件使用hiAppEvent.domain.OS常量 |
| 11102003 | row值无效，小于0 | 检查triggerCondition.row字段（此场景不使用） |
| 11102004 | size值无效，小于0 | 检查triggerCondition.size字段（此场景不使用） |
| 11102005 | timeout值无效，小于0 | 检查triggerCondition.timeOut字段（此场景不使用） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "最新版本",
    "@ohos.web.webview": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS API version：>= 11（支持元服务）
- DevEco Studio：>= 3.1
- 开发语言：ArkTS
- 设备类型：支持HarmonyOS的所有设备

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：
- 确保DevEco Studio版本>= 3.1
- 确保工程配置文件中已声明依赖
- 清理项目缓存并重新编译

**问题2：web_webview模块导入失败**
```
Error: Cannot find module '@ohos.web.webview'
```
**解决方法**：
- 确保使用正确的导入路径
- 检查ohos.web.webview模块是否已安装

**问题3：类型定义错误**
```
Error: Property 'getWebId' does not exist on type 'WebviewController'
```
**解决方法**：
- 确保API version >= 11
- 检查WebviewController实例化是否正确

**问题4：回调函数参数类型错误**
```
Error: Type 'AppEventGroup' is not assignable to type 'Array<AppEventGroup>'
```
**解决方法**：
- 检查回调函数参数定义：`appEventGroups: Array<hiAppEvent.AppEventGroup>`
- 确保导入hiAppEvent类型定义

## 常见问题与解决方法

### Q1：事件未触发或无法接收到回调
**原因**：
- Web页面未发生抛滑操作
- 卡顿时长未达到50ms阈值
- 观察者未正确添加或订阅配置错误

**解决方法**：
- 确保Web页面存在抛滑操作（快速滑动）
- 检查观察者配置是否正确（domain和names字段）
- 验证addWatcher是否成功调用（检查返回值是否为null）
- 确保Web组件已加载并正常工作

### Q2：web_id映射到URL失败
**原因**：
- webIdToUrlMap未正确初始化
- Web组件onPageBegin回调未触发
- web_id不存在于映射表中

**解决方法**：
- 确保webIdToUrlMap已定义为全局变量
- 检查Web组件onPageBegin回调是否正确实现
- 确保每次页面跳转都更新映射关系
- 添加容错处理：`const currentUrl = webIdToUrlMap.get(webId) || 'Unknown URL';`

### Q3：回调函数执行阻塞
**原因**：
- 回调函数中执行了耗时操作
- 日志输出过多导致性能下降
- 在回调中执行了同步阻塞代码

**解决方法**：
- 优化回调函数逻辑，避免耗时操作
- 减少不必要的日志输出
- 使用异步处理复杂逻辑
- 避免在回调中使用while循环或sleep

### Q4：观察者名称冲突
**原因**：
- 多次调用addWatcher使用相同name
- name命名不规范导致系统识别失败

**解决方法**：
- 使用唯一的观察者名称（建议添加业务标识）
- 遵循命名规范：首字符字母、中间数字/字母/下划线、结尾数字/字母
- 移除旧观察者后再添加新观察者

### Q5：多个Web组件如何区分丢帧来源
**原因**：
- 应用中包含多个Web组件
- 需要区分不同Web组件的丢帧事件

**解决方法**：
- 每个Web组件有独立的web_id
- 通过webIdToUrlMap查询对应URL
- 根据URL区分不同Web组件的丢帧事件
- 建议为每个Web组件维护独立的映射关系

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "webJankWatcher",
  "eventDomain": "OS",
  "eventName": "SCROLL_ARKWEB_FLING_JANK",
  "subscriptionStatus": "active",
  "lastEventTime": "1765892111768",
  "lastEventDuration": "1554",
  "lastEventWebId": "1",
  "lastEventMaxFrameTime": "195",
  "lastEventUrl": "https://www.baidu.com",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.SCROLL_ARKWEB_FLING_JANK",
    "WebviewController.getWebId"
  ]
}
```

**日志输出示例**：
```
HiAppEvent onReceive: domain=OS
HiAppEvent eventName=SCROLL_ARKWEB_FLING_JANK
HiAppEvent eventInfo.domain=OS
HiAppEvent eventInfo.name=SCROLL_ARKWEB_FLING_JANK
HiAppEvent eventInfo.params.start_time=1765892111768
HiAppEvent eventInfo.params.duration=1554
HiAppEvent eventInfo.params.web_id=1
HiAppEvent eventInfo.params.max_app_frame_time=195
HiAppEvent get currentUrl=https://www.baidu.com
```

## 参考文档

- [API开发指南 - 订阅ArkWeb抛滑丢帧事件](references/hiappevent-watcher-web-fling-jank-events-arkts.md)
- [API参考说明 - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [ArkWeb简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-component-overview)

## 完整示例代码

- [ArkTS示例 - 完整工程实现](assets/complete_example.ets)
- [配置文件示例 - 权限配置](assets/module.json5)
- [路由配置示例 - 页面路由](assets/main_pages.json)

## 测试用例

### 正向测试用例
- [正常订阅并接收丢帧事件](tests/test_positive.ets)：验证事件订阅成功和回调触发
- [web_id映射成功](tests/test_mapping.ets)：验证web_id到URL的正确映射
- [多Web组件场景](tests/test_multi_web.ets)：验证多个Web组件的独立监控

### 边界测试用例
- [最小卡顿阈值50ms](tests/test_threshold.ets)：验证卡顿50ms刚好触发事件
- [观察者名称边界值](tests/test_watcher_name.ets)：验证32字符最大长度和特殊字符
- [大量事件并发](tests/test_concurrent_events.ets)：验证短时间内多个事件触发

### 异常测试用例
- [观察者名称非法](tests/test_invalid_name.ets)：验证非法字符和超长名称的错误处理
- [domain错误](tests/test_invalid_domain.ets)：验证错误domain的错误处理
- [web_id不存在](tests/test_invalid_webid.ets)：验证映射表中不存在web_id的处理
- [回调函数异常](tests/test_callback_exception.ets)：验证回调异常不影响后续事件
- [移除观察者](tests/test_remove_watcher.ets)：验证移除后事件不再触发