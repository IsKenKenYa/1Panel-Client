---
name: hmos-connectivity-kit-wlan-sta-mode
description: 实现HarmonyOS WLAN STA模式功能，支持查询Wi-Fi状态、建立Wi-Fi连接、监听状态变化，适用于应用连接Wi-Fi网络、网络状态监控场景
---

# STA模式开发技能

## 功能描述

本技能提供HarmonyOS WLAN STA模式（Station Mode，站点模式）的完整实现方案。STA模式是无线设备作为客户端接入无线局域网的工作模式，设备通过连接到接入点（AP）或无线路由器实现对网络的访问。

**核心能力**：
- 查询Wi-Fi开关状态
- 建立Wi-Fi连接（添加候选网络配置、连接指定网络）
- 监听Wi-Fi状态变化和连接状态变化
- 获取Wi-Fi连接信息和信号强度
- 管理候选网络配置（添加、移除、查询）

**技术特点**：
- 基于wifiManager模块实现
- 支持事件监听机制（wifiStateChange、wifiConnectionChange）
- 异步和同步API混合使用
- 需申请权限和系统能力

## 使用场景

### 触发词
- "连接Wi-Fi"
- "查询Wi-Fi状态"
- "Wi-Fi STA模式"
- "建立Wi-Fi连接"
- "监听Wi-Fi状态"
- "获取Wi-Fi连接信息"
- "管理Wi-Fi网络配置"

### 能做
- 查询WLAN开关是否已使能（isWifiActive）
- 添加候选网络配置（addCandidateConfig）
- 连接到候选网络（connectToCandidateConfig）
- 查询WLAN是否已连接（isConnected）
- 移除候选网络配置（removeCandidateConfig）
- 获取候选网络配置列表（getCandidateConfigs）
- 注册/取消注册WLAN状态改变事件（on/off wifiStateChange）
- 注册/取消注册WLAN连接状态改变事件（on/off wifiConnectionChange）
- 获取WLAN连接信息（getLinkedInfo）
- 查询信号强度（getSignalLevel）

### 绝不做
- 不实现P2P（peer-to-peer）服务功能
- 不实现AP（Access Point）模式功能
- 不处理热点扫描功能（需使用专门的扫描技能）
- 不处理Wi-Fi热点创建功能
- 不修改系统级Wi-Fi配置（仅处理应用维度的候选网络配置）
- 不支持WEP加密类型的候选网络配置

### 补充
- 使用前需要先使能WLAN
- 候选网络配置属于应用维度，与系统网络配置相互隔离
- 需要申请ohos.permission.GET_WIFI_INFO、ohos.permission.SET_WIFI_INFO权限
- 需要SystemCapability.Communication.WiFi.STA系统能力
- API版本要求：首批接口从API version 9开始支持

## 调用规范和规则

### 输入约束
- Wi-Fi配置参数：
  - ssid：最大长度32字节，UTF-8编码
  - preSharedKey：最大长度64字节（OPEN类型为空串，其他类型不能为空）
  - bssid：格式如"00:11:22:33:44:55"
  - securityType：有效枚举值（0-9）
- 信号强度参数：
  - rssi：dBm值，通常范围-100到0
  - band：1（2.4GHz）或2（5GHz）

### 执行约束
- 最大耗时：连接操作建议10秒内完成
- 监听器生命周期：建议在使用完成后及时取消注册
- 候选网络配置数量：建议不超过100个
- API调用频次：遵循系统限制（前台2分钟最多4次扫描）

### 内容约束
- 禁止使用：
  - 禁止使用已废弃的API（如scan、getScanResults等）
  - 禁止使用WEP加密类型的候选网络配置
  - 禁止直接修改系统级Wi-Fi配置
- 参数验证：
  - 必须验证ssid、preSharedKey长度
  - 必须验证securityType有效性
  - 必须验证networkId有效性（>=0）

### 降级约束
- Wi-Fi未使能：提示用户开启Wi-Fi或自动调用enableWifi（需权限）
- 连接失败：提供重试机制或提示用户检查网络配置
- 权限不足：提示用户申请必要权限
- 系统能力不支持：提示设备不支持该功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否已导入wifiManager模块
2. 检查是否已申请必要权限（ohos.permission.GET_WIFI_INFO、ohos.permission.SET_WIFI_INFO）
3. 检查系统能力是否支持（SystemCapability.Communication.WiFi.STA）
4. 检查Wi-Fi是否已使能（使用isWifiActive）

**参数准备**：
```typescript
// 导入必要模块
import { wifiManager } from '@kit.ConnectivityKit';

// 定义Wi-Fi配置
let config: wifiManager.WifiDeviceConfig = {
  ssid: "your_network_ssid",      // 网络名称，最大32字节
  bssid: "00:11:22:33:44:55",      // 可选，热点MAC地址
  preSharedKey: "your_password",   // 密码，最大64字节
  securityType: wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK  // 加密类型
};
```

### 步骤2：判断Wi-Fi状态

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

// 定义状态变化监听器
let recvPowerNotifyFunc: (result: number) => void = (result: number) => {
  let wifiState = "";
  switch (result) {
    case 0:
      wifiState = 'DISABLED';
      break;
    case 1:
      wifiState = 'ENABLED';
      break;
    case 2:
      wifiState = 'ENABLING';
      break;
    case 3:
      wifiState = 'DISABLING';
      break;
    default:
      wifiState = 'UNKNOWN STATUS';
      break;
  }
  console.info(`Wi-Fi state changed: ${wifiState}`);
};

try {
  // 注册Wi-Fi状态变化监听器
  wifiManager.on("wifiStateChange", recvPowerNotifyFunc);
  
  // 查询Wi-Fi状态
  let isWifiActive = wifiManager.isWifiActive();
  if (!isWifiActive) {
    console.info("Wi-Fi not enabled. Skipping monitor.");
  } else {
    console.info("Wi-Fi is enabled. Starting monitor...");
  }
} catch (error) {
  console.error(`WiFi state monitor failed: ${error.message}`);
} finally {
  try {
    // 取消注册监听器
    wifiManager.off("wifiStateChange", recvPowerNotifyFunc);
    console.info("Wi-Fi monitor off: listener removed.");
  } catch (e) {
    console.error(`WiFi state monitor failed. ${e.message}`);
  }
}
```

### 步骤3：建立Wi-Fi连接

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

try {
  // 定义连接状态变化监听器
  let recvWifiConnectionChangeFunc = (result: number) => {
    console.info("Receive wifi connection change event: " + result);
  };
  
  // 配置Wi-Fi网络参数
  let config: wifiManager.WifiDeviceConfig = {
    ssid: "your_network_ssid",
    bssid: "00:11:22:33:44:55",
    preSharedKey: "your_password",
    securityType: wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK
  };
  
  // 注册连接状态变化监听器
  wifiManager.on("wifiConnectionChange", recvWifiConnectionChangeFunc);
  
  // 添加候选网络配置
  wifiManager.addCandidateConfig(config).then(networkId => {
    console.info("Candidate config added, networkId: " + networkId);
    
    // 连接到候选网络
    wifiManager.connectToCandidateConfig(networkId);
    
    // 查询是否已连接
    if (!wifiManager.isConnected()) {
      console.info("Wi-Fi not connected");
    }
    
    // 获取连接信息
    wifiManager.getLinkedInfo().then(data => {
      console.info("Wi-Fi linked info: " + JSON.stringify(data));
    });
    
    // 查询信号强度
    let rssi = -88;
    let band = 1;  // 2.4GHz
    let level = wifiManager.getSignalLevel(rssi, band);
    console.info("Signal level: " + level);
  }).catch((err: number) => {
    console.error("Add candidate config failed: " + JSON.stringify(err));
  });
  
  // 取消注册监听器
  wifiManager.off("wifiConnectionChange", recvWifiConnectionChangeFunc);
} catch (error) {
  console.error(`WiFi Connection failed. ${error.message}`);
}
```

### 步骤4：管理候选网络配置

**查询候选配置**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

try {
  // 获取候选网络配置列表
  let configs = wifiManager.getCandidateConfigs();
  console.info("Candidate configs count: " + configs.length);
  
  for (let i = 0; i < configs.length; i++) {
    console.info(`Config ${i}:`);
    console.info("  ssid: " + configs[i].ssid);
    console.info("  bssid: " + configs[i].bssid);
    console.info("  securityType: " + configs[i].securityType);
  }
} catch (error) {
  console.error("Get candidate configs failed: " + JSON.stringify(error));
}
```

**移除候选配置**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

try {
  let networkId = 0;  // 要移除的网络配置ID
  
  wifiManager.removeCandidateConfig(networkId).then(() => {
    console.info("Candidate config removed successfully");
  }).catch((err: number) => {
    console.error("Remove candidate config failed: " + JSON.stringify(err));
  });
} catch (error) {
  console.error("Remove candidate config failed: " + JSON.stringify(error));
}
```

### 步骤5：错误处理

**完整错误处理示例**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

async function connectToWifi(ssid: string, password: string): Promise<void> {
  try {
    // 步骤1：检查Wi-Fi是否已使能
    if (!wifiManager.isWifiActive()) {
      console.warn("Wi-Fi is not enabled");
      // 可选：尝试开启Wi-Fi（需要ohos.permission.SET_WIFI_INFO权限）
      // wifiManager.enableWifi();
      throw new Error("Wi-Fi not enabled");
    }
    
    // 步骤2：配置网络参数
    let config: wifiManager.WifiDeviceConfig = {
      ssid: ssid,
      preSharedKey: password,
      securityType: wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK
    };
    
    // 步骤3：添加候选网络配置
    let networkId = await wifiManager.addCandidateConfig(config);
    console.info("Network config added, ID: " + networkId);
    
    // 步骤4：连接到网络
    wifiManager.connectToCandidateConfig(networkId);
    
    // 步骤5：等待连接完成（监听状态变化）
    // 实际应用中应通过on('wifiConnectionChange')监听
    
    // 步骤6：验证连接状态
    await new Promise(resolve => setTimeout(resolve, 3000));  // 等待3秒
    
    if (wifiManager.isConnected()) {
      console.info("Wi-Fi connected successfully");
      
      // 获取连接信息
      let linkedInfo = await wifiManager.getLinkedInfo();
      console.info("Connected to: " + linkedInfo.ssid);
      console.info("Signal level: " + wifiManager.getSignalLevel(linkedInfo.rssi, linkedInfo.band));
    } else {
      console.warn("Wi-Fi connection failed or timeout");
    }
    
  } catch (error) {
    // 错误码处理
    if (error.code) {
      switch (error.code) {
        case 201:
          console.error("Permission denied. Please check if required permissions are granted.");
          break;
        case 401:
          console.error("Invalid parameters. Please check ssid, password length and securityType.");
          break;
        case 801:
          console.error("Capability not supported. This device does not support Wi-Fi STA mode.");
          break;
        case 2501000:
          console.error("Operation failed. General Wi-Fi operation error.");
          break;
        case 2501001:
          console.error("Wi-Fi STA disabled. Please enable Wi-Fi first.");
          break;
        default:
          console.error("Unknown error: " + error.message);
      }
    } else {
      console.error("Error: " + error.message);
    }
    
    // 降级处理：提示用户手动连接
    console.warn("Please try to connect manually in system Wi-Fi settings");
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 检查是否已申请ohos.permission.GET_WIFI_INFO和ohos.permission.SET_WIFI_INFO权限 |
| 401 | Invalid parameters | 检查ssid（最大32字节）、preSharedKey（最大64字节）长度和securityType有效性 |
| 801 | Capability not supported | 确认设备支持SystemCapability.Communication.WiFi.STA系统能力 |
| 2501000 | Operation failed | 检查Wi-Fi是否已使能，网络配置是否正确，或尝试重启Wi-Fi |
| 2501001 | Wi-Fi STA disabled | 使用isWifiActive()检查状态，必要时调用enableWifi()（需权限） |
| 2501003 | Operation failed because the service is being closed | 等待服务关闭完成后再操作 |
| 2501004 | Operation failed because the service is being opened | 等待服务开启完成后再操作 |

**详细错误码参考**：
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API version 9或更高版本
- 设备支持SystemCapability.Communication.WiFi.STA系统能力
- DevEco Studio 3.0或更高版本

### 权限配置
在module.json5中添加权限：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_WIFI_INFO"
      },
      {
        "name": "ohos.permission.SET_WIFI_INFO"
      }
    ]
  }
}
```

### 常见编译问题

**问题1：导入wifiManager模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：
- 确认HarmonyOS SDK版本 >= API version 9
- 在DevEco Studio中正确配置SDK路径
- 检查import语句语法：`import { wifiManager } from '@kit.ConnectivityKit';`

**问题2：API调用类型错误**
```
Error: Property 'isWifiActive' does not exist on type 'wifiManager'
```
**解决方法**：
- 确认API版本支持（首批接口从API version 9开始）
- 检查API名称拼写是否正确
- 参考API文档确认接口定义

**问题3：权限不足导致运行失败**
```
Error: Permission denied (error code: 201)
```
**解决方法**：
- 在module.json5中添加必要权限声明
- 确认应用已获得用户授权（部分权限需要用户手动授权）
- 检查权限名称拼写是否正确

## 常见问题与解决方法

### Q1：Wi-Fi连接失败或超时
**原因**：
- Wi-Fi未使能
- 网络配置参数错误（ssid、密码不匹配）
- 网络信号弱或不在范围内
- 设备不支持该加密类型

**解决方法**：
- 使用isWifiActive()检查Wi-Fi状态
- 验证ssid和密码正确性
- 使用getSignalLevel()检查信号强度
- 确认securityType与热点匹配
- 增加连接超时时间和重试机制

### Q2：候选网络配置添加失败
**原因**：
- 参数验证失败（ssid超长、密码格式错误）
- WEP加密类型不支持
- Wi-Fi STA未使能
- 权限不足

**解决方法**：
- 检查ssid长度（<=32字节）
- 检查preSharedKey长度和格式（根据securityType）
- 避免使用WIFI_SEC_TYPE_WEP类型
- 确认Wi-Fi已使能
- 检查权限配置

### Q3：监听器未正确注销导致内存泄漏
**原因**：
- 在finally块中未正确调用off方法
- 监听器生命周期管理不当

**解决方法**：
- 在使用完成后立即调用off方法取消注册
- 使用try-finally确保监听器必定被注销
- 在页面/组件销毁时注销所有监听器

### Q4：获取连接信息返回随机MAC地址
**原因**：
- 未申请ohos.permission.GET_WIFI_LOCAL_MAC权限
- 未申请ohos.permission.GET_WIFI_PEERS_MAC权限（bssid）

**解决方法**：
- 申请GET_WIFI_LOCAL_MAC权限（API8-15仅系统应用，API16+PC设备普通应用可用）
- 申请GET_WIFI_PEERS_MAC权限获取真实BSSID
- 或接受使用随机MAC地址的设计

### Q5：应用维度候选网络与系统配置混淆
**原因**：
- 候选网络配置仅在应用维度可见
- 系统WLAN页面不显示候选网络

**解决方法**：
- 理解候选网络是应用维度的概念
- 使用getCandidateConfigs()查询应用添加的网络
- 使用getDeviceConfigs()查询系统网络配置（需额外权限）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "wifiState": "ENABLED",
  "connected": true,
  "ssid": "connected_network_name",
  "bssid": "00:11:22:33:44:55",
  "signalLevel": 4,
  "rssi": -50,
  "band": 1,
  "networkId": 123,
  "candidateConfigsCount": 5,
  "apiUsed": [
    "wifiManager.isWifiActive",
    "wifiManager.addCandidateConfig",
    "wifiManager.connectToCandidateConfig",
    "wifiManager.isConnected",
    "wifiManager.getLinkedInfo",
    "wifiManager.getSignalLevel",
    "wifiManager.on",
    "wifiManager.off"
  ]
}
```

## 参考文档

- [STA模式开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/sta-development-guide)
- [STA接口（js-apis-wifimanager）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)
- [ConnState连接状态说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)

## 完整示例代码

- [ArkTS示例：判断Wi-Fi状态](assets/wifi_state_monitor.ets)
- [ArkTS示例：建立Wi-Fi连接](assets/wifi_connect.ets)
- [ArkTS示例：管理候选网络配置](assets/wifi_config_manager.ets)
- [配置文件示例：权限配置](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试：查询Wi-Fi状态](tests/test_wifi_state_positive.ets)：验证Wi-Fi已使能时正确查询状态
- [测试：添加候选网络配置](tests/test_add_config_positive.ets)：验证成功添加有效配置
- [测试：连接Wi-Fi网络](tests/test_connect_positive.ets)：验证成功连接到候选网络
- [测试：获取连接信息](tests/test_get_info_positive.ets)：验证成功获取已连接网络信息

### 边界测试用例
- [测试：ssid最大长度](tests/test_ssid_max_length.ets)：验证32字节ssid边界值
- [测试：密码最大长度](tests/test_password_max_length.ets)：验证64字节密码边界值
- [测试：信号强度边界](tests/test_signal_level_boundary.ets)：验证rssi和band参数边界值

### 异常测试用例
- [测试：权限不足](tests/test_permission_denied.ets)：验证缺少权限时的错误处理
- [测试：参数无效](tests/test_invalid_params.ets)：验证超长ssid、无效密码的错误处理
- [测试：Wi-Fi未使能](tests/test_wifi_disabled.ets)：验证Wi-Fi未开启时的降级处理
- [测试：连接失败](tests/test_connect_failed.ets)：验证网络不存在或密码错误时的处理