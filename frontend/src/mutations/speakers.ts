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
  type CreateThread,
  type ParticipationCommunications,
  type ThreadWithEntry,
} from "@/dto/threads";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { ref } from "vue";

export interface UpdateSpeakerStatusVariables {
  speakerId: string;
  status: string;
}

export interface UpdateSpeakerStepVariables {
  speakerId: string;
  step: number;
}

export interface PostSpeakerThreadVariables {
  speakerId?: string;
  id?: string;
  threadData?: CreateThread;
  data?: CreateThread;
}

interface PostSpeakerThreadContext {
  key: string[];
  oldVal: ParticipationCommunications[];
  targetId?: string;
}

export interface UpdateSpeakerParticipationVariables {
  speakerId: string;
  data: UpdateSpeakerParticipationData;
}

export const useSpeakerParticipationStepMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const step = ref<number>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: UpdateSpeakerStepVariables) => {
      const targetId = vars?.speakerId ?? speakerId.value!;
      const targetStep = vars?.step ?? step.value!;
      return updateSpeakerParticipationStep(targetId, targetStep);
    },
    onSettled: (_data, _err, vars) => {
      const targetId = vars?.speakerId ?? speakerId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["speaker", targetId] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    speakerId,
    step,
  };
});

export const useSpeakerParticipationStatusMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars: UpdateSpeakerStatusVariables | string) => {
      const targetId =
        typeof vars === "object" ? vars.speakerId : speakerId.value!;
      const targetStatus = typeof vars === "object" ? vars.status : vars;
      return updateSpeakerParticipationStatus(targetId, targetStatus);
    },
    onSettled: (_data, _err, vars) => {
      const targetId =
        typeof vars === "object" ? vars.speakerId : speakerId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["speaker", targetId] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    speakerId,
  };
});

export interface CreateSpeakerParticipationVariables {
  speakerId: string;
}

export const useCreateSpeakerParticipationMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: CreateSpeakerParticipationVariables | string) => {
      const targetId =
        typeof vars === "string" ? vars : (vars?.speakerId ?? speakerId.value!);
      return createSpeakerParticipation(targetId);
    },
    onSettled: (_data, _err, vars) => {
      const targetId =
        typeof vars === "string" ? vars : (vars?.speakerId ?? speakerId.value);
      if (targetId) {
        queryCache.invalidateQueries({ key: ["speaker", targetId] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
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

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: PostSpeakerThreadVariables) => {
      const targetId = vars?.speakerId ?? vars?.id ?? speakerId.value!;
      const targetData = vars?.threadData ?? vars?.data ?? threadData.value!;
      return postSpeakerThread(targetId, targetData);
    },

    onMutate: (vars?: PostSpeakerThreadVariables) => {
      const targetId = vars?.speakerId ?? vars?.id ?? speakerId.value!;
      const targetData = vars?.threadData ?? vars?.data ?? threadData.value!;
      const key = ["speaker-communications", targetId];

      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const tempThreadId = crypto.randomUUID();
      const tempPostId = crypto.randomUUID();

      const kind = targetData?.kind;
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
        channel: targetData?.channel,
        comments: [],
        posted: now,
        status: ThreadStatus.ThreadStatusPending,
        entry: {
          id: tempPostId,
          member: memberId,
          posted: new Date().toISOString(),
          text: targetData?.text ?? "",
        },
        meeting: undefined,
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
        targetId,
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

    onError: (err, vars, ctx) => {
      const context = ctx as PostSpeakerThreadContext | undefined;
      const targetId =
        vars?.speakerId ?? vars?.id ?? context?.targetId ?? speakerId.value;
      const targetKey =
        context?.key ??
        (targetId ? ["speaker-communications", targetId] : undefined);
      if (targetKey && context?.oldVal) {
        queryCache.setQueryData<ParticipationCommunications[]>(
          targetKey,
          context.oldVal,
        );
      }
      console.error("Create speaker thread failed:", err);
    },

    onSettled: (_data, _err, vars, ctx) => {
      const context = ctx as PostSpeakerThreadContext | undefined;
      const targetId =
        vars?.speakerId ?? vars?.id ?? context?.targetId ?? speakerId.value;
      if (targetId) {
        queryCache.invalidateQueries({
          key: ["speaker-communications", targetId],
        });
        queryCache.invalidateQueries({ key: ["speaker", targetId] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    speakerId,
    threadData,
  };
});

export const useSpeakerParticipationMutation = defineMutation(() => {
  const speakerId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (
      variables:
        | UpdateSpeakerParticipationData
        | UpdateSpeakerParticipationVariables,
    ) => {
      const targetId =
        "speakerId" in variables ? variables.speakerId : speakerId.value!;
      const targetData = "data" in variables ? variables.data : variables;
      return updateSpeakerParticipation(targetId, targetData);
    },
    onSettled: (_data, _err, variables) => {
      const targetId =
        variables && "speakerId" in variables
          ? variables.speakerId
          : speakerId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["speaker", targetId] });
      }
      queryCache.invalidateQueries({ key: ["speakers"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
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
