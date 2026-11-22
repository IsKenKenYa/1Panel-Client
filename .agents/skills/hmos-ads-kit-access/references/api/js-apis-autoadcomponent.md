# @ohos.advertising.AutoAdComponent (轮播广告展示组件)

> 文档ID: js-apis-autoadcomponent
> 版本: V66
> 更新时间: 2026-06-08 05:39:01

---

# @ohos.advertising.AutoAdComponent (轮播广告展示组件)

 本模块提供展示轮播广告的能力。

 ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/af/v3/gbRJSPPESeSQetudHV-n4A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260611T155228Z&HW-CC-Expire=86400&HW-CC-Sign=636B0A79521831787A96C91EB20E7E75DE23D84F26CEEFB6D267CFC50F720B5B)  本模块首批接口从API version 11开始支持。后续版本的新增接口，采用上角标单独标记接口的起始版本。

#### 导入模块

```
import { AutoAdComponent } from '@kit.AdsKit';
```
#### AutoAdComponent

```
AutoAdComponent({
  adParam: advertising.AdRequestParams,
  adOptions: advertising.AdOptions,
  displayOptions: advertising.AdDisplayOptions,
  interactionListener: advertising.AdInteractionListener
})
```
 用于展示轮播广告的组件。

 **装饰器类型：**@Component

 **元服务API：** 从API version 12开始，该接口支持在元服务中使用。

 **系统能力：** SystemCapability.Advertising.Ads

 **参数：**


| **参数名** | **类型** | 必填 | **装饰器类型** | 说明 |
| --- | --- | --- | --- | --- |
| adParam | advertising.[AdRequestParams](js-apis-advertising.md) | 是 | - | 广告请求参数。 |
| adOptions | advertising.[AdOptions](js-apis-advertising.md) | 是 | - | 广告配置参数。 |
| displayOptions | advertising.[AdDisplayOptions](js-apis-advertising.md) | 是 | - | 广告展示参数。 |
| interactionListener | advertising.[AdInteractionListener](js-apis-advertising.md) | 是 | - | 广告状态变化回调。 |

  **示例：**


```
import { advertising, AutoAdComponent } from '@kit.AdsKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  // 广告请求参数
  private adRequestParams: advertising.AdRequestParams = {
    // 广告位ID
    adId: 'h5xkz3mbr2',
    // 广告类型
    adType: 8,
    // 广告位宽，单位vp
    adWidth: 360,
    // 广告位高，单位vp
    adHeight: 57
  };
  // 广告配置参数
  private adOptions: advertising.AdOptions = {};
  // 广告展示参数
  private adDisplayOptions: advertising.AdDisplayOptions = {
    // 广告轮播的时间间隔，单位ms，取值范围[30000, 120000]
    refreshTime: 30000
  };
  private ratio: number = -1;

  aboutToAppear() {
    if (this.adRequestParams.adWidth && this.adRequestParams.adHeight) {
      this.ratio = this.adRequestParams.adWidth / this.adRequestParams.adHeight;
    }
  }
  
  build() {
    Column() {
      AutoAdComponent({
        adParam: this.adRequestParams,
        adOptions: this.adOptions,
        displayOptions: this.adDisplayOptions,
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            switch (status) {
              case 'onAdOpen':
                hilog.info(0x0000, 'testTag', 'onAdOpen');
                break;
              case 'onAdClick':
                hilog.info(0x0000, 'testTag', 'onAdClick');
                break;
              case 'onAdClose':
                hilog.info(0x0000, 'testTag', 'onAdClose');
                break;
            }
          }
        }
      })
        .width('100%')
        .aspectRatio(this.ratio)
    }
    .width('100%')
    .height('100%')
  }
}
```
 **效果图：**

 ![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/44/v3/0NXGpyGLTqGT9ZI8byABJA/zh-cn_image_0000002622698759.png?HW-CC-KV=V1&HW-CC-Date=20260611T155228Z&HW-CC-Expire=86400&HW-CC-Sign=3A30F04FAB84C829516DDCCD0A40D90E6EEA10157FC7B114831D96D989CC7E35)

### build

build(): void

 用于创建AutoAdComponent对象的构造函数。

 **元服务API：** 从API version 12开始，该接口支持在元服务中使用。

 **系统能力：** SystemCapability.Advertising.Ads
