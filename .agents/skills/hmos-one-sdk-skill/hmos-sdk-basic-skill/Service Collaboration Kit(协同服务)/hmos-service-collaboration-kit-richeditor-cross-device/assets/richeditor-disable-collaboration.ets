import { RichEditor, RichEditorController, RichEditorOptions, TextMenuItem, TextMenuItemId, TextRange, EditMenuOptions } from '@ohos.arkui';

@Entry
@Component
struct RichEditorDisableCollaboration {
  controller: RichEditorController = new RichEditorController();
  options: RichEditorOptions = { controller: this.controller };

  build() {
    Column() {
      Column() {
        RichEditor(this.options)
          .editMenuOptions({
            onCreateMenu: (menuItems: Array<TextMenuItem>) => {
              if (menuItems.length === 0) {
                return menuItems;
              }
              let newMenuItems: TextMenuItem[] = [];
              menuItems.forEach((item, index) => {
                if (!item.id.equals(TextMenuItemId.COLLABORATION_SERVICE)) {
                  newMenuItems.push(item);
                }
              });
              return newMenuItems;
            },
            onMenuItemClick: (menuItem: TextMenuItem, textRange: TextRange) => {
              return false;
            }
          })
          .borderWidth(1)
          .borderColor(Color.Green)
          .width('100%')
          .height('100%')
      }
      .borderWidth(1)
      .borderColor(Color.Red)
      .width('100%')
      .height('70%')
    }
  }
}