# systemShare API参考摘要

本文档提取了systemShare模块中与获取分享结果相关的核心API定义。

## ShareController.on('shareCompleted')

### API定义
```typescript
on(type: 'shareCompleted', callback: Callback<ShareOperationResult>): void
```

### 功能说明
注册用户完成分享事件监听。返回用户分享渠道,可用于数据统计等。

### 参数
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 事件回调类型,支持的事件为'shareCompleted',当用户完成分享时,触发该事件。 |
| callback | Callback<ShareOperationResult> | 是 | 事件回调。 |

### 返回值
无

### 系统能力
SystemCapability.Collaboration.SystemShare

### 模型约束
此接口仅可在Stage模型下使用。

### 设备行为差异
该接口在TV中无效果,在其他设备类型中可正常调用。

### 起始版本
5.1.0(18)

### 错误码
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |

### 示例
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
let data: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});
let controller: systemShare.ShareController = new systemShare.ShareController(data);
controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
  console.info('shareCompleted name:', result.targetAbilityInfo.name);
});
```

## ShareOperationResult

### 数据结构定义
shareCompleted事件的返回值,用于获知用户分享渠道信息。

### 属性
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| targetAbilityInfo | ShareAbilityInfo | 是 | 否 | 用户分享渠道的信息。 |

### 系统能力
SystemCapability.Collaboration.SystemShare

### 模型约束
此接口仅可在Stage模型下使用。

### 起始版本
5.1.0(18)

## ShareAbilityInfo

### 数据结构定义
用户分享渠道的信息。

### 属性
| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| name | string | 否 | 否 | 分享渠道的名称。系统操作有固定名称。请参见: ShareAbilityName。非系统操作采用'[bundleName]#[moduleName]#[abilityName]'格式拼接。 |

### 系统能力
SystemCapability.Collaboration.SystemShare

### 模型约束
此接口仅可在Stage模型下使用。

### 起始版本
5.1.0(18)

## ShareAbilityName

### 数据结构定义
系统操作的名称,用于返回分享结果数据。

### 枚举值
| 名称 | 值 | 说明 |
| --- | --- | --- |
| COPY_TO_PASTEBOARD | SystemShare_CopyToPasteboard | 复制 |
| SAVE_TO_MEDIA_ASSET | SystemShare_SaveToMediaAsset | 保存至图库 |
| SAVE_AS_FILE | SystemShare_SaveAsFile | 另存为 |
| PRINT | SystemShare_Print | 打印 |
| SAVE_TO_SUPERHUB | SystemShare_Superhub | 添加至中转站 |
| COLLECTION | SystemShare_Collection | 小艺知识空间 |
| HARMONYSHARE | SystemShare_HarmonyShare | 华为分享 |
| ENCRYPT | SystemShare_Encrypt | 加密分享 |

### 系统能力
SystemCapability.Collaboration.SystemShare

### 模型约束
此接口仅可在Stage模型下使用。

### 起始版本
5.1.0(18)

## ShareController.off('shareCompleted')

### API定义
```typescript
off(type: 'shareCompleted', callback?: Callback<ShareOperationResult>): void
```

### 功能说明
取消用户完成分享事件监听。

### 参数
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| type | string | 是 | 事件回调类型,支持的事件为'shareCompleted',取消触发该事件。 |
| callback | Callback<ShareOperationResult> | 否 | 回调函数。可以指定传入on中的callback取消对应的监听,也可以不指定callback清空所有监听。 |

### 返回值
无

### 系统能力
SystemCapability.Collaboration.SystemShare

### 模型约束
此接口仅可在Stage模型下使用。

### 设备行为差异
该接口在TV中无效果,在其他设备类型中可正常调用。

### 起始版本
5.1.0(18)

### 错误码
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |

### 示例
```typescript
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
let data: systemShare.SharedData = new systemShare.SharedData({
  utd: utd.UniformDataType.PLAIN_TEXT,
  content: 'Hello HarmonyOS'
});
let controller: systemShare.ShareController = new systemShare.ShareController(data);
let callback = (result: systemShare.ShareOperationResult) => {
  console.info('shareCompleted name:', result.targetAbilityInfo.name);
};
controller.on('shareCompleted', callback);
controller.off('shareCompleted', callback);
```

## 完整API文档链接

完整的systemShare API文档请参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share