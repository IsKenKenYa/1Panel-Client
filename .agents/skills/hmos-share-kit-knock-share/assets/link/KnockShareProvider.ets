/**
 * Link-only KnockShareProvider. Do not add getFileShareData here.
 * For file or both, use assets/file or assets/both instead (or incremental merge).
 */
import { systemShare } from '@kit.ShareKit';

export interface KnockShareProvider {
  canShare(): boolean;

  /**
   * Build App Linking / hyperlink SharedData.
   * Success → SharedData; failure / empty → undefined. Never throw.
   */
  getLinkShareData(): systemShare.SharedData | undefined;

  onUnsupported?: () => void;
}
