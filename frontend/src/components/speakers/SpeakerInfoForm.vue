<template>
  <div class="flex flex-col h-full">
    <!-- Form Content -->
    <div class="flex-1 space-y-6">
      <!-- Speaker Name Field -->
      <div class="space-y-2">
        <Label for="speaker-name" class="text-sm font-medium"
          >Speaker Name *</Label
        >
        <Input
          id="speaker-name"
          v-model="formData.name"
          placeholder="Enter speaker name"
          :disabled="isLoading"
          required
        />
      </div>

      <!-- Title Field -->
      <div class="space-y-2">
        <Label for="speaker-title" class="text-sm font-medium">Title</Label>
        <Input
          id="speaker-title"
          v-model="formData.title"
          placeholder="Enter speaker title"
          :disabled="isLoading"
        />
      </div>

      <!-- Company Name Field -->
      <div class="space-y-2">
        <Label for="speaker-company" class="text-sm font-medium">Company</Label>
        <Input
          id="speaker-company"
          v-model="formData.companyName"
          placeholder="Enter company name"
          :disabled="isLoading"
        />
      </div>

      <!-- Bio Field -->
      <div class="space-y-2">
        <Label for="speaker-bio" class="text-sm font-medium">Biography</Label>
        <textarea
          id="speaker-bio"
          v-model="formData.bio"
          placeholder="Enter speaker biography"
          :disabled="isLoading"
          rows="4"
          class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
      </div>

      <!-- Image Upload Field -->
      <div class="space-y-2">
        <Label for="speaker-image" class="text-sm font-medium"
          >Speaker Image</Label
        >
        <Input
          id="speaker-image"
          type="file"
          accept="image/*"
          @change="handleImageChange"
          :disabled="isLoading"
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
              alt="Speaker image preview"
              class="w-full h-full object-cover"
            />
          </div>
        </div>
      </div>

      <!-- Notes Field -->
      <div class="space-y-2">
        <Label for="speaker-notes" class="text-sm font-medium">Notes</Label>
        <textarea
          id="speaker-notes"
          v-model="formData.notes"
          placeholder="Enter internal notes"
          :disabled="isLoading"
          rows="3"
          class="flex min-h-[60px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        />
      </div>
    </div>

    <!-- Form Actions -->
    <div class="flex justify-end gap-3 pt-6 border-t">
      <Button variant="outline" @click="$emit('cancel')" :disabled="isLoading">
        Cancel
      </Button>
      <Button
        @click="handleSubmit"
        :disabled="!isValid || isLoading"
        :loading="isLoading"
      >
        {{ mode === "edit" ? "Update" : "Save" }} Speaker
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch, ref } from "vue";
import type { UpdateSpeakerData } from "@/dto/speakers";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";

interface Props {
  isLoading?: boolean;
  mode?: "create" | "edit";
  initialData?: Pick<
    UpdateSpeakerData,
    "name" | "title" | "bio" | "companyName" | "notes"
  >;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
});

const emit = defineEmits<{
  submit: [
    data: Pick<
      UpdateSpeakerData,
      "name" | "title" | "bio" | "companyName" | "notes"
    >,
  ];
  cancel: [];
  imageSelected: [file: File];
}>();

// Image handling
const imagePreview = ref<string>("");
const selectedImageFile = ref<File | null>(null);
const errors = ref<Record<string, string>>({});

const formData = reactive<
  Pick<UpdateSpeakerData, "name" | "title" | "bio" | "companyName" | "notes">
>({
  name: "",
  title: "",
  bio: "",
  companyName: "",
  notes: "",
});

// Initialize form data when in edit mode or when initial data changes
watch(
  () => props.initialData,
  (newData) => {
    if (newData) {
      formData.name = newData.name || "";
      formData.title = newData.title || "";
      formData.bio = newData.bio || "";
      formData.companyName = newData.companyName || "";
      formData.notes = newData.notes || "";
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
      title: formData.title?.trim() || "",
      bio: formData.bio?.trim() || "",
      companyName: formData.companyName?.trim() || "",
      notes: formData.notes?.trim() || "",
    });
  }
};
</script>
