import {
  FlutterPlugin,
  FlutterPluginBinding,
  FlutterManager,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import bundleManager from '@ohos.bundle.bundleManager';
import deviceInfo from '@ohos.deviceInfo';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';
import OhosDownloadPlugin from './OhosDownloadPlugin';

const TAG = 'OhosPlatformPlugin';
const CHANNEL = 'onepanel/ohos_platform';

interface OhosRuntimeInfo {
  deviceType: string;
  brand: string;
  productModel: string;
  osFullName: string;
  displayVersion: string;
  sdkApiVersion: number;
  appFilesDir: string;
  appCacheDir: string;
  bundleName: string;
  hapCommit: string;
  flutterOhosVersion: string;
}

interface SaveOutcome {
  uri: string;
  displayName: string;
  kind: 'pickerUri' | 'publicDownloadDir' | 'privateFallback';
}

interface OhosPublicDownloadDir {
  path: string;
  displayName: string;
}

// MIME kinds used to route pickers. Match values to
// `mimeKind` argument from Dart-side `pickAndSaveBytesByKind`.
type MimeKind = 'document' | 'audio' | 'image_video';

export default class OhosPlatformPlugin
  implements FlutterPlugin, MethodCallHandler
{
  private channel: MethodChannel | null = null;
  private applicationContext: common.Context | null = null;
  // UIAbility context is required by picker APIs (DocumentViewPicker /
  // AudioViewPicker / PhotoAccessHelper). Injected from EntryAbility during
  // plugin registration. When missing (e.g. headless tests), picker calls
  // surface an explicit error instead of silently writing to private dir.
  private uiAbilityContext: common.UIAbilityContext | null = null;
  // 每次挂载递增的绑定代次；卸载递增表示旧绑定作废。所有异步保存路径在
  // 每次 await 恢复后、创建目标与首次 open/写入/删除前都要核对代次。
  private bindingGeneration: number = 0;
  private detached: boolean = false;

  getUniqueClassName(): string {
    return 'OhosPlatformPlugin';
  }

  private downloadPlugin: OhosDownloadPlugin | null = null;

  constructor(uiAbilityContext?: common.UIAbilityContext) {
    if (uiAbilityContext != null) {
      this.uiAbilityContext = uiAbilityContext;
    }
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.bindingGeneration += 1;
    this.detached = false;
    this.applicationContext = binding.getApplicationContext() as common.Context;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
    // Download plugin registers its own channels, so it's wired as a sub-plugin here
    // rather than in the registrant — avoids double-registration.
    this.downloadPlugin = this.uiAbilityContext != null
      ? new OhosDownloadPlugin(this.uiAbilityContext)
      : new OhosDownloadPlugin();
    this.downloadPlugin.onAttachedToEngine(binding);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // 先递增代次并标记卸载，挂起的异步保存在下一次检查点退出。
    this.bindingGeneration += 1;
    this.detached = true;
    if (this.downloadPlugin) {
      this.downloadPlugin.onDetachedFromEngine(binding);
      this.downloadPlugin = null;
    }
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.applicationContext = null;
    this.uiAbilityContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.handleMethodCall(call, result);
  }

  private async handleMethodCall(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    let generation: number = this.bindingGeneration;
    try {
      generation = this.requireCurrentGeneration();
      switch (call.method) {
        case 'getRuntimeInfo':
          result.success(await this.getRuntimeInfo());
          return;
        case 'saveBytes':
          result.success(await this.saveBytes(call));
          return;
        case 'openPath':
        case 'openDirectory':
          result.success(await this.openPath(call));
          return;
        case 'openUri':
          result.success(await this.openUri(call));
          return;
        case 'pickSaveDirectory':
          result.success(await this.pickSaveDirectory());
          return;
        case 'pickFiles':
          result.success(await this.pickFiles(call, generation));
          return;
        case 'getPublicDownloadDir':
          result.success(await this.getPublicDownloadDir());
          return;
        case 'pickAndSaveBytes':
          // Legacy entry point kept for compatibility — routes to the new
          // kind-aware picker with default `document` kind. Returns null on
          // cancel and throws on real errors (no more silent fallback).
          result.success(await this.pickAndSaveBytesByKind(
            call,
            'document',
            generation,
          ));
          return;
        case 'pickAndSaveBytesByKind':
          result.success(await this.pickAndSaveBytesByKind(
            call,
            this.requireMimeKindArgument(call),
            generation,
          ));
          return;
        case 'saveBytesToPublicDownload':
          result.success(await this.saveBytesToPublicDownload(call, generation));
          return;
        case 'saveBytesToDownload':
          result.success(await this.saveBytesToDownload(call, generation));
          return;
        default:
          result.notImplemented();
      }
    } catch (error) {
      Log.e(TAG, `Failed to handle ${call.method}`, error);
      try {
        result.error('ohos_platform_error', `${error}`, null);
      } catch (replyError) {
        Log.w(TAG, `Failed to reply ${call.method}: ${replyError}`);
      }
    }
  }

  private async getRuntimeInfo(): Promise<OhosRuntimeInfo> {
    const context = this.requireContext();
    const bundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT,
    );
    return {
      deviceType: deviceInfo.deviceType,
      brand: deviceInfo.brand,
      productModel: deviceInfo.productModel,
      osFullName: deviceInfo.osFullName,
      displayVersion: deviceInfo.displayVersion,
      sdkApiVersion: deviceInfo.sdkApiVersion,
      appFilesDir: context.filesDir,
      appCacheDir: context.cacheDir,
      bundleName: bundleInfo.name,
      hapCommit: '',
      flutterOhosVersion: '',
    };
  }

  private async saveBytes(call: MethodCall): Promise<string> {
    const generation = this.requireCurrentGeneration();
    const context = this.requireContext();
    const fileName = this.sanitizeFileName(
      this.requireNonEmptyStringArgument(call, 'fileName'),
    );
    const bytes = call.argument('bytes') as Uint8Array | null;
    if (bytes == null) {
      throw new Error('Missing required bytes argument: bytes');
    }

    const exportDir = `${context.filesDir}/exports`;
    await this.ensureDirectory(exportDir);
    this.requireBoundGeneration(generation);
    const filePath = await this.nextAvailablePath(exportDir, fileName);
    // 目录创建与路径分配都等待过，首次 open/TRUNC 前必须确认绑定仍然有效。
    this.requireBoundGeneration(generation);
    const file = fs.openSync(
      filePath,
      fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC,
    );
    try {
      this.requireBoundGeneration(generation);
      fs.writeSync(
        file.fd,
        bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
      );
      fs.fsyncSync(file.fd);
    } finally {
      fs.closeSync(file);
    }
    return filePath;
  }

  private async openPath(call: MethodCall): Promise<boolean> {
    const appContext = this.requireContext();
    const path = this.requireNonEmptyStringArgument(call, 'path');
    // fileUri.getUriFromPath 生成规范 URI；自行拼接的 file:// 地址不保证可用。
    const uri = fileUri.getUriFromPath(path);
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      // 目标查看器需要显式只读授权才能读取本应用沙箱内的文件。
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
    };
    try {
      const uiAbility = FlutterManager.getInstance().getUIAbility(appContext);
      if (uiAbility == null) {
        Log.w(TAG, 'openPath: UIAbility not found');
        return false;
      }
      const abilityContext = uiAbility.context as common.UIAbilityContext | undefined;
      if (abilityContext == null) {
        Log.w(TAG, 'openPath: UIAbility.context is null');
        return false;
      }
      await abilityContext.startAbility(want);
      return true;
    } catch (error) {
      Log.w(TAG, `openPath failed: ${error}`);
      return false;
    }
  }

  // 打开 Picker 返回的 content:// 或文档 URI：入参已具备临时读授权，
  // 原样使用并转授只读权限，不再经过路径转换。
  private async openUri(call: MethodCall): Promise<boolean> {
    const contentUri = this.requireNonEmptyStringArgument(call, 'uri');
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: contentUri,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
    };
    try {
      const pickerContext = this.getUIAbilityContext();
      await pickerContext.startAbility(want);
      return true;
    } catch (error) {
      Log.w(TAG, `openUri failed: ${error}`);
      return false;
    }
  }

  private async pickSaveDirectory(): Promise<string | null> {
    const documentPicker = new picker.DocumentViewPicker(this.getUIAbilityContext());
    const selectResult = await documentPicker.select({
      maxSelectNumber: 1,
      selectMode: picker.DocumentSelectMode.FOLDER,
    });
    return selectResult.length > 0 ? selectResult[0] : null;
  }

  private async pickFiles(call: MethodCall, generation: number): Promise<string[]> {
    const context = this.requireContext();
    const documentPicker = new picker.DocumentViewPicker(this.getUIAbilityContext());
    const multiple = call.argument('allowMultiple') === true;
    const extensions = call.argument('fileSuffixFilters') as string[];
    const uris = await documentPicker.select({
      maxSelectNumber: multiple ? undefined : 1,
      fileSuffixFilters: extensions.length > 0 ? extensions : undefined,
    });
    this.requireBoundGeneration(generation);
    const files: string[] = [];
    for (const uri of uris) {
      const name = this.sanitizeFileName(new fileUri.FileUri(uri).name);
      const directory = `${context.cacheDir}/picked_files/${util.generateRandomUUID()}`;
      fs.mkdirSync(directory, true);
      const path = `${directory}/${name}`;
      const source = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      try {
        await fs.copyFile(source.fd, path);
      } finally {
        fs.closeSync(source);
      }
      this.requireBoundGeneration(generation);
      files.push(path);
    }
    return files;
  }

  // Returns the on-device "Downloads" directory exposed by the system
  // Files app, creating it on demand. Mirrors what `path_provider`
  // would do on macOS — gives callers a stable path for subfolder-based
  // saves when the picker is off.
  private async getPublicDownloadDir(): Promise<OhosPublicDownloadDir> {
    const generation = this.requireCurrentGeneration();
    const context = this.requireContext();
    // /storage/emulated/0/Download is not directly accessible from the
    // OHOS app sandbox; we surface the same logical location through
    // filesDir/Download so users can browse it in the Files app.
    const downloadsDir = `${context.filesDir}/Download`;
    await this.ensureDirectory(downloadsDir);
    this.requireBoundGeneration(generation);
    const result: OhosPublicDownloadDir = {
      path: downloadsDir,
      displayName: '下载',
    };
    return result;
  }

  // Picker entry point. Routes to the picker that matches `kind`:
  //   document     — DocumentViewPicker.save()
  //   audio        — AudioViewPicker.save()
  //   image_video  — PhotoAccessHelper.createAsset()
  // Returns a structured SaveOutcome with the URI and a display name so
  // the UI can show "saved to <name>'s downloads" without leaking raw
  // private paths. Returns null on user cancel.
  // Throws on permission/SDK errors so the Dart layer can decide whether
  // to fall back to the public download directory.
  private async pickAndSaveBytesByKind(
    call: MethodCall,
    kind: MimeKind,
    generation: number,
  ): Promise<SaveOutcome | null> {
    const fileName = this.sanitizeFileName(
      this.requireNonEmptyStringArgument(call, 'fileName'),
    );
    const bytes = call.argument('bytes') as Uint8Array | null;
    if (bytes == null) {
      throw new Error('Missing required bytes argument: bytes');
    }
    const mimeType = call.argument('mimeType') as string | null;

    const pickerContext = this.getUIAbilityContext();

    let targetUri: string | null = null;
    if (kind === 'audio') {
      const audioPicker = new picker.AudioViewPicker(pickerContext);
      const saveResult = await audioPicker.save({ newFileNames: [fileName] });
      this.requireBoundGeneration(generation);
      targetUri = saveResult && saveResult.length > 0 ? saveResult[0] : null;
    } else {
      // image_video falls through to the document picker because
      // PhotoAccessHelper.createAsset requires ohos.permission.WRITE_IMAGEVIDEO,
      // which is gated to system_basic APL apps. We let the user pick a
      // folder for image/video bytes via the same DocumentViewPicker flow.
      const documentPicker = new picker.DocumentViewPicker(pickerContext);
      const saveResult = await documentPicker.save({ newFileNames: [fileName] });
      this.requireBoundGeneration(generation);
      targetUri = saveResult && saveResult.length > 0 ? saveResult[0] : null;
    }

    if (targetUri == null) {
      Log.i(TAG, `pickAndSaveBytesByKind: user cancelled (kind=${kind})`);
      return null;
    }

    // Picker 返回后可能已经卸载：写入前必须确认绑定仍然有效，
    // 旧调用不得覆盖新绑定创建的同名文件。
    this.requireBoundGeneration(generation);
    // Write bytes to the picked URI. fs.openSync accepts content:// URIs
    // in OHOS — the picker grant is sufficient for the writing ability.
    const file = fs.openSync(
      targetUri,
      fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC,
    );
    try {
      this.requireBoundGeneration(generation);
      fs.writeSync(
        file.fd,
        bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
      );
      fs.fsyncSync(file.fd);
    } finally {
      fs.closeSync(file);
    }

    Log.i(TAG, `pickAndSaveBytesByKind: saved to ${targetUri}`);
    return {
      uri: targetUri,
      displayName: this.extractDisplayName(targetUri, fileName),
      kind: 'pickerUri',
    };
  }

  // Save into the public Downloads directory, creating a per-category
  // subfolder. Used when the user has the picker toggle off or when the
  // picker flow is unavailable.
  //
  // Layout:
  //   <filesDir>/<subDir>/<category>/<fileName>   (subDir non-empty)
  //   <filesDir>/<category>/<fileName>            (subDir empty)
  //
  // `subDir` is sanitized for filesystem use to defend against
  // user-supplied separators or illegal characters.
  private async saveBytesToPublicDownload(
    call: MethodCall,
    generation: number,
  ): Promise<SaveOutcome> {
    const context = this.requireContext();
    const fileName = this.sanitizeFileName(
      this.requireNonEmptyStringArgument(call, 'fileName'),
    );
    const bytes = call.argument('bytes') as Uint8Array | null;
    if (bytes == null) {
      throw new Error('Missing required bytes argument: bytes');
    }
    const category = this.sanitizeCategory(
      (call.argument('category') as string | null) ?? 'files',
    );
    const subDir = this.sanitizeSubDir(
      (call.argument('subDir') as string | null) ?? '',
    );

    // context.filesDir points to /data/storage/el2/base/files/ on OHOS,
    // which the system exposes as "Files" in the Files app. A nested
    // 1Panel-Client/<category>/ layout keeps exports discoverable
    // without polluting root.
    const baseDir = `${context.filesDir}/Download`;
    const exportDir = subDir.length > 0
      ? `${baseDir}/${subDir}/${category}`
      : `${baseDir}/${category}`;
    await this.ensureDirectory(exportDir);
    this.requireBoundGeneration(generation);
    const filePath = await this.nextAvailablePath(exportDir, fileName);
    this.requireBoundGeneration(generation);
    const file = fs.openSync(
      filePath,
      fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC,
    );
    try {
      this.requireBoundGeneration(generation);
      fs.writeSync(
        file.fd,
        bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
      );
      fs.fsyncSync(file.fd);
    } finally {
      fs.closeSync(file);
    }

    const displayName = subDir.length > 0
      ? `${subDir}/${category}/${fileName}`
      : `${category}/${fileName}`;
    Log.i(TAG, `saveBytesToPublicDownload: saved to ${filePath}`);
    return {
      uri: filePath,
      displayName,
      kind: 'publicDownloadDir',
    };
  }

  private async saveBytesToDownload(
    call: MethodCall,
    generation: number,
  ): Promise<string> {
    const context = this.requireContext();
    const fileName = this.sanitizeFileName(
      this.requireNonEmptyStringArgument(call, 'fileName'),
    );
    const bytes = call.argument('bytes') as Uint8Array | null;
    if (bytes == null) {
      throw new Error('Missing required bytes argument: bytes');
    }

    // Save to exports directory in app files
    const exportDir = `${context.filesDir}/exports`;
    await this.ensureDirectory(exportDir);
    this.requireBoundGeneration(generation);
    const filePath = await this.nextAvailablePath(exportDir, fileName);
    this.requireBoundGeneration(generation);
    const file = fs.openSync(
      filePath,
      fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC,
    );
    try {
      this.requireBoundGeneration(generation);
      fs.writeSync(
        file.fd,
        bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength),
      );
      fs.fsyncSync(file.fd);
    } finally {
      fs.closeSync(file);
    }

    Log.i(TAG, `saveBytesToDownload: saved to ${filePath}`);
    return filePath;
  }

  private extractDisplayName(uri: string, fallback: string): string {
    // content:// URIs end in /<encoded_filename>; pick the last path segment
    // and unescape common percent-encodings. Falls back to file name.
    try {
      const lastSlash = uri.lastIndexOf('/');
      if (lastSlash < 0 || lastSlash === uri.length - 1) {
        return fallback;
      }
      const raw = decodeURIComponent(uri.substring(lastSlash + 1));
      return raw.length > 0 ? raw : fallback;
    } catch (_) {
      return fallback;
    }
  }

  private async ensureDirectory(path: string): Promise<void> {
    try {
      if (fs.accessSync(path)) {
        return;
      }
    } catch (_) {
      // Directory does not exist.
    }
    fs.mkdirSync(path, true);
  }

  private async nextAvailablePath(
    directory: string,
    fileName: string,
  ): Promise<string> {
    const first = `${directory}/${fileName}`;
    if (!this.exists(first)) {
      return first;
    }

    const lastDot = fileName.lastIndexOf('.');
    const baseName = lastDot > 0 ? fileName.substring(0, lastDot) : fileName;
    const extension = lastDot > 0 ? fileName.substring(lastDot) : '';
    const maxAttempts = 9999;
    let counter = 1;
    while (counter <= maxAttempts) {
      const candidate = `${directory}/${baseName}_${counter}${extension}`;
      if (!this.exists(candidate)) {
        return candidate;
      }
      counter += 1;
    }
    throw new Error(
      `Failed to generate unique file name after ${maxAttempts} attempts: ${fileName}`,
    );
  }

  private exists(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch (_) {
      return false;
    }
  }

  private sanitizeFileName(fileName: string): string {
    return fileName.replace(/[<>:"/\\|?*]/g, '_');
  }

  // category is part of a filesystem path, so it must be filesystem-safe.
  // Reject anything outside [a-zA-Z0-9_-] and cap length to avoid abuse.
  private sanitizeCategory(category: string): string {
    const cleaned = category.replace(/[^a-zA-Z0-9_-]/g, '').toLowerCase();
    return cleaned.length > 0 ? cleaned.substring(0, 32) : 'files';
  }

  // subDir mirrors the same policy as category: keep the alphabet tight,
  // strip path separators, cap length. Empty input is allowed and is
  // treated as "no parent folder" by callers.
  private sanitizeSubDir(subDir: string): string {
    const cleaned = subDir
      .replace(/[<>:"/\\|?*\x00-\x1F]/g, '')
      .replace(/\.\.+/g, '.')
      .trim();
    return cleaned.length > 0 ? cleaned.substring(0, 64) : '';
  }

  private requireContext(): common.Context {
    if (this.applicationContext == null) {
      throw new Error('Application context is not ready');
    }
    return this.applicationContext;
  }

  // Returns the UIAbility context required by picker APIs. Injected by
  // EntryAbility during plugin registration; falls back to FlutterManager
  // for backwards compatibility (older test harnesses register without
  // injecting the context). Throws an explicit error if no UI context is
  // available — callers must catch and decide whether to fall back.
  private getUIAbilityContext(): common.UIAbilityContext {
    if (this.uiAbilityContext != null) {
      return this.uiAbilityContext;
    }
    const appContext = this.requireContext();
    const uiAbility = FlutterManager.getInstance().getUIAbility(appContext);
    if (uiAbility == null) {
      throw new Error('UIAbility not ready — picker requires ability context');
    }
    const context = uiAbility.context as common.UIAbilityContext;
    this.uiAbilityContext = context;
    return context;
  }

  private requireStringArgument(call: MethodCall, key: string): string {
    const rawValue = call.argument(key) as string | null;
    if (rawValue != null) {
      return rawValue;
    }
    throw new Error(`Missing required string argument: ${key}`);
  }

  private requireNonEmptyStringArgument(call: MethodCall, key: string): string {
    const value = this.requireStringArgument(call, key);
    if (value.length > 0) {
      return value;
    }
    throw new Error(`Missing required string argument: ${key}`);
  }

  private requireMimeKindArgument(call: MethodCall): MimeKind {
    const raw = (call.argument('mimeKind') as string | null) ?? 'document';
    if (raw === 'document' || raw === 'audio' || raw === 'image_video') {
      return raw;
    }
    throw new Error(`Unsupported mimeKind: ${raw}`);
  }

  private requireCurrentGeneration(): number {
    if (this.detached || this.applicationContext == null) {
      throw new Error('Ohos platform plugin detached from engine');
    }
    return this.bindingGeneration;
  }

  private requireBoundGeneration(generation: number): void {
    if (this.detached || generation !== this.bindingGeneration) {
      throw new Error('Ohos platform plugin detached from engine');
    }
  }
}
