import { instance } from ".";
import type { AllBillingsFilter, Billing } from "@/dto/billings";

export const getAllBillings = (filters: AllBillingsFilter) =>
  instance.get<Billing[]>("/billings", {
    params: filters,
  });
