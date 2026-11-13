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
} from "@/api/companies";
import type { ParticipationStatus } from "@/dto";
import type {
  UpdateCompanyData,
  UpdateCompanyParticipationData,
  AddParticipationData,
  CompanyBillingInfo,
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
import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { ref } from "vue";

export interface UpdateCompanyParticipationVariables {
  companyId: string;
  data: UpdateCompanyParticipationData;
}

export interface UpdateCompanyStatusVariables {
  companyId: string;
  status: ParticipationStatus;
}

export interface UpdateCompanyStepVariables {
  companyId: string;
  step: number;
}

export interface UpdateCompanyPackageVariables {
  companyId: string;
  packageId: string;
}

export const useCompanyParticipationMutation = defineMutation(() => {
  const companyId = ref<string>();
  const data = ref<UpdateCompanyParticipationData>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: UpdateCompanyParticipationVariables) => {
      const targetId = vars?.companyId ?? companyId.value!;
      const targetData = vars?.data ?? data.value!;
      return updateCompanyParticipation(targetId, targetData);
    },
    onSettled: (_data, _err, vars) => {
      const targetId = vars?.companyId ?? companyId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
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

export interface CreateCompanyParticipationVariables {
  companyId: string;
  data: AddParticipationData;
}

export const useCreateCompanyParticipationMutation = defineMutation(() => {
  const companyId = ref<string>();
  const data = ref<AddParticipationData>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: CreateCompanyParticipationVariables) => {
      const targetId = vars?.companyId ?? companyId.value!;
      const targetData = vars?.data ?? data.value!;
      return createCompanyParticipation(targetId, targetData);
    },
    onSettled: (_data, _err, vars) => {
      const targetId = vars?.companyId ?? companyId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
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

export const useCompanyParticipationStatusMutation = defineMutation(() => {
  const companyId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars: UpdateCompanyStatusVariables | ParticipationStatus) => {
      const targetId =
        typeof vars === "object" ? vars.companyId : companyId.value!;
      const targetStatus = typeof vars === "object" ? vars.status : vars;
      return updateCompanyParticipationStatus(targetId, targetStatus);
    },
    onSettled: (_data, _err, vars) => {
      const targetId =
        typeof vars === "object" ? vars.companyId : companyId.value;
      queryCache.invalidateQueries({ key: ["companies"] });
      if (targetId) {
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
    companyId,
  };
});

export const useCompanyParticipationStepMutation = defineMutation(() => {
  const companyId = ref<string>();
  const step = ref<number>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: UpdateCompanyStepVariables) => {
      const targetId = vars?.companyId ?? companyId.value!;
      const targetStep = vars?.step ?? step.value!;
      return updateCompanyParticipationStep(targetId, targetStep);
    },
    onSettled: (_data, _err, vars) => {
      const targetId = vars?.companyId ?? companyId.value;
      queryCache.invalidateQueries({ key: ["companies"] });
      if (targetId) {
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
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

export interface PostCompanyThreadVariables {
  companyId?: string;
  id?: string;
  threadData?: CreateThread;
  data?: CreateThread;
}

interface PostCompanyThreadContext {
  key: string[];
  oldVal: ParticipationCommunications[];
  targetId?: string;
}

export const useCompanyParticipationPackageMutation = defineMutation(() => {
  const companyId = ref<string>();
  const packageId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: UpdateCompanyPackageVariables) => {
      const targetId = vars?.companyId ?? companyId.value!;
      const targetPkgId = vars?.packageId ?? packageId.value!;
      return updateCompanyParticipationPackage(targetId, targetPkgId);
    },
    onSettled: (_data, _err, vars) => {
      const targetId = vars?.companyId ?? companyId.value;
      if (targetId) {
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
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

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars?: PostCompanyThreadVariables) => {
      const targetId = vars?.companyId ?? vars?.id ?? companyId.value!;
      const targetData = vars?.threadData ?? vars?.data ?? threadData.value!;
      return postThread(targetId, targetData);
    },
    onMutate: (vars?: PostCompanyThreadVariables) => {
      const targetId = vars?.companyId ?? vars?.id ?? companyId.value!;
      const targetData = vars?.threadData ?? vars?.data ?? threadData.value!;
      const key = ["company-communications", targetId];

      const oldVal =
        queryCache.getQueryData<ParticipationCommunications[]>(key) ?? [];

      const tempThreadId = crypto.randomUUID();
      const tempPostId = crypto.randomUUID();

      const kind = targetData?.kind;
      if (!kind) throw new Error("Thread kind is required");
      const memberId = authStore.decoded?.id;
      if (!memberId) throw new Error("Authenticated member id is required");

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
      const context = ctx as PostCompanyThreadContext | undefined;
      const targetId =
        vars?.companyId ?? vars?.id ?? context?.targetId ?? companyId.value;
      const targetKey =
        context?.key ??
        (targetId ? ["company-communications", targetId] : undefined);
      if (targetKey && context?.oldVal) {
        queryCache.setQueryData<ParticipationCommunications[]>(
          targetKey,
          context.oldVal,
        );
      }
      console.error("Create company thread failed:", err);
    },

    onSettled: (_data, _err, vars, ctx) => {
      const context = ctx as PostCompanyThreadContext | undefined;
      const targetId =
        vars?.companyId ?? vars?.id ?? context?.targetId ?? companyId.value;
      if (targetId) {
        queryCache.invalidateQueries({
          key: ["company-communications", targetId],
        });
        queryCache.invalidateQueries({ key: ["company", targetId] });
      }
      queryCache.invalidateQueries({ key: ["companies"] });
      queryCache.invalidateQueries({ key: ["responsibilities"] });
    },
  });

  return {
    mutate,
    mutateAsync,
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
