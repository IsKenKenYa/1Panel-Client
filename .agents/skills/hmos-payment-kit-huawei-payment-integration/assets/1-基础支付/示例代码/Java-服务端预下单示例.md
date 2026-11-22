# Java 服务端预下单示例

## 来源

基于本地 `pay-example/src/main/java/.../MercApiController.java` 提炼。

## 关键点

- 使用 `DefaultPetalPayClient`。
- 调用 `/api/v2/aggr/preorder/create/app`。
- 校验 `resultCode == "000000"` 后，返回 `buildOrderStr(response.getPrepayId())`。

## 最小示例

```java
PreOrderCreateRequestV2 preOrderReq = PreOrderCreateRequestV2.builder()
    .mercOrderNo("pay-example-" + System.currentTimeMillis())
    .appId(MercConfigUtil.APP_ID)
    .mercNo(MercConfigUtil.MERC_NO)
    .tradeSummary("请修改为对应的商品简称")
    .bizType("100002")
    .totalAmount(2L)
    .callbackUrl("https://www.xxxxxx.com/hw/pay/callback")
    .build();

PreOrderCreateResponse response = payClient.execute(
    "POST",
    "/api/v2/aggr/preorder/create/app",
    PreOrderCreateResponse.class,
    preOrderReq
);

return CommonResponse.buildSuccessRsp(payClient.buildOrderStr(response.getPrepayId()));
```

## 提示

- `appId`、`mercNo`、`authId`、私钥和回调公钥应从配置加载。
- 商户订单号必须唯一。
