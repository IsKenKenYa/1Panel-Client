# 鏌ヨ搴旂敤鍐呭揩鎹锋柟寮?
---
# 鏌ヨ搴旂敤鍐呭揩鎹锋柟寮?
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/62/v3/tqOBYdzMSRu-z36rhvI_cg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=416AEE13F1E01176A16DCEE4DFA35E2C08E24B7DEAD8BCBFEAF410FA70B05EB7)
6.1.1(24)鐗堟湰寮€濮嬶紝鏂板鏌ヨ妗岄潰蹇嵎鏂瑰紡鎺ュ彛锛屾敮鎸佺敤鎴锋煡璇㈡闈㈠揩鎹锋柟寮忋€?
#### 鍦烘櫙浠嬬粛
鏌ヨ搴旂敤鍐呭揩鎹锋柟寮忕敤浜庤幏鍙栧綋鍓嶅簲鐢ㄥ凡鍥哄畾鍦ㄦ闈笂鐨勬墍鏈夊揩鎹锋柟寮忓垪琛ㄣ€傜敤鎴峰彲浠ュ湪搴旂敤鍐呮煡鐪嬪凡娣诲姞鍒版闈㈢殑蹇嵎鏂瑰紡鍒楄〃锛屽揩閫熸壘鍒扮壒瀹氱殑蹇嵎鏂瑰紡銆備篃鍙€氳繃瀹氭湡鏌ョ湅鍜岀鐞嗚繖浜涘揩鎹锋柟寮忥紝纭繚妗岄潰鐨勬暣娲佸拰楂樻晥銆?
#### 涓氬姟娴佺▼
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/9e/v3/CiRWCBKHRGah5_Q1SzdmpQ/zh-cn_image_0000002659100797.png?HW-CC-KV=V1&HW-CC-Date=20260701T105134Z&HW-CC-Expire=86400&HW-CC-Sign=390D591C551961CE33496C2941289CF39BD0E3148C8C1571AC1CD59814B79F3C)
1.
鐢ㄦ埛闇€瑕佹煡璇㈠綋鍓嶅簲鐢ㄧ殑蹇嵎鏂瑰紡銆?
2.
搴旂敤璋冪敤 [getPinShortcutInfos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-productviewmanager) 鎺ュ彛鑾峰彇蹇嵎鏂瑰紡淇℃伅銆?
3.
AppGallery Kit杩斿洖鏌ヨ缁撴灉淇℃伅缁欏簲鐢ㄣ€?
4.
搴旂敤灏嗘煡璇㈢粨鏋滆繑鍥炵粰鐢ㄦ埛銆?
#### 绾︽潫涓庨檺鍒?
-
搴旂敤甯傚満鎺ㄨ崘鏈嶅姟涓嶆敮鎸佹ā鎷熷櫒锛岃浣跨敤鐪熸満璋冭瘯銆傚湪妯℃嫙鍣ㄤ腑浣跨敤璇ユ湇鍔″皢浼氭彁绀猴細鏃犳硶鑾峰彇鍐呭锛岃鐐瑰嚮灞忓箷閲嶈瘯銆?
-
搴旂敤甯傚満鎺ㄨ崘鏈嶅姟鏀寔Phone銆乀ablet銆丳C/2in1璁惧銆傚苟涓斾粠6.0.2(22)鐗堟湰寮€濮嬶紝鏂板鏀寔TV璁惧銆?
#### 鎺ュ彛璇存槑
璇︾粏鎺ュ彛璇存槑鍙弬鑰?[鎺ュ彛鏂囨。](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-productviewmanager) 銆?
| 鎺ュ彛鍚?| 鎻忚堪 |
| --- | --- |
| [getPinShortcutInfos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-productviewmanager)(): Promise<[PinShortcutInfo](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-productviewmanager)[]> | 鏌ヨ妗岄潰蹇嵎鏂瑰紡鍒楄〃銆?|
#### 寮€鍙戞楠?
1.
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
```
2.
[getPinShortcutInfos](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-productviewmanager)
```typescript
const TAG: string = 'GetPinShortcutInfos';
@Entry
@Component
struct GetPinShortcutInfos {
  build() {
    Column() {
      Button("GetPinShortcutInfos")
        .onClick(() => {
          try {
         // 閫氳繃getPinShortcutInfos鎺ュ彛鑾峰彇妗岄潰蹇嵎鏂瑰紡鍒楄〃淇℃伅
            productViewManager.getPinShortcutInfos()
              .then(() => {
                hilog.info(0x0001, TAG, `getPinShortcutInfos success.`);
              }).catch((error: BusinessError) => {
              hilog.error(0x0001, TAG, `getPinShortcutInfos error. code is ${error.code}, message is ${error.message}`);
             })
          } catch (err) {
            hilog.error(0x0001, TAG, `getPinShortcutInfos failed, code is ${err.code}, message is ${err.message}`);
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
