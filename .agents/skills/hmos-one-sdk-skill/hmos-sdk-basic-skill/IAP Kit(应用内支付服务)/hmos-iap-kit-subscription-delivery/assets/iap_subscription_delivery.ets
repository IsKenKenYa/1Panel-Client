import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JWSUtil } from './JWSUtil';

interface SubGroupStatusPayload {
  environment: string;
  applicationId: string;
  packageName: string;
  subGroupId: string;
  lastSubscriptionStatus?: SubscriptionStatus;
  historySubscriptionStatusList?: SubscriptionStatus[];
}

interface SubscriptionStatus {
  subGroupGenerationId: string;
  subscriptionId: string;
  purchaseToken: string;
  status: string;
  expiresTime: number;
  lastPurchaseOrder?: PurchaseOrderPayload;
  recentPurchaseOrderList?: PurchaseOrderPayload[];
  renewalInfo?: SubRenewalInfo;
}

interface PurchaseOrderPayload {
  environment: string;
  purchaseOrderId: string;
  purchaseToken: string;
  applicationId: string;
  productId: string;
  productType: string;
  purchaseTime: number;
  finishStatus?: string;
  needFinish?: boolean;
  price: number;
  currency: string;
  countryCode: string;
  signedTime: number;
}

interface SubRenewalInfo {
  environment: string;
  subGroupGenerationId: string;
  productId: string;
  autoRenewStatusCode: string;
  hasInBillingRetryPeriod: boolean;
}

interface DeliveryRecord {
  orderId: string;
  productId: string;
  deliveryTime: number;
  deliveryStatus: string;
}

@Entry
@Component
struct SubscriptionDeliveryPage {
  @State deliveryRecords: DeliveryRecord[] = [];
  @State processingStatus: string = 'Ready';

  async queryActiveSubscriptions(context: common.UIAbilityContext): Promise<void> {
    this.processingStatus = 'Querying active subscriptions...';
    
    const param: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      queryType: iap.PurchaseQueryType.CURRENT_ENTITLEMENT
    };

    try {
      const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, param);
      console.info('Succeeded in querying purchases.');
      
      const purchaseDataList: string[] = result.purchaseDataList;
      if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
        this.processingStatus = 'No active subscriptions found.';
        return;
      }

      this.processingStatus = `Processing ${purchaseDataList.length} subscriptions...`;

      for (let i = 0; i < purchaseDataList.length; i++) {
        await this.processSubscriptionData(purchaseDataList[i], context);
      }

      this.processingStatus = 'Subscription delivery completed.';
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`Failed to query purchases. Code: ${error.code}, Message: ${error.message}`);
      this.processingStatus = `Query failed: ${error.message}`;
      this.handleQueryError(error);
    }
  }

  async queryUnfinishedSubscriptions(context: common.UIAbilityContext): Promise<void> {
    this.processingStatus = 'Querying unfinished subscriptions...';
    
    const param: iap.QueryPurchasesParameter = {
      productType: iap.ProductType.AUTORENEWABLE,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };

    try {
      const result: iap.QueryPurchaseResult = await iap.queryPurchases(context, param);
      console.info('Succeeded in querying unfinished purchases.');
      
      const purchaseDataList: string[] = result.purchaseDataList;
      if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
        this.processingStatus = 'No unfinished subscriptions found.';
        return;
      }

      this.processingStatus = `Processing ${purchaseDataList.length} unfinished subscriptions...`;

      for (let i = 0; i < purchaseDataList.length; i++) {
        await this.processSubscriptionData(purchaseDataList[i], context);
      }

      this.processingStatus = 'Unfinished subscription delivery completed.';
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`Failed to query unfinished purchases. Code: ${error.code}, Message: ${error.message}`);
      this.processingStatus = `Query failed: ${error.message}`;
      this.handleQueryError(error);
    }
  }

  async processSubscriptionData(purchaseData: string, context: common.UIAbilityContext): Promise<void> {
    try {
      const jwsSubscriptionStatus: string = JSON.parse(purchaseData).jwsSubscriptionStatus;
      if (!jwsSubscriptionStatus) {
        console.warn('No subscription status found in purchase data.');
        return;
      }

      const subscriptionStatus: string = JWSUtil.decodeJwsObj(jwsSubscriptionStatus);
      const subGroupStatusPayload: SubGroupStatusPayload = JSON.parse(subscriptionStatus);

      const lastSubscriptionStatus = subGroupStatusPayload.lastSubscriptionStatus;
      if (!lastSubscriptionStatus) {
        console.warn('No last subscription status found.');
        return;
      }

      const status = lastSubscriptionStatus.status;
      const purchaseOrderPayload = lastSubscriptionStatus.lastPurchaseOrder;

      if (purchaseOrderPayload === undefined) {
        console.warn('No purchase order found.');
        return;
      }

      console.info(`Subscription status: ${status}, OrderId: ${purchaseOrderPayload.purchaseOrderId}`);

      if (status === '1') {
        await this.deliverSubscriptionBenefit(purchaseOrderPayload, context);
      } else {
        console.info(`Subscription not active. Status: ${status}`);
      }
    } catch (err) {
      console.error('Failed to process subscription data:', err);
      this.handleProcessError(err);
    }
  }

  async deliverSubscriptionBenefit(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
    try {
      const orderId = purchaseOrder.purchaseOrderId;
      const productId = purchaseOrder.productId;

      const isDelivered = await this.checkBenefitDeliveryStatus(orderId);
      if (isDelivered) {
        console.info(`Benefit already delivered for order: ${orderId}`);
        return;
      }

      await this.grantUserBenefit(productId, orderId);
      await this.recordDeliveryOrder(purchaseOrder);

      console.info(`Benefit delivered successfully for order: ${orderId}`);

      if (purchaseOrder.finishStatus !== '1') {
        await this.confirmPurchaseDelivery(purchaseOrder, context);
      }
    } catch (err) {
      console.error('Failed to deliver benefit:', err);
      this.handleDeliveryError(err, purchaseOrder);
    }
  }

  async checkBenefitDeliveryStatus(orderId: string): Promise<boolean> {
    const delivered = this.deliveryRecords.find(record => record.orderId === orderId && record.deliveryStatus === 'success');
    return delivered !== undefined;
  }

  async grantUserBenefit(productId: string, orderId: string): Promise<void> {
    console.info(`Granting benefit for product: ${productId}, order: ${orderId}`);
  }

  async recordDeliveryOrder(purchaseOrder: PurchaseOrderPayload): Promise<void> {
    const record: DeliveryRecord = {
      orderId: purchaseOrder.purchaseOrderId,
      productId: purchaseOrder.productId,
      deliveryTime: Date.now(),
      deliveryStatus: 'success'
    };
    this.deliveryRecords.push(record);
    console.info(`Recorded delivery order: ${purchaseOrder.purchaseOrderId}`);
  }

  async confirmPurchaseDelivery(purchaseOrder: PurchaseOrderPayload, context: common.UIAbilityContext): Promise<void> {
    const finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: Number(purchaseOrder.productType),
      purchaseToken: purchaseOrder.purchaseToken,
      purchaseOrderId: purchaseOrder.purchaseOrderId
    };

    try {
      await iap.finishPurchase(context, finishPurchaseParam);
      console.info('Succeeded in finishing purchase.');
      await this.updateDeliveryConfirmation(purchaseOrder.purchaseOrderId);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
      this.handleFinishError(error, purchaseOrder);
    }
  }

  async updateDeliveryConfirmation(orderId: string): Promise<void> {
    const record = this.deliveryRecords.find(r => r.orderId === orderId);
    if (record) {
      record.deliveryStatus = 'confirmed';
    }
    console.info(`Delivery confirmed for order: ${orderId}`);
  }

  handleQueryError(error: BusinessError): void {
    switch (error.code) {
      case 1001860050:
        console.error('User not logged in. Please login first.');
        break;
      case 1001860005:
        console.error('Network error. Please check network connection.');
        break;
      case 1001860004:
        console.error('Too frequent API calls. Please wait and retry.');
        break;
      case 1001860054:
        console.error('IAP not supported in current region.');
        break;
      default:
        console.error(`Query error: ${error.message}`);
    }
  }

  handleFinishError(error: BusinessError, purchaseOrder: PurchaseOrderPayload): void {
    switch (error.code) {
      case 1001860052:
        console.error('Purchase not paid. Cannot finish delivery.');
        break;
      case 1001860053:
        console.error('Purchase already finished.');
        break;
      case 1001860001:
        console.error('System error. Will retry later.');
        this.scheduleRetryConfirmation(purchaseOrder);
        break;
      default:
        console.error(`Finish error: ${error.message}`);
    }
  }

  scheduleRetryConfirmation(purchaseOrder: PurchaseOrderPayload): void {
    console.info(`Scheduled retry for order: ${purchaseOrder.purchaseOrderId}`);
  }

  handleProcessError(err: any): void {
    console.error('Process error:', err);
  }

  handleDeliveryError(err: any, purchaseOrder: PurchaseOrderPayload): void {
    console.error('Delivery error:', err);
    const record: DeliveryRecord = {
      orderId: purchaseOrder.purchaseOrderId,
      productId: purchaseOrder.productId,
      deliveryTime: Date.now(),
      deliveryStatus: 'failed'
    };
    this.deliveryRecords.push(record);
  }

  build() {
    Column() {
      Text('Subscription Delivery Management')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`Status: ${this.processingStatus}`)
        .fontSize(16)
        .margin({ bottom: 20 });

      Button('Query Active Subscriptions')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.queryActiveSubscriptions(context);
        });

      Button('Query Unfinished Subscriptions')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.queryUnfinishedSubscriptions(context);
        });

      Text(`Delivery Records: ${this.deliveryRecords.length}`)
        .fontSize(16)
        .margin({ top: 20 });

      List() {
        ForEach(this.deliveryRecords, (record: DeliveryRecord) => {
          ListItem() {
            Row() {
              Text(`Order: ${record.orderId}`)
                .fontSize(14)
                .width('50%');
              Text(`Status: ${record.deliveryStatus}`)
                .fontSize(14)
                .width('50%');
            }
            .padding(10);
          }
        });
      }
      .width('90%')
      .height('40%')
      .margin({ top: 10 });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}