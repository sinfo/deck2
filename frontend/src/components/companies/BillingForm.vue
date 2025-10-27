<template>
  <div class="flex flex-col h-full">
    <!-- Form Content -->
    <div class="flex-1 space-y-6">
      <!-- Company Name Field -->
      <div class="space-y-2">
        <Label for="billing-name" class="text-sm font-medium"
          >Company Name *</Label
        >
        <Input
          id="billing-name"
          v-model="formData.name"
          placeholder="Enter company name for billing"
          :disabled="isLoading"
          required
        />
      </div>

      <!-- Address Field -->
      <div class="space-y-2">
        <Label for="billing-address" class="text-sm font-medium"
          >Address *</Label
        >
        <Input
          id="billing-address"
          v-model="formData.address"
          placeholder="Enter billing address"
          :disabled="isLoading"
          required
        />
      </div>

      <!-- TIN Field -->
      <div class="space-y-2">
        <Label for="billing-tin" class="text-sm font-medium"
          >Tax Identification Number (TIN) *</Label
        >
        <Input
          id="billing-tin"
          v-model="formData.tin"
          placeholder="Enter TIN"
          :disabled="isLoading"
          required
        />
      </div>
    </div>

    <!-- Form Actions -->
    <div class="flex justify-end gap-3 pt-6 border-t">
      <Button variant="outline" :disabled="isLoading" @click="$emit('cancel')">
        Cancel
      </Button>
      <Button
        :disabled="!isValid || isLoading"
        :loading="isLoading"
        @click="handleSubmit"
      >
        {{ mode === "edit" ? "Update" : "Save" }} Billing Info
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from "vue";
import type { CompanyBillingInfo } from "@/dto/companies";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";

interface Props {
  isLoading?: boolean;
  mode?: "create" | "edit";
  initialData?: CompanyBillingInfo;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
  initialData: undefined,
});

const emit = defineEmits<{
  submit: [data: CompanyBillingInfo];
  cancel: [];
}>();

const formData = reactive<CompanyBillingInfo>({
  name: "",
  address: "",
  tin: "",
});

// Initialize form data when in edit mode or when initial data changes
watch(
  () => props.initialData,
  (newData) => {
    if (newData) {
      formData.name = newData.name;
      formData.address = newData.address;
      formData.tin = newData.tin;
    }
  },
  { immediate: true },
);

const isValid = computed(() => {
  return (
    formData.name?.trim() && formData.address?.trim() && formData.tin?.trim()
  );
});

const handleSubmit = () => {
  if (isValid.value) {
    emit("submit", { ...formData });
  }
};
</script>
