# 展示广告时显示白屏

> 文档ID: ads-publisher-service-faq-4
> 版本: V280
> 更新时间: 2026-06-08 05:32:42

---

# 展示广告时显示白屏

       展示广告时出现白屏可能原因为展示的广告样式与UI展示页面不匹配，横幅广告使用[AutoAdComponent](api/js-apis-autoadcomponent.md)组件展示；原生广告、开屏广告、贴片广告使用[AdComponent](api/js-apis-adcomponent.md)组件展示；激励广告、插屏广告调用[showAd](api/js-apis-advertising.md)方法展示。

    建议排查步骤：


  - 获取请求广告时返回的广告数据并记录。

  - 打印展示广告时入参的广告数据，对比两者是否一致。

  - 检查请求的广告类型与使用的展示组件是否匹配。
