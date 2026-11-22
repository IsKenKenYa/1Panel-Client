import { shippingAddress } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct ChooseAddressExample {
  @State addressInfo: shippingAddress.AddressInfo | null = null;
  @State message: string = 'Ready to choose address';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .margin(20)

      Button('Choose Shipping Address')
        .fontSize(18)
        .margin(10)
        .onClick(() => {
          this.chooseAddress();
        })

      if (this.addressInfo) {
        Column() {
          Text('Address Information:')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin(10)

          Text(`Name: ${this.addressInfo.userName}`)
            .fontSize(14)
            .margin(5)

          Text(`Mobile: ${this.addressInfo.mobileNumber}`)
            .fontSize(14)
            .margin(5)

          Text(`Country: ${this.addressInfo.countryCode}`)
            .fontSize(14)
            .margin(5)

          Text(`Province: ${this.addressInfo.provinceName}`)
            .fontSize(14)
            .margin(5)

          Text(`City: ${this.addressInfo.cityName}`)
            .fontSize(14)
            .margin(5)

          Text(`District: ${this.addressInfo.districtName}`)
            .fontSize(14)
            .margin(5)

          Text(`Street: ${this.addressInfo.streetName}`)
            .fontSize(14)
            .margin(5)

          Text(`Detail: ${this.addressInfo.detailedAddress}`)
            .fontSize(14)
            .margin(5)

          if (this.addressInfo.telNumber) {
            Text(`Tel: ${this.addressInfo.telNumber}`)
              .fontSize(14)
              .margin(5)
          }

          if (this.addressInfo.zipCode) {
            Text(`Zip: ${this.addressInfo.zipCode}`)
              .fontSize(14)
              .margin(5)
          }
        }
        .margin(20)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }

  private chooseAddress(): void {
    try {
      const context = this.getUIContext().getHostContext();
      
      shippingAddress.chooseAddress(context)
        .then((data: shippingAddress.AddressInfo) => {
          this.addressInfo = data;
          this.message = 'Successfully obtained address';
          hilog.info(0x0000, 'ChooseAddressExample', 'Succeeded in choosing address.');
          hilog.info(0x0000, 'ChooseAddressExample', `User: ${data.userName}, Mobile: ${data.mobileNumber}`);
          hilog.info(0x0000, 'ChooseAddressExample', 
            `Address: ${data.provinceName} ${data.cityName} ${data.districtName} ${data.streetName} ${data.detailedAddress}`);
        })
        .catch((error: BusinessError) => {
          this.message = `Error: ${error.message}`;
          this.addressInfo = null;
          this.handleAddressError(error);
        });
    } catch (error) {
      const businessError = error as BusinessError;
      this.message = `Exception: ${businessError.message}`;
      this.addressInfo = null;
      this.handleAddressError(businessError);
    }
  }

  private handleAddressError(error: BusinessError): void {
    hilog.error(0x0000, 'ChooseAddressExample', 
      `Failed to choose address. Code: ${error.code}, message: ${error.message}`);

    switch (error.code) {
      case 401:
        hilog.error(0x0000, 'ChooseAddressExample', 'Parameter error. Check context parameter.');
        this.message = 'Parameter error occurred';
        break;
      case 1008100001:
        hilog.error(0x0000, 'ChooseAddressExample', 'Internal error. Please retry or restart device.');
        this.message = 'Internal error. Please retry.';
        break;
      case 1008100002:
        hilog.error(0x0000, 'ChooseAddressExample', 'Network unavailable. Check network connection.');
        this.message = 'Network unavailable. Check connection.';
        break;
      case 1008100003:
        hilog.error(0x0000, 'ChooseAddressExample', 'User not logged in. Please login Huawei ID first.');
        this.message = 'Please login Huawei ID first.';
        break;
      case 1008100004:
        hilog.error(0x0000, 'ChooseAddressExample', 
          'Fingerprint check failed. Check client_id and fingerprint configuration.');
        this.message = 'Configuration error. Please check app settings.';
        break;
      case 1008100005:
        hilog.error(0x0000, 'ChooseAddressExample', 'Permission not applied. Please apply for permission first.');
        this.message = 'Permission not applied. Please contact developer.';
        break;
      case 1008100006:
        hilog.info(0x0000, 'ChooseAddressExample', 'User canceled operation.');
        this.message = 'You canceled the operation.';
        break;
      case 1008100007:
        hilog.error(0x0000, 'ChooseAddressExample', 'Account not supported. Please use China mainland account.');
        this.message = 'Your account does not support this feature.';
        break;
      default:
        hilog.error(0x0000, 'ChooseAddressExample', 'Unknown error occurred.');
        this.message = 'Unknown error occurred.';
    }
  }
}