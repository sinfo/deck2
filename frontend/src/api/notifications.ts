import type { Notification } from "@/dto/notifications";
import { instance } from ".";

export const getMyNotifications = () => instance.get<Notification[]>('/me/notifications');
export const deleteMyNotification = (id: string) => instance.delete<Notification>(`/me/notifications/${id}`);
