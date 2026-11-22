# Java 服务端查单示例

## 适用场景

- 支付成功回调未到达，需要主动确认订单状态。
- 用户要求提供基础支付的服务端查询接口示例。

## 推荐优先级

- 未支付或刚发起支付时，优先按商户订单号查单。
- 已拿到平台交易号后，可按交易号补充查询。

## 最小结构示例

```java
Object response = payClient.execute(
    "GET",
    "/api/v2/aggr/transactions/merc-orders/{mercOrderNo}",
    Object.class
);
```

## 来源

- 基于 `QuickRequestApiTest.java` 中的 GET 示例提炼。

## 提示

- 查单通常作为回调未达、结果不确定时的兜底链路。
- 最终业务状态不要只看客户端回调。
