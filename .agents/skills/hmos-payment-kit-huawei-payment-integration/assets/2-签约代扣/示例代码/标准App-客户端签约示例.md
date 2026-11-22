# 标准 App 客户端签约示例

```ts
paymentService.requestContract(context, contractStr)
  .then(() => {
    console.info('succeeded in signing');
  })
  .catch((error: BusinessError) => {
    console.error(`failed to sign, error.code: ${error.code}, error.message: ${error.message}`);
  });
```

## 提示

- `contractStr` 来自服务端预签约结果。
- 客户端签约成功回调不代表服务端已完成最终签约处理。
