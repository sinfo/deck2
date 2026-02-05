<template>
  <div
    v-if="isDeleteConfirmOpen"
    class="fixed inset-0 bg-black/20 z-40 transition-opacity duration-200"
    @click="isDeleteConfirmOpen = false"
  ></div>
  <Card class="w-full hover:shadow-lg transition-shadow duration-200">
    <CardHeader>
      <div class="flex items-center justify-between mb-4">
        <CardTitle class="text-lg">Speaker Information</CardTitle>
        <div class="flex items-center gap-2">
          <Button
            v-if="!isEditing"
            variant="outline"
            size="sm"
            :disabled="isUpdating"
            @click="startEditing"
          >
            Edit
          </Button>
          <Popover v-if="canDelete" v-model:open="isDeleteConfirmOpen">
            <PopoverTrigger as-child>
              <Button
                variant="outline"
                size="sm"
                :disabled="isDeleting"
                class="h-6 w-6 p-0 text-destructive hover:text-destructive"
                aria-label="Delete speaker"
                :title="isDeleting ? 'Deleting...' : 'Delete speaker'"
              >
                <TrashIcon class="w-4 h-4" />
              </Button>
            </PopoverTrigger>
            <PopoverContent class="w-80 z-50">
              <ConfirmDelete
                title="Delete Speaker"
                :message="`Are you sure you want to delete ${speaker.name}? This action cannot be undone.`"
                :is-deleting="isDeleting"
                @cancel="isDeleteConfirmOpen = false"
                @confirm="handleDelete"
              />
            </PopoverContent>
          </Popover>
        </div>
      </div>

      <!-- Editing Form -->
      <div v-if="isEditing">
        <SpeakerInfoForm
          :initial-data="{
            name: speaker.name,
            title: speaker.title,
            bio: speaker.bio,
            companyName: speaker.companyName,
            notes: speaker.notes,
          }"
          :is-loading="isUpdating || isUploadingImage"
          mode="edit"
          @submit="handleSubmit"
          @cancel="cancelEditing"
          @image-selected="handleImageSelected"
        />
      </div>

      <!-- Display Mode -->
      <div v-else class="flex flex-col sm:flex-row items-start gap-4">
        <div class="flex-shrink-0 mx-auto sm:mx-0">
          <Image
            :src="
              speaker.imgs?.internal ||
              speaker.imgs?.speaker ||
              speaker.imgs?.company
            "
            :alt="`${speaker.name} photo`"
            class="w-20 h-20 sm:w-24 sm:h-24 object-cover rounded-lg border"
          />
        </div>
        <div class="flex-1 min-w-0">
          <CardTitle class="text-lg truncate">{{ speaker.name }}</CardTitle>
          <div class="text-sm text-muted-foreground mb-2">
            {{ speaker.title }}
          </div>
          <div class="flex flex-wrap gap-1 mt-2">
            <Badge v-if="speaker.companyName">{{ speaker.companyName }}</Badge>
          </div>
        </div>
      </div>
    </CardHeader>

    <CardContent v-if="!isEditing" class="space-y-3">
      <div v-if="speaker.bio" class="relative">
        <CardDescription
          :class="[
            'transition-all duration-300 ease-in-out whitespace-pre-wrap',
            isBioExpanded ? '' : 'line-clamp-3',
          ]"
        >
          {{ speaker.bio }}
        </CardDescription>

        <button
          v-if="shouldShowToggle"
          class="text-primary hover:underline text-xs mt-1 focus:outline-none"
          @click="toggleBio"
        >
          {{ isBioExpanded ? "Show less" : "Show more" }}
        </button>
      </div>

      <div v-if="speaker.notes" class="space-y-2 text-sm">
        <div class="flex items-start gap-2">
          <span class="text-muted-foreground">Notes:</span>
          <span class="text-sm whitespace-pre-wrap">{{ speaker.notes }}</span>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import type {
  SpeakerWithParticipation,
  UpdateSpeakerData,
} from "@/dto/speakers";
import { useSpeakerInfoMutation } from "@/mutations/speakers";
import { useSpeakerImageUploadMutation } from "@/mutations/speakers";
import { deleteSpeaker } from "@/api/speakers";
import { useQueryCache } from "@pinia/colada";
import { useRouter } from "vue-router";
import Card from "../ui/card/Card.vue";
import CardContent from "../ui/card/CardContent.vue";
import CardDescription from "../ui/card/CardDescription.vue";
import CardHeader from "../ui/card/CardHeader.vue";
import CardTitle from "../ui/card/CardTitle.vue";
import Badge from "../ui/badge/Badge.vue";
import Button from "../ui/button/Button.vue";
import Image from "../Image.vue";
import SpeakerInfoForm from "../speakers/SpeakerInfoForm.vue";
import { Popover, PopoverContent, PopoverTrigger } from "../ui/popover";
import { TrashIcon } from "lucide-vue-next";
import ConfirmDelete from "@/components/ConfirmDelete.vue";
import { usePermissions } from "@/composables/usePermissions";

const props = defineProps<{
  speaker: SpeakerWithParticipation;
}>();

const emit = defineEmits<{
  updated: [];
  deleted: [];
}>();

const isBioExpanded = ref(false);
const isEditing = ref(false);
const isDeleteConfirmOpen = ref(false);
const isDeleting = ref(false);
const { isCoordinatorOrAdmin } = usePermissions();
const queryCache = useQueryCache();
const router = useRouter();

const navigateBackWithReload = (fallback: string) => {
  try {
    if (window.history.length > 1) {
      router.back();
      setTimeout(() => window.location.reload(), 50);
    } else {
      router.push(fallback).then(() => window.location.reload());
    }
  } catch {
    router.push(fallback).then(() => window.location.reload());
  }
};

const speakerInfoMutation = useSpeakerInfoMutation();
const { mutate: updateSpeakerInfo, isLoading: isUpdating } =
  speakerInfoMutation;

const speakerImageMutation = useSpeakerImageUploadMutation();
const { mutate: uploadSpeakerImage, isLoading: isUploadingImage } =
  speakerImageMutation;

// Store selected image file for upload
const selectedImageFile = ref<File | null>(null);

const startEditing = () => {
  isEditing.value = true;
};

const cancelEditing = () => {
  isEditing.value = false;
  selectedImageFile.value = null; // Reset image selection when canceling
};

const handleImageSelected = (file: File) => {
  selectedImageFile.value = file;
};

const handleSubmit = async (
  data: Pick<
    UpdateSpeakerData,
    "name" | "title" | "bio" | "companyName" | "notes"
  >,
) => {
  if (!props.speaker?.id) return;

  speakerInfoMutation.speakerId.value = props.speaker.id;
  speakerInfoMutation.speakerData.value = data;

  try {
    // Update speaker info first
    await updateSpeakerInfo();

    // Upload image if one was selected
    if (selectedImageFile.value) {
      const imageFormData = new FormData();
      imageFormData.append("image", selectedImageFile.value);

      speakerImageMutation.speakerId.value = props.speaker.id;
      speakerImageMutation.imageData.value = imageFormData;

      await uploadSpeakerImage();
    }

    isEditing.value = false;
    selectedImageFile.value = null; // Reset image selection
    emit("updated");
  } catch (error) {
    console.error("Failed to update speaker information:", error);
    // You might want to show a toast notification here
  }
};

const shouldShowToggle = computed(() => {
  if (!props.speaker.bio) return false;
  // Simple heuristic: show toggle if bio is longer than 150 characters
  return props.speaker.bio.length > 150;
});

const toggleBio = () => {
  isBioExpanded.value = !isBioExpanded.value;
};

const canDelete = computed(() => {
  return isCoordinatorOrAdmin.value === true;
});

const handleDelete = async () => {
  if (!props.speaker?.id) return;
  isDeleting.value = true;
  try {
    await deleteSpeaker(props.speaker.id);
    // Invalidate cache and navigate to list
    queryCache.invalidateQueries({ key: ["speakers"] });
    navigateBackWithReload("/speakers");
    emit("deleted");
  } catch (error) {
    console.error("Error deleting speaker:", error);
  } finally {
    isDeleting.value = false;
    isDeleteConfirmOpen.value = false;
  }
};
</script>

<style scoped>
.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
