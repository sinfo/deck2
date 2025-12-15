import { instance } from "@/api/index.ts";

export const deleteThread = (id: string) => {
  return instance.delete(`/threads/${id}`);
};
