import { instance } from ".";
import type { Team } from "@/dto/teams";

export const getAllTeams = (params?: Record<string, unknown>) =>
  instance.get<Team[]>("/teams", { params });
