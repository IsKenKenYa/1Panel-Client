/**
 * 字符处理完整示例代码
 * 演示i18n模块的字符属性判断、音译、标准化、换行点处理和路径镜像功能
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 字符属性判断示例
 */
export class UnicodeCharacterExample {
  
  /**
   * 判断字符类别
   */
  static checkCharacterProperties(): void {
    console.log('=== 字符属性判断示例 ===');
    
    // 判断是否是数字
    let isDigit: boolean = i18n.Unicode.isDigit('1');
    console.log(`'1' 是数字: ${isDigit}`); // true
    
    let isDigit2: boolean = i18n.Unicode.isDigit('abc');
    console.log(`'abc' 首字符是数字: ${isDigit2}`); // false（只判断'a'）
    
    // 判断是否是空格符
    let isSpaceChar: boolean = i18n.Unicode.isSpaceChar(' ');
    console.log(`空格是空格符: ${isSpaceChar}`); // true
    
    // 判断是否是空白符
    let isWhitespace: boolean = i18n.Unicode.isWhitespace('\t');
    console.log(`Tab是空白符: ${isWhitespace}`); // true
    
    // 判断是否是RTL字符
    let isRTL: boolean = i18n.Unicode.isRTL('ا'); // 阿拉伯字母
    console.log(`阿拉伯字母是RTL字符: ${isRTL}`); // true
    
    // 判断是否是表意文字（中日韩）
    let isIdeograph: boolean = i18n.Unicode.isIdeograph('华');
    console.log(`'华' 是表意文字: ${isIdeograph}`); // true
    
    // 获取字符一般类别值
    let unicodeType: string = i18n.Unicode.getType('a');
    console.log(`'a' 的Unicode类别: ${unicodeType}`); // 'U_LOWERCASE_LETTER'
    
    let unicodeType2: string = i18n.Unicode.getType('A');
    console.log(`'A' 的Unicode类别: ${unicodeType2}`); // 'U_UPPERCASE_LETTER'
    
    let unicodeType3: string = i18n.Unicode.getType('1');
    console.log(`'1' 的Unicode类别: ${unicodeType3}`); // 'U_DECIMAL_DIGIT_NUMBER'
  }
  
  /**
   * 批量判断字符串中所有字符的属性
   */
  static analyzeStringProperties(text: string): void {
    console.log(`\n=== 分析字符串 "${text}" 的字符属性 ===`);
    
    let digitCount: number = 0;
    let letterCount: number = 0;
    let ideographCount: number = 0;
    
    for (let char of text) {
      if (i18n.Unicode.isDigit(char)) {
        digitCount++;
      }
      if (i18n.Unicode.getType(char).includes('LETTER')) {
        letterCount++;
      }
      if (i18n.Unicode.isIdeograph(char)) {
        ideographCount++;
      }
    }
    
    console.log(`数字字符数: ${digitCount}`);
    console.log(`字母字符数: ${letterCount}`);
    console.log(`表意文字数: ${ideographCount}`);
  }
}

/**
 * 文本音译示例
 */
export class TransliterationExample {
  
  /**
   * 基本音译：汉字转拼音（带声调）
   */
  static basicTransliteration(): void {
    console.log('\n=== 基本音译示例 ===');
    
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
    
    let text1: string = '中国';
    let result1: string = transliterator.transform(text1);
    console.log(`"${text1}" -> "${result1}"`); // 'zhōng guó'
    
    let text2: string = '德国';
    let result2: string = transliterator.transform(text2);
    console.log(`"${text2}" -> "${result2}"`); // 'dé guó'
  }
  
  /**
   * 音译去声调
   */
  static transliterationWithoutTone(): void {
    console.log('\n=== 音译去声调示例 ===');
    
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn;Latin-Ascii');
    
    let text: string = '中国美国法国';
    let result: string = transliterator.transform(text);
    console.log(`"${text}" -> "${result}"`); // 'zhong guo mei guo fa guo'
  }
  
  /**
   * 姓氏读音处理
   */
  static nameTransliteration(): void {
    console.log('\n=== 姓氏读音示例 ===');
    
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Han-Latin/Names');
    
    let name1: string = '单老师';
    let result1: string = transliterator.transform(name1);
    console.log(`"${name1}" -> "${result1}"`); // 'shàn lǎo shī'（单姓读音）
    
    let name2: string = '长孙无忌';
    let result2: string = transliterator.transform(name2);
    console.log(`"${name2}" -> "${result2}"`); // 'zhǎng sūn wú jì'（长孙复姓读音）
  }
  
  /**
   * 获取支持的音译ID列表
   */
  static getAvailableIds(): void {
    console.log('\n=== 音译ID列表 ===');
    
    let ids: string[] = i18n.Transliterator.getAvailableIDs();
    console.log(`总共支持 ${ids.length} 个音译转换ID`);
    
    // 显示部分常用ID
    let commonIds: string[] = ['Han-Latin', 'Any-Latn', 'Latin-Ascii', 'Han-Latin/Names'];
    console.log('常用音译ID:');
    commonIds.forEach(id => {
      if (ids.includes(id)) {
        console.log(`  - ${id}`);
      }
    });
  }
  
  /**
   * 批量音译处理
   */
  static batchTransliteration(): void {
    console.log('\n=== 批量音译示例 ===');
    
    let transliterator: i18n.Transliterator = i18n.Transliterator.getInstance('Any-Latn');
    let wordArray: string[] = ['中国', '德国', '美国', '法国', '日本', '韩国'];
    
    console.log('批量音译结果:');
    for (let word of wordArray) {
      let transliterated: string = transliterator.transform(word);
      console.log(`  "${word}" -> "${transliterated}"`);
    }
  }
}

/**
 * 文本标准化示例
 */
export class NormalizationExample {
  
  /**
   * NFC范式标准化
   */
  static nfcNormalization(): void {
    console.log('\n=== NFC标准化示例 ===');
    
    try {
      let normalizer: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
      
      // 示例：组合字符标准化
      let text: string = '\u1E9B\u0323'; // ẛ + ̣
      let normalized: string = normalizer.normalize(text);
      console.log(`原始文本: "${text}"`);
      console.log(`标准化结果: "${normalized}"`); // 'ẛ̣'（预组合形式）
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`标准化失败, 错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  /**
   * 对比四种标准化范式
   */
  static compareNormalizationModes(): void {
    console.log('\n=== 四种范式对比示例 ===');
    
    let text: string = '\u1E9B\u0323';
    
    try {
      // NFC范式
      let normalizerNFC: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFC);
      let nfcResult: string = normalizerNFC.normalize(text);
      console.log(`NFC: "${nfcResult}"`);
      
      // NFD范式
      let normalizerNFD: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFD);
      let nfdResult: string = normalizerNFD.normalize(text);
      console.log(`NFD: "${nfdResult}"`);
      
      // NFKC范式
      let normalizerNFKC: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKC);
      let nfkcResult: string = normalizerNFKC.normalize(text);
      console.log(`NFKC: "${nfkcResult}"`);
      
      // NFKD范式
      let normalizerNFKD: i18n.Normalizer = i18n.Normalizer.getInstance(i18n.NormalizerMode.NFKD);
      let nfkdResult: string = normalizerNFKD.normalize(text);
      console.log(`NFKD: "${nfkdResult}"`);
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`标准化失败, 错误码: ${err.code}`);
    }
  }
}

/**
 * 文本换行点处理示例
 */
export class BreakIteratorExample {
  
  /**
   * 基本换行点迭代
   */
  static basicBreakIterator(): void {
    console.log('\n=== 换行点迭代示例 ===');
    
    let iterator: i18n.BreakIterator = i18n.getLineInstance('en-GB');
    iterator.setLineBreakText('Apple is my favorite fruit.');
    
    // 移动到起始位置
    let firstPos: number = iterator.first();
    console.log(`起始位置: ${firstPos}`); // 0
    
    // 向后移动2个换行点
    let nextPos: number = iterator.next(2);
    console.log(`移动2个换行点后位置: ${nextPos}`); // 9（"Apple is"之后）
    
    // 获取当前位置
    let currentPos: number = iterator.current();
    console.log(`当前位置: ${currentPos}`); // 9
    
    // 判断是否是换行点
    let isBoundary: boolean = iterator.isBoundary(9);
    console.log(`位置9是否是换行点: ${isBoundary}`); // true
    
    // 获取文本
    let breakText: string = iterator.getLineBreakText();
    console.log(`正在处理的文本: "${breakText}"`);
  }
  
  /**
   * 遍历所有换行点
   */
  static iterateAllBreakPoints(): void {
    console.log('\n=== 遍历所有换行点 ===');
    
    let iterator: i18n.BreakIterator = i18n.getLineInstance('zh-CN');
    iterator.setLineBreakText('这是一段测试文本，用于演示换行点的位置。');
    
    let pos: number = iterator.first();
    console.log(`换行点位置: ${pos}`);
    
    while (pos !== -1) {
      pos = iterator.next();
      if (pos !== -1) {
        console.log(`换行点位置: ${pos}`);
      }
    }
    
    console.log('已到达文本末尾');
  }
  
  /**
   * 使用following和previous方法
   */
  static useFollowingAndPrevious(): void {
    console.log('\n=== Following和Previous示例 ===');
    
    let iterator: i18n.BreakIterator = i18n.getLineInstance('en');
    iterator.setLineBreakText('Apple is my favorite fruit.');
    
    // 移动到位置10后的换行点
    let followingPos: number = iterator.following(10);
    console.log(`位置10后的换行点: ${followingPos}`); // 12（"Apple is my"之后）
    
    // 向前移动1个换行点
    let prevPos: number = iterator.previous();
    console.log(`前一个换行点: ${prevPos}`); // 9
  }
}

/**
 * 文件路径镜像处理示例
 */
export class PathMirrorExample {
  
  /**
   * RTL语言路径镜像
   */
  static rtlPathMirror(): void {
    console.log('\n=== 路径镜像示例 ===');
    
    try {
      let path: string = 'data/out/tmp';
      let delimiter: string = '/';
      
      // 阿拉伯语（RTL语言）路径镜像
      let localeAr: Intl.Locale = new Intl.Locale('ar');
      let mirrorPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeAr);
      console.log(`原始路径: "${path}"`);
      console.log(`阿拉伯语镜像路径: "${mirrorPath}"`); // 'tmp/out/data/'（RTL显示效果）
      
      // 中文（LTR语言）路径不镜像
      let localeZh: Intl.Locale = new Intl.Locale('zh');
      let unMirrorPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeZh);
      console.log(`中文路径（无镜像）: "${unMirrorPath}"`); // 'data/out/tmp'
      
      // 英语（LTR语言）路径不镜像
      let localeEn: Intl.Locale = new Intl.Locale('en');
      let enPath: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path, delimiter, localeEn);
      console.log(`英语路径（无镜像）: "${enPath}"`); // 'data/out/tmp'
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`路径镜像处理失败, 错误码: ${err.code}, 信息: ${err.message}`);
    }
  }
  
  /**
   * 不同分隔符的路径处理
   */
  static differentDelimiters(): void {
    console.log('\n=== 不同分隔符路径示例 ===');
    
    try {
      // 使用反斜杠分隔符
      let path1: string = 'data\\out\\tmp';
      let delimiter1: string = '\\';
      let localeAr: Intl.Locale = new Intl.Locale('ar');
      let mirrorPath1: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path1, delimiter1, localeAr);
      console.log(`反斜杠分隔路径镜像: "${mirrorPath1}"`);
      
      // 使用冒号分隔符
      let path2: string = 'data:out:tmp';
      let delimiter2: string = ':';
      let mirrorPath2: string = i18n.I18NUtil.getUnicodeWrappedFilePath(path2, delimiter2, localeAr);
      console.log(`冒号分隔路径镜像: "${mirrorPath2}"`);
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`处理失败, 错误码: ${err.code}`);
    }
  }
}

/**
 * 主函数：运行所有示例
 */
export function runAllExamples(): void {
  console.log('========================================');
  console.log('  字符处理完整示例');
  console.log('========================================');
  
  // 字符属性判断
  UnicodeCharacterExample.checkCharacterProperties();
  UnicodeCharacterExample.analyzeStringProperties('Hello世界123');
  
  // 文本音译
  TransliterationExample.basicTransliteration();
  TransliterationExample.transliterationWithoutTone();
  TransliterationExample.nameTransliteration();
  TransliterationExample.getAvailableIds();
  TransliterationExample.batchTransliteration();
  
  // 文本标准化
  NormalizationExample.nfcNormalization();
  NormalizationExample.compareNormalizationModes();
  
  // 文本换行点
  BreakIteratorExample.basicBreakIterator();
  BreakIteratorExample.iterateAllBreakPoints();
  BreakIteratorExample.useFollowingAndPrevious();
  
  // 路径镜像
  PathMirrorExample.rtlPathMirror();
  PathMirrorExample.differentDelimiters();
  
  console.log('\n========================================');
  console.log('  所有示例执行完成');
  console.log('========================================');
}

// 调用主函数
runAllExamples();