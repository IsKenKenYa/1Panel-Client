# 静默登录参考文档索引

本文件汇总了静默登录技能相关的所有参考文档链接。

## 客户端开发文档

### API开发指南
- 原始文档：account-silent-login.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-silent-login

### API参考文档
- authentication模块：account-api-authentication.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication

### 开发准备文档
- 配置签名和指纹：account-sign-fingerprints.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints

- 配置Client ID：account-client-id.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-client-id

### 相关场景文档
- 客户端与服务端交互开发：account-phone-unionid-login.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-phone-unionid-login

- ID Token解析与验证：account-faq-12.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-12

## 服务端开发文档

### REST API参考
- 获取用户级凭证：account-api-obtain-user-token.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-user-token

- 解析凭证：account-api-get-token-info.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-get-token-info

- 刷新用户级凭证：account-api-obtain-refresh-token.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-obtain-refresh-token

- TLS协议及加密套件：account-api-common.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-common

## 错误码参考

### 客户端错误码
- Account Kit错误码：account-api-error-code.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code

- 通用错误码：errorcode-account.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-account

- 通用错误码：errorcode-universal.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal

## 常见问题

- Access Token和Refresh Token长度限制要求：account-faq-11.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-11

- OpenID和UnionID的格式说明：account-faq-9.md
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-faq-9

## API模块依赖

### ArkTS模块
- util模块（js-apis-util.md）
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-util

- common模块（js-apis-app-ability-common.md）
- 在线链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-common

## 文档转换规则

根据用户要求，所有本地MD文档链接已转换为华为开发者网站在线链接：
1. harmonyos-guides目录下的文档：转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/... 格式
2. harmonyos-references目录下的文档：转换为 https://developer.huawei.com/consumer/cn/doc/harmonyos-references/... 格式
3. 去掉.md后缀，保留文档名称

示例：
- 原始路径：D:/code/APIDevice/output/md_output/harmonyos-guides/应用服务/Account Kit（华为账号服务）/登录/静默登录/account-silent-login.md
- 转换链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-silent-login