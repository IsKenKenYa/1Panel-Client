import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class HttpFormExample {
  async sendSimpleForm(url: string): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info('Sending simple form data');
      
      const simpleForm = new rcp.Form({
        'username': 'john_doe',
        'password': 'secure_password',
        'email': 'john@example.com',
        'age': '30'
      });
      
      simpleForm.keys = ['username', 'password', 'email', 'age'];
      
      const request = new rcp.Request(url, 'POST');
      request.content = simpleForm;
      
      const response: rcp.Response = await session.fetch(request);
      
      console.info(`Form submitted successfully: ${response.statusCode}`);
      
      if (response.statusCode === 200) {
        console.info('Server accepted the form data');
      } else if (response.statusCode === 201) {
        console.info('Resource created successfully');
      }
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Form submission failed: ${err.code}, ${err.data}`);
    } finally {
      session.close();
    }
  }
  
  async sendMultipartForm(url: string): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info('Sending multipart form data');
      
      const multipartForm = new rcp.MultipartForm({
        'field1': 'value1',
        'field2': 'value2',
        'field3': 'value3',
        'field4': 'value4'
      });
      
      multipartForm.keys = ['field1', 'field2', 'field3', 'field4'];
      
      const request = new rcp.Request(url, 'POST');
      request.content = multipartForm;
      request.headers = {
        'Accept': 'application/json'
      };
      
      const response: rcp.Response = await session.fetch(request);
      
      console.info(`Multipart form sent: ${response.statusCode}`);
      console.info(`Response headers: ${JSON.stringify(response.headers)}`);
      
    } catch (error) {
      console.error(`Multipart form failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  async sendFormWithFiles(url: string): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info('Sending form with file data');
      
      const uploadFromFile: rcp.UploadFromFile = {
        fileOrPath: '/data/local/tmp/upload_file.txt'
      };
      
      const response: rcp.Response = await session.uploadFromFile(url, uploadFromFile);
      
      console.info(`File upload status: ${response.statusCode}`);
      
    } catch (error) {
      console.error(`File upload failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  async sendOrderedForm(url: string): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info('Sending ordered form data');
      
      const form = new rcp.Form({
        'step1': 'data1',
        'step2': 'data2',
        'step3': 'data3',
        'step4': 'data4'
      });
      
      form.keys = ['step4', 'step3', 'step2', 'step1'];
      
      console.info('Sending fields in reverse order');
      
      const request = new rcp.Request(url, 'POST');
      request.content = form;
      
      const response = await session.fetch(request);
      console.info(`Ordered form response: ${response.statusCode}`);
      
    } catch (error) {
      console.error(`Ordered form failed: ${error}`);
    } finally {
      session.close();
    }
  }
  
  async sendDynamicForm(url: string, formData: Record<string, string>, fieldOrder: string[]): Promise<void> {
    const session = rcp.createSession();
    
    try {
      console.info('Sending dynamic form data');
      
      const form = new rcp.Form(formData);
      form.keys = fieldOrder;
      
      const request = new rcp.Request(url, 'POST');
      request.content = form;
      
      const response = await session.fetch(request);
      console.info(`Dynamic form response: ${response.statusCode}`);
      
    } catch (error) {
      console.error(`Dynamic form failed: ${error}`);
    } finally {
      session.close();
    }
  }
}

export async function main(): Promise<void> {
  const example = new HttpFormExample();
  
  const apiUrl = 'https://www.example.com/api/submit';
  
  await example.sendSimpleForm(apiUrl);
  
  await example.sendMultipartForm(apiUrl);
  
  await example.sendFormWithFiles('https://www.example.com/upload');
  
  await example.sendOrderedForm(apiUrl);
  
  const dynamicData = {
    'name': 'Test User',
    'email': 'test@example.com',
    'phone': '1234567890'
  };
  const order = ['phone', 'email', 'name'];
  
  await example.sendDynamicForm(apiUrl, dynamicData, order);
}