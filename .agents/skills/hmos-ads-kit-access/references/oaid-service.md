# OAID服务

> 文档ID: oaid-service
> 来源: oaid-service.md

---

# OAID服务

OAID（开放匿名设备标识符）是用于广告精准推送的标识符服务。

## 核心要点

- **OAID**（Open Anonymous Device Identifier）是基于开放匿名设备标识符实现的非永久性设备标识，用于广告精准投放和转化跟踪，同时保护用户隐私
- 获取前需申请 `ohos.permission.APP_TRACKING_CONSENT` 用户授权（user_grant），并在 `module.json5` 中声明
- 广告请求 `AdRequestParams` 需携带 `oaid` 字段
- API 参考：`api/js-apis-oaid.md`

详细文档请参见：[OAID服务 - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/oaid-service)
