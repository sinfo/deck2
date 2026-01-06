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
        <Tabs v-model="imageInputMode" class="w-full">
          <TabsList class="grid w-full grid-cols-2">
            <TabsTrigger value="file">Upload File</TabsTrigger>
            <TabsTrigger value="url">From URL</TabsTrigger>
          </TabsList>
          <TabsContent value="file" class="space-y-2">
            <Input
              id="speaker-image"
              type="file"
              accept="image/*"
              :disabled="isLoading"
              @change="handleImageChange"
            />
            <p class="text-xs text-muted-foreground">
              Recommended: Square image, minimum 256x256px, max 10MB
            </p>
          </TabsContent>
          <TabsContent value="url" class="space-y-2">
            <Input
              id="imageUrl"
              v-model="imageUrl"
              type="url"
              placeholder="https://example.com/image.jpg"
              :disabled="isLoading || isLoadingImageUrl"
              @blur="handleImageUrlChange"
              @keyup.enter="handleImageUrlChange"
            />
            <p class="text-xs text-muted-foreground">
              Enter the URL of an image to use
            </p>
            <p
              v-if="isLoadingImageUrl"
              class="text-xs text-muted-foreground flex items-center gap-1"
            >
              Loading image...
            </p>
          </TabsContent>
        </Tabs>
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
      <Button variant="outline" :disabled="isLoading" @click="$emit('cancel')">
        Cancel
      </Button>
      <Button
        :disabled="!isValid || isLoading"
        :loading="isLoading"
        @click="handleSubmit"
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

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
  initialData: undefined,
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
const imageInputMode = ref<string>("file");
const imageUrl = ref<string>("");
const isLoadingImageUrl = ref<boolean>(false);

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

// Handle image URL input
const handleImageUrlChange = async () => {
  const url = imageUrl.value.trim();
  if (!url) {
    return;
  }

  // Validate URL format
  try {
    new URL(url);
  } catch {
    errors.value.image = "Please enter a valid URL";
    return;
  }

  isLoadingImageUrl.value = true;
  delete errors.value.image;

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error("Failed to fetch image");
    }

    const contentType = response.headers.get("content-type");
    if (!contentType || !contentType.startsWith("image/")) {
      throw new Error("URL does not point to a valid image");
    }

    const blob = await response.blob();

    // Check file size (10MB limit)
    if (blob.size > 10 << 20) {
      errors.value.image = "Image file size must be less than 10MB";
      return;
    }

    // Extract filename from URL or use a default
    const urlPath = new URL(url).pathname;
    const filename = urlPath.split("/").pop() || "image";
    const extension = contentType.split("/")[1] || "png";
    const finalFilename = filename.includes(".")
      ? filename
      : `${filename}.${extension}`;

    // Create a File object from the blob
    const file = new File([blob], finalFilename, { type: contentType });
    selectedImageFile.value = file;

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      imagePreview.value = e.target?.result as string;
    };
    reader.readAsDataURL(blob);

    // Emit the selected file to parent component
    emit("imageSelected", file);
  } catch (error) {
    console.error("Error fetching image from URL:", error);
    errors.value.image =
      "Failed to load image from URL. Please check the URL and try again.";
  } finally {
    isLoadingImageUrl.value = false;
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
