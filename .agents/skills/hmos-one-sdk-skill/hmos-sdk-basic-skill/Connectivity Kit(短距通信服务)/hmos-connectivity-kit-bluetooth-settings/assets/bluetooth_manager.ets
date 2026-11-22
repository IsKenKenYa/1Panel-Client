/**
 * Bluetooth Manager - Complete Example
 * This file provides a complete implementation of Bluetooth settings management
 * including enable/disable, state monitoring, and error handling.
 */

import { access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';

/**
 * Bluetooth state change callback type
 */
type BluetoothStateCallback = (state: access.BluetoothState) => void;

/**
 * BluetoothManager class provides comprehensive Bluetooth settings management
 */
export class BluetoothManager {
  private context: common.UIAbilityContext;
  private stateCallbacks: BluetoothStateCallback[] = [];
  private isSubscribed: boolean = false;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * Request Bluetooth permission
   * @returns Promise<boolean> - true if permission granted, false otherwise
   */
  async requestPermission(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    
    try {
      // Check if permission already granted
      const grantStatus = await atManager.checkAccessToken(
        this.context.applicationInfo.accessTokenId,
        'ohos.permission.ACCESS_BLUETOOTH'
      );
      
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info('[BluetoothManager] Permission already granted');
        return true;
      }
      
      // Request permission
      console.info('[BluetoothManager] Requesting ACCESS_BLUETOOTH permission');
      const result = await atManager.requestPermissionsFromUser(
        this.context,
        ['ohos.permission.ACCESS_BLUETOOTH']
      );
      
      const granted = result.authResults[0] === 0;
      console.info('[BluetoothManager] Permission request result: ' + granted);
      return granted;
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Permission request failed: ' + err.message);
      return false;
    }
  }

  /**
   * Subscribe to Bluetooth state changes
   * @param callback - State change callback function
   */
  subscribeStateChange(callback: BluetoothStateCallback): void {
    if (!this.isSubscribed) {
      try {
        access.on('stateChange', this.handleStateChange.bind(this));
        this.isSubscribed = true;
        console.info('[BluetoothManager] State change subscription enabled');
      } catch (error) {
        const err = error as BusinessError;
        console.error('[BluetoothManager] Subscribe failed: ' + err.code + ', ' + err.message);
      }
    }
    
    this.stateCallbacks.push(callback);
    console.info('[BluetoothManager] Callback registered, total callbacks: ' + this.stateCallbacks.length);
  }

  /**
   * Unsubscribe from Bluetooth state changes
   * @param callback - Optional specific callback to remove, removes all if not provided
   */
  unsubscribeStateChange(callback?: BluetoothStateCallback): void {
    if (callback) {
      const index = this.stateCallbacks.indexOf(callback);
      if (index !== -1) {
        this.stateCallbacks.splice(index, 1);
        console.info('[BluetoothManager] Specific callback removed');
      }
    } else {
      this.stateCallbacks = [];
      console.info('[BluetoothManager] All callbacks cleared');
    }
    
    if (this.stateCallbacks.length === 0 && this.isSubscribed) {
      try {
        access.off('stateChange');
        this.isSubscribed = false;
        console.info('[BluetoothManager] State change subscription disabled');
      } catch (error) {
        const err = error as BusinessError;
        console.error('[BluetoothManager] Unsubscribe failed: ' + err.code + ', ' + err.message);
      }
    }
  }

  /**
   * Internal handler for state change events
   * @param state - New Bluetooth state
   */
  private handleStateChange(state: access.BluetoothState): void {
    const stateMessage = this.getStateMessage(state);
    console.info('[BluetoothManager] State changed: ' + stateMessage);
    
    // Notify all registered callbacks
    this.stateCallbacks.forEach(callback => {
      try {
        callback(state);
      } catch (error) {
        console.error('[BluetoothManager] Callback execution failed: ' + error);
      }
    });
  }

  /**
   * Get human-readable state message
   * @param state - Bluetooth state
   * @returns string - State description
   */
  private getStateMessage(state: access.BluetoothState): string {
    switch (state) {
      case access.BluetoothState.STATE_OFF:
        return 'STATE_OFF - Bluetooth is disabled';
      case access.BluetoothState.STATE_TURNING_ON:
        return 'STATE_TURNING_ON - Bluetooth is turning on';
      case access.BluetoothState.STATE_ON:
        return 'STATE_ON - Bluetooth is enabled (ready for use)';
      case access.BluetoothState.STATE_TURNING_OFF:
        return 'STATE_TURNING_OFF - Bluetooth is turning off';
      case access.BluetoothState.STATE_BLE_TURNING_ON:
        return 'STATE_BLE_TURNING_ON - Bluetooth LE-only mode turning on';
      case access.BluetoothState.STATE_BLE_ON:
        return 'STATE_BLE_ON - Bluetooth LE-only mode enabled';
      case access.BluetoothState.STATE_BLE_TURNING_OFF:
        return 'STATE_BLE_TURNING_OFF - Bluetooth LE-only mode turning off';
      default:
        return 'Unknown state';
    }
  }

  /**
   * Get current Bluetooth state
   * @returns access.BluetoothState - Current state
   */
  getState(): access.BluetoothState {
    try {
      const state = access.getState();
      console.info('[BluetoothManager] Current state: ' + this.getStateMessage(state));
      return state;
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Get state failed: ' + err.code + ', ' + err.message);
      this.handleError(err);
      return access.BluetoothState.STATE_OFF;
    }
  }

  /**
   * Check if Bluetooth is enabled (STATE_ON)
   * @returns boolean - true if enabled
   */
  isEnabled(): boolean {
    return this.getState() === access.BluetoothState.STATE_ON;
  }

  /**
   * Enable Bluetooth (synchronous method)
   * User confirmation dialog will be shown
   */
  enableBluetooth(): void {
    try {
      const state = this.getState();
      
      if (state === access.BluetoothState.STATE_OFF) {
        console.info('[BluetoothManager] Attempting to enable Bluetooth');
        access.enableBluetooth();
        console.info('[BluetoothManager] Enable request sent, waiting for user confirmation');
      } else if (state === access.BluetoothState.STATE_ON) {
        console.info('[BluetoothManager] Bluetooth is already enabled');
      } else {
        console.warn('[BluetoothManager] Bluetooth is in transition state, please wait');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Enable failed: ' + err.code + ', ' + err.message);
      this.handleError(err);
    }
  }

  /**
   * Enable Bluetooth asynchronously (API 20+)
   * Can detect user response to the confirmation dialog
   * @returns Promise<void>
   */
  async enableBluetoothAsync(): Promise<void> {
    try {
      const state = this.getState();
      
      if (state === access.BluetoothState.STATE_OFF) {
        console.info('[BluetoothManager] Attempting to enable Bluetooth asynchronously');
        
        await access.enableBluetoothAsync();
        console.info('[BluetoothManager] User accepted enable request');
      } else if (state === access.BluetoothState.STATE_ON) {
        console.info('[BluetoothManager] Bluetooth is already enabled');
      } else {
        console.warn('[BluetoothManager] Bluetooth is in transition state, please wait');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Async enable failed: ' + err.code + ', ' + err.message);
      
      if (err.code === 2900013) {
        console.warn('[BluetoothManager] User did not respond to the dialog');
      } else if (err.code === 2900014) {
        console.warn('[BluetoothManager] User refused to enable Bluetooth');
      }
      
      this.handleError(err);
      throw err;
    }
  }

  /**
   * Disable Bluetooth (synchronous method)
   * User confirmation dialog will be shown
   */
  disableBluetooth(): void {
    try {
      const state = this.getState();
      
      if (state === access.BluetoothState.STATE_ON) {
        console.info('[BluetoothManager] Attempting to disable Bluetooth');
        access.disableBluetooth();
        console.info('[BluetoothManager] Disable request sent, waiting for user confirmation');
      } else if (state === access.BluetoothState.STATE_OFF) {
        console.info('[BluetoothManager] Bluetooth is already disabled');
      } else {
        console.warn('[BluetoothManager] Bluetooth is in transition state, please wait');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Disable failed: ' + err.code + ', ' + err.message);
      this.handleError(err);
    }
  }

  /**
   * Disable Bluetooth asynchronously (API 20+)
   * Can detect user response to the confirmation dialog
   * @returns Promise<void>
   */
  async disableBluetoothAsync(): Promise<void> {
    try {
      const state = this.getState();
      
      if (state === access.BluetoothState.STATE_ON) {
        console.info('[BluetoothManager] Attempting to disable Bluetooth asynchronously');
        
        await access.disableBluetoothAsync();
        console.info('[BluetoothManager] User accepted disable request');
      } else if (state === access.BluetoothState.STATE_OFF) {
        console.info('[BluetoothManager] Bluetooth is already disabled');
      } else {
        console.warn('[BluetoothManager] Bluetooth is in transition state, please wait');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('[BluetoothManager] Async disable failed: ' + err.code + ', ' + err.message);
      
      if (err.code === 2900013) {
        console.warn('[BluetoothManager] User did not respond to the dialog');
      } else if (err.code === 2900014) {
        console.warn('[BluetoothManager] User refused to disable Bluetooth');
      }
      
      this.handleError(err);
      throw err;
    }
  }

  /**
   * Ensure Bluetooth is enabled before using other Bluetooth features
   * This method checks the state and enables if necessary
   * @returns Promise<boolean> - true if Bluetooth is ready for use
   */
  async ensureBluetoothEnabled(): Promise<boolean> {
    console.info('[BluetoothManager] Checking Bluetooth status');
    
    // Check permission first
    const hasPermission = await this.requestPermission();
    if (!hasPermission) {
      console.error('[BluetoothManager] Permission denied, cannot enable Bluetooth');
      return false;
    }
    
    const state = this.getState();
    
    if (state === access.BluetoothState.STATE_ON) {
      console.info('[BluetoothManager] Bluetooth is already enabled and ready');
      return true;
    }
    
    if (state !== access.BluetoothState.STATE_OFF) {
      console.warn('[BluetoothManager] Bluetooth is in transition state: ' + state);
      // Wait for state to settle (could implement a wait mechanism here)
      return false;
    }
    
    // Try to enable Bluetooth
    try {
      console.info('[BluetoothManager] Bluetooth is OFF, attempting to enable');
      
      // Use async method if available (API 20+), otherwise use sync method
      try {
        await this.enableBluetoothAsync();
      } catch (error) {
        // Fallback to sync method if async not available
        this.enableBluetooth();
      }
      
      // Wait for STATE_ON (could implement a timeout mechanism)
      // For now, return false and let caller wait for stateChange callback
      console.info('[BluetoothManager] Enable request sent, wait for STATE_ON callback');
      return false;
    } catch (error) {
      console.error('[BluetoothManager] Failed to enable Bluetooth: ' + error);
      return false;
    }
  }

  /**
   * Handle common Bluetooth errors
   * @param error - BusinessError object
   */
  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[BluetoothManager] Permission denied. Solution: Request ACCESS_BLUETOOTH permission');
        break;
      case 401:
        console.error('[BluetoothManager] Invalid parameter. Solution: Check callback function validity');
        break;
      case 801:
        console.error('[BluetoothManager] Capability not supported. Device does not support Bluetooth');
        break;
      case 2900001:
        console.error('[BluetoothManager] Service stopped. Solution: Restart device');
        break;
      case 2900003:
        console.error('[BluetoothManager] Bluetooth disabled. Enable Bluetooth first');
        break;
      case 2900013:
        console.warn('[BluetoothManager] User did not respond. Wait for user action');
        break;
      case 2900014:
        console.warn('[BluetoothManager] User refused. Respect user choice');
        break;
      case 2900099:
        console.error('[BluetoothManager] Operation failed. Check system status');
        break;
      default:
        console.error('[BluetoothManager] Unknown error: ' + error.code + ', ' + error.message);
        break;
    }
  }

  /**
   * Cleanup - unsubscribe all callbacks and release resources
   */
  cleanup(): void {
    console.info('[BluetoothManager] Cleaning up resources');
    this.unsubscribeStateChange();
  }
}

/**
 * Example usage in an EntryAbility
 */
export class BluetoothUsageExample {
  private bluetoothManager: BluetoothManager;
  
  constructor(context: common.UIAbilityContext) {
    this.bluetoothManager = new BluetoothManager(context);
    
    // Subscribe to state changes
    this.bluetoothManager.subscribeStateChange((state: access.BluetoothState) => {
      if (state === access.BluetoothState.STATE_ON) {
        console.info('[Example] Bluetooth is ready, can start other Bluetooth operations');
        // Example: start scanning, connect to device, etc.
      } else if (state === access.BluetoothState.STATE_OFF) {
        console.info('[Example] Bluetooth is disabled, cannot use Bluetooth features');
      }
    });
  }
  
  async initialize(): Promise<void> {
    // Ensure Bluetooth is enabled before using other features
    const ready = await this.bluetoothManager.ensureBluetoothEnabled();
    
    if (!ready) {
      console.info('[Example] Waiting for Bluetooth to be enabled');
      // The stateChange callback will notify when Bluetooth is ready
    } else {
      console.info('[Example] Bluetooth is ready immediately');
      // Can start other Bluetooth operations here
    }
  }
  
  cleanup(): void {
    this.bluetoothManager.cleanup();
  }
}

// Export singleton instance for easy usage
let bluetoothManagerInstance: BluetoothManager | null = null;

export function getBluetoothManager(context: common.UIAbilityContext): BluetoothManager {
  if (!bluetoothManagerInstance) {
    bluetoothManagerInstance = new BluetoothManager(context);
  }
  return bluetoothManagerInstance;
}