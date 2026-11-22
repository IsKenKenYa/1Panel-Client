import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function handleBasicErrors(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/data';
    
    session.get(requestURL).then((response: rcp.Response) => {
      console.info(`Request succeeded: statusCode=${response.statusCode}`);
      session.close();
    }).catch((err: BusinessError) => {
      switch (err.code) {
        case 401:
          console.error('Parameter error: Invalid request parameters');
          console.error('Please check URL, method, headers, content format');
          break;
        case 1007900994:
          console.error('Sessions number reached limit');
          console.error('Maximum 1024 session instances allowed');
          console.error('Please close unused sessions');
          break;
        default:
          console.error(`Unknown error: code=${err.code}, message=${err.data}`);
      }
      session.close();
    });
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Exception caught: code=${err.code}, message=${err.data}`);
  }
}

async function handleHttpStatusErrors(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/resource';
    
    session.get(requestURL).then((response: rcp.Response) => {
      switch (response.statusCode) {
        case 200:
          console.info('Success: Request completed successfully');
          break;
        case 201:
          console.info('Created: Resource created successfully');
          break;
        case 204:
          console.info('No Content: Request successful, no content returned');
          break;
        case 400:
          console.error('Bad Request: Invalid request syntax');
          console.error('Please check request parameters');
          break;
        case 401:
          console.error('Unauthorized: Authentication required');
          console.error('Please provide valid credentials');
          break;
        case 403:
          console.error('Forbidden: Access denied');
          console.error('Please check permissions');
          break;
        case 404:
          console.error('Not Found: Resource does not exist');
          console.error('Please check URL path');
          break;
        case 500:
          console.error('Internal Server Error: Server error occurred');
          console.error('Please try again later');
          break;
        case 502:
          console.error('Bad Gateway: Invalid response from upstream server');
          break;
        case 503:
          console.error('Service Unavailable: Server temporarily unavailable');
          break;
        default:
          console.error(`HTTP Status Code: ${response.statusCode}`);
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Request failed: ${err.code}, ${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function handleNetworkErrors(): Promise<void> {
  try {
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
    const requestURL = 'https://www.example.com/api/timeout-test';
    
    session.get(requestURL).then((response: rcp.Response) => {
      console.info(`Network request succeeded`);
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Network error occurred`);
      
      if (err.code === -1) {
        console.error('Network connection failed');
        console.error('Please check network connectivity');
      } else if (err.code === -2) {
        console.error('DNS resolution failed');
        console.error('Please check domain name');
      } else if (err.code === -3) {
        console.error('Connection timeout');
        console.error('Please increase timeout settings or check server status');
      } else if (err.code === -4) {
        console.error('SSL/TLS certificate error');
        console.error('Please check certificate configuration');
      }
      
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function handlePermissionErrors(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/secure-data';
    
    session.get(requestURL).then((response: rcp.Response) => {
      console.info(`Request succeeded`);
      session.close();
    }).catch((err: BusinessError) => {
      if (err.code === 201) {
        console.error('Permission denied: ohos.permission.INTERNET required');
        console.error('Please add permission in module.json5');
      } else if (err.code === 202) {
        console.error('Permission denied: ohos.permission.GET_NETWORK_INFO required');
        console.error('Required for cellular network access');
      } else {
        console.error(`Error: ${err.code}, ${err.data}`);
      }
      
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function fallbackWithRetry(): Promise<void> {
  const maxRetries = 3;
  let retryCount = 0;
  
  async function attemptRequest(): Promise<rcp.Response | null> {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/unstable';
    
    try {
      const response = await session.get(requestURL);
      session.close();
      return response;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Attempt ${retryCount + 1} failed: ${error.code}`);
      session.close();
      return null;
    }
  }
  
  while (retryCount < maxRetries) {
    const response = await attemptRequest();
    if (response && response.statusCode === 200) {
      console.info(`Request succeeded on attempt ${retryCount + 1}`);
      break;
    }
    retryCount++;
    
    if (retryCount < maxRetries) {
      console.info(`Retrying... (${retryCount}/${maxRetries})`);
      await new Promise(resolve => setTimeout(resolve, 1000));
    } else {
      console.error('Max retries reached, using fallback');
    }
  }
}

async function gracefulDegradation(): Promise<void> {
  try {
    const session = rcp.createSession();
    const primaryURL = 'https://www.example.com/api/primary';
    
    session.get(primaryURL).then((response: rcp.Response) => {
      if (response.statusCode === 200) {
        console.info('Primary endpoint succeeded');
      } else {
        throw new Error(`Primary endpoint failed with status ${response.statusCode}`);
      }
      session.close();
    }).catch(async (err: BusinessError) => {
      console.error('Primary endpoint failed, trying fallback');
      session.close();
      
      const fallbackSession = rcp.createSession();
      const fallbackURL = 'https://www.example.com/api/fallback';
      
      fallbackSession.get(fallbackURL).then((fallbackResponse: rcp.Response) => {
        if (fallbackResponse.statusCode === 200) {
          console.info('Fallback endpoint succeeded');
        } else {
          console.error('Both endpoints failed, using cached data');
        }
        fallbackSession.close();
      }).catch((fallbackErr: BusinessError) => {
        console.error('Fallback failed, using cached data');
        fallbackSession.close();
      });
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function main(): Promise<void> {
  console.info('=== Error Handling Examples ===');
  
  await handleBasicErrors();
  await handleHttpStatusErrors();
  await handleNetworkErrors();
  await handlePermissionErrors();
  await fallbackWithRetry();
  await gracefulDegradation();
  
  console.info('=== All error handling examples completed ===');
}

export { handleBasicErrors, handleHttpStatusErrors, handleNetworkErrors, handlePermissionErrors, fallbackWithRetry, gracefulDegradation, main };