# Java 快速请求调试示例

## 适用场景

- 用户想快速验证某个接口是否可通。
- 用户正在补 SDK 尚未封装的新接口，想先用通用 `execute(...)` 探路。

## 最小示例

```java
Object response = payClient.execute(
    "POST",
    "/api/v2/aggr/preorder/create/app",
    Object.class,
    body
);
```

## 来源

- 基于 `QuickRequestApiTest.java` 提炼。

## 适用边界

- 适合联调验证和快速排障。
- 不适合直接替代正式的业务接口封装。
