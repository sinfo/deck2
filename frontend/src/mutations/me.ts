import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { uploadMyImage } from "@/api/me";
import { useAuthStore } from "@/stores/auth";
import { getMe } from "@/api/members";

export const useUploadImageMutation = defineMutation(() => {
  const queryCache = useQueryCache();
  const authStore = useAuthStore();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (file: File) => uploadMyImage(file),
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
    mutateAsync,
    ...mutation,
  };
});
