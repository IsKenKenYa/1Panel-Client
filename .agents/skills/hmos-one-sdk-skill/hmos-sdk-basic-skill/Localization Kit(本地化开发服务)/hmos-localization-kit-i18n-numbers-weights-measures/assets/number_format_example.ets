/**
 * 数字格式化完整示例
 * 使用Intl.NumberFormat进行不同区域的数字格式化
 */

// 示例1：基本数字格式化
function basicNumberFormatting(): void {
  console.log('=== 基本数字格式化示例 ===');
  
  const value = 1234567.89;
  
  // 美式格式（逗号千位分隔，点小数分隔）
  const usFormatted = new Intl.NumberFormat('en-US').format(value);
  console.log('美式格式:', usFormatted);  // 输出: "1,234,567.89"
  
  // 德式格式（点千位分隔，逗号小数分隔）
  const deFormatted = new Intl.NumberFormat('de-DE').format(value);
  console.log('德式格式:', deFormatted);  // 输出: "1.234.567,89"
  
  // 中文格式
  const cnFormatted = new Intl.NumberFormat('zh-CN').format(value);
  console.log('中文格式:', cnFormatted);
  
  // 法式格式
  const frFormatted = new Intl.NumberFormat('fr-FR').format(value);
  console.log('法式格式:', frFormatted);
}

// 示例2：控制小数位数
function controlDecimalPlaces(): void {
  console.log('=== 控制小数位数示例 ===');
  
  const value = 1234.56789;
  
  // 保留2位小数
  const twoDecimals = new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value);
  console.log('保留2位小数:', twoDecimals);  // 输出: "1,234.57"
  
  // 保留0位小数（整数）
  const noDecimals = new Intl.NumberFormat('en-US', {
    maximumFractionDigits: 0
  }).format(value);
  console.log('整数格式:', noDecimals);  // 输出: "1,235"
  
  // 保留4位小数
  const fourDecimals = new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4
  }).format(value);
  console.log('保留4位小数:', fourDecimals);  // 输出: "1,234.5679"
}

// 示例3：百分比格式化
function percentageFormatting(): void {
  console.log('=== 百分比格式化示例 ===');
  
  const value = 0.1234;
  
  // 百分比格式（默认保留0位小数）
  const percentDefault = new Intl.NumberFormat('en-US', {
    style: 'percent'
  }).format(value);
  console.log('百分比（默认）:', percentDefault);  // 输出: "12%"
  
  // 百分比格式（保留2位小数）
  const percentTwoDecimals = new Intl.NumberFormat('en-US', {
    style: 'percent',
    minimumFractionDigits: 2
  }).format(value);
  console.log('百分比（2位小数）:', percentTwoDecimals);  // 输出: "12.34%"
  
  // 中文百分比
  const percentCN = new Intl.NumberFormat('zh-CN', {
    style: 'percent',
    minimumFractionDigits: 2
  }).format(value);
  console.log('中文百分比:', percentCN);
}

// 示例4：科学计数法格式化
function scientificFormatting(): void {
  console.log('=== 科学计数法格式化示例 ===');
  
  const largeNumber = 1234567890;
  const smallNumber = 0.0001234;
  
  // 科学计数法
  const scientificLarge = new Intl.NumberFormat('en-US', {
    notation: 'scientific'
  }).format(largeNumber);
  console.log('大数科学计数法:', scientificLarge);  // 输出类似: "1.235E9"
  
  const scientificSmall = new Intl.NumberFormat('en-US', {
    notation: 'scientific'
  }).format(smallNumber);
  console.log('小数科学计数法:', scientificSmall);  // 输出类似: "1.234E-4"
  
  // 工程计数法（指数为3的倍数）
  const engineeringLarge = new Intl.NumberFormat('en-US', {
    notation: 'engineering'
  }).format(largeNumber);
  console.log('大数工程计数法:', engineeringLarge);
}

// 示例5：紧凑格式（如K、M、B）
function compactFormatting(): void {
  console.log('=== 紧凑格式示例 ===');
  
  const thousands = 12345;
  const millions = 1234567;
  const billions = 1234567890;
  
  // 紧凑格式（short）
  const compactShortK = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'short'
  }).format(thousands);
  console.log('千（short）:', compactShortK);  // 输出: "12K"
  
  const compactShortM = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'short'
  }).format(millions);
  console.log('百万（short）:', compactShortM);  // 输出: "1M"
  
  const compactShortB = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'short'
  }).format(billions);
  console.log('十亿（short）:', compactShortB);  // 输出: "1B"
  
  // 紧凑格式（long）
  const compactLongK = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'long'
  }).format(thousands);
  console.log('千（long）:', compactLongK);  // 输出: "12 thousand"
  
  const compactLongM = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'long'
  }).format(millions);
  console.log('百万（long）:', compactLongM);  // 输出: "1 million"
}

// 示例6：单位格式化
function unitFormatting(): void {
  console.log('=== 单位格式化示例 ===');
  
  const distance = 50;
  const speed = 60;
  const temperature = 25;
  
  // 距离单位
  const distanceKM = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'kilometer'
  }).format(distance);
  console.log('距离（公里）:', distanceKM);  // 输出: "50 km"
  
  const distanceMile = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'mile'
  }).format(distance);
  console.log('距离（英里）:', distanceMile);  // 输出: "50 mi"
  
  // 速度单位
  const speedKMH = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'kilometer-per-hour'
  }).format(speed);
  console.log('速度（公里/小时）:', speedKMH);  // 输出: "60 km/h"
  
  // 温度单位
  const tempCelsius = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'celsius'
  }).format(temperature);
  console.log('温度（摄氏度）:', tempCelsius);  // 输出: "25°C"
  
  const tempFahrenheit = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'fahrenheit'
  }).format(temperature);
  console.log('温度（华氏度）:', tempFahrenheit);  // 输出: "25°F"
}

// 示例7：不同单位显示风格
function unitDisplayStyle(): void {
  console.log('=== 单位显示风格示例 ===');
  
  const value = 100;
  
  // long风格（完整单位名称）
  const longStyle = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'liter',
    unitDisplay: 'long'
  }).format(value);
  console.log('long风格:', longStyle);  // 输出: "100 liters"
  
  // short风格（简短单位符号）
  const shortStyle = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'liter',
    unitDisplay: 'short'
  }).format(value);
  console.log('short风格:', shortStyle);  // 输出: "100 L"
  
  // narrow风格（紧凑显示）
  const narrowStyle = new Intl.NumberFormat('en-US', {
    style: 'unit',
    unit: 'liter',
    unitDisplay: 'narrow'
  }).format(value);
  console.log('narrow风格:', narrowStyle);  // 输出: "100L"
}

// 示例8：数字分组分隔符控制
function groupingSeparatorControl(): void {
  console.log('=== 数字分组分隔符控制示例 ===');
  
  const value = 1234567.89;
  
  // 使用分组分隔符（默认）
  const withGrouping = new Intl.NumberFormat('en-US', {
    useGrouping: true
  }).format(value);
  console.log('使用分组分隔符:', withGrouping);  // 输出: "1,234,567.89"
  
  // 不使用分组分隔符
  const withoutGrouping = new Intl.NumberFormat('en-US', {
    useGrouping: false
  }).format(value);
  console.log('不使用分组分隔符:', withoutGrouping);  // 输出: "1234567.89"
  
  // 最小分组位数
  const minGrouping = new Intl.NumberFormat('en-US', {
    useGrouping: 'min2'
  }).format(value);
  console.log('最小分组位数2:', minGrouping);
}

// 示例9：自定义格式化选项
function customFormatting(): void {
  console.log('=== 自定义格式化示例 ===');
  
  const value = 1234.56;
  
  // 自定义：保留3位小数，不分组，百分比格式
  const custom1 = new Intl.NumberFormat('en-US', {
    style: 'percent',
    minimumFractionDigits: 3,
    maximumFractionDigits: 3,
    useGrouping: false
  }).format(value / 100);
  console.log('自定义1:', custom1);
  
  // 自定义：紧凑格式，short显示，保留1位小数
  const custom2 = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'short',
    maximumFractionDigits: 1
  }).format(12345678);
  console.log('自定义2:', custom2);
  
  // 自定义：科学计数法，保留2位小数
  const custom3 = new Intl.NumberFormat('en-US', {
    notation: 'scientific',
    maximumFractionDigits: 2
  }).format(12345678);
  console.log('自定义3:', custom3);
}

// 示例10：formatRange - 数字范围格式化
function formatRangeExample(): void {
  console.log('=== 数字范围格式化示例 ===');
  
  // 基本范围格式化
  const range1 = new Intl.NumberFormat('en-US').formatRange(1000, 2000);
  console.log('范围1:', range1);  // 输出类似: "1,000–2,000"
  
  // 中文范围格式化
  const range2 = new Intl.NumberFormat('zh-CN').formatRange(100, 200);
  console.log('范围2:', range2);
  
  // 百分比范围
  const range3 = new Intl.NumberFormat('en-US', {
    style: 'percent'
  }).formatRange(0.1, 0.2);
  console.log('百分比范围:', range3);
  
  // 货币范围
  const range4 = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).formatRange(100, 200);
  console.log('货币范围:', range4);
}

// 主函数 - 运行所有示例
export function runAllNumberFormatExamples(): void {
  console.log('\n===== 数字格式化完整示例 =====\n');
  
  basicNumberFormatting();
  console.log('');
  
  controlDecimalPlaces();
  console.log('');
  
  percentageFormatting();
  console.log('');
  
  scientificFormatting();
  console.log('');
  
  compactFormatting();
  console.log('');
  
  unitFormatting();
  console.log('');
  
  unitDisplayStyle();
  console.log('');
  
  groupingSeparatorControl();
  console.log('');
  
  customFormatting();
  console.log('');
  
  formatRangeExample();
}

// 导出函数供其他模块使用
export {
  basicNumberFormatting,
  controlDecimalPlaces,
  percentageFormatting,
  scientificFormatting,
  compactFormatting,
  unitFormatting,
  unitDisplayStyle,
  groupingSeparatorControl,
  customFormatting,
  formatRangeExample
};