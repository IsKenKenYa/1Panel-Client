// entry/src/main/ets/formability/WgtImgUpdateEntryFormAbility.ets
// ArkTS卡片图片刷新完整示例 - FormExtensionAbility实现

import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';

const TAG: string = 'WgtImgUpdateEntryFormAbility';
const DOMAIN_NUMBER: number = 0xFF00;
const TEXT1: string = '刷新中...';
const TEXT2: string = '刷新失败';

export default class WgtImgUpdateEntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, `onAddForm, want: ${want.abilityName}`);
    
    let tempDir = this.context.getApplicationContext().tempDir;
    hilog.info(DOMAIN_NUMBER, TAG, `tempDir: ${tempDir}`);
    
    let imgMap: Record<string, number> = {};
    try {
      let file = fileIo.openSync(tempDir + '/' + 'head.PNG');
      imgMap['imgBear'] = file.fd;
      hilog.info(DOMAIN_NUMBER, TAG, `openSync succeed, fd: ${file.fd}`);
    } catch (e) {
      hilog.error(DOMAIN_NUMBER, TAG, `openSync failed: ${JSON.stringify(e as BusinessError)}`);
    }
    
    class FormDataClass {
      text: string = 'Image: Bear';
      loaded: boolean = true;
      imgName: string = 'imgBear';
      formImages: Record<string, number> = imgMap;
    }
    
    let formData = new FormDataClass();
    return formBindingData.createFormBindingData(formData);
  }

  async onFormEvent(formId: string, message: string): Promise<void> {
    hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent, formId: ${formId}, message: ${message}`);
    
    let param: Record<string, string> = {
      'text': TEXT1
    };
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
    formProvider.updateForm(formId, formInfo);
    
    let netFile = 'https://cn-assets.gitee.com/assets/mini_app-e5eee5a21c552b69ae6bf2cf87406b59.jpg';
    let tempDir = this.context.getApplicationContext().tempDir;
    let fileName = 'file' + Date.now();
    let tmpFile = tempDir + '/' + fileName;
    let imgMap: Record<string, number> = {};
    
    class FormDataClass {
      text: string = 'Image: ' + fileName;
      loaded: boolean = true;
      imgName: string = fileName;
      formImages: Record<string, number> = imgMap;
    }
    
    let httpRequest = http.createHttp();
    let data = await httpRequest.request(netFile);
    
    if (data?.responseCode == http.ResponseCode.OK) {
      try {
        let imgFile = fileIo.openSync(tmpFile, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        imgMap[fileName] = imgFile.fd;
        
        try {
          let writeLen: number = await fileIo.write(imgFile.fd, data.result as ArrayBuffer);
          hilog.info(DOMAIN_NUMBER, TAG, "write data to file succeed and size is:" + writeLen);
          hilog.info(DOMAIN_NUMBER, TAG, 'ArkTSCard download complete: %{public}s', tmpFile);
          
          try {
            let formData = new FormDataClass();
            let formInfo = formBindingData.createFormBindingData(formData);
            await formProvider.updateForm(formId, formInfo);
            hilog.info(DOMAIN_NUMBER, TAG, '%{public}s', 'FormAbility updateForm success.');
          } catch (error) {
            hilog.error(DOMAIN_NUMBER, TAG, `FormAbility updateForm failed: ${JSON.stringify(error)}`);
          }
        } catch (err) {
          hilog.error(DOMAIN_NUMBER, TAG, "write data to file failed with error message: " + err.message + ", error code: " + err.code);
        } finally {
          fileIo.closeSync(imgFile);
        }
      } catch (e) {
        hilog.error(DOMAIN_NUMBER, TAG, `openSync failed: ${JSON.stringify(e as BusinessError)}`);
      }
    } else {
      hilog.error(DOMAIN_NUMBER, TAG, `ArkTSCard download task failed`);
      let param: Record<string, string> = {
        'text': TEXT2
      };
      let formInfo = formBindingData.createFormBindingData(param);
      formProvider.updateForm(formId, formInfo);
    }
    
    httpRequest.destroy();
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    hilog.info(DOMAIN_NUMBER, TAG, `onAcquireFormState, want: ${want}`);
    return formInfo.FormState.READY;
  }

  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm, formId: ${formId}`);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onConfigurationUpdate, config: ${newConfig?.language}`);
  }
}