import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class HttpPostExample {
  async submitData(url: string, data: Record<string, string | number>): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info(`Sending POST request to: ${url}`);
      
      const postContent: rcp.RequestContent = {
        fields: data
      };
      
      const response: rcp.Response = await session.post(url, postContent);
      
      console.info(`Response status code: ${response.statusCode}`);
      
      if (response.statusCode === 200 || response.statusCode === 201) {
        console.info('Data submitted successfully');
        
        if (response.body) {
          const decoder = new TextDecoder('utf-8');
          const result = decoder.decode(response.body);
          console.info(`Server response: ${result}`);
        }
      } else {
        console.warn(`Unexpected status code: ${response.statusCode}`);
      }
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`POST request failed: ${err.code}, ${err.data}`);
      this.handlePostError(err);
    } finally {
      session.close();
      console.info('Session closed');
    }
  }
  
  async submitJsonData(url: string, jsonData: object): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info(`Sending JSON POST request to: ${url}`);
      
      const request = new rcp.Request(url, 'POST');
      request.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      };
      request.content = JSON.stringify(jsonData);
      
      const response: rcp.Response = await session.fetch(request);
      
      console.info(`Response status code: ${response.statusCode}`);
      
      if (response.body) {
        const decoder = new TextDecoder('utf-8');
        const bodyString = decoder.decode(response.body);
        const responseData = JSON.parse(bodyString);
        console.info(`Response data: ${JSON.stringify(responseData)}`);
      }
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`JSON POST request failed: ${err.code}, ${err.data}`);
    } finally {
      session.close();
    }
  }
  
  async submitFormData(url: string, formData: Map<string, string>): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info(`Sending form POST request to: ${url}`);
      
      const fields: Record<string, string> = {};
      formData.forEach((value, key) => {
        fields[key] = value;
      });
      
      const response: rcp.Response = await session.post(url, { fields });
      
      console.info(`Form submitted: ${response.statusCode}`);
      
    } catch (error) {
      console.error(`Form POST failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  private handlePostError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Invalid request parameters');
        break;
      case 403:
        console.error('Permission denied or authentication failed');
        break;
      case 404:
        console.error('API endpoint not found');
        break;
      case 500:
        console.error('Server internal error');
        break;
      default:
        console.error(`Error: ${error.code}`);
    }
  }
}

export async function main(): Promise<void> {
  const example = new HttpPostExample();
  
  const apiUrl = 'https://www.example.com/api/create';
  const data = {
    'title': 'Test Item',
    'description': 'This is a test item',
    'price': 99.99,
    'quantity': 10
  };
  
  await example.submitData(apiUrl, data);
  
  const jsonData = {
    user: {
      name: 'John Doe',
      email: 'john@example.com'
    },
    items: [
      { id: 1, name: 'Item 1' },
      { id: 2, name: 'Item 2' }
    ]
  };
  
  await example.submitJsonData('https://www.example.com/api/json', jsonData);
  
  const formData = new Map<string, string>();
  formData.set('username', 'testuser');
  formData.set('password', 'testpass');
  formData.set('remember', 'true');
  
  await example.submitFormData('https://www.example.com/login', formData);
}