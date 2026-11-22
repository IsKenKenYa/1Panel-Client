/**
 * HarmonyOS 未成年人模式内容分级示例
 * 
 * 功能说明：
 * 1. 根据年龄段实现内容分级展示
 * 2. 内容过滤和审查逻辑
 * 3. 分级标签管理
 * 4. 动态内容适配
 * 
 * 年龄段范围：
 * - [0,3): 婴幼儿内容
 * - [3,8): 学龄前儿童内容
 * - [8,12): 学龄儿童内容
 * - [12,16): 青少年内容
 * - [16,18): 大龄青少年内容
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { minorsProtection } from '@kit.AccountKit';

const TAG = 'ContentFilter';
const DOMAIN = 0x0000;

/**
 * 内容分级级别定义
 */
enum ContentRatingLevel {
  INFANT = 0,        // 婴幼儿（0-3岁）
  PRESCHOOL = 1,     // 学龄前（3-8岁）
  SCHOOL_AGE = 2,    // 学龄期（8-12岁）
  TEENAGER = 3,      // 青少年（12-16岁）
  YOUNG_ADULT = 4,   // 大龄青少年（16-18岁）
  ADULT = 5          // 成人（无限制）
}

/**
 * 内容分类定义
 */
enum ContentCategory {
  EDUCATION = 'education',      // 教育类
  ENTERTAINMENT = 'entertainment', // 娱乐类
  GAME = 'game',                // 游戏类
  VIDEO = 'video',              // 视频类
  MUSIC = 'music',              // 音乐类
  BOOK = 'book',                // 图书类
  SOCIAL = 'social'             // 社交类
}

/**
 * 内容项定义
 */
interface ContentItem {
  id: string;
  title: string;
  category: ContentCategory;
  ratingLevel: ContentRatingLevel;  // 内容适合的最高年龄段
  tags: string[];
  isViolent: boolean;               // 是否包含暴力内容
  isExplicit: boolean;              // 是否包含不适宜内容
}

/**
 * 内容过滤器类
 */
class ContentFilter {
  private currentAgeGroup: minorsProtection.AgeGroup | null = null;
  private currentLevel: ContentRatingLevel = ContentRatingLevel.ADULT;
  private filterEnabled: boolean = false;
  
  /**
   * 设置当前年龄段
   */
  setAgeGroup(ageGroup: minorsProtection.AgeGroup | undefined): void {
    if (ageGroup) {
      this.currentAgeGroup = ageGroup;
      this.currentLevel = this.convertAgeGroupToLevel(ageGroup.upperAge);
      this.filterEnabled = true;
      hilog.info(DOMAIN, TAG, `Age group set: [${ageGroup.lowerAge}, ${ageGroup.upperAge}), level: ${this.currentLevel}`);
    } else {
      this.currentAgeGroup = null;
      this.currentLevel = ContentRatingLevel.ADULT;
      this.filterEnabled = false;
      hilog.info(DOMAIN, TAG, 'Age group cleared, no filter applied');
    }
  }
  
  /**
   * 将年龄段转换为分级级别
   */
  private convertAgeGroupToLevel(upperAge: number): ContentRatingLevel {
    switch (upperAge) {
      case 3:
        return ContentRatingLevel.INFANT;
      case 8:
        return ContentRatingLevel.PRESCHOOL;
      case 12:
        return ContentRatingLevel.SCHOOL_AGE;
      case 16:
        return ContentRatingLevel.TEENAGER;
      case 18:
        return ContentRatingLevel.YOUNG_ADULT;
      default:
        return ContentRatingLevel.ADULT;
    }
  }
  
  /**
   * 过滤内容列表
   */
  filterContentList(contents: ContentItem[]): ContentItem[] {
    if (!this.filterEnabled) {
      hilog.info(DOMAIN, TAG, 'Filter disabled, returning all content');
      return contents;
    }
    
    const filteredContents = contents.filter(content => {
      return this.isContentAllowed(content);
    });
    
    hilog.info(DOMAIN, TAG, `Filtered ${contents.length} items to ${filteredContents.length} items`);
    return filteredContents;
  }
  
  /**
   * 判断内容是否允许展示
   */
  isContentAllowed(content: ContentItem): boolean {
    if (!this.filterEnabled) {
      return true;
    }
    
    // 内容分级级别必须小于等于当前年龄段级别
    if (content.ratingLevel > this.currentLevel) {
      hilog.info(DOMAIN, TAG, `Content ${content.id} blocked: rating level ${content.ratingLevel} > current level ${this.currentLevel}`);
      return false;
    }
    
    // 暴力内容：仅允许大龄青少年及以上
    if (content.isViolent && this.currentLevel < ContentRatingLevel.YOUNG_ADULT) {
      hilog.info(DOMAIN, TAG, `Content ${content.id} blocked: violent content not allowed for current age`);
      return false;
    }
    
    // 不适宜内容：完全禁止
    if (content.isExplicit && this.filterEnabled) {
      hilog.info(DOMAIN, TAG, `Content ${content.id} blocked: explicit content not allowed`);
      return false;
    }
    
    return true;
  }
  
  /**
   * 获取推荐内容
   */
  getRecommendedContent(contents: ContentItem[]): ContentItem[] {
    if (!this.filterEnabled) {
      return contents;
    }
    
    // 优先推荐符合当前年龄段的内容
    const preferredContents = contents.filter(content => {
      return content.ratingLevel === this.currentLevel;
    });
    
    hilog.info(DOMAIN, TAG, `Found ${preferredContents.length} recommended items for level ${this.currentLevel}`);
    return preferredContents;
  }
  
  /**
   * 获取当前过滤状态
   */
  getFilterStatus(): { enabled: boolean; level: ContentRatingLevel; ageGroup: string } {
    return {
      enabled: this.filterEnabled,
      level: this.currentLevel,
      ageGroup: this.currentAgeGroup ? `[${this.currentAgeGroup.lowerAge}, ${this.currentAgeGroup.upperAge})` : 'No limit'
    };
  }
}

/**
 * 内容数据库（示例）
 */
class ContentDatabase {
  private contents: ContentItem[] = [
    {
      id: '1',
      title: '幼儿启蒙动画',
      category: ContentCategory.ENTERTAINMENT,
      ratingLevel: ContentRatingLevel.INFANT,
      tags: ['动画', '启蒙', '幼儿'],
      isViolent: false,
      isExplicit: false
    },
    {
      id: '2',
      title: '小学数学课程',
      category: ContentCategory.EDUCATION,
      ratingLevel: ContentRatingLevel.SCHOOL_AGE,
      tags: ['数学', '课程', '小学'],
      isViolent: false,
      isExplicit: false
    },
    {
      id: '3',
      title: '青少年科幻小说',
      category: ContentCategory.BOOK,
      ratingLevel: ContentRatingLevel.TEENAGER,
      tags: ['小说', '科幻', '青少年'],
      isViolent: false,
      isExplicit: false
    },
    {
      id: '4',
      title: '成人动作电影',
      category: ContentCategory.VIDEO,
      ratingLevel: ContentRatingLevel.ADULT,
      tags: ['电影', '动作'],
      isViolent: true,
      isExplicit: false
    },
    {
      id: '5',
      title: '益智小游戏',
      category: ContentCategory.GAME,
      ratingLevel: ContentRatingLevel.PRESCHOOL,
      tags: ['游戏', '益智', '儿童'],
      isViolent: false,
      isExplicit: false
    }
  ];
  
  getAllContents(): ContentItem[] {
    return this.contents;
  }
  
  getContentsByCategory(category: ContentCategory): ContentItem[] {
    return this.contents.filter(content => content.category === category);
  }
}

/**
 * 内容服务类
 */
class ContentService {
  private filter: ContentFilter = new ContentFilter();
  private database: ContentDatabase = new ContentDatabase();
  
  /**
   * 更新年龄段并刷新内容
   */
  updateAgeGroup(ageGroup: minorsProtection.AgeGroup | undefined): void {
    this.filter.setAgeGroup(ageGroup);
  }
  
  /**
   * 获取所有可用内容
   */
  getAvailableContents(): ContentItem[] {
    const allContents = this.database.getAllContents();
    return this.filter.filterContentList(allContents);
  }
  
  /**
   * 获取推荐内容
   */
  getRecommendedContents(): ContentItem[] {
    const allContents = this.database.getAllContents();
    return this.filter.getRecommendedContent(allContents);
  }
  
  /**
   * 获取特定分类的可用内容
   */
  getContentsByCategory(category: ContentCategory): ContentItem[] {
    const categoryContents = this.database.getContentsByCategory(category);
    return this.filter.filterContentList(categoryContents);
  }
  
  /**
   * 获取过滤状态
   */
  getFilterStatus(): { enabled: boolean; level: ContentRatingLevel; ageGroup: string } {
    return this.filter.getFilterStatus();
  }
}

/**
 * 使用示例
 */
function exampleUsage(): void {
  const contentService = new ContentService();
  
  // 示例1：婴幼儿年龄段 [0,3)
  hilog.info(DOMAIN, TAG, 'Example 1: Infant age group [0,3)');
  contentService.updateAgeGroup({ lowerAge: 0, upperAge: 3 });
  const infantContents = contentService.getAvailableContents();
  hilog.info(DOMAIN, TAG, `Available contents for infant: ${infantContents.length} items`);
  infantContents.forEach(content => {
    hilog.info(DOMAIN, TAG, `  - ${content.title}`);
  });
  
  // 示例2：学龄儿童年龄段 [8,12)
  hilog.info(DOMAIN, TAG, 'Example 2: School-age age group [8,12)');
  contentService.updateAgeGroup({ lowerAge: 8, upperAge: 12 });
  const schoolAgeContents = contentService.getAvailableContents();
  hilog.info(DOMAIN, TAG, `Available contents for school-age: ${schoolAgeContents.length} items`);
  schoolAgeContents.forEach(content => {
    hilog.info(DOMAIN, TAG, `  - ${content.title}`);
  });
  
  // 示例3：无年龄段限制
  hilog.info(DOMAIN, TAG, 'Example 3: No age group limit');
  contentService.updateAgeGroup(undefined);
  const allContents = contentService.getAvailableContents();
  hilog.info(DOMAIN, TAG, `Available contents without limit: ${allContents.length} items`);
  allContents.forEach(content => {
    hilog.info(DOMAIN, TAG, `  - ${content.title}`);
  });
}

/**
 * UI组件示例
 */
import { Component } from '@kit.ArkUI';

@Entry
@Component
struct ContentFilterPage {
  private contentService: ContentService = new ContentService();
  
  @State availableContents: ContentItem[] = [];
  @State filterStatus: string = 'No filter';
  
  aboutToAppear(): void {
    // 初始化内容服务
    this.loadContents();
  }
  
  loadContents(): void {
    this.availableContents = this.contentService.getAvailableContents();
    const status = this.contentService.getFilterStatus();
    this.filterStatus = `Filter: ${status.enabled ? 'Enabled' : 'Disabled'}, Age: ${status.ageGroup}`;
  }
  
  build() {
    Column() {
      Text('内容分级展示示例')
        .fontSize(24)
        .margin({ top: 20, bottom: 10 })
      
      Text(this.filterStatus)
        .fontSize(16)
        .margin({ bottom: 10 })
      
      List() {
        ForEach(this.availableContents, (content: ContentItem) => {
          ListItem() {
            Row() {
              Text(content.title)
                .fontSize(18)
                .width('70%')
              
              Text(this.getLevelText(content.ratingLevel))
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .padding({ left: 10, right: 10 })
          }
          .height(50)
        })
      }
      .width('100%')
      .height('60%')
      
      Row() {
        Button('婴幼儿 [0,3)')
          .onClick(() => {
            this.contentService.updateAgeGroup({ lowerAge: 0, upperAge: 3 });
            this.loadContents();
          })
          .width('30%')
        
        Button('学龄 [8,12)')
          .onClick(() => {
            this.contentService.updateAgeGroup({ lowerAge: 8, upperAge: 12 });
            this.loadContents();
          })
          .width('30%')
        
        Button('无限制')
          .onClick(() => {
            this.contentService.updateAgeGroup(undefined);
            this.loadContents();
          })
          .width('30%')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
  }
  
  getLevelText(level: ContentRatingLevel): string {
    switch (level) {
      case ContentRatingLevel.INFANT:
        return '婴幼儿';
      case ContentRatingLevel.PRESCHOOL:
        return '学龄前';
      case ContentRatingLevel.SCHOOL_AGE:
        return '学龄期';
      case ContentRatingLevel.TEENAGER:
        return '青少年';
      case ContentRatingLevel.YOUNG_ADULT:
        return '大龄青少年';
      case ContentRatingLevel.ADULT:
        return '成人';
      default:
        return '未知';
    }
  }
}