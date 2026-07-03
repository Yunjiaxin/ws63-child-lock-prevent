import StatusPage from './StatusPage';
import DataPage from './DataPage';
import InfoPage from './InfoPage';
import ProfilePage from './ProfilePage';
import VideoPage from './VideoPage';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { initHistoryData } from '../common/HistoryData';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0;
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;
  private tabsController: TabsController = new TabsController();

  aboutToAppear(): void {
    if (AppStorage.get<string>('themeMode') === undefined) {
      AppStorage.setOrCreate('themeMode', ThemeMode.GREEN_WHITE);
    }
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
          VideoPage()
        }
        .tabBar(this.TabBarBuilder('监控', 2))

        TabContent() {
          InfoPage()
        }
        .tabBar(this.TabBarBuilder('信息', 3))

        TabContent() {
          ProfilePage()
        }
        .tabBar(this.TabBarBuilder('我的', 4))
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
      Image(this.getIconRes(index))
        .width(24)
        .height(24)
        .fillColor(this.getTabColor(index))
      Text(title)
        .fontSize(12)
        .fontColor(this.getTabColor(index))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private getIconRes(index: number): Resource {
    switch (index) {
      case 0: return $r('app.media.a1');
      case 1: return $r('app.media.a2');
      case 2: return $r('app.media.video');
      case 3: return $r('app.media.a3');
      case 4: return $r('app.media.a4');
      default: return $r('app.media.a1');
    }
  }

  private getTabColor(index: number): string {
    const isActive = this.currentTabIndex === index;
    const colors = getThemeColors(this.themeMode as ThemeMode);
    return isActive ? colors.primary : colors.textSecondary;
  }

  private getTabBarBgColor(): string {
    const colors = getThemeColors(this.themeMode as ThemeMode);
    return colors.cardBg;
  }

  private getPageBgColor(): string {
    const colors = getThemeColors(this.themeMode as ThemeMode);
    return colors.background;
  }
}
