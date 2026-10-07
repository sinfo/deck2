import {
  updateCompany,
  updateCompanyParticipation,
  updateCompanyParticipationPackage,
  updateCompanyParticipationStatus,
  updateCompanyParticipationStep,
  createCompanyParticipation,
  postThread,
  uploadCompanyInternalImage,
  uploadCompanyPublicImage,
  updateRepresentativeOrder,
  updateCompanyTasks,
  getCompanyRelationships,
  addCompanyRelationship,
  removeCompanyRelationship,
} from "@/api/companies";
import type { ParticipationStatus } from "@/dto";
import type {
  UpdateCompanyData,
  UpdateCompanyParticipationData,
  AddParticipationData,
  CompanyBillingInfo,
  AddCompanyRelationshipData,
  CompanyRelationshipType,
} from "@/dto/companies";
import type { CompanyTasks } from "@/dto/tasks";
import {
  ThreadStatus,
  type CreateThread,
  type ParticipationCommunications,
  type ThreadWithEntry,
} from "@/dto/threads";
import { useAuthStore } from "@/stores/auth";
import { useEventStore } from "@/stores/event";
import {
  defineMutation,
  useMutation,
  useQuery,
  useQueryCache,
} from "@pinia/colada";
import { ref, toValue, type MaybeRefOrGetter } from "vue";

export const useCompanyParticipationMutation = defineMutation(() => {
  const companyId = ref<string>();
  const data = ref<UpdateCompanyParticipationData>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: () => updateCompanyParticipation(companyId.value!, data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
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
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
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
    ref<
      Pick<UpdateCompanyData, "name" | "description" | "site" | "linkedin">
    >();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => {
      const updateData: UpdateCompanyData = {
        name: companyData.value?.name,
        description: companyData.value?.description,
        site: companyData.value?.site,
        linkedin: companyData.value?.linkedin,
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

export const useCompanyParticipationPackageMutation = defineMutation(() => {
  const companyId = ref<string>();
  const packageId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: () =>
      updateCompanyParticipationPackage(companyId.value!, packageId.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["company", companyId.value!] });
      queryCache.invalidateQueries({ key: ["companies"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    companyId,
    packageId,
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
      const key = ["company-communications", companyId.value!];

      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const tempThreadId = crypto.randomUUID();
      const tempPostId = crypto.randomUUID();

      const kind = threadData.value?.kind;
      if (!kind) throw new Error("Thread kind is required");

      const now = new Date().toISOString();

      const valToAdd: ThreadWithEntry = {
        id: tempThreadId,
        kind,
        comments: [],
        posted: now,
        status: ThreadStatus.ThreadStatusPending,
        entry: {
          id: tempPostId,
          member: authStore.decoded?.id,
          posted: new Date().toISOString(),
          text: threadData.value?.text ?? "",
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

export const useCompanyPublicImageUploadMutation = defineMutation(() => {
  const companyId = ref<string>();
  const imageData = ref<FormData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      uploadCompanyPublicImage(companyId.value!, imageData.value!),
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

export const useCompanyTasksMutation = defineMutation(() => {
  const companyId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (tasks: CompanyTasks) =>
      updateCompanyTasks(companyId.value!, tasks),
    onSettled: () => {
      if (companyId.value) {
        queryCache.invalidateQueries({ key: ["company", companyId.value] });
      }
      queryCache.invalidateQueries({ key: ["companies"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    companyId,
  };
});

export const useCompanyRelationshipsQuery = (
  companyId: MaybeRefOrGetter<string | undefined>,
) =>
  useQuery({
    key: () => ["company-relationships", toValue(companyId) ?? ""],
    enabled: () => !!toValue(companyId),
    query: async () =>
      (await getCompanyRelationships(toValue(companyId)!)).data,
  });

// Relationships are stored on both companies, so both sides must be refreshed.
const invalidateCompanyRelationships = (
  queryCache: ReturnType<typeof useQueryCache>,
  companyIds: string[],
) => {
  for (const id of companyIds) {
    queryCache.invalidateQueries({ key: ["company", id] });
    queryCache.invalidateQueries({ key: ["company-relationships", id] });
  }
  queryCache.invalidateQueries({ key: ["companies"] });
};

export const useAddCompanyRelationshipMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars: { companyId: string; data: AddCompanyRelationshipData }) =>
      addCompanyRelationship(vars.companyId, vars.data),
    onSettled: (_data, _error, vars) => {
      invalidateCompanyRelationships(queryCache, [
        vars.companyId,
        vars.data.company,
      ]);
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
  };
});

export const useRemoveCompanyRelationshipMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars: {
      companyId: string;
      targetId: string;
      type: CompanyRelationshipType;
    }) => removeCompanyRelationship(vars.companyId, vars.targetId, vars.type),
    onSettled: (_data, _error, vars) => {
      invalidateCompanyRelationships(queryCache, [
        vars.companyId,
        vars.targetId,
      ]);
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
  };
});
