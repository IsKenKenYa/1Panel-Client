---
name: hmos-remote-communication-kit-pause-resume
description: 实现HTTP请求的暂停、恢复与断点续传功能,支持发送暂停、接收暂停和基于TransferRange的断点续传,适用于大文件上传下载、网络不稳定场景,最大支持1024个session实例
---

# 实现请求暂停、恢复与断点续传技能

## 功能描述

本技能提供HTTP请求的暂停、恢复与断点续传完整解决方案,基于Remote Communication Kit的rcp模块实现。核心功能包括:

1. **请求暂停与恢复**: 支持发送暂停(SendingPausePolicy)和接收暂停(ReceivingPausePolicy),通过timeout策略控制暂停时机
2. **断点续传**: 通过TransferRange设置数据传输范围,支持分段下载和续传功能
3. **调试信息追踪**: 通过DebugInfo追踪暂停和恢复事件,便于问题排查
4. **会话管理**: 支持最多1024个session实例并发管理

**技术特点**:
- 使用Promise异步回调模式
- 支持GET/POST等多种HTTP方法
- 提供完整的错误处理和降级方案
- 自动记录传输位置,支持中断后继续传输

## 使用场景

### 触发词
- "暂停HTTP请求"
- "恢复HTTP请求"
- "断点续传"
- "暂停下载"
- "继续下载"
- "分段下载"
- "网络不稳定下载"
- "大文件上传暂停"
- "大文件下载暂停"
- "请求暂停恢复"

### 能做
- 实现HTTP请求的发送暂停功能(通过timeout策略)
- 实现HTTP请求的接收暂停功能(通过timeout或cacheSize策略)
- 实现基于TransferRange的断点续传下载
- 实现请求的取消和恢复功能
- 记录传输位置并支持续传
- 提供调试信息追踪暂停/恢复事件
- 支持分段下载大文件
- 处理网络不稳定导致的传输中断

### 绝不做
- 不支持WebSocket协议的暂停恢复
- 不处理非HTTP协议的请求(如FTP)
- 不提供文件完整性校验功能(MD5/SHA)
- 不处理服务器不支持Range请求的情况
- 不支持跨session的续传功能
- 不处理超过1024个session实例的情况

### 补充
- 设备支持: Phone、2in1、Tablet、Wearable;TV设备从API 5.1.1(19)开始支持;Car设备从API 6.1.0(23)开始支持
- Session实例限制: 最大1024个并发session(API 5.1.0(18)及以上),使用后需及时关闭
- 权限要求: 需要ohos.permission.INTERNET权限;使用cellular模式需额外ohos.permission.GET_NETWORK_INFO权限
- TransferRange依赖服务器支持HTTP Range请求(需服务器返回206 Partial Content状态码)
- 建议文件大小超过50MB时使用分段下载,避免内存溢出

## 调用规范和规则

### 输入约束
- 文件大小: 最大单个文件不超过系统限制(默认响应体最大50MB)
- Session数量: 最大1024个并发session实例(API 5.1.0(18)+)
- PausePolicy timeout: timeoutMs必须为正整数,单位毫秒
- TransferRange范围: from和to必须为有效字节位置,to >= from
- URL格式: 必须为有效HTTP/HTTPS URL
- 请求方法: 支持GET、POST、HEAD、PUT、DELETE、PATCH等标准HTTP方法

### 执行约束
- 最大耗时: timeout策略的timeoutMs决定暂停时机
- 最大迭代次数: 断点续传建议单次传输不超过100字节(示例中),可根据实际调整
- Session管理: 使用完毕后必须调用session.close()释放资源
- 并发限制: 同一应用最多1024个session实例同时存在
- 传输位置记录: 必须准确记录lastTransferPosition以确保续传正确性

### 内容约束
- 禁止生成: 不生成不存在的API接口
- 禁止使用高危函数: 不使用eval、exec等高危函数
- 禁止操作: 不在未关闭session的情况下创建新session超过限制
- 调试信息: 禁止修改DebugInfo数据结构
- TransferRange: 禁止设置超出文件实际大小的范围

### 降级约束
- 网络失败: 捕获BusinessError,记录错误码和消息,提供重试机制
- Session创建失败: 错误码1007900994时,提示关闭其他session后再试
- 文件过大: 超过50MB时使用分段下载或stream方式处理
- 权限不足: 提示用户申请ohos.permission.INTERNET权限
- 服务器不支持Range: 改用完整下载或其他方案

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 验证URL格式是否正确(HTTP/HTTPS)
2. 检查ohos.permission.INTERNET权限是否已申请
3. 确认session实例数量未超过1024个限制
4. 验证TransferRange范围是否有效(from <= to)

**参数准备**:
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

const HTTP_SERVER_POST: string = 'https://example.org/anything';
const HTTP_SERVER_DOWNLOAD: string = 'http://www.example.com/fetch';
```

### 步骤2: 实现请求暂停与恢复

**场景一: 发送暂停策略(timeout模式)**

```typescript
const SendingPauseByTimeout = async (done: Function): Promise<void> => {
  const session = rcp.createSession();
  const request = new rcp.Request(HTTP_SERVER_POST);
  
  const sendPolicy: rcp.SendingPausePolicy = {
    kind: 'timeout',
    timeoutMs: 1,
  };
  
  const pausePolicy: rcp.PausePolicy = {
    sending: sendPolicy,
  };
  
  request.configuration = {
    transfer: {
      pausePolicy: pausePolicy,
    },
    tracing: {
      infoToCollect: {
        textual: true,
      },
    },
  };
  
  const data = 'TestData';
  request.headers = {
    'Content-Length': data.length.toString(),
  };
  
  let isReadCompleted = false;
  request.method = 'POST';
  
  request.content = (maxSize) => {
    if (isReadCompleted) {
      return new ArrayBuffer(0);
    }
    isReadCompleted = true;
    const buffer = new ArrayBuffer(data.length);
    util.TextEncoder.create('utf-8').encodeIntoUint8Array(data, new Uint8Array(buffer));
    return buffer;
  };
  
  const response = await session.fetch(request);
  
  const pausedEvents = getSendPausedEvents(response);
  const resumedEvents = getSendResumedEvents(response);
  
  session.close();
  done();
}

function getSendPausedEvents(debugInfo: rcp.DebugInfo[] | rcp.Response): StringifiedDebugInfo[] {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Pause sending'));
}

function getSendResumedEvents(debugInfo: rcp.DebugInfo[] | rcp.Response): StringifiedDebugInfo[] {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Resume sending'));
}
```

**调试信息处理函数**:
```typescript
interface StringifiedDebugInfo {
  type: rcp.DebugEvent;
  data: string;
};

type DebugInfoSource = undefined | rcp.DebugInfo[] | rcp.Response;

function debugInfoStringify(infoSource: DebugInfoSource): StringifiedDebugInfo[] {
  const debugInfo = Array.isArray(infoSource)
    ? (infoSource as rcp.DebugInfo[])
    : (infoSource as rcp.Response).debugInfo;
  if (!debugInfo) {
    return [];
  }
  const decoder = util.TextDecoder.create('utf-8');
  return debugInfo.map((i: rcp.DebugInfo): StringifiedDebugInfo => {
    return {
      type: i.type,
      data: decoder.decodeToString(new Uint8Array(i.data)).trim(),
    };
  });
}
```

### 步骤3: 实现断点续传下载

**初始化变量**:
```typescript
let session: rcp.Session | null = rcp.createSession();
const kHttpServerAddress = 'http://www.example.com/fetch';
const request = new rcp.Request(kHttpServerAddress, 'GET');
let totalSize = 0;
let lastTransferPosition = 0;
```

**获取文件总大小**:
```typescript
async function getTotalSize(): Promise<number> {
  request.transferRange = { from: 0, to: 1 };
  try {
    let rep = await session?.fetch(request);
    if (rep) {
      let contentRange = rep.headers['content-range'];
      let sizeStr = contentRange ? contentRange.substring(contentRange.indexOf('/') + 1, contentRange.length) : '0';
      totalSize = Number(sizeStr);
    }
  } catch (err) {
    console.error(`getTotalSize error code is ${err.code}, error data is ${err.data}`);
  }
  console.info(`getTotalSize totalSize: ${totalSize.toString()}`);
  return totalSize;
}
```

**分段下载函数**:
```typescript
function downloadTransfer(from: number, to: number) {
  request.transferRange = { from: from, to: to };
  session?.fetch(request).then((rep) => {
    if (rep.body) {
      console.info(`Response succeeded: ${JSON.stringify(rep.headers)}`);
      lastTransferPosition += rep.body.byteLength;
      if (lastTransferPosition < totalSize) {
        const nextTo = Math.min(lastTransferPosition + 100, totalSize);
        downloadTransfer(lastTransferPosition, nextTo);
      } else {
        console.info('Response succeeded, completed.');
      }
    }
  }).catch((err: BusinessError) => {
    console.error(`Continue transfer error: code is ${err.code}, message is ${err.message}`);
  });
}
```

**开始下载**:
```typescript
async function startDownload() {
  if (!session) {
    session = rcp.createSession();
  }
  lastTransferPosition = 0;
  totalSize = await getTotalSize();
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  downloadTransfer(lastTransferPosition, nextTo);
}
```

**暂停下载**:
```typescript
function pauseDownload() {
  session?.cancel(request);
}
```

**继续下载**:
```typescript
function resumeDownload() {
  const nextTo = Math.min(lastTransferPosition + 100, totalSize);
  downloadTransfer(lastTransferPosition, nextTo);
}
```

**停止下载**:
```typescript
function stopDownload() {
  session?.cancel(request);
  session?.close();
  session = null;
}
```

### 步骤4: 错误处理

```typescript
try {
  await session.fetch(request);
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('Parameter error: check request parameters');
      break;
    case 1007900994:
      console.error('Sessions number reached limit: close other sessions first');
      session?.close();
      break;
    default:
      console.error(`Unknown error: code ${err.code}, message ${err.message}`);
      if (lastTransferPosition > 0) {
        console.info(`Transfer paused at position: ${lastTransferPosition}, can resume later`);
      }
  }
}
```

### 步骤5: 降级处理

```typescript
async function fallbackDownload(url: string): Promise<void> {
  try {
    if (!session) {
      session = rcp.createSession();
    }
    const simpleRequest = new rcp.Request(url, 'GET');
    const response = await session.fetch(simpleRequest);
    if (response.body) {
      console.info('Fallback: downloaded without range support');
    }
  } catch (error) {
    console.warn('Fallback failed: server may not support any download method');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误,如TransferRange范围无效 | 检查from/to参数,确保from <= to且为有效数字 |
| 1007900994 | Session数量达到上限(1024个) | 关闭其他未使用的session后再创建新session |
| 网络错误 | 网络连接失败或超时 | 检查网络连接,增加timeout配置,或使用重试机制 |
| 服务器错误 | 服务器不支持Range请求(返回200而非206) | 改用完整下载方式,或联系服务器管理员 |
| 权限错误 | 缺少ohos.permission.INTERNET权限 | 在module.json5中申请ohos.permission.INTERNET权限 |
| 内存溢出 | 下载文件超过50MB导致内存溢出 | 使用分段下载或stream方式处理大文件 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.ArkTS": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS API版本: 4.1.0(11)及以上
- Device支持: Phone、2in1、Tablet、Wearable(全部版本);TV(5.1.1(19)+);Car(6.1.0(23)+)
- DevEco Studio: 4.0及以上
- ArkTS编译器: 支持ES2017+语法

### 常见编译问题

**问题1: 导入错误 - Cannot find module '@kit.RemoteCommunicationKit'**
```
Error: Module '@kit.RemoteCommunicationKit' not found
```
**解决方法**: 
- 确认HarmonyOS API版本 >= 4.1.0(11)
- 在oh-package.json5中添加依赖声明
- 运行ohpm install安装依赖

**问题2: Session创建失败 - 1007900994错误码**
```
Error: Sessions number reached limit (1007900994)
```
**解决方法**:
- 检查代码中是否未关闭session
- 在session使用完毕后立即调用session.close()
- 减少并发session数量,低于1024个限制

**问题3: TransferRange参数错误 - 401错误码**
```
Error: Parameter error (401)
```
**解决方法**:
- 验证from和to参数是否为有效数字
- 确保from <= to
- 检查范围是否超出文件实际大小

**问题4: 权限缺失错误**
```
Error: Permission denied
```
**解决方法**:
- 在module.json5的requestPermissions中添加:
```json
{
  "name": "ohos.permission.INTERNET",
  "reason": "$string:internet_permission_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

## 常见问题与解决方法

### Q1: 如何判断服务器是否支持Range请求?
**原因**: 不是所有服务器都支持HTTP Range请求头
**解决方法**:
- 先发送一个小范围请求(如from:0, to:1)
- 检查响应状态码是否为206 Partial Content
- 检查响应头是否包含Content-Range字段
- 如果状态码为200且无Content-Range,说明不支持,需改用完整下载

### Q2: 暂停后如何准确恢复传输位置?
**原因**: 需要准确记录已传输的字节数
**解决方法**:
- 使用lastTransferPosition变量记录位置
- 每次传输成功后更新:lastTransferPosition += rep.body.byteLength
- 暂停时保持lastTransferPosition不变
- 恢复时从lastTransferPosition开始: downloadTransfer(lastTransferPosition, nextTo)

### Q3: 大文件下载导致内存溢出怎么办?
**原因**: 默认响应体最大50MB,超过会内存溢出
**解决方法**:
- 使用分段下载,每次传输小块数据(如100字节或更大)
- 使用INetworkOutputQueue流式处理响应体
- 使用DownloadToFile直接下载到文件,不占用内存
- 使用DownloadToStream写入流中

### Q4: timeoutMs设置为多少合适?
**原因**: timeoutMs太小可能导致频繁暂停,太大可能导致长时间等待
**解决方法**:
- 发送暂停: 根据应用提供数据的速度设置,示例中使用1ms仅为演示
- 接收暂停: 根据网络环境和应用处理数据的速度设置
- 建议: 网络稳定时设置较大值(如5000ms),网络不稳定时设置较小值(如1000ms)
- 实际应用中应根据具体场景测试调整

### Q5: 如何处理网络中断导致的下载失败?
**原因**: 网络不稳定可能导致请求失败
**解决方法**:
- 使用try-catch捕获BusinessError
- 记录lastTransferPosition位置
- 提供重试机制,等待网络恢复后从上次位置继续
- 设置合理的timeout配置
- 使用session.cancel()主动暂停,而非依赖网络中断

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success|failed",
  "transferredBytes": "已传输的字节数",
  "totalBytes": "文件总大小",
  "lastPosition": "上次传输位置(用于续传)",
  "pausedEvents": "发送暂停事件数量",
  "resumedEvents": "发送恢复事件数量",
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "rcp.Session.fetch",
    "rcp.Session.cancel",
    "rcp.Session.close",
    "rcp.PausePolicy",
    "rcp.SendingPausePolicy",
    "rcp.TransferRange",
    "rcp.DebugInfo"
  ],
  "errors": "遇到的错误列表(如有)"
}
```

## 参考文档

- [API开发指南 - 实现请求暂停、恢复与断点续传](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-pauseresume)
- [API参考说明 - rcp模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 完整示例代码

- [请求暂停恢复示例](assets/pause_resume_example.ets)
- [断点续传下载示例](assets/resumable_download_example.ets)
- [完整实现示例](assets/complete_example.ets)

## 测试用例

### 正向测试用例
- [测试发送暂停策略](tests/test_send_pause.ets): 验证timeout策略能正确触发发送暂停
- [测试断点续传下载](tests/test_resumable_download.ets): 验证分段下载和续传功能
- [测试暂停恢复流程](tests/test_pause_resume_flow.ets): 验证完整的暂停-恢复-续传流程

### 边界测试用例
- [测试TransferRange边界值](tests/test_transfer_range_boundary.ets): 测试from=0、to=文件大小等边界情况
- [测试Session数量限制](tests/test_session_limit.ets): 测试1024个session限制
- [测试大文件分段下载](tests/test_large_file_download.ets): 测试超过50MB文件的分段下载

### 异常测试用例
- [测试无效URL](tests/test_invalid_url.ets): 测试URL格式错误的处理
- [测试服务器不支持Range](tests/test_no_range_support.ets): 测试服务器不支持Range请求的降级方案
- [测试网络中断恢复](tests/test_network_interruption.ets): 测试网络中断后的续传功能
- [测试权限缺失](tests/test_permission_missing.ets): 测试缺少INTERNET权限的错误处理