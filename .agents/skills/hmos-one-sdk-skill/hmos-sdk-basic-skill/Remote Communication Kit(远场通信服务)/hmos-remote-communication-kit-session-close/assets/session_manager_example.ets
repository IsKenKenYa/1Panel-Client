import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class SessionManager {
  private activeSessions: Set<rcp.Session> = new Set();
  private closedSessions: Set<string> = new Set();
  
  registerSession(session: rcp.Session): void {
    this.activeSessions.add(session);
    console.info(`Session registered: ${session.id}`);
  }
  
  unregisterSession(session: rcp.Session): void {
    this.activeSessions.delete(session);
    console.info(`Session unregistered: ${session.id}`);
  }
  
  isSessionClosed(sessionId: string): boolean {
    return this.closedSessions.has(sessionId);
  }
  
  markSessionClosed(sessionId: string): void {
    this.closedSessions.add(sessionId);
  }
  
  closeSession(session: rcp.Session): void {
    if (this.isSessionClosed(session.id)) {
      console.warn(`Session ${session.id} already closed, skip operation`);
      return;
    }
    
    try {
      session.close();
      this.markSessionClosed(session.id);
      this.unregisterSession(session);
      console.info(`Session ${session.id} closed successfully`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to close session ${session.id}: code=${err.code}, message=${err.message}`);
    }
  }
  
  closeAllSessions(): void {
    console.info(`Closing ${this.activeSessions.size} active sessions`);
    
    this.activeSessions.forEach((session) => {
      this.closeSession(session);
    });
    
    console.info(`All sessions closed, remaining active: ${this.activeSessions.size}`);
  }
  
  getActiveSessionCount(): number {
    return this.activeSessions.size;
  }
  
  getClosedSessionCount(): number {
    return this.closedSessions.size;
  }
}

export class ManagedHttpRequest {
  private sessionManager: SessionManager;
  
  constructor(sessionManager: SessionManager) {
    this.sessionManager = sessionManager;
  }
  
  async performRequest(url: string, method: string = "GET"): Promise<rcp.Response | null> {
    const session = rcp.createSession();
    this.sessionManager.registerSession(session);
    
    try {
      const request = new rcp.Request(url, method);
      const response = await session.fetch(request);
      console.info(`Request to ${url} succeeded`);
      return response;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Request to ${url} failed: code=${err.code}, message=${err.data}`);
      return null;
    } finally {
      this.sessionManager.closeSession(session);
    }
  }
  
  async performMultipleRequests(urls: string[]): Promise<void> {
    for (const url of urls) {
      await this.performRequest(url);
    }
  }
}

export async function testSessionManager(): Promise<void> {
  const sessionManager = new SessionManager();
  const httpRequest = new ManagedHttpRequest(sessionManager);
  
  console.info('=== Testing Session Manager ===');
  
  await httpRequest.performRequest("http://www.example.com/api1");
  await httpRequest.performRequest("http://www.example.com/api2");
  
  console.info(`Active sessions: ${sessionManager.getActiveSessionCount()}`);
  console.info(`Closed sessions: ${sessionManager.getClosedSessionCount()}`);
  
  sessionManager.closeAllSessions();
  
  console.info(`After cleanup - Active: ${sessionManager.getActiveSessionCount()}`);
  console.info('=== Session Manager Test Completed ===');
}