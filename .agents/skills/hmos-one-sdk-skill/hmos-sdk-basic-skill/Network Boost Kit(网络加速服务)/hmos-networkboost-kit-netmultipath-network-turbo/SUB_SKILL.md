---
name: hmos-networkboost-kit-netmultipath-network-turbo
description: 实现多网并发网络加速，支持WiFi和蜂窝网络并发传输，通过多Socket绑定不同网络通路实现大文件分片和多文件并发传输，最大支持系统配额限制，适用于大文件上传下载、多文件同步迁移场景
---

# 多网并发网络加速技能

## 功能描述

本技能实现HarmonyOS的多网并发网络加速能力，通过系统接口同时建立并使用多个网络通路（如WiFi和蜂窝、主卡和副卡），突破单网传输带宽限制，提升网络传输性能。支持两种典型场景：
1. **大文件分片传输**：将大文件分片后通过不同网络通路并发上传/下载，显著提升传输速度
2. **多文件并发传输**：多个文件分配给不同网络通路同时传输，提高整体传输效率

核心流程包括：发起多网请求、监听多网状态、获取NetHandle、绑定Socket到指定网络、并发传输、释放多网资源。

## 使用场景

### 触发词
- "多网并发传输"
- "大文件分片上传"
- "大文件分片下载"
- "多文件并发下载"
- "网络加速"
- "多网并发"

### 能做
- 发起和释放多网并发请求（WiFi+蜂窝或主卡+副卡）
- 监听多网状态变化并获取可用NetHandle
- 将Socket绑定到指定网络通路
- 实现大文件分片并发上传/下载
- 实现多文件并发传输
- 查询多网配额使用情况

### 绝不做
- 不支持指定并发组合（由系统决定）
- 不支持超过配额限制的多网请求
- 不支持跨线程传递Socket和NetHandle对象
- 不处理非网络传输类的加速需求

### 补充
- 需要申请ohos.permission.LINKTURBO受限ACL权限
- 多网请求受系统配额限制（次数和时长）
- 发起多网前需设置业务场景帮助系统管控
- 完成传输后必须释放多网资源
- 仅支持API version 6.0.0(20)及以上

## 调用规范和规则

### 输入约束
- 文件大小：建议单文件不超过200MB（可分片处理）
- 文件数量：建议不超过10个文件并发传输
- 网络状态：至少有2个可用网络通路（WiFi+蜂窝或主卡+副卡）
- 权限要求：已申请ohos.permission.LINKTURBO权限
- 配额限制：需检查多网配额是否充足

### 执行约束
- 最大耗时：单次传输建议不超过30分钟
- 最大迭代次数：文件分片不超过500片
- API调用频次：多网请求不超过系统配额限制
- Socket并发数：不超过可用网络通路数

### 内容约束
- 禁止生成：非HarmonyOS平台的代码、不支持的并发组合
- 禁止使用高危函数：eval、exec、系统命令执行
- 禁止操作：硬编码敏感信息、绕过权限检查

### 降级约束
- 网络失败：回退到单网传输，提示用户网络条件不足
- 文件过大：自动分片处理或提示用户拆分
- 配额耗尽：提示用户等待配额恢复或使用单网传输
- 权限不足：提示用户申请权限，引导至权限配置文档

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本要求（>=6.0.0(20))
2. 检查权限配置（ohos.permission.LINKTURBO、ohos.permission.INTERNET）
3. 检查网络状态（至少2个可用网络通路）
4. 检查多网配额是否充足

**权限配置示例**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.LINKTURBO"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 步骤2：发起多网并发

**设置业务场景**：
```typescript
import { netBoost } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

function setUploadSceneDesc(enter: boolean): boolean {
  try {
    let sceneDesc: netBoost.SceneDesc = {
      scene: 'upload',
      sceneEvent: enter ? netBoost.SceneEvent.SCENE_EVENT_ENTER : netBoost.SceneEvent.SCENE_EVENT_LEAVE
    };
    netBoost.setSceneDesc(sceneDesc);
    return true;
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`setSceneDesc Error: ${error.code}, ${error.message}`);
    return false;
  }
}
```

**查询多网配额**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

function getMultiPathQuota(): netHandover.MultiPathQuota | undefined {
  try {
    let quota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
    console.info(`已使用次数: ${quota.used.count}, 剩余次数: ${quota.remaining.count}`);
    console.info(`已使用时长: ${quota.used.duration}s, 剩余时长: ${quota.remaining.duration}s`);
    return quota;
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`getMultiPathQuotaStats Error: ${error.code}, ${error.message}`);
    return undefined;
  }
}
```

**发起多网请求**：
```typescript
function requestMultiPath(): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
        if (data && data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
          console.info('多网请求成功');
          resolve(true);
        } else {
          console.error(`多网请求失败: ${data.result}`);
          resolve(false);
        }
      });
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`requestMultiPath Error: ${error.code}, ${error.message}`);
      resolve(false);
    }
  });
}
```

### 步骤3：监听多网状态

**订阅多网状态变化**：
```typescript
import { connection } from '@kit.NetworkKit';

interface NetHandleChange {
  onMultiNetSuccess: (netHandle: connection.NetHandle) => void;
  onMultiNetRelease: (netHandle: connection.NetHandle) => void;
}

function setOnMultiPathStateChange(netHandleChange: NetHandleChange) {
  try {
    netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
      if (data.multiPathState === netHandover.MultiPathState.MULTIPATH_CREATED &&
        data.netHandle.netId >= 100) {
        console.info(`多网创建成功: netId=${data.netHandle.netId}`);
        netHandleChange?.onMultiNetSuccess(data.netHandle);
      } else if (data.multiPathState === netHandover.MultiPathState.MULTIPATH_CREATING) {
        console.info(`多网正在创建: netId=${data.netHandle.netId}`);
      } else {
        console.info(`多网释放: netId=${data.netHandle.netId}`);
        netHandleChange?.onMultiNetRelease(data.netHandle);
      }
    });
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`on multiPathStateChange Error: ${error.code}, ${error.message}`);
  }
}
```

### 步骤4：绑定Socket到网络

**获取所有网络**：
```typescript
function getAllNetHandles(): connection.NetHandle[] | undefined {
  try {
    let netHandles = connection.getAllNetsSync();
    const usefulNetHandles: connection.NetHandle[] = [];
    for (let i = 0; i < netHandles.length; i++) {
      console.info(`网络[${i}]: netId=${netHandles[i].netId}`);
      if (netHandles[i].netId >= 100) {
        usefulNetHandles.push(netHandles[i]);
      }
    }
    return usefulNetHandles;
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`getAllNetsSync Error: ${error.code}, ${error.message}`);
    return undefined;
  }
}
```

**绑定Socket到指定网络**：
```typescript
import { socket } from '@kit.NetworkKit';

async function bindSpecifiedNet(socketInstance: socket.TCPSocket, netId: number, port: number) {
  const netHandles = getAllNetHandles();
  if (netHandles) {
    for (let i = 0; i < netHandles.length; i++) {
      if (netHandles[i].netId === netId) {
        try {
          const connectionProperties = connection.getConnectionPropertiesSync(netHandles[i]);
          if (connectionProperties && connectionProperties.linkAddresses &&
            connectionProperties.linkAddresses.length > 0) {
            let netAddress: socket.NetAddress = {
              address: connectionProperties.linkAddresses[0].address.address,
              port: port
            };
            await socketInstance.bind(netAddress);
            await netHandles[i].bindSocket(socketInstance);
            console.info(`Socket绑定成功: netId=${netId}`);
          } else {
            console.error('获取连接属性失败');
          }
        } catch (err) {
          const error: BusinessError = err as BusinessError;
          console.error(`bindSocket Error: ${error.code}, ${error.message}`);
        }
        break;
      }
    }
  } else {
    console.error('网络列表为空');
  }
}
```

### 步骤5：执行并发传输

**创建Socket并发起传输**：
```typescript
async function uploadSegment(host: string, port: number, initResult: InitiateMultipartUpload,
  fileChunk: FileUpChunk, netId: number): Promise<UploadPartResult | undefined> {
  const socketInstance: socket.TCPSocket = socket.constructTCPSocketInstance();
  await bindSpecifiedNet(socketInstance, netId, 8080);
  
  try {
    await socketInstance.connect({
      address: { address: host, port: port, family: socket.NetFamily.IPv4 },
      timeout: 60000
    });
    
    const sendData = buildUploadRequest(initResult, fileChunk);
    await socketInstance.send({ data: sendData });
    
    socketInstance.on('message', (value: socket.SocketMessageInfo) => {
      const response = parseResponse(value.message);
      if (response.success) {
        return response.result;
      }
    });
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`uploadSegment Error: ${error.code}, ${error.message}`);
  }
}
```

### 步骤6：释放资源

**释放多网和取消监听**：
```typescript
function releaseMultiPath() {
  try {
    netHandover.releaseMultiPath();
    console.info('多网释放成功');
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`releaseMultiPath Error: ${error.code}, ${error.message}`);
  }
}

function setOffMultiPathStateChange() {
  try {
    netHandover.off('multiPathStateChange');
    console.info('取消多网状态监听');
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error(`off multiPathStateChange Error: ${error.code}, ${error.message}`);
  }
}
```

### 步骤7：错误处理

```typescript
try {
  await requestMultiPath();
  setOnMultiPathStateChange(netHandleChange);
  await performUpload();
} catch (error) {
  const err: BusinessError = error as BusinessError;
  switch (err.code) {
    case 201:
      console.error('权限校验失败，请检查权限配置');
      break;
    case 1013620002:
      console.error('应用多网请求已达上限');
      break;
    case 1013620004:
      console.error('限额耗尽，请等待配额恢复');
      break;
    case 1013620007:
      console.error('没有合适的多网链路可用');
      break;
    default:
      console.error(`未知错误: ${err.code}, ${err.message}`);
      // 降级到单网传输
      await fallbackToSingleNet();
  }
} finally {
  releaseMultiPath();
  setOffMultiPathStateChange();
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 检查ohos.permission.LINKTURBO权限配置 |
| 401 | 参数检查失败 | 检查API调用参数是否正确 |
| 801 | 设备不支持该API | 确认设备API版本>=6.0.0(20) |
| 1013600001 | 内部处理异常 | 重试或检查系统状态 |
| 1013600002 | 系统处理异常 | 检查网络服务是否正常 |
| 1013620000 | 多网功能没有使能 | 确认多网功能已启用 |
| 1013620001 | 多网已激活或正在激活 | 等待当前多网释放后重新请求 |
| 1013620002 | 多网请求已达上限 | 等待配额恢复或减少请求频次 |
| 1013620003 | 功耗限制不允许发起多网 | 降低功耗或等待功耗限制解除 |
| 1013620004 | 限额耗尽 | 等待配额恢复或使用单网传输 |
| 1013620005 | 多网请求场景冲突 | 调整业务场景设置 |
| 1013620006 | 多网发起太频繁 | 降低请求频次 |
| 1013620007 | 没有合适的多网链路 | 确认至少有2个可用网络通路 |
| 1013620008 | 流量不足 | 确认蜂窝流量充足 |
| 1013620009 | 不支持并发 | 确认设备支持WiFi+蜂窝或主卡+副卡并发 |
| 1013620100 | 多网不是当前应用拉起的 | 仅释放自己发起的多网 |
| 1013620101 | 多网不在激活态 | 确认多网已成功发起 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "^1.0.0",
    "@kit.NetworkKit": "^1.0.0",
    "@kit.CoreFileKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：>=6.0.0(20)
- DevEco Studio版本：>=5.0
- 设备类型：支持多网并发的手机/平板设备

### 常见编译问题

**问题1：权限配置错误**
```
Error: Permission ohos.permission.LINKTURBO is not granted
```
**解决方法**：在module.json5中添加权限配置，并申请受限ACL权限

**问题2：API版本不匹配**
```
Error: API 'requestMultiPath' is not supported on this device
```
**解决方法**：确认设备API版本>=6.0.0(20)，在代码中添加版本检查

**问题3：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：检查项目依赖配置，确保已安装最新SDK

## 常见问题与解决方法

### Q1：多网请求失败，提示没有合适的多网链路可用
**原因**：当前网络条件不足，只有一个可用网络通路
**解决方法**：
- 检查WiFi和蜂窝网络是否都已连接
- 确认蜂窝流量充足
- 降级到单网传输模式

### Q2：Socket绑定网络失败
**原因**：NetHandle对象无效或网络已断开
**解决方法**：
- 在绑定前检查NetHandle.netId是否>=100
- 使用getAllNetsSync获取最新网络列表
- 添加网络断开重试机制

### Q3：多网配额耗尽
**原因**：应用多网请求次数或时长超过系统限制
**解决方法**：
- 调用getMultiPathQuotaStats查询剩余配额
- 完成传输后及时释放多网资源
- 等待配额恢复或使用单网传输

### Q4：跨线程传递NetHandle失败
**原因**：Socket和NetHandle对象不支持跨线程传递
**解决方法**：
- 在子线程中使用getAllNetsSync重新获取网络
- 通过netId标识网络，在线程间传递netId而非对象
- 使用TaskPool管理并发任务

### Q5：大文件传输中断
**原因**：网络不稳定或分片失败
**解决方法**：
- 实现分片重试机制（retryTimes字段）
- 记录已传输分片，支持断点续传
- 添加网络状态监听，异常时暂停传输

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "multiPathEnabled": true,
  "netHandlesUsed": [
    {"netId": 100, "bearerType": "WiFi"},
    {"netId": 101, "bearerType": "Cellular"}
  ],
  "fileTransferred": "example.zip",
  "transferSpeed": "15.2 MB/s",
  "chunksUploaded": 10,
  "totalChunks": 10,
  "duration": "45s",
  "quotaUsed": {
    "count": 1,
    "duration": 45
  },
  "apiUsed": [
    "netBoost.setSceneDesc",
    "netHandover.getMultiPathQuotaStats",
    "netHandover.requestMultiPath",
    "netHandover.on('multiPathStateChange')",
    "connection.getAllNetsSync",
    "NetHandle.bindSocket",
    "socket.constructTCPSocketInstance",
    "netHandover.releaseMultiPath"
  ]
}
```

## 参考文档

- [多网并发网络加速开发指南](references/networkboost-netmultipath-network-turbo.md)
- [netBoost API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-netboost)
- [netHandover API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)
- [connection API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-net-connection)
- [socket API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-socket)
- [多网发起和释放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-request-release)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
- [多网并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipathguide)
- [Network Boost Kit指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/network-boost-kit-guide)

## 完整示例代码

- [大文件分片上传示例](assets/multi_network_upload.ets) - 完整的大文件分片并发上传实现
- [多文件并发下载示例](assets/multi_file_download.ets) - 多文件并发下载实现
- [文件处理工具](assets/file_chunk_util.ets) - 文件分片处理工具类
- [网络绑定工具](assets/net_bind_util.ets) - 网络绑定Socket工具类

## 测试用例

### 正向测试用例
- [大文件上传测试](tests/test_large_file_upload.ets) - 测试200MB文件分片上传
- [多文件下载测试](tests/test_multi_file_download.ets) - 测试5个文件并发下载
- [配额查询测试](tests/test_quota_query.ets) - 测试多网配额查询功能

### 边界测试用例
- [最小文件测试](tests/test_min_file.ets) - 测试1MB文件传输
- [最大分片测试](tests/test_max_chunks.ets) - 测试500分片边界
- [配额耗尽测试](tests/test_quota_exhausted.ets) - 测试配额耗尽场景

### 异常测试用例
- [权限缺失测试](tests/test_permission_denied.ets) - 测试权限缺失时的降级处理
- [网络断开测试](tests/test_network_disconnect.ets) - 测试网络断开时的异常处理
- [单网场景测试](tests/test_single_net.ets) - 测试只有一个网络时的降级方案
- [配额不足测试](tests/test_insufficient_quota.ets) - 测试配额不足时的处理