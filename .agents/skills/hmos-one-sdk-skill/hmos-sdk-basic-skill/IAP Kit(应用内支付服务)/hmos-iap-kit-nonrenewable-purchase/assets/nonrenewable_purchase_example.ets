import { iap } from '@kit.IAPKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface PurchaseOrderPayload {
  purchaseOrderId: string;
  purchaseToken: string;
  productType: number;
  productId: string;
  purchaseTime: number;
  price: number;
  currency: string;
  purchaseOrderRevocationReasonCode?: string;
  quantity?: number;
}

@Entry
@Component
struct NonrenewablePurchaseExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private productList: Array<iap.Product> = [];
  @State purchaseStatus: string = '未购买';

  async checkIAPEnvironment(): Promise<boolean> {
    try {
      await iap.queryEnvironmentStatus(this.context);
      console.info('Succeeded in querying environment status.');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query environment status. Code: ${error.code}, Message: ${error.message}`);
      
      if (error.code === 1001860054) {
        console.warn('User account service region does not support IAP.');
        this.purchaseStatus = '当前地区不支持IAP';
      }
      return false;
    }
  }

  async queryProducts(): Promise<void> {
    const queryProductParam: iap.QueryProductsParameter = {
      productType: iap.ProductType.NONRENEWABLE,
      productIds: ['ohos_nonrenewable_001', 'ohos_nonrenewable_002']
    };

    try {
      const products = await iap.queryProducts(this.context, queryProductParam);
      this.productList = products;
      console.info(`Succeeded in querying products. Count: ${products.length}`);
      
      products.forEach(product => {
        console.info(`Product: ${product.productId}, Name: ${product.productName}, Price: ${product.price}`);
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to query products. Code: ${error.code}, Message: ${error.message}`);
      this.purchaseStatus = '商品查询失败';
    }
  }

  async purchaseProduct(productId: string, quantity?: number): Promise<void> {
    const purchaseParam: iap.PurchaseParameter = {
      productType: iap.ProductType.NONRENEWABLE,
      productId: productId,
      developerPayload: 'test_purchase_payload'
    };

    if (quantity && quantity >= 1 && quantity <= 10) {
      purchaseParam.quantity = quantity;
    }

    try {
      this.purchaseStatus = '购买中...';
      const result = await iap.createPurchase(this.context, purchaseParam);
      console.info('Succeeded in creating purchase.');
      
      await this.handlePurchaseResult(result);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to create purchase. Code: ${error.code}, Message: ${error.message}`);
      this.handlePurchaseError(error);
    }
  }

  async handlePurchaseResult(result: iap.CreatePurchaseResult): Promise<void> {
    const purchaseData = JSON.parse(result.purchaseData);
    const jwsPurchaseOrder = purchaseData.jwsPurchaseOrder;

    if (!jwsPurchaseOrder) {
      console.error('No purchase order data found.');
      this.purchaseStatus = '购买数据缺失';
      return;
    }

    const purchaseStr = this.decodeJws(jwsPurchaseOrder);
    const orderPayload: PurchaseOrderPayload = JSON.parse(purchaseStr);

    if (orderPayload.purchaseOrderRevocationReasonCode) {
      console.warn(`Purchase order revoked. Reason: ${orderPayload.purchaseOrderRevocationReasonCode}`);
      this.purchaseStatus = '订单已撤销';
      return;
    }

    try {
      await this.deliverEntitlement(orderPayload);
      console.info('Entitlement delivered successfully.');
      
      await this.finishPurchase(orderPayload);
      this.purchaseStatus = '购买成功';
    } catch (err) {
      console.error('Failed to deliver entitlement:', err);
      this.purchaseStatus = '权益发放失败';
    }
  }

  decodeJws(jws: string): string {
    const parts = jws.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWS format');
    }

    const payload = parts[1];
    const decoded = this.base64Decode(payload);
    return decoded;
  }

  base64Decode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let i = 0;
    
    str = str.replace(/[^A-Za-z0-9+/]/g, '');
    
    while (i < str.length) {
      const c1 = chars.indexOf(str.charAt(i++));
      const c2 = chars.indexOf(str.charAt(i++));
      const c3 = chars.indexOf(str.charAt(i++));
      const c4 = chars.indexOf(str.charAt(i++));

      const b1 = (c1 << 2) | (c2 >> 4);
      const b2 = ((c2 & 15) << 4) | (c3 >> 2);
      const b3 = ((c3 & 3) << 6) | c4;

      result += String.fromCharCode(b1);
      if (c3 !== 64) {
        result += String.fromCharCode(b2);
      }
      if (c4 !== 64) {
        result += String.fromCharCode(b3);
      }
    }

    return decodeURIComponent(escape(result));
  }

  async deliverEntitlement(order: PurchaseOrderPayload): Promise<void> {
    const delivered = await this.checkDeliverStatus(order.purchaseOrderId);
    if (delivered) {
      console.info('Entitlement already delivered.');
      return;
    }

    console.info(`Delivering entitlement for product: ${order.productId}`);
    console.info(`Purchase time: ${new Date(order.purchaseTime).toISOString()}`);
    console.info(`Price: ${order.price} ${order.currency}`);
    
    if (order.quantity) {
      console.info(`Quantity: ${order.quantity}`);
    }

    await this.saveDeliverRecord(order);
  }

  async checkDeliverStatus(orderId: string): Promise<boolean> {
    return false;
  }

  async saveDeliverRecord(order: PurchaseOrderPayload): Promise<void> {
    console.info(`Saving deliver record for order: ${order.purchaseOrderId}`);
  }

  async finishPurchase(order: PurchaseOrderPayload): Promise<void> {
    const finishParam: iap.FinishPurchaseParameter = {
      productType: order.productType,
      purchaseToken: order.purchaseToken,
      purchaseOrderId: order.purchaseOrderId
    };

    try {
      await iap.finishPurchase(this.context, finishParam);
      console.info('Succeeded in finishing purchase.');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to finish purchase. Code: ${error.code}, Message: ${error.message}`);
    }
  }

  handlePurchaseError(err: BusinessError): void {
    console.error(`Purchase failed. Code: ${err.code}, Message: ${err.message}`);

    if (err.code === iap.IAPErrorCode.PRODUCT_OWNED || err.code === iap.IAPErrorCode.SYSTEM_ERROR) {
      console.warn('Need to check and deliver entitlement.');
      this.purchaseStatus = '检查补发货';
    }

    switch (err.code) {
      case 1001860000:
        this.purchaseStatus = '用户取消购买';
        break;
      case 1001860004:
        this.purchaseStatus = '接口调用过频';
        break;
      case 1001860005:
        this.purchaseStatus = '网络连接异常';
        break;
      case 1001860054:
        this.purchaseStatus = '地区不支持IAP';
        break;
      default:
        this.purchaseStatus = `购买失败: ${err.code}`;
    }
  }

  async initPurchaseFlow(): Promise<void> {
    const envSupported = await this.checkIAPEnvironment();
    if (!envSupported) {
      return;
    }

    await this.queryProducts();
  }

  build() {
    Column({ space: 20 }) {
      Text('非续期订阅商品购买示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)

      Text(`状态: ${this.purchaseStatus}`)
        .fontSize(16)

      Button('初始化购买环境')
        .onClick(() => {
          this.initPurchaseFlow();
        })

      ForEach(this.productList, (product: iap.Product) => {
        Column({ space: 10 }) {
          Text(`商品: ${product.productName || product.productId}`)
            .fontSize(18)
          Text(`价格: ${product.price || '未知'}`)
            .fontSize(14)
          Button('购买')
            .onClick(() => {
              this.purchaseProduct(product.productId);
            })
        }
        .padding(10)
        .border({ width: 1, color: '#ccc' })
      })

      Button('批量购买(数量=3)')
        .onClick(() => {
          this.purchaseProduct('ohos_nonrenewable_001', 3);
        })
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}