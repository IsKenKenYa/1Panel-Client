import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SessionCloseExample {
  @State message: string = '准备发起HTTP请求';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      Button('发起请求并关闭会话')
        .fontSize(18)
        .padding(10)
        .onClick(() => {
          this.fetchAndCloseSession();
        })

      Button('错误处理并关闭会话')
        .fontSize(18)
        .padding(10)
        .margin({ top: 10 })
        .onClick(() => {
          this.fetchWithErrorHandling();
        })

      Button('使用finally确保关闭')
        .fontSize(18)
        .padding(10)
        .margin({ top: 10 })
        .onClick(() => {
          this.fetchWithFinally();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  async fetchAndCloseSession(): void {
    try {
      this.message = '创建Session...';
      const session = rcp.createSession();

      this.message = '发起HTTP请求...';
      let req = new rcp.Request("http://www.example.com/fetch", "GET");

      session.fetch(req).then((response) => {
        this.message = `请求成功: ${response.statusCode}`;
        console.info(`Response succeeded: ${JSON.stringify(response)}`);

        session.close();
        this.message += '\nSession已关闭';
        console.info('Session closed successfully');
      }).catch((err: BusinessError) => {
        this.message = `请求失败: code=${err.code}`;
        console.error(`Response error: code=${err.code}, message=${err.data}`);

        session.close();
        this.message += '\nSession已关闭(错误处理)';
        console.info('Session closed after error');
      });
    } catch (error) {
      this.message = `异常: ${error.message}`;
      console.error(`Unexpected error: ${error.message}`);
    }
  }

  async fetchWithErrorHandling(): void {
    const session = rcp.createSession();
    let req = new rcp.Request("http://www.example.com/invalid-url", "GET");

    try {
      this.message = '发起请求...';
      const response = await session.fetch(req);
      
      this.message = `请求成功: ${response.statusCode}`;
      console.info(`Response succeeded: ${response.statusCode}`);

      session.close();
      this.message += '\nSession已关闭';
    } catch (err) {
      const error = err as BusinessError;

      switch (error.code) {
        case 401:
          this.message = '参数错误';
          console.error('Parameter error');
          break;
        case 1007900001:
          this.message = '网络连接失败';
          console.error('Network connection failed');
          break;
        case 1007900002:
          this.message = '请求超时';
          console.error('Request timeout');
          break;
        default:
          this.message = `未知错误: code=${error.code}`;
          console.error(`Unknown error: code=${error.code}, message=${error.message}`);
      }

      session.close();
      this.message += '\nSession已关闭(错误处理)';
      console.info('Session closed after error handling');
    }
  }

  async fetchWithFinally(): void {
    let session: rcp.Session | null = null;

    try {
      this.message = '创建Session...';
      session = rcp.createSession();

      this.message = '发起请求...';
      let req = new rcp.Request("http://www.example.com/fetch", "GET");
      
      const response = await session.fetch(req);
      this.message = `请求成功: ${response.statusCode}`;
      console.info(`Response succeeded: ${response.statusCode}`);

    } catch (error) {
      this.message = `请求失败: ${error.message}`;
      console.error(`Error occurred: ${error.message}`);
    } finally {
      if (session) {
        session.close();
        this.message += '\nSession已关闭(finally)';
        console.info('Session closed in finally block');
      }
    }
  }

  async multipleSessionsExample(): void {
    const sessions: rcp.Session[] = [];

    try {
      this.message = '创建多个Session...';
      
      for (let i = 0; i < 3; i++) {
        const session = rcp.createSession();
        sessions.push(session);
        
        let req = new rcp.Request(`http://www.example.com/resource${i}`, "GET");
        session.fetch(req).then((response) => {
          console.info(`Request ${i} succeeded: ${response.statusCode}`);
        }).catch((err: BusinessError) => {
          console.error(`Request ${i} failed: ${err.code}`);
        });
      }

      this.message = '3个请求已发起';

      await new Promise(resolve => setTimeout(resolve, 2000));

      this.message = '关闭所有Session...';
      sessions.forEach((session, index) => {
        session.close();
        console.info(`Session ${index} closed`);
      });

      this.message += '\n所有Session已关闭';
    } catch (error) {
      this.message = `异常: ${error.message}`;
      console.error(`Error: ${error.message}`);
      
      sessions.forEach((session, index) => {
        if (session) {
          session.close();
          console.info(`Session ${index} closed in error handling`);
        }
      });
    }
  }

  async sessionWithConfiguration(): void {
    try {
      this.message = '创建配置Session...';
      
      const sessionConfig: rcp.SessionConfiguration = {
        requestConfiguration: {
          transfer: {
            timeout: {
              connectMs: 5000,
              transferMs: 10000
            }
          }
        }
      };

      const session = rcp.createSession(sessionConfig);
      
      this.message = '发起请求...';
      let req = new rcp.Request("http://www.example.com/api", "GET");
      
      const response = await session.fetch(req);
      this.message = `请求成功: ${response.statusCode}`;
      
      session.close();
      this.message += '\n配置Session已关闭';
    } catch (error) {
      this.message = `异常: ${error.message}`;
    }
  }
}