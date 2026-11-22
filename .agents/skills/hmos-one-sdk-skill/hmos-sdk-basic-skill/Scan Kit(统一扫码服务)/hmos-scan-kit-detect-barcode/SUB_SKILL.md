---
name: hmos-scan-kit-detect-barcode
description: 识别本地图片中的条形码、二维码、MULTIFUNCTIONAL CODE，返回码类型、码值、码位置信息，支持单码和多码识别，适用于图库图片识码、付款码识别场景
---

# 识别本地图片技能

## 功能描述

本技能提供本地图片识码能力，支持对图库中的条形码、二维码、MULTIFUNCTIONAL CODE进行识别，并获取码类型、码值、码位置（码图最小外接矩形左上角和右下角的坐标）等信息。该能力可用于一图单码和一图多码的识别，比如条形码、付款码等。

**核心能力**：
- 支持13种码类型识别：AZTEC、CODABAR、CODE 39、CODE 93、CODE 128、DATA MATRIX、EAN-8、EAN-13、ITF-14、PDF417、QR CODE、UPC-A、UPC-E、MULTIFUNCTIONAL CODE
- 支持单码和多码识别模式
- 返回码的位置信息（外接矩形坐标）
- 支持通过picker选择图库图片
- 提供Promise和Callback两种异步调用方式

**适用版本**：API version 4.1.0(11)及以上

## 使用场景

### 触发词
- "识别本地图片中的码"
- "图片识码"
- "识别图库二维码"
- "识别条形码图片"
- "本地图片扫码"
- "detectBarcode"

### 能做
- 识别图库中存储的条形码、二维码、MULTIFUNCTIONAL CODE
- 获取码的类型、码值、码位置信息
- 支持单张图片中识别一个或多个码
- 通过picker选择图片后进行识码
- 返回码图的最小外接矩形坐标位置

### 绝不做
- 不支持直接识别相机流数据（需要使用customScan或decodeImage接口）
- 不支持识别视频中的码
- 不支持实时扫码（需要使用默认界面扫码或自定义界面扫码）
- 不处理超出图片识码范围的请求（如生成码图）
- 不支持识别网络图片URL（需要先下载到本地）

### 补充
- 推荐使用picker获取图片路径，确保uri格式正确
- 多码识别模式下，最多可识别同一图片中的多个码
- 图片识码为同步算法处理，不支持并行调用decodeImage接口
- 传入的图片uri必须为有效路径，否则会触发1000500001错误

## 调用规范和规则

### 输入约束
- 图片格式：支持常见图片格式（JPEG、PNG等）
- 图片路径：必须为有效的本地路径，格式为`file://media/Photo/x/xxx.jpg`
- 图片大小：无明确限制，建议不超过10MB
- 图片数量：每次调用识别一张图片
- 码图数量：单码模式识别一个码，多码模式可识别多个码

### 执行约束
- 最大耗时：依赖图片大小和码图复杂度，通常1-5秒
- API调用频次：无明确限制
- 并发限制：decodeImage接口不支持并行调用
- 调用方式：支持Promise和Callback两种异步回调

### 内容约束
- 禁止生成：不生成码图，只识别已有码图
- 禁止操作：不修改原始图片内容
- 参数校验：必须校验InputImage的uri参数是否有效
- 错误处理：必须捕获并处理401和1000500001错误码

### 降级约束
- 图片读取失败：提示用户检查图片路径，重新选择图片
- 识码失败：提示用户图片中可能无码或码图质量较差
- 多码识别失败：降级为单码识别模式
- 权限不足：提示用户授予相册访问权限

## 调用流程和步骤

### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**前置校验**：
1. 检查应用是否已授予相册访问权限
2. 确认HarmonyOS版本不低于4.1.0(11)
3. 确认已导入@kit.ScanKit模块

### 步骤2：通过Picker选择图片

**使用photoAccessHelper选择图片**：
```typescript
let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
photoSelectOptions.maxSelectNumber = 1;
photoSelectOptions.isPhotoTakingSupported = false;
photoSelectOptions.isEditSupported = false;

let photoPicker = new photoAccessHelper.PhotoViewPicker();
photoPicker.select(photoSelectOptions).then((result: photoAccessHelper.PhotoSelectResult) => {
  if (!result || (result.photoUris && result.photoUris.length === 0)) {
    hilog.error(0x0001, 'picker', 'Failed to get PhotoSelectResult by promise');
    return;
  }
  hilog.info(0x0001, 'picker', `Succeeded in getting PhotoSelectResult by promise.`);
}).catch((error: BusinessError) => {
  hilog.error(0x0001, 'picker', `Failed to get PhotoSelectResult by promise. Code: ${error.code}`);
});
```

### 步骤3：调用detectBarcode.decode接口（Promise方式）

**定义识码参数并调用接口**：
```typescript
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],
  enableMultiMode: true,
  enableAlbum: true
};

let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };

try {
  detectBarcode.decode(inputImage, options).then((result: Array<scanBarcode.ScanResult>) => {
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
  }).catch((error: BusinessError) => {
    hilog.error(0x0001, '[Scan Sample]',
      `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]',
    `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
}
```

### 步骤4：调用detectBarcode.decode接口（Callback方式）

**使用Callback回调处理结果**：
```typescript
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],
  enableMultiMode: true,
  enableAlbum: true
};

let inputImage: detectBarcode.InputImage = { uri: result.photoUris[0] };

try {
  detectBarcode.decode(inputImage, options, (error: BusinessError, result: Array<scanBarcode.ScanResult>) => {
    if (error && error.code) {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get ScanResult by callback with options. Code: ${error.code}, message: ${error.message}`);
      return;
    }
    hilog.info(0x0001, '[Scan Sample]',
      `Succeeded in getting ScanResult by callback with options, result is ${JSON.stringify(result)}`);
  });
} catch (error) {
  hilog.error(0x0001, '[Scan Sample]',
    `Failed to detectBarcode. Code: ${error.code}, message: ${error.message}`);
}
```

### 步骤5：处理识码结果

**解析ScanResult数据结构**：
```typescript
for (let scanResult of result) {
  hilog.info(0x0001, '[Scan Sample]', `ScanType: ${scanResult.scanType}`);
  hilog.info(0x0001, '[Scan Sample]', `OriginalValue: ${scanResult.originalValue}`);
  
  if (scanResult.scanCodeRect) {
    hilog.info(0x0001, '[Scan Sample]', 
      `Position: left=${scanResult.scanCodeRect.left}, top=${scanResult.scanCodeRect.top}, 
       right=${scanResult.scanCodeRect.right}, bottom=${scanResult.scanCodeRect.bottom}`);
  }
}
```

### 步骤6：错误处理

**错误码处理逻辑**：
```typescript
try {
  await detectBarcode.decode(inputImage, options);
} catch (error) {
  switch (error.code) {
    case 401:
      hilog.error(0x0001, '[Scan Sample]', 'Parameter error. Check inputImage uri format.');
      break;
    case 1000500001:
      hilog.error(0x0001, '[Scan Sample]', 'Internal error. Try again or check image quality.');
      break;
    default:
      hilog.error(0x0001, '[Scan Sample]', `Unknown error: ${error.message}`);
  }
}
```

### 步骤7：降级处理

**单码识别降级方案**：
```typescript
async function detectBarcodeWithFallback(uri: string): Promise<void> {
  let inputImage: detectBarcode.InputImage = { uri: uri };
  
  try {
    let multiModeOptions: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true
    };
    
    let result = await detectBarcode.decode(inputImage, multiModeOptions);
    if (result.length > 0) {
      hilog.info(0x0001, '[Scan Sample]', `Multi-mode succeeded, found ${result.length} codes`);
    }
  } catch (error) {
    hilog.warn(0x0001, '[Scan Sample]', 'Multi-mode failed, fallback to single-mode');
    
    try {
      let singleModeOptions: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: false
      };
      
      let result = await detectBarcode.decode(inputImage, singleModeOptions);
      hilog.info(0x0001, '[Scan Sample]', `Single-mode succeeded`);
    } catch (fallbackError) {
      hilog.error(0x0001, '[Scan Sample]', 'Both multi and single mode failed');
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | Parameter error | 1. 参数类型错误<br>2. 参数校验失败 | 检查InputImage的uri参数格式是否正确 |
| 1000500001 | Internal error | 1. 算法异常<br>2. 图片读取失败<br>3. 传入uri无效 | 1. 尝试重新调用接口<br>2. 检查传入的uri路径<br>3. 确认图片文件存在 |

**错误码详细说明**：
- **401错误**：参数校验失败，通常是因为InputImage的uri参数格式不正确或为空。确保uri为有效的本地路径，格式如`file://media/Photo/x/xxx.jpg`。
- **1000500001错误**：内部错误，可能原因包括：
  - 算法异常：图片中码图质量较差或无法识别
  - 图片读取失败：传入的uri路径无效或文件不存在
  - 系统创建图像逻辑异常

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ScanKit": "4.1.0(11)",
    "@kit.MediaLibraryKit": "4.1.0(11)",
    "@kit.PerformanceAnalysisKit": "4.1.0(11)",
    "@kit.BasicServicesKit": "4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS版本：不低于4.1.0(11)
- 开发模型：Stage模型
- 系统能力：SystemCapability.Multimedia.Scan.ScanBarcode

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.ScanKit'
```
**解决方法**：确认DevEco Studio版本支持HarmonyOS 4.1.0(11)，检查项目配置是否正确。

**问题2：photoAccessHelper导入错误**
```
Error: Cannot find name 'photoAccessHelper'
```
**解决方法**：确保导入路径正确：`import { photoAccessHelper } from '@kit.MediaLibraryKit';`

**问题3：类型定义错误**
```
Error: Property 'photoUris' does not exist on type 'PhotoSelectResult'
```
**解决方法**：检查API版本，photoUris属性在4.1.0(11)版本可用。

### 权限配置

**module.json5权限声明**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "用于读取图库中的图片进行识码"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：picker选择图片后photoUris为空
**原因**：未正确配置picker参数或用户未选择图片
**解决方法**：
- 检查photoSelectOptions的MIMEType配置
- 确认maxSelectNumber大于0
- 处理用户取消选择的情况

### Q2：decode接口返回空数组
**原因**：图片中无码图或码图质量较差无法识别
**解决方法**：
- 提示用户选择包含清晰码图的图片
- 尝试调整ScanOptions参数，如设置具体的scanTypes
- 检查图片质量和码图清晰度

### Q3：多码识别模式下只识别到一个码
**原因**：图片中确实只有一个码，或多个码质量差异较大
**解决方法**：
- 检查图片中实际码图数量
- 尝试使用单码识别模式提高准确率
- 检查码图位置和大小是否合理

### Q4：传入uri后触发1000500001错误
**原因**：图片路径无效或文件不存在
**解决方法**：
- 确保使用picker返回的uri，不要手动构造路径
- 检查uri格式是否为`file://media/Photo/x/xxx.jpg`
- 确认图片文件在图库中存在

### Q5：识别速度较慢
**原因**：图片较大或码图复杂度高
**解决方法**：
- 选择较小尺寸的图片
- 避免识别超高分辨率图片
- 如只识别特定码类型，设置scanTypes参数缩小识别范围

### Q6：不支持网络图片URL识别
**原因**：detectBarcode.decode接口只支持本地图片uri
**解决方法**：
- 先下载网络图片到本地
- 使用本地路径作为InputImage的uri参数
- 或使用其他接口处理网络图片

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "scanResultCount": 1,
  "scanResults": [
    {
      "scanType": 11,
      "scanTypeName": "QR_CODE",
      "originalValue": "https://example.com",
      "scanCodeRect": {
        "left": 100,
        "top": 200,
        "right": 300,
        "bottom": 400
      }
    }
  ],
  "apiUsed": [
    "detectBarcode.decode",
    "photoAccessHelper.PhotoViewPicker.select"
  ],
  "inputImage": {
    "uri": "file://media/Photo/1/xxx.jpg"
  },
  "scanOptions": {
    "scanTypes": ["ALL"],
    "enableMultiMode": true,
    "enableAlbum": true
  }
}
```

**结果说明**：
- **status**：识码状态，success或failed
- **scanResultCount**：识别到的码图数量
- **scanResults**：识别结果数组，包含码类型、码值、位置信息
- **apiUsed**：调用的API列表
- **inputImage**：输入的图片信息
- **scanOptions**：使用的识码参数

## 参考文档

- [API开发指南 - 识别本地图片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-detectbarcode)
- [API参考说明 - detectBarcode图像识码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-imagedecode)
- [API参考说明 - scanBarcode默认界面扫码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [API参考说明 - scanCore扫码公共信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [API参考说明 - ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code)

## 完整示例代码

- [ArkTS示例 - Promise方式识码](assets/detect_barcode_promise.ets)
- [ArkTS示例 - Callback方式识码](assets/detect_barcode_callback.ets)
- [ArkTS示例 - 完整页面实现](assets/detect_barcode_page.ets)

## 测试用例

### 正向测试用例
- [识别单个二维码](tests/test_single_qr_code.py)：测试识别图片中的单个QR Code
- [识别多个二维码](tests/test_multi_qr_codes.py)：测试多码识别模式
- [识别条形码](tests/test_barcode.py)：测试识别CODE 128条形码

### 边界测试用例
- [识别模糊码图](tests/test_blur_code.py)：测试码图质量较差的情况
- [识别小尺寸码图](tests/test_small_code.py)：测试码图占比较小的图片
- [识别大尺寸图片](tests/test_large_image.py)：测试高分辨率图片识码

### 异常测试用例
- [无效图片路径](tests/test_invalid_uri.py)：测试传入无效uri的错误处理
- [无码图图片](tests/test_no_code.py)：测试图片中无码图的返回结果
- [权限不足](tests/test_permission_denied.py)：测试无相册访问权限的错误处理