import { invoiceAssistant } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct InvoiceTitleExample {
  @State invoiceTitleInfo: string = '';

  build() {
    Column() {
      Text('发票抬头示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Button('获取发票抬头')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.selectInvoiceTitle();
        });

      if (this.invoiceTitleInfo !== '') {
        Text(this.invoiceTitleInfo)
          .fontSize(16)
          .margin({ top: 20 })
          .width('80%');
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  private selectInvoiceTitle(): void {
    if (!canIUse('SystemCapability.HuaweiID.InvoiceAssistant')) {
      hilog.info(0x0000, 'InvoiceTitleExample',
        'The current device does not support the invoking of the selectInvoiceTitle interface.');
      this.invoiceTitleInfo = '当前设备不支持发票助手服务';
      return;
    }

    try {
      invoiceAssistant.selectInvoiceTitle(this.getUIContext().getHostContext())
        .then((data: invoiceAssistant.InvoiceTitle) => {
          hilog.info(0x0000, 'InvoiceTitleExample', 'Succeeded in selecting invoice title');
          
          const type: string = data.type;
          const title: string = data.title;
          const taxNumber: string = data.taxNumber;
          const companyAddress: string = data.companyAddress;
          const telephone: string = data.telephone;
          const bankName: string = data.bankName;
          const bankAccount: string = data.bankAccount;

          if (type === '0') {
            this.invoiceTitleInfo = `个人发票抬头:\n名称: ${title}`;
          } else if (type === '1') {
            this.invoiceTitleInfo = `企业发票抬头:\n名称: ${title}\n税号: ${taxNumber}\n地址: ${companyAddress}\n电话: ${telephone}\n银行: ${bankName}\n账户: ${bankAccount}`;
          }

          this.processInvoiceTitle(data);
        })
        .catch((error: BusinessError<Object>) => {
          this.handleError(error);
        });
    } catch (error) {
      this.handleError(error as BusinessError<Object>);
    }
  }

  private processInvoiceTitle(data: invoiceAssistant.InvoiceTitle): void {
    hilog.info(0x0000, 'InvoiceTitleExample', 'Processing invoice title data...');
    
    const type: string = data.type;
    const title: string = data.title;
    const taxNumber: string = data.taxNumber;
    const companyAddress: string = data.companyAddress;
    const telephone: string = data.telephone;
    const bankName: string = data.bankName;
    const bankAccount: string = data.bankAccount;

    if (type === '0') {
      hilog.info(0x0000, 'InvoiceTitleExample', `Personal invoice title: ${title}`);
    } else if (type === '1') {
      hilog.info(0x0000, 'InvoiceTitleExample',
        `Company invoice title: ${title}, Tax: ${taxNumber}, Address: ${companyAddress}, Tel: ${telephone}, Bank: ${bankName}, Account: ${bankAccount}`);
    }
  }

  private handleError(error: BusinessError<Object>): void {
    hilog.error(0x0000, 'InvoiceTitleExample',
      `Failed to selectInvoiceTitle. Code: ${error.code}, message: ${error.message}`);
    
    switch (error.code) {
      case 401:
        this.invoiceTitleInfo = '参数错误,请检查Context参数';
        break;
      case 1010060001:
        this.invoiceTitleInfo = '用户取消了操作';
        break;
      case 1010060002:
        this.invoiceTitleInfo = '系统内部错误,请稍后重试';
        break;
      case 1010060003:
        this.invoiceTitleInfo = '应用配置错误,请检查签名和指纹配置';
        break;
      case 1010060004:
        this.invoiceTitleInfo = '操作过于频繁,请稍后重试';
        break;
      case 1010060005:
        this.invoiceTitleInfo = '网络连接错误,请检查网络状态';
        break;
      case 1010060006:
        this.invoiceTitleInfo = '用户未登录华为账号,请先登录';
        break;
      case 1010060007:
        this.invoiceTitleInfo = '发票抬头已存在';
        break;
      case 1010060008:
        this.invoiceTitleInfo = '当前账号不支持发票助手服务';
        break;
      default:
        this.invoiceTitleInfo = `未知错误: ${error.code}`;
    }
  }
}