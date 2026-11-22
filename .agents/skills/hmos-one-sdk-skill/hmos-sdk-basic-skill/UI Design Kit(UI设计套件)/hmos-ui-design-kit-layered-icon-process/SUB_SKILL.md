---
name: hmos-ui-design-kit-layered-icon-process
description: 处理分层图标并生成符合HarmonyOS设计风格的图标，支持单个图标处理和批量处理，适用于应用列表、应用详情、主题换肤等场景，API版本5.0.0(12)及以上
---

# （推荐）分层图标处理技能

## 功能描述

本技能提供HarmonyOS分层图标处理能力，通过UI Design Kit的hdsDrawable模块对分层图标资源进行处理，生成符合HarmonyOS Design System设计风格的图标。支持单个图标处理和批量处理两种模式，可控制图标尺寸、是否添加描边等参数。

**核心能力**：
- 前景与背景图层合成
- 图标剪切与缩放处理
- 描边效果添加
- 批量并发处理
- 主题换肤支持

**适用场景**：
- 展示带图标的应用列表（批量处理）
- 展示应用详情（单个图标处理）
- 展示跟随在线主题的应用图标（主题换肤）

## 使用场景

### 触发词
- "分层图标处理"
- "处理分层图标"
- "应用图标处理"
- "批量处理图标"
- "HDS图标处理"
- "分层图标"
- "图标描边"

### 能做
- 处理单个分层图标，返回PixelMap格式图标
- 批量处理多个分层图标，支持并发控制
- 为图标添加描边效果
- 控制输出图标尺寸
- 支持在线主题换肤场景
- 生成符合HarmonyOS设计风格的图标

### 绝不做
- 不处理非分层图标资源（单层图标需使用其他接口）
- 不支持超过10个并发批量处理
- 不处理负数或零尺寸参数
- 不处理空或无效的LayeredDrawableDescriptor对象
- 不支持在线主题场景设置描边（hasBorder会被忽略）

### 补充
- 分层图标必须包含foreground和background两层资源
- 需要通过JSON文件定义layered-image结构
- 支持Phone、Tablet、PC/2in1、TV设备（TV从5.1.1(19)版本开始）
- 批量处理默认并发数为4，最大为10
- 在线主题场景不支持描边设置

## 调用规范和规则

### 输入约束
- **bundleName**：必须为有效的应用Bundle名称字符串，不能为空
- **layeredDrawableDescriptor**：必须为有效的LayeredDrawableDescriptor对象，不能为undefined或null
- **size**：必须大于0，单位vp，推荐使用常用尺寸（如48、64、96等）
- **hasBorder**：可选参数，默认false，在线主题场景不支持设置为true
- **parallelNumber**：批量处理并发数，可选参数，默认4，最大10
- **icons数组长度**：批量处理时，建议不超过100个图标

### 执行约束
- **最大耗时**：单个图标处理不超过500ms，批量处理根据数量动态调整
- **最大并发数**：批量处理最多10个并发
- **资源准备**：必须提前准备好foreground和background两层图片资源
- **JSON配置**：必须在resources/base/media目录下创建drawable.json文件定义分层结构

### 内容约束
- 禁止使用空字符串作为bundleName
- 禁止使用undefined或null作为layeredDrawableDescriptor
- 禁止使用负数或零作为size参数
- 禁止在在线主题场景设置hasBorder为true
- 禁止使用大于10的parallelNumber参数
- 禁止使用不包含layered-image结构的普通图片资源

### 降级约束
- **参数错误**：返回错误码401，提示参数不正确并停止处理
- **任务繁忙**：返回错误码1012600001，建议稍后重试或减少并发数
- **资源缺失**：提示用户检查foreground/background资源是否存在
- **JSON配置缺失**：提示用户创建drawable.json文件并配置layered-image结构
- **资源管理器获取失败**：提示用户检查UIAbilityContext是否正确获取

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否为5.0.0(12)及以上
2. 检查设备类型是否支持（Phone、Tablet、PC/2in1、TV）
3. 检查是否已准备好foreground和background图片资源
4. 检查是否已创建drawable.json配置文件

**资源准备**：
```typescript
// 在entry/src/main/resources/base/media目录下创建drawable.json文件
{
  "layered-image": {
    "background": "$media:background",
    "foreground": "$media:foreground"
  }
}
```

**参数准备**：
```typescript
import { LayeredDrawableDescriptor } from '@kit.ArkUI';
import { hdsDrawable } from '@kit.UIDesignKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';

const bundleName: string = 'com.example.uidesignkit';
const iconSize: number = 48;
const hasBorder: boolean = true;
```

### 步骤2：获取资源管理器和分层图标对象

**获取资源管理器**：
```typescript
// 在组件内获取UIAbilityContext
let resManager: resourceManager.ResourceManager | undefined = undefined;
try {
  resManager = (this.getUIContext().getHostContext() as common.UIAbilityContext)?.resourceManager;
  if (!resManager) {
    console.error('Failed to get resource manager');
    return;
  }
} catch (err) {
  console.error('Failed to get UIAbilityContext:', err);
  return;
}
```

**获取分层图标对象**：
```typescript
// 通过资源管理器获取LayeredDrawableDescriptor
let layeredDrawableDescriptor: LayeredDrawableDescriptor | undefined = undefined;
try {
  layeredDrawableDescriptor = (resManager.getDrawableDescriptor($r('app.media.drawable').id)) as LayeredDrawableDescriptor;
  if (!layeredDrawableDescriptor) {
    console.error('Failed to get layeredDrawableDescriptor');
    return;
  }
} catch (err) {
  console.error('Failed to get DrawableDescriptor:', err);
  return;
}
```

### 步骤3：调用单个图标处理API

**同步接口示例**：
```typescript
// 使用getHdsLayeredIcon处理单个图标
private getHdsLayeredIcon(): image.PixelMap | null {
  if (!this.layeredDrawableDescriptor) {
    console.error('layeredDrawableDescriptor is undefined');
    return null;
  }
  
  try {
    const processedIcon: image.PixelMap = hdsDrawable.getHdsLayeredIcon(
      this.bundleName,
      this.layeredDrawableDescriptor,
      48,
      true
    );
    console.info('getHdsLayeredIcon success');
    return processedIcon;
  } catch (err) {
    const message = (err as BusinessError).message;
    const code = (err as BusinessError).code;
    console.error(`getHdsLayeredIcon failed, code: ${code}, message: ${message}`);
    return null;
  }
}
```

**异步接口示例**：
```typescript
// 使用getHdsLayeredIconAsync处理单个图标
private async getHdsLayeredIconAsync(): Promise<image.PixelMap | null> {
  if (!this.layeredDrawableDescriptor) {
    console.error('layeredDrawableDescriptor is undefined');
    return null;
  }
  
  try {
    const processedIcon: image.PixelMap = await hdsDrawable.getHdsLayeredIconAsync(
      this.bundleName,
      this.layeredDrawableDescriptor,
      48,
      true
    );
    console.info('getHdsLayeredIconAsync success');
    return processedIcon;
  } catch (err) {
    const message = (err as BusinessError).message;
    const code = (err as BusinessError).code;
    console.error(`getHdsLayeredIconAsync failed, code: ${code}, message: ${message}`);
    return null;
  }
}
```

### 步骤4：调用批量图标处理API

**构造批量处理参数**：
```typescript
// 构造批量处理的Options和LayeredIcon数组
const options: hdsDrawable.Options = {
  size: 48,
  hasBorder: true,
  parallelNumber: 4
};

const layeredIcons: Array<hdsDrawable.LayeredIcon> = [];
for (let i = 0; i < 10; i++) {
  layeredIcons.push({
    bundleName: `${this.bundleName}-${i}`,
    layeredDrawableDescriptor: this.layeredDrawableDescriptor
  });
}
```

**批量处理示例**：
```typescript
// 使用getHdsLayeredIcons批量处理图标
private async getHdsLayeredIcons(): Promise<void> {
  if (!this.layeredDrawableDescriptor) {
    console.error('layeredDrawableDescriptor is undefined');
    return;
  }
  
  const options: hdsDrawable.Options = {
    size: 48,
    hasBorder: true,
    parallelNumber: 4
  };
  
  const layeredIcons: Array<hdsDrawable.LayeredIcon> = [];
  for (let i = 0; i < 10; i++) {
    layeredIcons.push({
      bundleName: `${this.bundleName}-${i}`,
      layeredDrawableDescriptor: this.layeredDrawableDescriptor
    });
  }
  
  try {
    const processedIcons: Array<hdsDrawable.ProcessedIcon> = 
      await hdsDrawable.getHdsLayeredIcons(layeredIcons, options);
    console.info(`getHdsLayeredIcons success, processed ${processedIcons.length} icons`);
    this.layeredIconsResult = processedIcons;
  } catch (err) {
    const message = (err as BusinessError).message;
    const code = (err as BusinessError).code;
    console.error(`getHdsLayeredIcons failed, code: ${code}, message: ${message}`);
  }
}
```

### 步骤5：错误处理

**错误码处理示例**：
```typescript
try {
  const processedIcon = hdsDrawable.getHdsLayeredIcon(
    bundleName,
    layeredDrawableDescriptor,
    size,
    hasBorder
  );
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 401:
      console.error('参数错误：请检查bundleName、layeredDrawableDescriptor、size、hasBorder参数是否正确');
      break;
    case 1012600001:
      console.error('任务繁忙：请稍后重试或减少并发数');
      break;
    default:
      console.error(`未知错误：code ${error.code}, message ${error.message}`);
  }
}
```

### 步骤6：降级处理

**资源获取失败降级**：
```typescript
// 降级处理：如果无法获取LayeredDrawableDescriptor，使用默认图标
private getIconWithFallback(): image.PixelMap | null {
  try {
    // 尝试获取分层图标
    if (this.layeredDrawableDescriptor) {
      return hdsDrawable.getHdsLayeredIcon(
        this.bundleName,
        this.layeredDrawableDescriptor,
        48,
        true
      );
    }
  } catch (err) {
    console.warn('Failed to process layered icon, fallback to default');
  }
  
  // 降级方案：返回默认图标或null
  return null;
}
```

**批量处理失败降级**：
```typescript
// 降级处理：如果批量处理失败，逐个处理
private async processIconsWithFallback(): Promise<void> {
  try {
    // 尝试批量处理
    const processedIcons = await hdsDrawable.getHdsLayeredIcons(layeredIcons, options);
    this.layeredIconsResult = processedIcons;
  } catch (err) {
    console.warn('Batch processing failed, fallback to individual processing');
    
    // 降级方案：逐个处理图标
    const fallbackResults: Array<hdsDrawable.ProcessedIcon> = [];
    for (const icon of layeredIcons) {
      try {
        const pixelMap = hdsDrawable.getHdsLayeredIcon(
          icon.bundleName,
          icon.layeredDrawableDescriptor,
          options.size,
          options.hasBorder
        );
        fallbackResults.push({
          bundleName: icon.bundleName,
          pixelMap: pixelMap
        });
      } catch (e) {
        console.error(`Failed to process icon ${icon.bundleName}`);
      }
    }
    this.layeredIconsResult = fallbackResults;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查bundleName是否为有效字符串，layeredDrawableDescriptor是否为有效对象，size是否大于0，hasBorder是否为布尔值 |
| 1012600001 | 任务繁忙 | 稍后重试或减少parallelNumber并发数（最大建议10） |

**参数错误401详细说明**：
- `Parameter error. The value of bundleName is incorrect.` - bundleName为空或格式不正确
- `Parameter error. The value of layeredDrawableDescriptor is incorrect.` - layeredDrawableDescriptor为undefined或null
- `Parameter error. The value of size is incorrect.` - size小于等于0或不是有效数字
- `Parameter error. The value of hasBorder is incorrect.` - hasBorder不是布尔值
- `Parameter error. The value of parallelNumber is incorrect.` - parallelNumber不在1-10范围内

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.UIDesignKit": "5.0.0(12)",
    "@kit.ArkUI": "5.0.0(12)",
    "@kit.ImageKit": "5.0.0(12)",
    "@kit.LocalizationKit": "5.0.0(12)",
    "@kit.AbilityKit": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS API版本：5.0.0(12)及以上
- DevEco Studio版本：5.0.0及以上
- 设备类型：Phone、Tablet、PC/2in1、TV（TV从5.1.1(19)版本开始支持）

### 常见编译问题

**问题1：无法导入hdsDrawable模块**
```
错误：Cannot find module '@kit.UIDesignKit' or its corresponding type declarations
```
**解决方法**：
- 检查HarmonyOS API版本是否为5.0.0(12)及以上
- 在build-profile.json5中配置正确的API版本
- 确保DevEco Studio版本支持UIDesignKit

**问题2：无法获取LayeredDrawableDescriptor**
```
错误：TypeError: Cannot read property 'getDrawableDescriptor' of undefined
```
**解决方法**：
- 确保在UI组件内调用getUIContext().getHostContext()
- 检查返回的context是否为UIAbilityContext类型
- 验证资源管理器是否正确初始化

**问题3：drawable.json文件配置错误**
```
错误：LayeredDrawableDescriptor is not a valid layered icon
```
**解决方法**：
- 确保drawable.json文件位于entry/src/main/resources/base/media目录
- 检查JSON文件是否包含layered-image结构
- 验证foreground和background资源路径是否正确
- 确保使用正确的资源引用格式：$media:资源名

**问题4：批量处理并发数超限**
```
错误：parallelNumber exceeds maximum limit
```
**解决方法**：
- 将parallelNumber参数设置为4（推荐）或不超过10
- 减少批量处理的图标数量
- 分批次处理大量图标

## 常见问题与解决方法

### Q1：如何判断资源是否为分层图标？
**原因**：需要确认图片资源是否包含前后景两层结构
**解决方法**：
- 打开对应的Symbol JSON文件
- 检查是否包含layered-image属性
- 验证是否包含background和foreground两个字段
- 示例结构：
```json
{
  "layered-image": {
    "background": "$background_path",
    "foreground": "$foreground_path"
  }
}
```

### Q2：为什么在线主题场景不支持描边？
**原因**：在线主题场景下图标风格由主题决定，描边效果会与主题设计冲突
**解决方法**：
- 在在线主题场景下，将hasBorder设置为false或不设置（默认false）
- 如果设置了hasBorder为true，系统会自动忽略该参数
- 等待主题加载完成后，系统会自动应用主题风格

### Q3：批量处理时如何控制并发数？
**原因**：需要平衡处理性能和系统资源占用
**解决方法**：
- 使用默认并发数4（推荐值）
- 根据设备性能调整并发数，最大不超过10
- 对于大量图标（超过50个），建议分批次处理
- 监控系统资源占用，动态调整并发数

### Q4：如何处理批量处理失败的图标？
**原因**：部分图标可能因参数错误或资源问题导致处理失败
**解决方法**：
- 在catch回调中记录失败图标信息
- 使用降级方案逐个处理失败图标
- 提供默认图标作为最终降级方案
- 建议的降级流程：
```typescript
try {
  // 批量处理
  const results = await hdsDrawable.getHdsLayeredIcons(icons, options);
} catch (err) {
  // 降级：逐个处理
  for (const icon of icons) {
    try {
      const pixelMap = hdsDrawable.getHdsLayeredIcon(
        icon.bundleName,
        icon.layeredDrawableDescriptor,
        options.size,
        options.hasBorder
      );
      // 保存成功的图标
    } catch (e) {
      // 使用默认图标或记录失败信息
    }
  }
}
```

### Q5：如何优化图标处理性能？
**原因**：大量图标处理可能影响应用性能
**解决方法**：
- 使用批量处理接口而非逐个调用
- 合理设置并发数（推荐4，最大10）
- 在应用空闲时段预加载图标
- 缓存处理后的图标避免重复处理
- 根据屏幕分辨率选择合适的图标尺寸

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "processedIcons": [
    {
      "bundleName": "com.example.uidesignkit-0",
      "pixelMap": "[PixelMap对象]",
      "size": 48,
      "hasBorder": true
    },
    {
      "bundleName": "com.example.uidesignkit-1",
      "pixelMap": "[PixelMap对象]",
      "size": 48,
      "hasBorder": true
    }
  ],
  "totalCount": 10,
  "successCount": 10,
  "failedCount": 0,
  "apiUsed": [
    "hdsDrawable.getHdsLayeredIcon",
    "hdsDrawable.getHdsLayeredIcons"
  ],
  "options": {
    "size": 48,
    "hasBorder": true,
    "parallelNumber": 4
  }
}
```

## 参考文档

- [API开发指南 - 分层图标处理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-design-layered-process)
- [API参考说明 - hdsDrawable](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdsdrawable)
- [API参考说明 - LayeredDrawableDescriptor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-arkui-drawabledescriptor)
- [API参考说明 - image.PixelMap](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)
- [API错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-error-code)

## 完整示例代码

- [ArkTS示例代码 - 分层图标处理](assets/layered_icon_process_example.ets)
- [配置文件示例 - drawable.json](assets/drawable.json)

## 测试用例

### 正向测试用例
- [单个分层图标处理测试](tests/test_single_icon_process.py)：验证单个图标处理功能
- [批量分层图标处理测试](tests/test_batch_icon_process.py)：验证批量处理功能
- [图标描边测试](tests/test_icon_border.py)：验证描边参数生效

### 边界测试用例
- [最大并发数测试](tests/test_max_parallel_number.py)：验证并发数边界值（最大10）
- [最大图标数量测试](tests/test_max_icon_count.py)：验证大批量图标处理（100+个）
- [最小尺寸测试](tests/test_min_size.py)：验证最小尺寸参数（size=1）

### 异常测试用例
- [参数错误测试](tests/test_parameter_error.py)：验证空参数、负数参数等异常场景
- [资源缺失测试](tests/test_resource_missing.py)：验证foreground/background资源缺失场景
- [任务繁忙测试](tests/test_task_busy.py)：验证高并发场景下的任务繁忙处理