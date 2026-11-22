# FormExtensionAbility API 参考

## API概述

FormExtensionAbility为卡片扩展模块，提供卡片创建、销毁、刷新等生命周期回调。

## 导入模块

```typescript
import { FormExtensionAbility } from '@kit.FormKit';
```

## API版本

- 首批接口从API version 9开始支持
- 元服务API：从API version 11开始支持

## 主要生命周期回调

### onAddForm
卡片创建时回调，返回卡片要显示的数据。

### onUpdateForm
卡片更新时回调，获取最新数据并刷新卡片。

### onRemoveForm
卡片销毁时回调，清理卡片相关资源。

### onFormEvent
卡片事件处理回调，处理卡片的自定义事件。

### onChangeFormVisibility
卡片可见性变化回调（仅系统应用）。

### onConfigurationUpdate
系统配置变更回调（如语言、颜色模式变化）。

### onAcquireFormState
卡片状态查询回调（可选）。

### onStop
卡片进程退出回调（API version 12+）。

### onFormLocationChanged
卡片位置变化回调（API version 20+）。

### onSizeChanged
卡片尺寸变化回调（API version 20+）。

## 重要注意事项

1. FormExtensionAbility创建后10秒内无操作将会被清理
2. 不支持引用以下模块：
   - @ohos.ability.particleAbility
   - @ohos.multimedia.audio
   - @ohos.multimedia.camera
   - @ohos.multimedia.media
   - @ohos.resourceschedule.backgroundTaskManager

## 完整API文档链接

详细API文档请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formextensionability