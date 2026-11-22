import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function sendSimpleFormData(): Promise<void> {
  try {
    const session = rcp.createSession();
    
    const simpleForm = new rcp.Form({
      'username': 'john_doe',
      'password': 'secure_password',
      'remember_me': 'true'
    });
    
    simpleForm.keys = ['password', 'username', 'remember_me'];
    
    let req = new rcp.Request('https://www.example.com/login', 'POST');
    req.content = simpleForm;
    
    session.fetch(req).then((resp: rcp.Response) => {
      console.info(`Form request succeeded`);
      console.info(`Status Code: ${resp.statusCode}`);
      console.info(`Response: ${JSON.stringify(resp.body)}`);
      
      if (resp.statusCode === 200) {
        console.info('Login successful');
      } else {
        console.error('Login failed');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Form request failed: code=${err.code}, data=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function sendMultipartFormData(): Promise<void> {
  try {
    const session = rcp.createSession();
    
    const multiForm = new rcp.MultipartForm({
      'user_id': '123',
      'username': 'john_doe',
      'email': 'john@example.com',
      'bio': 'Software developer'
    });
    
    multiForm.keys = ['user_id', 'username', 'email', 'bio'];
    
    let req = new rcp.Request('https://www.example.com/api/profile', 'POST');
    req.content = multiForm;
    
    req.headers = {
      'Authorization': 'Bearer YOUR_TOKEN'
    };
    
    session.fetch(req).then((resp: rcp.Response) => {
      console.info(`MultipartForm request succeeded`);
      console.info(`Status Code: ${resp.statusCode}`);
      
      if (resp.statusCode === 200) {
        console.info('Profile updated successfully');
      } else if (resp.statusCode === 400) {
        console.error('Invalid form data');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`MultipartForm request failed: code=${err.code}, data=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function sendFormDataWithFile(): Promise<void> {
  try {
    const session = rcp.createSession();
    
    const uploadFromFile: rcp.UploadFromFile = {
      fileOrPath: '/path/to/file.pdf'
    };
    
    const multiForm = new rcp.MultipartForm({
      'document_type': 'pdf',
      'description': 'Project documentation'
    });
    
    let req = new rcp.Request('https://www.example.com/api/upload', 'POST');
    req.content = multiForm;
    
    session.uploadFromFile(req.url.toString(), uploadFromFile).then((resp: rcp.Response) => {
      console.info(`File upload succeeded`);
      console.info(`Status Code: ${resp.statusCode}`);
      
      if (resp.statusCode === 201) {
        console.info('File uploaded successfully');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`File upload failed: code=${err.code}, data=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function sendFormWithValidation(): Promise<void> {
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
    
    const formData = new rcp.Form({
      'name': 'John Doe',
      'email': 'john@example.com',
      'phone': '1234567890'
    });
    
    formData.keys = ['name', 'email', 'phone'];
    
    let req = new rcp.Request('https://www.example.com/api/submit', 'POST');
    req.content = formData;
    req.headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization': 'Bearer YOUR_TOKEN'
    };
    
    session.fetch(req).then((resp: rcp.Response) => {
      console.info(`Form validation request succeeded`);
      console.info(`Status Code: ${resp.statusCode}`);
      
      if (resp.statusCode === 200) {
        const result = resp.body;
        if (typeof result === 'object' && result !== null) {
          const resultObj = result as Record<string, string>;
          if (resultObj['success'] === 'true') {
            console.info('Form submitted and validated successfully');
          } else {
            console.error(`Validation failed: ${resultObj['message']}`);
          }
        }
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`Form validation request failed: code=${err.code}, data=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function main(): Promise<void> {
  console.info('=== Form Data Request Examples ===');
  
  await sendSimpleFormData();
  await sendMultipartFormData();
  await sendFormDataWithFile();
  await sendFormWithValidation();
  
  console.info('=== All form requests completed ===');
}

export { sendSimpleFormData, sendMultipartFormData, sendFormDataWithFile, sendFormWithValidation, main };