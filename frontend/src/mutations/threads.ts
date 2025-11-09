import { computed, ref } from "vue";
import { deleteThread } from "@/api/threads.ts";
import { useMutation, useQueryCache } from "@pinia/colada";
import type { ParticipationCommunications } from "@/dto/threads.ts";

type EntityType = "speaker" | "company";

export const useDeleteThreadMutation = () => {
  // inputs you set from the component before mutate()
  const threadId = ref<string>();

  // scope to know which communications list to patch
  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();
  const commsKey = computed(
    () => [`${entityType.value}-communications`, entityId.value] as const,
  );
  console.log(entityType.value);

  const { mutate, ...mutation } = useMutation({
    mutation: () => deleteThread(threadId.value!),

    // optimistic remove from communications
    onMutate: () => {
      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(
          commsKey.value,
        ) || [];

      const next = prev.map((bucket) => ({
        ...bucket,
        communications: bucket.communications.filter(
          (t) => String(t.id) !== threadId.value,
        ),
      }));

      queryCache.setQueryData(commsKey.value, next);
      queryCache.cancelQueries({ key: commsKey.value });

      return { prev };
    },

    // rollback on error
    onError: (_e, _v, ctx) => {
      if (ctx?.prev) {
        queryCache.setQueryData(commsKey.value, ctx.prev);
      }
    },

    // reconcile with server (background)
    onSettled: () => {
      queryCache.invalidateQueries({ key: commsKey.value });
    },
  });

  return {
    mutate,
    ...mutation,
    // inputs to set from outside
    threadId,
    entityType,
    entityId,
  };
};
