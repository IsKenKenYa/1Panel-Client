# Java 服务端配置示例

## 适用场景

- 用户问 `petalpayconfig.properties` 应该包含哪些字段。
- 用户排查 `mercNo`、`authId`、回调验签公钥或域名配置问题。

## 配置示例

```properties
PETALPAY.MERC_PRIVATE_KEY=
PETALPAY.MERC_NO=
PETALPAY.MERC_AUTH_ID=
PETALPAY.SIGN_TYPE=
PETALPAY.SERVER_HOST=https://petalpay-developer.cloud.huawei.com.cn
PETALPAY.HW_PAY_PUBLIC_KEY_FOR_CALLBACK=
PETALPAY.HW_PUBLIC_KEY_FOR_SESSIONKEY=
PETALPAY.APPID=
```

## 字段说明

- `PETALPAY.MERC_PRIVATE_KEY`：商户私钥，仅保留在服务端。
- `PETALPAY.MERC_NO`：商户号。
- `PETALPAY.MERC_AUTH_ID`：商户证书或鉴权标识。
- `PETALPAY.SIGN_TYPE`：商户签名类型。
- `PETALPAY.SERVER_HOST`：当前环境域名。
- `PETALPAY.HW_PAY_PUBLIC_KEY_FOR_CALLBACK`：回调验签公钥。
- `PETALPAY.HW_PUBLIC_KEY_FOR_SESSIONKEY`：敏感字段加密相关公钥。
- `PETALPAY.APPID`：与商户关联的应用 `appId`。

## 提示

- 沙盒和生产配置要分开管理。
- 生产环境不要把私钥放在代码仓库里。
