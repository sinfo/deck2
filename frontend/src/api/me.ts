import type { MyResponsibilities, MyResponsibilitiesFilters } from "@/dto/me";
import { instance } from ".";

export const getMyResponsibilities = (filters: MyResponsibilitiesFilters) =>
  instance.get<MyResponsibilities>("/me/responsibilities", { params: filters });
