import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ErrorHandler {
  static handleSessionCloseError(error: BusinessError): void {
    console.error('Session close error occurred:');
    console.error(`  Error code: ${error.code}`);
    console.error(`  Error message: ${error.message}`);
    console.error(`  Error data: ${JSON.stringify(error.data)}`);
    
    switch (error.code) {
      case 401:
        console.error('  Reason: Parameter error - Session object may be invalid');
        console.error('  Solution: Check if session is created properly');
        break;
      case 1007900994:
        console.error('  Reason: Sessions number reached limit');
        console.error('  Solution: Close unnecessary sessions to free resources');
        break;
      default:
        console.error('  Reason: Unknown error');
        console.error('  Solution: Log error and continue cleanup process');
    }
  }
  
  static safeCloseWithRetry(session: rcp.Session, maxRetries: number = 3): boolean {
    let retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        session.close();
        console.info('Session closed successfully');
        return true;
      } catch (error) {
        retryCount++;
        const err = error as BusinessError;
        console.error(`Close attempt ${retryCount} failed: code=${err.code}`);
        
        if (retryCount < maxRetries) {
          console.info('Retrying close operation...');
        } else {
          console.error('Max retries reached, close operation failed');
          ErrorHandler.handleSessionCloseError(err);
          return false;
        }
      }
    }
    
    return false;
  }
}

export class GracefulShutdown {
  private sessions: Map<string, rcp.Session> = new Map();
  
  addSession(id: string, session: rcp.Session): void {
    this.sessions.set(id, session);
    console.info(`Session ${id} added to shutdown manager`);
  }
  
  removeSession(id: string): void {
    this.sessions.delete(id);
    console.info(`Session ${id} removed from shutdown manager`);
  }
  
  async gracefulShutdown(): Promise<void> {
    console.info('=== Starting graceful shutdown ===');
    console.info(`Total sessions to close: ${this.sessions.size}`);
    
    const closePromises: Promise<void>[] = [];
    
    this.sessions.forEach((session, id) => {
      const closePromise = new Promise<void>((resolve) => {
        try {
          session.close();
          console.info(`Session ${id} closed successfully`);
          this.removeSession(id);
        } catch (error) {
          const err = error as BusinessError;
          console.error(`Session ${id} close failed: code=${err.code}`);
          ErrorHandler.handleSessionCloseError(err);
        }
        resolve();
      });
      
      closePromises.push(closePromise);
    });
    
    await Promise.all(closePromises);
    
    console.info('=== Graceful shutdown completed ===');
    console.info(`Remaining sessions: ${this.sessions.size}`);
  }
  
  async emergencyShutdown(): Promise<void> {
    console.warn('=== Starting emergency shutdown ===');
    
    this.sessions.forEach((session, id) => {
      try {
        session.close();
        console.info(`Session ${id} emergency closed`);
      } catch (error) {
        console.error(`Session ${id} emergency close failed, but continuing`);
      }
    });
    
    this.sessions.clear();
    console.warn('=== Emergency shutdown completed, all sessions cleared ===');
  }
}

export async function testErrorHandling(): Promise<void> {
  console.info('=== Testing Error Handling ===');
  
  const shutdownManager = new GracefulShutdown();
  
  const session1 = rcp.createSession();
  const session2 = rcp.createSession();
  
  shutdownManager.addSession('session1', session1);
  shutdownManager.addSession('session2', session2);
  
  try {
    const request1 = new rcp.Request("http://www.example.com/api1", "GET");
    await session1.fetch(request1);
  } catch (error) {
    console.error('Request failed, but session will be closed anyway');
  }
  
  await shutdownManager.gracefulShutdown();
  
  console.info('=== Error Handling Test Completed ===');
}

export async function testRetryMechanism(): Promise<void> {
  console.info('=== Testing Retry Mechanism ===');
  
  const session = rcp.createSession();
  
  const success = ErrorHandler.safeCloseWithRetry(session, 3);
  
  if (success) {
    console.info('Session closed with retry mechanism');
  } else {
    console.error('Session close failed after all retries');
  }
  
  console.info('=== Retry Mechanism Test Completed ===');
}