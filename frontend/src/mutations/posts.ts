import { ref } from "vue";
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { updatePost } from "@/api/posts";
import type {
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";
import type { Post } from "@/dto/post.ts";
import type { EntityType } from "@/mutations/threads.ts";

// to get threads that actually have an entry
const hasEntry = (t: ThreadWithEntry): t is ThreadWithEntry & { entry: Post } =>
  !!t.entry;

export interface UpdatePostVariables {
  postId?: string;
  text?: string;
  entityType?: EntityType;
  entityId?: string;
}

export const useUpdatePostMutation = defineMutation(() => {
  const postId = ref<string>();
  const text = ref<string>("");

  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: UpdatePostVariables) => {
      const targetPostId = vars?.postId ?? postId.value!;
      const targetText = vars?.text ?? text.value!;
      return updatePost(targetPostId, { text: targetText });
    },

    // optimistic update
    onMutate: (vars?: UpdatePostVariables) => {
      const targetEntityType = vars?.entityType ?? entityType.value;
      const targetEntityId = vars?.entityId ?? entityId.value;
      const targetPostId = vars?.postId ?? postId.value;
      const targetText = vars?.text ?? text.value;

      const key = [
        `${targetEntityType}-communications`,
        targetEntityId,
      ] as const;

      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const updatedAt = new Date().toISOString();

      const next = prev.map((bucket) => {
        const withEntry = bucket.communications.filter(hasEntry);

        const updates = new Map(
          withEntry.map((t) => {
            const k = String(t.entry.id);
            return [
              k,
              k === targetPostId
                ? {
                    ...t,
                    entry: { ...t.entry, text: targetText, updated: updatedAt },
                  }
                : t,
            ] as const;
          }),
        );

        const merged = bucket.communications.map((t) =>
          hasEntry(t) ? (updates.get(String(t.entry.id)) ?? t) : t,
        );

        return { ...bucket, communications: merged };
      });

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
    postId,
    text,
    entityType,
    entityId,
  };
});
