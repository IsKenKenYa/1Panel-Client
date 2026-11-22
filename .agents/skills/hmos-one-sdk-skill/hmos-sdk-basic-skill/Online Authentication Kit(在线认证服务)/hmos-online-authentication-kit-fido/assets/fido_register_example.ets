import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';

@Entry
@Component
struct FidoRegisterExample {
  private uiContext: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State message: string = 'FIDO Registration Example';
  @State status: string = 'Ready';

  private async discoverAuthenticators(): Promise<fido.DiscoveryData> {
    try {
      this.status = 'Discovering authenticators...';
      let discoverData: fido.DiscoveryData = await fido.discover(this.uiContext);
      
      console.info('Discovery succeeded');
      console.info(`Supported UAF versions: ${JSON.stringify(discoverData.supportedUAFVersions)}`);
      console.info(`Client vendor: ${discoverData.clientVendor}`);
      console.info(`Available authenticators: ${discoverData.availableAuthenticators.length}`);
      
      discoverData.availableAuthenticators.forEach((authenticator, index) => {
        console.info(`Authenticator ${index + 1}:`);
        console.info(`  Title: ${authenticator.title}`);
        console.info(`  AAID: ${authenticator.aaid}`);
        console.info(`  Description: ${authenticator.description}`);
        console.info(`  User verification: ${authenticator.userVerification}`);
      });
      
      this.status = 'Discovery completed';
      return discoverData;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Discovery failed: ${err.message}`;
      console.error(`Discovery failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }

  private async checkRegistrationPolicy(regMessage: string): Promise<boolean> {
    let uafMessage: fido.UAFMessage = {
      uafProtocolMessage: regMessage,
      additionalData: ''
    };

    try {
      this.status = 'Checking registration policy...';
      await fido.checkPolicy(this.uiContext, uafMessage);
      
      console.info('Policy check succeeded. User is already registered.');
      this.status = 'Already registered';
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      
      if (err.code === 1005900005) {
        console.info('User is not registered. Proceeding with registration.');
        this.status = 'Not registered, proceed';
        return false;
      } else {
        this.status = `Policy check failed: ${err.message}`;
        console.error(`Policy check failed. Code: ${err.code}, message: ${err.message}`);
        throw error;
      }
    }
  }

  private async registerFido(regMessage: string): Promise<string> {
    let uafRegMessage: fido.UAFMessage = {
      uafProtocolMessage: regMessage,
      additionalData: '{"isGuideToSetBiometrics": true}'
    };

    let channelBinding: fido.ChannelBinding = {};

    try {
      this.status = 'Processing registration...';
      let messageResp: fido.UAFMessage = await fido.processUAFOperation(
        this.uiContext,
        uafRegMessage,
        channelBinding
      );
      
      console.info('Registration succeeded');
      console.info(`Response: ${messageResp.uafProtocolMessage}`);
      this.status = 'Registration completed';
      
      return messageResp.uafProtocolMessage;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Registration failed: ${err.message}`;
      
      switch (err.code) {
        case 1005900003:
          console.error('User cancelled registration');
          break;
        case 1005900005:
          console.error('No authenticator available');
          break;
        case 1005900007:
          console.error('FacetID not registered. Check application signature.');
          break;
        case 1005900014:
          console.error('User has not registered biometric features');
          break;
        case 1005900017:
          console.info('Switched to custom authentication process');
          break;
        default:
          console.error(`Registration failed. Code: ${err.code}, message: ${err.message}`);
      }
      
      throw error;
    }
  }

  private async notifyRegistrationResult(notifyMessage: string): Promise<void> {
    let uafMessage: fido.UAFMessage = {
      uafProtocolMessage: notifyMessage,
      additionalData: ''
    };

    try {
      this.status = 'Notifying registration result...';
      await fido.notifyUAFResult(this.uiContext, uafMessage);
      
      console.info('Registration result notification succeeded');
      this.status = 'Registration flow completed';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Notification failed: ${err.message}`;
      console.error(`Notification failed. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }

  private async fetchRegistrationMessageFromServer(discoverData: fido.DiscoveryData): Promise<string> {
    return JSON.stringify([
      {
        header: {
          upv: { major: 1, minor: 0 },
          op: "Reg",
          appID: "",
          serverData: "test server data"
        },
        challenge: "test challenge",
        username: "test user name",
        policy: {
          accepted: [[{
            aaid: ["001B#1001"],
            attachmentHint: 1,
            authenticationAlgorithms: [1],
            authenticatorVersion: 1
          }]]
        }
      }
    ]);
  }

  private async sendRegResponseToServer(regResponse: string): Promise<string> {
    console.info('Sending registration response to server:', regResponse);
    
    return JSON.stringify({
      authenticatorsSucceeded: [{
        description: "Attention completed successfully.",
        aaid: "001B#1001",
        keyID: "test keyID"
      }]
    });
  }

  private async completeFidoRegistration() {
    try {
      let discoverData = await this.discoverAuthenticators();
      
      let regMessage = await this.fetchRegistrationMessageFromServer(discoverData);
      
      let isRegistered = await this.checkRegistrationPolicy(regMessage);
      if (isRegistered) {
        console.info('Already registered. No need to register again.');
        this.message = 'User is already registered';
        return;
      }
      
      let regResponse = await this.registerFido(regMessage);
      
      let notifyMessage = await this.sendRegResponseToServer(regResponse);
      
      await this.notifyRegistrationResult(notifyMessage);
      
      console.info('FIDO registration completed successfully');
      this.message = 'FIDO registration completed';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Registration flow failed: ${err.message}`);
      this.message = `Registration failed: ${err.message}`;
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
        .margin({ bottom: 20 });

      Button('Register FIDO')
        .fontSize(18)
        .width('80%')
        .onClick(() => this.completeFidoRegistration());

      Button('Discover Authenticators')
        .fontSize(18)
        .width('80%')
        .margin({ top: 10 })
        .onClick(() => this.discoverAuthenticators());
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}