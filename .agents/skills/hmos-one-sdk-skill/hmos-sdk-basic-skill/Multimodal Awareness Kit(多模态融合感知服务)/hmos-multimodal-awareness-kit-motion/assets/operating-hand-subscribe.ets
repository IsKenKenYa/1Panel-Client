import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct OperatingHandSubscribePage {
  @State operatingHandStatus: string = '未订阅';
  @State isSubscribed: boolean = false;
  private operatingHandCallback: Callback<motion.OperatingHandStatus> | null = null;

  aboutToAppear() {
    this.operatingHandCallback = (data: motion.OperatingHandStatus) => {
      let statusDesc: string = '';
      switch (data) {
        case motion.OperatingHandStatus.UNKNOWN_STATUS:
          statusDesc = '未识别';
          break;
        case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
          statusDesc = '左手操作';
          break;
        case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
          statusDesc = '右手操作';
          break;
        default:
          statusDesc = '未知';
      }
      this.operatingHandStatus = statusDesc;
      console.info(`操作手状态变化: ${statusDesc}`);
    };
  }

  subscribeOperatingHand() {
    try {
      motion.on('operatingHandChanged', this.operatingHandCallback!);
      this.isSubscribed = true;
      this.operatingHandStatus = '已订阅，等待检测...';
      console.info('订阅操作手状态成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
      
      switch (error.code) {
        case 201:
          this.operatingHandStatus = '权限不足';
          break;
        case 801:
          this.operatingHandStatus = '设备不支持';
          break;
        case 31500001:
          this.operatingHandStatus = '服务异常';
          break;
        case 31500002:
          this.operatingHandStatus = '订阅失败';
          break;
        default:
          this.operatingHandStatus = `错误: ${error.code}`;
      }
    }
  }

  unsubscribeOperatingHand() {
    try {
      motion.off('operatingHandChanged');
      this.isSubscribed = false;
      this.operatingHandStatus = '未订阅';
      console.info('取消订阅操作手状态成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`取消订阅失败，错误码: ${error.code}`);
    }
  }

  getLatestStatus() {
    try {
      let status: motion.OperatingHandStatus = motion.getRecentOperatingHandStatus();
      let statusDesc: string = '';
      switch (status) {
        case motion.OperatingHandStatus.UNKNOWN_STATUS:
          statusDesc = '未识别';
          break;
        case motion.OperatingHandStatus.LEFT_HAND_OPERATED:
          statusDesc = '左手操作';
          break;
        case motion.OperatingHandStatus.RIGHT_HAND_OPERATED:
          statusDesc = '右手操作';
          break;
      }
      this.operatingHandStatus = statusDesc;
      console.info(`当前操作手状态: ${statusDesc}`);
    } catch (err) {
      let error = err as BusinessError;
      console.error(`获取状态失败，错误码: ${error.code}`);
    }
  }

  build() {
    Column() {
      Text('操作手状态订阅示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`当前状态: ${this.operatingHandStatus}`)
        .fontSize(18)
        .margin({ bottom: 20 });

      Button(this.isSubscribed ? '取消订阅' : '订阅操作手状态')
        .width('80%')
        .onClick(() => {
          if (this.isSubscribed) {
            this.unsubscribeOperatingHand();
          } else {
            this.subscribeOperatingHand();
          }
        })
        .margin({ bottom: 10 });

      Button('获取最新状态')
        .width('80%')
        .onClick(() => {
          this.getLatestStatus();
        })
        .margin({ bottom: 10 });

      Text('说明:')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text('1. 点击订阅按钮开始监听操作手状态变化')
        .fontSize(14)
        .margin({ top: 5 });

      Text('2. 在屏幕上进行操作，系统会自动识别操作手')
        .fontSize(14)
        .margin({ top: 5 });

      Text('3. 点击获取最新状态按钮，主动查询当前状态')
        .fontSize(14)
        .margin({ top: 5 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}