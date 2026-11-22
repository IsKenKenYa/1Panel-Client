# Java 支付回调示例

## 来源

基于本地 `CallbackController.java` 与 `MercConfigUtil.java` 提炼。

## 关键点

- 回调验签公钥应从配置加载。
- 使用 `VerifyTools.getCallbackResult(...)` 验签。
- 验签通过后再转 `NotifyPaymentReq`。

## 最小示例

```java
return VerifyTools.getCallbackResult(callbackStr, MercConfigUtil.HW_PAY_PUBLIC_KEY_FOR_CALLBACK, reqString -> {
    NotifyPaymentReq callbackReq = JSONObject.parseObject(reqString, NotifyPaymentReq.class);
    doProcess(callbackReq);
});
```

## 提示

- 示例中的业务处理需要你自己补充幂等逻辑。
- 返回值必须符合华为支付要求，否则会触发重试。
