# ASCF 客户端支付示例

## 适用场景

- 用户明确是 ASCF 元服务。
- 用户要求使用 `has.requestPayment(...)`。

## 最小示例

```js
has.requestPayment({
  orderStr: '...服务端返回的 orderStr...',
  success: (res) => {
    console.log(`requestPayment success, res = ${JSON.stringify(res)}`);
  },
  fail: (err) => {
    console.log(`requestPayment fail, err = ${JSON.stringify(err)}`);
  },
  complete: (res) => {
    console.log(`requestPayment complete, res = ${JSON.stringify(res)}`);
  }
});
```

## 提示

- 该示例用于元服务接口形态，不能与标准 App 的 `paymentService.requestPayment(...)` 混用。
- 仍需以服务端回调或查单确认最终结果。
