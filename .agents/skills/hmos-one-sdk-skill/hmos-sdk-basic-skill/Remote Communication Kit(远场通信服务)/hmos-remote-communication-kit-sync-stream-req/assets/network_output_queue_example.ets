import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export const testNetworkOutputQueue = () => {
  const networkOutputQueue = new rcp.NetworkOutputQueue();
  
  try {
    const session = rcp.createSession();
    const numOfChunks = 10;
    const chunkLength = 1000;
    const totalBytes = numOfChunks * chunkLength;
    
    session.get('https://httpbin.org/bytes/' + totalBytes.toString(), networkOutputQueue).then((response) => {
      if (response && response.statusCode === 200) {
        console.info(`get bytes succeeded.`);
      } else {
        console.error(`get bytes failed.`);
      }
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`get bytes error code is ${err.code}, error data is ${err.data}`);
      session.close();
    });
    
    let totalGetLength = 0;
    const intervalId = setInterval(() => {
      const chunk = networkOutputQueue.read(chunkLength);
      totalGetLength += chunk.byteLength;
      console.info(`get bytes totalGetLength: ${totalGetLength}`);
      
      if (totalGetLength === totalBytes) {
        clearInterval(intervalId);
        console.info(`get bytes finished.`);
      }
    }, 1000);
  } catch (err) {
    console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  }
}

export const testNetworkOutputQueueWithParams = (maxSize: number, chunkLength: number, numOfChunks: number) => {
  const networkOutputQueue = new rcp.NetworkOutputQueue(maxSize);
  
  try {
    const session = rcp.createSession();
    const totalBytes = numOfChunks * chunkLength;
    
    session.get('https://httpbin.org/bytes/' + totalBytes.toString(), networkOutputQueue).then((response) => {
      if (response && response.statusCode === 200) {
        console.info(`get bytes succeeded.`);
      } else {
        console.error(`get bytes failed.`);
      }
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`get bytes error code is ${err.code}, error data is ${err.data}`);
      session.close();
    });
    
    let totalGetLength = 0;
    const intervalId = setInterval(() => {
      const chunk = networkOutputQueue.read(chunkLength);
      totalGetLength += chunk.byteLength;
      console.info(`get bytes totalGetLength: ${totalGetLength}, stored: ${networkOutputQueue.getStoredBytes()}`);
      
      if (totalGetLength === totalBytes) {
        clearInterval(intervalId);
        console.info(`get bytes finished.`);
      }
    }, 1000);
  } catch (err) {
    console.error(`create session error code is ${err.code}, error data is ${err.data}`);
  }
}