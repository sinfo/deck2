import { instance } from ".";
import type {
  AllMembersFilter,
  Member,
  MemberWithContact,
  MemberEventTeam,
} from "@/dto/members";

export const getAllMembers = (filters?: AllMembersFilter) =>
  instance.get<Member[]>("/members", {
    params: filters,
  });

export const getMe = () => instance.get<MemberWithContact>("/me");

export const getMemberById = (id: string) =>
  instance.get<Member>(`/members/${id}`);

export const getMemberRole = (id: string) =>
  instance.get<{ role: string }>(`/members/${id}/role`);

export const getMemberParticipations = (id: string) =>
  instance.get<MemberEventTeam[]>(`/members/${id}/participations`);
