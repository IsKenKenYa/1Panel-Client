// src/main/ets/WidgetEventCallEntryAbility/WidgetEventCallEntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetEventCallEntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;
const CONST_NUMBER_PLAY: number = 1;
const CONST_NUMBER_PAUSE: number = 2;
const CONST_NUMBER_NEXT: number = 3;

class MusicControlResult implements rpc.Parcelable {
  private status: number;
  private message: string;
  
  constructor(status: number, message: string) {
    this.status = status;
    this.message = message;
  }
  
  getStatus(): number {
    return this.status;
  }
  
  getMessage(): string {
    return this.message;
  }
  
  marshalling(messageSequence: rpc.MessageSequence): boolean {
    messageSequence.writeInt(this.status);
    messageSequence.writeString(this.message);
    return true;
  }
  
  unmarshalling(messageSequence: rpc.MessageSequence): boolean {
    this.status = messageSequence.readInt();
    this.message = messageSequence.readString();
    return true;
  }
}

export default class WidgetEventCallEntryAbility extends UIAbility {
  private isPlaying: boolean = false;
  private currentSongIndex: number = 0;
  
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'WidgetEventCallEntryAbility onCreate');
    
    try {
      this.callee.on('play', (data: rpc.MessageSequence) => {
        try {
          let params = data.readString();
          hilog.info(DOMAIN_NUMBER, TAG, `Play method called with params: ${params}`);
          
          this.isPlaying = true;
          hilog.info(DOMAIN_NUMBER, TAG, 'Music is playing');
          
          return new MusicControlResult(CONST_NUMBER_PLAY, 'Music playing');
        } catch (error) {
          hilog.error(DOMAIN_NUMBER, TAG, `Play method execution failed: ${error.message}`);
          return new MusicControlResult(-1, 'Play failed');
        }
      });
      
      this.callee.on('pause', (data: rpc.MessageSequence) => {
        try {
          let params = data.readString();
          hilog.info(DOMAIN_NUMBER, TAG, `Pause method called with params: ${params}`);
          
          this.isPlaying = false;
          hilog.info(DOMAIN_NUMBER, TAG, 'Music is paused');
          
          return new MusicControlResult(CONST_NUMBER_PAUSE, 'Music paused');
        } catch (error) {
          hilog.error(DOMAIN_NUMBER, TAG, `Pause method execution failed: ${error.message}`);
          return new MusicControlResult(-1, 'Pause failed');
        }
      });
      
      this.callee.on('next', (data: rpc.MessageSequence) => {
        try {
          let params = data.readString();
          hilog.info(DOMAIN_NUMBER, TAG, `Next method called with params: ${params}`);
          
          this.currentSongIndex++;
          if (this.currentSongIndex > 10) {
            this.currentSongIndex = 0;
          }
          
          hilog.info(DOMAIN_NUMBER, TAG, `Switched to song ${this.currentSongIndex}`);
          
          return new MusicControlResult(CONST_NUMBER_NEXT, `Song ${this.currentSongIndex}`);
        } catch (error) {
          hilog.error(DOMAIN_NUMBER, TAG, `Next method execution failed: ${error.message}`);
          return new MusicControlResult(-1, 'Next failed');
        }
      });
      
      hilog.info(DOMAIN_NUMBER, TAG, 'Callee methods registered successfully');
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to register callee on. Cause: ${JSON.stringify(err as BusinessError)}`);
    }
  }
  
  onDestroy(): void | Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, 'WidgetEventCallEntryAbility onDestroy');
    
    try {
      this.callee.off('play');
      this.callee.off('pause');
      this.callee.off('next');
      hilog.info(DOMAIN_NUMBER, TAG, 'Callee methods unregistered successfully');
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to unregister callee off. Cause: ${JSON.stringify(err as BusinessError)}`);
    }
  }
  
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'WidgetEventCallEntryAbility onNewWant');
  }
}