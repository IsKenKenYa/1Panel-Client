# systemShare（分享）
---
# systemShare（分享）
本模块提供分享数据创建及分享面板拉起的功能，提供多种系统标准分享服务，例如分享数据给其他应用、复制、打印等。
- 分享接入应用需要配置、呈现和关闭分享面板。
- 分享面板的配置包括数据对象、呈现视图的方式、预览模式等。
**模型约束：** 此模块的接口仅可在Stage模型下使用。
**起始版本：** 4.1.0(11)
#### 导入模块
```typescript
import { systemShare } from '@kit.ShareKit';
```
#### ShareAbilityResultCode
从UIExtensionAbility返回的Code值。可控制分享面板的行为。
**模型约束：** 此接口仅可在Stage模型下使用。
**系统能力：** SystemCapability.Collaboration.SystemShare
**起始版本：** 5.0.0(12)
| 名称 | 值 | 说明 |
| --- | --- | --- |
| ERROR | -1 | 发生错误。如果同时传递message参数，将弹出toast提示。 |
| BACK | 0 | 用户点击返回按钮。返回分享面板。 |
| CLOSE | 1 | 用户点击关闭按钮。关闭分享面板。 |