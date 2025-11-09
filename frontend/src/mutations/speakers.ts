import {
  updateSpeaker,
  updateSpeakerParticipation,
  updateSpeakerParticipationStep,
  createSpeakerParticipation,
  postSpeakerThread,
  uploadSpeakerInternalImage,
  updateSpeakerParticipationStatus,
} from "@/api/speakers";
import type {
  UpdateSpeakerData,
  UpdateSpeakerParticipationData,
} from "@/dto/speakers";
import {
  ThreadStatus,
  type CreateThread,
  type ParticipationCommunications,
  type ThreadWithEntry,
} from "@/dto/threads";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { ref } from "vue";

export const useSpeakerParticipationStepMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const step = ref<number>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      updateSpeakerParticipationStep(speakerId.value!, step.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
    step,
  };
});

export const useSpeakerParticipationStatusMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: (status: string) =>
      updateSpeakerParticipationStatus(speakerId.value!, status),
    onSettled: () => {
      if (speakerId.value) {
        queryCache.invalidateQueries({ key: ["speaker", speakerId.value] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
  };
});

export const useCreateSpeakerParticipationMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => createSpeakerParticipation(speakerId.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["speaker", speakerId.value!] });
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
  };
});

export const useSpeakerInfoMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const speakerData = ref<UpdateSpeakerData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updateSpeaker(speakerId.value!, speakerData.value!),
    onSettled: () => {
      if (speakerId.value) {
        queryCache.invalidateQueries({ key: ["speaker", speakerId.value] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
    speakerData,
  };
});

export const usePostSpeakerThreadMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const threadData = ref<CreateThread>();
  const queryCache = useQueryCache();
  const authStore = useAuthStore();
  const eventStore = useEventStore();

  const { mutate, ...mutation } = useMutation({
    mutation: () => postSpeakerThread(speakerId.value!, threadData.value!),

    onMutate: () => {
      const key = ["speaker-communications", speakerId.value!] as const;

      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>(key) || [];

      const tempThreadId = crypto.randomUUID();
      const tempPostId = crypto.randomUUID();

      const kind = threadData.value?.kind;
      if (!kind) {
        throw new Error("Thread kind is required for optimistic update");
      }

      const valToAdd: ThreadWithEntry = {
        id: tempThreadId,
        kind: kind,
        comments: [],
        posted: new Date().toISOString(),
        status: ThreadStatus.ThreadStatusPending,
        entry: {
          id: tempPostId,
          member: authStore.decoded?.id,
          posted: new Date().toISOString(),
          text: threadData.value?.text,
        },
      };

      const currentEventId = eventStore.selectedEvent?.id ?? 0;
      const existingBucket = oldVal.find((it) => it.event === currentEventId);

      const newVal: ParticipationCommunications[] = [
        ...oldVal.filter((it) => it.event !== currentEventId),
        {
          event: currentEventId,
          communications: existingBucket
            ? existingBucket.communications.concat(valToAdd)
            : [valToAdd],
        },
      ];

      queryCache.setQueryData<ParticipationCommunications[]>(key, newVal);

      return {
        key,
        oldVal,
        currentEventId,
        tempThreadId,
        tempPostId,
      };
    },

    onSuccess: (res, _vars, ctx) => {
      if (!ctx) return;
      const { key, oldVal, currentEventId, tempThreadId } = ctx;

      const speaker = res.data;
      const participation = speaker.participations.find(
        (p) => p.event === currentEventId,
      );
      if (!participation) return;

      const commIdsFromSpeaker = participation.communications.map(String);

      const oldBucket = (oldVal as ParticipationCommunications[]).find(
        (b) => b.event === currentEventId,
      );
      const existingIds = new Set(
        (oldBucket?.communications ?? []).map((c) => String(c.id)),
      );

      const newThreadId = commIdsFromSpeaker.find((id) => !existingIds.has(id));
      if (!newThreadId) return;

      const prev = queryCache.getQueryData<ParticipationCommunications[]>(key);
      if (!prev) return;

      const patched = prev.map((bucket) => {
        if (bucket.event !== currentEventId) return bucket;
        return {
          ...bucket,
          communications: bucket.communications.map((t) =>
            String(t.id) === String(tempThreadId)
              ? { ...t, id: newThreadId }
              : t,
          ),
        };
      });

      queryCache.setQueryData<ParticipationCommunications[]>(key, patched);
    },

    onError: (err, _vars, ctx) => {
      if (ctx?.key && ctx?.oldVal) {
        queryCache.setQueryData<ParticipationCommunications[]>(
          ctx.key,
          ctx.oldVal,
        );
      }
      console.error("Create speaker thread failed:", err);
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
    threadData,
  };
});

export const useSpeakerParticipationMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: (variables: UpdateSpeakerParticipationData) =>
      updateSpeakerParticipation(speakerId.value!, variables),
    onSettled: () => {
      if (speakerId.value) {
        queryCache.invalidateQueries({ key: ["speaker", speakerId.value] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
  };
});

export const useSpeakerImageUploadMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const imageData = ref<FormData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      uploadSpeakerInternalImage(speakerId.value!, imageData.value!),
    onSettled: () => {
      if (speakerId.value) {
        queryCache.invalidateQueries({ key: ["speaker", speakerId.value] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
    },
  });

  return {
    mutate,
    ...mutation,
    speakerId,
    imageData,
  };
});
