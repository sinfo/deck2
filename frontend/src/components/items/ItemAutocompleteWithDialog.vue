<template>
  <div>
    <ItemAutocomplete
      :model-value="modelValue"
      :label="label"
      :placeholder="placeholder"
      :disabled="disabled"
      show-create
      @selected="(item) => $emit('selected', item)"
      @update:model-value="(value: string) => $emit('update:modelValue', value)"
      @create-item="handleCreateItem"
    />

    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateItemForm
              :initial-item-name="searchTerm"
              header-title="Create New Item"
              @cancel="handleCancel"
              @success="handleSuccess"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import ItemAutocomplete from "./ItemAutocomplete.vue";
import CreateItemForm from "./CreateItemForm.vue";
import { AlertDialog, AlertDialogContent } from "@/components/ui/alert-dialog";
import type { Item } from "@/dto/item";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
}

defineProps<Props>();

const emit = defineEmits<{
  selected: [value: Item];
  "update:modelValue": [value: string];
  success: [itemId: string];
}>();

const isDialogOpen = ref(false);
const searchTerm = ref("");

const handleCreateItem = (term: string) => {
  searchTerm.value = term;
  isDialogOpen.value = true;
};

const handleCancel = () => {
  isDialogOpen.value = false;
  searchTerm.value = "";
};

const handleSuccess = (itemId: string) => {
  isDialogOpen.value = false;
  searchTerm.value = "";
  // set the autocomplete value so parent (e.g., forms) receive the new item id
  emit("update:modelValue", itemId);
  emit("success", itemId);
};
</script>
