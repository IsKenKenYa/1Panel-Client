---
name: hmos-share-kit-share-text
description: 分享文本内容到目标设备或应用，支持纯文本类型分享，可将文本保存为.txt文件或传递给应用处理，适用于文本分享、备忘录分享场景
---

# 分享文本技能

## 功能描述

本技能实现HarmonyOS系统中纯文本内容的分享功能。通过Share Kit提供的systemShare模块，将一段文字分享到目标设备或目标应用。

**核心能力**：
- 支持纯文本类型（TEXT、PLAIN_TEXT）的分享
- 可构造包含title、description、thumbnail等元数据的分享数据
- 支持单选模式和批量模式分享
- 提供详细预览和卡片预览两种展示方式
- 分享到目标设备时，文本会转化为.txt文件保存在文件管理中
- 分享到目标应用时，可便捷地处理文本内容

**限制条件**：
- 仅支持Stage模型
- 数据记录最大支持500条
- 数据总大小不超过IPC传输上限200KB
- 缩略图限制32KB以下
- 需要 API version 4.1.0(11)及以上

## 使用场景

### 触发词
- "分享文本"
- "文本分享"
- "分享文字"
- "文字分享"
- "纯文本分享"
- "分享内容到备忘录"
- "分享到目标应用"

### 能做
- 分享纯文本内容到其他应用或设备
- 构造包含标题、描述、缩略图的文本分享数据
- 添加多条文本记录进行批量分享
- 配置分享面板的预览模式和选择模式
- 监听分享完成事件和面板关闭事件
- 获取用户选择的分享渠道信息

### 绝不做
- 不支持分享文件、图片、视频等非文本类型内容
- 不支持跨设备分享超过200KB的文本数据
- 不支持在FA模型中使用
- 不直接处理目标应用接收分享数据的逻辑（需由目标应用自行处理）

### 补充
- 文本分享时建议传入合适的title和description，提升用户体验
- 如需分享多条文本，可使用addRecord方法追加记录
- 单选模式下用户需多选一进行分享，批量模式下分享全部记录
- TV设备不支持shareCompleted事件监听

## 调用规范和规则

### 输入约束
- 文本内容：字符串类型，长度不超过IPC传输上限（200KB整体限制）
- title字段：可选，不传时显示content内容
- description字段：可选，缺省为空字符串
- thumbnail字段：可选，Uint8Array类型，限制32KB以下
- 数据记录数量：1-500条
- utd类型：必须是TEXT或PLAIN_TEXT等文本类型

### 执行约束
- 最大耗时：取决于用户选择分享目标的耗时，分享面板显示为异步Promise调用
- API调用频次：无限制
- 必须在UI组件中调用show方法（需要UIContext）
- 需要获取UIAbilityContext作为context参数

### 内容约束
- 禁止分享空文本内容（content和uri至少有一个不为空）
- 禁止使用非文本类型的utd（如IMAGE、VIDEO等）
- 禁止传入超过32KB的缩略图
- 禁止在数据总大小超过200KB时调用show方法
- 禁止修改getWant返回的want数据参数

### 降级约束
- 分享面板显示失败：捕获BusinessError，输出错误日志，提示用户分享失败
- 缩略图过大：使用ImagePacker压缩图片质量或使用应用图标替代
- 多条数据超限：减少数据记录数量，分批分享
- 目标应用不支持文本类型：提示用户选择其他分享目标

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认当前为Stage模型运行环境
2. 确认API version >= 4.1.0(11)
3. 确认文本内容不为空
4. 确认缩略图大小不超过32KB（如提供）
5. 确认总数据大小不超过200KB

**参数准备**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const textContent: string = '这是一段文本内容';
const title: string = '文本标题';
const description: string = '文本描述';
```

### 步骤2：构造分享数据

**示例代码**：
```typescript
// 构造ShareData，需配置一条有效数据信息
let shareData: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.TEXT,
  content: textContent,
  title: title,
  description: description,
  // thumbnail: new Uint8Array() // 推荐传入适合的缩略图，不传则显示默认text图标
});
```

**说明**：
- utd字段：必填，使用utd.UniformDataType.TEXT或PLAIN_TEXT
- content字段：必填，文本内容字符串
- title字段：可选，不传时显示content内容
- description字段：可选，文本描述
- thumbnail字段：可选，缩略图数据，限制32KB

### 步骤3：添加额外数据记录（可选）

**示例代码**：
```typescript
// 额外增加一条数据记录（可选）
shareData.addRecord({
  utd: utd.UniformDataType.TEXT,
  content: '这是一段额外的文本内容',
  title: '额外文本',
  description: '额外文本描述'
});
```

**说明**：
- 一条分享数据可包含多条记录，最多500条
- 单选模式下用户需多选一进行分享
- 批量模式下分享全部记录

### 步骤4：创建分享控制器并启动分享面板

**示例代码**：
```typescript
// 进行分享面板显示
let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
let uiContext: UIContext = this.getUIContext();
let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

controller.show(context, {
  selectionMode: systemShare.SelectionMode.SINGLE,
  previewMode: systemShare.SharePreviewMode.DETAIL
}).then(() => {
  console.info('ShareController show success.');
}).catch((error: BusinessError) => {
  console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
});
```

**说明**：
- selectionMode：选择模式，SINGLE为单选，BATCH为批量
- previewMode：预览模式，DEFAULT为卡片模式（推荐文本使用），DETAIL为详细预览图模式
- show方法返回Promise，成功时无返回值

### 步骤5：监听分享事件（可选）

**监听分享完成事件**：
```typescript
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('shareCompleted name:', result.targetAbilityInfo.name);
  // 可用于数据统计，获取用户选择的分享渠道
});
```

**监听面板关闭事件**：
```typescript
controller.on('dismiss', () => {
  console.info('Share panel closed');
  // 可在此处清理资源或执行后续操作
});
```

**取消监听**：
```typescript
let callback = () => {
  console.info('Share panel closed');
};
controller.on('dismiss', callback);
// 需要取消监听时
controller.off('dismiss', callback);
```

### 步骤6：错误处理

**错误处理代码**：
```typescript
try {
  await controller.show(context, {
    selectionMode: systemShare.SelectionMode.SINGLE,
    previewMode: systemShare.SharePreviewMode.DETAIL
  });
  console.info('ShareController show success.');
} catch (error) {
  const businessError: BusinessError = error as BusinessError;
  switch (businessError.code) {
    case 401:
      console.error('Parameter error. Please check input parameters.');
      break;
    case 1003702001:
      console.error('Record types are not support. Batch and multiple selection modes support FILE type records only.');
      break;
    case 1003702002:
      console.error('IPC data is oversized. Please reduce data size.');
      break;
    default:
      console.error(`Unknown error. code: ${businessError.code}, message: ${businessError.message}`);
  }
}
```

### 步骤7：降级处理

**数据超限降级处理**：
```typescript
// 如果数据总大小超过200KB，进行分批分享
function shareTextInBatches(textList: string[]): void {
  const batchSize = 10; // 每批分享10条
  for (let i = 0; i < textList.length; i += batchSize) {
    const batch = textList.slice(i, i + batchSize);
    const shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.TEXT,
      content: batch[0]
    });
    batch.slice(1).forEach(text => {
      shareData.addRecord({
        utd: utd.UniformDataType.TEXT,
        content: text
      });
    });
    // 显示分享面板
    const controller = new systemShare.ShareController(shareData);
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.BATCH,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    });
  }
}
```

**缩略图过大降级处理**：
```typescript
import { image } from '@kit.ImageKit';

// 压缩缩略图
async function compressThumbnail(thumbnailData: Uint8Array): Promise<Uint8Array> {
  try {
    const imageSource = image.createImageSource(thumbnailData);
    const packingOptions: image.PackingOption = {
      format: 'image/jpeg',
      quality: 80
    };
    const packer = image.createImagePacker();
    const packedData = await packer.packing(imageSource, packingOptions);
    packer.release();
    imageSource.release();
    return packedData;
  } catch (error) {
    console.warn('Failed to compress thumbnail, using default icon instead.');
    return new Uint8Array(0); // 使用默认图标
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误 | 检查输入参数是否正确，确保utd、content等必填字段已提供 |
| 1003700001 | The number of records exceeds the maximum. 记录数量超过上限 | 减少分享数据记录数量，最多支持500条 |
| 1003702001 | Record types are not support. 记录类型不支持 | 批量和多选模式仅支持FILE类型记录，文本分享使用单选模式 |
| 1003702002 | IPC data is oversized. IPC数据过大 | 减少数据总大小，确保不超过200KB；压缩缩略图或减少记录数量 |
| 1003703001 | Parse data failed. 解析数据失败 | 检查分享数据格式是否正确，确保符合SharedData规范 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ShareKit": "^4.1.0",
    "@kit.ArkData": "^4.1.0",
    "@kit.AbilityKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS API version: 4.1.0(11)及以上
- 模型约束：Stage模型
- 系统能力：SystemCapability.Collaboration.SystemShare

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit' or its corresponding type declarations.
```
**解决方法**：确保项目API version >= 4.1.0(11)，在build-profile.json5中配置正确的compileSdkVersion

**问题2：SharedData构造失败**
```
Error: Parameter error. Missing required parameter 'utd' or 'content'.
```
**解决方法**：确保SharedData构造时传入完整的必填参数（utd和content）

**问题3：缩略图过大导致分享失败**
```
Error: IPC data is oversized (1003702002).
```
**解决方法**：使用ImagePacker压缩缩略图质量，确保缩略图小于32KB

**问题4：在UI组件外调用show方法**
```
Error: Cannot read property 'getUIContext' of undefined.
```
**解决方法**：确保在UI组件（@Component装饰的组件）中调用show方法，使用this.getUIContext()获取UIContext

## 常见问题与解决方法

### Q1：分享面板显示后无响应？
**原因**：可能context参数不正确或分享数据格式错误
**解决方法**：
- 检查UIAbilityContext是否正确获取
- 检查分享数据是否符合SharedData规范
- 查看错误日志，捕获BusinessError进行处理

### Q2：如何区分TEXT和PLAIN_TEXT类型？
**原因**：两种文本类型的使用场景不同
**解决方法**：
- TEXT：通用文本类型，适用于大多数文本分享场景
- PLAIN_TEXT：未指定编码的文本类型，适用于简单纯文本分享
- 建议使用TEXT类型，更通用

### Q3：如何获取用户分享的目标应用信息？
**原因**：需要进行数据统计或后续处理
**解决方法**：
- 注册shareCompleted事件监听
- 从ShareOperationResult的targetAbilityInfo.name获取分享渠道名称
- 系统操作有固定名称（如SystemShare_CopyToPasteboard），非系统操作格式为'[bundleName]#[moduleName]#[abilityName]'

### Q4：分享多条文本时如何控制用户选择？
**原因**：不同场景需要不同的选择方式
**解决方法**：
- 单选模式（SINGLE）：用户需多选一进行分享，适用于提供多个文本选项供用户选择
- 批量模式（BATCH）：分享全部记录，适用于批量分享多个文本内容
- 在show方法的options参数中配置selectionMode

### Q5：缩略图如何设置？
**原因**：提升分享面板的用户体验
**解决方法**：
- 可传入Uint8Array类型的缩略图数据
- 如无合适缩略图，可传入应用图标
- 确保缩略图大小小于32KB，过大可使用ImagePacker压缩
- 不传thumbnail字段时，显示默认text图标

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "function": "分享文本到目标应用/设备",
  "shareData": {
    "recordCount": 1,
    "utdType": "TEXT",
    "hasTitle": true,
    "hasDescription": true,
    "hasThumbnail": false
  },
  "shareMode": {
    "selectionMode": "SINGLE",
    "previewMode": "DETAIL"
  },
  "apiUsed": [
    "systemShare.SharedData",
    "systemShare.ShareController",
    "controller.show"
  ],
  "shareResult": "用户选择分享目标后，分享面板关闭"
}
```

## 参考文档

- [API开发指南 - 分享文本](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-utd-text)
- [API参考说明 - systemShare（分享）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share)
- [API参考说明 - uniformTypeDescriptor（标准化数据定义与描述）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-uniformtypedescriptor)
- [API参考说明 - 分享服务错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-error-code)

## 完整示例代码

- [ArkTS示例 - 分享文本](assets/share-text-example.ets)
- [ArkTS示例 - 多条文本分享](assets/share-text-multiple-example.ets)
- [ArkTS示例 - 监听分享事件](assets/share-text-event-example.ets)

## 测试用例

### 正向测试用例
- [分享单条文本内容](tests/test_positive.py)：测试正常分享单条文本内容
- [分享多条文本内容](tests/test_positive.py)：测试批量分享多条文本内容
- [带标题和描述的分享](tests/test_positive.py)：测试包含title和description的文本分享

### 边界测试用例
- [分享空文本内容](tests/test_boundary.py)：测试分享空字符串的处理
- [分享超长文本内容](tests/test_boundary.py)：测试接近200KB限制的文本分享
- [添加最大数量记录](tests/test_boundary.py)：测试添加500条文本记录

### 异常测试用例
- [参数缺失错误](tests/test_exception.py)：测试缺少必填参数的错误处理
- [缩略图过大错误](tests/test_exception.py)：测试缩略图超过32KB的错误处理
- [IPC数据过大错误](tests/test_exception.py)：测试数据总大小超过200KB的错误处理
- [不支持的数据类型](tests/test_exception.py)：测试使用非文本类型utd的错误处理