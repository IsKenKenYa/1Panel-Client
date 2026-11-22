# 标准 App 客户端支付示例

## 来源

来自本地示例工程 `payment-kit-codelab-clientdemo-arkts/entry/src/main/ets/pages/Index.ets`。

## 关键点

- 引入 `paymentService`。
- 从服务端拿到 `orderStr` 后再调用支付接口。
- 可使用 Promise 风格或 callback 风格。

## 最小示例

```ts
import { paymentService } from '@kit.PaymentKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

function startPay(context: common.UIAbilityContext, orderStr: string): void {
  paymentService.requestPayment(context, orderStr)
    .then(() => {
      console.info('succeeded in paying');
    })
    .catch((error: BusinessError) => {
      console.error(`failed to pay, error.code: ${error.code}, error.message: ${error.message}`);
    });
}
```

## 提示

- `orderStr` 由服务端预下单后返回。
- 客户端成功回调不代表最终支付成功。
