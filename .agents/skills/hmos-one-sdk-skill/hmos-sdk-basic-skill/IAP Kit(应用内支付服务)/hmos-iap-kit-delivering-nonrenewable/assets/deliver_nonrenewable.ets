import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from './JWSUtil';
import { PurchaseOrderPayload } from './PurchaseOrderPayload';

interface DeliveryResult {
  success: boolean;
  orderId: string;
  message: string;
}

export class NonrenewableDeliveryManager {
  private context: common.UIAbilityContext;
  
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }
  
  async queryAndDeliverUnfinishedPurchases(): Promise<DeliveryResult[]> {
    const results: DeliveryResult[] = [];
    
    try {
      const queryParam: iap.QueryPurchasesParameter = {
        productType: iap.ProductType.NONRENEWABLE,
        queryType: iap.PurchaseQueryType.UNFINISHED
      };
      
      const queryResult: iap.QueryPurchaseResult = await iap.queryPurchases(this.context, queryParam);
      console.info('Succeeded in querying purchases.');
      
      const purchaseDataList: string[] | undefined = queryResult.purchaseDataList;
      if (!purchaseDataList || purchaseDataList.length === 0) {
        console.info('No unfinished purchases found.');
        return results;
      }
      
      for (let i = 0; i < purchaseDataList.length; i++) {
        const result = await this.processPurchaseData(purchaseDataList[i]);
        results.push(result);
      }
      
      return results;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to query purchases. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }
  
  private async processPurchaseData(purchaseData: string): Promise<DeliveryResult> {
    try {
      const purchaseDataObj = JSON.parse(purchaseData);
      const jwsPurchaseOrder: string | undefined = purchaseDataObj.jwsPurchaseOrder;
      
      if (!jwsPurchaseOrder) {
        return {
          success: false,
          orderId: '',
          message: 'Missing jwsPurchaseOrder in purchaseData'
        };
      }
      
      const decodedStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
      const orderPayload: PurchaseOrderPayload = JSON.parse(decodedStr);
      
      console.info(`Processing order: ${orderPayload.purchaseOrderId}`);
      
      if (orderPayload.purchaseOrderRevocationReasonCode) {
        console.warn(`Order revoked: ${orderPayload.purchaseOrderId}, Reason: ${orderPayload.purchaseOrderRevocationReasonCode}`);
        return {
          success: false,
          orderId: orderPayload.purchaseOrderId,
          message: `Order revoked: ${orderPayload.purchaseOrderRevocationReasonCode}`
        };
      }
      
      const deliveryStatus = await this.checkDeliveryStatus(orderPayload.purchaseOrderId);
      if (deliveryStatus === 'delivered') {
        console.info(`Order already delivered: ${orderPayload.purchaseOrderId}`);
        return {
          success: false,
          orderId: orderPayload.purchaseOrderId,
          message: 'Order already delivered'
        };
      }
      
      if (orderPayload.quantity && orderPayload.quantity > 1) {
        console.info(`Batch purchase detected. Quantity: ${orderPayload.quantity}`);
      }
      
      const delivered = await this.deliverRights(orderPayload);
      if (!delivered) {
        return {
          success: false,
          orderId: orderPayload.purchaseOrderId,
          message: 'Failed to deliver rights'
        };
      }
      
      await this.recordDeliveryStatus(orderPayload);
      
      await this.confirmDelivery(orderPayload);
      
      return {
        success: true,
        orderId: orderPayload.purchaseOrderId,
        message: 'Successfully delivered rights and confirmed purchase'
      };
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to process purchase data: ${err.message}`);
      return {
        success: false,
        orderId: '',
        message: `Error: ${err.message}`
      };
    }
  }
  
  private async checkDeliveryStatus(orderId: string): Promise<'delivered' | 'undelivered'> {
    return 'undelivered';
  }
  
  private async deliverRights(orderPayload: PurchaseOrderPayload): Promise<boolean> {
    console.info(`Delivering rights for product: ${orderPayload.productId}`);
    console.info(`Quantity: ${orderPayload.quantity || 1}`);
    console.info(`Purchase time: ${orderPayload.purchaseTime}`);
    console.info(`Price: ${orderPayload.price} ${orderPayload.currency}`);
    
    return true;
  }
  
  private async recordDeliveryStatus(orderPayload: PurchaseOrderPayload): Promise<void> {
    console.info(`Recording delivery status for order: ${orderPayload.purchaseOrderId}`);
  }
  
  private async confirmDelivery(orderPayload: PurchaseOrderPayload): Promise<void> {
    const finishParam: iap.FinishPurchaseParameter = {
      productType: Number(orderPayload.productType),
      purchaseToken: orderPayload.purchaseToken,
      purchaseOrderId: orderPayload.purchaseOrderId
    };
    
    try {
      await iap.finishPurchase(this.context, finishParam);
      console.info('Succeeded in finishing purchase.');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to finish purchase. Code: ${err.code}, Message: ${err.message}`);
      throw error;
    }
  }
}

@Entry
@Component
struct DeliveryPage {
  private deliveryManager?: NonrenewableDeliveryManager;
  
  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.deliveryManager = new NonrenewableDeliveryManager(context);
  }
  
  async handleCheckAndDeliver() {
    if (!this.deliveryManager) {
      console.error('Delivery manager not initialized');
      return;
    }
    
    try {
      const results = await this.deliveryManager.queryAndDeliverUnfinishedPurchases();
      console.info(`Delivery completed. Processed ${results.length} orders.`);
      
      for (const result of results) {
        if (result.success) {
          console.info(`Success: ${result.orderId} - ${result.message}`);
        } else {
          console.warn(`Failed: ${result.orderId} - ${result.message}`);
        }
      }
    } catch (error) {
      console.error('Failed to handle delivery:', error);
    }
  }
  
  build() {
    Column() {
      Button('Check and Deliver Unfinished Purchases')
        .onClick(() => {
          this.handleCheckAndDeliver();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}