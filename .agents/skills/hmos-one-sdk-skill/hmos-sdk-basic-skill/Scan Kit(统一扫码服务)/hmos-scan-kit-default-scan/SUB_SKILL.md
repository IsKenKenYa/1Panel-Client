---
name: hmos-scan-kit-default-scan
description: 提供系统级默认界面扫码能力+支持单码和多码识别+无需申请相机权限+适用于应用内扫码场景
---

# 默认界面扫码技能

## 功能描述

本技能提供HarmonyOS系统级默认界面扫码能力,通过Scan Kit的`startScanForResult`接口实现。默认界面扫码提供统一的扫码体验,包含相机预览流、相册扫码入口、暗光环境闪光灯开启提示,对系统相机权限进行了预授权且调用期间处于安全访问状态,无需开发者再次申请相机权限。

### 核心特性
- 系统级体验一致的扫码界面
- 支持单码和多码识别模式
- 支持多种码类型(QR Code、条形码等)
- 相册扫码入口(仅支持单码)
- 无需申请相机权限
- 支持Promise和Callback两种异步回调方式
- 暗光环境自动提示开启闪光灯

### API版本要求
- 起始版本: 4.0.0(10)
- 元服务API支持: 从版本4.1.0(11)开始
- 默认界面扫码标题动态显示: 从6.1.0(23)版本开始
- 支持Wearable设备: 从6.1.0(23)版本开始(需带后置相机)
- 支持悬浮屏、分屏场景: 从6.0.0(20)版本开始

## 使用场景

### 触发词
- "默认界面扫码" - 使用系统默认UI扫码
- "扫码功能" - 实现应用内扫码
- "二维码扫描" - 扫描QR码
- "条形码扫描" - 扫描条形码
- "多码识别" - 同时识别多个码图
- "相册扫码" - 从相册选择图片扫码
- "startScanForResult" - 调用默认界面扫码API

### 能做
- 启动系统默认扫码界面进行扫码
- 配置扫码类型(支持ALL、QR_CODE、条形码等多种类型)
- 配置单码或多码识别模式
- 开启或关闭相册扫码功能
- 通过Promise或Callback方式获取扫码结果
- 解析扫码结果获取码类型、码值、码位置等信息
- 处理扫码错误和异常情况

### 绝不做
- 不支持自定义扫码界面UI(如需自定义界面请使用自定义界面扫码能力)
- 不支持同时开启多码识别和相册扫码(相册扫码只支持单码)
- 不支持扫码结果的后处理逻辑(如URL跳转、数据解析等需开发者自行实现)
- 不支持在非Stage模型下使用
- 不支持在页面和组件生命周期外调用

### 补充
- 系统首次使用时会弹出隐私横幅提醒,用户关闭后再次打开将显示安全访问提示(3秒后消失)
- 从6.1.0(23)版本开始,扫码界面标题根据scanTypes动态显示
- startScanForResult接口需要在页面和组件的生命周期内调用
- 推荐接入"扫码直达"服务以支持系统扫码入口和应用内扫码两种方式

## 调用规范和规则

### 输入约束
- **Context类型**: 必须提供有效的`common.Context`对象
- **ScanOptions配置**:
  - scanTypes: 码类型数组,默认ALL(全部码类型)
  - enableMultiMode: boolean,是否开启多码识别,默认false
  - enableAlbum: boolean,是否开启相册,默认true
- **码类型限制**: scanTypes支持以下类型:
  - ALL(1001): 所有码类型
  - QR_CODE(11): QR码
  - ONE_D_CODE(100): 条形码(包含CODABAR、CODE39等)
  - TWO_D_CODE(101): 二维码(包含AZTEC、DATAMATRIX等)
  - 其他具体码类型(如EAN13、CODE128等)

### 执行约束
- **调用时机**: 必须在页面和组件的生命周期内调用
- **权限要求**: 无需申请相机权限(系统预授权)
- **模型限制**: 仅可在Stage模型下使用
- **线程安全**: 异步调用,不阻塞主线程

### 内容约束
- **禁止生成**: 不生成自定义扫码界面代码
- **禁止高危操作**: 不使用eval、exec等高危函数
- **禁止权限申请**: 不生成相机权限申请代码
- **错误处理**: 必须包含try-catch错误捕获和BusinessError处理

### 降级约束
- **网络失败**: 提示用户检查网络连接
- **设备不支持**: 使用scanCore.isDefaultScanSupported接口检测,不支持时提示用户
- **用户取消**: 处理错误码1000500002,提供友好的取消提示
- **内部错误**: 处理错误码1000500001,记录日志并提示用户稍后重试

## 调用流程和步骤

### 步骤1: 导入必要模块

**说明**: 导入Scan Kit的核心模块和辅助模块。

```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**模块说明**:
- `scanCore`: 提供扫码类型定义(ScanType)
- `scanBarcode`: 提供默认界面扫码方法和参数
- `hilog`: 日志记录模块
- `BusinessError`: 错误处理模块

### 步骤2: 配置扫码参数

**说明**: 根据业务需求配置ScanOptions参数。

```typescript
// 配置扫码参数
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],      // 扫码类型:全部码类型
  enableMultiMode: true,                    // 开启多码识别
  enableAlbum: true                         // 开启相册扫码
};
```

**参数说明**:
- `scanTypes`: 码类型数组,可配置多种码类型
- `enableMultiMode`: 是否开启多码识别,默认false
- `enableAlbum`: 是否开启相册,默认true(相册仅支持单码)

### 步骤3: 获取UIContext和HostContext

**说明**: 在页面组件中获取UIContext和HostContext。

```typescript
@Entry
@Component
struct ScanPage {
  build() {
    Column() {
      Button('启动扫码')
        .onClick(() => {
          // 获取当前页面关联的Context
          let context = this.getUIContext().getHostContext();
          // 调用扫码接口
          this.startScan(context);
        })
    }
  }
}
```

**Context说明**:
- `getUIContext()`: 获取UI上下文
- `getHostContext()`: 获取当前页面关联的Context对象

### 步骤4: 调用startScanForResult(Promise方式)

**说明**: 使用Promise异步回调方式启动扫码。

```typescript
async function startScanPromise(context: common.Context, options: scanBarcode.ScanOptions): void {
  try {
    const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
    hilog.info(0x0001, '[ScanKit]', `扫码成功: ${JSON.stringify(result)}`);
    // 处理扫码结果
    this.handleScanResult(result);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0001, '[ScanKit]', `扫码失败: Code=${err.code}, Message=${err.message}`);
    // 错误处理
    this.handleScanError(err);
  }
}
```

**返回值说明**:
- `ScanResult`包含:
  - `scanType`: 码类型
  - `originalValue`: 码识别内容
  - `scanCodeRect`: 码位置信息(可选)
  - `cornerPoints`: 码角点位置(可选)
  - `isGS1`: 是否携带GS1数据(可选)
  - `source`: 扫码来源(可选)

### 步骤5: 调用startScanForResult(Callback方式)

**说明**: 使用Callback异步回调方式启动扫码。

```typescript
function startScanCallback(context: common.Context, options: scanBarcode.ScanOptions): void {
  try {
    scanBarcode.startScanForResult(context, options, (error: BusinessError, result: scanBarcode.ScanResult) => {
      if (error) {
        hilog.error(0x0001, '[ScanKit]', `扫码失败: Code=${error.code}, Message=${error.message}`);
        this.handleScanError(error);
        return;
      }
      hilog.info(0x0001, '[ScanKit]', `扫码成功: ${JSON.stringify(result)}`);
      this.handleScanResult(result);
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0001, '[ScanKit]', `启动扫码失败: Code=${err.code}, Message=${err.message}`);
  }
}
```

**Callback说明**:
- `error`: 错误对象,成功时为undefined
- `result`: 扫码结果对象

### 步骤6: 处理扫码结果

**说明**: 解析并处理扫码返回的结果数据。

```typescript
function handleScanResult(result: scanBarcode.ScanResult): void {
  // 获取码类型
  const scanType = result.scanType;
  hilog.info(0x0001, '[ScanKit]', `码类型: ${scanType}`);
  
  // 获取码值
  const codeValue = result.originalValue;
  hilog.info(0x0001, '[ScanKit]', `码内容: ${codeValue}`);
  
  // 获取码位置(可选)
  if (result.scanCodeRect) {
    const rect = result.scanCodeRect;
    hilog.info(0x0001, '[ScanKit]', `码位置: left=${rect.left}, top=${rect.top}, right=${rect.right}, bottom=${rect.bottom}`);
  }
  
  // 检查是否携带GS1数据(可选)
  if (result.isGS1) {
    hilog.info(0x0001, '[ScanKit]', '码图携带GS1数据');
  }
  
  // 获取扫码来源(可选)
  if (result.source) {
    const source = result.source;
    hilog.info(0x0001, '[ScanKit]', `扫码来源: ${source === scanCore.ScanSource.CAMERA ? '相机' : '相册'}`);
  }
  
  // 根据码类型进行后续处理
  if (scanType === scanCore.ScanType.QR_CODE) {
    // 处理QR码,可能是URL或其他内容
    if (codeValue.startsWith('http://') || codeValue.startsWith('https://')) {
      // 跳转到URL页面
      this.openUrl(codeValue);
    } else {
      // 显示其他内容
      this.showContent(codeValue);
    }
  } else {
    // 处理条形码等其他码类型
    this.showContent(codeValue);
  }
}
```

### 步骤7: 错误处理和降级

**说明**: 处理扫码过程中可能出现的错误。

```typescript
function handleScanError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      // 参数错误
      hilog.error(0x0001, '[ScanKit]', '参数错误: 检查参数类型和验证');
      // 提示用户检查输入
      this.showToast('扫码参数错误,请检查配置');
      break;
      
    case 1000500001:
      // 内部错误
      hilog.error(0x0001, '[ScanKit]', '内部错误: 扫码服务异常');
      // 提示用户稍后重试
      this.showToast('扫码服务异常,请稍后重试');
      // 降级处理: 建议用户手动输入
      this.showManualInputDialog();
      break;
      
    case 1000500002:
      // 用户取消扫码
      hilog.info(0x0001, '[ScanKit]', '用户取消了扫码');
      // 正常处理取消操作,不做额外提示
      break;
      
    default:
      // 其他未知错误
      hilog.error(0x0001, '[ScanKit]', `未知错误: Code=${error.code}, Message=${error.message}`);
      this.showToast('扫码失败,请重试');
      break;
  }
}
```

**错误码说明**:
- `401`: 参数错误(类型错误或验证失败)
- `1000500001`: 内部错误(扫码服务异常)
- `1000500002`: 用户取消扫码

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 可能原因: 1.参数类型错误; 2.参数验证失败 | 检查context是否为有效的common.Context对象; 检查options参数类型和取值范围 |
| 1000500001 | Internal error. 扫码服务内部错误 | 记录日志并提示用户稍后重试; 提供手动输入作为降级方案 |
| 1000500002 | The user canceled the barcode scanning. 用户取消扫码 | 正常处理取消操作,不做额外提示或错误处理 |

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**:
```json
{
  "dependencies": {
    "@kit.ScanKit": "4.0.0(10)+"
  }
}
```

**导入说明**:
- Scan Kit从API版本4.0.0(10)开始提供
- 需要在oh-package.json5中声明依赖

### 环境要求

- **HarmonyOS版本**: 4.0.0(10)及以上
- **开发模型**: Stage模型
- **设备要求**: 
  - 默认支持Phone、Tablet设备
  - 从6.1.0(23)版本开始支持带后置相机的Wearable设备
- **权限要求**: 无需申请相机权限(系统预授权)
- **开发工具**: DevEco Studio 4.0及以上

### 常见编译问题

**问题1: 导入模块找不到**
```
Error: Cannot find module '@kit.ScanKit' or its corresponding type declarations.
```
**解决方法**: 
- 检查oh-package.json5是否声明了@kit.ScanKit依赖
- 确认HarmonyOS SDK版本是否支持Scan Kit(需要4.0.0+)
- 在DevEco Studio中执行ohpm install安装依赖

**问题2: Context类型错误**
```
Error: Argument of type 'UIContext' is not assignable to parameter of type 'common.Context'.
```
**解决方法**: 
- 使用`this.getUIContext().getHostContext()`获取正确的Context对象
- 不要直接传递UIContext或Component对象

**问题3: 异步回调类型错误**
```
Error: Callback signature mismatch.
```
**解决方法**: 
- 确保Callback签名正确: `(error: BusinessError, result: scanBarcode.ScanResult) => void`
- 注意error和result的顺序,error在前,result在后

**问题4: ScanOptions参数错误**
```
Error: Property 'enableMultiMode' does not exist on type 'ScanOptions'.
```
**解决方法**: 
- 检查scanTypes、enableMultiMode、enableAlbum参数名称是否正确
- 确认参数类型:boolean和Array<scanCore.ScanType>

## 常见问题与解决方法

### Q1: 如何配置扫码类型?
**原因**: 需要根据业务场景选择合适的码类型。
**解决方法**:
- 扫描所有码类型: `scanTypes: [scanCore.ScanType.ALL]`
- 仅扫描QR码: `scanTypes: [scanCore.ScanType.QR_CODE]`
- 仅扫描条形码: `scanTypes: [scanCore.ScanType.ONE_D_CODE]`
- 仅扫描二维码: `scanTypes: [scanCore.ScanType.TWO_D_CODE]`
- 扫描特定码类型: `scanTypes: [scanCore.ScanType.EAN13_CODE, scanCore.ScanType.CODE128_CODE]`

### Q2: 如何开启多码识别?
**原因**: 需要同时识别多个码图。
**解决方法**:
- 设置`enableMultiMode: true`
- 注意: 多码识别时,用户需要点击选择其中一个码图获取结果
- 相册扫码不支持多码识别

### Q3: 如何判断设备是否支持默认界面扫码?
**原因**: 不同设备可能不支持默认界面扫码能力。
**解决方法**:
```typescript
import { scanCore } from '@kit.ScanKit';

// 从API版本26.0.0开始支持检测
const isSupported = scanCore.isDefaultScanSupported();
if (!isSupported) {
  // 设备不支持,提示用户或使用其他扫码方式
  this.showToast('当前设备不支持默认界面扫码');
}
```

### Q4: 如何处理扫码结果中的URL?
**原因**: QR码可能包含URL链接,需要跳转到对应页面。
**解决方法**:
```typescript
function handleScanResult(result: scanBarcode.ScanResult): void {
  const codeValue = result.originalValue;
  
  // 判断是否为URL
  if (codeValue.startsWith('http://') || codeValue.startsWith('https://')) {
    // 使用Web组件或其他方式打开URL
    // 注意: 需要在module.json5中配置网络权限
    this.openWebPage(codeValue);
  }
}
```

### Q5: 如何获取扫码的图片来源?
**原因**: 需要区分是从相机扫码还是相册扫码。
**解决方法**:
```typescript
function handleScanResult(result: scanBarcode.ScanResult): void {
  if (result.source) {
    const source = result.source;
    if (source === scanCore.ScanSource.CAMERA) {
      hilog.info(0x0001, '[ScanKit]', '扫码来源: 相机流');
    } else if (source === scanCore.ScanSource.PHOTO) {
      hilog.info(0x0001, '[ScanKit]', '扫码来源: 相册照片');
    }
  }
}
```

### Q6: 如何设置扫码界面为全屏或沉浸式?
**原因**: 需要自定义扫码界面的显示样式。
**解决方法**:
- 参考开发应用沉浸式效果文档
- 在页面组件中设置窗口属性
- 注意: 默认界面扫码的UI不可自定义,只能设置页面样式

### Q7: 相册扫码有什么限制?
**原因**: 相册扫码功能有特殊限制。
**解决方法**:
- 相册扫码只支持单码识别(不支持enableMultiMode)
- 相册扫码通过`enableAlbum: true`开启
- 用户需要手动从相册选择图片

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "scanResult": {
    "scanType": "QR_CODE",
    "originalValue": "https://example.com",
    "scanCodeRect": {
      "left": 100,
      "top": 100,
      "right": 200,
      "bottom": 200
    },
    "isGS1": false,
    "source": "CAMERA"
  },
  "apiUsed": [
    "scanBarcode.startScanForResult",
    "scanCore.ScanType",
    "scanCore.ScanSource"
  ],
  "executionTime": "2.5s",
  "userAction": "camera_scan"
}
```

**字段说明**:
- `status`: 扫码状态(success/failed/canceled)
- `scanResult`: 扫码结果对象
- `apiUsed`: 使用的API列表
- `executionTime`: 执行耗时
- `userAction`: 用户操作方式(camera_scan/photo_scan)

## 参考文档

- [默认界面扫码开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-scanbarcode)
- [scanBarcode API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [scanCore API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [接入"扫码直达"服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-directservice)

## 完整示例代码

### Promise方式示例
- [ArkTS示例(Promise)](assets/scan_promise_example.ets)

### Callback方式示例
- [ArkTS示例(Callback)](assets/scan_callback_example.ets)

### 多码识别示例
- [ArkTS示例(多码识别)](assets/scan_multi_mode_example.ets)

### 相册扫码示例
- [ArkTS示例(相册扫码)](assets/scan_album_example.ets)

### 错误处理示例
- [ArkTS示例(错误处理)](assets/scan_error_handling_example.ets)

## 测试用例

### 正向测试用例
- [基础扫码测试](tests/test_basic_scan.ts): 测试默认参数扫码功能
- [QR码扫码测试](tests/test_qr_code_scan.ts): 测试QR码识别
- [条形码扫码测试](tests/test_barcode_scan.ts): 测试条形码识别
- [多码识别测试](tests/test_multi_mode_scan.ts): 测试多码识别功能
- [相册扫码测试](tests/test_album_scan.ts): 测试相册扫码功能

### 边界测试用例
- [空参数测试](tests/test_empty_params.ts): 测试不传递options参数
- [极限参数测试](tests/test_extreme_params.ts): 测试所有码类型配置
- [Context边界测试](tests/test_context_boundary.ts): 测试不同Context获取方式

### 异常测试用例
- [参数错误测试](tests/test_invalid_params.ts): 测试错误的参数类型
- [用户取消测试](tests/test_user_cancel.ts): 测试用户取消扫码场景
- [内部错误测试](tests/test_internal_error.ts): 测试内部错误处理
- [设备不支持测试](tests/test_device_not_supported.ts): 测试设备不支持场景
- [生命周期外调用测试](tests/test_out_of_lifecycle.ts): 测试在生命周期外调用