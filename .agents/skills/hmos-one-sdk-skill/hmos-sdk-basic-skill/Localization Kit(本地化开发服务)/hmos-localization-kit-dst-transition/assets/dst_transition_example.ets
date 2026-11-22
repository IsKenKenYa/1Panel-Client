/**
 * 夏令时跳变完整示例代码
 * 功能：计算夏令时跳变前后挂钟时间之间相差的小时数
 */

import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 夏令时计算参数接口
 */
interface DSTCalculationParams {
  locale: string;           // 区域ID，如 'zh-Hans'
  timezone: string;         // 时区ID，如 'Europe/London'
  startTime: {              // 夏令时开始前的参考时间
    year: number;
    month: number;          // 注意：月份从0开始
    day: number;
    hour: number;
    minute: number;
    second: number;
  };
  endTime: {                // 夏令时期间的参考时间
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
  };
}

/**
 * 计算结果接口
 */
interface DSTCalculationResult {
  hoursDiff: number;        // 相差的小时数
  timezone: string;         // 使用的时区
  startTimeInMillis: number; // 起始时间戳
  endTimeInMillis: number;   // 结束时间戳
  description: string;      // 结果描述
}

/**
 * 计算夏令时跳变前后挂钟时间之间相差的小时数
 * @param params 计算参数配置
 * @returns 计算结果对象
 */
function calculateDSTHours(params: DSTCalculationParams): DSTCalculationResult {
  try {
    console.log(`开始计算夏令时跳变，区域：${params.locale}, 时区：${params.timezone}`);
    
    let calendar: i18n.Calendar = i18n.getCalendar(params.locale);
    calendar.setTimeZone(params.timezone);
    
    let actualTimezone = calendar.getTimeZone();
    console.log(`时区设置成功，实际时区：${actualTimezone}`);
    
    calendar.set(
      params.startTime.year,
      params.startTime.month,
      params.startTime.day,
      params.startTime.hour,
      params.startTime.minute,
      params.startTime.second
    );
    let startTimeInMillis = calendar.getTimeInMillis();
    console.log(`起始时间：${params.startTime.year}-${params.startTime.month + 1}-${params.startTime.day} ${params.startTime.hour}:${params.startTime.minute}:${params.startTime.second}, 时间戳：${startTimeInMillis}`);
    
    calendar.set(
      params.endTime.year,
      params.endTime.month,
      params.endTime.day,
      params.endTime.hour,
      params.endTime.minute,
      params.endTime.second
    );
    let endTimeInMillis = calendar.getTimeInMillis();
    console.log(`结束时间：${params.endTime.year}-${params.endTime.month + 1}-${params.endTime.day} ${params.endTime.hour}:${params.endTime.minute}:${params.endTime.second}, 时间戳：${endTimeInMillis}`);
    
    let hoursDiff = (endTimeInMillis - startTimeInMillis) / (3600 * 1000);
    
    let description = hoursDiff === 24 
      ? '正常的一天24小时' 
      : hoursDiff < 24 
        ? `夏令时开始当天，时间缩短为${hoursDiff}小时` 
        : `夏令时结束当天，时间延长为${hoursDiff}小时`;
    
    console.log(`计算完成：相差${hoursDiff}小时，${description}`);
    
    return {
      hoursDiff,
      timezone: actualTimezone,
      startTimeInMillis,
      endTimeInMillis,
      description
    };
    
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`计算失败：错误码 ${err.code}, 错误信息 ${err.message}`);
    throw error;
  }
}

/**
 * 演示案例1：伦敦夏令时开始
 */
function exampleLondonDSTStart(): void {
  console.log('\n=== 案例1：伦敦夏令时开始 ===');
  
  let params: DSTCalculationParams = {
    locale: 'zh-Hans',
    timezone: 'Europe/London',
    startTime: {
      year: 2021,
      month: 2,      // 3月（月份从0开始）
      day: 27,
      hour: 16,
      minute: 0,
      second: 0
    },
    endTime: {
      year: 2021,
      month: 2,      // 3月（月份从0开始）
      day: 28,
      hour: 16,
      minute: 0,
      second: 0
    }
  };
  
  let result = calculateDSTHours(params);
  console.log(`结果：${result.hoursDiff}小时 (${result.description})`);
}

/**
 * 演示案例2：纽约夏令时开始
 */
function exampleNewYorkDSTStart(): void {
  console.log('\n=== 案例2：纽约夏令时开始 ===');
  
  let params: DSTCalculationParams = {
    locale: 'en-US',
    timezone: 'America/New_York',
    startTime: {
      year: 2021,
      month: 2,      // 3月
      day: 13,
      hour: 12,
      minute: 0,
      second: 0
    },
    endTime: {
      year: 2021,
      month: 2,      // 3月
      day: 14,
      hour: 12,
      minute: 0,
      second: 0
    }
  };
  
  let result = calculateDSTHours(params);
  console.log(`结果：${result.hoursDiff}小时 (${result.description})`);
}

/**
 * 演示案例3：伦敦夏令时结束
 */
function exampleLondonDSTEnd(): void {
  console.log('\n=== 案例3：伦敦夏令时结束 ===');
  
  let params: DSTCalculationParams = {
    locale: 'zh-Hans',
    timezone: 'Europe/London',
    startTime: {
      year: 2021,
      month: 9,      // 10月（月份从0开始）
      day: 30,
      hour: 16,
      minute: 0,
      second: 0
    },
    endTime: {
      year: 2021,
      month: 9,      // 10月（月份从0开始）
      day: 31,
      hour: 16,
      minute: 0,
      second: 0
    }
  };
  
  let result = calculateDSTHours(params);
  console.log(`结果：${result.hoursDiff}小时 (${result.description})`);
}

/**
 * 演示案例4：无夏令时的时区（上海）
 */
function exampleShanghaiNoDST(): void {
  console.log('\n=== 案例4：上海（无夏令时） ===');
  
  let params: DSTCalculationParams = {
    locale: 'zh-Hans',
    timezone: 'Asia/Shanghai',
    startTime: {
      year: 2021,
      month: 2,      // 3月
      day: 27,
      hour: 16,
      minute: 0,
      second: 0
    },
    endTime: {
      year: 2021,
      month: 2,      // 3月
      day: 28,
      hour: 16,
      minute: 0,
      second: 0
    }
  };
  
  let result = calculateDSTHours(params);
  console.log(`结果：${result.hoursDiff}小时 (${result.description})`);
}

/**
 * 主函数：运行所有示例
 */
function main(): void {
  console.log('========== 夏令时跳变计算示例 ==========\n');
  
  exampleLondonDSTStart();
  exampleNewYorkDSTStart();
  exampleLondonDSTEnd();
  exampleShanghaiNoDST();
  
  console.log('\n========== 示例执行完成 ==========');
}

main();