import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class HttpGetExample {
  async fetchData(url: string): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info(`Sending GET request to: ${url}`);
      
      const response: rcp.Response = await session.get(url);
      
      console.info(`Response status code: ${response.statusCode}`);
      console.info(`Response headers: ${JSON.stringify(response.headers)}`);
      
      if (response.body) {
        const decoder = new TextDecoder('utf-8');
        const bodyString = decoder.decode(response.body);
        console.info(`Response body: ${bodyString}`);
        
        try {
          const jsonData = JSON.parse(bodyString);
          console.info(`Parsed JSON data: ${JSON.stringify(jsonData)}`);
        } catch (parseError) {
          console.warn('Response is not JSON format');
        }
      }
      
      console.info('GET request completed successfully');
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`GET request failed: ${err.code}, ${err.data}`);
      
      this.handleGetError(err);
    } finally {
      session.close();
      console.info('Session closed');
    }
  }
  
  private handleGetError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error: Check URL format and request parameters');
        break;
      case 1007900994:
        console.error('Session limit reached: Close unused sessions');
        break;
      case 403:
        console.error('Permission denied: Check ohos.permission.INTERNET permission');
        break;
      case 404:
        console.error('Resource not found: Check URL path');
        break;
      case 500:
        console.error('Server error: Contact server administrator');
        break;
      default:
        console.error(`Unknown error: ${error.code}, ${error.data}`);
    }
  }
  
  async fetchMultipleUrls(urls: string[]): Promise<void[]> {
    const promises: Promise<void>[] = urls.map(url => this.fetchData(url));
    return Promise.all(promises);
  }
}

export async function main(): Promise<void> {
  const example = new HttpGetExample();
  
  const testUrl = 'https://www.example.com/api/data';
  await example.fetchData(testUrl);
  
  const multipleUrls = [
    'https://www.example.com/api/users',
    'https://www.example.com/api/products',
    'https://www.example.com/api/orders'
  ];
  
  try {
    await example.fetchMultipleUrls(multipleUrls);
    console.info('All requests completed successfully');
  } catch (error) {
    console.error('Some requests failed');
  }
}