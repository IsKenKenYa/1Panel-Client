import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UIAbility } from '@kit.AbilityKit';
import { pushService } from '@kit.PushKit';
import { resourceManager } from '@kit.LocalizationKit';

interface VoipCallContent {
  data: string;
  callId: string;
  callerName: string;
  isVoiceAnswerAllowed: boolean;
}

export default class VoipVideoCallAbility extends UIAbility {
  private currentCallId: string = '';
  private isCallActive: boolean = false;
  private currentCallType: voipCall.VoipCallType = voipCall.VoipCallType.VOIP_CALL_VIDEO;

  onCreate(): void {
    hilog.info(0x0000, 'VoipVideoCallDemo', 'VoipVideoCallAbility onCreate');
    
    this.registerVoipCallUiEvent();
    this.setupPushMessageListener();
  }

  onDestroy(): void {
    hilog.info(0x0000, 'VoipVideoCallDemo', 'VoipVideoCallAbility onDestroy');
    this.unregisterVoipCallUiEvent();
  }

  private registerVoipCallUiEvent(): void {
    voipCall.on('voipCallUiEvent', (callback: voipCall.VoipCallUiEventInfo) => {
      hilog.info(0x0000, 'VoipVideoCallDemo', 
        `Received UI event: ${callback.voipCallUiEvent}, callId: ${callback.callId}, errorReason: ${callback.errorReason}`);
      
      if (callback.errorReason !== voipCall.ErrorReason.ERROR_NONE) {
        hilog.error(0x0000, 'VoipVideoCallDemo', `Error in UI event: ${callback.errorReason}`);
        this.handleCallError(callback.callId, callback.errorReason);
        return;
      }

      this.currentCallId = callback.callId;

      switch (callback.voipCallUiEvent) {
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VOICE_ANSWER:
          this.handleVoiceAnswer(callback.callId);
          break;
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VIDEO_ANSWER:
          this.handleVideoAnswer(callback.callId);
          break;
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_REJECT:
          this.handleReject(callback.callId);
          break;
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP:
          this.handleHangup(callback.callId);
          break;
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED:
          this.handleMuted(callback.callId);
          break;
        case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED:
          this.handleUnmuted(callback.callId);
          break;
        default:
          hilog.warn(0x0000, 'VoipVideoCallDemo', `Unhandled event: ${callback.voipCallUiEvent}`);
      }
    });

    hilog.info(0x0000, 'VoipVideoCallDemo', 'Registered voipCallUiEvent');
  }

  private unregisterVoipCallUiEvent(): void {
    voipCall.off('voipCallUiEvent');
    hilog.info(0x0000, 'VoipVideoCallDemo', 'Unregistered voipCallUiEvent');
  }

  private setupPushMessageListener(): void {
    pushService.receiveMessage('VoIP', this, async (data) => {
      try {
        const content: VoipCallContent = JSON.parse(data.data);
        hilog.info(0x0000, 'VoipVideoCallDemo', `Received VoIP push message: ${content.callId}`);
        
        await this.handleIncomingCall(content);
      } catch (error) {
        hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to parse push message: ${error}`);
      }
    });

    hilog.info(0x0000, 'VoipVideoCallDemo', 'Setup push message listener');
  }

  private async handleIncomingCall(content: VoipCallContent): Promise<void> {
    try {
      this.currentCallId = content.callId;
      this.currentCallType = voipCall.VoipCallType.VOIP_CALL_VIDEO;
      
      const userProfile: image.PixelMap = await this.createUserProfile();
      
      const voipCallAttribute: voipCall.VoipCallAttribute = {
        callId: content.callId,
        voipCallType: voipCall.VoipCallType.VOIP_CALL_VIDEO,
        userName: content.callerName || 'Unknown',
        userProfile: userProfile,
        abilityName: 'VoipVideoCallAbility',
        voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_RINGING,
        showBannerForIncomingCall: true,
        isVoiceAnswerSupported: content.isVoiceAnswerAllowed
      };

      const errorReason: voipCall.ErrorReason = await voipCall.reportIncomingCall(voipCallAttribute);
      
      if (errorReason === voipCall.ErrorReason.ERROR_NONE) {
        hilog.info(0x0000, 'VoipVideoCallDemo', 'Successfully reported incoming video call');
      } else {
        hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to report incoming call: ${errorReason}`);
        await this.handleReportIncomingCallError(content.callId, errorReason);
      }
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Exception in handleIncomingCall: ${error}`);
    }
  }

  private async createUserProfile(): Promise<image.PixelMap> {
    try {
      const resourceMgr: resourceManager.ResourceManager = this.context.resourceManager;
      const fileData: Uint8Array = await resourceMgr.getRawFileContent('default_avatar.png');
      const buffer = fileData.buffer;
      const imageSource: image.ImageSource = image.createImageSource(buffer);
      const pixelMap: image.PixelMap = await imageSource.createPixelMap();
      
      return pixelMap;
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to create user profile: ${error}`);
      
      return image.createPixelMapSync(new ArrayBuffer(100), { size: { width: 90, height: 90 } });
    }
  }

  private async handleVoiceAnswer(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling voice answer for video call: ${callId}`);
      
      await voipCall.reportCallStateChange(
        callId, 
        voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED,
        voipCall.VoipCallType.VOIP_CALL_VOICE
      );
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported ANSWERED state with voice type');
      
      await this.performAppInternalVoiceAnswer(callId);
      
      await voipCall.reportCallStateChange(
        callId, 
        voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE,
        voipCall.VoipCallType.VOIP_CALL_VOICE
      );
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported ACTIVE state with voice type');
      
      this.isCallActive = true;
      this.currentCallType = voipCall.VoipCallType.VOIP_CALL_VOICE;
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle voice answer: ${error}`);
      await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
    }
  }

  private async handleVideoAnswer(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling video answer for video call: ${callId}`);
      
      await voipCall.reportCallStateChange(
        callId, 
        voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED,
        voipCall.VoipCallType.VOIP_CALL_VIDEO
      );
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported ANSWERED state with video type');
      
      await this.performAppInternalVideoAnswer(callId);
      
      await voipCall.reportCallStateChange(
        callId, 
        voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE,
        voipCall.VoipCallType.VOIP_CALL_VIDEO
      );
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported ACTIVE state with video type');
      
      this.isCallActive = true;
      this.currentCallType = voipCall.VoipCallType.VOIP_CALL_VIDEO;
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle video answer: ${error}`);
      await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
    }
  }

  private async performAppInternalVoiceAnswer(callId: string): Promise<void> {
    hilog.info(0x0000, 'VoipVideoCallDemo', `Performing internal voice answer for call: ${callId}`);
  }

  private async performAppInternalVideoAnswer(callId: string): Promise<void> {
    hilog.info(0x0000, 'VoipVideoCallDemo', `Performing internal video answer for call: ${callId}`);
  }

  private async handleReject(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling reject for call: ${callId}`);
      
      await this.performAppInternalReject(callId);
      
      await voipCall.reportCallStateChange(callId, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED);
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported DISCONNECTED state after reject');
      
      this.isCallActive = false;
      this.currentCallId = '';
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle reject: ${error}`);
    }
  }

  private async performAppInternalReject(callId: string): Promise<void> {
    hilog.info(0x0000, 'VoipVideoCallDemo', `Performing internal reject for call: ${callId}`);
  }

  private async handleHangup(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling hangup for call: ${callId}`);
      
      await this.performAppInternalHangup(callId);
      
      await voipCall.reportCallStateChange(
        callId, 
        voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED,
        this.currentCallType
      );
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported DISCONNECTED state after hangup');
      
      this.isCallActive = false;
      this.currentCallId = '';
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle hangup: ${error}`);
    }
  }

  private async performAppInternalHangup(callId: string): Promise<void> {
    hilog.info(0x0000, 'VoipVideoCallDemo', `Performing internal hangup for call: ${callId}`);
  }

  private async handleMuted(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling muted for call: ${callId}`);
      
      await this.performAppInternalMute(callId, true);
      
      await voipCall.reportCallAudioEventChange(callId, voipCall.CallAudioEvent.AUDIO_EVENT_MUTED);
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported MUTED audio event');
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle muted: ${error}`);
    }
  }

  private async handleUnmuted(callId: string): Promise<void> {
    try {
      hilog.info(0x0000, 'VoipVideoCallDemo', `Handling unmuted for call: ${callId}`);
      
      await this.performAppInternalMute(callId, false);
      
      await voipCall.reportCallAudioEventChange(callId, voipCall.CallAudioEvent.AUDIO_EVENT_UNMUTED);
      hilog.info(0x0000, 'VoipVideoCallDemo', 'Reported UNMUTED audio event');
    } catch (error) {
      hilog.error(0x0000, 'VoipVideoCallDemo', `Failed to handle unmuted: ${error}`);
    }
  }

  private async performAppInternalMute(callId: string, mute: boolean): Promise<void> {
    hilog.info(0x0000, 'VoipVideoCallDemo', `Set mute=${mute} for call: ${callId}`);
  }

  private async handleReportIncomingCallError(callId: string, errorReason: voipCall.ErrorReason): Promise<void> {
    let failureCause: voipCall.VoipCallFailureCause = voipCall.VoipCallFailureCause.OTHER;
    
    switch (errorReason) {
      case voipCall.ErrorReason.CELLULAR_CALL_EXISTS:
        hilog.warn(0x0000, 'VoipVideoCallDemo', 'Cellular call exists');
        failureCause = voipCall.VoipCallFailureCause.OTHER;
        break;
      case voipCall.ErrorReason.VOIP_CALL_EXISTS:
        hilog.warn(0x0000, 'VoipVideoCallDemo', 'Another VoIP call exists');
        failureCause = voipCall.VoipCallFailureCause.ROUTE_BUSY;
        break;
      case voipCall.ErrorReason.INVALID_CALL:
        hilog.error(0x0000, 'VoipVideoCallDemo', 'Invalid call parameters');
        return;
      case voipCall.ErrorReason.USER_ANSWER_CELLULAR_FIRST:
        hilog.info(0x0000, 'VoipVideoCallDemo', 'User answered cellular call first');
        return;
    }
    
    await voipCall.reportIncomingCallError(callId, failureCause);
    hilog.info(0x0000, 'VoipVideoCallDemo', `Reported incoming call error with cause: ${failureCause}`);
  }

  private handleCallError(callId: string, errorReason: voipCall.ErrorReason): void {
    hilog.error(0x0000, 'VoipVideoCallDemo', `Call error for ${callId}: ${errorReason}`);
    this.isCallActive = false;
    this.currentCallId = '';
  }
}