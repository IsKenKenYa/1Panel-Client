# API迁移指南

## 从FaultLogger迁移到HiAppEvent

### 概述

[@ohos.faultLogger](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-faultlogger) 接口从API version 18开始废弃使用，不再维护。后续版本推荐使用 [@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent) 订阅崩溃事件。

### 崩溃类型对应关系

| FaultLogger.FaultType | hiAppEvent.AppEventInfo.params.crash_type |
| --- | --- |
| CPP_CRASH | NativeCrash |
| JS_CRASH | JsError |

### 接口对应关系

| FaultLogger接口 | HiAppEvent接口 | 说明 |
| --- | --- | --- |
| FaultLogger.query(callback) | hiAppEvent.addWatcher + onReceive | 查询崩溃日志 |
| FaultLogger.query(promise) | hiAppEvent.addWatcher + onReceive | 查询崩溃日志 |

### 数据字段对应关系

| Faultlogger.FaultLogInfo | hiAppEvent.AppEventInfo.params | 说明 |
| --- | --- | --- |
| pid | pid | 进程ID |
| uid | uid | 用户ID |
| type | crash_type | 类型不同，Faultlogger中是故障类型枚举，hiAppEvent中是字符串类型 |
| timestamp | time | 时间戳 |
| module | bundle_name | 包名 |
| fullLog | external_log | fullLog为故障日志全文。external_log为故障日志文件应用沙箱路径，访问该路径的文件，可以得到故障日志全文 |
| reason | external_log文件内容中的Reason字段 | 崩溃原因 |
| summary | external_log文件内容中的一部分 | CPP_CRASH对应Fault thread info字段；JS_CRASH对应Error name、Error message、Stacktrace、HybridStack字段 |

### 迁移示例代码

**FaultLogger旧接口（已废弃）**：
```typescript
import faultLogger from '@ohos.faultLogger';

// 使用callback方式查询
faultLogger.query(faultLogger.FaultType.JS_CRASH, (err, data) => {
  if (err) {
    console.error('query failed, error:', err);
    return;
  }
  console.log('query success, data:', JSON.stringify(data));
});

// 使用promise方式查询
faultLogger.query(faultLogger.FaultType.JS_CRASH).then(data => {
  console.log('query success, data:', JSON.stringify(data));
}).catch(err => {
  console.error('query failed, error:', err);
});
```

**HiAppEvent新接口（推荐）**：
```typescript
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';

// 使用观察者方式订阅
const watcher = {
  name: 'crashWatcher',
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  onReceive: (domain, appEventGroups) => {
    for (const eventGroup of appEventGroups) {
      for (const eventInfo of eventGroup.appEventInfos) {
        const params = eventInfo.params;
        console.log('crash_type:', params['crash_type']);
        console.log('pid:', params['pid']);
        console.log('uid:', params['uid']);
        console.log('time:', params['time']);
        console.log('bundle_name:', params['bundle_name']);
        console.log('external_log:', params['external_log']);
      }
    }
  }
};

hiAppEvent.addWatcher(watcher);
```

### 迁移注意事项

1. **订阅方式变化**：FaultLogger使用query主动查询，HiAppEvent使用addWatcher订阅回调
2. **崩溃类型名称变化**：CPP_CRASH改为NativeCrash，JS_CRASH改为JsError
3. **日志获取方式变化**：fullLog字段改为external_log文件路径，需要访问文件获取全文
4. **API版本要求**：HiAppEvent从API version 9开始支持，FaultLogger已废弃
5. **回调时机**：HiAppEvent崩溃事件在采集完成后异步回调，不阻塞业务
6. **自定义参数**：HiAppEvent支持设置自定义崩溃参数（setEventParam）

### 高级功能对比

| 功能 | FaultLogger | HiAppEvent | API版本 |
| --- | --- | --- | --- |
| 订阅崩溃事件 | query | addWatcher + onReceive | API 9+ |
| 设置自定义参数 | 不支持 | setEventParam | API 9+ |
| 配置崩溃日志规格 | 不支持 | setEventConfig | API 20+ |
| 配置页面切换日志 | 不支持 | configEventPolicy | API 24+ |
| 区分崩溃类型 | FaultType枚举 | crash_type字符串 | API 9+ |

### 推荐迁移路径

1. **基础迁移**：将FaultLogger.query替换为hiAppEvent.addWatcher
2. **参数优化**：使用setEventParam添加自定义崩溃参数
3. **日志增强**：使用setEventConfig配置崩溃日志规格（API 20+）
4. **场景扩展**：使用configEventPolicy配置页面切换日志（API 24+）
5. **数据处理**：适配新的数据字段结构（crash_type、external_log等）