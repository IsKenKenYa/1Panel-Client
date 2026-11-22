// 全接模式实现示例
// 直接使用系统分享面板

import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct FullAccessModeExample {
  build() {
    Column() {
      Button('分享文本')
        .onClick(() => {
          this.shareText();
        })
      
      Button('分享图片')
        .onClick(() => {
          this.shareImage();
        })
      
      Button('分享链接')
        .onClick(() => {
          this.shareLink();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // 分享文本示例
  private shareText() {
    // 构造分享数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PLAIN_TEXT,
      content: 'Hello HarmonyOS',
      title: '分享文本'
    });

    // 创建分享控制器
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    // 获取UIAbility上下文
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    // 注册面板关闭监听
    controller.on('dismiss', () => {
      console.info('Share panel closed');
      // 分享结束，可处理其他业务
    });

    // 显示系统分享面板
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      this.handleShareError(error);
    });
  }

  // 分享图片示例
  private shareImage() {
    // 构造分享数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.PNG,
      uri: 'file://.../test.png',
      title: '分享图片'
    });

    // 创建分享控制器
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    // 获取UIAbility上下文
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    // 显示系统分享面板（使用详细预览模式）
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
      this.handleShareError(error);
    });
  }

  // 分享链接示例
  private shareLink() {
    // 构造分享数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://developer.huawei.com',
      title: '分享链接'
    });

    // 创建分享控制器
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);

    // 获取UIAbility上下文
    let uiContext: UIContext = this.getUIContext();
    let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;

    // 显示系统分享面板
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
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
          title: '分享失败',
          message: `错误码：${error.code}，请稍后重试`
        });
    }
  }
}