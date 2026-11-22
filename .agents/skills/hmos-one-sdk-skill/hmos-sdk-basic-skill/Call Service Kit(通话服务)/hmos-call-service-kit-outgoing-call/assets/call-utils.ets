import { voipCall } from '@kit.CallServiceKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { resourceManager } from '@kit.LocalizationKit';

const TAG = 'CallUtils';
const DOMAIN = 0x0000;

export class CallUtils {
  static async createAvatarPixelMap(
    resourceMgr: resourceManager.ResourceManager,
    imageFileName: string,
    targetWidth: number = 112,
    targetHeight: number = 112
  ): Promise<image.PixelMap | null> {
    try {
      const fileData: Uint8Array = await resourceMgr.getRawFileContent(imageFileName);
      const buffer = fileData.buffer;
      const imageSource: image.ImageSource = image.createImageSource(buffer);
      
      const decodingOptions: image.DecodingOptions = {
        desiredSize: { width: targetWidth, height: targetHeight }
      };
      
      const pixelMap: image.PixelMap = await imageSource.createPixelMap(decodingOptions);
      
      const pixelBytes = pixelMap.getPixelBytesNumber();
      if (pixelBytes >= 196608) {
        hilog.warn(DOMAIN, TAG, 
          `PixelMap size ${pixelBytes} exceeds limit 196608, scaling down`);
        return await this.scaleDownPixelMap(pixelMap, targetWidth * 0.5, targetHeight * 0.5);
      }
      
      hilog.info(DOMAIN, TAG, 
        `Avatar created: ${targetWidth}x${targetHeight}, ${pixelBytes} bytes`);
      return pixelMap;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to create avatar: ${error.message}`);
      return null;
    }
  }

  private static async scaleDownPixelMap(
    pixelMap: image.PixelMap,
    newWidth: number,
    newHeight: number
  ): Promise<image.PixelMap> {
    try {
      await pixelMap.scale(newWidth / pixelMap.getImageInfoSync().size.width, 
                           newHeight / pixelMap.getImageInfoSync().size.height);
      return pixelMap;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to scale PixelMap: ${error.message}`);
      return pixelMap;
    }
  }

  static generateCallId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 9);
    return `call_${timestamp}_${random}`;
  }

  static validateCallId(callId: string): boolean {
    if (!callId || callId.trim().length === 0) {
      hilog.error(DOMAIN, TAG, 'CallId is empty');
      return false;
    }
    return true;
  }

  static validateCallType(callType: voipCall.VoipCallType): boolean {
    const validTypes = [
      voipCall.VoipCallType.VOIP_CALL_VOICE,
      voipCall.VoipCallType.VOIP_CALL_VIDEO
    ];
    
    if (!validTypes.includes(callType)) {
      hilog.error(DOMAIN, TAG, `Invalid call type: ${callType}`);
      return false;
    }
    return true;
  }

  static validateCallStateForOutgoing(callState: voipCall.VoipCallState): boolean {
    if (callState !== voipCall.VoipCallState.VOIP_CALL_STATE_DIALING) {
      hilog.error(DOMAIN, TAG, 
        `Invalid call state for outgoing: ${callState}, must be VOIP_CALL_STATE_DIALING`);
      return false;
    }
    return true;
  }

  static validateVoipCallAttribute(attribute: voipCall.VoipCallAttribute): boolean {
    if (!this.validateCallId(attribute.callId)) {
      return false;
    }
    
    if (!this.validateCallType(attribute.voipCallType)) {
      return false;
    }
    
    if (!this.validateCallStateForOutgoing(attribute.voipCallState)) {
      return false;
    }
    
    if (!attribute.userName || attribute.userName.trim().length === 0) {
      hilog.error(DOMAIN, TAG, 'UserName is empty');
      return false;
    }
    
    if (!attribute.userProfile) {
      hilog.error(DOMAIN, TAG, 'UserProfile is null');
      return false;
    }
    
    const pixelBytes = attribute.userProfile.getPixelBytesNumber();
    if (pixelBytes >= 196608) {
      hilog.error(DOMAIN, TAG, 
        `UserProfile size ${pixelBytes} exceeds limit 196608`);
      return false;
    }
    
    if (!attribute.abilityName || attribute.abilityName.trim().length === 0) {
      hilog.error(DOMAIN, TAG, 'AbilityName is empty');
      return false;
    }
    
    return true;
  }

  static getCallStateName(state: voipCall.VoipCallState): string {
    const stateNames = {
      [voipCall.VoipCallState.VOIP_CALL_STATE_IDLE]: '空闲',
      [voipCall.VoipCallState.VOIP_CALL_STATE_RINGING]: '来电响铃',
      [voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE]: '通话中',
      [voipCall.VoipCallState.VOIP_CALL_STATE_HOLDING]: '保持',
      [voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED]: '已断开',
      [voipCall.VoipCallState.VOIP_CALL_STATE_DIALING]: '拨号中',
      [voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED]: '正在接听',
      [voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTING]: '正在断开'
    };
    return stateNames[state] || '未知状态';
  }

  static getCallTypeName(type: voipCall.VoipCallType): string {
    const typeNames = {
      [voipCall.VoipCallType.VOIP_CALL_VOICE]: '语音通话',
      [voipCall.VoipCallType.VOIP_CALL_VIDEO]: '视频通话'
    };
    return typeNames[type] || '未知类型';
  }

  static getEventName(event: voipCall.VoipCallUiEvent): string {
    const eventNames = {
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_NONE]: '无事件',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VOICE_ANSWER]: '语音接听',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_VIDEO_ANSWER]: '视频接听',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_REJECT]: '拒接',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_HANGUP]: '挂断',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTED]: '静音',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_UNMUTED]: '取消静音',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_SPEAKER_ON]: '开启扬声器',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_SPEAKER_OFF]: '关闭扬声器',
      [voipCall.VoipCallUiEvent.VOIP_CALL_EVENT_MUTE_RINGTONE]: '静音铃声'
    };
    return eventNames[event] || '未知事件';
  }

  static getErrorReasonName(reason: voipCall.ErrorReason): string {
    const reasonNames = {
      [voipCall.ErrorReason.ERROR_NONE]: '无错误',
      [voipCall.ErrorReason.CELLULAR_CALL_EXISTS]: '存在运营商通话',
      [voipCall.ErrorReason.VOIP_CALL_EXISTS]: '存在VoIP通话',
      [voipCall.ErrorReason.INVALID_CALL]: '通话无效',
      [voipCall.ErrorReason.USER_ANSWER_CELLULAR_FIRST]: '用户选择运营商通话'
    };
    return reasonNames[reason] || '未知错误';
  }

  static formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:` +
             `${minutes.toString().padStart(2, '0')}:` +
             `${secs.toString().padStart(2, '0')}`;
    }
    
    return `${minutes.toString().padStart(2, '0')}:` +
           `${secs.toString().padStart(2, '0')}`;
  }

  static logCallInfo(callId: string, callType: voipCall.VoipCallType, 
                     callState: voipCall.VoipCallState, userName: string): void {
    hilog.info(DOMAIN, TAG, 
      `Call Info - ID: ${callId}, Type: ${this.getCallTypeName(callType)}, ` +
      `State: ${this.getCallStateName(callState)}, User: ${userName}`);
  }
}

export class CallStateMachine {
  private currentState: voipCall.VoipCallState = voipCall.VoipCallState.VOIP_CALL_STATE_IDLE;
  
  canTransitionTo(newState: voipCall.VoipCallState): boolean {
    const validTransitions: Map<voipCall.VoipCallState, voipCall.VoipCallState[]> = new Map([
      [voipCall.VoipCallState.VOIP_CALL_STATE_IDLE, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_DIALING, voipCall.VoipCallState.VOIP_CALL_STATE_RINGING]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_DIALING, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_RINGING, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_ANSWERED, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_HOLDING, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTING]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_HOLDING, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_ACTIVE, voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTING]],
      [voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTING, 
       [voipCall.VoipCallState.VOIP_CALL_STATE_DISCONNECTED]]
    ]);
    
    const allowedStates = validTransitions.get(this.currentState);
    if (!allowedStates || !allowedStates.includes(newState)) {
      hilog.error(DOMAIN, TAG, 
        `Invalid state transition: ${CallUtils.getCallStateName(this.currentState)} -> ` +
        `${CallUtils.getCallStateName(newState)}`);
      return false;
    }
    
    return true;
  }
  
  transitionTo(newState: voipCall.VoipCallState): void {
    if (this.canTransitionTo(newState)) {
      hilog.info(DOMAIN, TAG, 
        `State transition: ${CallUtils.getCallStateName(this.currentState)} -> ` +
        `${CallUtils.getCallStateName(newState)}`);
      this.currentState = newState;
    }
  }
  
  getCurrentState(): voipCall.VoipCallState {
    return this.currentState;
  }
  
  reset(): void {
    this.currentState = voipCall.VoipCallState.VOIP_CALL_STATE_IDLE;
    hilog.info(DOMAIN, TAG, 'State machine reset to IDLE');
  }
}