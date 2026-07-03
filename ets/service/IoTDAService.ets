import { MqttAsync, MqttClient, MqttMessage } from '@ohos/mqtt';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import IoTDAConfig from './IoTDAConfig';
import { EnvironmentData } from '../models/EnvironmentData';
import { MoistureData } from '../models/MoistureData';
import { DeviceMonitorService } from './DeviceMonitorService';

// 对外UI回调类型
export type SensorDataCallback = (
  temp: number,
  humidity: number,
  co2: number,
  tvoc: number
) => void;

// IAM鉴权结构体
interface IamUser {
  name: string;
  password: string;
  domain: IamDomain;
}
interface IamDomain {
  name: string;
}
interface IamPassword {
  user: IamUser;
}
interface IamIdentity {
  methods: string[];
  password: IamPassword;
}
interface IamAuth {
  identity: IamIdentity;
}
interface IamRequestBody {
  auth: IamAuth;
}

// 下发命令结构体
interface CommandParas {
  SwitchVal: number;
}
interface CommandRequestBody {
  service_id: string;
  command_name: string;
  paras: CommandParas;
}

// IoTDA上报报文类型（匹配你的environment服务）
interface IoTDAEnvironmentProps {
  temperature: string | number;
  humidity: string | number;
  CO2: string | number;
  TVOC: string | number;
}
interface IoTDAServiceItem {
  service_id: string;
  properties: IoTDAEnvironmentProps;
}
interface IoTDANotifyBody {
  services: IoTDAServiceItem[];
}
interface IoTDANotifyData {
  body: IoTDANotifyBody;
}
interface IoTDAReportMsg {
  resource: string;
  event: string;
  notify_data: IoTDANotifyData;
}

export class IoTDAService {
  private static instance: IoTDAService;
  private mqttClient: MqttClient | null = null;
  private mqttConnected: boolean = false;
  private dataCallback: SensorDataCallback | null = null;

  private cachedToken: string = '';
  private tokenExpireTime: number = 0;
  private monitorService: DeviceMonitorService = DeviceMonitorService.getInstance();

  private constructor() {}

  static getInstance(): IoTDAService {
    if (!IoTDAService.instance) {
      IoTDAService.instance = new IoTDAService();
    }
    return IoTDAService.instance;
  }

  // 页面注册/注销数据监听
  registerDataCallback(cb: SensorDataCallback): void {
    this.dataCallback = cb;
  }
  unregisterDataCallback(): void {
    this.dataCallback = null;
  }

  // IAM获取Token（带缓存）
  private async getIamToken(): Promise<string> {
    if (this.cachedToken && Date.now() < this.tokenExpireTime) {
      return this.cachedToken;
    }
    return new Promise((resolve, reject) => {
      const req = http.createHttp();
      const body: IamRequestBody = {
        auth: {
          identity: {
            methods: ['password'],
            password: {
              user: {
                name: IoTDAConfig.IAM_USERNAME,
                password: IoTDAConfig.IAM_PASSWORD,
                domain: { name: IoTDAConfig.IAM_DOMAIN }
              }
            }
          }
        }
      };
      req.request('https://iam.myhuaweicloud.com/v3/auth/tokens', {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify(body)
      }, (err: BusinessError, res: http.HttpResponse) => {
        req.destroy();
        if (err || (res.responseCode !== 200 && res.responseCode !== 201)) {
          reject(new Error(`Token获取失败，响应码:${res.responseCode}`));
          return;
        }
        const token = (res.header['x-subject-token'] ?? res.header['X-Subject-Token']) as string;
        if (!token) return reject(new Error('响应头未拿到X-Subject-Token'));
        this.cachedToken = token;
        this.tokenExpireTime = Date.now() + 23 * 3600 * 1000;
        resolve(token);
      });
    });
  }

  // 通用下发控制命令
  private async sendCtrlCommand(serviceId: string, switchVal: number): Promise<void> {
    const token = await this.getIamToken();
    const url = `https://${IoTDAConfig.END_POINT}/v5/iot/${IoTDAConfig.PROJECT_ID}/devices/${IoTDAConfig.TARGET_DEVICE_ID}/commands`;
    const cmdBody: CommandRequestBody = {
      service_id: serviceId,
      command_name: 'Device_Switch_Ctrl',
      paras: { SwitchVal: switchVal }
    };
    return new Promise((resolve, reject) => {
      const req = http.createHttp();
      req.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token
        },
        extraData: JSON.stringify(cmdBody)
      }, (err: BusinessError, res: http.HttpResponse) => {
        req.destroy();
        if (err || res.responseCode !== 200) {
          reject(new Error(`命令下发失败，响应码:${res.responseCode}`));
          return;
        }
        resolve();
      });
    });
  }

  // 对外暴露控制接口
  async sendFanCtrl(on: number): Promise<void> {
    await this.sendCtrlCommand('ctrl_fan', on);
  }
  async sendDoorCtrl(open: number): Promise<void> {
    await this.sendCtrlCommand('ctrl_door', open);
  }
  async sendBuzzerCtrl(on: number): Promise<void> {
    await this.sendCtrlCommand('ctrl_buzzer', on);
  }

  // MQTT连接IoTDA订阅上报
  async connectToIoTDA(): Promise<void> {
    if (this.mqttConnected && this.mqttClient) return;
    try {
      const timestamp = Date.now().toString();
      const clientId = IoTDAConfig.ACCESS_KEY;
      const username = `accessKey=${IoTDAConfig.ACCESS_KEY}|timestamp=${timestamp}`;
      const password = IoTDAConfig.ACCESS_CODE;

      this.mqttClient = await MqttAsync.createMqttAsync({
        url: `ssl://${IoTDAConfig.MQTT_HOST}:${IoTDAConfig.MQTT_PORT}`,
        clientId: clientId,
        persistenceType: 1,
        MQTTVersion: 4
      });

      this.mqttClient.messageArrived((err: Error, msg: MqttMessage) => {
        if (err) {
          console.error('MQTT消息接收异常', err.message);
          return;
        }
        this.handleDeviceMsg(msg.payload);
      });

      await this.mqttClient.connect({
        userName: username,
        password: password,
        connectTimeout: 30,
        keepAliveInterval: 120,
        MQTTVersion: 4,
        sslOptions: { enableServerCertAuth: false }
      });
      this.mqttConnected = true;
      console.info('MQTT应用侧连接IoTDA成功');

      await this.mqttClient.subscribe({
        topic: IoTDAConfig.SUBSCRIBE_TOPIC,
        qos: 0
      });
      console.info('订阅设备上报Topic成功');
    } catch (e) {
      console.error('MQTT连接失败', JSON.stringify(e));
    }
  }

  // 解析设备上报报文
  private handleDeviceMsg(payload: string): void {
    try {
      const data = JSON.parse(payload) as IoTDAReportMsg;
      if (data.resource !== 'device.property' || data.event !== 'report') return;
      const envItem = data.notify_data.body.services.find(item => item.service_id === 'environment');
      if (!envItem) return;

      const props = envItem.properties;
      const temp = Number(props.temperature);
      const hum = Number(props.humidity);
      const co2 = Number(props.CO2);
      const tvoc = Number(props.TVOC);

      if (this.dataCallback) {
        this.dataCallback(temp, hum, co2, tvoc);
      }

      const envData = new EnvironmentData();
      envData.timestamp = Date.now();
      envData.temperature = temp;
      envData.humidity = hum;
      this.monitorService.processEnvironmentData(envData);
    } catch (e) {
      console.error('报文解析异常', e);
    }
  }

  // 全局销毁连接（APP退出调用，页面不要调用）
  disconnect(): void {
    if (this.mqttClient) {
      this.mqttClient.disconnect();
      this.mqttClient = null;
      this.mqttConnected = false;
    }
  }
}