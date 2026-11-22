# 参考文档

## API开发指南

本技能的开发指南文档来自HarmonyOS官方文档：

- **原始文档**：[字符处理开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-character-processing)
- **本地备份**：i18n-character-processing-guide.md（当前目录）

## API参考说明

本技能使用的API来自@ohos.i18n模块，详细API说明请参考：

- **官方文档**：[js-apis-i18n API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- **本地备份**：js-apis-i18n.md（harmonyos-references目录）

## 相关标准

### Unicode标准化

文本标准化功能基于Unicode TR15标准：

- **Unicode标准化报告**：[Unicode Normalization Forms](https://www.unicode.org/reports/tr15/#Norm_Forms)

### 音译标准

音译功能基于ISO-15924和CLDR标准：

- **ISO-15924**：Script codes for the representation of names of scripts
- **CLDR**：Common Locale Data Repository

## API版本信息

| API功能 | 起始版本 | 说明 |
|---------|---------|------|
| BreakIterator | API version 8+ | 文本换行点处理 |
| Unicode | API version 9+ | 字符属性判断 |
| Transliterator | API version 9+ | 文本音译转换 |
| I18NUtil | API version 9+ | 国际化工具类 |
| Normalizer | API version 10+ | 文本标准化 |
| NormalizerMode | API version 10+ | 标准化范式枚举 |
| getUnicodeWrappedFilePath | API version 20+ | 路径镜像处理新版本 |

## Kit信息

- **Kit名称**：Localization Kit（本地化开发服务）
- **导入路径**：`@kit.LocalizationKit`
- **系统能力**：SystemCapability.Global.I18n

## 使用限制

1. **音译多音字**：中文多音字可能无法完全准确识别，建议手动校验结果
2. **文本长度**：超长文本可能影响性能，建议不超过50000字符
3. **API版本兼容**：注意各API的起始版本，确保设备SDK版本满足要求
4. **区域ID格式**：必须使用合法的区域ID字符串格式（如'zh-CN', 'en-GB'）

## 术语说明

- **音译(Transliteration)**：将文本从一种文字系统转换为发音相同的另一种文字系统，不等同于翻译
- **标准化(Normalization)**：按照Unicode范式规范化文本，消除不同表示形式的差异
- **表意文字(Ideograph)**：主要指中文、日文、韩文中表示概念或词语的字符
- **RTL(Right-to-Left)**：从右到左书写方向的语言（如阿拉伯语、希伯来语）
- **换行点(Break Point)**：文本中可以换行的位置，根据语言规则确定