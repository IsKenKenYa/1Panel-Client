import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct GroupInviteSenderPage {
  @State private windowId: number = 0;
  @State private groupLink: string = '';
  @State private previewImagePath: string = '';
  @State private isRegistered: boolean = false;
  
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  
  async aboutToAppear(): void {
    await this.initWindowId();
    this.prepareShareData();
    this.registerKnockShare();
  }
  
  aboutToDisappear(): void {
    this.unregisterKnockShare();
  }
  
  private async initWindowId(): Promise<void> {
    try {
      const windowInstance = await window.getLastWindow(this.context);
      this.windowId = windowInstance.id;
      console.info(`WindowId initialized: ${this.windowId}`);
    } catch (error) {
      console.error('Failed to get windowId:', error);
    }
  }
  
  private prepareShareData(): void {
    this.groupLink = 'https://game.example.com/group/invite?roomId=12345&inviterId=user001';
    this.previewImagePath = this.context.filesDir + '/group_invite_preview.jpg';
  }
  
  private registerKnockShare(): void {
    if (this.windowId === 0) {
      console.error('Invalid windowId, cannot register knockShare');
      return;
    }
    
    const capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: this.windowId,
      sendOnly: true
    };
    
    harmonyShare.on('knockShare', capabilityRegistry, async (sharableTarget: harmonyShare.SharableTarget) => {
      console.info('KnockShare event triggered');
      await this.handleKnockShare(sharableTarget);
    });
    
    this.isRegistered = true;
    console.info('KnockShare registered successfully');
  }
  
  private unregisterKnockShare(): void {
    if (!this.isRegistered || this.windowId === 0) {
      return;
    }
    
    const capabilityRegistry: harmonyShare.SendCapabilityRegistry = {
      windowId: this.windowId
    };
    
    harmonyShare.off('knockShare', capabilityRegistry);
    this.isRegistered = false;
    console.info('KnockShare unregistered');
  }
  
  private async handleKnockShare(sharableTarget: harmonyShare.SharableTarget): Promise<void> {
    try {
      const canShare = await this.checkShareCondition();
      if (!canShare) {
        await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        console.warn('Share rejected: condition not met');
        return;
      }
      
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.groupLink,
        thumbnailUri: fileUri.getUriFromPath(this.previewImagePath),
        title: '游戏组队邀请',
        description: '点击加入我的游戏房间'
      });
      
      await sharableTarget.share(shareData);
      console.info('Group invite sent successfully');
      
    } catch (error) {
      console.error('KnockShare error:', error);
      await this.handleShareError(error, sharableTarget);
    }
  }
  
  private async checkShareCondition(): Promise<boolean> {
    if (!this.groupLink) {
      console.error('Group link is empty');
      return false;
    }
    
    try {
      const fileStat = await fs.stat(this.previewImagePath);
      if (!fileStat) {
        console.error('Preview image not found');
        return false;
      }
    } catch (error) {
      console.error('Failed to check preview image:', error);
      return false;
    }
    
    return true;
  }
  
  private async handleShareError(error: Error, sharableTarget: harmonyShare.SharableTarget): Promise<void> {
    const errorCode = (error as any).code || 'UNKNOWN';
    
    switch (errorCode) {
      case 'NO_NETWORK':
        await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_INTERNET_ERROR);
        break;
      case 'DOWNLOAD_FAILED':
        await sharableTarget.reject(harmonyShare.SharableErrorCode.DOWNLOAD_ERROR);
        break;
      default:
        await sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    }
    
    console.error(`Share error handled: ${errorCode}`);
  }
  
  build() {
    Column({ space: 20 }) {
      Text('组队邀请')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
      
      Text('碰一碰设备即可邀请好友加入')
        .fontSize(16)
        .fontColor('#666666')
      
      Divider()
      
      Row({ space: 10 }) {
        Text('分享状态:')
          .fontSize(14)
        
        Text(this.isRegistered ? '已激活' : '未激活')
          .fontSize(14)
          .fontColor(this.isRegistered ? '#00AA00' : '#AA0000')
      }
      
      Row({ space: 10 }) {
        Text('发送模式:')
          .fontSize(14)
        
        Text('仅发送（避免冲突）')
          .fontSize(14)
          .fontColor('#0066CC')
      }
      
      Divider()
      
      Text('组队房间信息')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      
      Text(`房间ID: 12345`)
        .fontSize(14)
      
      Text(`邀请链接: ${this.groupLink}`)
        .fontSize(12)
        .fontColor('#666666')
        .maxLines(2)
      
      Divider()
      
      Button('手动邀请')
        .width('80%')
        .onClick(() => {
          console.info('Manual invite button clicked');
          this.manualInvite();
        })
      
      Text('提示：当对方也在组队房间时，请确保对方未设置"仅发送"模式')
        .fontSize(12)
        .fontColor('#FF6600')
        .maxLines(2)
      
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Start)
  }
  
  private manualInvite(): void {
    console.info('Manual invite triggered');
  }
}

import { fs } from '@kit.CoreFileKit';