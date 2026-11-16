import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { uploadMyImage } from "@/api/me";
import { useAuthStore } from "@/stores/auth";
import { getMe } from "@/api/members";

export const useUploadImageMutation = defineMutation(() => {
  const queryCache = useQueryCache();
  const authStore = useAuthStore();

  return useMutation({
    mutation: uploadMyImage,
    onSuccess: async () => {
      try {
        const response = await getMe();
        queryCache.setQueryData(["me"], response);
        authStore.member = response.data;
      } catch {
        // Keep the profile query consistent if the direct refresh fails.
        queryCache.invalidateQueries({ key: ["me"] });
      }
    },
  });
});
