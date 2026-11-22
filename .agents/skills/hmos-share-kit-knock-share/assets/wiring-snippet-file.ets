/**
 * FILE-ONLY lifecycle wiring. Do NOT copy this file into the host project.
 * Adapt fragments onto the target page after copying assets/file/.
 *
 * Forbidden in this snippet and in a file-only host:
 * getLinkShareData, HYPERLINK, KnockShareMode.LINK, example.com, gesturesShare.
 * Copy KnockRectUtil.ets only when Q8=yes.
 *
 * ArkTS tip: prefer `class X implements KnockShareProvider` (see this snippet);
 * object literals may trigger arkts-no-untyped-obj-literals.
 *
 * enable(context, provider, options?)  — no KnockShareMode argument.
 */

/*
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KnockShareManager } from './KnockShareManager';
import { KnockReceiveCapability, KnockShareProvider } from './KnockShareProvider';
// Q8=yes only:
// import { HitTypes, KnockRectUtil } from './KnockRectUtil';

const TAG = 'KnockShare';
const DOMAIN = 0x0000;

// ---------- @Entry ----------
onPageShow(): void {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  KnockShareManager.getInstance().enable(ctx, this.shareProvider);
  // Q7/Q8=yes only:
  // KnockShareManager.getInstance().enable(ctx, this.shareProvider, {
  //   pcReceive: true,
  //   preciseKnock: true
  // });
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

class HostFileShareProvider implements KnockShareProvider {
  // Q3 必须单独确认（不要照抄本段当唯一业务）：
  // 1) 可分享范围：勾选 / 当前列表 / 其它（禁止臆造 selected*）
  // 2) uri：已有 file:// 字段 / 沙箱 path + getUriFromPath / 选择器或其它文件就绪回调
  //    path 以宿主实际写入处为准（filesDir / cacheDir / tempDir / 业务目录皆可能）
  //    Q7 的 filesDir 只给 getReceiveDirUri / receive()，不是发送默认根路径
  // 3) 页面在「文件就绪」时 addFileUri(...)；getFileShareData 不要用文件名拼目录
  // canShare() 只看 uris.length；禁止 !is2in1()
  uris: string[] = [];
  allUris: string[] = [];
  hostContext: common.UIAbilityContext | undefined = undefined;
  // Q8=yes：由页面注入。componentIds 必须与当前参与命中的可见项一致
  uiContext: UIContext | undefined = undefined;
  componentIds: string[] = [];
  onFilesInserted: ((shareData: systemShare.SharedData, insertIndex: number) => void) | undefined = undefined;

  addFileUri(uri: string): void {
    if (uri.length === 0) { return; }
    if (this.uris.indexOf(uri) < 0) { this.uris.push(uri); }
  }

  canShare(): boolean { return this.uris.length > 0; }

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

  // Q7=yes: same utd rule as getFileShareData / addRecord.
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

// 按宿主选一种时机调用 addFileUri（已有 file:// 直接传；path 则 getUriFromPath）：
// - 列表/选中变化
// - 选择器/拍照回调
// - 下载/拷贝/导出完成（path 以该 API 实际落盘为准）
// - onDataReceived 之后
*/
