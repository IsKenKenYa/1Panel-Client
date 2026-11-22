import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

export class FileDownloader {
  private context: common.UIAbilityContext;
  
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }
  
  async downloadFile(url: string, targetPath?: string): Promise<void> {
    const DOWNLOAD_TO_PATH = targetPath || this.context.filesDir;
    
    const securityConfig: rcp.SecurityConfiguration = {
      remoteValidation: 'skip'
    };
    
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 6000,
            transferMs: 6000,
            inactivityMs: 6000
          }
        },
        security: securityConfig
      }
    });
    
    try {
      if (fileIo.accessSync(DOWNLOAD_TO_PATH)) {
        fileIo.rmdirSync(DOWNLOAD_TO_PATH);
      }
      
      const downloadToFile: rcp.DownloadToFile = {
        kind: 'folder',
        path: DOWNLOAD_TO_PATH
      };
      
      const response = await session.downloadToFile(url, downloadToFile);
      
      console.info(`Successfully downloaded, statusCode: ${response.statusCode}`);
      console.info(`File saved to: ${DOWNLOAD_TO_PATH}`);
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Download failed, error code: ${error.code}, message: ${error.data}`);
      
      switch (error.code) {
        case 1007900003:
          throw new Error('URL格式错误,请检查URL格式是否正确');
        case 1007900006:
          throw new Error('域名解析失败,请检查网络连接');
        case 1007900007:
          throw new Error('连接服务器失败,请检查网络和服务器状态');
        case 1007900028:
          throw new Error('操作超时,请检查网络状况');
        default:
          throw new Error(`下载失败: ${error.message}`);
      }
    } finally {
      session.close();
    }
  }
  
  async downloadFileToSpecificPath(url: string, targetFilePath: string): Promise<void> {
    const securityConfig: rcp.SecurityConfiguration = {
      remoteValidation: 'skip'
    };
    
    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 10000,
            transferMs: 10000,
            inactivityMs: 10000
          }
        },
        security: securityConfig
      }
    });
    
    try {
      const downloadToFile: rcp.DownloadToFile = {
        kind: 'file',
        file: targetFilePath
      };
      
      const response = await session.downloadToFile(url, downloadToFile);
      
      console.info(`Download succeeded, statusCode: ${response.statusCode}`);
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Download failed: ${error.code}, ${error.data}`);
      throw error;
    } finally {
      session.close();
    }
  }
}

export async function testDownload(): Promise<void> {
  const context = getContext(this) as common.UIAbilityContext;
  const downloader = new FileDownloader(context);
  
  try {
    await downloader.downloadFile('https://example.com/test.png');
    console.info('Download test passed');
  } catch (error) {
    console.error(`Download test failed: ${error.message}`);
  }
}