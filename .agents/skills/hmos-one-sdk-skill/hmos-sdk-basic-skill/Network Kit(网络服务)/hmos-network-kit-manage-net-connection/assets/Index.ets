import testNetManager from 'libentry.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

enum ReturnCode {
  SUCCESS = 0,
  MISSING_PERMISSION = 201,
  PARAMETER_ERROR = 401,
  SERVICE_UNAVAILABLE = 2100002,
  INTERNAL_ERROR = 2100003
}

@Entry
@Component
struct Index {
  @State message: string = 'Network Manager Demo';
  @State networkInfo: string = '';
  @State netId: number = -1;
  @State resultCode: number = -1;

  build() {
    Column() {
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(this.networkInfo)
        .fontSize(16)
        .fontColor(Color.Black)
        .margin({ bottom: 20 })
        .width('90%')
        .textAlign(TextAlign.Start)

      Button('Check Network')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          this.checkNetwork();
        })

      Button('Get Default Net ID')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          this.getDefaultNetId();
        })

      Button('Test Code Number')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          this.testCodeNumber();
        })

      Button('Get Full Info')
        .width('80%')
        .margin({ bottom: 10 })
        .onClick(() => {
          this.getFullNetworkInfo();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  checkNetwork(): void {
    try {
      const hasDefaultNet: number = testNetManager.HasDefaultNet();
      
      if (hasDefaultNet === -1) {
        this.networkInfo = 'Failed to check network status';
        hilog.error(0x0000, 'NetworkTest', 'Check network failed');
        return;
      }
      
      this.networkInfo = `Network Status: ${hasDefaultNet === 1 ? 'Connected' : 'Disconnected'}`;
      hilog.info(0x0000, 'NetworkTest', `Has default network: ${hasDefaultNet}`);
    } catch (error) {
      this.networkInfo = `Exception: ${error}`;
      hilog.error(0x0000, 'NetworkTest', `Exception: ${error}`);
    }
  }

  getDefaultNetId(): void {
    try {
      this.netId = testNetManager.GetNetId();
      
      if (this.netId === -1) {
        this.networkInfo = 'Failed to get default network ID';
        hilog.error(0x0000, 'NetworkTest', 'Get net ID failed');
        return;
      }
      
      this.networkInfo = `Default Network ID: ${this.netId}`;
      hilog.info(0x0000, 'NetworkTest', `Default net ID: ${this.netId}`);
    } catch (error) {
      this.networkInfo = `Exception: ${error}`;
      hilog.error(0x0000, 'NetworkTest', `Exception: ${error}`);
    }
  }

  testCodeNumber(): void {
    try {
      const testParam: number = 1;
      this.resultCode = testNetManager.GetDefaultNet(testParam);
      
      let resultMessage: string = '';
      
      switch (this.resultCode) {
        case ReturnCode.SUCCESS:
          resultMessage = 'Test success (code 0)';
          hilog.info(0x0000, 'NetworkTest', 'Test success');
          break;
        case ReturnCode.MISSING_PERMISSION:
          resultMessage = 'Missing permissions (code 201)';
          hilog.warn(0x0000, 'NetworkTest', 'Missing permissions');
          break;
        case ReturnCode.PARAMETER_ERROR:
          resultMessage = 'Parameter error (code 401)';
          hilog.warn(0x0000, 'NetworkTest', 'Parameter error');
          break;
        case ReturnCode.SERVICE_UNAVAILABLE:
          resultMessage = 'Service unavailable (code 2100002)';
          hilog.error(0x0000, 'NetworkTest', 'Service unavailable');
          break;
        case ReturnCode.INTERNAL_ERROR:
          resultMessage = 'Internal error (code 2100003)';
          hilog.error(0x0000, 'NetworkTest', 'Internal error');
          break;
        default:
          resultMessage = `Unexpected result (code ${this.resultCode})`;
          hilog.error(0x0000, 'NetworkTest', `Unexpected result: ${this.resultCode}`);
          break;
      }
      
      this.networkInfo = resultMessage;
    } catch (error) {
      this.networkInfo = `Exception: ${error}`;
      hilog.error(0x0000, 'NetworkTest', `Exception: ${error}`);
    }
  }

  getFullNetworkInfo(): void {
    try {
      let info: string = '=== Network Information ===\n';
      
      const hasDefaultNet: number = testNetManager.HasDefaultNet();
      info += `Has Default Network: ${hasDefaultNet === 1 ? 'Yes' : hasDefaultNet === 0 ? 'No' : 'Error'}\n`;
      
      if (hasDefaultNet === 1) {
        const netId: number = testNetManager.GetNetId();
        info += `Default Network ID: ${netId > 0 ? netId : 'Not available'}\n`;
        
        const isMetered: number = testNetManager.IsMetered();
        info += `Is Metered: ${isMetered === 1 ? 'Yes' : isMetered === 0 ? 'No' : 'Unknown'}\n`;
      }
      
      const netCount: number = testNetManager.GetAllNetsCount();
      info += `Active Networks: ${netCount >= 0 ? netCount : 'Unknown'}\n`;
      
      this.networkInfo = info;
      hilog.info(0x0000, 'NetworkTest', 'Full network info retrieved');
    } catch (error) {
      this.networkInfo = `Exception: ${error}`;
      hilog.error(0x0000, 'NetworkTest', `Exception: ${error}`);
    }
  }
}