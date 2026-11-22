import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from '../common/JWSUtil';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  quantity?: number;
  purchaseTime: number;
  finishStatus?: string;
  needFinish?: boolean;
  price: number;
  currency: string;
  developerPayload?: string;
  purchaseOrderRevocationReasonCode?: string;
  countryCode: string;
  applicationId: string;
  environment: string;
}

interface DeliveryRecord {
  purchaseOrderId: string;
  productId: string;
  deliveryTime: number;
  deliveryStatus: string;
}

@Entry
@Component
struct IAPDeliveringProductsExample {
  private deliveryRecords: DeliveryRecord[] = [];
  
  async queryAndDeliverProducts(context: common.UIAbilityContext): Promise<void> {
    try {
      console.info('[权益发放] 开始查询未发货订单...');
      
      const queryParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.CONSUMABLE,
        queryType: iap.PurchaseQueryType.UNFINISHED
      };
      
      const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, queryParam);
      
      console.info(`[权益发放] 查询成功，订单数量: ${result.purchaseDataList?.length || 0}`);
      
      const purchaseDataList: string[] = result.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length <= 0) {
        console.info('[权益发放] 无未发货订单，跳过处理');
        return;
      }
      
      for (let i = 0; i < purchaseDataList.length; i++) {
        await this.processPurchaseData(purchaseDataList[i], context);
      }
      
      console.info('[权益发放] 所有订单处理完成');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[权益发放] 查询失败，错误码: ${err.code}, 错误信息: ${err.message}`);
      this.handleQueryError(err);
    }
  }
  
  async processPurchaseData(purchaseData: string, context: common.UIAbilityContext): Promise<void> {
    try {
      const purchaseDataObj = JSON.parse(purchaseData);
      const jwsPurchaseOrder: string = purchaseDataObj.jwsPurchaseOrder;
      
      if (!jwsPurchaseOrder) {
        console.warn('[权益发放] 订单数据缺少jwsPurchaseOrder字段');
        return;
      }
      
      console.info('[权益发放] 开始解码验签JWS数据...');
      
      const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
      const purchaseOrderPayload: PurchaseOrderPayload = JSON.parse(purchaseStr);
      
      console.info(`[权益发放] 验签成功，订单ID: ${purchaseOrderPayload.purchaseOrderId}`);
      
      if (purchaseOrderPayload.purchaseOrderRevocationReasonCode) {
        console.warn(`[权益发放] 订单已撤销，撤销原因: ${purchaseOrderPayload.purchaseOrderRevocationReasonCode}`);
        return;
      }
      
      if (purchaseOrderPayload.finishStatus === '1') {
        console.info(`[权益发放] 订单已发货，订单ID: ${purchaseOrderPayload.purchaseOrderId}`);
        return;
      }
      
      await this.deliverProduct(purchaseOrderPayload, context);
    } catch (error) {
      console.error('[权益发放] 处理订单数据失败:', error);
    }
  }
  
  async deliverProduct(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
    try {
      const isDelivered = await this.checkDeliveryStatus(purchaseOrder.purchaseOrderId);
      
      if (isDelivered) {
        console.info(`[权益发放] 订单已发放权益，订单ID: ${purchaseOrder.purchaseOrderId}`);
        return;
      }
      
      console.info(`[权益发放] 开始发放权益，商品ID: ${purchaseOrder.productId}, 数量: ${purchaseOrder.quantity || 1}`);
      
      await this.grantUserRights(purchaseOrder.productId, purchaseOrder.quantity || 1);
      
      await this.recordDeliveryInfo(purchaseOrder);
      
      console.info(`[权益发放] 权益发放成功，商品: ${purchaseOrder.productId}`);
      
      await this.finishPurchase(context, purchaseOrder);
    } catch (error) {
      console.error('[权益发放] 发放权益失败:', error);
      this.recordDeliveryFailure(purchaseOrder, error);
    }
  }
  
  async checkDeliveryStatus(purchaseOrderId: string): Promise<boolean> {
    const record = this.deliveryRecords.find(r => r.purchaseOrderId === purchaseOrderId);
    return record !== undefined && record.deliveryStatus === 'delivered';
  }
  
  async grantUserRights(productId: string, quantity: number): Promise<void> {
    console.info(`[权益发放] 发放权益 - 商品: ${productId}, 数量: ${quantity}`);
    
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        console.info('[权益发放] 权益发放模拟完成');
        resolve();
      }, 100);
    });
  }
  
  async recordDeliveryInfo(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    const record: DeliveryRecord = {
      purchaseOrderId: purchaseOrder.purchaseOrderId,
      productId: purchaseOrder.productId,
      deliveryTime: Date.now(),
      deliveryStatus: 'delivered'
    };
    
    this.deliveryRecords.push(record);
    console.info(`[权益发放] 记录发货信息，订单ID: ${purchaseOrder.purchaseOrderId}`);
  }
  
  recordDeliveryFailure(purchaseOrder: PurchaseOrderPayload, error: any): void {
    const record: DeliveryRecord = {
      purchaseOrderId: purchaseOrder.purchaseOrderId,
      productId: purchaseOrder.productId,
      deliveryTime: Date.now(),
      deliveryStatus: 'failed'
    };
    
    this.deliveryRecords.push(record);
    console.error(`[权益发放] 记录发货失败，订单ID: ${purchaseOrder.purchaseOrderId}, 错误: ${error}`);
  }
  
  async finishPurchase(context: common.UIAbilityContext, purchaseOrder: PurchaseOrderPayload): Promise<void> {
    try {
      console.info(`[权益发放] 开始确认发货，订单ID: ${purchaseOrder.purchaseOrderId}`);
      
      const finishParam: iap.FinishPurchaseParameter = {
        productType: Number(purchaseOrder.productType),
        purchaseToken: purchaseOrder.purchaseToken,
        purchaseOrderId: purchaseOrder.purchaseOrderId
      };
      
      await iap.finishPurchase(context, finishParam);
      
      console.info('[权益发放] 确认发货成功');
      
      if (purchaseOrder.productType === '0') {
        console.info('[权益发放] 消耗型商品已确认发货，用户可再次购买');
      } else {
        console.info('[权益发放] 靶消耗型商品已确认发货，用户永久拥有');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[权益发放] 确认发货失败，错误码: ${err.code}, 错误信息: ${err.message}`);
      this.handleFinishError(err, purchaseOrder);
    }
  }
  
  handleQueryError(err: BusinessError): void {
    switch (err.code) {
      case 1001860005:
        console.error('[权益发放] 网络连接异常，请检查网络设置');
        break;
      case 1001860050:
        console.error('[权益发放] 用户未登录华为账号，请引导用户登录');
        break;
      case 1001860054:
        console.error('[权益发放] 用户账号所在服务地不支持IAP');
        break;
      case 1001860001:
        console.error('[权益发放] 系统内部错误，建议通过queryPurchases重新查询订单');
        break;
      case 1001860002:
        console.error('[权益发放] 应用未被授权，请检查签名配置和支付服务开关');
        break;
      case 1001860004:
        console.error('[权益发放] 接口访问过频，请控制调用频率');
        break;
      default:
        console.error(`[权益发放] 查询错误，错误码: ${err.code}`);
    }
  }
  
  handleFinishError(err: BusinessError, purchaseOrder: PurchaseOrderPayload): void {
    switch (err.code) {
      case 1001860052:
        console.error('[权益发放] 订单未支付，无法确认发货');
        break;
      case 1001860053:
        console.warn('[权益发放] 订单已完成发货，无需重复操作');
        break;
      case 1001860001:
        console.error('[权益发放] 系统错误，稍后重试finishPurchase');
        this.recordPendingFinish(purchaseOrder);
        break;
      case 1001860050:
        console.error('[权益发放] 用户未登录，无法确认发货');
        this.recordPendingFinish(purchaseOrder);
        break;
      case 1001860005:
        console.error('[权益发放] 网络异常，稍后重试finishPurchase');
        this.recordPendingFinish(purchaseOrder);
        break;
      default:
        console.error(`[权益发放] 确认发货失败，错误码: ${err.code}`);
        this.recordPendingFinish(purchaseOrder);
    }
  }
  
  recordPendingFinish(purchaseOrder: PurchaseOrderPayload): void {
    console.warn(`[权益发放] 记录待确认订单，订单ID: ${purchaseOrder.purchaseOrderId}`);
  }
  
  async queryNonConsumableProducts(context: common.UIAbilityContext): Promise<void> {
    try {
      console.info('[权益恢复] 查询已购非消耗型商品...');
      
      const queryParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.NONCONSUMABLE,
        queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
      };
      
      const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, queryParam);
      
      console.info(`[权益恢复] 查询成功，已购商品数量: ${result.purchaseDataList?.length || 0}`);
      
      const purchaseDataList: string[] = result.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length <= 0) {
        console.info('[权益恢复] 无已购非消耗型商品');
        return;
      }
      
      for (let i = 0; i < purchaseDataList.length; i++) {
        const purchaseDataObj = JSON.parse(purchaseDataList[i]);
        const jwsPurchaseOrder: string = purchaseDataObj.jwsPurchaseOrder;
        
        if (!jwsPurchaseOrder) {
          continue;
        }
        
        const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
        const purchaseOrderPayload: PurchaseOrderPayload = JSON.parse(purchaseStr);
        
        console.info(`[权益恢复] 已购商品: ${purchaseOrderPayload.productId}`);
        
        if (purchaseOrderPayload && purchaseOrderPayload.finishStatus !== '1') {
          await this.grantUserRights(purchaseOrderPayload.productId, 1);
          await this.finishPurchase(context, purchaseOrderPayload);
        }
      }
      
      console.info('[权益恢复] 非消耗型商品权益恢复完成');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[权益恢复] 查询失败，错误码: ${err.code}, 错误信息: ${err.message}`);
    }
  }
  
  build() {
    Column() {
      Button('查询并发放权益')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.queryAndDeliverProducts(context);
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 })
      
      Button('恢复非消耗型商品权益')
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.queryNonConsumableProducts(context);
        })
        .width('80%')
        .height(50)
        .margin({ top: 20 })
      
      Text('权益发放示例')
        .fontSize(20)
        .margin({ top: 30 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}