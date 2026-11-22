---
name: hmos-localization-kit-i18n-character-processing
description: 处理不同语言规则下的字符属性判断、文本音译、文本标准化、换行点获取和文件路径镜像,支持Unicode字符分类、中文转拼音、NFC/NFD范式标准化、多语言文本换行和RTL语言路径镜像,适用于国际化应用开发场景
---

# 字符处理技能

## 功能描述

本技能提供HarmonyOS国际化字符处理能力,支持在不同语言规则下以相似逻辑处理文本。包含五大核心功能:
1. **字符属性判断**: 判断字符类别(数字、字母、空格、RTL字符、表意文字等)
2. **文本音译**: 将文本转换为发音相同的另一个文字系统(如中文转拼音)
3. **文本标准化**: 按指定范式(NFC/NFD/NFKC/NFKD)标准化文本
4. **换行点获取**: 根据区域规则获取文本的可换行点
5. **文件路径镜像**: 对镜像语言(RTL)的文件路径进行本地化处理

## 使用场景

### 触发词
- "字符处理" - 字符属性判断和处理
- "字符属性" - 判断字符是否为数字、字母、表意文字等
- "音译" - 文本音译转换(如中文转拼音)
- "文本标准化" - Unicode文本标准化处理
- "换行点" - 获取文本可换行位置
- "路径镜像" - RTL语言文件路径镜像处理
- "i18n字符处理" - 国际化字符处理相关功能
- "Unicode字符" - Unicode字符分类和判断

### 能做
- 判断字符是否为数字、字母、空格、RTL字符、表意文字等Unicode类别
- 获取字符的一般类别值(如U_LOWERCASE_LETTER、U_UPPERCASE_LETTER)
- 将文本音译为目标格式(中文转拼音、去声调、姓氏读音)
- 按NFC/NFD/NFKC/NFKD范式标准化文本
- 根据区域规则获取文本的可换行点位置
- 对镜像语言(如阿拉伯语)的文件路径进行镜像处理

### 绝不做
- 不处理超出字符处理范围的国际化需求(如日期格式化、数字格式化)
- 不提供文本翻译功能(音译不等同于翻译)
- 不处理完整的文本编辑和排版功能
- 不替代系统级的语言区域设置

### 补充
- 音译功能支持中文汉字转拼音,但多音字可能无法按正确发音转换
- 文本标准化范式参考[Unicode标准TR15](https://www.unicode.org/reports/tr15/#Norm_Forms)
- 换行点获取依赖区域规则,不同区域换行规则可能不同
- 文件路径镜像仅对镜像语言(如阿拉伯语、希伯来语)有效

## 调用规范和规则

### 输入约束
- 字符输入: 单个字符或字符串(字符串时只判断首字符)
- 音译文本: 任意文本字符串,长度无限制
- 标准化文本: 任意文本字符串
- 换行文本: 需要计算换行点的文本字符串
- 路径字符串: 合法的文件路径字符串
- 区域ID: 合法的区域ID字符串(如zh-Hans-CN、en-US、ar-EG)

### 执行约束
- 字符判断: 立即返回结果,无异步操作
- 音译转换: 支持实时转换,无超时限制
- 标准化处理: 立即返回结果,无异步操作
- 换行点计算: 需先设置文本,再迭代计算换行点
- 路径镜像: 需传入区域对象,立即返回结果

### 内容约束
- 禁止生成: 禁止生成虚假API或推测API参数
- 禁止高危函数: 不使用eval、exec等高危函数
- 错误处理: 必须使用try-catch捕获异常,处理错误码401和890001

### 降级约束
- 字符判断失败: 返回false或默认值
- 音译失败: 返回原文本或空字符串
- 标准化失败: 返回原文本
- 换行点获取失败: 返回-1或空文本
- 路径镜像失败: 返回原路径或抛出异常

## 调用流程和步骤

### 步骤1: 导入模块

**前置校验**:
1. 确认项目支持HarmonyOS API version 7及以上
2. 确认已安装@kit.LocalizationKit模块

**模块导入**:
```typescript
import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2: 字符属性判断

**功能说明**: 判断字符的Unicode类别属性

**示例代码**:
```typescript
// 判断字符是否是数字
function checkDigitExample(): void {
  try {
    let isDigit: boolean = i18n.Unicode.isDigit('1'); // isDigit = true
    console.log(`字符'1'是否为数字: ${isDigit}`);
    
    isDigit = i18n.Unicode.isDigit('a'); // isDigit = false
    console.log(`字符'a'是否为数字: ${isDigit}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`判断数字失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 判断字符是否是从右到左语言的字符
function checkRTLExample(): void {
  try {
    let isRTL: boolean = i18n.Unicode.isRTL('a'); // isRTL = false
    console.log(`字符'a'是否为RTL字符: ${isRTL}`);
    
    // 阿拉伯语字符示例
    isRTL = i18n.Unicode.isRTL('ا'); // isRTL = true
    console.log(`阿拉伯语字符是否为RTL字符: ${isRTL}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`判断RTL字符失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 判断字符是否是表意文字(中文日文韩文)
function checkIdeographExample(): void {
  try {
    let isIdeograph: boolean = i18n.Unicode.isIdeograph('华'); // isIdeograph = true
    console.log(`字符'华'是否为表意文字: ${isIdeograph}`);
    
    isIdeograph = i18n.Unicode.isIdeograph('a'); // isIdeograph = false
    console.log(`字符'a'是否为表意文字: ${isIdeograph}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`判断表意文字失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 获取字符的一般类别值
function getUnicodeTypeExample(): void {
  try {
    let unicodeType: string = i18n.Unicode.getType('a'); // unicodeType = 'U_LOWERCASE_LETTER'
    console.log(`字符'a'的Unicode类别: ${unicodeType}`);
    
    unicodeType = i18n.Unicode.getType('A'); // unicodeType = 'U_UPPERCASE_LETTER'
    console.log(`字符'A'的Unicode类别: ${unicodeType}`);
    
    unicodeType = i18n.Unicode.getType('1'); // unicodeType = 'U_DECIMAL_DIGIT_NUMBER'
    console.log(`字符'1'的Unicode类别: ${unicodeType}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`获取Unicode类别失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 其他字符属性判断示例
function otherCharacterChecks(): void {
  try {
    // 判断是否为空格符
    let isSpaceChar: boolean = i18n.Unicode.isSpaceChar(' '); // true
    
    // 判断是否为空白符
    let isWhitespace: boolean = i18n.Unicode.isWhitespace('\t'); // true
    
    // 判断是否为字母
    let isLetter: boolean = i18n.Unicode.isLetter('a'); // true
    
    // 判断是否为小写字母
    let isLowerCase: boolean = i18n.Unicode.isLowerCase('a'); // true
    
    // 判断是否为大写字母
    let isUpperCase: boolean = i18n.Unicode.isUpperCase('A'); // true
    
    console.log(`空格符: ${isSpaceChar}, 空白符: ${isWhitespace}, 字母: ${isLetter}`);
    console.log(`小写字母: ${isLowerCase}, 大写字母: ${isUpperCase}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`字符属性判断失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}
```

### 步骤3: 文本音译

**功能说明**: 将文本转换为发音相同的另一个文字系统

**示例代码**:
```typescript
// 音译成Latn格式(带声调)
function transliterateToLatn(): void {
  try {
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
    let translatedText: string = transliterator.transform('中国'); // translatedText = 'zhōng guó'
    console.log(`'中国'音译为: ${translatedText}`);
    
    translatedText = transliterator.transform('美国'); // translatedText = 'měi guó'
    console.log(`'美国'音译为: ${translatedText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 汉语音译去声调
function transliterateWithoutTone(): void {
  try {
    let toneLessTransliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn;Latin-Ascii');
    let toneLessTranslatedText: string = toneLessTransliterator.transform('中国'); // toneLessTranslatedText = 'zhong guo'
    console.log(`'中国'去声调音译为: ${toneLessTranslatedText}`);
    
    toneLessTranslatedText = toneLessTransliterator.transform('德国'); // toneLessTranslatedText = 'de guo'
    console.log(`'德国'去声调音译为: ${toneLessTranslatedText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`去声调音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 汉语姓氏读音(特殊多音字处理)
function transliterateNames(): void {
  try {
    let nameTransliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Han-Latin/Names');
    let nameTranslatedText: string = nameTransliterator.transform('单老师'); // nameTranslatedText = 'shàn lǎo shī'
    console.log(`'单老师'姓氏读音音译为: ${nameTranslatedText}`);
    
    nameTranslatedText = nameTransliterator.transform('长孙无忌'); // nameTranslatedText = 'zhǎng sūn wú jì'
    console.log(`'长孙无忌'姓氏读音音译为: ${nameTranslatedText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`姓氏读音音译失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 获取音译支持的转换ID列表
function getAvailableTransliteratorIDs(): void {
  try {
    let ids: string[] = i18n.Transliterator.getAvailableIDs();
    console.log(`音译支持的转换ID数量: ${ids.length}`);
    console.log(`示例ID: ${ids.slice(0, 5).join(', ')}`);
    // ids = ['ASCII-Latin', 'Accents-Any', 'Amharic-Latin/BGN', 'Any-Latn', ...]
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`获取音译ID列表失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}
```

### 步骤4: 文本标准化

**功能说明**: 按指定范式标准化文本

**示例代码**:
```typescript
// 按照NFC范式对文本进行标准化处理
function normalizeWithNFC(): void {
  try {
    let normalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
    let normalizedText: string = normalizer.normalize('\u1E9B\u0323'); // normalizedText = 'ẛ̣'
    console.log(`NFC标准化结果: ${normalizedText}`);
    
    // 对比原始文本和标准化文本
    let originalText: string = '\u1E9B\u0323';
    console.log(`原始文本: ${originalText}, 标准化文本: ${normalizedText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`NFC标准化失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 使用不同的标准化范式
function normalizeWithDifferentModes(): void {
  try {
    let text: string = '\u1E9B\u0323';
    
    // NFC范式
    let nfcNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
    let nfcText: string = nfcNormalizer.normalize(text);
    console.log(`NFC: ${nfcText}`);
    
    // NFD范式
    let nfdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFD);
    let nfdText: string = nfdNormalizer.normalize(text);
    console.log(`NFD: ${nfdText}`);
    
    // NFKC范式
    let nfkcNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKC);
    let nfkcText: string = nfkcNormalizer.normalize(text);
    console.log(`NFKC: ${nfkcText}`);
    
    // NFKD范式
    let nfkdNormalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKD);
    let nfkdText: string = nfkdNormalizer.normalize(text);
    console.log(`NFKD: ${nfkdText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`标准化失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}
```

### 步骤5: 获取文本的可换行点

**功能说明**: 根据区域规则获取文本的可换行点

**示例代码**:
```typescript
// 创建获取文本可换行点的对象
function createBreakIterator(): void {
  try {
    // 创建BreakIterator对象,按照en-GB区域规则
    let iterator: i18n.BreakIterator = i18n.getLineInstance('en-GB');
    
    // 设置处理文本
    iterator.setLineBreakText('Apple is my favorite fruit.');
    
    // 将换行迭代器移动到文本起始位置
    let firstPos: number = iterator.first(); // firstPos = 0
    console.log(`起始位置: ${firstPos}`);
    
    // 将换行迭代器向后移动2个可换行点
    let nextPos: number = iterator.next(2); // nextPos = 9
    console.log(`移动2个换行点后的位置: ${nextPos}`);
    
    // 获取换行迭代器当前位置
    let currentPos: number = iterator.current(); // currentPos = 9
    console.log(`当前位置: ${currentPos}`);
    
    // 判断某个位置是否是可换行点
    let isBoundary: boolean = iterator.isBoundary(9); // isBoundary = true
    console.log(`位置9是否为换行点: ${isBoundary}`);
    
    // 获取BreakIterator对象处理的文本
    let breakText: string = iterator.getLineBreakText();
    console.log(`处理的文本: ${breakText}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`换行点获取失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 完整的换行点遍历示例
function traverseLineBreaks(): void {
  try {
    let iterator: i18n.BreakIterator = i18n.getLineInstance('zh-CN');
    iterator.setLineBreakText('这是一个中文文本换行示例。我们需要找到所有的换行点。');
    
    let pos: number = iterator.first();
    console.log(`起始位置: ${pos}`);
    
    // 遍历所有换行点
    while (pos !== -1) {
      pos = iterator.next();
      if (pos !== -1) {
        console.log(`换行点位置: ${pos}`);
      }
    }
    
    // 移动到上一个换行点
    pos = iterator.previous();
    console.log(`上一个换行点: ${pos}`);
    
    // 移动到最后一个换行点
    pos = iterator.last();
    console.log(`最后一个换行点: ${pos}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`换行点遍历失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}
```

### 步骤6: 文件路径镜像处理

**功能说明**: 对镜像语言的文件路径进行本地化处理

**示例代码**:
```typescript
// 文件路径镜像处理(RTL语言)
function mirrorFilePath(): void {
  try {
    let mirrorPath: string = '';
    let unMirrorPath: string = '';
    
    // 传入镜像语言,对路径进行镜像处理
    let path: string = 'data/out/tmp';
    let delimiter: string = '/';
    
    // 阿拉伯语(镜像语言)
    let localeAr: Intl.Locale = new Intl.Locale('ar');
    mirrorPath = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeAr);
    // mirrorPath = 'tmp/out/data/' (显示为镜像格式)
    console.log(`阿拉伯语路径镜像: ${mirrorPath}`);
    
    // 中文(非镜像语言)
    let localeZh: Intl.Locale = new Intl.Locale('zh');
    unMirrorPath = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeZh);
    // unMirrorPath = '/data/out/tmp' (不处理路径)
    console.log(`中文路径: ${unMirrorPath}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`路径镜像处理失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 不同分隔符的路径镜像
function mirrorFilePathWithDifferentDelimiter(): void {
  try {
    // 使用反斜杠作为分隔符
    let path: string = 'data\\out\\tmp';
    let delimiter: string = '\\';
    let localeAr: Intl.Locale = new Intl.Locale('ar');
    
    let mirrorPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeAr);
    console.log(`反斜杠分隔符路径镜像: ${mirrorPath}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`路径镜像失败, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}
```

### 步骤7: 错误处理

**错误处理代码**:
```typescript
// 统一错误处理函数
function handleI18nError(error: unknown, operation: string): void {
  let err: BusinessError = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error(`${operation}失败: 参数错误。可能原因: 1.必填参数未指定; 2.参数类型错误`);
      break;
    case 890001:
      console.error(`${operation}失败: 参数无效。可能原因: 参数验证失败`);
      break;
    default:
      console.error(`${operation}失败: 未知错误, 错误码: ${err.code}, 消息: ${err.message}`);
  }
}

// 使用错误处理的示例
function safeCharacterProcessing(): void {
  try {
    let isDigit: boolean = i18n.Unicode.isDigit('1');
    console.log(`字符判断结果: ${isDigit}`);
  } catch (error) {
    handleI18nError(error, '字符属性判断');
  }
  
  try {
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
    let result: string = transliterator.transform('中国');
    console.log(`音译结果: ${result}`);
  } catch (error) {
    handleI18nError(error, '文本音译');
  }
}
```

### 步骤8: 降级处理

**降级处理代码**:
```typescript
// 字符判断降级处理
function safeCheckDigit(ch: string): boolean {
  try {
    return i18n.Unicode.isDigit(ch);
  } catch (error) {
    console.warn(`字符判断失败, 返回默认值false`);
    return false;
  }
}

// 音译降级处理
function safeTransliterate(text: string, id: string): string {
  try {
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance(id);
    return transliterator.transform(text);
  } catch (error) {
    console.warn(`音译失败, 返回原文本`);
    return text;
  }
}

// 标准化降级处理
function safeNormalize(text: string, mode: i18n.NormalizerMode): string {
  try {
    let normalizer: i18n.Normalizer = i18n.Normalizer.getInstance(mode);
    return normalizer.normalize(text);
  } catch (error) {
    console.warn(`标准化失败, 返回原文本`);
    return text;
  }
}

// 换行点获取降级处理
function safeGetLineBreaks(text: string, locale: string): number[] {
  try {
    let iterator: i18n.BreakIterator = i18n.getLineInstance(locale);
    iterator.setLineBreakText(text);
    
    let breakPoints: number[] = [];
    let pos: number = iterator.first();
    
    while (pos !== -1) {
      breakPoints.push(pos);
      pos = iterator.next();
    }
    
    return breakPoints;
  } catch (error) {
    console.warn(`换行点获取失败, 返回空数组`);
    return [];
  }
}

// 路径镜像降级处理
function safeMirrorPath(path: string, delimiter: string, locale: Intl.Locale): string {
  try {
    return i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, locale);
  } catch (error) {
    console.warn(`路径镜像失败, 返回原路径`);
    return path;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因: 1.必填参数未指定; 2.参数类型错误 | 检查参数是否正确传入,确认参数类型符合要求 |
| 890001 | 参数无效。可能原因: 参数验证失败 | 检查参数值是否符合规范,如区域ID格式、音译ID是否支持 |
| -1 | 换行迭代器移动超出文本范围 | 检查移动步数是否超出文本长度范围 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.LocalizationKit": "HarmonyOS API version 7+"
  }
}
```

### 环境要求
- HarmonyOS API version: 7及以上(首批接口)
- 部分API需要更高版本:
  - Unicode类: API version 9+
  - Normalizer类: API version 10+
  - BreakIterator类: API version 8+
  - I18NUtil.getUnicodeWrappedFilePath: API version 18+ (废弃),推荐使用API version 20+
  - Transliterator类: API version 9+

### 常见编译问题

**问题1: 模块导入错误**
```
Error: Cannot find module '@kit.LocalizationKit'
```
**解决方法**: 确认HarmonyOS项目配置正确,API version >= 7

**问题2: API不存在错误**
```
Error: Property 'Unicode' does not exist on type 'i18n'
```
**解决方法**: 确认API version >= 9才能使用Unicode类

**问题3: 区域ID格式错误**
```
Error: Invalid locale format
```
**解决方法**: 使用正确的区域ID格式,如zh-Hans-CN、en-US、ar-EG

**问题4: 音译ID不支持**
```
Error: Invalid transliterator ID
```
**解决方法**: 使用getAvailableIDs()查询支持的音译ID列表

## 常见问题与解决方法

### Q1: 多音字音译结果不正确
**原因**: 音译功能对多音字的处理可能不准确
**解决方法**:
- 使用'Han-Latin/Names'音译ID处理姓氏读音
- 手动标注多音字的正确读音
- 结合上下文进行多音字判断

### Q2: 换行点获取结果不符合预期
**原因**: 不同区域的换行规则不同
**解决方法**:
- 使用正确的区域ID创建BreakIterator
- 理解区域换行规则的差异
- 使用isBoundary()判断具体位置是否为换行点

### Q3: 文本标准化后显示异常
**原因**: Unicode字符组合和分解的差异
**解决方法**:
- 理解NFC/NFD/NFKC/NFKD范式的区别
- 根据应用场景选择合适的标准化范式
- NFC适合显示,NFD适合内部处理

### Q4: 文件路径镜像处理无效
**原因**: 非镜像语言不进行路径镜像
**解决方法**:
- 确认语言是否为镜像语言(如阿拉伯语、希伯来语)
- 使用i18n.isRTL()判断语言是否为RTL语言
- 传入正确的区域对象

### Q5: API调用返回异常
**原因**: API version不满足要求
**解决方法**:
- 检查项目API version配置
- 查阅API文档确认最低API version要求
- 升级项目API version或使用替代API

## 输出结果报告

执行字符处理功能完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "character_processing",
  "function": "具体功能名称",
  "input": {
    "text": "输入文本或字符",
    "locale": "区域ID(如适用)"
  },
  "output": {
    "result": "处理结果",
    "type": "结果类型(boolean/string/number/array)"
  },
  "apiUsed": [
    "i18n.Unicode.isDigit",
    "i18n.Transliterator.transform",
    "i18n.Normalizer.normalize",
    "i18n.BreakIterator.getLineBreakText",
    "i18n.I18NUtil.getUnicodeWrappedFilePath"
  ]
}
```

## 参考文档

- [API开发指南 - 字符处理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/i18n-character-processing)
- [API参考说明 - @ohos.i18n](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n)
- [Unicode标准化TR15](https://www.unicode.org/reports/tr15/#Norm_Forms)
- [Unicode日期字段符号表](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table)

## 完整示例代码

- [ArkTS字符处理示例](assets/character_processing_example.ets)
- [字符属性判断示例](assets/character_properties.ets)
- [文本音译示例](assets/transliteration_example.ets)
- [文本标准化示例](assets/normalization_example.ets)
- [换行点获取示例](assets/line_break_example.ets)
- [路径镜像示例](assets/path_mirror_example.ets)

## 测试用例

### 正向测试用例
- [字符属性判断测试](tests/test_character_properties.py): 测试各种Unicode字符的正确分类
- [音译转换测试](tests/test_transliteration.py): 测试中文转拼音、去声调等功能
- [标准化处理测试](tests/test_normalization.py): 测试NFC/NFD范式标准化
- [换行点获取测试](tests/test_line_break.py): 测试不同区域的换行点计算
- [路径镜像测试](tests/test_path_mirror.py): 测试RTL语言的路径镜像处理

### 边界测试用例
- [空字符串处理](tests/test_empty_string.py): 测试空字符串输入的处理
- [特殊字符处理](tests/test_special_chars.py): 测试特殊Unicode字符的处理
- [长文本处理](tests/test_long_text.py): 测试超长文本的性能和正确性

### 异常测试用例
- [无效区域ID](tests/test_invalid_locale.py): 测试传入无效区域ID的错误处理
- [不支持音译ID](tests/test_invalid_transliterator_id.py): 测试传入不支持的音译ID
- [参数类型错误](tests/test_invalid_params.py): 测试传入错误类型参数的处理