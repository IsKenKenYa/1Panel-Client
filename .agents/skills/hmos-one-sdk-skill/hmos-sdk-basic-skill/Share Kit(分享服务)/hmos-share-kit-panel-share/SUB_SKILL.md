---
name: hmos-share-kit-panel-share
description: 通过系统分享面板发起分享，支持文本、图片、视频、链接等多种数据类型，最大支持500条记录/200KB数据，适用于社交分享、文件传输、数据分享场景
---

# 通过分享面板发起分享技能

## 功能描述

本技能提供通过系统分享面板发起分享的功能，支持构造分享数据对象、显示分享面板、监听分享事件等操作。支持多种数据类型分享（文本、图片、视频、链接等），可配置分享面板显示位置、预览模式、选择模式等参数。

### 核心功能
- 构造分享数据对象（SharedData）
- 添加多条分享记录
- 配置分享面板显示参数
- 显示分享面板（支持手机、平板、2in1设备）
- 监听分享面板关闭事件
- 监听分享完成事件（获取分享渠道信息）

### 技术特点
- 支持多种数据类型（PLAIN_TEXT、IMAGE、VIDEO、HYPERLINK等）
- 最大支持500条分享记录
- 数据总大小不超过200KB（IPC传输上限）
- 支持单选和批量模式
- 支持卡片预览和详细预览模式
- 2in1设备支持Popup悬浮窗显示

## 使用场景

### 触发词
- "发起分享"
- "通过分享面板分享"
- "分享面板"
- "拉起分享面板"
- "系统分享"
- "分享文本"
- "分享图片"
- "分享视频"
- "分享链接"

### 能做
- 构造分享数据对象并配置分享内容
- 添加单条或多条分享记录（文本、图片、视频、链接等）
- 显示系统分享面板，支持多种设备类型
- 配置分享面板显示位置（锚点控件ID或坐标位置）
- 配置分享面板预览模式和选择模式
- 监听分享面板关闭事件
- 监听用户完成分享事件，获取分享渠道信息
- 在2in1设备上以Popup悬浮窗形式显示分享面板

### 绝不做
- 不处理分享目标应用的接收逻辑（需要使用ShareExtensionAbility）
- 不直接分享数据到目标应用（通过系统分享面板）
- 不处理超出500条记录或200KB数据限制的分享
- 不修改返回的want数据（可能导致未知错误）
- 不在TV设备上监听shareCompleted事件（无效）

### 补充
- 数据记录必须包含utd字段（统一数据类型）
- content和uri字段至少有一个不为空
- 缩略图限制32KB以下，可使用ImagePacker压缩
- 批量模式仅支持FILE类型记录
- 分享面板在不同设备有不同显示形式（手机模态、平板对话框、2in1 Popup）
- 起始版本：4.1.0(11)，shareCompleted事件起始版本：5.1.0(18)

## 调用规范和规则

### 输入约束
- 数据记录数量：最大500条
- 数据总大小：最大200KB（包含want数据本身字段）
- 缩略图大小：最大32KB
- 数据类型：必须为预置的UniformDataType类型或已知的自定义类型
- content和uri：至少有一个不为空
- uri格式：必须为合法的uri格式（应用文件uri、用户文件uri）

### 执行约束
- 最大耗时：异步操作，建议设置Promise超时处理
- API调用频次：无限制
- 分享面板显示：必须在UIAbility上下文中执行
- 锚点参数：2in1设备必须传入anchor参数（控件ID或坐标位置）

### 内容约束
- 禁止生成：超出数据限制的分享代码、非法uri格式、错误的utd类型
- 禁止使用高危函数：不涉及
- 禁止操作：修改getWant返回的want数据参数、在TV设备监听shareCompleted事件

### 降级约束
- 数据过大：压缩缩略图、限制文本字数、分批分享
- 数据类型不支持：使用FILE类型或检查utd类型合法性
- 解析失败：提示用户分享数据错误，中止分享处理
- 分享面板无法显示：检查UIAbilityContext是否正确获取

## 调用流程和步骤

### 步骤1：导入必要模块

```typescript
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
```

### 步骤2：构造分享数据对象

**参数准备**：
```typescript
let data: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});
```

**说明**：
- utd：统一数据类型，必须传入
- content：文本内容（文本、链接类型）
- uri：文件uri（图片、视频、文件类型）
- content和uri至少有一个不为空

### 步骤3：添加多条分享记录（可选）

```typescript
data.addRecord({
  utd: utd.UniformDataType.PNG,
  uri: 'file://...',
  title: '图片标题',
  description: '图片描述',
  thumbnail: thumbnailData
});
```

**说明**：
- 最大支持500条记录
- thumbnail限制32KB以下
- 可添加title、label、description等字段

### 步骤4：创建分享控制器

```typescript
let controller: systemShare.ShareController = new systemShare.ShareController(data);
```

### 步骤5：获取UIAbility上下文对象

```typescript
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
```

### 步骤6：注册分享面板关闭监听（可选）

```typescript
controller.on('dismiss', () => {
  console.info('Share panel closed');
});
```

### 步骤7：注册分享完成监听（可选，用于数据统计）

```typescript
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('shareCompleted name:', result.targetAbilityInfo.name);
});
```

### 步骤8：配置分享面板显示参数并显示

**方法一：配置分享面板关联的控件ID（推荐）**
```typescript
controller.show(context, {
  anchor: 'shareButtonId'
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

**方法二：配置分享面板显示的坐标位置**
```typescript
controller.show(context, {
  anchor: {
    windowOffset: { x: 100, y: 100 },
    size: { width: 0, height: 0 }
  },
  previewMode: systemShare.SharePreviewMode.DETAIL,
  selectionMode: systemShare.SelectionMode.SINGLE
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

**参数说明**：
- anchor：锚点参数，string类型为控件ID，ShareControllerAnchor类型为坐标位置
- previewMode：预览模式，DEFAULT（卡片模式）或DETAIL（详细预览模式）
- selectionMode：选择模式，SINGLE（单选）或BATCH（批量）
- 2in1设备必须传入anchor参数

### 步骤9：取消事件监听（可选）

```typescript
controller.off('dismiss', callback);
controller.off('shareCompleted', callback);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查参数类型和必填字段 |
| 1003700001 | 数据记录超过上限（500条） | 限制用户可选分享内容数量 |
| 1003702001 | 数据记录格式非法/类型不支持 | 检查utd类型、uri格式、content和uri是否为空 |
| 1003702002 | IPC传输数据超过上限（200KB） | 压缩缩略图、限制文本字数 |
| 1003703001 | 数据解析失败 | 检查want参数格式，中止分享处理 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "4.1.0+",
    "@kit.AbilityKit": "4.1.0+",
    "@kit.ArkData": "4.1.0+"
  }
}
```

### 环境要求
- HarmonyOS版本：4.1.0(11)及以上
- 模型：仅支持Stage模型
- API版本：shareCompleted事件需要5.1.0(18)及以上

### 常见编译问题

**问题1：导入模块错误**
```
Cannot find module '@kit.ShareKit'
```
**解决方法**：确保HarmonyOS版本为4.1.0(11)及以上，SDK版本匹配

**问题2：UIAbilityContext获取失败**
```
Cannot get UIAbilityContext
```
**解决方法**：确保在UIAbility上下文中调用，使用`this.getUIContext().getHostContext()`

**问题3：分享面板无法显示**
```
ShareController show error. code: 1003702002
```
**解决方法**：压缩缩略图数据，限制文本内容字数，确保总数据不超过200KB

## 常见问题与解决方法

### Q1：如何分享图片文件？
**原因**：需要正确配置uri字段
**解决方法**：
- 使用应用文件uri或用户文件uri
- 通过fileUri.getUriFromPath方法获取文件URI
- 设置utd为UniformDataType.PNG或IMAGE
- 可添加缩略图（thumbnail或thumbnailUri）

### Q2：分享面板无法在2in1设备上显示？
**原因**：2in1设备必须传入anchor参数
**解决方法**：
- 传入控件ID：`{ anchor: 'shareButtonId' }`
- 传入坐标位置：`{ anchor: { windowOffset: { x: 100, y: 100 } } }`

### Q3：如何监听用户分享到哪个应用？
**原因**：需要监听shareCompleted事件
**解决方法**：
- 使用controller.on('shareCompleted', callback)
- 返回ShareOperationResult包含targetAbilityInfo
- 需要API版本5.1.0(18)及以上
- TV设备不支持此功能

### Q4：如何处理批量分享？
**原因**：批量模式仅支持FILE类型记录
**解决方法**：
- 设置selectionMode为SelectionMode.BATCH
- 所有记录必须为FILE类型
- 最大支持500条记录

### Q5：缩略图过大导致分享失败？
**原因**：缩略图超过32KB或总数据超过200KB
**解决方法**：
- 使用ImagePacker.packToData压缩图片质量
- 控制缩略图大小在32KB以下
- 确保总数据不超过200KB

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "shareData": "分享数据对象已构造",
  "sharePanel": "分享面板已显示",
  "recordsCount": "分享记录数量",
  "totalSize": "数据总大小（KB）",
  "apiUsed": [
    "SharedData.constructor",
    "SharedData.addRecord",
    "ShareController.constructor",
    "ShareController.show",
    "ShareController.on",
    "ShareController.off"
  ]
}
```

## 参考文档

- [API开发指南：通过分享面板发起分享](references/share-mobilephone-app-share.md)
- [API参考说明：systemShare（分享）](references/share-system-share.md)
- [错误码说明：分享服务错误码](references/share-error-code.md)
- [统一数据类型定义：uniformTypeDescriptor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor)
- [UIAbilityContext：应用上下文](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)

## 完整示例代码

- [ArkTS示例：分享文本](assets/share_text_example.ets)
- [ArkTS示例：分享图片](assets/share_image_example.ets)
- [ArkTS示例：分享多条数据](assets/share_multiple_example.ets)
- [ArkTS示例：2in1设备分享](assets/share_2in1_example.ets)

## 测试用例

### 正向测试用例
- [分享单条文本数据](tests/test_positive.py)：测试正常分享文本场景
- [分享图片文件](tests/test_positive.py)：测试正常分享图片场景
- [分享多条数据](tests/test_positive.py)：测试添加多条分享记录
- [监听分享事件](tests/test_positive.py)：测试监听dismiss和shareCompleted事件

### 边界测试用例
- [分享500条记录](tests/test_boundary.py)：测试最大记录数量限制
- [分享200KB数据](tests/test_boundary.py)：测试最大数据大小限制
- [分享32KB缩略图](tests/test_boundary.py)：测试缩略图大小限制

### 异常测试用例
- [分享超过500条记录](tests/test_exception.py)：测试超出记录数量限制
- [分享超过200KB数据](tests/test_exception.py)：测试超出数据大小限制
- [分享非法uri格式](tests/test_exception.py)：测试uri格式错误
- [分享不支持的utd类型](tests/test_exception.py)：测试数据类型错误
- [缺少必填参数](tests/test_exception.py)：测试缺少utd或content/uri参数