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
import { definePostThreadMutation } from "./postThread";
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

export const usePostSpeakerThreadMutation = definePostThreadMutation(
  "speaker",
  postSpeakerThread,
);

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
