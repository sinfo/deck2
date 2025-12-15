import {
  defineMutation,
  useMutation,
  useQuery,
  useQueryCache,
} from "@pinia/colada";
import { ref, type Ref } from "vue";
import {
  getPackages,
  getPackageById,
  createPackage,
  updatePackage,
  deletePackage,
  updatePackageItems,
} from "@/api/packages";
import type { PackageItem } from "@/dto/packages";

// Shared packages list query
export const usePackagesQuery = (params?: Record<string, unknown>) =>
  useQuery({
    key: ["packages", params ? JSON.stringify(params) : ""],
    query: () => getPackages(params),
  });

// Single package query by id
export const usePackageQuery = (
  id: string | Ref<string | null | undefined> | null | undefined,
) => {
  const isRef = (v: unknown): v is Ref<string | null | undefined> =>
    typeof v === "object" &&
    v !== null &&
    (v as Record<string, unknown>) &&
    "value" in (v as Record<string, unknown>);

  return useQuery({
    key: () => [
      "package",
      isRef(id) ? (id as Ref<string | null | undefined>).value || "" : id || "",
    ],
    enabled: () =>
      isRef(id) ? !!(id as Ref<string | null | undefined>).value : !!id,
    query: () =>
      getPackageById(
        isRef(id)
          ? (id as Ref<string | null | undefined>).value!
          : (id as string)!,
      ),
  });
};

export const useCreatePackageMutation = defineMutation(() => {
  const data = ref<{
    name: string;
    items: PackageItem[];
    price: number;
    vat: number;
  }>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => createPackage(data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["packages"] });
    },
  });

  return { mutate, ...mutation, data };
});

export const useUpdatePackageMutation = defineMutation(() => {
  const packageId = ref<string>();
  const data = ref<{
    name: string;
    price: number;
    vat: number;
    edition?: number;
  }>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updatePackage(packageId.value!, data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["packages"] });
      if (packageId.value)
        queryCache.invalidateQueries({ key: ["package", packageId.value] });
    },
  });

  return { mutate, ...mutation, packageId, data };
});

export const useDeletePackageMutation = defineMutation(() => {
  const packageId = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => deletePackage(packageId.value!),
    onSettled: () => queryCache.invalidateQueries({ key: ["packages"] }),
  });

  return { mutate, ...mutation, packageId };
});

export const useUpdatePackageItemsMutation = defineMutation(() => {
  const packageId = ref<string>();
  const items = ref<{ item: string; quantity: number }[]>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      updatePackageItems(packageId.value!, { items: items.value || [] }),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["packages"] });
      if (packageId.value)
        queryCache.invalidateQueries({ key: ["package", packageId.value] });
    },
  });

  return { mutate, ...mutation, packageId, items };
});
