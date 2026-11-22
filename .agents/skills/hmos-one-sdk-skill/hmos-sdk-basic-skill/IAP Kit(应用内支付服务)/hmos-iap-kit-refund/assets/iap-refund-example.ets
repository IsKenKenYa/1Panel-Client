import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';

interface PurchaseRecord {
  purchaseOrderId: string;
  productId: string;
  purchaseTime: string;
  amount: string;
  status: string;
}

@Entry
@Component
struct IAPRefundExample {
  @State purchaseRecords: PurchaseRecord[] = [];
  @State selectedOrderId: string = '';
  @State isLoading: boolean = false;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  aboutToAppear(): void {
    this.loadPurchaseRecords();
  }
  
  loadPurchaseRecords(): void {
    this.purchaseRecords = [
      {
        purchaseOrderId: 'order_001',
        productId: 'product_001',
        purchaseTime: '2026-06-01 10:00:00',
        amount: '￥9.99',
        status: '已购买'
      },
      {
        purchaseOrderId: 'order_002',
        productId: 'product_002',
        purchaseTime: '2026-06-15 14:30:00',
        amount: '￥19.99',
        status: '已购买'
      }
    ];
  }
  
  createRefundRequest(purchaseOrderId: string): void {
    if (!purchaseOrderId || purchaseOrderId.length === 0) {
      promptAction.showToast({
        message: '订单号不能为空',
        duration: 2000
      });
      return;
    }
    
    if (purchaseOrderId.length > 256) {
      promptAction.showToast({
        message: '订单号长度不能超过256字符',
        duration: 2000
      });
      return;
    }
    
    this.isLoading = true;
    
    iap.createRefundRequest(this.context, purchaseOrderId).then(() => {
      console.info('Succeeded in creating refund request.');
      this.isLoading = false;
      this.showRefundSuccessDialog(purchaseOrderId);
    }).catch((err: BusinessError) => {
      console.error(`Failed to create refund request. Code is ${err.code}, message is ${err.message}`);
      this.isLoading = false;
      this.handleRefundError(err);
    });
  }
  
  showRefundSuccessDialog(purchaseOrderId: string): void {
    AlertDialog.show({
      title: '退款申请已提交',
      message: `订单 ${purchaseOrderId} 的退款申请已提交成功。\n\n退款流程说明:\n1. 开发者将审核您的退款申请\n2. 审核通过后将在7个工作日内完成退款\n3. 退款金额将退回至您的支付账户\n\n您可以在"系统设置 > 华为账号 > 付款与账单 > 退款记录"中查看退款进度`,
      confirm: {
        value: '确定',
        action: () => {
          this.selectedOrderId = '';
        }
      },
      cancel: {
        value: '查看退款记录',
        action: () => {
          this.navigateToRefundRecords();
        }
      }
    });
  }
  
  handleRefundError(err: BusinessError): void {
    let errorMsg: string = '';
    let actionText: string = '确定';
    
    switch (err.code) {
      case 401:
        errorMsg = '参数错误: 订单号无效或参数类型错误';
        actionText = '重新选择订单';
        break;
      case 801:
        errorMsg = '当前设备不支持退款功能\n\n支持的设备类型: Phone/Tablet/2in1\n\n请在支持的设备上申请退款,或通过"系统设置 > 华为账号 > 付款与账单 > 购买记录"路径手动申请';
        actionText = '了解详情';
        break;
      case 1001860000:
        errorMsg = '您取消了退款操作';
        actionText = '确定';
        break;
      case 1001860001:
        errorMsg = '系统内部错误,请稍后重试';
        actionText = '稍后重试';
        break;
      case 1001860002:
        errorMsg = '应用未被授权访问退款接口\n\n请检查应用是否在AppGallery Connect配置了IAP权限';
        actionText = '联系客服';
        break;
      case 1001860004:
        errorMsg = '操作过于频繁,请稍后重试';
        actionText = '稍后重试';
        break;
      case 1001860005:
        errorMsg = '网络连接异常\n\n请检查网络连接后重试,或通过"系统设置 > 华为账号 > 付款与账单 > 购买记录"路径手动申请退款';
        actionText = '检查网络';
        break;
      case 1001860054:
        errorMsg = '当前账号所在地区不支持应用内支付退款功能';
        actionText = '联系客服';
        break;
      case 1001860061:
        errorMsg = '订单已退款或正在退款流程中\n\n无需重复申请退款';
        actionText = '查看退款状态';
        break;
      case 1001860062:
        errorMsg = '该订单不允许退款\n\n可能原因:\n1. 订单已超过退款时限\n2. 商品已被消耗\n3. 订单不符合退款条件';
        actionText = '联系客服';
        break;
      default:
        errorMsg = `退款失败: ${err.message}`;
        actionText = '确定';
        break;
    }
    
    AlertDialog.show({
      title: '退款失败',
      message: errorMsg,
      confirm: {
        value: actionText,
        action: () => {
          if (err.code === 1001860005 || err.code === 801) {
            this.navigateToManualRefund();
          }
        }
      }
    });
  }
  
  navigateToRefundRecords(): void {
    promptAction.showToast({
      message: '请前往: 系统设置 > 华为账号 > 付款与账单 > 退款记录',
      duration: 3000
    });
  }
  
  navigateToManualRefund(): void {
    promptAction.showToast({
      message: '请前往: 系统设置 > 华为账号 > 付款与账单 > 购买记录',
      duration: 3000
    });
  }
  
  build() {
    Column() {
      Text('购买记录')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 });
      
      Text('选择需要退款的订单')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 20 });
      
      if (this.purchaseRecords.length === 0) {
        Text('暂无购买记录')
          .fontSize(16)
          .fontColor('#999999')
          .margin({ top: 50 });
      } else {
        List() {
          ForEach(this.purchaseRecords, (record: PurchaseRecord) => {
            ListItem() {
              Row() {
                Column() {
                  Text(`商品ID: ${record.productId}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium);
                  
                  Text(`订单号: ${record.purchaseOrderId}`)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 5 });
                  
                  Row() {
                    Text(`购买时间: ${record.purchaseTime}`)
                      .fontSize(12)
                      .fontColor('#999999');
                    
                    Text(`金额: ${record.amount}`)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF6B6B')
                      .margin({ left: 20 });
                  }
                  .margin({ top: 5 });
                }
                .alignItems(HorizontalAlign.Start)
                
                Button('申请退款')
                  .fontSize(14)
                  .height(40)
                  .backgroundColor('#FF6B6B')
                  .onClick(() => {
                    this.selectedOrderId = record.purchaseOrderId;
                    this.createRefundRequest(record.purchaseOrderId);
                  });
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 10 });
            }
          });
        }
        .width('100%')
        .height('60%');
      }
      
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .color('#FF6B6B');
        
        Text('正在提交退款申请...')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 10 });
      }
      
      Column() {
        Text('退款说明')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 });
        
        Text('1. 仅支持非游戏类应用的订单退款')
          .fontSize(14)
          .fontColor('#666666');
        
        Text('2. 退款只能由用户发起')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 5 });
        
        Text('3. 退款流程通常需要7个工作日')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 5 });
        
        Text('4. 最低系统版本要求: 6.16.10')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 5 });
        
        Text('5. 支持设备: Phone/Tablet/2in1')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 5 });
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#FFFFFF');
  }
}