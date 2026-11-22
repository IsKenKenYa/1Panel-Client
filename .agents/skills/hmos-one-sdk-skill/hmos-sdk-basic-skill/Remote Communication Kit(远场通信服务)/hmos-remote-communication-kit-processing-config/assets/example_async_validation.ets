import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function asyncValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com/api/data');
  
  const processing: rcp.ProcessingConfiguration = {
    validateResponse: async (response: rcp.Response): Promise<boolean> => {
      console.info(`Starting async validation...`);
      
      await new Promise<void>((resolve) => setTimeout(resolve, 100));
      
      if (response.statusCode !== 200) {
        console.error(`Status code validation failed: ${response.statusCode}`);
        return false;
      }
      
      const contentType = response.headers['content-type'];
      if (!contentType || !contentType.includes('application/json')) {
        console.error('Content-Type validation failed');
        return false;
      }
      
      if (!response.body) {
        console.error('Response body is empty');
        return false;
      }
      
      const decoder = new TextDecoder('utf-8');
      const jsonString = decoder.decode(response.body);
      
      try {
        const jsonData = JSON.parse(jsonString);
        console.info(`JSON data parsed successfully`);
        console.info(`Data keys: ${Object.keys(jsonData).join(', ')}`);
        return true;
      } catch (e) {
        console.error(`JSON parsing failed: ${e}`);
        return false;
      }
    },
  };
  
  request.configuration = {
    processing: processing,
  };
  
  try {
    const response = await session.fetch(request);
    console.info(`Async validation succeeded`);
    console.info(`Status code: ${response.statusCode}`);
    console.info(`Response body length: ${response.body?.byteLength || 0}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Async validation failed`);
    console.error(`Error code: ${error.code}`);
    console.error(`Error message: ${error.data}`);
  } finally {
    session.close();
  }
}

asyncValidation();