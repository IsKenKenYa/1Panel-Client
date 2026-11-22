import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export const testNetworkInputQueue = () => {
  const networkInputQueue = new rcp.NetworkInputQueue();
  
  let counter = 0;
  const interval = setInterval(() => {
    networkInputQueue.write('a counter ' + counter++);
    console.info(`networkInputQueue write`);
    
    if (counter === 10) {
      clearInterval(interval);
      networkInputQueue.close();
    }
  }, 1000);
  
  try {
    const session = rcp.createSession();
    console.info(`Post start.`);
    
    session.post('https://httpbin.org/anything', networkInputQueue).then((response) => {
      console.info(`Response status code is: ${response.statusCode}`);
      if (response && response.statusCode === 200) {
        console.info(`Post succeeded! response: ${response.toString()}`);
      } else {
        console.error(`Post failed.`);
      }
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Post error code is ${err.code}, error data is ${err.data}`);
      session.close();
    });
  } catch (err) {
    console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  }
}