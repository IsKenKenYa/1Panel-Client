import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function basicGetRequest(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/users';
    
    session.get(requestURL).then((response: rcp.Response) => {
      console.info(`GET Request succeeded`);
      console.info(`Status Code: ${response.statusCode}`);
      console.info(`Headers: ${JSON.stringify(response.headers)}`);
      console.info(`Body: ${JSON.stringify(response.body)}`);
      
      if (response.statusCode === 200) {
        const data = response.body;
        console.info('Data received successfully');
      } else {
        console.error(`HTTP Error: ${response.statusCode}`);
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`GET Request failed: code=${err.code}, message=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function basicPostRequest(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/users';
    
    const postData: rcp.RequestContent = {
      fields: {
        'username': 'john_doe',
        'email': 'john@example.com',
        'age': '30'
      }
    };
    
    const headers: rcp.RequestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_TOKEN'
    };
    
    const request = new rcp.Request(requestURL, 'POST', headers, postData);
    
    session.fetch(request).then((response: rcp.Response) => {
      console.info(`POST Request succeeded`);
      console.info(`Status Code: ${response.statusCode}`);
      console.info(`Response Body: ${JSON.stringify(response.body)}`);
      
      if (response.statusCode === 201) {
        console.info('User created successfully');
      } else if (response.statusCode === 400) {
        console.error('Bad Request: Invalid data');
      } else if (response.statusCode === 401) {
        console.error('Unauthorized: Invalid token');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`POST Request failed: code=${err.code}, message=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function basicPutRequest(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/users/123';
    
    const putData: rcp.RequestContent = {
      fields: {
        'username': 'john_doe_updated',
        'email': 'john_updated@example.com'
      }
    };
    
    session.put(requestURL, putData).then((response: rcp.Response) => {
      console.info(`PUT Request succeeded`);
      console.info(`Status Code: ${response.statusCode}`);
      
      if (response.statusCode === 200) {
        console.info('User updated successfully');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`PUT Request failed: code=${err.code}, message=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function basicHeadRequest(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/users/123';
    
    session.head(requestURL).then((response: rcp.Response) => {
      console.info(`HEAD Request succeeded`);
      console.info(`Status Code: ${response.statusCode}`);
      console.info(`Headers: ${JSON.stringify(response.headers)}`);
      
      const contentType = response.headers['Content-Type'];
      const lastModified = response.headers['Last-Modified'];
      console.info(`Content-Type: ${contentType}`);
      console.info(`Last-Modified: ${lastModified}`);
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`HEAD Request failed: code=${err.code}, message=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function basicDeleteRequest(): Promise<void> {
  try {
    const session = rcp.createSession();
    const requestURL = 'https://www.example.com/api/users/123';
    
    session.delete(requestURL).then((response: rcp.Response) => {
      console.info(`DELETE Request succeeded`);
      console.info(`Status Code: ${response.statusCode}`);
      
      if (response.statusCode === 204) {
        console.info('User deleted successfully');
      }
      
      session.close();
    }).catch((err: BusinessError) => {
      console.error(`DELETE Request failed: code=${err.code}, message=${err.data}`);
      session.close();
    });
  } catch (error) {
    console.error(`Exception: ${JSON.stringify(error)}`);
  }
}

async function main(): Promise<void> {
  console.info('=== Basic HTTP Request Examples ===');
  
  await basicGetRequest();
  await basicPostRequest();
  await basicPutRequest();
  await basicHeadRequest();
  await basicDeleteRequest();
  
  console.info('=== All requests completed ===');
}

export { basicGetRequest, basicPostRequest, basicPutRequest, basicHeadRequest, basicDeleteRequest, main };