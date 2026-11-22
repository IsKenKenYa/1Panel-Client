import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import hilog from '@ohos.hilog';
import bundleManager from '@ohos.bundle.bundleManager';

const TAG = 'FallbackHandler';
const DOMAIN = 0xFF00;

export class ShareKitFallbackHandler {
  private context: common.UIAbilityContext;
  
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }
  
  async handleFallback(want: common.Want): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Fallback to default handler');
      
      const targetBundleName = await this.findAlternativeApp(want);
      
      if (targetBundleName) {
        hilog.info(DOMAIN, TAG, 'Found alternative app: %{public}s', targetBundleName);
        await this.launchAlternativeApp(targetBundleName, want);
      } else {
        hilog.warn(DOMAIN, TAG, 'No alternative app found, using system default');
        await this.launchSystemDefault(want);
      }
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Fallback handler failed: %{public}s', error.message);
      await this.showFallbackError(error.message);
    }
  }
  
  async findAlternativeApp(want: common.Want): Promise<string | null> {
    try {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION_INFO;
      const installedBundles = await bundleManager.getAllBundleInfo(bundleFlags);
      
      for (const bundle of installedBundles) {
        if (bundle.name === this.context.applicationInfo.bundleName) {
          continue;
        }
        
        if (await this.canHandleFileType(bundle.name, want)) {
          return bundle.name;
        }
      }
      
      return null;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Find alternative app failed: %{public}s', error.message);
      return null;
    }
  }
  
  async canHandleFileType(bundleName: string, want: common.Want): Promise<boolean> {
    try {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_ABILITY_INFO;
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags);
      
      for (const ability of bundleInfo.abilityInfo) {
        if (!ability.skills) {
          continue;
        }
        
        for (const skill of ability.skills) {
          if (!skill.uris) {
            continue;
          }
          
          for (const uriConfig of skill.uris) {
            if (want.type && uriConfig.type === want.type) {
              return true;
            }
            
            if (want.uri && uriConfig.scheme) {
              const wantScheme = this.getSchemeFromUri(want.uri);
              if (wantScheme === uriConfig.scheme) {
                return true;
              }
            }
          }
        }
      }
      
      return false;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Check ability failed: %{public}s', error.message);
      return false;
    }
  }
  
  getSchemeFromUri(uri: string): string {
    try {
      const schemeMatch = uri.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/);
      return schemeMatch ? schemeMatch[1] : '';
    } catch (error) {
      return '';
    }
  }
  
  async launchAlternativeApp(bundleName: string, want: common.Want): Promise<void> {
    try {
      const alternativeWant: common.Want = {
        bundleName: bundleName,
        action: want.action || 'ohos.want.action.viewData',
        uri: want.uri,
        type: want.type,
        parameters: want.parameters
      };
      
      await this.context.startAbility(alternativeWant);
      hilog.info(DOMAIN, TAG, 'Successfully launched alternative app: %{public}s', bundleName);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Launch alternative app failed: %{public}s', error.message);
      throw error;
    }
  }
  
  async launchSystemDefault(want: common.Want): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId = this.context.applicationInfo.accessTokenId;
      
      const permissions = [
        'ohos.permission.READ_MEDIA',
        'ohos.permission.WRITE_MEDIA'
      ];
      
      let hasPermission = true;
      for (const permission of permissions) {
        const grantStatus = await atManager.verifyAccessToken(tokenId, permission);
        if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          hasPermission = false;
          break;
        }
      }
      
      if (hasPermission) {
        const defaultWant: common.Want = {
          action: 'ohos.want.action.viewData',
          uri: want.uri,
          type: want.type
        };
        
        await this.context.startAbility(defaultWant);
        hilog.info(DOMAIN, TAG, 'Successfully launched system default handler');
        
      } else {
        hilog.warn(DOMAIN, TAG, 'Permission denied for media access');
        await this.requestPermissions();
      }
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Launch system default failed: %{public}s', error.message);
      throw error;
    }
  }
  
  async requestPermissions(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Requesting media permissions');
      
      const permissions = [
        'ohos.permission.READ_MEDIA',
        'ohos.permission.WRITE_MEDIA'
      ];
      
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId = this.context.applicationInfo.accessTokenId;
      
      for (const permission of permissions) {
        try {
          await atManager.grantAccessToken(tokenId, permission);
          hilog.info(DOMAIN, TAG, 'Permission granted: %{public}s', permission);
        } catch (error) {
          hilog.warn(DOMAIN, TAG, 'Permission request failed: %{public}s', permission);
        }
      }
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Request permissions failed: %{public}s', error.message);
    }
  }
  
  async showFallbackError(errorMessage: string): Promise<void> {
    hilog.error(DOMAIN, TAG, 'Fallback failed: %{public}s', errorMessage);
    
    const userMessage = '无法打开文件，请安装支持的应用或检查文件权限';
    hilog.error(DOMAIN, TAG, 'User message: %{public}s', userMessage);
  }
}