import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

class FdReadFile {
  readonly fd: number;
  
  constructor(fd: number) {
    this.fd = fd;
  }
  
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  }
}

export class FileUploader {
  private context: common.UIAbilityContext;
  
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }
  
  async uploadFile(filePath: string, uploadUrl: string): Promise<void> {
    const SESSION_CONFIG: rcp.SessionConfiguration = {
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 6000
          }
        },
        security: {
          remoteValidation: 'skip',
          tlsOptions: {
            tlsVersion: 'TlsV1.3'
          }
        }
      }
    };
    
    const session = rcp.createSession(SESSION_CONFIG);
    
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    
    if (!file) {
      console.error('Failed to open file');
      throw new Error('文件打开失败,请检查文件路径');
    }
    
    try {
      const fdReadFile = new FdReadFile(file.fd);
      const buffer = new ArrayBuffer(1024 * 1024);
      
      await fdReadFile.read(buffer);
      
      const response = await session.uploadFromFile(uploadUrl, new rcp.UploadFromFile(fdReadFile));
      
      console.info(`Upload succeeded, response: ${response}`);
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Upload failed: ${error.code}, ${error.data}`);
      
      switch (error.code) {
        case 1007900001:
          throw new Error('不支持的协议,请使用HTTP/HTTPS');
        case 1007900003:
          throw new Error('URL格式错误');
        case 13900002:
          throw new Error('文件不存在或无法读取');
        case 13900012:
          throw new Error('权限不足,无法读取文件');
        default:
          throw new Error(`上传失败: ${error.message}`);
      }
    } finally {
      fileIo.closeSync(file.fd);
      session.close();
    }
  }
  
  async uploadLargeFile(filePath: string, uploadUrl: string): Promise<void> {
    const SESSION_CONFIG: rcp.SessionConfiguration = {
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 30000,
            transferMs: 30000,
            inactivityMs: 30000
          }
        },
        security: {
          remoteValidation: 'skip',
          tlsOptions: {
            tlsVersion: 'TlsV1.3'
          }
        }
      }
    };
    
    const session = rcp.createSession(SESSION_CONFIG);
    const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
    
    if (!file) {
      throw new Error('文件打开失败');
    }
    
    try {
      const fdReadFile = new FdReadFile(file.fd);
      const stat = fileIo.statSync(filePath);
      
      const bufferSize = Math.min(stat.size, 5 * 1024 * 1024);
      const buffer = new ArrayBuffer(bufferSize);
      
      await fdReadFile.read(buffer);
      
      const response = await session.uploadFromFile(uploadUrl, new rcp.UploadFromFile(fdReadFile));
      console.info(`Large file upload succeeded: ${response}`);
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Large file upload failed: ${error.code}`);
      throw error;
    } finally {
      fileIo.closeSync(file.fd);
      session.close();
    }
  }
}

export async function testUpload(): Promise<void> {
  const context = getContext(this) as common.UIAbilityContext;
  const uploader = new FileUploader(context);
  
  const testFilePath = `${context.filesDir}/test_upload.txt`;
  
  try {
    await uploader.uploadFile(testFilePath, 'https://httpbin.org/anything');
    console.info('Upload test passed');
  } catch (error) {
    console.error(`Upload test failed: ${error.message}`);
  }
}