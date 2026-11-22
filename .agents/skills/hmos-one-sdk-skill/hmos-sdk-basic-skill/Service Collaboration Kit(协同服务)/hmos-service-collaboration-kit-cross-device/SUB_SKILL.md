---
name: hmos-service-collaboration-kit-cross-device
description: 实现跨设备相机、扫描、图库互通能力，支持PC/2in1/Tablet调用Phone/Tablet设备，最大支持50张图片选择，适用于远程拍照、文档扫描、跨设备图库访问场景
---

# 跨设备互通开发指导

## 功能描述

跨设备互通提供相机、扫描以及图库（图片和视频）的跨设备调用能力。Tablet或PC/2in1设备可以调用Phone的相机、扫描、图库等功能。从API 6.1.0(23)开始，TV、Phone、Tablet或PC/2in1设备可调用具备拍照、扫描及图库能力的Phone、Tablet和PC/2in1设备。

**核心能力**：
- 跨设备拍照：远程调用其他设备的相机
- 文档扫描：跨设备扫描文档
- 图库选择：跨设备选择图片和视频
- 视频选择：跨设备选择视频

**技术特点**：
- 基于HarmonyOS分布式能力
- 自动设备发现和列表展示
- 统一的状态回调机制
- 支持批量图片选择（最多50张）

## 使用场景

### 触发词
- "跨设备拍照"
- "远程拍照"
- "跨设备扫描"
- "跨设备图库"
- "远程选择图片"
- "跨设备选择视频"
- "Service Collaboration Kit"
- "设备互通"

### 能做
- 实现PC/2in1调用Phone/Tablet的相机进行拍照
- 实现Tablet调用Phone的相机进行拍照
- 实现跨设备文档扫描
- 实现跨设备图库图片选择（单张或多张，最多50张）
- 实现跨设备视频选择
- 实现跨设备图片和视频同时选择
- 处理跨设备数据回传和状态监控
- 实现设备列表的自动发现和展示

### 绝不做
- 不支持非HarmonyOS设备之间的互通
- 不支持未登录同一华为账号的设备互通
- 不支持设备类型限制之外的调用关系
- 不处理超出50张图片的选择需求
- 不支持在不满足设备类型要求的设备上使用
- 不处理图片编辑、裁剪等后续处理功能

### 补充
- 本端设备要求：HarmonyOS 5及以上版本的TV、Phone、Tablet或PC/2in1
- 远端设备要求：HarmonyOS 5及以上版本，支持拍照/扫描/图库能力的Phone、Tablet或PC/2in1
- 必须登录同一华为账号
- 需要开启WLAN和蓝牙
- 推荐接入同一局域网以提升唤醒速度
- API版本要求：5.0.0(12)起支持，6.0.0(20)新增视频选择能力
- 系统能力要求：SystemCapability.Collaboration.Service

## 调用规范和规则

### 输入约束
- 设备类型限制：本端必须是TV、Phone、Tablet或PC/2in1，远端必须是Phone、Tablet或PC/2in1
- 设备系统版本：HarmonyOS 5.0.0(12)及以上
- 图片选择数量：1-50张（仅在IMAGE_PICKER模式下有效）
- 账号要求：双端必须登录同一华为账号
- 网络要求：WLAN和蓝牙必须开启
- 能力类型：仅支持ALL、TAKE_PHOTO、SCAN_DOCUMENT、IMAGE_PICKER、VIDEO_PICKER、IMAGE_VIDEO_PICKER

### 执行约束
- 设备发现时间：最长等待30秒
- 数据传输超时：最长等待60秒
- 单次操作最大图片数：50张
- 单个图片文件大小限制：系统默认限制
- API调用必须在UI线程执行
- Menu组件必须正确绑定触发元素

### 内容约束
- 禁止在非PC/2in1/Tablet设备上展示设备列表
- 禁止使用canReceiveNumber ≤ 0的参数值
- 禁止在Menu组件外部调用createCollaborationServiceMenuItems
- 禁止忽略stateCode错误码
- 禁止直接操作buffer数据而不进行类型校验
- 必须处理所有错误状态码

### 降级约束
- 设备发现失败：提示用户检查设备连接和账号登录状态
- 数据传输失败：提示重试并检查网络连接
- 权限不足：引导用户到系统设置开启权限
- 设备不支持：提示当前设备不支持该功能
- 网络异常：建议检查WLAN和蓝牙开关状态

## 调用流程和步骤

### 步骤1：环境准备与权限检查

**前置校验**：
1. 确认设备类型符合要求（TV、Phone、Tablet或PC/2in1）
2. 确认HarmonyOS版本≥5.0.0(12)
3. 确认已登录华为账号
4. 确认WLAN和蓝牙已开启
5. 确认系统能力支持：SystemCapability.Collaboration.Service

**依赖声明**：
```typescript
// oh-package.json5
{
  "dependencies": {
    "@kit.ServiceCollaborationKit": "^5.0.0",
    "@kit.ImageKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0"
  }
}
```

**导入模块**：
```typescript
import { 
  createCollaborationServiceMenuItems, 
  CollaborationServiceStateDialog, 
  CollaborationServiceFilter 
} from '@kit.ServiceCollaborationKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：创建设备列表选择器

**定义能力类型枚举**：
```typescript
// 根据业务需求选择合适的能力类型
// ALL: 匹配跨端拍照、文档扫描和图库选择器
// TAKE_PHOTO: 匹配跨端拍照
// SCAN_DOCUMENT: 匹配文档扫描
// IMAGE_PICKER: 匹配图库选择器
// VIDEO_PICKER: 匹配视频选择器（API 6.0.0(20)起支持）
// IMAGE_VIDEO_PICKER: 匹配图片和视频选择器（API 6.0.0(20)起支持）

@Builder
myDeviceMenu() {
  Menu() {
    // 方式1：使用默认参数（全部能力）
    createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL]);
    
    // 方式2：指定特定能力（如跨设备拍照）
    // createCollaborationServiceMenuItems([CollaborationServiceFilter.TAKE_PHOTO]);
    
    // 方式3：指定能力和图片数量（图库选择）
    // createCollaborationServiceMenuItems([CollaborationServiceFilter.IMAGE_PICKER], 10);
  }
}
```

**重要说明**：
- `createCollaborationServiceMenuItems` 必须在 `Menu` 组件内调用
- 该方法是 `@Builder` 装饰的自定义构建函数
- 可以组合多个能力类型，如 `[CollaborationServiceFilter.TAKE_PHOTO, CollaborationServiceFilter.SCAN_DOCUMENT]`

### 步骤3：创建状态提示框组件

**定义状态回调处理**：
```typescript
@Entry
@Component
struct CrossDeviceExample {
  @State picture: PixelMap | undefined = undefined;
  @State receivedFiles: string[] = [];

  build() {
    Column({ space: 20 }) {
      // 必须在页面中定义CollaborationServiceStateDialog组件
      CollaborationServiceStateDialog({
        onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => {
          this.handleCrossDeviceResult(stateCode, bufferType, buffer);
        }
      })
      
      // 绑定设备选择菜单的按钮
      Button('使用远端设备进行拍照')
        .type(ButtonType.Normal)
        .borderRadius(10)
        .bindMenu(this.myDeviceMenu)
      
      // 显示返回的图片
      if (this.picture) {
        Image(this.picture)
          .borderStyle(BorderStyle.Dotted)
          .borderWidth(1)
          .objectFit(ImageFit.Contain)
          .height('80%')
      }
    }
    .padding(20)
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
```

### 步骤4：处理回调数据

**完整的状态处理逻辑**：
```typescript
handleCrossDeviceResult(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
  // 根据状态码处理不同情况
  switch (stateCode) {
    case 0:
      // 成功：处理返回的数据
      this.processSuccessData(bufferType, buffer);
      hilog.info(0, 'CrossDevice', '跨设备操作成功');
      break;
      
    case 1001202001:
      // 对端取消
      hilog.warn(0, 'CrossDevice', '对端用户取消了操作');
      this.showUserMessage('对端用户取消了操作');
      break;
      
    case 1001202002:
      // 协同框架内部错误
      hilog.error(0, 'CrossDevice', '协同框架内部错误');
      this.showUserMessage('操作失败，请重试');
      break;
      
    case 1001202003:
      // 本端取消
      hilog.info(0, 'CrossDevice', '本端用户取消了操作');
      break;
      
    case 1001202004:
      // 跨设备互通能力开始
      hilog.info(0, 'CrossDevice', '跨设备操作已开始');
      this.showUserMessage('正在处理...');
      break;
      
    case 1001202005:
      // 图片全部回传结束
      hilog.info(0, 'CrossDevice', '所有图片已接收完成');
      this.showUserMessage('接收完成');
      break;
      
    case 1001202006:
      // 回传文件名称
      hilog.info(0, 'CrossDevice', '接收到文件名称');
      break;
      
    case 1001202007:
      // canReceiveNumber参数错误
      hilog.error(0, 'CrossDevice', '图片数量参数错误：必须大于0');
      this.showUserMessage('参数配置错误');
      break;
      
    default:
      hilog.error(0, 'CrossDevice', `未知状态码: ${stateCode}`);
      this.showUserMessage('操作异常');
  }
}

processSuccessData(bufferType: string, buffer: ArrayBuffer): void {
  if (!buffer || buffer.byteLength === 0) {
    hilog.warn(0, 'CrossDevice', '接收到的数据为空');
    return;
  }
  
  try {
    if (bufferType === 'general.image') {
      // 处理图片数据
      this.processImageData(buffer);
    } else if (bufferType === 'general.video') {
      // 处理视频数据
      this.processVideoData(buffer);
    } else if (bufferType === 'general.fileName') {
      // 处理文件名数据
      this.processFileNameData(buffer);
    } else {
      hilog.warn(0, 'CrossDevice', `未知的数据类型: ${bufferType}`);
    }
  } catch (error) {
    hilog.error(0, 'CrossDevice', `数据处理失败: ${error}`);
  }
}

processImageData(buffer: ArrayBuffer): void {
  try {
    let imageSource = image.createImageSource(buffer);
    imageSource.createPixelMap().then((pixelMap: PixelMap) => {
      this.picture = pixelMap;
      hilog.info(0, 'CrossDevice', '图片处理成功');
    }).catch((error: Error) => {
      hilog.error(0, 'CrossDevice', `创建PixelMap失败: ${error.message}`);
    }).finally(() => {
      imageSource.release();
    });
  } catch (error) {
    hilog.error(0, 'CrossDevice', `图片处理异常: ${error}`);
  }
}

processVideoData(buffer: ArrayBuffer): void {
  // 视频数据处理逻辑
  hilog.info(0, 'CrossDevice', `接收到视频数据，大小: ${buffer.byteLength} bytes`);
  // 实际项目中需要保存视频文件或进行其他处理
}

processFileNameData(buffer: ArrayBuffer): void {
  // 文件名数据处理逻辑
  try {
    let decoder = new TextDecoder('utf-8');
    let fileName = decoder.decode(buffer);
    this.receivedFiles.push(fileName);
    hilog.info(0, 'CrossDevice', `接收到文件名: ${fileName}`);
  } catch (error) {
    hilog.error(0, 'CrossDevice', `文件名解码失败: ${error}`);
  }
}

showUserMessage(message: string): void {
  // 显示用户提示信息（可以使用Toast或AlertDialog）
  hilog.info(0, 'CrossDevice', message);
}
```

### 步骤5：完整示例实现

**完整可运行示例**：
```typescript
import { 
  createCollaborationServiceMenuItems, 
  CollaborationServiceStateDialog, 
  CollaborationServiceFilter 
} from '@kit.ServiceCollaborationKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct CrossDeviceCollaboration {
  @State picture: PixelMap | undefined = undefined;
  @State receivedFiles: string[] = [];
  @State operationStatus: string = '';

  @Builder
  deviceMenuBuilder() {
    Menu() {
      // 使用全部能力，设置最大接收30张图片
      createCollaborationServiceMenuItems(
        [CollaborationServiceFilter.ALL], 
        30
      );
    }
  }

  build() {
    Column({ space: 20 }) {
      // 状态提示框组件
      CollaborationServiceStateDialog({
        onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => {
          this.handleStateCallback(stateCode, bufferType, buffer);
        }
      });

      // 触发跨设备操作的按钮
      Button('跨设备拍照/扫描/选择图片')
        .type(ButtonType.Normal)
        .borderRadius(10)
        .width('80%')
        .height(50)
        .bindMenu(this.deviceMenuBuilder);

      // 显示操作状态
      if (this.operationStatus) {
        Text(this.operationStatus)
          .fontSize(14)
          .fontColor('#666666');
      }

      // 显示接收的图片
      if (this.picture) {
        Image(this.picture)
          .width('90%')
          .height('60%')
          .objectFit(ImageFit.Contain)
          .borderStyle(BorderStyle.Dotted)
          .borderWidth(2)
          .borderColor('#999999');
      }

      // 显示接收的文件列表
      if (this.receivedFiles.length > 0) {
        List({ space: 10 }) {
          ForEach(this.receivedFiles, (fileName: string) => {
            ListItem() {
              Text(fileName)
                .fontSize(12)
                .fontColor('#333333');
            }
          });
        }
        .width('90%')
        .height('20%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center);
  }

  handleStateCallback(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    switch (stateCode) {
      case 0:
        // 成功
        this.operationStatus = '操作成功';
        this.processData(bufferType, buffer);
        break;
        
      case 1001202001:
        this.operationStatus = '对端取消操作';
        break;
        
      case 1001202002:
        this.operationStatus = '协同框架错误';
        break;
        
      case 1001202003:
        this.operationStatus = '本端取消操作';
        break;
        
      case 1001202004:
        this.operationStatus = '跨设备操作开始...';
        break;
        
      case 1001202005:
        this.operationStatus = '所有图片接收完成';
        break;
        
      case 1001202006:
        this.processFileName(buffer);
        break;
        
      case 1001202007:
        this.operationStatus = '参数错误：图片数量必须大于0';
        break;
        
      default:
        this.operationStatus = `未知状态: ${stateCode}`;
    }
    
    hilog.info(0, 'CrossDevice', `状态: ${this.operationStatus}`);
  }

  processData(bufferType: string, buffer: ArrayBuffer): void {
    if (!buffer || buffer.byteLength === 0) {
      return;
    }

    try {
      if (bufferType === 'general.image') {
        let imageSource = image.createImageSource(buffer);
        imageSource.createPixelMap().then((pixelMap: PixelMap) => {
          this.picture = pixelMap;
          hilog.info(0, 'CrossDevice', '图片显示成功');
        }).catch((error: Error) => {
          hilog.error(0, 'CrossDevice', `图片处理失败: ${error.message}`);
        }).finally(() => {
          imageSource.release();
        });
      } else if (bufferType === 'general.video') {
        hilog.info(0, 'CrossDevice', `接收到视频: ${buffer.byteLength} bytes`);
      }
    } catch (error) {
      hilog.error(0, 'CrossDevice', `数据处理异常: ${error}`);
    }
  }

  processFileName(buffer: ArrayBuffer): void {
    try {
      let decoder = new TextDecoder('utf-8');
      let fileName = decoder.decode(buffer);
      this.receivedFiles.push(fileName);
      hilog.info(0, 'CrossDevice', `文件名: ${fileName}`);
    } catch (error) {
      hilog.error(0, 'CrossDevice', `文件名解码失败: ${error}`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 数据正常返回，处理buffer数据 |
| 1001202001 | 对端取消 | 对端用户主动取消了操作，提示用户 |
| 1001202002 | 协同框架内部错误 | 框架内部错误，建议用户重试或检查系统状态 |
| 1001202003 | 本端取消 | 本端用户主动取消了操作 |
| 1001202004 | 跨设备互通能力开始 | 提示用户操作已开始，请等待 |
| 1001202005 | 图片全部回传结束 | 所有图片已接收完成，可以结束loading状态 |
| 1001202006 | 回传文件名称 | 接收到文件名数据，解析buffer获取文件名 |
| 1001202007 | canReceiveNumber参数错误 | 图片数量参数≤0，修改为1-50之间的值 |

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**：
```json
{
  "name": "crossdeviceexample",
  "version": "1.0.0",
  "description": "跨设备互通示例",
  "main": "",
  "author": "",
  "license": "",
  "dependencies": {
    "@kit.ServiceCollaborationKit": "^5.0.0",
    "@kit.ImageKit": "^5.0.0",
    "@kit.PerformanceAnalysisKit": "^5.0.0"
  }
}
```

### 环境要求
- **HarmonyOS SDK版本**：5.0.0(12)及以上
- **DevEco Studio版本**：4.0及以上
- **系统能力**：SystemCapability.Collaboration.Service
- **设备要求**：TV、Phone、Tablet或PC/2in1

### 常见编译问题

**问题1：找不到模块 '@kit.ServiceCollaborationKit'**
```
Error: Cannot find module '@kit.ServiceCollaborationKit'
```
**解决方法**：
- 确认HarmonyOS SDK版本≥5.0.0(12)
- 在DevEco Studio中更新SDK
- 检查oh-package.json5中的依赖声明

**问题2：Menu组件未正确绑定**
```
Error: createCollaborationServiceMenuItems must be called inside Menu component
```
**解决方法**：
- 确保createCollaborationServiceMenuItems在Menu() {}内部调用
- 使用@Builder装饰器定义菜单构建函数
- 使用.bindMenu()方法绑定到UI组件

**问题3：状态回调未触发**
```
Warning: CollaborationServiceStateDialog onState callback not triggered
```
**解决方法**：
- 确认CollaborationServiceStateDialog组件已添加到页面build方法中
- 确认onState回调函数已正确实现
- 检查设备连接和账号登录状态

**问题4：图片显示失败**
```
Error: Failed to create PixelMap from buffer
```
**解决方法**：
- 检查buffer数据是否为空
- 确认bufferType为'general.image'
- 使用try-catch捕获异常
- 调用imageSource.release()释放资源

## 常见问题与解决方法

### Q1：设备列表为空，无法发现远端设备
**原因**：
- 双端未登录同一华为账号
- WLAN或蓝牙未开启
- 设备不在同一局域网
- 远端设备系统版本不支持

**解决方法**：
- 检查双端是否登录同一华为账号
- 确认WLAN和蓝牙开关已打开
- 将设备接入同一局域网以提升发现速度
- 确认远端设备为HarmonyOS 5及以上版本的Phone、Tablet或PC/2in1

### Q2：选择设备后无响应
**原因**：
- 远端设备不支持所选能力
- 网络连接不稳定
- 权限未授予

**解决方法**：
- 确认远端设备支持拍照/扫描/图库能力
- 检查网络连接状态，建议使用同一局域网
- 检查应用是否获得了必要的权限

### Q3：图片接收失败或显示异常
**原因**：
- buffer数据格式不正确
- 图片文件损坏
- 内存不足

**解决方法**：
- 检查bufferType是否为'general.image'
- 使用try-catch捕获异常并提示用户重试
- 限制图片选择数量，避免一次性接收过多图片

### Q4：视频选择器不可用
**原因**：
- API版本低于6.0.0(20)
- 使用了错误的能力类型枚举

**解决方法**：
- 确认HarmonyOS版本≥6.0.0(20)
- 使用CollaborationServiceFilter.VIDEO_PICKER或IMAGE_VIDEO_PICKER
- 检查设备是否支持视频选择能力

### Q5：多张图片选择时部分图片丢失
**原因**：
- canReceiveNumber参数设置过大
- 网络传输中断
- 内存溢出

**解决方法**：
- 控制canReceiveNumber在合理范围（建议≤30）
- 监听stateCode状态，处理错误和中断情况
- 实现分批次接收和处理的逻辑

### Q6：跨设备调用在TV设备上失败
**原因**：
- API版本低于6.1.0(23)
- TV作为本端设备不支持某些调用能力

**解决方法**：
- 确认TV设备系统版本≥6.1.0(23)
- 检查TV设备支持的远端设备类型
- 确认TV调用的是支持相应能力的远端设备

## 输出结果报告

执行跨设备互通操作后，输出以下信息：

```json
{
  "status": "success",
  "operationType": "TAKE_PHOTO | SCAN_DOCUMENT | IMAGE_PICKER | VIDEO_PICKER | IMAGE_VIDEO_PICKER",
  "remoteDevice": "设备名称或标识",
  "receivedData": {
    "imageCount": "接收的图片数量",
    "videoCount": "接收的视频数量",
    "fileNames": ["文件名列表"]
  },
  "stateCode": 0,
  "message": "操作成功",
  "timestamp": "2026-07-03T22:15:00Z"
}
```

**状态说明**：
- status：操作总体状态（success/failed/cancelled）
- operationType：本次操作的类型
- remoteDevice：远端设备信息
- receivedData：接收的数据统计
- stateCode：最终状态码
- message：状态描述信息
- timestamp：操作完成时间戳

## 参考文档

- [跨设备互通开发指导](references/servicecollaboration-dev-guides.md) - 原始开发指南文档
- [CollaborationService API参考](references/servicecollaboration-collaborationservice.md) - API接口详细说明
- [Menu组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-menu) - Menu组件使用说明
- [@Builder装饰器](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-builder) - 自定义构建函数说明

## 完整示例代码

- [ArkTS完整示例](assets/cross-device-example.ets) - 可直接运行的完整示例项目
- [配置文件示例](assets/oh-package.json5) - 依赖配置文件

## 测试用例

### 正向测试用例
- [跨设备拍照测试](tests/test_positive.ets) - 测试正常跨设备拍照流程
- [跨设备扫描测试](tests/test_positive.ets) - 测试文档扫描功能
- [跨设备图库选择测试](tests/test_positive.ets) - 测试图片选择功能（单张/多张）
- [跨设备视频选择测试](tests/test_positive.ets) - 测试视频选择功能

### 边界测试用例
- [最大图片数量测试](tests/test_boundary.ets) - 测试选择50张图片的边界情况
- [设备发现超时测试](tests/test_boundary.ets) - 测试设备发现的最长等待时间
- [数据传输超时测试](tests/test_boundary.ets) - 测试大数据量传输的超时处理

### 异常测试用例
- [未登录账号测试](tests/test_exception.ets) - 测试未登录华为账号的错误处理
- [网络断开测试](tests/test_exception.ets) - 测试网络中断的异常处理
- [权限不足测试](tests/test_exception.ets) - 测试权限未授予的情况
- [设备不支持测试](tests/test_exception.ets) - 测试在不支持设备上的错误提示
- [参数错误测试](tests/test_exception.ets) - 测试canReceiveNumber≤0的错误处理