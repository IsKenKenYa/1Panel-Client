---
name: hmos-remote-communication-kit-sync-stream-req
description: 实现HTTP流式传输，支持基于缓冲区的同步读写队列和基于回调函数的流式传输，适用于大文件上传下载、直播、实时数据更新等场景，支持Phone/2in1/Tablet/Wearable设备，API版本5.0.0(12)以上
---

# HTTP流式传输技能

## 功能描述

HTTP流式传输（Streaming）允许客户端与服务器之间以流的形式进行数据交互，无需等待所有数据准备完毕即可开始传输，显著提升用户体验。该技能提供两种流式传输方式：

1. **基于缓冲区的流式传输**：使用`rcp.NetworkInputQueue`和`rcp.NetworkOutputQueue`创建同步读写队列，实现数据的同步写入和读取
2. **基于回调函数的流式传输**：使用`uploadFromStream`和`downloadToStream`接口，通过自定义流对象实现数据的上传和下载

主要功能：
- 同步写队列上传数据：数据写入队列的同时同步进行上传
- 同步读队列下载数据：响应数据暂存队列，按需循环读取
- 从流中上传数据：实现自定义ReadStream接口，从文件流中读取数据并上传
- 下载到流中：实现自定义WriteStream接口，将下载数据写入文件流

适用场景：大文件上传下载、直播、实时数据更新、文件分片传输等。

## 使用场景

### 触发词
- "流式传输"
- "流式上传"
- "流式下载"
- "同步队列上传"
- "同步队列下载"
- "大文件上传"
- "大文件下载"
- "实时数据传输"
- "HTTP streaming"

### 能做
- 实现基于缓冲区的同步写队列上传（NetworkInputQueue）
- 实现基于缓冲区的同步读队列下载（NetworkOutputQueue）
- 实现基于回调函数的流式上传（uploadFromStream）
- 实现基于回调函数的流式下载（downloadToStream）
- 支持大文件分片上传和下载
- 支持实时数据流传输
- 支持自定义读写流实现

### 绝不做
- 不处理非HTTP协议的流式传输
- 不处理超过内存限制的超大文件（需分片处理）
- 不替代完整的文件上传下载API（仅适用于流式场景）
- 不处理非Stream类型的请求内容

### 补充
- 流式传输能力支持Phone、2in1、Tablet、Wearable设备
- 从5.1.1(19)开始，新增支持TV设备
- 从6.1.0(23)开始，新增支持Car设备
- 需要导入`@kit.RemoteCommunicationKit`和`@kit.BasicServicesKit`模块
- 需要申请`ohos.permission.INTERNET`权限
- Session实例最大支持1024个（5.1.0(18)版本起）

## 调用规范和规则

### 输入约束
- 文件大小：无固定限制，但建议分片处理超大文件（>100MB）
- 文件格式：任意二进制或文本文件
- 队列大小：NetworkInputQueue/NetworkOutputQueue可选参数maxSize，默认动态调整
- URL格式：必须是有效的HTTP/HTTPS URL
- 流对象：必须实现正确的ReadStream/WriteStream接口

### 执行约束
- 最大耗时：根据网络状况和数据大小动态调整
- 最大迭代次数：数据分片读取循环次数不超过10000次
- API调用频次：受Session实例限制（最大1024个）
- 队列暂停策略：支持超时策略和缓存大小策略

### 内容约束
- 禁止生成：非流式传输相关的代码
- 禁止使用高危函数：eval、exec、系统命令调用
- 禁止操作：直接操作文件系统（需通过fileIo API）
- 必须校验：Session创建、文件打开、流对象实现

### 降级约束
- 网络失败：提供重试机制和错误提示
- 文件过大：建议分片处理或使用downloadToFile/uploadFromFile
- 权限不足：提示申请ohos.permission.INTERNET权限
- Session数量超限：提示关闭已完成的Session
- 流对象实现错误：提供标准实现模板

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否导入必要模块：`@kit.RemoteCommunicationKit`、`@kit.BasicServicesKit`、`@kit.CoreFileKit`
2. 检查是否申请必要权限：`ohos.permission.INTERNET`
3. 检查URL是否有效（HTTP/HTTPS协议）
4. 检查文件路径是否存在（文件上传/下载场景）

**参数准备**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const session = rcp.createSession();
const url = 'https://example.com/api';
const filePath = '/path/to/file';
```

### 步骤2：基于缓冲区的流式传输 - 同步写队列上传

**示例代码**：
```typescript
export const testNetworkInputQueue = () => {
  const networkInputQueue = new rcp.NetworkInputQueue();
  
  let counter = 0;
  const interval = setInterval(() => {
    networkInputQueue.write('a counter ' + counter++);
    console.info(`networkInputQueue write`);
    
    if (counter === 10) {
      clearInterval(interval);
      networkInputQueue.close();
    }
  }, 1000);
  
  try {
    const session = rcp.createSession();
    console.info(`Post start.`);
    
    session.post('https://httpbin.org/anything', networkInputQueue).then((response) => {
      console.info(`Response status code is: ${response.statusCode}`);
      if (response && response.statusCode === 200) {
        console.info(`Post succeeded! response: ${response.toString()}`);
      } else {
        console.error(`Post failed.`);
      }
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Post error code is ${err.code}, error data is ${err.data}`);
      session.close();
    });
  } catch (err) {
    console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  }
}
```

### 步骤3：基于缓冲区的流式传输 - 同步读队列下载

**示例代码**：
```typescript
export const testNetworkOutputQueue = () => {
  const networkOutputQueue = new rcp.NetworkOutputQueue();
  
  try {
    const session = rcp.createSession();
    const numOfChunks = 10;
    const chunkLength = 1000;
    const totalBytes = numOfChunks * chunkLength;
    
    session.get('https://httpbin.org/bytes/' + totalBytes.toString(), networkOutputQueue).then((response) => {
      if (response && response.statusCode === 200) {
        console.info(`get bytes succeeded.`);
      } else {
        console.error(`get bytes failed.`);
      }
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`get bytes error code is ${err.code}, error data is ${err.data}`);
      session.close();
    });
    
    let totalGetLength = 0;
    const intervalId = setInterval(() => {
      const chunk = networkOutputQueue.read(chunkLength);
      totalGetLength += chunk.byteLength;
      console.info(`get bytes totalGetLength: ${totalGetLength}`);
      
      if (totalGetLength === totalBytes) {
        clearInterval(intervalId);
        console.info(`get bytes finished.`);
      }
    }, 1000);
  } catch (err) {
    console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  }
}
```

### 步骤4：基于回调函数的流式传输 - 从流中上传

**定义ReadStream实现**：
```typescript
class FdReadStream implements rcp.ReadStream {
  readonly fd: number;
  constructor(fd: number) {
    this.fd = fd;
  }
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  }
}
```

**上传示例代码**：
```typescript
export function testUploadFromStream(uploadFilePath: string) {
  try {
    const session = rcp.createSession();
    const file = fileIo.openSync(uploadFilePath, fileIo.OpenMode.READ_ONLY);
    const fileStream = new rcp.UploadFromStream(new FdReadStream(file.fd));
    
    session.uploadFromStream('https://httpbin.org/anything', fileStream).then((resp) => {
      console.info(`testUploadFromStream response: ${JSON.stringify(resp)}`);
      if (resp && resp.statusCode === 200) {
        console.info(`testUploadFromStream succeeded.`);
      } else {
        console.error(`testUploadFromStream failed.`);
      }
      fileIo.closeSync(file.fd);
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`testUploadFromStream error code is ${err.code}, error data is ${err.data}`);
      fileIo.closeSync(file.fd);
      session.close();
    });
  } catch (err) {
    console.error(`testUploadFromStream error code is ${err.code}, error data is ${err.data}`);
  }
}
```

### 步骤5：基于回调函数的流式传输 - 下载到流

**定义WriteStream实现**：
```typescript
class FdWriteStream implements rcp.WriteStream {
  readonly fd: number;
  constructor(fd: number) {
    this.fd = fd;
  }
  async write(buffer: ArrayBuffer): Promise<number | void> {
    return fileIo.write(this.fd, buffer);
  }
}
```

**下载示例代码**：
```typescript
export function testDownloadToStream(downloadToPath: string) {
  try {
    const session = rcp.createSession();
    const file = fileIo.openSync(downloadToPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    const fileStream = { kind: 'stream', stream: new FdWriteStream(file.fd) } as rcp.DownloadToStream;
    
    session.downloadToStream('https://httpbin.org/bytes/10000', fileStream)
      .then((resp) => {
        console.info(`testDownloadToStream response: ${JSON.stringify(resp)}`);
        if (resp && resp.statusCode === 200) {
          console.info(`testDownloadToStream succeeded.`);
        } else {
          console.error(`testDownloadToStream failed.`);
        }
        fileIo.close(file.fd);
        session.close();
      })
      .catch((err: BusinessError) => {
        console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
        fileIo.close(file.fd);
        session.close();
      });
  } catch (err) {
    console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
  }
}
```

### 步骤6：错误处理

```typescript
try {
  await session.post(url, networkInputQueue);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Please check input parameters.');
      break;
    case 1007900994:
      console.error('Sessions number reached limit (max 1024). Close unused sessions.');
      break;
    case 1007900001:
      console.error('Network error. Check network connection.');
      break;
    case 1007900002:
      console.error('Permission denied. Request ohos.permission.INTERNET.');
      break;
    default:
      console.error(`Unknown error: code ${error.code}, message ${error.message}`);
  }
  session.close();
}
```

### 步骤7：降级处理

```typescript
async function fallbackUpload(filePath: string, url: string): Promise<void> {
  try {
    const session = rcp.createSession();
    const uploadFromFile: rcp.UploadFromFile = {
      fileOrPath: filePath
    };
    
    await session.uploadFromFile(url, uploadFromFile);
    console.warn('Fallback to uploadFromFile succeeded.');
    session.close();
  } catch (error) {
    console.error('Fallback upload failed. Manual intervention required.');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，输入参数不符合要求 | 检查URL、队列对象、流对象等参数是否正确 |
| 1007900994 | Session数量达到上限（1024个） | 关闭已完成的Session，释放资源 |
| 1007900001 | 网络错误，连接失败 | 检查网络连接，重试请求 |
| 1007900002 | 权限不足，缺少INTERNET权限 | 在module.json5中申请ohos.permission.INTERNET权限 |
| 1007900003 | URL格式错误 | 检查URL是否为有效的HTTP/HTTPS地址 |
| 1007900004 | 文件操作失败 | 检查文件路径、权限、是否存在 |
| 1007900005 | 流对象实现错误 | 检查ReadStream/WriteStream接口实现是否正确 |
| 1007900006 | 队列操作失败 | 检查队列是否已关闭或已满 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0",
    "@kit.CoreFileKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低版本5.0.0(12)
- DevEco Studio：最低版本3.1
- ArkTS语言支持：ES2015+

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：在module.json5中添加依赖配置，确保SDK版本>=5.0.0(12)

**问题2：权限错误**
```
Error: Permission denied for ohos.permission.INTERNET
```
**解决方法**：在module.json5中声明权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**问题3：Session数量超限**
```
Error: Sessions number reached limit (1007900994)
```
**解决方法**：及时关闭已完成的Session：
```typescript
session.close();
```

**问题4：流接口实现错误**
```
Error: Property 'read' is missing in type 'FdReadStream'
```
**解决方法**：正确实现ReadStream/WriteStream接口的所有方法

## 常见问题与解决方法

### Q1：如何选择流式传输方式？
**原因**：两种方式各有优劣，需根据场景选择
**解决方法**：
- 基于缓冲区的同步队列：适用于实时数据流、数据分片明确的场景
- 基于回调函数的流：适用于文件上传下载、需要自定义流处理的场景

### Q2：队列读取时数据不完整？
**原因**：读取时机不当或队列未及时关闭
**解决方法**：
- 使用setInterval定期检查队列数据
- 在数据读取完成后清除interval
- 确保队列在数据传输完成后正确关闭

### Q3：上传/下载速度慢？
**原因**：网络带宽限制或分片大小不合理
**解决方法**：
- 调整分片大小（chunkLength）
- 使用暂停策略控制缓存大小
- 检查网络连接质量

### Q4：内存占用过高？
**原因**：队列缓存过大或未及时释放
**解决方法**：
- 设置maxSize限制队列大小
- 使用ReceivingPausePolicy控制缓存
- 及时关闭Session和队列

### Q5：文件上传后服务器接收不到完整数据？
**原因**：流对象实现错误或文件未正确关闭
**解决方法**：
- 确保FdReadStream正确实现read方法
- 确保文件在传输完成后正确关闭
- 检查服务器端接收逻辑

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "method": "sync_stream_request",
  "uploadType": "networkInputQueue | uploadFromStream",
  "downloadType": "networkOutputQueue | downloadToStream",
  "dataSize": "传输数据大小（字节）",
  "statusCode": "HTTP响应状态码",
  "sessionClosed": true,
  "apiUsed": [
    "rcp.createSession",
    "rcp.NetworkInputQueue",
    "rcp.NetworkOutputQueue",
    "session.post",
    "session.get",
    "session.uploadFromStream",
    "session.downloadToStream",
    "fileIo.openSync",
    "fileIo.closeSync"
  ]
}
```

## 参考文档

- [流式传输开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-syncstreamreq)
- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)

## 完整示例代码

- [基于缓冲区的流式上传示例](assets/network_input_queue_example.ets)
- [基于缓冲区的流式下载示例](assets/network_output_queue_example.ets)
- [基于回调函数的流式上传示例](assets/upload_from_stream_example.ets)
- [基于回调函数的流式下载示例](assets/download_to_stream_example.ets)

## 测试用例

### 正向测试用例
- [同步写队列上传测试](tests/test_network_input_queue_positive.ets)：验证数据正确上传
- [同步读队列下载测试](tests/test_network_output_queue_positive.ets)：验证数据正确下载
- [流式上传测试](tests/test_upload_from_stream_positive.ets)：验证文件流正确上传
- [流式下载测试](tests/test_download_to_stream_positive.ets)：验证文件流正确下载

### 边界测试用例
- [大文件上传测试](tests/test_large_file_upload.ets)：验证大文件分片上传
- [队列大小限制测试](tests/test_queue_size_limit.ets)：验证maxSize参数生效
- [超时策略测试](tests/test_timeout_policy.ets)：验证暂停策略生效

### 异常测试用例
- [网络异常测试](tests/test_network_error.ets)：验证网络错误处理
- [文件不存在测试](tests/test_file_not_exist.ets)：验证文件路径错误处理
- [权限不足测试](tests/test_permission_denied.ets)：验证权限错误处理
- [Session超限测试](tests/test_session_limit.ets)：验证Session数量限制处理