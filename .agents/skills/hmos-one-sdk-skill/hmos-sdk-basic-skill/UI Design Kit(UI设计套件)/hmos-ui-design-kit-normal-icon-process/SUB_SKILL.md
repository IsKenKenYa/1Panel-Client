---
name: hmos-ui-design-kit-normal-icon-process
description: 处理单层图标资源使其符合HarmonyOS Design System设计风格，支持单个和批量处理，适用于图标风格统一场景
---

# 单层图标处理技能

## 功能描述

本技能提供单层图标处理能力，通过调用HarmonyOS UIDesignKit的hdsDrawable API，将单层图标资源处理为符合HarmonyOS Design System设计风格的图标。支持单个图标处理和批量处理两种模式，适用于需要对现有单层图标进行统一风格处理的场景。

**核心能力**：
- 单层图标剪切处理
- 图标缩放处理
- 图标描边处理
- 批量异步处理能力

**适用场景**：
- 应用图标风格统一化
- 单层图标资源适配HarmonyOS设计规范
- 批量图标处理优化性能

## 使用场景

### 触发词
- "处理单层图标"
- "图标风格统一"
- "单层图标适配"
- "图标描边"
- "批量处理图标"

### 能做
- 处理单个单层图标使其符合HarmonyOS设计风格
- 批量异步处理多个单层图标
- 为图标添加蒙版剪切效果
- 为图标添加描边效果
- 自定义输出图标尺寸

### 绝不做
- 不处理分层图标（分层图标应使用分层图标处理技能）
- 不处理不存在的图标资源
- 不处理超过并发限制的批量任务（最大并发10个）

### 补充
- 从API版本5.0.0(12)开始支持
- 支持Phone、Tablet、PC/2in1设备
- 从API版本5.1.1(19)开始支持TV设备
- 在线主题场景不支持设置描边

## 调用规范和规则

### 输入约束
- 图标资源：必须存在于应用的resources/base/media目录下
- bundleName：必须为应用的Bundle名称，字符串类型
- size：输出图标尺寸，必须大于0，单位vp
- hasBorder：是否描边，布尔类型，在线主题场景不支持
- parallelNumber：批量处理并发数量，默认4，最大10

### 执行约束
- 单个图标处理：同步调用，最大耗时1秒
- 批量图标处理：异步调用，最大耗时根据图标数量和并发数确定
- 并发限制：批量处理最大并发数10个

### 内容约束
- 禁止生成：不生成违反HarmonyOS设计规范的图标
- 禁止操作：不修改原始图标资源文件
- 禁止使用：不使用无效的mask资源

### 降级约束
- 资源不存在：提示用户检查资源路径并返回null
- 参数错误：捕获异常并返回错误信息
- 任务繁忙：返回错误码1012600001，提示用户稍后重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认API版本≥5.0.0(12)
2. 确认设备类型支持（Phone/Tablet/PC/2in1/TV）
3. 确认图标资源已正确放置在resources/base/media目录
4. 确认已导入必要的模块

**参数准备**：
```typescript
import { LayeredDrawableDescriptor, DrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
```

### 步骤2：获取资源管理器

**示例代码**：
```typescript
// 在组件内获取context和资源管理器
aboutToAppear(): void {
  this.resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
  if (!this.resManager) {
    console.error('Failed to get resource manager');
    return;
  }
}
```

### 步骤3：获取图标资源

**获取单层图标**：
```typescript
// 通过资源管理获取单层图标信息
let drawableDescriptor: DrawableDescriptor = 
  (this.resManager?.getDrawableDescriptor($r('app.media.normal_icon').id)) as DrawableDescriptor;
```

**获取蒙版资源**：
```typescript
// 获取分层图标的蒙版用于剪切处理
let layeredDrawableDescriptor: LayeredDrawableDescriptor = 
  (this.resManager.getDrawableDescriptor($r('app.media.drawable').id)) as LayeredDrawableDescriptor;
let mask: image.PixelMap = layeredDrawableDescriptor.getMask().getPixelMap();
```

### 步骤4：调用单个图标处理接口

**同步处理**：
```typescript
private getHdsIcon(): image.PixelMap | null {
  try {
    // 调用HDS单层图标接口
    return hdsDrawable.getHdsIcon(
      this.bundleName,           // 应用Bundle名称
      this.drawableDescriptor?.getPixelMap(),  // 单层图标PixelMap
      48,                        // 输出尺寸48vp
      mask,                      // 蒙版PixelMap
      true                       // 添加描边
    );
  } catch (err) {
    let message = (err as BusinessError).message;
    let code = (err as BusinessError).code;
    console.error(`getHdsIcon failed, code: ${code}, message: ${message}`);
    return null;
  }
}
```

**异步处理**：
```typescript
private async getHdsIconAsync(): Promise<image.PixelMap | null> {
  try {
    let processedIcon: image.PixelMap = await hdsDrawable.getHdsIconAsync(
      this.bundleName,
      this.drawableDescriptor?.getPixelMap(),
      48,
      mask,
      true
    );
    return processedIcon;
  } catch (err) {
    let message = (err as BusinessError).message;
    let code = (err as BusinessError).code;
    console.error(`getHdsIconAsync failed, code: ${code}, message: ${message}`);
    return null;
  }
}
```

### 步骤5：调用批量图标处理接口

**示例代码**：
```typescript
getHdsIcons(): void {
  if (!this.drawableDescriptor) {
    console.error('drawableDescriptor is undefined');
    return;
  }
  if (!this.layeredDrawableDescriptor) {
    console.error('layeredDrawableDescriptor is undefined');
    return;
  }
  
  // 构造批量接口传参
  let options: hdsDrawable.Options = {
    size: 48,
    hasBorder: true,
    parallelNumber: 4
  };
  
  let icons: Array<hdsDrawable.Icon> = [];
  for (let i = 0; i < 10; i++) {
    icons.push({
      bundleName: `${this.bundleName}-${i}`,
      pixelMap: this.drawableDescriptor.getPixelMap()
    });
  }
  
  try {
    // 调用HDS单层批量接口处理图标
    hdsDrawable.getHdsIcons(icons, this.layeredDrawableDescriptor.getMask().getPixelMap(), options)
      .then((data: Array<hdsDrawable.ProcessedIcon>) => {
        console.info(`getHdsIcons success, processed ${data.length} icons`);
        this.iconsResult = data;
      })
      .catch((err: BusinessError) => {
        console.error(`getHdsIcons error, code: ${err.code}, msg: ${err.message}`);
      });
  } catch (err) {
    let message = (err as BusinessError).message;
    let code = (err as BusinessError).code;
    console.error(`getHdsIcons failed: ${message}, code: ${code}`);
  }
}
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
try {
  let processedIcon = hdsDrawable.getHdsIcon(bundleName, pixelMap, size, mask, hasBorder);
} catch (err) {
  let error = err as BusinessError;
  switch (error.code) {
    case 401:
      console.error('Parameter error:', error.message);
      break;
    case 1012600001:
      console.error('Task is busy, please retry later');
      break;
    default:
      console.error('Unknown error:', error.code, error.message);
  }
}
```

### 步骤7：降级处理

**降级方案**：
```typescript
async function processIconWithFallback(
  bundleName: string,
  pixelMap: image.PixelMap,
  size: number,
  mask: image.PixelMap,
  hasBorder: boolean
): Promise<image.PixelMap | null> {
  try {
    // 尝试使用HDS处理
    return hdsDrawable.getHdsIcon(bundleName, pixelMap, size, mask, hasBorder);
  } catch (err) {
    console.warn('HDS processing failed, using fallback');
    // 降级方案：返回原始图标或使用其他处理方式
    return pixelMap;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：bundleName、pixelMap、size、mask或hasBorder参数值不正确，或必填参数未指定 | 检查参数类型和取值范围，确保必填参数已正确传递 |
| 1012600001 | 任务繁忙 | 稍后重试或减少并发数量 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.UIDesignKit": ">=5.0.0",
    "@kit.ArkUI": ">=5.0.0",
    "@kit.ImageKit": ">=5.0.0",
    "@kit.LocalizationKit": ">=5.0.0",
    "@kit.AbilityKit": ">=5.0.0",
    "@kit.BasicServicesKit": ">=5.0.0"
  }
}
```

### 环境要求
- HarmonyOS API版本：≥5.0.0(12)
- 设备支持：Phone、Tablet、PC/2in1、TV(≥5.1.1(19))
- DevEco Studio：推荐使用最新版本

### 常见编译问题

**问题1：找不到模块'@kit.UIDesignKit'**
```
Error: Cannot find module '@kit.UIDesignKit'
```
**解决方法**：确保HarmonyOS SDK版本≥5.0.0，并在build-profile.json5中配置正确的API版本

**问题2：LayeredDrawableDescriptor类型错误**
```
Error: Type 'DrawableDescriptor' is not assignable to type 'LayeredDrawableDescriptor'
```
**解决方法**：确认资源文件是分层图标资源，包含foreground和background图层

**问题3：getMask()方法不存在**
```
Error: Property 'getMask' does not exist on type 'DrawableDescriptor'
```
**解决方法**：getMask()方法只在LayeredDrawableDescriptor上存在，确保使用正确的资源类型

## 常见问题与解决方法

### Q1：如何确认图标资源是单层还是分层？
**原因**：不同类型的图标需要使用不同的处理接口
**解决方法**：
- 单层图标：使用DrawableDescriptor获取
- 分层图标：使用LayeredDrawableDescriptor获取，包含foreground和background
- 判断方法：打开Symbol json文件查看layered-image属性

### Q2：批量处理时任务繁忙错误
**原因**：并发任务过多或系统资源不足
**解决方法**：
- 降低parallelNumber参数（推荐4，最大10）
- 分批处理图标，避免一次处理过多
- 稍后重试

### Q3：图标处理后显示效果不符合预期
**原因**：参数配置不当或资源问题
**解决方法**：
- 检查size参数是否合理
- 检查mask资源是否正确
- 确认hasBorder参数设置是否符合设计要求
- 检查原始图标资源质量

### Q4：在线主题场景描边无效
**原因**：在线主题场景不支持描边功能
**解决方法**：
- 在在线主题场景下设置hasBorder为false
- 或使用其他方式实现描边效果

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedIcons": [
    {
      "bundleName": "com.example.app",
      "pixelMap": "[PixelMap对象]"
    }
  ],
  "apiUsed": [
    "hdsDrawable.getHdsIcon",
    "hdsDrawable.getHdsIcons"
  ]
}
```

## 参考文档

- [单层图标处理开发指南](references/ui-design-normal-process.md)
- [hdsDrawable API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsdrawable)

## 完整示例代码

- [ArkTS示例 - 单个图标处理](assets/normal_icon_single.ets)
- [ArkTS示例 - 批量图标处理](assets/normal_icon_batch.ets)
- [配置文件示例](assets/config.json)

## 测试用例

### 正向测试用例
- [单个图标处理测试](tests/test_single_icon.ts)：测试单个图标处理成功场景
- [批量图标处理测试](tests/test_batch_icons.ts)：测试批量图标处理成功场景

### 边界测试用例
- [最大并发数测试](tests/test_max_parallel.ts)：测试并发数为10的场景
- [最小尺寸测试](tests/test_min_size.ts)：测试size参数临界值

### 异常测试用例
- [参数错误测试](tests/test_invalid_params.ts)：测试参数类型错误和缺失场景
- [资源不存在测试](tests/test_resource_not_found.ts)：测试图标资源不存在场景
- [任务繁忙测试](tests/test_task_busy.ts)：测试系统繁忙错误处理