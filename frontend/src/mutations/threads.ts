import { deleteThread } from "@/api/threads.ts";
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import type { ParticipationCommunications } from "@/dto/threads.ts";
import { ref } from "vue";

export type EntityType = "speaker" | "company";

export interface DeleteThreadVariables {
  threadId?: string;
  entityType?: EntityType;
  entityId?: string;
}

export const useDeleteThreadMutation = defineMutation(() => {
  const threadId = ref<string>("");
  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: DeleteThreadVariables) => {
      const targetThreadId = vars?.threadId ?? threadId.value;
      return deleteThread(targetThreadId);
    },
    onMutate: (vars?: DeleteThreadVariables) => {
      const targetEntityType = vars?.entityType ?? entityType.value;
      const targetEntityId = vars?.entityId ?? entityId.value;
      const targetThreadId = vars?.threadId ?? threadId.value;

      const key = [
        `${targetEntityType}-communications`,
        targetEntityId,
      ] as const;

      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const next = prev.map((bucket) => ({
        ...bucket,
        communications: bucket.communications.filter(
          (t) => String(t.id) !== String(targetThreadId),
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
    mutateAsync,
    ...mutation,
    threadId,
    entityType,
    entityId,
  };
});
