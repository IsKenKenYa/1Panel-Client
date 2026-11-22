---
name: hmos-scan-kit-decodeimage
description: 识别NV21格式图像数据中的条形码/二维码/MULTIFUNCTIONAL CODE，支持单码/多码识别，返回码类型/码值/码位置/放大倍数，适用于相机预览流实时扫码场景
---

# 识别图像数据技能

## 功能描述

本技能提供对NV21像素格式图像数据的扫码识别能力，支持识别条形码、二维码、MULTIFUNCTIONAL CODE等多种码类型。通过调用Scan Kit的`detectBarcode.decodeImage`接口，传入ByteImage类型的图像数据，可以获取码类型、码值、码位置、期望图像放大倍数等识别结果。该能力支持一图单码和一图多码的识别，适用于相机预览流实时扫码、条形码识别、付款码识别等场景。

**核心能力**：
- 支持NV21格式图像数据识码
- 支持单码和多码识别模式
- 返回详细的识别结果（码类型、码值、码位置、角点坐标）
- 提供相机变焦参考值
- 支持条形码、二维码、MULTIFUNCTIONAL CODE识别

## 使用场景

### 触发词
- "识别图像数据中的码"
- "解码图像中的条形码"
- "识别相机预览流中的二维码"
- "实时扫码"
- "图像数据识码"
- "NV21图像识码"
- "decodeImage"

### 能做
- 识别NV21格式的图像数据中的条形码、二维码、MULTIFUNCTIONAL CODE
- 支持一图单码和一图多码识别
- 获取码的类型、码值、码位置信息
- 获取QR码四个角点坐标
- 提供相机期望放大倍数，辅助实现自动变焦
- 处理相机预览流的实时图像数据

### 绝不做
- 不支持直接识别图片文件（使用`detectBarcode.decode`接口识别图片文件）
- 不支持非NV21格式的图像数据
- 不提供相机启动功能（需配合Camera Kit使用）
- 不在模拟器上运行（模拟器不支持）
- 不支持并行调用多个decodeImage接口

### 补充
- 图像数据来源于Camera Kit的预览流，需要使用ImageReceiver获取
- 相机预览流宽高和图像数据宽高需要正确对应（注意旋转角度）
- 需要在识别完成后再释放图像数据资源
- 返回的cornerPoints坐标需要根据屏幕方向和预览组件大小进行转换

## 调用规范和规则

### 输入约束
- **图像格式**：仅支持NV21格式
- **图像数据**：ArrayBuffer类型的byteBuffer
- **图像宽度**：正整数，单位px
- **图像高度**：正整数，单位px
- **码类型**：支持ALL、QR_CODE、CODABAR、CODE_39、CODE_93、CODE_128、CODE_11、ITF_14、PDF_417、EAN_13、EAN_8、UPC_A、UPC_E、DATA_MATRIX、AZTEC等

### 执行约束
- **API调用频次**：不支持并行调用，需等待上一次调用完成
- **图像数据有效性**：需在识别完成后再释放图像数据
- **依赖声明**：需要Camera Kit配合获取预览流数据
- **API版本要求**：HarmonyOS 5.0.0(12)及以上版本

### 内容约束
- 禁止使用模拟器运行（会返回"Emulator is not supported"错误）
- 禁止在图像数据被释放后继续访问识别结果
- 禁止并行调用decodeImage接口

### 降级约束
- **模拟器环境**：提示用户"暂不支持模拟器开发"，建议使用真机
- **图像数据获取失败**：提示用户检查Camera Kit配置和ImageReceiver设置
- **识别失败**：返回错误码和错误信息，根据错误类型提供解决建议
- **码未识别**：提示用户调整相机角度、距离或光照条件

## 调用流程和步骤

### 步骤1：导入必要模块

**前置条件**：项目已配置HarmonyOS SDK

```typescript
import { detectBarcode, scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：配置Camera Kit并获取预览流

**前置条件**：已申请相机权限

**详细步骤**：参考Camera Kit的[双路预览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-dual-channel-preview)文档，实现双路预览功能，通过ImageReceiver获取预览流数据。

### 步骤3：准备图像数据参数

**参数说明**：
- `byteBuffer`: 图像数据（ArrayBuffer）
- `width`: 图像宽度（注意：相机预览流数据旋转90°，宽度应为相机高度的值）
- `height`: 图像高度（注意：相机预览流数据旋转90°，高度应为相机宽度的值）
- `format`: 图像格式，固定为NV21

**示例代码**：
```typescript
// 从ImageReceiver获取imgComponent: image.Component，预览流设置的宽高: width, height
function prepareByteImage(imgComponent: image.Component, width: number, height: number): detectBarcode.ByteImage {
  let byteImg: detectBarcode.ByteImage = {
    byteBuffer: imgComponent.byteBuffer,
    // 相机预览流数据旋转90°
    width: height,
    height: width,
    format: detectBarcode.ImageFormat.NV21
  };
  return byteImg;
}
```

### 步骤4：调用decodeImage接口识别图像数据

**示例代码**：
```typescript
function decodeImageBuffer(imgComponent: image.Component, width: number, height: number) {
  // 准备图像数据
  let byteImg: detectBarcode.ByteImage = {
    byteBuffer: imgComponent.byteBuffer,
    // 相机预览流数据旋转90°
    width: height,
    height: width,
    format: detectBarcode.ImageFormat.NV21
  };
  
  // 配置识码参数
  let options: scanBarcode.ScanOptions = {
    scanTypes: [scanCore.ScanType.ALL],  // 识别所有码类型
    enableMultiMode: true,                // 启用多码识别
    enableAlbum: false                    // 关闭相册功能
  };
  
  try {
    detectBarcode.decodeImage(byteImg, options).then((data: detectBarcode.DetectResult) => {
      hilog.info(0x0001, '[Scan Sample]',
        `Succeeded in getting DetectResult by promise with options, result is ${JSON.stringify(data)}`);
      
      // 处理识别结果
      if (data.scanResults && data.scanResults.length > 0) {
        data.scanResults.forEach((result, index) => {
          hilog.info(0x0001, '[Scan Sample]', 
            `Result ${index}: type=${result.scanType}, value=${result.originalValue}`);
        });
      }
      
      // 处理zoomValue（用于自动变焦）
      if (data.zoomValue) {
        hilog.info(0x0001, '[Scan Sample]', `Zoom value: ${data.zoomValue}`);
        // 可以根据zoomValue调整相机焦距
      }
    }).catch((err: BusinessError) => {
      hilog.error(0x0001, '[Scan Sample]',
        `Failed to get DetectResult by promise with options. Code: ${err.code}, message: ${err.message}`);
    });
  } catch (err) {
    hilog.error(0x0001, '[Scan Sample]', 
      `Failed to detectBarcode. Code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤5：处理识别结果

**结果处理**：
```typescript
function processDetectResult(result: detectBarcode.DetectResult) {
  // 遍历所有识别结果
  result.scanResults.forEach((scanResult, index) => {
    // 码类型
    const scanType = scanResult.scanType;
    
    // 码值
    const originalValue = scanResult.originalValue;
    
    // 码位置（最小外接矩形）
    if (scanResult.scanCodeRect) {
      const rect = scanResult.scanCodeRect;
      hilog.info(0x0001, '[Scan Sample]', 
        `Rect: left=${rect.left}, top=${rect.top}, right=${rect.right}, bottom=${rect.bottom}`);
    }
    
    // QR码四个角点坐标
    if (scanResult.cornerPoints && scanResult.cornerPoints.length === 4) {
      const cornerPoints = scanResult.cornerPoints;
      // 需要根据屏幕方向和预览组件大小进行坐标转换
      hilog.info(0x0001, '[Scan Sample]', 
        `Corner points: ${JSON.stringify(cornerPoints)}`);
    }
  });
  
  // 相机期望放大倍数
  const zoomValue = result.zoomValue;
  // 可以用于调整相机焦距，实现自动变焦
}
```

### 步骤6：处理cornerPoints坐标转换

**坐标转换逻辑**（假设相机预览流宽高为1080*1920）：

```typescript
function convertCornerPoints(cornerPoints: Array<scanBarcode.Point>, previewWidth: number, previewHeight: number) {
  // 屏幕自然方向和摄像头传感器方向不同，需要转换
  // 假设创建的相机预览流宽高为1080 * 1920
  const convertedPoints: Array<{x: number, y: number}> = [];
  
  // 右下角(x, y)：(1080 - cornerPoints[0].y, cornerPoints[0].x）
  // 左下角(x, y)：(1080 - cornerPoints[1].y, cornerPoints[1].x）
  // 左上角(x, y)：(1080 - cornerPoints[2].y, cornerPoints[2].x）
  // 右上角(x, y)：(1080 - cornerPoints[3].y, cornerPoints[3].x）
  
  if (cornerPoints && cornerPoints.length === 4) {
    convertedPoints.push({
      x: previewWidth - cornerPoints[0].y,
      y: cornerPoints[0].x
    }); // 右下角
    convertedPoints.push({
      x: previewWidth - cornerPoints[1].y,
      y: cornerPoints[1].x
    }); // 左下角
    convertedPoints.push({
      x: previewWidth - cornerPoints[2].y,
      y: cornerPoints[2].x
    }); // 左上角
    convertedPoints.push({
      x: previewWidth - cornerPoints[3].y,
      y: cornerPoints[3].x
    }); // 右上角
  }
  
  return convertedPoints;
}

// 如果预览组件XComponent的宽高和相机预览流宽高不一致，还需要缩放
function scaleCornerPoints(
  points: Array<{x: number, y: number}>,
  previewWidth: number,
  previewHeight: number,
  xComponentWidth: number,
  xComponentHeight: number
) {
  const ratio = xComponentWidth / previewWidth;
  return points.map(point => ({
    x: point.x * ratio,
    y: point.y * ratio
  }));
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 参数类型不正确；2. 参数验证失败。 | 检查参数类型和取值范围，确保ByteImage对象的属性正确设置 |
| 1000500001 | 内部错误。 | 检查系统日志，确认图像数据格式正确，尝试重新调用接口 |
| 模拟器错误 | "Emulator is not supported" | 使用真机进行开发和测试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ScanKit": ">=5.0.0",
    "@kit.CameraKit": ">=5.0.0",
    "@kit.ImageKit": ">=5.0.0",
    "@kit.BasicServicesKit": ">=5.0.0",
    "@kit.PerformanceAnalysisKit": ">=5.0.0"
  }
}
```

### 环境要求
- **HarmonyOS版本**：5.0.0(12)及以上
- **开发环境**：DevEco Studio
- **运行环境**：真机（模拟器不支持）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ScanKit' or its corresponding type declarations.
```
**解决方法**：检查项目配置，确保已正确配置HarmonyOS SDK，并且SDK版本不低于API 12。

**问题2：类型定义错误**
```
Error: Property 'decodeImage' does not exist on type 'typeof detectBarcode'.
```
**解决方法**：确认使用的HarmonyOS版本不低于5.0.0(12)，该接口从API 12开始支持。

**问题3：相机权限问题**
```
Error: Permission denied: camera
```
**解决方法**：在module.json5中添加相机权限配置：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：如何获取NV21格式的图像数据？
**原因**：decodeImage接口只支持NV21格式的图像数据。
**解决方法**：
- 使用Camera Kit启动相机预览流
- 配置预览流格式为NV21
- 通过ImageReceiver获取预览流的图像数据
- 参考Camera Kit的[双路预览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-dual-channel-preview)文档

### Q2：图像宽高应该传什么值？
**原因**：相机预览流数据和图像数据存在方向差异。
**解决方法**：
- 相机预览流数据通常旋转90°
- ByteImage的width应为相机预览流的height
- ByteImage的height应为相机预览流的width
- 例如：预览流设置1080*1920，ByteImage的width应为1920，height应为1080

### Q3：如何在预览组件上绘制码位置框？
**原因**：cornerPoints返回的坐标需要进行转换。
**解决方法**：
- 根据屏幕方向转换cornerPoints坐标（参考步骤6）
- 根据预览组件大小缩放坐标
- 在XComponent或Canvas组件上绘制矩形框

### Q4：识别速度慢或识别失败怎么办？
**原因**：图像质量、光照条件、码图大小等因素影响识别。
**解决方法**：
- 确保图像清晰度和分辨率足够
- 改善光照条件
- 调整相机与码图的距离
- 使用zoomValue实现自动变焦，拉近码图

### Q5：如何实现多码识别？
**原因**：需要配置多码识别模式。
**解决方法**：
- 在ScanOptions中设置`enableMultiMode: true`
- 遍历scanResults数组处理所有识别到的码
- 注意：多码识别可能影响识别速度

## 输出结果报告

执行完成后输出以下信息：

```typescript
{
  "status": "success",
  "scanResultCount": 2,  // 识别到的码数量
  "scanResults": [
    {
      "scanType": "QR_CODE",      // 码类型
      "originalValue": "https://example.com",  // 码值
      "scanCodeRect": {           // 码位置
        "left": 100,
        "top": 200,
        "right": 300,
        "bottom": 400
      },
      "cornerPoints": [           // QR码四个角点（仅QR码返回）
        {"x": 100, "y": 200},
        {"x": 100, "y": 400},
        {"x": 300, "y": 400},
        {"x": 300, "y": 200}
      ]
    }
  ],
  "zoomValue": 1.5,  // 相机期望放大倍数
  "apiUsed": [
    "detectBarcode.decodeImage",
    "detectBarcode.ByteImage",
    "scanBarcode.ScanOptions",
    "detectBarcode.DetectResult"
  ]
}
```

## 参考文档

- [API开发指南：识别图像数据](references/scan-decodeimage.md)
- [API参考：detectBarcode (图像识码)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-imagedecode)
- [API参考：scanBarcode (默认界面扫码)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [Camera Kit：双路预览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/camera-dual-channel-preview)

## 完整示例代码

- [ArkTS示例：图像数据识码](assets/decodeimage_example.ets)

## 测试用例

### 正向测试用例
- [单码识别测试](tests/test_single_decode.ts)：测试识别单个QR码
- [多码识别测试](tests/test_multi_decode.ts)：测试识别多个不同类型的码
- [条形码识别测试](tests/test_barcode_decode.ts)：测试识别条形码

### 边界测试用例
- [最小图像尺寸测试](tests/test_min_image_size.ts)：测试最小图像尺寸识别
- [最大图像尺寸测试](tests/test_max_image_size.ts)：测试最大图像尺寸识别
- [模糊图像测试](tests/test_blur_image.ts)：测试模糊图像识别能力

### 异常测试用例
- [空图像数据测试](tests/test_empty_buffer.ts)：测试空图像数据输入
- [错误格式测试](tests/test_wrong_format.ts)：测试非NV21格式输入
- [模拟器测试](tests/test_emulator.ts)：验证模拟器环境返回错误