---
name: hmos-share-kit-knock-share-content
description: 实现手机与手机之间碰一碰内容分享功能，支持文本、链接、图片、文件等类型数据分享，提供三种卡片模板展示，支持预览图延迟更新，适用于快速分享场景
---

# 碰一碰内容分享技能

## 功能描述

本技能实现HarmonyOS手机与手机之间的碰一碰内容分享功能。用户通过轻碰手机即可分享文本、链接、图片、文件等内容到另一台HarmonyOS设备，支持三种卡片模板展示（纯图片布局、沉浸式大卡布局、白卡上下布局），提供预览图延迟更新能力，支持异常场景处理。

**核心能力**：
- 注册碰一碰事件监听
- 构造分享数据（文本、链接、图片、文件）
- 设置分享预览图和卡片模板
- 预览图延迟更新
- 异常场景终止分享
- App Linking和Deep Linking跳转

**技术特点**：
- 基于harmonyShare模块实现
- 支持同步和异步API调用
- 提供三种卡片模板自适应展示
- 支持云端预览图延迟加载
- 完整的错误处理机制

**API版本要求**：
- 基础功能：HarmonyOS 5.0.0(12)及以上
- 预览图更新：HarmonyOS 6.0.0(20)及以上
- 终止分享优化：HarmonyOS 6.0.2(22)及以上

## 使用场景

### 触发词
- "碰一碰分享"
- "碰一碰内容分享"
- "手机碰一碰分享"
- "knock share"
- "Share Kit内容分享"
- "碰一碰分享文本"
- "碰一碰分享链接"
- "碰一碰分享图片"
- "碰一碰分享文件"

### 能做
- 注册和监听碰一碰分享事件
- 分享文本内容（纯文本、链接等）
- 分享图片内容（单张或多张）
- 分享文件内容
- 设置分享预览图和卡片样式
- 实现云端预览图延迟更新
- 处理分享异常场景（无内容、下载失败等）
- 使用App Linking或Deep Linking实现应用跳转
- 提供用户引导和提示

### 绝不做
- 不支持Tablet设备的碰一碰分享
- 不支持非HarmonyOS设备的分享
- 不支持超过文件大小限制的内容分享
- 不处理沙箱接收功能（属于另一个技能）
- 不处理隔空传送功能（属于另一个技能）
- 不处理分享接收端逻辑

### 补充
- 需要两台设备均支持NFC功能
- 需要设备登录华为账号（5.0.0.123 SP16及以上版本会显示对端身份信息）
- 建议使用系统提供的碰一碰引导资源文件
- 需要根据分享内容类型选择合适的卡片模板
- 预览图推荐分辨率：最小600*800px，最大3000*4000px
- 推荐使用App Linking实现应用未安装时的跳转

## 调用规范和规则

### 输入约束
- 文本内容：无长度限制，建议不超过1000字符
- 链接内容：必须是有效的URL格式
- 图片文件：支持常见图片格式（jpg、png、gif等），单个文件最大3000*4000px
- 其他文件：需指定正确的文件路径和URI
- 预览图：最小宽高比1:4，最大分辨率3000*4000px
- 标题：建议20个中文左右，最多2行显示
- 描述：建议1行显示

### 执行约束
- 注册监听时机：在页面aboutToAppear生命周期中注册
- 注销监听时机：在页面aboutToDisappear生命周期中注销
- 回调响应时间：建议在100ms内响应碰一碰事件
- 预览图下载超时：建议不超过5秒
- API调用频次：无限制，但避免频繁注册注销
- 最大迭代次数：无限制

### 内容约束
- 禁止生成：恶意代码、病毒文件、侵权内容
- 禁止使用高危函数：eval、exec、os.system等
- 禁止操作：访问非授权文件路径、获取用户敏感信息
- 分享内容必须合法合规
- 不得分享违法违规内容

### 降级约束
- 网络失败：调用`sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR)`终止分享
- 内容下载失败：调用`sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR)`终止分享
- 当前界面无可分享内容：调用`sharableTarget.clarifyNonShare()`提示用户
- 预览图加载失败：使用默认预览图或延迟更新预览图
- 应用未安装：使用App Linking跳转应用市场或浏览器打开
- 设备不支持：提示用户设备不支持碰一碰分享功能

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持NFC功能
2. 检查HarmonyOS版本是否满足要求（5.0.0(12)及以上）
3. 检查分享内容是否准备就绪
4. 准备分享预览图（如有云端图片需提前下载）
5. 确定分享内容类型（文本、链接、图片、文件）

**参数准备**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

// 准备分享数据类型
const SHARE_TYPES = {
  TEXT: utd.UniformDataType.PLAIN_TEXT,
  HYPERLINK: utd.UniformDataType.HYPERLINK,
  IMAGE: utd.UniformDataType.IMAGE,
  FILE: utd.UniformDataType.FILE
};

// 准备窗口ID（用于注册碰一碰事件）
let windowId: number = 999; // 实际使用时需替换为正确的windowId
```

### 步骤2：注册碰一碰事件监听

**示例代码**：
```typescript
@Component
export struct KnockShareComponent {
  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    // 碰一碰事件回调处理
    this.handleKnockShare(sharableTarget);
  }

  aboutToAppear(): void {
    // 注册碰一碰分享监听
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: windowId
    };
    harmonyShare.on('knockShare', capabilityRegistry, this.immersiveCallback);
  }

  aboutToDisappear(): void {
    // 注销碰一碰分享监听
    let capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: windowId
    };
    harmonyShare.off('knockShare', capabilityRegistry, this.immersiveCallback);
  }

  build() {
    // UI构建
  }
}
```

### 步骤3：构造分享数据

**纯图片布局分享**：
```typescript
// 构造纯图片分享数据
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let filePath = contextFaker.filesDir + '/exampleImage.jpg';

let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.IMAGE,
  thumbnailUri: fileUri.getUriFromPath(filePath)
});

// 发起分享
sharableTarget.share(shareData);
```

**沉浸式大卡布局分享（链接类型）**：
```typescript
// 构造链接分享数据（预览图宽高比 < 1:1）
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let filePath = contextFaker.filesDir + '/preview.jpg';

let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://example.com/share',
  title: '碰一碰分享标题',
  description: '这是碰一碰分享的描述内容',
  thumbnailUri: fileUri.getUriFromPath(filePath)
});

// 发起分享
sharableTarget.share(shareData);
```

**白卡上下布局分享（链接类型）**：
```typescript
// 构造链接分享数据（预览图宽高比 > 1:1）
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let filePath = contextFaker.filesDir + '/preview-landscape.jpg';

let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://example.com/share',
  title: '碰一碰分享标题',
  description: '这是碰一碰分享的描述内容',
  thumbnailUri: fileUri.getUriFromPath(filePath)
});

// 发起分享
sharableTarget.share(shareData);
```

### 步骤4：预览图延迟更新

**示例代码**：
```typescript
// 云端预览图无法及时下载时，先发送数据再更新预览图
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.HYPERLINK,
  content: 'https://example.com/share',
  title: '碰一碰分享标题',
  description: '碰一碰分享描述'
});

// 先发送分享数据
sharableTarget.share(shareData);

// 延迟更新预览图
setTimeout(() => {
  let uiContext: UIContext = this.getUIContext();
  let contextFaker: Context = uiContext.getHostContext() as Context;
  let filePath = contextFaker.filesDir + '/downloaded-preview.jpg';
  
  sharableTarget.updateShareData({
    thumbnailUri: fileUri.getUriFromPath(filePath)
  });
}, 5000);
```

### 步骤5：异常场景处理

**当前界面无可分享内容**：
```typescript
handleKnockShare(sharableTarget: harmonyShare.SharableTarget) {
  // 判断当前界面是否支持分享
  if (!this.canShare()) {
    // 终止分享并提示用户
    sharableTarget.clarifyNonShare({ 
      message: '请在支持碰一碰分享的界面再试' 
    });
    return;
  }
  
  // 正常分享流程
  this.performShare(sharableTarget);
}
```

**下载失败等异常场景**：
```typescript
async handleKnockShare(sharableTarget: harmonyShare.SharableTarget) {
  try {
    // 尝试下载分享内容
    let content = await this.downloadShareContent();
    let shareData = this.buildShareData(content);
    sharableTarget.share(shareData);
  } catch (error) {
    // 下载失败，终止分享
    sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
  }
}
```

**无网络场景**：
```typescript
handleKnockShare(sharableTarget: harmonyShare.SharableTarget) {
  // 检查网络连接
  if (!this.isNetworkAvailable()) {
    sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR);
    return;
  }
  
  // 正常分享流程
  this.performShare(sharableTarget);
}
```

### 步骤6：App Linking跳转实现

**示例代码**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';

@Component
export struct AppLinkingShareComponent {
  private onBackGround = () => {
    this.immersiveDisablingListening();
  }

  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget) => {
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;
    let filePath = contextFaker.filesDir + '/app-linking-preview.jpg';
    
    // 构造App Linking分享数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://sharekitdemo.drcn.agconnect.link/ZB3p',
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: '碰一碰分享卡片标题',
      description: '碰一碰分享卡片描述'
    });
    
    sharableTarget.share(shareData);
  }

  private immersiveListening() {
    harmonyShare.on('knockShare', this.immersiveCallback);
  }

  private immersiveDisablingListening() {
    harmonyShare.off('knockShare', this.immersiveCallback);
  }

  aboutToAppear(): void {
    this.immersiveListening();
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.on('onBackGround', this.onBackGround);
  }

  aboutToDisappear(): void {
    this.immersiveDisablingListening();
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onBackGround', this.onBackGround);
  }

  onPageHide(): void {
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  build() {
    // UI构建
  }
}
```

### 步骤7：错误处理

**完整错误处理代码**：
```typescript
handleKnockShareError(sharableTarget: harmonyShare.SharableTarget, error: Error) {
  // 根据错误类型选择不同的处理方式
  if (error.message.includes('network')) {
    // 无网络错误
    sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR);
  } else if (error.message.includes('download')) {
    // 下载失败错误
    sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
  } else if (error.message.includes('no content')) {
    // 无内容错误
    sharableTarget.clarifyNonShare({ 
      message: '当前界面无可分享内容，请前往内容详情页再试' 
    });
  } else {
    // 其他错误，使用下载错误提示
    sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| NO_CONTENT_ERROR (1) | 无内容分享场景 | 检查当前界面是否有可分享内容，引导用户前往支持分享的界面 |
| NO_INTERNET_ERROR (2) | 无网络场景 | 检查网络连接状态，提示用户检查网络设置 |
| DOWNLOAD_ERROR (3) | 下载失败场景 | 检查下载链接是否有效，尝试重新下载或使用本地资源 |
| 401 | 参数错误 | 检查API参数类型和格式是否正确 |
| 801 | 设备不支持 | 提示用户当前设备不支持碰一碰分享功能 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "HarmonyOS SDK",
    "@kit.ArkData": "HarmonyOS SDK",
    "@kit.CoreFileKit": "HarmonyOS SDK",
    "@kit.AbilityKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- DevEco Studio：最新版本
- 开发语言：ArkTS
- 模型：Stage模型

### 常见编译问题

**问题1：找不到ShareKit模块**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：确保项目API版本不低于12，在build-profile.json5中配置正确的compileSdkVersion

**问题2：windowId参数错误**
```
Error: Parameter error. The windowId must be a valid number.
```
**解决方法**：使用正确的windowId，可以通过UIContext获取

**问题3：文件路径不存在**
```
Error: File not found at path: /data/...
```
**解决方法**：确保文件路径真实存在，使用context.filesDir获取正确的沙箱路径

**问题4：预览图格式不支持**
```
Error: Unsupported image format
```
**解决方法**：使用支持的图片格式（jpg、png、gif），确保图片未损坏

## 常见问题与解决方法

### Q1：碰一碰分享无响应
**原因**：
- 设备不支持NFC功能
- HarmonyOS版本过低
- 未正确注册事件监听
- 窗口ID错误

**解决方法**：
- 检查设备NFC功能是否开启
- 确认HarmonyOS版本不低于5.0.0(12)
- 确保在aboutToAppear中注册监听
- 使用正确的windowId参数

### Q2：预览图显示模糊或不显示
**原因**：
- 预览图分辨率过低或过高
- 预览图宽高比不符合要求
- 文件路径错误

**解决方法**：
- 使用推荐分辨率600*800px至3000*4000px
- 确保预览图宽高比符合卡片模板要求
- 使用fileUri.getUriFromPath转换正确的URI格式
- 对于云端图片，使用预览图延迟更新能力

### Q3：分享内容跳转失败
**原因**：
- 链接格式错误
- 目标应用未安装且未配置App Linking
- 使用Deep Linking但应用未安装

**解决方法**：
- 检查链接格式是否正确
- 配置App Linking实现应用未安装时的降级方案
- 使用App Linking Kit的直达应用市场能力
- 使用延迟链接能力提升用户体验

### Q4：Tablet设备无法使用碰一碰分享
**原因**：碰一碰分享在Tablet设备上不支持

**解决方法**：
- 在代码中判断设备类型
- Tablet设备使用其他分享方式（如系统分享面板）
- 提示用户使用其他分享方式

### Q5：如何判断使用哪种卡片模板
**原因**：不同内容类型适合不同的卡片模板

**解决方法**：
- 纯图片布局：分享图片、文件等无需标题描述的内容，只传递thumbnailUri
- 沉浸式大卡布局：分享链接，预览图宽高比<1:1，传递title、description、thumbnailUri
- 白卡上下布局：分享链接，预览图宽高比>1:1，传递title、description、thumbnailUri

### Q6：如何处理应用未安装场景
**原因**：使用Deep Linking跳转时，目标应用可能未安装

**解决方法**：
- 使用App Linking代替Deep Linking
- 配置App Linking Kit直达应用市场能力
- 使用延迟链接能力，应用安装后仍能获取分享内容
- 参考[App Linking Kit简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-introduction)和[直达应用市场能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-direct-to-ag)

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shareType": "knockShare",
  "contentType": "text|hyperlink|image|file",
  "cardTemplate": "pureImage|immersiveCard|whiteCard",
  "previewUpdated": true|false,
  "apiUsed": [
    "harmonyShare.on('knockShare')",
    "sharableTarget.share()",
    "sharableTarget.updateShareData()",
    "harmonyShare.off('knockShare')"
  ],
  "deviceType": "phone",
  "harmonyOSVersion": "5.0.0(12)"
}
```

## 参考文档

- [API开发指南 - 碰一碰内容分享](references/knock-share-between-phones-content.md)
- [API参考说明 - harmonyShare模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [碰一碰分享设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/onehop-0000002354602581)
- [使用App Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-linking-startup)
- [使用Deep Linking实现应用间跳转](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/deep-linking-startup)
- [App Linking Kit简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-introduction)
- [直达应用市场能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-direct-to-ag)
- [延迟链接能力](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/applinking-deferredlink)

## 完整示例代码

- [ArkTS示例 - 基础碰一碰分享](assets/basic-knock-share.ets)
- [ArkTS示例 - 预览图延迟更新](assets/preview-delay-update.ets)
- [ArkTS示例 - App Linking分享](assets/app-linking-share.ets)
- [ArkTS示例 - 异常处理](assets/error-handling.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试纯文本分享](tests/test_text_share.py)：验证纯文本内容分享功能
- [测试链接分享](tests/test_hyperlink_share.py)：验证链接内容分享功能
- [测试图片分享](tests/test_image_share.py)：验证图片内容分享功能
- [测试文件分享](tests/test_file_share.py)：验证文件内容分享功能
- [测试预览图延迟更新](tests/test_preview_update.py)：验证云端预览图延迟更新功能

### 边界测试用例
- [测试最大文件大小](tests/test_max_file_size.py)：验证文件大小边界限制
- [测试预览图分辨率](tests/test_preview_resolution.py)：验证预览图分辨率边界
- [测试标题字符长度](tests/test_title_length.py)：验证标题字符长度限制
- [测试并发分享请求](tests/test_concurrent_share.py)：验证多个分享请求处理

### 异常测试用例
- [测试无网络场景](tests/test_no_network.py)：验证无网络错误处理
- [测试下载失败场景](tests/test_download_error.py)：验证下载失败错误处理
- [测试无内容场景](tests/test_no_content.py)：验证无内容提示功能
- [测试设备不支持场景](tests/test_unsupported_device.py)：验证设备不支持错误处理
- [测试参数错误场景](tests/test_invalid_params.py)：验证参数错误处理