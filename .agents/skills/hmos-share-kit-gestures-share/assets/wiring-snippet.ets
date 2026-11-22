/**
 * Lifecycle wiring examples. Adapt to the target page; do not copy blindly.
 * Copy Manager/Provider from assets/file | assets/link | assets/both per Q1.
 * Recommended: get*ShareData returns SharedData | undefined; on failure return undefined.
 * Import paths here use './' for brevity — adjust to the page's real relative path.
 *
 * ArkTS tip (arkts-no-untyped-obj-literals): prefer `class X implements GestureShareProvider`
 * over assigning an object literal to GestureShareProvider.
 */
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GestureShareManager, GestureShareMode } from './GestureShareManager';
import { GestureShareProvider } from './GestureShareProvider';

// ---------- NavDestination (file-only Manager: enable(ctx, provider)) ----------
/*
NavDestination() { }
.onShown(() => {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  GestureShareManager.getInstance().enable(ctx, this.shareProvider);
})
.onHidden(() => {
  GestureShareManager.getInstance().disable();
})
*/

// ---------- NavDestination (both Manager: enable(ctx, mode, provider)) ----------
/*
.onShown(() => {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  GestureShareManager.getInstance().enable(ctx, GestureShareMode.FILE, this.shareProvider);
})
*/

// ---------- @Entry (link-only Manager: enable(ctx, provider)) ----------
/*
onPageShow(): void {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  GestureShareManager.getInstance().enable(ctx, this.shareProvider);
}
onPageHide(): void {
  GestureShareManager.getInstance().disable();
}
*/

// ---------- Provider: FILE — collect URIs then loop (preferred when count can be >1) ----------
/*
// Q3 must confirm separately:
// 1) sharable scope (which items): checkbox subset / full list / focus+related / ...
// 2) uri acquisition: already file:// field / sandbox path + fileUri.getUriFromPath / picker result
// Do NOT invent selected* ; do NOT treat a path string as uri without confirmed conversion.
// Do NOT use object literals for GestureShareProvider (arkts-no-untyped-obj-literals).

class HostFileShareProvider implements GestureShareProvider {
  // Hold sharable state as fields; page syncs them before enable / on selection change.
  uris: string[] = [];

  canShare(): boolean {
    return this.uris.length > 0;
  }

  // utd 从"文件名"取扩展名：禁止对整个 uri 做 split('.')——
  // URI 末段可能无扩展名、带 query 或编码文件名；取不到扩展名 → 无法定 utd → 返回 undefined
  private extOf(uri: string): string | undefined {
    const name = uri.substring(uri.lastIndexOf('/') + 1);
    const dot = name.lastIndexOf('.');
    if (dot <= 0 || dot === name.length - 1) {
      return undefined;
    }
    return name.substring(dot);
  }

  getFileShareData(): systemShare.SharedData | undefined {
    try {
      if (this.uris.length === 0) {
        return undefined;
      }
      const firstExt = this.extOf(this.uris[0]);
      if (firstExt === undefined) {
        return undefined; // utd 必填，取不到扩展名不能糊弄，交给 Manager reject
      }
      const data = new systemShare.SharedData({
        utd: uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(firstExt),
        uri: this.uris[0]
      });
      for (let i = 1; i < this.uris.length; i++) {
        const ext = this.extOf(this.uris[i]);
        if (ext === undefined) {
          return undefined; // 任一条取不到扩展名：整次失败，禁止静默丢条
        }
        data.addRecord({
          utd: uniformTypeDescriptor.getUniformDataTypeByFilenameExtension(ext),
          uri: this.uris[i]
        });
      }
      return data;
    } catch (err) {
      hilog.error(0x0000, 'GestureShare', `getFileShareData failed ${JSON.stringify(err)}`);
      return undefined; // recommended: let Manager reject
    }
  }
}

// In @Component:
// private shareProvider: HostFileShareProvider = new HostFileShareProvider();
*/

// ---------- Provider: LINK ONLY (assets/link) ----------
/*
class HostLinkShareProvider implements GestureShareProvider {
  linkContent: string = '';

  canShare(): boolean {
    return this.linkContent.length > 0;
  }

  getLinkShareData(): systemShare.SharedData | undefined {
    try {
      if (this.linkContent.length === 0) {
        return undefined;
      }
      return new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        content: this.linkContent
      });
    } catch (err) {
      hilog.error(0x0000, 'GestureShare', `getLinkShareData failed ${JSON.stringify(err)}`);
      return undefined;
    }
  }
}

// In @Component:
// private shareProvider: HostLinkShareProvider = new HostLinkShareProvider();
*/

// ---------- Provider: BOTH (assets/both / incremental) ----------
/*
class HostBothShareProvider implements GestureShareProvider {
  // ... fields for file and/or link ...
  canShare(): boolean { ... }
  getFileShareData(): systemShare.SharedData | undefined { ... } // 同 FILE 写法
  getLinkShareData(): systemShare.SharedData | undefined { ... } // 同 LINK 写法
}
*/
