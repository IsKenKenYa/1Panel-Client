import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { getContext } from '@kit.AbilityKit';

@Entry
@Component
struct HoldingHandExample {
  @State currentHoldingHand: number = motion.HoldingHandStatus.UNKNOWN_STATUS;
  @State subscribeStatus: string = '未订阅';
  @State errorMessage: string = '';
  @State apiVersionSupported: boolean = false;
  
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
  
  aboutToAppear(): void {
    this.checkAPIVersion();
    this.startHoldingHandSubscription();
  }
  
  aboutToDisappear(): void {
    this.unsubscribeHoldingHand();
  }
  
  checkAPIVersion(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const apiVersion = context.applicationInfo.apiVersion;
      
      this.apiVersionSupported = apiVersion >= 20;
      
      if (!this.apiVersionSupported) {
        this.errorMessage = '当前API版本不支持握持手感知，需要API version 20+';
      }
    } catch (error) {
      console.error('获取API版本失败');
      this.apiVersionSupported = false;
    }
  }
  
  startHoldingHandSubscription(): void {
    if (!this.apiVersionSupported) {
      console.warn('API版本不支持，跳过订阅');
      return;
    }
    
    this.holdingHandCallback = (data: motion.HoldingHandStatus) => {
      this.currentHoldingHand = data;
      this.errorMessage = '';
      console.info('握持手状态变化: ' + data);
      this.adjustCameraLayout();
    };
    
    try {
      motion.on('holdingHandChanged', this.holdingHandCallback);
      this.subscribeStatus = '已订阅';
      console.info('订阅握持手成功');
    } catch (err) {
      let error = err as BusinessError;
      this.subscribeStatus = '订阅失败';
      this.errorMessage = '订阅失败，错误码: ' + error.code;
      console.error('订阅握持手失败: ' + error.code);
      
      this.handleHoldingHandError(error);
    }
  }
  
  unsubscribeHoldingHand(): void {
    if (!this.apiVersionSupported) {
      return;
    }
    
    try {
      motion.off('holdingHandChanged');
      this.subscribeStatus = '未订阅';
      this.holdingHandCallback = null;
      console.info('取消订阅握持手成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('取消订阅失败: ' + error.code);
    }
  }
  
  handleHoldingHandError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        this.errorMessage = '缺少 ohos.permission.DETECT_GESTURE 权限';
        break;
      case 801:
        this.errorMessage = '设备不支持握持手感知，检查设置菜单是否有"智感握姿"开关';
        break;
      case 31500001:
        this.errorMessage = '服务异常，稍后重试';
        setTimeout(() => this.startHoldingHandSubscription(), 1000);
        break;
      case 31500002:
        this.errorMessage = '订阅失败';
        break;
      default:
        this.errorMessage = '未知错误: ' + error.code;
    }
  }
  
  adjustCameraLayout(): void {
    switch (this.currentHoldingHand) {
      case motion.HoldingHandStatus.LEFT_HAND_HELD:
        console.info('左手握持 - 调整相机按钮到左侧');
        break;
      case motion.HoldingHandStatus.RIGHT_HAND_HELD:
        console.info('右手握持 - 调整相机按钮到右侧');
        break;
      case motion.HoldingHandStatus.BOTH_HANDS_HELD:
        console.info('双手握持 - 使用标准布局');
        break;
      case motion.HoldingHandStatus.NOT_HELD:
        console.info('未握持 - 提示用户握持设备');
        break;
      case motion.HoldingHandStatus.UNKNOWN_STATUS:
        console.info('未识别 - 使用默认布局');
        break;
    }
  }
  
  getHoldingHandText(): string {
    switch (this.currentHoldingHand) {
      case motion.HoldingHandStatus.LEFT_HAND_HELD:
        return '左手握持';
      case motion.HoldingHandStatus.RIGHT_HAND_HELD:
        return '右手握持';
      case motion.HoldingHandStatus.BOTH_HANDS_HELD:
        return '双手握持';
      case motion.HoldingHandStatus.NOT_HELD:
        return '未握持';
      case motion.HoldingHandStatus.UNKNOWN_STATUS:
        return '未识别';
      default:
        return '未知状态';
    }
  }
  
  build() {
    Column({ space: 20 }) {
      Text('握持手感知示例（API version 20+）')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
      }
      
      Row({ space: 10 }) {
        Text('API版本支持: ')
          .fontSize(16)
        Text(this.apiVersionSupported ? '是 (>= 20)' : '否')
          .fontSize(16)
          .fontColor(this.apiVersionSupported ? Color.Green : Color.Red)
      }
      
      Row({ space: 10 }) {
        Text('当前状态: ')
          .fontSize(16)
        Text(this.getHoldingHandText())
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      
      Row({ space: 10 }) {
        Text('订阅状态: ')
          .fontSize(16)
        Text(this.subscribeStatus)
          .fontSize(16)
          .fontColor(this.subscribeStatus === '已订阅' ? Color.Green : Color.Blue)
      }
      
      if (this.apiVersionSupported) {
        Button('订阅握持手状态')
          .onClick(() => {
            this.startHoldingHandSubscription();
          })
          .enabled(this.subscribeStatus !== '已订阅')
        
        Button('取消订阅')
          .onClick(() => {
            this.unsubscribeHoldingHand();
          })
          .enabled(this.subscribeStatus === '已订阅')
      }
      
      Divider()
      
      Text('握持手感知要求:')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      
      Text('1. 设备需有"智感握姿"开关并已开启')
        .fontSize(14)
      
      Text('2. 设备亮屏且解锁')
        .fontSize(14)
      
      Text('3. 五指自然握持，掌心区域接触设备')
        .fontSize(14)
      
      Text('4. 保护壳厚度不超过3mm')
        .fontSize(14)
      
      Text('5. 竖屏握持时，摄像头朝上')
        .fontSize(14)
      
      Text('6. 屏幕朝向握持人')
        .fontSize(14)
      
      Text('7. 不佩戴手套，不接触其他物体')
        .fontSize(14)
      
      Text('8. 每根手指接触面积>=30mm²')
        .fontSize(14)
    }
    .width('100%')
    .padding(20)
  }
}