/**
 * 时区跳变功能示例（需要API version 20+）
 * 展示如何获取时区跳变规则、查询跳变时间点和偏移量变化
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';

/**
 * 获取时区跳变信息
 * @param timezoneId 时区ID
 * @param fromDate 查询起始日期
 * @returns 跳变信息对象
 */
function getTimezoneTransition(timezoneId: string, fromDate: Date): object | null {
  try {
    // 获取时区对象
    const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
    
    // 获取时区跳变规则（API 20+）
    const zoneRules: i18n.ZoneRules = timezone.getZoneRules();
    
    // 获取指定时间后的下一个跳变对象
    const timestamp: number = fromDate.getTime();
    const zoneOffsetTransition: i18n.ZoneOffsetTransition = zoneRules.nextTransition(timestamp);
    
    // 获取跳变时间点
    const transitionTime: number = zoneOffsetTransition.getMilliseconds();
    
    // 获取跳变前后偏移量
    const offsetBefore: number = zoneOffsetTransition.getOffsetBefore();
    const offsetAfter: number = zoneOffsetTransition.getOffsetAfter();
    
    // 转换为小时
    const offsetBeforeHours: number = offsetBefore / 3600000;
    const offsetAfterHours: number = offsetAfter / 3600000;
    
    // 如果跳变时间为0，说明该时区无夏令时
    if (transitionTime === 0) {
      console.info(`时区 ${timezoneId} 无夏令时跳变`);
      return {
        hasTransition: false,
        timezoneId: timezoneId,
        offsetBefore: offsetBefore,
        offsetBeforeHours: offsetBeforeHours,
        offsetAfter: offsetAfter,
        offsetAfterHours: offsetAfterHours
      };
    }
    
    // 格式化跳变时间
    const dateTimeFormat: Intl.DateTimeFormat = new Intl.DateTimeFormat('zh-CN', {
      timeZone: timezoneId,
      dateStyle: 'long',
      timeStyle: 'long',
      hour12: false
    });
    const formattedTime: string = dateTimeFormat.format(new Date(transitionTime));
    
    console.info(`时区跳变时间: ${formattedTime}`);
    console.info(`跳变前偏移量: ${offsetBeforeHours}小时`);
    console.info(`跳变后偏移量: ${offsetAfterHours}小时`);
    
    return {
      hasTransition: true,
      timezoneId: timezoneId,
      transitionTime: transitionTime,
      formattedTime: formattedTime,
      offsetBefore: offsetBefore,
      offsetBeforeHours: offsetBeforeHours,
      offsetAfter: offsetAfter,
      offsetAfterHours: offsetAfterHours,
      offsetDiff: offsetAfter - offsetBefore,
      offsetDiffHours: offsetAfterHours - offsetBeforeHours
    };
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`获取时区跳变信息失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    return null;
  }
}

/**
 * 检查时区是否支持夏令时
 * @param timezoneId 时区ID
 * @returns 是否支持夏令时
 */
function checkDaylightSavingSupport(timezoneId: string): boolean {
  try {
    const timezone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
    const rawOffset: number = timezone.getRawOffset();
    const currentOffset: number = timezone.getOffset(new Date().getTime());
    
    // 如果当前偏移量与固定偏移量不同，说明当前处于夏令时
    const currentlyInDST: boolean = currentOffset !== rawOffset;
    
    // 查询未来跳变点
    const zoneRules: i18n.ZoneRules = timezone.getZoneRules();
    const futureTransition: i18n.ZoneOffsetTransition = zoneRules.nextTransition(new Date().getTime());
    const transitionTime: number = futureTransition.getMilliseconds();
    
    // 如果跳变时间为0，说明该时区无夏令时规则
    const hasDSTRules: boolean = transitionTime !== 0;
    
    console.info(`时区 ${timezoneId}:`);
    console.info(`  当前处于夏令时: ${currentlyInDST}`);
    console.info(`  支持夏令时规则: ${hasDSTRules}`);
    
    return hasDSTRules;
  } catch (error) {
    console.error(`检查夏令时支持失败: ${error}`);
    return false;
  }
}

/**
 * 获取多个时区的跳变信息
 * @param timezoneIds 时区ID列表
 * @param fromDate 查询起始日期
 * @returns 跳变信息列表
 */
function getMultipleTimezoneTransitions(timezoneIds: Array<string>, fromDate: Date): Array<object> {
  const transitions: Array<object> = [];
  
  for (let i = 0; i < timezoneIds.length; i++) {
    const timezoneId: string = timezoneIds[i];
    const transitionInfo: object | null = getTimezoneTransition(timezoneId, fromDate);
    
    if (transitionInfo) {
      transitions.push(transitionInfo);
    }
  }
  
  console.info(`成功获取${transitions.length}个时区的跳变信息`);
  return transitions;
}

/**
 * 格式化展示跳变信息
 * @param transitionInfo 跳变信息
 */
function displayTransitionInfo(transitionInfo: object): void {
  if (!transitionInfo) {
    console.error('跳变信息为空');
    return;
  }
  
  const info = transitionInfo as {
    hasTransition?: boolean;
    timezoneId?: string;
    formattedTime?: string;
    offsetBeforeHours?: number;
    offsetAfterHours?: number;
    offsetDiffHours?: number;
  };
  
  console.info('\n=== 时区跳变信息 ===');
  console.info(`时区ID: ${info.timezoneId || '未知'}`);
  
  if (info.hasTransition) {
    console.info(`跳变时间: ${info.formattedTime || '未知'}`);
    console.info(`跳变前偏移量: ${info.offsetBeforeHours || 0}小时`);
    console.info(`跳变后偏移量: ${info.offsetAfterHours || 0}小时`);
    console.info(`偏移量变化: ${info.offsetDiffHours || 0}小时`);
  } else {
    console.info('该时区无夏令时跳变');
  }
}

/**
 * 主函数 - 演示时区跳变功能
 */
function main(): void {
  console.info('=== 时区跳变功能示例（API 20+） ===');
  
  // 示例1：查询单个时区的跳变信息
  console.info('\n--- 示例1：查询蒂华纳时区跳变 ---');
  const transition1 = getTimezoneTransition('America/Tijuana', new Date(2025, 4, 13));
  displayTransitionInfo(transition1);
  
  // 示例2：查询无夏令时的时区
  console.info('\n--- 示例2：查询上海时区（无夏令时）---');
  const transition2 = getTimezoneTransition('Asia/Shanghai', new Date(2025, 4, 13));
  displayTransitionInfo(transition2);
  
  // 示例3：检查多个时区的夏令时支持
  console.info('\n--- 示例3：检查多个时区夏令时支持 ---');
  const timezoneIds = [
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Asia/Shanghai',
    'Australia/Sydney'
  ];
  
  for (let i = 0; i < timezoneIds.length; i++) {
    checkDaylightSavingSupport(timezoneIds[i]);
  }
  
  // 示例4：获取多个时区的跳变信息
  console.info('\n--- 示例4：获取多个时区跳变信息 ---');
  const transitions = getMultipleTimezoneTransitions(
    ['America/New_York', 'Europe/London', 'America/Tijuana'],
    new Date(2025, 4, 13)
  );
  
  console.info(`\n汇总：获取了${transitions.length}个时区的跳变信息`);
  
  console.info('\n=== 示例执行完成 ===');
}

// 执行主函数
main();