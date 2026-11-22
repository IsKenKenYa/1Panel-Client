import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit';

@Entry
@Component
struct OperatingHandExample {
  @State currentOperatingHand: number = motion.OperatingHandStatus.UNKNOWN_STATUS;
  @State subscribeStatus: string = '未订阅';
  @State errorMessage: string = '';
  @State deviceSupport: boolean = false;
  
  private operatingHandCallback: Callback<motion.OperatingHandStatus> | null = null;
  
  aboutToAppear(): void {
    this.checkDeviceSupport();
    this.checkPermission();
    this.initializeOperatingHandStatus();
  }
  
  aboutToDisappear(): void {
    this.unsubscribeOperatingHand();
  }
  
  async checkDeviceSupport(): Promise<void> {
    try {
      const testCallback = (data: motion.OperatingHandStatus) => {
        console.info('设备支持操作手感知');
      };
      
      motion.on('operatingHandChanged', testCallback);
      motion.off('operatingHandChanged');
      
      this.deviceSupport = true;
      this.errorMessage = '';
    } catch (err) {
      let error = err as BusinessError;
      if (error.code === 801) {
        this.deviceSupport = false;
        this.errorMessage = '设备不支持多模态感知能力';
      }
    }
  }
  
  async checkPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_PERMISSION);
      
      const hasPermission = bundleInfo.requestPermissions.some(p =>
        p.name === 'ohos.permission.ACTIVITY_MOTION' || p.name === 'ohos.permission.DETECT_GESTURE'
      );
      
      if (!hasPermission) {
        this.errorMessage = '缺少必要权限配置';
      }
    } catch (error) {
      console.error('权限检查失败');
    }
  }
  
  initializeOperatingHandStatus(): void {
    try {
      this.currentOperatingHand = motion.getRecentOperatingHandStatus();
      console.info('初始操作手状态: ' + this.currentOperatingHand);
    } catch (err) {
      let error = err as BusinessError;
      console.error('初始化状态失败: ' + error.code);
      this.errorMessage = '获取初始状态失败，错误码: ' + error.code;
    }
  }
  
  subscribeOperatingHand(): void {
    if (!this.deviceSupport) {
      this.errorMessage = '设备不支持，无法订阅';
      return;
    }
    
    this.operatingHandCallback = (data: motion.OperatingHandStatus) => {
      this.currentOperatingHand = data;
      this.errorMessage = '';
      console.info('操作手状态变化: ' + data);
      this.adjustUILayout();
    };
    
    try {
      motion.on('operatingHandChanged', this.operatingHandCallback);
      this.subscribeStatus = '已订阅';
      this.errorMessage = '';
      console.info('订阅操作手成功');
    } catch (err) {
      let error = err as BusinessError;
      this.subscribeStatus = '订阅失败';
      this.errorMessage = '订阅失败，错误码: ' + error.code;
      console.error('订阅操作手失败: ' + error.code);
      
      this.handleOperatingHandError(error);
    }
  }
  
  unsubscribeOperatingHand(): void {
    try {
      motion.off('operatingHandChanged');
      this.subscribeStatus = '未订阅';
      this.operatingHandCallback = null;
      console.info('取消订阅成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error('取消订阅失败: ' + error.code);
    }
  }
  
  handleOperatingHandError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        this.errorMessage = '权限不足，请检查权限配置';
        break;
      case 401:
        this.errorMessage = '参数错误，请检查回调函数';
        break;
      case 801:
        this.errorMessage = '设备不支持操作手感知';
        break;
      case 31500001:
        this.errorMessage = '服务异常，稍后重试';
        setTimeout(() => this.subscribeOperatingHand(), 1000);
        break;
      case 31500002:
        this.errorMessage = '订阅失败，检查回调函数';
        break;
      default:
        this.errorMessage = '未知错误: ' + error.code;
    }
  }
  
  adjustUILayout(): void {
    switch (this.currentOperatingHand) {
      case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
        console.info('左手操作 - 调整UI为左手友好布局');
        break;
      case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
        console.info('右手操作 - 调整UI为右手友好布局');
        break;
      case motion.OperatingHandStatus.UNKNOWN_STATUS:
        console.info('未识别 - 使用默认布局');
        break;
    }
  }
  
  getOperatingHandText(): string {
    switch (this.currentOperatingHand) {
      case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
        return '左手操作';
      case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
        return '右手操作';
      case motion.OperatingHandStatus.UNKNOWN_STATUS:
        return '未识别';
      default:
        return '未知状态';
    }
  }
  
  build() {
    Column({ space: 20 }) {
      Text('操作手感知示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor(Color.Red)
      }
      
      Row({ space: 10 }) {
        Text('设备支持: ')
          .fontSize(16)
        Text(this.deviceSupport ? '是' : '否')
          .fontSize(16)
          .fontColor(this.deviceSupport ? Color.Green : Color.Red)
      }
      
      Row({ space: 10 }) {
        Text('当前状态: ')
          .fontSize(16)
        Text(this.getOperatingHandText())
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
      
      Button('订阅操作手状态')
        .onClick(() => {
          this.subscribeOperatingHand();
        })
        .enabled(this.subscribeStatus !== '已订阅' && this.deviceSupport)
      
      Button('取消订阅')
        .onClick(() => {
          this.unsubscribeOperatingHand();
        })
        .enabled(this.subscribeStatus === '已订阅')
      
      Button('获取最新状态')
        .onClick(() => {
          this.initializeOperatingHandStatus();
        })
      
      Divider()
      
      Text('使用说明:')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      
      Text('1. 在屏幕中心区域进行单指触控操作')
        .fontSize(14)
      
      Text('2. 避免屏幕边缘8mm区域')
        .fontSize(14)
      
      Text('3. 不支持多指同时操作')
        .fontSize(14)
      
      Text('4. 连续点数次后触发识别')
        .fontSize(14)
    }
    .width('100%')
    .padding(20)
  }
}