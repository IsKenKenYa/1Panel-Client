# i18n API参考 - 语言与地区名称显示

## getDisplayCountry9+

static getDisplayCountry(country: string, locale: string, sentenceCase?: boolean): string

获取国家地区名称在指定语言下的翻译。

**元服务API：** 从API version 12开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

### 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| country | string | 是 | 国家地区，要求是合法的国家地区码。 |
| locale | string | 是 | 表示区域ID的字符串，由语言、脚本、国家地区组成。 |
| sentenceCase | boolean | 否 | true表示按照首字母大写的格式显示文本，false表示按照区域默认的大小写格式显示文本。默认值：true。 |

### 返回值

| 类型 | 说明 |
| --- | --- |
| string | 国家地区名称在指定语言下的翻译。 |

### 错误码

以下错误码的详细介绍请参见 [ohos.i18n错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-i18n) 和 [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. |
| 890001 | Invalid parameter. Possible causes: Parameter verification failed. |

### 示例

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

try {
  let displayCountry: string = i18n.System.getDisplayCountry('CN', 'en-GB'); // displayCountry = 'China'
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`call System.getDisplayCountry failed, error code: ${err.code}, message: ${err.message}.`);
}
```

## getDisplayLanguage9+

static getDisplayLanguage(language: string, locale: string, sentenceCase?: boolean): string

获取语言名称在指定语言下的翻译。

**元服务API：** 从API version 11开始，该接口支持在元服务中使用。

**系统能力：** SystemCapability.Global.I18n

### 参数

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| language | string | 是 | 语言，要求是合法的语言ID。 |
| locale | string | 是 | 表示区域ID的字符串，由语言、脚本、国家地区组成。 |
| sentenceCase | boolean | 否 | true表示按照首字母大写的格式显示文本，false表示按照区域默认的大小写格式显示文本。默认值：true。 |

### 返回值

| 类型 | 说明 |
| --- | --- |
| string | 语言名称在指定语言下的翻译。 |

### 错误码

以下错误码的详细介绍请参见 [ohos.i18n错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-i18n) 和 [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1.Mandatory parameters are left unspecified; 2.Incorrect parameter types. |
| 890001 | Invalid parameter. Possible causes: Parameter verification failed. |

### 示例

```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

try {
  // 获取"中文"在英文下的翻译
  let displayLanguage: string = i18n.System.getDisplayLanguage('zh', 'en-GB'); // displayLanguage = 'Chinese'
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`call System.getDisplayLanguage failed, error code: ${err.code}, message: ${err.message}.`);
}
```