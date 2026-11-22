---
name: hmos-share-kit-utd-type
description: 查询UTD类型+构造分享数据+显示分享面板+API version 10+适用于宿主应用分享场景
---

# 宿主应用发起分享需使用精细化的UTD类型技能

## 功能描述

本技能用于宿主应用发起分享时使用精细化的UTD类型，通过文件后缀名或MIME类型查询标准化的数据类型ID，构造分享数据并显示分享面板。精准的UTD类型有助于宿主应用匹配到精确的目标应用，让分享内容更好的传递。

**核心功能**：
- 根据文件后缀名查询标准化数据类型ID
- 根据MIME类型查询标准化数据类型ID
- 构造分享数据对象（SharedData）
- 构建分享控制器（ShareController）
- 显示分享面板

**技术特点**：
- 支持两种UTD类型查询方式：文件后缀名查询和MIME类型查询
- 提供精细化的数据类型匹配，提高分享准确性
- 支持多种预览模式和选择模式
- 异步API调用，Promise方式返回结果

## 使用场景

### 触发词
- "分享文件"
- "使用UTD类型分享"
- "根据文件后缀分享"
- "根据MIME类型分享"
- "精细化分享"
- "构造分享数据"
- "显示分享面板"

### 能做
- 根据文件后缀名查询标准化数据类型ID（如.jpg、.png、.mp3等）
- 根据MIME类型查询标准化数据类型ID（如image/jpeg、text/plain等）
- 构造包含UTD类型的分享数据对象
- 配置分享面板的预览模式和选择模式
- 显示系统分享面板供用户选择目标应用
- 支持单选模式和批量模式分享
- 处理分享过程中的错误和异常

### 绝不做
- 不支持非Stage模型的应用
- 不直接处理分享内容的实际传输（仅提供面板和数据构造）
- 不替代目标应用处理分享数据
- 不处理超出API限制的数据量（最大500条记录，总大小不超过200KB）
- 不支持自定义UTD类型的创建（仅查询预置类型）

### 补充
- 建议传入精准的UTD类型以提高匹配准确性
- 文件后缀名需包含点号（如'.jpg'而非'jpg')
- MIME类型需符合标准格式（如'image/jpeg')
- 分享数据至少包含一条有效记录
- thumbnail图片建议不超过32KB
- content和uri字段至少有一个不为空

## 调用规范和规则

### 输入约束
- **文件后缀名**：必须包含点号（如'.jpg'），长度限制1-20字符
- **MIME类型**：必须符合标准格式（如'image/jpeg'），长度限制1-100字符
- **归属类型**：可选参数，必须是UniformDataType枚举值或自定义UTD类型ID
- **数据记录数量**：最小1条，最大500条
- **数据总大小**：不超过IPC传输上限200KB
- **缩略图大小**：建议不超过32KB
- **uri格式**：应用文件uri或用户文件uri，需符合uri规范

### 执行约束
- **最大耗时**：API调用不超过5秒
- **最大迭代次数**：不涉及迭代操作
- **API调用频次**：建议不超过每秒10次调用
- **并发限制**：同一时间只能显示一个分享面板

### 内容约束
- **禁止生成**：不生成虚假的UTD类型ID，必须通过API查询获取
- **禁止使用高危函数**：不使用eval、exec等高危函数
- **禁止操作**：不直接修改系统文件，不访问敏感权限
- **参数校验**：必须校验文件后缀名、MIME类型、UTD类型ID的有效性

### 降级约束
- **网络失败**：不涉及网络请求，无需降级
- **文件过大**：缩略图超过32KB时，使用默认图标或应用图标
- **权限不足**：提示用户申请必要权限（ohos.permission.SET_SYSTEMSHARE_APPLAUNCHTRUSTLIST）
- **类型不存在**：返回根据入参按指定规则生成的动态类型
- **数据超限**：提示用户减少分享数据量或分批分享

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 校验应用运行在Stage模型下
2. 校验文件后缀名或MIME类型参数的有效性
3. 校验归属类型参数（可选）的有效性
4. 校验文件uri或content的有效性
5. 校验数据记录数量不超过500条
6. 校验数据总大小不超过200KB

**参数准备**：
```typescript
// 导入必要模块
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';

// 方式1：根据文件后缀名准备参数
const filenameExtension = '.jpg'; // 文件后缀名，必须包含点号
const belongsToType = utd.UniformDataType.IMAGE; // 归属类型，可选参数

// 方式2：根据MIME类型准备参数
const mimeType = 'image/jpeg'; // MIME类型
const belongsToTypeMime = utd.UniformDataType.IMAGE; // 归属类型，可选参数

// 分享数据参数
const shareUri = 'file://.../xxx.jpg'; // 文件uri
const shareContent = '这是分享的内容'; // 内容文本，可选
```

### 步骤2：查询UTD类型ID

**示例代码（方式1：根据文件后缀名）**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

async function queryUtdByFileExtension(filenameExtension: string, belongsTo?: string): Promise<string | null> {
  try {
    // 校验参数有效性
    if (!filenameExtension || filenameExtension.length === 0) {
      console.error('filenameExtension parameter is invalid');
      return null;
    }

    // 查询UTD类型ID
    const utdTypeId = utd.getUniformDataTypeByFilenameExtension(filenameExtension, belongsTo);
    
    if (utdTypeId) {
      console.info(`Successfully queried UTD type ID: ${utdTypeId}`);
      return utdTypeId;
    } else {
      console.warn('UTD type ID not found for given filename extension');
      return null;
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to getUniformDataTypeByFilenameExtension. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

**示例代码（方式2：根据MIME类型）**：
```typescript
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

async function queryUtdByMIMEType(mimeType: string, belongsTo?: string): Promise<string | null> {
  try {
    // 校验参数有效性
    if (!mimeType || mimeType.length === 0) {
      console.error('mimeType parameter is invalid');
      return null;
    }

    // 查询UTD类型ID
    const utdTypeId = utd.getUniformDataTypeByMIMEType(mimeType, belongsTo);
    
    if (utdTypeId) {
      console.info(`Successfully queried UTD type ID: ${utdTypeId}`);
      return utdTypeId;
    } else {
      console.warn('UTD type ID not found for given MIME type');
      return null;
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to getUniformDataTypeByMIMEType. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤3：构造分享数据

**示例代码**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

async function createShareData(utdTypeId: string, uri?: string, content?: string): Promise<systemShare.SharedData | null> {
  try {
    // 校验UTD类型ID有效性
    if (!utdTypeId || utdTypeId.length === 0) {
      console.error('utdTypeId parameter is invalid');
      return null;
    }

    // 校验uri或content至少有一个不为空
    if (!uri && !content) {
      console.error('At least one of uri or content must be provided');
      return null;
    }

    // 构造分享数据记录
    const shareRecord: systemShare.SharedRecord = {
      utd: utdTypeId,
      uri: uri || '',
      content: content || ''
    };

    // 创建分享数据对象
    const shareData: systemShare.SharedData = new systemShare.SharedData(shareRecord);
    
    console.info('Successfully created SharedData object');
    return shareData;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to create SharedData. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}

// 添加多条分享数据记录（可选）
async function addShareRecords(shareData: systemShare.SharedData, records: systemShare.SharedRecord[]): Promise<void> {
  try {
    // 校验记录数量不超过500条
    const currentRecords = shareData.getRecords();
    if (currentRecords.length + records.length > 500) {
      console.error('Total number of records exceeds the maximum limit of 500');
      return;
    }

    // 添加记录
    for (const record of records) {
      shareData.addRecord(record);
    }
    
    console.info(`Successfully added ${records.length} share records`);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to add share records. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤4：构建分享控制器并显示面板

**示例代码**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function showSharePanel(
  shareData: systemShare.SharedData,
  context: common.UIAbilityContext,
  previewMode?: systemShare.SharePreviewMode,
  selectionMode?: systemShare.SelectionMode
): Promise<void> {
  try {
    // 校验分享数据有效性
    if (!shareData) {
      console.error('shareData parameter is invalid');
      return;
    }

    // 校验上下文有效性
    if (!context) {
      console.error('context parameter is invalid');
      return;
    }

    // 构建分享控制器
    const controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    // 配置分享面板选项
    const options: systemShare.ShareControllerOptions = {
      previewMode: previewMode || systemShare.SharePreviewMode.DEFAULT,
      selectionMode: selectionMode || systemShare.SelectionMode.SINGLE
    };

    // 显示分享面板
    await controller.show(context, options);
    
    console.info('Successfully showed share panel');
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to show share panel. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

function handleShareError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameters types.');
      // 提示用户检查输入参数
      break;
    case 1003700001:
      console.error('The number of records exceeds the maximum (500).');
      // 提示用户减少分享数据数量
      break;
    case 1003702001:
      console.error('Record types are not supported. The batch and multiple selection modes support FILE type records only.');
      // 提示用户检查数据类型或切换到单选模式
      break;
    case 1003702002:
      console.error('IPC data is oversized (exceeds 200KB).');
      // 提示用户减少分享数据大小或分批分享
      break;
    case 1003703001:
      console.error('Parse data failed.');
      // 提示用户检查数据格式
      break;
    default:
      console.error(`Unknown error occurred. Code: ${error.code}, message: ${error.message}`);
      // 提示用户稍后重试
      break;
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function shareWithFallback(
  filenameExtension: string,
  uri: string,
  context: common.UIAbilityContext
): Promise<void> {
  let utdTypeId: string | null = null;

  // 尝试方式1：根据文件后缀名查询UTD类型
  try {
    utdTypeId = utd.getUniformDataTypeByFilenameExtension(filenameExtension, utd.UniformDataType.FILE);
  } catch (error) {
    console.warn('Failed to query UTD by filename extension, using fallback');
  }

  // 降级方案1：如果查询失败，使用FILE基类型
  if (!utdTypeId) {
    utdTypeId = utd.UniformDataType.FILE;
    console.warn('Using fallback UTD type: FILE');
  }

  // 尝试创建分享数据
  let shareData: systemShare.SharedData | null = null;
  try {
    shareData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: uri
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to create share data: ${err.message}`);
    // 降级方案2：提示用户手动分享
    console.warn('Please share the file manually');
    return;
  }

  // 尝试显示分享面板
  try {
    const controller = new systemShare.ShareController(shareData);
    await controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to show share panel: ${err.message}`);
    // 降级方案3：提示用户分享失败
    console.warn('Share failed, please try again later');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误。 | 检查所有必填参数是否正确传入，确保参数类型符合API要求。 |
| 1003700001 | 分享数据记录数量超过最大限制（500条）。 | 减少分享数据记录数量，确保不超过500条。可分批分享或筛选重要数据。 |
| 1003702001 | 数据记录类型不支持。批量模式和多项选择模式仅支持FILE类型记录。 | 检查数据类型是否为FILE类型，或切换到单选模式。 |
| 1003702002 | IPC数据大小超过限制（200KB）。 | 减少分享数据总大小，压缩图片或文本内容，或分批分享。 |
| 1003703001 | 解析数据失败。 | 检查分享数据格式是否正确，确保uri、content等字段符合规范。 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ArkData": "API version 10+",
    "@kit.ShareKit": "API version 11+",
    "@kit.AbilityKit": "API version 11+",
    "@kit.BasicServicesKit": "API version 11+"
  }
}
```

### 环境要求
- **HarmonyOS API**：最低API version 10（uniformTypeDescriptor），推荐API version 11+
- **模型约束**：仅支持Stage模型
- **系统能力**：SystemCapability.DistributedDataManager.UDMF.Core, SystemCapability.Collaboration.SystemShare
- **开发环境**：DevEco Studio 3.1+

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ShareKit' or its corresponding type declarations.
```
**解决方法**：确保HarmonyOS SDK版本不低于API version 11，在项目配置中添加必要的Kit依赖。

**问题2：类型定义错误**
```
Error: Property 'UniformDataType' does not exist on type 'typeof uniformTypeDescriptor'.
```
**解决方法**：检查导入语句是否正确，确保使用`import { uniformTypeDescriptor as utd } from '@kit.ArkData'`。

**问题3：上下文对象获取失败**
```
Error: Cannot read property 'getHostContext' of undefined.
```
**解决方法**：确保在UI组件中调用`this.getUIContext()`，检查UIAbilityContext是否正确初始化。

**问题4：分享面板显示失败**
```
Error: ShareController show error. code: 1003702002, message: IPC data is oversized.
```
**解决方法**：减少分享数据大小，压缩缩略图，确保数据总大小不超过200KB。

## 常见问题与解决方法

### Q1：如何选择文件后缀名查询还是MIME类型查询？
**原因**：两种查询方式各有适用场景，需要根据实际需求选择。
**解决方法**：
- **文件后缀名查询**：适用于已知文件扩展名的场景，如分享本地文件、相册图片等。
- **MIME类型查询**：适用于已知内容MIME类型的场景，如网络下载文件、应用生成内容等。
- 如果两种方式都可用，优先使用文件后缀名查询，匹配更精确。

### Q2：查询不到预置的UTD类型怎么办？
**原因**：某些特殊的文件类型或自定义格式可能不在预置UTD类型列表中。
**解决方法**：
- API会根据入参按指定规则生成动态类型，可直接使用返回的动态类型ID。
- 可以使用FILE基类型作为降级方案，虽然匹配精度较低但保证分享功能可用。
- 建议向华为开发者社区提交需求，申请添加新的预置UTD类型。

### Q3：分享数据记录数量超过500条怎么办？
**原因**：IPC传输和数据处理的性能限制，单次分享最大支持500条记录。
**解决方法**：
- 筛选重要数据，减少分享记录数量。
- 分批分享，先分享第一批500条，再分享剩余数据。
- 使用批量模式（SelectionMode.BATCH）提高分享效率。

### Q4：缩略图图片超过32KB导致分享失败怎么办？
**原因**：过大的缩略图会增加IPC数据大小，可能导致数据超限。
**解决方法**：
- 使用ImagePacker.packToData压缩图片质量，降低图片大小。
- 降级使用默认图标或应用图标作为缩略图。
- 省略thumbnail字段，系统会自动使用与分享内容类型匹配的图标。

### Q5：如何监听分享面板关闭事件？
**原因**：需要在分享完成后执行后续操作，如清理数据、更新UI等。
**解决方法**：
```typescript
const controller = new systemShare.ShareController(shareData);
controller.on('dismiss', () => {
  console.info('Share panel closed');
  // 执行后续操作
});
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "utdTypeId": "general.jpeg",
  "shareDataRecords": 1,
  "sharePanelShown": true,
  "apiUsed": [
    "uniformTypeDescriptor.getUniformDataTypeByFilenameExtension",
    "systemShare.SharedData",
    "systemShare.ShareController",
    "ShareController.show"
  ],
  "executionTime": "2.5s",
  "previewMode": "DEFAULT",
  "selectionMode": "SINGLE"
}
```

## 参考文档

- [API开发指南 - 宿主应用发起分享需使用精细化的utd类型](references/share-access-utd.md)
- [API参考说明 - uniformTypeDescriptor](references/js-apis-data-uniformtypedescriptor.md)
- [API参考说明 - systemShare](references/share-system-share.md)

## 完整示例代码

### ArkTS示例1：根据文件后缀名分享图片
参见：[assets/share_image_by_extension.ets](assets/share_image_by_extension.ets)

### ArkTS示例2：根据MIME类型分享文本
参见：[assets/share_text_by_mimetype.ets](assets/share_text_by_mimetype.ets)

### ArkTS示例3：完整分享流程示例
参见：[assets/share_complete_flow.ets](assets/share_complete_flow.ets)

## 测试用例

### 正向测试用例
- [测试用例1：根据jpg文件后缀查询UTD类型](tests/test_positive_1.py)：测试文件后缀名查询功能，验证返回正确的UTD类型ID。
- [测试用例2：根据image/jpeg MIME类型查询UTD类型](tests/test_positive_2.py)：测试MIME类型查询功能，验证返回正确的UTD类型ID。
- [测试用例3：构造分享数据并显示面板](tests/test_positive_3.py)：测试完整的分享流程，验证分享面板正常显示。

### 边界测试用例
- [测试用例1：查询不存在的文件后缀名](tests/test_boundary_1.py)：测试查询不存在类型的处理，验证返回动态类型。
- [测试用例2：构造500条分享数据记录](tests/test_boundary_2.py)：测试最大记录数量限制，验证不超过500条记录。
- [测试用例3：构造接近200KB的分享数据](tests/test_boundary_3.py)：测试数据大小限制，验证不超过200KB。

### 异常测试用例
- [测试用例1：传入空文件后缀名](tests/test_exception_1.py)：测试空参数处理，验证错误码401。
- [测试用例2：传入无效的MIME类型](tests/test_exception_2.py)：测试无效参数处理，验证错误码401。
- [测试用例3：超出500条数据记录限制](tests/test_exception_3.py)：测试超出限制处理，验证错误码1003700001。
- [测试用例4：IPC数据超过200KB](tests/test_exception_4.py)：测试数据超限处理，验证错误码1003702002。