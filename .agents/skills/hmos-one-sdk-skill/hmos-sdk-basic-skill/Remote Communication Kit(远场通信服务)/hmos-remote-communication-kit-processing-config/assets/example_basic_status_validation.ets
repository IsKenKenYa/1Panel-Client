import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

function basicStatusValidation(): void {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com/api/data');
  
  const processing: rcp.ProcessingConfiguration = {
    validateResponse: (response: rcp.Response): boolean => {
      console.info(`Received status code: ${response.statusCode}`);
      return response.statusCode === 200;
    },
  };
  
  request.configuration = {
    processing: processing,
  };
  
  session.fetch(request).then((response: rcp.Response) => {
    console.info(`Response validation succeeded`);
    console.info(`Status code: ${response.statusCode}`);
    console.info(`Response body length: ${response.body?.byteLength || 0}`);
    session.close();
  }).catch((err: BusinessError) => {
    console.error(`Response validation failed`);
    console.error(`Error code: ${err.code}`);
    console.error(`Error message: ${err.data}`);
    session.close();
  });
}

basicStatusValidation();