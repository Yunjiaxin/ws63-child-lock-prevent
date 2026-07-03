# WS63 儿童误锁预防系统 - 应用侧

## 项目简介

本项目是一个基于 **HarmonyOS (OpenHarmony)** 的智能汽车**儿童安全守护应用**，旨在防止儿童被误锁在车内。应用通过**华为云 IoTDA（物联网设备接入）平台**与车载 WS63 硬件设备进行 MQTT 通信，实时监控车内环境数据（温度、湿度、CO₂、甲醛、人体红外感应），并支持远程控制车内风扇和车门舵机（SG90）。

- **Bundle 名称**: `com.huaweicloud.iot.device`
- **版本**: 0.0.1
- **目标 SDK**: 5.0.0(12) ~ 6.1.0(23)
- **许可证**: Apache License 2.0
- **技术栈**: HarmonyOS ArkTS + 华为云 IoTDA MQTT SDK

---

## 项目结构

```
ws63-child-lock-prevent/
├── AppScope/                          # 应用全局配置
│   └── app.json5                      # bundleName、版本号、图标等
│
├── entry/                             # 主应用模块（HAP）
│   └── src/main/ets/
│       ├── common/                    # 公共工具模块
│       │   ├── HistoryData.ets        # 历史数据管理（记录、传感器数据点）
│       │   ├── Styles.ets             # 尺寸、样式常量定义
│       │   └── Theme.ets              # 主题系统（绿白/黑蓝双主题）
│       │
│       ├── entryability/              # 应用入口
│       │   └── EntryAbility.ets       # UIAbility 入口，加载启动页
│       │
│       ├── models/                    # 数据模型
│       │   ├── EnvironmentData.ets    # 环境数据模型（温度、湿度）
│       │   └── MoistureData.ets       # 湿度数据模型
│       │
│       ├── pages/                     # 页面模块
│       │   ├── utils/
│       │   │   └── LogUtil.ets        # 日志工具类
│       │   ├── SplashPage.ets         # 启动页（双门开启动画）
│       │   ├── Index.ets              # 主页（Tab 导航容器）
│       │   ├── StatusPage.ets         # 状态页（传感器监控 + 设备控制 + 数据上报）
│       │   ├── DataPage.ets           # 数据页（柱状图/折线图 + 历史记录）
│       │   ├── VideoPage.ets          # 监控页（WebView 车内摄像头实时画面）
│       │   ├── InfoPage.ets           # 信息页（聊天/消息功能）
│       │   └── ProfilePage.ets        # 个人页（主题切换、关于我们）
│       │
│       └── service/                   # 服务层
│           ├── IoTDAConfig.ets        # IoTDA 平台连接配置（设备ID、密钥、Topic）
│           ├── IoTDAService.ets       # IoTDA 核心服务（MQTT连接、影子数据、命令下发）
│           └── DeviceMonitorService.ets # 设备监控服务（数据处理扩展）
│
├── Backend/                           # 华为云 IoT 设备 SDK（HAR 库）
│   ├── index.ets                      # SDK 导出入口
│   └── src/main/ets/
│       ├── client/
│       │   └── DeviceClient.ets       # MQTT 客户端核心（连接、订阅、发布、命令响应）
│       ├── service/                   # 抽象设备服务
│       ├── listener/                  # 各类监听器接口
│       ├── handler/                   # Topic 消息处理器
│       ├── requests/                  # 请求/响应数据模型
│       └── utils/                     # 工具类
│
├── ets/                               # 备用应用代码（简化版，结构同上）
├── build-profile.json5                # 根构建配置（含签名配置）
├── oh-package.json5                   # 根包配置
└── hvigorfile.ts                      # 根 Hvigor 构建入口
```

---

## 核心功能

### 1. 启动动画 (`SplashPage.ets`)

应用启动时展示品牌标志 "SAFE 安全守护"，随后通过双门打开动画过渡到主界面，增强用户体验。

### 2. 五 Tab 主界面 (`Index.ets`)

| Tab | 页面 | 功能描述 |
|-----|------|----------|
| 状态 | `StatusPage` | 传感器数据实时监控、设备控制、数据上报 |
| 数据 | `DataPage` | 传感器数据趋势图表（柱状图 + 折线图）、历史事件记录 |
| 监控 | `VideoPage` | WebView 加载车内摄像头实时画面，AI 分析告警 |
| 信息 | `InfoPage` | 聊天消息功能，类似即时通讯界面 |
| 我的 | `ProfilePage` | 主题切换（绿白/黑蓝）、版本信息 |

### 3. 传感器实时监控 (`StatusPage.ets`)

监控以下传感器数据（均来自华为云 IoTDA 平台推送）：

| 传感器 | 属性名 | 说明 |
|--------|--------|------|
| 温度 | `temperature` | 车内温度（°C） |
| 湿度 | `humidity` | 车内湿度（%） |
| CO₂ | `CO2` | 二氧化碳浓度（ppm） |
| 甲醛/TVOC | `TVOC` | 空气质量指标（mg/m³） |
| 人体红外 | `motion` | 人体感应（"0"=无人, "1"=有人） |

支持**列表视图**和**仪表盘视图**两种展示模式。

### 4. 设备远程控制 (`StatusPage.ets`)

通过 MQTT 属性上报方式远程控制车载硬件：

| 设备 | 属性名 | 控制逻辑 |
|------|--------|----------|
| 风扇 | `FAN` | "0"=开启, "1"=关闭 |
| 车门舵机 (SG90) | `SG90` | "0"=开门, "90"=关门 |

控制流程：
1. 用户点击按钮 → 调用 `IoTDAService.sendFanCtrl()` / `sendDoorCtrl()`
2. 通过 MQTT `reportProperties` 上报属性到 IoTDA 平台
3. WS63 设备接收平台下发的属性变更通知并执行相应动作

### 5. 数据可视化 (`DataPage.ets`)

- **柱状图**：展示最近 N 条传感器数据，支持切换 CO₂/温度/湿度/甲醛四种类型
- **折线图**：使用纯 ArkUI 组件实现的折线趋势图，含 Y 轴刻度和 X 轴序号
- **历史事件记录**：按时间倒序展示所有操作记录（风扇控制、车门控制、数据上报等）

### 6. 视频监控 (`VideoPage.ets`)

- 通过 WebView 加载车内摄像头实时视频流（地址: `http://192.168.203.184:5000/`）
- 支持 WebView `onAlert` 事件触发系统通知，用于 AI 异常检测告警
- 显示 "前置摄像头：车内后视镜处" 标签

### 7. 主题系统 (`Theme.ets`)

支持两套主题配色，全局响应式切换：

| 主题 | 主色调 | 背景 | 卡片 | 适用场景 |
|------|--------|------|------|----------|
| 绿白 | `#4CAF50` 绿色 | `#F5F5F5` 浅灰 | `#FFFFFF` 白色 | 日间/默认 |
| 黑蓝 | `#2196F3` 蓝色 | `#121212` 深色 | `#1E1E2E` 深灰 | 夜间/深色模式 |

---

## IoTDA 平台通信架构

### MQTT 连接配置 (`IoTDAConfig.ets`)

```typescript
MQTT_HOST:    b2305098be.st1.iotda-device.cn-north-4.myhuaweicloud.com
MQTT_PORT:    8883 (SSL)
SERVER_URI:   ssl://{MQTT_HOST}:{MQTT_PORT}
DEVICE_ID:    6a2918decbb0cf6bb9638b99_147852369
DEVICE_SECRET: lsj1234567
```

### 通信流程

```
┌─────────────┐     MQTT/SSL      ┌──────────────┐     串口/WiFi    ┌──────────┐
│  手机 App    │ ◄──────────────► │ 华为云 IoTDA  │ ◄─────────────► │ WS63 设备 │
│ (HarmonyOS)  │                   │    平台       │                  │ (硬件端)  │
└─────────────┘                   └──────────────┘                  └──────────┘
      │                                  │                               │
      │  1. connect()                    │                               │
      │─────────────────────────────────►│                               │
      │  2. getShadow(zhxy/environment)  │                               │
      │─────────────────────────────────►│                               │
      │  3. onShadow 回调 (传感器数据)    │                               │
      │◄─────────────────────────────────│                               │
      │                                  │  4. reportProperties(FAN/SG90) │
      │─────────────────────────────────►│──────────────────────────────►│
      │                                  │  5. 设备上报传感器数据          │
      │                                  │◄──────────────────────────────│
      │  6. onShadow 回调 (更新UI)       │                               │
      │◄─────────────────────────────────│                               │
```

### 核心服务 (`IoTDAService.ets`)

采用**单例模式**，提供：

- **MQTT 连接管理**：`connect()` / `disconnect()` / `isConnected`
- **影子数据获取**：`fetchShadow()` / `refreshData()`
- **设备控制**：`sendFanCtrl(val)` / `sendDoorCtrl(val)`
- **数据上报**：`reportEnvironmentData()` / `reportZhxyData()`
- **命令监听**：接收平台下发的设备控制命令并响应
- **回调机制**：
  - `SensorDataCallback` - 传感器数据更新回调
  - `ConnectionCallback` - 连接状态变化回调
  - `DeviceCommandCallback` - 设备命令下发回调

### 平台服务 ID

| 服务 ID | 用途 | 属性 |
|---------|------|------|
| `environment` | 环境数据服务 | temperature, humidity, CO2, TVOC |
| `environment`（复用） | 设备控制服务 | FAN, SG90, motion |

---

## Backend SDK 模块

`Backend/` 是一个 **HAR（HarmonyOS Archive）库**，封装了华为云 IoTDA 设备侧 SDK 的核心功能：

- **`DeviceClient.ets`**：MQTT 客户端核心实现
  - MQTT 连接/重连/断开管理
  - HMAC-SHA256 密码鉴权
  - 系统 Topic 自动订阅（消息下发、命令下发、属性设置/获取、影子响应、事件下发）
  - 属性上报 `reportProperties()`
  - 消息上报 `reportDeviceMessage()`
  - 事件上报 `reportEvent()`
  - 命令响应 `respondCommand()`
  - 影子获取 `getShadow()`
  - 自定义 Topic 订阅 `subscribeTopic()`
  - 指数退避自动重连机制
- **监听器接口**：`CommandListener`、`PropertyListener`、`ShadowListener`、`RawMessageListener`、`ConnectListener`
- **消息处理器**：`CommandHandler`、`PropertySetHandler`、`PropertyGetHandler`、`ShadowHandler` 等

---

## 数据模型

### EnvironmentData (`models/EnvironmentData.ets`)
```typescript
{
  timestamp: number;    // 时间戳
  temperature: number;  // 温度
  humidity: number;     // 湿度
}
```

### MoistureData (`models/MoistureData.ets`)
```typescript
{
  timestamp: number;     // 时间戳
  moisture_level: number; // 湿度等级
  duration: number;      // 持续时长
}
```

### HistoryRecord (`common/HistoryData.ets`)
```typescript
{
  id: number;           // 唯一标识
  timestamp: string;    // 格式化时间字符串
  description: string;  // 事件描述
}
```

### SensorDataPoint (`common/HistoryData.ets`)
```typescript
{
  id: number;           // 唯一标识
  timestamp: number;    // Unix 时间戳
  type: SensorType;     // 传感器类型（CO2/HCHO/TEMPERATURE/HUMIDITY）
  value: number;        // 传感器数值
}
```

---

## 构建与运行

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK API 12+
- Node.js 18+
- 华为云 IoTDA 平台账号及已注册设备

### 构建步骤

```bash
# 1. 安装依赖
cd ws63-child-lock-prevent
ohpm install

# 2. 配置签名（在 DevEco Studio 中）
# File → Project Structure → Signing Configs → 自动生成或导入签名文件

# 3. 修改 IoTDA 配置
# 编辑 entry/src/main/ets/service/IoTDAConfig.ets
# 填入实际的设备ID、密钥、MQTT地址等信息

# 4. 构建 HAP
hvigorw assembleHap

# 5. 安装到设备
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

### 注意事项

- **签名配置**：需要在 `build-profile.json5` 中配置正确的 `.p12` 签名文件路径
- **MQTT 连接**：需要确保手机能访问华为云 IoTDA 的 MQTT 服务端口（8883）
- **视频监控**：`VideoPage` 中的摄像头地址 `http://192.168.203.184:5000/` 需根据实际局域网环境修改
- **设备 ID**：`IoTDAConfig.ets` 中的 `DEVICE_ID` 和 `DEVICE_SECRET` 需要替换为实际在 IoTDA 平台注册的设备信息
- **证书文件**：需要将 `GlobalSign-rootca.pem` 放入 `entry/src/main/resources/rawfile/` 目录

---

## 技术亮点

1. **纯 ArkTS 图表实现**：DataPage 中的柱状图和折线图使用原生 ArkUI 组件（`Row`/`Column`/`Circle`/`Divider`）实现，无需第三方图表库
2. **单例服务架构**：`IoTDAService` 和 `DeviceMonitorService` 均采用单例模式，全局共享连接状态
3. **响应式主题系统**：通过 `@StorageLink` 实现全局主题切换，所有页面自动响应
4. **MQTT 自动重连**：Backend SDK 内置指数退避重连机制，保证连接稳定性
5. **双门开启动画**：SplashPage 使用 `animateTo` 实现类似双门打开的入场动画效果
6. **影子数据机制**：通过 IoTDA 设备影子（Shadow）获取设备最新上报数据，支持 reported/desired 双方向数据同步

---

## 许可证

本项目基于 Apache License 2.0 开源协议发布。

---

*基于华为云 IoTDA 平台 + HarmonyOS ArkTS 构建的儿童误锁预防系统应用侧*
