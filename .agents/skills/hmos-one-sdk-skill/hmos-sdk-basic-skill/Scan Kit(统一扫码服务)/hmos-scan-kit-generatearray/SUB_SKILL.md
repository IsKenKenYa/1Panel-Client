---
name: hmos-scan-kit-generatearray
description: 将字节数组转换为QR码图，支持自定义尺寸/颜色/纠错级别，最大支持2048字节（LEVEL_L/M）/1536字节（LEVEL_Q）/1024字节（LEVEL_H），适用于交通一卡通、地铁闸机等特殊编码场景
---

# 通过字节数组生成码图技能

## 功能描述

本技能实现将字节数组转换为QR码图的功能，适用于需要将二进制数据编码为二维码的场景。主要特点：

- 支持将ArrayBuffer字节数组转换为QR码图（仅支持QR_CODE类型）
- 可自定义码图尺寸（宽高范围：200-4096px）
- 可设置纠错级别（LEVEL_L/M/Q/H），不同级别对应不同的字节数组长度限制
- 可自定义码图颜色和背景颜色（HEX格式）
- 可设置最小边距（1-10px）
- 返回PixelMap格式图片，可直接使用Image组件渲染

## 使用场景

### 触发词
- "字节数组生成二维码"
- "字节数组生成码图"
- "生成交通一卡通二维码"
- "ArrayBuffer生成QR码"
- "二进制数据生成二维码"
- "地铁闸机二维码生成"

### 能做
- 将字节数组（ArrayBuffer）转换为QR码图
- 支持交通一卡通、地铁闸机等特殊编码场景
- 自定义码图尺寸、颜色、纠错级别、边距
- 返回PixelMap格式图片，可使用Image组件渲染显示

### 绝不做
- 不支持生成除QR_CODE外的其他码制式（如EAN-8、Data Matrix等）
- 不处理超出纠错级别限制的字节数组长度
- 不处理需要专门解码器解析的乱码内容（仅生成码图，不解码）
- 不支持模拟器环境运行

### 补充
- 仅支持QR_CODE类型码图生成
- 字节数组长度限制与纠错级别相关：LEVEL_L/M≤2048字节，LEVEL_Q≤1536字节，LEVEL_H≤1024字节
- 建议使用默认颜色（黑色码图、白色背景）以保证识别率
- 建议宽高值相同且≥200px以保证识别效果
- 支持设备：Phone、Tablet、Wearable（5.1.0(18)版本开始）、PC/2in1、TV（5.1.1(19)版本开始）
- API版本：5.0.0(12)开始支持字节数组生成码图

## 调用规范和规则

### 输入约束
- 字节数组类型：必须为ArrayBuffer
- 字节数组长度：
  - LEVEL_L纠错：最大2048字节
  - LEVEL_M纠错：最大2048字节
  - LEVEL_Q纠错：最大1536字节
  - LEVEL_H纠错：最大1024字节
- 码图宽度：200-4096px，建议与高度相同
- 码图高度：200-4096px，建议与宽度相同
- 最小边距：1-10px（可选，默认1px）
- 码图颜色：HEX格式（可选，默认黑色0x000000）
- 背景颜色：HEX格式（可选，默认白色0xFFFFFF）
- 纠错级别：LEVEL_L/M/Q/H（可选，默认LEVEL_H）

### 执行约束
- 最大耗时：异步回调模式，无固定时间限制
- API调用频次：无限制
- 必须在真机环境运行，不支持模拟器

### 内容约束
- 禁止生成除QR_CODE外的其他码制式
- 禁止使用超出字节数组长度限制的内容
- 禁止使用对比度过低的颜色组合（影响识别率）
- 禁止使用高危函数（如eval、exec等）

### 降级约束
- 字节数组过长：提示用户降低纠错级别或减少字节数组长度
- 网络失败：不涉及网络请求
- 权限不足：无特殊权限要求
- 模拟器环境：返回错误信息"Emulator is not supported."

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查运行环境是否为真机（不支持模拟器）
2. 验证字节数组长度是否符合纠错级别限制
3. 验证码图宽高参数是否在有效范围内（200-4096px）
4. 确认码类型为QR_CODE（字节数组生成仅支持QR_CODE）

**参数准备**：
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { buffer } from '@kit.ArkTS';

// 准备字节数组（示例：交通一卡通数据）
const hexString: string = '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da';
const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;

// 准备生成参数
const options: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.QR_CODE,
  width: 400,
  height: 400,
  margin: 1,
  level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,
  backgroundColor: 0xFFFFFF,
  pixelMapColor: 0x000000
};
```

### 步骤2：调用API生成码图

**示例代码（Promise模式）**：
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG: string = 'GenerateBarcodeFromArray';
const DOMAIN: number = 0x0001;

async function generateBarcodeFromArray(
  hexContent: string,
  width: number,
  height: number
): Promise<image.PixelMap | undefined> {
  // 校验参数
  if (width < 200 || width > 4096 || height < 200 || height > 4096) {
    hilog.error(DOMAIN, TAG, 'Invalid width or height. Range: [200, 4096]');
    return undefined;
  }

  // 转换字节数组
  const contentBuffer: ArrayBuffer = buffer.from(hexContent, 'hex').buffer;
  const bufferSize = contentBuffer.byteLength;
  
  // 校验字节数组长度（根据纠错级别）
  if (bufferSize > 2048) {
    hilog.error(DOMAIN, TAG, `Buffer size ${bufferSize} exceeds max limit 2048 bytes`);
    return undefined;
  }

  // 配置生成参数
  const options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    width: width,
    height: height,
    margin: 1,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000
  };

  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    hilog.info(DOMAIN, TAG, 'Succeeded in generating barcode from array');
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate barcode. Code: ${err.code}, Message: ${err.message}`);
    return undefined;
  }
}
```

### 步骤3：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  const pixelMap = await generateBarcodeFromArray(hexContent, 400, 400);
  if (pixelMap) {
    // 成功生成码图，使用Image组件渲染
    this.pixelMap = pixelMap;
  }
} catch (error) {
  const err: BusinessError = error as BusinessError;
  switch (err.code) {
    case 401:
      console.error('Parameter error. Check parameter types and values.');
      break;
    case 1000500001:
      console.error('Internal error. Please try again later.');
      break;
    default:
      console.error(`Unknown error: Code ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤4：降级处理

```typescript
async function generateBarcodeWithFallback(
  hexContent: string,
  width: number,
  height: number
): Promise<image.PixelMap | undefined> {
  const bufferSize = buffer.from(hexContent, 'hex').buffer.byteLength;
  
  // 根据字节数组长度自动选择合适的纠错级别
  let level: generateBarcode.ErrorCorrectionLevel;
  if (bufferSize <= 1024) {
    level = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
  } else if (bufferSize <= 1536) {
    level = generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
  } else if (bufferSize <= 2048) {
    level = generateBarcode.ErrorCorrectionLevel.LEVEL_M;
  } else {
    console.error(`Buffer size ${bufferSize} exceeds max limit 2048 bytes. Please reduce content size.`);
    return undefined;
  }

  const options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    width: width,
    height: height,
    level: level,
    margin: 1,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000
  };

  const contentBuffer: ArrayBuffer = buffer.from(hexContent, 'hex').buffer;
  
  try {
    return await generateBarcode.createBarcode(contentBuffer, options);
  } catch (error) {
    console.error('Failed to generate barcode with fallback strategy');
    return undefined;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 参数类型错误；2. 参数校验失败。 | 检查参数类型是否正确（ArrayBuffer、CreateOptions），验证宽高范围[200, 4096]，验证字节数组长度不超过纠错级别限制。 |
| 1000500001 | 内部错误。 | 稍后重试，或检查设备API版本是否≥5.0.0(12)。 |
| Emulator not supported | 模拟器不支持。 | 在真机环境运行，不支持模拟器。 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ScanKit": "系统Kit，无需额外安装",
    "@kit.ImageKit": "系统Kit，无需额外安装",
    "@kit.BasicServicesKit": "系统Kit，无需额外安装",
    "@kit.PerformanceAnalysisKit": "系统Kit，无需额外安装",
    "@kit.ArkTS": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API版本：≥5.0.0(12)（字节数组生成码图从5.0.0(12)开始支持）
- 设备类型：Phone、Tablet、Wearable（≥5.1.0(18)）、PC/2in1（≥5.1.1(19)）、TV（≥5.1.1(19)）
- 运行环境：真机（不支持模拟器）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ScanKit'
```
**解决方法**：确保HarmonyOS SDK版本≥5.0.0(12)，检查module.json5中是否声明依赖。

**问题2：字节数组转换失败**
```
Error: Invalid buffer conversion
```
**解决方法**：确保使用buffer.from(content, 'hex').buffer正确转换，验证十六进制字符串格式。

**问题3：码图生成失败**
```
Error: Code: 401, Message: Parameter error
```
**解决方法**：验证宽高参数范围[200, 4096]，验证字节数组长度不超过纠错级别限制，确认scanType为QR_CODE。

## 常见问题与解决方法

### Q1：字节数组长度超过限制怎么办？
**原因**：不同纠错级别有不同的字节数组长度限制。
**解决方法**：
- 查看字节数组实际长度
- 根据长度选择合适的纠错级别：
  - ≤1024字节：使用LEVEL_H（最高纠错）
  - ≤1536字节：使用LEVEL_Q
  - ≤2048字节：使用LEVEL_M或LEVEL_L
- 如果超过2048字节，需减少内容长度

### Q2：生成的码图无法识别怎么办？
**原因**：可能颜色对比度过低、码图尺寸过小或边距设置不当。
**解决方法**：
- 使用默认颜色（黑色码图0x000000、白色背景0xFFFFFF）
- 增大码图尺寸（建议宽高≥400px且相等）
- 保持默认边距（margin=1）
- 确保字节数组内容完整无误

### Q3：模拟器运行失败怎么办？
**原因**：码图生成不支持模拟器环境。
**解决方法**：
- 在真机设备上运行测试
- 确认设备API版本≥5.0.0(12)

### Q4：如何显示生成的码图？
**原因**：生成的是PixelMap格式，需要使用Image组件渲染。
**解决方法**：
```typescript
@State pixelMap: image.PixelMap | undefined = undefined;

// 在UI中使用Image组件
if (this.pixelMap) {
  Image(this.pixelMap)
    .width(300)
    .height(300)
    .objectFit(ImageFit.Contain)
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "pixelMap": "image.PixelMap对象或undefined",
  "imageInfo": {
    "width": "码图宽度（px）",
    "height": "码图高度（px）",
    "size": "图片尺寸信息"
  },
  "parameters": {
    "scanType": "QR_CODE",
    "bufferSize": "字节数组长度（字节）",
    "errorCorrectionLevel": "纠错级别",
    "margin": "边距（px）",
    "backgroundColor": "背景颜色（HEX）",
    "pixelMapColor": "码图颜色（HEX）"
  },
  "apiUsed": [
    "generateBarcode.createBarcode(ArrayBuffer, CreateOptions)"
  ]
}
```

## 参考文档

- [API开发指南 - 通过字节数组生成码图](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-generatearray)
- [API参考说明 - generateBarcode](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-generatebarcode)
- [API参考说明 - PixelMap](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)

## 完整示例代码

- [ArkTS完整示例（Promise模式）](assets/generate_barcode_array_promise.ets)
- [ArkTS完整示例（UI组件）](assets/generate_barcode_array_ui.ets)
- [参数配置示例](assets/config.json)

## 测试用例

### 正向测试用例
- [生成交通一卡通二维码](tests/test_positive.py)：使用标准交通一卡通数据生成QR码
- [生成自定义字节数组二维码](tests/test_positive.py)：使用自定义十六进制字符串生成QR码
- [不同纠错级别测试](tests/test_positive.py)：测试不同纠错级别下的字节数组长度限制

### 边界测试用例
- [最小尺寸测试](tests/test_boundary.py)：宽高=200px的码图生成
- [最大尺寸测试](tests/test_boundary.py)：宽高=4096px的码图生成
- [最大字节数组长度测试](tests/test_boundary.py)：测试各纠错级别的最大字节数组长度

### 异常测试用例
- [字节数组超限测试](tests/test_exception.py)：字节数组长度超过2048字节
- [参数范围超限测试](tests/test_exception.py)：宽高参数超出[200, 4096]范围
- [模拟器环境测试](tests/test_exception.py)：在模拟器环境运行