/**
 * File-only KnockShareProvider. Do not add getLinkShareData / HYPERLINK here.
 * For link or both, use assets/link or assets/both instead (or incremental merge).
 *
 * Optional methods are used only when enable() options turn on pcReceive / preciseKnock.
 * Q7=yes: implement getReceiveCapabilities() with the same utd(s) used when sending.
 * Q7+Q8=yes: hitTestReceiveIndex returns the hit item index; the host applies the
 * confirmed receive-placement policy in onDataReceived (do not assume a container template).
 */
import { systemShare } from '@kit.ShareKit';

export interface KnockReceiveCapability {
  utd: string;
  maxSupportedCount: number;
}

export interface KnockShareProvider {
  canShare(): boolean;

  getFileShareData(): systemShare.SharedData | undefined;

  onUnsupported?: () => void;

  getFileShareDataAt?: (screenX: number, screenY: number) => systemShare.SharedData | undefined;

  getReceiveDirUri?: () => string;

  getReceiveCapabilities?: () => KnockReceiveCapability[];

  // insertIndex is the hit item index (-1 if miss). Host interprets it per Q8 receive placement.
  onDataReceived?: (shareData: systemShare.SharedData, insertIndex: number) => void;

  // Hit item index; -1 if miss. Default is whole-rect hit. Other hit rules only if confirmed.
  hitTestReceiveIndex?: (screenX: number, screenY: number) => number;
}
