import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';

@Entry
@Component
struct TurnOffMinorsModePage {
  private TAG = 'TurnOffMinorsMode';
  private DOMAIN = 0x0000;
  
  private cachedMinorsMode: boolean = false;
  private cachedAgeGroup: minorsProtection.AgeGroup | undefined = undefined;
  
  aboutToAppear() {
    this.checkAndSubscribeMinorsMode();
  }
  
  aboutToDisappear() {
    this.unsubscribeMinorsMode();
  }
  
  checkAndSubscribeMinorsMode() {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      hilog.info(this.DOMAIN, this.TAG, 'Device does not support minors protection.');
      return;
    }
    
    try {
      if (!minorsProtection.supportMinorsMode()) {
        hilog.info(this.DOMAIN, this.TAG, 'Current environment does not support minors mode.');
        return;
      }
      
      const info = minorsProtection.getMinorsProtectionInfoSync();
      this.cachedMinorsMode = info.minorsProtectionMode;
      this.cachedAgeGroup = info.ageGroup;
      
      hilog.info(this.DOMAIN, this.TAG, 
        `Minors mode status: ${this.cachedMinorsMode}, AgeGroup: ${this.cachedAgeGroup ? 
          `[${this.cachedAgeGroup.lowerAge}, ${this.cachedAgeGroup.upperAge})` : 'undefined'}`);
      
      this.subscribeMinorsModeEvent();
      
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, 
        `Failed to get minors mode info. Code: ${error.code}, Message: ${error.message}`);
    }
  }
  
  subscribeMinorsModeEvent() {
    try {
      const offSubscriber = commonEventManager.createSubscriber({
        events: ['usual.event.MINORSMODE_OFF']
      });
      
      commonEventManager.subscribe(offSubscriber, (err, data) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, 'Received minors mode OFF event.');
          this.cachedMinorsMode = false;
          this.cachedAgeGroup = undefined;
        }
      });
      
      const onSubscriber = commonEventManager.createSubscriber({
        events: ['usual.event.MINORSMODE_ON']
      });
      
      commonEventManager.subscribe(onSubscriber, (err, data) => {
        if (!err) {
          hilog.info(this.DOMAIN, this.TAG, 'Received minors mode ON event.');
          const newInfo = minorsProtection.getMinorsProtectionInfoSync();
          this.cachedMinorsMode = newInfo.minorsProtectionMode;
          this.cachedAgeGroup = newInfo.ageGroup;
        }
      });
      
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, 
        `Failed to subscribe minors mode event. Code: ${error.code}, Message: ${error.message}`);
    }
  }
  
  unsubscribeMinorsMode() {
    try {
      commonEventManager.unsubscribe(this.offSubscriber);
      commonEventManager.unsubscribe(this.onSubscriber);
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, 
        `Failed to unsubscribe. Code: ${error.code}, Message: ${error.message}`);
    }
  }
  
  build() {
    Column() {
      Text('关闭系统的未成年人模式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      Text(`当前状态: ${this.cachedMinorsMode ? '已开启' : '已关闭'}`)
        .fontSize(16)
        .margin({ bottom: 10 });
      
      if (this.cachedAgeGroup) {
        Text(`年龄段: [${this.cachedAgeGroup.lowerAge}, ${this.cachedAgeGroup.upperAge})`)
          .fontSize(16)
          .margin({ bottom: 10 });
      }
      
      if (this.cachedMinorsMode) {
        Button('关闭系统未成年人模式')
          .width('80%')
          .height(50)
          .fontSize(18)
          .margin({ top: 20 })
          .onClick(() => {
            this.turnOffMinorsMode();
          });
        
        Text('提示：关闭系统未成年人模式后，其他应用的未成年人模式也会关闭')
          .fontSize(14)
          .fontColor('#FF9800')
          .margin({ top: 10 });
      } else {
        Text('未成年人模式已关闭，无需操作')
          .fontSize(16)
          .fontColor('#4CAF50')
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
  
  turnOffMinorsMode() {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.showAlertDialog('当前设备不支持未成年人模式');
      return;
    }
    
    try {
      if (!minorsProtection.supportMinorsMode()) {
        this.showAlertDialog('当前设备环境不支持未成年人模式');
        return;
      }
      
      if (!this.cachedMinorsMode) {
        this.showAlertDialog('未成年人模式已关闭，无需操作');
        return;
      }
      
      minorsProtection.leadToTurnOffMinorsMode(this.getUIContext().getHostContext())
        .then(() => {
          hilog.info(this.DOMAIN, this.TAG, 'Successfully turned off minors mode.');
          this.showAlertDialog('系统未成年人模式已关闭');
          this.cachedMinorsMode = false;
          this.cachedAgeGroup = undefined;
        })
        .catch((error: BusinessError<Object>) => {
          this.handleTurnOffError(error);
        });
        
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, 
        `Failed to turn off minors mode. Code: ${error.code}, Message: ${error.message}`);
      this.showAlertDialog('关闭失败，请稍后重试');
    }
  }
  
  handleTurnOffError(error: BusinessError<Object>) {
    let message = '';
    
    switch (error.code) {
      case 1009900003:
        message = '用户取消操作';
        hilog.warn(this.DOMAIN, this.TAG, 'User canceled the operation.');
        break;
      case 1009900006:
        message = '未成年人模式已关闭';
        hilog.info(this.DOMAIN, this.TAG, 'Minors mode is already off.');
        this.cachedMinorsMode = false;
        break;
      case 1009900011:
        message = '服务不可用，请检查网络连接后重试';
        hilog.error(this.DOMAIN, this.TAG, 'Service is not available.');
        break;
      case 401:
        message = '参数错误，Context无效';
        hilog.error(this.DOMAIN, this.TAG, 'Parameter error: invalid context.');
        break;
      case 1001502009:
        message = '内部错误，请稍后重试';
        hilog.error(this.DOMAIN, this.TAG, 'Internal error occurred.');
        break;
      default:
        message = `未知错误(${error.code})，请稍后重试`;
        hilog.error(this.DOMAIN, this.TAG, 
          `Unknown error. Code: ${error.code}, Message: ${error.message}`);
        break;
    }
    
    this.showAlertDialog(message);
  }
  
  showAlertDialog(message: string) {
    AlertDialog.show({
      title: '提示',
      message: message,
      buttons: [
        {
          text: '确定',
          action: () => {
            hilog.info(this.DOMAIN, this.TAG, 'Dialog confirmed.');
          }
        }
      ]
    });
  }
}