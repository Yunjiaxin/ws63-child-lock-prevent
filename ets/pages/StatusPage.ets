import { AppDimens, TEXT_TITLE_SIZE, TEXT_TITLE_WEIGHT, TEXT_BODY_SIZE } from '../common/Styles';
import { ThemeMode, getThemeColors } from '../common/Theme';
import { addHistoryRecord, addSensorDataPoint, SensorType } from '../common/HistoryData';
import { IoTDAService, SensorDataCallback } from '../service/IoTDAService';

@Component
export default struct StatusPage {
  @StorageLink('themeMode') themeMode: string = ThemeMode.GREEN_WHITE;

  @State isFanOn: boolean = false;
  @State isDoorOpen: boolean = false;
  @State isBuzzerOn: boolean = false;
  @State co2: number = 420;
  @State hcho: number = 0.08;
  @State temperature: number = 24.5;
  @State humidity: number = 55;
  @State location: string = '东经118.78°, 北纬32.04°';
  @State isVehicleMoving: boolean = false;
  @State isSeatOccupied: boolean = true;

  private iot = IoTDAService.getInstance();

  aboutToAppear(): void {
    const cb: SensorDataCallback = (temp, hum, co2Val, tvocVal) => {
      this.temperature = temp;
      this.humidity = hum;
      this.co2 = co2Val;
      this.hcho = tvocVal / 100;
      addSensorDataPoint(SensorType.TEMPERATURE, temp);
      addHistoryRecord(`实时更新：温度${temp}℃，湿度${hum}%`);
    };
    this.iot.registerDataCallback(cb);
    this.iot.connectToIoTDA();
  }

  aboutToDisappear(): void {
    this.iot.unregisterDataCallback();
  }

  private async toggleFan() {
    const val = this.isFanOn ? 0 : 1;
    try {
      await this.iot.sendFanCtrl(val);
      this.isFanOn = !this.isFanOn;
      addHistoryRecord(`风扇${this.isFanOn ? '开启成功' : '关闭成功'}`);
    } catch (err) {
      addHistoryRecord(`风扇控制失败：${String(err)}`);
    }
  }

  private async toggleDoor() {
    const val = this.isDoorOpen ? 0 : 1;
    try {
      await this.iot.sendDoorCtrl(val);
      this.isDoorOpen = !this.isDoorOpen;
      addHistoryRecord(`车门${this.isDoorOpen ? '打开成功' : '关闭成功'}`);
    } catch (err) {
      addHistoryRecord(`车门控制失败：${String(err)}`);
    }
  }

  private async toggleBuzzer() {
    const val = this.isBuzzerOn ? 0 : 1;
    try {
      await this.iot.sendBuzzerCtrl(val);
      this.isBuzzerOn = !this.isBuzzerOn;
      addHistoryRecord(`蜂鸣器${this.isBuzzerOn ? '开启鸣响' : '关闭静默'}`);
    } catch (err) {
      addHistoryRecord(`蜂鸣器控制失败：${String(err)}`);
    }
  }

  build() {
    Scroll() {
      Column({ space: AppDimens.MARGIN_MEDIUM }) {
        this.CO2Card()
        this.TempHumidCard()
        this.LocationCard()
        this.VehicleCard()
        this.SeatCard()
        this.DeviceControlCard()
      }
      .padding(AppDimens.PADDING_LARGE)
      .width('100%')
    }
    .backgroundColor(this.getColors().background)
  }

  // ========== 下方所有UI Builder 一行未改动 ==========
  @Builder
  private CO2Card(): void {
    Column() {
      Row() {
        Text('CO₂ / 甲醛')
          .fontSize(TEXT_TITLE_SIZE)
          .fontWeight(TEXT_TITLE_WEIGHT)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Button('模拟变化')
          .height(32)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => {
            this.co2 = Math.floor(300 + Math.random() * 300);
            this.hcho = parseFloat((0.02 + Math.random() * 0.2).toFixed(2));
          })
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`${this.co2} ppm  /  ${this.hcho} mg/m³`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
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
      Row() {
        Text('温湿度')
          .fontSize(TEXT_TITLE_SIZE)
          .fontWeight(TEXT_TITLE_WEIGHT)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Button('模拟变化')
          .height(32)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => {
            this.temperature = parseFloat((20 + Math.random() * 10).toFixed(1));
            this.humidity = Math.floor(30 + Math.random() * 50);
          })
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`${this.temperature} °C  /  ${this.humidity} %`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private LocationCard(): void {
    Column() {
      Row() {
        Text('定位')
          .fontSize(TEXT_TITLE_SIZE)
          .fontWeight(TEXT_TITLE_WEIGHT)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Button('模拟变化')
          .height(32)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => {
            const lng: number = 118 + Math.random() * 2;
            const lat: number = 32 + Math.random() * 1;
            this.location = `东经${lng.toFixed(2)}°, 北纬${lat.toFixed(2)}°`;
          })
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(this.location)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private VehicleCard(): void {
    Column() {
      Row() {
        Text('重力 & ADXL345')
          .fontSize(TEXT_TITLE_SIZE)
          .fontWeight(TEXT_TITLE_WEIGHT)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Button('模拟变化')
          .height(32)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => {
            this.isVehicleMoving = !this.isVehicleMoving;
          })
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`车辆行驶中: ${this.isVehicleMoving ? '是' : '否'}`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private SeatCard(): void {
    Column() {
      Row() {
        Text('人体红外')
          .fontSize(TEXT_TITLE_SIZE)
          .fontWeight(TEXT_TITLE_WEIGHT)
          .fontColor(this.getColors().textPrimary)
          .layoutWeight(1)
        Button('模拟变化')
          .height(32)
          .backgroundColor(this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => {
            this.isSeatOccupied = !this.isSeatOccupied;
          })
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_SMALL })
      Text(`座位上有人: ${this.isSeatOccupied ? '是' : '否'}`)
        .fontSize(TEXT_BODY_SIZE)
        .fontColor(this.getColors().textSecondary)
        .width('100%')
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  @Builder
  private DeviceControlCard(): void {
    Column() {
      Text('设备控制')
        .fontSize(TEXT_TITLE_SIZE)
        .fontWeight(TEXT_TITLE_WEIGHT)
        .fontColor(this.getColors().textPrimary)
        .width('100%')
        .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Row() {
        Text(`风扇状态：${this.isFanOn ? '开启' : '关闭'}`)
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.isFanOn ? this.getColors().primary : this.getColors().textSecondary)
          .layoutWeight(1)
        Button(this.isFanOn ? '关闭' : '开启')
          .height(AppDimens.BUTTON_HEIGHT)
          .backgroundColor(this.isFanOn ? this.getColors().textSecondary : this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => this.toggleFan())
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Row() {
        Text(`车门状态：${this.isDoorOpen ? '打开' : '关闭'}`)
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.isDoorOpen ? this.getColors().primary : this.getColors().textSecondary)
          .layoutWeight(1)
        Button(this.isDoorOpen ? '关闭' : '打开')
          .height(AppDimens.BUTTON_HEIGHT)
          .backgroundColor(this.isDoorOpen ? this.getColors().textSecondary : this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => this.toggleDoor())
      }
      .width('100%')
      .margin({ bottom: AppDimens.MARGIN_MEDIUM })

      Row() {
        Text(`蜂鸣器状态：${this.isBuzzerOn ? '鸣响' : '静默'}`)
          .fontSize(TEXT_BODY_SIZE)
          .fontColor(this.isBuzzerOn ? this.getColors().primary : this.getColors().textSecondary)
          .layoutWeight(1)
        Button(this.isBuzzerOn ? '关闭' : '开启')
          .height(AppDimens.BUTTON_HEIGHT)
          .backgroundColor(this.isBuzzerOn ? this.getColors().textSecondary : this.getColors().primary)
          .fontColor(this.getColors().cardBg)
          .borderRadius(AppDimens.CORNER_RADIUS)
          .onClick(() => this.toggleBuzzer())
      }
      .width('100%')
    }
    .padding(AppDimens.PADDING_MEDIUM)
    .backgroundColor(this.getColors().cardBg)
    .borderRadius(AppDimens.CORNER_RADIUS)
    .shadow({ radius: 4, color: this.getColors().shadow, offsetY: 2 })
    .width('100%')
  }

  private getColors() {
    return getThemeColors(this.themeMode as ThemeMode);
  }
}