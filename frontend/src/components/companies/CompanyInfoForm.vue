<template>
  <div class="flex flex-col h-full">
    <!-- Form Content -->
    <div class="flex-1 space-y-6">
      <!-- Company Name Field -->
      <div class="space-y-2">
        <Label for="company-name" class="text-sm font-medium"
          >Company Name *</Label
        >
        <Input
          id="company-name"
          v-model="formData.name"
          placeholder="Enter company name"
          :disabled="isLoading"
          required
        />
      </div>

      <!-- Description Field -->
      <div class="space-y-2">
        <Label for="company-description" class="text-sm font-medium"
          >Description</Label
        >
        <textarea
          id="company-description"
          v-model="formData.description"
          placeholder="Enter company description"
          :disabled="isLoading"
          rows="4"
          class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
      </div>

      <!-- Website Field -->
      <div class="space-y-2">
        <Label for="company-site" class="text-sm font-medium">Website</Label>
        <Input
          id="company-site"
          v-model="formData.site"
          placeholder="https://example.com"
          type="url"
          :disabled="isLoading"
        />
      </div>

      <!-- LinkedIn Field -->
      <div class="space-y-2">
        <Label for="company-linkedin" class="text-sm font-medium"
          >LinkedIn</Label
        >
        <Input
          id="company-linkedin"
          v-model="formData.linkedin"
          placeholder="username or profile URL"
          type="text"
          :disabled="isLoading"
        />
      </div>

      <!-- Image Upload Field -->
      <ImageUpload
        label="Company Logo"
        input-id="company-logo"
        url-placeholder="https://example.com/logo.jpg"
        preview-alt="Company logo preview"
        preview-size="sm"
        :disabled="isLoading"
        @file-selected="handleImageSelected"
      />
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
        {{ mode === "edit" ? "Update" : "Save" }} Company
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from "vue";
import type { UpdateCompanyData } from "@/dto/companies";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";
import ImageUpload from "@/components/ImageUpload.vue";

interface Props {
  isLoading?: boolean;
  mode?: "create" | "edit";
  initialData?: Pick<
    UpdateCompanyData,
    "name" | "description" | "site" | "linkedin"
  >;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
  initialData: undefined,
});

const emit = defineEmits<{
  submit: [
    data: Pick<UpdateCompanyData, "name" | "description" | "site" | "linkedin">,
  ];
  cancel: [];
  imageSelected: [file: File];
}>();

// Handle image selection from ImageUpload component
const handleImageSelected = (file: File) => {
  emit("imageSelected", file);
};

const formData = reactive<
  Pick<UpdateCompanyData, "name" | "description" | "site" | "linkedin">
>({
  name: "",
  description: "",
  site: "",
  linkedin: "",
});

// Initialize form data when in edit mode or when initial data changes
watch(
  () => props.initialData,
  (newData) => {
    if (newData) {
      formData.name = newData.name || "";
      formData.description = newData.description || "";
      formData.site = newData.site || "";
      formData.linkedin = newData.linkedin || "";
    }
  },
  { immediate: true },
);

const isValid = computed(() => {
  return formData.name?.trim();
});

const handleSubmit = () => {
  if (isValid.value) {
    emit("submit", {
      name: formData.name?.trim() || undefined,
      description: formData.description?.trim() || "",
      site: formData.site?.trim() || "",
      linkedin: formData.linkedin?.trim() || "",
    });
  }
};
</script>
