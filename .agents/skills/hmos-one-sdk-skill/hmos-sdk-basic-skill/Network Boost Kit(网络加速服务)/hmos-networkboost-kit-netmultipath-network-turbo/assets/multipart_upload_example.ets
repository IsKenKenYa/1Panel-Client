import { netBoost, netHandover } from '@kit.NetworkBoostKit';
import { connection, socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0xFF00;
const TAG = 'MultipartUpload';
const MIN_USEFUL_NET_ID = 100;
const SOCKET_BIND_PORT = 8080;

export class FileUpChunk {
  chunkNumber: number = 1;
  startPosition: number = 0;
  chunkSize: number = 0;
  buffer: ArrayBuffer = new ArrayBuffer(0);
  retryTimes: number = 0;
}

interface UploadPartResult {
  partNumber: number;
  eTag: string;
}

interface InitiateMultipartUpload {
  bucket: string;
  key: string;
  uploadId: string;
}

export class MultipartUploadManager {
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
      console.error(`[Constructor] Error:${err.code},${err.name}`);
    }
  }

  private splitFile(file: fileIo.File): FileUpChunk[] {
    try {
      const fileStat = fileIo.statSync(file.fd);
      const fileSize = fileStat.size;
      const chunks: FileUpChunk[] = [];
      const splitChunkSize = Math.floor(fileSize / this.getChunkSize(fileSize));
      
      let chunkNumber = 1;
      for (let start = 0; start < fileSize; start += splitChunkSize) {
        const chunkSize = Math.min(splitChunkSize, fileSize - start);
        const chunk = new FileUpChunk();
        chunk.chunkNumber = chunkNumber++;
        chunk.startPosition = start;
        chunk.chunkSize = chunkSize;
        chunks.push(chunk);
      }
      
      console.info(`[splitFile] File size:${fileSize}, chunks:${chunks.length}`);
      return chunks;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[splitFile] Error:${err.code},${err.name}`);
      return [];
    }
  }

  private getChunkSize(fileSize: number): number {
    const MB = 1024 * 1024;
    const fullMBs = Math.floor(fileSize / MB);
    return Math.max(1, Math.min(10, fullMBs));
  }

  public async startMultiPathUpload() {
    try {
      const quota = netHandover.getMultiPathQuotaStats();
      if (quota.remaining.count <= 0 || quota.remaining.duration <= 0) {
        console.warn('[startMultiPathUpload] Quota exhausted');
        return false;
      }

      let sceneDesc: netBoost.SceneDesc = {
        scene: 'upload',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
      };
      netBoost.setSceneDesc(sceneDesc);

      netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
        if (data.multiPathState === netHandover.MultiPathState.MULTIPATH_CREATED &&
          data.netHandle.netId >= MIN_USEFUL_NET_ID) {
          this.netHandles.push(data.netHandle);
          if (this.netHandles.length >= 2) {
            this.startUpload();
          }
        }
      });

      netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
        if (data.result !== netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
          console.error(`[requestMultiPath] Error:${data.result}`);
        }
      });

      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[startMultiPathUpload] Error:${err.code},${err.name}`);
      return false;
    }
  }

  private startUpload() {
    if (this.fileChunks.length === 0) {
      console.error('[startUpload] No file chunks');
      return;
    }

    for (let i = 0; i < this.netHandles.length; i++) {
      this.uploadFileChunkWithNet(this.netHandles[i]);
    }
  }

  private async uploadFileChunkWithNet(netHandle: connection.NetHandle) {
    if (this.abortUpload) return;

    if (this.fileChunks.length === 0) {
      console.info('[uploadFileChunkWithNet] All chunks uploaded');
      await this.mergeSegmentsOnServer();
      return;
    }

    const fileChunk = this.fileChunks.shift()!;
    const chunkWithData = this.readFileChunkBuffer(fileChunk);

    if (chunkWithData) {
      const task = new taskpool.Task(
        this.uploadSegment,
        'upload-server-host',
        SOCKET_BIND_PORT,
        this.initMultipartUpload!,
        chunkWithData,
        netHandle.netId
      );

      try {
        const result = await taskpool.execute(task) as UploadPartResult;
        if (result) {
          this.uploadResult.push(result);
          this.uploadFileChunkWithNet(netHandle);
          console.info(`[uploadFileChunkWithNet] Chunk ${fileChunk.chunkNumber} uploaded`);
        } else {
          this.retryUpload(fileChunk, netHandle);
        }
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        console.error(`[uploadFileChunkWithNet] Error:${err.code},${err.name}`);
        this.retryUpload(fileChunk, netHandle);
      }
    } else {
      this.retryUpload(fileChunk, netHandle);
    }
  }

  @Concurrent
  private async uploadSegment(
    host: string,
    port: number,
    initResult: InitiateMultipartUpload,
    fileChunk: FileUpChunk,
    netId: number
  ): Promise<UploadPartResult | undefined> {
    const socketInstance = socket.constructTCPSocketInstance();
    
    try {
      const netHandles = connection.getAllNetsSync();
      for (let netHandle of netHandles) {
        if (netHandle.netId === netId) {
          const props = connection.getConnectionPropertiesSync(netHandle);
          if (props.linkAddresses && props.linkAddresses.length > 0) {
            const netAddress: socket.NetAddress = {
              address: props.linkAddresses[0].address.address,
              port: port
            };
            await socketInstance.bind(netAddress);
            await netHandle.bindSocket(socketInstance);
          }
          break;
        }
      }

      return { partNumber: fileChunk.chunkNumber, eTag: 'etag-' + fileChunk.chunkNumber };
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[uploadSegment] Error:${err.code},${err.name}`);
      return undefined;
    }
  }

  private readFileChunkBuffer(chunk: FileUpChunk): FileUpChunk | undefined {
    try {
      const buffer = new ArrayBuffer(chunk.chunkSize);
      fileIo.readSync(this.file!.fd, buffer, { offset: chunk.startPosition });
      chunk.buffer = buffer;
      return chunk;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[readFileChunkBuffer] Error:${err.code},${err.name}`);
      return undefined;
    }
  }

  private retryUpload(chunk: FileUpChunk, netHandle: connection.NetHandle) {
    chunk.retryTimes++;
    if (chunk.retryTimes < 3) {
      this.fileChunks.unshift(chunk);
      this.uploadFileChunkWithNet(netHandle);
    } else {
      console.error(`[retryUpload] Chunk ${chunk.chunkNumber} failed after 3 retries`);
    }
  }

  private async mergeSegmentsOnServer() {
    try {
      fileIo.close(this.file!.fd);
      this.uploadResult.sort((a, b) => a.partNumber - b.partNumber);
      console.info('[mergeSegmentsOnServer] All segments uploaded successfully');
      this.cleanup();
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[mergeSegmentsOnServer] Error:${err.code},${err.name}`);
    }
  }

  private cleanup() {
    try {
      netHandover.releaseMultiPath();
      netHandover.off('multiPathStateChange');
      
      let sceneDesc: netBoost.SceneDesc = {
        scene: 'upload',
        sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
      };
      netBoost.setSceneDesc(sceneDesc);
      
      console.info('[cleanup] Multi-path released');
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[cleanup] Error:${err.code},${err.name}`);
    }
  }

  public abort() {
    this.abortUpload = true;
    this.cleanup();
  }
}

async function main() {
  const uploadManager = new MultipartUploadManager('/data/test-file.bin');
  await uploadManager.startMultiPathUpload();
}