/**
 * HTTP文件上传示例
 * 展示多部分表单数据(Multipart/Form-Data)文件上传
 */

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fs } from '@kit.CoreFileKit';

@Entry
@Component
struct HttpFileUpload {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private readonly DOMAIN: number = 0x0000;
  private readonly TAG: string = 'HttpFileUpload';
  
  @State uploadStatus: string = '准备上传';

  build() {
    Column({ space: 15 }) {
      Text('HTTP文件上传示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      
      Text(this.uploadStatus)
        .fontSize(16)
      
      Button('上传单个文件')
        .onClick(() => {
          this.uploadSingleFile();
        })
      
      Button('上传多个文件')
        .onClick(() => {
          this.uploadMultipleFiles();
        })
      
      Button('上传文件和文本数据')
        .onClick(() => {
          this.uploadFileWithText();
        })
      
      Button('上传图片文件')
        .onClick(() => {
          this.uploadImageFile();
        })
    }
    .width('100%')
    .padding(20)
  }

  /**
   * 上传单个文件示例
   */
  private uploadSingleFile(): void {
    let httpRequest = http.createHttp();
    this.uploadStatus = '正在上传单个文件...';
    
    // 准备文件路径
    const filePath = `${this.context.filesDir}/document.txt`;
    
    // 创建文件用于上传(示例)
    this.createTestFile(filePath, 'This is a test file content');
    
    httpRequest.request(
      'https://example.com/upload/single',
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: [
          {
            name: 'file', // 表单字段名
            contentType: 'text/plain', // 文件类型
            filePath: filePath, // 文件沙箱路径
            remoteFileName: 'document.txt' // 远程文件名
          }
        ]
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.uploadStatus = '上传成功';
          hilog.info(this.DOMAIN, this.TAG, `文件上传成功,响应码: ${data.responseCode}`);
          hilog.info(this.DOMAIN, this.TAG, `响应内容: ${data.result}`);
          
          if (data.responseCode === 200) {
            hilog.info(this.DOMAIN, this.TAG, '服务器已接收文件');
          }
        } else {
          this.uploadStatus = '上传失败';
          hilog.error(this.DOMAIN, this.TAG, `文件上传失败: ${err.message}`);
          
          if (err.code === 2300025) {
            hilog.error(this.DOMAIN, this.TAG, '上传失败,请检查文件路径');
          } else if (err.code === 2300026) {
            hilog.error(this.DOMAIN, this.TAG, '无法读取本地文件');
          }
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 上传多个文件示例
   */
  private uploadMultipleFiles(): void {
    let httpRequest = http.createHttp();
    this.uploadStatus = '正在上传多个文件...';
    
    // 准备多个文件路径
    const filePath1 = `${this.context.filesDir}/file1.txt`;
    const filePath2 = `${this.context.filesDir}/file2.txt`;
    const filePath3 = `${this.context.filesDir}/file3.json`;
    
    // 创建测试文件
    this.createTestFile(filePath1, 'Content of file 1');
    this.createTestFile(filePath2, 'Content of file 2');
    this.createTestFile(filePath3, JSON.stringify({ key: 'value' }));
    
    httpRequest.request(
      'https://example.com/upload/multiple',
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: [
          {
            name: 'files', // 多文件上传使用相同字段名
            contentType: 'text/plain',
            filePath: filePath1,
            remoteFileName: 'file1.txt'
          },
          {
            name: 'files',
            contentType: 'text/plain',
            filePath: filePath2,
            remoteFileName: 'file2.txt'
          },
          {
            name: 'files',
            contentType: 'application/json',
            filePath: filePath3,
            remoteFileName: 'file3.json'
          }
        ]
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.uploadStatus = '多文件上传成功';
          hilog.info(this.DOMAIN, this.TAG, `多文件上传成功,响应码: ${data.responseCode}`);
        } else {
          this.uploadStatus = '多文件上传失败';
          hilog.error(this.DOMAIN, this.TAG, `多文件上传失败: ${err.message}`);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 上传文件和文本数据示例
   */
  private uploadFileWithText(): void {
    let httpRequest = http.createHttp();
    this.uploadStatus = '正在上传文件和文本数据...';
    
    const filePath = `${this.context.filesDir}/data.csv`;
    this.createTestFile(filePath, 'id,name,value\n1,test,100\n2,example,200');
    
    httpRequest.request(
      'https://example.com/upload/mixed',
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'multipart/form-data'
        },
        multiFormDataList: [
          {
            name: 'description', // 文本数据字段
            contentType: 'text/plain',
            data: 'This is a CSV data file', // 文本内容
            remoteFileName: 'description.txt'
          },
          {
            name: 'csvFile', // 文件字段
            contentType: 'text/csv',
            filePath: filePath,
            remoteFileName: 'data.csv'
          },
          {
            name: 'metadata', // JSON数据字段
            contentType: 'application/json',
            data: JSON.stringify({
              uploadTime: new Date().toISOString(),
              fileType: 'CSV',
              userId: 12345
            }),
            remoteFileName: 'metadata.json'
          }
        ]
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.uploadStatus = '混合数据上传成功';
          hilog.info(this.DOMAIN, this.TAG, `文件和文本上传成功,响应码: ${data.responseCode}`);
        } else {
          this.uploadStatus = '混合数据上传失败';
          hilog.error(this.DOMAIN, this.TAG, `上传失败: ${err.message}`);
        }
        httpRequest.destroy();
      }
    );
  }

  /**
   * 上传图片文件示例
   */
  private uploadImageFile(): void {
    let httpRequest = http.createHttp();
    this.uploadStatus = '正在上传图片文件...';
    
    const imagePath = `${this.context.filesDir}/image.png`;
    
    // 检查文件是否存在
    try {
      const stat = fs.statSync(imagePath);
      hilog.info(this.DOMAIN, this.TAG, `图片文件大小: ${stat.size} bytes`);
      
      httpRequest.request(
        'https://example.com/upload/image',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'multipart/form-data'
          },
          multiFormDataList: [
            {
              name: 'image',
              contentType: 'image/png', // 图片类型
              filePath: imagePath,
              remoteFileName: 'upload_image.png'
            }
          ]
        },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err) {
            this.uploadStatus = '图片上传成功';
            hilog.info(this.DOMAIN, this.TAG, `图片上传成功,响应码: ${data.responseCode}`);
            
            // 解析服务器返回的图片URL
            try {
              const result = JSON.parse(data.result as string);
              if (result.imageUrl) {
                hilog.info(this.DOMAIN, this.TAG, `图片URL: ${result.imageUrl}`);
              }
            } catch (parseError) {
              hilog.warn(this.DOMAIN, this.TAG, '无法解析响应数据');
            }
          } else {
            this.uploadStatus = '图片上传失败';
            hilog.error(this.DOMAIN, this.TAG, `图片上传失败: ${err.message}`);
          }
          httpRequest.destroy();
        }
      );
      
    } catch (error) {
      this.uploadStatus = '图片文件不存在';
      hilog.error(this.DOMAIN, this.TAG, `图片文件不存在: ${error}`);
      hilog.info(this.DOMAIN, this.TAG, `请先准备图片文件到路径: ${imagePath}`);
    }
  }

  /**
   * 创建测试文件
   */
  private createTestFile(filePath: string, content: string): void {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      hilog.info(this.DOMAIN, this.TAG, `测试文件已创建: ${filePath}`);
    } catch (error) {
      hilog.error(this.DOMAIN, this.TAG, `创建测试文件失败: ${error}`);
    }
  }
}