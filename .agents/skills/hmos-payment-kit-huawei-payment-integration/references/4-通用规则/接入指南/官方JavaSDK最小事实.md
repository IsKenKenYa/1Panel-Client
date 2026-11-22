# 官方 Java SDK 最小事实

> 本文件中的“华为支付”“鸿蒙支付服务”“HarmonyOS Payment Kit”默认视为同一主题下的不同叫法。

> 当用户要在 Spring Boot / Java工程中接入 HarmonyOS Payment Kit 服务端能力，且目标是“官方 SDK 主实现”时，优先使用这一组可验证事实，避免把“HTTP 手写网关”误判为唯一可行路径。

## 使用时机

- 用户明确要求“优先官方 SDK”或“必须使用官方 SDK”。
- 需要确认 `com.huawei.petalpay:pay-java` 是否可用。
- 需要核对关键类、关键 API 或样例调用，而不是凭印象生成 SDK 代码。

## 官方接入文档入口

- 服务端接入与依赖说明：[payment-server-connect](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/payment-server-connect)

## 官方样例工程

- Java 服务端示例仓库：[paymentkit-sample-code-serverdemo-java](https://gitcode.com/HarmonyOS_Samples/paymentkit-sample-code-serverdemo-java)

优先把官方样例当作 SDK 闸门的事实源，再决定是否继续写业务实现。

## 常见 Maven 坐标

- `com.huawei.petalpay:pay-java:<version>`
- Maven 仓库通常配置为 `https://developer.huawei.com/repo/`

说明：

- 版本号以官方样例 `pom.xml` 或官方文档为准，不要凭记忆填写。
- 若依赖尚未验证可解析，不要先写依赖相关 `import` 和 SDK 耦合实现。

## 常见关键类

- `com.huawei.petalpay.paymentservice.core.client.DefaultPetalPayClient`
- `com.huawei.petalpay.paymentservice.core.client.PetalPayClient`
- `com.huawei.petalpay.paymentservice.core.config.PetalPayConfig`
- `com.huawei.petalpay.paymentservice.apiservice.client.model.PreOrderCreateRequestV2`
- `com.huawei.petalpay.paymentservice.core.tools.VerifyTools`

## 直连商户基础支付样例事实

- 常见预下单调用：`payClient.execute("POST", "/api/v2/aggr/preorder/create/app", PreOrderCreateResponse.class, preOrderReq)`
- `orderStr` 优先通过 `payClient.buildOrderStr(prepayId)` 生成。

不要在业务工程里重复实现一套“拼接字段再签名”的 `orderStr` 生成器，除非官方文档明确要求自定义。

## SDK 可用性闸门

建议按下面顺序验证：

1. **依赖可解析**：执行依赖拉取，确认 `pay-java` 能进入本地仓库。
2. **关键类可见**：对 jar 使用 `javap` 或等价方式抽查关键类。
3. **关键 API 可确认**：以官方样例 `MercApiController`、`CallbackController` 为准核对方法签名与返回类型。
4. **再写业务代码**：通过闸门后再把 SDK 调用封装进用户工程。

若任一环节无法完成验证：

- 回退为“SDK 适配层 + HTTP 网关兜底”的结构。
- 明确告知这是降级方案，而不是已验证的 SDK 直连实现。
- 不得伪造 SDK 类名、配置对象、方法签名或请求/响应对象。

## 相关入口

- [服务端构建与依赖排障](服务端构建与依赖排障.md)
- [官方文档映射](../../6-资源索引/官方文档映射.md)
- [基础支付接口索引](../../../assets/1-基础支付/示例代码/接口索引.md)
