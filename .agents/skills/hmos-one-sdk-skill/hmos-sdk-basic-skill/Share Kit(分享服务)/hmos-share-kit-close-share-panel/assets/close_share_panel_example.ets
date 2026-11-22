import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

export default class SharePanelCloseAbility extends ShareExtensionAbility {
  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    try {
      console.info('[SharePanelCloseAbility] onSessionCreate start');
      
      const sharedData = await systemShare.getSharedData(want);
      console.info('[SharePanelCloseAbility] getSharedData success');
      
      const records = sharedData.getRecords();
      console.info('[SharePanelCloseAbility] records count:', records.length);
      
      for (const record of records) {
        console.info('[SharePanelCloseAbility] record utd:', record.utd);
        if (record.content) {
          console.info('[SharePanelCloseAbility] record content:', record.content);
        }
        if (record.uri) {
          console.info('[SharePanelCloseAbility] record uri:', record.uri);
        }
      }
      
      await this.processShareContent(records);
      
      console.info('[SharePanelCloseAbility] share process completed, closing panel');
      session.terminateSelfWithResult({
        resultCode: systemShare.ShareAbilityResultCode.CLOSE
      });
      
    } catch (error) {
      const err = error as BusinessError;
      console.error('[SharePanelCloseAbility] error occurred:', err.code, err.message);
      
      if (err.code === 1003703001) {
        console.error('[SharePanelCloseAbility] parse data failed, return with error');
        session.terminateSelfWithResult({
          resultCode: systemShare.ShareAbilityResultCode.ERROR
        });
      } else {
        console.warn('[SharePanelCloseAbility] other error, return to share panel');
        session.terminateSelfWithResult({
          resultCode: systemShare.ShareAbilityResultCode.BACK
        });
      }
    }
  }

  private async processShareContent(records: systemShare.SharedRecord[]): Promise<void> {
    for (const record of records) {
      if (record.utd.includes('TEXT') || record.utd.includes('PLAIN_TEXT')) {
        await this.processTextShare(record.content || '');
      } else if (record.utd.includes('IMAGE') || record.utd.includes('PNG') || record.utd.includes('JPEG')) {
        await this.processImageShare(record.uri || '');
      } else if (record.utd.includes('FILE')) {
        await this.processFileShare(record.uri || '');
      }
    }
  }

  private async processTextShare(content: string): Promise<void> {
    console.info('[SharePanelCloseAbility] processing text:', content.substring(0, 100));
  }

  private async processImageShare(uri: string): Promise<void> {
    console.info('[SharePanelCloseAbility] processing image uri:', uri);
  }

  private async processFileShare(uri: string): Promise<void> {
    console.info('[SharePanelCloseAbility] processing file uri:', uri);
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
    console.info('[SharePanelCloseAbility] onSessionDestroy');
  }
}

const RESULT_CODE_EXAMPLES = {
  CLOSE_PANEL_ON_SUCCESS: systemShare.ShareAbilityResultCode.CLOSE,
  BACK_TO_PANEL_ON_CANCEL: systemShare.ShareAbilityResultCode.BACK,
  ERROR_TO_PANEL_ON_FAILURE: systemShare.ShareAbilityResultCode.ERROR,
};

export function getShareResultCodeByScenario(scenario: string): number {
  switch (scenario) {
    case 'success':
      return systemShare.ShareAbilityResultCode.CLOSE;
    case 'cancel':
      return systemShare.ShareAbilityResultCode.BACK;
    case 'error':
      return systemShare.ShareAbilityResultCode.ERROR;
    default:
      return systemShare.ShareAbilityResultCode.BACK;
  }
}

export function closeSharePanelWithResult(
  session: UIExtensionContentSession,
  scenario: string = 'success'
): void {
  const resultCode = getShareResultCodeByScenario(scenario);
  console.info('[closeSharePanelWithResult] resultCode:', resultCode, 'scenario:', scenario);
  
  session.terminateSelfWithResult({
    resultCode: resultCode
  });
}