import type { Event } from "@/dto/events";
import { instance } from ".";

export const getAllEvents = () => instance.get<Event[]>("/events");
