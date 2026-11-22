import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from './JWSUtil';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: string;
  productId: string;
  price: number;
  currency: string;
  purchaseTime: number;
  purchaseOrderRevocationReasonCode?: string;
}

@Entry
@Component
struct IAPurchasePage {
  @State productList: Array<iap.Product> = [];
  @State purchaseStatus: string = 'Ready';
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    await this.checkIAPEnvironment();
    await this.queryProducts();
  }

  async checkIAPEnvironment(): Promise<boolean> {
    try {
      await iap.queryEnvironmentStatus(this.context);
      console.info('IAP environment is supported.');
      this.purchaseStatus = 'IAP Supported';
      return true;
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === 1001860054) {
        console.error('User account service region does not support IAP.');
        this.purchaseStatus = 'IAP Not Supported in Your Region';
        return false;
      }
      console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
      this.purchaseStatus = 'Check IAP Failed';
      return false;
    }
  }

  async queryProducts(): Promise<void> {
    const queryProductParam: iap.QueryProductsParameter = {
      productType: iap.ProductType.CONSUMABLE,
      productIds: ['consumable_product_001', 'consumable_product_002']
    };

    try {
      const products = await iap.queryProducts(this.context, queryProductParam);
      this.productList = products;
      console.info(`Succeeded in querying products. Count: ${products.length}`);
      this.purchaseStatus = 'Products Loaded';
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
      this.purchaseStatus = 'Query Products Failed';
    }
  }

  async purchaseProduct(productId: string): Promise<void> {
    this.purchaseStatus = 'Purchasing...';

    try {
      const purchaseParam: iap.PurchaseParameter = {
        productType: iap.ProductType.CONSUMABLE,
        productId: productId
      };

      const result = await iap.createPurchase(this.context, purchaseParam);
      console.info('Succeeded in creating purchase.');
      
      await this.handlePurchaseResult(result);
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to create purchase. Code: ${error.code}, Message: ${error.message}`);
      this.purchaseStatus = `Purchase Failed: ${error.code}`;
      
      await this.handlePurchaseError(error);
    }
  }

  async handlePurchaseResult(result: iap.CreatePurchaseResult): Promise<void> {
    try {
      const purchaseData = JSON.parse(result.purchaseData);
      const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;

      if (!jwsPurchaseOrder) {
        throw new Error('No purchase order data found.');
      }

      const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
      const purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseOrderPayload;

      if (purchaseOrderPayload.purchaseOrderRevocationReasonCode) {
        console.warn('Purchase order revoked:', purchaseOrderPayload.purchaseOrderRevocationReasonCode);
        throw new Error('Purchase order has been revoked.');
      }

      console.info('Purchase verified successfully.');
      
      await this.deliverProduct(purchaseOrderPayload);
      await this.finishPurchase(purchaseOrderPayload);
      
      this.purchaseStatus = 'Purchase Completed';
      
    } catch (error) {
      console.error('Failed to handle purchase result:', error);
      this.purchaseStatus = 'Handle Purchase Failed';
    }
  }

  async deliverProduct(purchaseOrder: PurchaseOrderPayload): Promise<boolean> {
    try {
      console.info(`Delivering product: ${purchaseOrder.productId}, Order: ${purchaseOrder.purchaseOrderId}`);
      
      await this.simulateProductDelivery(purchaseOrder.productId);
      await this.recordPurchaseOrder(purchaseOrder);
      
      console.info('Product delivered successfully.');
      return true;
    } catch (error) {
      console.error('Failed to deliver product:', error);
      return false;
    }
  }

  async simulateProductDelivery(productId: string): Promise<void> {
    console.info(`Simulating delivery for product: ${productId}`);
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  async recordPurchaseOrder(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    console.info(`Recording purchase order: ${purchaseOrder.purchaseOrderId}`);
  }

  async finishPurchase(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    const finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };

    try {
      await iap.finishPurchase(this.context, finishPurchaseParam);
      console.info('Succeeded in finishing purchase.');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
      throw error;
    }
  }

  async handlePurchaseError(error: BusinessError): Promise<void> {
    if (error.code === iap.IAPErrorCode.PRODUCT_OWNED || error.code === iap.IAPErrorCode.SYSTEM_ERROR) {
      console.warn('Need to check for pending deliveries.');
      
      try {
        const queryParam: iap.QueryPurchasesParameter = {
          productType: iap.ProductType.CONSUMABLE
        };
        const purchases = await iap.queryPurchases(this.context, queryParam);

        for (const purchase of purchases.purchaseDataList) {
          const purchaseData = JSON.parse(purchase.purchaseData);
          const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;
          const purchaseStr = JWSUtil.decodeJwsObj(jwsPurchaseOrder);
          const purchaseOrder = JSON.parse(purchaseStr) as PurchaseOrderPayload;

          const delivered = await this.deliverProduct(purchaseOrder);
          if (delivered) {
            await this.finishPurchase(purchaseOrder);
          }
        }
        
        this.purchaseStatus = 'Pending Deliveries Processed';
        
      } catch (err) {
        console.error('Failed to handle pending purchases:', err);
      }
    }
  }

  build() {
    Column() {
      Text('IAP Purchase Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`Status: ${this.purchaseStatus}`)
        .fontSize(16)
        .margin({ bottom: 20 });

      List() {
        ForEach(this.productList, (product: iap.Product) => {
          ListItem() {
            Row() {
              Column() {
                Text(product.productName || product.productId)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium);
                Text(`Price: ${product.price / 100} ${product.currency}`)
                  .fontSize(14)
                  .margin({ top: 5 });
              }
              .layoutWeight(1);

              Button('Buy')
                .onClick(() => {
                  this.purchaseProduct(product.productId);
                });
            }
            .padding(10)
            .margin({ bottom: 10 });
          }
        });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%');
  }
}