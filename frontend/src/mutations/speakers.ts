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
      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>([
          "speaker-communications",
          speakerId.value!,
        ]) || [];

      const valToAdd = {
        id: crypto.randomUUID(),
        kind: threadData.value?.kind,
        comments: [],
        posted: new Date().toISOString(),
        status: ThreadStatus.ThreadStatusPending,
        entry: {
          id: crypto.randomUUID(),
          member: authStore.decoded?.id,
          posted: new Date().toISOString(),
          text: threadData.value?.text,
          updated: new Date(0).toISOString(),
        },
      } as ThreadWithEntry;

      const event = oldVal.find(
        (it) => it.event === eventStore.selectedEvent?.id,
      );
      const newVal: ParticipationCommunications[] = [
        ...oldVal.filter((it) => it.event !== eventStore.selectedEvent?.id),
        {
          event: eventStore.selectedEvent?.id || 0,
          communications: event
            ? event.communications.concat(valToAdd)
            : [valToAdd],
        },
      ];

      queryCache.setQueryData<ParticipationCommunications[]>(
        ["speaker-communications", speakerId.value!],
        newVal,
      );
      queryCache.cancelQueries({
        key: ["speaker-communications", speakerId.value!],
      });

      return {
        oldVal,
        newVal,
      };
    },
    onError: (err, _, { oldVal, newVal }) => {
      console.error(
        `An error occurred when updating ${oldVal} to ${newVal}`,
        err,
      );
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
