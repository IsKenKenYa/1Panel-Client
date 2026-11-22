import { i18n } from '@kit.LocalizationKit';

// 电话号码归属地查询示例

// 示例1: 中国号码归属地查询
function locationQueryChinaExample(): void {
  console.log('=== 中国号码归属地查询示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  
  // 查询不同地区号码
  const phoneNumbers: string[] = [
    '158****2312',  // 陕西西安
    '139****5678',  // 广东广州
    '186****1234',  // 北京
    '131****9876'   // 上海
  ];
  
  console.log('使用中文显示归属地:');
  for (const number of phoneNumbers) {
    const location: string = formatter.getLocationName(number, 'zh-CN');
    const isValid: boolean = formatter.isValidNumber(number);
    console.log(`号码: ${number}, 有效: ${isValid}, 归属地: ${location}`);
  }
}

// 示例2: 多语言归属地显示
function locationQueryMultiLanguageExample(): void {
  console.log('=== 多语言归属地显示示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  const phoneNumber: string = '158****2312';
  
  // 不同语言显示归属地
  const locales: string[] = ['zh-CN', 'en-GB', 'en-US', 'ja-JP', 'ko-KR'];
  
  console.log(`号码: ${phoneNumber}`);
  for (const locale of locales) {
    const location: string = formatter.getLocationName(phoneNumber, locale);
    console.log(`语言 ${locale}: ${location}`);
  }
}

// 示例3: 国际号码归属地查询
function locationQueryInternationalExample(): void {
  console.log('=== 国际号码归属地查询示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  
  // 查询其他国家号码归属地(需要国际区号前缀)
  const internationalNumbers: string[] = [
    '0039312****789',  // 意大利号码(前缀0039)
    '001415****2671',  // 美国号码(前缀001)
    '0044791****5678', // 英国号码(前缀0044)
    '+81131****5678'   // 日本号码(前缀+81)
  ];
  
  console.log('使用中文显示国际号码归属地:');
  for (const number of internationalNumbers) {
    const location: string = formatter.getLocationName(number, 'zh-CN');
    console.log(`号码: ${number}, 归属地: ${location}`);
  }
}

// 示例4: 归属地查询与格式化结合
function locationQueryWithFormatExample(): void {
  console.log('=== 归属地查询与格式化结合示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  const phoneNumber: string = '158****2312';
  
  // 验证有效性
  const isValid: boolean = formatter.isValidNumber(phoneNumber);
  console.log(`号码有效性: ${isValid}`);
  
  if (isValid) {
    // 格式化号码
    const formatted: string = formatter.format(phoneNumber);
    console.log(`格式化号码: ${formatted}`);
    
    // 查询归属地
    const locationZh: string = formatter.getLocationName(phoneNumber, 'zh-CN');
    const locationEn: string = formatter.getLocationName(phoneNumber, 'en-GB');
    
    console.log(`归属地(中文): ${locationZh}`);
    console.log(`归属地(英文): ${locationEn}`);
    
    // 组合显示
    const displayText: string = `${formatted} (${locationZh})`;
    console.log(`组合显示: ${displayText}`);
  }
}

// 示例5: 归属地查询错误处理
function locationQueryErrorHandlingExample(): void {
  console.log('=== 归属地查询错误处理示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  
  // 无效号码查询
  const invalidNumber: string = '1234567';
  const invalidLocation: string = formatter.getLocationName(invalidNumber, 'zh-CN');
  console.log(`无效号码 ${invalidNumber} 归属地: "${invalidLocation}" (空字符串)`);
  
  // 缺少国际区号的国际号码
  const missingPrefixNumber: string = '312****789'; // 缺少意大利国际区号
  const missingPrefixLocation: string = formatter.getLocationName(missingPrefixNumber, 'zh-CN');
  console.log(`缺少前缀号码归属地: "${missingPrefixLocation}"`);
}

// 示例6: 安全的归属地查询函数
function safeLocationQueryExample(): void {
  console.log('=== 安全的归属地查询函数示例 ===');
  
  function safeGetLocation(country: string, phoneNumber: string, locale: string): string {
    try {
      const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat(country);
      
      // 验证号码有效性
      const isValid: boolean = formatter.isValidNumber(phoneNumber);
      if (!isValid) {
        console.warn(`号码 ${phoneNumber} 无效`);
        return '无效号码';
      }
      
      // 查询归属地
      const location: string = formatter.getLocationName(phoneNumber, locale);
      return location || '归属地未知';
    } catch (error) {
      console.error(`查询失败: ${error}`);
      return '查询失败';
    }
  }
  
  const result1: string = safeGetLocation('CN', '158****2312', 'zh-CN');
  const result2: string = safeGetLocation('CN', 'invalid', 'zh-CN');
  const result3: string = safeGetLocation('CN', '0039312****789', 'zh-CN');
  
  console.log(`有效号码归属地: ${result1}`);
  console.log(`无效号码归属地: ${result2}`);
  console.log(`国际号码归属地: ${result3}`);
}

// 示例7: 批量归属地查询
function batchLocationQueryExample(): void {
  console.log('=== 批量归属地查询示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  
  interface PhoneNumberInfo {
    number: string;
    isValid: boolean;
    formatted: string;
    location: string;
  }
  
  const phoneNumbers: string[] = [
    '158****2312',
    '139****5678',
    '1234567',      // 无效号码
    '0039312****789' // 国际号码
  ];
  
  const results: PhoneNumberInfo[] = phoneNumbers.map(number => {
    const isValid: boolean = formatter.isValidNumber(number);
    const formatted: string = formatter.format(number);
    const location: string = formatter.getLocationName(number, 'zh-CN');
    
    return {
      number,
      isValid,
      formatted: formatted || number,
      location: location || '未知'
    };
  });
  
  console.log('批量查询结果:');
  for (const result of results) {
    console.log(`号码: ${result.number}`);
    console.log(`  有效: ${result.isValid}`);
    console.log(`  格式化: ${result.formatted}`);
    console.log(`  归属地: ${result.location}`);
    console.log('---');
  }
}

// 执行所有示例
locationQueryChinaExample();
locationQueryMultiLanguageExample();
locationQueryInternationalExample();
locationQueryWithFormatExample();
locationQueryErrorHandlingExample();
safeLocationQueryExample();
batchLocationQueryExample();