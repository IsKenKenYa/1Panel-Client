# ASCF 客户端签约示例

```js
has.requestContract({
  contractStr: '...服务端返回的 contractStr...',
  success: (res) => {
    console.log(`requestContract success, res = ${JSON.stringify(res)}`);
  },
  fail: (err) => {
    console.log(`requestContract fail, err = ${JSON.stringify(err)}`);
  },
  complete: (res) => {
    console.log(`requestContract complete, res = ${JSON.stringify(res)}`);
  }
});
```

## 提示

- ASCF 使用 `has.requestContract(...)`，不要误写成标准 App 形态。
