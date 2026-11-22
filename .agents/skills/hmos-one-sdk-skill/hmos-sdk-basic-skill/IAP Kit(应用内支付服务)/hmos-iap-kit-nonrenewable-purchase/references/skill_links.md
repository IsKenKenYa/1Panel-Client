# API参考文档链接汇总

本文档汇总了非续期订阅商品购买技能所需的所有API参考文档链接。

## 核心API文档

### IAP Kit ArkTS API
- [IAP模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-iap)
  - queryEnvironmentStatus - 查询环境状态
  - queryProducts - 查询商品信息
  - createPurchase - 发起购买
  - finishPurchase - 完成购买确认发货

### 数据模型
- [数据类型说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-data-model)
  - Product - 商品信息模型
  - PurchaseData - 购买数据模型
  - PurchaseOrderPayload - 订单信息模型
  - QueryProductsParameter - 查询商品参数
  - PurchaseParameter - 购买参数
  - FinishPurchaseParameter - 完成购买参数

### 错误码
- [ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-error-code)
  - IAPErrorCode枚举定义
  - 错误码详解

## 服务端API文档

### REST API
- [解码验签](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-verifying-signature)
  - JWS解码验签流程
  - 公钥获取方法

- [服务端关键事件通知](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-key-event-notifications)
  - 购买成功事件通知
  - NotificationPayload数据结构

- [订单状态查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-query-order-status)
  - 服务端查询订单状态
  - jwsPurchaseOrder获取

- [订单确认发货](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-confirm-purchase-for-order)
  - 服务端确认发货接口
  - 完成购买流程

- [生成优惠签名购买参数](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/iap-server-subscribe-offer-sign)
  - 优惠促销签名生成

## 开发指南文档

### 应用内支付服务
- [接入购买](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-integrate-nonrenewable)
  - 非续期订阅商品购买完整流程

- [配置商品信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-config-product)
  - AppGallery Connect商品配置

- [权益发放](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-delivering-nonrenewable)
  - 购买失败补发货处理

- [使用入门](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/iap-dev-guide)
  - JWSUtil示例代码

## 设备和版本支持

### 支持设备
- Phone - 4.0.0(10)+
- Tablet - 4.0.0(10)+
- PC/2in1 - 4.0.0(10)+
- TV - 5.1.1(19)+
- Car - 26.0.0+

### API版本
- 非续期订阅商品支持起始版本：5.0.2(14)
- 批量购买(quantity参数)：5.0.3(15)+
- 元服务支持：5.0.2(14)+