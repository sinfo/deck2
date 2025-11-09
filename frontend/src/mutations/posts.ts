import { ref, computed } from "vue";
import { useMutation, useQueryCache } from "@pinia/colada";
import { updatePost } from "@/api/posts";
import type {
  ParticipationCommunications,
  ThreadWithEntry,
} from "@/dto/threads";
import type { Post } from "@/dto/post.ts";

type EntityType = "speaker" | "company";

// type guard to narrow threads that actually have an entry
const hasEntry = (t: ThreadWithEntry): t is ThreadWithEntry & { entry: Post } =>
  !!t.entry;

export const useUpdatePostMutation = () => {
  // inputs you set from the component before calling mutate()
  const postId = ref<string>();
  const text = ref<string>("");

  // scope to decide which communications list to patch locally
  const entityType = ref<EntityType>("speaker");
  const entityId = ref<string>("");

  const queryCache = useQueryCache();
  const commsKey = computed(() => [
    `${entityType.value}-communications`,
    entityId.value,
  ]);

  const { mutate, ...mutation } = useMutation({
    mutation: () => updatePost(postId.value!, { text: text.value! }),

    onMutate: () => {
      const prev =
        queryCache.getQueryData<ParticipationCommunications[]>(
          commsKey.value,
        ) || [];

      const newText = text.value;
      const updatedAt = new Date().toISOString();

      // Build next state:
      //  - narrow with filter(hasEntry) for type safety
      //  - compute updates for those with entry
      //  - rebuild original array, replacing only the edited post
      const next = prev.map((bucket) => {
        const withEntry = bucket.communications.filter(hasEntry);

        const updates = new Map(
          withEntry.map((t) => {
            const key = String(t.entry.id);
            return [
              key,
              key === postId.value
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

      queryCache.setQueryData(commsKey.value, next);
      queryCache.cancelQueries({ key: commsKey.value });

      return { prev };
    },

    onError: (_err, _vars, ctx) => {
      if (ctx?.prev) {
        queryCache.setQueryData(commsKey.value, ctx.prev);
      }
    },

    onSettled: () => {
      queryCache.invalidateQueries({ key: commsKey.value }); // background reconcile
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
};
