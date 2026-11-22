import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct HoldingHandSubscribePage {
  @State holdingHandStatus: string = '未订阅';
  @State isSubscribed: boolean = false;
  private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;

  aboutToAppear() {
    this.holdingHandCallback = (data: motion.HoldingHandStatus) => {
      let statusDesc: string = '';
      switch (data) {
        case motion.HoldingHandStatus.NOT_HELD:
          statusDesc = '未握持';
          break;
        case motion.HoldingHandStatus.LEFT_HAND_HELD:
          statusDesc = '左手握持';
          break;
        case motion.HoldingHandStatus.RIGHT_HAND_HELD:
          statusDesc = '右手握持';
          break;
        case motion.HoldingHandStatus.BOTH_HANDS_HELD:
          statusDesc = '双手握持';
          break;
        case motion.HoldingHandStatus.UNKNOWN_STATUS:
          statusDesc = '未识别';
          break;
        default:
          statusDesc = '未知';
      }
      this.holdingHandStatus = statusDesc;
      console.info(`握持手状态变化: ${statusDesc}`);
    };
  }

  subscribeHoldingHand() {
    try {
      motion.on('holdingHandChanged', this.holdingHandCallback!);
      this.isSubscribed = true;
      this.holdingHandStatus = '已订阅，等待检测...';
      console.info('订阅握持手状态成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
      
      switch (error.code) {
        case 201:
          this.holdingHandStatus = '权限不足';
          break;
        case 801:
          this.holdingHandStatus = '设备不支持';
          break;
        case 31500001:
          this.holdingHandStatus = '服务异常';
          break;
        case 31500002:
          this.holdingHandStatus = '订阅失败';
          break;
        default:
          this.holdingHandStatus = `错误: ${error.code}`;
      }
    }
  }

  unsubscribeHoldingHand() {
    try {
      motion.off('holdingHandChanged');
      this.isSubscribed = false;
      this.holdingHandStatus = '未订阅';
      console.info('取消订阅握持手状态成功');
    } catch (err) {
      let error = err as BusinessError;
      console.error(`取消订阅失败，错误码: ${error.code}`);
    }
  }

  build() {
    Column() {
      Text('握持手状态订阅示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`当前状态: ${this.holdingHandStatus}`)
        .fontSize(18)
        .margin({ bottom: 20 });

      Button(this.isSubscribed ? '取消订阅' : '订阅握持手状态')
        .width('80%')
        .onClick(() => {
          if (this.isSubscribed) {
            this.unsubscribeHoldingHand();
          } else {
            this.subscribeHoldingHand();
          }
        })
        .margin({ bottom: 10 });

      Text('说明:')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      Text('1. 点击订阅按钮开始监听握持手状态变化')
        .fontSize(14)
        .margin({ top: 5 });

      Text('2. 握持设备，系统会自动识别握持姿态')
        .fontSize(14)
        .margin({ top: 5 });

      Text('3. 要求：')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10 });

      Text('- 设备亮屏且解锁')
        .fontSize(13)
        .margin({ top: 3 });

      Text('- 保护壳厚度不超过3mm')
        .fontSize(13)
        .margin({ top: 3 });

      Text('- 五指自然握持，掌心接触设备')
        .fontSize(13)
        .margin({ top: 3 });

      Text('- 屏幕朝向握持人')
        .fontSize(13)
        .margin({ top: 3 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}