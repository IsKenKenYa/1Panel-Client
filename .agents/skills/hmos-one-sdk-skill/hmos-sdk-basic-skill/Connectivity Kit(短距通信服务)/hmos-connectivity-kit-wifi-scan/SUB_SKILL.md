---
name: hmos-connectivity-kit-wifi-scan
description: 扫描Wi-Fi网络获取周围可用网络信息，支持主动扫描、PNO扫描和周期扫描三种模式，需要WiFi开启状态和GET_WIFI_INFO权限，适用于网络连接、信号强度检测和设备定位场景
---

# Wi-Fi扫描技能

## 功能描述

本技能提供HarmonyOS Wi-Fi扫描功能的完整实现方案，支持获取周围可用Wi-Fi网络的基本信息（网络名称、信号强度、加密方式等），包括三种扫描模式：
- **主动扫描**：应用主动发起Wi-Fi扫描，获取当前扫描结果
- **PNO扫描**：设备未连接Wi-Fi且屏幕关闭时自动扫描，降低功耗
- **周期扫描**：按照系统规定的时间间隔自动扫描周围Wi-Fi网络

扫描结果包含详细的网络信息，可用于网络连接、信号强度检测、设备定位等场景。

## 使用场景

### 触发词
- "扫描Wi-Fi"
- "搜索Wi-Fi"
- "获取Wi-Fi列表"
- "Wi-Fi扫描"
- "检测周围网络"

### 能做
- 获取当前扫描到的所有Wi-Fi网络列表
- 提取每个Wi-Fi网络的详细信息（SSID、BSSID、信号强度、加密方式等）
- 监听Wi-Fi扫描状态变更事件
- 支持主动扫描、PNO扫描、周期扫描三种模式
- 区分真实BSSID和随机BSSID（需要额外权限）

### 绝不做
- 不主动发起扫描操作（扫描接口已废弃，仅获取缓存结果）
- 不执行Wi-Fi连接操作（仅负责扫描和信息获取）
- 不修改Wi-Fi配置或设置
- 不处理Wi-Fi热点创建功能
- 不处理P2P连接功能

### 补充
- 扫描结果为当前时间点前30秒内的缓存数据
- 前台应用2分钟内最多可扫描4次，后台应用30分钟内最多可扫描1次
- 设备温度达到阈值时扫描会被管控
- 从API version 10开始，扫描接口已废弃，替代接口仅向系统应用开放
- 获取真实BSSID需要申请ohos.permission.GET_WIFI_PEERS_MAC权限

## 调用规范和规则

### 输入约束
- 无需输入参数（直接获取扫描结果）
- 可选参数：
  - 是否需要真实BSSID（需要额外权限）
  - 扫描结果筛选条件（如信号强度阈值）

### 执行约束
- WiFi必须处于开启状态
- 应用必须在前台运行才能获取扫描结果
- 扫描结果为缓存数据，时间范围为前30秒
- 单次调用耗时：通常小于1秒
- 最大并发调用：不建议并发调用

### 内容约束
- 禁止修改扫描结果数据
- 禁止缓存扫描结果超过应用生命周期
- 禁止在没有权限的情况下尝试获取真实BSSID
- 必须正确处理空扫描结果的情况

### 降级约束
- WiFi未开启：提示用户打开WiFi开关
- 无扫描结果：返回空数组，提示当前无可用网络
- 权限不足：使用随机BSSID或提示用户授予权限
- 系统错误：记录错误信息，建议用户重启WiFi或设备

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查应用是否在前台运行
2. 验证WiFi是否已开启
3. 检查权限是否已授予（ohos.permission.GET_WIFI_INFO）

**参数准备**：
```typescript
// 无需额外参数准备
// 导入必要模块
import { wifiManager } from '@kit.ConnectivityKit';
```

**权限配置**（module.json5）：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_WIFI_INFO"
      }
    ]
  }
}
```

### 步骤2：注册扫描状态事件

**示例代码**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

let scanStateCallback = (result: number) => {
  if (result === 1) {
    console.info("Wi-Fi扫描成功");
    // 扫描成功后可以获取结果
    getWifiScanResults();
  } else if (result === 0) {
    console.error("Wi-Fi扫描失败");
  }
};

try {
  // 注册扫描状态变更事件
  wifiManager.on("wifiScanStateChange", scanStateCallback);
  console.info("已注册扫描状态监听");
} catch (error) {
  console.error(`注册扫描事件失败: ${error.message}`);
}
```

### 步骤3：检查WiFi状态并获取扫描结果

**示例代码**：
```typescript
function getWifiScanResults(): void {
  try {
    // 检查WiFi是否开启
    let isWifiActive = wifiManager.isWifiActive();
    if (!isWifiActive) {
      console.error("WiFi未开启，请先打开WiFi");
      return;
    }

    // 获取扫描结果
    let scanInfoList = wifiManager.getScanInfoList();
    let len = scanInfoList.length;
    
    console.info(`扫描到 ${len} 个Wi-Fi网络`);
    
    if (len > 0) {
      for (let i = 0; i < len; i++) {
        let scanInfo = scanInfoList[i];
        console.info(`网络 ${i + 1}:`);
        console.info(`  SSID: ${scanInfo.ssid}`);
        console.info(`  BSSID: ${scanInfo.bssid}`);
        console.info(`  信号强度(RSSI): ${scanInfo.rssi}`);
        console.info(`  频段: ${scanInfo.band}`);
        console.info(`  频率: ${scanInfo.frequency}`);
        console.info(`  信道宽度: ${scanInfo.channelWidth}`);
        console.info(`  安全类型: ${scanInfo.securityType}`);
        console.info(`  加密能力: ${scanInfo.capabilities}`);
        console.info(`  时间戳: ${scanInfo.timestamp}`);
        console.info(`  WiFi类别: ${scanInfo.supportedWifiCategory}`);
        console.info(`  HiLink网络: ${scanInfo.isHiLinkNetwork}`);
      }
    } else {
      console.warn("当前无扫描结果，可能周围无可用WiFi网络");
    }
  } catch (error) {
    console.error(`获取扫描结果失败: ${error.message}`);
    handleScanError(error);
  }
}
```

### 步骤4：错误处理

**示例代码**：
```typescript
function handleScanError(error: any): void {
  // 根据错误码进行处理
  switch (error.code) {
    case 201:
      console.error("权限不足，请授予GET_WIFI_INFO权限");
      // 提示用户授予权限
      break;
    case 801:
      console.error("系统不支持WiFi功能");
      // 设备不支持WiFi
      break;
    case 2501000:
      console.error("WiFi操作失败，建议重启WiFi或设备");
      // WiFi服务内部异常
      break;
    case 2501001:
      console.error("WiFi STA功能未开启，请打开WiFi");
      // WiFi未开启
      break;
    default:
      console.error(`未知错误: ${error.message}`);
  }
}
```

### 步骤5：取消注册事件（业务退出时）

**示例代码**：
```typescript
function unregisterScanEvent(): void {
  try {
    // 取消注册扫描状态变更事件
    wifiManager.off("wifiScanStateChange", scanStateCallback);
    console.info("已取消扫描状态监听");
  } catch (error) {
    console.error(`取消注册失败: ${error.message}`);
  }
}
```

### 步骤6：完整流程封装

**完整示例**：
```typescript
import { wifiManager } from '@kit.ConnectivityKit';

class WifiScanner {
  private scanStateCallback: (result: number) => void;
  
  constructor() {
    this.scanStateCallback = (result: number) => {
      if (result === 1) {
        this.onScanSuccess();
      } else {
        this.onScanFailed();
      }
    };
  }
  
  // 开始扫描流程
  async startScan(): Promise<Array<wifiManager.WifiScanInfo>> {
    try {
      // 1. 检查WiFi状态
      if (!wifiManager.isWifiActive()) {
        throw new Error("WiFi未开启");
      }
      
      // 2. 注册扫描事件
      wifiManager.on("wifiScanStateChange", this.scanStateCallback);
      
      // 3. 等待扫描完成或直接获取缓存结果
      let scanResults = wifiManager.getScanInfoList();
      return scanResults;
    } catch (error) {
      console.error(`扫描失败: ${error.message}`);
      throw error;
    }
  }
  
  // 扫描成功回调
  private onScanSuccess(): void {
    console.info("扫描成功，可以获取结果");
  }
  
  // 扫描失败回调
  private onScanFailed(): void {
    console.error("扫描失败");
  }
  
  // 停止扫描流程
  stopScan(): void {
    wifiManager.off("wifiScanStateChange", this.scanStateCallback);
  }
  
  // 过滤扫描结果
  filterScanResults(
    results: Array<wifiManager.WifiScanInfo>,
    minRssi: number = -70
  ): Array<wifiManager.WifiScanInfo> {
    return results.filter(info => info.rssi >= minRssi);
  }
}

// 使用示例
let scanner = new WifiScanner();
try {
  let scanResults = await scanner.startScan();
  let filteredResults = scanner.filterScanResults(scanResults, -70);
  console.info(`过滤后的网络数量: ${filteredResults.length}`);
} catch (error) {
  console.error(error.message);
} finally {
  scanner.stopScan();
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限不足。未授予ohos.permission.GET_WIFI_INFO权限 | 在module.json5中声明权限，或引导用户授予权限 |
| 401 | 参数错误。必填参数未指定或参数类型错误 | 检查参数是否正确传递 |
| 801 | 系统能力不支持。设备不支持WiFi功能 | 提示用户设备不支持该功能 |
| 2501000 | WiFi操作失败。WiFi服务内部异常 | 建议用户重启WiFi或重启设备 |
| 2501001 | WiFi STA功能未开启 | 提示用户打开WiFi开关 |
| 2501003 | WiFi服务正在关闭 | 等待服务完全关闭后重试 |
| 2501004 | WiFi服务正在打开 | 等待服务完全打开后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS API version 9或更高版本
- 设备必须支持WiFi功能（SystemCapability.Communication.WiFi.STA）
- 应用需在前台运行

### 常见编译问题

**问题1：模块导入错误**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：
- 确保HarmonyOS SDK版本 >= 9
- 在build-profile.json5中正确配置SDK版本
- 检查IDE是否正确识别Kit模块

**问题2：权限未配置**
```
Error: Permission denied
```
**解决方法**：
- 在module.json5中添加权限声明
- 确保权限名称正确（ohos.permission.GET_WIFI_INFO）
- 运行时引导用户授予权限

**问题3：API不存在**
```
Error: wifiManager.getScanInfoList is not a function
```
**解决方法**：
- 检查API版本是否 >= 10
- 使用正确的导入方式：`import { wifiManager } from '@kit.ConnectivityKit'`

## 常见问题与解决方法

### Q1：扫描结果为空怎么办？
**原因**：
- WiFi未开启
- 周围确实无可用WiFi网络
- 扫描结果缓存已过期（超过30秒）
- 系统扫描被管控

**解决方法**：
- 检查WiFi是否开启
- 提示用户周围无可用网络
- 建议用户手动触发扫描（系统应用）
- 等待系统自动扫描完成后重试

### Q2：如何获取真实的BSSID？
**原因**：
默认情况下，BSSID为随机设备地址，保护隐私

**解决方法**：
- 申请ohos.permission.GET_WIFI_PEERS_MAC权限
- 在module.json5中添加权限声明
- 注意：此权限可能需要系统应用或特殊授权

### Q3：扫描结果不更新怎么办？
**原因**：
- 扫描结果为缓存数据，时间范围前30秒
- 系统扫描频率限制（前台2分钟4次，后台30分钟1次）
- 扫描接口已废弃，无法主动触发

**解决方法**：
- 等待系统自动扫描周期
- 监听扫描状态变更事件，获取最新结果
- 对于系统应用，可使用替代接口（从API version 10开始）

### Q4：如何在后台获取扫描结果？
**原因**：
后台应用扫描频率受限，30分钟最多1次

**解决方法**：
- 将应用切换到前台运行
- 使用PNO扫描机制（系统自动扫描）
- 订阅扫描状态事件，在扫描完成时获取结果
- 降低扫描频率要求

### Q5：扫描失败如何处理？
**原因**：
- WiFi服务异常
- 设备温度过高触发管控
- 权限不足
- 系统不支持

**解决方法**：
- 重启WiFi开关
- 检查设备温度，等待降温
- 确认权限配置正确
- 检查设备是否支持WiFi功能
- 如果持续失败，建议重启设备

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "scanResultCount": 10,
  "networkList": [
    {
      "ssid": "Network1",
      "bssid": "00:11:22:33:44:55",
      "rssi": -65,
      "securityType": "WPA2",
      "band": 2,
      "frequency": 2400
    }
  ],
  "apiUsed": [
    "wifiManager.isWifiActive",
    "wifiManager.getScanInfoList",
    "wifiManager.on('wifiScanStateChange')",
    "wifiManager.off('wifiScanStateChange')"
  ],
  "permissions": [
    "ohos.permission.GET_WIFI_INFO"
  ],
  "timestamp": "2026-01-01T10:00:00Z"
}
```

## 参考文档

- [Wi-Fi扫描开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-development-guide)
- [WLAN API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-wifimanager)
- [WIFI错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-wifi)

## 完整示例代码

- [ArkTS完整示例](assets/wifi_scan_example.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [基本扫描测试](tests/test_basic_scan.ets)：测试基本扫描流程
- [扫描结果获取测试](tests/test_get_results.ets)：测试获取扫描结果
- [事件注册测试](tests/test_event_register.ets)：测试扫描事件注册和取消

### 边界测试用例
- [空结果测试](tests/test_empty_result.ets)：测试无扫描结果情况
- [权限测试](tests/test_permission.ets)：测试权限不足情况
- [WiFi关闭测试](tests/test_wifi_off.ets)：测试WiFi未开启情况

### 异常测试用例
- [错误处理测试](tests/test_error_handling.ets)：测试各种错误场景
- [异常参数测试](tests/test_invalid_params.ets)：测试参数错误情况
- [并发调用测试](tests/test_concurrent.ets)：测试并发调用处理