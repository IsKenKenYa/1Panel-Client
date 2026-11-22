import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class CloseSessionExample {
  static async basicCloseSession(): Promise<void> {
    const session = rcp.createSession();
    
    try {
      const request = new rcp.Request("http://www.example.com/fetch", "GET");
      const response = await session.fetch(request);
      console.info('Response succeeded:', response);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Response error: code=${err.code}, message=${err.data}`);
    } finally {
      session.close();
      console.info('Session closed successfully');
    }
  }
  
  static async closeSessionWithPostRequest(): Promise<void> {
    const session = rcp.createSession();
    
    try {
      const request = new rcp.Request("http://www.example.com/post", "POST");
      request.content = "data to send";
      
      const response = await session.fetch(request);
      console.info('POST Response succeeded:', response);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`POST Response error: code=${err.code}, message=${err.data}`);
    } finally {
      session.close();
      console.info('Session closed after POST request');
    }
  }
  
  static async multipleSequentialRequests(): Promise<void> {
    const session = rcp.createSession();
    
    try {
      const urls = [
        "http://www.example.com/api1",
        "http://www.example.com/api2",
        "http://www.example.com/api3"
      ];
      
      for (const url of urls) {
        const request = new rcp.Request(url, "GET");
        const response = await session.fetch(request);
        console.info(`Response from ${url}:`, response);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Sequential request error: code=${err.code}, message=${err.data}`);
    } finally {
      session.close();
      console.info('Session closed after sequential requests');
    }
  }
}

export function safeCloseSession(session: rcp.Session | null): void {
  if (session === null || session === undefined) {
    console.warn('Session is null, skip close operation');
    return;
  }
  
  try {
    session.close();
    console.info('Session closed successfully');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`Failed to close session: code=${err.code}, message=${err.message}`);
  }
}

export async function runAllExamples(): Promise<void> {
  console.info('=== Running CloseSession Examples ===');
  
  await CloseSessionExample.basicCloseSession();
  await CloseSessionExample.closeSessionWithPostRequest();
  await CloseSessionExample.multipleSequentialRequests();
  
  console.info('=== All Examples Completed ===');
}