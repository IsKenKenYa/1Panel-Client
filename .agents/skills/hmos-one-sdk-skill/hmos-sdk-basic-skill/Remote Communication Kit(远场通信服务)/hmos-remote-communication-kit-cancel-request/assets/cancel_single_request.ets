import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function cancelSingleRequestExample(): void {
  try {
    const session = rcp.createSession();
    let request1 = new rcp.Request("https://www.example.com/api/data");
    
    session.fetch(request1).then((response: rcp.Response) => {
      console.info(`Request1 succeeded with status code: ${response.statusCode}`);
      if (response.body) {
        console.info(`Response body: ${response.body}`);
      }
    }).catch((err: BusinessError) => {
      console.error(`Request1 failed with error code: ${err.code}, error data: ${err.data}`);
    });
    
    session.cancel(request1);
    console.info('Request1 has been canceled');
    
    session.close();
    console.info('Session closed');
  } catch (error) {
    console.error(`Error occurred: ${JSON.stringify(error)}`);
  }
}

export { cancelSingleRequestExample };