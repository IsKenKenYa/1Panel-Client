# 基于服务账号生成鉴权令牌 - 开发指南

**原文链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-deviceverify-token

---

> **注意**：只有使用应用设备状态检测服务时才需要配置此章节。

## 概述

服务账号（Service Account）是一种可实现服务器与服务器之间接口鉴权的账号，在华为开发者联盟的 [API Console](https://developer.huawei.com/consumer/cn/console/overview) 上创建服务账号，您可根据返回的公私钥在业务应用中生成鉴权令牌，调用支持此类鉴权的华为公开API。

服务账号令牌为JWT（JSON Web Token）格式字符串，JWT数据格式包括三个部分：
- Header（头部）
- Payload（负载）
- Signature（签名）

这三个部分通过"."进行连接，其中Signature为通过SHA256withRSA算法对Header与Payload拼接的字符串签名生成的字符串。

**示例**
```json
eyJra*****JjNjBjMXXX.
eyJhd*****JodHRXXX.
BRNss*****7az5oU7-Zp5g9X2WJVXXX
```

更多JWT的相关知识请参见 [Introduction to JSON Web Tokens](https://jwt.io/introduction/) 。

## 开发步骤

### 步骤1：创建服务账号密钥文件

开发者需要在华为开发者联盟的 [API Console](https://developer.huawei.com/consumer/cn/console/overview) 上创建并下载服务账号的密钥文件，相关创建步骤请参见 [API Console操作指南-服务账号密钥](https://developer.huawei.com/consumer/cn/doc/start/api-0000001062522591#section91275725415) 。

> **注意**：您在开发者联盟需要申请开发者级的服务账号凭证。

服务账号密钥样例文件形式可参考：
```json
{
    "project_id": "*****",
    "key_id": "*****",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIJQgIBADANBgkqhkiG9w0BAQEFAASCCSwwggkoAgEAAoICAQCKw6kJKtCh7qmMvp1u1dI27z2TKZrPOzHbQaXO/Eez0AWZ2EN+ouF496R3pfo7fQXC1XOT/YTbVC4DNZwWSMA54fu3/AOCY9Zzyi46OK*****==\n-----END PRIVATE KEY-----\n",
    "sub_account": "*****",
    "auth_uri": "https://oauth-login.cloud.huawei.com/oauth2/v3/authorize",
    "token_uri": "https://oauth-login.cloud.huawei.com/oauth2/v3/token",
    "auth_provider_cert_uri": "https://oauth-login.cloud.huawei.com/oauth2/v3/certs",
    "client_cert_uri": "https://oauth-login.cloud.huawei.com/oauth2/v3/x509?client_id=*****"
}
```

### 步骤2：生成JWT Header数据

根据服务账号密钥文件中的key_id字段拼接以下JSON体，对JSON体进行BASE64编码。

```json
{
  "kid": "*****",
  "typ": "JWT",
  "alg": "PS256"
}
```

| 字段名 | 描述 |
| --- | --- |
| kid | 服务账号密钥文件中key_id字段。 |
| typ | 数据类型，固定为：JWT。 |
| alg | 算法类型，固定为：PS256。 |

### 步骤3：生成JWT Payload数据

根据服务账号密钥文件中的sub_account字段拼接以下JSON体，对JSON体进行BASE64编码。

```json
{
  "aud": "https://oauth-login.cloud.huawei.com/oauth2/v3/token",
  "iss": "*****",
  "exp": 1581410664,
  "iat": 1581407064
}
```

| 字段名 | 描述 |
| --- | --- |
| aud | 固定为：https://oauth-login.cloud.huawei.com/oauth2/v3/token。 |
| iss | 服务账号密钥文件中sub_account字段，标识数据生成者。 |
| exp | JWT到期UTC时间戳，建议比"iat"晚3600秒。 |
| iat | JWT签发UTC时间戳，为自UTC时间1970年1月1日00:00:00的秒数（应用服务器时间需要校准为标准时间）。 |

### 步骤4：生成JWT Token数据

将完成BASE64编码后的Header字符串与Payload字符串，通过"."进行连接，并在开发者的应用中，通过服务账号密钥文件中的private_key（华为不进行存储，请您妥善保管），使用SHA256withRSA/PSS算法对拼接的字符串签名，最后将Header，Payload以及字符串签名通过"."进行连接，即可得到Token数据。

## 示例代码

为了方便您生成服务账号鉴权令牌，我们提供了Java语言的示例代码，请按照说明替换参数运行。

如果您使用其他开发语言，请选择对应的 [JWT开源组件](https://www.jwt.io/libraries) 进行开发。

完整示例代码请参见：[Java示例](../assets/JWTGenerateDemo.java)

推荐的java版本为java8，maven依赖配置请参见：[pom.xml](../assets/pom.xml)