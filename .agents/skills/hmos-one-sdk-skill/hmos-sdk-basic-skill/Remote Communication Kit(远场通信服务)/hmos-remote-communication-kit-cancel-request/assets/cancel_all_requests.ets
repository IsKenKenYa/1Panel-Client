import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function cancelAllRequestsExample(): void {
  try {
    const session = rcp.createSession();
    let request1 = new rcp.Request("https://www.example.com/api/data1");
    let request2 = new rcp.Request("https://www.example.com/api/data2");
    let request3 = new rcp.Request("https://www.example.com/api/data3");
    
    session.fetch(request1).then((response: rcp.Response) => {
      console.info(`Request1 succeeded with status code: ${response.statusCode}`);
    }).catch((err: BusinessError) => {
      console.error(`Request1 failed with error code: ${err.code}, error data: ${err.data}`);
    });
    
    session.fetch(request2).then((response: rcp.Response) => {
      console.info(`Request2 succeeded with status code: ${response.statusCode}`);
    }).catch((err: BusinessError) => {
      console.error(`Request2 failed with error code: ${err.code}, error data: ${err.data}`);
    });
    
    session.fetch(request3).then((response: rcp.Response) => {
      console.info(`Request3 succeeded with status code: ${response.statusCode}`);
    }).catch((err: BusinessError) => {
      console.error(`Request3 failed with error code: ${err.code}, error data: ${err.data}`);
    });
    
    session.cancel();
    console.info('All requests have been canceled');
    
    session.close();
    console.info('Session closed');
  } catch (error) {
    console.error(`Error occurred: ${JSON.stringify(error)}`);
  }
}

export { cancelAllRequestsExample };