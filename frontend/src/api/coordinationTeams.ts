import { instance } from ".";
import type {
  CoordinationTeam,
  CreateCoordinationTeamData,
  AddCoordinatedTeamData,
  SetCoordinatorData,
} from "@/dto/coordinationTeams";

export const getAllCoordinationTeams = () =>
  instance.get<CoordinationTeam[]>(`/coordinationTeams`);

export const getMyCoordinationTeams = () =>
  instance.get<CoordinationTeam[]>(`/coordinationTeams/me`);

export const createCoordinationTeam = (data: CreateCoordinationTeamData) =>
  instance.post<CoordinationTeam>(`/coordinationTeams`, data);

export const getCoordinationTeamById = (id: string) =>
  instance.get<CoordinationTeam>(`/coordinationTeams/${id}`);

export const updateCoordinationTeamName = (
  id: string,
  data: { name: string },
) => instance.put<CoordinationTeam>(`/coordinationTeams/${id}`, data);

export const deleteCoordinationTeam = (id: string) =>
  instance.delete(`/coordinationTeams/${id}`);

export const addCoordinatedTeam = (id: string, data: AddCoordinatedTeamData) =>
  instance.post<CoordinationTeam>(
    `/coordinationTeams/${id}/coordinatedMembers`,
    data,
  );

export const removeCoordinatedTeam = (id: string, memberId: string) =>
  instance.delete(`/coordinationTeams/${id}/coordinatedMembers/${memberId}`);

export const setCoordinator = (id: string, data: SetCoordinatorData) =>
  instance.post<CoordinationTeam>(`/coordinationTeams/${id}/coordinator`, data);

export const removeCoordinator = (id: string, memberId: string) =>
  instance.delete(`/coordinationTeams/${id}/coordinator/${memberId}`);
