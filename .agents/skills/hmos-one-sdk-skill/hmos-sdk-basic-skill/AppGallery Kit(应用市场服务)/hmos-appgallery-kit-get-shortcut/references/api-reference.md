# productViewManager (搴旂敤甯傚満鎺ㄨ崘)
---
# productViewManager (搴旂敤甯傚満鎺ㄨ崘)
鎻愪緵灞曠ず搴旂敤/鍏冩湇鍔¤鎯呴〉銆佸簲鐢ㄥ唴蹇嵎鏂瑰紡鍔犳鐨勮兘鍔涖€?
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/53/v3/F5dxDUebTzGYqTXPasCBcA/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093800Z&HW-CC-Expire=86400&HW-CC-Sign=BC5ACCEEA164A83EDEFA3958CACAC354BFFA84129319680944637A0650C1DFB9)
璋冪敤鎺ュ彛闇€鎹曡幏寮傚父銆?
**璧峰鐗堟湰锛?* 4.1.0(11)
#### 瀵煎叆妯″潡
```typescript
import { productViewManager } from '@kit.AppGalleryKit';
```
#### ProductViewCallback
鍦ㄥ姞杞藉簲鐢ㄨ鎯呴〉闈㈡椂浣滀负鍏ュ弬鐢ㄤ簬鎺ユ敹鍔犺浇杩囩▼涓殑鐘舵€佸彉鍖栥€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 4.1.0(11)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| onError | [ErrorCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/绯荤粺/鍩虹鍔熻兘/Basic Services Kit锛堝熀纭€鏈嶅姟锛?ArkTS API/鍏朵粬/js-apis-base) | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屾帴鏀跺簲鐢ㄨ鎯呴〉鍔犺浇澶辫触鐨勯敊璇爜銆?011琛ㄧず鎷夎捣/鍒囧墠鍙板け璐ャ€?012琛ㄧず鍒囧悗鍙板け璐ャ€?013琛ㄧず閿€姣佸け璐ャ€?|
| onAppear | Callback<void> | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屽綋搴旂敤璇︽儏椤垫垚鍔熸墦寮€鏃跺洖璋冭鏂规硶銆傝鏄庯細**璧峰鐗堟湰锛?*5.0.2(14)銆?|
| onDisappear | Callback<void> | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屽綋搴旂敤璇︽儏椤靛叧闂椂鍥炶皟璇ユ柟娉曘€傝鏄庯細**璧峰鐗堟湰锛?*5.0.2(14)銆?|
#### ServiceViewCallback
鍦ㄥ姞杞藉厓鏈嶅姟鍗＄墖鍔犳椤甸潰鏃朵綔涓哄叆鍙傜敤浜庢帴鏀跺姞杞借繃绋嬩腑鐨勭姸鎬佸彉鍖栥€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 4.1.0(11)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| onReceive | Callback<[ServiceViewReceiveData](#section530571318012)> | 鍚?| 鏄?| 褰撴墦寮€鍏冩湇鍔″崱鐗囧姞妗岄〉鎴愬姛锛岀偣鍑诲姞妗岋紝鏀跺埌鍔犳缁撴灉銆?|
| onError | [ErrorCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/绯荤粺/鍩虹鍔熻兘/Basic Services Kit锛堝熀纭€鏈嶅姟锛?ArkTS API/鍏朵粬/js-apis-base) | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屾帴鏀跺厓鏈嶅姟鍗＄墖鍔犳椤靛姞杞藉け璐ョ殑閿欒鐮併€?011琛ㄧず鎷夎捣/鍒囧墠鍙板け璐ャ€?012琛ㄧず鍒囧悗鍙板け璐ャ€?013琛ㄧず閿€姣佸け璐ャ€?|
| onAppear | Callback<void> | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屽綋鍏冩湇鍔″崱鐗囧姞妗岄〉鎴愬姛鎵撳紑鏃跺洖璋冭鏂规硶銆傝鏄庯細**璧峰鐗堟湰**锛?.0.2(14)銆?|
| onDisappear | Callback<void> | 鍚?| 鏄?| 鍥炶皟鍑芥暟锛屽綋鍏冩湇鍔″崱鐗囧姞妗岄〉鍏抽棴鏃跺洖璋冭鏂规硶銆傝鏄庯細**璧峰鐗堟湰**锛?.0.2(14)銆?|
#### ServiceViewReceiveData
鍏冩湇鍔″姞妗屽洖璋冩暟鎹€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 4.1.0(11)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| result | [ReceiveDataResult](#section1690663817619) | 鏄?| 鍚?| 鍔犳缁撴灉銆?|
| msg | string | 鏄?| 鍚?| 鍔犳缁撴灉鎻忚堪淇℃伅銆?|
| formInfo | {[key: string]: Object;} | 鏄?| 鍚?| 鍔犳鍗＄墖鏁版嵁銆傛湁浠ヤ笅蹇呭～灞炴€э細bundleName琛ㄧず鍏冩湇鍔″寘鍚嶃€俷ame琛ㄧず鍗＄墖鍚嶇О銆俛bilityName琛ㄧずability鍚嶇О銆俶oduleName琛ㄧず鍏冩湇鍔℃ā鍧楀悕銆俤efaultDimension琛ㄧず鍗＄墖灏哄銆?|
#### ReceiveDataResult
鍏冩湇鍔″姞妗岀粨鏋滅爜绫诲瀷鐨勬灇涓俱€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 4.1.0(11)
| 鍚嶇О | 鍊?| 璇存槑 |
| --- | --- | --- |
| SUCCESS | 1000 | 鎴愬姛銆?|
| FAILURE | 1001 | 澶辫触銆?|
| EXCEPTION | 1002 | 寮傚父銆?|
#### CheckShortcutResult
蹇嵎鏂瑰紡鏍￠獙缁撴灉銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 5.0.2(14)
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| tid | string | 鍚?| 鏄?| 鍩轰簬搴旂敤鐨勫揩鎹锋柟寮忎俊鎭敓鎴愮殑Transaction ID銆傝嫢蹇嵎鏂瑰紡淇℃伅鍙戠敓鍙樺寲锛屽垯姣忔瑕嗙洊鐢熸垚鏂扮殑tid锛屽惁鍒欒繑鍥炲巻鍙瞭id浠ュ強鍓╀綑杩囨湡鏃堕棿expired銆?|
| expired | number | 鍚?| 鏄?| Transaction ID鐨勮繃鏈熸椂闂达紝鍗曚綅鏄痬s銆?|
| code | number | 鍚?| 鍚?| 鏍￠獙鐨勭粨鏋滅爜锛?琛ㄧず鏍￠獙鎴愬姛锛屽惁鍒欏叿浣撶殑澶辫触鍘熷洜锛屽彲浠ュ弬鑰僛ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-error-code)銆?|
| limit | number | 鍚?| 鏄?| 鍏佽搴旂敤娣诲姞蹇嵎鏂瑰紡鐨勬暟閲忋€?|
#### SKExposure
鐧昏褰掑洜鏉ユ簮鐨勫箍鍛婃洕鍏夋暟鎹€?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璧峰鐗堟湰锛?* 5.0.2(14)
**鍙傛暟锛?*
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| adTechId | string | 鍚?| 鍚?| 鍒嗗彂骞冲彴瀵瑰簲鐨勫綊鍥犺鑹睮D锛屾湰娆＄櫥璁板綊鍥犳潵婧愬搴旇惀閿€浠诲姟鎵€褰掑睘鐨勫垎鍙戝钩鍙扮殑鏍囪瘑绗︺€傚垎鍙戝钩鍙板悜搴旂敤褰掑洜浜戜晶[娉ㄥ唽褰掑洜瑙掕壊](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/搴旂敤褰掑洜鏈嶅姟/寮€鍙戝噯澶?绠＄悊褰掑洜瑙掕壊/store-attribution-register)鏃讹紝鐢卞簲鐢ㄥ綊鍥犳湇鍔″垎閰嶏紝闀垮害鍥哄畾涓?瀛楃銆?|
| campaignId | string | 鍚?| 鍚?| 钀ラ攢浠诲姟ID锛岀櫥璁板綊鍥犳潵婧愬搴旂殑钀ラ攢浠诲姟鐨処D锛岄暱搴︿笉瓒呰繃6涓瓧绗︺€傝鏄庯細浠?.0.2(22)寮€濮嬶紝璇ユ帴鍙ｆ敮鎸侀暱搴︾敱涓嶈秴杩?涓瓧绗﹀彉涓轰笉瓒呰繃9涓瓧绗︺€?|
| destinationId | string | 鍚?| 鍚?| 搴旂敤涓婃灦鍗庝负搴旂敤甯傚満鐨凙ppId锛岄暱搴︿笉瓒呰繃64涓瓧绗︺€傝鏄庯細鎮ㄧ殑搴旂敤ID鍙傝€僛鏌ョ湅搴旂敤鍩烘湰淇℃伅](https://developer.huawei.com/consumer/cn/doc/app/agc-help-appinfo-0000001100014694)鑾峰彇銆?|
| mmpIds | string[] | 鍚?| 鏄?| 鏈骞垮憡鎶曟斁锛屼娇鐢ㄧ殑褰掑洜鐩戞祴骞冲彴瀵瑰簲鐨勫綊鍥犺鑹睮D銆傛渶澶ф暟閲?涓紝姣忎釜ID瀛楃涓查暱搴﹀浐瀹氫负8涓瓧绗︺€傚鏋滆皟鐢ㄦ柟浼犻€掍簡褰掑洜鐩戞祴骞冲彴ID锛屽簲鐢ㄥ綊鍥犳湇鍔′細鍚戝綊鍥犵洃娴嬪钩鍙板洖浼犲綊鍥犵粨鏋滐紱濡傛灉璋冪敤鏂规病鏈変紶閫掔洃娴嬪钩鍙癐D锛屽垯褰掑洜鐩戞祴骞冲彴鏀朵笉鍒板洖浼犵殑褰掑洜缁撴灉銆?|
| serviceTag | string | 鍚?| 鏄?| 鍒嗗彂骞冲彴鍏虫敞鐨勪笟鍔′俊鎭紝濡傚垱鎰忋€佺礌鏉愮瓑锛岄暱搴︿笉瓒呰繃32瀛楃銆傚鏋滆皟鐢ㄦ柟浼犻€掍簡serviceTag锛屽湪[鐢宠寮€閫氭潈闄怾(https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/搴旂敤褰掑洜鏈嶅姟/寮€鍙戝噯澶?绠＄悊褰掑洜瑙掕壊/store-attribution-register)鍚庡簲鐢ㄥ綊鍥犳湇鍔′細灏唖erviceTag鍥炰紶鍒嗗彂骞冲彴銆?|
| nonce | string | 鍚?| 鍚?| 鐢ㄤ簬璁＄畻绛惧悕鐨勯殢鏈烘暟锛屼笉甯?-'锛屾瘡娆″箍鍛婅姹傦紝nonce鍞竴銆傞暱搴﹀浐瀹氫负32瀛楃銆傚悓涓€涓猘dTechId锛屽悓涓€涓猲once鏈€澶氬彲浠ョ櫥璁?娆℃洕鍏夛紝5娆＄偣鍑荤被鍨嬬殑褰掑洜鏉ユ簮淇℃伅銆?|
| timestamp | number | 鍚?| 鍚?| unix鏃堕棿鎴筹紝鍗曚綅锛氭绉掞紝璇锋眰骞垮憡鐨勬椂闂存埑銆傦紙鍗冲箍鍛婃姇鏀炬椂闂达紝鐧昏褰掑洜鏉ユ簮鏃讹紝瑕佹眰骞垮憡鏃堕棿涓庡綋鍓嶆椂闂村亸宸笉瓒呰繃10鍒嗛挓锛?|
| signature | string | 鍚?| 鍚?| 绛惧悕鍊硷紝鍒嗗彂骞冲彴/濯掍綋鏍规嵁骞垮憡鐩稿簲淇℃伅鎸夌収[褰掑洜鏉ユ簮绛惧悕璁＄畻瑙勫垯](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/闄勫綍/鏍囧噯鍖栦簨浠跺強搴旂敤褰掑洜绛惧悕/appgallery-attribution-appendix-triger)璁＄畻鐢熸垚绛惧悕骞舵彁渚涳紝闀垮害涓嶈秴杩?00涓瓧绗︺€?|
**绀轰緥锛?*
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
            // 鐧昏褰掑洜鏉ユ簮鐨勫箍鍛婃洕鍏夋暟鎹?
            const exposureData: productViewManager.SKExposure = {
              // 鍦ㄥ簲鐢ㄥ綊鍥犱簯渚ф敞鍐屽箍鍛婄敓鎬佷紮浼磋鑹叉椂锛岀敱搴旂敤褰掑洜鏈嶅姟鍒嗛厤
              adTechId: '20****e8',
              // 鍒嗗彂骞冲彴鍒涘缓鐨勮惀閿€浠诲姟id
              campaignId: '123456',
              // 寮€鍙戣€呭簲鐢ㄤ笂鏋跺崕涓哄簲鐢ㄥ競鍦虹殑appId锛屼笉甯
              destinationId: '10******',
              // 褰掑洜鐩戞祴骞冲彴id
              mmpIds: ['2f****5', '2f7***5'],
              // 鍒嗗彂骞冲彴鍏虫敞鐨勪笟鍔′俊鎭?
              serviceTag: '123***2',
              // 鐢ㄤ簬璁＄畻绛惧悕鐨勯殢鏈烘暟锛屼笉甯?-'
              nonce: '123***2',
              // 鏃堕棿鎴?
              timestamp: 1705536488,
              // 绛惧悕鍊?
              signature: 'MEQCIEQlmZ****zKBSE8QnhLTIHZZZ****ZpRqRxHss65Ko****JgJKjdrWdkL****juEx2RmFS7da****ZRVZ8RyMyUXg=='
            };
            const request: Want = {
              parameters: {
                bundleName: 'com.huawei.hmsapp.books',
                skExposure: exposureData
              }
            };
            // 灞曠ず搴旂敤璇︽儏椤碉紝涓嬭浇瀹夎鐩爣搴旂敤
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
#### productViewManager.loadProduct
loadProduct(context: common.UIAbilityContext, want: Want, callback?: ProductViewCallback): void
灞曠ず搴旂敤璇︽儏椤碉紝涓嬭浇瀹夎鐩爣搴旂敤銆備娇鐢–allback鍥炶皟銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璁惧琛屼负宸紓锛?* 瀵逛簬6.0.1(21)鍙婁箣鍓嶇増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€傚浜?.0.2(22)鍙婁箣鍚庣増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1銆乀V涓潎鍙甯镐娇鐢紝鍦ㄥ叾浠栬澶囩被鍨嬩腑杩斿洖401閿欒鐮併€?
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/鎺ュ彛渚濊禆鐨勫厓绱犲強瀹氫箟/application/js-apis-inner-application-uiabilitycontext) | 鏄?| 璋冪敤鏂瑰簲鐢ㄧ殑涓婁笅鏂囥€?|
| want | [Want](D:/code/APIDevice/output/md_output/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/閫氱敤鑳藉姏鐨勬帴鍙?鎺ㄨ崘)/js-apis-app-ability-want.md) | 鏄?| 灞曠ず搴旂敤璇︽儏椤电殑璇锋眰鍙傛暟銆俻arameters 鏄鍙傛暟涓殑蹇呭～灞炴€э紝涓轰竴涓粨鏋勪綋銆傝缁撴瀯浣撳寘鍚袱涓睘鎬э細bundleName锛屽繀濉紝琛ㄧず闇€瑕佸睍绀鸿鎯呴〉鐨勫簲鐢ㄥ寘鍚嶃€俿kExposure锛屽彲閫夛紝琛ㄧず闇€瑕佷紶閫掔櫥璁板綊鍥犳潵婧愮殑骞垮憡鏇濆厜鏁版嵁銆傚叿浣撳弬鑰冪ず渚嬩唬鐮併€?|
| callback | [ProductViewCallback](#section1744815172418) | 鍚?| 鍦ㄥ姞杞藉簲鐢ㄨ鎯呴〉闈㈡椂浣滀负鍏ュ弬鐢ㄤ簬鎺ユ敹鍔犺浇杩囩▼涓殑鐘舵€佸彉鍖栥€傝嫢涓嶅～姝ゅ弬鏁帮紝褰撳姞杞藉簲鐢ㄨ鎯呴〉澶辫触鏃讹紝鏃犳硶鑾峰彇澶辫触鐨勯敊璇爜銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/API鍙傝€冩杩?errorcode-universal) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. |
**绀轰緥锛?*
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
                // 姝ゅ濉叆瑕佸姞杞界殑搴旂敤鍖呭悕锛屼緥濡傦細 bundleName: "com.huawei.hmsapp.appgallery"
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
#### productViewManager.loadService
loadService(context: common.UIAbilityContext, want: Want, callback?: ServiceViewCallback): void
灞曠ず鍏冩湇鍔¤鎯呴〉锛屾坊鍔犺嚦妗岄潰銆備娇鐢–allback鍥炶皟銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璁惧琛屼负宸紓锛?* 瀵逛簬6.0.1(21)鍙婁箣鍓嶇増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€傚浜?.0.2(22)鍙婁箣鍚庣増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛孴V涓棤鍝嶅簲锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€?
**璧峰鐗堟湰锛?* 4.1.0(11)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/鎺ュ彛渚濊禆鐨勫厓绱犲強瀹氫箟/application/js-apis-inner-application-uiabilitycontext) | 鏄?| 璋冪敤鏂瑰簲鐢ㄧ殑涓婁笅鏂囥€?|
| want | [Want](D:/code/APIDevice/output/md_output/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/閫氱敤鑳藉姏鐨勬帴鍙?鎺ㄨ崘)/js-apis-app-ability-want.md) | 鏄?| 鍔犺浇鍏冩湇鍔¤鎯呴〉闈㈡帴鍙ｇ殑璇锋眰鍙傛暟銆倁ri涓哄繀濉弬鏁帮紝鍏跺€间负鍏冩湇鍔″姞妗岄摼鎺ャ€傚叿浣撳彲鍙傝€冧笅鏂囦腑鐨勭ず渚嬩唬鐮併€?|
| callback | [ServiceViewCallback](#section428319231351) | 鍚?| 鍦ㄥ姞杞藉厓鏈嶅姟璇︽儏椤甸潰鏃朵綔涓哄叆鍙傜敤浜庢帴鏀跺姞杞借繃绋嬩腑鐨勭姸鎬佸彉鍖栥€傝嫢涓嶅～姝ゅ弬鏁帮紝褰撳姞杞藉厓鏈嶅姟璇︽儏椤靛け璐ユ椂锛屾棤娉曡繑鍥炲け璐ョ殑閿欒鐮侊紱褰撳姞杞藉厓鏈嶅姟璇︽儏椤垫垚鍔熸椂锛岀偣鍑诲姞妗岋紝鏃犳硶鑾峰彇鍔犳缁撴灉銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/API鍙傝€冩杩?errorcode-universal) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. |
**绀轰緥锛?*
```typescript
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
const TAG: string = 'LoadService';
@Entry
@Component
struct LoadService {
  build() {
    Column() {
      Button("load_service")
        .onClick(() => {
          try {
            const request: Want = {
              // 璇疯緭鍏ュ厓鏈嶅姟鐨勫姞妗岄摼鎺?
              uri: 'store://appgallery.huawei.com/oper/addhome?referrer=xxxx&id=xxxx&installType=xxxx&s=xxxx'
            };
            productViewManager.loadService(this.getUIContext().getHostContext() as common.UIAbilityContext, request, {
              onReceive: (data: productViewManager.ServiceViewReceiveData) => {
                hilog.info(0, TAG, `Succeeded in loading Service onReceive.result is ${data.result}, msg is ${data.msg}`);
              },
              onError: (error: BusinessError) => {
                hilog.error(0, TAG, `loadService onError.code is ${error.code}, message is ${error.message}`)
              },
              onAppear: () => {
                hilog.info(0, TAG, `loadService onAppear.`);
              },
              onDisappear: () => {
                hilog.info(0, TAG, `loadService onDisappear.`);
              }
            });
          } catch (err) {
            hilog.error(0, TAG, `loadService failed.code is ${err.code}, message is ${err.message}`);
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
#### productViewManager.checkPinShortcutPermitted
checkPinShortcutPermitted(context: common.UIAbilityContext, shortcutId: string, want: Want, labelResName: string, iconResName: string): Promise<CheckShortcutResult>
浠ラ潤鎬佽祫婧愭柟寮忔牎楠屽揩鎹锋柟寮忔槸鍚﹀厑璁稿姞妗岋紝浣跨敤Promise寮傛鍥炶皟銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璁惧琛屼负宸紓锛?* 瀵逛簬6.0.1(21)鍙婁箣鍓嶇増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€傚浜?.0.2(22)鍙婁箣鍚庣増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛孴V涓繑鍥?006620001閿欒鐮侊紝鍦ㄥ叾浠栬澶囩被鍨嬩腑杩斿洖401閿欒鐮併€?
**璧峰鐗堟湰锛?* 5.0.2(14)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/鎺ュ彛渚濊禆鐨勫厓绱犲強瀹氫箟/application/js-apis-inner-application-uiabilitycontext) | 鏄?| 璋冪敤鏂瑰簲鐢ㄧ殑涓婁笅鏂囥€?|
| shortcutId | string | 鏄?| 蹇嵎鏂瑰紡ID锛屽彇鍊间负闀垮害涓嶈秴杩?3瀛楄妭鐨勫瓧绗︿覆銆?|
| want | [Want](D:/code/APIDevice/output/md_output/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/閫氱敤鑳藉姏鐨勬帴鍙?鎺ㄨ崘)/js-apis-app-ability-want.md) | 鏄?| 鐐瑰嚮蹇嵎鏂瑰紡鍚庤鎷夎捣鏂圭殑want淇℃伅銆?|
| labelResName | string | 鏄?| 蹇嵎鏂瑰紡鏄剧ず鍦ㄦ闈㈠悕绉扮殑label璧勬簮绱㈠紩鍚嶇О銆?|
| iconResName | string | 鏄?| 蹇嵎鏂瑰紡鏄剧ず鍦ㄦ闈㈠浘鏍囩殑icon璧勬簮绱㈠紩鍚嶇О銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<[CheckShortcutResult](#section1548317391199)> | Promise瀵硅薄锛岃繑鍥炲揩鎹锋柟寮忔牎楠岀粨鏋溿€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. |
| 1006620001 | System internal error. |
| 1006620002 | Request to service error. |
| 1006620003 | Shortcut id already exists. |
| 1006620004 | The number of shortcuts has reached the maximum. |
| 1006620005 | Shortcut verification failed. |
**绀轰緥锛?*
```typescript
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
const TAG: string = 'CheckPinShortcutPermitted';
@Entry
@Component
struct CheckPinShortcutPermitted {
  build() {
    Column() {
      Button("checkPinShortcutPermitted")
        .onClick(() => {
          try {
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const shortcutId = "id_test1"; // 瀵瑰簲shortcuts鏍囩涓厤缃殑shortcutId, 渚嬪: "shortcutId": "id_test1"
            const labelResName = "shortcut"; // 瀵瑰簲shortcuts鏍囩涓厤缃殑label璧勬簮绱㈠紩鍚嶇О, 渚嬪: "label": "$string:shortcut"
            const iconResName = "aa_icon"; // 瀵瑰簲shortcuts鏍囩涓厤缃殑icon璧勬簮绱㈠紩鍚嶇О, 渚嬪: "icon": "$media:aa_icon"
            const want: Want = {
              bundleName: "com.example.appgallery.kit.demo",
              moduleName: "entry",
              abilityName: "EntryAbility",
              parameters: {
                testKey: "testValue"
              }
            };
            // 浠ラ潤鎬佽祫婧愭柟寮忔牎楠屽揩鎹锋柟寮忔槸鍚﹀厑璁稿姞妗?骞惰繑鍥炲揩鎹锋柟寮忔牎楠岀粨鏋?
            productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, labelResName, iconResName)
              .then((result: productViewManager.CheckShortcutResult) => {
                hilog.info(0x0001, TAG, `checkPinShortcutPermitted success result is ${JSON.stringify(result)}`);
              }).catch((error: BusinessError) => {
              hilog.error(0x0001, TAG, `checkPinShortcutPermitted error. code is ${error.code}, message is ${error.message}`);
            })
          } catch (err) {
            hilog.error(0x0001, TAG, `checkPinShortcutPermitted failed, code is ${err.code}, message is ${err.message}`);
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
#### productViewManager.checkPinShortcutPermitted
checkPinShortcutPermitted(context: common.UIAbilityContext, shortcutId: string, want: Want, label: string, foregroundIcon: string, backgroundIcon: string): Promise<CheckShortcutResult>
浠ヨ嚜瀹氫箟璧勬簮鏂瑰紡鏍￠獙蹇嵎鏂瑰紡鏄惁鍏佽鍔犳锛屼娇鐢≒romise寮傛鍥炶皟銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璁惧琛屼负宸紓锛?* 瀵逛簬6.0.1(21)鍙婁箣鍓嶇増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€傚浜?.0.2(22)鍙婁箣鍚庣増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛孴V涓繑鍥?006620001閿欒鐮侊紝鍦ㄥ叾浠栬澶囩被鍨嬩腑杩斿洖401閿欒鐮併€?
**璧峰鐗堟湰锛?* 5.0.2(14)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/鎺ュ彛渚濊禆鐨勫厓绱犲強瀹氫箟/application/js-apis-inner-application-uiabilitycontext) | 鏄?| 涓婁笅鏂囥€?|
| shortcutId | string | 鏄?| 蹇嵎鏂瑰紡ID锛屽彇鍊间负闀垮害涓嶈秴杩?3瀛楄妭鐨勫瓧绗︿覆銆?|
| want | [Want](D:/code/APIDevice/output/md_output/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/閫氱敤鑳藉姏鐨勬帴鍙?鎺ㄨ崘)/js-apis-app-ability-want.md) | 鏄?| 鐐瑰嚮蹇嵎鏂瑰紡鍚庤鎷夎捣鏂圭殑want淇℃伅銆?|
| label | string | 鏄?| 蹇嵎鏂瑰紡鏄剧ず鍦ㄦ闈㈠悕绉扮殑鏂囨湰锛岄暱搴︿笉瓒呰繃255涓瓧绗︺€?|
| foregroundIcon | string | 鏄?| 蹇嵎鏂瑰紡鏄剧ず鍦ㄦ闈㈠浘鏍囩殑娌欑鍦板潃锛屽浘鏍囨渶澶т笉瓒呰繃100KB锛屾牸寮忎负png鍜寃ebp銆?|
| backgroundIcon | string | 鏄?| 棰勭暀瀛楁锛岀洰鍓嶅彧鏀寔浼犲叆绌哄瓧绗︿覆銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<[CheckShortcutResult](#section1548317391199)> | Promise瀵硅薄锛岃繑鍥炲揩鎹锋柟寮忔牎楠岀粨鏋溿€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. |
| 1006620001 | System internal error. |
| 1006620002 | Request to service error. |
| 1006620003 | Shortcut id already exists. |
| 1006620004 | The number of shortcuts has reached the maximum. |
| 1006620005 | Shortcut verification failed. |
**绀轰緥锛?*
```typescript
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
const TAG: string = 'CheckPinShortcutPermitted';
@Entry
@Component
struct CheckPinShortcutPermitted {
  build() {
    Column() {
      Button("checkPinShortcutPermitted")
        .onClick(() => {
          try {
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const shortcutId = `shortcutId_1`;
            const want: Want = {
              bundleName: "com.example.appgallery.kit.demo",
              moduleName: "entry",
              abilityName: "EntryAbility",
              parameters: {
                testKey: "testValue"
              }
            }
            const label = "shortcut";
            const foregroundIcon = uiContext.filesDir + "/icon.png";
            const backgroundIcon = "";
            // 浠ヨ嚜瀹氫箟璧勬簮鏂瑰紡鏍￠獙蹇嵎鏂瑰紡鏄惁鍏佽鍔犳,杩斿洖蹇嵎鏂瑰紡鏍￠獙缁撴灉
            productViewManager.checkPinShortcutPermitted(uiContext, shortcutId, want, label, foregroundIcon, backgroundIcon)
              .then((result: productViewManager.CheckShortcutResult) => {
                hilog.info(0x0001, TAG, `checkPinShortcutPermitted success result is ${JSON.stringify(result)}`);
              }).catch((error: BusinessError) => {
              hilog.error(0x0001, TAG, `checkPinShortcutPermitted error. code is ${error.code}, message is ${error.message}`);
            })
          } catch (err) {
            hilog.error(0x0001, TAG, `checkPinShortcutPermitted failed, code is ${err.code}, message is ${err.message}`);
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
#### productViewManager.requestNewPinShortcut
requestNewPinShortcut(context: common.UIAbilityContext, tid: string): Promise<void>
鍒涘缓蹇嵎鏂瑰紡鍔犳锛屼娇鐢≒romise寮傛鍥炶皟銆?
**妯″瀷绾︽潫锛?* 姝ゆ帴鍙ｄ粎鍙湪Stage妯″瀷涓嬩娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.AppGalleryService.Distribution.Recommendations
**璁惧琛屼负宸紓锛?* 瀵逛簬6.0.1(21)鍙婁箣鍓嶇増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€傚浜?.0.2(22)鍙婁箣鍚庣増鏈紝璇ユ帴鍙ｅ湪Phone銆乀ablet銆丳C/2in1涓彲姝ｅ父浣跨敤锛孴V涓棤鍝嶅簲锛屽湪鍏朵粬璁惧绫诲瀷涓繑鍥?01閿欒鐮併€?
**璧峰鐗堟湰锛?* 5.0.2(14)
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| context | [common.UIAbilityContext](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤妗嗘灦/Ability Kit锛堢▼搴忔鏋舵湇鍔★級/ArkTS API/鎺ュ彛渚濊禆鐨勫厓绱犲強瀹氫箟/application/js-apis-inner-application-uiabilitycontext) | 鏄?| 涓婁笅鏂囥€?|
| tid | string | 鏄?| 蹇嵎鏂瑰紡鏍￠獙缁撴灉[CheckShortcutResult](#section1548317391199)杩斿洖鐨則id銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<void> | Promise瀵硅薄銆傛棤杩斿洖缁撴灉鐨凱romise瀵硅薄銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[ArkTS API閿欒鐮乚(https://developer.huawei.com/consumer/cn/doc/harmonyos-references/搴旂敤鏈嶅姟/AppGallery Kit锛堝簲鐢ㄥ競鍦烘湇鍔★級/ArkTS API/store-error-code) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. |
| 1006620001 | System internal error. |
| 1006620003 | Shortcut id already exists. |
| 1006620004 | The number of shortcuts has reached the maximum. |
| 1006620005 | Shortcut verification failed. |
| 1006620006 | The shortcut is not verified or has expired. |
| 1006620007 | User refused to add shortcut. |
**绀轰緥锛?*
```typescript
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { productViewManager } from '@kit.AppGalleryKit';
const TAG: string = 'RequestNewPinShortcut';
@Entry
@Component
struct RequestNewPinShortcut {
  build() {
    Column() {
      Button("RequestNewPinShortcut")
        .onClick(() => {
          try {
            const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            const tid = 'xxx'; // 閫氳繃checkPinShortcutPermitted鎺ュ彛鑾峰彇
            productViewManager.requestNewPinShortcut(uiContext, tid)
              .then(() => {
                hilog.info(0x0001, TAG, `requestNewPinShortcut success.`);
              }).catch((error: BusinessError) => {
              hilog.error(0x0001, TAG, `requestNewPinShortcut error. code is ${error.code}, message is ${error.message}`);
            })
          } catch (err) {
            hilog.error(0x0001, TAG, `requestNewPinShortcut failed, code is ${err.code}, message is ${err.message}`);
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
