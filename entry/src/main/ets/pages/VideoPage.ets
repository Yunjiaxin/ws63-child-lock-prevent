import { notificationManager } from '@kit.NotificationKit';
import web_webview from '@ohos.web.webview';
import { AppDimens } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';

@Component
export default struct VideoPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;

  webviewController: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
      Column() {
        Row() {
          Text('实时监视画面 (AI 分析中)')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getColors().textPrimary)
            .layoutWeight(1)
          Text('前置摄像头：车内后视镜处')
            .fontSize(12)
            .fontColor(this.getColors().textSecondary)
        }
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })

        Web({ src: 'http://192.168.203.184:5000/', controller: this.webviewController })
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(Color.Black)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onAlert((event) => {
            if (event) {
              notificationManager.addSlot(notificationManager.SlotType.SOCIAL_COMMUNICATION).then(() => {
                let notificationRequest: notificationManager.NotificationRequest = {
                  id: 1001,
                  content: {
                    notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
                    normal: {
                      title: '车内安全系统警告',
                      text: event.message,
                      additionalText: '前置摄像头检测到异常'
                    }
                  },
                  notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
                };

                notificationManager.publish(notificationRequest).then(() => {
                  console.info('通知发送成功');
                }).catch((err: Error) => {
                  console.error('通知发送失败: ' + JSON.stringify(err));
                });
              });

              event.result.handleConfirm();
              return true;
            }
            return false;
          })
      }
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .width('100%')
      .layoutWeight(1)
    }
    .padding(AppDimens.PADDING_LARGE)
    .width('100%')
    .height('100%')
    .backgroundColor(this.getColors().background)
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}
