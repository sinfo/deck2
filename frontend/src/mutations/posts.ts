import { useMutation, useQueryCache } from "@pinia/colada";
import { ref } from "vue";
import { updatePost } from "@/api/posts.ts";

export const useUpdatePostMutation = () => {
  const postId = ref<string>();
  const text = ref<string>("");
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updatePost(postId.value!, { text: text.value! }),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["posts", postId.value!] });
    },
  });

  return { mutate, ...mutation, postId, text };
};
