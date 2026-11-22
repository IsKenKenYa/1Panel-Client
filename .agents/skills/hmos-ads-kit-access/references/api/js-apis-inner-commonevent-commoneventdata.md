# CommonEventData

> 文档ID: js-apis-inner-commonevent-commoneventdata
> 来源: js-apis-inner-commonevent-commoneventdata.md

---

# CommonEventData

公共事件数据对象，通过parameters参数获取事件携带的额外数据。

## 核心要点

- 激励广告/插屏广告的展示状态通过公共事件回传，订阅回调中收到的 `CommonEventData.parameters` 携带状态数据
- 激励广告：`parameters['reward_ad_status']` 为 `onAdReward`/`onAdClose`，`parameters['reward_ad_data']` 含 `rewardType`/`rewardAmount`
- 插屏广告：`parameters['interstitial_ad_status']` 为 `onAdClose`
- 订阅配置见 `ads-publisher-service-reward.md` 和 `ads-publisher-service-interstitial.md`

详细文档请参见：[CommonEventData - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-commonevent-commoneventdata)
