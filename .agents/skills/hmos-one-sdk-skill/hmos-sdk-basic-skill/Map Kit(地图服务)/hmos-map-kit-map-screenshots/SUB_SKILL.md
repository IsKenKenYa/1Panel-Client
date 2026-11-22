---
name: hmos-map-kit-map-screenshots
description: 对当前地图显示区域进行截图，生成包含地图、覆盖物和Logo的PixelMap图像，支持地图状态保存为图片，适用于分享位置、生成导航路线图、记录特定视角地图等场景
---

# 地图截图技能

## 功能描述

地图截图功能对当前屏幕显示的地图区域进行截屏，支持对地图、覆盖物、Logo进行屏幕截图。该功能通过Map Kit的snapshot方法实现，返回PixelMap对象，可用于保存当前地图状态为图片。

**主要功能**：
- 对当前地图显示区域进行截图
- 支持截图包含地图内容、覆盖物、Logo
- 返回PixelMap对象，可用于图片显示或保存
- 支持分享当前位置、生成导航路线图、记录特定视角的地图内容

**适用范围**：
- HarmonyOS应用（Stage模型）
- 元服务（API version 5.0.0(12)及以上）

**限制条件**：
- 仅支持Stage模型
- 需要地图组件已初始化完成
- 截图仅包含当前屏幕显示区域
- 需等待地图加载完成后再截图

## 使用场景

### 触发词
- "地图截图"
- "截取地图"
- "保存地图图片"
- "地图快照"
- "获取地图截图"
- "地图截屏"

### 能做
- 对当前显示的地图区域进行截图
- 获取包含地图内容、覆盖物、Logo的PixelMap图像
- 将截图结果用于图片显示组件
- 将截图保存为图片文件
- 用于分享当前位置、生成导航路线图
- 记录特定视角的地图内容

### 绝不做
- 不截取地图组件外的其他UI元素
- 不支持自定义截图区域范围
- 不支持调整截图分辨率或质量
- 不支持截图动画或视频内容
- 不处理超出当前屏幕显示区域的地图内容

### 补充
- 截图前应确保地图已完全加载
- 建议在地图初始化回调中或地图加载事件后调用
- 返回的PixelMap对象可通过Image组件直接显示
- PixelMap对象可通过Image Kit API保存为文件

## 调用规范和规则

### 输入约束
- 地图组件必须已初始化完成
- 必须在地图初始化回调中或地图加载事件后调用
- 地图控制器（MapComponentController）必须有效

### 执行约束
- 截图方法为异步调用，使用Promise返回结果
- 最大耗时：取决于地图渲染复杂度，通常1-3秒
- 截图仅包含当前屏幕显示区域，不包含未显示区域

### 内容约束
- 禁止在地图未初始化时调用
- 禁止在地图加载过程中立即调用
- 禁止对未显示的地图区域进行截图

### 降级约束
- 地图未初始化：提示用户等待地图加载完成
- 截图失败：检查地图控制器是否有效，重新尝试
- PixelMap对象过大：建议压缩或调整地图显示区域大小

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已导入Map Kit和Image Kit相关模块
2. 确认地图组件已初始化并显示
3. 确认已获取MapComponentController实例
4. 确认地图已加载完成

**参数准备**：
```typescript
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@Entry
@Component
struct MapScreenshotsDemo {
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  @State screenshotImage?: image.PixelMap = undefined;
}
```

### 步骤2：初始化地图组件

**示例代码**：
```typescript
aboutToAppear(): void {
  this.mapOptions = {
    position: {
      target: {
        latitude: 39.9,
        longitude: 116.4
      },
      zoom: 10
    }
  };
  
  this.callback = async (err, mapController) => {
    if (!err) {
      this.mapController = mapController;
      console.info('地图初始化成功');
    } else {
      console.error(`地图初始化失败: ${err.code}, ${err.message}`);
    }
  };
}

build() {
  Stack() {
    MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
      .width('100%')
      .height('50%');
  }
}
```

### 步骤3：调用截图API

**示例代码**：
```typescript
async takeScreenshot(): Promise<void> {
  if (!this.mapController) {
    console.error('地图控制器未初始化');
    return;
  }
  
  try {
    let pixelMap = await this.mapController.snapshot();
    this.screenshotImage = pixelMap;
    console.info('地图截图成功');
  } catch (error) {
    console.error(`地图截图失败: ${error.code}, ${error.message}`);
  }
}
```

### 步骤4：显示或保存截图

**显示截图示例**：
```typescript
build() {
  Stack() {
    Column() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('50%');
      
      Button('获取截图')
        .onClick(async () => {
          await this.takeScreenshot();
        });
      
      if (this.screenshotImage) {
        Image(this.screenshotImage)
          .objectFit(ImageFit.Auto)
          .width('100%')
          .border({ width: 1, color: Color.Red });
      }
    }
  }
}
```

**保存截图示例**：
```typescript
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';

async saveScreenshot(pixelMap: image.PixelMap): Promise<string> {
  const imagePackerApi = image.createImagePacker();
  let packOpts: image.PackingOption = {
    format: 'image/jpeg',
    quality: 90
  };
  
  try {
    const data = await imagePackerApi.packing(pixelMap, packOpts);
    const filePath = `/data/storage/el2/base/files/screenshot_${Date.now()}.jpg`;
    const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    fs.writeSync(file.fd, data);
    fs.closeSync(file.fd);
    console.info(`截图已保存: ${filePath}`);
    return filePath;
  } catch (error) {
    console.error(`保存截图失败: ${error}`);
    throw error;
  } finally {
    imagePackerApi.release();
  }
}
```

### 步骤5：错误处理

```typescript
async takeScreenshotWithErrorHandling(): Promise<void> {
  if (!this.mapController) {
    console.error('地图控制器未初始化');
    return;
  }
  
  try {
    let pixelMap = await this.mapController.snapshot();
    if (pixelMap) {
      this.screenshotImage = pixelMap;
      console.info('地图截图成功');
    } else {
      console.warn('截图返回空结果');
    }
  } catch (error) {
    const err = error as BusinessError;
    switch (err.code) {
      case 1002601001:
        console.error('操作对象不存在');
        break;
      case 501:
        console.error('资源不可用');
        break;
      default:
        console.error(`未知错误: ${err.code}, ${err.message}`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1002601001 | 操作对象不存在 | 检查地图控制器是否有效，确保地图组件已初始化 |
| 501 | 资源不可用 | 检查地图资源加载状态，等待地图加载完成后再截图 |
| 401 | 输入参数无效 | 检查调用参数是否符合要求（当前方法无参数） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": "API version 12+",
    "@kit.ImageKit": "API version 12+",
    "@kit.BasicServicesKit": "API version 12+"
  }
}
```

### 环境要求
- HarmonyOS API version: 5.0.0(12)及以上
- 开发环境: DevEco Studio 3.1及以上
- 运行环境: HarmonyOS设备（支持Stage模型）

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：确保项目配置正确的HarmonyOS SDK版本，检查module.json5中的依赖声明

**问题2：类型定义错误**
```
Error: Property 'snapshot' does not exist on type 'MapComponentController'
```
**解决方法**：确保使用正确的API版本（5.0.0(12)及以上），检查导入的map模块是否正确

**问题3：PixelMap类型错误**
```
Error: Type 'image.PixelMap' is not assignable to type 'Image'
```
**解决方法**：Image组件可直接接收PixelMap对象作为source，无需类型转换

## 常见问题与解决方法

### Q1：截图返回空白或黑色图像
**原因**：地图未完全加载或渲染未完成
**解决方法**：
- 在地图加载事件回调中执行截图
- 等待地图完全显示后再触发截图按钮
- 使用地图事件监听器监听mapLoad事件

### Q2：截图分辨率不理想
**原因**：截图分辨率取决于地图组件的显示大小
**解决方法**：
- 调整MapComponent的宽高属性
- 使用更大的地图显示区域
- 对PixelMap进行缩放处理

### Q3：截图包含不需要的UI元素
**原因**：截图仅包含MapComponent区域内的内容
**解决方法**：
- 截图只包含地图组件本身，不包含其他UI
- 如需纯地图截图，确保地图组件上无其他叠加UI

### Q4：截图保存失败
**原因**：文件路径权限不足或PixelMap数据过大
**解决方法**：
- 使用正确的应用沙箱路径
- 检查PixelMap大小是否超过128MB限制
- 降低图片质量或压缩图片

### Q5：元服务中截图功能不可用
**原因**：API版本不满足要求
**解决方法**：
- 确保元服务API版本为5.0.0(12)及以上
- 检查module.json5中的minAPIVersion配置

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "screenshotResult": "image.PixelMap对象",
  "screenshotTime": "截图执行时间戳",
  "apiUsed": [
    "map.MapComponentController.snapshot()"
  ],
  "nextSteps": [
    "可通过Image组件显示PixelMap",
    "可通过Image Kit保存为图片文件",
    "可通过分享功能分享截图"
  ]
}
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-screenshots)
- [API参考说明 - MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)
- [API参考说明 - PixelMap](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)

## 完整示例代码

- [ArkTS完整示例](assets/map-screenshots-demo.ets)

## 测试用例

### 正向测试用例
- [地图截图基本功能测试](tests/test_positive.py)：验证地图截图返回有效的PixelMap对象
- [截图显示测试](tests/test_positive.py)：验证截图可通过Image组件正确显示
- [截图保存测试](tests/test_positive.py)：验证截图可成功保存为图片文件

### 边界测试用例
- [大尺寸地图截图测试](tests/test_boundary.py)：验证大分辨率地图截图功能
- [多覆盖物地图截图测试](tests/test_boundary.py)：验证包含多个覆盖物的地图截图
- [不同缩放级别截图测试](tests/test_boundary.py)：验证不同缩放级别的截图效果

### 异常测试用例
- [未初始化地图截图测试](tests/test_exception.py)：验证地图未初始化时的错误处理
- [地图加载中截图测试](tests/test_exception.py)：验证地图加载过程中截图的错误处理
- [地图控制器无效测试](tests/test_exception.py)：验证地图控制器无效时的错误处理