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
import type { Package, PackageItem } from "@/dto/packages";
import { useEventStore } from "@/stores/event";
import { computed } from "vue";

// Shared packages list query
export const usePackagesQuery = (params?: Record<string, unknown>) =>
  useQuery({
    key: ["packages", params ? JSON.stringify(params) : ""],
    query: () => getPackages(params),
  });

// Extract "SINFO XX" event prefix from package name
const extractEventName = (name: string) => {
  const match = name.match(/^(SINFO\s*\d+)\s*/i);
  return match ? match[1] : "";
};

// Remove "SINFO XX " prefix from package name
const formatPackageName = (name: string) => {
  return name.replace(/^SINFO\s*\d+\s*/i, "").trim();
};

// Packages query filtered by current event
export const useEventPackagesQuery = () => {
  const eventStore = useEventStore();
  const eventName = computed(() => eventStore.selectedEvent?.name || "");

  const query = useQuery({
    key: () => ["packages", "event", eventName.value],
    query: () => getPackages(),
  });

  const data = computed(() => {
    if (!query.data.value || !eventName.value) return [];
    return (query.data.value as Package[])
      .filter((p) => String(p.name || "").startsWith(eventName.value))
      .map((p) => ({
        ...p,
        name: formatPackageName(p.name),
        event: extractEventName(p.name),
      }));
  });

  return {
    ...query,
    data,
  };
};

// Single package query by id
export const usePackageQuery = (
  id: string | Ref<string | null | undefined> | null | undefined,
) => {
  const isRef = (v: unknown): v is Ref<string | null | undefined> =>
    typeof v === "object" &&
    v !== null &&
    (v as Record<string, unknown>) &&
    "value" in (v as Record<string, unknown>);

  const query = useQuery({
    key: () => [
      "package",
      isRef(id) ? (id as Ref<string | null | undefined>).value || "" : id || "",
    ],
    enabled: () =>
      isRef(id) ? !!(id as Ref<string | null | undefined>).value : !!id,
    query: async () => {
      const pkg = await getPackageById(
        isRef(id)
          ? (id as Ref<string | null | undefined>).value!
          : (id as string)!,
      );
      // Format the package name to remove "SINFO XX " prefix
      return {
        ...pkg,
        name: formatPackageName(pkg.name),
        event: extractEventName(pkg.name),
      };
    },
  });

  return query;
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
