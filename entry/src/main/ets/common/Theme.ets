// 主题模式枚举
export enum ThemeMode {
  GREEN_WHITE = 'green_white',
  DARK_BLUE = 'dark_blue'
}

// 主题颜色接口
export interface ThemeColors {
  primary: string;
  background: string;
  cardBg: string;
  textPrimary: string;
  textSecondary: string;
  border: string;
  shadow: string;
}

// 绿白主题（默认）
const GreenWhiteTheme: ThemeColors = {
  primary: '#4CAF50',
  background: '#F5F5F5',
  cardBg: '#FFFFFF',
  textPrimary: '#333333',
  textSecondary: '#757575',
  border: '#E0E0E0',
  shadow: '#1A000000'
};

// 黑蓝主题
const DarkBlueTheme: ThemeColors = {
  primary: '#2196F3',
  background: '#121212',
  cardBg: '#1E1E2E',
  textPrimary: '#FFFFFF',
  textSecondary: '#B0B0B0',
  border: '#2C2C3A',
  shadow: '#33000000'
};

// 根据模式获取主题颜色
export function getThemeColors(mode: ThemeMode): ThemeColors {
  return mode === ThemeMode.GREEN_WHITE ? GreenWhiteTheme : DarkBlueTheme;
}
