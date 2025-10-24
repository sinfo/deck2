import type {
  AllSpeakersFilter,
  CreateSpeakerData,
  Speaker,
  SpeakerWithContactObject,
  UpdateSpeakerData,
  UpdateSpeakerParticipationData,
} from "@/dto/speakers";
import { instance } from ".";
import {
  type ParticipationCommunications,
  type CreateThread,
  type ThreadWithEntry,
} from "@/dto/threads";

export const getAllSpeakers = (filter: AllSpeakersFilter) =>
  instance.get<Speaker[]>("/speakers", { params: filter });

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
