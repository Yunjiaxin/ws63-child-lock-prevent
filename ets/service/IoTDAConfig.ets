export default class IoTDAConfig {
  // 应用侧MQTT订阅（接收设备上报）
  public static readonly MQTT_HOST: string = 'b2305098be.st1.iotda-device.cn-north-4.myhuaweicloud.com';
  public static readonly MQTT_PORT: number = 8883;
  public static readonly ACCESS_KEY: string = 'gZMFB2i3';    // 填入你的应用AK
  public static readonly ACCESS_CODE: string = 'Ghx1kewnATOfs7PA77BLjftXea3vv3nv';   // 填入你的应用SK
  public static readonly SUBSCRIBE_TOPIC: string = '$oc/subscribe/#';

  // HTTP命令下发地址
  public static readonly END_POINT: string = 'iotda.cn-north-4.myhuaweicloud.com';
  public static readonly PROJECT_ID: string = '9791a4542e6841fb92b479b705fde193';    // 项目ID
  public static readonly TARGET_DEVICE_ID: string = '6a2918decbb0cf6bb9638b99_147852369'; // test1完整设备ID

  // IAM账号鉴权信息
  public static readonly IAM_DOMAIN: string = 'hid_1qarjrh54by67ji';
  public static readonly IAM_USERNAME: string = '18646119819';
  public static readonly IAM_PASSWORD: string = '@Lsj15173404427';

  // 虚拟设备TCP连接（本项目不用，留空）
  public static readonly DEVICE_HOST: string = '';
  public static readonly DEVICE_PORT: number = 1883;
  public static readonly DEVICE_ID: string = '';
  public static readonly DEVICE_SECRET: string = '';
}