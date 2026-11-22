import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function dateCalculationExample(): void {
  try {
    let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
    calendar.set(2023, 6, 25, 8, 0, 0);
    console.log(`初始日期：2023年7月25日`);
    calendar.add('date', 10);
    let newDay = calendar.get('date');
    let newMonth = calendar.get('month');
    console.log(`加10天后的日期：${calendar.get('year')}年${newMonth + 1}月${newDay}日`);
    calendar.add('month', 2);
    newMonth = calendar.get('month');
    console.log(`加2个月后的日期：${calendar.get('year')}年${newMonth + 1}月${calendar.get('date')}日`);
    calendar.add('year', -1);
    console.log(`减1年后的日期：${calendar.get('year')}年${calendar.get('month') + 1}月${calendar.get('date')}日`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
  }
}

function weekendCheckExample(): void {
  try {
    let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
    let testDates: Date[] = [
      new Date(2023, 6, 25),
      new Date(2023, 6, 29),
      new Date(2023, 6, 30)
    ];
    console.log('周末判断测试：');
    for (let date of testDates) {
      calendar.setTime(date);
      let isWeekend = calendar.isWeekend();
      let dayOfWeek = calendar.get('day_of_week');
      console.log(`${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 - 星期${dayOfWeek} - 是否周末：${isWeekend}`);
    }
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
  }
}

function compareDaysExample(): void {
  try {
    let calendar: i18n.Calendar = i18n.getCalendar('zh-Hans', 'gregory');
    calendar.set(2023, 6, 25);
    let targetDate1 = new Date(2023, 6, 30);
    let diff1 = calendar.compareDays(targetDate1);
    console.log(`当前日期与2023年7月30日相差${Math.abs(diff1)}天`);
    let targetDate2 = new Date(2023, 6, 20);
    let diff2 = calendar.compareDays(targetDate2);
    console.log(`当前日期与2023年7月20日相差${Math.abs(diff2)}天`);
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Error: code=${err.code}, message=${err.message}`);
  }
}

export { dateCalculationExample, weekendCheckExample, compareDaysExample };