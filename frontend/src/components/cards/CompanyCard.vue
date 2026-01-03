<template>
  <div
    v-if="isDeleteConfirmOpen"
    class="fixed inset-0 bg-black/20 z-40 transition-opacity duration-200"
    @click="isDeleteConfirmOpen = false"
  ></div>
  <Card class="w-full hover:shadow-lg transition-shadow duration-200">
    <CardHeader>
      <div class="flex items-center justify-between mb-4">
        <CardTitle class="text-lg">Company Information</CardTitle>
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
                aria-label="Delete company"
                :title="isDeleting ? 'Deleting...' : 'Delete company'"
              >
                <TrashIcon class="w-4 h-4" />
              </Button>
            </PopoverTrigger>
            <PopoverContent class="w-80 z-50">
              <ConfirmDelete
                title="Delete Company"
                :message="`Are you sure you want to delete ${company.name}? This action cannot be undone.`"
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
        <CompanyInfoForm
          :initial-data="{
            name: company.name,
            description: company.description,
            site: company.site,
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
            :src="company.imgs?.internal || company.imgs?.public"
            :alt="`${company.name} logo`"
            class="w-20 h-20 sm:w-24 sm:h-24 object-contain rounded-lg border"
          />
        </div>
        <div class="flex-1 min-w-0">
          <CardTitle class="text-lg truncate">{{ company.name }}</CardTitle>
          <div class="flex flex-wrap gap-1 mt-2">
            <Badge v-if="company.participation?.partner" variant="secondary">
              Partner
            </Badge>
          </div>
        </div>
      </div>
    </CardHeader>

    <CardContent v-if="!isEditing" class="space-y-3">
      <div v-if="company.description" class="relative">
        <CardDescription
          :class="[
            'transition-all duration-300 ease-in-out whitespace-pre-wrap',
            isDescriptionExpanded ? '' : 'line-clamp-3',
          ]"
        >
          {{ company.description }}
        </CardDescription>

        <button
          v-if="shouldShowToggle"
          class="text-primary hover:underline text-xs mt-1 focus:outline-none"
          @click="toggleDescription"
        >
          {{ isDescriptionExpanded ? "Show less" : "Show more" }}
        </button>
      </div>

      <div class="space-y-2 text-sm">
        <div v-if="company.site" class="flex items-center gap-2">
          <span class="text-muted-foreground">Website:</span>
          <a
            :href="company.site"
            target="_blank"
            rel="noopener noreferrer"
            class="text-primary hover:underline truncate"
          >
            {{ formatWebsite(company.site) }}
          </a>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import type {
  CompanyWithParticipation,
  UpdateCompanyData,
} from "@/dto/companies";
import { useCompanyInfoMutation } from "@/mutations/companies";
import { useCompanyImageUploadMutation } from "@/mutations/companies";
import { deleteCompany } from "@/api/companies";
import { useAuthStore } from "@/stores/auth";
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
import CompanyInfoForm from "../companies/CompanyInfoForm.vue";
import { Popover, PopoverContent, PopoverTrigger } from "../ui/popover";
import { TrashIcon } from "lucide-vue-next";
import ConfirmDelete from "@/components/ConfirmDelete.vue";

const props = defineProps<{
  company: CompanyWithParticipation;
}>();

const emit = defineEmits<{
  updated: [];
  deleted: [];
}>();

const isDescriptionExpanded = ref(false);
const isEditing = ref(false);
const isDeleteConfirmOpen = ref(false);
const isDeleting = ref(false);
const authStore = useAuthStore();
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

const companyInfoMutation = useCompanyInfoMutation();
const { mutate: updateCompanyInfo, isLoading: isUpdating } =
  companyInfoMutation;

const companyImageMutation = useCompanyImageUploadMutation();
const { mutate: uploadCompanyImage, isLoading: isUploadingImage } =
  companyImageMutation;

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
  data: Pick<UpdateCompanyData, "name" | "description" | "site">,
) => {
  if (!props.company?.id) return;

  companyInfoMutation.companyId.value = props.company.id;
  companyInfoMutation.companyData.value = data;

  try {
    // Update company info first
    await updateCompanyInfo();

    // Upload image if one was selected
    if (selectedImageFile.value) {
      const imageFormData = new FormData();
      imageFormData.append("image", selectedImageFile.value);

      companyImageMutation.companyId.value = props.company.id;
      companyImageMutation.imageData.value = imageFormData;

      await uploadCompanyImage();
    }

    isEditing.value = false;
    selectedImageFile.value = null; // Reset image selection
    emit("updated");
  } catch (error) {
    console.error("Failed to update company information:", error);
    // You might want to show a toast notification here
  }
};

const shouldShowToggle = computed(() => {
  if (!props.company.description) return false;
  // Simple heuristic: show toggle if description is longer than 150 characters
  return props.company.description.length > 150;
});

const toggleDescription = () => {
  isDescriptionExpanded.value = !isDescriptionExpanded.value;
};

const formatWebsite = (url: string): string => {
  try {
    const urlObj = new URL(url);
    return urlObj.hostname;
  } catch {
    return url;
  }
};

const canDelete = computed(() => {
  if (!authStore.decoded) return false;
  const role = (authStore.decoded as { role?: string }).role;
  return role === "COORDINATOR" || role === "ADMIN";
});

const handleDelete = async () => {
  if (!props.company?.id) return;
  isDeleting.value = true;
  try {
    await deleteCompany(props.company.id);
    // Invalidate cache and navigate to list
    queryCache.invalidateQueries({ key: ["companies"] });
    navigateBackWithReload("/companies");
    emit("deleted");
  } catch (error) {
    console.error("Error deleting company:", error);
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
