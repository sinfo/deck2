<template>
  <TaskTimelineItem
    :step-number="stepNumber"
    title="Images"
    :is-complete="isComplete"
    :is-last="isLast"
  >
    <template #icon>
      <ImageIcon class="w-4 h-4" />
    </template>

    <div class="space-y-6">
      <!-- Company: public logo -->
      <template v-if="entityType === 'company'">
        <div class="space-y-2">
          <span class="text-sm font-medium">Public Logo</span>
          <p class="text-xs text-muted-foreground">
            This image is shown publicly on the website.
          </p>
          <ImageUpload
            label=""
            input-id="company-public-image"
            url-placeholder="https://example.com/logo.png"
            preview-alt="Company public logo"
            preview-size="sm"
            :initial-url="companyPublicImgUrl"
            :disabled="isUploading"
            @file-selected="handleCompanyPublicFile"
          />
          <p
            v-if="isUploading"
            class="text-xs text-muted-foreground flex items-center gap-1"
          >
            <Loader2 class="w-3 h-3 animate-spin" /> Uploading…
          </p>
        </div>
      </template>

      <!-- Speaker: public photo + company logo -->
      <template v-if="entityType === 'speaker'">
        <div class="space-y-2">
          <span class="text-sm font-medium">Speaker Photo</span>
          <p class="text-xs text-muted-foreground">
            Public photo of the speaker shown on the website.
          </p>
          <ImageUpload
            label=""
            input-id="speaker-public-image"
            url-placeholder="https://example.com/photo.jpg"
            preview-alt="Speaker public photo"
            preview-size="sm"
            :initial-url="speakerImgUrl"
            :disabled="isSpeakerUploading"
            @file-selected="handleSpeakerPublicFile"
          />
          <p
            v-if="isSpeakerUploading"
            class="text-xs text-muted-foreground flex items-center gap-1"
          >
            <Loader2 class="w-3 h-3 animate-spin" /> Uploading…
          </p>
        </div>

        <Separator />

        <div class="space-y-2">
          <span class="text-sm font-medium">Speaker's Company Logo</span>
          <p class="text-xs text-muted-foreground">
            Logo of the speaker's company, shown publicly.
          </p>
          <ImageUpload
            label=""
            input-id="speaker-company-image"
            url-placeholder="https://example.com/company-logo.png"
            preview-alt="Speaker company logo"
            preview-size="sm"
            :initial-url="speakerCompanyImgUrl"
            :disabled="isCompanyUploading"
            @file-selected="handleSpeakerCompanyFile"
          />
          <p
            v-if="isCompanyUploading"
            class="text-xs text-muted-foreground flex items-center gap-1"
          >
            <Loader2 class="w-3 h-3 animate-spin" /> Uploading…
          </p>
        </div>
      </template>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import ImageUpload from "@/components/ImageUpload.vue";
import { Separator } from "@/components/ui/separator";
import { ImageIcon, Loader2 } from "lucide-vue-next";
import type { EntityType } from "@/dto/tasks";
import { useCompanyPublicImageUploadMutation } from "@/mutations/companies";
import {
  useSpeakerPublicImageUploadMutation,
  useSpeakerCompanyImageUploadMutation,
} from "@/mutations/speakers";
import useToast from "@/lib/toast";

interface Props {
  entityId: string;
  entityType: EntityType;
  stepNumber?: number;
  isLast?: boolean;
  /** Existing image URLs for preview on load */
  companyPublicImgUrl?: string;
  speakerImgUrl?: string;
  speakerCompanyImgUrl?: string;
}

const props = withDefaults(defineProps<Props>(), {
  stepNumber: 7,
  isLast: false,
  companyPublicImgUrl: undefined,
  speakerImgUrl: undefined,
  speakerCompanyImgUrl: undefined,
});

const { toast } = useToast();

// ── Company public image ────────────────────────────────────
const companyPublicMutation = useCompanyPublicImageUploadMutation();
companyPublicMutation.companyId.value = props.entityId;

const isUploading = ref(false);

async function handleCompanyPublicFile(file: File) {
  const fd = new FormData();
  fd.append("image", file);
  companyPublicMutation.imageData.value = fd;
  isUploading.value = true;
  try {
    await companyPublicMutation.mutate();
    toast.success({ title: "Public logo uploaded" });
  } catch {
    toast.error({ title: "Failed to upload public logo" });
  } finally {
    isUploading.value = false;
  }
}

// ── Speaker public image ────────────────────────────────────
const speakerPublicMutation = useSpeakerPublicImageUploadMutation();
speakerPublicMutation.speakerId.value = props.entityId;

const isSpeakerUploading = ref(false);

async function handleSpeakerPublicFile(file: File) {
  const fd = new FormData();
  fd.append("image", file);
  speakerPublicMutation.imageData.value = fd;
  isSpeakerUploading.value = true;
  try {
    await speakerPublicMutation.mutate();
    toast.success({ title: "Speaker photo uploaded" });
  } catch {
    toast.error({ title: "Failed to upload speaker photo" });
  } finally {
    isSpeakerUploading.value = false;
  }
}

// ── Speaker company image ───────────────────────────────────
const speakerCompanyMutation = useSpeakerCompanyImageUploadMutation();
speakerCompanyMutation.speakerId.value = props.entityId;

const isCompanyUploading = ref(false);

async function handleSpeakerCompanyFile(file: File) {
  const fd = new FormData();
  fd.append("image", file);
  speakerCompanyMutation.imageData.value = fd;
  isCompanyUploading.value = true;
  try {
    await speakerCompanyMutation.mutate();
    toast.success({ title: "Company logo uploaded" });
  } catch {
    toast.error({ title: "Failed to upload company logo" });
  } finally {
    isCompanyUploading.value = false;
  }
}

const isComplete = computed(() => false); // image upload is always optional
</script>
