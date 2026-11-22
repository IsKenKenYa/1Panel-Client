---
name: hmos-networkboost-kit-getmultipathquota
description: 查询应用多网并发配额使用情况，包括已使用和剩余的次数与时长，支持24小时周期自动刷新，适用于多网加速场景配额管理
---

# 多网配额查询技能

## 功能描述

本技能提供多网并发配额查询能力，帮助应用获取当前剩余的多网并发配额信息，包括已使用的配额次数和时长、剩余的配额次数和时长。应用可根据配额信息合理分配使用多网络加速的次数和时长。配额以24小时为周期进行刷新，配额耗尽时会限制使用多网功能。

## 使用场景

### 触发词
- "查询多网配额"
- "获取配额信息"
- "多网配额查询"
- "查看剩余配额"
- "配额统计"

### 能做
- 获取应用已使用的多网配额次数和时长
- 获取应用剩余的多网配额次数和时长
- 在发起多网请求前检查配额是否充足
- 在配额不足时提示用户等待刷新

### 绝不做
- 修改或重置配额信息
- 绕过配额限制发起多网请求
- 查询其他应用的配额信息

### 补充
- 配额以24小时为周期自动刷新
- 配额耗尽后请求多网会抛出错误码1013620004
- 需要申请ohos.permission.LINKTURBO权限
- API版本要求：6.0.0(20)及以上

## 调用规范和规则

### 输入约束
- 无需输入参数
- 调用前需确保已申请ohos.permission.LINKTURBO权限
- 调用前需导入@kit.NetworkBoostKit模块

### 执行约束
- 同步调用，立即返回结果
- 最大耗时：< 100ms
- 无频次限制

### 内容约束
- 禁止修改返回的配额数据
- 禁止缓存配额数据超过1小时
- 返回数据仅供展示和判断使用

### 降级约束
- 权限未申请：提示用户申请权限
- API不支持：提示设备不支持
- 内部异常：返回默认值或提示稍后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否>=6.0.0(20)
2. 确认已申请ohos.permission.LINKTURBO权限
3. 导入必要的模块

**参数准备**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：调用API

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

function getMultiPathQuota(): netHandover.MultiPathQuota | null {
  try {
    let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
    
    console.info('getMultiPathQuotaStats multiPathQuota.used.count is:' + multiquota.used.count);
    console.info('getMultiPathQuotaStats multiPathQuota.used.duration is:' + multiquota.used.duration);
    console.info('getMultiPathQuotaStats multiPathQuota.remaining.count is:' + multiquota.remaining.count);
    console.info('getMultiPathQuotaStats multiPathQuota.remaining.duration is:' + multiquota.remaining.duration);
    
    return multiquota;
  } catch (err) {
    console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    return null;
  }
}
```

### 步骤3：错误处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

function getMultiPathQuotaWithErrorHandling(): void {
  try {
    let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
    
    if (multiquota.remaining.count <= 0 || multiquota.remaining.duration <= 0) {
      console.warn('配额已耗尽，请等待24小时后重试');
      return;
    }
    
    console.info('已使用次数: ' + multiquota.used.count);
    console.info('已使用时长: ' + multiquota.used.duration + '秒');
    console.info('剩余次数: ' + multiquota.remaining.count);
    console.info('剩余时长: ' + multiquota.remaining.duration + '秒');
    
  } catch (err) {
    const businessError = err as BusinessError;
    switch (businessError.code) {
      case 201:
        console.error('权限校验失败，请申请ohos.permission.LINKTURBO权限');
        break;
      case 1013600001:
        console.error('内部处理异常，请稍后重试');
        break;
      case 1013600002:
        console.error('系统处理异常，请检查网络管理服务');
        break;
      default:
        console.error('未知错误: code=' + businessError.code + ', message=' + businessError.message);
    }
  }
}
```

### 步骤4：降级处理

```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function checkQuotaAndRequest(): Promise<boolean> {
  try {
    let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
    
    if (multiquota.remaining.count <= 0) {
      console.warn('剩余配额次数为0，无法发起多网请求');
      return false;
    }
    
    if (multiquota.remaining.duration <= 0) {
      console.warn('剩余配额时长为0，无法发起多网请求');
      return false;
    }
    
    console.info('配额充足，可以发起多网请求');
    return true;
    
  } catch (err) {
    const businessError = err as BusinessError;
    if (businessError.code === 201) {
      console.error('权限不足，请先申请权限');
    }
    return false;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 在module.json5中申请ohos.permission.LINKTURBO权限 |
| 1013600001 | 内部处理异常，如内部管理状态机异常 | 稍后重试或重启应用 |
| 1013600002 | 系统处理异常，如IPC跨进程调用失败 | 检查系统服务状态或重启设备 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "^6.0.0",
    "@kit.BasicServicesKit": "^6.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：6.0.0(20)及以上
- DevEco Studio：4.0及以上版本

### 常见编译问题

**问题1：找不到@kit.NetworkBoostKit模块**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：确保项目使用的HarmonyOS SDK版本>=6.0.0(20)，在build-profile.json5中配置正确的compatibleSdkVersion。

**问题2：权限未声明导致运行时错误**
```
Error: Permission denied
```
**解决方法**：在module.json5文件的requestPermissions中添加：
```json
{
  "name": "ohos.permission.LINKTURBO"
}
```

## 常见问题与解决方法

### Q1：获取配额时返回null或抛出异常
**原因**：权限未申请或API版本不支持
**解决方法**：
- 检查module.json5中是否添加ohos.permission.LINKTURBO权限
- 确认设备API版本>=6.0.0(20)

### Q2：配额数据为0是否正常
**原因**：配额已耗尽或尚未分配
**解决方法**：
- 配额耗尽时需等待24小时周期刷新
- 首次使用时系统可能需要初始化配额

### Q3：如何判断是否可以发起多网请求
**原因**：需要综合判断次数和时长
**解决方法**：
- 检查remaining.count > 0
- 检查remaining.duration > 0
- 两个条件都满足时才可发起多网请求

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "usedQuota": {
    "count": "已使用次数",
    "duration": "已使用时长(秒)"
  },
  "remainingQuota": {
    "count": "剩余次数",
    "duration": "剩余时长(秒)"
  },
  "apiUsed": [
    "netHandover.getMultiPathQuotaStats()"
  ]
}
```

## 参考文档

- [API开发指南](references/networkboost-netmultipath-getmultipathquota.md)
- [API参考说明](references/networkboost-nethandover.md)

## 完整示例代码

- [ArkTS示例](assets/example_getmultipathquota.ets)

## 测试用例

### 正向测试用例
- [正常获取配额信息](tests/test_positive.ets)：验证成功获取配额数据

### 边界测试用例
- [配额耗尽场景](tests/test_boundary.ets)：验证配额为0时的处理

### 异常测试用例
- [权限未申请](tests/test_exception.ets)：验证权限缺失时的错误处理