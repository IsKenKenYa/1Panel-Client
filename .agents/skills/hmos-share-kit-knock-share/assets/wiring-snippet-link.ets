/**
 * LINK-ONLY lifecycle wiring. Do NOT copy this file into the host project.
 * Adapt fragments onto the target page after copying assets/link/.
 *
 * Forbidden in this snippet and in a link-only host:
 * getFileShareData, dataReceive, pcReceive, preciseKnock, KnockRectUtil,
 * file:// uri, addRecord, KnockShareMode.FILE, gesturesShare.
 *
 * ArkTS tip: prefer `class X implements KnockShareProvider` (see this snippet);
 * object literals may trigger arkts-no-untyped-obj-literals.
 *
 * enable(context, provider)  — no mode, no options.
 */

/*
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KnockShareManager } from './KnockShareManager';
import { KnockShareProvider } from './KnockShareProvider';

const TAG = 'KnockShare';
const DOMAIN = 0x0000;

// ---------- @Entry ----------
onPageShow(): void {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  KnockShareManager.getInstance().enable(ctx, this.shareProvider);
}
onPageHide(): void {
  KnockShareManager.getInstance().disable();
}

// ---------- NavDestination ----------
.onShown(() => {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  KnockShareManager.getInstance().enable(ctx, this.shareProvider);
})
.onHidden(() => {
  KnockShareManager.getInstance().disable();
})

class HostLinkShareProvider implements KnockShareProvider {
  linkContent: string = '';
  canShare(): boolean { return this.linkContent.length > 0; }
  getLinkShareData(): systemShare.SharedData | undefined {
    try {
      if (this.linkContent.length === 0) { return undefined; }
      return new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: this.linkContent
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `getLinkShareData failed ${JSON.stringify(err)}`);
      return undefined;
    }
  }
}
*/
