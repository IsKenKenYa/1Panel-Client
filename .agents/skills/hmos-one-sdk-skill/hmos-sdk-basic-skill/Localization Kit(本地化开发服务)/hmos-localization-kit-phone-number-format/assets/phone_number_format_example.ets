import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct PhoneNumberFormatExample {
  @State formattedNumber: string = '';
  @State isValidNumber: boolean = false;
  @State locationName: string = '';
  @State inputNumber: string = '158****2312';
  @State selectedCountry: string = 'CN';
  @State selectedType: string = 'NATIONAL';
  @State selectedLocale: string = 'zh-CN';

  build() {
    Column({ space: 20 }) {
      Text('电话号码格式化示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      // 输入区域
      TextInput({ placeholder: '请输入电话号码', text: this.inputNumber })
        .width('80%')
        .onChange((value: string) => {
          this.inputNumber = value;
        });

      // 国家代码选择
      Row({ space: 10 }) {
        Text('国家代码:');
        TextInput({ text: this.selectedCountry })
          .width(100)
          .onChange((value: string) => {
            this.selectedCountry = value;
          });
      };

      // 格式化类型选择
      Row({ space: 10 }) {
        Text('格式化类型:');
        Select([
          { value: 'E164' },
          { value: 'INTERNATIONAL' },
          { value: 'NATIONAL' },
          { value: 'RFC3966' },
          { value: 'TYPING' }
        ])
          .selected(this.selectedType === 'E164' ? 0 : 
                   this.selectedType === 'INTERNATIONAL' ? 1 : 
                   this.selectedType === 'NATIONAL' ? 2 : 
                   this.selectedType === 'RFC3966' ? 3 : 4)
          .onSelect((index: number) => {
            this.selectedType = index === 0 ? 'E164' : 
                                index === 1 ? 'INTERNATIONAL' : 
                                index === 2 ? 'NATIONAL' : 
                                index === 3 ? 'RFC3966' : 'TYPING';
          });
      };

      // 操作按钮
      Row({ space: 10 }) {
        Button('格式化')
          .onClick(() => {
            this.formatPhoneNumber();
          });

        Button('验证')
          .onClick(() => {
            this.validatePhoneNumber();
          });

        Button('获取归属地')
          .onClick(() => {
            this.getLocationName();
          });
      };

      // 结果显示区域
      Column({ space: 10 }) {
        Text('格式化结果:')
          .fontSize(16);
        Text(this.formattedNumber || '未格式化')
          .fontSize(18)
          .fontWeight(FontWeight.Medium);

        Text('号码有效性:')
          .fontSize(16);
        Text(this.isValidNumber ? '有效' : '无效')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isValidNumber ? Color.Green : Color.Red);

        Text('号码归属地:')
          .fontSize(16);
        Text(this.locationName || '未知')
          .fontSize(18)
          .fontWeight(FontWeight.Medium);
      }
      .margin({ top: 20 });

      // 完整示例按钮
      Button('运行完整示例')
        .width('80%')
        .onClick(() => {
          this.runCompleteExample();
        });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  private formatPhoneNumber(): void {
    try {
      let options: i18n.PhoneNumberFormatOptions = { type: this.selectedType };
      let formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat(this.selectedCountry, options);
      this.formattedNumber = formatter.format(this.inputNumber);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`格式化失败: ${err.message}`);
      this.formattedNumber = '格式化失败: ' + err.message;
    }
  }

  private validatePhoneNumber(): void {
    try {
      let formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat(this.selectedCountry);
      this.isValidNumber = formatter.isValidNumber(this.inputNumber);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`验证失败: ${err.message}`);
      this.isValidNumber = false;
    }
  }

  private getLocationName(): void {
    try {
      let formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat(this.selectedCountry);
      this.locationName = formatter.getLocationName(this.inputNumber, this.selectedLocale);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`获取归属地失败: ${err.message}`);
      this.locationName = '获取失败';
    }
  }

  private runCompleteExample(): void {
    console.log('===== 电话号码格式化完整示例 =====');
    
    try {
      // 1. 创建不同类型的格式化对象
      let phoneNumber: string = '158****2312';
      
      // E164格式
      let e164Formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'E164' });
      let e164Number: string = e164Formatter.format(phoneNumber);
      console.log(`E164格式: ${e164Number}`); // +86 158****2312
      
      // INTERNATIONAL格式
      let internationalFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'INTERNATIONAL' });
      let internationalNumber: string = internationalFormatter.format(phoneNumber);
      console.log(`INTERNATIONAL格式: ${internationalNumber}`); // +86 158 **** 2312
      
      // NATIONAL格式
      let nationalFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'NATIONAL' });
      let nationalNumber: string = nationalFormatter.format(phoneNumber);
      console.log(`NATIONAL格式: ${nationalNumber}`); // 158 **** 2312
      
      // RFC3966格式
      let rfc3966Formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'RFC3966' });
      let rfc3966Number: string = rfc3966Formatter.format(phoneNumber);
      console.log(`RFC3966格式: ${rfc3966Number}`); // tel:+86-158-****-2312
      
      // 2. 判断号码有效性
      let formatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN');
      let isValid: boolean = formatter.isValidNumber(phoneNumber);
      console.log(`号码有效性: ${isValid}`); // true
      
      // 3. 获取号码归属地
      let location: string = formatter.getLocationName(phoneNumber, 'zh-CN');
      console.log(`号码归属地: ${location}`); // 陕西省西安市
      
      // 4. 拨号中的实时格式化（TYPING）
      let typingFormatter: i18n.PhoneNumberFormat = new i18n.PhoneNumberFormat('CN', { type: 'TYPING' });
      let inputNumber: string = '0755453';
      let formatResult: string = '';
      for (let i = 0; i < inputNumber.length; i++) {
        formatResult += inputNumber.charAt(i);
        formatResult = typingFormatter.format(formatResult);
      }
      console.log(`拨号实时格式化: ${formatResult}`); // 0755 453
      
      // 5. 国际号码归属地查询
      let internationalPhoneNumber: string = '0039312****789';
      let internationalLocation: string = formatter.getLocationName(internationalPhoneNumber, 'zh-CN');
      console.log(`国际号码归属地: ${internationalLocation}`); // 意大利
      
      console.log('===== 示例执行完成 =====');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`示例执行失败: ${err.code}, ${err.message}`);
    }
  }
}