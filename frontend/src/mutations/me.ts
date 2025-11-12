import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import { uploadMyImage } from "@/api/me.ts";
import type { CreateContactData } from "@/dto/contacts.ts";
import { updateContact } from "@/api/contacts.ts";
import { ref } from "vue";

export const useUploadImageMutation = defineMutation(() => {
  const file = ref<File>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => uploadMyImage(file.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["me"] });
    },
  });

  return {
    mutate,
    ...mutation,
    file,
  };
});

export const useUpdateContactMutation = defineMutation(() => {
  const contactId = ref<string>();
  const data = ref<CreateContactData>();
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => updateContact(contactId.value!, data.value!),
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["me"] });
    },
  });

  return {
    mutate,
    ...mutation,
    contactId,
    data,
  };
});
