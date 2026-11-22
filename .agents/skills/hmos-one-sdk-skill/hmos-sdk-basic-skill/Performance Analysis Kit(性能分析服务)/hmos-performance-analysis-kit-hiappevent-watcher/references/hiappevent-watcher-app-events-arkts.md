# HiAppEvent 事件订阅（ArkTS）开发指南

本文档提供 HiAppEvent 事件订阅功能的完整开发指导。

## 功能概述

HiAppEvent 提供了事件订阅接口，用于获取应用的事件。支持订阅系统事件和应用自定义事件，通过观察者回调实时处理或批量获取事件数据。

## 接口说明

详细的 API 接口使用说明，包括参数使用限制和具体取值范围，请参考 [@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)。

### 订阅接口功能介绍

| 接口名 | 描述 |
| --- | --- |
| addWatcher(watcher: Watcher): AppEventPackageHolder | 添加应用的事件观察者。 |
| removeWatcher(watcher: Watcher): void | 移除应用的事件观察者。 |

**注意事项**：
- addWatcher 接口涉及 I/O 操作。在对性能敏感的业务场景中，开发者应根据实际需要确定该接口是在主线程还是在子线程中调用。
- 如果选择在子线程中调用 addWatcher，需要确保该子线程在整个接口使用周期内不会被销毁，以免影响接口的正常工作。
- 可参考 [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)，以实现在子线程中调用接口。

### 打点接口功能介绍

| 接口名 | 描述 |
| --- | --- |
| write(info: AppEventInfo, callback: AsyncCallback<void>): void | 应用事件异步打点方法，使用 callback 方式作为异步回调。 |
| write(info: AppEventInfo): Promise<void> | 应用事件异步打点方法，使用 Promise 方式作为异步回调。 |

**注意事项**：
- write 接口涉及 I/O 操作，执行时间通常在毫秒级别。因此，开发者应根据实际业务需求，确定该接口是在主线程还是在子线程中调用。
- 可参考 [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)，以实现在子线程中调用接口。

## 事件订阅开发指导

以订阅崩溃事件（系统事件）和按钮点击事件（应用事件）为例，说明开发步骤。

### 步骤1：导入依赖模块

新建一个 ArkTS 应用工程，编辑工程中的 "entry > src > main > ets > entryability > EntryAbility.ets" 文件，导入所需的依赖模块：

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：订阅崩溃事件（OnReceive 模式）

编辑工程中的 "entry > src > main > ets > entryability > EntryAbility.ets" 文件，在 onCreate 函数中添加对崩溃事件的订阅。

订阅崩溃事件，采用 OnReceive 类型观察者的订阅方式，观察者接收到事件后会立即触发 OnReceive() 回调：

```typescript
hiAppEvent.addWatcher({
  name: 'AppCrashWatcher',
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onReceive callback');
    hilog.info(0x0000, 'testTag', `domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'testTag', `time=${JSON.stringify(eventInfo.params['time'])}`);
        hilog.info(0x0000, 'testTag', `bundle_name=${JSON.stringify(eventInfo.params['bundle_name'])}`);
        hilog.info(0x0000, 'testTag', `external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
      }
    }
  }
});
```

### 步骤3：订阅按钮点击事件（OnTrigger 模式）

订阅按钮点击事件，采用 OnTrigger 类型观察者的订阅方式。需满足 triggerCondition 设置的条件，才能触发 OnTrigger() 回调：

```typescript
hiAppEvent.addWatcher({
  name: 'ButtonClickWatcher',
  appEventFilters: [{ domain: 'button' }],
  triggerCondition: { row: 1 },
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'testTag', 'HiAppEvent holder is null');
      return;
    }
    hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onTrigger callback');
    hilog.info(0x0000, 'testTag', `curRow=${curRow}, curSize=${curSize}`);
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'testTag', `packageId=${eventPkg.packageId}`);
      hilog.info(0x0000, 'testTag', `row=${eventPkg.row}`);
      hilog.info(0x0000, 'testTag', `size=${eventPkg.size}`);
      for (const eventInfo of eventPkg.data) {
        hilog.info(0x0000, 'testTag', `info=${eventInfo}`);
      }
    }
  }
});
```

### 步骤4：导入页面依赖模块

编辑工程中的 "entry > src > main > ets > pages > Index.ets" 文件，导入依赖模块：

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤5：触发崩溃事件和按钮点击事件

编辑工程中的 "entry > src > main > ets > pages > Index.ets" 文件，新增按钮触发崩溃事件和按钮点击事件：

**触发崩溃事件**：

```typescript
Button('WatchAppCrash ArkTS&C++')
  .type(ButtonType.Capsule)
  .margin({ top: 20 })
  .backgroundColor('#0D9FFB')
  .width('80%')
  .height('5%')
  .onClick(() => {
    let result: object = JSON.parse('');
  })
```

**按钮点击事件打点**：

```typescript
Button('writeEvent ArkTS')
  .type(ButtonType.Capsule)
  .margin({ top: 20 })
  .backgroundColor('#0D9FFB')
  .width('80%')
  .height('5%')
  .onClick(() => {
    let eventParams: Record<string, number> = {'clickTime': 100};
    let eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'button',
      name: 'click',
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams,
    };
    hiAppEvent.write(eventInfo).then(() => {
      hilog.info(0x0000, 'testTag', `writeEvent success`);
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', `err.code: ${err.code}, err.message: ${err.message}`);
    });
  })
```

## 调测验证

### 验证崩溃事件订阅

1. 点击 DevEco Studio 界面中的运行按钮，运行应用工程。
2. 在应用界面中点击 "WatchAppCrash ArkTS&C++" 按钮，触发崩溃事件。
3. 应用退出后，重新打开应用。
4. 在 HiLog 窗口搜索 "AppEvents" 关键字，查看应用处理崩溃事件数据的日志：

```
AppEvents HiAppEvent success to read event with onReceive callback
AppEvents HiAppEvent eventName=APP_CRASH
AppEvents HiAppEvent eventInfo.params.time=1750747995874
AppEvents HiAppEvent eventInfo.params.bundle_name="com.example.txxxxx"
AppEvents HiAppEvent eventInfo.params.external_log=
["/data/storage/el2/log/hiappevent/APP_CRASH_1750747996042_28962.log"]
```

### 验证按钮点击事件订阅

1. 点击 DevEco Studio 界面中的运行按钮，运行应用工程。
2. 在应用界面中点击 "writeEvent ArkTS" 按钮，触发按钮点击事件并打点。
3. 在 HiLog 窗口搜索 "AppEvents" 关键字，查看应用处理按钮点击事件数据的日志：

```
AppEvents HiAppEvent success to read event with onTrigger callback
AppEvents HiAppEvent onTrigger: curRow=1, curSize=121
AppEvents HiAppEvent eventPkg.packageId=0
AppEvents HiAppEvent eventPkg.row=1
AppEvents HiAppEvent eventPkg.size=121
AppEvents HiAppEvent eventPkg.info={"domain_":"button","name_":"click","type_":4,"time_":1750754529033,"tz_":"","pid_":40664,"tid_":40664,"clickTime":100}
AppEvents writeEvent success
```

## 相关文档

- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)