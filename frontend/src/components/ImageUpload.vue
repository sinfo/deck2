<template>
  <div class="space-y-2">
    <Label v-if="label" class="text-sm font-medium">{{ label }}</Label>
    <Tabs v-model="imageInputMode" class="w-full">
      <TabsList class="grid w-full grid-cols-2">
        <TabsTrigger value="file">Upload File</TabsTrigger>
        <TabsTrigger value="url">From URL</TabsTrigger>
      </TabsList>
      <TabsContent value="file" class="space-y-2">
        <Input
          :id="inputId"
          type="file"
          accept="image/*"
          :disabled="disabled"
          @change="handleFileChange"
        />
        <p class="text-xs text-muted-foreground">
          Recommended: Square image, minimum 256x256px, max 10MB
        </p>
      </TabsContent>
      <TabsContent value="url" class="space-y-2">
        <Input
          :id="`${inputId}-url`"
          v-model="imageUrl"
          type="url"
          :placeholder="urlPlaceholder"
          :disabled="disabled || isLoadingImageUrl"
          @blur="handleUrlChange"
          @keyup.enter="handleUrlChange"
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
    <span v-if="imageError" class="text-sm text-destructive">{{
      imageError
    }}</span>

    <!-- Image preview -->
    <div v-if="imagePreview" class="space-y-2">
      <Label class="text-sm font-medium">Preview</Label>
      <div
        :class="[
          'border border-muted rounded-lg overflow-hidden',
          previewSizeClass,
        ]"
      >
        <img
          :src="imagePreview"
          :alt="previewAlt"
          class="w-full h-full object-cover"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { watch } from "vue";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useImageUpload } from "@/composables/useImageUpload";

interface Props {
  label?: string;
  inputId?: string;
  urlPlaceholder?: string;
  previewAlt?: string;
  previewSize?: "sm" | "md";
  disabled?: boolean;
  initialUrl?: string;
}

const props = withDefaults(defineProps<Props>(), {
  label: undefined,
  inputId: "image-upload",
  urlPlaceholder: "https://example.com/image.jpg",
  previewAlt: "Image preview",
  previewSize: "md",
  disabled: false,
  initialUrl: undefined,
});

const emit = defineEmits<{
  fileSelected: [file: File];
}>();

const {
  imagePreview,
  selectedImageFile,
  imageInputMode,
  imageUrl,
  isLoadingImageUrl,
  imageError,
  handleFileChange,
  handleUrlChange,
} = useImageUpload();

// Seed the preview from the prop if no new file has been chosen yet
if (props.initialUrl) {
  imagePreview.value = props.initialUrl;
}

const previewSizeClass = props.previewSize === "sm" ? "w-20 h-20" : "w-24 h-24";

// Emit the selected file when it changes
watch(selectedImageFile, (file) => {
  if (file) {
    emit("fileSelected", file);
  }
});

// Expose state and methods to parent
defineExpose({
  imagePreview,
  selectedImageFile,
  isLoadingImageUrl,
  imageError,
});
</script>
