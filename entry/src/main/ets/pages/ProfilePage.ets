import { ThemeMode, getThemeColors } from '../common/Theme';
import { AppDimens, TEXT_BODY_SIZE } from '../common/Styles';

@Component
export default struct ProfilePage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;

  build() {
    Column() {
      Text('我的')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getColors().textPrimary)
        .margin({ top: AppDimens.MARGIN_LARGE })

      // 主题切换区域
      Row() {
        Text('深色主题（黑蓝）')
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.themeMode === ThemeMode.DARK_BLUE })
          .onChange((isOn: boolean) => {
            if (isOn) {
              this.themeMode = ThemeMode.DARK_BLUE;
            } else {
              this.themeMode = ThemeMode.GREEN_WHITE;
            }
          })
      }
      .width('90%')
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .margin({ top: AppDimens.MARGIN_LARGE })

      // 关于我们
      Row() {
        Text('关于我们')
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Text('版本 1.0.0')
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.getColors().textSecondary)
      }
      .width('90%')
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .margin({ top: AppDimens.MARGIN_MEDIUM })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.getColors().background)
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}
