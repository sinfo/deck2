import { instance } from ".";
import type {
  AllMembersFilter,
  Member,
} from "@/dto/members";

export const getAllMembers = (filters?: AllMembersFilter) =>
  instance.get<Member[]>("/members", {
    params: filters,
  });