---
name: hmos-scan-kit-customscan
description: 自定义界面扫码能力，提供相机流控制接口实现自定义扫码UI，支持条形码/二维码/MULTIFUNCTIONAL CODE识别、闪光灯控制、变焦、对焦、多码识别，适用于对扫码界面有定制化需求的应用开发场景
---

# 自定义界面扫码技能

## 功能描述

本技能提供 HarmonyOS Scan Kit 的自定义界面扫码能力，通过 `customScan` 模块的相机流控制接口，实现完全自定义的扫码界面和交互逻辑。支持单码/多码识别、闪光灯控制、变焦调节、对焦设置、重新扫码等完整功能，可识别条形码、二维码、MULTIFUNCTIONAL CODE 等多种码类型。

**核心能力：**
- 相机流初始化、启动、暂停、释放、重新扫码
- 闪光灯状态获取、开启、关闭、环境光监听
- 变焦比获取和设置（支持双指缩放手势）
- 相机焦点设置和连续自动对焦
- 单码/多码识别模式
- 相机预览流（YUV）数据获取
- 码图位置坐标返回

**起始版本：** 4.1.0(11)，部分接口需要 5.0.0(12) 或更高版本

## 使用场景

### 触发词
- "自定义界面扫码"
- "自定义扫码"
- "customScan"
- "扫码相机流控制"
- "多码识别"
- "扫码界面定制"

### 能做
- 实现完全自定义 UI 的扫码功能
- 控制相机流（初始化、启动、暂停、释放、重新扫码）
- 控制闪光灯（开启、关闭、状态查询、环境光监听）
- 调节相机变焦（手动设置、获取当前值、双指缩放手势）
- 设置相机对焦位置和连续自动对焦
- 识别单码和多码场景
- 获取相机预览流 YUV 数据和码图位置坐标
- 支持竖屏/横屏/折叠屏适配

### 绝不做
- 不提供默认扫码 UI（默认界面扫码请使用 `scanBarcode.startScanForResult`）
- 不处理图片识码场景（图片识码请使用 `detectBarcode.decodeImage`）
- 不直接生成码图（码图生成请使用 `generateBarcode.createBarcode`）
- 不替代系统扫码入口（控制中心扫一扫）

### 补充
- 需要申请 `ohos.permission.CAMERA` 权限（user_grant 授权方式）
- 必须使用 `XComponent` 组件承载相机预览流 Surface
- 支持的分辨率比例为 16:9、4:3、1:1
- 从 API 版本 26.0.0 开始，可使用 `scanCore.isCustomScanSupported` 查询设备是否支持
- 从 6.1.0(23) 版本开始，支持带后置相机的 Wearable 设备

## 调用规范和规则

### 输入约束
- ViewControl 的 width/height 必须与 XComponent 宽高一致，单位 vp
- 支持的分辨率比例：16:9、4:3、1:1
- 变焦比精度：小数点后两位（例如 1.45）
- setFocusPoint 坐标范围：[0, 1]，超出范围会被截断
- surfaceId 必须从 XComponentController.getXComponentSurfaceId() 获取

### 执行约束
- init 接口必须在 start 之前调用
- 闪光灯/变焦/对焦接口必须在 start 之后、stop 之前调用
- rescan 仅对 start 的 Callback 异步回调有效，Promise 回调无效
- release 建议在 stop 之后调用
- 页面隐藏时必须调用 off('lightingFlash')、stop、release 释放资源

### 内容约束
- 禁止在未申请相机权限时调用 init/start 接口
- 禁止在相机流未启动时调用闪光灯/变焦/对焦接口
- 禁止硬编码 surfaceId，必须动态获取
- 禁止在 Promise 模式下调用 rescan

### 降级约束
- 设备不支持自定义界面扫码时，提示用户使用默认界面扫码
- 相机权限被拒绝时，引导用户到设置页面开启权限
- 相机流异常时，调用 release 释放资源后重新初始化
- 多码识别失败时，降级为单码识别模式

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验：**
1. 检查设备是否支持自定义界面扫码（API 26.0.0+）
2. 在 module.json5 中声明 `ohos.permission.CAMERA` 权限
3. 请求用户授权相机权限

**权限声明（module.json5）：**
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:camera_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**请求权限示例代码：**
```typescript
import { common, abilityAccessCtrl, PermissionRequestResult } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = '[customScan]';
const DOMAIN: number = 0x0001;

async function requestCameraPermission(context: common.UIAbilityContext): Promise<boolean> {
  let atManager = abilityAccessCtrl.createAtManager();
  try {
    const grantStatus: PermissionRequestResult =
      await atManager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
    for (let i = 0; i < grantStatus.authResults.length; i++) {
      if (grantStatus.authResults[i] === 0) {
        hilog.info(DOMAIN, TAG, 'Succeeded in getting camera permission.');
        return true;
      }
    }
    return false;
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to requestPermissionsFromUser. Code: ${err.code}, message: ${err.message}`);
    return false;
  }
}
```

### 步骤2：初始化自定义扫码

**导入模块：**
```typescript
import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
import { display } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, abilityAccessCtrl, PermissionRequestResult } from '@kit.AbilityKit';
```

**设置扫码参数并初始化：**
```typescript
// 多码识别：enableMultiMode: true；单码识别：enableMultiMode: false
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],
  enableMultiMode: true,
  enableAlbum: true
};

try {
  customScan.init(options);
  hilog.info(DOMAIN, TAG, 'Succeeded in init customScan.');
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to init customScan. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤3：设置预览流布局并启动扫码

**设置预览流尺寸（竖屏全屏示例）：**
```typescript
function setDisplay(uiContext: UIContext): { width: number, height: number, offsetX: number } {
  try {
    let displayClass = display.getDefaultDisplaySync();
    let displayHeight = uiContext.px2vp(displayClass.height);
    let displayWidth = uiContext.px2vp(displayClass.width);
    let maxLen = Math.max(displayWidth, displayHeight);
    let minLen = Math.min(displayWidth, displayHeight);
    const RATIO = 16 / 9;
    return {
      width: maxLen / RATIO,
      height: maxLen,
      offsetX: (minLen - maxLen / RATIO) / 2
    };
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to getDefaultDisplaySync. Code: ${err.code}, message: ${err.message}`);
    return { width: 360, height: 640, offsetX: 0 };
  }
}
```

**启动扫码（Promise 方式）：**
```typescript
let viewControl: customScan.ViewControl = {
  width: cameraWidth,
  height: cameraHeight,
  surfaceId: surfaceId
};

try {
  customScan.start(viewControl)
    .then((data: Array<scanBarcode.ScanResult>) => {
      hilog.info(DOMAIN, TAG, `Scan result: ${JSON.stringify(data)}`);
      if (data.length > 0) {
        // 解析码值结果跳转应用服务页
        // 获取到扫描结果后暂停相机流
        customScan.stop().catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
        });
      }
    })
    .catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to start. Code: ${err.code}, message: ${err.message}`);
    });
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to start. Code: ${err.code}, message: ${err.message}`);
}
```

**启动扫码（Callback 方式，含 YUV 预览流）：**
```typescript
const scanCallback: AsyncCallback<Array<scanBarcode.ScanResult>> =
  (err: BusinessError, data: Array<scanBarcode.ScanResult>) => {
    if (err && err.code) {
      hilog.error(DOMAIN, TAG, `Failed to get ScanResult. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    hilog.info(DOMAIN, TAG, `ScanResult: ${JSON.stringify(data)}`);
    if (data.length > 0) {
      // 获取到结果后暂停相机流
      customScan.stop().catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
      });
    }
  };

const frameCallback: AsyncCallback<customScan.ScanFrame> =
  (err: BusinessError, frameResult: customScan.ScanFrame) => {
    if (err) {
      hilog.error(DOMAIN, TAG, `Failed to get ScanFrame. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    hilog.info(DOMAIN, TAG, `ScanFrame byteLength: ${frameResult.byteBuffer.byteLength}, width: ${frameResult.width}, height: ${frameResult.height}`);
  };

try {
  customScan.start(viewControl, scanCallback, frameCallback);
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to start. Code: ${err.code}, message: ${err.message}`);
}
```

### 步骤4：相机控制操作

**闪光灯控制：**
```typescript
// 订阅环境光变化
try {
  customScan.on('lightingFlash', (err: BusinessError, isLightingFlash: boolean) => {
    if (err) {
      hilog.error(DOMAIN, TAG, `Failed to on lightingFlash. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    // isLightingFlash 为 true 表示环境暗，可提示用户开启闪光灯
    if (isLightingFlash) {
      try {
        customScan.openFlashLight();
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to openFlashLight. Code: ${err.code}, message: ${err.message}`);
      }
    } else {
      try {
        if (customScan.getFlashLightStatus()) {
          customScan.closeFlashLight();
        }
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Failed to closeFlashLight. Code: ${err.code}, message: ${err.message}`);
      }
    }
  });
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to on lightingFlash. Code: ${err.code}, message: ${err.message}`);
}
```

**变焦控制：**
```typescript
// 获取当前变焦比
let currentZoom: number = 1;
try {
  currentZoom = customScan.getZoom();
  hilog.info(DOMAIN, TAG, `Current zoom: ${currentZoom}`);
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to getZoom. Code: ${err.code}, message: ${err.message}`);
}

// 设置变焦比（精度最高小数点后两位）
try {
  customScan.setZoom(2.0);
  hilog.info(DOMAIN, TAG, 'Succeeded in setting zoom.');
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to setZoom. Code: ${err.code}, message: ${err.message}`);
}
```

**对焦控制：**
```typescript
// 设置相机焦点（坐标范围 [0, 1]）
// 竖屏时：x = displayY / displayHeight，y = 1.0 - displayX / displayWidth
try {
  customScan.setFocusPoint({ x: 0.5, y: 0.5 });
  hilog.info(DOMAIN, TAG, 'Succeeded in setting focusPoint.');
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to setFocusPoint. Code: ${err.code}, message: ${err.message}`);
}

// 延迟恢复连续自动对焦
setTimeout(() => {
  try {
    customScan.resetFocus();
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to resetFocus. Code: ${err.code}, message: ${err.message}`);
  }
}, 200);
```

### 步骤5：重新扫码与资源释放

**重新扫码（仅 Callback 模式有效）：**
```typescript
try {
  customScan.rescan();
  hilog.info(DOMAIN, TAG, 'Succeeded in rescanning.');
} catch (err) {
  hilog.error(DOMAIN, TAG, `Failed to rescan. Code: ${err.code}, message: ${err.message}`);
}
```

**页面隐藏时释放资源：**
```typescript
function onPageHide() {
  // 1. 注销闪光灯监听
  try {
    customScan.off('lightingFlash');
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to off lightingFlash. Code: ${err.code}, message: ${err.message}`);
  }

  // 2. 暂停相机流
  try {
    customScan.stop().catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
    });
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to stop. Code: ${err.code}, message: ${err.message}`);
  }

  // 3. 释放相机流
  try {
    customScan.release().catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, `Failed to release. Code: ${err.code}, message: ${err.message}`);
    });
  } catch (err) {
    hilog.error(DOMAIN, TAG, `Failed to release. Code: ${err.code}, message: ${err.message}`);
  }
}
```

### 步骤6：错误处理

```typescript
try {
  customScan.start(viewControl);
} catch (err) {
  switch (err.code) {
    case 201:
      hilog.error(DOMAIN, TAG, 'Permission denied. Please request camera permission.');
      // 引导用户到设置页面开启权限
      break;
    case 401:
      hilog.error(DOMAIN, TAG, `Parameter error: ${err.message}`);
      // 检查 ViewControl 参数
      break;
    case 1000500001:
      hilog.error(DOMAIN, TAG, 'Internal error. Try to release and re-init.');
      // 释放资源后重新初始化
      customScan.release().then(() => {
        customScan.init(options);
      });
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error. Code: ${err.code}, message: ${err.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied. | 在 module.json5 中声明 ohos.permission.CAMERA 权限，并调用 requestPermissionsFromUser 请求用户授权 |
| 401 | Parameter error. | 检查 ViewControl 的 width/height/surfaceId 是否正确，确保 surfaceId 从 XComponentController 获取 |
| 1000500001 | Internal error. | 确保调用顺序正确（init → start → 其他接口 → stop → release），尝试 release 后重新 init |
| 1000500002 | The user canceled the barcode scanning. | 用户取消扫码，无需处理，属于正常行为 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {}
}
```

**模块导入：**
```typescript
import { scanCore, scanBarcode, customScan } from '@kit.ScanKit';
```

Scan Kit 为系统 Kit，无需额外安装依赖，只需在 oh-package.json5 中确保 SDK 版本 >= 4.1.0(11)。

### 环境要求
- HarmonyOS SDK: >= 4.1.0(11)（基础接口）
- HarmonyOS SDK: >= 5.0.0(12)（变焦/对焦/闪光灯监听/rescan/ScanFrame）
- HarmonyOS SDK: >= 5.1.0(18)（setAutoZoomEnabled）
- 设备需具备后置摄像头
- 从 6.0.0(20) 开始，模拟器支持 init/start/stop/release/rescan 基本功能验证（仅 1280*720 分辨率）

### 常见编译问题

**问题1：找不到 @kit.ScanKit 模块**
```
Error: Cannot find module '@kit.ScanKit'
```
**解决方法**：确保 HarmonyOS SDK 版本 >= 4.1.0(11)，在 oh-package.json5 中检查 SDK 依赖配置。

**问题2：XComponent surfaceId 获取失败**
```
Error: surfaceId is empty
```
**解决方法**：确保在 XComponent 的 onLoad 回调中获取 surfaceId，不要在 build 阶段获取。

**问题3：init 接口抛出 201 错误**
```
Error: Permission denied
```
**解决方法**：在 module.json5 中声明 ohos.permission.CAMERA 权限，并在调用 init 之前通过 requestPermissionsFromUser 获取用户授权。

## 常见问题与解决方法

### Q1：扫码结果 scanCodeRect 坐标如何转换为屏幕坐标？
**原因**：scanCodeRect 返回的是码图在预览流中的坐标，需要根据 XComponent 的偏移量进行转换。
**解决方法**：
- 竖屏场景：x = (left + right) / 2 + offsetX，y = (top + bottom) / 2 + offsetY
- 设备旋转时需根据 Display.rotation 进行坐标变换
- 详细转换公式参见 [自定义界面扫码开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-customscan)

### Q2：rescan 接口调用无效？
**原因**：rescan 仅对 start 接口的 Callback 异步回调有效，Promise 异步回调无效。
**解决方法**：使用 Callback 模式启动扫码（`customScan.start(viewControl, callback, frameCallback)`），在回调中调用 rescan。

### Q3：闪光灯接口抛出 1000500001 错误？
**原因**：闪光灯接口必须在 start 之后、stop 之前调用。
**解决方法**：确保相机流已启动，调用顺序为：init → start → getFlashLightStatus/openFlashLight/closeFlashLight → stop → release。

### Q4：多码识别场景如何让用户选择特定码图？
**原因**：多码识别返回多个结果，需要暂停相机流由用户选择。
**解决方法**：
1. 在 start 的回调中判断 data.length > 1
2. 调用 stop 暂停相机流
3. 在界面上标注每个码图位置（使用 scanCodeRect 坐标）
4. 用户点击后处理对应结果

### Q5：折叠屏设备如何适配？
**原因**：折叠态切换时 XComponent 宽高变化，需要重新适配相机分辨率。
**解决方法**：
1. 监听折叠态变化事件
2. 调用 stop 暂停相机流
3. 重新计算 XComponent 宽高
4. 重新调用 start 接口适配新分辨率

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "scanResult": [
    {
      "scanType": 11,
      "originalValue": "https://example.com",
      "scanCodeRect": {
        "left": 84,
        "top": 142,
        "right": 1695,
        "bottom": 996
      }
    }
  ],
  "apiUsed": [
    "customScan.init",
    "customScan.start",
    "customScan.stop",
    "customScan.release",
    "customScan.on('lightingFlash')",
    "customScan.off('lightingFlash')",
    "customScan.getFlashLightStatus",
    "customScan.openFlashLight",
    "customScan.closeFlashLight",
    "customScan.setZoom",
    "customScan.getZoom",
    "customScan.setFocusPoint",
    "customScan.resetFocus",
    "customScan.rescan"
  ]
}
```

## 参考文档

- [自定义界面扫码开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-customscan)
- [customScan API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-customscan-api)
- [scanBarcode API 参考（ScanResult/ScanOptions/ScanCodeRect/Point）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [scanCore API 参考（ScanType 枚举）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [扫码错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code)
- [接入扫码直达服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-directservice)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- [requestPermissionsFromUser 接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-abilityaccessctrl)
- [XComponent 组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-xcomponent)
- [display 屏幕管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-display)
- [UIContext px2vp](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-uicontext-uicontext)
- [cameraManager.getSupportedCameras](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-camera-cameramanager)
- [使用模拟器运行应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-run-emulator)

## 完整示例代码

- [ArkTS 完整示例（Promise 模式）](assets/custom_scan_promise_example.ets)
- [ArkTS 完整示例（Callback 模式）](assets/custom_scan_callback_example.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常单码扫码流程](tests/test_positive.py)：验证 init → start → 获取结果 → stop → release 完整流程
- [多码识别场景](tests/test_positive.py)：验证 enableMultiMode: true 时多码识别返回多个结果
- [闪光灯自动控制](tests/test_positive.py)：验证 on('lightingFlash') 监听和闪光灯开关逻辑

### 边界测试用例
- [变焦比边界值](tests/test_boundary.py)：验证 setZoom 设置最小值(1.0)和最大值时的行为
- [对焦坐标边界值](tests/test_boundary.py)：验证 setFocusPoint 设置 {0,0} 和 {1,1} 时的行为
- [分辨率比例适配](tests/test_boundary.py)：验证 16:9、4:3、1:1 三种比例的适配

### 异常测试用例
- [未申请权限调用 init](tests/test_exception.py)：验证返回 201 错误码
- [未启动相机流调用闪光灯接口](tests/test_exception.py)：验证返回 1000500001 错误码
- [Promise 模式调用 rescan](tests/test_exception.py)：验证 rescan 在 Promise 模式下无效
- [页面隐藏未释放资源](tests/test_exception.py)：验证资源泄漏检测
