/**
 * Component hit-test helpers for API 26+ precise knock on 2in1.
 * Copy only when Q8=yes. Host items must set .id() matching the id list.
 *
 * TYPE_SEND: point inside the full rect → that item index (default hit).
 * TYPE_RECEIVE: left half = this index, right half = next index.
 * Use TYPE_RECEIVE only when the developer confirmed that hit rule for this page.
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'KnockRectUtil';
const DOMAIN = 0x0000;

export interface ComponentOffset {
  x: number;
  y: number;
}

export interface ComponentSize {
  width: number;
  height: number;
}

export interface ComponentWindowRect {
  screenOffset: ComponentOffset;
  size: ComponentSize;
}

export enum HitTypes {
  TYPE_SEND = 'send',
  TYPE_RECEIVE = 'receive'
}

export enum HitReceivePlace {
  RECEIVE_THIS = 'this',
  RECEIVE_NEXT = 'next'
}

export class KnockRectUtil {
  static hitTestComponentIds(uiContext: UIContext, x: number, y: number, componentIds: string[],
    hitType: HitTypes): number {
    if (!componentIds || componentIds.length === 0) {
      return -1;
    }
    for (let i = 0; i < componentIds.length; i++) {
      const rect = KnockRectUtil.getRectangleById(uiContext, componentIds[i]);
      if (!rect) {
        continue;
      }
      const hitResult = KnockRectUtil.checkHitForComponent(x, y, rect, hitType, i);
      if (hitResult !== null) {
        return hitResult;
      }
    }
    return -1;
  }

  private static checkHitForComponent(x: number, y: number, rect: ComponentWindowRect, hitType: HitTypes,
    index: number): number | null {
    if (!KnockRectUtil.isPointInWindowRect(x, y, rect)) {
      return null;
    }
    if (hitType === HitTypes.TYPE_SEND) {
      return index;
    }
    const receiveResult = KnockRectUtil.isPointInWindowRectReceive(x, y, rect);
    return receiveResult === HitReceivePlace.RECEIVE_THIS ? index : index + 1;
  }

  static isPointInWindowRectReceive(x: number, y: number, rect: ComponentWindowRect): HitReceivePlace {
    const left: number = rect.screenOffset.x;
    const top: number = rect.screenOffset.y;
    const bottom: number = top + rect.size.height;
    const right: number = left + rect.size.width / 2;
    if (x >= left && x <= right && y >= top && y <= bottom) {
      return HitReceivePlace.RECEIVE_THIS;
    }
    return HitReceivePlace.RECEIVE_NEXT;
  }

  static getRectangleById(uiContext: UIContext, componentId: string): ComponentWindowRect | undefined {
    try {
      const componentInfo = uiContext.getComponentUtils().getRectangleById(componentId);
      const rect: ComponentWindowRect = {
        screenOffset: {
          x: componentInfo.screenOffset.x,
          y: componentInfo.screenOffset.y
        },
        size: {
          width: componentInfo.size.width,
          height: componentInfo.size.height
        }
      };
      return rect;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `getRectangleById failed id=${componentId}`);
      return undefined;
    }
  }

  static isPointInWindowRect(x: number, y: number, rect: ComponentWindowRect): boolean {
    const left: number = rect.screenOffset.x;
    const top: number = rect.screenOffset.y;
    const bottom: number = top + rect.size.height;
    const right: number = left + rect.size.width;
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  static buildFileItemIds(count: number, prefix: string): string[] {
    const ids: string[] = [];
    for (let i = 0; i < count; i++) {
      ids.push(`${prefix}${i}`);
    }
    return ids;
  }
}
