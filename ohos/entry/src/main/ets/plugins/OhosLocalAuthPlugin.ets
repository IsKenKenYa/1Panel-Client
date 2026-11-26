import { BusinessError } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

const TAG = 'OhosLocalAuthPlugin';
const CHANNEL = 'plugins.flutter.io/local_auth';
const TRUST_LEVEL = userAuth.AuthTrustLevel.ATL2;

export default class OhosLocalAuthPlugin
  implements FlutterPlugin, MethodCallHandler
{
  private channel: MethodChannel | null = null;
  private authentication: userAuth.UserAuthInstance | null = null;

  getUniqueClassName(): string {
    return 'OhosLocalAuthPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    const authentication = this.authentication;
    this.authentication = null;
    if (authentication !== null) {
      try {
        authentication.cancel();
      } catch (error) {
        Log.w(TAG, 'Unable to cancel local authentication during engine detach');
      }
    }
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      switch (call.method) {
        case 'authenticate':
          this.authenticate(call, result);
          return;
        case 'getAvailableBiometrics':
          result.success(this.getBiometrics());
          return;
        case 'isDeviceSupported':
          result.success(this.isAvailable(userAuth.UserAuthType.PIN) || this.getBiometrics().length > 0);
          return;
        case 'deviceSupportsBiometrics':
          result.success(this.getBiometrics().length > 0);
          return;
        case 'stopAuthentication':
          if (this.authentication === null) {
            result.success(false);
            return;
          }
          this.authentication.cancel();
          result.success(true);
          return;
        default:
          result.notImplemented();
      }
    } catch (error) {
      Log.e(TAG, `Failed to handle ${call.method}`, error);
      result.error('local_auth_error', `${error}`, null);
    }
  }

  private isAvailable(type: userAuth.UserAuthType): boolean {
    try {
      userAuth.getAvailableStatus(type, TRUST_LEVEL);
      return true;
    } catch (error) {
      const failure = error as BusinessError;
      const code = failure.code;
      if (code === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT ||
        code === userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT ||
        code === userAuth.UserAuthResultCode.NOT_ENROLLED ||
        code === userAuth.UserAuthResultCode.PIN_EXPIRED) {
        return false;
      }
      throw new Error(failure.message);
    }
  }

  private getBiometrics(): string[] {
    const biometrics: string[] = [];
    if (this.isAvailable(userAuth.UserAuthType.FINGERPRINT)) biometrics.push('fingerprint');
    if (this.isAvailable(userAuth.UserAuthType.FACE)) biometrics.push('face');
    return biometrics;
  }

  private authenticate(call: MethodCall, result: MethodResult): void {
    if (this.authentication !== null) {
      result.error('auth_in_progress', 'Local authentication is already in progress', null);
      return;
    }
    const authType: userAuth.UserAuthType[] = [];
    if (this.isAvailable(userAuth.UserAuthType.FINGERPRINT)) authType.push(userAuth.UserAuthType.FINGERPRINT);
    if (this.isAvailable(userAuth.UserAuthType.FACE)) authType.push(userAuth.UserAuthType.FACE);
    if (call.argument('biometricOnly') !== true && this.isAvailable(userAuth.UserAuthType.PIN)) {
      authType.push(userAuth.UserAuthType.PIN);
    }
    if (authType.length === 0) {
      result.error('NotAvailable', 'No enrolled authentication method is available', null);
      return;
    }
    const challenge = cryptoFramework.createRandom().generateRandomSync(32).data;
    const authentication = userAuth.getUserAuthInstance({
      authType, challenge, authTrustLevel: TRUST_LEVEL,
    }, { title: call.argument('localizedReason') as string });
    authentication.on('result', {
      onResult: (response: userAuth.UserAuthResult): void => {
        if (this.authentication !== authentication) return;
        this.authentication = null;
        if (response.result === userAuth.UserAuthResultCode.LOCKED) {
          result.error('LockedOut', 'Local authentication is temporarily locked', null);
        } else {
          result.success(response.result === userAuth.UserAuthResultCode.SUCCESS);
        }
      },
    });
    this.authentication = authentication;
    try {
      authentication.start();
    } catch (error) {
      this.authentication = null;
      result.error('local_auth_error', (error as BusinessError).message, null);
    }
  }
}
