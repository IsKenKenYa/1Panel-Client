import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const EXAMPLE_URL = 'https://webdav.example.com/';

@Entry
@Component
struct WebDAVExample {
  private proppatchXml: string = `<propertyupdate xmlns="DAV:">
    <set>
      <prop>
        <displayname>Updated File Name</displayname>
      </prop>
    </set>
  </propertyupdate>`;
  
  private lockXml: string = `<lockinfo xmlns="DAV:">
    <locktype>
      <write/>
    </locktype>
    <lockscope>
      <exclusive/>
    </lockscope>
    <owner>
      <href>http://example.com/user</href>
    </owner>
  </lockinfo>`;
  
  private lockToken: string = '';

  build() {
    Column({ space: 10 }) {
      Button('WebDAV PUT (上传文件)')
        .onClick(() => {
          this.webdavPut();
        })
      
      Button('WebDAV GET (下载文件)')
        .onClick(() => {
          this.webdavGet();
        })
      
      Button('WebDAV MKCOL (创建目录)')
        .onClick(() => {
          this.webdavMkcol();
        })
      
      Button('WebDAV DELETE (删除文件)')
        .onClick(() => {
          this.webdavDelete();
        })
      
      Button('WebDAV COPY (复制文件)')
        .onClick(() => {
          this.webdavCopy();
        })
      
      Button('WebDAV MOVE (移动文件)')
        .onClick(() => {
          this.webdavMove();
        })
      
      Button('WebDAV PROPFIND (查询属性)')
        .onClick(() => {
          this.webdavPropfind();
        })
      
      Button('WebDAV PROPPATCH (修改属性)')
        .onClick(() => {
          this.webdavProppatch();
        })
      
      Button('WebDAV LOCK (锁定文件)')
        .onClick(() => {
          this.webdavLock();
        })
      
      Button('WebDAV UNLOCK (解锁文件)')
        .onClick(() => {
          this.webdavUnlock();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private webdavPut(): void {
    let httpRequest = http.createHttp();
    let file = 'example content';
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        expectDataType: http.HttpDataType.STRING,
        extraData: file,
        header: { 
          'Content-Type': 'text/plain; charset=utf-8', 
          'Content-Length': file.length.toString() 
        },
        customMethod: 'PUT'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'PUT Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'PUT code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'PUT error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavGet(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        expectDataType: http.HttpDataType.STRING,
        customMethod: 'GET'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'GET Result:' + data.result.toString());
          hilog.info(0x0000, 'WebDAVExample', 'GET code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'GET error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavMkcol(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'new-directory/',
      {
        expectDataType: http.HttpDataType.STRING,
        customMethod: 'MKCOL'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'MKCOL Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'MKCOL code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'MKCOL error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavDelete(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example/',
      {
        expectDataType: http.HttpDataType.STRING,
        header: { 'Content-Type': 'text/xml' },
        customMethod: 'DELETE'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'DELETE Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'DELETE code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'DELETE error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavCopy(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        expectDataType: http.HttpDataType.STRING,
        header: { 'Destination': EXAMPLE_URL + 'new_example.txt' },
        customMethod: 'COPY'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'COPY Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'COPY code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'COPY error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavMove(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        expectDataType: http.HttpDataType.STRING,
        header: { 'Destination': EXAMPLE_URL + 'reNameText.txt' },
        customMethod: 'MOVE'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'MOVE Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'MOVE code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'MOVE error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavPropfind(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        expectDataType: http.HttpDataType.STRING,
        header: {
          'Content-Type': 'text/xml',
          'Depth': '0'
        },
        customMethod: 'PROPFIND'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'PROPFIND Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'PROPFIND code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'PROPFIND error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavProppatch(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        extraData: this.proppatchXml,
        expectDataType: http.HttpDataType.STRING,
        header: { 'Content-Type': 'application/xml; charset=utf-8', 'Depth': 'infinity' },
        customMethod: 'PROPPATCH'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'PROPPATCH Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'PROPPATCH code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'PROPPATCH error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavLock(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        extraData: this.lockXml,
        expectDataType: http.HttpDataType.STRING,
        header: {
          'Content-Type': 'application/xml',
          'Depth': '0',
        },
        customMethod: 'LOCK'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          let lockTokenRegex = /<D:href>(urn:uuid:[a-fA-F0-9\-]+)<\/D:href>/;
          let statusMatch: RegExpMatchArray | null = (data.result as string).match(lockTokenRegex);
          if (statusMatch) {
            this.lockToken = statusMatch[1];
          }
          hilog.info(0x0000, 'WebDAVExample', 'LOCK Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'LOCK code:' + data.responseCode);
          hilog.info(0x0000, 'WebDAVExample', 'LOCK lockToken:' + this.lockToken);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'LOCK error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }

  private webdavUnlock(): void {
    let httpRequest = http.createHttp();
    
    httpRequest.request(EXAMPLE_URL + 'example.txt',
      {
        header: {
          'Content-Length': '0',
          'Lock-Token': this.lockToken,
          'Depth': '0'
        },
        customMethod: 'UNLOCK'
      },
      (err: Error, data: http.HttpResponse) => {
        if (!err) {
          hilog.info(0x0000, 'WebDAVExample', 'UNLOCK Result:' + data.result);
          hilog.info(0x0000, 'WebDAVExample', 'UNLOCK code:' + data.responseCode);
        } else {
          hilog.error(0x0000, 'WebDAVExample', 'UNLOCK error:' + JSON.stringify(err));
        }
        httpRequest.destroy();
      });
  }
}