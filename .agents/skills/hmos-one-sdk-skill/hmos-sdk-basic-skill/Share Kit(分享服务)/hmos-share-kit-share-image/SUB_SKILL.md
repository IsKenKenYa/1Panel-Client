---
name: hmos-share-kit-share-image
description: 分享图片到目标设备或目标应用，支持单张或多张图片分享，目标设备接收时图片保存到图库，目标应用接收时可便捷处理图片内容，适用于社交分享、图片传输场景
---

# 分享图片技能

## 功能描述

本技能提供HarmonyOS图片分享功能，支持将一张或多张图片通过系统分享面板分享到目标设备或目标应用。分享内容包括图片文件URI、标题、描述等信息，系统会自动匹配合适的目标应用（如畅连、图库等），并在分享面板中显示预览图。

**核心能力**：
- 支持单张或多张图片分享（最多500条记录）
- 自动识别图片类型（JPEG、PNG等）
- 提供图片预览功能（缩略图或原图）
- 支持自定义标题和描述
- 分享到目标设备时自动保存到图库
- 分享到目标应用时可便捷处理图片内容

**技术特点**：
- 仅支持Stage模型
- 使用系统分享面板（模态/悬浮窗形式）
- 支持单选和批量模式
- 支持详细预览图模式和卡片模式
- 数据总大小不超过IPC传输上限200KB

## 使用场景

### 触发词
- "分享图片" - 分享单张或多张图片
- "发送图片" - 发送图片到目标应用
- "图片分享" - 图片分享场景
- "分享照片" - 分享照片到社交应用
- "传输图片" - 图片传输场景

### 能做
- 分享本地图片文件到目标设备或目标应用
- 支持多种图片格式（JPEG、PNG、BMP等）
- 自定义图片标题和描述信息
- 设置图片缩略图预览
- 添加多条图片记录进行批量分享
- 获取精准的UTD类型以匹配精确的目标应用

### 绝不做
- 不支持分享网络图片（仅支持本地沙箱路径）
- 不支持超过500条记录的分享
- 不支持数据总大小超过200KB的分享
- 不支持非Stage模型的应用
- 不直接保存图片到图库（仅通过分享面板）
- 不处理图片编辑或压缩功能

### 补充
- 图片路径必须是应用沙箱路径
- 缩略图建议限制在32KB以下，否则可能导致want数据超限
- 建议传入精准的UTD类型（如JPEG、PNG），有助于匹配精确的目标应用
- 不传title字段时，默认显示图片文件名
- 不传description字段时，默认显示图片大小
- 不传thumbnail字段时，默认使用原图做预览图

## 调用规范和规则

### 输入约束
- 图片文件大小：无限制（但需满足IPC传输上限200KB总数据）
- 图片格式：JPEG、PNG、BMP、GIF、TIFF等标准图片格式
- 图片数量：最多500条记录
- 图片路径：必须是应用沙箱路径（如context.filesDir + '/example.jpg'）
- 缩略图大小：建议32KB以下
- title字段：字符串类型，可选
- description字段：字符串类型，可选

### 执行约束
- 最大耗时：分享面板显示为异步操作，无固定耗时限制
- 最大迭代次数：无需迭代
- API调用频次：无限制
- 必须在UI组件中调用（需要UIContext）

### 内容约束
- 禁止使用网络图片路径（仅支持应用沙箱路径）
- 禁止传入超过32KB的缩略图数据
- 禁止修改系统返回的want数据参数
- 禁止在非Stage模型中使用
- 禁止传入无效的文件路径

### 降级约束
- 文件路径不存在：提示用户检查路径并重新选择图片
- IPC数据超限：压缩缩略图或减少图片数量
- 分享面板显示失败：检查错误码并提示用户
- 权限不足：提示用户检查权限配置

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用使用Stage模型
2. 确认图片文件存在于应用沙箱路径
3. 确认图片格式为标准图片类型
4. 确认图片数量不超过500条
5. 确认缩略图大小不超过32KB（如果提供）

**参数准备**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

let uiContext: UIContext = this.getUIContext();
let contextFaker: Context = uiContext.getHostContext() as Context;
let filePath = contextFaker.filesDir + '/exampleImage.jpg';
```

### 步骤2：获取UTD类型

**示例代码**：
```typescript
let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
```

**说明**：
- 使用文件扩展名获取精准的UTD类型
- 第二个参数为父类型，用于限定搜索范围
- 建议传入精准类型以匹配精确的目标应用

### 步骤3：构造分享数据

**示例代码**：
```typescript
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath),
  title: '图片标题',
  description: '图片描述',
  // thumbnail: new Uint8Array() // 优先使用传递的缩略图预览，不传则默认使用原图做预览图
});
```

**说明**：
- `utd`：必填，统一数据类型
- `uri`：必填，文件URI（通过fileUri.getUriFromPath从沙箱路径获取）
- `title`：可选，不传时显示图片文件名
- `description`：可选，不传时显示图片大小
- `thumbnail`：可选，建议32KB以下

### 步骤4：添加额外的图片记录（可选）

**示例代码**：
```typescript
shareData.addRecord({
  utd: utdTypeId,
  uri: fileUri.getUriFromPath(filePath2),
  title: '图片标题2',
  description: '图片描述2'
});
```

**说明**：
- 支持添加多条图片记录
- 最多支持500条记录
- 所有数据总大小不超过200KB

### 步骤5：创建分享控制器并显示分享面板

**示例代码**：
```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
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

**说明**：
- `selectionMode`：选择模式，SINGLE（单选）或BATCH（批量）
- `previewMode`：预览模式，推荐图片使用DETAIL（详细预览图模式）
- 返回Promise对象，异步回调

### 步骤6：错误处理

**示例代码**：
```typescript
try {
  let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
  let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
  await controller.show(context, {
    selectionMode: systemShare.SelectionMode.SINGLE,
    previewMode: systemShare.SharePreviewMode.DETAIL
  });
  console.info('ShareController show success.');
} catch (error) {
  let businessError: BusinessError = error as BusinessError;
  switch (businessError.code) {
    case 401:
      console.error('Parameter error. Please check input parameters.');
      break;
    case 1003702001:
      console.error('Record types are not supported.');
      break;
    case 1003702002:
      console.error('IPC data is oversized. Please reduce data size.');
      break;
    default:
      console.error(`Unknown error. code: ${businessError.code}, message: ${businessError.message}`);
  }
}
```

### 步骤7：降级处理

**示例代码**：
```typescript
async function shareImageWithFallback(filePath: string): Promise<void> {
  try {
    // 尝试正常分享
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: fileUri.getUriFromPath(filePath)
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    });
  } catch (error) {
    let businessError: BusinessError = error as BusinessError;
    if (businessError.code === 1003702002) {
      // IPC数据超限，尝试不使用缩略图
      console.warn('IPC data oversized, trying without thumbnail...');
      let utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath)
      });
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });
    } else {
      console.error('Share failed, please check file path and permissions.');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误 | 检查输入参数是否正确，确保必填参数不为空 |
| 1003700001 | The number of records exceeds the maximum. 记录数量超过最大值 | 减少分享数据记录数量，最多支持500条 |
| 1003702001 | Record types are not support. 记录类型不支持 | 批量模式和多重选择模式仅支持FILE类型记录，检查UTD类型 |
| 1003702002 | IPC data is oversized. IPC数据超限 | 压缩缩略图大小或减少分享数据量，确保总数据不超过200KB |
| 1003703001 | Parse data failed. 数据解析失败 | 检查分享数据格式是否正确，确保URI有效 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "harmonyos",
    "@kit.ArkData": "harmonyos",
    "@kit.AbilityKit": "harmonyos",
    "@kit.CoreFileKit": "harmonyos",
    "@kit.BasicServicesKit": "harmonyos"
  }
}
```

### 环境要求
- HarmonyOS API version：至少11（4.1.0）
- 应用模型：仅支持Stage模型
- 开发环境：DevEco Studio 3.1及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit'
```
**解决方法**：确保项目SDK版本至少为API 11，检查build-profile.json5中的compileSdkVersion

**问题2：UIContext类型错误**
```
Error: Property 'getUIContext' does not exist on type '...'
```
**解决方法**：确保在UI组件（Component）中调用，使用正确的ArkUI语法

**问题3：文件路径无效**
```
Error: File not found: /exampleImage.jpg
```
**解决方法**：使用context.filesDir获取应用沙箱路径，确保文件存在

**问题4：缩略图过大**
```
Error: IPC data is oversized (1003702002)
```
**解决方法**：压缩缩略图至32KB以下，使用ImagePacker.packToData压缩图片质量

## 常见问题与解决方法

### Q1：如何获取应用沙箱路径？
**原因**：需要使用正确的路径才能获取文件URI
**解决方法**：
- 使用UIAbility的context.filesDir获取应用文件目录
- 示例：`let filePath = context.filesDir + '/exampleImage.jpg'`

### Q2：分享面板无法显示？
**原因**：可能参数错误或权限不足
**解决方法**：
- 检查context是否为common.UIAbilityContext类型
- 检查文件路径是否存在
- 查看错误码并针对性解决

### Q3：如何设置图片缩略图？
**原因**：缩略图可以提高分享面板的预览效果
**解决方法**：
- 使用Uint8Array存储缩略图数据
- 建议缩略图大小32KB以下
- 可使用ImagePacker.packToData压缩图片

### Q4：如何分享多张图片？
**原因**：需要批量分享多张图片
**解决方法**：
- 使用shareData.addRecord添加多条记录
- 设置selectionMode为BATCH模式
- 确保总数据不超过200KB

### Q5：如何监听分享面板关闭事件？
**原因**：需要在分享完成后执行后续操作
**解决方法**：
- 使用controller.on('dismiss', callback)监听关闭事件
- 使用controller.on('shareCompleted', callback)监听分享完成事件（API 18+）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "share_image",
  "imageCount": 1,
  "targetDevice": "图库或其他应用",
  "previewMode": "DETAIL",
  "selectionMode": "SINGLE",
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "utd.getUniformDataTypeByFilenameExtension",
    "fileUri.getUriFromPath"
  ]
}
```

## 参考文档

- [API开发指南 - 分享图片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-image)
- [API参考说明 - systemShare（分享）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [API参考说明 - uniformTypeDescriptor（标准化数据定义与描述）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor)
- [API参考说明 - fileUri（文件URI）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-file-fileuri)

## 完整示例代码

- [ArkTS示例代码](assets/share_image_example.ets) - 完整的图片分享示例
- [配置文件示例](assets/module.json5) - 模块配置示例

## 测试用例

### 正向测试用例
- [测试单张图片分享](tests/test_single_image_share.ets) - 分享单张JPEG图片到图库
- [测试多张图片分享](tests/test_multiple_images_share.ets) - 批量分享多张图片
- [测试PNG图片分享](tests/test_png_image_share.ets) - 分享PNG格式图片

### 边界测试用例
- [测试最大记录数量](tests/test_max_records.ets) - 分享500张图片记录
- [测试IPC数据上限](tests/test_ipc_data_limit.ets) - 测试数据总大小接近200KB的情况

### 异常测试用例
- [测试文件路径不存在](tests/test_file_not_found.ets) - 测试无效文件路径的错误处理
- [测试缩略图过大](tests/test_thumbnail oversized.ets) - 测试缩略图超过32KB的错误处理
- [测试非Stage模型](tests/test_non_stage_model.ets) - 测试在非Stage模型中的错误提示