---
name: hmos-appgallery-kit-store-update
description: 检测应用新版本并显示更新对话框，支持Phone/Tablet/PC/2in1/TV/Wearable设备，适用于应用启动检查更新和用户主动检查更新场景
---

# 应用市场更新功能技能

## 功能描述

本技能提供HarmonyOS应用版本检测和更新提醒能力，帮助开发者实现应用内版本检查和更新提示功能。通过调用应用市场更新服务API，可以检测应用是否有可更新版本，并在有新版本时显示升级对话框提示用户更新。

**核心能力**：
- 检查应用是否有可更新版本
- 显示升级对话框提示用户更新
- 支持多种设备类型（Phone、Tablet、PC/2in1、TV、Wearable）
- 提供更新状态监听能力（元服务场景）

**版本要求**：
- 起始版本：5.0.0(12)
- 元服务支持：从6.0.0(20)版本开始

## 使用场景

### 触发词
- "检查应用更新"
- "检测新版本"
- "显示更新对话框"
- "应用版本更新"
- "应用市场更新"

### 能做
- 检查当前应用是否有可更新版本
- 显示升级对话框提示用户进行版本更新
- 获取新版本信息（版本名称、版本号）
- 监听元服务更新状态（仅元服务场景）

### 绝不做
- 不支持模拟器运行（必须使用真机调试）
- 不支持未上架应用市场的应用
- 不支持邀请测试和公开测试版本
- 不支持签名信息不一致的应用更新检测

### 补充
- 本地安装版本须低于应用市场在架版本才能检查到更新
- 本地安装版本须和应用市场在架版本签名信息保持一致
- 同一设备下元服务的调用次数不超过6次/天、每30分钟调用次数不超过1次（仅元服务场景）

## 调用规范和规则

### 输入约束
- 应用必须已上架应用市场
- 应用签名信息必须与应用市场版本一致
- 必须使用真机调试（不支持模拟器）
- Context参数必须为common.UIAbilityContext类型

### 执行约束
- 最大耗时：异步调用，超时时间20秒
- 调用频次限制：元服务场景下，同一设备调用次数不超过6次/天，每30分钟不超过1次
- 必须在前台调用（应用不在前台会返回错误码1009400004）

### 内容约束
- 禁止在模拟器环境调用
- 禁止对未上架应用调用更新检查
- 禁止绕过用户确认直接执行更新
- 禁止在后台静默调用更新检查

### 降级约束
- 网络失败：提示用户检查网络连接，稍后重试
- 服务不可用：记录错误日志，降级为手动检查更新
- 设备不支持：提示用户当前设备不支持应用内更新功能
- 应用未上架：提示用户应用暂未上架应用市场

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用已上架应用市场
2. 确认使用真机调试环境
3. 确认应用在前台运行
4. 确认设备类型支持（Phone、Tablet、PC/2in1、TV、Wearable）

**参数准备**：
```typescript
import { updateManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
```

### 步骤2：检查应用更新

**示例代码**：
```typescript
async function checkAppUpdate(context: common.UIAbilityContext): Promise<void> {
  try {
    const checkResult: updateManager.CheckUpdateResult = await updateManager.checkAppUpdate(context);
    
    if (checkResult.updateAvailable === updateManager.UpdateAvailableCode.LATER_VERSION_EXIST) {
      hilog.info(0, 'TAG', '发现新版本');
      
      if (checkResult.versionName) {
        hilog.info(0, 'TAG', `新版本名称: ${checkResult.versionName}`);
      }
      if (checkResult.versionCode) {
        hilog.info(0, 'TAG', `新版本号: ${checkResult.versionCode}`);
      }
      
      await showUpdateDialog(context);
    } else {
      hilog.info(0, 'TAG', '当前已是最新版本');
    }
  } catch (error) {
    const err = error as BusinessError;
    handleUpdateError(err);
  }
}
```

### 步骤3：显示更新对话框

**示例代码**：
```typescript
async function showUpdateDialog(context: common.UIAbilityContext): Promise<void> {
  try {
    const resultCode: updateManager.ShowUpdateResultCode = await updateManager.showUpdateDialog(context);
    
    if (resultCode === updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS) {
      hilog.info(0, 'TAG', '更新对话框显示成功');
    } else {
      hilog.error(0, 'TAG', '更新对话框显示失败');
    }
  } catch (error) {
    const err = error as BusinessError;
    handleUpdateError(err);
  }
}
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
function handleUpdateError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      hilog.error(0, 'TAG', '参数错误');
      break;
    case 1009400001:
      hilog.error(0, 'TAG', 'SA连接错误');
      break;
    case 1009400002:
      hilog.error(0, 'TAG', '服务请求错误');
      break;
    case 1009400003:
      hilog.error(0, 'TAG', '网络错误，请检查网络连接');
      break;
    case 1009400004:
      hilog.error(0, 'TAG', '应用不在前台，请在前台调用');
      break;
    case 1009400005:
      hilog.error(0, 'TAG', '未同意隐私协议');
      break;
    case 1009400006:
      hilog.error(0, 'TAG', '调用频率超限，请稍后重试');
      break;
    case 1009400007:
      hilog.error(0, 'TAG', '其他错误');
      break;
    default:
      hilog.error(0, 'TAG', `未知错误: ${error.code}, ${error.message}`);
  }
}
```

### 步骤5：降级处理

**降级处理代码**：
```typescript
async function checkUpdateWithFallback(context: common.UIAbilityContext): Promise<void> {
  try {
    await checkAppUpdate(context);
  } catch (error) {
    const err = error as BusinessError;
    
    if (err.code === 1009400003) {
      hilog.warn(0, 'TAG', '网络不可用，降级为手动检查');
      showManualUpdateTip();
    } else if (err.code === 1009400004) {
      hilog.warn(0, 'TAG', '应用不在前台，延迟检查');
      scheduleBackgroundCheck();
    } else {
      hilog.error(0, 'TAG', '更新检查失败，请稍后重试');
    }
  }
}

function showManualUpdateTip(): void {
  console.log('网络不可用，请手动检查更新或稍后重试');
}

function scheduleBackgroundCheck(): void {
  console.log('已安排稍后在应用前台时检查更新');
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查context参数是否为common.UIAbilityContext类型 |
| 1009400001 | SA连接错误 | 重试或检查应用市场服务是否正常 |
| 1009400002 | 服务请求错误 | 检查应用是否已上架应用市场 |
| 1009400003 | 网络错误 | 检查网络连接，稍后重试 |
| 1009400004 | 应用不在前台 | 确保在前台调用API |
| 1009400005 | 未同意隐私协议 | 引导用户同意隐私协议 |
| 1009400006 | 调用频率超限 | 降低调用频率，元服务场景每天不超过6次 |
| 1009400007 | 其他错误 | 查看错误日志，联系技术支持 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.AppGalleryKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0",
    "@kit.AbilityKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API：5.0.0(12)及以上
- DevEco Studio：3.1及以上
- 设备要求：真机调试（不支持模拟器）
- 支持设备：Phone、Tablet、PC/2in1（API 12+）、TV（API 19+）、Wearable（API 20+）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.AppGalleryKit'
```
**解决方法**：确保项目API版本不低于5.0.0(12)，并在oh-package.json5中添加依赖

**问题2：Context类型错误**
```
Error: Type 'UIAbilityContext' is not assignable to type 'common.UIAbilityContext'
```
**解决方法**：确保正确导入类型：`import type { common } from '@kit.AbilityKit'`

**问题3：权限配置缺失**
```
Error: Permission denied
```
**解决方法**：应用市场更新功能不需要额外权限配置，检查应用签名是否正确

## 常见问题与解决方法

### Q1：模拟器上提示"无法获取内容，请点击屏幕重试"
**原因**：应用市场更新功能不支持模拟器
**解决方法**：
- 使用真机调试
- 在模拟器上暂时禁用更新检查功能

### Q2：检查不到更新版本
**原因**：可能是版本、签名或测试状态问题
**解决方法**：
- 确认本地安装版本低于应用市场版本
- 确认本地版本与应用市场版本签名信息一致
- 确认应用不是邀请测试或公开测试版本

### Q3：调用接口返回错误码1009400004
**原因**：应用不在前台运行
**解决方法**：
- 确保应用在前台时调用API
- 在onPageShow或onClick事件中调用
- 避免在onCreate等生命周期过早调用

### Q4：元服务调用频率受限
**原因**：元服务更新检查有调用频率限制
**解决方法**：
- 同一设备每天调用不超过6次
- 每30分钟调用不超过1次
- 建议用户主动触发检查，避免自动频繁检查

### Q5：TV或Wearable设备无法正常使用
**原因**：不同API版本支持的设备类型不同
**解决方法**：
- API 19+支持TV设备
- API 20+支持Wearable设备
- 在不支持设备上返回固定值，需要做兼容处理

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "updateAvailable": true,
  "versionName": "1.0.1",
  "versionCode": 1001,
  "dialogShown": true,
  "apiUsed": [
    "updateManager.checkAppUpdate",
    "updateManager.showUpdateDialog"
  ]
}
```

## 参考文档

- [应用市场更新功能开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-update)
- [updateManager API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-updatemanager)

## 完整示例代码

- [ArkTS示例 - 检查更新](assets/check_update_example.ets)
- [ArkTS示例 - 完整流程](assets/complete_update_example.ets)

## 测试用例

### 正向测试用例
- [正常检查更新流程](tests/test_positive.py)：应用已上架，有新版本，检查更新成功
- [显示更新对话框](tests/test_positive.py)：有新版本时成功显示更新对话框

### 边界测试用例
- [当前已是最新版本](tests/test_boundary.py)：检查更新返回无新版本
- [调用频率限制](tests/test_boundary.py)：元服务场景下测试调用频率限制

### 异常测试用例
- [网络异常](tests/test_exception.py)：网络不可用时的错误处理
- [应用未上架](tests/test_exception.py)：应用未上架应用市场时的错误处理
- [模拟器环境](tests/test_exception.py)：在模拟器上调用API的错误处理