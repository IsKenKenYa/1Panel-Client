import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct MultiPathQuotaPage {
  @State usedCount: number = 0;
  @State usedDuration: number = 0;
  @State remainingCount: number = 0;
  @State remainingDuration: number = 0;
  @State errorMessage: string = '';
  @State isLoading: boolean = false;

  build() {
    Column({ space: 20 }) {
      Text('多网配额查询')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        Column({ space: 15 }) {
          Row() {
            Text('已使用次数:')
              .fontSize(16)
              .width(120)
            Text(this.usedCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Row() {
            Text('已使用时长:')
              .fontSize(16)
              .width(120)
            Text(this.usedDuration + ' 秒')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Row() {
            Text('剩余次数:')
              .fontSize(16)
              .width(120)
            Text(this.remainingCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.remainingCount <= 0 ? Color.Red : Color.Black)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)

          Row() {
            Text('剩余时长:')
              .fontSize(16)
              .width(120)
            Text(this.remainingDuration + ' 秒')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.remainingDuration <= 0 ? Color.Red : Color.Black)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .width('90%')
        .padding(20)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)

        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor(Color.Red)
            .padding(10)
            .backgroundColor('#FFEBEE')
            .borderRadius(5)
        }

        Button('刷新配额')
          .width('90%')
          .height(45)
          .onClick(() => {
            this.refreshQuota();
          })
          .margin({ top: 20 })

        Button('检查是否可用')
          .width('90%')
          .height(45)
          .onClick(() => {
            this.checkAvailability();
          })
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  refreshQuota(): void {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
      
      this.usedCount = multiquota.used.count;
      this.usedDuration = multiquota.used.duration;
      this.remainingCount = multiquota.remaining.count;
      this.remainingDuration = multiquota.remaining.duration;
      
      console.info('配额信息已更新');
      console.info('已使用次数: ' + this.usedCount);
      console.info('已使用时长: ' + this.usedDuration + '秒');
      console.info('剩余次数: ' + this.remainingCount);
      console.info('剩余时长: ' + this.remainingDuration + '秒');
      
    } catch (err) {
      const businessError = err as BusinessError;
      this.handleQuotaError(businessError.code, businessError.message);
    } finally {
      this.isLoading = false;
    }
  }

  checkAvailability(): void {
    this.errorMessage = '';

    try {
      let multiquota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
      
      if (multiquota.remaining.count <= 0) {
        this.errorMessage = '配额次数已耗尽，请等待24小时后刷新';
        return;
      }
      
      if (multiquota.remaining.duration <= 0) {
        this.errorMessage = '配额时长已耗尽，请等待24小时后刷新';
        return;
      }
      
      this.errorMessage = '';
      AlertDialog.show({
        title: '配额检查结果',
        message: '配额充足，可以发起多网请求\n剩余次数: ' + multiquota.remaining.count + '\n剩余时长: ' + multiquota.remaining.duration + '秒',
        confirm: {
          value: '确定',
          action: () => {}
        }
      });
      
    } catch (err) {
      const businessError = err as BusinessError;
      this.handleQuotaError(businessError.code, businessError.message);
    }
  }

  handleQuotaError(code: number, message: string): void {
    switch (code) {
      case 201:
        this.errorMessage = '权限校验失败，请申请ohos.permission.LINKTURBO权限';
        break;
      case 1013600001:
        this.errorMessage = '内部处理异常，请稍后重试';
        break;
      case 1013600002:
        this.errorMessage = '系统处理异常，请检查网络管理服务';
        break;
      default:
        this.errorMessage = '查询失败: code=' + code + ', message=' + message;
    }
    console.error('配额查询错误: ' + this.errorMessage);
  }
}