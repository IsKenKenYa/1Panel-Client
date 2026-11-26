import { HarmonyAIPage } from './HarmonyAIPage';
import { HarmonyVMPage } from './HarmonyVMPage';
import { HarmonyAlertPage } from './HarmonyAlertPage';

@Component
export struct HarmonyComputePage {
  @Prop initialRoute: string = '/ai';
  @Prop routeArguments: Map<string, Object | null> = new Map<string, Object | null>();
  @Prop showBack: boolean = true;
  onBack: () => void = (): void => {};

  build() {
    Column() {
      if (this.initialRoute === '/vm') {
        HarmonyVMPage({ initialRoute: this.initialRoute, routeArguments: this.routeArguments, showBack: this.showBack, onBack: this.onBack })
      } else if (this.initialRoute === '/alert') {
        HarmonyAlertPage({ showBack: this.showBack, onBack: this.onBack })
      } else {
        HarmonyAIPage({ initialRoute: this.initialRoute, routeArguments: this.routeArguments, showBack: this.showBack, onBack: this.onBack })
      }
    }
    .width('100%')
    .height('100%')
  }
}
