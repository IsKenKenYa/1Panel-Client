# 实时竞价

> 文档ID: ads-real-time-bidding
> 版本: V215
> 更新时间: 2026-06-08 05:32:29

---

# 实时竞价

#### 场景介绍

     实时竞价是指用户在访问媒体产生曝光机会时，众多家DSP（Demand Side Platform，需求方平台）根据曝光的上下文以及用户属性实时地评估曝光价值并给出报价，出价最高的DSP胜出，赢得此次曝光机会。

#### 约束与限制

     支持Phone、Tablet、PC/2in1设备。

     使用PC/2in1设备时，需要确保设备上智慧营销服务或广告服务的版本在8.4.80.300及以上，版本号可通过选择“设置> 应用和元服务 > 更多应用”查看。

#### 支持场景


  - 原生广告

  - 激励广告

  - 插屏广告

  - 开屏广告

  - 贴片广告


#### 接口说明


| 接口名 | 描述 |
| --- | --- |
| [loadAd](api/js-apis-advertising.md)(adParam: AdRequestParams, adOptions: AdOptions, listener: AdLoadListener): void | 请求单广告位广告，通过AdRequestParams、AdOptions进行广告请求参数设置，通过AdLoadListener监听广告请求回调。 |
| [loadAdWithMultiSlots](api/js-apis-advertising.md)(adParams: AdRequestParams[], adOptions: AdOptions, listener: MultiSlotsAdLoadListener): void | 请求多广告位广告，通过AdRequestParams[]、AdOptions进行广告请求参数设置，通过MultiSlotsAdLoadListener监听广告请求回调。 |

#### 开发步骤

### 添加竞价参数

     开发者需要在广告请求参数[AdRequestParams](api/js-apis-advertising.md)中添加实时竞价相关参数。

     实时竞价关键参数如下所示：


| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| tMax | number | 否 | 交易的最大超时时间（包含网络延迟），单位ms。 |
| cur | string | 否 | 竞价请求支持的币种，支持传多个，用英文逗号分隔。 |

          当前支持五种货币： CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。

          不填默认是CNY。


| bidFloor | number | 否 | 竞价广告位的底价。 |

          当前支持五种货币： CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。

          不填默认是CNY。


| bidFloorCur | string | 否 | 竞价广告位底价使用的币种。如果bidFloor非空，则bidFloorCur也非空。 |

          当前只支持五种货币中的一种： CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。

          不填默认是CNY。


| bpkgName | string | 否 | 广告位禁投的APP包名，支持传多个，用英文逗号分隔。 |

          示例代码如下所示：


```
import { advertising } from '@kit.AdsKit';

const adRequestParams: advertising.AdRequestParams = {
  // 'h8asowxwhq'为测试专用的广告位ID，暂无竞价信息，App正式发布时需要改为正式的广告位ID
  adId: 'h8asowxwhq',
  // 广告类型
  adType: 3,
  // 交易的最大超时时间
  tMax: 100,
  // 竞价请求支持的币种，多个用英文逗号分隔
  cur: 'CNY',
  // 竞价广告位的底价
  bidFloor: 6.66,
  // 竞价广告位底价使用的币种
  bidFloorCur: 'CNY',
  // 广告位禁投的APP包名，多个用英文逗号分隔
  bpkgName: 'com.huawei.baidu,com.huawei.music'
};
```
### 处理竞价结果

     开发者需要在广告请求成功后的回调AdLoadListener.[onAdLoadSuccess](api/js-apis-advertising.md)或MultiSlotsAdLoadListener.[onAdLoadSuccess](api/js-apis-advertising.md)中，处理广告返回的实时竞价结果[Advertisement](api/js-apis-advertisement.md).biddingInfo。

     实时竞价结果信息如下所示：

![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0a/v3/bN-t4YLjT1Kt0OYBbV-OWg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T154123Z&HW-CC-Expire=86400&HW-CC-Sign=8FDDB97F4BB3CB9D71E2B9AE60B25B7E48307723B07BC3BFB7BCDBA4D8933699)              回传竞价结果，需要申请使用Internet网络权限[ohos.permission.INTERNET](permissions-for-all.md)。详细申请权限流程请参考[开发准备](development-preparation.md)。


| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| price | number | 是 | 本条广告的eCPM（Effective Cost Per Mille，每一千次展示可以获得的广告收入）。支持币种：CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。 |
| cur | string | 是 | 本条广告的价格币种。支持币种：CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。 |
| nurl | string | 是 | 媒体回传竞价成功结果的URL。 |
| lurl | string | 是 | 媒体回传竞价失败结果的URL。 |


  - 若广告竞胜，开发者需要替换nurl中的宏，并回传竞胜结果。

       宏说明如下：


| 宏 | 说明 |
| --- | --- |
| SECOND_PRICE | 竞胜时，其他DSP最高出价。样例：3.6。 |
| AUCTION_CURRENCY | 价格币种。支持币种：CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。 |


  - 若广告竞败，开发者需要替换lurl中的宏，并回传竞败结果。

       宏说明如下：


| 宏 | 说明 |
| --- | --- |
| AUCTION_PRICE | 竞败时，其他DSP最高出价。样例：3.6。 |
| AUCTION_LOSS | 竞价结果，如果没有走到参竞环节也需要回调，并替换具体过滤结果码。 |

枚举：

102：竞价失败。

103：底价过滤。

104：包名过滤。

105：其他原因过滤。

4005：超时未返回。


| AUCTION_CURRENCY | 价格币种。支持币种：CNY（单位：元）、USD（单位：美元）、EUR（单位：欧元）、GBP（单位：英镑）、JPY（单位：日元）。 |
| --- | --- |
| AUCTION_APP_PKG | 竞败时，竞胜DSP推广的App包名。 |
| AUCTION_APP_NAME | 竞败时，竞胜DSP推广的App名称。 |
| AUCTION_CP_ID | 竞败时，竞胜DSP的编号： |

1：广点通

2：穿山甲

3：百青藤

4：快手联盟

5：爱奇艺

6：阿里

7：VIVO

8：OPPO

9：小米

10：京东

11：拼多多

100：其他


     示例代码如下所示：


```
import { advertising } from '@kit.AdsKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { rcp } from '@kit.RemoteCommunicationKit';

interface BiddingInfo {
  // 本条广告的eCPM（每一千次展示可以获得的广告收入）
  price: number;

  // 本条广告的价格币种
  cur: string;

  // 媒体回传竞价成功结果的URL
  nurl: string;

  // 媒体回传竞价失败结果的URL
  lurl: string;
}

const adLoaderListener: advertising.AdLoadListener = {
  // 广告请求失败回调
  onAdLoadFailure: (errorCode: number, errorMsg: string) => {
    hilog.error(0x0000, 'testTag', `Failed to load ad. Code is ${errorCode}, message is ${errorMsg}`);
  },
  // 广告请求成功回调
  onAdLoadSuccess: (ads: Array) => {
    hilog.info(0x0000, 'testTag', 'Succeeded in loading ad');
    // 期望的底价
    const bidFloor: number = 6;
    const biddingSuccessAds: Array = [];
    for (const ad of ads) {
      const biddingInfo: BiddingInfo = ad.biddingInfo as BiddingInfo;
      if (!biddingInfo) {
        continue;
      }
      if (biddingInfo.cur === 'CNY' && biddingInfo.price >= bidFloor) {
        hilog.info(0x0000, 'testTag', 'Petal Ads wins.');
        if (biddingInfo.nurl) {
          const url: string = biddingInfo.nurl
            // 竞胜时，其他DSP最高出价
            .replace('SECOND_PRICE', '3.6')
            // 价格币种
            .replace('AUCTION_CURRENCY', 'CNY');
          void sendBiddingResult(url).catch((error: BusinessError) => {
            hilog.error(0x0000, 'testTag',
              `Failed to sendBiddingResult. Code is ${error.code}, message is ${error.message}`);
          });
        }
        biddingSuccessAds.push(ad);
      } else {
        hilog.info(0x0000, 'testTag', 'Petal Ads loses.');
        if (biddingInfo.lurl) {
          const url: string = biddingInfo.lurl
            // 竞败时，其他DSP最高出价
            .replace('AUCTION_PRICE', '3.6')
            // 竞价结果
            .replace('AUCTION_LOSS', '102')
            // 价格币种
            .replace('AUCTION_CURRENCY', 'CNY')
            // 竞败时，竞胜DSP推广的App包名
            .replace('AUCTION_APP_PKG', 'com.huawei.music')
            // 竞败时，竞胜DSP推广的App名称
            .replace('AUCTION_APP_NAME', 'music')
            // 竞败时，竞胜DSP的编号
            .replace('AUCTION_CP_ID', '100')
          void sendBiddingResult(url).catch((error: BusinessError) => {
            hilog.error(0x0000, 'testTag',
              `Failed to sendBiddingResult. Code is ${error.code}, message is ${error.message}`);
          });
        }
      }
    }
    // ...此处省略展示广告的逻辑
  }
};

async function sendBiddingResult(url: string): Promise {
  let session: rcp.Session | undefined = undefined;
  try {
    session = rcp.createSession();
    await session.get(url);
  } catch (e) {
    hilog.error(0x0000, 'testTag', `Failed to send bidding result. Code is ${e.code}, message is ${e.message}`);
  } finally {
    session?.close();
  }
}
```
