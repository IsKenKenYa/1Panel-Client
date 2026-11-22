---
name: hmos-share-kit-share-utd-video
description: 分享视频文件到目标设备或目标应用，支持MP4等视频格式，可生成封面图缩略图，最大支持200KB数据传输，适用于社交分享、视频传输场景
---

# 分享视频技能

## 功能描述

本技能用于实现HarmonyOS应用中视频文件的系统分享功能。通过Share Kit提供的systemShare模块，开发者可以将一个或多个视频文件分享到目标设备或目标应用，支持自动生成视频封面缩略图，提供详细的预览信息和描述。

**核心能力**：
- 支持单个或多个视频文件分享
- 支持生成视频封面缩略图（推荐）
- 支持精准的UTD类型匹配
- 支持自定义标题、描述信息
- 支持应用文件URI和用户文件URI

**技术特点**：
- 仅支持Stage模型
- 需配合Image Kit生成缩略图
- 需配合Core File Kit获取文件URI
- 使用系统分享面板提供标准分享服务

## 使用场景

### 触发词
- "分享视频"
- "视频分享"
- "发送视频到其他应用"
- "视频文件分享"
- "分享MP4文件"

### 能做
- 分享单个或多个视频文件到目标应用（如畅连、微信等）
- 分享视频到目标设备，视频会自动保存到图库
- 为视频生成封面缩略图，提供更好的预览效果
- 自定义视频标题和描述信息
- 使用精准的UTD类型匹配目标应用

### 绝不做
- 不支持直接分享视频内容流（需通过文件URI）
- 不支持分享超出200KB IPC传输限制的数据
- 不支持超过500条分享记录
- 不支持在FA模型中使用（仅Stage模型）
- 不支持分享不存在或无权限访问的视频文件

### 补充
- 推荐生成视频封面缩略图，提升用户体验
- 缩略图建议压缩至32KB以下，避免IPC传输失败
- 不传title字段时，显示视频文件名
- 不传description字段时，显示视频大小
- 不传thumbnail字段时，默认使用视频第一帧画面做预览图

## 调用规范和规则

### 输入约束
- 视频文件格式：支持MP4等标准视频格式
- 文件大小：无明确限制，但需满足IPC传输上限200KB（包含所有分享数据）
- 文件数量：单个或多个，最多支持500条记录
- 缩略图大小：建议32KB以下，使用JPEG/WebP/PNG格式
- 文件路径：必须是有效的应用沙箱路径或用户文件路径

### 执行约束
- 必须在Stage模型下使用
- 必须获取UIAbilityContext
- 必须先生成视频封面缩略图（推荐）
- 必须使用fileUri.getUriFromPath转换沙箱路径为URI
- 分享面板显示为异步操作，使用Promise回调

### 内容约束
- 禁止使用虚假或不存在的文件路径
- 禁止传递超过32KB的缩略图数据
- 禁止修改Want数据中的系统参数
- 禁止在回调函数中执行耗时操作
- 禁止使用eval、exec等高危函数

### 降级约束
- 文件不存在：提示用户选择有效文件
- 缩略图生成失败：使用视频第一帧作为默认预览
- 分享面板拉起失败：记录错误日志，提示用户稍后重试
- IPC数据超限：提示用户减少分享文件数量或压缩缩略图
- 权限不足：提示用户申请必要权限

## 调用流程和步骤

### 步骤1：导入必要模块

**导入模块**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：获取上下文和文件路径

**获取UIAbilityContext**：
```typescript
let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let thumbnailPath = contextFaker.filesDir + '/exampleImage.jpg';
let filePath = contextFaker.filesDir + '/exampleVideo.mp4';
```

**参数校验**：
```typescript
if (!filePath || !thumbnailPath) {
  console.error('文件路径不能为空');
  return;
}
```

### 步骤3：生成视频封面缩略图（推荐）

**创建图片源**：
```typescript
let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
```

**创建图片打包器并压缩**：
```typescript
let imagePacker: image.ImagePacker = image.createImagePacker();
let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
  format: 'image/jpeg',
  quality: 30
});
```

**注意事项**：
- 当前只支持'image/jpeg'、'image/webp'和'image/png'类型图片
- JPEG编码质量参数取值范围0-100，建议30左右适当压缩
- 图片过大可能导致want数据超限无法拉起分享

### 步骤4：构造分享数据

**获取精准UTD类型**：
```typescript
let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.mp4', utd.UniformDataType.VIDEO);
```

**创建SharedData对象**：
```typescript
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '视频标题',
  description: '视频描述',
  thumbnail: new Uint8Array(buffer)
});
```

**字段说明**：
- utd：统一数据类型，建议使用精准类型匹配目标应用
- uri：文件URI，通过fileUri.getUriFromPath获取
- title：不传时显示视频文件名
- description：不传时显示视频大小
- thumbnail：优先使用传递的缩略图，不传则使用视频第一帧

### 步骤5：额外增加分享数据（可选）

**添加更多视频记录**：
```typescript
shareData.addRecord({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath2),
  title: '视频标题2',
  description: '视频描述2'
});
```

**约束检查**：
- 最大支持500条记录
- 所有数据总大小不超过200KB

### 步骤6：启动分享面板

**创建ShareController**：
```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
```

**获取UIAbilityContext并显示**：
```typescript
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DETAIL
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

**参数说明**：
- selectionMode：SINGLE为单选模式，BATCH为批量模式
- previewMode：DETAIL为详细预览模式，推荐视频使用

### 步骤7：错误处理

**完整错误处理示例**：
```typescript
try {
  let shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: utdTypeId,
    uri: fileUri.getUriFromPath(filePath),
    title: '视频标题',
    description: '视频描述',
    thumbnail: new Uint8Array(buffer)
  });
  
  let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
  let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
  
  controller.show(context, {
    selectionMode: systemShare.SelectionMode.SINGLE,
    previewMode: systemShare.SharePreviewMode.DETAIL
  }).then(() => {
    console.info('ShareController show success.');
  }).catch((error: BusinessError) => {
    handleShareError(error);
  });
} catch (error) {
  console.error('构造分享数据失败:', error);
}

function handleShareError(error: BusinessError) {
  switch (error.code) {
    case 401:
      console.error('参数错误，请检查输入参数');
      break;
    case 1003702001:
      console.error('记录类型不支持，批量和多选模式仅支持文件类型');
      break;
    case 1003702002:
      console.error('IPC数据过大，请减少分享数量或压缩缩略图');
      break;
    default:
      console.error(`未知错误: ${error.code}, ${error.message}`);
  }
}
```

### 步骤8：降级处理

**缩略图生成失败降级**：
```typescript
async function generateThumbnailWithFallback(thumbnailPath: string): Promise<Uint8Array | undefined> {
  try {
    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: 30
    });
    return new Uint8Array(buffer);
  } catch (error) {
    console.warn('缩略图生成失败，将使用视频第一帧作为预览');
    return undefined;
  }
}
```

**分享失败降级**：
```typescript
async function shareWithFallback(shareData: systemShare.SharedData, context: common.UIAbilityContext) {
  try {
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    });
  } catch (error) {
    console.error('分享失败，尝试使用简化数据重新分享');
    let simpleShareData = new systemShare.SharedData({
      utd: shareData.getRecords()[0].utd,
      uri: shareData.getRecords()[0].uri
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(simpleShareData);
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    });
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，必填参数未指定或类型错误 | 检查输入参数是否正确，确保文件路径和URI有效 |
| 1003700001 | 分享记录数量超过最大值（500条） | 减少分享记录数量，保持在500条以内 |
| 1003702001 | 记录类型不支持，批量和多选模式仅支持文件类型 | 检查UTD类型，确保使用文件类型而非纯文本类型 |
| 1003702002 | IPC数据过大，超过200KB限制 | 减少分享数量或压缩缩略图质量，确保总数据小于200KB |
| 1003703001 | 解析数据失败 | 检查分享数据格式是否正确，确保URI和UTD类型有效 |
| 62980096 | 图片操作失败，可能是内存不足或解码异常 | 检查图片文件是否有效，尝试降低图片质量或尺寸 |
| 62980106 | 图片数据过大 | 增加压缩质量参数值，进一步压缩图片 |
| 62980119 | 图片编码失败 | 检查图片格式是否支持，尝试使用JPEG格式 |
| 13900002 | 文件不存在 | 检查文件路径是否正确，确保文件存在 |
| 13900012 | 权限不足 | 申请必要的文件访问权限 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.ShareKit": ">=4.1.0",
    "@kit.ArkData": ">=4.1.0",
    "@kit.AbilityKit": ">=4.1.0",
    "@kit.CoreFileKit": ">=9.0.0",
    "@kit.ImageKit": ">=6.0.0",
    "@kit.BasicServicesKit": ">=4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：>=4.1.0(11)
- DevEco Studio：>=3.1
- API Version：>=11
- 模型类型：仅支持Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：确保HarmonyOS SDK版本>=4.1.0，检查oh-package.json5依赖配置

**问题2：类型错误**
```
Error: Type 'UIContext' is not assignable to type 'common.UIAbilityContext'
```
**解决方法**：使用`uiContext.getHostContext() as common.UIAbilityContext`正确转换类型

**问题3：文件路径错误**
```
Error: File does not exist
```
**解决方法**：检查文件路径是否在应用沙箱目录内，使用`context.filesDir`获取正确路径

**问题4：缩略图过大**
```
Error: IPC data oversized
```
**解决方法**：增加图片压缩质量参数，将quality从30降低到20，或减小图片尺寸

## 常见问题与解决方法

### Q1：如何获取应用沙箱路径？
**原因**：需要使用正确的应用文件路径构造URI
**解决方法**：
- 使用`context.filesDir`获取应用沙箱路径
- 使用`fileUri.getUriFromPath()`将沙箱路径转换为URI
- 确保文件存在于应用沙箱目录内

### Q2：缩略图无法生成？
**原因**：图片文件不存在、格式不支持或内存不足
**解决方法**：
- 检查缩略图文件路径是否正确
- 确保图片格式为JPEG/WebP/PNG
- 降低图片质量参数（建议30）
- 释放不再使用的ImageSource和ImagePacker对象

### Q3：分享面板无法拉起？
**原因**：IPC数据超限或参数错误
**解决方法**：
- 检查分享数据总大小是否超过200KB
- 确保缩略图小于32KB
- 减少分享记录数量
- 检查文件URI是否有效

### Q4：如何分享多个视频文件？
**原因**：需要使用addRecord方法添加多条记录
**解决方法**：
- 创建第一个SharedData对象
- 使用`shareData.addRecord()`添加更多视频记录
- 注意记录总数不超过500条
- 注意数据总大小不超过200KB

### Q5：如何处理分享失败？
**原因**：各种错误情况需要降级处理
**解决方法**：
- 捕获BusinessError并检查错误码
- 根据错误类型提供降级方案
- 对于参数错误，提示用户检查输入
- 对于数据过大，尝试减少分享数量
- 对于权限问题，提示申请必要权限

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "share_video",
  "videoCount": 1,
  "thumbnailGenerated": true,
  "thumbnailSize": "28KB",
  "previewMode": "DETAIL",
  "selectionMode": "SINGLE",
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "fileUri.getUriFromPath",
    "image.createImageSource",
    "image.createImagePacker",
    "image.ImagePacker.packToData",
    "utd.getUniformDataTypeByFilenameExtension"
  ],
  "shareCompleted": true,
  "timestamp": "2026-07-02T23:10:00Z"
}
```

## 参考文档

- [API开发指南 - 分享视频](references/share-utd-video-guide.md)
- [API参考说明 - systemShare](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [API参考说明 - fileUri](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fileuri)
- [API参考说明 - ImageSource](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-imagesource)
- [API参考说明 - ImagePacker](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-imagepacker)

## 完整示例代码

- [ArkTS示例 - 分享视频（带缩略图）](assets/share-video-with-thumbnail.ets)
- [ArkTS示例 - 分享视频（无缩略图）](assets/share-video-simple.ets)
- [ArkTS示例 - 分享多个视频](assets/share-multiple-videos.ets)

## 测试用例

### 正向测试用例
- [测试分享单个MP4视频文件](tests/test_share_single_video.py)：验证基本分享功能
- [测试分享带缩略图的视频](tests/test_share_video_with_thumbnail.py)：验证缩略图生成和分享
- [测试分享多个视频文件](tests/test_share_multiple_videos.py)：验证批量分享功能

### 边界测试用例
- [测试分享500条视频记录](tests/test_share_max_records.py)：验证最大记录数量限制
- [测试缩略图32KB限制](tests/test_thumbnail_size_limit.py)：验证缩略图大小限制
- [测试200KB数据传输限制](tests/test_ipc_data_limit.py)：验证IPC传输大小限制

### 异常测试用例
- [测试分享不存在文件](tests/test_share_nonexistent_file.py)：验证文件不存在错误处理
- [测试分享无权限文件](tests/test_share_no_permission.py)：验证权限错误处理
- [测试缩略图生成失败](tests/test_thumbnail_generation_failed.py)：验证降级处理
- [测试IPC数据超限](tests/test_ipc_data_exceeded.py)：验证数据过大降级处理