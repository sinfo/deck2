import {
  updateSpeaker,
  updateSpeakerParticipation,
  updateSpeakerParticipationStep,
  createSpeakerParticipation,
  postSpeakerThread,
  uploadSpeakerInternalImage,
  uploadSpeakerPublicImage,
  uploadSpeakerCompanyImage,
  updateSpeakerParticipationStatus,
  updateSpeakerTasks,
} from "@/api/speakers";
import type {
  UpdateSpeakerData,
  UpdateSpeakerParticipationData,
} from "@/dto/speakers";
import type { SpeakerTasks } from "@/dto/tasks";
import {
  ThreadStatus,
  type ParticipationCommunications,
  type ThreadWithEntry,
} from "@/dto/threads";
import { useAuthStore } from "@/stores/auth";
import type { PostThreadVariables } from "./threads";
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
  const queryCache = useQueryCache();
  const authStore = useAuthStore();
  const eventStore = useEventStore();

  const { mutate, ...mutation } = useMutation({
    mutation: ({ entityId, threadData }: PostThreadVariables) =>
      postSpeakerThread(entityId, threadData),
    onMutate: ({ entityId, threadData }: PostThreadVariables) => {
      const key = ["speaker-communications", entityId];

      const current =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const tempThreadId = crypto.randomUUID();
      const tempPostId = crypto.randomUUID();

      const kind = threadData.kind;
      if (!kind) {
        throw new Error("Thread kind is required for optimistic update");
      }
      const memberId = authStore.decoded?.id;
      if (!memberId) {
        throw new Error(
          "Authenticated member id is required for optimistic update",
        );
      }
      const now = new Date().toISOString();

      const valToAdd: ThreadWithEntry = {
        id: tempThreadId,
        kind,
        channel: threadData.channel,
        comments: [],
        posted: now,
        status: ThreadStatus.ThreadStatusPending,
        entry: {
          id: tempPostId,
          member: memberId,
          posted: new Date().toISOString(),
          text: threadData.text ?? "",
        },
      };

      const currentEventId = eventStore.selectedEvent?.id ?? 0;
      const existingBucket = current.find((it) => it.event === currentEventId);

      const newVal: ParticipationCommunications[] = [
        ...current.filter((it) => it.event !== currentEventId),
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
        currentEventId,
        tempThreadId,
      };
    },

    onSuccess: (res, _vars, ctx) => {
      if (!ctx) return;
      const { key, currentEventId, tempThreadId } = ctx;

      const newThread = res.data;
      const prev = queryCache.getQueryData<ParticipationCommunications[]>(key);
      if (!prev) return;

      const patched = prev.map((bucket) => {
        if (bucket.event !== currentEventId) return bucket;
        return {
          ...bucket,
          communications: bucket.communications.map((t) =>
            String(t.id) === String(tempThreadId) ? newThread : t,
          ),
        };
      });

      queryCache.setQueryData<ParticipationCommunications[]>(key, patched);
    },

    onError: (err, _vars, ctx) => {
      if (ctx) {
        const current =
          queryCache.getQueryData<ParticipationCommunications[]>(ctx.key);
        if (current) {
          queryCache.setQueryData<ParticipationCommunications[]>(
            ctx.key,
            current.map((bucket) =>
              bucket.event === ctx.currentEventId
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
      console.error("Create speaker thread failed:", err);
    },

    onSettled: (_data, _error, { entityId }: PostThreadVariables) => {
      queryCache.invalidateQueries({
        key: ["speaker-communications", entityId],
      });
      queryCache.invalidateQueries({ key: ["speaker", entityId] });
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return { mutate, ...mutation };
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

export const useSpeakerPublicImageUploadMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const imageData = ref<FormData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      uploadSpeakerPublicImage(speakerId.value!, imageData.value!),
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

export const useSpeakerCompanyImageUploadMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const imageData = ref<FormData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      uploadSpeakerCompanyImage(speakerId.value!, imageData.value!),
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

export const useSpeakerTasksMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (tasks: SpeakerTasks) =>
      updateSpeakerTasks(speakerId.value!, tasks),
    onSettled: () => {
      if (speakerId.value) {
        queryCache.invalidateQueries({ key: ["speaker", speakerId.value] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    speakerId,
  };
});
