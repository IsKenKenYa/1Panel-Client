---
name: hmos-share-kit-knock-coordinate
description: 获取手机与PC/2in1、Tablet设备间轻碰分享时的坐标位置信息，支持发送端和接收端坐标获取，适用于向文档指定位置插入图片或获取窗口指定图片等场景，需要API 26.0.0(23)及以上版本
---

# 手机与PC/2in1、手机与Tablet间相互分享技能

## 功能描述

本技能提供手机与PC/2in1、Tablet设备间碰一碰分享功能，核心能力是从轻碰事件中获取坐标位置信息（基于屏幕左上角为初始点的坐标）。通过获取轻碰位置，可实现向文档指定位置插入图片、从窗口指定位置获取图片等精准业务逻辑。

**主要功能**：
- 注册碰一碰分享事件监听（发送端）
- 注册沙箱接收事件监听（接收端）
- 从轻碰事件中获取屏幕坐标信息
- 实现跨设备内容分享与接收

**适用场景**：
- Phone与PC/2in1设备间相互分享（API 5.0.0(12)及以上）
- Phone与Tablet设备间相互分享（API 6.1.0(23)及以上）
- 需要获取轻碰坐标的精准操作场景（API 26.0.0(23)及以上）

## 使用场景

### 触发词
- "碰一碰分享"
- "获取轻碰坐标"
- "手机与PC分享"
- "手机与Tablet分享"
- "跨设备分享"
- "获取分享位置"

### 能做
- 注册和取消碰一碰分享事件监听
- 获取轻碰事件的屏幕坐标（screenX、screenY）
- 发送分享数据到目标设备
- 接收其他设备分享的数据
- 根据坐标位置实现精准业务逻辑（如向指定位置插入内容）

### 绝不做
- 不支持Tablet设备作为发送端注册knockShare事件（仅PC/2in1可接收）
- 不处理超出Share Kit范围的其他分享方式
- 不处理文本类型的沙箱接收（仅支持文件类型）
- 不生成或修改分享内容本身（仅负责传输和坐标获取）

### 补充
- 获取轻碰坐标功能需要API 26.0.0(23)及以上版本
- 发送端坐标通过SharableTarget.getInfo()获取
- 接收端坐标通过ReceivableTarget.getInfo()获取
- coordinate字段包含screenX和screenY两个属性
- Phone与Phone间分享请参考：[手机间内容分享](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/knock-share-between-phones-content)

## 调用规范和规则

### 输入约束
- windowId：必须为有效的窗口ID
- 接收目录路径：必须真实存在且为有效沙箱路径
- 数据类型：必须为utd.UniformDataType预置类型或已知自定义类型
- 文件路径：必须是应用沙箱内的有效路径
- 数据记录数量：最大500条
- 缩略图大小：最大32KB
- 数据总大小：最大200KB（IPC传输上限）

### 执行约束
- 调用模式：异步Promise模式
- 事件监听：必须先注册监听再触发分享
- 设备类型限制：
  - knockShare事件：Tablet设备无效
  - dataReceive事件：仅PC/2in1设备可用
- API版本要求：
  - 基础分享：API 5.0.0(12)
  - Tablet分享：API 6.1.0(23)
  - 坐标获取：API 26.0.0(23)

### 内容约束
- 禁止生成：不生成分享内容本身（图片、文本等）
- 禁止高危函数：不使用eval、exec等高危操作
- 禁止硬编码：不硬编码windowId、文件路径等参数
- 必须校验：参数类型校验、路径有效性校验
- 必须捕获：所有API调用必须包含try-catch异常捕获

### 降级约束
- 网络失败：提示用户检查网络连接，使用系统分享面板作为备选方案
- 坐标获取失败：使用默认位置或提示用户手动选择位置
- 设备不支持：提示用户设备不支持此功能，引导使用其他分享方式
- 权限不足：提示用户申请必要权限或使用系统默认分享功能
- 文件过大：提示用户压缩文件或使用其他传输方式

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 导入必要模块：@kit.ShareKit, @kit.ArkData, @kit.CoreFileKit, @kit.AbilityKit
2. 验证API版本是否符合要求（最低5.0.0(12)，坐标获取需要26.0.0(23)）
3. 验证设备类型是否支持对应功能
4. 验证windowId参数是否有效
5. 验证接收目录是否存在

**参数准备**：
```typescript
// 导入必要模块
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

// 定义状态变量存储坐标信息
@State knockShareScreenX: number | undefined = undefined;
@State knockShareScreenY: number | undefined = undefined;
@State dataReceiveScreenX: number | undefined = undefined;
@State dataReceiveScreenY: number | undefined = undefined;

// 准备windowId（需要替换为实际值）
const windowId: number = 999; // 实际使用时需替换为正确的windowId

// 准备接收目录路径
let uiContext: UIContext = this.getUIContext();
let context = uiContext.getHostContext() as common.UIAbilityContext;
const receiveDir = context.filesDir; // 应用沙箱目录
```

### 步骤2：注册事件监听

**示例代码**：
```typescript
// 注册碰一碰分享事件监听（发送端）
private registerKnockShareListener() {
  try {
    harmonyShare.on('knockShare', this.knockShareCallback);
    console.info('KnockShare listener registered successfully');
  } catch (error) {
    console.error('Failed to register knockShare listener:', error.message);
    throw error;
  }
}

// 注册沙箱接收事件监听（接收端）
private registerDataReceiveListener() {
  try {
    // 配置接收能力
    let capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
      windowId: this.windowId, // 替换为实际的windowId
      capabilities: [{
        utd: utd.UniformDataType.IMAGE, // 设置接收的数据类型
        maxSupportedCount: 1 // 最大接收数量
      }]
    };
    
    harmonyShare.on('dataReceive', capabilityRegistry, this.dataReceiveCallback);
    console.info('DataReceive listener registered successfully');
  } catch (error) {
    console.error('Failed to register dataReceive listener:', error.message);
    throw error;
  }
}
```

### 步骤3：处理分享回调（发送端）

**示例代码**：
```typescript
private knockShareCallback = (sharableTarget: harmonyShare.SharableTarget) => {
  try {
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;
    
    // 准备分享数据
    let filePath = contextFaker.filesDir + '/exampleKnock1.jpg'; // 替换为实际文件路径
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.JPEG,
      uri: fileUri.getUriFromPath(filePath),
      thumbnailUri: fileUri.getUriFromPath(filePath)
    });
    
    // 获取轻碰坐标信息
    let sharableTargetInfo = sharableTarget.getInfo();
    this.knockShareScreenX = sharableTargetInfo.coordinate?.screenX;
    this.knockShareScreenY = sharableTargetInfo.coordinate?.screenY;
    
    console.info(`KnockShare coordinate: X=${this.knockShareScreenX}, Y=${this.knockShareScreenY}`);
    
    // 发起分享
    sharableTarget.share(shareData)
      .then(() => {
        console.info('Share successful');
      })
      .catch((error) => {
        console.error('Share failed:', error.message);
      });
  } catch (error) {
    console.error('KnockShare callback error:', error.message);
  }
}
```

### 步骤4：处理接收回调（接收端）

**示例代码**：
```typescript
private dataReceiveCallback = (receivableTarget: harmonyShare.ReceivableTarget) => {
  try {
    let uiContext: UIContext = this.getUIContext();
    let context = uiContext.getHostContext() as common.UIAbilityContext;
    
    // 准备接收目录
    let sandboxUri = fileUri.getUriFromPath(context.filesDir);
    
    // 获取轻碰坐标信息
    let receivableTargetInfo = receivableTarget.getInfo();
    this.dataReceiveScreenX = receivableTargetInfo.coordinate?.screenX;
    this.dataReceiveScreenY = receivableTargetInfo.coordinate?.screenY;
    
    console.info(`DataReceive coordinate: X=${this.dataReceiveScreenX}, Y=${this.dataReceiveScreenY}`);
    
    // 发起接收
    receivableTarget.receive(sandboxUri, {
      onDataReceived: (sharedData: systemShare.SharedData) => {
        let sharedRecords = sharedData.getRecords();
        sharedRecords.forEach((record: systemShare.SharedRecord) => {
          console.info('Received file:', record.uri);
          // 处理接收到的数据
        });
      },
      onResult: (resultCode: harmonyShare.ShareResultCode) => {
        if (resultCode === harmonyShare.ShareResultCode.SHARE_SUCCESS) {
          console.info('Receive successful');
        } else {
          console.error('Receive failed with code:', resultCode);
        }
      }
    });
  } catch (error) {
    console.error('DataReceive callback error:', error.message);
  }
}
```

### 步骤5：错误处理

**示例代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  // 尝试注册监听或调用分享API
  this.registerKnockShareListener();
} catch (error) {
  let businessError = error as BusinessError;
  switch (businessError.code) {
    case 401:
      console.error('Parameter error. Please check windowId and file path.');
      // 提示用户检查参数配置
      break;
    case 1003703001:
      console.error('Parse data failed. Invalid want format.');
      // 提示数据格式错误
      break;
    case 1003700001:
      console.error('Number of records exceeds maximum (500).');
      // 提示用户减少分享文件数量
      break;
    case 1003702001:
      console.error('Record types not supported.');
      // 提示用户使用支持的数据类型
      break;
    case 1003702002:
      console.error('IPC data oversized (200KB limit).');
      // 提示用户压缩缩略图或减少文本内容
      break;
    default:
      console.error('Unknown error:', businessError.message);
      // 使用降级方案
      this.fallbackToSystemShare();
  }
}
```

### 步骤6：降级处理

**示例代码**：
```typescript
private fallbackToSystemShare() {
  try {
    // 使用系统分享面板作为降级方案
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.IMAGE,
      uri: 'file://...'
    });
    
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let uiContext: UIContext = this.getUIContext();
    let context = uiContext.getHostContext() as common.UIAbilityContext;
    
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    }).then(() => {
      console.info('Fallback to system share successful');
    }).catch((error) => {
      console.error('Fallback failed:', error.message);
      // 最终降级方案：提示用户手动操作
      console.warn('Please use other sharing method');
    });
  } catch (error) {
    console.error('Fallback error:', error.message);
  }
}
```

### 步骤7：取消监听

**示例代码**：
```typescript
// 取消碰一碰分享监听
private unregisterKnockShareListener() {
  try {
    harmonyShare.off('knockShare');
    console.info('KnockShare listener unregistered');
  } catch (error) {
    console.error('Failed to unregister knockShare listener:', error.message);
  }
}

// 取消沙箱接收监听
private unregisterDataReceiveListener() {
  try {
    let capabilityRegistry: harmonyShare.RecvCapabilityRegistry = {
      windowId: this.windowId,
      capabilities: [{
        utd: utd.UniformDataType.IMAGE,
        maxSupportedCount: 1
      }]
    };
    harmonyShare.off('dataReceive', capabilityRegistry);
    console.info('DataReceive listener unregistered');
  } catch (error) {
    console.error('Failed to unregister dataReceive listener:', error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查windowId、文件路径、数据类型等参数是否正确 |
| 1003700001 | 数据记录超过上限（500条） | 减少分享文件数量至500条以内 |
| 1003702001 | 数据记录类型不支持 | 检查utd类型是否为预置类型或已知自定义类型 |
| 1003702002 | IPC传输数据超过上限（200KB） | 压缩缩略图至32KB以下，减少文本内容 |
| 1003703001 | 数据解析失败 | 检查want格式是否正确，是否为分享类型数据 |
| 801 | 设备不支持此功能 | Tablet设备不支持knockShare事件，PC/2in1以外设备不支持dataReceive事件 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "5.0.0(12)",
    "@kit.ArkData": "5.0.0(12)",
    "@kit.CoreFileKit": "5.0.0(12)",
    "@kit.AbilityKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS API：最低5.0.0(12)
- 坐标获取功能：最低26.0.0(23)
- Tablet分享：最低6.1.0(23)
- 运行环境：Stage模型
- 系统能力：SystemCapability.Collaboration.HarmonyShare

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.ShareKit' or its corresponding type declarations.
```
**解决方法**：确保HarmonyOS SDK版本为5.0.0(12)及以上，检查项目配置

**问题2：API不存在**
```
Property 'getInfo' does not exist on type 'SharableTarget'.
```
**解决方法**：确保API版本为26.0.0(23)及以上，检查SDK版本配置

**问题3：windowId参数错误**
```
Parameter error. Possible reasons: Incorrect parameter type.
```
**解决方法**：使用正确的方法获取windowId，避免硬编码

**问题4：权限不足**
```
Permission denied. Required permission: ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST
```
**解决方法**：申请必要权限或使用系统默认分享功能

## 常见问题与解决方法

### Q1：无法获取轻碰坐标信息
**原因**：
- API版本低于26.0.0(23)
- 设备类型不支持
- coordinate字段为undefined

**解决方法**：
1. 检查API版本是否满足26.0.0(23)
2. 验证设备类型（PC/2in1、Tablet）
3. 使用可选链操作符访问coordinate字段
4. 提供默认坐标作为降级方案

### Q2：Tablet设备无法触发分享
**原因**：knockShare事件在Tablet设备上无效

**解决方法**：
1. Tablet设备不支持作为发送端注册knockShare事件
2. Tablet可作为接收端（API 6.1.0(23)及以上）
3. 使用系统分享面板替代方案

### Q3：接收目录不存在导致接收失败
**原因**：receive方法要求接收目录必须真实存在

**解决方法**：
1. 在调用receive前先创建接收目录
2. 使用应用沙箱路径（context.filesDir）
3. 检查目录权限和有效性

### Q4：缩略图过大导致分享失败
**原因**：缩略图超过32KB，IPC传输数据超过200KB

**解决方法**：
1. 使用ImagePacker压缩缩略图
2. 减小缩略图尺寸或质量
3. 控制文本内容长度

### Q5：分享数据记录数量超限
**原因**：SharedData包含超过500条记录

**解决方法**：
1. 控制单次分享文件数量在500条以内
2. 分批次进行多次分享
3. 使用批量模式（SelectionMode.BATCH）优化

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "knockShareCoordinate": {
    "screenX": 100,
    "screenY": 200
  },
  "dataReceiveCoordinate": {
    "screenX": 150,
    "screenY": 250
  },
  "sharedFiles": ["file://.../example.jpg"],
  "receivedFiles": ["file://.../received_image.jpg"],
  "apiUsed": [
    "harmonyShare.on('knockShare')",
    "harmonyShare.on('dataReceive')",
    "SharableTarget.getInfo()",
    "ReceivableTarget.getInfo()",
    "SharableTarget.share()",
    "ReceivableTarget.receive()"
  ]
}
```

## 参考文档

- [API开发指南](references/knock-share-pc-phones-mutually.md)
- [harmonyShare API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [systemShare API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [Share Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-error-code)
- [手机间内容分享](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/knock-share-between-phones-content)

## 完整示例代码

- [ArkTS示例代码](assets/knock-share-example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [注册监听并获取坐标](tests/test_positive.ts)：测试正常注册监听并成功获取轻碰坐标
- [发送端分享数据](tests/test_positive.ts)：测试发送端成功分享文件并获取坐标
- [接收端接收数据](tests/test_positive.ts)：测试接收端成功接收文件并获取坐标

### 边界测试用例
- [最大数据记录测试](tests/test_boundary.ts)：测试500条数据记录的边界情况
- [最大缩略图大小测试](tests/test_boundary.ts)：测试32KB缩略图大小边界
- [坐标边界值测试](tests/test_boundary.ts)：测试屏幕坐标的边界值

### 异常测试用例
- [参数错误测试](tests/test_exception.ts)：测试windowId、文件路径等参数错误情况
- [设备不支持测试](tests/test_exception.ts)：测试在不支持设备上调用API
- [网络失败测试](tests/test_exception.ts)：测试网络异常时的降级处理
- [目录不存在测试](tests/test_exception.ts)：测试接收目录不存在的情况