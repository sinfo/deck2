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
      const key = ["company-communications", companyId.value!] as const;

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
          text: threadData.value?.text ?? "",
          updated: new Date(0).toISOString(),
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

      const company = res.data;
      const participation = company.participations.find(
        (p) => p.event === currentEventId,
      );
      if (!participation) return;

      const commIdsFromCompany = participation.communications.map(String);

      const oldBucket = (oldVal as ParticipationCommunications[]).find(
        (b) => b.event === currentEventId,
      );
      const existingIds = new Set(
        (oldBucket?.communications ?? []).map((c) => String(c.id)),
      );

      const newThreadId = commIdsFromCompany.find((id) => !existingIds.has(id));
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
      console.error("Create company thread failed:", err);
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
