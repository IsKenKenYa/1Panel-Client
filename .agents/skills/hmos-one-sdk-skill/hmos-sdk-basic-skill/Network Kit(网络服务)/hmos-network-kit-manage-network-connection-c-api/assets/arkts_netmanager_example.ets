import testNetManager from 'libentry.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

enum ReturnCode {
    SUCCESS = 0,
    MISSING_PERMISSION = 201,
    PARAMETER_ERROR = 401,
    OPERATION_FAILED = 2100002,
    INTERNAL_ERROR = 2100003
}

@Entry
@Component
struct NetManagerExample {
    @State message: string = 'Network Manager Example';
    @State netId: number = -1;
    @State hasDefaultNet: number = -1;
    @State isMetered: number = -1;

    build() {
        Column() {
            Text(this.message)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 20 })

            Text(`NetId: ${this.netId}`)
                .fontSize(16)
                .margin({ bottom: 10 })

            Text(`HasDefaultNet: ${this.hasDefaultNet}`)
                .fontSize(16)
                .margin({ bottom: 10 })

            Text(`IsMetered: ${this.isMetered}`)
                .fontSize(16)
                .margin({ bottom: 20 })

            Button('Get Default NetId')
                .width('80%')
                .onClick(() => {
                    this.getDefaultNetId();
                })
                .margin({ bottom: 10 })

            Button('Has Default Net')
                .width('80%')
                .onClick(() => {
                    this.hasDefaultNetTest();
                })
                .margin({ bottom: 10 })

            Button('Is Default Net Metered')
                .width('80%')
                .onClick(() => {
                    this.isDefaultNetMeteredTest();
                })
                .margin({ bottom: 10 })

            Button('Test Error Codes')
                .width('80%')
                .onClick(() => {
                    this.testErrorCodes();
                })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
    }

    getDefaultNetId() {
        let netId = testNetManager.NetId();
        if (netId <= 0) {
            hilog.error(0x0000, 'NetManager', 'Failed to get netId');
            this.netId = -1;
            this.message = 'Failed to get default netId';
        } else {
            hilog.info(0x0000, 'NetManager', 'Default netId: %{public}d', netId);
            this.netId = netId;
            this.message = `Default netId: ${netId}`;
        }
    }

    hasDefaultNetTest() {
        let hasDefaultNet = testNetManager.HasDefaultNet();
        if (hasDefaultNet == 1) {
            hilog.info(0x0000, 'NetManager', 'Device has default network');
            this.hasDefaultNet = 1;
            this.message = 'Device has default network';
        } else if (hasDefaultNet == 0) {
            hilog.warn(0x0000, 'NetManager', 'Device has no default network');
            this.hasDefaultNet = 0;
            this.message = 'Device has no default network';
        } else {
            hilog.error(0x0000, 'NetManager', 'HasDefaultNet check failed: %{public}d', hasDefaultNet);
            this.hasDefaultNet = -1;
            this.message = `Error: ${this.handleErrorCode(hasDefaultNet)}`;
        }
    }

    isDefaultNetMeteredTest() {
        let isMetered = testNetManager.IsDefaultNetMetered();
        if (isMetered >= 0) {
            hilog.info(0x0000, 'NetManager', 'Is metered: %{public}d', isMetered);
            this.isMetered = isMetered;
            this.message = `Is metered: ${isMetered}`;
        } else {
            hilog.error(0x0000, 'NetManager', 'IsDefaultNetMetered failed: %{public}d', isMetered);
            this.isMetered = -1;
            this.message = `Error: ${this.handleErrorCode(isMetered)}`;
        }
    }

    testErrorCodes() {
        let testParam = 0;
        let codeNumber = testNetManager.GetDefaultNet(testParam);
        
        let errorMsg = this.handleErrorCode(codeNumber);
        hilog.info(0x0000, 'NetManager', 'Test result: %{public}s', errorMsg);
        this.message = errorMsg;
    }

    handleErrorCode(code: number): string {
        switch (code) {
            case ReturnCode.SUCCESS:
                return 'Operation successful';
            case ReturnCode.MISSING_PERMISSION:
                return 'Missing permission (201): Need ohos.permission.GET_NETWORK_INFO';
            case ReturnCode.PARAMETER_ERROR:
                return 'Parameter error (401): Check parameter validity';
            case ReturnCode.OPERATION_FAILED:
                return 'Operation failed (2100002): Cannot connect to service';
            case ReturnCode.INTERNAL_ERROR:
                return 'Internal error (2100003): System error';
            default:
                return `Unknown error code: ${code}`;
        }
    }
}