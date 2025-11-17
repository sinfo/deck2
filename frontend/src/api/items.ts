import { instance } from "./index";
import type { Item } from "@/dto/item";

export const getItems = async (params?: Record<string, unknown>) => {
  const res = await instance.get(`/items`, { params });
  return res.data as Item[];
};

export const getItemById = async (id: string) => {
  const res = await instance.get(`/items/${id}`);
  return res.data as Item;
};

export const createItem = async (data: {
  name: string;
  type: string;
  description: string;
  price: number;
  vat: number;
}) => {
  const res = await instance.post(`/items`, data);
  return res.data as Item;
};

export const updateItem = async (
  id: string,
  data: {
    name: string;
    type: string;
    description: string;
    price: number;
    vat: number;
  },
) => {
  const res = await instance.put(`/items/${id}`, data);
  return res.data as Item;
};

export const deleteItem = async (id: string) => {
  const res = await instance.delete(`/items/${id}`);
  return res.data as Item;
};

export const getItemCategories = async () => {
  const res = await instance.get(`/items/categories`);
  // API returns either [{ id, name }, ...] or (legacy) ["name", ...]
  return res.data as Array<{ id: string; name: string } | string>;
};

export const createItemCategory = async (name: string) => {
  const res = await instance.post(`/items/categories`, { name });
  return res.data;
};

export const updateItemCategory = async (
  id: string,
  data: { name: string },
) => {
  const res = await instance.put(`/items/categories/${id}`, data);
  return res.data;
};

export const deleteItemCategory = async (id: string) => {
  const res = await instance.delete(`/items/categories/${id}`);
  return res.data;
};
