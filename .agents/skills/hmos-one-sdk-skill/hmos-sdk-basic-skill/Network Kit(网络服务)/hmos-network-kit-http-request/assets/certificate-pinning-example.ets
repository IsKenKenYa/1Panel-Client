import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct CertificatePinningExample {
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    Column({ space: 10 }) {
      Button('使用CA证书发起HTTPS请求')
        .onClick(() => {
          this.httpRequestWithCaCert();
        })
      
      Button('使用客户端证书发起HTTPS请求')
        .onClick(() => {
          this.httpRequestWithClientCert();
        })
      
      Button('使用证书锁定发起HTTPS请求')
        .onClick(() => {
          this.httpRequestWithCertificatePinning();
        })
      
      Button('跳过SSL证书校验（仅用于测试）')
        .onClick(() => {
          this.httpRequestSkipSslVerification();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private httpRequestWithCaCert(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request('https://example.com/api/data', {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      caPath: '/data/storage/el1/bundle/entry/resources/resfile/cacert.pem',
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'CertPinningExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'CertPinningExample', `code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'CertPinningExample', `error: ${JSON.stringify(err)}`);
      }
      httpRequest.destroy();
    });
  }

  private httpRequestWithClientCert(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request('https://example.com/api/data', {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      clientCert: {
        certPath: '/data/storage/el1/bundle/entry/resources/resfile/client.pem',
        keyPath: '/data/storage/el1/bundle/entry/resources/resfile/client.key',
        certType: http.CertType.PEM,
        keyPassword: 'passwordToKey'
      },
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'CertPinningExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'CertPinningExample', `code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'CertPinningExample', `error: ${JSON.stringify(err)}`);
      }
      httpRequest.destroy();
    });
  }

  private httpRequestWithCertificatePinning(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request('https://example.com/api/data', {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      certificatePinning: [
        {
          publicKeyHash: 'FEDCBA9876543210ABCDEF1234567890',
          hashAlgorithm: 'SHA-256'
        },
        {
          publicKeyHash: 'ABCDEF1234567890FEDCBA9876543210',
          hashAlgorithm: 'SHA-256'
        }
      ],
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'CertPinningExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'CertPinningExample', `code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'CertPinningExample', `error: ${JSON.stringify(err)}`);
        if (err.code === 2300060) {
          hilog.error(0x0000, 'CertPinningExample', 'Invalid SSL peer certificate - Certificate pinning failed');
        }
      }
      httpRequest.destroy();
    });
  }

  private httpRequestSkipSslVerification(): void {
    let httpRequest = http.createHttp();
    
    hilog.warn(0x0000, 'CertPinningExample', 'WARNING: Skipping SSL verification - Only use for testing!');
    
    httpRequest.request('https://example.com/api/data', {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      remoteValidation: 'skip',
      connectTimeout: 60000,
      readTimeout: 60000
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err) {
        hilog.info(0x0000, 'CertPinningExample', `Result: ${JSON.stringify(data.result)}`);
        hilog.info(0x0000, 'CertPinningExample', `code: ${JSON.stringify(data.responseCode)}`);
      } else {
        hilog.error(0x0000, 'CertPinningExample', `error: ${JSON.stringify(err)}`);
      }
      httpRequest.destroy();
    });
  }
}