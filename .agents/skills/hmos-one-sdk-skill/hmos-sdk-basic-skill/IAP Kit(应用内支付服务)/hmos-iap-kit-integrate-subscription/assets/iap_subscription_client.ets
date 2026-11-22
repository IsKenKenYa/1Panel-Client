import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class IAPSubscriptionManager {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async checkIAPEnvironment(): Promise<boolean> {
    try {
      await iap.queryEnvironmentStatus(this.context);
      console.info('IAP environment is available.');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
      
      if (error.code === 1001860054) {
        console.warn('User account territory not supported. Hide IAP features.');
      } else if (error.code === 1001860050) {
        console.warn('User not logged in. Please guide user to login.');
      }
      
      return false;
    }
  }

  async querySubscriptionProducts(productIds: string[]): Promise<Array<iap.Product>> {
    const queryProductParam: iap.QueryProductsParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      productIds: productIds
    };
    
    try {
      const products = await iap.queryProducts(this.context, queryProductParam);
      console.info(`Succeeded in querying products. Found ${products.length} products.`);
      return products;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
      throw error;
    }
  }

  async queryActiveSubscriptions(): Promise<Array<iap.PurchaseData>> {
    const queryPurchasesParam: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
    };
    
    try {
      const result = await iap.queryPurchases(this.context, queryPurchasesParam);
      console.info(`Succeeded in querying purchases. Found ${result.purchaseDataList.length} active subscriptions.`);
      return result.purchaseDataList;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query purchases. Code: ${error.code}, Message: ${error.message}`);
      throw error;
    }
  }

  async createSubscriptionPurchase(productId: string, developerPayload?: string): Promise<iap.CreatePurchaseResult> {
    const purchaseParam: iap.PurchaseParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      productId: productId,
      developerPayload: developerPayload || ''
    };
    
    try {
      const result = await iap.createPurchase(this.context, purchaseParam);
      console.info('Succeeded in creating purchase.');
      return result;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to create purchase. Code: ${error.code}, Message: ${error.message}`);
      
      if (error.code === iap.IAPErrorCode.PRODUCT_OWNED || error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
        console.warn('Product owned or system error. Check for supplementary delivery.');
        await this.handleSupplementaryDelivery();
      }
      
      throw error;
    }
  }

  async finishPurchase(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    if (purchaseOrder.finishStatus === '1') {
      console.warn('Purchase already finished. Skip delivery.');
      return;
    }
    
    const finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };
    
    try {
      await iap.finishPurchase(this.context, finishPurchaseParam);
      console.info('Succeeded in finishing purchase. Delivery confirmed.');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
      throw error;
    }
  }

  private async handleSupplementaryDelivery(): Promise<void> {
    try {
      const activeSubscriptions = await this.queryActiveSubscriptions();
      
      for (const purchaseData of activeSubscriptions) {
        const purchaseDataObj = JSON.parse(purchaseData.jwsPurchaseOrder || '');
        if (purchaseDataObj && purchaseDataObj.finishStatus !== '1') {
          await this.finishPurchase(purchaseDataObj);
        }
      }
    } catch (error) {
      console.error('Failed to handle supplementary delivery:', error);
    }
  }
}

export interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  price: number;
  currency: string;
  purchaseTime: number;
  finishStatus?: string;
}