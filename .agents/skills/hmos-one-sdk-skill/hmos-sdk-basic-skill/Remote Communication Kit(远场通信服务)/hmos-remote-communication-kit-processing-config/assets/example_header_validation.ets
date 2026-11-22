import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function headerValidation(): void {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com/api/json');
  
  const processing: rcp.ProcessingConfiguration = {
    validateResponse: (response: rcp.Response): boolean => {
      if (response.statusCode !== 200) {
        console.error(`Status code validation failed: ${response.statusCode}`);
        return false;
      }
      
      const contentType = response.headers['content-type'];
      if (!contentType) {
        console.error('Content-Type header is missing');
        return false;
      }
      
      if (!contentType.includes('application/json')) {
        console.error(`Content-Type validation failed: ${contentType}`);
        return false;
      }
      
      const contentLength = response.headers['content-length'];
      if (contentLength) {
        console.info(`Content-Length: ${contentLength}`);
      }
      
      return true;
    },
  };
  
  request.configuration = {
    processing: processing,
  };
  
  session.fetch(request).then((response: rcp.Response) => {
    console.info(`Response validation succeeded`);
    console.info(`Content-Type: ${response.headers['content-type']}`);
    console.info(`Response body length: ${response.body?.byteLength || 0}`);
    session.close();
  }).catch((err: BusinessError) => {
    console.error(`Response validation failed`);
    console.error(`Error code: ${err.code}`);
    console.error(`Error message: ${err.data}`);
    session.close();
  });
}

headerValidation();