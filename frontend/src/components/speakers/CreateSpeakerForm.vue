<template>
  <div class="w-full max-w-md mx-auto p-4">
    <!-- Header -->
    <div class="mb-6">
      <!-- Stepper -->
      <Stepper v-model="currentStep">
        <StepperItem
          v-for="item in steps"
          :key="item.step"
          class="basis-1/3"
          :step="item.step"
        >
          <StepperTrigger>
            <StepperIndicator>
              <component :is="item.icon" class="w-4 h-4" />
            </StepperIndicator>
            <div class="flex flex-col">
              <StepperTitle>
                {{ item.title }}
              </StepperTitle>
            </div>
          </StepperTrigger>
          <StepperSeparator
            v-if="item.step !== steps[steps.length - 1].step"
            class="w-full h-px"
          />
        </StepperItem>
      </Stepper>
    </div>

    <!-- Step 1: Basic Speaker Information -->
    <div v-if="currentStep === 1" class="space-y-4">
      <div class="space-y-2">
        <SpeakerAutocomplete
          v-model="formData.name"
          label="Speaker Name *"
          placeholder="Enter speaker name"
          :disabled="isLoading"
          autofocus
          @selected="selectExistingSpeaker"
        />
        <span v-if="errors.name" class="text-sm text-destructive">{{
          errors.name
        }}</span>
      </div>

      <!-- Title @ Company Input -->
      <div class="space-y-2">
        <Label class="text-sm font-medium">Title @ Company *</Label>
        <div class="flex flex-col sm:flex-row sm:items-center gap-2">
          <div class="flex-1">
            <Input
              id="speaker-title"
              v-model="formData.title"
              placeholder="Enter speaker title"
              :disabled="isLoading"
            />
          </div>
          <div class="flex items-center justify-center sm:px-2">
            <span class="text-muted-foreground font-medium">@</span>
          </div>
          <div class="flex-1">
            <Input
              id="speaker-company"
              v-model="formData.companyName"
              placeholder="Enter company name"
              :disabled="isLoading"
            />
          </div>
        </div>
        <span v-if="errors.title" class="text-sm text-destructive">{{
          errors.title
        }}</span>
        <span v-if="errors.companyName" class="text-sm text-destructive">{{
          errors.companyName
        }}</span>
      </div>

      <div class="space-y-2">
        <Label for="speaker-bio" class="text-sm font-medium">Bio</Label>
        <Textarea
          id="speaker-bio"
          v-model="formData.bio"
          placeholder="Enter speaker bio"
          :disabled="isLoading"
          rows="4"
        />
      </div>

      <!-- Step 1 Actions -->
      <div class="flex justify-between pt-4">
        <Button variant="outline" :disabled="isLoading" @click="handleCancel">
          Cancel
        </Button>
        <Button :disabled="isLoading || !isStep1Valid" @click="nextStep">
          Next
        </Button>
      </div>
    </div>

    <!-- Step 2: Speaker Image -->
    <div v-if="currentStep === 2" class="space-y-4">
      <div class="space-y-2">
        <Label for="image" class="text-sm font-medium">Speaker Image</Label>
        <Input
          id="image"
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
      </div>

      <!-- Image preview -->
      <div v-if="imagePreview" class="space-y-2">
        <Label class="text-sm font-medium">Preview</Label>
        <div class="w-24 h-24 border border-muted rounded-lg overflow-hidden">
          <img
            :src="imagePreview"
            alt="Speaker image preview"
            class="w-full h-full object-cover"
          />
        </div>
      </div>

      <!-- Step 2 Actions -->
      <div class="flex justify-between pt-4">
        <Button variant="outline" :disabled="isLoading" @click="previousStep">
          Back
        </Button>
        <div class="flex gap-2">
          <Button :disabled="isLoading" @click="nextStep">
            <span v-if="!imagePreview">Skip</span>
            <span v-else>Next</span>
          </Button>
        </div>
      </div>
    </div>

    <!-- Step 3: Contact Information -->
    <div v-if="currentStep === 3" class="space-y-4">
      <!-- Contact Form -->
      <ContactForm
        without-name
        without-action
        :is-loading="isLoading"
        mode="create"
        @updated="(newData) => (contactData = newData.contact!)"
      />

      <!-- Step 3 Actions -->
      <div class="flex justify-between pt-4">
        <Button variant="outline" :disabled="isLoading" @click="previousStep">
          Back
        </Button>
        <div class="flex gap-2">
          <Button
            :disabled="isLoading || !isStep3Valid"
            @click="createSpeakerAndFinish"
          >
            <span>Create Speaker</span>
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { useRouter } from "vue-router";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Stepper,
  StepperIndicator,
  StepperItem,
  StepperSeparator,
  StepperTitle,
  StepperTrigger,
} from "@/components/ui/stepper";
import SpeakerAutocomplete from "./SpeakerAutocomplete.vue";
import ContactForm from "../companies/ContactForm.vue";
import {
  createSpeaker,
  createSpeakerParticipation,
  uploadSpeakerInternalImage,
} from "@/api/speakers";
import type { Speaker, CreateSpeakerData } from "@/dto/speakers";
import type { CreateContactData } from "@/dto/contacts";
import { UserIcon, ImageIcon, ContactIcon } from "lucide-vue-next";

interface Props {
  initialSpeakerName?: string;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  success: [speakerId: string];
  cancel: [];
}>();

const router = useRouter();

const steps = [
  {
    step: 1,
    title: "Info",
    icon: UserIcon,
  },
  {
    step: 2,
    title: "Image",
    icon: ImageIcon,
  },
  {
    step: 3,
    title: "Contact",
    icon: ContactIcon,
  },
];

// Form state
const currentStep = ref(1);
const isLoading = ref(false);
const errors = ref<Record<string, string>>({});

// Speaker data
interface CreateSpeakerFormData {
  name: string;
  title: string;
  companyName: string;
  bio: string;
}

const formData = ref<CreateSpeakerFormData>({
  name: "",
  title: "",
  companyName: "",
  bio: "",
});

// Image preview and file
const imagePreview = ref<string>("");
const selectedImageFile = ref<File | null>(null);

// Contact data - store the submitted contact data
const contactData = ref<CreateContactData>({
  mails: [],
  phones: [],
  socials: {},
});

// Validation
const isStep1Valid = computed(() => {
  return (
    formData.value.name.trim().length > 0 &&
    formData.value.title.trim().length > 0 &&
    formData.value.companyName.trim().length > 0
  );
});

const isStep3Valid = computed(() => {
  return (
    contactData.value.gender != undefined &&
    contactData.value.language != undefined
  );
});

// Step navigation
const nextStep = () => {
  if (currentStep.value === 1 && validateStep1()) {
    currentStep.value = 2;
  } else if (currentStep.value === 2) {
    currentStep.value = 3;
  }
};

const previousStep = () => {
  if (currentStep.value === 3) {
    currentStep.value = 2;
  } else if (currentStep.value === 2) {
    currentStep.value = 1;
  }
  errors.value = {};
};

const selectExistingSpeaker = (speaker: Speaker) => {
  emit("cancel");
  router.push({ name: "speaker", params: { speakerId: speaker.id } });
};

// Validation functions
const validateStep1 = () => {
  errors.value = {};

  if (!formData.value.name.trim()) {
    errors.value.name = "Speaker name is required";
    return false;
  }

  if (!formData.value.title.trim()) {
    errors.value.title = "Speaker title is required";
    return false;
  }

  if (!formData.value.companyName.trim()) {
    errors.value.companyName = "Company name is required";
    return false;
  }

  return true;
};

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
  }
};

// Speaker creation
const createSpeakerAndFinish = async () => {
  if (!validateStep1()) return;

  isLoading.value = true;
  errors.value = {};

  try {
    // Filter out empty contacts before submission
    const filteredContact = {
      mails: contactData.value.mails.filter(
        (mail) => mail.mail && mail.mail.trim().length > 0,
      ),
      phones: contactData.value.phones.filter(
        (phone) => phone.phone && phone.phone.trim().length > 0,
      ),
      socials: contactData.value.socials || {},
      gender: contactData.value.gender,
      language: contactData.value.language,
    };

    const createData: CreateSpeakerData = {
      name: formData.value.name,
      title: formData.value.title,
      bio: formData.value.bio,
      companyName: formData.value.companyName,
      contact: filteredContact,
    };

    const response = await createSpeaker(createData);
    const speakerId = response.data.id;

    // Upload image if selected
    if (selectedImageFile.value) {
      const imageFormData = new FormData();
      imageFormData.append("image", selectedImageFile.value);
      await uploadSpeakerInternalImage(speakerId, imageFormData);
    }

    await createSpeakerParticipation(speakerId);

    emit("success", speakerId);
    router.push({ name: "speaker", params: { speakerId } });
  } catch (error) {
    console.error("Error creating speaker:", error);
    errors.value.general = "Failed to create speaker. Please try again.";
  } finally {
    isLoading.value = false;
  }
};

const handleCancel = () => {
  emit("cancel");
};

onMounted(() => {
  if (props.initialSpeakerName) {
    formData.value.name = props.initialSpeakerName;
  }
});
</script>
