import StatusPage from './StatusPage';
import DataPage from './DataPage';
import InfoPage from './InfoPage';
import ProfilePage from './ProfilePage';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { initHistoryData } from '../common/HistoryData';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0;
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;
  private tabsController: TabsController = new TabsController();

  aboutToAppear(): void {
    // 初始化主题默认值
    if (AppStorage.get<string>('themeMode') === undefined) {
      AppStorage.setOrCreate('themeMode', ThemeMode.GREEN_WHITE);
    }
    // 初始化历史数据
    initHistoryData();
  }

  build() {
    Column() {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentTabIndex,
        controller: this.tabsController
      }) {
        TabContent() {
          StatusPage()
        }
        .tabBar(this.TabBarBuilder('状态', 0))

        TabContent() {
          DataPage()
        }
        .tabBar(this.TabBarBuilder('数据', 1))

        TabContent() {
          InfoPage()
        }
        .tabBar(this.TabBarBuilder('信息', 2))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBarBuilder('我的', 3))
      }
      .vertical(false)
      .scrollable(false)
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
      .backgroundColor(this.getTabBarBgColor())
    }
    .height('100%')
    .width('100%')
    .backgroundColor(this.getPageBgColor())
  }

  @Builder
  TabBarBuilder(title: string, index: number) {
    Column() {
      Text(this.getIconText(index))
        .fontSize(24)
        .fontColor(this.getTabColor(index))
      Text(title)
        .fontSize(12)
        .fontColor(this.getTabColor(index))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private getIconText(index: number): string {
    switch (index) {
      case 0: return '📊';
      case 1: return '📈';
      case 2: return '💬';
      case 3: return '👤';
      default: return '?';
    }
  }

  // 动态获取 Tab 图标/文字颜色（根据主题模式和选中状态）
  private getTabColor(index: number): string {
    const isActive = this.currentTabIndex === index;
    const colors = getThemeColors(this.themeMode as ThemeMode);
    if (isActive) {
      return colors.primary;
    } else {
      return colors.textSecondary;
    }
  }

  // 动态获取底部 Tab 栏背景色
  private getTabBarBgColor(): string {
    const colors = getThemeColors(this.themeMode as ThemeMode);
    return colors.cardBg;
  }

  // 动态获取整个页面背景色（可能会被子组件覆盖，但作为整体背景）
  private getPageBgColor(): string {
    const colors = getThemeColors(this.themeMode as ThemeMode);
    return colors.background;
  }
}