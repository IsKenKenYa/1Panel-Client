import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface ApiResponse {
  status: string;
  data: object;
  message?: string;
}

async function completeValidation(): Promise<void> {
  const session = rcp.createSession();
  const request = new rcp.Request('https://www.example.com/api/complete', 'GET');
  
  request.headers = {
    'Accept': 'application/json',
    'User-Agent': 'HarmonyOS-App/1.0'
  };
  
  const processing: rcp.ProcessingConfiguration = {
    validateResponse: async (response: rcp.Response): Promise<boolean> => {
      console.info('=== Starting complete validation ===');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        console.error(`Status code out of success range: ${response.statusCode}`);
        return false;
      }
      
      const contentType = response.headers['content-type'];
      if (!contentType) {
        console.error('Content-Type header is missing');
        return false;
      }
      
      const validContentTypes = [
        'application/json',
        'application/json; charset=utf-8',
        'application/json;charset=utf-8'
      ];
      
      const isValidContentType = validContentTypes.some(type => 
        contentType.toLowerCase().includes(type.toLowerCase())
      );
      
      if (!isValidContentType) {
        console.error(`Invalid Content-Type: ${contentType}`);
        return false;
      }
      
      if (!response.body) {
        console.error('Response body is empty');
        return false;
      }
      
      const decoder = new TextDecoder('utf-8');
      const jsonString = decoder.decode(response.body);
      
      let jsonData: ApiResponse;
      try {
        jsonData = JSON.parse(jsonString) as ApiResponse;
      } catch (e) {
        console.error(`JSON parsing failed: ${e}`);
        return false;
      }
      
      if (!jsonData.status || jsonData.status !== 'success') {
        console.error(`Invalid response status: ${jsonData.status}`);
        return false;
      }
      
      if (!jsonData.data) {
        console.error('Response data field is missing');
        return false;
      }
      
      console.info('=== All validations passed ===');
      console.info(`Status: ${jsonData.status}`);
      console.info(`Message: ${jsonData.message || 'No message'}`);
      
      return true;
    },
  };
  
  request.configuration = {
    processing: processing,
    transfer: {
      timeout: {
        connectMs: 5000,
        transferMs: 10000
      }
    }
  };
  
  try {
    const response = await session.fetch(request);
    console.info('=== Request completed successfully ===');
    console.info(`Final status code: ${response.statusCode}`);
    console.info(`Response headers: ${JSON.stringify(response.headers)}`);
    
    if (response.body) {
      const decoder = new TextDecoder('utf-8');
      const jsonString = decoder.decode(response.body);
      console.info(`Response body: ${jsonString}`);
    }
  } catch (err) {
    const error = err as BusinessError;
    console.error('=== Request validation failed ===');
    console.error(`Error code: ${error.code}`);
    console.error(`Error message: ${error.data}`);
    console.error(`Error details: ${JSON.stringify(error)}`);
  } finally {
    session.close();
    console.info('Session closed');
  }
}

completeValidation();