# productViewManager API参考说明

## removePinShortcut接口

**接口定义**:
```typescript
removePinShortcut(context: common.UIAbilityContext, shortcutId: string): Promise<void>
```

**功能**: 删除桌面快捷方式

**起始版本**: 6.1.1(24)

**模型约束**: 仅可在Stage模型下使用

**系统能力**: SystemCapability.AppGalleryService.Distribution.Recommendations

### 参数说明

| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext) | 是 | 调用方应用的上下文 |
| shortcutId | string | 是 | 快捷方式ID,取值为长度不超过63字节的字符串 |

### 返回值

| 类型 | 说明 |
|------|------|
| Promise<void> | Promise对象,无返回结果的Promise对象 |

### 错误码

| 错误码ID | 错误信息 |
|---------|---------|
| 401 | Parameter error. |
| 1006620001 | System internal error. |
| 1006620006 | The shortcut is not verified or has expired. |
| 1006620007 | User refused to delete shortcut. |

### 设备支持

- Phone
- Tablet
- PC/2in1
- TV (从6.0.2(22)版本开始)

### 使用说明

1. 不支持模拟器,必须使用真机调试
2. 只能删除当前应用创建的快捷方式
3. shortcutId需要通过checkPinShortcutPermitted接口获取
4. 标准删除模式下会弹出系统确认框
5. 申请静默删除权限后可以无需用户确认直接删除

### 示例代码

```typescript
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'RemovePinShortcut';

try {
  const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const shortcutId = 'xxx'; // 通过checkPinShortcutPermitted接口获取
  
  productViewManager.removePinShortcut(uiContext, shortcutId)
    .then(() => {
      hilog.info(0x0001, TAG, 'removePinShortcut success.');
    })
    .catch((error: BusinessError) => {
      hilog.error(0x0001, TAG, `removePinShortcut error. code is ${error.code}, message is ${error.message}`);
    });
} catch (err) {
  hilog.error(0x0001, TAG, `removePinShortcut failed, code is ${err.code}, message is ${err.message}`);
}
```

## 相关接口

- [checkPinShortcutPermitted](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager): 校验快捷方式是否允许加桌
- [requestNewPinShortcut](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager): 创建快捷方式加桌

## 完整API文档

详细API文档请参考: [productViewManager完整API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/store-productviewmanager)