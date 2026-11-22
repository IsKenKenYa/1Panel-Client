import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct AutoCompleteExample {
  @State searchQuery: string = '';
  @State suggestions: string[] = [];
  @State selectedSuggestion: string = '';

  build() {
    Column() {
      Text('自动补全示例')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      TextInput({ placeholder: '请输入关键字，如：北京' })
        .width('80%')
        .height(40)
        .onChange(async (value: string) => {
          this.searchQuery = value;
          if (value.length > 0) {
            await this.getAutoCompleteSuggestions(value);
          } else {
            this.suggestions = [];
          }
        });

      if (this.suggestions.length > 0) {
        Text('搜索建议:')
          .fontSize(16)
          .margin({ top: 10, bottom: 5 });

        List() {
          ForEach(this.suggestions, (suggestion: string) => {
            ListItem() {
              Text(suggestion)
                .fontSize(14)
                .padding(10)
                .onClick(() => {
                  this.selectedSuggestion = suggestion;
                });
            }
          });
        }
        .width('80%')
        .height(200)
        .margin({ top: 10 });
      }

      if (this.selectedSuggestion) {
        Text(`已选择: ${this.selectedSuggestion}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%');
  }

  async getAutoCompleteSuggestions(query: string): Promise<void> {
    let params: site.QueryAutoCompleteParams = {
      query: query,
      location: {
        latitude: 39.9042,
        longitude: 116.4074
      },
      radius: 50000,
      language: 'zh',
      isChildren: true
    };

    try {
      const result = await site.queryAutoComplete(params);
      
      if (result.sites && result.sites.length > 0) {
        this.suggestions = result.sites.map(siteInfo => siteInfo.name);
      } else {
        this.suggestions = [];
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`自动补全失败: 错误码 ${err.code}, 错误信息 ${err.message}`);
      this.suggestions = [];
    }
  }
}