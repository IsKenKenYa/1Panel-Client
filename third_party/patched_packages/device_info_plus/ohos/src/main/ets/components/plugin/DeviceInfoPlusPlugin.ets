/**
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodChannel,
  MethodCall,
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos';
import deviceInfo from '@ohos.deviceInfo';
import HashMap from '@ohos.util.HashMap';

/**
 * Flutter OHOS plugin that exposes HarmonyOS device information to the Dart
 * side over a {@link MethodChannel}.
 *
 * The channel ({@link DeviceInfoPlusPlugin#CHANNEL_NAME}) exposes two methods:
 * - {@link DeviceInfoPlusPlugin#METHOD_GET_DEVICE_INFO}: a map of general
 *   device attributes (brand, version, ABI list, ...).
 * - {@link DeviceInfoPlusPlugin#METHOD_GET_ACCESS_UDID}: the device `serial`
 *   and `udid`, which require the system permission
 *   `ohos.permission.sec.ACCESS_UDID`.
 */
export default class DeviceInfoPlusPlugin implements FlutterPlugin, MethodCallHandler {
  /** Name of the method channel shared with the Dart side. */
  private readonly CHANNEL_NAME: string = 'dev.fluttercommunity.plus/device_info';

  /** Method name returning the full device information map. */
  private readonly METHOD_GET_DEVICE_INFO: string = 'getDeviceInfo';

  /** Method name returning the serial/UDID map (system permission required). */
  private readonly METHOD_GET_ACCESS_UDID: string = 'getAccessUDIDInfo';

  /** Tag whose presence in device attributes indicates an emulator runtime. */
  private readonly EMULATOR_TAG: string = 'emulator';

  private channel: MethodChannel | null = null;

  constructor() {
  }

  /**
   * Returns the unique class name used for plugin identification.
   *
   * @returns The plugin class name.
   */
  getUniqueClassName(): string {
    return 'DeviceInfoPlusPlugin';
  }

  /**
   * Called when the plugin is attached to a Flutter engine. Creates the
   * {@link MethodChannel} and registers this instance as its call handler.
   *
   * @param binding - The binding providing the binary messenger.
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), this.CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  /**
   * Called when the plugin is detached from a Flutter engine. Releases the
   * {@link MethodChannel} and unregisters the call handler.
   *
   * @param binding - The binding (kept for lifecycle symmetry with
   *   {@link DeviceInfoPlusPlugin#onAttachedToEngine}).
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel !== null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
  }

  /**
   * Handles a method call received from Flutter.
   *
   * Dispatches to the device-info or UDID handlers. Any failure — most
   * commonly a missing `ohos.permission.sec.ACCESS_UDID` permission when
   * reading the UDID — is reported back to Flutter via
   * {@link MethodResult#error} instead of propagating an uncaught exception
   * that would crash the host.
   *
   * @param call - The incoming method call.
   * @param result - The callback used to submit the result back to Flutter.
   */
  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === this.METHOD_GET_DEVICE_INFO) {
        result.success(this.buildDeviceInfoMap());
      } else if (call.method === this.METHOD_GET_ACCESS_UDID) {
        result.success(this.buildAccessUDIDMap());
      } else {
        result.notImplemented();
      }
    } catch (e) {
      // Report failures (e.g. permission denial) to Flutter so the plugin
      // does not crash the host. result is called exactly once per path.
      const reason = e instanceof Error ? (e.message ?? '') : String(e);
      result.error('DEVICE_INFO_ERROR', `${call.method} failed: ${reason}`, null);
    }
  }

  /**
   * Builds the general device information map returned by `getDeviceInfo`.
   *
   * @returns A map of device attributes keyed by their Dart-side field names.
   */
  private buildDeviceInfoMap(): HashMap<string, Object> {
    const infoMap: HashMap<string, Object> = new HashMap<string, Object>();
    infoMap.set('deviceType', deviceInfo.deviceType);
    infoMap.set('manufacture', deviceInfo.manufacture);
    infoMap.set('brand', deviceInfo.brand);
    infoMap.set('marketName', deviceInfo.marketName);
    infoMap.set('productSeries', deviceInfo.productSeries);
    infoMap.set('productModel', deviceInfo.productModel);
    infoMap.set('softwareModel', deviceInfo.softwareModel);
    infoMap.set('hardwareModel', deviceInfo.hardwareModel);
    infoMap.set('bootloaderVersion', deviceInfo.bootloaderVersion);
    infoMap.set('abiList', deviceInfo.abiList);
    infoMap.set('securityPatchTag', deviceInfo.securityPatchTag);
    infoMap.set('displayVersion', deviceInfo.displayVersion);
    infoMap.set('incrementalVersion', deviceInfo.incrementalVersion);
    infoMap.set('osReleaseType', deviceInfo.osReleaseType);
    infoMap.set('osFullName', deviceInfo.osFullName);
    infoMap.set('majorVersion', deviceInfo.majorVersion);
    infoMap.set('seniorVersion', deviceInfo.seniorVersion);
    infoMap.set('featureVersion', deviceInfo.featureVersion);
    infoMap.set('buildVersion', deviceInfo.buildVersion);
    infoMap.set('sdkApiVersion', deviceInfo.sdkApiVersion);
    infoMap.set('firstApiVersion', deviceInfo.firstApiVersion);
    infoMap.set('versionId', deviceInfo.versionId);
    infoMap.set('buildType', deviceInfo.buildType);
    infoMap.set('buildUser', deviceInfo.buildUser);
    infoMap.set('buildHost', deviceInfo.buildHost);
    infoMap.set('buildTime', deviceInfo.buildTime);
    infoMap.set('buildRootHash', deviceInfo.buildRootHash);
    infoMap.set('ODID', deviceInfo.ODID); // ohos.permission.APP_TRACKING_CONSENT 用户授权才能获取有效值
    infoMap.set('distributionOSName', deviceInfo.distributionOSName);
    infoMap.set('distributionOSVersion', deviceInfo.distributionOSVersion);
    infoMap.set('distributionOSApiVersion', deviceInfo.distributionOSApiVersion);
    infoMap.set('distributionOSReleaseType', deviceInfo.distributionOSReleaseType);
    infoMap.set('isPhysicalDevice', !this.isEmulator(infoMap));
    return infoMap;
  }

  /**
   * Builds the serial/UDID map returned by `getAccessUDIDInfo`.
   *
   * Requires the system permission `ohos.permission.sec.ACCESS_UDID`; without
   * it the underlying `deviceInfo` calls throw and the caller (see
   * {@link DeviceInfoPlusPlugin#onMethodCall}) reports the error to Flutter.
   *
   * @returns A map containing the device `serial` and `udid`.
   */
  private buildAccessUDIDMap(): HashMap<string, Object> {
    const infoMap: HashMap<string, Object> = new HashMap<string, Object>();
    infoMap.set('serial', deviceInfo.serial);
    infoMap.set('udid', deviceInfo.udid);
    return infoMap;
  }

  /**
   * Heuristically detects whether the current runtime is an emulator.
   *
   * @param infoMap - The assembled device info map (checked for an
   *   {@link DeviceInfoPlusPlugin#EMULATOR_TAG} entry).
   * @returns `true` if the runtime looks like an emulator, otherwise `false`.
   */
  isEmulator(infoMap: HashMap<string, Object>): boolean {
    return infoMap.hasValue(this.EMULATOR_TAG) ||
      deviceInfo.versionId.includes(this.EMULATOR_TAG) ||
      deviceInfo.displayVersion.includes(this.EMULATOR_TAG);
  }
}
