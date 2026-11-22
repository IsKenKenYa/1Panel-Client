import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct InvoiceWithErrorHandler {
  @State purchaseOrderId: string = '';
  @State isLoading: boolean = false;
  
  /**
   * 拉起开发票页面（带完整错误处理和降级方案）
   */
  async showManagedInvoicesWithHandling() {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    
    // 参数校验
    if (!this.purchaseOrderId || this.purchaseOrderId.trim() === '') {
      promptAction.showToast({
        message: '订单号无效，请检查订单信息',
        duration: 2000
      });
      return;
    }
    
    this.isLoading = true;
    
    try {
      // 调用iap.showManagedInvoices拉起开发票页面
      await iap.showManagedInvoices(context, this.purchaseOrderId);
      
      // 请求成功
      console.info('Succeeded in showing invoice page.');
      promptAction.showToast({
        message: '开发票页面已打开，请填写发票信息',
        duration: 2000
      });
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to show invoice page. Code is ${err.code}, message is ${err.message}`);
      
      // 错误处理
      this.handleInvoiceErrorWithFallback(err, context);
      
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 错误处理（带降级方案）
   */
  handleInvoiceErrorWithFallback(err: BusinessError, context: common.UIAbilityContext) {
    let errorMessage = '';
    let showFallbackOption = false;
    
    switch (err.code) {
      case 1001860000:
        // 用户取消操作
        errorMessage = '您已取消开发票操作';
        console.info('User canceled the invoice operation.');
        break;
        
      case 1001860001:
        // 系统内部错误
        errorMessage = '系统错误，请稍后重试';
        showFallbackOption = true;
        console.error('System internal error.');
        break;
        
      case 1001860002:
        // 应用未授权
        errorMessage = '应用未授权访问发票功能';
        console.error('App is not authorized.');
        break;
        
      case 1001860004:
        // 接口访问过频
        errorMessage = '请稍后再试';
        console.error('Too frequent API calls.');
        break;
        
      case 1001860005:
        // 网络连接异常
        errorMessage = '网络异常，请检查网络连接后重试';
        showFallbackOption = true;
        console.error('Network connection error.');
        break;
        
      case 1001860050:
        // 未登录华为账号
        errorMessage = '请先登录华为账号';
        console.error('HUAWEI ID is not signed in.');
        // 可以引导用户登录
        break;
        
      case 1001860054:
        // 用户账号所在服务地暂不支持IAP
        errorMessage = '当前地区暂不支持发票功能';
        showFallbackOption = true;
        console.error('The country or region does not support IAP.');
        break;
        
      case 401:
        // 参数错误
        errorMessage = '订单信息无效';
        console.error('Parameter error.');
        break;
        
      default:
        // 其他错误
        errorMessage = `开发票失败，请稍后重试或联系客服`;
        showFallbackOption = true;
        console.error(`Unknown error: ${err.message}`);
        break;
    }
    
    // 显示错误提示
    promptAction.showToast({
      message: errorMessage,
      duration: 3000
    });
    
    // 提供降级方案
    if (showFallbackOption) {
      this.showFallbackDialog();
    }
  }
  
  /**
   * 显示降级方案对话框
   */
  showFallbackDialog() {
    promptAction.showDialog({
      title: '开发票功能暂时不可用',
      message: '您可以前往：手机设置 > 华为账号 > 付款与账单 > 发票中心 申请开发票',
      buttons: [
        { text: '知道了', color: '#666666' },
        { text: '查看帮助', color: '#007DFF' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击"查看帮助"，可以跳转到帮助页面或打开系统设置
        console.info('User clicked help button');
      }
    });
  }
  
  build() {
    Column() {
      // 订单号输入框（实际应用中应该从订单详情自动获取）
      TextInput({ placeholder: '请输入订单号', text: this.purchaseOrderId })
        .onChange((value) => {
          this.purchaseOrderId = value;
        })
        .width('80%')
        .height(50)
        .margin({ bottom: 20 })
      
      // 开发票按钮
      Button(this.isLoading ? '正在处理...' : '申请开发票')
        .onClick(() => {
          if (!this.isLoading) {
            this.showManagedInvoicesWithHandling();
          }
        })
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .backgroundColor(this.isLoading ? '#CCCCCC' : '#007DFF')
      
      // 说明文字
      Text('说明：点击按钮后将拉起华为官方开发票页面，您可以在页面中填写发票信息并提交申请。')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .width('80%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }
}