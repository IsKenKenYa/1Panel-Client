/**
 * App Linking receive-side snippet for EntryAbility + host navigation.
 *
 * Ability: if want.uri is non-empty, store it in AppStorage. Do NOT re-validate host here;
 * domain association belongs in module.json5 skills / AGC.
 *
 * Navigation: detect the host app's real router (Navigation / router / custom) and keep
 * the same style. Ability usually only persists uri; the entry UI navigates.
 */
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'KnockShareLink';
const DOMAIN = 0x0000;
/** Shared key: non-empty means a pending App Linking uri for the landing page to consume. */
const INCOMING_URI_KEY = 'KnockShare_incomingUri';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.handleAppLinkWant(want);
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    this.handleAppLinkWant(want);
  }

  private handleAppLinkWant(want: Want): void {
    const uri = want?.uri;
    if (!uri || uri.length === 0) {
      return;
    }
    AppStorage.setOrCreate(INCOMING_URI_KEY, uri);
    hilog.info(DOMAIN, TAG, 'App Linking uri stored');
  }
}

// ---------- Navigate on entry UI (pick ONE style matching the host app) ----------
/*
// A) Navigation + NavPathStack
@StorageLink('KnockShare_incomingUri') incomingUri: string = '';
onPageShow(): void {
  if (this.incomingUri.length > 0) {
    this.pageInfos.pushPathByName('LandingPageName', null, true);
  }
}
// Landing page: if (this.incomingUri.length > 0) { apply; this.incomingUri = ''; }

// B) router
@StorageLink('KnockShare_incomingUri') incomingUri: string = '';
onPageShow(): void {
  if (this.incomingUri.length > 0) {
    router.pushUrl({ url: 'pages/LandingPage' });
  }
}
*/
