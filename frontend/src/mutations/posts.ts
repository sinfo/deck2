import { ref, computed } from "vue";
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

export const useUpdatePostMutation = defineMutation(() => {
  const postId = ref<string>();
  const text = ref<string>("");

  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();
  const commsKey = computed(
    () => [`${entityType.value}-communications`, entityId.value] as const,
  );

  const { mutate, ...mutation } = useMutation({
    mutation: () => updatePost(postId.value!, { text: text.value! }),

    // optimistic update
    onMutate: () => {
      const key = commsKey.value;

      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const newText = text.value;
      const updatedAt = new Date().toISOString();

      const next = prev.map((bucket) => {
        const withEntry = bucket.communications.filter(hasEntry);

        const updates = new Map(
          withEntry.map((t) => {
            const k = String(t.entry.id);
            return [
              k,
              k === postId.value
                ? {
                    ...t,
                    entry: { ...t.entry, text: newText, updated: updatedAt },
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
    ...mutation,
    postId,
    text,
    entityType,
    entityId,
  };
});
