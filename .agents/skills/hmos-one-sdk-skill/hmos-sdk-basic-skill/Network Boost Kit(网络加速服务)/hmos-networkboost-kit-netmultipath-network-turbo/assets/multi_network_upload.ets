import { netBoost, netHandover } from '@kit.NetworkBoostKit';
import { connection, socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { buffer } from '@kit.ArkTS';

const DOMAIN = 0xFF00;
const TAG = 'MultiNetworkUpload';
const MIN_USEFUL_NET_ID = 100;

export class FileUpChunk {
  chunkNumber: number = 1;
  startPosition: number = 0;
  chunkSize: number = 0;
  buffer: ArrayBuffer = new ArrayBuffer(0);
  retryTimes: number = 0;
}

export interface InitiateMultipartUpload {
  bucket: string;
  key: string;
  uploadId: string;
}

export interface UploadPartResult {
  partNumber: number;
  eTag: string;
}

export interface NetHandleChange {
  onMultiNetSuccess: (netHandle: connection.NetHandle) => void;
  onMultiNetRelease: (netHandle: connection.NetHandle) => void;
}

export class MultiNetworkUploader {
  private file: fileIo.File | undefined;
  private fileChunks: FileUpChunk[] = [];
  private netHandles: connection.NetHandle[] = [];
  private uploadResult: UploadPartResult[] = [];
  private initMultipartUpload: InitiateMultipartUpload | undefined;
  private abortUpload: boolean = false;

  constructor(filePath: string) {
    try {
      this.file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      this.fileChunks = this.splitFile(this.file);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[${TAG}] Open file error: ${err.code}, ${err.message}`);
    }
  }

  setUploadSceneDesc(enter: boolean): boolean {
    try {
      let sceneDesc: netBoost.SceneDesc = {
        scene: 'upload',
        sceneEvent: enter ? netBoost.SceneEvent.SCENE_EVENT_ENTER : netBoost.SceneEvent.SCENE_EVENT_LEAVE
      };
      netBoost.setSceneDesc(sceneDesc);
      console.info(`[${TAG}] Scene set to ${enter ? 'enter' : 'leave'} upload`);
      return true;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] setSceneDesc Error: ${error.code}, ${error.message}`);
      return false;
    }
  }

  getMultiPathQuota(): netHandover.MultiPathQuota | undefined {
    try {
      let quota: netHandover.MultiPathQuota = netHandover.getMultiPathQuotaStats();
      console.info(`[${TAG}] Quota: used=${quota.used.count}, remaining=${quota.remaining.count}`);
      return quota;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] getMultiPathQuotaStats Error: ${error.code}, ${error.message}`);
      return undefined;
    }
  }

  async requestMultiPath(): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
          if (data && data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
            console.info(`[${TAG}] MultiPath requested successfully`);
            resolve(true);
          } else {
            console.error(`[${TAG}] MultiPath request failed: ${data.result}`);
            resolve(false);
          }
        });
      } catch (err) {
        const error: BusinessError = err as BusinessError;
        console.error(`[${TAG}] requestMultiPath Error: ${error.code}, ${error.message}`);
        resolve(false);
      }
    });
  }

  setOnMultiPathStateChange(netHandleChange: NetHandleChange) {
    try {
      netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
        if (data.multiPathState === netHandover.MultiPathState.MULTIPATH_CREATED &&
          data.netHandle.netId >= MIN_USEFUL_NET_ID) {
          console.info(`[${TAG}] MultiPath created: netId=${data.netHandle.netId}`);
          this.netHandles.push(data.netHandle);
          netHandleChange?.onMultiNetSuccess(data.netHandle);
        } else if (data.multiPathState === netHandover.MultiPathState.MULTIPATH_CREATING) {
          console.info(`[${TAG}] MultiPath creating: netId=${data.netHandle.netId}`);
        } else {
          console.info(`[${TAG}] MultiPath released: netId=${data.netHandle.netId}`);
          netHandleChange?.onMultiNetRelease(data.netHandle);
        }
      });
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] on multiPathStateChange Error: ${error.code}, ${error.message}`);
    }
  }

  getAllNetHandles(): connection.NetHandle[] | undefined {
    try {
      let netHandles = connection.getAllNetsSync();
      const usefulNetHandles: connection.NetHandle[] = [];
      for (let i = 0; i < netHandles.length; i++) {
        console.info(`[${TAG}] Net[${i}]: netId=${netHandles[i].netId}`);
        if (netHandles[i].netId >= MIN_USEFUL_NET_ID) {
          usefulNetHandles.push(netHandles[i]);
        }
      }
      return usefulNetHandles;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] getAllNetsSync Error: ${error.code}, ${error.message}`);
      return undefined;
    }
  }

  async bindSpecifiedNet(socketInstance: socket.TCPSocket, netId: number, port: number) {
    const netHandles = this.getAllNetHandles();
    if (netHandles) {
      for (let i = 0; i < netHandles.length; i++) {
        if (netHandles[i].netId === netId) {
          try {
            const connectionProperties = connection.getConnectionPropertiesSync(netHandles[i]);
            if (connectionProperties && connectionProperties.linkAddresses &&
              connectionProperties.linkAddresses.length > 0) {
              let netAddress: socket.NetAddress = {
                address: connectionProperties.linkAddresses[0].address.address,
                port: port
              };
              await socketInstance.bind(netAddress);
              await netHandles[i].bindSocket(socketInstance);
              console.info(`[${TAG}] Socket bound to netId=${netId}`);
            } else {
              console.error(`[${TAG}] Get ConnectionProperties error`);
            }
          } catch (err) {
            const error: BusinessError = err as BusinessError;
            console.error(`[${TAG}] bindSocket Error: ${error.code}, ${error.message}`);
          }
          break;
        }
      }
    } else {
      console.error(`[${TAG}] Net list empty`);
    }
  }

  splitFile(file: fileIo.File): FileUpChunk[] {
    try {
      const fileStat = fileIo.statSync(file.fd);
      const fileSize = fileStat.size;
      const chunks: FileUpChunk[] = [];
      let chunkNumber = 1;
      const splitChunkSize = Math.floor(fileSize / this.getChunkSize(fileSize));
      
      for (let start = 0; start < fileSize; start += splitChunkSize) {
        const chunkSize = Math.min(splitChunkSize, fileSize - start);
        const chunk = new FileUpChunk();
        chunk.chunkNumber = chunkNumber++;
        chunk.startPosition = start;
        chunk.chunkSize = chunkSize;
        chunks.push(chunk);
      }
      
      console.info(`[${TAG}] File split into ${chunks.length} chunks`);
      return chunks;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[${TAG}] splitFile Error: ${err.code}, ${err.message}`);
      return [];
    }
  }

  getChunkSize(fileSize: number): number {
    const MB = 1024 * 1024;
    const fullMBs = Math.floor(fileSize / MB);
    let res = Math.max(1, Math.min(500, fullMBs));
    console.info(`[${TAG}] FileSize: ${fileSize}, ChunkCount: ${res}`);
    return res;
  }

  readFileChunkBuffer(file: fileIo.File, chunk: FileUpChunk): FileUpChunk | undefined {
    try {
      const buffer = new ArrayBuffer(chunk.chunkSize);
      fileIo.readSync(file.fd, buffer, { offset: chunk.startPosition });
      chunk.buffer = buffer;
      return chunk;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[${TAG}] readFileChunkBuffer Error: ${err.code}, ${err.message}`);
      return undefined;
    }
  }

  async uploadFileChunkWithNet(netHandle: connection.NetHandle) {
    if (this.abortUpload) {
      return;
    }
    if (this.fileChunks.length === 0) {
      console.info(`[${TAG}] All chunks uploaded`);
      this.mergeSegmentsOnServer();
      return;
    }

    const fileChunk = this.fileChunks.shift()!;
    let fileChunkWithData = this.readFileChunkBuffer(this.file!, fileChunk);

    if (fileChunkWithData) {
      const task = new taskpool.Task(
        this.uploadSegment,
        'your.server.host',
        8080,
        this.initMultipartUpload!,
        fileChunkWithData,
        netHandle.netId
      );

      try {
        const uploadPartRes = await taskpool.execute(task);
        if (uploadPartRes) {
          this.uploadResult.push(uploadPartRes as UploadPartResult);
          this.uploadFileChunkWithNet(netHandle);
        } else {
          this.retryUpload(fileChunk, netHandle);
        }
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`[${TAG}] taskpool Error: ${err.code}, ${err.message}`);
        this.retryUpload(fileChunk, netHandle);
      }
    } else {
      this.retryUpload(fileChunk, netHandle);
    }
  }

  @Concurrent
  async uploadSegment(host: string, port: number, initResult: InitiateMultipartUpload,
    fileChunk: FileUpChunk, netId: number): Promise<UploadPartResult | undefined> {
    const socketInstance: socket.TCPSocket = socket.constructTCPSocketInstance();
    await this.bindSpecifiedNet(socketInstance, netId, 8080);
    
    const path = `/${initResult.key}?partNumber=${fileChunk.chunkNumber}&uploadId=${initResult.uploadId}`;
    const headers = [
      `Host: ${host}`,
      `Content-Length: ${fileChunk.chunkSize}`,
      `Content-Type: application/octet-stream`
    ];
    
    const requestHeader = `PUT ${path} HTTP/1.1\r\n` + headers.join('\r\n') + '\r\n\r\n';
    const headerBuffer = buffer.from(requestHeader, 'utf-8').buffer;
    
    const requestBuffer = new Uint8Array(headerBuffer.byteLength + fileChunk.buffer.byteLength);
    requestBuffer.set(new Uint8Array(headerBuffer), 0);
    requestBuffer.set(new Uint8Array(fileChunk.buffer), headerBuffer.byteLength);
    
    try {
      await socketInstance.connect({
        address: { address: host, port: port, family: socket.NetFamily.IPv4 },
        timeout: 60000
      });
      
      await socketInstance.send({ data: requestBuffer.buffer });
      
      socketInstance.on('message', (value: socket.SocketMessageInfo) => {
        const responseStr = buffer.from(value.message).toString('utf-8');
        const eTagMatch = responseStr.match(/ETag: "([^"]+)"/);
        if (eTagMatch && eTagMatch[1]) {
          return {
            partNumber: fileChunk.chunkNumber,
            eTag: eTagMatch[1]
          } as UploadPartResult;
        }
      });
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] uploadSegment Error: ${error.code}, ${error.message}`);
    }
    
    return undefined;
  }

  retryUpload(fileChunk: FileUpChunk, netHandle: connection.NetHandle) {
    fileChunk.retryTimes++;
    if (fileChunk.retryTimes < 3) {
      this.fileChunks.unshift(fileChunk);
      this.uploadFileChunkWithNet(netHandle);
    } else {
      console.error(`[${TAG}] Chunk ${fileChunk.chunkNumber} failed after 3 retries`);
      this.abortUpload = true;
      this.releaseMultiPath();
    }
  }

  async mergeSegmentsOnServer() {
    if (this.file) {
      fileIo.close(this.file.fd).catch((error: BusinessError) => {
        console.error(`[${TAG}] Close file error: ${error.code}, ${error.message}`);
      });
    }
    
    this.uploadResult.sort((a, b) => a.partNumber - b.partNumber);
    console.info(`[${TAG}] Upload completed, ${this.uploadResult.length} parts uploaded`);
    this.releaseMultiPath();
  }

  releaseMultiPath() {
    try {
      netHandover.releaseMultiPath();
      console.info(`[${TAG}] MultiPath released`);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] releaseMultiPath Error: ${error.code}, ${error.message}`);
    }
  }

  setOffMultiPathStateChange() {
    try {
      netHandover.off('multiPathStateChange');
      console.info(`[${TAG}] MultiPath state listener removed`);
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`[${TAG}] off multiPathStateChange Error: ${error.code}, ${error.message}`);
    }
  }

  async startUpload() {
    if (!this.fileChunks || this.fileChunks.length === 0) {
      console.error(`[${TAG}] No file chunks to upload`);
      return;
    }

    const quota = this.getMultiPathQuota();
    if (!quota || quota.remaining.count <= 0) {
      console.error(`[${TAG}] Insufficient quota`);
      return;
    }

    if (!this.setUploadSceneDesc(true)) {
      console.error(`[${TAG}] Failed to set scene`);
      return;
    }

    const requested = await this.requestMultiPath();
    if (!requested) {
      console.error(`[${TAG}] Failed to request multiPath`);
      this.setUploadSceneDesc(false);
      return;
    }

    this.setOnMultiPathStateChange({
      onMultiNetSuccess: async (netHandle: connection.NetHandle) => {
        console.info(`[${TAG}] Starting upload with netId=${netHandle.netId}`);
        this.uploadFileChunkWithNet(netHandle);
      },
      onMultiNetRelease: async (netHandle: connection.NetHandle) => {
        console.info(`[${TAG}] NetHandle released: ${netHandle.netId}`);
      }
    });

    setTimeout(() => {
      if (this.netHandles.length === 0) {
        console.error(`[${TAG}] No netHandles available after timeout`);
        this.abortUpload = true;
        this.releaseMultiPath();
        this.setOffMultiPathStateChange();
        this.setUploadSceneDesc(false);
      }
    }, 10000);
  }
}

async function main() {
  const uploader = new MultiNetworkUploader('/path/to/your/file.zip');
  await uploader.startUpload();
}

main();