import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class GroupInviteReceiverAbility extends UIAbility {
  private groupInfo: GroupInviteInfo | null = null;
  
  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    try {
      await windowStage.loadContent('pages/GroupInviteReceiverPage');
      hilog.info(0x0000, 'GroupInvite', 'WindowStage created');
    } catch (error) {
      hilog.error(0x0000, 'GroupInvite', `Failed to load content: ${JSON.stringify(error)}`);
    }
  }
  
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'GroupInvite', `onCreate invoked, uri: ${want.uri}`);
    
    if (want.uri) {
      this.handleGroupInvite(want.uri);
    }
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'GroupInvite', `onNewWant invoked, uri: ${want.uri}`);
    
    if (want.uri) {
      this.handleGroupInvite(want.uri);
    }
  }
  
  private handleGroupInvite(uri: string): void {
    try {
      const groupInviteInfo = this.parseGroupInviteLink(uri);
      this.groupInfo = groupInviteInfo;
      
      hilog.info(0x0000, 'GroupInvite', 
        `Group invite received: roomId=${groupInviteInfo.roomId}, inviterId=${groupInviteInfo.inviterId}`);
      
      this.saveGroupInviteInfo(groupInviteInfo);
      this.showGroupInviteNotification(groupInviteInfo);
      
    } catch (error) {
      hilog.error(0x0000, 'GroupInvite', `Failed to parse invite link: ${JSON.stringify(error)}`);
      this.showInviteErrorDialog();
    }
  }
  
  private parseGroupInviteLink(uri: string): GroupInviteInfo {
    const urlObj = new URL(uri);
    const params = urlObj.searchParams;
    
    const roomId = params.get('roomId');
    const inviterId = params.get('inviterId');
    const timestamp = params.get('timestamp');
    
    if (!roomId || !inviterId) {
      throw new Error('Missing required parameters: roomId or inviterId');
    }
    
    return {
      roomId: roomId,
      inviterId: inviterId,
      timestamp: timestamp ? parseInt(timestamp) : Date.now(),
      inviteLink: uri
    };
  }
  
  private saveGroupInviteInfo(groupInviteInfo: GroupInviteInfo): void {
    try {
      AppStorage.SetOrCreate('currentGroupInvite', JSON.stringify(groupInviteInfo));
      hilog.info(0x0000, 'GroupInvite', 'Group invite info saved to AppStorage');
    } catch (error) {
      hilog.error(0x0000, 'GroupInvite', `Failed to save invite info: ${JSON.stringify(error)}`);
    }
  }
  
  private showGroupInviteNotification(groupInviteInfo: GroupInviteInfo): void {
    hilog.info(0x0000, 'GroupInvite', 
      `Showing notification: User ${groupInviteInfo.inviterId} invites you to room ${groupInviteInfo.roomId}`);
    
  }
  
  private showInviteErrorDialog(): void {
    hilog.warn(0x0000, 'GroupInvite', 'Showing invite error dialog');
  }
  
  onForeground(): void {
    hilog.info(0x0000, 'GroupInvite', 'onForeground');
    
    if (this.groupInfo) {
      this.updateGroupInviteUI(this.groupInfo);
    }
  }
  
  private updateGroupInviteUI(groupInfo: GroupInviteInfo): void {
    hilog.info(0x0000, 'GroupInvite', `Updating UI with group info: ${JSON.stringify(groupInfo)}`);
  }
  
  onBackground(): void {
    hilog.info(0x0000, 'GroupInvite', 'onBackground');
  }
  
  onDestroy(): void {
    hilog.info(0x0000, 'GroupInvite', 'onDestroy');
    this.groupInfo = null;
  }
}

interface GroupInviteInfo {
  roomId: string;
  inviterId: string;
  timestamp: number;
  inviteLink: string;
}