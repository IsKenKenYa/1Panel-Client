/**
 * App Linking receive-side MERGE FRAGMENT (方法级合并片段).
 *
 * 【合并方式，禁止整文件替换宿主 EntryAbility】：
 * 1. 把 handleAppLinkWant 整个方法拷入宿主已有 EntryAbility 类内
 * 2. 在已有 onCreate / onNewWant 里各加一行 this.handleAppLinkWant(want)，宿主原有逻辑全部保留
 * 3. host 校验属于 module.json5 skills / AGC 域名关联，Ability 内不做二次校验、不设 fromAppLink
 * 4. 导航跳转不在 Ability 做：入口页消费 INCOMING_URI_KEY 后按宿主路由风格跳转
 *
 * Imports needed by the merged code (供参考)：
 *   import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
 *   import { hilog } from '@kit.PerformanceAnalysisKit';
 */
const TAG = 'GestureShareLink';
const DOMAIN = 0x0000;
/** Shared key: non-empty means a pending App Linking uri for the landing page to consume. */
const INCOMING_URI_KEY = 'GestureShare_incomingUri';

/*
// ---------- 合并进宿主 EntryAbility（宿主已有代码全部保留，只加方法与两处调用） ----------
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleAppLinkWant(want); // ← 只新增这一行
    // ...host's existing onCreate code...
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleAppLinkWant(want); // ← 只新增这一行
    // ...host's existing onNewWant code...
  }

  // ↓ 整个方法拷入类内
  private handleAppLinkWant(want: Want): void {
    const uri = want?.uri;
    if (!uri || uri.length === 0) {
      return;
    }
    AppStorage.setOrCreate(INCOMING_URI_KEY, uri);
    hilog.info(DOMAIN, TAG, 'App Linking uri stored');
  }
}
*/

// ---------- Navigate on entry UI (pick ONE style matching the host app) ----------
/*
// A) Navigation + NavPathStack (common Stage pattern)
@StorageLink('GestureShare_incomingUri') incomingUri: string = '';
onPageShow(): void {
  if (this.incomingUri.length > 0) {
    this.pageInfos.pushPathByName('LandingPageName', null, true);
  }
}
// Landing page: if (this.incomingUri.length > 0) { apply; this.incomingUri = ''; }

// B) router
@StorageLink('GestureShare_incomingUri') incomingUri: string = '';
onPageShow(): void {
  if (this.incomingUri.length > 0) {
    router.pushUrl({ url: 'pages/LandingPage' });
  }
}
*/
