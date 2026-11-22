# @ohos.i18n (国际化-I18n) - System接口参考

## System9+

提供系统属性相关的能力，包括语言地区名称翻译、支持的语言地区列表获取和系统语言地区获取等。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

## getSystemLanguage9+

static getSystemLanguage(): string

获取系统当前设置的语言。若要监听系统语言变化，可以监听公共事件OHOS::EventFwk::CommonEventSupport::COMMON_EVENT_LOCALE_CHANGED。

**元服务API：** 从API version 11开始，该接口支持在元服务中使用。

**卡片能力**：从API version 11开始，该接口支持在ArkTS卡片中使用。

**系统能力：** SystemCapability.Global.I18n

**返回值：**

| 类型 | 说明 |
| --- | --- |
| string | 表示语言ID的字符串。 |

**示例：**

```typescript
import { i18n } from '@kit.LocalizationKit';
let systemLanguage: string = i18n.System.getSystemLanguage(); // 如果系统语言为简体中文，systemLanguage = 'zh-Hans'
```

## getSystemRegion9+

static getSystemRegion(): string

获取系统当前设置的国家地区。若要监听系统地区变化，可以监听公共事件OHOS::EventFwk::CommonEventSupport::COMMON_EVENT_LOCALE_CHANGED。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

**返回值：**

| 类型 | 说明 |
| --- | --- |
| string | 表示国家地区ID的字符串。 |

**示例：**

```typescript
import { i18n } from '@kit.LocalizationKit';
let systemRegion: string = i18n.System.getSystemRegion(); // 如果系统地区为中国，systemRegion = 'CN'
```

## getSystemLocaleInstance20+

static getSystemLocaleInstance(): Intl.Locale

获取系统当前设置的区域对象。若要监听系统区域变化，可以监听公共事件OHOS::EventFwk::CommonEventSupport::COMMON_EVENT_LOCALE_CHANGED。

**元服务API：** 从API version 20开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

**返回值：**

| 类型 | 说明 |
| --- | --- |
| [Intl.Locale](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale) | 系统区域对象。 |

**示例：**

```typescript
import { i18n } from '@kit.LocalizationKit';
let systemLocale: Intl.Locale = i18n.System.getSystemLocaleInstance();
```

## getSystemLanguages9+

static getSystemLanguages(): Array<string>

获取系统支持的语言列表。

从API version 11开始，该类型支持在ArkTS卡片中使用。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

**返回值：**

| 类型 | 说明 |
| --- | --- |
| Array<string> | 系统支持的语言列表。 |

**示例：**

```typescript
import { i18n } from '@kit.LocalizationKit';
// systemLanguages = [ 'ug', 'bo', 'zh-Hant', 'en-Latn-US', 'zh-Hans' ]
let systemLanguages: Array<string> = i18n.System.getSystemLanguages();
```

## getSystemCountries9+

static getSystemCountries(language: string): Array<string>

获取输入语言下系统支持的国家地区列表。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

**参数：**

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| language | string | 是 | 合法的语言ID。 |

**返回值：**

| 类型 | 说明 |
| --- | --- |
| Array<string> | 某种特定语言下系统支持的国家地区列表。 |

**错误码：**

以下错误码的详细介绍请参见ohos.i18n错误码和通用错误码。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. |
| 890001 | Invalid parameter. Possible causes: Parameter verification failed. |

**示例：**

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
try {
  // systemCountries = [ 'ZW', 'YT', 'YE', ..., 'ER', 'CN', 'DE' ]
  let systemCountries: Array<string> = i18n.System.getSystemCountries('zh');
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`call System.getSystemCountries failed, error code: ${err.code}, message: ${err.message}.`);
}
```

## isSuggested9+

static isSuggested(language: string, region?: string): boolean

判断语言是否是地区的推荐语言。用于根据地区推荐语言或根据语言推荐地区。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

**参数：**

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| language | string | 是 | 合法的语言ID，例如zh。 |
| region | string | 否 | 合法的国家地区码，例如CN。默认值：SIM卡国家地区。 |

**返回值：**

| 类型 | 说明 |
| --- | --- |
| boolean | true表示语言是地区的推荐语言，false表示语言不是地区的推荐语言。 |

**错误码：**

以下错误码的详细介绍请参见ohos.i18n错误码和通用错误码。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. |
| 890001 | Invalid parameter. Possible causes: Parameter verification failed. |

**示例：**

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
try {
  let isSuggestedCountry: boolean = i18n.System.isSuggested('zh', 'CN'); // isSuggestedCountry = true
  isSuggestedCountry = i18n.System.isSuggested('en'); // 结果和系统当前地区相关
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`call System.isSuggested failed, error code: ${err.code}, message: ${err.message}.`);
}
```

## 参考链接

- [完整API参考文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- [Intl.Locale对象说明](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale)
- [区域ID与文化习惯划分](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-locale-culture)