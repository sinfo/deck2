import { instance } from "./index";
import type { Log } from "@/dto/logs";

export const getLogs = (params?: Record<string, string | number | boolean>) =>
  instance.get<Log[]>("/logs", { params });

export const getLog = (id: string) => instance.get<Log>(`/logs/${id}`);

export const getLogsByCompany = (
  companyId: string,
  params?: Record<string, string | number | boolean>,
) => instance.get<Log[]>(`/logs/company/${companyId}`, { params });

export const getLogsBySpeaker = (
  speakerId: string,
  params?: Record<string, string | number | boolean>,
) => instance.get<Log[]>(`/logs/speaker/${speakerId}`, { params });
