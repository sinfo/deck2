import { instance } from ".";
import type {
  AllMembersFilter,
  Member,
  MemberWithContact,
} from "@/dto/members";

export const getAllMembers = (filters?: AllMembersFilter) =>
  instance.get<Member[]>("/members", {
    params: filters,
  });

export const getMe = () => instance.get<MemberWithContact>("/me");
