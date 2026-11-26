import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  EventChannel,
  StreamHandler,
  EventSink,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { request } from '@kit.BasicServicesKit';
import { url as urlModule, util } from '@kit.ArkTS';
import { fileIo as fs, picker } from '@kit.CoreFileKit';

const TAG = 'OhosDownloadPlugin';
const METHOD_CHANNEL = 'onepanel/ohos_download';
const EVENT_CHANNEL = 'onepanel/ohos_download_progress';

interface DownloadEntry {
  taskId: string;
  url: string;
  savedDir: string;
  fileName: string;
  status: string;
  bytesReceived: number;
  totalBytes: number;
  filePath: string;
  targetUri: string | null;
  task: request.DownloadTask;
}

class ProgressStreamHandler implements StreamHandler {
  private sink: EventSink | null = null;

  onListen(args: Object, events: EventSink): void {
    this.sink = events;
  }

  onCancel(args: Object): void {
    this.sink = null;
  }

  release(): void {
    this.sink = null;
  }

  sendEvent(data: Object): void {
    this.sink?.success(data);
  }
}

export default class OhosDownloadPlugin implements FlutterPlugin, MethodCallHandler {
  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private streamHandler: ProgressStreamHandler = new ProgressStreamHandler();
  private applicationContext: common.Context | null = null;
  private uiAbilityContext: common.UIAbilityContext | null = null;
  private downloads: Map<string, DownloadEntry> = new Map<string, DownloadEntry>();

  constructor(uiAbilityContext?: common.UIAbilityContext) {
    this.uiAbilityContext = uiAbilityContext ?? null;
  }

  getUniqueClassName(): string {
    return 'OhosDownloadPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext() as common.Context;
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL);
    this.eventChannel.setStreamHandler(this.streamHandler);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.methodChannel?.setMethodCallHandler(null);
    this.eventChannel?.setStreamHandler(null);
    this.streamHandler.release();
    this.downloads.forEach((entry: DownloadEntry): void => {
      this.removeListeners(entry.task);
      entry.task.delete().then((): void => {
        if (entry.status !== 'completed' && fs.accessSync(entry.filePath)) {
          fs.unlinkSync(entry.filePath);
        }
      }).catch((error: Error): void => {
        Log.e(TAG, `Failed to release download task: ${error}`);
      });
    });
    this.downloads.clear();
    this.methodChannel = null;
    this.eventChannel = null;
    this.applicationContext = null;
    this.uiAbilityContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.handleMethodCall(call, result);
  }

  private async handleMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case 'enqueue':
          result.success(await this.enqueue(call));
          return;
        case 'pause':
          await this.pauseDownload(this.taskArgument(call));
          result.success(null);
          return;
        case 'resume':
          await this.resumeDownload(this.taskArgument(call));
          result.success(null);
          return;
        case 'cancel':
          await this.cancelDownload(this.taskArgument(call));
          result.success(null);
          return;
        case 'delete':
          await this.deleteTask(this.taskArgument(call));
          result.success(null);
          return;
        case 'getProgress': {
          const entry = this.downloads.get(this.taskArgument(call));
          result.success(entry === undefined ? null : this.progressMap(entry));
          return;
        }
        case 'listTasks': {
          const tasks: Record<string, Object>[] = [];
          this.downloads.forEach((entry: DownloadEntry): void => {
            const item = this.progressMap(entry);
            item['url'] = entry.url;
            item['savedDir'] = entry.savedDir;
            item['fileName'] = entry.fileName;
            tasks.push(item);
          });
          result.success(tasks);
          return;
        }
        case 'saveDownloadedFile': {
          const entry = this.downloads.get(this.taskArgument(call));
          result.success(entry?.status === 'completed' ? entry.targetUri ?? entry.filePath : null);
          return;
        }
        default:
          result.notImplemented();
      }
    } catch (error) {
      Log.e(TAG, `Failed to handle ${call.method}`, error);
      result.error('ohos_download_error', `${error}`, null);
    }
  }

  private async enqueue(call: MethodCall): Promise<string | null> {
    const context = this.requireContext();
    const url = this.requireStringArgument(call, 'url');
    const explicitName = call.argument('fileName') as string | null;
    const pathname = urlModule.URL.parseURL(url).pathname;
    const lastSegment = pathname.substring(pathname.lastIndexOf('/') + 1);
    const derivedName = lastSegment.length > 0 ? decodeURIComponent(lastSegment) : 'download';
    const fileName = (explicitName ?? derivedName).replace(/[<>:"/\\|?*]/g, '_');
    const taskId = util.generateRandomUUID();
    const usePicker = (call.argument('usePicker') as boolean | null) ?? true;
    let targetUri: string | null = null;
    if (usePicker) {
      if (this.uiAbilityContext === null) {
        throw new Error('UIAbility context is required to choose a download location');
      }
      const documentPicker = new picker.DocumentViewPicker(this.uiAbilityContext);
      const locations = await documentPicker.save({ newFileNames: [fileName] });
      if (locations.length === 0) return null;
      targetUri = locations[0];
    }
    if (this.applicationContext !== context) {
      throw new Error('Download plugin is not attached');
    }

    const requestedDir = call.argument('savedDir') as string | null;
    const savedDir = requestedDir !== null && requestedDir.length > 0
      ? requestedDir : `${context.filesDir}/Download`;
    const directory = targetUri === null ? savedDir : `${context.cacheDir}/downloads`;
    if (!fs.accessSync(directory)) fs.mkdirSync(directory, true);
    const filePath = targetUri === null
      ? this.nextAvailablePath(directory, fileName) : `${directory}/${taskId}`;
    const rawHeaders = call.argument('headers') as Map<string, string> | null;
    const headers: Record<string, string> = { 'Accept-Encoding': 'identity' };
    rawHeaders?.forEach((headerValue: string, headerName: string): void => {
      headers[headerName] = headerValue;
    });
    const task = await request.downloadFile(context, {
      url,
      header: headers,
      filePath,
      enableMetered: true,
    });
    if (this.applicationContext !== context) {
      await task.delete();
      throw new Error('Download plugin is not attached');
    }
    const entry: DownloadEntry = {
      taskId,
      url,
      savedDir,
      fileName,
      status: 'running',
      bytesReceived: 0,
      totalBytes: 0,
      filePath,
      targetUri,
      task,
    };
    this.downloads.set(taskId, entry);
    task.on('progress', (received: number, total: number): void => {
      if (entry.status !== 'running') return;
      entry.bytesReceived = received;
      entry.totalBytes = total;
      this.sendProgress(entry);
    });
    task.on('pause', (): void => {
      entry.status = 'paused';
      this.sendProgress(entry);
    });
    task.on('complete', (): void => {
      this.completeDownload(entry).catch((error: Error): void => {
        entry.status = 'failed';
        Log.e(TAG, `Failed to save completed download: ${error}`);
        this.sendProgress(entry);
      });
    });
    task.on('fail', (code: number): void => {
      entry.status = 'failed';
      Log.e(TAG, `Download failed with code ${code}`);
      this.sendProgress(entry);
    });
    this.sendProgress(entry);
    return taskId;
  }

  private async completeDownload(entry: DownloadEntry): Promise<void> {
    if (this.downloads.get(entry.taskId) !== entry) return;
    if (entry.targetUri !== null) {
      const file = fs.openSync(entry.targetUri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        await fs.copyFile(entry.filePath, file.fd);
      } finally {
        fs.closeSync(file);
      }
      fs.unlinkSync(entry.filePath);
    }
    if (this.downloads.get(entry.taskId) !== entry) return;
    entry.status = 'completed';
    if (entry.totalBytes > 0) entry.bytesReceived = entry.totalBytes;
    this.sendProgress(entry);
  }

  private async pauseDownload(taskId: string): Promise<void> {
    const entry = this.requireTask(taskId);
    if (entry.status !== 'running') return;
    if (!await entry.task.suspend()) throw new Error('Download could not be paused');
    entry.status = 'paused';
    this.sendProgress(entry);
  }

  private async resumeDownload(taskId: string): Promise<void> {
    const entry = this.requireTask(taskId);
    if (entry.status !== 'paused') return;
    if (!await entry.task.restore()) throw new Error('Download could not be resumed');
    entry.status = 'running';
    this.sendProgress(entry);
  }

  private async cancelDownload(taskId: string): Promise<void> {
    const entry = this.requireTask(taskId);
    this.removeListeners(entry.task);
    await entry.task.delete();
    entry.status = 'cancelled';
    if (fs.accessSync(entry.filePath)) fs.unlinkSync(entry.filePath);
    this.sendProgress(entry);
    this.downloads.delete(taskId);
  }

  private async deleteTask(taskId: string): Promise<void> {
    const entry = this.requireTask(taskId);
    if (entry.status === 'running' || entry.status === 'paused') {
      await this.cancelDownload(taskId);
      return;
    }
    this.removeListeners(entry.task);
    await entry.task.delete();
    this.downloads.delete(taskId);
  }

  private removeListeners(task: request.DownloadTask): void {
    task.off('progress');
    task.off('pause');
    task.off('complete');
    task.off('fail');
  }

  private progressMap(entry: DownloadEntry): Record<string, Object> {
    const progress = entry.status === 'completed' ? 100 : entry.totalBytes > 0
      ? Math.floor(entry.bytesReceived / entry.totalBytes * 100) : 0;
    return {
      'taskId': entry.taskId,
      'bytesReceived': entry.bytesReceived,
      'totalBytes': entry.totalBytes,
      'status': entry.status,
      'progress': progress,
    };
  }

  private sendProgress(entry: DownloadEntry): void {
    if (this.downloads.get(entry.taskId) === entry) {
      this.streamHandler.sendEvent(this.progressMap(entry));
    }
  }

  private nextAvailablePath(directory: string, fileName: string): string {
    const lastDot = fileName.lastIndexOf('.');
    const baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
    const extension = lastDot > 0 ? fileName.substring(lastDot) : '';
    let candidate = `${directory}/${fileName}`;
    let counter = 1;
    while (fs.accessSync(candidate)) {
      candidate = `${directory}/${baseName}_${counter}${extension}`;
      counter += 1;
    }
    return candidate;
  }

  private requireContext(): common.Context {
    if (this.applicationContext === null) throw new Error('Download plugin is not attached');
    return this.applicationContext;
  }

  private requireTask(taskId: string): DownloadEntry {
    const entry = this.downloads.get(taskId);
    if (entry === undefined) throw new Error(`Download task does not exist: ${taskId}`);
    return entry;
  }

  private taskArgument(call: MethodCall): string {
    return this.requireStringArgument(call, 'taskId');
  }

  private requireStringArgument(call: MethodCall, key: string): string {
    const content = call.argument(key) as string | null;
    if (content === null || content.length === 0) throw new Error(`Missing argument: ${key}`);
    return content;
  }
}
