import {
  updateCompany,
  updateCompanyParticipation,
  updateCompanyParticipationStatus,
  updateCompanyParticipationStep,
  createCompanyParticipation,
  postThread,
  uploadCompanyInternalImage,
  updateRepresentativeOrder,
} from "@/api/companies";
import type { ParticipationStatus } from "@/dto";
import type {
  UpdateCompanyData,
  UpdateCompanyParticipationData,
  AddParticipationData,
  CompanyBillingInfo,
} from "@/dto/companies";
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

export const useCompanyParticipationMutation = defineMutation(() => {
  const companyId = ref<string>();
  const data = ref<UpdateCompanyParticipationData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updateCompanyParticipation(companyId.value!, data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    data,
  };
});

export const useCreateCompanyParticipationMutation = defineMutation(() => {
  const companyId = ref<string>();
  const data = ref<AddParticipationData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => createCompanyParticipation(companyId.value!, data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    data,
  };
});

export const useCompanyParticipationStatusMutation = defineMutation(() => {
  const companyId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: (status: ParticipationStatus) =>
      updateCompanyParticipationStatus(companyId.value!, status),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    status,
  };
});

export const useCompanyParticipationStepMutation = defineMutation(() => {
  const companyId = ref<string>();
  const step = ref<number>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      updateCompanyParticipationStep(companyId.value!, step.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    step,
  };
});

export const useCompanyBillingMutation = defineMutation(() => {
  const companyId = ref<string>();
  const billingInfo = ref<CompanyBillingInfo>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => {
      const updateData: UpdateCompanyData = {
        name: undefined,
        description: undefined,
        site: undefined,
        billingInfo: billingInfo.value!,
      };
      return updateCompany(companyId.value!, updateData);
    },
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["companies"] });
      if (companyId.value) {
        queryCache.invalidateQueries({ key: ["company", companyId.value] });
      }
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    billingInfo,
  };
});

export const useCompanyInfoMutation = defineMutation(() => {
  const companyId = ref<string>();
  const companyData =
    ref<Pick<UpdateCompanyData, "name" | "description" | "site">>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => {
      const updateData: UpdateCompanyData = {
        name: companyData.value?.name,
        description: companyData.value?.description,
        site: companyData.value?.site,
        billingInfo: undefined,
      };
      return updateCompany(companyId.value!, updateData);
    },
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["companies"] });
      if (companyId.value) {
        queryCache.invalidateQueries({ key: ["company", companyId.value] });
      }
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    companyData,
  };
});

export const usePostCompanyThreadMutation = defineMutation(() => {
  const companyId = ref<string>();
  const threadData = ref<CreateThread>();
  const queryCache = useQueryCache();
  const authStore = useAuthStore();
  const eventStore = useEventStore();

  const { mutate, ...mutation } = useMutation({
    mutation: () => postThread(companyId.value!, threadData.value!),
    onMutate: () => {
      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>([
          "company-communications",
          companyId.value!,
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
        ["company-communications", companyId.value!],
        newVal,
      );
      queryCache.cancelQueries({
        key: ["company-communications", companyId.value!],
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
    companyId,
    threadData,
  };
});

export const useCompanyImageUploadMutation = defineMutation(() => {
  const companyId = ref<string>();
  const imageData = ref<FormData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      uploadCompanyInternalImage(companyId.value!, imageData.value!),
    onSettled: () => {
      if (companyId.value) {
        queryCache.invalidateQueries({ key: ["company", companyId.value] });
      }
      queryCache.invalidateQueries({ key: ["companies"] });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    imageData,
  };
});

export const useUpdateRepresentativeOrderMutation = defineMutation(() => {
  const companyId = ref<string>();
  const representativeIds = ref<string[]>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      updateRepresentativeOrder(companyId.value!, representativeIds.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
      queryCache.invalidateQueries({
        key: ["company-representatives", companyId.value!],
      });
    },
  });

  return {
    mutate,
    ...mutation,
    companyId,
    representativeIds,
  };
});
