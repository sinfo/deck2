import type { MyResponsibilities, MyResponsibilitiesFilters } from "@/dto/me";
import { instance } from ".";

export const getMyResponsibilities = (filters: MyResponsibilitiesFilters) =>
  instance.get<MyResponsibilities>("/me/responsibilities", { params: filters });

export const uploadMyImage = (file: File) => {
  const formData = new FormData();
  formData.append("image", file);

  return instance.post("/me/image", formData);
};
