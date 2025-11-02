import { instance } from "@/api/index.ts";
import type { UpdatePostData } from "@/dto/post.ts";

export const updatePost = (id: string, data: UpdatePostData) => {
  return instance.put(`/posts/${id}`, data);
};
