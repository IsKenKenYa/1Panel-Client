import { KeyCode } from '@kit.InputKit';

export function handleSettingsActivationKey(event: KeyEvent | undefined, action: () => void): boolean {
  if (event === undefined || event.type !== KeyType.Down) {
    return false;
  }
  if (event.keyCode !== KeyCode.KEYCODE_ENTER && event.keyCode !== KeyCode.KEYCODE_SPACE) {
    return false;
  }
  action();
  return true;
}
