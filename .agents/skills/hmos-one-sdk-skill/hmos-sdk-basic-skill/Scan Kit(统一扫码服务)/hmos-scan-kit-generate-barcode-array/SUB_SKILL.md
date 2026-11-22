---
name: hmos-scan-kit-generate-barcode-array
description: 将字节数组转换为QR Code码图,支持自定义宽高边距颜色等参数,仅支持QR_CODE类型,字节数组长度根据纠错水平限制在1024-2048字节,适用于交通一卡通二维码等自定义码图生成场景
---

# 通过字节数组生成码图技能

## 功能描述

本技能提供将字节数组转换为QR Code码图的能力。通过generateBarcode.createBarcode接口,可以将ArrayBuffer格式的字节数据转换为PixelMap格式的二维码图片,支持自定义码图的宽高、边距、背景颜色、码图颜色和纠错水平等参数。

**核心能力**:
- 将ArrayBuffer字节数组转换为QR Code码图
- 支持自定义码图尺寸(宽高范围:200-4096px)
- 支持设置边距(1-10px)、纠错水平(LEVEL_L/M/Q/H)
- 支持自定义背景颜色和码图颜色
- 返回PixelMap格式图片,可直接用于Image组件渲染

**适用范围**:
- 仅支持QR_CODE码类型
- 适用于需要生成自定义格式二维码的场景(如交通一卡通、特殊编码格式等)
- 支持Phone、Tablet、Wearable(5.1.0+)、PC/2in1(5.1.1+)、TV(5.1.1+)

**限制条件**:
- 字节数组长度根据纠错水平限制:LEVEL_L/M≤2048字节,LEVEL_Q≤1536字节,LEVEL_H≤1024字节
- 码图宽高必须相等且在[200,4096]范围内
- 建议使用默认颜色配置(黑色码图+白色背景)以确保识别率
- 模拟器不支持此功能

**典型场景**:
- 交通一卡通二维码生成
- 自定义编码格式的二维码生成
- 特殊行业应用的码图生成

## 使用场景

### 触发词
- "字节数组生成二维码"
- "ArrayBuffer生成码图"
- "生成自定义格式二维码"
- "交通一卡通二维码"
- "字节数据转QR Code"

### 能做
- 将ArrayBuffer字节数组转换为QR Code码图
- 自定义码图的宽高、边距、颜色等参数
- 生成符合特定编码规范的二维码(如交通卡二维码)
- 返回可渲染的PixelMap图片对象

### 绝不做
- 不支持生成除QR_CODE外的其他码类型(EAN、Code 39等)
- 不处理字符串内容的码图生成(需使用string参数版本的createBarcode)
- 不执行扫码识别功能
- 不支持MULTIFUNCTIONAL CODE生成

### 补充
- 若Scan Kit识别某码图显示乱码,说明该码图需要专门解码器解析(如地铁闸机码)
- 建议码图宽高设置为相等值以确保识别率
- 建议使用默认黑色码图+白色背景配置

## 调用规范和规则

### 输入约束
- **字节数组长度**: 根据纠错水平限制
  - LEVEL_L/LEVEL_M: 最大2048字节
  - LEVEL_Q: 最大1536字节
  - LEVEL_H: 最大1024字节
- **码图宽高**: 必须相等,范围[200,4096]px
- **边距**: 范围[1,10]px,默认1px
- **颜色格式**: HEX格式(如0xFFFFFF表示白色,0x000000表示黑色)

### 执行约束
- **最大耗时**: 码图生成通常在100ms内完成
- **API调用频次**: 无限制
- **设备支持**: Phone/Tablet必选,Wearable/PC/TV需特定版本

### 内容约束
- **禁止生成**: 除QR_CODE外的其他码类型
- **禁止参数**: scanType必须为QR_CODE,不能设置为其他值
- **禁止操作**: 在模拟器上调用此API(会返回"Emulator is not supported"错误)

### 降级约束
- **字节数组过长**: 根据纠错水平自动提示限制,建议降低纠错水平或缩减数据
- **参数错误**: 返回401错误码,需检查参数类型和取值范围
- **内部错误**: 返回1000500001错误码,建议重试或检查系统状态

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 检查字节数组长度是否符合纠错水平限制
2. 检查设备类型是否支持(模拟器不支持)
3. 验证码图宽高参数是否相等且在[200,4096]范围内

**参数准备**:
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { buffer } from '@kit.ArkTS';

// 准备字节数组数据
const hexString: string = '0177C10DD10F7768600202312110000063458FD...';
const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;

// 准备码图生成参数
const options: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.QR_CODE, // 必须为QR_CODE
  width: 400,  // 码图宽度,单位px
  height: 400, // 码图高度,单位px(必须与width相等)
  margin: 1,   // 边距,可选,默认1,范围[1,10]
  level: generateBarcode.ErrorCorrectionLevel.LEVEL_H, // 纠错水平,可选
  backgroundColor: 0xFFFFFF, // 背景颜色,可选,默认白色
  pixelMapColor: 0x000000    // 码图颜色,可选,默认黑色
};
```

### 步骤2: 调用API

**示例代码(Promise方式)**:
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG: string = 'GenerateBarcodeArray';
const DOMAIN: number = 0x0001;

async function generateBarcodeFromArrayBuffer(
  hexString: string,
  width: number,
  height: number
): Promise<image.PixelMap | undefined> {
  try {
    // 参数校验
    if (width !== height) {
      hilog.error(DOMAIN, TAG, 'Width and height must be equal for QR Code');
      return undefined;
    }
    if (width < 200 || width > 4096) {
      hilog.error(DOMAIN, TAG, 'Width/height must be in range [200, 4096]');
      return undefined;
    }

    // 将十六进制字符串转换为ArrayBuffer
    const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;
    
    // 检查字节数组长度
    const byteLength = contentBuffer.byteLength;
    hilog.info(DOMAIN, TAG, `Byte array length: ${byteLength}`);
    
    // 设置码图生成参数
    const options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      width: width,
      height: height,
      margin: 1,
      level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,
      backgroundColor: 0xFFFFFF,
      pixelMapColor: 0x000000
    };

    // 调用码图生成接口
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    
    hilog.info(DOMAIN, TAG, 'Succeeded in creating barcode from ArrayBuffer');
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to create barcode. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}
```

**示例代码(ArkUI组件集成)**:
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

@Entry
@Component
struct BarcodeGeneratorPage {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State errorMessage: string = '';

  build() {
    Column() {
      // 码图显示区域
      if (this.pixelMap) {
        Image(this.pixelMap)
          .width(300)
          .height(300)
          .objectFit(ImageFit.Contain)
      } else if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
      } else {
        Text('Click button to generate barcode')
          .fontSize(16)
      }

      // 生成按钮
      Button('Generate QR Code from ByteArray')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.generateBarcode();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private async generateBarcode(): Promise<void> {
    this.pixelMap = undefined;
    this.errorMessage = '';

    try {
      // 交通一卡通示例数据(十六进制字符串)
      const hexString: string = 
        '0177C10DD10F7768600202312110000063458FD14112345678FFFFD381012610b746365409210201b66636540ad0200020000000000110e617003201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006645fbec664358ECF657CB40693c92da';
      
      // 转换为ArrayBuffer
      const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;

      // 配置生成参数
      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        width: 400,
        height: 400,
        margin: 1,
        level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
      };

      // 生成码图
      const result: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
      this.pixelMap = result;
      
      hilog.info(0x0001, 'BarcodeGenerator', 'Succeeded in creating barcode');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.errorMessage = `Error: ${err.code} - ${err.message}`;
      hilog.error(0x0001, 'BarcodeGenerator', 
        `Failed to create barcode. Code: ${err.code}, message: ${err.message}`);
    }
  }
}
```

### 步骤3: 错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

async function handleBarcodeGeneration(): Promise<void> {
  try {
    const pixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    // 成功处理
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        // 参数错误
        console.error('Parameter error. Possible causes:');
        console.error('1. Incorrect parameter types');
        console.error('2. Parameter verification failed');
        console.error('3. Width/height not equal or out of range');
        console.error('4. scanType not QR_CODE');
        break;
        
      case 1000500001:
        // 内部错误
        console.error('Internal error. Possible causes:');
        console.error('1. Algorithm encoding failed');
        console.error('2. PixelMap creation failed');
        console.error('Solution: Retry the API call');
        break;
        
      default:
        console.error(`Unknown error: ${err.code} - ${err.message}`);
    }
  }
}
```

### 步骤4: 降级处理

```typescript
async function generateBarcodeWithFallback(
  hexString: string,
  preferredLevel: generateBarcode.ErrorCorrectionLevel
): Promise<image.PixelMap | undefined> {
  const contentBuffer: ArrayBuffer = buffer.from(hexString, 'hex').buffer;
  const byteLength = contentBuffer.byteLength;
  
  // 根据字节数组长度自动调整纠错水平
  let level: generateBarcode.ErrorCorrectionLevel = preferredLevel;
  
  if (byteLength > 2048) {
    console.warn('Byte array too long, no suitable error correction level');
    return undefined;
  } else if (byteLength > 1536 && preferredLevel === generateBarcode.ErrorCorrectionLevel.LEVEL_H) {
    console.warn('LEVEL_H supports max 1024 bytes, auto downgrade to LEVEL_Q');
    level = generateBarcode.ErrorCorrectionLevel.LEVEL_Q;
  } else if (byteLength > 1024 && preferredLevel === generateBarcode.ErrorCorrectionLevel.LEVEL_H) {
    console.warn('LEVEL_H supports max 1024 bytes, auto downgrade to LEVEL_M');
    level = generateBarcode.ErrorCorrectionLevel.LEVEL_M;
  }

  const options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    width: 400,
    height: 400,
    level: level
  };

  try {
    return await generateBarcode.createBarcode(contentBuffer, options);
  } catch (error) {
    console.error('Failed even with fallback level');
    return undefined;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | 参数错误 | 1. 参数类型不正确<br/>2. 参数校验失败<br/>3. width/height不相等或超出范围<br/>4. scanType不是QR_CODE | 检查参数类型和取值范围,确保width=height且在[200,4096]范围内 |
| 1000500001 | 内部错误 | 1. 算法编码失败<br/>2. PixelMap创建失败<br/>3. 系统内部异常 | 重试API调用,检查系统状态 |

**错误处理最佳实践**:
- 使用try-catch捕获所有可能的异常
- 根据错误码提供用户友好的错误提示
- 对于401错误,详细检查每个参数的有效性
- 对于1000500001错误,建议最多重试3次

## 编译和修复问题

### 依赖声明

**oh-package.json5**:
```json
{
  "dependencies": {
    "@kit.ScanKit": "^4.1.0",
    "@kit.ImageKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.PerformanceAnalysisKit": "^4.1.0",
    "@kit.ArkTS": "^4.1.0"
  }
}
```

**导入声明**:
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';
```

### 环境要求
- **HarmonyOS API版本**: 5.0.0(12)及以上(ArrayBuffer版本从5.0.0开始支持)
- **设备支持**: Phone、Tablet、Wearable(5.1.0+)、PC/2in1(5.1.1+)、TV(5.1.1+)
- **不支持**: 模拟器(调用会返回"Emulator is not supported")

### 常见编译问题

**问题1: 找不到@kit.ScanKit模块**
```
Error: Cannot find module '@kit.ScanKit'
```
**解决方法**: 
- 检查项目API版本是否≥5.0.0(12)
- 在oh-package.json5中添加依赖声明
- 执行ohpm install安装依赖

**问题2: buffer.from方法不存在**
```
Error: Property 'from' does not exist on type 'buffer'
```
**解决方法**:
- 确保导入正确的buffer模块: `import { buffer } from '@kit.ArkTS'`
- 检查API版本是否支持buffer.from方法

**问题3: PixelMap类型错误**
```
Error: Type 'image.PixelMap' is not assignable to type 'Image'
```
**解决方法**:
- PixelMap可以直接传递给Image组件,无需额外转换
- 确保正确导入image模块: `import { image } from '@kit.ImageKit'`

## 常见问题与解决方法

### Q1: 如何将普通字符串转换为ArrayBuffer?
**原因**: generateBarcode的ArrayBuffer版本需要二进制数据
**解决方法**:
```typescript
// 方法1: 直接字符串转ArrayBuffer
const text = 'Hello World';
const encoder = new TextEncoder();
const bufferArray = encoder.encode(text);
const contentBuffer = bufferArray.buffer;

// 方法2: 十六进制字符串转ArrayBuffer
import { buffer } from '@kit.ArkTS';
const hexString = '0123456789ABCDEF';
const contentBuffer = buffer.from(hexString, 'hex').buffer;
```

### Q2: 字节数组超过纠错水平限制怎么办?
**原因**: 不同纠错水平有不同的字节数组长度限制
**解决方法**:
- LEVEL_L/LEVEL_M: 最大2048字节
- LEVEL_Q: 最大1536字节  
- LEVEL_H: 最大1024字节
- 建议根据数据长度选择合适的纠错水平,或压缩数据

### Q3: 生成的二维码识别率低怎么办?
**原因**: 颜色对比度不足或码图过小
**解决方法**:
- 使用默认颜色配置(黑色码图0x000000 + 白色背景0xFFFFFF)
- 增大码图尺寸(建议≥400px)
- 确保width=height且都≥200px
- 检查字节数据的有效性

### Q4: 模拟器上调用返回错误怎么办?
**原因**: 模拟器不支持码图生成功能
**解决方法**:
- 使用真机设备测试
- 模拟器调用会返回"Emulator is not supported"错误,这是预期行为

### Q5: 如何选择合适的纠错水平?
**原因**: 纠错水平影响码图容量和抗损性
**解决方法**:
- LEVEL_L(7%纠错): 容量最大,适合数据量大场景
- LEVEL_M(15%纠错): 平衡容量和纠错能力
- LEVEL_Q(25%纠错): 纠错能力较强
- LEVEL_H(30%纠错): 纠错能力最强,适合易损环境
- 默认推荐LEVEL_H

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "barcodeGenerated": true,
  "pixelMapSize": {
    "width": 400,
    "height": 400
  },
  "byteArrayLength": 256,
  "errorCorrectionLevel": "LEVEL_H",
  "scanType": "QR_CODE",
  "apiUsed": [
    "generateBarcode.createBarcode",
    "buffer.from"
  ],
  "timestamp": "2026-07-04T12:00:00Z"
}
```

**报告字段说明**:
- **status**: 执行状态(success/failed)
- **barcodeGenerated**: 码图是否生成成功
- **pixelMapSize**: 生成的码图尺寸
- **byteArrayLength**: 输入的字节数组长度
- **errorCorrectionLevel**: 使用的纠错水平
- **scanType**: 码图类型(固定为QR_CODE)
- **apiUsed**: 使用的API列表
- **timestamp**: 执行时间戳

## 参考文档

- [API开发指南](references/scan-generatearray.md)
- [API参考说明](references/scan-generatebarcode.md)
- [错误码说明](references/scan-error-code.md)

## 完整示例代码

- [ArkTS完整示例](assets/barcode_generator_array.ets)
- [交通一卡通示例](assets/traffic_card_barcode.ets)

## 测试用例

### 正向测试用例
- [生成标准QR码](tests/test_positive.ts): 使用256字节生成400x400 QR码
- [交通卡二维码](tests/test_traffic_card.ts): 生成交通一卡通格式二维码

### 边界测试用例
- [最大字节限制](tests/test_boundary_max_bytes.ts): 测试不同纠错水平的字节限制
- [最小尺寸限制](tests/test_boundary_min_size.ts): 测试200x200最小尺寸
- [最大尺寸限制](tests/test_boundary_max_size.ts): 测试4096x4096最大尺寸

### 异常测试用例
- [字节数组过长](tests/test_exception_bytes_exceeded.ts): 超过纠错水平限制
- [宽高不相等](tests/test_exception_unequal_dimensions.ts): width≠height
- [尺寸超范围](tests/test_exception_invalid_size.ts): 尺寸<200或>4096
- [参数类型错误](tests/test_exception_invalid_params.ts): 错误的参数类型