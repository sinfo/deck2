export interface Log {
  id: string;
  actor?: string | null;
  action: string;
  resource: string;
  resourceId?: string | null;
  data?: Record<string, unknown> | null;
  date: string;
}
