---
name: hmos-remote-communication-kit-sync-stream-request
description: 实现HTTP流式传输，支持基于缓冲区的同步读写队列和基于回调函数的流式传输，适用于大文件上传下载、直播、实时数据更新场景，支持Phone/Tablet/Wearable设备，从API 5.0.0(12)开始支持
---

# HTTP流式传输技能

## 功能描述

本技能实现HTTP流式传输功能，允许客户端与服务器之间以流的形式进行数据交互，无需等待所有数据准备完毕。支持两种流式传输方式：

1. **基于缓冲区的流式传输**：使用`rcp.NetworkInputQueue`创建同步写队列实现数据上传，使用`rcp.NetworkOutputQueue`创建同步读队列实现数据下载
2. **基于回调函数的流式传输**：使用`uploadFromStream`接口从流中上传数据，使用`downloadToStream`接口下载数据到流中

适用场景：大文件上传下载、直播、实时数据更新等需要流式数据交互的场景。

## 使用场景

### 触发词
- "HTTP流式传输"
- "流式上传"
- "流式下载"
- "大文件上传"
- "大文件下载"
- "实时数据传输"
- "直播数据传输"
- "NetworkInputQueue"
- "NetworkOutputQueue"
- "uploadFromStream"
- "downloadToStream"

### 能做
- 创建同步写队列(`rcp.NetworkInputQueue`)实现数据上传
- 创建同步读队列(`rcp.NetworkOutputQueue`)实现数据下载
- 实现`rcp.ReadStream`接口从流中读取数据并上传
- 实现`rcp.WriteStream`接口将数据写入流中并下载
- 处理大文件的上传下载场景
- 处理实时数据更新场景
- 处理直播数据传输场景
- 按需读取和写入数据，控制数据流速度

### 绝不做
- 不处理非流式数据传输场景
- 不处理WebSocket通信
- 不处理FTP文件传输
- 不处理邮件协议(SMTP/POP3)
- 不处理DNS查询
- 不处理非HTTP/HTTPS协议

### 补充
- 支持设备类型：Phone、2in1、Tablet、Wearable，从API 5.1.1(19)开始支持TV，从API 6.1.0(23)开始支持Car
- 最小API版本要求：5.0.0(12)
- 需要导入模块：`import { rcp } from '@kit.RemoteCommunicationKit'`
- 基于回调函数的流式传输还需要导入：`import { fileIo } from '@kit.CoreFileKit'`

## 调用规范和规则

### 输入约束
- **文件大小**：无明确限制，但建议单个文件不超过100MB以保证性能
- **URL格式**：必须是合法的HTTP/HTTPS URL
- **数据格式**：支持string或ArrayBuffer类型数据
- **队列大小**：可自定义队列最大字节数，建议不超过10MB
- **读取字节数**：每次读取建议不超过1MB
- **网络连接**：需要稳定的网络连接，建议使用WiFi或有线网络

### 执行约束
- **最大耗时**：建议单个请求不超过60秒
- **最大迭代次数**：流式读写建议不超过1000次循环
- **API调用频次**：单个session建议不超过10个并发请求
- **同步队列操作**：write/close/read操作必须在请求发送前或响应接收后调用
- **流式传输**：必须在数据准备好后立即开始传输，避免长时间等待

### 内容约束
- **禁止生成**：不生成WebSocket代码、FTP代码、邮件协议代码
- **禁止使用高危函数**：不使用`eval()`、`exec()`、`system()`等高危函数
- **禁止操作**：不在生产环境使用硬编码的URL和凭证
- **异常处理**：必须包含try-catch错误处理和session关闭逻辑
- **资源管理**：必须在完成后关闭session和文件描述符

### 降级约束
- **网络失败**：提示用户检查网络连接，建议使用离线缓存或重试机制
- **文件过大**：建议分片上传下载，或提示用户压缩文件
- **权限不足**：提示用户申请ohos.permission.INTERNET权限
- **队列满**：等待队列有空间后再写入，或提示用户减少数据量
- **连接超时**：建议设置合理的超时时间(5-30秒)，并提供重试选项

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查网络连接是否正常
2. 检查URL是否合法(HTTP/HTTPS格式)
3. 检查是否已导入必要模块
4. 检查是否有必要的权限(ohos.permission.INTERNET)

**参数准备**：
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 基于回调函数的流式传输还需导入
import { fileIo } from '@kit.CoreFileKit';

// 定义URL和数据
const uploadUrl = 'https://httpbin.org/anything';
const downloadUrl = 'https://httpbin.org/bytes/10000';
```

### 步骤2：基于缓冲区的流式传输 - 同步写队列上传

**示例代码**：
```typescript
export const testNetworkInputQueue = () => {
  // 创建同步写队列对象
  const networkInputQueue = new rcp.NetworkInputQueue();
  
  // 模拟文件通过同步读写流上传场景，将文件写入到同步写队列
  let counter = 0;
  const interval = setInterval(() => {
    // 添加数据到同步写队列
    networkInputQueue.write('a counter ' + counter++);
    console.info(`networkInputQueue write`);
    
    if (counter === 10) {
      clearInterval(interval);
      // 关闭同步写队列
      networkInputQueue.close();
    }
  }, 1000);
  
  try {
    // 创建session
    const session = rcp.createSession();
    console.info(`Post start.`);
    
    // 发起请求，相关数据在写入队列的同时会同步进行上传
    session.post('https://httpbin.org/anything', networkInputQueue).then((response) => {
      // 结果状态码
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

**关键API说明**：
- `rcp.NetworkInputQueue`：构造函数，创建同步写队列对象
- `networkInputQueue.write(buffer: string | ArrayBuffer)`：将数据写入队列
- `networkInputQueue.close()`：关闭同步写队列
- `networkInputQueue.getFreeSpace()`：获取剩余可写空间
- `session.post(url, networkInputQueue)`：发起POST请求，使用队列作为请求内容

### 步骤3：基于缓冲区的流式传输 - 同步读队列下载

**示例代码**：
```typescript
export const testNetworkOutputQueue = () => {
  // 创建同步读队列对象
  const networkOutputQueue = new rcp.NetworkOutputQueue();
  
  // 创建session
  try {
    const session = rcp.createSession();
    
    // 配置请求流数据size
    const numOfChunks = 10;
    const chunkLength = 1000;
    const totalBytes = numOfChunks * chunkLength;
    
    // 发起请求，响应数据会暂存在同步读队列中
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
    
    // 在需要使用响应数据时，可按需从队列中循环读取
    let totalGetLength = 0;
    const intervalId = setInterval(() => {
      // 读取数据后，开发者需根据具体业务场景进行后续处理
      const chunk = networkOutputQueue.read(chunkLength);
      totalGetLength += chunk.byteLength;
      console.info(`get bytes totalGetLength: ${totalGetLength}`);
      
      // 数据读取完成后，清除计时器
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

**关键API说明**：
- `rcp.NetworkOutputQueue`：构造函数，创建同步读队列对象
- `networkOutputQueue.read(maxBytesToRead: number)`：从队列读取数据，返回ArrayBuffer
- `networkOutputQueue.readInto(buffer: ArrayBuffer)`：将数据读取到指定缓冲区，返回字节数
- `networkOutputQueue.getStoredBytes()`：获取队列中数据的大小
- `session.get(url, networkOutputQueue)`：发起GET请求，使用队列作为响应目标

### 步骤4：基于回调函数的流式传输 - 实现ReadStream接口

**示例代码**：
```typescript
// 定义FdReadStream实现rcp.ReadStream接口，从流中读取数据
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

**关键接口说明**：
- `rcp.ReadStream`：接口，定义从流中读取数据的方法
- `read(buffer: ArrayBuffer): Promise<number>`：异步读取数据到缓冲区，返回读取的字节数

### 步骤5：基于回调函数的流式传输 - uploadFromStream上传

**示例代码**：
```typescript
export function testUploadFromStream(uploadFilePath: string) {
  try {
    // 创建session
    const session = rcp.createSession();
    
    // 根据传入的上传文件的路径打开文件
    const file = fileIo.openSync(uploadFilePath, fileIo.OpenMode.READ_ONLY);
    
    // 文件读取流
    const fileStream = new rcp.UploadFromStream(new FdReadStream(file.fd));
    
    // 以流的形式上传数据
    session.uploadFromStream('https://httpbin.org/anything', fileStream).then((resp) => {
      console.info(`testUploadFromStream response: ${JSON.stringify(resp)}`);
      if (resp && resp.statusCode === 200) {
        console.info(`testUploadFromStream succeeded.`);
      } else {
        console.error(`testUploadFromStream failed.`);
      }
      
      // 完成后关闭文件和session
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

**关键API说明**：
- `rcp.UploadFromStream`：构造函数，创建从流上传的对象，参数为ReadStream对象
- `session.uploadFromStream(url, uploadFromStream)`：从流中上传数据，返回Promise<Response>

### 步骤6：基于回调函数的流式传输 - 实现WriteStream接口

**示例代码**：
```typescript
// 定义FdWriteStream实现WriteStream接口，将数据写入流中
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

**关键接口说明**：
- `rcp.WriteStream`：接口，定义将数据写入流的方法
- `write(buffer: ArrayBuffer): Promise<number | void>`：异步写入数据到流，返回写入的字节数或void

### 步骤7：基于回调函数的流式传输 - downloadToStream下载

**示例代码**：
```typescript
export function testDownloadToStream(downloadToPath: string) {
  try {
    // 创建session
    const session = rcp.createSession();
    
    // 根据传入的下载文件保存路径打开文件
    const file = fileIo.openSync(downloadToPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    
    // 文件写入流
    const fileStream = { kind: 'stream', stream: new FdWriteStream(file.fd) } as rcp.DownloadToStream
    
    // 以流的形式下载数据
    session.downloadToStream('https://httpbin.org/bytes/10000', fileStream)
      .then((resp) => {
        console.info(`testDownloadToStream response: ${JSON.stringify(resp)}`);
        if (resp && resp.statusCode === 200) {
          console.info(`testDownloadToStream succeeded.`);
        } else {
          console.error(`testDownloadToStream failed.`);
        }
        
        // 完成后关闭文件和session
        fileIo.close(file.fd);
        session.close();
      })
      .catch((err: BusinessError) => {
        console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
        fileIo.close(file.fd);
        session.close();
      })
  } catch (err) {
    console.error(`testDownloadToStream error code is ${err.code}, error data is ${err.data}`);
  }
}
```

**关键API说明**：
- `rcp.DownloadToStream`：类型定义，包含kind和stream属性
  - `kind: 'stream'`：指定类型为流
  - `stream: WriteStream`：WriteStream对象
- `session.downloadToStream(url, downloadToStream)`：下载数据到流中，返回Promise<Response>

### 步骤8：错误处理

```typescript
// 统一错误处理代码
try {
  const session = rcp.createSession();
  
  // 执行流式传输操作
  // ...
  
} catch (err) {
  // 捕获创建session错误
  console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  
  // 根据错误码进行特定处理
  switch (err.code) {
    case 401:
      console.error('Parameter error. Please check input parameters.');
      break;
    case 1007900994:
      console.error('Sessions number reached limit. Please close unused sessions.');
      break;
    default:
      console.error(`Unknown error: ${err.message}`);
  }
}

// Promise错误处理
session.post(url, networkInputQueue)
  .then((response) => {
    // 处理成功响应
    if (response.statusCode === 200) {
      console.info('Request succeeded.');
    } else {
      console.error(`Request failed with status code: ${response.statusCode}`);
    }
  })
  .catch((err: BusinessError) => {
    // 处理请求错误
    console.error(`Request error code is ${err.code}, error data is ${err.data}`);
  })
  .finally(() => {
    // 确保关闭session
    session.close();
  });
```

### 步骤9：降级处理

```typescript
// 网络失败降级处理
async function fallbackNetworkError(url: string, data: any): Promise<void> {
  try {
    // 尝试使用缓存数据
    const cachedData = await getCachedData(url);
    if (cachedData) {
      console.info('Using cached data.');
      return cachedData;
    }
    
    // 尝试重试机制
    for (let i = 0; i < 3; i++) {
      try {
        const result = await retryRequest(url, data);
        return result;
      } catch (retryErr) {
        console.warn(`Retry ${i + 1} failed: ${retryErr.message}`);
        if (i === 2) {
          throw new Error('All retries failed. Please check network connection.');
        }
        await sleep(2000); // 等待2秒后重试
      }
    }
  } catch (finalErr) {
    // 最终降级方案
    console.warn('Network unavailable. Please try again later.');
    throw finalErr;
  }
}

// 文件过大降级处理
async function fallbackLargeFile(filePath: string, maxSize: number = 100 * 1024 * 1024): Promise<void> {
  const fileSize = await getFileSize(filePath);
  if (fileSize > maxSize) {
    // 分片处理
    console.warn('File is too large. Splitting into smaller chunks.');
    const chunks = await splitFile(filePath, maxSize);
    
    for (const chunk of chunks) {
      await uploadChunk(chunk);
    }
    
    console.info('All chunks uploaded successfully.');
  } else {
    // 直接上传
    await uploadFile(filePath);
  }
}

// 队列满降级处理
async function fallbackQueueFull(networkInputQueue: rcp.INetworkInputQueue, data: any): Promise<void> {
  const freeSpace = networkInputQueue.getFreeSpace();
  const dataSize = getDataSize(data);
  
  if (dataSize > freeSpace) {
    // 等待队列有空间
    console.warn('Queue is full. Waiting for space...');
    await waitForQueueSpace(networkInputQueue, dataSize);
    
    // 或分批写入
    const chunks = splitData(data, freeSpace);
    for (const chunk of chunks) {
      networkInputQueue.write(chunk);
      await sleep(100); // 给队列处理时间
    }
  } else {
    networkInputQueue.write(data);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查输入参数是否正确，URL格式是否合法 |
| 1007900994 | Sessions number reached limit | 关闭未使用的session，确保session数量不超过1024 |
| 1007900001 | Network error | 检查网络连接，确认URL可访问 |
| 1007900002 | Timeout error | 设置合理的超时时间，或检查网络速度 |
| 1007900003 | Permission denied | 申请ohos.permission.INTERNET权限 |
| 1007900004 | File not found | 检查文件路径是否正确 |
| 1007900005 | File read/write error | 检查文件权限和文件状态 |
| 1007900006 | Queue full | 等待队列有空间，或减少数据量 |
| 1007900007 | Queue closed | 检查队列是否已关闭，重新创建队列 |
| 1007900008 | Stream error | 检查流对象是否正确实现接口 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": ">=5.0.0(12)",
    "@kit.CoreFileKit": ">=5.0.0(12)",
    "@kit.BasicServicesKit": ">=5.0.0(12)"
  }
}
```

### 环境要求
- **HarmonyOS版本**：>=5.0.0(12)
- **DevEco Studio版本**：>=5.0.0
- **ArkTS版本**：>=1.0.0
- **设备类型**：Phone、2in1、Tablet、Wearable、TV(>=5.1.1(19))、Car(>=6.1.0(23))

### 常见编译问题

**问题1：导入模块错误**
```
Cannot find module '@kit.RemoteCommunicationKit' or its corresponding type declarations.
```
**解决方法**：确保项目配置正确，在`oh-package.json5`中添加依赖，并执行`ohpm install`

**问题2：API版本不兼容**
```
Property 'NetworkInputQueue' does not exist on type 'typeof rcp'.
```
**解决方法**：确保使用的API版本>=5.0.0(12)，检查设备是否支持该API

**问题3：接口实现错误**
```
Class 'FdReadStream' incorrectly implements interface 'ReadStream'.
```
**解决方法**：确保正确实现接口的所有方法，包括`read(buffer: ArrayBuffer): Promise<number>`

**问题4：类型错误**
```
Type '{ kind: string; stream: FdWriteStream; }' is not assignable to type 'DownloadToStream'.
```
**解决方法**：使用正确的类型断言，确保kind值为'stream'

**问题5：权限错误**
```
Permission denied: ohos.permission.INTERNET
```
**解决方法**：在`module.json5`中添加权限声明：
```json
{
  "module": {
    "reqPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：如何选择流式传输方式？
**原因**：两种流式传输方式各有适用场景
**解决方法**：
- **基于缓冲区的流式传输**：适用于需要精确控制数据流速度、按需读写数据的场景
- **基于回调函数的流式传输**：适用于已有文件流、需要直接从文件上传或下载到文件的场景

### Q2：NetworkInputQueue写入数据后如何知道队列状态？
**原因**：需要监控队列状态以避免队列溢出
**解决方法**：
- 使用`networkInputQueue.getFreeSpace()`获取剩余可写空间
- 在写入前检查剩余空间，避免写入过多数据
- 设置合理的队列大小和暂停策略

### Q3：NetworkOutputQueue读取数据时如何知道数据是否完整？
**原因**：需要确保所有数据都已接收并读取
**解决方法**：
- 使用`networkOutputQueue.getStoredBytes()`获取队列中数据大小
- 根据响应头中的Content-Length判断总数据量
- 循环读取直到读取的数据量等于总数据量

### Q4：如何处理大文件上传下载？
**原因**：大文件可能导致内存不足或队列溢出
**解决方法**：
- 使用分片上传下载，将大文件分割成多个小块
- 设置合理的队列大小和读取字节数
- 实现进度监控和暂停恢复功能

### Q5：流式传输过程中网络中断如何处理？
**原因**：网络不稳定可能导致传输中断
**解决方法**：
- 实现自动重试机制，设置合理的重试次数和间隔
- 使用断点续传功能，记录已传输的数据位置
- 提供用户友好的错误提示和恢复选项

### Q6：如何优化流式传输性能？
**原因**：性能问题可能导致用户体验不佳
**解决方法**：
- 设置合理的队列大小(建议1-10MB)
- 调整读写频率和数据块大小
- 使用合适的暂停策略避免队列溢出
- 监控网络状态，动态调整传输速度

### Q7：如何实现进度监控？
**原因**：用户需要了解传输进度
**解决方法**：
- 使用`HttpEventsHandler`的`onUploadProgress`和`onDownloadProgress`回调
- 在回调中计算已传输数据和总数据的比例
- 实现进度条显示和百分比提示

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "transferType": "stream",
  "methodUsed": "NetworkInputQueue | NetworkOutputQueue | uploadFromStream | downloadToStream",
  "dataTransferred": "number of bytes transferred",
  "transferDuration": "duration in seconds",
  "apiUsed": [
    "rcp.createSession",
    "rcp.NetworkInputQueue",
    "rcp.NetworkOutputQueue",
    "session.post",
    "session.get",
    "session.uploadFromStream",
    "session.downloadToStream",
    "session.close"
  ],
  "responseCode": "HTTP status code",
  "errorMessage": "error message if failed"
}
```

## 参考文档

- [API开发指南](references/remote-communication-syncstreamreq.md)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [基于缓冲区的流式上传示例](assets/network_input_queue_example.ets)
- [基于缓冲区的流式下载示例](assets/network_output_queue_example.ets)
- [基于回调函数的流式上传示例](assets/upload_from_stream_example.ets)
- [基于回调函数的流式下载示例](assets/download_to_stream_example.ets)

## 测试用例

### 正向测试用例
- [测试NetworkInputQueue正常上传](tests/test_network_input_queue_positive.ets)：验证同步写队列上传功能
- [测试NetworkOutputQueue正常下载](tests/test_network_output_queue_positive.ets)：验证同步读队列下载功能
- [测试uploadFromStream正常上传](tests/test_upload_from_stream_positive.ets)：验证从流上传功能
- [测试downloadToStream正常下载](tests/test_download_to_stream_positive.ets)：验证下载到流功能

### 边界测试用例
- [测试大文件上传](tests/test_large_file_upload.ets)：验证100MB文件上传
- [测试大数据下载](tests/test_large_data_download.ets)：验证大数据量下载
- [测试队列满处理](tests/test_queue_full.ets)：验证队列满时的处理逻辑
- [测试网络超时](tests/test_network_timeout.ets)：验证超时设置和处理

### 异常测试用例
- [测试URL格式错误](tests/test_invalid_url.ets)：验证非法URL的错误处理
- [测试网络断开](tests/test_network_disconnect.ets)：验证网络中断的处理
- [测试文件不存在](tests/test_file_not_found.ets)：验证文件路径错误的处理
- [测试权限不足](tests/test_permission_denied.ets)：验证权限错误的处理
- [测试session数量超限](tests/test_session_limit.ets)：验证session数量限制的错误处理