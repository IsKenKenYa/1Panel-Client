/**
 * 发票抬头选择完整示例
 * 功能：展示如何使用Account Kit的发票助手能力获取用户发票抬头信息
 * 
 * 本示例包含：
 * 1. 完整的发票抬头选择流程
 * 2. 错误处理和降级方案
 * 3. 个人和企业抬头的数据处理
 * 4. UI组件示例
 */

import { invoiceAssistant } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG = 'InvoiceTitleExample';
const DOMAIN = 0x0000;

/**
 * 发票抬头数据接口
 */
interface InvoiceTitleData {
  type: string;              // 抬头类型：'0'-个人，'1'-企业
  title: string;             // 抬头名称
  taxNumber: string;         // 纳税人识别号
  companyAddress: string;    // 公司地址
  telephone: string;         // 公司电话
  bankName: string;          // 银行名称
  bankAccount: string;       // 银行账户
}

/**
 * 发票抬头选择结果接口
 */
interface InvoiceTitleResult {
  status: 'success' | 'failed' | 'canceled';
  errorCode?: number;
  errorMessage?: string;
  data?: InvoiceTitleData;
}

/**
 * 发票抬头选择服务类
 */
export class InvoiceTitleService {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  /**
   * 检查设备是否支持发票助手能力
   * @returns boolean - 是否支持
   */
  private checkDeviceCapability(): boolean {
    const isSupported = canIUse('SystemCapability.HuaweiID.InvoiceAssistant');
    if (!isSupported) {
      hilog.warn(DOMAIN, TAG, '当前设备不支持发票助手服务');
    }
    return isSupported;
  }

  /**
   * 选择发票抬头
   * @returns Promise<InvoiceTitleResult> - 选择结果
   */
  async selectInvoiceTitle(): Promise<InvoiceTitleResult> {
    // 检查设备能力
    if (!this.checkDeviceCapability()) {
      return {
        status: 'failed',
        errorCode: -1,
        errorMessage: '当前设备不支持发票助手服务'
      };
    }

    try {
      hilog.info(DOMAIN, TAG, '开始调用发票抬头选择接口');
      
      // 调用发票抬头选择接口
      const invoiceTitle = await invoiceAssistant.selectInvoiceTitle(this.context);
      
      hilog.info(DOMAIN, TAG, '成功选择发票抬头');
      
      // 构造返回数据
      const titleData: InvoiceTitleData = {
        type: invoiceTitle.type,
        title: invoiceTitle.title,
        taxNumber: invoiceTitle.taxNumber,
        companyAddress: invoiceTitle.companyAddress,
        telephone: invoiceTitle.telephone,
        bankName: invoiceTitle.bankName,
        bankAccount: invoiceTitle.bankAccount
      };

      return {
        status: 'success',
        data: titleData
      };
    } catch (error) {
      const businessError = error as BusinessError<Object>;
      hilog.error(DOMAIN, TAG, 
        `选择发票抬头失败。错误码: ${businessError.code}, 错误信息: ${businessError.message}`);
      
      // 根据错误码判断是取消还是失败
      if (businessError.code === 1010060001) {
        return {
          status: 'canceled',
          errorCode: businessError.code,
          errorMessage: businessError.message
        };
      } else {
        return {
          status: 'failed',
          errorCode: businessError.code,
          errorMessage: businessError.message
        };
      }
    }
  }

  /**
   * 格式化发票抬头信息为可读文本
   * @param data - 发票抬头数据
   * @returns string - 格式化后的文本
   */
  formatInvoiceTitle(data: InvoiceTitleData): string {
    const typeText = data.type === '0' ? '个人' : '企业';
    let text = `抬头类型: ${typeText}\n`;
    text += `抬头名称: ${data.title}\n`;
    
    if (data.type === '1') {
      // 企业抬头显示完整信息
      text += `纳税人识别号: ${data.taxNumber}\n`;
      text += `公司地址: ${data.companyAddress}\n`;
      text += `公司电话: ${data.telephone}\n`;
      text += `开户银行: ${data.bankName}\n`;
      text += `银行账户: ${data.bankAccount}`;
    }
    
    return text;
  }

  /**
   * 处理错误信息
   * @param errorCode - 错误码
   * @returns string - 用户友好的错误提示
   */
  getErrorMessage(errorCode: number): string {
    switch (errorCode) {
      case 1010060001:
        return '您已取消选择发票抬头';
      case 1010060002:
        return '系统内部错误，请稍后重试';
      case 1010060003:
        return '应用配置错误，请检查签名和指纹配置';
      case 1010060004:
        return '操作过于频繁，请稍后重试';
      case 1010060005:
        return '网络连接错误，请检查网络后重试';
      case 1010060006:
        return '您尚未登录华为账号，请先登录';
      case 1010060007:
        return '该发票抬头已存在';
      case 1010060008:
        return '当前华为账号不支持发票助手服务';
      case 401:
        return '参数错误，请联系开发者';
      default:
        return '未知错误，请稍后重试';
    }
  }
}

/**
 * 发票抬头选择页面组件示例
 */
@Entry
@Component
struct InvoiceTitlePage {
  private service: InvoiceTitleService | null = null;
  
  // 发票抬头数据
  @State invoiceTitleData: InvoiceTitleData | null = null;
  // 操作状态
  @State isLoading: boolean = false;
  @State statusMessage: string = '';
  
  aboutToAppear(): void {
    // 初始化服务
    const context = getContext(this) as common.UIAbilityContext;
    this.service = new InvoiceTitleService(context);
  }

  build() {
    Column() {
      // 标题
      Text('发票抬头选择示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // 选择按钮
      Button('选择发票抬头')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleSelectInvoiceTitle();
        })
        .margin({ bottom: 20 })

      // 状态信息
      if (this.statusMessage) {
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor('#FF0000')
          .margin({ bottom: 10 })
      }

      // 发票抬头信息展示
      if (this.invoiceTitleData) {
        this.InvoiceTitleCard()
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  /**
   * 发票抬头信息卡片
   */
  @Builder
  InvoiceTitleCard() {
    Column() {
      Text('发票抬头信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })

      Divider().margin({ bottom: 10 })

      // 抬头类型
      this.InfoRow('抬头类型', this.invoiceTitleData!.type === '0' ? '个人' : '企业')
      
      // 抬头名称
      this.InfoRow('抬头名称', this.invoiceTitleData!.title)

      // 企业抬头额外信息
      if (this.invoiceTitleData!.type === '1') {
        this.InfoRow('纳税人识别号', this.invoiceTitleData!.taxNumber)
        this.InfoRow('公司地址', this.invoiceTitleData!.companyAddress)
        this.InfoRow('公司电话', this.invoiceTitleData!.telephone)
        this.InfoRow('开户银行', this.invoiceTitleData!.bankName)
        this.InfoRow('银行账户', this.invoiceTitleData!.bankAccount)
      }

      // 使用按钮
      Button('使用此抬头')
        .width('100%')
        .height(40)
        .margin({ top: 20 })
        .onClick(() => {
          this.useInvoiceTitle();
        })
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
  }

  /**
   * 信息行组件
   */
  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label + ':')
        .fontSize(14)
        .width('30%')
        .fontColor('#666666')
      
      Text(value)
        .fontSize(14)
        .width('70%')
        .fontColor('#333333')
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  /**
   * 处理选择发票抬头
   */
  private async handleSelectInvoiceTitle(): Promise<void> {
    if (!this.service) {
      this.statusMessage = '服务未初始化';
      return;
    }

    this.isLoading = true;
    this.statusMessage = '';
    
    try {
      const result = await this.service.selectInvoiceTitle();
      
      switch (result.status) {
        case 'success':
          this.invoiceTitleData = result.data || null;
          this.statusMessage = '成功获取发票抬头';
          break;
          
        case 'canceled':
          this.statusMessage = '您已取消选择';
          break;
          
        case 'failed':
          this.statusMessage = this.service.getErrorMessage(result.errorCode || -1);
          break;
      }
    } catch (error) {
      this.statusMessage = '发生未知错误';
      hilog.error(DOMAIN, TAG, `Error: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 使用发票抬头（示例）
   */
  private useInvoiceTitle(): void {
    if (this.invoiceTitleData) {
      // 这里可以将发票抬头数据传递给发票开具流程
      hilog.info(DOMAIN, TAG, '使用发票抬头: ' + JSON.stringify(this.invoiceTitleData));
      this.statusMessage = '发票抬头已应用';
      
      // 实际应用中，这里应该：
      // 1. 将发票抬头数据传递给发票开具组件
      // 2. 或者保存到应用状态管理中
      // 3. 或者发送到服务器进行发票开具
    }
  }
}

/**
 * 使用示例（非UI组件环境）
 */
export async function selectInvoiceTitleExample(): Promise<void> {
  // 获取Context（需要在UI组件或Ability中调用）
  const context = getContext(this) as common.UIAbilityContext;
  
  // 创建服务实例
  const service = new InvoiceTitleService(context);
  
  // 选择发票抬头
  const result = await service.selectInvoiceTitle();
  
  if (result.status === 'success' && result.data) {
    // 成功获取发票抬头
    const formattedText = service.formatInvoiceTitle(result.data);
    console.log('发票抬头信息:\n' + formattedText);
    
    // 根据抬头类型处理
    if (result.data.type === '0') {
      // 个人抬头处理
      console.log('个人抬头:', result.data.title);
    } else {
      // 企业抬头处理
      console.log('企业抬头:', result.data.title);
      console.log('纳税人识别号:', result.data.taxNumber);
    }
  } else if (result.status === 'canceled') {
    // 用户取消
    console.log('用户取消选择');
  } else {
    // 失败
    console.log('选择失败:', service.getErrorMessage(result.errorCode || -1));
  }
}