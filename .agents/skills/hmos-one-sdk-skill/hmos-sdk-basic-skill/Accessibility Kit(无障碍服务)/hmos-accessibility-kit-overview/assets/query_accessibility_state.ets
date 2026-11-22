/**
 * 查询无障碍服务状态示例
 * 本示例演示如何使用Accessibility Kit查询无障碍服务的开启状态
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 查询辅助应用列表
 */
async function getAccessibilityAbilityList(): Promise<Array<accessibility.AccessibilityAbilityInfo>> {
  try {
    const abilities = await accessibility.getAccessibilityAbilityList();
    console.info('辅助应用列表:', JSON.stringify(abilities));
    return abilities;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error('查询辅助应用列表失败, 错误码:', businessError.code, '错误信息:', businessError.message);
    return [];
  }
}

/**
 * 查询触摸浏览状态
 */
async function getTouchExploreState(): Promise<boolean> {
  try {
    const state = await accessibility.getTouchExploreState();
    console.info('触摸浏览状态:', state);
    return state;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error('查询触摸浏览状态失败, 错误码:', businessError.code, '错误信息:', businessError.message);
    return false;
  }
}

/**
 * 查询屏幕朗读状态
 */
async function getScreenReaderState(): Promise<boolean> {
  try {
    const state = await accessibility.getScreenReaderState();
    console.info('屏幕朗读状态:', state);
    return state;
  } catch (error) {
    const businessError = error as BusinessError;
    console.error('查询屏幕朗读状态失败, 错误码:', businessError.code, '错误信息:', businessError.message);
    return false;
  }
}

/**
 * 查询所有无障碍状态
 */
async function queryAllAccessibilityStates(): Promise<void> {
  console.info('=== 开始查询无障碍状态 ===');
  
  const touchExploreEnabled = await getTouchExploreState();
  const screenReaderEnabled = await getScreenReaderState();
  const abilitiesList = await getAccessibilityAbilityList();
  
  console.info('查询结果汇总:');
  console.info('触摸浏览:', touchExploreEnabled ? '开启' : '关闭');
  console.info('屏幕朗读:', screenReaderEnabled ? '开启' : '关闭');
  console.info('辅助应用数量:', abilitiesList.length);
  
  console.info('=== 查询完成 ===');
}

/**
 * 主函数
 */
@Entry
@Component
struct QueryAccessibilityStateExample {
  build() {
    Column() {
      Button('查询无障碍状态')
        .onClick(() => {
          queryAllAccessibilityStates();
        })
        .width('80%')
        .margin(20);
      
      Text('点击按钮查询当前系统的无障碍服务状态')
        .fontSize(14)
        .textAlign(TextAlign.Center);
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}