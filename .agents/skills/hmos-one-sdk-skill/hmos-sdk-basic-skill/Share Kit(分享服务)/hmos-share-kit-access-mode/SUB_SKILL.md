---
name: hmos-share-kit-access-mode
description: 提供宿主应用接入系统分享的两种模式配置能力，支持全接模式和半接模式，全接模式直接使用系统分享面板，半接模式自行开发分享面板并提供系统分享入口，适用于华为自研应用及对分享方式区有商业诉求的开发者
---

# 宿主应用接入模式技能

## 功能描述

本技能提供Share Kit宿主应用接入模式的配置和实现能力，包含两种接入模式：

1. **全接模式**：直接使用系统分享面板，适用于华为自研应用以及对分享方式区无商业诉求的开发者，降低开发成本
2. **半接模式**：开发者自行开发分享能力面板，并在分享面板中提供系统分享入口，适用于分享方式区有商业诉求或有独特业务逻辑的开发者

两种模式可灵活选择，满足不同开发者的接入诉求。

## 使用场景

### 触发词
- "接入系统分享"
- "宿主应用接入模式"
- "配置分享接入模式"
- "全接模式分享"
- "半接模式分享"
- "Share Kit接入"

### 能做
- 配置全接模式，直接使用系统分享面板
- 配置半接模式，开发自定义分享面板并提供系统分享入口
- 使用系统Symbol图标和标准文本标识系统分享功能
- 集成系统分享能力到宿主应用

### 绝不做
- 不处理接收分享数据的功能（由目标应用处理）
- 不配置分享目标应用的选择逻辑
- 不修改系统分享面板的核心功能

### 补充
- 半接模式必须使用系统标准图标"$r('sys.symbol.share')"和文本"系统分享"，确保用户体验一致性
- 全接模式开发成本较低，适合快速接入
- 半接模式可满足商业诉求，但需自行开发分享面板UI

## 调用规范和规则

### 输入约束
- 接入模式类型：必须明确指定"全接模式"或"半接模式"
- 分享数据类型：支持文本、图片、视频、链接等多种类型
- 文件大小限制：单个文件最大200MB
- 数据记录数量：最多500条，总大小不超过IPC传输上限200KB

### 执行约束
- 最大耗时：面板显示耗时不超过3秒
- API调用频次：单次分享操作，无需频次限制
- 权限要求：使用appLaunchTrustInfo字段需申请ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST权限（受限开放）

### 内容约束
- 禁止修改系统分享图标样式：必须使用"$r('sys.symbol.share')"
- 禁止修改系统分享文本：必须使用"系统分享"
- 禁止使用自定义图标替代系统分享图标（半接模式）
- 禁止拦截或修改系统分享面板的核心功能

### 降级约束
- 网络失败：显示错误提示，不影响本地分享功能
- 文件过大：提示用户压缩或选择其他分享方式
- 权限不足：降级为全接模式或提示用户申请权限
- 目标应用不可用：显示应用列表供用户选择其他目标

## 调用流程和步骤

### 步骤1：选择接入模式

**前置校验**：
1. 明确业务需求：是否需要对分享方式区有商业诉求
2. 明确开发成本：是否需要降低开发成本
3. 确定接入模式类型：全接模式或半接模式

**参数准备**：
```typescript
// 接入模式选择
const accessMode = 'full' | 'half'; // 'full': 全接模式, 'half': 半接模式
```

### 步骤2：全接模式实现

**示例代码**：
```typescript
// 全接模式：直接使用系统分享面板
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 构造分享数据
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});

// 创建分享控制器
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

// 获取UIAbility上下文
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

// 注册面板关闭监听
controller.on('dismiss', () => {
  console.info('Share panel closed');
  // 分享结束，可处理其他业务
});

// 显示系统分享面板
controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DEFAULT
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

### 步骤3：半接模式实现

**示例代码**：
```typescript
// 半接模式：自定义分享面板并提供系统分享入口
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

@Component
export struct CustomSharePanel {
  private shareData: systemShare.SharedData | null = null;
  private controller: systemShare.ShareController | null = null;

  build() {
    Column() {
      // 自定义分享面板UI
      Text('自定义分享方式1')
        .onClick(() => {
          // 自定义分享逻辑
        })

      Text('自定义分享方式2')
        .onClick(() => {
          // 自定义分享逻辑
        })

      // 系统分享入口（必须使用系统标准图标和文本）
      Row() {
        // 分享图标使用系统提供的Symbol格式图标
        SymbolGlyph($r('sys.symbol.share'))
          .fontSize(24)
        
        // 文本使用'系统分享'
        Text('系统分享')
          .fontSize(16)
      }
      .onClick(() => {
        this.invokeSystemShare();
      })
    }
  }

  // 调用系统分享面板
  private invokeSystemShare() {
    // 构造分享数据
    this.shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Hello HarmonyOS'
    });

    // 创建分享控制器
    this.controller = new systemShare.ShareController(this.shareData);

    // 获取UIAbility上下文
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    // 注册面板关闭监听
    this.controller.on('dismiss', () => {
      console.info('System share panel closed');
    });

    // 显示系统分享面板
    this.controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    }).then(() => {
      console.info('System share panel shown successfully.');
    }).catch((error: BusinessError) => {
      console.error(`Failed to show system share panel. code: ${error.code}, message: ${error.message}`);
    });
  }
}
```

### 步骤4：错误处理

```typescript
// 错误处理代码
try {
  await controller.show(context, options);
} catch (error) {
  const businessError = error as BusinessError;
  switch (businessError.code) {
    case 401:
      console.error('参数错误：检查SharedData和ShareControllerOptions配置');
      break;
    case 1003702001:
      console.error('记录类型不支持：批量模式和多选模式仅支持文件类型记录');
      break;
    case 1003702002:
      console.error('IPC数据超限：减少分享数据记录数量或文件大小');
      break;
    default:
      console.error(`未知错误：code=${businessError.code}, message=${businessError.message}`);
  }
}
```

### 步骤5：降级处理

```typescript
// 降级处理代码
async function shareWithFallback(shareData: systemShare.SharedData, context: common.UIAbilityContext) {
  try {
    // 尝试使用半接模式
    let controller = new systemShare.ShareController(shareData);
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    });
  } catch (error) {
    console.warn('半接模式失败，降级为全接模式');
    
    try {
      // 降级为全接模式
      let fallbackController = new systemShare.ShareController(shareData);
      await fallbackController.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DEFAULT
      });
    } catch (fallbackError) {
      console.error('全接模式也失败，提示用户使用其他分享方式');
      // 显示错误提示
      AlertDialog.show({
        title: '分享失败',
        message: '请尝试使用其他分享方式或检查数据格式'
      });
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，检查SharedData和ShareControllerOptions配置 | 确保所有必填参数已正确配置，数据类型匹配 |
| 1003700001 | 分享数据记录数量超过最大限制（500条） | 减少分享数据记录数量，确保不超过500条 |
| 1003702001 | 记录类型不支持，批量模式和多选模式仅支持文件类型记录 | 检查数据类型，批量模式和多选模式使用文件类型记录 |
| 1003702002 | IPC数据超限，总大小超过200KB | 减少分享数据总大小，压缩文件或减少记录数量 |
| 1003703001 | 解析数据失败 | 检查Want数据格式，确保符合UDMF规范 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": ">=4.1.0",
    "@kit.ArkData": ">=4.1.0",
    "@kit.AbilityKit": ">=4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK版本：>=4.1.0(11)
- Stage模型：必须在Stage模型下使用
- 设备类型：支持手机、平板、2in1设备

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.ShareKit' or its corresponding type declarations.
```
**解决方法**：确保HarmonyOS SDK版本>=4.1.0，检查项目配置文件中的SDK版本设置

**问题2：SymbolGlyph组件编译错误**
```
Cannot find name 'SymbolGlyph'.
```
**解决方法**：确保使用最新版本的ArkUI组件库，SymbolGlyph是HarmonyOS新增的系统图标组件

**问题3：权限声明缺失**
```
Permission ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST is required.
```
**解决方法**：在module.json5中添加权限声明，该权限为受限权限，需通过ACL方式申请

## 常见问题与解决方法

### Q1：如何选择接入模式？
**原因**：开发者不清楚两种模式的适用场景
**解决方法**：
- **全接模式**：适用于华为自研应用、对分享方式区无商业诉求、需要降低开发成本
- **半接模式**：适用于分享方式区有商业诉求、有独特业务逻辑、需要自定义分享面板UI

### Q2：半接模式系统分享入口图标和文本能否自定义？
**原因**：开发者希望修改系统分享图标样式
**解决方法**：
- **图标必须使用**："$r('sys.symbol.share')"（系统Symbol图标）
- **文本必须使用**："系统分享"（标准文本）
- **禁止修改**：为确保用户获得良好的分享体验，请勿自行更改图标和文本

### Q3：分享面板显示失败，提示IPC数据超限？
**原因**：分享数据总大小超过IPC传输上限（200KB）
**解决方法**：
- 减少分享数据记录数量（最多500条）
- 压缩文件大小，确保单文件不超过200MB
- 使用thumbnailUri替代thumbnail，减少数据大小

### Q4：如何在2in1设备上显示分享面板？
**原因**：2in1设备需要传入锚点信息，分享面板以悬浮窗形式显示
**解决方法**：
- 配置ShareControllerOptions的anchor参数
- 方法一：配置关联的控件ID（anchor: 'shareButtonId'）
- 方法二：配置显示坐标（anchor: { windowOffset: { x: 100, y: 100 }, size: { width: 0, height: 0 } }）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "accessMode": "full | half",
  "sharePanelShown": true,
  "shareCompleted": false,
  "apiUsed": [
    "systemShare.SharedData.constructor",
    "systemShare.ShareController.constructor",
    "systemShare.ShareController.show",
    "systemShare.ShareController.on"
  ],
  "dataRecords": 1,
  "dataType": "PLAIN_TEXT"
}
```

## 参考文档

- [API开发指南：宿主应用接入模式](references/share-access-mode.md)
- [API开发指南：通过分享面板发起分享](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-mobilephone-app-share)
- [API参考说明：systemShare（分享）](references/share-system-share.md)

## 完整示例代码

- [ArkTS示例：全接模式实现](assets/access-mode-full.ets)
- [ArkTS示例：半接模式实现](assets/access-mode-half.ets)
- [完整示例代码：samplecode-接入模式](https://gitcode.com/harmonyos_samples/share-kit_-sample-code_-clientdemo_-arkts/blob/master/entry/src/main/ets/components/AccessModel.ets)

## 测试用例

### 正向测试用例
- [全接模式文本分享](tests/test_full_mode_text.py)：验证全接模式分享文本功能
- [半接模式系统分享入口](tests/test_half_mode_system_share.py)：验证半接模式调用系统分享面板

### 边界测试用例
- [最大数据记录数量测试](tests/test_max_records.py)：验证分享500条数据记录
- [最大数据大小测试](tests/test_max_data_size.py)：验证分享数据总大小接近200KB

### 异常测试用例
- [参数错误测试](tests/test_parameter_error.py)：验证缺少必填参数时的错误处理
- [IPC数据超限测试](tests/test_ipc_overflow.py)：验证数据超限时的降级处理