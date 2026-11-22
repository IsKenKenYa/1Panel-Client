---
name: hmos-scan-kit-barcode-generate
description: 通过文本生成条形码或二维码，支持QR Code、EAN、Code等多种码制式，返回PixelMap格式图片，适用于支付码、会员码、身份码场景
---

# 通过文本生成码图技能

## 功能描述

码图生成能力支持将字符串转换为自定义格式的码图，包含条形码、二维码生成。可以将字符串转成联系人码图、手机克隆码图等。支持以下码制式：

- **二维码**：QR Code、Data Matrix、PDF417、Aztec
- **条形码**：EAN-8、EAN-13、UPC-A、UPC-E、Codabar、Code 39、Code 93、Code 128、ITF-14

**版本支持**：
- Phone、Tablet：4.1.0(11)及以上
- Wearable：5.1.0(18)及以上
- PC/2in1、TV：5.1.1(19)及以上

**限制说明**：
- 暂不支持MULTIFUNCTIONAL CODE生成
- 模拟器不支持此功能

## 使用场景

### 触发词
- "生成二维码"
- "生成条形码"
- "创建QR码"
- "制作支付码"
- "生成会员码"
- "文本转码图"
- "字符串生成码图"

### 能做
- 生成QR Code二维码，支持中文内容
- 生成各类条形码（EAN、UPC、Code系列等）
- 自定义码图尺寸（宽高200-4096px）
- 自定义码图颜色和背景色
- 设置纠错等级（QR Code支持L/M/Q/H四个等级）
- 设置边距（1-10px）
- 返回PixelMap格式图片，可用于Image组件渲染

### 绝不做
- 不支持MULTIFUNCTIONAL CODE生成
- 不支持在模拟器上运行
- 不支持超出参数限制的内容生成
- 不支持生成后直接保存为文件（需要额外调用图片保存接口）

### 补充
- 不同码制式对内容有不同限制（详见参数说明）
- 建议使用默认颜色和背景（黑色码图、白色背景）
- 建议使用默认最小边距1px
- 二维码建议宽高相同且≥200px

## 调用规范和规则

### 输入约束

**content参数限制**：
- **QR Code**：支持中文，不超过512字符
- **Aztec**：支持中文，不超过512字符
- **PDF417**：支持中文，不超过512字符
- **Data Matrix**：不超过512字符
- **UPC-A**：支持11位数字，生成12位（含校验位）
- **UPC-E**：支持7位数字，首位0或1，生成8位（含校验位）
- **ITF-14**：支持80位以内偶数位数字
- **EAN-8**：支持7位数字，生成8位（含校验位）
- **EAN-13**：支持12位数字，首位不可为0，生成13位（含校验位）
- **Code 39/93**：不超过80字节，支持数字、大小写字母、符号
- **Code 128**：不超过80字节，支持数字、大小写字母、符号
- **Codabar**：不超过512字符，起始/终止符ABCD

**options参数限制**：
- **width**：200-4096px（必填）
- **height**：200-4096px（必填）
- **margin**：1-10px（可选，默认1）
- **level**：仅QR Code有效，L/M/Q/H四等级（可选，默认H）
- **backgroundColor**：HEX格式颜色（可选，默认0xFFFFFF）
- **pixelMapColor**：HEX格式颜色（可选，默认0x000000）

### 执行约束
- API调用模式：异步（Promise或Callback）
- 最大耗时：取决于内容复杂度，通常<1秒
- 建议在主线程调用，返回结果可用于UI渲染

### 内容约束
- 禁止使用模拟器运行
- 禁止超出内容长度限制
- 禁止设置FORMAT_UNKNOWN、ONE_D_CODE、TWO_D_CODE、ALL作为scanType（仅用于扫码）
- 禁止设置MULTIFUNCTIONAL_CODE作为scanType（暂不支持生成）

### 降级约束
- 参数错误（401）：检查参数类型和范围，修正后重试
- 内部错误（1000500001）：重新调用接口
- 模拟器环境：提示用户不支持，引导使用真机测试

## 调用流程和步骤

### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**参数准备**：
```typescript
// 准备内容字符串
let content: string = 'huawei';

// 准备生成参数
let options: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.QR_CODE,  // 码类型
  height: 400,                           // 高度(px)
  width: 400,                            // 宽度(px)
  margin: 1,                             // 边距(px，可选)
  level: generateBarcode.ErrorCorrectionLevel.LEVEL_H,  // 纠错等级(可选，仅QR码)
  backgroundColor: 0xFFFFFF,             // 背景色(可选)
  pixelMapColor: 0x000000                // 码图颜色(可选)
};
```

### 步骤2：调用API（Promise方式）

**示例代码**：
```typescript
@Entry
@Component
struct BarcodeGeneratePage {
  @State pixelMap: image.PixelMap | undefined = undefined;

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Button('生成二维码').onClick(() => {
        this.generateQRCode();
      })
      
      if (this.pixelMap) {
        Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
      }
    }
    .width('100%')
    .height('100%')
  }

  // 使用Promise方式生成码图
  async generateQRCode(): Promise<void> {
    let content: string = 'huawei';
    let options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.QR_CODE,
      height: 400,
      width: 400
    };

    try {
      const pixelMap = await generateBarcode.createBarcode(content, options);
      this.pixelMap = pixelMap;
      hilog.info(0x0001, '[BarcodeGenerate]', `成功生成码图，尺寸: ${pixelMap.getImageInfoSync().size}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0001, '[BarcodeGenerate]', 
        `生成码图失败，错误码: ${err.code}，错误信息: ${err.message}`);
    }
  }
}
```

### 步骤3：调用API（Callback方式）

**示例代码**：
```typescript
@Entry
@Component
struct BarcodeGenerateCallbackPage {
  @State pixelMap: image.PixelMap | undefined = undefined;

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Center }) {
      Button('生成条形码').onClick(() => {
        this.generateBarcode();
      })
      
      if (this.pixelMap) {
        Image(this.pixelMap).width(300).height(150).objectFit(ImageFit.Contain)
      }
    }
    .width('100%')
    .height('100%')
  }

  // 使用Callback方式生成码图
  generateBarcode(): void {
    let content: string = '690123456789';  // EAN-13内容（12位数字）
    let options: generateBarcode.CreateOptions = {
      scanType: scanCore.ScanType.EAN13_CODE,
      height: 200,
      width: 400  // 条形码建议宽高比2:1
    };

    try {
      generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
        if (err) {
          hilog.error(0x0001, '[BarcodeGenerate]', 
            `生成码图失败，错误码: ${err.code}，错误信息: ${err.message}`);
          return;
        }
        this.pixelMap = pixelMap;
        hilog.info(0x0001, '[BarcodeGenerate]', '成功生成码图');
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0001, '[BarcodeGenerate]', 
        `调用接口失败，错误码: ${err.code}，错误信息: ${err.message}`);
    }
  }
}
```

### 步骤4：错误处理

**错误处理代码**：
```typescript
async function generateBarcodeWithErrorHandling(content: string, options: generateBarcode.CreateOptions): Promise<image.PixelMap | null> {
  try {
    // 参数校验
    if (!content || content.length === 0) {
      hilog.error(0x0001, '[BarcodeGenerate]', '内容不能为空');
      return null;
    }

    if (options.width < 200 || options.width > 4096) {
      hilog.error(0x0001, '[BarcodeGenerate]', '宽度必须在200-4096之间');
      return null;
    }

    if (options.height < 200 || options.height > 4096) {
      hilog.error(0x0001, '[BarcodeGenerate]', '高度必须在200-4096之间');
      return null;
    }

    // 调用API
    const pixelMap = await generateBarcode.createBarcode(content, options);
    return pixelMap;

  } catch (error) {
    const err = error as BusinessError;
    
    switch (err.code) {
      case 401:
        hilog.error(0x0001, '[BarcodeGenerate]', '参数错误，请检查参数类型和范围');
        // 提示用户检查输入
        break;
      case 1000500001:
        hilog.error(0x0001, '[BarcodeGenerate]', '内部错误，正在重试...');
        // 重试逻辑
        try {
          const retryPixelMap = await generateBarcode.createBarcode(content, options);
          return retryPixelMap;
        } catch (retryError) {
          hilog.error(0x0001, '[BarcodeGenerate]', '重试失败');
          return null;
        }
      default:
        hilog.error(0x0001, '[BarcodeGenerate]', `未知错误: ${err.message}`);
        return null;
    }
  }
}
```

### 步骤5：参数优化建议

**不同码制式的参数建议**：

```typescript
// QR Code、Data Matrix、Aztec：建议宽高相同且≥200px
let qrOptions: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.QR_CODE,
  height: 400,
  width: 400,
  level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
};

// EAN、UPC、Code系列条形码：建议宽高比2:1，宽度>400px
let barcodeOptions: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.EAN13_CODE,
  height: 200,
  width: 400
};

// ITF-14：建议宽高比2:1，宽度>400px
let itfOptions: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.ITF14_CODE,
  height: 200,
  width: 400
};
```

## 错误码说明

| 错误码 | 错误名称 | 说明 | 解决方法 |
|--------|---------|------|---------|
| 401 | 参数错误 | 参数类型不正确或参数验证失败 | 检查参数类型和范围，确保符合要求 |
| 1000500001 | 内部错误 | 算法异常、创建PixelMap失败、读取文件失败等 | 重新调用码图生成接口 |

**详细错误说明**：

**401 - 参数错误**：
- 可能原因1：参数类型不正确
- 可能原因2：参数验证失败（如宽度超出范围）
- 解决方法：检查参数类型和范围

**1000500001 - 内部错误**：
- 可能原因：算法异常、创建PixelMap失败、读取文件失败等
- 解决方法：尝试重新调用接口

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["default", "tablet"],
    "abilities": [...]
  }
}
```

**需要在module.json5中声明权限**（无需特殊权限）：
```json
{
  "module": {
    "requestPermissions": []
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API Version 11 (4.1.0) 及以上
- **DevEco Studio**：4.0及以上版本
- **设备要求**：真机测试（模拟器不支持）
- **Kit依赖**：@kit.ScanKit、@kit.ImageKit、@kit.BasicServicesKit、@kit.PerformanceAnalysisKit

### 常见编译问题

**问题1：模块导入错误**
```
Error: Cannot find module '@kit.ScanKit' or its corresponding type declarations.
```
**解决方法**：
- 检查HarmonyOS SDK版本是否≥11
- 确认module.json5中的deviceTypes包含default或tablet
- 同步项目依赖：File -> Sync and Refresh Project

**问题2：类型定义错误**
```
Error: Property 'PixelMap' does not exist on type 'typeof image'.
```
**解决方法**：
- 检查是否正确导入image模块：`import { image } from '@kit.ImageKit';`
- 确认SDK版本支持PixelMap类型

**问题3：模拟器运行错误**
```
Error: Emulator is not supported.
```
**解决方法**：
- 使用真机测试
- 模拟器不支持码图生成功能

## 常见问题与解决方法

### Q1：生成的码图无法识别
**原因**：
- 码图颜色和背景对比度低
- 码图尺寸过小
- 内容过长导致码图复杂

**解决方法**：
- 使用默认颜色（黑色码图、白色背景）
- 增大码图尺寸（建议≥200px）
- 减少内容长度或选择合适的纠错等级

### Q2：生成条形码时内容限制不明确
**原因**：不同条形码对内容有不同限制

**解决方法**：
参考参数限制表：
- **EAN-8**：7位数字
- **EAN-13**：12位数字，首位不可为0
- **UPC-A**：11位数字
- **UPC-E**：7位数字，首位0或1
- **Code 39/93/128**：数字、字母、符号组合

### Q3：如何在生成后保存为图片文件
**原因**：createBarcode返回PixelMap，不是文件路径

**解决方法**：
```typescript
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';

async function savePixelMapToFile(pixelMap: image.PixelMap, filePath: string): Promise<void> {
  const imagePackerApi = image.createImagePacker();
  const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 98 };
  const data = await imagePackerApi.packing(pixelMap, packOpts);
  const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
  fileIo.writeSync(file.fd, data);
  fileIo.closeSync(file.fd);
}
```

### Q4：纠错等级如何选择
**原因**：QR Code支持四个纠错等级

**解决方法**：
- **LEVEL_L (7%)**：适用于清晰环境，内容较多
- **LEVEL_M (15%)**：平衡纠错和容量
- **LEVEL_Q (25%)**：适用于可能污染的环境
- **LEVEL_H (30%)**：最高纠错，适用于复杂环境（默认）

### Q5：如何生成联系人码图
**原因**：需要将联系人信息格式化为特定格式

**解决方法**：
```typescript
// 生成vCard格式的联系人信息
let contact = `BEGIN:VCARD
VERSION:3.0
N:张三
FN:张三
TEL:13800138000
EMAIL:zhangsan@example.com
END:VCARD`;

let options: generateBarcode.CreateOptions = {
  scanType: scanCore.ScanType.QR_CODE,
  height: 400,
  width: 400
};

const pixelMap = await generateBarcode.createBarcode(contact, options);
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "barcodeType": "QR_CODE",
  "contentLength": 6,
  "imageSize": {
    "width": 400,
    "height": 400
  },
  "pixelMapGenerated": true,
  "apiUsed": [
    "generateBarcode.createBarcode"
  ]
}
```

## 参考文档

- [API开发指南](references/scan-barcodegenerate.md)
- [API参考说明](references/scan-generatebarcode.md)
- [扫码公共信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [图片处理PixelMap](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)
- [错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code)

## 完整示例代码

- [ArkTS示例代码 - Promise方式](assets/barcode_generate_promise.ets)
- [ArkTS示例代码 - Callback方式](assets/barcode_generate_callback.ets)
- [完整页面示例](assets/barcode_generate_page.ets)

## 测试用例

### 正向测试用例
- [生成QR Code二维码](tests/test_positive.ets)：测试生成包含中文内容的QR码
- [生成EAN-13条形码](tests/test_positive.ets)：测试生成标准EAN-13条形码
- [自定义颜色码图](tests/test_positive.ets)：测试自定义前景色和背景色

### 边界测试用例
- [最大尺寸码图](tests/test_boundary.ets)：测试4096x4096像素码图
- [最小尺寸码图](tests/test_boundary.ets)：测试200x200像素码图
- [最大内容长度](tests/test_boundary.ets)：测试512字符QR码内容

### 异常测试用例
- [空内容错误](tests/test_exception.ets)：测试空字符串内容
- [尺寸超限错误](tests/test_exception.ets)：测试宽度或高度超出范围
- [内容格式错误](tests/test_exception.ets)：测试不符合码制式要求的内容