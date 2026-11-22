---
name: hmos-connectivity-kit-p2p-mode
description: P2P点对点连接开发，支持创建删除群组、建立P2P连接、获取对端IP及Socket通信，需要SystemCapability.Communication.WiFi.P2P系统能力，适用于设备间直接通信场景
---

# P2P模式开发技能

## 功能描述

本技能提供HarmonyOS WLAN P2P（peer-to-peer）点对点连接开发能力，允许两台STA设备直接建立TCP/IP连接，无需AP参与。支持创建临时组或永久组、发现P2P设备、建立连接、获取连接信息和群组IP地址，以及后续的Socket通信。需要SystemCapability.Communication.WiFi.P2P系统能力和ohos.permission.GET_WIFI_INFO权限。

## 使用场景

### 触发词
- "P2P连接" - 建立设备间点对点连接
- "创建P2P群组" - 创建临时组或永久组
- "删除P2P群组" - 移除现有群组
- "发现P2P设备" - 扫描查找附近的P2P设备
- "获取P2P连接信息" - 查询当前连接状态
- "P2P点对点通信" - 设备间直接通信
- "WLAN P2P" - WLAN点对点模式开发

### 能做
- 创建P2P群组（临时组或永久组）
- 删除已创建的P2P群组
- 发现并扫描附近的P2P设备
- 与目标P2P设备建立连接
- 获取P2P连接状态和信息
- 获取群组IP地址用于Socket通信
- 注册和取消P2P相关事件监听
- 处理P2P连接过程中的错误和异常

### 绝不做
- 不直接处理Socket通信的详细实现（需要路由到Socket通信技能）
- 不处理超出P2P范围的WLAN功能（如STA模式、热点模式）
- 不替代网络连接管理功能
- 不处理不满足权限要求的场景
- 不处理不支持P2P系统能力的设备

### 补充
- 需要设备开启Wi-Fi功能
- 需要SystemCapability.Communication.WiFi.P2P系统能力
- 需要ohos.permission.GET_WIFI_INFO权限（API 10起）
- 永久组（netId=-2）下次连接不需要重新GO和WPS密钥协商
- 临时组（netId=-1）下次连接需要重新GO协商
- 作为GO时不能主动发起连接
- P2P连接完成后需要注册"p2pConnectionChange"事件监听

## 调用规范和规则

### 输入约束
- 网络ID范围：-1（临时组）或-2（永久组）
- 设备地址：符合MAC地址格式（如"00:11:22:33:44:55"）
- 群组密钥：最小8个字符
- 群组名称：非空字符串
- 群组带宽：0（自动）、1（2.4GHZ）、2（5GHZ）
- 设备地址类型：可选参数，默认为随机设备地址类型

### 执行约束
- 最大耗时：P2P扫描建议不超过125秒
- 最大迭代次数：设备发现循环建议不超过10次
- API调用频次：避免频繁调用startDiscoverDevices
- 必须先开启Wi-Fi功能再执行P2P操作
- 必须注册事件监听再执行连接操作
- 必须在连接成功后才能获取IP地址

### 内容约束
- 禁止生成：不生成Socket通信的详细实现代码
- 禁止使用高危函数：不使用eval、exec等高危函数
- 禁止操作：不执行超出P2P范围的WLAN操作
- 必须校验：必须校验Wi-Fi是否开启、权限是否获取
- 必须处理：必须处理P2P事件回调、错误码处理

### 降级约束
- Wi-Fi未开启：提示用户开启Wi-Fi并等待用户操作
- 权限不足：提示用户申请必要权限并说明申请方法
- 系统能力不支持：明确告知用户设备不支持P2P功能
- P2P连接失败：提供重试机制或提示检查设备状态
- 扫描超时：停止扫描并提示用户检查设备距离或环境

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备Wi-Fi是否已开启（使用isWifiActive）
2. 检查设备是否支持SystemCapability.Communication.WiFi.P2P系统能力
3. 检查应用是否已获取ohos.permission.GET_WIFI_INFO权限
4. 准备必要的参数（设备地址、netId、密钥、群组名称等）

**参数准备**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function prepareP2PConfig(): Promise<wifiManager.WifiP2PConfig> {
  try {
    let deviceInfo = await wifiManager.getP2pLocalDevice();
    let config: wifiManager.WifiP2PConfig = {
      deviceAddress: deviceInfo.deviceAddress,
      deviceAddressType: 1,
      netId: -2,
      passphrase: "12345678",
      groupName: "testGroup",
      goBand: 0
    };
    console.info(`P2P config prepared: deviceAddress=${config.deviceAddress}`);
    return config;
  } catch (error) {
    console.error(`Prepare config failed: ${JSON.stringify(error)}`);
    throw error;
  }
}
```

### 步骤2：创建P2P群组

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

async function createP2PGroup(config: wifiManager.WifiP2PConfig): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error("Wi-Fi is not active, please enable Wi-Fi first");
      return;
    }
    
    if (config.netId === -2) {
      let recvP2pPersistentGroupChangeFunc = () => {
        console.info("P2P persistent group change event received");
      };
      wifiManager.on("p2pPersistentGroupChange", recvP2pPersistentGroupChangeFunc);
    }
    
    await wifiManager.createGroup(config);
    console.info("P2P group created successfully");
    console.info(`Group name: ${config.groupName}, Passphrase: ${config.passphrase}`);
  } catch (error) {
    console.error(`Create group failed: ${JSON.stringify(error)}`);
    switch (error.code) {
      case 201:
        console.error("Permission denied, please check GET_WIFI_INFO permission");
        break;
      case 401:
        console.error("Invalid parameters, please check config format");
        break;
      case 2801000:
        console.error("P2P module exception, please try restart Wi-Fi");
        break;
      case 2801001:
        console.error("Wi-Fi STA disabled, please enable Wi-Fi first");
        break;
      default:
        console.error(`Unknown error: ${error.message}`);
    }
    throw error;
  }
}
```

### 步骤3：删除P2P群组

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function removeP2PGroup(): Promise<void> {
  try {
    wifiManager.removeGroup();
    console.info("P2P group removed successfully");
  } catch (error) {
    console.error(`Remove group failed: ${JSON.stringify(error)}`);
    switch (error.code) {
      case 201:
        console.error("Permission denied");
        break;
      case 2801000:
        console.error("P2P module exception");
        break;
      case 2801001:
        console.error("Wi-Fi STA disabled");
        break;
      default:
        console.error(`Unknown error: ${error.message}`);
    }
    throw error;
  }
}
```

### 步骤4：发现P2P设备

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function discoverP2PDevices(): Promise<void> {
  try {
    if (!wifiManager.isWifiActive()) {
      console.error("Wi-Fi is not active");
      return;
    }
    
    let recvP2pPeerDeviceChangeFunc = (result: wifiManager.WifiP2pDevice[]) => {
      console.info(`P2P peer device change event: found ${result.length} devices`);
      for (let device of result) {
        console.info(`Device: ${device.deviceName}, Address: ${device.deviceAddress}`);
      }
    };
    
    wifiManager.on("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
    wifiManager.startDiscoverDevices();
    console.info("P2P device discovery started");
    
    setTimeout(() => {
      wifiManager.off("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
      console.info("P2P device discovery stopped after timeout");
    }, 125 * 1000);
  } catch (error) {
    console.error(`Discover devices failed: ${JSON.stringify(error)}`);
    throw error;
  }
}
```

### 步骤5：建立P2P连接

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function connectP2PDevice(targetDeviceAddress: string): Promise<void> {
  try {
    let recvP2pConnectionChangeFunc = (result: wifiManager.WifiP2pLinkedInfo) => {
      console.info(`P2P connection change event: ${JSON.stringify(result)}`);
      wifiManager.getP2pLinkedInfo((err, data) => {
        if (err) {
          console.error(`Get P2P linked info failed: ${JSON.stringify(err)}`);
          return;
        }
        console.info(`P2P linked info: ${JSON.stringify(data)}`);
        if (data.connectState === wifiManager.P2pConnectState.P2P_CONNECTED) {
          console.info("P2P connection established successfully");
        }
      });
    };
    
    wifiManager.on("p2pConnectionChange", recvP2pConnectionChangeFunc);
    
    let recvP2pPeerDeviceChangeFunc = (result: wifiManager.WifiP2pDevice[]) => {
      wifiManager.getP2pPeerDevices((err, data) => {
        if (err) {
          console.error(`Get peer devices failed: ${JSON.stringify(err)}`);
          return;
        }
        for (let device of data) {
          if (device.deviceAddress === targetDeviceAddress) {
            let config: wifiManager.WifiP2PConfig = {
              deviceAddress: device.deviceAddress,
              deviceAddressType: 1,
              netId: -2,
              passphrase: "",
              groupName: "",
              goBand: 0
            };
            wifiManager.p2pConnect(config);
            console.info(`P2P connect request sent to ${targetDeviceAddress}`);
            break;
          }
        }
      });
    };
    
    wifiManager.on("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
    wifiManager.startDiscoverDevices();
    
    setTimeout(() => {
      wifiManager.off("p2pConnectionChange", recvP2pConnectionChangeFunc);
      wifiManager.off("p2pPeerDeviceChange", recvP2pPeerDeviceChangeFunc);
    }, 125 * 1000);
  } catch (error) {
    console.error(`Connect P2P device failed: ${JSON.stringify(error)}`);
    throw error;
  }
}
```

### 步骤6：获取连接信息和IP地址

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function getP2PConnectionInfo(): Promise<void> {
  try {
    let linkedInfo = await wifiManager.getP2pLinkedInfo();
    console.info(`P2P linked info: connectState=${linkedInfo.connectState}`);
    
    if (linkedInfo.connectState === wifiManager.P2pConnectState.P2P_CONNECTED) {
      let groupInfo = await wifiManager.getCurrentGroup();
      console.info(`Group owner IP: ${groupInfo.goIpAddress}`);
      console.info(`Group owner device address: ${groupInfo.owner.deviceAddress}`);
      
      return {
        connectState: linkedInfo.connectState,
        groupOwnerIP: groupInfo.goIpAddress,
        ownerAddress: groupInfo.owner.deviceAddress
      };
    } else {
      console.warn("P2P not connected yet");
      return null;
    }
  } catch (error) {
    console.error(`Get P2P connection info failed: ${JSON.stringify(error)}`);
    throw error;
  }
}
```

### 步骤7：错误处理和降级

**错误处理代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

function handleP2PError(error: any, operation: string): void {
  console.error(`${operation} failed with error: ${JSON.stringify(error)}`);
  
  switch (error.code) {
    case 201:
      console.error("Permission denied. Solution: Check and request GET_WIFI_INFO permission");
      break;
    case 401:
      console.error("Invalid parameters. Solution: Verify config parameters format and values");
      break;
    case 801:
      console.error("Capability not supported. Solution: This device doesn't support P2P functionality");
      break;
    case 2801000:
      console.error("P2P module exception. Solution: Try restart Wi-Fi or reboot device");
      break;
    case 2801001:
      console.error("Wi-Fi STA disabled. Solution: Enable Wi-Fi first using enableWifi()");
      break;
    default:
      console.error(`Unknown error. Solution: Check network status and retry`);
  }
}

async function fallbackP2POperation(operation: string): Promise<void> {
  console.warn(`Primary P2P operation failed, attempting fallback for ${operation}`);
  
  if (!wifiManager.isWifiActive()) {
    console.warn("Fallback: Wi-Fi not active, waiting for user to enable Wi-Fi");
    return;
  }
  
  if (operation === "createGroup") {
    try {
      let config: wifiManager.WifiP2PConfig = {
        deviceAddress: "00:00:00:00:00:00",
        netId: -1,
        passphrase: "fallback123",
        groupName: "fallbackGroup",
        goBand: 0
      };
      await wifiManager.createGroup(config);
      console.info("Fallback: Created temporary group successfully");
    } catch (error) {
      console.error("Fallback: Create temporary group also failed");
    }
  }
  
  console.warn("Fallback: All fallback attempts failed, please check device status");
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限被拒绝 | 检查并申请ohos.permission.GET_WIFI_INFO权限 |
| 401 | 参数校验失败 | 检查config参数格式和取值范围，确保deviceAddress格式正确 |
| 801 | 系统能力不支持 | 设备不支持P2P功能，提示用户更换设备或放弃此功能 |
| 2801000 | P2P模块异常 | 重新执行关闭及打开Wi-Fi开关的操作，或重启设备 |
| 2801001 | Wi-Fi STA未打开 | 先使用enableWifi()开启Wi-Fi功能 |
| 2501003 | 服务打开失败 | 服务正在关闭，重新执行打开服务操作 |
| 2501004 | 服务关闭失败 | 服务正在打开，重新执行关闭服务操作 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version 9及以上
- SystemCapability.Communication.WiFi.P2P系统能力
- 开发环境：DevEco Studio 3.1及以上

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：确保在module.json5中正确配置依赖，并在DevEco Studio中同步项目

**问题2：权限未声明**
```
Permission denied error code 201
```
**解决方法**：在module.json5的requestPermissions中添加：
```json
{
  "name": "ohos.permission.GET_WIFI_INFO"
}
```

**问题3：系统能力不支持**
```
Capability not supported error code 801
```
**解决方法**：检查设备是否支持P2P功能，可以在代码中动态判断系统能力

**问题4：Wi-Fi未开启**
```
Wi-Fi STA disabled error code 2801001
```
**解决方法**：调用enableWifi()开启Wi-Fi，或提示用户手动开启

## 常见问题与解决方法

### Q1：P2P连接总是失败怎么办？
**原因**：可能是Wi-Fi未开启、权限未获取、设备距离过远、目标设备不支持P2P
**解决方法**：
- 检查Wi-Fi是否已开启（使用isWifiActive）
- 检查权限是否已申请（ohos.permission.GET_WIFI_INFO）
- 检查目标设备是否支持P2P功能
- 缩短设备间距离（建议10米以内）
- 尝试重启两台设备的Wi-Fi功能

### Q2：如何判断P2P连接是否成功？
**原因**：P2P连接是异步过程，需要监听事件回调
**解决方法**：
- 注册"p2pConnectionChange"事件监听
- 在回调中检查WifiP2pLinkedInfo的connectState
- connectState为P2P_CONNECTED表示连接成功
- 可以使用getP2pLinkedInfo()主动查询连接状态

### Q3：永久组和临时组有什么区别？
**原因**：两种群组类型的重连机制不同
**解决方法**：
- 永久组（netId=-2）：下次连接不需要重新GO协商和WPS密钥协商，适合长期固定的设备连接
- 临时组（netId=-1）：每次连接都需要重新GO协商和WPS密钥协商，适合临时性的设备连接
- 根据实际使用场景选择合适的群组类型

### Q4：作为GO能否主动发起连接？
**原因**：P2P协议规定Group Owner不能主动发起连接
**解决方法**：
- 作为GO（Group Owner）时，只能等待其他设备连接
- 如果需要主动连接，应使用Client角色
- 可以通过netId参数控制设备角色

### Q5：如何获取对端IP地址进行Socket通信？
**原因**：连接成功后才能获取IP地址
**解决方法**：
- 确保P2P连接状态为P2P_CONNECTED
- 使用getCurrentGroup()获取群组信息
- 从WifiP2pGroupInfo中获取goIpAddress
- 使用goIpAddress作为Socket通信的目标地址
- 参考Socket通信技能进行后续开发

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "P2P connection established",
  "groupInfo": {
    "groupName": "testGroup",
    "passphrase": "12345678",
    "netId": -2,
    "ownerAddress": "00:11:22:33:44:55",
    "groupOwnerIP": "192.168.49.1"
  },
  "connectionInfo": {
    "connectState": "P2P_CONNECTED",
    "deviceAddress": "00:11:22:33:44:55"
  },
  "apiUsed": [
    "wifiManager.isWifiActive",
    "wifiManager.createGroup",
    "wifiManager.removeGroup",
    "wifiManager.startDiscoverDevices",
    "wifiManager.getP2pPeerDevices",
    "wifiManager.p2pConnect",
    "wifiManager.getP2pLinkedInfo",
    "wifiManager.getCurrentGroup",
    "wifiManager.on",
    "wifiManager.off"
  ]
}
```

## 参考文档

- [P2P模式开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/p2p-development-guide)
- [WLAN API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)

## 完整示例代码

- [创建P2P群组示例](assets/p2p-create-group.ets)
- [建立P2P连接示例](assets/p2p-connect.ets)
- [完整P2P开发示例](assets/p2p-complete-example.ets)
- [配置文件示例](assets/module-config.json)

## 测试用例

### 正向测试用例
- [创建永久组测试](tests/test_create_permanent_group.py)：验证netId=-2的永久组创建成功
- [建立P2P连接测试](tests/test_p2p_connect.py)：验证两台设备成功建立P2P连接
- [获取连接信息测试](tests/test_get_connection_info.py)：验证连接成功后能正确获取IP地址

### 边界测试用例
- [最小密钥长度测试](tests/test_min_passphrase_length.py)：验证passphrase最小8字符边界
- [临时组和永久组切换测试](tests/test_group_type_switch.py)：验证netId=-1和-2的切换
- [超时扫描测试](tests/test_discovery_timeout.py)：验证125秒扫描超时处理

### 异常测试用例
- [Wi-Fi未开启测试](tests/test_wifi_disabled.py)：验证Wi-Fi未开启时的错误处理
- [权限不足测试](tests/test_permission_denied.py)：验证缺少权限时的降级方案
- [设备地址格式错误测试](tests/test_invalid_device_address.py)：验证非法MAC地址的参数校验
- [系统能力不支持测试](tests/test_capability_not_supported.py)：验证不支持P2P设备的处理