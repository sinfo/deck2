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
  updateCompanyRelationship,
  setCompanyClosure,
  removeCompanyClosure,
} from "@/api/companies";
import type { ParticipationStatus } from "@/dto";
import type {
  UpdateCompanyData,
  UpdateCompanyParticipationData,
  AddParticipationData,
  CompanyBillingInfo,
  AddCompanyRelationshipData,
  CompanyRelationshipType,
  CompanyClosure,
  UpdateCompanyRelationshipData,
} from "@/dto/companies";
import type { CompanyTasks } from "@/dto/tasks";
import { definePostThreadMutation } from "./postThread";
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

export const usePostCompanyThreadMutation = definePostThreadMutation(
  "company",
  postThread,
);

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

export const useUpdateCompanyRelationshipMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    mutation: (vars: {
      companyId: string;
      targetId: string;
      type: CompanyRelationshipType;
      data: UpdateCompanyRelationshipData;
    }) =>
      updateCompanyRelationship(
        vars.companyId,
        vars.targetId,
        vars.type,
        vars.data,
      ),
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

export const useCompanyClosureMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, mutateAsync, ...mutation } = useMutation({
    // A null closure marks the company as operating again.
    mutation: (vars: { companyId: string; closure: CompanyClosure | null }) =>
      vars.closure
        ? setCompanyClosure(vars.companyId, vars.closure)
        : removeCompanyClosure(vars.companyId),
    onSettled: (_data, _error, vars) => {
      queryCache.invalidateQueries({ key: ["company", vars.companyId] });
      queryCache.invalidateQueries({ key: ["companies"] });
    },
  });

  return {
    mutate,
    mutateAsync,
    ...mutation,
  };
});
