/**
 * 货币格式化完整示例
 * 使用Intl.NumberFormat进行不同区域的货币格式化
 */

// 示例1：基本货币格式化
function basicCurrencyFormatting(): void {
  console.log('=== 基本货币格式化示例 ===');
  
  const value = 1234.56;
  
  // 美元格式（en-US）
  const usdFormatted = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value);
  console.log('美元格式:', usdFormatted);  // 输出: "$1,234.56"
  
  // 欧元格式（de-DE - 德国）
  const eurGerman = new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元（德国）:', eurGerman);  // 输出: "1.234,56 €"
  
  // 人民币格式（zh-CN）
  const cnyFormatted = new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).format(value);
  console.log('人民币格式:', cnyFormatted);  // 输出: "¥1,234.56"
  
  // 日元格式（ja-JP）
  const jpyFormatted = new Intl.NumberFormat('ja-JP', {
    style: 'currency',
    currency: 'JPY'
  }).format(value);
  console.log('日元格式:', jpyFormatted);  // 输出类似: "￥1,235"（日元通常无小数）
}

// 示例2：不同区域的同一种货币
function sameCurrencyDifferentLocale(): void {
  console.log('=== 同种货币不同区域格式示例 ===');
  
  const value = 1234.56;
  
  // 欧元在不同区域的显示
  const eurUS = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元（美式）:', eurUS);  // 输出: "€1,234.56"
  
  const eurDE = new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元（德式）:', eurDE);  // 输出: "1.234,56 €"
  
  const eurFR = new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元（法式）:', eurFR);
  
  const eurIT = new Intl.NumberFormat('it-IT', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元（意式）:', eurIT);
}

// 示例3：货币显示样式控制
function currencyDisplayStyle(): void {
  console.log('=== 货币显示样式示例 ===');
  
  const value = 1234.56;
  
  // symbol - 使用货币符号（默认）
  const symbolDisplay = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencyDisplay: 'symbol'
  }).format(value);
  console.log('symbol样式:', symbolDisplay);  // 输出: "$1,234.56"
  
  // code - 使用ISO货币代码
  const codeDisplay = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencyDisplay: 'code'
  }).format(value);
  console.log('code样式:', codeDisplay);  // 输出: "USD 1,234.56"
  
  // name - 使用货币名称
  const nameDisplay = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencyDisplay: 'name'
  }).format(value);
  console.log('name样式:', nameDisplay);  // 输出: "1,234.56 US dollars"
  
  // narrowSymbol - 使用紧凑符号
  const narrowSymbol = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencyDisplay: 'narrowSymbol'
  }).format(value);
  console.log('narrowSymbol样式:', narrowSymbol);
}

// 示例4：货币小数位数控制
function currencyDecimalPlaces(): void {
  console.log('=== 货币小数位数控制示例 ===');
  
  const value = 1234.5678;
  
  // 默认（根据货币类型自动决定）
  const defaultDecimals = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value);
  console.log('默认小数位数:', defaultDecimals);  // 输出: "$1,234.57"
  
  // 强制保留0位小数
  const noDecimals = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(value);
  console.log('保留0位小数:', noDecimals);  // 输出: "$1,235"
  
  // 强制保留3位小数
  const threeDecimals = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 3,
    maximumFractionDigits: 3
  }).format(value);
  console.log('保留3位小数:', threeDecimals);  // 输出: "$1,234.568"
  
  // 强制保留4位小数
  const fourDecimals = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 4,
    maximumFractionDigits: 4
  }).format(value);
  console.log('保留4位小数:', fourDecimals);  // 输出: "$1,234.5678"
}

// 示例5：日元格式化（无小数）
function yenFormatting(): void {
  console.log('=== 日元格式化示例 ===');
  
  const value = 1234.56;
  
  // 日元默认无小数
  const jpyDefault = new Intl.NumberFormat('ja-JP', {
    style: 'currency',
    currency: 'JPY'
  }).format(value);
  console.log('日元默认:', jpyDefault);  // 输出: "￥1,235"
  
  // 强制日元显示小数（不常见）
  const jpyWithDecimals = new Intl.NumberFormat('ja-JP', {
    style: 'currency',
    currency: 'JPY',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value);
  console.log('日元强制2位小数:', jpyWithDecimals);
}

// 示例6：货币符号位置
function currencySymbolPosition(): void {
  console.log('=== 货币符号位置示例 ===');
  
  const value = 1234.56;
  
  // 美元：符号在前
  const usd = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value);
  console.log('美元（符号在前）:', usd);  // 输出: "$1,234.56"
  
  // 欧元（德国）：符号在后
  const eurDE = new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元德国（符号在后）:', eurDE);  // 输出: "1.234,56 €"
  
  // 欧元（法国）：符号在后，带空格
  const eurFR = new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR'
  }).format(value);
  console.log('欧元法国:', eurFR);
}

// 示例7：货币范围格式化
function currencyRangeFormatting(): void {
  console.log('=== 货币范围格式化示例 ===');
  
  // 美元范围
  const usdRange = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).formatRange(100, 200);
  console.log('美元范围:', usdRange);
  
  // 欧元范围
  const eurRange = new Intl.NumberFormat('de-DE', {
    style: 'currency',
    currency: 'EUR'
  }).formatRange(1000, 2000);
  console.log('欧元范围:', eurRange);
  
  // 人民币范围
  const cnyRange = new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).formatRange(50, 100);
  console.log('人民币范围:', cnyRange);
}

// 示例8：会计格式（负数显示）
function accountingFormat(): void {
  console.log('=== 会计格式示例 ===');
  
  const negativeValue = -1234.56;
  const positiveValue = 1234.56;
  
  // 标准格式（负号）
  const standardNegative = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(negativeValue);
  console.log('标准负数格式:', standardNegative);  // 输出: "-$1,234.56"
  
  // 会计格式（括号表示负数）
  const accountingNegative = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencySign: 'accounting'
  }).format(negativeValue);
  console.log('会计负数格式:', accountingNegative);  // 输出: "($1,234.56)"
  
  const accountingPositive = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    currencySign: 'accounting'
  }).format(positiveValue);
  console.log('会计正数格式:', accountingPositive);  // 输出: "$1,234.56"
}

// 示例9：货币分组分隔符控制
function currencyGroupingSeparator(): void {
  console.log('=== 货币分组分隔符控制示例 ===');
  
  const value = 1234567.89;
  
  // 使用分组分隔符（默认）
  const withGrouping = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    useGrouping: true
  }).format(value);
  console.log('使用分组分隔符:', withGrouping);  // 输出: "$1,234,567.89"
  
  // 不使用分组分隔符
  const withoutGrouping = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    useGrouping: false
  }).format(value);
  console.log('不使用分组分隔符:', withoutGrouping);  // 输出: "$1234567.89"
}

// 示例10：常见货币格式化大全
function commonCurrencies(): void {
  console.log('=== 常见货币格式化大全 ===');
  
  const value = 1234.56;
  
  const currencies = [
    { code: 'USD', locale: 'en-US', name: '美元' },
    { code: 'EUR', locale: 'de-DE', name: '欧元' },
    { code: 'CNY', locale: 'zh-CN', name: '人民币' },
    { code: 'JPY', locale: 'ja-JP', name: '日元' },
    { code: 'GBP', locale: 'en-GB', name: '英镑' },
    { code: 'KRW', locale: 'ko-KR', name: '韩元' },
    { code: 'INR', locale: 'en-IN', name: '印度卢比' },
    { code: 'AUD', locale: 'en-AU', name: '澳元' },
    { code: 'CAD', locale: 'en-CA', name: '加拿大元' },
    { code: 'CHF', locale: 'de-CH', name: '瑞士法郎' },
  ];
  
  currencies.forEach(currency => {
    const formatted = new Intl.NumberFormat(currency.locale, {
      style: 'currency',
      currency: currency.code
    }).format(value);
    console.log(`${currency.name}:`, formatted);
  });
}

// 示例11：动态货币格式化函数
function formatCurrencyDynamic(
  value: number,
  currencyCode: string,
  locale?: string
): string {
  console.log('=== 动态货币格式化 ===');
  
  // 如果未提供locale，根据货币代码推断
  if (!locale) {
    const currencyLocaleMap: Record<string, string> = {
      'USD': 'en-US',
      'EUR': 'de-DE',
      'CNY': 'zh-CN',
      'JPY': 'ja-JP',
      'GBP': 'en-GB',
      'KRW': 'ko-KR',
      'INR': 'en-IN',
      'AUD': 'en-AU',
      'CAD': 'en-CA',
      'CHF': 'de-CH'
    };
    locale = currencyLocaleMap[currencyCode] || 'en-US';
  }
  
  const formatter = new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: currencyCode
  });
  
  const result = formatter.format(value);
  console.log(`格式化结果（${currencyCode}, ${locale}):`, result);
  return result;
}

// 主函数 - 运行所有示例
export function runAllCurrencyFormatExamples(): void {
  console.log('\n===== 货币格式化完整示例 =====\n');
  
  basicCurrencyFormatting();
  console.log('');
  
  sameCurrencyDifferentLocale();
  console.log('');
  
  currencyDisplayStyle();
  console.log('');
  
  currencyDecimalPlaces();
  console.log('');
  
  yenFormatting();
  console.log('');
  
  currencySymbolPosition();
  console.log('');
  
  currencyRangeFormatting();
  console.log('');
  
  accountingFormat();
  console.log('');
  
  currencyGroupingSeparator();
  console.log('');
  
  commonCurrencies();
  console.log('');
  
  // 动态格式化示例
  formatCurrencyDynamic(1234.56, 'USD');
  formatCurrencyDynamic(1234.56, 'EUR', 'fr-FR');
  formatCurrencyDynamic(1234.56, 'CNY');
}

// 导出函数供其他模块使用
export {
  basicCurrencyFormatting,
  sameCurrencyDifferentLocale,
  currencyDisplayStyle,
  currencyDecimalPlaces,
  yenFormatting,
  currencySymbolPosition,
  currencyRangeFormatting,
  accountingFormat,
  currencyGroupingSeparator,
  commonCurrencies,
  formatCurrencyDynamic
};