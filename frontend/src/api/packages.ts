import { instance } from "./index";
import type { Package, PackageItem } from "@/dto/packages";

export const getPackages = async (params?: Record<string, unknown>) => {
  const res = await instance.get(`/packages`, { params });
  return res.data as Package[];
};

export const getPackageById = async (id: string) => {
  const res = await instance.get(`/packages/${id}`);
  return res.data as Package;
};

export const createPackage = async (data: {
  name: string;
  items: PackageItem[];
  price: number;
  vat: number;
}) => {
  const res = await instance.post(`/packages`, data);
  return res.data as Package;
};

export const updatePackage = async (
  id: string,
  data: { name: string; price: number; vat: number; edition?: number },
) => {
  const res = await instance.put(`/packages/${id}`, data);
  return res.data as Package;
};

export const deletePackage = async (id: string) => {
  const res = await instance.delete(`/packages/${id}`);
  return res.data as Package;
};

export const updatePackageItems = async (
  id: string,
  data: { items: { item: string; quantity: number }[] },
) => {
  const res = await instance.put(`/packages/${id}/items`, data);
  return res.data as Package;
};
