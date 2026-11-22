export interface PurchaseOrderPayload {
  environment: 'NORMAL' | 'SANDBOX';
  purchaseOrderId: string;
  purchaseToken: string;
  applicationId: string;
  productId: string;
  productType: '0' | '1' | '2' | '3';
  quantity?: number;
  purchaseTime: number;
  finishStatus?: '1' | '2';
  needFinish?: boolean;
  price: number;
  currency: string;
  developerPayload?: string;
  purchaseOrderRevocationReasonCode?: '0' | '1';
  revocationTime?: number;
  offerTypeCode?: '1' | '2' | '4';
  offerId?: string;
  countryCode: string;
  signedTime: number;
  subGroupGenerationId?: string;
  subscriptionId?: string;
  subGroupId?: string;
  duration?: string;
  durationTypeCode?: '0' | '1';
}

export interface PurchaseData {
  type: '0' | '1' | '2' | '3';
  jwsPurchaseOrder?: string;
  jwsSubscriptionStatus?: string;
}

export interface DeliveryStatus {
  orderId: string;
  status: 'pending' | 'delivered' | 'failed';
  deliveredAt?: number;
  quantity?: number;
}