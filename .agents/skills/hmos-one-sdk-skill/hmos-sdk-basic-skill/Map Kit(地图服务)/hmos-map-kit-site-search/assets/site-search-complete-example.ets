import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

interface SearchResult {
  totalCount: number;
  sites: Array<{
    siteId: string;
    name: string;
    formatAddress: string;
    location: { latitude: number; longitude: number };
    distance?: number;
  }>;
}

@Entry
@Component
struct SiteSearchCompleteExample {
  @State searchMode: string = 'text'; // text, nearby, autocomplete, detail
  @State searchQuery: string = '';
  @State currentLat: number = 39.9042;
  @State currentLng: number = 116.4074;
  @State searchRadius: number = 5000;
  @State siteId: string = '';
  @State searchResults: SearchResult | null = null;
  @State siteDetail: string = '';
  @State suggestions: string[] = [];
  @State errorMessage: string = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  build() {
    Column() {
      Text('POI搜索完整示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Row() {
        Button('关键字搜索')
          .width('23%')
          .height(40)
          .onClick(() => {
            this.searchMode = 'text';
            this.errorMessage = '';
          });

        Button('周边搜索')
          .width('23%')
          .height(40)
          .onClick(() => {
            this.searchMode = 'nearby';
            this.errorMessage = '';
          });

        Button('自动补全')
          .width('23%')
          .height(40)
          .onClick(() => {
            this.searchMode = 'autocomplete';
            this.errorMessage = '';
          });

        Button('地点详情')
          .width('23%')
          .height(40)
          .onClick(() => {
            this.searchMode = 'detail';
            this.errorMessage = '';
          });
      }
      .width('95%')
      .margin({ bottom: 20 });

      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor(Color.Red)
          .margin({ bottom: 10 });
      }

      if (this.searchMode === 'text') {
        this.buildTextSearchUI();
      } else if (this.searchMode === 'nearby') {
        this.buildNearbySearchUI();
      } else if (this.searchMode === 'autocomplete') {
        this.buildAutoCompleteUI();
      } else if (this.searchMode === 'detail') {
        this.buildDetailSearchUI();
      }

      if (this.searchResults) {
        this.buildResultsList();
      }
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  buildTextSearchUI() {
    Column() {
      TextInput({ placeholder: '请输入搜索关键字' })
        .width('80%')
        .height(40)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.searchQuery = value;
        });

      Button('搜索')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.performTextSearch();
        });
    };
  }

  @Builder
  buildNearbySearchUI() {
    Column() {
      TextInput({ placeholder: '纬度 (如: 39.9042)' })
        .width('80%')
        .height(40)
        .margin({ bottom: 10 })
        .type(InputType.Number)
        .onChange((value: string) => {
          this.currentLat = parseFloat(value);
        });

      TextInput({ placeholder: '经度 (如: 116.4074)' })
        .width('80%')
        .height(40)
        .margin({ bottom: 10 })
        .type(InputType.Number)
        .onChange((value: string) => {
          this.currentLng = parseFloat(value);
        });

      TextInput({ placeholder: '搜索半径(米) (如: 5000)' })
        .width('80%')
        .height(40)
        .margin({ bottom: 10 })
        .type(InputType.Number)
        .onChange((value: string) => {
          this.searchRadius = parseInt(value);
        });

      Button('周边搜索')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.performNearbySearch();
        });
    };
  }

  @Builder
  buildAutoCompleteUI() {
    Column() {
      TextInput({ placeholder: '请输入关键字获取建议' })
        .width('80%')
        .height(40)
        .onChange(async (value: string) => {
          this.searchQuery = value;
          if (value.length > 0) {
            await this.performAutoComplete();
          } else {
            this.suggestions = [];
          }
        });

      if (this.suggestions.length > 0) {
        Text('搜索建议:')
          .fontSize(16)
          .margin({ top: 10 });

        List() {
          ForEach(this.suggestions, (suggestion: string) => {
            ListItem() {
              Text(suggestion)
                .fontSize(14)
                .padding(10)
                .onClick(() => {
                  this.searchQuery = suggestion;
                  this.searchMode = 'text';
                  this.performTextSearch();
                });
            }
          });
        }
        .width('80%')
        .height(200);
      }
    };
  }

  @Builder
  buildDetailSearchUI() {
    Column() {
      TextInput({ placeholder: '请输入地点ID' })
        .width('80%')
        .height(40)
        .margin({ bottom: 10 })
        .onChange((value: string) => {
          this.siteId = value;
        });

      Button('查询详情')
        .width('80%')
        .height(40)
        .onClick(async () => {
          await this.performDetailSearch();
        });

      if (this.siteDetail) {
        Text(this.siteDetail)
          .fontSize(14)
          .margin({ top: 10 })
          .maxLines(30);
      }
    };
  }

  @Builder
  buildResultsList() {
    Column() {
      Text(`搜索结果总数: ${this.searchResults!.totalCount}`)
        .fontSize(16)
        .margin({ top: 10 });

      List() {
        ForEach(this.searchResults!.sites, (siteInfo) => {
          ListItem() {
            Column() {
              Text(`地点: ${siteInfo.name}`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold);

              Text(`地址: ${siteInfo.formatAddress}`)
                .fontSize(12);

              Text(`经纬度: (${siteInfo.location.latitude}, ${siteInfo.location.longitude})`)
                .fontSize(12);

              if (siteInfo.distance) {
                Text(`距离: ${siteInfo.distance} 米`)
                  .fontSize(12);
              }

              Button('查看详情')
                .fontSize(12)
                .height(30)
                .onClick(() => {
                  this.siteId = siteInfo.siteId;
                  this.searchMode = 'detail';
                  this.performDetailSearch();
                });
            }
            .padding(10)
            .margin({ bottom: 5 });
          }
        });
      }
      .width('80%')
      .height(400);
    };
  }

  async performTextSearch(): Promise<void> {
    if (!this.searchQuery || this.searchQuery.length < 1) {
      this.errorMessage = '关键字长度必须大于0';
      return;
    }

    let params: site.SearchByTextParams = {
      query: this.searchQuery,
      location: {
        latitude: this.currentLat,
        longitude: this.currentLng
      },
      radius: this.searchRadius,
      language: 'zh',
      pageSize: 20,
      pageIndex: 1
    };

    try {
      const result = await site.searchByText(params);
      this.searchResults = {
        totalCount: result.totalCount,
        sites: result.sites?.map(s => ({
          siteId: s.siteId,
          name: s.name || '',
          formatAddress: s.formatAddress || '',
          location: { latitude: s.location.latitude, longitude: s.location.longitude },
          distance: s.distance
        })) || []
      };
      this.errorMessage = '';
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  async performNearbySearch(): Promise<void> {
    let params: site.NearbySearchParams = {
      location: {
        latitude: this.currentLat,
        longitude: this.currentLng
      },
      radius: this.searchRadius,
      poiTypes: ['RESTAURANT', 'HOTEL', 'SCENIC_SPOT'],
      language: 'zh',
      pageSize: 20,
      pageIndex: 1,
      sortRule: site.SortRule.DISTANCE
    };

    try {
      const result = await site.nearbySearch(params);
      this.searchResults = {
        totalCount: result.totalCount,
        sites: result.sites?.map(s => ({
          siteId: s.siteId,
          name: s.name || '',
          formatAddress: s.formatAddress || '',
          location: { latitude: s.location.latitude, longitude: s.location.longitude },
          distance: s.distance
        })) || []
      };
      this.errorMessage = '';
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  async performAutoComplete(): Promise<void> {
    let params: site.QueryAutoCompleteParams = {
      query: this.searchQuery,
      location: {
        latitude: this.currentLat,
        longitude: this.currentLng
      },
      radius: 50000,
      language: 'zh',
      isChildren: true
    };

    try {
      const result = await site.queryAutoComplete(params);
      this.suggestions = result.sites?.map(s => s.name || '') || [];
      this.errorMessage = '';
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  async performDetailSearch(): Promise<void> {
    if (!this.siteId || this.siteId.length < 1) {
      this.errorMessage = '地点ID不能为空';
      return;
    }

    let params: site.SearchByIdParams = {
      siteId: this.siteId,
      language: 'zh',
      isChildren: true
    };

    try {
      const result = await site.searchById(params);
      
      if (result.site) {
        let detail = `地点详情:\n`;
        detail += `名称: ${result.site.name}\n`;
        detail += `地址: ${result.site.formatAddress}\n`;
        detail += `经纬度: (${result.site.location.latitude}, ${result.site.location.longitude})\n`;
        
        if (result.site.poi) {
          detail += `\nPOI信息:\n`;
          detail += `类型: ${result.site.poi.poiTypes?.join(', ')}\n`;
          if (result.site.poi.phone) detail += `电话: ${result.site.poi.phone}\n`;
          if (result.site.poi.rating) detail += `评分: ${result.site.poi.rating}\n`;
          if (result.site.poi.businessStatus) detail += `状态: ${result.site.poi.businessStatus}\n`;
        }
        
        this.siteDetail = detail;
      } else {
        this.siteDetail = '未找到地点信息';
      }
      this.errorMessage = '';
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  handleError(err: BusinessError): void {
    switch (err.code) {
      case 401:
        this.errorMessage = '参数无效，请检查输入';
        break;
      case 1002600001:
        this.errorMessage = '系统内部错误，请稍后重试';
        break;
      case 1002600002:
        this.errorMessage = '网络连接失败，请检查网络';
        break;
      case 1002600003:
        this.errorMessage = '应用认证失败，请检查配置';
        break;
      case 1002600004:
        this.errorMessage = 'Map Kit权限未开启';
        break;
      case 1002603001:
        this.errorMessage = '未找到搜索结果';
        break;
      default:
        this.errorMessage = `错误: ${err.code}, ${err.message}`;
    }
  }
}