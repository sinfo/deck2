import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import {
  ThreadStatus,
  type CreateThread,
  type ParticipationCommunications,
  type ThreadWithEntry,
} from "@/dto/threads";
import type { EntityType, PostThreadVariables } from "./threads";

type CreateThreadRequest = (
  entityId: string,
  threadData: CreateThread,
) => Promise<{ data: ThreadWithEntry }>;

// Company and speaker communications have the same optimistic lifecycle.
// Only the API request and cache prefix depend on the entity type.
export const definePostThreadMutation = (
  entityType: EntityType,
  createThread: CreateThreadRequest,
) =>
  defineMutation(() => {
    const queryCache = useQueryCache();
    const authStore = useAuthStore();
    const eventStore = useEventStore();

    const { mutate, ...mutation } = useMutation({
      mutation: ({ entityId, threadData }: PostThreadVariables) =>
        createThread(entityId, threadData),

      onMutate: ({ entityId, threadData }: PostThreadVariables) => {
        const key = [`${entityType}-communications`, entityId];
        const current =
          queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

        if (!threadData.kind) throw new Error("Thread kind is required");
        const memberId = authStore.decoded?.id;
        if (!memberId) throw new Error("Authenticated member id is required");

        const tempThreadId = crypto.randomUUID();
        const tempPostId = crypto.randomUUID();
        const now = new Date().toISOString();
        const optimisticThread: ThreadWithEntry = {
          id: tempThreadId,
          kind: threadData.kind,
          channel: threadData.channel,
          comments: [],
          posted: now,
          status: ThreadStatus.ThreadStatusPending,
          entry: {
            id: tempPostId,
            member: memberId,
            posted: now,
            text: threadData.text ?? "",
          },
        };

        const eventId = eventStore.selectedEvent?.id ?? 0;
        const existingBucket = current.find(
          (bucket) => bucket.event === eventId,
        );
        queryCache.setQueryData<ParticipationCommunications[]>(key, [
          ...current.filter((bucket) => bucket.event !== eventId),
          {
            event: eventId,
            communications: [
              ...(existingBucket?.communications ?? []),
              optimisticThread,
            ],
          },
        ]);

        return { key, eventId, tempThreadId };
      },

      onSuccess: (response, _vars, ctx) => {
        if (!ctx) return;
        const current = queryCache.getQueryData<ParticipationCommunications[]>(
          ctx.key,
        );
        if (!current) return;

        queryCache.setQueryData<ParticipationCommunications[]>(
          ctx.key,
          current.map((bucket) =>
            bucket.event === ctx.eventId
              ? {
                  ...bucket,
                  communications: bucket.communications.map((thread) =>
                    thread.id === ctx.tempThreadId ? response.data : thread,
                  ),
                }
              : bucket,
          ),
        );
      },

      onError: (error, _vars, ctx) => {
        if (ctx) {
          const current = queryCache.getQueryData<
            ParticipationCommunications[]
          >(ctx.key);
          if (current) {
            // Only remove this request's temporary thread. Other in-flight
            // requests must keep their own optimistic data.
            queryCache.setQueryData<ParticipationCommunications[]>(
              ctx.key,
              current.map((bucket) =>
                bucket.event === ctx.eventId
                  ? {
                      ...bucket,
                      communications: bucket.communications.filter(
                        (thread) => thread.id !== ctx.tempThreadId,
                      ),
                    }
                  : bucket,
              ),
            );
          }
        }
        console.error(`Create ${entityType} thread failed:`, error);
      },

      onSettled: (_data, _error, { entityId }: PostThreadVariables) => {
        queryCache.invalidateQueries({
          key: [`${entityType}-communications`, entityId],
        });
        queryCache.invalidateQueries({ key: [entityType, entityId] });
        queryCache.invalidateQueries({
          key: [entityType === "company" ? "companies" : "speakers"],
        });
        queryCache.invalidateQueries({ key: ["responsibilities"] });
      },
    });

    return { mutate, ...mutation };
  });
