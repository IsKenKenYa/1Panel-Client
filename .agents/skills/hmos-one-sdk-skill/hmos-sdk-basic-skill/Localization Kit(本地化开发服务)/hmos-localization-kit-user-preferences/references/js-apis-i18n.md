# @ohos.i18n System API参考说明

本文档提取了i18n.System模块中与用户偏好相关的API接口说明。

## 导入模块

```typescript
import { i18n } from '@kit.LocalizationKit';
```

## System9+

提供系统属性相关的能力,包括语言地区名称翻译、支持的语言地区列表获取和系统语言地区获取等。

**元服务API**: 从API version 12开始,该接口支持在元服务中使用。

**系统能力**: SystemCapability.Global.I18n

### is24HourClock9+

static is24HourClock(): boolean

判断系统时制是否为24小时制。若要监听系统时制变化,可以监听公共事件OHOS::EventFwk::CommonEventSupport::COMMON_EVENT_TIME_CHANGED,具体可参考[用户偏好](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-user-preferences)。

**卡片能力**: 从API version 11开始,该接口支持在ArkTS卡片中使用。

**元服务API**: 从API version 12开始,该接口支持在元服务中使用。

**系统能力**: SystemCapability.Global.I18n

**返回值**:

| 类型 | 说明 |
| --- | --- |
| boolean | true表示系统时制为24小时制,false表示系统时制为12小时制。 |

**示例**:
```typescript
import { i18n } from '@kit.LocalizationKit';
let is24HourClock: boolean = i18n.System.is24HourClock(); // 如果系统时制是24小时制,is24HourClock = true
```

### getUsingLocalDigit9+

static getUsingLocalDigit(): boolean

判断系统是否使用本地数字。

**元服务API**: 从API version 12开始,该接口支持在元服务中使用。

**系统能力**: SystemCapability.Global.I18n

**返回值**:

| 类型 | 说明 |
| --- | --- |
| boolean | true表示系统当前使用本地数字,false表示系统当前不使用本地数字。 |

**示例**:
```typescript
import { i18n } from '@kit.LocalizationKit';
let usingLocalDigit: boolean = i18n.System.getUsingLocalDigit();
```

## 相关公共事件

### COMMON_EVENT_TIME_CHANGED

设置系统时间的公共事件的动作。当设置系统时间时,将会触发事件通知服务发布该系统公共事件。

**系统能力**: SystemCapability.Notification.CommonEvent

**订阅者所需权限**: 无

**取值**: "usual.event.TIME_CHANGED"

**说明**: 通过监听此事件可以感知系统时制变化。需要通过事件数据区分系统时间变化和系统时制变化,当data.data == '24HourChange'时表示时制变化。

## 参考文档

- [i18n完整API文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- [公共事件定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)