# Java 服务端预签约示例

## 来源

基于本地 `MercApiController.java` 中的预签约逻辑提炼。

## 最小示例

```java
PreSignRequestV2 preSignReq = PreSignRequestV2.builder()
    .appId(MercConfigUtil.APP_ID)
    .mercContractCode("pay-example-" + System.currentTimeMillis())
    .mercNo(MercConfigUtil.MERC_NO)
    .planId("100")
    .callbackUrl("https://www.xxxxxx.com/hw/sign/callback")
    .build();

PreSignResponse response = payClient.execute(
    "POST",
    "/api/v2/contract/presign/app",
    PreSignResponse.class,
    preSignReq
);

return CommonResponse.buildSuccessRsp(payClient.buildContractStr(response.getPreSignNo()));
```

## 提示

- 协议号需要保证唯一。
- `planId` 必须与商户实际申请的协议模板一致。
