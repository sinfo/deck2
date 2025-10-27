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

      <!-- Image Upload Field -->
      <div class="space-y-2">
        <Label for="company-image" class="text-sm font-medium"
          >Company Logo</Label
        >
        <Input
          id="company-image"
          type="file"
          accept="image/*"
          :disabled="isLoading"
          @change="handleImageChange"
        />
        <p class="text-xs text-muted-foreground">
          Recommended: Square image, minimum 256x256px, max 10MB
        </p>
        <span v-if="errors.image" class="text-sm text-destructive">{{
          errors.image
        }}</span>

        <!-- Image preview -->
        <div v-if="imagePreview" class="space-y-2">
          <Label class="text-sm font-medium">Preview</Label>
          <div class="w-20 h-20 border border-muted rounded-lg overflow-hidden">
            <img
              :src="imagePreview"
              alt="Company logo preview"
              class="w-full h-full object-cover"
            />
          </div>
        </div>
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
        {{ mode === "edit" ? "Update" : "Save" }} Company
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch, ref } from "vue";
import type { UpdateCompanyData } from "@/dto/companies";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";

interface Props {
  isLoading?: boolean;
  mode?: "create" | "edit";
  initialData?: Pick<UpdateCompanyData, "name" | "description" | "site">;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
  initialData: undefined,
});

const emit = defineEmits<{
  submit: [data: Pick<UpdateCompanyData, "name" | "description" | "site">];
  cancel: [];
  imageSelected: [file: File];
}>();

// Image handling
const imagePreview = ref<string>("");
const selectedImageFile = ref<File | null>(null);
const errors = ref<Record<string, string>>({});

const formData = reactive<
  Pick<UpdateCompanyData, "name" | "description" | "site">
>({
  name: "",
  description: "",
  site: "",
});

// Initialize form data when in edit mode or when initial data changes
watch(
  () => props.initialData,
  (newData) => {
    if (newData) {
      formData.name = newData.name || "";
      formData.description = newData.description || "";
      formData.site = newData.site || "";
    }
  },
  { immediate: true },
);

const isValid = computed(() => {
  return formData.name?.trim();
});

// Image handling
const handleImageChange = (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (file) {
    // Check file size (10MB limit)
    if (file.size > 10 << 20) {
      errors.value.image = "Image file size must be less than 10MB";
      return;
    }

    // Clear any previous image errors
    delete errors.value.image;

    selectedImageFile.value = file;

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview.value = e.target?.result as string;
    };
    reader.readAsDataURL(file);

    // Emit the selected file to parent component
    emit("imageSelected", file);
  }
};

const handleSubmit = () => {
  if (isValid.value) {
    emit("submit", {
      name: formData.name?.trim() || undefined,
      description: formData.description?.trim() || "",
      site: formData.site?.trim() || "",
    });
  }
};
</script>
