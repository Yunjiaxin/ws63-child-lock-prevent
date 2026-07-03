import {
  IoTDevice,
  IoTMqttResponse,
  ShadowRequest,
  ShadowData,
  ServiceProperty,
  CommandListener,
  CommandRsp
} from 'backend';
import IoTDAConfig from './IoTDAConfig';
import { EnvironmentData } from '../models/EnvironmentData';
import { MoistureData } from '../models/MoistureData';
import { DeviceMonitorService } from './DeviceMonitorService';
import { LogUtil } from '../pages/utils/LogUtil';

const TAG: string = "IoTDAService#";

// 对外UI回调类型：温度、湿度、CO2、甲醛、人体、风扇/车门状态
// 属性值均为设备上报的原始字符串，UI 层自行解析显示
export type SensorDataCallback = (
  temp: string,
  humidity: string,
  co2: string,
  hcho: string,
  motion: string,
  fanState: string,
  doorState: string
) => void;

// 连接状态回调
export type ConnectionCallback = (connected: boolean, message: string) => void;

// 设备控制命令回调：UI 注册此回调以接收平台下发的命令并更新界面
export type DeviceCommandCallback = (target: string, status: number) => void;

export class IoTDAService {
  private static instance: IoTDAService;
  private device: IoTDevice | null = null;
  private connected: boolean = false;
  private dataCallback: SensorDataCallback | null = null;
  private connectionCallback: ConnectionCallback | null = null;
  private commandCallback: DeviceCommandCallback | null = null;
  private monitorService: DeviceMonitorService = DeviceMonitorService.getInstance();

  // 当前设备控制状态缓存（平台返回字符串类型）
  private fanState: string = '1';   // 风扇: "0"=开启, "1"=关闭
  private doorState: string = '90'; // SG90舵机: "0"=开门, "90"=关门

  private constructor() {}

  static getInstance(): IoTDAService {
    if (!IoTDAService.instance) {
      IoTDAService.instance = new IoTDAService();
    }
    return IoTDAService.instance;
  }

  // ====== 获取当前设备状态 ======
  getFanState(): string { return this.fanState; }
  getDoorState(): string { return this.doorState; }

  // ====== 回调注册 ======
  registerDataCallback(cb: SensorDataCallback): void {
    this.dataCallback = cb;
  }

  unregisterDataCallback(): void {
    this.dataCallback = null;
  }

  registerConnectionCallback(cb: ConnectionCallback): void {
    this.connectionCallback = cb;
  }

  /**
   * 注册设备控制命令回调。
   * UI 页面注册此回调后，当平台下发车门/风扇控制命令时，
   * 自动通知 UI 更新显示状态。
   */
  registerCommandCallback(cb: DeviceCommandCallback): void {
    this.commandCallback = cb;
  }

  unregisterCommandCallback(): void {
    this.commandCallback = null;
  }

  // ====== 连接华为云IoTDA（使用IoTDevice设备侧SDK） ======
  async connect(): Promise<boolean> {
    if (this.connected && this.device) {
      LogUtil.info(TAG, 'already connected');
      return true;
    }

    try {
      LogUtil.info(TAG,
        `connecting to ${IoTDAConfig.SERVER_URI} deviceId=${IoTDAConfig.DEVICE_ID}`);
      this.device = new IoTDevice(
        IoTDAConfig.SERVER_URI,
        IoTDAConfig.DEVICE_ID,
        IoTDAConfig.DEVICE_SECRET,
        'GlobalSign-rootca.pem'
      );

      const result: boolean = await this.device.init();
      LogUtil.info(TAG, `init result: ${result}`);

      const isConnected: boolean = await this.device.client.isConnected();
      if (isConnected) {
        this.connected = true;
        LogUtil.info(TAG, 'MQTT connected to IoTDA successfully');

        // ====== 设置命令监听器：接收平台下发的设备控制命令 ======
        this.device.client.commandListener = {
          onCommand: (requestId: string, serviceId: string, commandName: string, paras: object): void => {
            LogUtil.info(TAG,
              `onCommand: requestId=${requestId}, serviceId=${serviceId}, commandName=${commandName}, paras=${JSON.stringify(paras)}`);
            this.handleDeviceCommand(requestId, serviceId, commandName, paras);
          }
        };

        // 设置影子监听器——接收平台推送的设备数据
        this.device.client.shadowListener = {
          onShadow: (requestId: string, list?: ShadowData[]): void => {
            LogUtil.info(TAG,
              `onShadow triggered, requestId=${requestId}, listLen=${list?.length ?? 0}`);
            if (list && list.length > 0) {
              this.handleShadowData(list);
            }
          }
        };

        // 立即拉取一次影子数据
        await this.fetchShadow();

        if (this.connectionCallback) {
          this.connectionCallback(true, '连接成功');
        }
        return true;
      } else {
        LogUtil.error(TAG, 'device connected but isConnected() returned false');
        if (this.connectionCallback) {
          this.connectionCallback(false, '设备未连接');
        }
        return false;
      }
    } catch (err) {
      LogUtil.error(TAG, `connect failed: ${JSON.stringify(err)}`);
      if (this.connectionCallback) {
        this.connectionCallback(false, `连接失败: ${JSON.stringify(err)}`);
      }
      return false;
    }
  }

  // ====== 核心：从平台拉取影子数据 ======
  private async fetchShadow(): Promise<void> {
    if (!this.device?.client) {
      LogUtil.error(TAG, 'fetchShadow: no client');
      return;
    }

    // 拉取 zhxy 服务影子
    const zhxyReq: ShadowRequest = {
      object_device_id: IoTDAConfig.DEVICE_ID,
      service_id: IoTDAConfig.SERVICE_ID_ZHXY
    };
    LogUtil.info(TAG, `getShadow zhxy: ${JSON.stringify(zhxyReq)}`);
    this.device.client.getShadow(zhxyReq)
      .then((_res: IoTMqttResponse): void => {
        LogUtil.info(TAG, 'getShadow zhxy publish OK');
      })
      .catch((err: IoTMqttResponse | string): void => {
        LogUtil.error(TAG, `getShadow zhxy FAILED: ${JSON.stringify(err)}`);
      });

    // 拉取 environment 服务影子
    const envReq: ShadowRequest = {
      object_device_id: IoTDAConfig.DEVICE_ID,
      service_id: IoTDAConfig.SERVICE_ID_ENVIRONMENT
    };
    LogUtil.info(TAG, `getShadow environment: ${JSON.stringify(envReq)}`);
    this.device.client.getShadow(envReq)
      .then((_res: IoTMqttResponse): void => {
        LogUtil.info(TAG, 'getShadow environment publish OK');
      })
      .catch((err: IoTMqttResponse | string): void => {
        LogUtil.info(TAG,
          `getShadow environment FAILED (may not exist): ${JSON.stringify(err)}`);
      });
  }

  // 手动刷新数据（供UI调用）
  async refreshData(): Promise<void> {
    await this.fetchShadow();
  }

  // ====== 解析影子数据（同时支持 zhxy 和 environment 服务） ======
  private handleShadowData(list: ShadowData[]): void {
    LogUtil.info(TAG, `handleShadowData: received ${list.length} services`);
    let temp: string = '';
    let humidity: string = '';
    let co2: string = '';
    let hcho: string = '';
    let motion: string = '';

    let fanState: string = '';
    let doorState: string = '';

    for (let i = 0; i < list.length; i++) {
      const sd: ShadowData = list[i];
      LogUtil.info(TAG,
        `  service_id=${sd.service_id}, has_reported=${!!sd.reported}, has_desired=${!!sd.desired}`);

      // 取 reported 或 desired 的 properties
      let sourceProps: object | undefined = undefined;
      if (sd.reported && sd.reported.properties) {
        sourceProps = sd.reported.properties;
      } else if (sd.desired && sd.desired.properties) {
        sourceProps = sd.desired.properties;
      } else {
        continue;
      }

      const props: Record<string, Object> = sourceProps as Record<string, Object>;
      LogUtil.info(TAG, `  property keys: [${Object.keys(props)}], raw values: ${JSON.stringify(props)}`);

      // 风扇 FAN：设备上报的是字符串 "0"/"1"
      const fanRaw: Object | undefined = props['FAN'];
      if (fanRaw !== undefined) {
        fanState = String(fanRaw);
      }
      // SG90 舵机：设备上报的是字符串 "0"/"90"
      const sg90Raw: Object | undefined = props['SG90'];
      if (sg90Raw !== undefined) {
        doorState = String(sg90Raw);
      }
      // === temperature：直接取原始字符串 ===
      const tempRaw: Object | undefined = props['temperature'];
      if (tempRaw !== undefined) {
        temp = String(tempRaw);
      }
      // === humidity ===
      const humidRaw: Object | undefined = props['humidity'];
      if (humidRaw !== undefined) {
        humidity = String(humidRaw);
      }
      // === CO2 ===
      const co2Raw: Object | undefined = props['CO2'];
      if (co2Raw !== undefined) {
        co2 = String(co2Raw);
      }
      // === TVOC（字符串）→ 直接透传 ===
      const tvocRaw: Object | undefined = props['TVOC'];
      if (tvocRaw !== undefined) {
        hcho = String(tvocRaw);
      }
      // === motion：设备上报字符串 "0"/"1" ===
      const motionRaw: Object | undefined = props['motion'];
      if (motionRaw !== undefined) {
        motion = String(motionRaw);
      }
    }

    // 只要至少有一个属性被解析到就回调
    const hasAny: boolean = temp !== '' || humidity !== '' || co2 !== '' || hcho !== '' || motion !== ''
      || fanState !== '' || doorState !== '';

    if (hasAny && this.dataCallback) {
      LogUtil.info(TAG,
        `callback: temp=${temp}, hum=${humidity}, co2=${co2}, hcho=${hcho}, motion=${motion}, fan=${fanState}, door=${doorState}`);
      this.dataCallback(temp, humidity, co2, hcho, motion, fanState, doorState);

      // 通知监控服务（需要 number）
      const envData = new EnvironmentData();
      envData.timestamp = Date.now();
      envData.temperature = Number(temp);
      envData.humidity = Number(humidity);
      this.monitorService.processEnvironmentData(envData);
    }
  }

  // ====== 处理平台下发的设备控制命令 ======
  private handleDeviceCommand(requestId: string, serviceId: string, commandName: string, paras: object): void {
    const parasObj = paras as Record<string, Object>;
    const target: string = (parasObj['target'] as string) ?? '';
    const status: number = Number(parasObj['status'] ?? -1);

    LogUtil.info(TAG, `handleDeviceCommand: target=${target}, status=${status}, commandName=${commandName}`);

    // 根据命令更新本地状态缓存
    if (target === 'fan' && status >= 0) {
      this.fanState = String(status);
    }

    // 通知 UI 更新界面状态
    if (this.commandCallback && target !== '') {
      this.commandCallback(target, status);
    }

    // 响应平台：命令执行成功
    const rsp: CommandRsp = {
      result_code: 0,
      response_name: commandName,
      paras: {
        target: target,
        status: status,
        message: '命令执行成功'
      }
    };
    this.device?.client.respondCommand(requestId, rsp)
      .then(() => {
        LogUtil.info(TAG, `respondCommand success for ${target}`);
      })
      .catch((err: Object) => {
        LogUtil.error(TAG, `respondCommand failed: ${JSON.stringify(err)}`);
      });
  }

  // ====== 风扇控制：通过 FAN 属性直接上报到 zhxy 服务 ======
  // 风扇: "0"=开启, "1"=关闭
  async sendFanCtrl(val: string): Promise<void> {
    if (!this.device?.client) {
      throw new Error('设备未连接');
    }
    if (!await this.device.client.isConnected()) {
      throw new Error('MQTT未连接');
    }

    const props: ServiceProperty[] = [{
      service_id: IoTDAConfig.SERVICE_ID_ZHXY,
      properties: {
        FAN: val
      }
    }];

    LogUtil.info(TAG, `reportProperties FAN: ${JSON.stringify(props)}`);
    await this.device.client.reportProperties(props);

    // 更新本地缓存
    this.fanState = val;
  }

  // ====== 车门控制：通过 SG90 属性直接上报到 zhxy 服务 ======
  // SG90 舵机："0"=开门，"90"=关门
  async sendDoorCtrl(val: string): Promise<void> {
    if (!this.device?.client) {
      throw new Error('设备未连接');
    }
    if (!await this.device.client.isConnected()) {
      throw new Error('MQTT未连接');
    }

    const props: ServiceProperty[] = [{
      service_id: IoTDAConfig.SERVICE_ID_ZHXY,
      properties: {
        SG90: val
      }
    }];

    LogUtil.info(TAG, `reportProperties SG90(door): ${JSON.stringify(props)}`);
    await this.device.client.reportProperties(props);

    // 更新本地缓存
    this.doorState = val;
  }


  // ====== 上报环境数据到平台（environment 服务） ======
  async reportEnvironmentData(
    temperature: number, humidity: number, co2: number, tvoc: number
  ): Promise<void> {
    if (!this.device?.client) {
      throw new Error('设备未连接');
    }
    if (!await this.device.client.isConnected()) {
      throw new Error('MQTT未连接');
    }

    const props: ServiceProperty[] = [{
      service_id: IoTDAConfig.SERVICE_ID_ENVIRONMENT,
      properties: {
        temperature: temperature,
        humidity: humidity,
        CO2: co2,
        TVOC: tvoc
      }
    }];

    LogUtil.info(TAG, `reportEnvironmentData: ${JSON.stringify(props)}`);
    await this.device.client.reportProperties(props);
  }

  // ====== 上报 zhxy 服务数据到平台（含 SG90 车门状态） ======
  async reportZhxyData(
    temperature: number, humidity: number, motion: number
  ): Promise<void> {
    if (!this.device?.client) {
      throw new Error('设备未连接');
    }
    if (!await this.device.client.isConnected()) {
      throw new Error('MQTT未连接');
    }

    const props: ServiceProperty[] = [{
      service_id: IoTDAConfig.SERVICE_ID_ZHXY,
      properties: {
        temperature: temperature,
        humidity: humidity,
        motion: motion,
        FAN: this.fanState,     // 风扇状态：0=开启, 1=关闭
        SG90: this.doorState    // 车门舵机状态：0=开门, 90=关门
      }
    }];

    LogUtil.info(TAG, `reportZhxyData: ${JSON.stringify(props)}`);
    await this.device.client.reportProperties(props);
  }

  // ====== 断连 ======
  disconnect(): void {
    if (this.device?.client) {
      this.device.client.disconnect();
      this.device = null;
      this.connected = false;
      LogUtil.info(TAG, 'disconnected');
    }
  }

  get isConnected(): boolean {
    return this.connected;
  }
}
