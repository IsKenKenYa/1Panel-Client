# productViewManager (应用市场推荐)

提供展示应用/元服务详情页、应用内快捷方式加桌的能力。

调用接口需捕获异常。

**起始版本：** 4.1.0(11)

## 导入模块

```typescript
import { productViewManager } from '@kit.AppGalleryKit';
```

## ProductViewCallback

在加载应用详情页面时作为入参用于接收加载过程中的状态变化。

**模型约束：** 此接口仅可在Stage模型下使用。

**系统能力：** SystemCapability.AppGalleryService.Distribution.Recommendations

**起始版本：** 4.1.0(11)

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| onError | [ErrorCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-base) | 否 | 是 | 回调函数，接收应用详情页加载失败的错误码。1011表示拉起/切前台失败。1012表示切后台失败。1013表示销毁失败。 |
| onAppear | Callback<void> | 否 | 是 | 回调函数，当应用详情页成功打开时回调该方法。说明：**起始版本：**5.0.2(14)。 |
| onDisappear | Callback<void> | 否 | 是 | 回调函数，当应用详情页关闭时回调该方法。说明：**起始版本：**5.0.2(14)。 |

## SKExposure

登记归因来源的广告曝光数据。

**模型约束：** 此接口仅可在Stage模型下使用。

**系统能力：** SystemCapability.AppGalleryService.Distribution.Recommendations

**起始版本：** 5.0.2(14)

**参数：**

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| adTechId | string | 否 | 否 | 分发平台对应的归因角色ID，本次登记归因来源对应营销任务所归属的分发平台的标识符。分发平台向应用归因云侧[注册归因角色](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-register)时，由应用归因服务分配，长度固定为8字符。 |
| campaignId | string | 否 | 否 | 营销任务ID，登记归因来源对应的营销任务的ID，长度不超过6个字符。说明：从6.0.2(22)开始，该接口支持长度由不超过6个字符变为不超过9个字符。 |
| destinationId | string | 否 | 否 | 应用上架华为应用市场的AppId，长度不超过64个字符。说明：您的应用ID参考[查看应用基本信息](https://developer.huawei.com/consumer/cn/doc/app/agc-help-appinfo-0000001100014694)获取。 |
| mmpIds | string[] | 否 | 是 | 本次广告投放，使用的归因监测平台对应的归因角色ID。最大数量2个，每个ID字符串长度固定为8个字符。如果调用方传递了归因监测平台ID，应用归因服务会向归因监测平台回传归因结果；如果调用方没有传递监测平台ID，则归因监测平台收不到回传的归因结果。 |
| serviceTag | string | 否 | 是 | 分发平台关注的业务信息，如创意、素材等，长度不超过32字符。如果调用方传递了serviceTag，在[申请开通权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/store-attribution-register)后应用归因服务会将serviceTag回传分发平台。 |
| nonce | string | 否 | 否 | 用于计算签名的随机数，不带'-'，每次广告请求，nonce唯一。长度固定为32字符。同一个adTechId，同一个nonce最多可以登记5次曝光，5次点击类型的归因来源信息。 |
| timestamp | number | 否 | 否 | unix时间戳，单位：毫秒，请求广告的时间戳。（即广告投放时间，登记归因来源时，要求广告时间与当前时间偏差不超过10分钟） |
| signature | string | 否 | 否 | 签名值，分发平台/媒体根据广告相应信息按照[归因来源签名计算规则](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/appgallery-attribution-appendix-triger)计算生成签名并提供，长度不超过800个字符。 |

**示例：**

```typescript
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'LoadProduct';

@Entry
@Component
struct LoadProduct {
  build() {
    Column() {
      Button("load_product")
        .onClick(() => {
          try {
            // 登记归因来源的广告曝光数据
            const exposureData: productViewManager.SKExposure = {
              // 在应用归因云侧注册广告生态伙伴角色时，由应用归因服务分配
              adTechId: '20****e8',
              // 分发平台创建的营销任务id
              campaignId: '123456',
              // 开发者应用上架华为应用市场的appId，不带C
              destinationId: '10******',
              // 归因监测平台id
              mmpIds: ['2f****5', '2f7***5'],
              // 分发平台关注的业务信息
              serviceTag: '123***2',
              // 用于计算签名的随机数，不带'-'
              nonce: '123***2',
              // 时间戳
              timestamp: 1705536488,
              // 签名值
              signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg=='
            };

            const request: Want = {
              parameters: {
                bundleName: 'com.huawei.hmsapp.books',
                skExposure: exposureData
              }
            };

            // 展示应用详情页，下载安装目标应用
            productViewManager.loadProduct(this.getUIContext().getHostContext() as common.UIAbilityContext, request, {
              onError: (error: BusinessError) => {
                hilog.error(0, TAG, `loadProduct onError.code is ${error.code}, message is ${error.message}`);
              }
            });
          } catch (err) {
            hilog.error(0, TAG, `loadProduct failed.code is ${err.code}, message is ${err.message}`);
          }
        })
        .width('100%')
    }
    .margin(16)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

## productViewManager.loadProduct

loadProduct(context: common.UIAbilityContext, want: Want, callback?: ProductViewCallback): void

展示应用详情页，下载安装目标应用。使用Callback回调。

**模型约束：** 此接口仅可在Stage模型下使用。

**系统能力：** SystemCapability.AppGalleryService.Distribution.Recommendations

**设备行为差异：** 对于6.0.1(21)及之前版本，该接口在Phone、Tablet、PC/2in1中可正常使用，在其他设备类型中返回401错误码。对于6.0.2(22)及之后版本，该接口在Phone、Tablet、PC/2in1、TV中均可正常使用，在其他设备类型中返回401错误码。

**起始版本：** 4.1.0(11)

**参数：**

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext) | 是 | 调用方应用的上下文。 |
| want | [Want](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want) | 是 | 展示应用详情页的请求参数。parameters 是该参数中的必填属性，为一个结构体。该结构体包含两个属性：bundleName，必填，表示需要展示详情页的应用包名。skExposure，可选，表示需要传递登记归因来源的广告曝光数据。具体参考示例代码。 |
| callback | [ProductViewCallback](#productviewcallback) | 否 | 在加载应用详情页面时作为入参用于接收加载过程中的状态变化。若不填此参数，当加载应用详情页失败时，无法获取失败的错误码。 |

**错误码：**

以下错误码的详细介绍请参见 [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal) 。

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. |

**示例：**

```typescript
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';

const TAG: string = 'LoadProduct';

@Entry
@Component
struct LoadProduct {
  build() {
    Column() {
      Button("load_product")
        .onClick(() => {
          try {
            const request: Want = {
              parameters: {
                // 此处填入要加载的应用包名，例如： bundleName: "com.huawei.hmsapp.appgallery"
                bundleName: 'com.xxx'
              }
            };

            productViewManager.loadProduct(this.getUIContext().getHostContext() as common.UIAbilityContext, request, {
              onError: (error: BusinessError) => {
                hilog.error(0, TAG, `loadProduct onError.code is ${error.code}, message is ${error.message}`);
              },
              onAppear: () => {
                hilog.info(0, TAG, `loadProduct onAppear.`);
              },
              onDisappear: () => {
                hilog.info(0, TAG, `loadProduct onDisappear.`);
              }
            });
          } catch (err) {
            hilog.error(0, TAG, `loadProduct failed.code is ${err.code}, message is ${err.message}`);
          }
        })
        .width('100%')
    }
    .margin(16)
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```