import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'TransparentFormAbility';

interface TextColor {
  mTextColor: string;
  mWallpaperType: number;
}

export default class TransparentFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    console.info(TAG, 'onAddForm triggered');
    
    let textColor: string = '#707070';
    let formData: Record<string, string> = {
      'title': '透明卡片',
      'temperature': '22°C',
      'time': '14:30'
    };
    
    if (want && want.parameters) {
      let colorInfo = want.parameters[formInfo.FormParam.HOST_BG_INVERSE_COLOR_KEY] as TextColor;
      if (colorInfo) {
        textColor = colorInfo.mTextColor;
        console.info(TAG, `Got inverse color: ${textColor}, wallpaper type: ${colorInfo.mWallpaperType}`);
      } else {
        console.error(TAG, 'No inverse color provided by host');
      }
    }
    
    formData['textColor'] = textColor;
    
    try {
      let bindingData = formBindingData.createFormBindingData(formData);
      console.info(TAG, 'FormBindingData created successfully');
      return bindingData;
    } catch (error) {
      console.error(TAG, `Failed to create FormBindingData: ${error}`);
      return formBindingData.createFormBindingData({});
    }
  }
  
  onCastToNormalForm(formId: string) {
    console.info(TAG, `onCastToNormalForm, formId: ${formId}`);
  }
  
  onUpdateForm(formId: string, wantParams?: Record<string, Object>) {
    console.info(TAG, `onUpdateForm, formId: ${formId}`);
    
    let textColor: string = '#707070';
    let formData: Record<string, string> = {
      'title': '透明卡片',
      'temperature': this.getRandomTemperature(),
      'time': this.getCurrentTime()
    };
    
    if (wantParams) {
      let colorInfo = wantParams[formInfo.FormParam.HOST_BG_INVERSE_COLOR_KEY] as TextColor;
      if (colorInfo) {
        textColor = colorInfo.mTextColor;
        console.info(TAG, `Updated inverse color: ${textColor}`);
      } else {
        console.error(TAG, 'No inverse color in update params');
      }
    }
    
    formData['textColor'] = textColor;
    
    try {
      let bindingData = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, bindingData).then(() => {
        console.info(TAG, 'Form updated successfully');
      }).catch((error: BusinessError) => {
        this.handleUpdateError(error);
      });
    } catch (error) {
      console.error(TAG, `Failed to update form: ${error}`);
    }
  }
  
  onFormEvent(formId: string, message: string) {
    console.info(TAG, `onFormEvent, formId: ${formId}, message: ${message}`);
    
    let messageObj = JSON.parse(message);
    if (messageObj.method === 'refresh') {
      this.refreshFormData(formId);
    }
  }
  
  onRemoveForm(formId: string) {
    console.info(TAG, `onRemoveForm, formId: ${formId}`);
  }
  
  onAcquireFormState(want: Want) {
    console.info(TAG, 'onAcquireFormState');
    return formInfo.FormState.READY;
  }
  
  private handleUpdateError(error: BusinessError) {
    switch (error.code) {
      case 16501001:
        console.error(TAG, 'Form ID does not exist');
        break;
      case 16501003:
        console.error(TAG, 'Cannot operate form by current application');
        break;
      case 16500050:
        console.error(TAG, 'IPC connection error');
        break;
      case 16500100:
        console.error(TAG, 'Failed to obtain configuration information');
        break;
      default:
        console.error(TAG, `Update error: code ${error.code}, message ${error.message}`);
    }
  }
  
  private getRandomTemperature(): string {
    let temp = Math.floor(Math.random() * 10 + 20);
    return `${temp}°C`;
  }
  
  private getCurrentTime(): string {
    let now = new Date();
    let hours = now.getHours();
    let minutes = now.getMinutes();
    return `${hours}:${minutes}`;
  }
  
  private refreshFormData(formId: string) {
    let formData: Record<string, string> = {
      'temperature': this.getRandomTemperature(),
      'time': this.getCurrentTime()
    };
    
    try {
      let bindingData = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, bindingData).then(() => {
        console.info(TAG, 'Form refreshed successfully');
      }).catch((error: BusinessError) => {
        this.handleUpdateError(error);
      });
    } catch (error) {
      console.error(TAG, `Failed to refresh form: ${error}`);
    }
  }
}