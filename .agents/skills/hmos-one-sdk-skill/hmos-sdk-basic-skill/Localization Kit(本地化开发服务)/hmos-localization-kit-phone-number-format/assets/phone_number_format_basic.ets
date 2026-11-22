import { i18n } from '@kit.LocalizationKit';

// 基本电话号码格式化示例

// 示例1: NATIONAL格式化(本地国家标准格式)
function formatNationalExample(): void {
  console.log('=== NATIONAL格式化示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  const phoneNumber: string = '158****2312';
  
  // 格式化电话号码
  const formattedNumber: string = formatter.format(phoneNumber);
  console.log(`原始号码: ${phoneNumber}`);
  console.log(`格式化结果: ${formattedNumber}`); // 输出: 158 **** 2312
  
  // 验证号码有效性
  const isValid: boolean = formatter.isValidNumber(phoneNumber);
  console.log(`号码有效性: ${isValid}`); // 输出: true
}

// 示例2: E164格式化(国际通信标准格式)
function formatE164Example(): void {
  console.log('=== E164格式化示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'E164' });
  const phoneNumber: string = '158****2312';
  
  const formattedNumber: string = formatter.format(phoneNumber);
  console.log(`原始号码: ${phoneNumber}`);
  console.log(`格式化结果: ${formattedNumber}`); // 输出: +86 158****2312
}

// 示例3: INTERNATIONAL格式化(国际展示格式)
function formatInternationalExample(): void {
  console.log('=== INTERNATIONAL格式化示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'INTERNATIONAL' });
  const phoneNumber: string = '158****2312';
  
  const formattedNumber: string = formatter.format(phoneNumber);
  console.log(`原始号码: ${phoneNumber}`);
  console.log(`格式化结果: ${formattedNumber}`); // 输出: +86 158 **** 2312
}

// 示例4: RFC3966格式化(URI格式)
function formatRFC3966Example(): void {
  console.log('=== RFC3966格式化示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'RFC3966' });
  const phoneNumber: string = '158****2312';
  
  const formattedNumber: string = formatter.format(phoneNumber);
  console.log(`原始号码: ${phoneNumber}`);
  console.log(`格式化结果: ${formattedNumber}`); // 输出: tel:+86-158-****-2312
}

// 示例5: 多国家号码格式化
function formatMultiCountryExample(): void {
  console.log('=== 多国家号码格式化示例 ===');
  
  // 中国号码
  const cnFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  const cnNumber: string = '138****5678';
  const cnFormatted: string = cnFormatter.format(cnNumber);
  console.log(`中国号码: ${cnFormatted}`);
  
  // 美国号码
  const usFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('US');
  const usNumber: string = '4155552671';
  const usFormatted: string = usFormatter.format(usNumber);
  console.log(`美国号码: ${usFormatted}`);
  
  // 英国号码
  const ukFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('GB');
  const ukNumber: string = '7912345678';
  const ukFormatted: string = ukFormatter.format(ukNumber);
  console.log(`英国号码: ${ukFormatted}`);
}

// 示例6: 号码有效性验证
function validateNumberExample(): void {
  console.log('=== 号码有效性验证示例 ===');
  
  const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
  
  // 有效号码
  const validNumber: string = '158****2312';
  const isValid1: boolean = formatter.isValidNumber(validNumber);
  console.log(`号码 ${validNumber} 有效性: ${isValid1}`);
  
  // 无效号码
  const invalidNumber: string = '1234567';
  const isValid2: boolean = formatter.isValidNumber(invalidNumber);
  console.log(`号码 ${invalidNumber} 有效性: ${isValid2}`);
}

// 示例7: 安全格式化函数(包含错误处理)
function safeFormatExample(): void {
  console.log('=== 安全格式化示例 ===');
  
  function safeFormat(country: string, phoneNumber: string, type?: string): string {
    try {
      const options: i18n.PhoneNumberFormatOptions = type ? { type } : undefined;
      const formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat(country, options);
      
      const isValid: boolean = formatter.isValidNumber(phoneNumber);
      if (!isValid) {
        console.warn(`号码 ${phoneNumber} 无效,返回原始号码`);
        return phoneNumber;
      }
      
      const formattedNumber: string = formatter.format(phoneNumber);
      return formattedNumber || phoneNumber;
    } catch (error) {
      console.error(`格式化失败: ${error}`);
      return phoneNumber;
    }
  }
  
  const result1: string = safeFormat('CN', '158****2312', 'NATIONAL');
  const result2: string = safeFormat('CN', 'invalid', 'NATIONAL');
  
  console.log(`有效号码格式化: ${result1}`);
  console.log(`无效号码格式化: ${result2}`);
}

// 执行所有示例
formatNationalExample();
formatE164Example();
formatInternationalExample();
formatRFC3966Example();
formatMultiCountryExample();
validateNumberExample();
safeFormatExample();