import type { CreateContactData } from "@/dto/contacts";
import { instance } from ".";

export const updateContact = (id: string, data: CreateContactData) =>
  instance.put(`/contacts/${id}`, data);
