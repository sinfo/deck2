<template>
  <div class="space-y-3">
    <div>
      <h3 class="text-sm font-medium">Company Status</h3>
      <p class="text-xs text-muted-foreground">
        Mark the company as bankrupt or banned. Changes are saved immediately.
      </p>
    </div>

    <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
      <div class="space-y-2">
        <Label for="closure-type" class="text-sm font-medium">Status</Label>
        <NativeSelect
          id="closure-type"
          v-model="selectedType"
          class="w-full"
          :disabled="isLoading"
          @change="handleTypeChange"
        >
          <option value="">Operating</option>
          <option
            v-for="(label, type) in companyClosureLabels"
            :key="type"
            :value="type"
          >
            {{ label }}
          </option>
        </NativeSelect>
      </div>

      <div v-if="selectedType" class="space-y-2">
        <Label for="closure-since" class="text-sm font-medium">Since</Label>
        <Input
          id="closure-since"
          type="date"
          :model-value="toDateInputValue(company.closure?.since)"
          :disabled="isLoading"
          @change="handleDateChange"
        />
      </div>
    </div>

    <p v-if="errorMessage" class="text-xs text-destructive">
      {{ errorMessage }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import {
  companyClosureLabels,
  type Company,
  type CompanyClosureType,
} from "@/dto/companies";
import { useCompanyClosureMutation } from "@/mutations/companies";
import { fromDateInputValue, toDateInputValue } from "@/lib/utils";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";
import { NativeSelect } from "../ui/native-select";

const props = defineProps<{
  company: Company;
}>();

const closureType = computed<CompanyClosureType | "">(
  () => props.company.closure?.type ?? "",
);

// Local copy for the select, kept in sync with the saved value.
const selectedType = ref<CompanyClosureType | "">(closureType.value);
watch(closureType, (type) => (selectedType.value = type));

const errorMessage = ref("");

const { mutateAsync: saveClosure, isLoading } = useCompanyClosureMutation();

const save = async (type: CompanyClosureType | "", since?: string) => {
  errorMessage.value = "";

  try {
    await saveClosure({
      companyId: props.company.id,
      closure: type ? { type, since } : null,
    });
  } catch {
    errorMessage.value = "Could not update the company status.";
  }
};

// Reads the value from the event: this handler can run before v-model updates selectedType.
const handleTypeChange = (event: Event) => {
  const type = (event.target as HTMLSelectElement).value as
    | CompanyClosureType
    | "";
  save(type, props.company.closure?.since);
};

const handleDateChange = (event: Event) => {
  const value = (event.target as HTMLInputElement).value;
  save(closureType.value, fromDateInputValue(value) ?? undefined);
};
</script>
