import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class CustomProcessingExample {
  private session: rcp.Session | null = null;

  async validateStatusCodeOnly(url: string): Promise<void> {
    try {
      this.session = rcp.createSession();
      const request = new rcp.Request(url);

      const processing: rcp.ProcessingConfiguration = {
        validateResponse: (response: rcp.Response): boolean => {
          return response.statusCode === 200;
        },
      };

      request.configuration = {
        processing: processing,
      };

      const response = await this.session.fetch(request);
      console.info(`Response received with status code: ${response.statusCode}`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Error: code=${err.code}, data=${err.data}`);
    } finally {
      this.closeSession();
    }
  }

  async validateResponseWithBody(url: string): Promise<void> {
    try {
      this.session = rcp.createSession();
      const request = new rcp.Request(url);

      request.configuration = {
        processing: {
          validateResponse: (response: rcp.Response): boolean => {
            if (response.statusCode !== 200) {
              return false;
            }
            if (!response.body || response.body.byteLength === 0) {
              return false;
            }
            return true;
          }
        }
      };

      const response = await this.session.fetch(request);
      console.info(`Valid response received, body size: ${response.body?.byteLength}`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Validation failed: code=${err.code}, message=${err.message}`);
    } finally {
      this.closeSession();
    }
  }

  async validateWithHeaders(url: string): Promise<void> {
    try {
      this.session = rcp.createSession();
      const request = new rcp.Request(url);
      request.headers = {
        'Accept': 'application/json'
      };

      request.configuration = {
        processing: {
          validateResponse: (response: rcp.Response): boolean => {
            if (response.statusCode !== 200) {
              return false;
            }
            const contentType = response.headers['Content-Type'];
            if (!contentType || !contentType.includes('application/json')) {
              console.warn('Unexpected Content-Type');
              return false;
            }
            return true;
          }
        }
      };

      const response = await this.session.fetch(request);
      console.info(`JSON response validated successfully`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Response validation error: ${err.message}`);
    } finally {
      this.closeSession();
    }
  }

  async validateAsync(url: string): Promise<void> {
    try {
      this.session = rcp.createSession();
      const request = new rcp.Request(url);

      request.configuration = {
        processing: {
          validateResponse: async (response: rcp.Response): Promise<boolean> => {
            await new Promise(resolve => setTimeout(resolve, 10));
            
            if (response.statusCode !== 200) {
              return false;
            }
            
            return true;
          }
        }
      };

      const response = await this.session.fetch(request);
      console.info(`Async validation completed, status: ${response.statusCode}`);
      
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Async validation error: ${err.code}`);
    } finally {
      this.closeSession();
    }
  }

  private closeSession(): void {
    if (this.session) {
      this.session.close();
      this.session = null;
      console.info('Session closed successfully');
    }
  }
}

export async function main(): Promise<void> {
  const example = new CustomProcessingExample();
  
  console.info('=== Test 1: Validate status code only ===');
  await example.validateStatusCodeOnly('https://www.example.com/api/test');
  
  console.info('\n=== Test 2: Validate response with body ===');
  await example.validateResponseWithBody('https://www.example.com/api/data');
  
  console.info('\n=== Test 3: Validate with headers ===');
  await example.validateWithHeaders('https://www.example.com/api/json');
  
  console.info('\n=== Test 4: Async validation ===');
  await example.validateAsync('https://www.example.com/api/async');
  
  console.info('\nAll tests completed');
}