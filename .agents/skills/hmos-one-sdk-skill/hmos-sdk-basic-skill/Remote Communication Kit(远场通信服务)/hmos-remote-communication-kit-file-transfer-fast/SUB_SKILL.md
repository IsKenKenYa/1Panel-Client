---
name: hmos-remote-communication-kit-file-transfer-fast
description: 实现基于HTTP协议的文件快速上传下载功能,结合Remote Communication Kit和Core File Kit,支持文件、目录的传输,适用于网络文件传输、资源下载、文件同步场景
---

# 快速实现上传下载技能

## 功能描述

本技能实现基于HTTP协议的文件快速上传和下载功能。通过Remote Communication Kit提供的远程通信API与Core File Kit提供的文件管理API相结合,实现高效的文件传输能力:

- **下载功能**: 将远程服务器上的文件快速下载到本地指定路径,支持下载到文件或文件夹
- **上传功能**: 将本地文件快速上传到远程服务器指定URL,支持基于文件描述符的流式上传
- **特点**: 高效传输、配置灵活、支持安全验证、支持超时配置

支持设备类型:
- Phone、2in1、Tablet、Wearable(基础支持)
- TV设备(从5.1.1(19)版本开始)
- Car设备(从6.1.0(23)版本开始)

API版本要求:
- downloadToFile和uploadFromFile API从5.0.0(12)版本开始支持
- 需配合Core File Kit的fileIo模块使用

## 使用场景

### 触发词
- "下载文件" - 从远程服务器下载文件到本地
- "上传文件" - 将本地文件上传到远程服务器
- "文件传输" - 实现文件的快速上传或下载
- "快速上传下载" - 使用HTTP协议进行高效文件传输
- "Remote Communication Kit文件传输" - 基于该Kit的文件传输功能

### 能做
- 从指定URL下载文件到本地文件夹或指定文件路径
- 将本地文件上传到指定的服务器URL
- 配置传输超时时间、安全验证策略、TLS版本等参数
- 检查文件路径是否存在并进行清理
- 使用文件描述符进行流式文件读取和上传
- 处理上传下载过程中的错误和异常
- 关闭文件和会话释放资源

### 绝不做
- 不支持非HTTP协议的文件传输(如FTP、SFTP等)
- 不处理超出应用沙箱范围的文件路径
- 不支持断点续传功能(需要额外实现)
- 不处理文件加密解密功能(需要配合其他Kit)
- 不提供进度回调监控(当前示例未包含,但API支持)
- 不自动处理网络切换和重连逻辑

### 补充
- 文件路径必须在应用沙箱范围内
- 需要ohos.permission.INTERNET权限
- 使用cellular模式还需要ohos.permission.GET_NETWORK_INFO权限
- 建议及时关闭Session和文件描述符释放资源
- Session实例数量限制: 从5.1.0(18)开始可创建1024个,之前版本限制16个
- remoteValidation设置为'skip'表示跳过远程验证,请根据实际安全需求配置

## 调用规范和规则

### 输入约束
- URL格式: 必须为有效的HTTP/HTTPS URL字符串
- 本地文件路径: 必须为应用沙箱路径(如/data/storage/el2/base/haps/entry/files)
- 文件大小: 无明确限制,但建议根据网络和内存情况合理设置
- 超时时间: connectMs、transferMs、inactivityMs建议范围1000-60000ms
- 缓冲区大小: 建议根据文件大小设置,示例中使用1MB(1024*1024字节)

### 执行约束
- 最大耗时: 根据文件大小和网络情况,建议设置超时时间6000-60000ms
- Session管理: 及时关闭Session释放资源,避免超过实例数量限制(1024个)
- 文件描述符管理: 及时关闭文件描述符,避免资源泄露
- 并发限制: 避免同时创建过多Session实例
- API调用频次: 无明确限制,建议合理控制并发请求数量

### 内容约束
- 禁止生成: 不生成绕过安全验证的代码、不处理敏感文件路径的代码
- 禁止使用高危函数: 不使用eval、exec等高危函数
- 禁止操作: 不修改系统文件、不访问其他应用文件、不执行未授权的网络请求
- 安全验证: 建议根据实际需求配置remoteValidation,不应随意设置为'skip'

### 降级约束
- 网络失败: 捕获错误并提示用户检查网络连接和URL有效性
- 文件过大: 提示用户文件过大可能导致传输失败,建议分片传输
- 权限不足: 提示用户添加必要的权限声明(ohos.permission.INTERNET等)
- Session创建失败: 检查Session数量是否超限,及时关闭旧Session
- 文件操作失败: 检查文件路径是否在沙箱范围内,检查文件是否存在
- TLS连接失败: 检查TLS版本配置是否合理,降级到支持的TLS版本

## 调用流程和步骤

### 步骤1: 准备阶段(下载功能)

**前置校验**:
1. 检查设备类型和API版本是否支持(Phone/Tablet/Wearable/TV/Car, API 5.0.0+)
2. 验证URL格式是否正确(HTTP/HTTPS协议)
3. 验证本地路径是否在应用沙箱范围内
4. 检查是否已添加ohos.permission.INTERNET权限声明
5. 检查目标路径是否存在,如存在则清理

**参数准备**:
```typescript
// 导入必要模块
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

// 定义下载目标路径(应用沙箱路径)
const DOWNLOAD_TO_PATH = `/data/storage/el2/base/haps/entry/files`;

// 创建安全配置对象
const securityConfig: rcp.SecurityConfiguration = {
  remoteValidation: 'skip'  // 根据实际需求配置
};

// 创建下载配置对象
let downloadToFile: rcp.DownloadToFile = {
  kind: 'folder',  // 或'file'
  path: DOWNLOAD_TO_PATH  // 对于folder类型使用path,对于file类型使用file
};

// 创建会话配置
const session = rcp.createSession({
  requestConfiguration: {
    transfer: { 
      timeout: { 
        connectMs: 6000, 
        transferMs: 6000, 
        inactivityMs: 6000 
      } 
    },
    security: securityConfig
  }
});
```

### 步骤2: 执行下载操作

**示例代码**:
```typescript
// 检查目标路径是否存在并清理
if (fileIo.accessSync(DOWNLOAD_TO_PATH)) {
  fileIo.rmdirSync(DOWNLOAD_TO_PATH);
}

// 发起下载请求
session.downloadToFile('https://example.com/test.png', downloadToFile)
  .then((response: rcp.Response) => {
    console.info(`Successfully received the response, statusCode: ${JSON.stringify(response.statusCode)}`);
    // 处理响应结果
  })
  .catch((err: BusinessError) => {
    console.error(`Failed, the error code is ${err.code}, error data is ${err.data}`);
    // 错误处理
    handleDownloadError(err);
  })
  .finally(() => {
    // 关闭会话释放资源
    session.close();
  });
```

### 步骤3: 准备阶段(上传功能)

**前置校验**:
1. 检查设备类型和API版本是否支持
2. 验证上传URL格式是否正确
3. 验证本地文件是否存在且可读
4. 检查权限声明(ohos.permission.INTERNET)

**参数准备**:
```typescript
// 定义Session配置
let SESSION_CONFIG: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 6000  // 连接超时时间
      }
    },
    security: {
      remoteValidation: 'skip',
      tlsOptions: {
        tlsVersion: 'TlsV1.3'  // TLS版本配置
      }
    }
  }
};

// 定义FdReadFile类用于读取文件描述符
class FdReadFile {
  readonly fd: number;
  constructor(fd: number) {
    this.fd = fd;
  }
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  }
}

// 创建会话
const session = rcp.createSession(SESSION_CONFIG);
```

### 步骤4: 执行上传操作

**示例代码**:
```typescript
// 打开文件(只读模式)
const file = fileIo.openSync(
  '/data/storage/el1/bundle/entry_test/resources/resfile/upload_file.txt',
  fileIo.OpenMode.READ_ONLY
);

if (!file) {
  console.error('fileIo.openSync failed');
  return;
}

try {
  // 创建FdReadFile实例
  const fdReadFile = new FdReadFile(file.fd);
  
  // 分配缓冲区并读取文件
  const buffer = new ArrayBuffer(1024 * 1024);  // 1MB缓冲区
  await fdReadFile.read(buffer);
  
  // 执行上传
  session.uploadFromFile('https://httpbin.org/anything', new rcp.UploadFromFile(fdReadFile))
    .then((response: rcp.Response) => {
      console.info(`Upload succeeded: ${response}`);
      // 处理上传成功
    })
    .catch((err: BusinessError) => {
      console.error(`Upload failed: error code is ${err.code}, error data is ${err.data}`);
      // 错误处理
      handleUploadError(err);
    });
} finally {
  // 关闭文件和会话
  fileIo.closeSync(file.fd);
  session.close();
}
```

### 步骤5: 错误处理

```typescript
// 下载错误处理函数
function handleDownloadError(err: BusinessError): void {
  switch (err.code) {
    case 1007900003:
      console.error('URL格式错误,请检查URL格式是否正确');
      break;
    case 1007900006:
      console.error('域名解析失败,请检查网络连接和URL有效性');
      break;
    case 1007900007:
      console.error('连接服务器失败,请检查网络连接和服务器状态');
      break;
    case 1007900028:
      console.error('操作超时,请检查网络状况或增加超时时间');
      break;
    case 401:
      console.error('参数错误,请检查传入参数是否正确');
      break;
    default:
      console.error(`未知错误: code=${err.code}, message=${err.data}`);
  }
}

// 上传错误处理函数
function handleUploadError(err: BusinessError): void {
  switch (err.code) {
    case 1007900001:
      console.error('不支持的协议,请检查URL协议是否为HTTP/HTTPS');
      break;
    case 1007900003:
      console.error('URL格式错误,请检查URL格式');
      break;
    case 13900002:
      console.error('文件不存在或无法读取,请检查文件路径');
      break;
    case 13900012:
      console.error('权限不足,请检查文件读写权限');
      break;
    default:
      console.error(`上传失败: code=${err.code}, message=${err.data}`);
  }
}
```

### 步骤6: 降级处理

```typescript
// 网络失败降级方案
async function downloadWithFallback(url: string, path: string): Promise<void> {
  try {
    // 主要方案: 使用downloadToFile
    await performDownload(url, path);
  } catch (error) {
    if (error.code === 1007900028) {
      // 降级方案1: 增加超时时间重试
      console.warn('超时失败,尝试增加超时时间重试');
      await performDownloadWithLongerTimeout(url, path);
    } else if (error.code === 1007900006) {
      // 降级方案2: 切换网络重试
      console.warn('域名解析失败,提示用户检查网络');
      throw new Error('网络连接失败,请检查网络设置');
    } else {
      // 最终降级: 提示用户手动处理
      throw new Error(`下载失败,请手动下载文件: ${url}`);
    }
  }
}

// 文件过大降级方案
async function uploadLargeFileWithFallback(url: string, filePath: string): Promise<void> {
  try {
    const fileSize = getFileSize(filePath);
    if (fileSize > 10 * 1024 * 1024) {  // 大于10MB
      // 提示用户文件过大
      console.warn('文件过大,建议分片上传或使用流式传输');
      await uploadFileStream(url, filePath);  // 使用流式传输
    } else {
      await performUpload(url, filePath);
    }
  } catch (error) {
    // 最终降级方案
    throw new Error(`上传失败,请尝试压缩文件或使用其他传输方式`);
  }
}
```

## 错误码说明

### Remote Communication Kit错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900001 | 不支持的协议 | 检查URL协议是否为HTTP/HTTPS,确保服务器支持该协议版本 |
| 1007900002 | 初始化失败 | 释放内存资源,确保有充足的可用内存空间 |
| 1007900003 | URL格式错误 | 检查传入的URL格式是否正确,确保符合HTTP/HTTPS规范 |
| 1007900005 | 代理服务器域名解析失败 | 检查代理服务器URL是否正确,确认代理服务器可访问 |
| 1007900006 | 域名解析失败 | 检查服务器URL是否正确,检查网络连接是否正常 |
| 1007900007 | 连接服务器失败 | 检查网络连接,确认服务器在线且可访问 |
| 1007900028 | 操作超时 | 增加超时时间配置,检查网络状况,优化传输参数 |
| 1007900994 | Session数量达到限制 | 及时关闭旧Session释放资源,确保Session数量不超过1024 |
| 401 | 参数错误 | 检查传入参数类型和格式是否正确 |

### Core File Kit错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 13900001 | 操作不允许 | 检查文件操作权限,确认在沙箱范围内操作 |
| 13900002 | 文件不存在 | 检查文件路径是否正确,确认文件实际存在 |
| 13900004 | 目录不存在 | 检查目录路径是否正确,创建必要的目录结构 |
| 13900012 | 权限不足 | 检查文件读写权限,添加必要的权限声明 |
| 13900013 | 文件已存在 | 检查目标文件是否已存在,清理或重命名文件 |
| 13900020 | 参数错误 | 检查传入参数是否合法,确认参数类型正确 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "5.0.0(12)+",
    "@kit.CoreFileKit": "9+",
    "@kit.BasicServicesKit": "9+"
  }
}
```

### 环境要求
- HarmonyOS API版本: 5.0.0(12)及以上
- DevEco Studio版本: 3.1及以上
- 设备类型: Phone、2in1、Tablet、Wearable、TV(5.1.1+)、Car(6.1.0+)

### 权限配置
在module.json5中添加必要权限:
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:network_info_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 常见编译问题

**问题1: 导入模块错误**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**: 确保DevEco Studio版本>=3.1,检查SDK版本>=5.0.0(12),在build-profile.json5中配置正确的compileSdkVersion

**问题2: API版本不匹配**
```
Error: Property 'downloadToFile' does not exist on type 'Session'
```
**解决方法**: 检查API版本配置,确保compileSdkVersion>=5.0.0(12),在代码中添加版本检查逻辑

**问题3: 权限未声明**
```
Error: Permission denied: ohos.permission.INTERNET
```
**解决方法**: 在module.json5的requestPermissions中添加ohos.permission.INTERNET权限声明

**问题4: 文件路径错误**
```
Error: File not found: /data/storage/el2/base/haps/entry/files/test.txt
```
**解决方法**: 检查文件路径是否在应用沙箱范围内,使用context.filesDir获取正确的沙箱路径

**问题5: Session数量超限**
```
Error: Sessions number reached limit (1007900994)
```
**解决方法**: 及时调用session.close()关闭不再使用的Session,确保活跃Session数量不超过1024

## 常见问题与解决方法

### Q1: 下载文件时目标路径不存在
**原因**: 目标文件夹未创建或路径错误
**解决方法**:
- 使用context.filesDir获取应用沙箱路径
- 使用fileIo.mkdirSync创建目标文件夹
- 检查路径是否在沙箱范围内

### Q2: 上传大文件时内存不足
**原因**: 文件过大导致缓冲区分配失败
**解决方法**:
- 根据文件大小合理设置缓冲区大小
- 对于超大文件(>10MB)使用流式传输方式
- 分片上传大文件,避免一次性读取整个文件

### Q3: 网络请求超时
**原因**: 网络状况差或超时时间设置过短
**解决方法**:
- 增加超时时间配置(connectMs、transferMs、inactivityMs)
- 检查网络连接状态
- 提供重试机制,失败后自动重试2-3次

### Q4: TLS连接失败
**原因**: TLS版本不匹配或证书验证失败
**解决方法**:
- 检查服务器支持的TLS版本
- 配置合理的tlsVersion参数(TlsV1.2或TlsV1.3)
- 根据实际需求配置remoteValidation参数

### Q5: Session未及时关闭导致资源泄露
**原因**: Session创建后未调用close()方法
**解决方法**:
- 在finally块中调用session.close()
- 在组件销毁时清理Session资源
- 监控Session数量,确保不超过限制

### Q6: 文件描述符未关闭导致资源泄露
**原因**: 文件打开后未调用closeSync()
**解决方法**:
- 在finally块中调用fileIo.closeSync(fd)
- 使用try-finally确保资源释放
- 避免长时间持有文件描述符

### Q7: 多次下载同一文件导致冲突
**原因**: 目标文件已存在但未清理
**解决方法**:
- 使用fileIo.accessSync检查文件是否存在
- 存在时使用fileIo.rmdirSync清理目录
- 或配置keepLocal参数避免重复下载

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "download/upload",
  "url": "https://example.com/file",
  "localPath": "/data/storage/el2/base/haps/entry/files/downloaded_file",
  "statusCode": 200,
  "transferTime": "1234ms",
  "fileSize": "10240 bytes",
  "apiUsed": [
    "rcp.createSession",
    "rcp.downloadToFile",
    "rcp.uploadFromFile",
    "fileIo.accessSync",
    "fileIo.rmdirSync",
    "fileIo.openSync",
    "fileIo.read",
    "fileIo.closeSync",
    "rcp.Session.close"
  ],
  "securityConfig": {
    "remoteValidation": "skip",
    "tlsVersion": "TlsV1.3"
  },
  "timeoutConfig": {
    "connectMs": 6000,
    "transferMs": 6000,
    "inactivityMs": 6000
  }
}
```

## 参考文档

- [API开发指南](references/api-guide.md) - 快速实现上传下载功能开发指南
- [API参考说明](references/api-reference.md) - Remote Communication Kit ArkTS API参考文档
- [错误码说明](references/api-error-code.md) - Remote Communication Kit错误码详细说明
- [Core File Kit API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fs) - 文件管理API参考文档

## 完整示例代码

- [下载文件示例](assets/download-file-example.ets) - 完整的文件下载功能实现示例
- [上传文件示例](assets/upload-file-example.ets) - 完整的文件上传功能实现示例
- [配置文件示例](assets/config-example.json) - Session配置和安全配置示例

## 测试用例

### 正向测试用例
- [下载小文件测试](tests/test-download-small-file.ets) - 测试下载小于1MB的文件
- [上传文本文件测试](tests/test-upload-text-file.ets) - 测试上传txt文件到服务器
- [配置超时参数测试](tests/test-timeout-config.ets) - 测试不同超时配置的效果

### 边界测试用例
- [下载大文件测试](tests/test-download-large-file.ets) - 测试下载大于10MB的文件
- [超时边界测试](tests/test-timeout-boundary.ets) - 测试极限超时时间设置(1ms-60000ms)
- [并发Session测试](tests/test-concurrent-session.ets) - 测试创建多个Session的场景

### 异常测试用例
- [无效URL测试](tests/test-invalid-url.ets) - 测试URL格式错误时的错误处理
- [文件不存在测试](tests/test-file-not-exist.ets) - 测试上传不存在文件时的错误处理
- [网络断开测试](tests/test-network-disconnect.ets) - 测试网络异常时的降级处理
- [权限不足测试](tests/test-permission-denied.ets) - 测试缺少INTERNET权限时的错误
- [Session超限测试](tests/test-session-limit.ets) - 测试Session数量超过1024时的错误处理