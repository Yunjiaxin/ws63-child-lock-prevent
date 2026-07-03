import { EnvironmentData } from '../models/EnvironmentData';
import { MoistureData } from '../models/MoistureData';

export class DeviceMonitorService {
  private static instance: DeviceMonitorService;

  private constructor() {}

  static getInstance(): DeviceMonitorService {
    if (!DeviceMonitorService.instance) {
      DeviceMonitorService.instance = new DeviceMonitorService();
    }
    return DeviceMonitorService.instance;
  }

  processEnvironmentData(data: EnvironmentData): void {
    // 可扩展本地存储、持久化逻辑
  }

  processMoistureData(data: MoistureData): void {
    // 可扩展本地存储、持久化逻辑
  }
}