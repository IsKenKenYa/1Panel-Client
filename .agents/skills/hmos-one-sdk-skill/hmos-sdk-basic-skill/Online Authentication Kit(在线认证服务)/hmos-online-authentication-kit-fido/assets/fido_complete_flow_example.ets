import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';
import { userAuth } from '@kit.UserAuthenticationKit';

enum OperationType {
  REGISTER = 'Register',
  AUTHENTICATE = 'Authenticate',
  DEREGISTER = 'Deregister'
}

@Entry
@Component
struct FidoCompleteFlowExample {
  private uiContext: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State currentOperation: OperationType = OperationType.REGISTER;
  @State message: string = 'FIDO Complete Flow Example';
  @State status: string = 'Ready';
  @State logText: string = '';

  private appendLog(text: string) {
    this.logText += `${new Date().toLocaleTimeString()}: ${text}\n`;
    console.info(text);
  }

  private async checkDeviceSupport(): Promise<boolean> {
    try {
      this.appendLog('Checking device support for ATL4...');
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
      this.appendLog('Device supports ATL4 authentication trust level');
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.appendLog(`Device does not support ATL4: ${err.message}`);
      return false;
    }
  }

  private async discoverAuthenticators(): Promise<fido.DiscoveryData> {
    try {
      this.status = 'Discovering authenticators...';
      let discoverData: fido.DiscoveryData = await fido.discover(this.uiContext);
      
      this.appendLog(`Discovery succeeded. Found ${discoverData.availableAuthenticators.length} authenticators`);
      
      discoverData.availableAuthenticators.forEach((auth, index) => {
        this.appendLog(`  Authenticator ${index + 1}: ${auth.title} (${auth.aaid})`);
      });
      
      this.status = 'Discovery completed';
      return discoverData;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.status = `Discovery failed: ${err.message}`;
      this.appendLog(`Discovery failed: ${err.message}`);
      throw error;
    }
  }

  private async registerFido(): Promise<void> {
    try {
      let discoverData = await this.discoverAuthenticators();
      
      let regMessage = JSON.stringify([
        {
          header: {
            upv: { major: 1, minor: 0 },
            op: "Reg",
            appID: "",
            serverData: "server data"
          },
          challenge: "challenge",
          username: "user",
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

      this.status = 'Checking registration policy...';
      let uafCheckMessage: fido.UAFMessage = {
        uafProtocolMessage: regMessage,
        additionalData: ''
      };
      
      try {
        await fido.checkPolicy(this.uiContext, uafCheckMessage);
        this.appendLog('User is already registered');
        this.status = 'Already registered';
        return;
      } catch (checkError) {
        const checkErr: BusinessError = checkError as BusinessError;
        if (checkErr.code !== 1005900005) {
          throw checkError;
        }
        this.appendLog('User not registered, proceeding with registration');
      }

      this.status = 'Processing registration...';
      let uafRegMessage: fido.UAFMessage = {
        uafProtocolMessage: regMessage,
        additionalData: '{"isGuideToSetBiometrics": true}'
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let regResponse = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
      
      this.appendLog('Registration succeeded');
      this.status = 'Registration completed';

      this.status = 'Notifying registration result...';
      let notifyMessage = JSON.stringify({
        authenticatorsSucceeded: [{
          description: "Success",
          aaid: "001B#1001",
          keyID: "keyID"
        }]
      });
      
      let uafNotifyMessage: fido.UAFMessage = {
        uafProtocolMessage: notifyMessage,
        additionalData: ''
      };
      
      await fido.notifyUAFResult(this.uiContext, uafNotifyMessage);
      this.appendLog('Registration flow completed successfully');
      this.status = 'Registration flow completed';
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.appendLog(`Registration failed: ${err.message}`);
      this.status = `Registration failed: ${err.message}`;
    }
  }

  private async authenticateFido(): Promise<void> {
    try {
      let discoverData = await this.discoverAuthenticators();
      
      let authMessage = JSON.stringify([
        {
          header: {
            upv: { major: 1, minor: 0 },
            op: "Auth",
            appID: "",
            serverData: "server data"
          },
          challenge: "challenge",
          policy: {
            accepted: [[{
              aaid: ["001B#1001"],
              keyIDs: ["keyIDs"],
              authenticationAlgorithms: [1]
            }]]
          }
        }
      ]);

      this.status = 'Checking authentication policy...';
      let uafCheckMessage: fido.UAFMessage = {
        uafProtocolMessage: authMessage,
        additionalData: ''
      };
      
      try {
        await fido.checkPolicy(this.uiContext, uafCheckMessage);
        this.appendLog('User can authenticate');
      } catch (checkError) {
        const checkErr: BusinessError = checkError as BusinessError;
        if (checkErr.code === 1005900005) {
          this.appendLog('User not registered. Need to register first.');
          this.status = 'Not registered';
          return;
        }
        throw checkError;
      }

      this.status = 'Processing authentication...';
      let uafAuthMessage: fido.UAFMessage = {
        uafProtocolMessage: authMessage,
        additionalData: '{"navigationButtonText": "使用其他方式验证"}'
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let authResponse = await fido.processUAFOperation(this.uiContext, uafAuthMessage, channelBinding);
      
      this.appendLog('Authentication succeeded');
      this.status = 'Authentication completed';
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.appendLog(`Authentication failed: ${err.message}`);
      this.status = `Authentication failed: ${err.message}`;
    }
  }

  private async deregisterFido(): Promise<void> {
    try {
      let discoverData = await this.discoverAuthenticators();
      
      let deregMessage = JSON.stringify([
        {
          header: {
            upv: { major: 1, minor: 0 },
            op: "Dereg",
            appID: ""
          },
          authenticators: [{
            aaid: "001B#1001",
            keyID: "keyID"
          }]
        }
      ]);

      this.status = 'Processing deregistration...';
      let uafDeregMessage: fido.UAFMessage = {
        uafProtocolMessage: deregMessage,
        additionalData: ''
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let deregResponse = await fido.processUAFOperation(this.uiContext, uafDeregMessage, channelBinding);
      
      this.appendLog('Deregistration succeeded');
      this.status = 'Deregistration completed';
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      this.appendLog(`Deregistration failed: ${err.message}`);
      this.status = `Deregistration failed: ${err.message}`;
    }
  }

  private async executeOperation() {
    this.logText = '';
    
    let isSupported = await this.checkDeviceSupport();
    if (!isSupported) {
      this.status = 'Device not supported';
      return;
    }

    switch (this.currentOperation) {
      case OperationType.REGISTER:
        await this.registerFido();
        break;
      case OperationType.AUTHENTICATE:
        await this.authenticateFido();
        break;
      case OperationType.DEREGISTER:
        await this.deregisterFido();
        break;
    }
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 });

      Text(`Current Operation: ${this.currentOperation}`)
        .fontSize(18)
        .margin({ bottom: 10 });

      Text(this.status)
        .fontSize(16)
        .fontColor(Color.Blue)
        .margin({ bottom: 10 });

      Row() {
        Button('Register')
          .fontSize(16)
          .width('30%')
          .onClick(() => {
            this.currentOperation = OperationType.REGISTER;
          });

        Button('Authenticate')
          .fontSize(16)
          .width('30%')
          .margin({ left: 5, right: 5 })
          .onClick(() => {
            this.currentOperation = OperationType.AUTHENTICATE;
          });

        Button('Deregister')
          .fontSize(16)
          .width('30%')
          .onClick(() => {
            this.currentOperation = OperationType.DEREGISTER;
          });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Button('Execute Operation')
        .fontSize(18)
        .width('80%')
        .onClick(() => this.executeOperation());

      Scroll() {
        Text(this.logText)
          .fontSize(12)
          .width('100%')
          .padding(10);
      }
      .width('100%')
      .height('40%')
      .margin({ top: 10 });
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}