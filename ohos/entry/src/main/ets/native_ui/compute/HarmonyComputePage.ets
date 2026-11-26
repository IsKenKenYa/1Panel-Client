import { HarmonyAIPage } from './HarmonyAIPage';
import { HarmonyVMPage } from './HarmonyVMPage';
import { HarmonyAlertPage } from './HarmonyAlertPage';

@Component
export struct HarmonyComputePage {
  @Prop initialRoute: string = '/ai';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();

  build() {
    Column() {
      if (this.initialRoute === '/vm') {
        HarmonyVMPage({ initialRoute: this.initialRoute, routeArguments: this.routeArguments })
      } else if (this.initialRoute === '/alert') {
        HarmonyAlertPage()
      } else {
        HarmonyAIPage({ initialRoute: this.initialRoute, routeArguments: this.routeArguments })
      }
    }
    .width('100%')
    .height('100%')
  }
}
