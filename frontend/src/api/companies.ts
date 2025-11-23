import { instance } from ".";
import type {
  AddParticipationData,
  AllCompaniesFilter,
  Company,
  CompanyPublic,
  CompanyRep,
  CreateCompanyData,
  CreateCompanyRepData,
  UpdateCompanyData,
  UpdateCompanyParticipationData,
} from "@/dto/companies";
import type {
  CreateThread,
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";

export const getAllPublicCompanies = () =>
  instance.get<CompanyPublic[]>("/public/companies");

export const getAllCompanies = (filters: AllCompaniesFilter) =>
  instance.get<Company[]>("/companies", {
    params: filters,
  });

export const getCompaniesByMembers = (members: string[], event?: number) =>
  instance.post<Company[]>("/companies/byMembers", { members, event });

export const getCompanyById = (id: string) =>
  instance.get<Company>(`/companies/${id}`);

export const createCompany = (data: CreateCompanyData) =>
  instance.post<Company>("/companies", data);

export const createCompanyParticipation = (
  id: string,
  data: AddParticipationData,
) => instance.post<Company>(`/companies/${id}/participation`, data);

export const updateCompany = (id: string, data: UpdateCompanyData) =>
  instance.put<Company>(`/companies/${id}`, data);

export const updateCompanyParticipation = (
  id: string,
  data: UpdateCompanyParticipationData,
) => instance.put<Company>(`/companies/${id}/participation`, data);

export const updateCompanyParticipationPackage = (
  id: string,
  packageId: string,
) =>
  instance.put<Company>(`/companies/${id}/participation/package/${packageId}`);

export const updateCompanyParticipationStatus = (id: string, status: string) =>
  instance.put<Company>(`/companies/${id}/participation/status/${status}`);

export const updateCompanyParticipationStep = (id: string, step: number) =>
  instance.post<Company>(`/companies/${id}/participation/status/${step}`);

export const getCompanyRepresentatives = (id: string) =>
  instance.get<CompanyRep[]>(`/companies/${id}/employers`);

export const getCompanyCommunications = (id: string) =>
  instance.get<ParticipationCommunications[]>(`/companies/${id}/threads`);

export const postThread = (id: string, data: CreateThread) =>
  instance.post<ThreadWithEntry>(`/companies/${id}/thread`, data);

export const createCompanyRepresentative = (
  id: string,
  data: CreateCompanyRepData,
) => instance.post<Company>(`/companies/${id}/employer`, data);

export const deleteCompanyRepresentative = (id: string, repId: string) =>
  instance.delete(`/companies/${id}/employer/${repId}`);

export const updateCompanyRepresentative = (
  repId: string,
  data: CreateCompanyRepData,
) => instance.put(`/companyReps/${repId}`, data);

export const updateRepresentativeOrder = (
  id: string,
  representativeIds: string[],
) =>
  instance.put<Company>(`/companies/${id}/employers`, {
    employers: representativeIds,
  });

export const uploadCompanyInternalImage = (id: string, data: FormData) =>
  instance.post<Company>(`/companies/${id}/image/internal`, data);
