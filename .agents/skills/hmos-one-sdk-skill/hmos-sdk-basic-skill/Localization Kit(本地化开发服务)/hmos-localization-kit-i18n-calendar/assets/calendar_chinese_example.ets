import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function chineseCalendarExample(): void {
  try {
    let calendarChinese: i18n.Calendar = i18n.getCalendar('zh-Hans', 'chinese');
    calendarChinese.setTime(new Date(2023, 6, 25, 8, 0, 0));
    let yearChinese = calendarChinese.get('year');
    console.log(`农历年（干支纪年）= ${yearChinese}`);
    let monthChinese = calendarChinese.get('month');
    console.log(`农历月 = ${monthChinese}`);
    let dayChinese = calendarChinese.get('date');
    console.log(`农历日 = ${dayChinese}`);
    console.log(`公历2023年7月25日对应的农历日期：年${yearChinese} 月${monthChinese + 1} 日${dayChinese}`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
  }
}

function getChineseCalendarInfo(gregoryDate: Date): { year: number; month: number; day: number } {
  try {
    let calendarChinese: i18n.Calendar = i18n.getCalendar('zh-Hans', 'chinese');
    calendarChinese.setTime(gregoryDate);
    return {
      year: calendarChinese.get('year'),
      month: calendarChinese.get('month'),
      day: calendarChinese.get('date')
    };
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
    return { year: -1, month: -1, day: -1 };
  }
}

export { chineseCalendarExample, getChineseCalendarInfo };