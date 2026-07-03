import { AppDimens, TEXT_TITLE_SIZE, TEXT_TITLE_WEIGHT, TEXT_BODY_SIZE, TEXT_CAPTION_SIZE } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { addHistoryRecord, addSensorDataPoint, SensorType } from '../common/HistoryData';
import { IoTDAService, SensorDataCallback } from '../service/IoTDAService';
import { promptAction } from '@kit.ArkUI';

@Component
export default struct StatusPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;

  @State co2: string = '--';
  @State hcho: string = '--';
  @State temperature: string = '--';
  @State humidity: string = '--';
  @State motion: string = '--';
  @State connectionStatus: string = '连接中...';
  @State isConnected: boolean = false;
  @State isDashboardMode: boolean = false;

  @State uploadEnvTemp: string = '25.0';
  @State uploadEnvHum: string = '60';
  @State uploadEnvCO2: string = '400';
  @State uploadEnvTVOC: string = '50';
  @State uploadLoading: boolean = false;

  private iot = IoTDAService.getInstance();

  aboutToAppear(): void {
    const cb: SensorDataCallback = (
      temp: string, hum: string, co2Val: string, hchoVal: string,
      motionVal: string
    ) => {
      if (temp !== '') {
        const t = Number(temp);
        this.temperature = isNaN(t) ? temp : (t % 1 === 0 ? t.toString() : t.toFixed(1));
        if (!isNaN(t)) addSensorDataPoint(SensorType.TEMPERATURE, t);
      }
      if (hum !== '') {
        const h = Number(hum);
        this.humidity = isNaN(h) ? hum : (h % 1 === 0 ? h.toString() : h.toFixed(1));
        if (!isNaN(h)) addSensorDataPoint(SensorType.HUMIDITY, h);
      }
      if (co2Val !== '') {
        this.co2 = co2Val;
        const c = Number(co2Val);
        if (!isNaN(c)) addSensorDataPoint(SensorType.CO2, c);
      }
      if (hchoVal !== '') {
        this.hcho = hchoVal;
        const hc = Number(hchoVal);
        if (!isNaN(hc)) addSensorDataPoint(SensorType.HCHO, hc);
      }
      if (motionVal !== '') {
        this.motion = motionVal;
      }
    };
    this.iot.registerDataCallback(cb);

    this.iot.registerConnectionCallback((connected: boolean, msg: string) => {
      this.isConnected = connected;
      this.connectionStatus = connected ? '已连接' : msg;
    });

    this.iot.connect().then((result: boolean) => {
      if (result) {
        this.isConnected = true;
        this.connectionStatus = '已连接';
        promptAction.showToast({ message: '平台连接成功', duration: 2000 });
      } else {
        this.connectionStatus = '连接失败';
      }
    });
  }

  aboutToDisappear(): void {
    this.iot.unregisterDataCallback();
  }

  private async uploadEnvironmentData() {
    if (!this.isConnected) {
      promptAction.showToast({ message: '请先连接平台', duration: 1500 });
      return;
    }
    const temp = Number(this.uploadEnvTemp);
    const hum = Number(this.uploadEnvHum);
    const co2 = Number(this.uploadEnvCO2);
    const tvoc = Number(this.uploadEnvTVOC);
    if (isNaN(temp) || isNaN(hum) || isNaN(co2) || isNaN(tvoc)) {
      promptAction.showToast({ message: '请输入有效数值', duration: 1500 });
      return;
    }
    this.uploadLoading = true;
    try {
      await this.iot.reportEnvironmentData(temp, hum, co2, tvoc);
      addHistoryRecord(`上报成功 environment：温度${temp}℃ 湿度${hum}% CO₂${co2}ppm TVOC${tvoc}`);
      promptAction.showToast({ message: 'environment 数据上报成功', duration: 2000 });
    } catch (err) {
      addHistoryRecord(`上报失败 environment：${String(err)}`);
      promptAction.showToast({ message: `上报失败: ${String(err)}`, duration: 2000 });
    } finally {
      this.uploadLoading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: AppDimens.MARGIN_MEDIUM }) {
        this.ConnectionStatusCard()
        this.ViewToggleButton()
        if (this.isDashboardMode) {
          this.DashboardView()
        } else {
          this.CO2Card()
          this.TempHumidCard()
          this.MotionCard()
        }
        this.UploadCard()
      }
      .padding(AppDimens.PADDING_LARGE)
      .width('100%')
    }
    .backgroundColor(this.getColors().background)
  }

  @Builder
  private ViewToggleButton(): void {
    Row() {
      Text(this.isDashboardMode ? '📋 仪表盘视图' : '📊 列表视图')
        .fontSize(13)
        .fontColor(this.getColors().textSecondary)
        .layoutWeight(1)
      Button(this.isDashboardMode ? '切换列表' : '切换仪表盘')
        .height(32)
        .fontSize(12)
        .backgroundColor(this.getColors().primary)
        .fontColor(Color.White)
        .borderRadius(AppDimens.CORNER_RADIUS)
        .padding({ left: 12, right: 12 })
        .onClick(() => {
          this.isDashboardMode = !this.isDashboardMode;
        })
    }
    .width('100%')
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
  }

  @Builder
  private DashboardView(): void {
    Column() {
      Text('传感器仪表盘')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Row({ space: AppDimens.MARGIN_MEDIUM }) {
        this.DashboardItem(
          '🌡️', '温度',
          this.temperature, '°C',
          '#FF6B35'
        )
        this.DashboardItem(
          '💧', '湿度',
          this.humidity, '%',
          '#2196F3'
        )
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Row({ space: AppDimens.MARGIN_MEDIUM }) {
        this.DashboardItem(
          '🫁', 'CO₂',
          this.co2, 'ppm',
          '#9C27B0'
        )
        this.DashboardItem(
          '☣️', '甲醛',
          this.hcho, 'mg/m³',
          '#FF9800'
        )
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Column() {
        Row() {
          Text('🚶')
            .fontSize(36)
            .margin({ right: 12 })
          Column() {
            Text('人体红外感应')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getColors().textPrimary)
            Row() {
              Circle({ width: 14, height: 14 })
                .fill(this.motion === '1' ? '#F44336' : '#4CAF50')
                .margin({ right: 6 })
              Text(this.motion === '1' ? '有人' : this.motion === '0' ? '无人' : this.motion)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.motion === '1' ? '#F44336' : '#4CAF50')
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .padding(AppDimens.PADDING_MEDIUM)
      .backgroundColor(this.getColors().cardBg)
      .borderRadius(AppDimens.CORNER_RADIUS)
      .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
      .width('100%')

      Text('来源：iotda 服务 · 实时上报')
        .fontSize(11)
        .fontColor(this.getColors().textSecondary + '80')
        .margin({ top: AppDimens.MARGIN_MEDIUM })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private DashboardItem(icon: string, label: string, value: string, unit: string, color: string) {
    Column() {
      Text(icon)
        .fontSize(40)
        .margin({ bottom: 4 })
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getColors().textSecondary)
        .margin({ bottom: 4 })
      Row() {
        Text(value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
        Text(` ${unit}`)
          .fontSize(14)
          .fontColor(this.getColors().textSecondary)
          .margin({ left: 2 })
      }
    }
    .layoutWeight(1)
    .padding({ top: 16, bottom: 16 })
    .backgroundColor(this.getColors().primary + '08')
    .borderRadius(AppDimens.CORNER_RADIUS)
    .border({ width: 1, color: color + '40' })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private ConnectionStatusCard(): void {
    Row() {
      Circle({ width: 10, height: 10 })
        .fill(this.isConnected ? '#4CAF50' : '#FF9800')
        .margin({ right: AppDimens.MARGIN_SMALL })
      Text(`平台连接：${this.connectionStatus}`)
        .fontSize(11)
        .fontColor(this.getColors().textSecondary)
        .layoutWeight(1)
      Button('刷新数据')
        .height(28)
        .fontSize(11)
        .backgroundColor(this.getColors().primary)
        .fontColor(this.getColors().cardBg)
        .borderRadius(AppDimens.CORNER_RADIUS)
        .enabled(this.isConnected)
        .onClick(() => {
          this.iot.refreshData();
        })
    }
    .width('100%')
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
  }

  @Builder
  private CO2Card(): void {
    Column() {
      Text('CO₂ / 甲醛')
        .fontSize(TEXT_TITLE_SIZE)
        .fontWeight(TEXT_TITLE_WEIGHT)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`CO₂: ${this.co2} ppm  甲醛: ${this.hcho} mg/m³`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
      Text('来源：environment 服务 · 实时上报')
        .fontSize(11)
        .fontColor(this.getColors().textSecondary + '80')
        .margin({ top: 4 })
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private TempHumidCard(): void {
    Column() {
      Text('温湿度')
        .fontSize(TEXT_TITLE_SIZE)
        .fontWeight(TEXT_TITLE_WEIGHT)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`温度: ${this.temperature} °C  湿度: ${this.humidity} %`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
      Text('来源：iotda 服务 · 实时上报')
        .fontSize(11)
        .fontColor(this.getColors().textSecondary + '80')
        .margin({ top: 4 })
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private MotionCard(): void {
    Column() {
      Text('人体红外感应')
        .fontSize(TEXT_TITLE_SIZE)
        .fontWeight(TEXT_TITLE_WEIGHT)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })
      Row() {
        Circle({ width: 12, height: 12 })
          .fill(this.motion === '1' ? '#F44336' : '#4CAF50')
          .margin({ right: 8 })
        Text(`检测状态: ${this.motion === '1' ? '有人' : this.motion === '0' ? '无人' : this.motion}`)
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.getColors().textSecondary)
      }
      .width('100%')
      Text('来源：iotda 服务 · 实时上报')
        .fontSize(11)
        .fontColor(this.getColors().textSecondary + '80')
        .margin({ top: 4 })
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private UploadCard(): void {
    Column() {
      Text('数据上报')
        .fontSize(TEXT_TITLE_SIZE)
        .fontWeight(TEXT_TITLE_WEIGHT)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Column() {
        Text('environment 服务')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getColors().primary)
          .width('100%')
          .margin({ bottom: AppDimens.MARGIN_SMALL })

        Row({ space: AppDimens.MARGIN_SMALL }) {
          this.InputField('温度(°C)', this.uploadEnvTemp, (v: string) => { this.uploadEnvTemp = v })
          this.InputField('湿度(%)', this.uploadEnvHum, (v: string) => { this.uploadEnvHum = v })
        }
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })

        Row({ space: AppDimens.MARGIN_SMALL }) {
          this.InputField('CO₂(ppm)', this.uploadEnvCO2, (v: string) => { this.uploadEnvCO2 = v })
          this.InputField('TVOC', this.uploadEnvTVOC, (v: string) => { this.uploadEnvTVOC = v })
        }
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_SMALL })

        Button(this.uploadLoading ? '上报中...' : '上报 environment 数据')
          .width('100%')
          .height(36)
          .fontSize(13)
          .fontColor(Color.White)
          .backgroundColor(this.isConnected ? '#4CAF50' : '#999')
          .borderRadius(AppDimens.CORNER_RADIUS)
          .enabled(this.isConnected && !this.uploadLoading)
          .onClick(() => this.uploadEnvironmentData())
      }
      .padding(AppDimens.PADDING_SMALL)
      .backgroundColor(this.getColors().primary + '10')
      .borderRadius(AppDimens.CORNER_RADIUS)
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })

      Text('数据通过 reportProperties 上报到华为云 IoTDA 平台')
        .fontSize(11)
        .fontColor(this.getColors().textSecondary + '80')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 4 })
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private InputField(label: string, value: string, onChange: (value: string) => void) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(11)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
      TextInput({ text: value })
        .height(34)
        .fontSize(13)
        .type(InputType.Number)
        .backgroundColor(this.getColors().background)
        .borderRadius(6)
        .padding({ left: 8, right: 8 })
        .fontColor(this.getColors().textPrimary)
        .onChange(onChange)
    }
    .layoutWeight(1)
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}
