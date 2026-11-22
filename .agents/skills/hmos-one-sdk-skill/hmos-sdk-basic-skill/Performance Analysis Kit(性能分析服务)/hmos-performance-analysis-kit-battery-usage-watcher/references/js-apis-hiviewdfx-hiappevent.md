# @ohos.hiviewdfx.hiAppEvent (搴旂敤浜嬩欢鎵撶偣)
---
# @ohos.hiviewdfx.hiAppEvent (搴旂敤浜嬩欢鎵撶偣)
鏈ā鍧楁彁渚涘簲鐢ㄦ墦鐐瑰拰浜嬩欢璁㈤槄鑳藉姏锛屽寘鎷簨浠跺瓨鍌ㄣ€佷簨浠惰闃呫€佷簨浠舵竻鐞嗐€佹墦鐐归厤缃瓑鍔熻兘銆侶iAppEvent灏嗗簲鐢ㄨ繍琛岃繃绋嬩腑瑙﹀彂鐨勪簨浠朵俊鎭粺涓€褰掔撼鍒?[AppEventInfo](#appeventinfo) 涓紝骞跺皢浜嬩欢鍒嗕负绯荤粺浜嬩欢鍜屽簲鐢ㄤ簨浠朵袱绫汇€?
绯荤粺浜嬩欢鏉ユ簮浜庣郴缁熸湇鍔★紝鏄郴缁熼鍏堝畾涔夌殑浜嬩欢锛岃繖绫讳簨浠朵俊鎭腑鐨勪簨浠跺弬鏁板璞arams鍖呭惈鐨勫瓧娈靛凡鐢卞悇绯荤粺浜嬩欢瀹氫箟锛屽叿浣撳瓧娈靛惈涔夊湪鍚勭郴缁熶簨浠舵寚鍗楃殑浠嬬粛涓紝渚嬪 [宕╂簝浜嬩欢浠嬬粛](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/宕╂簝浜嬩欢/宕╂簝浜嬩欢浠嬬粛/hiappevent-watcher-crash-events) 銆?
搴旂敤浜嬩欢鏉ユ簮浜庡簲鐢紝鏄簲鐢ㄥ紑鍙戣€呰嚜宸卞畾涔夌殑浜嬩欢锛岃繖绫讳簨浠朵俊鎭敮鎸佽嚜瀹氫箟鍚庨€氳繃 [Write](#hiappeventwrite-1) 鎵撶偣鎺ュ彛杩涜閰嶇疆璁惧畾锛屽叿浣撳瓧娈靛惈涔夊彲缁撳悎寮€鍙戣€呴渶姹傚睍寮€銆?
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/fd/v3/W58j43eMQcKgr0-cdDCkUQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=BE476CAAE41FE12426A331D6BE27BF5D8B6C026C4604F31825F3EB900834FEB9)
鏈ā鍧楅鎵规帴鍙ｄ粠API version 9寮€濮嬫敮鎸併€傚悗缁増鏈殑鏂板鎺ュ彛锛岄噰鐢ㄤ笂瑙掓爣鍗曠嫭鏍囪鎺ュ彛鐨勮捣濮嬬増鏈€?
#### 瀵煎叆妯″潡
```
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
```
#### hiAppEvent.addWatcher
addWatcher(watcher: Watcher): AppEventPackageHolder
娣诲姞浜嬩欢瑙傚療鑰呫€傚彲閫氳繃浜嬩欢瑙傚療鑰呯殑鍥炶皟鍑芥暟鐩戝惉浜嬩欢銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| watcher | [Watcher](#watcher) | 鏄?| 浜嬩欢瑙傚療鑰呫€?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| [AppEventPackageHolder](#appeventpackageholder) | 璁㈤槄鏁版嵁鎸佹湁鑰呫€傝闃呭け璐ユ椂杩斿洖null銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11102002 | Invalid filtering event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11102003 | Invalid row value. Possible caused by the row value is less than zero. |
| 11102004 | Invalid size value. Possible caused by the size value is less than zero. |
| 11102005 | Invalid timeout value. Possible caused by the timeout value is less than zero. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/2e/v3/t5e6thXUSYW-ik1soDVHCg/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=6FB308BF4F10A9AAA8CCDAF2DDA154EAC97C9F7DCF0B333322F3F4B9CD18FC6C)
addWatcher鎺ュ彛娑夊強I/O鎿嶄綔銆傚湪瀵规€ц兘鏁忔劅鐨勪笟鍔″満鏅腑锛屽紑鍙戣€呭簲鏍规嵁瀹為檯闇€瑕佺‘瀹氳鎺ュ彛鏄湪涓荤嚎绋嬭繕鏄湪瀛愮嚎绋嬩腑璋冪敤銆?
濡傛灉閫夋嫨鍦ㄥ瓙绾跨▼涓皟鐢╝ddWatcher锛岄渶瑕佺‘淇濊瀛愮嚎绋嬪湪鏁翠釜鎺ュ彛浣跨敤鍛ㄦ湡鍐呬笉浼氳閿€姣侊紝浠ュ厤褰卞搷鎺ュ彛鐨勬甯稿伐浣溿€?
鍙弬鑰?[Worker绠€浠媇(D:/code/APIDevice/output/md_output/harmonyos-guides/搴旂敤妗嗘灦/ArkTS锛堟柟鑸熺紪绋嬭瑷€锛?ArkTS骞跺彂/澶氱嚎绋嬪苟鍙?Worker绠€浠?worker-introduction.md) 锛屼互瀹炵幇鍦ㄥ瓙绾跨▼涓皟鐢ㄦ帴鍙ｃ€?
璁㈤槄鎺ュ彛addWatcher浼犲叆鐨勫悕绉皀ame鏄敮涓€鐨勶紝鐩稿悓鐨刵ame锛屽悗涓€娆¤皟鐢ㄤ細瑕嗙洊鍓嶄竴娆＄殑璁㈤槄銆?
**绀轰緥锛?*
鏍规嵁娣诲姞鐨勪簨浠惰瀵熻€呯被鍨嬶紝鐩墠鏈夊涓嬩笁绉嶄娇鐢ㄦ柟娉曪細
鏂规硶涓€锛氳缃洖璋冩潯浠秚riggerCondition锛屽疄鐜皁nTrigger()鍥炶皟銆傚綋婊¤冻鍥炶皟鏉′欢鏃讹紝绯荤粺灏嗚嚜鍔ㄨЕ鍙戝洖璋冦€?
```
import { hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.addWatcher({
  name: "watcher1",
  // 璁㈤槄杩囨护鏉′欢锛岃繖閲屾槸璁㈤槄浜嗙郴缁熶簨浠堕鍩熺殑搴旂敤宕╂簝浜嬩欢
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  // 璁剧疆瑙﹀彂onTrigger鍥炶皟鐨勬潯浠讹紝杩欓噷鏄綋婊¤冻浜嬩欢鎬绘暟閲忚揪鍒?0涓垨浜嬩欢鎬诲ぇ灏忚揪鍒?000byte鎴栦簨浠跺彂鐢熻秴杩?0s鏃朵細瑙﹀彂鍥炶皟
  triggerCondition: {
    row: 10,
    size: 1000,
    timeOut: 1
  },
  // 瀹炵幇onTrigger鍥炶皟锛岀粨鍚坱riggerCondition浣跨敤锛屾弧瓒冲洖璋冩潯浠惰Е鍙戝洖璋冿紝鎺ユ敹鍒板洖璋冮€氱煡鍚庯紝浣跨敤takeNext()鏌ヨ璁㈤槄鐨勪簨浠?
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'hiAppEvent', "holder is null");
      return;
    }
    hilog.info(0x0000, 'hiAppEvent', `curRow=${curRow}, curSize=${curSize}`);
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.packageId=${eventPkg.packageId}`);
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.row=${eventPkg.row}`);
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.size=${eventPkg.size}`);
      for (const eventInfo of eventPkg.data) {
        hilog.info(0x0000, 'hiAppEvent', `eventPkg.data=${eventInfo}`);
      }
    }
  }
});
```
鏂规硶浜岋細鏈缃洖璋冩潯浠跺弬鏁帮紝浣跨敤浜嬩欢璁㈤槄杩斿洖鐨刪older瀵硅薄涓诲姩鑾峰彇鐩戝惉鐨勪簨浠躲€?
閽堝寮傚父閫€鍑烘椂浜х敓鐨勫穿婧冧簨浠讹紙hiAppEvent.event.APP_CRASH锛夊拰搴旂敤鍐诲睆浜嬩欢锛坔iAppEvent.event.APP_FREEZE锛夛紝绯荤粺鎹曡幏缁存祴鏃ュ織鏈変竴瀹氳€楁椂锛屽吀鍨嬫儏鍐典笅30s鍐呭畬鎴愶紝鏋佺鎯呭喌涓?min宸﹀彸瀹屾垚銆?
鍦ㄦ墜鍔ㄥ鐞嗚闃呬簨浠剁殑鏂规硶涓紝鐢变簬浜嬩欢鍙兘鏈敓鎴愭垨鏃ュ織淇℃伅鏈姄鍙栧畬鎴愶紝寤鸿鍦ㄨ繘绋嬪惎鍔ㄥ悗寤舵椂閲嶈瘯璋冪敤takeNext()鑾峰彇姝ょ被浜嬩欢銆?
```
import { hilog } from '@kit.PerformanceAnalysisKit';
let holder: hiAppEvent.AppEventPackageHolder = hiAppEvent.addWatcher({
  name: "watcher2",
  // 璁㈤槄杩囨护鏉′欢锛岃繖閲屾槸璁㈤槄浜嗙郴缁熶簨浠堕鍩熺殑搴旂敤宕╂簝浜嬩欢
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
});
// 閫氳繃璁㈤槄鏁版嵁鎸佹湁鑰卙older锛屼富鍔ㄨ幏鍙栧穿婧冧簨浠?
if (holder != null) {
  let eventPkg: hiAppEvent.AppEventPackage | null = null;
  while ((eventPkg = holder.takeNext()) != null) {
    hilog.info(0x0000, 'hiAppEvent', `eventPkg.packageId=${eventPkg.packageId}`);
    hilog.info(0x0000, 'hiAppEvent', `eventPkg.row=${eventPkg.row}`);
    hilog.info(0x0000, 'hiAppEvent', `eventPkg.size=${eventPkg.size}`);
    for (const eventInfo of eventPkg.data) {
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.data=${eventInfo}`);
    }
  }
}
```
鏂规硶涓夛細瀹炵幇onReceive()鍥炶皟锛屽綋鐩戝惉鐨勪簨浠跺彂鐢熷悗瀹炴椂瑙﹀彂鍥炶皟銆?
```
import { hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.addWatcher({
  name: "watcher3",
  // 璁㈤槄杩囨护鏉′欢锛岃繖閲屾槸璁㈤槄浜嗙郴缁熶簨浠堕鍩熺殑搴旂敤宕╂簝浜嬩欢
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  // 瀹炵幇onReceive鍥炶皟锛岀洃鍚埌浜嬩欢鍚庡疄鏃跺洖璋?
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'hiAppEvent', `domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'hiAppEvent', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'hiAppEvent', `event=${JSON.stringify(eventInfo)}`, );
      }
    }
  }
});
```
#### hiAppEvent.removeWatcher
removeWatcher(watcher: Watcher): void
绉婚櫎浜嬩欢瑙傚療鑰呫€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| watcher | [Watcher](#watcher) | 鏄?| 浜嬩欢瑙傚療鑰呫€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
**绀轰緥锛?*
```
// 1. 瀹氫箟涓€涓簨浠惰瀵熻€?
let watcher: hiAppEvent.Watcher = {
  name: "watcher1",
}
// 2. 娣诲姞涓€涓簨浠惰瀵熻€呮潵璁㈤槄浜嬩欢
hiAppEvent.addWatcher(watcher);
// 3. 绉婚櫎璇ヤ簨浠惰瀵熻€呬互鍙栨秷璁㈤槄浜嬩欢
hiAppEvent.removeWatcher(watcher);
```
#### hiAppEvent.setEventParam12+
setEventParam(params: Record<string, ParamType>, domain: string, name?: string): Promise<void>
浜嬩欢鑷畾涔夊弬鏁拌缃柟娉曪紝浣跨敤Promise鏂瑰紡浣滀负寮傛鍥炶皟銆傚湪鍚屼竴鐢熷懡鍛ㄦ湡涓紝鍙互閫氳繃浜嬩欢棰嗗煙鍜屼簨浠跺悕绉板叧鑱旂郴缁熶簨浠跺拰搴旂敤浜嬩欢銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 12寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| params | Record<string,[ParamType](#paramtype12)> | 鏄?| 浜嬩欢鑷畾涔夊弬鏁板璞°€傚弬鏁板悕鍜屽弬鏁板€艰鏍煎畾涔夊涓嬶細- 鍙傛暟鍚嶄负string绫诲瀷锛岄瀛楃蹇呴』涓哄瓧姣嶅瓧绗︽垨$瀛楃銆備腑闂村瓧绗﹀繀椤讳负鏁板瓧瀛楃銆佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︺€傜粨灏惧瓧绗﹀繀椤讳负鏁板瓧瀛楃鎴栧瓧姣嶅瓧绗︺€傞暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€? 鍙傛暟鍊间负[ParamType](#paramtype12)绫诲瀷锛屽弬鏁板€奸暱搴﹂渶鍦?024涓瓧绗︿互鍐呫€? 鍙傛暟涓暟闇€鍦?4涓互鍐呫€?|
| domain | string | 鏄?| 浜嬩欢棰嗗煙銆備簨浠堕鍩熷彲鏀寔鍏宠仈搴旂敤浜嬩欢鍜岀郴缁熶簨浠讹紙hiAppEvent.domain.OS锛夈€?|
| name | string | 鍚?| 浜嬩欢鍚嶇О銆傞粯璁や负绌哄瓧绗︿覆锛岀┖瀛楃涓茶〃绀哄叧鑱斾簨浠堕鍩熶笅鐨勬墍鏈変簨浠跺悕绉般€備簨浠跺悕绉板彲鏀寔鍏宠仈搴旂敤浜嬩欢鍜岀郴缁熶簨浠讹紝鍏朵腑绯荤粺浜嬩欢浠呮敮鎸佸叧鑱旓細-[宕╂簝浜嬩欢](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/宕╂簝浜嬩欢/宕╂簝浜嬩欢浠嬬粛/hiappevent-watcher-crash-events)锛坔iAppEvent.event.APP_CRASH锛?[搴旂敤鍐诲睆浜嬩欢](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/搴旂敤鍐诲睆浜嬩欢/搴旂敤鍐诲睆浜嬩欢浠嬬粛/hiappevent-watcher-freeze-events)锛坔iAppEvent.event.APP_FREEZE锛?[璧勬簮娉勬紡浜嬩欢](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/璧勬簮娉勬紡浜嬩欢/璧勬簮娉勬紡浜嬩欢浠嬬粛/hiappevent-watcher-resourceleak-events)锛坔iAppEvent.event.RESOURCE_OVERLIMIT锛夈€?*娉ㄦ剰**锛氫粠API version 20寮€濮嬶紝鏀寔[璧勬簮娉勬紡浜嬩欢](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/璧勬簮娉勬紡浜嬩欢/璧勬簮娉勬紡浜嬩欢浠嬬粛/hiappevent-watcher-resourceleak-events)銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<void> | Promise瀵硅薄锛屾棤杩斿洖缁撴灉銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11100001 | Function disabled. Possible caused by the param disable in ConfigOption is true. |
| 11101001 | Invalid event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101002 | Invalid event name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101004 | Invalid string length of the event parameter. |
| 11101005 | Invalid event parameter name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101007 | The number of parameter keys exceeds the limit. |
**绀轰緥锛?*
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
let params: Record<string, hiAppEvent.ParamType> = {
  "int_data": 100,
  "str_data": "strValue",
};
// 缁欏簲鐢ㄤ簨浠惰拷鍔犺嚜瀹氫箟鍙傛暟
hiAppEvent.setEventParam(params, "test_domain", "test_event").then(() => {
  hilog.info(0x0000, 'hiAppEvent', `success to set event param`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `code: ${err.code}, message: ${err.message}`);
});
```
#### hiAppEvent.setEventConfig15+
setEventConfig(name: string, config: Record<string, ParamType>): Promise<void>
浜嬩欢鐩稿叧鐨勯厤缃弬鏁拌缃柟娉曪紝浣跨敤Promise鏂瑰紡浣滀负寮傛鍥炶皟銆傚湪鍚屼竴鐢熷懡鍛ㄦ湡涓紝鍙互閫氳繃浜嬩欢鍚嶇О锛岃缃簨浠剁浉鍏崇殑閰嶇疆鍙傛暟銆?
涓嶅悓鐨勪簨浠舵湁涓嶅悓鐨勯厤缃」锛岀洰鍓嶄粎鏀寔浠ヤ笅浜嬩欢锛?
- MAIN_THREAD_JANK锛堝弬鏁伴厤缃瑙乕涓荤嚎绋嬭秴鏃朵簨浠舵娴媇(D:/code/APIDevice/output/md_output/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/涓荤嚎绋嬭秴鏃朵簨浠?涓荤嚎绋嬭秴鏃朵簨浠朵粙缁?hiappevent-watcher-mainthreadjank-events.md)锛?
- APP_CRASH锛堝弬鏁伴厤缃瑙乕宕╂簝鏃ュ織閰嶇疆鍙傛暟璁剧疆浠嬬粛](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/宕╂簝浜嬩欢/宕╂簝浜嬩欢浠嬬粛/hiappevent-watcher-crash-events)锛?
- RESOURCE_OVERLIMIT锛堝弬鏁伴厤缃瑙乕璧勬簮娉勬紡浜嬩欢妫€娴媇(D:/code/APIDevice/output/md_output/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/璧勬簮娉勬紡浜嬩欢/璧勬簮娉勬紡浜嬩欢浠嬬粛/hiappevent-watcher-resourceleak-events.md)锛?
**鍏冩湇鍔PI锛?* 浠嶢PI version 15寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| name | string | 鏄?| 浜嬩欢鍚嶇О銆?|
| config | Record<string,[ParamType](#paramtype12)> | 鏄?| 浜嬩欢鑷畾涔夊弬鏁板璞°€傚弬鏁板悕鍜屽弬鏁板€艰鏍煎畾涔夊涓嬶細- 鍙傛暟鍚嶄负string绫诲瀷锛岃姹傞潪绌猴紝涓斿弬鏁板悕闀垮害闇€鍦?024涓瓧绗︿互鍐呫€? 鍙傛暟鍊间负ParamType绫诲瀷锛屽弬鏁板€奸暱搴﹂渶鍦?024涓瓧绗︿互鍐呫€?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<void> | Promise瀵硅薄锛屾棤杩斿洖缁撴灉銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types; 3.Parameter verification failed. |
**绀轰緥锛?*
浠ヤ笅绀轰緥鐢ㄤ簬妯℃嫙閰嶇疆MAIN_THREAD_JANK浜嬩欢鐨勯噰闆嗗爢鏍堣嚜瀹氫箟鍙傛暟锛?
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
let params: Record<string, hiAppEvent.ParamType> = {
  "log_type": "1",
  "sample_interval": "100",
  "ignore_startup_time": "11",
  "sample_count": "21",
  "report_times_per_app": "3"
};
hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
  hilog.info(0x0000, 'hiAppEvent', `Successfully set sampling stack parameters.`);
}).catch((err: BusinessError) => {
hilog.error(0x0000, 'hiAppEvent', `Failed to set sample stack value. Code: ${err.code}, message: ${err.message}`);
});
```
#### hiAppEvent.configEventPolicy22+
configEventPolicy(policy: EventPolicy): Promise<void>
绯荤粺浜嬩欢鐩稿叧鐨勯厤缃瓥鐣ヨ缃柟娉曪紝浣跨敤Promise鏂瑰紡浣滀负寮傛鍥炶皟銆?
鍦ㄥ悓涓€鐢熷懡鍛ㄦ湡涓紝鍙互閫氳繃閰嶇疆绛栫暐璁剧疆绯荤粺浜嬩欢鐩稿叧鐨勭瓥鐣ュ弬鏁般€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 22寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| policy | [EventPolicy](#eventpolicy22) | 鏄?| 绯荤粺浜嬩欢閰嶇疆绛栫暐銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<void> | Promise瀵硅薄锛屾棤杩斿洖缁撴灉銆傚悇涓簨浠剁殑浜嬩欢閰嶇疆绛栫暐锛岃缁嗚鏍艰[EventPolicy](#eventpolicy22)绫诲瀷璇存槑銆傝嫢閰嶇疆绛栫暐璁剧疆鏈夎锛屼細瀵艰嚧鎺ュ彛杩斿洖澶辫触銆? 鍙傛暟绫诲瀷璁剧疆鏈夎锛屽垯杩斿洖401閫氱敤閿欒淇℃伅锛? 鍙傛暟瑙勬牸璁剧疆鏈夎锛屽垯鍦╤ilog鏃ュ織杈撳嚭鐩稿叧閿欒淇℃伅銆?|
**绀轰緥锛?*
浠ヤ笅绀轰緥鐢ㄤ簬妯℃嫙璁剧疆MAIN_THREAD_JANK浜嬩欢鐨勯厤缃瓥鐣ワ細
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
let policy: hiAppEvent.EventPolicy = {
  "mainThreadJankPolicy":{
    "logType": 1,
    "sampleInterval": 100,
    "ignoreStartupTime": 11,
    "sampleCount": 21,
    "reportTimesPerApp": 3,
    "autoStopSampling": true
  }
};
hiAppEvent.configEventPolicy(policy).then(() => {
  hilog.info(0x0000, 'hiAppEvent', `Successfully set main thread jank event policy.`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `Failed to set main thread jank event policy. Code: ${err?.code}, message: ${err?.message}`);
});
```
#### Watcher
鎻愪緵浜嬩欢瑙傚療鑰呯殑鍙傛暟閫夐」銆傜敤浜庨厤缃拰绠＄悊浜嬩欢鐨勮瀵熻€咃紝瀹炵幇瀵圭壒瀹氫簨浠剁殑鐩戝惉鍜屽鐞嗐€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| name | string | 鍚?| 鍚?| 瑙傚療鑰呭悕绉帮紝鐢ㄤ簬鍞竴鏍囪瘑瑙傚療鑰呫€傞瀛楃蹇呴』涓哄瓧姣嶅瓧绗︼紝涓棿瀛楃蹇呴』涓烘暟瀛楀瓧绗︺€佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︼紝缁撳熬瀛楃蹇呴』涓烘暟瀛楀瓧绗︽垨瀛楁瘝瀛楃锛岄暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€傚testName1銆乧rash_Watcher绛夈€?|
| triggerCondition | [TriggerCondition](#triggercondition) | 鍚?| 鏄?| 璁㈤槄鍥炶皟瑙﹀彂鏉′欢锛岄渶瑕佷笌鍥炶皟鍑芥暟onTrigger涓€鍚屼紶鍏ユ墠浼氱敓鏁堛€傞粯璁や笉瑙﹀彂銆?|
| appEventFilters | [AppEventFilter](#appeventfilter)[] | 鍚?| 鏄?| 璁㈤槄杩囨护鏉′欢锛屽湪闇€瑕佸璁㈤槄浜嬩欢杩涜杩囨护鏃朵紶鍏ャ€傞粯璁や笉杩囨护浜嬩欢銆?|
| onTrigger | (curRow: number, curSize: number, holder:[AppEventPackageHolder](#appeventpackageholder)) => void | 鍚?| 鏄?| 璁㈤槄鍥炶皟鍑芥暟锛岄渶瑕佷笌鍥炶皟瑙﹀彂鏉′欢triggerCondition涓€鍚屼紶鍏ユ墠浼氱敓鏁堬紝鍑芥暟鍏ュ弬璇存槑濡備笅锛歝urRow锛氬湪鏈鍥炶皟瑙﹀彂鏃剁殑璁㈤槄浜嬩欢鎬绘暟閲忥紱curSize锛氬湪鏈鍥炶皟瑙﹀彂鏃剁殑璁㈤槄浜嬩欢鎬诲ぇ灏忥紝鍗曚綅涓篵yte锛沨older锛氳闃呮暟鎹寔鏈夎€呭璞★紝鍙互閫氳繃鍏跺璁㈤槄浜嬩欢杩涜澶勭悊銆?|
| onReceive11+ | (domain: string, appEventGroups: Array<[AppEventGroup](#appeventgroup11)>) => void | 鍚?| 鏄?| 璁㈤槄瀹炴椂鍥炶皟鍑芥暟锛屼笌鍥炶皟鍑芥暟onTrigger鍚屾椂瀛樺湪鏃讹紝鍙Е鍙戞鍥炶皟锛屽嚱鏁板叆鍙傝鏄庡涓嬶細domain锛氬洖璋冧簨浠剁殑棰嗗煙鍚嶇О锛沘ppEventGroups锛氬洖璋冧簨浠堕泦鍚堛€?|
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/4e/v3/kqvSeGYdTMaw-VebN_BaNg/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=530130DA503BBF30FFCD1FC336A58C88893FF0DB608DC6D8697BB4E49A6328F2)
涓嶅缓璁湪鍥炶皟鍑芥暟涓墽琛?[绉婚櫎瑙傚療鑰匽(#hiappeventremovewatcher) 鐨勬搷浣滐紝watcher涓€鏃﹁绉婚櫎锛屽垯鍏跺師鏈夌殑璁㈤槄鍥炶皟鍔熻兘涔熶細闅忎箣澶辨晥锛屽彲鑳戒細閫犳垚鏌愪簺浜嬩欢鍙戠敓鍚庢棤璁㈤槄鍥炶皟鎯呭喌銆?
#### TriggerCondition
鎻愪緵璁剧疆 [Watcher](#watcher) 鐨刼nTrigger鍥炶皟瑙﹀彂鏉′欢鐨勫弬鏁伴€夐」銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| row | number | 鍚?| 鏄?| 婊¤冻瑙﹀彂鍥炶皟鐨勪簨浠舵€绘暟閲忥紝姝ｆ暣鏁般€傞粯璁ゅ€?锛屼笉瑙﹀彂鍥炶皟銆備紶鍏ヨ礋鍊兼椂锛屼細琚疆涓洪粯璁ゅ€笺€?|
| size | number | 鍚?| 鏄?| 婊¤冻瑙﹀彂鍥炶皟鐨勪簨浠舵€诲ぇ灏忥紝姝ｆ暣鏁帮紝鍗曚綅涓篵yte銆傞粯璁ゅ€?锛屼笉瑙﹀彂鍥炶皟銆備紶鍏ヨ礋鍊兼椂锛屼細琚疆涓洪粯璁ゅ€笺€?|
| timeOut | number | 鍚?| 鏄?| 婊¤冻瑙﹀彂鍥炶皟鐨勮秴鏃舵椂闀匡紝姝ｆ暣鏁帮紝鍗曚綅涓?0s銆傞粯璁ゅ€?锛屼笉瑙﹀彂鍥炶皟銆備紶鍏ヨ礋鍊兼椂锛屼細琚疆涓洪粯璁ゅ€笺€?|
#### AppEventFilter
鎻愪緵璁剧疆 [Watcher](#watcher) 鐨勮闃呰繃婊ゆ潯浠剁殑鍙傛暟閫夐」銆傜敤浜庡湪浜嬩欢瑙傚療鑰呬腑璁剧疆浜嬩欢杩囨护鏉′欢锛岀‘淇濆彧鏈夋弧瓒宠繃婊ゆ潯浠剁殑浜嬩欢鎵嶄細琚洃鍚鐞嗐€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| domain | string | 鍚?| 鍚?| 闇€瑕佽闃呯殑浜嬩欢棰嗗煙銆傚彲浠ユ槸绯荤粺浜嬩欢棰嗗煙锛坔iAppEvent.domain.OS锛夋垨寮€鍙戣€呭湪浣跨敤[Write](#hiappeventwrite-1)鎺ュ彛鏃朵紶鍏ョ殑鑷畾涔変簨浠朵俊鎭紙[AppEventInfo](#appeventinfo)锛変腑鐨勪簨浠堕鍩熴€?|
| eventTypes | [EventType](#eventtype)[] | 鍚?| 鏄?| 闇€瑕佽闃呯殑浜嬩欢绫诲瀷闆嗗悎銆傞粯璁や笉杩涜杩囨护銆?|
| names11+ | string[] | 鍚?| 鏄?| 闇€瑕佽闃呯殑浜嬩欢鍚嶇О闆嗗悎銆傞粯璁や笉杩涜杩囨护銆?|
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/12/v3/olEde9dMRDSyhKbJ6o5OnQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=3C910B4BB6F49CFFDCAA9E05722473507C2B6078D54B180B389C0AAE83AFF09A)
涓嶅悓绫诲瀷搴旂敤涓婏紝绯荤粺浜嬩欢鐨勮闃呰鏍间笉鍚岋紝鍏蜂綋瑙勬牸鍙弬瑙?[HiAppEvent绾︽潫涓庨檺鍒禲(D:/code/APIDevice/output/md_output/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/HiAppEvent浠嬬粛/hiappevent-intro.md) 銆?
#### AppEventPackageHolder
璁㈤槄鏁版嵁鎸佹湁鑰呯被锛岀敤浜庡浜嬩欢淇℃伅杩涜澶勭悊銆?
#### constructor
constructor(watcherName: string)
绫绘瀯閫犲嚱鏁帮紝鐢ㄤ簬鍒涘缓璁㈤槄鏁版嵁鎸佹湁鑰呭疄渚嬨€傚厛閫氳繃 [addWatcher](#hiappeventaddwatcher) 娣诲姞浜嬩欢瑙傚療鑰咃紝鍐嶉€氳繃瑙傚療鑰呭悕绉板叧鑱斿埌搴旂敤鍐呭凡娣诲姞鐨勮瀵熻€呭璞°€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| watcherName | string | 鏄?| 宸查€氳繃[addWatcher](#hiappeventaddwatcher)娣诲姞鐨勪簨浠惰瀵熻€呭悕绉般€傝嫢鏈€氳繃addWatcher娣诲姞锛屽垯榛樿鏃犳暟鎹€?|
**绀轰緥锛?*
```
// 娣诲姞鏁版嵁瑙傚療鑰呪€淲atcher1鈥濓紝璁㈤槄鐩戝惉绯荤粺浜嬩欢
hiAppEvent.addWatcher({
  name: "Watcher1",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
    }
  ],
  });
// 鍒涘缓璁㈤槄鏁版嵁鎸佹湁鑰呭疄渚嬶紝holder1鎸佹湁鐨勬暟鎹负涓婅堪addWatcher涓坊鍔犵殑瑙傚療鑰呪€淲atcher1鈥濈洃鍚埌鐨勪簨浠?
let holder1: hiAppEvent.AppEventPackageHolder = new hiAppEvent.AppEventPackageHolder("Watcher1");
```
#### setSize
setSize(size: number): void
璁剧疆姣忔鍙栧嚭鐨勪簨浠跺寘鐨勬暟鎹ぇ灏忛槇鍊笺€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| size | number | 鏄?| 鏁版嵁澶у皬闃堝€硷紝鍗曚綅涓篵yte銆傚彇鍊艰寖鍥碵0, 2^31-1]锛岃秴鍑鸿寖鍥翠細鎶涘紓甯搞€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11104001 | Invalid size value. Possible caused by the size value is less than or equal to zero. |
**绀轰緥锛?*
```
// 鍒涘缓璁㈤槄鏁版嵁鎸佹湁鑰呭疄渚嬶紝holder2鎸佹湁鐨勬暟鎹负宸查€氳繃addWatcher娣诲姞鐨勮瀵熻€呪€淲atcher1鈥濈洃鍚埌鐨勪簨浠?
let holder2: hiAppEvent.AppEventPackageHolder = new hiAppEvent.AppEventPackageHolder("Watcher1");
// 璁剧疆姣忔鍙栧嚭浜嬩欢鍖呯殑鏁版嵁澶у皬闃堝€间负1000byte
holder2.setSize(1000);
```
#### setRow12+
setRow(size: number): void
璁剧疆姣忔鍙栧嚭鐨勪簨浠跺寘鐨勬暟鎹潯鏁帮紝浼樺厛绾ч珮浜巗etSize锛屽拰setSize鍚屾椂璋冪敤鏃朵粎setRow鐢熸晥銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 12寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| size | number | 鏄?| 浜嬩欢鏉℃暟锛屽崟浣嶄负鏉°€傚彇鍊艰寖鍥?0, 2^31-1]锛岃秴鍑鸿寖鍥翠細鎶涘紓甯搞€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11104001 | Invalid size value. Possible caused by the size value is less than or equal to zero. |
**绀轰緥锛?*
```
// 鍒涘缓璁㈤槄鏁版嵁鎸佹湁鑰呭疄渚嬶紝holder3鎸佹湁鐨勬暟鎹负宸查€氳繃addWatcher娣诲姞鐨勮瀵熻€呪€淲atcher1鈥濈洃鍚埌鐨勪簨浠?
let holder3: hiAppEvent.AppEventPackageHolder = new hiAppEvent.AppEventPackageHolder("Watcher1");
// 璁剧疆姣忔鍙栧嚭鐨勪簨浠跺寘鐨勬暟鎹潯鏁颁负1000鏉?
holder3.setRow(1000);
```
#### takeNext
takeNext(): AppEventPackage
鑾峰彇璁㈤槄浜嬩欢銆?
绯荤粺鏍规嵁setSize璁剧疆鐨勬暟鎹ぇ灏忛槇鍊兼垨setRow璁剧疆鐨勬潯鏁版潵鍙栧嚭璁㈤槄浜嬩欢鏁版嵁锛岄粯璁ゅ彇1鏉¤闃呬簨浠躲€傚綋璁㈤槄浜嬩欢鏁版嵁鍏ㄩ儴琚彇鍑烘椂杩斿洖null銆?
褰搒etRow鍜宻etSize鍚屾椂璋冪敤鏃朵粎setRow鐢熸晥銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| [AppEventPackage](#appeventpackage) | 鍙栧嚭鐨勪簨浠跺寘瀵硅薄锛岃闃呬簨浠舵暟鎹鍏ㄩ儴鍙栧嚭鍚庝細杩斿洖null銆?|
**绀轰緥锛?*
```
// 鍒涘缓璁㈤槄鏁版嵁鎸佹湁鑰呭疄渚嬶紝holder4鎸佹湁鐨勬暟鎹负宸查€氳繃addWatcher娣诲姞鐨勮瀵熻€呪€淲atcher1鈥濈洃鍚埌鐨勪簨浠?
let holder4: hiAppEvent.AppEventPackageHolder = new hiAppEvent.AppEventPackageHolder("Watcher1");
// 鑾峰彇璁㈤槄浜嬩欢
let eventPkg: hiAppEvent.AppEventPackage | null = holder4.takeNext();
```
#### AppEventInfo
鎻愪緵浜嬩欢淇℃伅鐨勫弬鏁伴€夐」銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| domain | string | 鍚?| 鍚?| 浜嬩欢棰嗗煙銆備簨浠堕鍩熷悕绉版敮鎸佹暟瀛椼€佸瓧姣嶃€佷笅鍒掔嚎瀛楃锛岄渶瑕佷互瀛楁瘝寮€澶翠笖涓嶈兘浠ヤ笅鍒掔嚎缁撳熬锛岄暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€?|
| name | string | 鍚?| 鍚?| 浜嬩欢鍚嶇О銆傞瀛楃蹇呴』涓哄瓧姣嶅瓧绗︽垨$瀛楃锛屼腑闂村瓧绗﹀繀椤讳负鏁板瓧瀛楃銆佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︼紝缁撳熬瀛楃蹇呴』涓烘暟瀛楀瓧绗︽垨瀛楁瘝瀛楃锛岄暱搴﹂潪绌轰笖涓嶈秴杩?8涓瓧绗︺€?|
| eventType | [EventType](#eventtype) | 鍚?| 鍚?| 浜嬩欢绫诲瀷銆?|
| params | object | 鍚?| 鍚?| 浜嬩欢鍙傛暟瀵硅薄锛屽寘鍚瘡涓簨浠跺弬鏁扮殑鍙傛暟鍚嶅拰鍙傛暟鍊笺€?*绯荤粺浜嬩欢涓璸arams鍖呭惈鐨勫瓧娈靛凡鐢卞悇绯荤粺浜嬩欢瀹氫箟锛屽叿浣撳瓧娈靛惈涔夊湪鍚勭被绯荤粺浜嬩欢鎸囧崡鐨勪粙缁嶄腑锛屼緥濡俒宕╂簝浜嬩欢浠嬬粛](D:/code/APIDevice/output/md_output/harmonyos-guides/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?浜嬩欢璁㈤槄/浣跨敤HiAppEvent璁㈤槄浜嬩欢/绯荤粺浜嬩欢/宕╂簝浜嬩欢/宕╂簝浜嬩欢浠嬬粛/hiappevent-watcher-crash-events.md)銆?*閽堝搴旂敤浜嬩欢锛孾Write](#hiappeventwrite-1)鎵撶偣鍐欏叆鐨勫弬鏁扮敱寮€鍙戣€呭畾涔夛紝鍏惰鏍煎涓嬶細- 鍙傛暟鍚嶄负string绫诲瀷锛岄瀛楃蹇呴』涓哄瓧姣嶅瓧绗︽垨$瀛楃锛屼腑闂村瓧绗﹀繀椤讳负鏁板瓧瀛楃銆佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︼紝缁撳熬瀛楃蹇呴』涓烘暟瀛楀瓧绗︽垨瀛楁瘝瀛楃锛岄暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€傚testName銆?123_name绛夈€? 鍙傛暟鍊兼敮鎸乻tring銆乶umber銆乥oolean銆佹暟缁勭被鍨嬨€俿tring绫诲瀷鍙傛暟闀垮害闇€鍦?*1024涓瓧绗︿互鍐咃紝瓒呭嚭鍚庝細鍜屽搴旂殑鍙傛暟鍚嶄竴鍚岃涓㈠純锛沶umber绫诲瀷鍙傛暟鍙栧€奸渶鍦∟umber.MIN_SAFE_INTEGER~Number.MAX_SAFE_INTEGER鑼冨洿鍐咃紝瓒呭嚭鍙兘浼氫骇鐢熶笉纭畾鍊硷紱鏁扮粍绫诲瀷鍙傛暟涓殑鍏冪礌绫诲瀷鍙兘鍏ㄤ负string銆乶umber銆乥oolean涓殑涓€绉嶏紝涓斿厓绱犱釜鏁伴渶鍦?00浠ュ唴锛岃秴鍑洪儴鍒嗗嵆浠庣101涓厓绱犲紑濮嬩細琚涪寮冦€? 鍙傛暟涓暟闇€鍦?2涓互鍐咃紝瓒呭嚭鐨勫弬鏁颁細鍋氫涪寮冨鐞嗐€?|
#### AppEventPackage
鎻愪緵璁㈤槄杩斿洖鐨勪簨浠跺寘鐨勫弬鏁板畾涔夈€傚彲鐢ㄤ簬鑾峰彇浜嬩欢鍖呯殑璇︾粏淇℃伅锛屼簨浠跺寘鐢?[takeNext](#takenext) 鎺ュ彛鑾峰緱銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| packageId | number | 鍚?| 鍚?| 浜嬩欢鍖匢D锛屼粠0寮€濮嬭嚜鍔ㄩ€掑銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| row | number | 鍚?| 鍚?| 浜嬩欢鍖呯殑浜嬩欢鏁伴噺銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| size | number | 鍚?| 鍚?| 浜嬩欢鍖呯殑浜嬩欢澶у皬锛屽崟浣嶄负byte銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| data | string[] | 鍚?| 鍚?| 浜嬩欢鍖呯殑浜嬩欢淇℃伅銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| appEventInfos12+ | Array<[AppEventInfo](#appeventinfo)> | 鍚?| 鍚?| 浜嬩欢瀵硅薄闆嗗悎銆?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
#### AppEventGroup11+
鎻愪緵璁㈤槄杩斿洖鐨勪簨浠剁粍鐨勫弬鏁板畾涔夈€傚彲鐢ㄤ簬鑾峰彇浜嬩欢缁勭殑璇︾粏淇℃伅锛屼簨浠剁粍甯稿湪 [Watcher](#watcher) 鐨刼nReceive鍥炶皟涓娇鐢ㄣ€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| name | string | 鍚?| 鍚?| 浜嬩欢鍚嶇О銆?|
| appEventInfos | Array<[AppEventInfo](#appeventinfo)> | 鍚?| 鍚?| 浜嬩欢瀵硅薄闆嗗悎銆?|
#### hiAppEvent.write
write(info: AppEventInfo, callback: AsyncCallback<void>): void
搴旂敤浜嬩欢鎵撶偣鏂规硶锛屽皢AppEventInfo绫诲瀷鐨勪簨浠惰繘琛屽瓨鍌紝浣跨敤callback鏂瑰紡浣滀负寮傛鍥炶皟銆傞€氳繃姝ゆ帴鍙ｅ啓鍏ョ殑浜嬩欢瀵硅薄鏄紑鍙戣€呰嚜瀹氫箟鐨勫璞★紝涓轰簡閬垮厤涓庣郴缁熶簨浠朵骇鐢熷啿绐佹贩娣嗭紝涓嶅缓璁啓鍏ョ郴缁熶簨浠讹紙 [Event](#hiappeventevent) 涓畾涔夌殑绯荤粺浜嬩欢鍚嶇О甯搁噺锛夈€傛鎺ュ彛鍐欏叆鐨勪簨浠跺彲閫氳繃璁㈤槄浜嬩欢瑙傚療鑰咃紙 [addWatcher](#hiappeventaddwatcher) 锛夎繘琛岃闃呫€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| info | [AppEventInfo](#appeventinfo) | 鏄?| 搴旂敤浜嬩欢瀵硅薄銆傚叾鍐呴儴瀹氫箟鐨勪簨浠跺悕绉板缓璁伩鍏嶄笌[Event](#hiappeventevent)涓畾涔夌殑绯荤粺浜嬩欢鍚嶇О甯搁噺浜х敓鍐茬獊銆?|
| callback | AsyncCallback<void> | 鏄?| 鎵撶偣鍥炶皟鍑芥暟銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11100001 | Function disabled. Possible caused by the param disable in ConfigOption is true. |
| 11101001 | Invalid event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101002 | Invalid event name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101003 | Invalid number of event parameters. Possible caused by the number of parameters is over 32. |
| 11101004 | Invalid string length of the event parameter. |
| 11101005 | Invalid event parameter name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101006 | Invalid array length of the event parameter. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/60/v3/fCN-mfJGTb68afsPq0Y8Yw/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=5EBDE469F652C394EF593964CA9EA56E67B2E8FC97B1760A7544779CB262778F)
write鎺ュ彛娑夊強I/O鎿嶄綔锛屾墽琛屾椂闂撮€氬父鍦ㄦ绉掔骇鍒€傚洜姝わ紝寮€鍙戣€呭簲鏍规嵁瀹為檯涓氬姟闇€姹傦紝纭畾璇ユ帴鍙ｆ槸鍦ㄤ富绾跨▼杩樻槸鍦ㄥ瓙绾跨▼涓皟鐢ㄣ€?
鍙弬鑰?[澶氱嚎绋嬪苟鍙戞杩癩(D:/code/APIDevice/output/md_output/harmonyos-guides/搴旂敤妗嗘灦/ArkTS锛堟柟鑸熺紪绋嬭瑷€锛?ArkTS骞跺彂/澶氱嚎绋嬪苟鍙?澶氱嚎绋嬪苟鍙戞杩?multi-thread-concurrency-overview.md) 锛屼互瀹炵幇鍦ㄥ瓙绾跨▼涓皟鐢ㄦ帴鍙ｃ€?
**绀轰緥锛?*
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
let eventParams: Record<string, number | string> = {
  "int_data": 100,
  "str_data": "strValue",
};
// 搴旂敤浜嬩欢鎵撶偣锛屼娇鐢╟allback鏂瑰紡浣滀负寮傛鍥炶皟
hiAppEvent.write({
  domain: "test_domain",
  name: "test_event",
  eventType: hiAppEvent.EventType.FAULT,
  params: eventParams,
}, (err: BusinessError) => {
  if (err) {
    hilog.error(0x0000, 'hiAppEvent', `code: ${err.code}, message: ${err.message}`);
    return;
  }
  hilog.info(0x0000, 'hiAppEvent', `success to write event`);
});
```
#### hiAppEvent.write
write(info: AppEventInfo): Promise<void>
搴旂敤浜嬩欢鎵撶偣鏂规硶锛屽皢AppEventInfo绫诲瀷鐨勪簨浠惰繘琛屽瓨鍌紝浣跨敤Promise鏂瑰紡浣滀负寮傛鍥炶皟銆傞€氳繃姝ゆ帴鍙ｅ啓鍏ョ殑浜嬩欢瀵硅薄鏄紑鍙戣€呰嚜瀹氫箟鐨勫璞★紝涓轰簡閬垮厤涓庣郴缁熶簨浠朵骇鐢熷啿绐佹贩娣嗭紝涓嶅缓璁啓鍏ョ郴缁熶簨浠讹紙 [Event](#hiappeventevent) 涓畾涔夌殑绯荤粺浜嬩欢鍚嶇О甯搁噺锛夈€傛鎺ュ彛鍐欏叆鐨勪簨浠跺彲閫氳繃璁㈤槄浜嬩欢瑙傚療鑰咃紙 [addWatcher](#hiappeventaddwatcher) 锛夎繘琛屽鐞嗐€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| info | [AppEventInfo](#appeventinfo) | 鏄?| 搴旂敤浜嬩欢瀵硅薄銆傚叾涓殑浜嬩欢鍚嶇О寤鸿閬垮厤涓嶽Event](#hiappeventevent)涓畾涔夌殑绯荤粺浜嬩欢鍚嶇О甯搁噺鍐茬獊娣锋穯銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<void> | Promise瀵硅薄锛屾棤杩斿洖缁撴灉銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11100001 | Function disabled. Possible caused by the param disable in ConfigOption is true. |
| 11101001 | Invalid event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101002 | Invalid event name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101003 | Invalid number of event parameters. Possible caused by the number of parameters is over 32. |
| 11101004 | Invalid string length of the event parameter. |
| 11101005 | Invalid event parameter name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11101006 | Invalid array length of the event parameter. |
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/c4/v3/HZw0dVauT6O5letLjlYd4A/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=BED29125EB810F6FD88EE93BE985A15707C1BC792C1633EE2B363F165FA78F81)
write鎺ュ彛娑夊強I/O鎿嶄綔锛屾墽琛屾椂闂撮€氬父鍦ㄦ绉掔骇鍒€傚洜姝わ紝寮€鍙戣€呭簲鏍规嵁瀹為檯涓氬姟闇€姹傦紝纭畾璇ユ帴鍙ｆ槸鍦ㄤ富绾跨▼杩樻槸鍦ㄥ瓙绾跨▼涓皟鐢ㄣ€?
鍙弬鑰?[澶氱嚎绋嬪苟鍙戞杩癩(D:/code/APIDevice/output/md_output/harmonyos-guides/搴旂敤妗嗘灦/ArkTS锛堟柟鑸熺紪绋嬭瑷€锛?ArkTS骞跺彂/澶氱嚎绋嬪苟鍙?澶氱嚎绋嬪苟鍙戞杩?multi-thread-concurrency-overview.md) 锛屼互瀹炵幇鍦ㄥ瓙绾跨▼涓皟鐢ㄦ帴鍙ｃ€?
**绀轰緥锛?*
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
let eventParams: Record<string, number | string> = {
  "int_data": 100,
  "str_data": "strValue",
};
// 搴旂敤浜嬩欢鎵撶偣锛屼娇鐢≒romise鏂瑰紡浣滀负寮傛鍥炶皟
hiAppEvent.write({
  domain: "test_domain",
  name: "test_event",
  eventType: hiAppEvent.EventType.FAULT,
  params: eventParams,
}).then(() => {
  hilog.info(0x0000, 'hiAppEvent', `success to write event`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `code: ${err.code}, message: ${err.message}`);
});
```
#### hiAppEvent.addProcessor11+
addProcessor(processor: Processor): number
娣诲姞鏁版嵁澶勭悊鑰呴厤缃俊鎭紝鐢ㄤ簬閰嶇疆澶勭悊鑰呮帴鏀剁殑浜嬩欢鍚嶇瓑淇℃伅銆備簨浠跺彂鐢熷悗澶勭悊鑰呭彲浠ユ帴鏀朵簨浠躲€?
璇ユ帴鍙ｄ负鍚屾鎺ュ彛锛屽寘鍚€楁椂鎿嶄綔銆備负浜嗙‘淇濇€ц兘锛屽缓璁娇鐢?[addProcessorFromConfig](#hiappeventaddprocessorfromconfig20) 寮傛鎺ュ彛鎴栬€呬氦鐢卞瓙绾跨▼鎵ц銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| processor | [Processor](#processor11) | 鏄?| 涓婃姤浜嬩欢鐨勬暟鎹鐞嗚€呫€?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| number | 鎵€娣诲姞涓婃姤浜嬩欢鏁版嵁澶勭悊鑰呯殑ID锛屾爣璇嗗敮涓€鏁版嵁澶勭悊鑰咃紝鍙敤浜庣Щ闄ゆ暟鎹鐞嗚€呫€?娣诲姞澶辫触杩斿洖-1锛屾坊鍔犳垚鍔熻繑鍥炲ぇ浜?鐨勫€笺€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
    let processor: hiAppEvent.Processor = {
      name: 'analytics_demo'
    };
    let id: number = hiAppEvent.addProcessor(processor);
    hilog.info(0x0000, 'hiAppEvent', `addProcessor event was successful, id=${id}`);
} catch (error) {
    hilog.error(0x0000, 'hiAppEvent', `failed to addProcessor event, code=${error.code}`);
}
```
#### hiAppEvent.addProcessorFromConfig20+
addProcessorFromConfig(processorName: string, configName?: string): Promise<number>
娣诲姞鏁版嵁澶勭悊鑰呴厤缃俊鎭€傜郴缁熶細鑷姩瑙ｆ瀽棰勭疆鍦ㄧ洰褰曗€?system/etc/hiappevent鈥濈殑processor.json閰嶇疆鏂囦欢锛屽苟鏍规嵁configName瀛楁鍔犺浇瀵瑰簲鐨刾rocessor淇℃伅锛堜緥濡傛敮鎸佹帴鏀剁殑鏁呴殰浜嬩欢鍚嶇О绛変俊鎭級銆?
閰嶇疆瀹屾垚鍚庯紝浜嬩欢鍙戠敓鏃剁郴缁熷皢鑷姩瑙﹀彂璇ュ洖璋冦€備娇鐢≒romise寮傛鍥炶皟銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 20寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| processorName | string | 鏄?| 鏁版嵁澶勭悊鑰呯殑鍚嶇О銆傚悕绉板彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€傚綋鍓嶅彇鍊间粎鏀寔鈥渉a_app_event鈥濓紝琛ㄧず鎺ュ彛鏁呴殰澶勭悊鑰呫€?|
| configName | string | 鍚?| 鏁版嵁澶勭悊鑰呯殑閰嶇疆鍚嶇О锛岀郴缁熶細鏍规嵁閰嶇疆鍚嶇О浠庣郴缁熼缃殑processor.json閰嶇疆鏂囦欢涓嚜鍔ㄥ姞杞藉搴旂殑閰嶇疆椤广€傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€傚綋鍓嶅彇鍊间粎鏀寔榛樿鍊尖€淪DK_OCG鈥濓紝鐢ㄤ簬閰嶇疆鈥滄帴鍙ｆ晠闅滃鐞嗚€呪€濆彲澶勭悊鐨勪簨浠跺悕绉扮瓑淇℃伅銆?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| Promise<number> | Promise瀵硅薄銆傝繑鍥炴坊鍔犵殑浜嬩欢鏁版嵁澶勭悊鑰呯殑鍞竴ID锛屽彲鐢ㄤ簬绉婚櫎璇ユ暟鎹鐞嗚€呫€?娣诲姞澶辫触杩斿洖11105001閿欒鐮併€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 11105001 | Invalid parameter value. Possible causes: 1. Incorrect parameter length; 2. Incorrect parameter format. |
**绀轰緥锛?*
```
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.addProcessorFromConfig("test_name").then((processorId) => {
  hilog.info(0x0000, 'hiAppEvent', `Succeeded in adding processor from config, processorId=${processorId}`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `Failed to add processor from config, code: ${err.code}, message: ${err.message}`);
});
```
#### hiAppEvent.removeProcessor11+
removeProcessor(id: number): void
绉婚櫎涓婃姤浜嬩欢鐨勬暟鎹鐞嗚€呫€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| id | number | 鏄?| 涓婃姤浜嬩欢鏁版嵁澶勭悊鑰匢D銆傚€煎ぇ浜?銆傜敱璋冪敤[addProcessor](#hiappeventaddprocessor11)鎴朳addProcessorFromConfig](#hiappeventaddprocessorfromconfig20)鎺ュ彛杩斿洖鍊兼墍寰椼€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
    let processor: hiAppEvent.Processor = {
      name: 'analytics_demo'
    };
    let id: number = hiAppEvent.addProcessor(processor);
    // 鏍规嵁娣诲姞鏁版嵁澶勭悊鑰呰繑鍥炵殑鏍囪瘑id绉婚櫎鐗瑰畾鏁版嵁澶勭悊鑰?
    hiAppEvent.removeProcessor(id);
} catch (error) {
    hilog.error(0x0000, 'hiAppEvent', `failed to removeProcessor event, code=${error.code}`);
}
```
#### hiAppEvent.setUserId11+
setUserId(name: string, value: string): void
璁剧疆鐢ㄦ埛ID鍊笺€傜敤浜庡湪閰嶇疆 [Processor](#processor11) 鏁版嵁澶勭悊鑰呮椂杩涜鍏宠仈銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| name | string | 鏄?| 鐢ㄦ埛ID鐨刱ey銆傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?$锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€?|
| value | string | 鏄?| 鐢ㄦ埛ID鐨勫€笺€傞暱搴︿笉瓒呰繃256锛屽綋鍊间负null鎴栫┖瀛楃涓叉椂锛屽垯娓呴櫎鐢ㄦ埛ID銆?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  hiAppEvent.setUserId('key', 'value');
} catch (error) {
  hilog.error(0x0000, 'hiAppEvent', `failed to setUserId event, code=${error.code}`);
}
```
#### hiAppEvent.getUserId11+
getUserId(name: string): string
鑾峰彇閫氳繃setUserId鎺ュ彛璁剧疆鐨剉alue鍊笺€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| name | string | 鏄?| 鐢ㄦ埛ID鐨刱ey銆傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?$锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| string | 鐢ㄦ埛ID鐨勫€笺€傛病鏈夋煡鍒拌繑鍥炵┖瀛楃涓层€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.setUserId('key', 'value');
try {
  let value: string = hiAppEvent.getUserId('key');
  hilog.info(0x0000, 'hiAppEvent', `getUserId event was successful, userId=${value}`);
} catch (error) {
  hilog.error(0x0000, 'hiAppEvent', `failed to getUserId event, code=${error.code}`);
}
```
#### hiAppEvent.setUserProperty11+
setUserProperty(name: string, value: string): void
璁剧疆鐢ㄦ埛灞炴€у€笺€傜敤浜庡湪閰嶇疆 [Processor](#processor11) 鏁版嵁澶勭悊鑰呮椂杩涜鍏宠仈銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| name | string | 鏄?| 鐢ㄦ埛灞炴€х殑key銆傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?$锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€?|
| value | string | 鏄?| 鐢ㄦ埛灞炴€х殑鍊笺€傞暱搴︿笉瓒呰繃1024锛屽綋鍊间负null鎴栫┖瀛楃涓叉椂锛屽垯娓呴櫎鐢ㄦ埛灞炴€с€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
try {
  hiAppEvent.setUserProperty('key', 'value');
} catch (error) {
  hilog.error(0x0000, 'hiAppEvent', `failed to setUserProperty event, code=${error.code}`);
}
```
#### hiAppEvent.getUserProperty11+
getUserProperty(name: string): string
鑾峰彇閫氳繃setUserProperty鎺ュ彛璁剧疆鐨剉alue鍊笺€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| name | string | 鏄?| 鐢ㄦ埛灞炴€х殑key銆傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?$锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€?|
**杩斿洖鍊硷細**
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| string | 鐢ㄦ埛灞炴€х殑鍊笺€傛病鏈夋煡鍒拌繑鍥炵┖瀛楃涓层€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
**绀轰緥锛?*
```
import { hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.setUserProperty('key', 'value');
try {
  let value: string = hiAppEvent.getUserProperty('key');
  hilog.info(0x0000, 'hiAppEvent', `getUserProperty event was successful, userProperty=${value}`);
} catch (error) {
  hilog.error(0x0000, 'hiAppEvent', `failed to getUserProperty event, code=${error.code}`);
}
```
#### hiAppEvent.clearData
clearData(): void
搴旂敤浜嬩欢鎵撶偣鏁版嵁娓呯悊鏂规硶锛屽皢褰撳墠搴旂敤瀛樺偍鍦ㄦ湰鍦扮殑鎵撶偣鏁版嵁杩涜娓呴櫎銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**绀轰緥锛?*
```
hiAppEvent.clearData();
```
#### hiAppEvent.configure
configure(config: ConfigOption): void
搴旂敤浜嬩欢鎵撶偣閰嶇疆鏂规硶锛屾敮鎸侀厤缃墦鐐瑰紑鍏冲拰鐩綍瀛樺偍閰嶉澶у皬銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
**鍙傛暟锛?*
| 鍙傛暟鍚?| 绫诲瀷 | 蹇呭～ | 璇存槑 |
| --- | --- | --- | --- |
| config | [ConfigOption](#configoption) | 鏄?| 搴旂敤浜嬩欢鎵撶偣閰嶇疆椤瑰璞°€?|
**閿欒鐮侊細**
浠ヤ笅閿欒鐮佺殑璇︾粏浠嬬粛璇峰弬瑙?[閫氱敤閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/API鍙傝€冩杩?errorcode-universal.md) 鍜?[搴旂敤浜嬩欢鎵撶偣閿欒鐮乚(D:/code/APIDevice/output/md_output/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?閿欒鐮?errorcode-hiappevent.md) 銆?
| 閿欒鐮両D | 閿欒淇℃伅 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11103001 | Invalid max storage quota value. Possible caused by incorrectly formatted. |
**绀轰緥锛?*
```
// 閰嶇疆鎵撶偣寮€鍏充负鍏抽棴鐘舵€?
let config1: hiAppEvent.ConfigOption = {
  disable: true,
};
hiAppEvent.configure(config1);
// 閰嶇疆鏂囦欢鐩綍瀛樺偍閰嶉涓?00M
let config2: hiAppEvent.ConfigOption = {
  maxStorage: '100M',
};
hiAppEvent.configure(config2);
```
#### ConfigOption
鎻愪緵瀵瑰簲鐢ㄤ簨浠舵墦鐐瑰姛鑳界殑閰嶇疆閫夐」銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| disable | boolean | 鍚?| 鏄?| 鎵撶偣鍔熻兘寮€鍏筹紝榛樿鍊间负false銆倀rue锛氬叧闂墦鐐瑰姛鑳斤紝false锛氬紑鍚墦鐐瑰姛鑳姐€?|
| maxStorage | string | 鍚?| 鏄?| 鎵撶偣鏁版嵁瀛樻斁鐩綍鐨勯厤棰濆ぇ灏忥紝榛樿鍊间负鈥?0M鈥濄€傚缓璁厤棰濆ぇ灏忎笉瓒呰繃10M锛岄厤棰濊繃澶у彲鑳戒細褰卞搷鎺ュ彛鏁堢巼銆傚湪鐩綍澶у皬瓒呭嚭閰嶉鍚庯紝涓嬫鎵撶偣浼氳Е鍙戝鐩綍鐨勬竻鐞嗘搷浣滐細鎸変粠鏃у埌鏂扮殑椤哄簭閫愪釜鍒犻櫎鎵撶偣鏁版嵁鏂囦欢锛岀洿鍒扮洰褰曞ぇ灏忎笉瓒呭嚭閰嶉鏃剁粨鏉熴€傞厤棰濆€煎瓧绗︿覆瑙勬牸濡備笅锛? 閰嶉鍊煎瓧绗︿覆鍙敱鏁板瓧瀛楃鍜屽ぇ灏忓崟浣嶅瓧绗︼紙鍗曚綅瀛楃鏀寔[b|k|kb|m|mb|g|gb|t|tb]锛屼笉鍖哄垎澶у皬鍐欙級鏋勬垚銆? 閰嶉鍊煎瓧绗︿覆蹇呴』浠ユ暟瀛楀紑澶达紝鍚庨潰鍙互閫夋嫨涓嶄紶鍗曚綅瀛楃锛堥粯璁や娇鐢╞yte浣滀负鍗曚綅锛夛紝鎴栬€呬互鍗曚綅瀛楃缁撳熬銆?|
#### EventPolicy22+
鎻愪緵绯荤粺浜嬩欢閰嶇疆绛栫暐鐨勫畾涔夛紝鐢ㄤ簬浣跨敤 [configEventPolicy](#hiappeventconfigeventpolicy22) 璁剧疆浜嬩欢閰嶇疆绛栫暐銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 22寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| mainThreadJankPolicy | [MainThreadJankPolicy](#mainthreadjankpolicy22) | 鍚?| 鏄?| 涓荤嚎绋嬭秴鏃朵簨浠堕厤缃瓥鐣ャ€?|
| cpuUsageHighPolicy | [CpuUsageHighPolicy](#cpuusagehighpolicy22) | 鍚?| 鏄?| CPU楂樿礋杞戒簨浠堕厤缃瓥鐣ャ€?|
#### MainThreadJankPolicy22+
鎻愪緵涓荤嚎绋嬭秴鏃朵簨浠堕厤缃瓥鐣ョ殑瀹氫箟銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 22寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| logType | number | 鍚?| 鏄?| 閲囬泦鏃ュ織鐨勭被鍨嬨€傞粯璁ゅ€硷細0銆俵ogType=0锛氬叾浠栭€夐」鍧囧彇榛樿鍊硷紝涓荤嚎绋嬭繛缁袱娆¤秴鏃?50ms~450ms锛岄噰闆嗚皟鐢ㄦ爤锛涗富绾跨▼瓒呮椂450ms锛岄噰闆唗race銆俵ogType=1锛氫粎閲囬泦璋冪敤鏍堬紝瑙﹀彂妫€娴嬬殑闃堝€肩敱鐢ㄦ埛鑷畾涔夈€俵ogType=2锛氫粎閲囬泦trace銆?*璇存槑**锛? logType=0鏃讹紝浠呴渶閰嶇疆autoStopSampling鍙傛暟锛屽叾浠栧弬鏁板潎鍙栭粯璁ゅ€硷紝鏃犻渶璁剧疆銆? logType=2鏃讹紝鍏朵粬鍙傛暟鍧囦笉鐢熸晥锛屾棤闇€璁剧疆銆?|
| ignoreStartupTime | number | 鍚?| 鏄?| 搴旂敤鍚姩鏈熼棿蹇界暐涓荤嚎绋嬭秴鏃舵娴嬬殑鏃堕棿銆傚崟浣嶏細绉掞紝榛樿鍊硷細10锛屾渶灏忓€硷細3銆?|
| sampleInterval | number | 鍚?| 鏄?| 涓荤嚎绋嬭秴鏃舵娴嬮棿闅斿拰閲囨牱闂撮殧銆傚崟浣嶏細姣锛岄粯璁ゅ€硷細150锛屽彇鍊艰寖鍥达細[50, 500]銆?|
| sampleCount | number | 鍚?| 鏄?| 涓荤嚎绋嬭秴鏃堕噰鏍锋鏁般€傚崟浣嶏細娆★紝榛樿鍊硷細10锛屾渶灏忓€硷細1銆傛渶澶у€奸渶瑕佺粨鍚堣嚜瀹氫箟鐨剆ampleInterval杩涜鍔ㄦ€佽绠楋紝璁＄畻鍏紡锛歴ampleCount <= (2500 / sampleInterval - 4)銆?*璇存槑**锛? 2500鐨勫惈涔夛細鏍规嵁绯荤粺瑙勫畾锛屼富绾跨▼瓒呮椂浜嬩欢浠庢娴嬪埌涓婃姤鐨勬椂闂翠笉鍙互瓒呰繃2.5s锛堝嵆锛?500ms锛夈€傚洜姝ampleCount鐨勮缃€间笉鑳借秴杩囩郴缁熸寜璁＄畻鍏紡寰楀嚭鐨勬渶澶у€笺€? 4鐨勫惈涔夛細绗竴娆¤秴鏃堕棿闅旀娴嬫椂闂?+ 绗簩娆¤秴鏃堕棿闅旓紙绯荤粺鎻愪緵涓ゆ鍐嶆鍙戠敓瓒呮椂浜嬩欢鐨勬娴嬫満浼氾級鏃堕棿 + 鏀堕泦骞朵笂鎶ュ爢鏍堜俊鎭殑鏃堕棿銆? 寮€鍙戣€呰缁撳悎闇€姹傚満鏅紝杩涜鍚堢悊鐨勮缃€?|
| reportTimesPerApp | number | 鍚?| 鏄?| 鍚屼竴涓簲鐢ㄧ殑PID涓€涓敓鍛藉懆鏈熷唴锛屼富绾跨▼瓒呮椂閲囨牱涓婃姤娆℃暟銆備竴涓敓鍛藉懆鏈熷唴鍙兘璁剧疆涓€娆°€傞粯璁ゅ€硷細1锛屽崟浣嶏細娆°€傛瘡鍒嗛挓涓婃姤娆℃暟鑼冨洿锛歔1, 3]銆?|
| autoStopSampling | boolean | 鍚?| 鏄?| 涓荤嚎绋嬭秴鏃剁粨鏉熸椂锛屾槸鍚﹁嚜鍔ㄥ仠姝㈤噰鏍蜂富绾跨▼鍫嗘爤銆倀rue: 瓒呮椂缁撴潫鎴栬揪鍒拌缃殑閲囨牱娆℃暟锛屽仠姝㈤噰鏍枫€俧alse锛氳揪鍒拌缃殑閲囨牱娆℃暟鏃跺仠姝㈤噰鏍枫€傞粯璁ゅ€硷細false銆?|
#### CpuUsageHighPolicy22+
鎻愪緵CPU楂樿礋杞戒簨浠堕厤缃瓥鐣ョ殑瀹氫箟銆?
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/1a/v3/6tP_5g39Twyfms09jyD5Qg/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260401T093449Z&HW-CC-Expire=86400&HW-CC-Sign=7128730ED41A10E8BEAF3C2C2B81E3915ADAC2FD28DD184F8577835FC9A84332)
璇ユ帴鍙ｈ璋冪敤鍚庯紝浼氬皢璁剧疆鍊兼寔涔呭寲銆傚悗缁噸澶嶈皟鐢ㄨ鎺ュ彛鏃讹紝鑻ヤ笉璁剧疆瀵瑰簲鍙傛暟锛屽垯鍙栦笂涓€娆＄郴缁熷彇鐢ㄧ殑鍊笺€?
**鍏冩湇鍔PI锛?* 浠嶢PI version 22寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪搴旂敤涓娇鐢ㄣ€?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| foregroundLoadThreshold | number | 鍚?| 鏄?| 搴旂敤鍓嶅彴CPU楂樿礋杞藉紓甯搁槇鍊硷紝闃堝€艰寖鍥达細[1, 100]锛屽崟浣嶏細%锛岄粯璁ゅ€硷細30銆傝嫢璁剧疆鍊煎湪闃堝€艰寖鍥村锛岀郴缁熷皢鍙栫敤榛樿鍊?0銆?*璇存槑**锛氬缓璁彇鍊煎皬浜?0銆?|
| backgroundLoadThreshold | number | 鍚?| 鏄?| 搴旂敤鍚庡彴CPU楂樿礋杞藉紓甯搁槇鍊硷紝闃堝€艰寖鍥达細[1, 100]锛屽崟浣嶏細%锛岄粯璁ゅ€硷細10銆傝嫢璁剧疆鍊煎湪闃堝€艰寖鍥村锛岀郴缁熷皢鍙栫敤榛樿鍊?0銆?*璇存槑**锛氬缓璁彇鍊煎皬浜?0銆?|
| threadLoadThreshold | number | 鍚?| 鏄?| 搴旂敤绾跨▼CPU楂樿礋杞藉紓甯搁槇鍊硷紝闃堝€艰寖鍥达細[15, 100]锛屽崟浣嶏細%锛岄粯璁ゅ€硷細70銆傝嫢璁剧疆鍊煎湪闃堝€艰寖鍥村锛岀郴缁熷皢鍙栫敤榛樿鍊?0銆?|
| perfLogCaptureCount | number | 鍚?| 鏄?| 閲囨牱鏍堟瘡鏃ラ噰闆嗘鏁般€備竴鏃︾郴缁熸娴嬪埌褰撳墠寮傚父鏃ュ織鐨勯噰闆嗘鏁拌秴杩囪缃€硷紝绯荤粺浠嶄細姝ｅ父涓婃姤浜嬩欢锛屼絾寮傚父浜嬩欢涓殑external_log瀛楁锛屽皢涓嶅啀闄勫姞鏃ュ織鏂囦欢璺緞淇℃伅銆侱ebug鐗堟湰搴旂敤锛岄槇鍊艰寖鍥达細[-1, 100]锛汻elease鐗堟湰搴旂敤锛岄槇鍊艰寖鍥达細[0, 20]銆傚崟浣嶏細娆★紝榛樿鍊硷細1銆傝嫢璁剧疆鍊煎湪闃堝€艰寖鍥村锛岀郴缁熷皢鍙栫敤榛樿鍊?銆?*璇存槑**锛?. 鍊间负-1锛岃〃绀轰笉闄愬埗閲囬泦鏃ュ織娆℃暟銆?. 鍊间负0锛岃〃绀轰笉閲囬泦鏃ュ織銆?. 鍊煎ぇ浜?锛岃〃绀烘瘡鏃ラ噰闆嗘鏁颁笂闄愩€?|
| threadLoadInterval | number | 鍚?| 鏄?| 搴旂敤绾跨▼CPU楂樿礋杞藉紓甯告娴嬪懆鏈燂紝闃堝€艰寖鍥达細[5, 3600]锛屽崟浣嶏細绉掞紝榛樿鍊硷細60銆傝嫢璁剧疆鍊煎湪闃堝€艰寖鍥村锛岀郴缁熷皢鍙栫敤榛樿鍊?0銆?|
#### Processor11+
鍙互涓婃姤浜嬩欢鐨勬暟鎹鐞嗚€呭璞°€傜敤浜庝簨浠剁殑涓婃姤鍜岀鐞嗭紝寮€鍙戣€呭彲鑷畾涔夋暟鎹鐞嗛厤缃紝婊¤冻涓嶅悓鐨勬暟鎹鐞嗛渶姹傘€?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| name | string | 鍚?| 鍚?| 鏁版嵁澶勭悊鑰呯殑鍚嶇О銆傚悕绉板彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?$锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| debugMode | boolean | 鍚?| 鏄?| 鏄惁寮€鍚痙ebug妯″紡锛岄粯璁ゅ€间负false銆傞厤缃€间负true琛ㄧず寮€鍚痙ebug妯″紡锛宖alse琛ㄧず涓嶅紑鍚痙ebug妯″紡銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| routeInfo | string | 鍚?| 鏄?| 鏈嶅姟鍣ㄤ綅缃俊鎭紝榛樿涓虹┖瀛楃涓层€備紶鍏ュ瓧绗︿覆闀垮害涓嶈兘瓒呰繃8KB锛岃秴杩囨椂浼氳缃负榛樿鍊笺€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| appId | string | 鍚?| 鏄?| 搴旂敤id锛岄粯璁や负绌哄瓧绗︿覆銆備紶鍏ュ瓧绗︿覆闀垮害涓嶈兘瓒呰繃8KB锛岃秴杩囨椂浼氳缃负榛樿鍊笺€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| onStartReport | boolean | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呭湪鍚姩鏃舵槸鍚︿笂鎶ヤ簨浠讹紝榛樿鍊间负false銆傞厤缃€间负true琛ㄧず涓婃姤浜嬩欢锛宖alse琛ㄧず涓嶄笂鎶ヤ簨浠躲€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| onBackgroundReport | boolean | 鍚?| 鏄?| 褰撳簲鐢ㄧ▼搴忚繘鍏ュ悗鍙版椂鏄惁涓婃姤浜嬩欢锛岄粯璁ゅ€间负false銆傞厤缃€间负true琛ㄧず涓婃姤浜嬩欢锛宖alse琛ㄧず涓嶄笂鎶ヤ簨浠躲€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| periodReport | number | 鍚?| 鏄?| 浜嬩欢瀹氭椂涓婃姤鏃堕棿鍛ㄦ湡锛屽崟浣嶄负绉掋€備紶鍏ユ暟鍊煎繀椤诲ぇ浜庢垨绛変簬0锛屽皬浜?鏃朵細琚疆涓洪粯璁ゅ€?锛屼笉杩涜瀹氭椂涓婃姤銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| batchReport | number | 鍚?| 鏄?| 浜嬩欢涓婃姤闃堝€硷紝褰撲簨浠舵潯鏁拌揪鍒伴槇鍊兼椂涓婃姤浜嬩欢銆備紶鍏ユ暟鍊煎繀椤诲ぇ浜?涓斿皬浜?000锛屼笉鍦ㄦ暟鍊艰寖鍥村唴浼氳缃负榛樿鍊?锛屼笉杩涜涓婃姤銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| userIds | string[] | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呭彲浠ヤ笂鎶ョ殑鐢ㄦ埛ID鐨刵ame鏁扮粍銆俷ame瀵瑰簲[setUserId](#hiappeventsetuserid11)鎺ュ彛鐨刵ame鍙傛暟銆傞粯璁や负绌烘暟缁勩€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| userProperties | string[] | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呭彲浠ヤ笂鎶ョ殑鐢ㄦ埛灞炴€х殑name鏁扮粍銆俷ame瀵瑰簲[setUserProperty](#hiappeventsetuserproperty11)鎺ュ彛鐨刵ame鍙傛暟銆傞粯璁や负绌烘暟缁勩€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| eventConfigs | [AppEventReportConfig](#appeventreportconfig11)[] | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呭彲浠ヤ笂鎶ョ殑浜嬩欢鎻忚堪閰嶇疆鏁扮粍銆傞粯璁や负绌烘暟缁勩€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| configId12+ | number | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呴厤缃甶d銆備紶鍏ユ暟鍊煎繀椤诲ぇ浜庢垨绛変簬0锛屽皬浜?鏃朵細琚疆涓洪粯璁ゅ€?銆備紶鍏ョ殑鍊煎ぇ浜?鏃讹紝涓庢暟鎹鐞嗚€呯殑鍚嶇Оname鍏卞悓鍞竴鏍囪瘑鏁版嵁澶勭悊鑰呫€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| customConfigs12+ | Record<string, string> | 鍚?| 鏄?| 鑷畾涔夋墿灞曞弬鏁般€備紶鍏ュ弬鏁板悕鍜屽弬鏁板€间笉绗﹀悎瑙勬牸浼氶粯璁や笉閰嶇疆鎵╁睍鍙傛暟锛屽叾瑙勬牸瀹氫箟濡備笅锛? 鍙傛暟鍚嶄负string绫诲瀷锛岄瀛楃蹇呴』涓哄瓧姣嶅瓧绗︽垨$瀛楃锛屼腑闂村瓧绗﹀繀椤讳负鏁板瓧瀛楃銆佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︼紝缁撳熬瀛楃蹇呴』涓烘暟瀛楀瓧绗︽垨瀛楁瘝瀛楃锛岄暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€? 鍙傛暟鍊间负string绫诲瀷锛屽弬鏁板€奸暱搴﹂渶鍦?024涓瓧绗︿互鍐呫€? 鍙傛暟涓暟闇€鍦?2涓互鍐呫€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| configName20+ | string | 鍚?| 鏄?| 鏁版嵁澶勭悊鑰呯殑閰嶇疆鍚嶇О锛岄粯璁や负绌猴紝绯荤粺涓嶄粠閰嶇疆鏂囦欢涓姞杞介厤缃」銆傚綋閰嶇疆鍚嶇О涓嶄负绌烘椂锛岀郴缁熶細鏍规嵁閰嶇疆鍚嶇О浠庣郴缁熼缃殑processor.json閰嶇疆鏂囦欢涓嚜鍔ㄥ姞杞藉搴旂殑閰嶇疆椤广€傚彧鑳藉寘鍚ぇ灏忓啓瀛楁瘝銆佹暟瀛椼€佷笅鍒掔嚎鍜?锛屼笉鑳戒互鏁板瓧寮€澶达紝闀垮害闈炵┖涓斾笉瓒呰繃256涓瓧绗︺€傚綋鍓嶅彇鍊间粎鏀寔鈥淪DK_OCG鈥濓紝鐢ㄤ簬閰嶇疆鈥滄帴鍙ｆ晠闅滃鐞嗚€呪€濆彲澶勭悊鐨勪簨浠跺悕绉扮瓑淇℃伅銆?*鍏冩湇鍔PI锛?*浠嶢PI version 20寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
#### AppEventReportConfig11+
鏁版嵁澶勭悊鑰呭彲浠ヤ笂鎶ヤ簨浠剁殑鎻忚堪閰嶇疆銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 鍙€?| 璇存槑 |
| --- | --- | --- | --- | --- |
| domain | string | 鍚?| 鏄?| 浜嬩欢棰嗗煙銆傞粯璁や负绌哄瓧绗︿覆锛屼簨浠堕鍩熷悕绉版敮鎸佹暟瀛椼€佸瓧姣嶃€佷笅鍒掔嚎瀛楃锛岄渶瑕佷互瀛楁瘝寮€澶翠笖涓嶈兘浠ヤ笅鍒掔嚎缁撳熬锛岄暱搴﹂潪绌轰笖涓嶈秴杩?2涓瓧绗︺€?|
| name | string | 鍚?| 鏄?| 浜嬩欢鍚嶇О銆傞粯璁や负绌哄瓧绗︿覆锛岄瀛楃蹇呴』涓哄瓧姣嶅瓧绗︽垨$瀛楃锛屼腑闂村瓧绗﹀繀椤讳负鏁板瓧瀛楃銆佸瓧姣嶅瓧绗︽垨涓嬪垝绾垮瓧绗︼紝缁撳熬瀛楃蹇呴』涓烘暟瀛楀瓧绗︽垨瀛楁瘝瀛楃锛岄暱搴﹂潪绌轰笖涓嶈秴杩?8涓瓧绗︺€?|
| isRealTime | boolean | 鍚?| 鏄?| 鏄惁瀹炴椂涓婃姤浜嬩欢銆傞粯璁ゅ€间负false锛岄厤缃€间负true琛ㄧず瀹炴椂涓婃姤浜嬩欢锛宖alse琛ㄧず涓嶅疄鏃朵笂鎶ヤ簨浠躲€?|
#### ParamType12+
type ParamType = number | string | boolean | Array<string>
浜嬩欢鑷畾涔夊弬鏁板€肩殑绫诲瀷銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 12寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 绫诲瀷 | 璇存槑 |
| --- | --- |
| number | 琛ㄧず鍊肩被鍨嬩负鏁板瓧銆?|
| string | 琛ㄧず鍊肩被鍨嬩负瀛楃涓层€?|
| boolean | 琛ㄧず鍊肩被鍨嬩负甯冨皵鍊笺€?|
| Array<string> | 琛ㄧず鍊肩被鍨嬩负瀛楃涓茬被鍨嬬殑鏁扮粍銆?|
#### EventType
浜嬩欢绫诲瀷鏋氫妇銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 鍊?| 璇存槑 |
| --- | --- | --- |
| FAULT | 1 | 鏁呴殰绫诲瀷浜嬩欢銆?|
| STATISTIC | 2 | 缁熻绫诲瀷浜嬩欢銆?|
| SECURITY | 3 | 瀹夊叏绫诲瀷浜嬩欢銆?|
| BEHAVIOR | 4 | 琛屼负绫诲瀷浜嬩欢銆?|
#### hiAppEvent.domain11+
鎻愪緵棰嗗煙鍚嶇О甯搁噺銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 璇存槑 |
| --- | --- | --- | --- |
| OS | string | 鏄?| 绯荤粺棰嗗煙銆?|
#### hiAppEvent.event
鎻愪緵浜嬩欢鍚嶇О甯搁噺銆傚寘鍚郴缁熶簨浠跺悕绉板父閲忓拰搴旂敤浜嬩欢鍚嶇О甯搁噺锛屽叾涓簲鐢ㄤ簨浠跺悕绉板父閲忔槸涓哄紑鍙戣€呭湪璋冪敤 [Write](#hiappeventwrite-1) 鎺ュ彛杩涜搴旂敤浜嬩欢鎵撶偣鏃堕鐣欑殑鍙€夎嚜瀹氫箟浜嬩欢鍚嶇О銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 璇存槑 |
| --- | --- | --- | --- |
| USER_LOGIN | string | 鏄?| 鐢ㄦ埛鐧诲綍浜嬩欢銆傞鐣欑殑搴旂敤浜嬩欢鍚嶇О甯搁噺銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| USER_LOGOUT | string | 鏄?| 鐢ㄦ埛鐧诲嚭浜嬩欢銆傞鐣欑殑搴旂敤浜嬩欢鍚嶇О甯搁噺銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| DISTRIBUTED_SERVICE_START | string | 鏄?| 鍒嗗竷寮忔湇鍔″惎鍔ㄤ簨浠躲€傞鐣欑殑搴旂敤浜嬩欢鍚嶇О甯搁噺銆?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| APP_CRASH11+ | string | 鏄?| 搴旂敤宕╂簝浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| APP_FREEZE11+ | string | 鏄?| 搴旂敤鍐诲睆浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 11寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| APP_LAUNCH12+ | string | 鏄?| 搴旂敤鍚姩鑰楁椂浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| SCROLL_JANK12+ | string | 鏄?| 搴旂敤婊戝姩涓㈠抚浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| CPU_USAGE_HIGH12+ | string | 鏄?| 搴旂敤CPU楂樿礋杞戒簨浠躲€傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| BATTERY_USAGE12+ | string | 鏄?| 搴旂敤24h鍔熻€楀櫒浠跺垎瑙ｇ粺璁′簨浠躲€傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| RESOURCE_OVERLIMIT12+ | string | 鏄?| 搴旂敤璧勬簮娉勬紡浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| ADDRESS_SANITIZER12+ | string | 鏄?| 搴旂敤鍦板潃瓒婄晫浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| MAIN_THREAD_JANK12+ | string | 鏄?| 搴旂敤涓荤嚎绋嬭秴鏃朵簨浠躲€傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 12寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| APP_KILLED20+ | string | 鏄?| 搴旂敤缁堟浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 20寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| APP_HICOLLIE21+ | string | 鏄?| 搴旂敤浠诲姟鎵ц瓒呮椂浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 21寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
| AUDIO_JANK_FRAME21+ | string | 鏄?| 搴旂敤闊抽鍗￠】浜嬩欢銆傜郴缁熶簨浠跺悕绉板父閲忋€?*鍏冩湇鍔PI锛?*浠嶢PI version 21寮€濮嬶紝璇ュ弬鏁版敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?|
#### hiAppEvent.param
鎻愪緵鍙傛暟鍚嶇О甯搁噺銆?
**鍏冩湇鍔PI锛?* 浠嶢PI version 11寮€濮嬶紝璇ユ帴鍙ｆ敮鎸佸湪鍏冩湇鍔′腑浣跨敤銆?
**绯荤粺鑳藉姏锛?* SystemCapability.HiviewDFX.HiAppEvent
| 鍚嶇О | 绫诲瀷 | 鍙 | 璇存槑 |
| --- | --- | --- | --- |
| USER_ID | string | 鏄?| 鐢ㄦ埛鑷畾涔塈D銆?|
| DISTRIBUTED_SERVICE_NAME | string | 鏄?| 鍒嗗竷寮忔湇鍔″悕绉般€?|
| DISTRIBUTED_SERVICE_INSTANCE_ID | string | 鏄?| 鍒嗗竷寮忔湇鍔″疄渚婭D銆?|
