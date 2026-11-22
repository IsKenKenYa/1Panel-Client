---
name: hmos-share-kit-gestures-share-app-linking
description: 实现通过隔空传送分享App Linking直达应用，支持注册/取消隔空传送监听事件，3秒内发起分享，适用于应用间跳转和内容分享场景
---

# 分享App Linking直达应用技能

## 功能描述

本技能提供通过隔空传送功能分享App Linking实现应用直达的能力。用户通过抓取握拳手势触发隔空传送事件，应用监听该事件并分享App Linking链接，实现跨端应用间跳转和内容传递。

**核心功能**：
- 注册隔空传送监听事件（gesturesShare）
- 取消隔空传送监听事件
- 构造分享数据（支持App Linking、文本、图片等）
- 发起跨端分享

**技术特点**：
- 基于华为分享（HarmonyShare）能力
- 支持Stage模型
- 异步回调机制
- 系统能力：SystemCapability.Collaboration.HarmonyShare

**适用场景**：
- 应用间跳转
- 内容分享
- 跨端数据传递

## 使用场景

### 触发词
- "隔空传送分享"
- "分享App Linking"
- "应用直达分享"
- "gesturesShare"
- "隔空分享"

### 能做
- 注册隔空传送分享监听事件，响应用户手势
- 构造包含App Linking的分享数据
- 在3秒内发起跨端分享
- 取消隔空传送监听事件
- 处理分享失败和拒绝场景

### 绝不做
- 不处理非App Linking类型的分享（使用其他Share Kit技能）
- 不支持后台无限制监听（必须在页面生命周期内管理）
- 不处理超过3秒延迟的分享请求（会导致超时失败）

### 补充
- 应用需接入App Linking以确保端到端完整体验
- 仅支持Stage模型
- 起始API版本：6.0.0(20)
- 设备行为差异：Tablet中无效果

## 调用规范和规则

### 输入约束
- 分享数据类型：App Linking（HYPERLINK）、文本、图片等
- App Linking链接格式：必须符合App Linking规范
- 缩略图大小：不超过32KB
- 分享回调响应时间：3秒内

### 执行约束
- 必须在页面生命周期内注册和取消监听
- 建议在aboutToAppear注册监听
- 建议在aboutToDisappear取消监听
- 应用退至后台时必须取消监听
- 最多支持同时注册1个回调函数

### 内容约束
- 禁止分享敏感信息（密码、密钥等）
- 禁止在回调中执行耗时操作（超过3秒）
- 禁止使用同步阻塞代码
- 禁止跳过参数校验

### 降级约束
- Tablet设备降级为不支持，跳过注册
- 3秒超时失败时，提示用户重试
- 网络失败时，使用SharableErrorCode.NO_INTERNET_ERROR拒绝分享
- 无内容可分享时，使用SharableErrorCode.NO_CONTENT_ERROR拒绝分享

## 调用流程和步骤

### 步骤1：导入必要模块

**前置校验**：
1. 确认项目使用Stage模型
2. 确认API版本 >= 6.0.0(20)
3. 确认设备非Tablet类型

**导入模块**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
```

### 步骤2：定义分享回调函数

**示例代码**：
```typescript
// 定义隔空传送分享事件监听回调
private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
  // 获取UI上下文
  let uiContext: UIContext = this.getUIContext();
  let context: Context = uiContext.getHostContext() as Context;
  
  // 构造分享数据（App Linking示例）
  let filePath = context.filesDir + '/thumbnail.jpg'; // 缩略图路径
  let shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utd.UniformDataType.HYPERLINK,        // 数据类型：超链接
    content: 'https://example.drcn.agconnect.link/XXXX', // App Linking地址
    thumbnailUri: fileUri.getUriFromPath(filePath),      // 缩略图URI
    title: '分享卡片标题',
    description: '分享卡片描述'
  });
  
  // 在3秒内发起分享
  sharableTarget.share(shareData)
    .then(() => {
      console.info('分享成功');
    })
    .catch((error: Error) => {
      console.error('分享失败:', error.message);
      // 拒绝分享（可选）
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
}
```

**错误处理**：
```typescript
private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
  try {
    let shareData = this.buildShareData();
    sharableTarget.share(shareData)
      .then(() => {
        console.info('分享成功');
      })
      .catch((error: Error) => {
        this.handleShareError(error, sharableTarget);
      });
  } catch (error) {
    console.error('构造分享数据失败:', error);
    sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
  }
}

private handleShareError(error: Error, sharableTarget: harmonyShare.SharableTarget) {
  console.error('分享失败:', error.message);
  // 根据错误类型选择拒绝原因
  let errorCode = harmonyShare.SharableErrorCode.NO_CONTENT_ERROR;
  if (error.message.includes('network')) {
    errorCode = harmonyShare.SharableErrorCode.NO_INTERNET_ERROR;
  } else if (error.message.includes('download')) {
    errorCode = harmonyShare.SharableErrorCode.DOWNLOAD_ERROR;
  }
  sharableTarget.reject(errorCode);
}
```

### 步骤3：注册隔空传送监听

**示例代码**：
```typescript
// 注册监听（页面显示时）
aboutToAppear(): void {
  this.immersiveListening();
  // 监听应用退至后台事件
  let uiContext: UIContext = this.getUIContext();
  let context: Context = uiContext.getHostContext() as Context;
  context.eventHub.on('onBackGround', this.onBackGround);
}

// 注册监听事件
private immersiveListening(): void {
  harmonyShare.on('gesturesShare', this.immersiveCallback);
  console.info('已注册隔空传送监听');
}
```

### 步骤4：取消隔空传送监听

**示例代码**：
```typescript
// 取消监听（页面隐藏时）
aboutToDisappear(): void {
  this.immersiveDisablingListening();
  // 取消监听应用退至后台事件
  let uiContext: UIContext = this.getUIContext();
  let context: Context = uiContext.getHostContext() as Context;
  context.eventHub.off('onBackGround', this.onBackGround);
}

// 页面隐藏回调
onPageHide(): void {
  let uiContext: UIContext = this.getUIContext();
  let context: Context = uiContext.getHostContext() as Context;
  context.eventHub.emit('onBackGround');
}

// 应用退至后台回调
private onBackGround = (): void => {
  this.immersiveDisablingListening();
}

// 取消监听事件
private immersiveDisablingListening(): void {
  harmonyShare.off('gesturesShare', this.immersiveCallback);
  console.info('已取消隔空传送监听');
}
```

### 步骤5：降级处理

**降级方案**：
```typescript
// 设备能力检查
private checkDeviceCapability(): boolean {
  // Tablet设备不支持
  if (deviceInfo.deviceType === 'tablet') {
    console.warn('Tablet设备不支持隔空传送功能');
    return false;
  }
  return true;
}

// 使用前检查
aboutToAppear(): void {
  if (!this.checkDeviceCapability()) {
    console.info('当前设备不支持隔空传送，跳过注册');
    return;
  }
  this.immersiveListening();
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查回调函数参数类型是否正确 |
| NO_CONTENT_ERROR (1) | 无内容分享场景 | 确认分享数据已正确构造 |
| NO_INTERNET_ERROR (2) | 无网络场景 | 检查网络连接，提示用户检查网络 |
| DOWNLOAD_ERROR (3) | 下载失败场景 | 检查下载链接是否有效，重试下载 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "^6.0.0",
    "@kit.ArkData": "^6.0.0",
    "@kit.CoreFileKit": "^6.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：>= 6.0.0 (API 20)
- 开发环境：DevEco Studio >= 4.0
- 模型约束：Stage模型
- 设备类型：Phone、2in1（不支持Tablet）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：检查SDK版本是否 >= 6.0.0，在build-profile.json5中配置正确的API版本

**问题2：类型错误**
```
Error: Property 'immersiveCallback' does not exist on type 'XXX'
```
**解决方法**：确保回调函数定义为类成员变量，使用箭头函数绑定this

**问题3：权限错误**
```
Error: Permission denied
```
**解决方法**：确认应用已申请必要的系统能力SystemCapability.Collaboration.HarmonyShare

## 常见问题与解决方法

### Q1：隔空传送监听未触发
**原因**：
- 设备类型为Tablet（不支持）
- 未在页面生命周期内正确注册
- 回调函数未正确绑定

**解决方法**：
- 检查设备类型，Tablet设备不支持
- 确保在aboutToAppear注册，aboutToDisappear取消
- 使用箭头函数确保this绑定正确

### Q2：分享超时失败
**原因**：
- 回调函数中执行耗时操作超过3秒
- 网络请求阻塞
- 主线程执行同步代码

**解决方法**：
- 立即调用sharableTarget.share()，不要在回调中执行耗时操作
- 使用异步操作，避免阻塞主线程
- 预先准备分享数据，减少构造时间

### Q3：应用退至后台后监听未取消
**原因**：
- 未监听应用生命周期事件
- 未在onPageHide中触发取消监听

**解决方法**：
- 在onPageHide中发送后台事件通知
- 监听应用退至后台事件并取消监听
- 使用eventHub进行页面间通信

### Q4：缩略图不显示或显示异常
**原因**：
- 缩略图大小超过32KB限制
- 缩略图URI格式不正确
- 文件路径不存在

**解决方法**：
- 使用ImagePacker压缩缩略图到32KB以下
- 使用fileUri.getUriFromPath()获取正确的URI
- 确保缩略图文件存在且可访问

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "message": "隔空传送分享App Linking功能已实现",
  "features": {
    "gestures_share_registered": true,
    "share_capability": "app_linking",
    "callback_response_time": "< 3s"
  },
  "apiUsed": [
    "harmonyShare.on('gesturesShare')",
    "harmonyShare.off('gesturesShare')",
    "sharableTarget.share()",
    "systemShare.SharedData",
    "fileUri.getUriFromPath()"
  ],
  "constraints": {
    "api_version": ">= 6.0.0(20)",
    "device_type": "Phone, 2in1 (Tablet not supported)",
    "model": "Stage Model Only"
  }
}
```

## 参考文档

### API开发指南
- [分享App Linking直达应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gestures-share-scenes)
- [使用App Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)

### API参考说明
- [harmonyShare（华为分享）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [systemShare（分享）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [uniformTypeDescriptor（标准化数据定义）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor)

## 完整示例代码

- [ArkTS完整示例](assets/gestures-share-example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试App Linking分享成功场景](tests/test_positive.py)
- [测试注册和取消监听流程](tests/test_positive.py)

### 边界测试用例
- [测试3秒超时场景](tests/test_boundary.py)
- [测试缩略图32KB限制](tests/test_boundary.py)

### 异常测试用例
- [测试Tablet设备不支持的降级处理](tests/test_exception.py)
- [测试网络失败场景](tests/test_exception.py)
- [测试无内容分享场景](tests/test_exception.py)