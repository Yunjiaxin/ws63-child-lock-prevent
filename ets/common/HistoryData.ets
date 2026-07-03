// 历史记录条目（描述性，用于列表显示）
export interface HistoryRecord {
  id: number;
  timestamp: string;
  description: string;
}

// 传感器数据点（用于折线图）
export interface SensorDataPoint {
  id: number;
  timestamp: number;   // Unix 毫秒时间戳
  type: SensorType;
  value: number;
}

export enum SensorType {
  CO2 = 'CO2',
  HCHO = 'HCHO',
  TEMPERATURE = 'TEMPERATURE',
  HUMIDITY = 'HUMIDITY'
}

// 添加描述性历史记录
export function addHistoryRecord(description: string): void {
  const now = new Date();
  const timeStr = `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()} ${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
  const newRecord: HistoryRecord = {
    id: Date.now(),
    timestamp: timeStr,
    description: description
  };
  const currentList = AppStorage.get<HistoryRecord[]>('historyList') ?? [];
  const updatedList = [newRecord, ...currentList];
  AppStorage.setOrCreate('historyList', updatedList);
}

// 添加传感器数据点（用于图表）
export function addSensorDataPoint(type: SensorType, value: number): void {
  const newPoint: SensorDataPoint = {
    id: Date.now(),
    timestamp: Date.now(),
    type: type,
    value: value
  };
  const currentData = AppStorage.get<SensorDataPoint[]>('sensorDataList') ?? [];
  const updatedData = [...currentData, newPoint];
  AppStorage.setOrCreate('sensorDataList', updatedData);
}

// 初始化存储
export function initHistoryData(): void {
  if (AppStorage.get<HistoryRecord[]>('historyList') === undefined) {
    AppStorage.setOrCreate('historyList', []);
  }
  if (AppStorage.get<SensorDataPoint[]>('sensorDataList') === undefined) {
    AppStorage.setOrCreate('sensorDataList', []);
  }
}

// 获取指定类型的传感器数据（最近 N 条，按时间升序）
export function getSensorDataByType(type: SensorType, limit: number = 20): SensorDataPoint[] {
  const allData = AppStorage.get<SensorDataPoint[]>('sensorDataList') ?? [];
  const filtered = allData.filter(item => item.type === type);
  const sorted = filtered.sort((a, b) => a.timestamp - b.timestamp);
  return sorted.slice(-limit);
}