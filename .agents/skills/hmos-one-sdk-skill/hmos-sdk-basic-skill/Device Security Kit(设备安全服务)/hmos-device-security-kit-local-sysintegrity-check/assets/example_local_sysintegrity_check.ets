/**
 * 本地系统完整性检测示例代码
 * 功能：检测设备本地系统完整性，判断是否被越狱、模拟器或攻击
 * API版本：≥5.1.0(18)
 */

import { safetyDetect } from '@kit.DeviceSecurityKit';
import { BusinessError } from '@ohos.base';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AlertDialog } from '@kit.ArkUI';

const TAG = "LocalSysIntegrityCheck";
const LOG_DOMAIN = 0x0000;

/**
 * 系统完整性检测结果结构
 */
interface SysIntegrityResult {
  basicIntegrity: boolean;
  detail?: string[];
}

/**
 * 执行本地系统完整性检测
 * @returns 检测结果JSON字符串
 */
async function checkLocalSysIntegrity(): Promise<string> {
  try {
    hilog.info(LOG_DOMAIN, TAG, '开始本地系统完整性检测');
    
    const result: string = await safetyDetect.checkSysIntegrityOnLocal();
    
    hilog.info(LOG_DOMAIN, TAG, '检测成功: %{public}s', result);
    return result;
    
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    hilog.error(LOG_DOMAIN, TAG, '检测失败: %{public}d %{public}s', e.code, e.message);
    throw e;
  }
}

/**
 * 解析系统完整性检测结果JSON
 * @param jsonResult JSON格式检测结果
 * @returns 解析后的结果对象
 */
function parseSysIntegrityResult(jsonResult: string): SysIntegrityResult {
  try {
    const result: SysIntegrityResult = JSON.parse(jsonResult);
    
    if (result.basicIntegrity) {
      hilog.info(LOG_DOMAIN, TAG, '设备系统完整性正常');
    } else {
      hilog.warn(LOG_DOMAIN, TAG, '设备存在安全风险');
      
      if (result.detail && result.detail.length > 0) {
        result.detail.forEach((risk: string) => {
          switch (risk) {
            case 'jailbreak':
              hilog.warn(LOG_DOMAIN, TAG, '风险：设备被越狱');
              break;
            case 'emulator':
              hilog.warn(LOG_DOMAIN, TAG, '风险：设备为模拟器');
              break;
            case 'attack':
              hilog.warn(LOG_DOMAIN, TAG, '风险：设备被攻击');
              break;
            case 'unlock':
              hilog.warn(LOG_DOMAIN, TAG, '风险：设备被解锁');
              break;
            default:
              hilog.warn(LOG_DOMAIN, TAG, '风险：未知类型 %{public}s', risk);
          }
        });
      }
    }
    
    return result;
    
  } catch (e) {
    hilog.error(LOG_DOMAIN, TAG, '解析检测结果失败');
    throw e;
  }
}

/**
 * 显示安全警告对话框
 * @param risks 风险详情列表
 */
function showSecurityWarning(risks?: string[]): void {
  let message = '您的设备疑似存在风险或运行在不安全环境中，请谨慎使用此功能。';
  
  if (risks && risks.length > 0) {
    message += '\n\n检测到的风险：';
    
    if (risks.includes('jailbreak')) {
      message += '\n• 设备被越狱';
    }
    if (risks.includes('emulator')) {
      message += '\n• 设备为模拟器';
    }
    if (risks.includes('attack')) {
      message += '\n• 设备被攻击';
    }
    if (risks.includes('unlock')) {
      message += '\n• 设备被解锁';
    }
  }
  
  AlertDialog.show({
    title: '安全提示',
    message: message,
    confirm: {
      value: '我知道了',
      action: () => {
        hilog.info(LOG_DOMAIN, TAG, '用户已知晓安全提示');
      }
    }
  });
}

/**
 * 完整的检测流程（包含错误处理）
 */
async function performLocalSysIntegrityCheck(): Promise<void> {
  try {
    const jsonResult = await checkLocalSysIntegrity();
    const integrityData = parseSysIntegrityResult(jsonResult);
    
    if (!integrityData.basicIntegrity) {
      showSecurityWarning(integrityData.detail);
    } else {
      hilog.info(LOG_DOMAIN, TAG, '设备环境安全，可以继续操作');
    }
    
  } catch (err) {
    const e: BusinessError = err as BusinessError;
    
    switch (e.code) {
      case 801:
        AlertDialog.show({
          title: '提示',
          message: '当前设备不支持此功能，请检查系统版本',
          confirm: { value: '确定', action: () => {} }
        });
        break;
        
      case 1010800001:
        AlertDialog.show({
          title: '提示',
          message: '检测失败，请稍后重试',
          confirm: { value: '确定', action: () => {} }
        });
        break;
        
      case 1010800004:
        AlertDialog.show({
          title: '提示',
          message: '请先在AppGallery Connect开通"安全检测服务"',
          confirm: { value: '了解详情', action: () => {} }
        });
        break;
        
      case 1010800005:
        AlertDialog.show({
          title: '提示',
          message: '系统繁忙，请稍后重试',
          confirm: { value: '确定', action: () => {} }
        });
        break;
        
      case 1010800006:
        AlertDialog.show({
          title: '提示',
          message: '检测次数过多，请稍后再试',
          confirm: { value: '确定', action: () => {} }
        });
        break;
        
      case 1010800007:
        AlertDialog.show({
          title: '提示',
          message: '检测超时，请重试',
          confirm: { value: '确定', action: () => {} }
        });
        break;
        
      default:
        AlertDialog.show({
          title: '提示',
          message: '检测失败，请稍后重试',
          confirm: { value: '确定', action: () => {} }
        });
    }
  }
}

/**
 * 入口页面示例
 */
@Entry
@Component
struct LocalSysIntegrityCheckPage {
  @State checkResult: string = '';
  @State isChecking: boolean = false;
  
  build() {
    Column({ space: 20 }) {
      Text('本地系统完整性检测')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      Text('检测设备是否被越狱、模拟器或攻击')
        .fontSize(16)
        .opacity(0.7)
      
      Button('开始检测')
        .width('80%')
        .height(50)
        .enabled(!this.isChecking)
        .onClick(async () => {
          this.isChecking = true;
          this.checkResult = '正在检测...';
          
          try {
            const result = await checkLocalSysIntegrity();
            this.checkResult = result;
            const integrityData = parseSysIntegrityResult(result);
            
            if (!integrityData.basicIntegrity) {
              showSecurityWarning(integrityData.detail);
            }
            
          } catch (e) {
            this.checkResult = '检测失败';
          } finally {
            this.isChecking = false;
          }
        })
      
      if (this.checkResult !== '') {
        Text('检测结果：')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        
        Text(this.checkResult)
          .fontSize(14)
          .width('90%')
          .border({ width: 1, color: Color.Gray })
          .padding(10)
      }
      
      Text('说明：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      
      Text('• 无需联网，本地快速检测')
        .fontSize(14)
      
      Text('• 检测设备是否被越狱、模拟器、攻击')
        .fontSize(14)
      
      Text('• 适用于无法接入服务端的安全评估场景')
        .fontSize(14)
      
      Text('• 需在AppGallery Connect开通"安全检测服务"')
        .fontSize(14)
        .fontColor(Color.Red)
      
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }
}