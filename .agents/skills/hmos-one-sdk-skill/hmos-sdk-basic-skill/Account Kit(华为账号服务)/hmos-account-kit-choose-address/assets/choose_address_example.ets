/**
 * 获取收货地址完整示例代码
 * 
 * 本示例演示如何使用Account Kit的shippingAddress.chooseAddress API获取用户收货地址
 * 
 * 功能说明：
 * - 拉起华为账号收货地址管理页面
 * - 用户可选择或添加收货地址
 * - 应用获取完整的地址信息（姓名、手机号、省市区街道等）
 * 
 * 使用前提：
 * 1. 企业开发者账号
 * 2. 已在AGC申请"获取收货地址"权限
 * 3. 已配置应用指纹证书和Client ID
 * 4. 用户已登录华为账号
 * 
 * 设备支持：Phone、Tablet、PC/2in1（API 26.0.0+支持TV、Car）
 * API版本：5.0.0(12)+
 */

import { shippingAddress } from '@kit.AccountKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'ShippingAddressExample';
const DOMAIN = 0x0000;

/**
 * 收货地址信息展示组件
 */
@Entry
@Component
struct ShippingAddressExample {
  @State addressInfo: shippingAddress.AddressInfo | null = null;
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('获取收货地址示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      // 说明文本
      Text('点击下方按钮选择或添加收货地址')
        .fontSize(16)
        .margin({ top: 10 });

      // 选择地址按钮
      Button('选择收货地址')
        .width('80%')
        .height(50)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.chooseAddress();
        });

      // 加载状态提示
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .margin({ top: 20 });
      }

      // 错误信息展示
      if (this.errorMessage !== '') {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ top: 10 });
      }

      // 地址信息展示
      if (this.addressInfo !== null) {
        this.AddressInfoCard();
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }

  /**
   * 地址信息卡片组件
   */
  @Builder
  AddressInfoCard() {
    Column({ space: 10 }) {
      Text('收货地址信息')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      // 收件人信息
      Row({ space: 10 }) {
        Text('收件人：')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(this.addressInfo!.userName)
          .fontSize(16);
      }
      .width('100%');

      // 手机号信息
      Row({ space: 10 }) {
        Text('手机号：')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(this.addressInfo!.mobileNumber)
          .fontSize(16);
      }
      .width('100%');

      // 座机号码（可选字段）
      if (this.addressInfo!.telNumber) {
        Row({ space: 10 }) {
          Text('座机号：')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Text(this.addressInfo!.telNumber!)
            .fontSize(16);
        }
        .width('100%');
      }

      // 邮政编码（可选字段）
      if (this.addressInfo!.zipCode) {
        Row({ space: 10 }) {
          Text('邮政编码：')
            .fontSize(16)
            .fontWeight(FontWeight.Medium);
          Text(this.addressInfo!.zipCode!)
            .fontSize(16);
        }
        .width('100%');
      }

      // 地址信息
      Column({ space: 5 }) {
        Text('详细地址：')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        Text(this.getFullAddress())
          .fontSize(16)
          .wordBreak(WordBreak.BREAK_ALL);
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);

      // 使用地址按钮（示例：提交订单）
      Button('使用此地址')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.useAddress();
        });
    }
    .width('100%')
    .padding(20)
    .borderRadius(10)
    .backgroundColor('#F5F5F5');
  }

  /**
   * 选择收货地址方法
   */
  private async chooseAddress(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 获取Context：必须在自定义组件实例中使用this.getUIContext().getHostContext()
      const context: common.Context = this.getUIContext().getHostContext();

      // 调用chooseAddress API，拉起收货地址管理页面
      hilog.info(DOMAIN, TAG, 'Starting to choose address...');
      const addressInfo: shippingAddress.AddressInfo = await shippingAddress.chooseAddress(context);

      // 成功获取地址信息
      hilog.info(DOMAIN, TAG, 'Succeeded in choosing address.');
      
      // 记录地址详细信息
      hilog.info(DOMAIN, TAG, `UserName: ${addressInfo.userName}`);
      hilog.info(DOMAIN, TAG, `MobileNumber: ${addressInfo.mobileNumber}`);
      hilog.info(DOMAIN, TAG, `Address: ${this.getFullAddressFromInfo(addressInfo)}`);

      // 更新状态
      this.addressInfo = addressInfo;
      this.isLoading = false;

    } catch (error) {
      // 错误处理
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Failed to choose address. Code: ${err.code}, message: ${err.message}`);
      
      this.isLoading = false;
      this.errorMessage = this.getErrorMessage(err.code);
      
      // 特殊错误处理
      this.handleSpecialError(err);
    }
  }

  /**
   * 获取完整地址字符串
   */
  private getFullAddress(): string {
    if (this.addressInfo === null) {
      return '';
    }

    return `${this.addressInfo.provinceName}${this.addressInfo.cityName}${this.addressInfo.districtName}${this.addressInfo.streetName}${this.addressInfo.detailedAddress}`;
  }

  /**
   * 从AddressInfo对象获取完整地址
   */
  private getFullAddressFromInfo(info: shippingAddress.AddressInfo): string {
    return `${info.provinceName}${info.cityName}${info.districtName}${info.streetName}${info.detailedAddress}`;
  }

  /**
   * 根据错误码获取错误提示信息
   */
  private getErrorMessage(code: number): string {
    switch (code) {
      case 401:
        return '参数错误，请检查调用方式';
      case 1008100001:
        return '内部错误，请重启设备后重试';
      case 1008100002:
        return '网络不可用，请检查网络连接';
      case 1008100003:
        return '用户未登录华为账号，请先登录';
      case 1008100004:
        return '应用指纹证书校验失败，请检查配置';
      case 1008100005:
        return '应用未申请获取收货地址权限';
      case 1008100006:
        return '用户取消了操作';
      case 1008100007:
        return '当前账号不支持收货地址服务';
      default:
        return `未知错误：${code}`;
    }
  }

  /**
   * 特殊错误处理（如引导用户登录）
   */
  private handleSpecialError(error: BusinessError): void {
    switch (error.code) {
      case 1008100003:
        // 用户未登录：引导用户登录
        hilog.info(DOMAIN, TAG, 'User not logged in, guide to login.');
        // 可调用LoginWithHuaweiIDRequest(forceLogin: true)或引导用户到系统设置登录
        // 示例：提示用户到系统设置登录
        AlertDialog.show({
          title: '需要登录华为账号',
          message: '请先登录华为账号后再选择收货地址',
          confirm: {
            value: '知道了',
            action: () => {}
          }
        });
        break;

      case 1008100006:
        // 用户取消操作：应用无需特殊处理
        hilog.info(DOMAIN, TAG, 'User canceled the operation.');
        this.errorMessage = ''; // 清除错误提示，因为用户主动取消不算错误
        break;

      case 1008100007:
        // 账号不支持：引导用户更换账号
        hilog.info(DOMAIN, TAG, 'Account does not support shipping address service.');
        AlertDialog.show({
          title: '账号不支持',
          message: '当前账号不支持收货地址服务，请使用中国境内账号',
          confirm: {
            value: '知道了',
            action: () => {}
          }
        });
        break;
    }
  }

  /**
   * 使用地址方法（示例：提交订单）
   */
  private useAddress(): void {
    if (this.addressInfo === null) {
      return;
    }

    hilog.info(DOMAIN, TAG, 'Using address for order submission...');
    
    // 示例：提交订单时使用地址信息
    // 实际应用中，这里可以：
    // 1. 将地址信息提交到服务器
    // 2. 保存地址到本地
    // 3. 跳转到订单确认页面
    
    AlertDialog.show({
      title: '地址已选择',
      message: `收件人：${this.addressInfo.userName}\n手机号：${this.addressInfo.mobileNumber}\n地址：${this.getFullAddress()}`,
      confirm: {
        value: '确定',
        action: () => {
          hilog.info(DOMAIN, TAG, 'Order submission with address completed.');
        }
      }
    });
  }
}