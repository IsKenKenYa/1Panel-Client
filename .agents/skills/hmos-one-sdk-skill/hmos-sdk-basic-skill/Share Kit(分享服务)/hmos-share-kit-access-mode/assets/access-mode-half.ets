// 半接模式实现示例
// 自定义分享面板并提供系统分享入口

import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct HalfAccessModeExample {
  private shareData: systemShare.SharedData | null = null;
  private controller: systemShare.ShareController | null = null;

  build() {
    Column() {
      // 标题
      Text('自定义分享面板')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // 自定义分享方式列表
      Column() {
        // 自定义分享方式1：微信分享
        Row() {
          Image($r('app.media.wechat_icon'))
            .width(48)
            .height(48)
          
          Text('分享到微信')
            .fontSize(18)
            .margin({ left: 12 })
        }
        .width('80%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.shareToWechat();
        })

        // 自定义分享方式2：QQ分享
        Row() {
          Image($r('app.media.qq_icon'))
            .width(48)
            .height(48)
          
          Text('分享到QQ')
            .fontSize(18)
            .margin({ left: 12 })
        }
        .width('80%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.shareToQQ();
        })

        // 自定义分享方式3：微博分享
        Row() {
          Image($r('app.media.weibo_icon'))
            .width(48)
            .height(48)
          
          Text('分享到微博')
            .fontSize(18)
            .margin({ left: 12 })
        }
        .width('80%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.shareToWeibo();
        })

        // 系统分享入口（必须使用系统标准图标和文本）
        Row() {
          // 分享图标使用系统提供的Symbol格式图标
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize(48)
            .fontColor([Color.Blue])
          
          // 文本使用'系统分享'
          Text('系统分享')
            .fontSize(18)
            .margin({ left: 12 })
        }
        .width('80%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .onClick(() => {
          this.invokeSystemShare();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // 自定义分享方式1：微信分享
  private shareToWechat() {
    console.info('分享到微信');
    // TODO: 实现微信分享逻辑
  }

  // 自定义分享方式2：QQ分享
  private shareToQQ() {
    console.info('分享到QQ');
    // TODO: 实现QQ分享逻辑
  }

  // 自定义分享方式3：微博分享
  private shareToWeibo() {
    console.info('分享到微博');
    // TODO: 实现微博分享逻辑
  }

  // 调用系统分享面板（必须使用系统标准图标和文本）
  private invokeSystemShare() {
    // 构造分享数据
    this.shareData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Hello HarmonyOS',
      title: '系统分享文本'
    });

    // 创建分享控制器
    this.controller = new systemShare.ShareController(this.shareData);

    // 获取UIAbility上下文
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    // 注册面板关闭监听
    this.controller.on('dismiss', () => {
      console.info('System share panel closed');
      // 系统分享结束，可处理其他业务
    });

    // 注册分享完成监听（可选）
    this.controller.on('shareCompleted', (result: systemShare.ShareOperationResult) => {
      console.info('Share completed to:', result.targetAbilityInfo.name);
      // 记录分享统计数据
    });

    // 显示系统分享面板
    this.controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    }).then(() => {
      console.info('System share panel shown successfully.');
    }).catch((error: BusinessError) => {
      console.error(`Failed to show system share panel. code: ${error.code}, message: ${error.message}`);
      this.handleShareError(error);
    });
  }

  // 错误处理
  private handleShareError(error: BusinessError) {
    switch (error.code) {
      case 401:
        AlertDialog.show({
          title: '参数错误',
          message: '请检查分享数据配置'
        });
        break;
      case 1003702001:
        AlertDialog.show({
          title: '记录类型不支持',
          message: '批量模式和多选模式仅支持文件类型记录'
        });
        break;
      case 1003702002:
        AlertDialog.show({
          title: 'IPC数据超限',
          message: '请减少分享数据数量或压缩文件大小'
        });
        break;
      default:
        AlertDialog.show({
          title: '系统分享失败',
          message: `错误码：${error.code}，请稍后重试`
        });
    }
  }
}

// 注意事项：
// 1. 系统分享入口必须使用系统标准图标：SymbolGlyph($r('sys.symbol.share'))
// 2. 系统分享文本必须使用"系统分享"，请勿自行更改
// 3. 确保用户获得良好的分享体验，图标和文本符合HarmonyOS规范