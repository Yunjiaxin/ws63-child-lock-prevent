export default class IoTDAConfig {
  // ================= 设备侧信息 (用于识别被控设备，而非手机本身) =================
  // MQTT设备连接地址
  public static readonly MQTT_HOST: string = 'b2305098be.st1.iotda-device.cn-north-4.myhuaweicloud.com';
  public static readonly MQTT_PORT: number = 8883;

  // 目标设备的ID (用于拼接头 Topic)
  public static readonly TARGET_DEVICE_ID: string = '6a2918decbb0cf6bb9638b99_147852369';

  // (手机端不需要使用设备密钥去连MQTT，否则会冲突)
  public static readonly DEVICE_ID: string = '6a2918decbb0cf6bb9638b99_147852369';
  public static readonly DEVICE_SECRET: string = 'lsj1234567';

  // ================= 手机 App MQTT 连接配置 (重点修改部分) =================

  // 🔴 核心修改：给手机设置一个独立的 ClientID，绝对不要和设备一样！
  public static readonly APP_CLIENT_ID: string = 'Mobile_App_Controller_V1';

  // 完整服务URI
  public static readonly SERVER_URI: string = `ssl://${IoTDAConfig.MQTT_HOST}:${IoTDAConfig.MQTT_PORT}`;

  // 🔴 核心修改：使用应用侧密钥 (AccessKey) 进行鉴权
  // 这样手机是以“管理员”身份登录，而不是以“设备”身份登录，避免互相踢下线
  public static readonly APP_ACCESS_KEY: string = 'gZMFB2i3';
  public static readonly APP_ACCESS_CODE: string = 'Ghx1kewnATOfs7PA77BLjftXea3vv3nv';

  // ================= 业务 Topic 配置 =================

  // 服务ID
  public static readonly SERVICE_ID_ZHXY: string = 'environment';
  public static readonly SERVICE_ID_ENVIRONMENT: string = 'environment';

  // 🟢 订阅 Topic：接收设备上报的数据
  // 格式：$oc/devices/{设备ID}/sys/properties/report
  public static readonly SUBSCRIBE_TOPIC: string = `$oc/devices/${IoTDAConfig.TARGET_DEVICE_ID}/sys/properties/report`;

  // 🟢 发布 Topic：向设备下发命令
  // 格式：$oc/devices/{设备ID}/sys/commands/request/id={指令ID}
  public static readonly COMMAND_TOPIC_PREFIX: string = `$oc/devices/${IoTDAConfig.TARGET_DEVICE_ID}/sys/commands/request/id/`;

  // HTTP命令下发（保留备用）
  public static readonly END_POINT: string = 'iotda.cn-north-4.myhuaweicloud.com';
  public static readonly PROJECT_ID: string = '9791a4542e6841fb92b479b705fde193';

  // IAM账号（保留备用）
  public static readonly IAM_DOMAIN: string = 'hid_1qarjrh54by67ji';
  public static readonly IAM_USERNAME: string = '18646119819';
  public static readonly IAM_PASSWORD: string = '@Lsj15173404427';
}