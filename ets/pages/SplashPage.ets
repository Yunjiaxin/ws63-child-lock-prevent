import router from '@ohos.router';

@Entry
@Component
struct SplashPage {
  @State leftOffsetX: string = '0%';
  @State rightOffsetX: string = '0%';

  aboutToAppear(): void {
    setTimeout(() => {
      this.startAnimation();
    }, 50);
  }

  startAnimation(): void {
    animateTo({
      duration: 1000,
      curve: Curve.EaseInOut,
      onFinish: () => {
        router.replaceUrl({ url: 'pages/Index' });
      }
    }, () => {
      this.leftOffsetX = '-50%';
      this.rightOffsetX = '50%';
    });
  }

  build() {
    Stack() {
      // 底层背景：白色，带中心渐变
      Column() {
        Text('SAFE')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4CAF50')
          .shadow({ radius: 6, color: '#AA000000', offsetY: 2 })
        Text('安全守护')
          .fontSize(18)
          .fontColor('#757575')
          .margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')

      // 左门：浅绿色不透明，带右侧阴影
      Row()
        .width('50%')
        .height('100%')
        .backgroundColor('#A5D6A7')
        .shadow({ radius: 10, color: '#33000000', offsetX: 2 })
        .translate({ x: this.leftOffsetX })
        .position({ x: 0, y: 0 })

      // 右门：浅绿色不透明，带左侧阴影
      Row()
        .width('50%')
        .height('100%')
        .backgroundColor('#A5D6A7')
        .shadow({ radius: 10, color: '#33000000', offsetX: -2 })
        .translate({ x: this.rightOffsetX })
        .position({ x: '50%', y: 0 })
    }
    .width('100%')
    .height('100%')
  }
}