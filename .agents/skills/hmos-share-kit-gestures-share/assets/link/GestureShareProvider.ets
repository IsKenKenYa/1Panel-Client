/**
 * Link-only GestureShareProvider. Do not add getFileShareData here.
 * For file or both, use assets/file or assets/both instead (or incremental merge).
 *
 * 【角色分工】Manager 管"何时问"（监听/超时/reject），Provider 管"回答什么"（内容组装）：
 * 页面在 enable 前把链接内容同步进 Provider 字段，手势回调里只做组装。
 *
 * Recommended contract with GestureShareManager:
 * - canShare(): whether there is a sharable link now
 * - getLinkShareData(): called only when canShare() is true; return SharedData or undefined
 * - On failure: catch locally, hilog, return undefined (Manager will reject)
 */
import { systemShare } from '@kit.ShareKit';

export interface GestureShareProvider {
  /** 当前有无可分享链接；false 时 Manager 直接 reject，不会再要数据 */
  canShare(): boolean;

  /**
   * Build App Linking / hyperlink SharedData.
   * Success → SharedData; failure / empty → undefined (Manager will reject).
   *
   * 【实现要点】
   * - utd 固定 uniformTypeDescriptor.UniformDataType.HYPERLINK
   * - content 为已关联域名的完整 https 链接（可带业务 query），禁止占位域名
   * - 必须同步返回（手势回调约 3 秒超时）；失败不要 throw，
   *   本地 catch 后返回 undefined，由 Manager 统一 reject(NO_CONTENT_ERROR)
   */
  getLinkShareData(): systemShare.SharedData | undefined;

  /**
   * Optional: device does not support SystemCapability.Collaboration.HarmonyShare.
   * 可选降级钩子：设备不支持时由页面隐藏分享入口或 Toast 提示（默认仅日志）。
   */
  onUnsupported?: () => void;
}
