import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { uploadMyImage } from "@/api/me";
import { ref } from "vue";
import { useAuthStore } from "@/stores/auth";
import { getMe } from "@/api/members";

export const useUploadImageMutation = defineMutation(() => {
  const file = ref<File>();
  const queryCache = useQueryCache();
  const authStore = useAuthStore();

  const { mutate, ...mutation } = useMutation({
    mutation: () => uploadMyImage(file.value!),
    onSettled: async () => {
      queryCache.invalidateQueries({ key: ["me"] });
      try {
        const res = await getMe();
        if (res.data) {
          authStore.member = res.data;
        }
      } catch {
        // ignore
      }
    },
  });

  return {
    mutate,
    ...mutation,
    file,
  };
});
