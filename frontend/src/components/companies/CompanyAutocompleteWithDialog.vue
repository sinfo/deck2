<template>
  <div>
    <!-- Company Autocomplete -->
    <CompanyAutocomplete
      :model-value="modelValue"
      :label="label"
      :placeholder="placeholder"
      :disabled="disabled"
      :event-id="eventId"
      show-create
      @selected="(company: Company) => $emit('selected', company)"
      @update:model-value="(value: string) => $emit('update:modelValue', value)"
      @create-company="handleCreateCompany"
    />

    <!-- Create Company Dialog -->
    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>Create New Company</AlertDialogTitle>
            <AlertDialogDescription>
              Fill out the information below to create a new company.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateCompanyForm
              :initial-company-name="searchTerm"
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
import CompanyAutocomplete from "./CompanyAutocomplete.vue";
import CreateCompanyForm from "./CreateCompanyForm.vue";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import type { Company } from "@/dto/companies";

interface Props {
  modelValue?: string;
  label?: string;
  placeholder?: string;
  disabled?: boolean;
  eventId?: number;
}

defineProps<Props>();

const emit = defineEmits<{
  selected: [value: Company];
  "update:modelValue": [value: string];
  success: [companyId: string];
}>();

const isDialogOpen = ref(false);
const searchTerm = ref("");

const handleCreateCompany = (term: string) => {
  searchTerm.value = term;
  isDialogOpen.value = true;
};

const handleCancel = () => {
  isDialogOpen.value = false;
  searchTerm.value = ""; // Clear search term when dialog is closed
};

const handleSuccess = (companyId: string) => {
  isDialogOpen.value = false;
  searchTerm.value = ""; // Clear search term when dialog is closed
  emit("success", companyId);
};
</script>
