# 璁㈤槄24h鍔熻€楀櫒浠跺垎瑙ｇ粺璁′簨浠讹紙ArkTS锛?
---
# 璁㈤槄24h鍔熻€楀櫒浠跺垎瑙ｇ粺璁′簨浠讹紙ArkTS锛?
#### 鎺ュ彛璇存槑
API鎺ュ彛鐨勫叿浣撲娇鐢ㄨ鏄庯紙鍙傛暟浣跨敤闄愬埗銆佸叿浣撳彇鍊艰寖鍥寸瓑锛夎鍙傝€?[@ohos.hiviewdfx.hiAppEvent (搴旂敤浜嬩欢鎵撶偣)ArkTS API鏂囨。](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/绯荤粺/璋冩祴璋冧紭/Performance Analysis Kit锛堟€ц兘鍒嗘瀽鏈嶅姟锛?ArkTS API/js-apis-hiviewdfx-hiappevent) 銆?
| 鎺ュ彛鍚?| 鎻忚堪 |
| --- | --- |
| addWatcher(watcher: Watcher): AppEventPackageHolder | 娣诲姞搴旂敤浜嬩欢瑙傚療鑰咃紝浠ユ坊鍔犲搴旂敤浜嬩欢鐨勮闃呫€?|
| removeWatcher(watcher: Watcher): void | 绉婚櫎搴旂敤浜嬩欢瑙傚療鑰咃紝浠ョЩ闄ゅ搴旂敤浜嬩欢鐨勮闃呫€?|
#### 寮€鍙戞楠?
浠ュ疄鐜板搴旂敤鍐呭绾跨▼鎵ц鑰楁椂鎿嶄綔鐢熸垚鐨?4h鍔熻€楀櫒浠跺垎瑙ｇ粺璁′簨浠惰闃呬负渚嬶紝璇存槑寮€鍙戞楠ゃ€?
1.
缂栬緫宸ョ▼涓殑鈥渆ntry > src > main > ets  > entryability > EntryAbility.ets鈥濇枃浠讹紝鍦╫nCreate鍑芥暟涓坊鍔犵郴缁熶簨浠剁殑璁㈤槄锛岀ず渚嬩唬鐮佸涓嬶細
```
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
hiAppEvent.addWatcher({
   // 寮€鍙戣€呭彲浠ヨ嚜瀹氫箟瑙傚療鑰呭悕绉帮紝绯荤粺浼氫娇鐢ㄥ悕绉版潵鏍囪瘑涓嶅悓鐨勮瀵熻€?
   name: "watcher",
   // 寮€鍙戣€呭彲浠ヨ闃呮劅鍏磋叮鐨勭郴缁熶簨浠讹紝姝ゅ鏄闃呬簡搴旂敤24h鍔熻€楀櫒浠跺垎瑙ｇ粺璁′簨浠?
   appEventFilters: [
     {
       domain: hiAppEvent.domain.OS,
       names: [hiAppEvent.event.BATTERY_USAGE]
     }
   ],
   // 寮€鍙戣€呭彲浠ヨ嚜琛屽疄鐜拌闃呭疄鏃跺洖璋冨嚱鏁帮紝浠ヤ究瀵硅闃呰幏鍙栧埌鐨勪簨浠舵暟鎹繘琛岃嚜瀹氫箟澶勭悊
   onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
     hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
     for (const eventGroup of appEventGroups) {
       // 寮€鍙戣€呭彲浠ユ牴鎹簨浠堕泦鍚堜腑鐨勪簨浠跺悕绉板尯鍒嗕笉鍚岀殑绯荤粺浜嬩欢
       hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
       for (const eventInfo of eventGroup.appEventInfos) {
         // 寮€鍙戣€呭彲浠ュ浜嬩欢闆嗗悎涓殑浜嬩欢鏁版嵁杩涜鑷畾涔夊鐞嗭紝姝ゅ鏄皢浜嬩欢鏁版嵁鎵撳嵃鍦ㄦ棩蹇椾腑
         hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo=${JSON.stringify(eventInfo)}`);
       }
     }
   }
 });
```
2.
宸ョ▼涓瀯閫犻珮鑰楃數娴嬭瘯鍦烘櫙锛屽苟杩涜鐩稿叧娴嬭瘯锛屼娇璁惧浜х敓瀹為檯鑰楃數锛屾紨绀虹ず渚嬪涓嬶細
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/0/v3/DqsuSCI7RBq88Y2hY_anug/caution_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T104946Z&HW-CC-Expire=86400&HW-CC-Sign=3F5A18362F7B6ACB82F6340C98CD98C907E08F7B6E1216173D3DF5270B1F9A33)
寮€鍙戣€呰嚜娴嬭瘯鍙烦杩囨姝ラ锛屼粎闇€瀹屾垚搴旂敤瀹夎鍚庡苟鏂紑鍏呯數锛堝厖鐢电姸鎬佷笅娴嬭瘯浼氬鑷存棤鏁版嵁涓婃姤锛夛紝浣跨敤搴旂敤5鍒嗛挓浠ヤ笂銆?
1锛夊伐绋嬩腑娣诲姞鈥渆ntry > src > main > ets  > workers> worker.ets鈥濇枃浠讹紝鏋勯€犱竴涓寰幆锛屾帴鏀跺埌涓荤嚎绋嬬殑娑堟伅鍚庤Е鍙慍PU楂樿礋杞戒簨浠讹紝瀹屾暣绀轰緥浠ｇ爜濡備笅
```
import { worker } from '@kit.ArkTS';
let workerPort = worker.workerPort;
workerPort.onmessage = (message) => {
  eatCpu();
}
function eatCpu(): void {
  let val:number = 0;
  while (true) {
    val++;
  }
}
```
2锛夊伐绋嬩腑娣诲姞鈥渆ntry > src > main > ets  > tester> CpuTester.ets鈥濇枃浠讹紝鍦–puTester 绫讳腑鐨剆tart鏂规硶涓紑鍚涓嚎绋嬬殑姝诲惊鐜紝浠ヨЕ鍙戝绾跨▼鐨凜PU楂樿礋杞戒簨浠讹紝瀹屾暣绀轰緥浠ｇ爜濡備笅锛?
```
import { worker } from '@kit.ArkTS';
export default class CpuTester {
  workerInstance: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/worker.ets');
  start(threadNum: number) {
    for (let index = 0; index < threadNum; index++) {
      this.workerInstance = new worker.ThreadWorker('entry/ets/workers/worker.ets');
      this.workerInstance.postMessage('msg');
    }
  }
}
```
3锛夌紪杈戝伐绋嬩腑鐨勨€渆ntry > src > main > ets  > pages > Index.ets鈥濇枃浠讹紝娣诲姞鈥淐PU鍔犲帇鈥濇寜閽苟鍦ㄥ叾onClick鍑芥暟鏋勯€犲绾跨▼鎵ц姝诲惊鐜紝浠ヨЕ鍙慍PU楂樿礋杞戒簨浠讹紝瀹屾暣绀轰緥浠ｇ爜濡備笅锛?
```
import CpuTester from '../tester/CpuTester';
@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State enable: boolean = true;
  @State threadNum: number = 5;
  cpuTester: CpuTester = new CpuTester();
build() {
  Row() {
    Column() {
      Text(this.message)
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
      Button('CPU鍔犲帇')
        .fontSize(18)
        .margin(12)
        .fontWeight(FontWeight.Bold)
        .enabled(this.enable)
        .onClick(() => {
          this.cpuTester.start(this.threadNum);
          this.enable = false;
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```
4锛夊畨瑁呰繍琛屾祴璇曞簲鐢ㄥ埌娴嬭瘯鏈轰笂锛屾柇寮€USB锛?in1璁惧杩橀渶瑕佹柇寮€鍏呯數绾匡級锛?
5锛夋墦寮€娴嬭瘯搴旂敤锛岀劧鍚庡湪搴旂敤鐣岄潰涓偣鍑烩€淐PU鍔犲帇鈥濇寜閽紝鎸佺画鍗佸垎閽燂紝娴嬭瘯杩囩▼淇濇寔灞忓箷甯镐寒銆?
3.
娴嬭瘯瀹屾垚鍚庤繛鎺SB锛?鐐瑰悗鍦↙og绐楀彛鐪嬪埌瀵圭郴缁熶簨浠舵暟鎹殑澶勭悊鏃ュ織锛堝揩閫熻Е鍙戜笂鎶ユ柟寮忥細鎵ц鍛戒护hdc shell hidumper -s 1213 -a '--test 1'锛岃繘鍏ユ祴璇曟ā寮忎笉杩涜鏃堕棿璺冲彉鐨勬牎楠岋紝鐒跺悗淇敼璁惧鏃堕棿涓轰笅鍗堢殑11鐐?8鍒嗭級锛?
```
HiAppEvent onReceive: domain=OS
HiAppEvent eventName=BATTERY_USAGE
HiAppEvent eventInfo={"domain":"OS","name":"BATTERY_USAGE","eventType":2,"params":{"audio_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"audio_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"background_usage":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"begin_time":1709654400000,"bundle_name":"com.example.myapplication","bundle_version":"1.0.0","cpu_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"cpu_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,125647],"ddr_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"ddr_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,207],"gps_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"gps_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"sensor_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"sensor_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"display_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"display_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8606],"end_time":1709740800000,"foreground_usage":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,67766],"gpu_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"gpu_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,48],"modem_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"modem_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"others_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"others_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1170],"rom_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"rom_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"time":1709740801326,"wifi_background_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"wifi_foreground_energy":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}}
```
