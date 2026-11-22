import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';

@Entry
@Component
struct FidoDeregisterExample {
  private uiContext: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State message: string = 'FIDO Deregistration Example';
  @State status: string = 'Ready';

  private async discoverForDeregistration(): Promise<fido.DiscoveryData> {
    try {
      this.status = 'Discovering authenticators...';
      let discoverData: fido.DiscoveryData = await fido.discover(this.uiContext);
      
      console.info('Discovery for deregistration succeeded');
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

  private async deregisterFido(deregMessage: string): Promise<string> {
    let uafDeregMessage: fido.UAFMessage = {
      uafProtocolMessage: deregMessage,
      additionalData: ''
    };

    let channelBinding: fido.ChannelBinding = {};

    try {
      this.status = 'Processing deregistration...';
      let messageResp: fido.UAFMessage = await fido.processUAFOperation(
        this.uiContext,
        uafDeregMessage,
        channelBinding
      );
      
      console.info('Deregistration succeeded');
      console.info(`Response: ${messageResp.uafProtocolMessage}`);
      this.status = 'Deregistration completed';
      
      return messageResp.uafProtocolMessage;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Deregistration failed: ${err.message}`;
      
      switch (err.code) {
        case 1005900003:
          console.error('User cancelled deregistration');
          break;
        case 1005900005:
          console.error('No authenticator available');
          break;
        case 1005900006:
          console.error('UAF protocol error');
          break;
        case 1005900007:
          console.error('FacetID not registered');
          break;
        default:
          console.error(`Deregistration failed. Code: ${err.code}, message: ${err.message}`);
      }
      
      throw error;
    }
  }

  private async sendDeregResponseToServer(deregResponse: string): Promise<void> {
    console.info('Sending deregistration response to server:', deregResponse);
    this.status = 'Response sent to server';
  }

  private async fetchDeregistrationMessageFromServer(): Promise<string> {
    return JSON.stringify([
      {
        header: {
          upv: { major: 1, minor: 0 },
          op: "Dereg",
          appID: ""
        },
        authenticators: [{
          aaid: "001B#1001",
          keyID: "test keyID"
        }]
      }
    ]);
  }

  private async completeFidoDeregistration() {
    try {
      let discoverData = await this.discoverForDeregistration();
      
      let deregMessage = await this.fetchDeregistrationMessageFromServer();
      
      let deregResponse = await this.deregisterFido(deregMessage);
      
      await this.sendDeregResponseToServer(deregResponse);
      
      console.info('FIDO deregistration completed successfully');
      this.message = 'FIDO deregistration completed';
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Deregistration flow failed: ${err.message}`);
      this.message = `Deregistration failed: ${err.message}`;
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

      Button('Deregister FIDO')
        .fontSize(18)
        .width('80%')
        .onClick(() => this.completeFidoDeregistration());

      Button('Discover Authenticators')
        .fontSize(18)
        .width('80%')
        .margin({ top: 10 })
        .onClick(() => this.discoverForDeregistration());
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}