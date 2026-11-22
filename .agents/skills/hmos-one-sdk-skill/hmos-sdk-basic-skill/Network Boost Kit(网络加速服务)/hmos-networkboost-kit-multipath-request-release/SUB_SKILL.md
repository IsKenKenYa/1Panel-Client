---
name: hmos-networkboost-kit-multipath-request-release
description: 发起和释放多网请求，支持WiFi和蜂窝并发以及主卡和副卡并发，系统决定并发组合，最大支持配额限制，适用于网络加速、弱网环境优化场景
---

# 多网发起和释放技能

## 功能描述

本技能实现HarmonyOS Network Boost Kit的多网发起和释放功能，应用可根据业务需求发起多网络加速请求，并在使用结束后及时释放。支持WiFi和蜂窝并发以及主卡和副卡并发，并发组合由系统决定，不支持开发者指定。

**核心能力**：
- 发起多网请求，通过回调获取请求结果
- 释放多网请求，释放网络资源
- 监听多网状态变化，获取实时状态信息
- 查询多网配额使用情况

**系统限制**：
- 主卡和副卡并发需开启智能切换上网卡开关
- 受限于硬件，部分设备不支持双卡场景下的多网并发
- 如果传输协议接口不支持指定网络，新发起的网络无法使用
- 需要开启网络加速开关（设置->移动网络->网络加速->允许使用移动数据加速网络）

## 使用场景

### 触发词
- "发起多网"
- "多网请求"
- "释放多网"
- "多网并发"
- "WiFi蜂窝并发"
- "网络加速"

### 能做
- 发起WiFi和蜂窝并发请求
- 发起主卡和副卡并发请求
- 监听多网状态变化
- 查询多网配额使用情况
- 及时释放多网资源

### 绝不做
- 不支持开发者指定并发组合（由系统决定）
- 不支持在不支持多网并发设备上使用
- 不支持HTTP等不支持指定网络的传输协议
- 不支持主副卡同运营商卡的并发场景

### 补充
- 需要申请ohos.permission.LINKTURBO权限
- API版本要求：6.0.0(20)及以上
- 需要设备支持网络加速功能
- 建议在弱网环境或需要高速下载场景使用

## 调用规范和规则

### 输入约束
- 回调函数必须为有效的Callback类型
- 参数类型必须符合API定义
- 应用必须在前台运行状态

### 执行约束
- 最大并发请求次数：受配额限制
- 最大并发时长：受配额限制
- API调用频次：避免频繁调用（错误码1013620006）

### 内容约束
- 禁止在不支持多网设备上调用
- 禁止在后台长时间持有多网资源
- 禁止忽略错误处理和降级方案
- 禁止使用不支持指定网络的传输协议

### 降级约束
- 多网请求失败：回退到单网络模式
- 权限不足：提示用户授权
- 设备不支持：提示设备限制
- 配额耗尽：等待配额恢复或降级处理

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持网络加速功能
2. 检查网络加速开关是否开启
3. 检查ohos.permission.LINKTURBO权限是否已申请
4. 检查API版本是否满足要求（6.0.0(20)及以上）

**参数准备**：
```typescript
// ArkTS示例
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：发起多网请求

**示例代码**：
```typescript
// 发起多网请求，同步监听多网状态
try {
  netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
    console.info('requestMultiPath result:' + JSON.stringify(data));
    // 处理请求结果
    if (data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
      console.info('多网请求成功');
      // 开始使用多网进行数据传输
    } else {
      console.error('多网请求失败，错误码：' + data.result);
      // 执行降级方案
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
  // 异常处理
}
```

### 步骤3：监听多网状态变化

**示例代码**：
```typescript
// 订阅多网状态变化事件
try {
  netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
    console.info('on multiPathStateChange: ' + JSON.stringify(data));
    // 处理状态变化
    switch (data.multiPathState) {
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        console.info('多网已建立');
        break;
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        console.info('多网处于空闲状态');
        break;
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        console.info('多网正在释放中');
        break;
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤4：查询配额使用情况

**示例代码**：
```typescript
// 查询当前应用多网使用的配额
try {
  let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
  console.info('已使用次数: ' + multiquota.used.count);
  console.info('已使用时长: ' + multiquota.used.duration + '秒');
  console.info('剩余次数: ' + multiquota.remaining.count);
  console.info('剩余时长: ' + multiquota.remaining.duration + '秒');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤5：释放多网

**示例代码**：
```typescript
// 当应用业务流程结束，释放多网
try {
  netHandover.releaseMultiPath();
  console.info('多网已释放');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤6：取消订阅状态变化

**示例代码**：
```typescript
// 取消订阅多网状态变化事件
try {
  netHandover.off('multiPathStateChange');
  console.info('已取消订阅多网状态变化');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤7：错误处理

```typescript
// 统一错误处理
try {
  netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
    // 处理请求结果
  });
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 201:
      console.error('权限校验失败，请检查是否申请了ohos.permission.LINKTURBO权限');
      break;
    case 1013600001:
      console.error('内部处理异常，请稍后重试');
      break;
    case 1013600002:
      console.error('系统处理异常，IPC跨进程调用失败');
      break;
    case 1013620000:
      console.error('多网功能没有使能，请检查网络加速开关');
      break;
    case 1013620001:
      console.error('多网已经激活或正在激活过程中');
      break;
    case 1013620002:
      console.error('应用多网请求已达到上限');
      break;
    case 1013620003:
      console.error('功耗限制不允许发起多网');
      break;
    case 1013620004:
      console.error('限额耗尽，请等待配额恢复');
      break;
    case 1013620005:
      console.error('多网请求场景冲突');
      break;
    case 1013620006:
      console.error('多网发起太频繁，请降低调用频次');
      break;
    case 1013620007:
      console.error('没有合适的多网链路可用');
      break;
    case 1013620008:
      console.error('流量不足');
      break;
    case 1013620009:
      console.error('设备不支持并发');
      break;
    default:
      console.error('未知错误：' + error.code + ', ' + error.message);
  }
}
```

### 步骤8：降级处理

```typescript
// 降级处理示例
async function requestMultiPathWithFallback(): Promise<void> {
  try {
    // 尝试发起多网请求
    netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
      if (data.result !== netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
        console.warn('多网请求失败，降级到单网络模式');
        // 使用单网络模式继续业务
        useSingleNetwork();
      }
    });
  } catch (err) {
    const error = err as BusinessError;
    if (error.code === 201) {
      // 权限不足，提示用户授权
      console.warn('权限不足，请申请ohos.permission.LINKTURBO权限');
      requestPermission();
    } else if (error.code === 1013620009) {
      // 设备不支持，使用单网络模式
      console.warn('设备不支持多网并发，使用单网络模式');
      useSingleNetwork();
    } else {
      // 其他错误，降级处理
      console.warn('多网请求异常，降级到单网络模式');
      useSingleNetwork();
    }
  }
}

// 单网络模式降级方案
function useSingleNetwork(): void {
  console.info('使用单网络模式继续业务');
  // 实现单网络模式下的数据传输逻辑
}
```

## 错误码说明

### 通用错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 申请ohos.permission.LINKTURBO权限 |
| 401 | 参数检查失败 | 检查参数类型和有效性 |
| 801 | 设备不支持该API | 检查设备API版本是否满足要求 |

### 专用错误码（requestMultiPath）

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1013600001 | 内部处理异常 | 稍后重试 |
| 1013600002 | 系统处理异常 | 检查网络管理服务状态 |
| 1013620000 | 多网功能没有使能 | 开启网络加速开关 |
| 1013620001 | 多网已经激活或正在激活 | 等待当前请求完成 |
| 1013620002 | 应用多网请求已达上限 | 等待配额恢复 |
| 1013620003 | 功耗限制不允许发起多网 | 降低应用功耗或等待 |
| 1013620004 | 限额耗尽 | 等待配额恢复 |
| 1013620005 | 多网请求场景冲突 | 检查是否有冲突场景 |
| 1013620006 | 多网发起太频繁 | 降低调用频次 |
| 1013620007 | 没有合适的多网链路可用 | 检查网络环境 |
| 1013620008 | 流量不足 | 检查流量余额 |
| 1013620009 | 不支持并发 | 使用单网络模式 |

### 专用错误码（releaseMultiPath）

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1013600001 | 内部处理异常 | 稍后重试 |
| 1013600002 | 系统处理异常 | 检查网络管理服务状态 |
| 1013620100 | 多网已激活但不是当前应用发起的 | 检查多网状态 |
| 1013620101 | 多网不在激活态 | 检查多网状态 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "API 12+",
    "@kit.BasicServicesKit": "API 12+"
  }
}
```

### 权限配置
在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO",
        "reason": "用于发起多网请求和释放多网资源",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API版本：6.0.0(20)及以上
- 设备需支持网络加速功能
- 需开启网络加速开关

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：确保HarmonyOS API版本满足要求（6.0.0(20)及以上），检查项目配置

**问题2：权限未配置**
```
Error: Permission denied
```
**解决方法**：在module.json5中添加ohos.permission.LINKTURBO权限声明

**问题3：设备不支持**
```
Error: Device does not support this API
```
**解决方法**：检查设备API版本和硬件支持情况，使用单网络模式降级方案

## 常见问题与解决方法

### Q1：多网请求失败，提示"多网功能没有使能"
**原因**：网络加速开关未开启
**解决方法**：
- 检查设置->移动网络->网络加速->允许使用移动数据加速网络是否开启
- 如果没有该开关，说明当前设备/ROM不支持多网并发能力

### Q2：主卡和副卡并发失败
**原因**：主副卡不满足并发条件
**解决方法**：
- 检查智能切换上网卡开关是否开启
- 检查主副卡是否为同运营商卡（不支持并发）
- 检查主副卡驻留网络的频点是否满足并发条件

### Q3：多网请求成功但无法使用
**原因**：传输协议不支持指定网络
**解决方法**：
- 检查使用的传输协议是否支持指定网络
- HTTP当前只支持默认网络传输，不支持指定网络
- 使用支持指定网络的传输协议

### Q4：多网请求频繁失败
**原因**：调用频次过高或配额耗尽
**解决方法**：
- 降低多网请求调用频次
- 使用getMultiPathQuotaStats查询配额使用情况
- 等待配额恢复后再发起请求

### Q5：应用切换到后台后多网被释放
**原因**：系统检测到应用使用不规范
**解决方法**：
- 及时释放多网资源，避免长时间持有
- 在应用切换到后台前主动释放多网
- 监听多网状态变化，及时处理释放事件

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "多网发起和释放",
  "apiUsed": [
    "netHandover.requestMultiPath",
    "netHandover.releaseMultiPath",
    "netHandover.on('multiPathStateChange')",
    "netHandover.off('multiPathStateChange')",
    "netHandover.getMultiPathQuotaStats"
  ],
  "quotaInfo": {
    "usedCount": "已使用次数",
    "usedDuration": "已使用时长（秒）",
    "remainingCount": "剩余次数",
    "remainingDuration": "剩余时长（秒）"
  },
  "multiPathState": "多网状态",
  "result": "请求结果"
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-request-release)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)
- [错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-arkts-errorcode)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)

## 完整示例代码

- [ArkTS示例](assets/example_multipath.ets)
- [完整示例项目](assets/multipath_example_project.zip)

## 测试用例

### 正向测试用例
- [发起多网请求成功](tests/test_request_success.ets)：正常场景下的多网请求
- [释放多网成功](tests/test_release_success.ets)：正常场景下的多网释放
- [查询配额成功](tests/test_quota_success.ets)：正常场景下的配额查询
- [监听状态变化成功](tests/test_state_listener.ets)：正常场景下的状态监听

### 边界测试用例
- [配额耗尽场景](tests/test_quota_exhausted.ets)：配额耗尽时的处理
- [频繁调用场景](tests/test_frequent_call.ets)：频繁调用时的处理
- [后台切换场景](tests/test_background_switch.ets)：应用切换到后台时的处理

### 异常测试用例
- [权限不足场景](tests/test_permission_denied.ets)：缺少权限时的处理
- [设备不支持场景](tests/test_device_unsupported.ets)：设备不支持时的降级处理
- [网络异常场景](tests/test_network_error.ets)：网络异常时的处理
- [参数错误场景](tests/test_param_error.ets)：参数错误时的处理