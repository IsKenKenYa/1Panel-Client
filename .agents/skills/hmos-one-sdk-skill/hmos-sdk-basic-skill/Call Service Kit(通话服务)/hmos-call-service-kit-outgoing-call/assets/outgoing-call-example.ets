import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';
import { UIAbility, AbilityConstant, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const TAG = 'OutgoingCallDemo';
const DOMAIN = 0x0000;

interface CallInfo {
  callId: string;
  userName: string;
  callType: voipCall.VoipCallType;
  callState: voipCall.VoipCallState;
  isMuted: boolean;
  startTime?: number;
}

export default class OutgoingCallAbility extends UIAbility {
  private currentCall: CallInfo | null = null;
  private userProfile: image.PixelMap | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'OutgoingCallAbility onCreate');
    this.initUserProfile();
    this.registerVoipCallEvents();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'OutgoingCallAbility onDestroy');
    this.unregisterVoipCallEvents();
    this.cleanupCurrentCall();
  }

  private async initUserProfile(): Promise<void> {
    try {
      const resourceMgr: resourceManager.ResourceManager = this.context.resourceManager;
      const fileData: Uint8Array = await resourceMgr.getRawFileContent('avatar.png');
      const buffer = fileData.buffer;
      const imageSource: image.ImageSource = image.createImageSource(buffer);
      this.userProfile = await imageSource.createPixelMap();
      
      if (this.userProfile) {
        hilog.info(DOMAIN, TAG, 'User profile initialized');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to init user profile: ${error.message}`);
    }
  }

  private registerVoipCallEvents(): void {
    voipCall.on('voipCallUiEvent', (data: voipCall.VoipCallUiEventInfo) => {
      hilog.info(DOMAIN, TAG, 
        `Received UI event - CallId: ${data.callId}, Event: ${data.voipCallUiEvent}`);
      
      if (!this.currentCall || this.currentCall.callId !== data.callId) {
        hilog.warn(DOMAIN, TAG, 'Event callId does not match current call');
        return;
      }

      this.handleVoipCallEvent(data);
    });
    hilog.info(DOMAIN, TAG, 'VoipCall events registered');
  }

  private unregisterVoipCallEvents(): void {
    voipCall.off('voipCallUiEvent');
    hilog.info(DOMAIN, TAG, 'VoipCall events unregistered');
  }

  private handleVoipCallEvent(data: voipCall.VoipCallUiEventInfo): void {
    switch (data.voipCallUiEvent) {
      case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP:
        this.handleUserHangup();
        break;
      case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED:
        this.handleUserMute(true);
        break;
      case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED:
        this.handleUserMute(false);
        break;
      case voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTE_RINGTONE:
        this.handleMuteRingtone();
        break;
      default:
        hilog.warn(DOMAIN, TAG, `Unhandled event: ${data.voipCallUiEvent}`);
    }
  }

  public async makeVoiceCall(targetUserName: string): Promise<boolean> {
    return this.makeOutgoingCall(targetUserName, voipCall.VoipCallType.VOIP_CALL_VOICE);
  }

  public async makeVideoCall(targetUserName: string): Promise<boolean> {
    return this.makeOutgoingCall(targetUserName, voipCall.VoipCallType.VOIP_CALL_VIDEO);
  }

  private async makeOutgoingCall(
    targetUserName: string, 
    callType: voipCall.VoipCallType
  ): Promise<boolean> {
    if (this.currentCall) {
      hilog.error(DOMAIN, TAG, 'Already has an ongoing call');
      return false;
    }

    if (!this.userProfile) {
      hilog.error(DOMAIN, TAG, 'User profile not initialized');
      return false;
    }

    const callId = this.generateCallId();
    
    try {
      const voipCallAttribute: voipCall.VoipCallAttribute = {
        callId: callId,
        voipCallType: callType,
        userName: targetUserName,
        userProfile: this.userProfile,
        abilityName: 'OutgoingCallAbility',
        voipCallState: voipCall.VoipCallState.VOIP_CALL_STATE_DIALING,
        showBannerForIncomingCall: true,
        isVoiceAnswerSupported: true
      };

      const errorReason = await voipCall.reportOutgoingCall(voipCallAttribute);

      if (errorReason === voipCall.ErrorReason.ERROR_NONE) {
        hilog.info(DOMAIN, TAG, 'Outgoing call reported successfully');
        
        this.currentCall = {
          callId: callId,
          userName: targetUserName,
          callType: callType,
          callState: voipCall.VoipCallState.VOIP_CALL_STATE_DIALING,
          isMuted: false,
          startTime: Date.now()
        };

        this.updateCallUI();
        return true;
      } else {
        hilog.error(DOMAIN, TAG, `Failed to report outgoing call: ${errorReason}`);
        this.handleOutgoingCallError(errorReason);
        return false;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Exception in making outgoing call: ${error.message}`);
      return false;
    }
  }

  public async handleCallAnswered(): Promise<void> {
    if (!this.currentCall) {
      hilog.error(DOMAIN, TAG, 'No current call to handle answer');
      return;
    }

    try {
      await voipCall.reportCallStateChange(
        this.currentCall.callId,
        voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE
      );
      
      this.currentCall.callState = voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE;
      this.currentCall.startTime = Date.now();
      
      hilog.info(DOMAIN, TAG, 'Call answered, reported ACTIVE state');
      this.updateCallUI();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to report call answered: ${error.message}`);
    }
  }

  public async handleCallEnded(): Promise<void> {
    if (!this.currentCall) {
      hilog.error(DOMAIN, TAG, 'No current call to end');
      return;
    }

    try {
      await voipCall.reportCallStateChange(
        this.currentCall.callId,
        voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED
      );
      
      hilog.info(DOMAIN, TAG, 'Call ended, reported DISCONNECTED state');
      this.cleanupCurrentCall();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to report call ended: ${error.message}`);
      this.cleanupCurrentCall();
    }
  }

  private async handleUserHangup(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'User clicked hangup');
    await this.handleCallEnded();
  }

  private async handleUserMute(isMuted: boolean): Promise<void> {
    if (!this.currentCall) {
      hilog.error(DOMAIN, TAG, 'No current call to mute/unmute');
      return;
    }

    try {
      const callAudioEvent = isMuted 
        ? voipCall.CallAudioEvent.AUDIO_EVENT_MUTED 
        : voipCall.CallAudioEvent.AUDIO_EVENT_UNMUTED;
      
      await voipCall.reportCallAudioEventChange(
        this.currentCall.callId,
        callAudioEvent
      );
      
      this.currentCall.isMuted = isMuted;
      hilog.info(DOMAIN, TAG, `Mute state changed: ${isMuted}`);
      
      this.applyMuteState(isMuted);
      this.updateCallUI();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to report mute state: ${error.message}`);
    }
  }

  private handleMuteRingtone(): void {
    hilog.info(DOMAIN, TAG, 'User muted ringtone');
  }

  private applyMuteState(isMuted: boolean): void {
    hilog.info(DOMAIN, TAG, `Applying mute state: ${isMuted}`);
  }

  private handleOutgoingCallError(errorReason: voipCall.ErrorReason): void {
    switch (errorReason) {
      case voipCall.ErrorReason.CELLULAR_CALL_EXISTS:
        hilog.error(DOMAIN, TAG, 'Cellular call exists');
        this.showErrorToUser('当前有运营商通话，无法发起VoIP通话');
        break;
      case voipCall.ErrorReason.VOIP_CALL_EXISTS:
        hilog.error(DOMAIN, TAG, 'VoIP call already exists');
        this.showErrorToUser('当前已有应用内通话');
        break;
      case voipCall.ErrorReason.INVALID_CALL:
        hilog.error(DOMAIN, TAG, 'Invalid call parameters');
        this.showErrorToUser('通话参数无效');
        break;
      case voipCall.ErrorReason.USER_ANSWER_CELLULAR_FIRST:
        hilog.error(DOMAIN, TAG, 'User chose cellular call');
        this.showErrorToUser('用户选择接听运营商通话');
        break;
      default:
        hilog.error(DOMAIN, TAG, `Unknown error: ${errorReason}`);
        this.showErrorToUser('未知错误');
    }
  }

  private cleanupCurrentCall(): void {
    if (this.currentCall) {
      hilog.info(DOMAIN, TAG, `Cleaning up call: ${this.currentCall.callId}`);
      this.currentCall = null;
      this.updateCallUI();
    }
  }

  private generateCallId(): string {
    return `call_${Date.now()}_${Math.random().toString(36).substring(7)}`;
  }

  private updateCallUI(): void {
    hilog.info(DOMAIN, TAG, 'Updating call UI');
  }

  private showErrorToUser(message: string): void {
    hilog.error(DOMAIN, TAG, `Showing error to user: ${message}`);
  }

  getWindowStage(): window.WindowStage {
    return this.context.windowStage;
  }
}

class CallUIManager {
  private currentCall: CallInfo | null = null;

  updateCallInfo(call: CallInfo | null): void {
    this.currentCall = call;
    this.refreshUI();
  }

  private refreshUI(): void {
    if (this.currentCall) {
      this.showCallPanel();
    } else {
      this.hideCallPanel();
    }
  }

  private showCallPanel(): void {
    hilog.info(DOMAIN, TAG, 'Showing call panel');
  }

  private hideCallPanel(): void {
    hilog.info(DOMAIN, TAG, 'Hiding call panel');
  }

  getCallDuration(): number {
    if (!this.currentCall || !this.currentCall.startTime) {
      return 0;
    }
    return Math.floor((Date.now() - this.currentCall.startTime) / 1000);
  }

  formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}