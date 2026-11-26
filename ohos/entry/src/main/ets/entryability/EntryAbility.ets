
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import { OhosCompatibilityPluginRegistrant } from '../plugins/OhosCompatibilityPluginRegistrant';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { HarmonyNativeBridge } from '../native_ui/HarmonyNativeBridge';
import { HarmonyContainerTerminalBridge } from '../native_ui/containers/HarmonyContainerTerminalBridge';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    // Pass the UIAbility context so picker-aware plugins (OhosPlatformPlugin,
    // OhosDownloadPlugin) can launch system picker dialogs. Picker APIs
    // (DocumentViewPicker / AudioViewPicker / PhotoAccessHelper) require a
    // UIAbility context with a valid UI token, which is only available on
    // the hosting ability, not the application context.
    const uiAbilityContext = this.context as common.UIAbilityContext;
    OhosCompatibilityPluginRegistrant.registerWith(flutterEngine, uiAbilityContext)
    flutterEngine.getPlugins()?.add(HarmonyNativeBridge.instance);
    flutterEngine.getPlugins()?.add(HarmonyContainerTerminalBridge.instance);
  }
}
