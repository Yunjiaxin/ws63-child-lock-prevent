import { AppDimens } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { HistoryRecord, SensorDataPoint, SensorType, getSensorDataByType } from '../common/HistoryData';
import { promptAction } from '@kit.ArkUI';

@Component
export default struct DataPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;
  @StorageLink('historyList') historyList: HistoryRecord[] = [];
  @StorageLink('sensorDataList') sensorDataList: SensorDataPoint[] = [];

  @State selectedSensorType: SensorType = SensorType.CO2;
  @State chartDataPoints: SensorDataPoint[] = [];
  @State minVal: number = 0;
  @State range: number = 1;
  @State lineMinVal: number = 0;
  @State lineRange: number = 1;
  @State lineMaxVal: number = 100;

  aboutToAppear(): void {
    this.loadData();
  }

  loadData(): void {
    this.chartDataPoints = getSensorDataByType(this.selectedSensorType, 15);
    this.calcParams();
    this.calcLineParams();
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

  calcLineParams(): void {
    if (this.chartDataPoints.length === 0) {
      this.lineMinVal = 0;
      this.lineMaxVal = 100;
      this.lineRange = 1;
      return;
    }
    let max = this.chartDataPoints[0].value;
    let min = this.chartDataPoints[0].value;
    for (let i = 1; i < this.chartDataPoints.length; i++) {
      const v = this.chartDataPoints[i].value;
      if (v > max) max = v;
      if (v < min) min = v;
    }
    const diff = max - min;
    if (diff === 0) {
      this.lineMinVal = min * 0.8;
      this.lineMaxVal = max * 1.2;
    } else {
      this.lineMinVal = min - diff * 0.2;
      this.lineMaxVal = max + diff * 0.2;
    }
    const rng = this.lineMaxVal - this.lineMinVal;
    this.lineRange = rng === 0 ? 1 : rng;
  }

  build() {
    Column() {
      // 传感器类型选择
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

      Scroll() {
        Column() {
          // 数据趋势卡片
          Column() {
            Row() {
              Text(this.getChartTitle())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getColors().textPrimary)
                .layoutWeight(1)
              Text('↻')
                .fontSize(24)
                .fontColor(this.getColors().primary)
                .onClick(() => {
                  this.loadData();
                })
            }
            .margin({ bottom: 12 })
            .width('100%')

            if (this.chartDataPoints.length === 0) {
              Text('暂无数据 — 请先在「状态」页连接平台获取真实数据')
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
              .height(260)
            }
          }
          .padding(AppDimens.PADDING_MEDIUM)
          .backgroundColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .margin({ bottom: AppDimens.MARGIN_LARGE })
          .width('100%')

          // 折线图卡片
          this.LineChartCard()

          // 数据来源说明
          Column() {
            Text('数据来源')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getColors().textPrimary)
              .margin({ bottom: AppDimens.MARGIN_SMALL })
            Row() {
              Text('所有传感器数据来自华为云 IoTDA 平台实时推送')
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
          .width('100%')

          // 历史事件记录
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
            }
          }
          .width('100%')
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
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
      .backgroundColor(this.selectedSensorType === type ? this.getColors().primary : this.getColors().cardBg + '80')
      .fontColor(this.selectedSensorType === type ? this.getColors().cardBg : this.getColors().textPrimary)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .border({ width: 1, color: this.getColors().border })
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
      Text(item.value.toFixed(3))
        .fontSize(12)
        .fontColor(this.getColors().textPrimary)
        .width(55)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }

  getBarWidth(value: number): string {
    const minWidthPct = 10;
    const maxWidthPct = 70;
    let ratio = (value - this.minVal) / this.range;
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

  // ========== 折线图卡片（纯组件实现） ==========
  @Builder
  private LineChartCard(): void {
    Column() {
      Row() {
        Text(this.getChartTitle() + ' - 折线图')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
      }
      .margin({ bottom: 12 })
      .width('100%')

      if (this.chartDataPoints.length === 0) {
        Text('暂无数据')
          .fontSize(14)
          .fontColor(this.getColors().textSecondary)
          .height(160)
          .textAlign(TextAlign.Center)
          .width('100%')
      } else {
        // 图表区域：Y轴标签 + 折线图
        Row() {
          // Y轴刻度标签
          Column() {
            Text(this.formatAxisVal(this.lineMaxVal))
              .fontSize(9)
              .fontColor(this.getColors().textSecondary)
            Text('')
              .layoutWeight(1)
            Text(this.formatAxisVal((this.lineMinVal + this.lineMaxVal) / 2))
              .fontSize(9)
              .fontColor(this.getColors().textSecondary)
            Text('')
              .layoutWeight(1)
            Text(this.formatAxisVal(this.lineMinVal))
              .fontSize(9)
              .fontColor(this.getColors().textSecondary)
          }
          .width(44)
          .height(160)
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ right: 4 })

          // 折线图区域：用点的高度模拟
          Stack() {
            // 背景网格线
            Column() {
              Divider().color(this.getColors().textSecondary + '18').height(1)
              Text('').layoutWeight(1)
              Divider().color(this.getColors().textSecondary + '18').height(1)
              Text('').layoutWeight(1)
              Divider().color(this.getColors().textSecondary + '18').height(1)
            }
            .width('100%')
            .height(160)

            // 数据点
            Row() {
              ForEach(this.chartDataPoints, (item: SensorDataPoint, idx: number) => {
                Column() {
                  Text('')
                    .layoutWeight(this.getLineBottomRatio(item.value))
                  // 圆点
                  Circle({ width: 8, height: 8 })
                    .fill(this.getColors().primary)
                  Text('')
                    .layoutWeight(this.getLineTopRatio(item.value))
                }
                .height(160)
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              })
            }
            .width('100%')
            .height(160)
          }
          .layoutWeight(1)
          .height(160)
          .backgroundColor(this.getColors().background)
          .borderRadius(6)
        }
        .width('100%')
        .height(160)

        // X轴序号标签
        Row() {
          Text('#1')
            .fontSize(9)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          if (this.chartDataPoints.length > 1) {
            Text(`#${Math.ceil(this.chartDataPoints.length / 2)}`)
              .fontSize(9)
              .fontColor(this.getColors().textSecondary)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
          Text(`#${this.chartDataPoints.length}`)
            .fontSize(9)
            .fontColor(this.getColors().textSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 48, right: 0 })
        .margin({ top: 4 })
      }
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .margin({ bottom: AppDimens.MARGIN_LARGE })
    .width('100%')
  }

  // 获取数据点在折线图中的底部占比（到最大值的距离）
  private getLineBottomRatio(value: number): number {
    const ratio = (value - this.lineMinVal) / this.lineRange;
    return Math.max(0, Math.min(1, ratio));
  }

  // 获取数据点在折线图中的顶部占比
  private getLineTopRatio(value: number): number {
    const ratio = (value - this.lineMinVal) / this.lineRange;
    return 1 - Math.max(0, Math.min(1, ratio));
  }

  // 格式化 Y 轴刻度值
  private formatAxisVal(v: number): string {
    if (v >= 1000) return Math.round(v).toString();
    if (v >= 100) return v.toFixed(0);
    if (v >= 10) return v.toFixed(1);
    if (v >= 1) return v.toFixed(1);
    return v.toFixed(2);
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}
