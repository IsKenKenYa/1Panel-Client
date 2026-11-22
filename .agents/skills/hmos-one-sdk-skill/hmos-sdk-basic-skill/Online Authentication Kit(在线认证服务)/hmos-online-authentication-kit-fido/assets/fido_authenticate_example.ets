import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';

@Entry
@Component
struct FidoAuthenticateExample {
  private uiContext: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State message: string = 'FIDO Authentication Example';
  @State status: string = 'Ready';
  @State authResult: string = '';

  private async discoverForAuthentication(): Promise<fido.DiscoveryData> {
    try {
      this.status = 'Discovering authenticators...';
      let discoverData: fido.DiscoveryData = await fido.discover(this.uiContext);
      
      console.info('Discovery for authentication succeeded');
      console.info(`Available authenticators: ${discoverData.availableAuthenticators.length}`);
      
      this.status = 'Discovery completed';
      return discoverData;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Discovery failed: ${err.message}`;
      console.error(`Discovery failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }

  private async checkAuthenticationPolicy(authMessage: string): Promise<boolean> {
    let uafMessage: fido.UAFMessage = {
      uafProtocolMessage: authMessage,
      additionalData: ''
    };

    try {
      this.status = 'Checking authentication policy...';
      await fido.checkPolicy(this.uiContext, uafMessage);
      
      console.info('Policy check succeeded. User can authenticate.');
      this.status = 'Policy check passed';
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      if (err.code === 1005900005) {
        console.error('User is not registered. Need to register first.');
        this.status = 'User not registered';
        return false;
      } else {
        this.status = `Policy check failed: ${err.message}`;
        console.error(`Policy check failed. Code: ${err.code}, message: ${err.message}`);
        throw error;
      }
    }
  }

  private async authenticateFido(authMessage: string): Promise<string> {
    let uafAuthMessage: fido.UAFMessage = {
      uafProtocolMessage: authMessage,
      additionalData: '{"navigationButtonText": "使用其他方式验证"}'
    };

    let channelBinding: fido.ChannelBinding = {};

    try {
      this.status = 'Processing authentication...';
      let messageResp: fido.UAFMessage = await fido.processUAFOperation(
        this.uiContext,
        uafAuthMessage,
        channelBinding
      );
      
      console.info('Authentication succeeded');
      console.info(`Response: ${messageResp.uafProtocolMessage}`);
      this.status = 'Authentication completed';
      this.authResult = 'Authenticated successfully';
      
      return messageResp.uafProtocolMessage;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Authentication failed: ${err.message}`;
      this.authResult = 'Authentication failed';
      
      switch (err.code) {
        case 1005900003:
          console.error('User cancelled authentication');
          this.authResult = 'User cancelled';
          break;
        case 1005900005:
          console.error('User is not registered');
          this.authResult = 'Not registered';
          break;
        case 1005900009:
          console.error('Authenticator denied request');
          this.authResult = 'Authenticator denied';
          break;
        case 1005900014:
          console.error('User has not registered biometric features');
          this.authResult = 'No biometrics';
          break;
        case 1005900017:
          console.info('Switched to custom authentication process');
          this.authResult = 'Custom auth';
          break;
        default:
          console.error(`Authentication failed. Code: ${err.code}, message: ${err.message}`);
      }
      
      throw error;
    }
  }

  private async sendAuthResponseToServer(authResponse: string): Promise<void> {
    console.info('Sending authentication response to server:', authResponse);
    this.status = 'Response sent to server';
  }

  private async fetchAuthenticationMessageFromServer(): Promise<string> {
    return JSON.stringify([
      {
        header: {
          upv: { major: 1, minor: 0 },
          op: "Auth",
          appID: "",
          serverData: "test server data"
        },
        challenge: "test challenge",
        policy: {
          accepted: [[{
            aaid: ["001B#1001"],
            keyIDs: ["test keyIDs"],
            authenticationAlgorithms: [1]
          }]]
        }
      }
    ]);
  }

  private async completeFidoAuthentication() {
    try {
      let discoverData = await this.discoverForAuthentication();
      
      let authMessage = await this.fetchAuthenticationMessageFromServer();
      
      let canAuthenticate = await this.checkAuthenticationPolicy(authMessage);
      if (!canAuthenticate) {
        console.error('User needs to register first');
        this.message = 'User needs to register first';
        return;
      }
      
      let authResponse = await this.authenticateFido(authMessage);
      
      await this.sendAuthResponseToServer(authResponse);
      
      console.info('FIDO authentication completed successfully');
      this.message = 'FIDO authentication completed';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Authentication flow failed: ${err.message}`);
      this.message = `Authentication failed: ${err.message}`;
    }
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(this.status)
        .fontSize(16)
        .margin({ bottom: 10 });

      Text(this.authResult)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.authResult === 'Authenticated successfully' ? Color.Green : Color.Red)
        .margin({ bottom: 20 });

      Button('Authenticate with FIDO')
        .fontSize(18)
        .width('80%')
        .onClick(() => this.completeFidoAuthentication());

      Button('Discover Authenticators')
        .fontSize(18)
        .width('80%')
        .margin({ top: 10 })
        .onClick(() => this.discoverForAuthentication());
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}