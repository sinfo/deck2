import {
  defineMutation,
  useMutation,
  useQuery,
  useQueryCache,
} from "@pinia/colada";
import { ref } from "vue";
import {
  createItem,
  updateItem,
  getItemCategories,
  createItemCategory,
  updateItemCategory,
} from "@/api/items";

type CreateItemApiPayload = {
  name: string;
  type: string;
  description: string;
  price: number;
  vat: number;
};

type UpdateItemApiPayload = CreateItemApiPayload;

export const useCreateItemMutation = defineMutation(() => {
  const data = ref<CreateItemApiPayload>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => createItem(data.value as CreateItemApiPayload),
    onSettled: () => {
      // invalidate items and any views that depend on them
      queryCache.invalidateQueries({ key: ["items"] });
      queryCache.invalidateQueries({ key: ["packages"] });
    },
  });

  return {
    mutate,
    ...mutation,
    data,
  };
});

export const useUpdateItemMutation = defineMutation(() => {
  const itemId = ref<string>();
  const data = ref<UpdateItemApiPayload>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () =>
      updateItem(itemId.value!, data.value as UpdateItemApiPayload),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["items"] });
      queryCache.invalidateQueries({ key: ["packages"] });
    },
  });

  return {
    mutate,
    ...mutation,
    itemId,
    data,
  };
});

export const useCreateItemCategoryMutation = defineMutation(() => {
  const name = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => createItemCategory(name.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["item-categories"] });
    },
  });

  return {
    mutate,
    ...mutation,
    name,
  };
});

export const useUpdateItemCategoryMutation = defineMutation(() => {
  const id = ref<string>();
  const name = ref<string>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updateItemCategory(id.value!, { name: name.value! }),
    onSettled: () => queryCache.invalidateQueries({ key: ["item-categories"] }),
  });

  return {
    mutate,
    ...mutation,
    id,
    name,
  };
});

export const useItemCategoriesQuery = (enabled = true) =>
  useQuery({
    key: ["item-categories"],
    query: () => getItemCategories(),
    enabled: () => enabled,
  });
