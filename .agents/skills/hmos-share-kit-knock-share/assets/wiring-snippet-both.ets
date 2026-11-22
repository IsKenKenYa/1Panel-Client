/**
 * BOTH (file + link) lifecycle wiring. Do NOT copy this file into the host project.
 * Adapt fragments onto the target page after copying assets/both/.
 * Use this file only when Q1 = 两者, or when incrementally upgrading file-only / link-only.
 *
 * One knock = one mode. Do not mix file and link records in one SharedData.
 * pcReceive / preciseKnock apply only when mode is FILE.
 * Copy KnockRectUtil.ets only when Q8=yes.
 *
 * ArkTS tip: prefer `class X implements KnockShareProvider` (see this snippet);
 * object literals may trigger arkts-no-untyped-obj-literals.
 *
 * enable(context, KnockShareMode, provider, options?)
 */

/*
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KnockShareManager, KnockShareMode } from './KnockShareManager';
import { KnockReceiveCapability, KnockShareProvider } from './KnockShareProvider';
// Q8=yes only:
// import { HitTypes, KnockRectUtil } from './KnockRectUtil';

const TAG = 'KnockShare';
const DOMAIN = 0x0000;

// FILE mode (Q7/Q8 options only here)
KnockShareManager.getInstance().enable(ctx, KnockShareMode.FILE, this.shareProvider);
// Q7/Q8=yes only:
// KnockShareManager.getInstance().enable(ctx, KnockShareMode.FILE, this.shareProvider, {
//   pcReceive: true,
//   preciseKnock: true
// });

// LINK mode
KnockShareManager.getInstance().enable(ctx, KnockShareMode.LINK, this.shareProvider);

// Switch radio: disable() then enable() with the other mode. Do not register a second knockShare listener.

// ---------- NavDestination ----------
.onShown(() => {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  if (this.isFileMode) {
    KnockShareManager.getInstance().enable(ctx, KnockShareMode.FILE, this.shareProvider);
  } else {
    KnockShareManager.getInstance().enable(ctx, KnockShareMode.LINK, this.shareProvider);
  }
})
.onHidden(() => {
  KnockShareManager.getInstance().disable();
})

class HostBothShareProvider implements KnockShareProvider {
  // Q3（文件）：uris 必须是已转换且可访问的 file://。
  // 由页面在「文件就绪」时写入；不要用文件名拼 Q7 的 filesDir。
  // canShare() 文件侧只看 uris.length，禁止 !is2in1()。
  fileMode: boolean = true;
  uris: string[] = [];
  allUris: string[] = [];
  linkContent: string = '';
  hostContext: common.UIAbilityContext | undefined = undefined;
  // Q8=yes：由页面注入。componentIds 必须与当前参与命中的可见项一致
  uiContext: UIContext | undefined = undefined;
  componentIds: string[] = [];
  onFilesInserted: ((shareData: systemShare.SharedData, insertIndex: number) => void) | undefined = undefined;

  addFileUri(uri: string): void {
    if (uri.length === 0) { return; }
    if (this.uris.indexOf(uri) < 0) { this.uris.push(uri); }
  }

  canShare(): boolean {
    return this.fileMode ? this.uris.length > 0 : this.linkContent.length > 0;
  }

  private utdOf(fileRef: string): string {
    const ext = '.' + fileRef.split('.').pop();
    return uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(ext);
  }

  getFileShareData(): systemShare.SharedData | undefined {
    try {
      if (this.uris.length === 0) { return undefined; }
      const data = new systemShare.SharedData({
        utd: this.utdOf(this.uris[0]),
        uri: this.uris[0]
      });
      for (let i = 1; i < this.uris.length; i++) {
        data.addRecord({
          utd: this.utdOf(this.uris[i]),
          uri: this.uris[i]
        });
      }
      return data;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `getFileShareData failed ${JSON.stringify(err)}`);
      return undefined;
    }
  }

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

  getReceiveCapabilities(): KnockReceiveCapability[] {
    const source = this.allUris.length > 0 ? this.allUris : this.uris;
    const seen: string[] = [];
    const caps: KnockReceiveCapability[] = [];
    for (let i = 0; i < source.length; i++) {
      const utd = this.utdOf(source[i]);
      if (seen.indexOf(utd) >= 0) {
        continue;
      }
      seen.push(utd);
      caps.push({ utd: utd, maxSupportedCount: 5 });
    }
    return caps;
  }

  // Q8=yes（Q8=no 时不要拷本段及 hitTestReceiveIndex）：整框命中 → 分享该项；未命中返回 undefined，由 Manager 回退 getFileShareData
  getFileShareDataAt(screenX: number, screenY: number): systemShare.SharedData | undefined {
    if (!this.uiContext || this.componentIds.length === 0) {
      return undefined;
    }
    const hitIndex = KnockRectUtil.hitTestComponentIds(
      this.uiContext, screenX, screenY, this.componentIds, HitTypes.TYPE_SEND);
    if (hitIndex < 0 || hitIndex >= this.uris.length) {
      return undefined;
    }
    try {
      return new systemShare.SharedData({
        utd: this.utdOf(this.uris[hitIndex]),
        uri: this.uris[hitIndex]
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `getFileShareDataAt failed ${JSON.stringify(err)}`);
      return undefined;
    }
  }

  // Q8 接收落点：默认整框命中返回该项下标。不要在这里插入数据。
  // 开发者按实际 UI 确认了其它命中规则时再改 hit 类型，不要预设。
  hitTestReceiveIndex(screenX: number, screenY: number): number {
    if (!this.uiContext || this.componentIds.length === 0) {
      return -1;
    }
    return KnockRectUtil.hitTestComponentIds(
      this.uiContext, screenX, screenY, this.componentIds, HitTypes.TYPE_SEND);
  }

  onDataReceived(shareData: systemShare.SharedData, insertIndex: number): void {
    // 只转发。插入策略在页面回调里按 Q8 接收落点确认结果实现。
    if (this.onFilesInserted !== undefined) {
      this.onFilesInserted(shareData, insertIndex);
    }
  }
}

// 页面 onFilesInserted 示例（不要整段拷贝；按 Q8 接收落点的确认结果实现）：
// this.shareProvider.onFilesInserted = (shareData, insertIndex) => {
//   this.getUIContext().runScopedTask(() => {
//     // 禁止未确认就把接收项 push 到末尾。只写已确认的落点策略。
//   });
// };

// 文件就绪时调用 addFileUri（已有 file:// 直接传；path 则 getUriFromPath）：
// 列表/选中变化、选择器回调、下载/拷贝/导出完成、onDataReceived 之后——以宿主为准。
*/
