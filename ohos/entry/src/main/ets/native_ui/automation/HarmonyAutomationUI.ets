import { HarmonyNativeBridge } from '../HarmonyNativeBridge';

export const automationMoreSymbol: Resource = $r('sys.symbol.more');
export const automationEditSymbol: Resource = $r('sys.symbol.square_and_pencil');
export const automationCopySymbol: Resource = $r('sys.symbol.doc');
export const automationScriptSymbol: Resource = $r('sys.symbol.doc');

export function automationText(key: string): string {
  return HarmonyNativeBridge.instance.text(key);
}

export function automationString(record: Map<string, Object | null>, key: string): string {
  const content = record.get(key);
  return content === null || content === undefined ? '' : `${content}`;
}

export async function automationWrite(method: string, args?: Map<string, Object | null>): Promise<void> {
  const result = await HarmonyNativeBridge.instance.invoke<Map<string, Object | null> | null>(method, args);
  if (result !== null && result.get('success') === false && result.get('cancelled') !== true) {
    throw new Error(automationString(result, 'error'));
  }
}
