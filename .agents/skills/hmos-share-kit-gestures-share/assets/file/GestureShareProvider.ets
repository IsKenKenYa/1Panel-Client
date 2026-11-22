/**
 * File-only GestureShareProvider. Do not add getLinkShareData here.
 * For link or both, use assets/link or assets/both instead (or incremental merge).
 *
 * 【角色分工】Manager 管"何时问"（监听/超时/reject），Provider 管"回答什么"（内容组装）：
 * 页面在 enable 前把可分享状态（URI 列表等）同步进 Provider 字段，手势回调里只做组装。
 *
 * Recommended contract with GestureShareManager:
 * - canShare(): whether there is sharable content now
 * - getFileShareData(): called only when canShare() is true; return SharedData or undefined
 * - On failure: catch locally, hilog, return undefined (Manager will reject)
 */
import { systemShare } from '@kit.ShareKit';

export interface GestureShareProvider {
  /** 当前有无可分享内容（如 URI 列表非空）；false 时 Manager 直接 reject，不会再要数据 */
  canShare(): boolean;

  /**
   * Build file SharedData. Called by Manager only after canShare()===true.
   * Success → SharedData (one or more file records via addRecord).
   * No content / assemble failure → undefined (Manager will reject).
   *
   * 【实现要点】
   * - 每条文件记录必填 utd + uri：utd 按扩展名 getUniformDataTypeByFilenameExtension 计算；
   *   uri 必须是真实可访问的 file://（沙箱路径需先 fileUri.getUriFromPath 转换）
   * - 多文件：首条进 SharedData 构造函数，其余循环 addRecord 追加，每条自带 utd+uri
   * - 必须同步返回（手势回调约 3 秒超时），禁止在此做下载/拷贝等重活；数据需提前预热
   * - 失败不要 throw：本地 catch 后返回 undefined，由 Manager 统一 reject(NO_CONTENT_ERROR)
   */
  getFileShareData(): systemShare.SharedData | undefined;

  /**
   * Optional: device does not support SystemCapability.Collaboration.HarmonyShare.
   * 可选降级钩子：设备不支持时由页面隐藏分享入口或 Toast 提示。
   */
  onUnsupported?: () => void;
}
