import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct InvoiceExample {
  /**
   * 拉起开发票页面
   */
  showManagedInvoices() {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    
    // 从订单信息中获取purchaseOrderId
    // 实际应用中需要从购买结果或订单查询接口获取
    let purchaseOrderId = 'ORDER_ID_123456789';
    
    // 调用iap.showManagedInvoices拉起开发票页面
    iap.showManagedInvoices(context, purchaseOrderId).then(() => {
      // 请求成功
      console.info('Succeeded in showing invoice page.');
      // 开发票页面已拉起，用户可在此页面填写发票信息
    }).catch((err: BusinessError) => {
      // 请求失败
      console.error(`Failed to show invoice page. Code is ${err.code}, message is ${err.message}`);
      // 根据错误码处理异常
      this.handleInvoiceError(err);
    });
  }
  
  /**
   * 处理开票错误
   */
  handleInvoiceError(err: BusinessError) {
    switch (err.code) {
      case 1001860000:
        console.info('User canceled the invoice operation.');
        break;
      case 1001860005:
        console.error('Network connection error.');
        break;
      case 1001860050:
        console.error('HUAWEI ID is not signed in.');
        break;
      default:
        console.error(`Unknown error: ${err.message}`);
        break;
    }
  }
  
  build() {
    Column() {
      Button('申请开发票')
        .onClick(() => {
          this.showManagedInvoices();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}