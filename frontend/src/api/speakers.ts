import type {
  AllSpeakersFilter,
  CreateSpeakerData,
  Speaker,
  SpeakerWithContactObject,
  UpdateSpeakerData,
  UpdateSpeakerParticipationData,
} from "@/dto/speakers";
import type { SpeakerTasks } from "@/dto/tasks";
import { instance } from ".";
import {
  type ParticipationCommunications,
  type CreateThread,
  type ThreadWithEntry,
} from "@/dto/threads";

export const getAllSpeakers = (filter: AllSpeakersFilter) =>
  instance.get<Speaker[]>("/speakers", { params: filter });

export const getSpeakersByMembers = (members: string[], event?: number) =>
  instance.post<Speaker[]>("/speakers/byMembers", { members, event });

export const getSpeakerById = (id: string) =>
  instance.get<SpeakerWithContactObject>(`/speakers/${id}`);

export const updateSpeaker = (id: string, data: UpdateSpeakerData) =>
  instance.put<Speaker>(`/speakers/${id}`, data);

export const updateSpeakerParticipation = (
  id: string,
  data: UpdateSpeakerParticipationData,
) => instance.put<Speaker>(`/speakers/${id}/participation`, data);

export const updateSpeakerParticipationStep = (id: string, step: number) =>
  instance.post<Speaker>(`/speakers/${id}/participation/status/${step}`);

export const updateSpeakerParticipationStatus = (id: string, status: string) =>
  instance.put<Speaker>(`/speakers/${id}/participation/status/${status}`);

export const getSpeakerCommunications = (id: string) =>
  instance.get<ParticipationCommunications[]>(`/speakers/${id}/threads`);

export const postSpeakerThread = (id: string, data: CreateThread) =>
  instance.post<ThreadWithEntry>(`/speakers/${id}/thread`, data);

export const createSpeakerParticipation = (id: string) =>
  instance.post(`/speakers/${id}/participation`);

export const createSpeaker = (data: CreateSpeakerData) =>
  instance.post<Speaker>("/speakers", data);

export const uploadSpeakerInternalImage = (id: string, data: FormData) =>
  instance.post<Speaker>(`/speakers/${id}/image/internal`, data);

export const deleteSpeaker = (id: string) =>
  instance.delete<Speaker>(`/speakers/${id}`);

export const updateSpeakerGmailThreadIds = (
  id: string,
  gmailThreadIds: string[],
) =>
  instance.put<Speaker>(`/speakers/${id}/participation/gmail-threads`, {
    gmailThreadIds,
  });

export interface GmailMessageData {
  messageId: string;
  threadId: string;
  subject: string;
  from: string;
  to: string;
  date: string;
  body: string;
  isOutgoing: boolean;
}

export interface SyncGmailResponse {
  synced: number;
  total: number;
}

export const syncSpeakerGmailMessages = (
  id: string,
  messages: GmailMessageData[],
) =>
  instance.post<SyncGmailResponse>(`/speakers/${id}/participation/gmail-sync`, {
    messages,
  });

export const updateSpeakerTasks = (id: string, tasks: SpeakerTasks) =>
  instance.put<Speaker>(`/speakers/${id}/participation/tasks`, { tasks });
