import { AppDimens } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { HistoryRecord, SensorDataPoint, SensorType, getSensorDataByType } from '../common/HistoryData';

@Component
export default struct DataPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;
  @StorageLink('historyList') historyList: HistoryRecord[] = [];
  @StorageLink('sensorDataList') sensorDataList: SensorDataPoint[] = [];

  @State selectedSensorType: SensorType = SensorType.CO2;
  @State chartDataPoints: SensorDataPoint[] = [];
  @State minVal: number = 0;
  @State range: number = 1; //  = max - min

  aboutToAppear(): void {
    this.loadData();
  }

  loadData(): void {
    this.chartDataPoints = getSensorDataByType(this.selectedSensorType, 15);
    this.calcParams();
  }

  calcParams(): void {
    if (this.chartDataPoints.length === 0) {
      this.minVal = 0;
      this.range = 1;
      return;
    }
    let max = this.chartDataPoints[0].value;
    let min = this.chartDataPoints[0].value;
    for (let i = 1; i < this.chartDataPoints.length; i++) {
      const v = this.chartDataPoints[i].value;
      if (v > max) max = v;
      if (v < min) min = v;
    }
    this.minVal = min;
    const diff = max - min;
    this.range = diff === 0 ? 1 : diff;
  }

  build() {
    Column() {
      Row() {
        this.createButton(SensorType.CO2, 'CO₂')
        this.createButton(SensorType.TEMPERATURE, '温度')
        this.createButton(SensorType.HUMIDITY, '湿度')
        this.createButton(SensorType.HCHO, '甲醛')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      // 数据趋势卡片（带刷新按钮）
      Column() {
        Row() {
          Text(this.getChartTitle())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getColors().textPrimary)
            .layoutWeight(1)
          Image($r('app.media.arrow_clockwise'))
            .width(24)
            .height(24)
            .onClick(() => {
              this.loadData();
            })
        }
        .margin({ bottom: 12 })
        .width('100%')

        if (this.chartDataPoints.length === 0) {
          Text('暂无数据')
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .height(120)
            .textAlign(TextAlign.Center)
        } else {
          Column() {
            ForEach(this.chartDataPoints, (item: SensorDataPoint, idx: number) => {
              this.createBarItem(item, idx)
            })
          }
          .width('100%')
          .height(200)
        }
      }
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .margin({ bottom: AppDimens.MARGIN_LARGE })
      .width('100%')

      Column() {
        Text('摄像头位置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getColors().textPrimary)
          .margin({ bottom: AppDimens.MARGIN_SMALL })
        Row() {
          Text('前置摄像头：车内后视镜处')
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
        }
        .padding(AppDimens.PADDING_SMALL)
        .backgroundColor(this.getColors().primary + '20')
        .borderRadius(AppDimens.CORNER_RADIUS)
        .width('100%')
      }
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .margin({ bottom: AppDimens.MARGIN_LARGE })

      Column() {
        Text('历史事件记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getColors().textPrimary)
          .margin({ bottom: AppDimens.MARGIN_MEDIUM })
        if (this.historyList.length === 0) {
          Text('暂无历史记录')
            .fontSize(14)
            .fontColor(this.getColors().textSecondary)
            .padding(AppDimens.PADDING_LARGE)
        } else {
          List() {
            ForEach(this.historyList, (item: HistoryRecord) => {
              ListItem() {
                Column() {
                  Text(item.timestamp)
                    .fontSize(12)
                    .fontColor(this.getColors().textSecondary)
                  Text(item.description)
                    .fontSize(14)
                    .fontColor(this.getColors().textPrimary)
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .padding(AppDimens.PADDING_SMALL)
                .width('100%')
              }
              .border({ width: { bottom: 1 }, color: this.getColors().border })
            }, (item: HistoryRecord) => item.id.toString())
          }
          .height(300)
          .width('100%')
          .backgroundColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
        }
      }
      .width('100%')
    }
    .padding(AppDimens.PADDING_LARGE)
    .width('100%')
    .height('100%')
    .backgroundColor(this.getColors().background)
  }

  @Builder
  createButton(type: SensorType, label: string) {
    Button(label)
      .height(36)
      .backgroundColor(this.selectedSensorType === type ? this.getColors().primary : this.getColors().cardBg)
      .fontColor(this.selectedSensorType === type ? this.getColors().cardBg : this.getColors().textPrimary)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .onClick(() => {
        this.selectedSensorType = type;
        this.loadData();
      })
  }

  @Builder
  createBarItem(item: SensorDataPoint, index: number) {
    Row() {
      Text((index + 1).toString())
        .fontSize(12)
        .fontColor(this.getColors().textSecondary)
        .width(30)
      Row()
        .width(this.getBarWidth(item.value))
        .height(20)
        .backgroundColor(this.getColors().primary)
        .borderRadius(4)
        .margin({ right: 8 })
      Text(item.value.toFixed(3))  // 保留三位小数，更精确
        .fontSize(12)
        .fontColor(this.getColors().textPrimary)
        .width(55)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }

  // 柱状图宽度：最小值对应 10%，最大值对应 70%，中间按比例映射
  getBarWidth(value: number): string {
    const minWidthPct = 10;
    const maxWidthPct = 70;
    let ratio = (value - this.minVal) / this.range;   // 0~1
    let widthPct = minWidthPct + ratio * (maxWidthPct - minWidthPct);
    return widthPct + '%';
  }

  getChartTitle(): string {
    switch (this.selectedSensorType) {
      case SensorType.CO2: return 'CO₂ 浓度趋势 (ppm)';
      case SensorType.TEMPERATURE: return '温度趋势 (°C)';
      case SensorType.HUMIDITY: return '湿度趋势 (%)';
      case SensorType.HCHO: return '甲醛浓度趋势 (mg/m³)';
      default: return '数据趋势';
    }
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}