import { AppDimens } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';

interface MessageItem {
  id: number;
  text: string;
  isMe: boolean;
  time: string;
}

@Component
export default struct InfoPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;

  @State messageList: MessageItem[] = [];
  @State currentInput: string = '';
  private scroller: Scroller = new Scroller();

  build() {
    Column() {
      // 聊天记录列表
      List({ scroller: this.scroller }) {
        ForEach(this.messageList, (item: MessageItem) => {
          ListItem() {
            this.MessageBubble(item)
          }
        }, (item: MessageItem) => item.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(this.getColors().background)

      // 输入区域
      Row() {
        TextInput({ placeholder: '输入消息内容...', text: this.currentInput })
          .onChange((value: string) => { this.currentInput = value })
          .layoutWeight(1)
          .height(AppDimens.BUTTON_HEIGHT)
          .backgroundColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .padding({ left: AppDimens.PADDING_MEDIUM })
          .fontColor(this.getColors().textPrimary)
          .placeholderColor(this.getColors().textSecondary)
        Button('发送')
          .height(AppDimens.BUTTON_HEIGHT)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .margin({ left: AppDimens.MARGIN_SMALL })
          .onClick(() => {
            if (this.currentInput.trim().length === 0) {
              return;
            }
            const newMessage: MessageItem = {
              id: Date.now(),
              text: this.currentInput,
              isMe: true,
              time: new Date().toLocaleTimeString().slice(0, 5)
            };
            this.messageList.push(newMessage);
            this.currentInput = '';
            this.scroller.scrollEdge(Edge.Bottom);
          })
      }
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MessageBubble(item: MessageItem) {
    Row() {
      if (item.isMe) {
        Blank()
      }
      Column() {
        Text(item.text)
          .fontSize(16)
          .fontColor(item.isMe ? this.getColors().cardBg : this.getColors().textPrimary)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(item.isMe ? this.getColors().primary : this.getColors().cardBg)
          .borderRadius(16)
        Text(item.time)
          .fontSize(10)
          .fontColor(this.getColors().textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(item.isMe ? HorizontalAlign.End : HorizontalAlign.Start)
      if (!item.isMe) {
        Blank()
      }
    }
    .padding({ left: AppDimens.PADDING_MEDIUM, right: AppDimens.PADDING_MEDIUM, top: AppDimens.PADDING_SMALL, bottom: AppDimens.PADDING_SMALL })
    .width('100%')
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}
