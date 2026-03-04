interface NavigatorUAData {
  platform?: string;
  brands?: Array<{ brand: string; version: string }>;
  mobile?: boolean;
}

declare global {
  interface Navigator {
    userAgentData?: NavigatorUAData;
  }
}

export {};
