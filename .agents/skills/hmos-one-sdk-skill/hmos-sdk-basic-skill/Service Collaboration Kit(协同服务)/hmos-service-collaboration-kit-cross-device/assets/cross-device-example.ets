/**
 * 跨设备互通完整示例
 * 功能：实现PC/2in1/Tablet调用Phone/Tablet设备进行拍照、扫描、图库选择
 * API版本：5.0.0(12)起支持
 * 系统能力：SystemCapability.Collaboration.Service
 */

import { 
  createCollaborationServiceMenuItems, 
  CollaborationServiceStateDialog, 
  CollaborationServiceFilter 
} from '@kit.ServiceCollaborationKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CrossDeviceExample';
const DOMAIN = 0xFF00;

@Entry
@Component
struct CrossDeviceCollaborationExample {
  // 状态变量
  @State receivedPicture: PixelMap | undefined = undefined;
  @State receivedVideos: ArrayBuffer[] = [];
  @State receivedFileNames: string[] = [];
  @State operationStatus: string = '准备就绪';
  @State selectedCapability: string = 'ALL';
  @State maxImageCount: number = 10;

  /**
   * 设备菜单构建器
   * 根据选择的能力类型创建设备列表菜单
   */
  @Builder
  deviceMenuBuilder() {
    Menu() {
      // 根据用户选择的能力类型创建菜单项
      switch (this.selectedCapability) {
        case 'ALL':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.ALL], 
            this.maxImageCount
          );
          break;
          
        case 'TAKE_PHOTO':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.TAKE_PHOTO]
          );
          break;
          
        case 'SCAN_DOCUMENT':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.SCAN_DOCUMENT]
          );
          break;
          
        case 'IMAGE_PICKER':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.IMAGE_PICKER], 
            this.maxImageCount
          );
          break;
          
        case 'VIDEO_PICKER':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.VIDEO_PICKER]
          );
          break;
          
        case 'IMAGE_VIDEO_PICKER':
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.IMAGE_VIDEO_PICKER], 
            this.maxImageCount
          );
          break;
          
        default:
          createCollaborationServiceMenuItems(
            [CollaborationServiceFilter.ALL], 
            this.maxImageCount
          );
      }
    }
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('跨设备互通示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      // 状态提示框组件（必需）
      CollaborationServiceStateDialog({
        onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => {
          this.handleStateCallback(stateCode, bufferType, buffer);
        }
      });

      // 能力类型选择
      Column({ space: 10 }) {
        Text('选择能力类型：')
          .fontSize(16)
          .fontWeight(FontWeight.Medium);
        
        Row({ space: 10 }) {
          Button('全部')
            .onClick(() => {
              this.selectedCapability = 'ALL';
              this.operationStatus = '已选择：全部能力';
            });
          
          Button('拍照')
            .onClick(() => {
              this.selectedCapability = 'TAKE_PHOTO';
              this.operationStatus = '已选择：跨设备拍照';
            });
          
          Button('扫描')
            .onClick(() => {
              this.selectedCapability = 'SCAN_DOCUMENT';
              this.operationStatus = '已选择：文档扫描';
            });
        }
        
        Row({ space: 10 }) {
          Button('图库')
            .onClick(() => {
              this.selectedCapability = 'IMAGE_PICKER';
              this.operationStatus = '已选择：图库选择';
            });
          
          Button('视频')
            .onClick(() => {
              this.selectedCapability = 'VIDEO_PICKER';
              this.operationStatus = '已选择：视频选择';
            });
          
          Button('图片+视频')
            .onClick(() => {
              this.selectedCapability = 'IMAGE_VIDEO_PICKER';
              this.operationStatus = '已选择：图片和视频选择';
            });
        }
      }
      .width('90%');

      // 图片数量设置（仅对IMAGE_PICKER和IMAGE_VIDEO_PICKER有效）
      if (this.selectedCapability === 'IMAGE_PICKER' || 
          this.selectedCapability === 'IMAGE_VIDEO_PICKER' ||
          this.selectedCapability === 'ALL') {
        Row({ space: 10 }) {
          Text('最大图片数量：')
            .fontSize(14);
          
          TextInput({ text: this.maxImageCount.toString() })
            .type(InputType.Number)
            .width(100)
            .onChange((value: string) => {
              let count = parseInt(value);
              if (count > 0 && count <= 50) {
                this.maxImageCount = count;
              }
            });
          
          Text('(1-50)')
            .fontSize(12)
            .fontColor('#999999');
        }
        .width('90%');
      }

      // 操作状态显示
      Text(this.operationStatus)
        .fontSize(16)
        .fontColor('#333333')
        .margin({ top: 10, bottom: 10 });

      // 触发跨设备操作的按钮
      Button('开始跨设备操作')
        .type(ButtonType.Normal)
        .borderRadius(10)
        .width('80%')
        .height(50)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .bindMenu(this.deviceMenuBuilder);

      // 显示接收的图片
      if (this.receivedPicture) {
        Column({ space: 10 }) {
          Text('接收到的图片：')
            .fontSize(14)
            .fontWeight(FontWeight.Medium);
          
          Image(this.receivedPicture)
            .width('90%')
            .height(300)
            .objectFit(ImageFit.Contain)
            .border({
              width: 2,
              color: '#999999',
              style: BorderStyle.Dashed
            })
            .onComplete((event) => {
              if (event != undefined) {
                hilog.info(DOMAIN, TAG, `图片加载完成: ${event.loadingStatus}`);
              }
            });
        }
        .width('100%');
      }

      // 显示接收的视频数量
      if (this.receivedVideos.length > 0) {
        Text(`接收到 ${this.receivedVideos.length} 个视频文件`)
          .fontSize(14)
          .fontColor('#333333');
      }

      // 显示接收的文件名列表
      if (this.receivedFileNames.length > 0) {
        Column({ space: 5 }) {
          Text('接收到的文件列表：')
            .fontSize(14)
            .fontWeight(FontWeight.Medium);
          
          List({ space: 5 }) {
            ForEach(this.receivedFileNames, (fileName: string, index: number) => {
              ListItem() {
                Text(`${index + 1}. ${fileName}`)
                  .fontSize(12)
                  .fontColor('#333333');
              }
            });
          }
          .width('90%')
          .height(150)
          .border({
            width: 1,
            color: '#CCCCCC',
            style: BorderStyle.Solid
          });
        }
        .width('100%');
      }

      // 清空按钮
      if (this.receivedPicture || this.receivedVideos.length > 0 || this.receivedFileNames.length > 0) {
        Button('清空数据')
          .type(ButtonType.Normal)
          .borderRadius(10)
          .width('60%')
          .height(40)
          .backgroundColor('#FF4500')
          .fontColor(Color.White)
          .onClick(() => {
            this.clearReceivedData();
          });
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center);
  }

  /**
   * 处理跨设备回调状态
   * @param stateCode 状态码
   * @param bufferType 数据类型
   * @param buffer 数据内容
   */
  handleStateCallback(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    hilog.info(DOMAIN, TAG, `状态回调: stateCode=${stateCode}, bufferType=${bufferType}, size=${buffer.byteLength}`);

    switch (stateCode) {
      case 0:
        // 成功：处理返回的数据
        this.operationStatus = '操作成功，正在处理数据...';
        this.processReceivedData(bufferType, buffer);
        break;
        
      case 1001202001:
        // 对端取消
        this.operationStatus = '对端用户取消了操作';
        this.showUserMessage('对端用户已取消操作');
        break;
        
      case 1001202002:
        // 协同框架内部错误
        this.operationStatus = '协同框架内部错误';
        this.showUserMessage('操作失败，请重试或检查设备连接状态');
        break;
        
      case 1001202003:
        // 本端取消
        this.operationStatus = '本端用户取消了操作';
        break;
        
      case 1001202004:
        // 跨设备互通能力开始
        this.operationStatus = '跨设备操作已开始，请稍候...';
        break;
        
      case 1001202005:
        // 图片全部回传结束
        this.operationStatus = '所有图片接收完成';
        this.showUserMessage('接收完成');
        break;
        
      case 1001202006:
        // 回传文件名称
        this.processFileName(buffer);
        break;
        
      case 1001202007:
        // canReceiveNumber参数错误
        this.operationStatus = '参数错误：图片数量必须大于0且小于等于50';
        this.showUserMessage('请设置正确的图片数量参数');
        break;
        
      default:
        this.operationStatus = `未知状态码: ${stateCode}`;
        this.showUserMessage('操作异常，请重试');
        hilog.warn(DOMAIN, TAG, `未处理的状态码: ${stateCode}`);
    }
  }

  /**
   * 处理接收到的数据
   * @param bufferType 数据类型
   * @param buffer 数据内容
   */
  processReceivedData(bufferType: string, buffer: ArrayBuffer): void {
    if (!buffer || buffer.byteLength === 0) {
      hilog.warn(DOMAIN, TAG, '接收到的数据为空');
      return;
    }

    try {
      switch (bufferType) {
        case 'general.image':
          // 处理图片数据
          this.processImageData(buffer);
          break;
          
        case 'general.video':
          // 处理视频数据
          this.processVideoData(buffer);
          break;
          
        case 'general.fileName':
          // 处理文件名数据
          this.processFileName(buffer);
          break;
          
        default:
          hilog.warn(DOMAIN, TAG, `未知的数据类型: ${bufferType}`);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `数据处理失败: ${error}`);
      this.showUserMessage('数据处理失败，请重试');
    }
  }

  /**
   * 处理图片数据
   * @param buffer 图片数据的ArrayBuffer
   */
  processImageData(buffer: ArrayBuffer): void {
    try {
      let imageSource = image.createImageSource(buffer);
      
      imageSource.createPixelMap().then((pixelMap: PixelMap) => {
        this.receivedPicture = pixelMap;
        hilog.info(DOMAIN, TAG, '图片处理成功');
        this.showUserMessage('图片接收成功');
      }).catch((error: Error) => {
        hilog.error(DOMAIN, TAG, `创建PixelMap失败: ${error.message}`);
        this.showUserMessage('图片处理失败');
      }).finally(() => {
        imageSource.release();
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, `图片处理异常: ${error}`);
      this.showUserMessage('图片处理异常');
    }
  }

  /**
   * 处理视频数据
   * @param buffer 视频数据的ArrayBuffer
   */
  processVideoData(buffer: ArrayBuffer): void {
    try {
      this.receivedVideos.push(buffer);
      hilog.info(DOMAIN, TAG, `视频接收成功，大小: ${buffer.byteLength} bytes`);
      this.showUserMessage('视频接收成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `视频处理失败: ${error}`);
      this.showUserMessage('视频处理失败');
    }
  }

  /**
   * 处理文件名数据
   * @param buffer 文件名数据的ArrayBuffer
   */
  processFileName(buffer: ArrayBuffer): void {
    try {
      let decoder = new TextDecoder('utf-8');
      let fileName = decoder.decode(buffer);
      this.receivedFileNames.push(fileName);
      hilog.info(DOMAIN, TAG, `文件名接收成功: ${fileName}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `文件名解码失败: ${error}`);
    }
  }

  /**
   * 清空接收的数据
   */
  clearReceivedData(): void {
    this.receivedPicture = undefined;
    this.receivedVideos = [];
    this.receivedFileNames = [];
    this.operationStatus = '准备就绪';
    hilog.info(DOMAIN, TAG, '已清空所有接收的数据');
  }

  /**
   * 显示用户提示信息
   * @param message 提示消息
   */
  showUserMessage(message: string): void {
    // 在实际应用中，这里可以使用Toast或AlertDialog
    // 示例中使用日志输出
    hilog.info(DOMAIN, TAG, `用户提示: ${message}`);
    
    // 更新状态显示
    this.operationStatus = message;
  }
}