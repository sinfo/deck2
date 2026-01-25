import type { Event } from "@/dto/events";
import { instance } from ".";

export const getAllEvents = () => instance.get<Event[]>("/events");

export interface LinkedGmailThreadInfo {
  threadId: string;
  entityType: "company" | "speaker";
  entityId: string;
  entityName: string;
  entityImage?: string;
}

export interface LinkedGmailThreadsResponse {
  threadIds: string[];
  details: LinkedGmailThreadInfo[];
}

export const getLinkedGmailThreads = (eventId: number) =>
  instance.get<LinkedGmailThreadsResponse>(`/events/${eventId}/gmail-threads`);
