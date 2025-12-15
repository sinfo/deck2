import { deleteThread } from "@/api/threads.ts";
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import type { ParticipationCommunications } from "@/dto/threads.ts";
import { computed, ref } from "vue";

export type EntityType = "speaker" | "company";

export const useDeleteThreadMutation = defineMutation(() => {
  const threadId = ref<string>("");
  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();
  const commsKey = computed(() => [
    `${entityType.value}-communications`,
    entityId.value,
  ]);

  const { mutate, ...mutation } = useMutation({
    mutation: () => deleteThread(threadId.value),
    onMutate: () => {
      const key = commsKey.value;

      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const next = prev.map((bucket) => ({
        ...bucket,
        communications: bucket.communications.filter(
          (t) => String(t.id) !== String(threadId.value),
        ),
      }));

      queryCache.setQueryData<ParticipationCommunications[]>(key, next);
      return { key, prev };
    },

    // rollback on error
    onError: (_err, _vars, ctx) => {
      if (ctx?.key && ctx?.prev) {
        queryCache.setQueryData<ParticipationCommunications[]>(
          ctx.key,
          ctx.prev,
        );
      }
    },
  });

  return {
    mutate,
    ...mutation,
    threadId,
    entityType,
    entityId,
  };
});
