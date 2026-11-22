# 技能参考文档链接

本文档记录了所有参考文档的华为开发者网站在线链接。

## API开发指南文档

- [流式传输开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-syncstreamreq)
  - 本地文件：`references/remote-communication-syncstreamreq.md`
  - 来源：harmonyos-guides目录
  - 功能：介绍HTTP流式传输的实现方法，包括基于缓冲区和基于回调函数的两种方式

## API参考文档

- [Remote Communication Kit API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
  - 本地文件：`references/remote-communication-rcp.md`
  - 来源：harmonyos-references目录
  - 功能：提供rcp模块的完整API定义，包括Session、Request、Response、NetworkInputQueue、NetworkOutputQueue等

## 相关API参考文档

以下API在本技能中被引用，可在华为开发者网站查看：

### 流式传输相关API

1. **NetworkInputQueue** - 同步写队列
   - 用于写请求体的同步写队列
   - 创建方式：`new rcp.NetworkInputQueue()`
   - 主要方法：`write()`, `close()`, `getFreeSpace()`
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索NetworkInputQueue）

2. **NetworkOutputQueue** - 同步读队列
   - 用于读响应体的同步读队列
   - 创建方式：`new rcp.NetworkOutputQueue()`
   - 主要方法：`read()`, `readInto()`, `getStoredBytes()`
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索NetworkOutputQueue）

3. **uploadFromStream** - 从流中上传
   - 接口：`session.uploadFromStream(url: URLOrString, uploadFrom: UploadFromStream): Promise<Response>`
   - 功能：从流中上传数据到服务器
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索uploadFromStream）

4. **downloadToStream** - 下载到流
   - 接口：`session.downloadToStream(url: URLOrString, downloadTo: DownloadToStream): Promise<Response>`
   - 功能：将数据下载到流中
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索downloadToStream）

### 流接口类型

1. **ReadStream** - 读流接口
   - 提供从流中读取数据的函数
   - 主要方法：`read(buffer: ArrayBuffer): Promise<number>`
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索ReadStream）

2. **WriteStream** - 写流接口
   - 提供将数据写入流中的函数
   - 主要方法：`write(buffer: ArrayBuffer): Promise<void | number>`
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索WriteStream）

3. **UploadFromStream** - 上传流对象
   - 表示以流的形式进行上传操作
   - 构造函数：`constructor(stream: Stream | ReadStream | SyncReadStream)`
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索UploadFromStream）

4. **DownloadToStream** - 下载流对象
   - 类型定义：`{ kind: 'stream'; stream: Stream | WriteStream | SyncWriteStream; }`
   - 功能：将文件下载到数据流中
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索DownloadToStream）

### Session相关API

1. **createSession** - 创建会话
   - 接口：`rcp.createSession(sessionConfiguration?: SessionConfiguration): Session`
   - 功能：创建HTTP会话，启动HTTP交互的主要方法
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索createSession）

2. **Session.post** - POST请求
   - 接口：`session.post(url: URLOrString, content?: RequestContent, destination?: ResponseBodyDestination): Promise<Response>`
   - 功能：发送HTTP POST请求
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索post）

3. **Session.get** - GET请求
   - 接口：`session.get(url: URLOrString, destination?: ResponseBodyDestination): Promise<Response>`
   - 功能：发送HTTP GET请求
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索get）

4. **Session.close** - 关闭会话
   - 接口：`session.close(): void`
   - 功能：关闭会话，释放资源
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索close）

### 暂停策略API

1. **SendingPausePolicy** - 发送暂停策略
   - 类型：`{ kind: 'timeout'; timeoutMs: number; }`
   - 功能：暂停发送流程的策略
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索SendingPausePolicy）

2. **ReceivingPausePolicy** - 接收暂停策略
   - 类型：`ReceivingPauseByCache | ReceivingPauseByTimeout`
   - 功能：暂停接收流程的策略
   - API文档链接：[remote-communication-rcp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)（搜索ReceivingPausePolicy）

## 链接转换规则

根据用户提供的规则，本地文档链接转换为华为开发者网站链接的规则：

1. **harmonyos-guides目录文档**：
   - 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-guides\...\{filename}.md`
   - 转换为：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}`
   - 示例：`remote-communication-syncstreamreq.md` → `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-syncstreamreq`

2. **harmonyos-references目录文档**：
   - 本地路径：`D:\z00810349\APIDevice\output\md_output\harmonyos-references\...\{filename}.md`
   - 转换为：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}`
   - 示例：`remote-communication-rcp.md` → `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp`

3. **转换规则**：
   - 只保留md文件名（不包含路径）
   - 去掉.md后缀
   - 根据来源目录选择正确的base URL（harmonyos-guides或harmonyos-references）