<template>
  <div class="w-full max-w-md mx-auto p-4">
    <!-- Header -->
    <div class="mb-6">
      <!-- Stepper -->
      <Stepper v-model="currentStep">
        <StepperItem
          v-for="item in steps"
          :key="item.step"
          class="basis-1/4"
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

    <!-- Step 1: Basic Company Information -->
    <div v-if="currentStep === 1" class="space-y-4">
      <div class="space-y-2">
        <!-- TODO autofocus not working -->
        <CompanyAutocomplete
          v-model="formData.name"
          label="Company Name *"
          placeholder="Enter company name"
          :disabled="isLoading"
          autofocus
          @selected="selectExistingCompany"
        />
        <span v-if="errors.name" class="text-sm text-destructive">{{
          errors.name
        }}</span>
      </div>

      <div class="space-y-2">
        <Label for="description" class="text-sm font-medium">Description</Label>
        <Textarea
          id="description"
          v-model="formData.description"
          placeholder="Enter company description"
          :disabled="isLoading"
          rows="3"
        />
      </div>

      <div class="space-y-2">
        <Label for="website" class="text-sm font-medium">Website</Label>
        <Input
          id="website"
          v-model="formData.site"
          placeholder="https://example.com"
          type="url"
          :disabled="isLoading"
        />
        <span v-if="errors.site" class="text-sm text-destructive">{{
          errors.site
        }}</span>
      </div>

      <!-- Step 1 Actions -->
      <div class="flex justify-between pt-4">
        <Button
          variant="outline"
          :disabled="isLoading"
          @click="$emit('cancel')"
        >
          Cancel
        </Button>
        <Button :disabled="isLoading || !isStep1Valid" @click="nextStep">
          Next
        </Button>
      </div>
    </div>

    <!-- Step 2: Company Logo -->
    <div v-if="currentStep === 2" class="space-y-4">
      <ImageUpload
        ref="imageUploadRef"
        label="Company Logo"
        input-id="company-logo"
        url-placeholder="https://example.com/logo.jpg"
        preview-alt="Logo preview"
        :disabled="isLoading"
        @file-selected="handleImageSelected"
      />

      <!-- Step 2 Actions -->
      <div class="flex justify-between pt-4">
        <Button variant="outline" :disabled="isLoading" @click="previousStep">
          Back
        </Button>
        <div class="flex gap-2">
          <Button
            :disabled="isLoading || imageUploadRef?.isLoadingImageUrl"
            @click="nextStep"
          >
            <span v-if="!imageUploadRef?.imagePreview">Skip</span>
            <span v-else>Next</span>
          </Button>
        </div>
      </div>
    </div>

    <!-- Step 3: Contacts -->
    <div v-if="currentStep === 3" class="space-y-4">
      <!-- Representatives List -->
      <div class="space-y-4">
        <div
          v-if="!representatives.length"
          class="text-center text-muted-foreground py-8 border border-dashed rounded-lg"
        >
          No representatives added yet
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="(rep, index) in representatives"
            :key="`rep-${index}`"
            class="border rounded-lg p-4 space-y-3"
          >
            <div class="flex justify-between items-start">
              <div class="space-y-1">
                <Label class="text-sm font-medium">Representative Name</Label>
                <Input
                  v-model="rep.name"
                  placeholder="Enter representative name"
                  :disabled="isLoading"
                />
              </div>
              <Button
                variant="outline"
                size="sm"
                :disabled="isLoading"
                @click="removeRepresentative(index)"
              >
                Remove
              </Button>
            </div>

            <!-- Email Contacts -->
            <div class="space-y-2">
              <Label class="text-sm font-medium">Email Addresses</Label>
              <div
                v-for="(email, emailIndex) in rep.contact?.mails || []"
                :key="`email-${index}-${emailIndex}`"
                class="flex gap-2 items-center"
              >
                <Input
                  v-model="email.mail"
                  placeholder="email@example.com"
                  type="email"
                  :disabled="isLoading"
                />
                <Button
                  variant="outline"
                  size="sm"
                  :disabled="isLoading"
                  @click="removeEmail(index, emailIndex)"
                >
                  Remove
                </Button>
              </div>
              <Button
                variant="outline"
                size="sm"
                :disabled="isLoading"
                @click="addEmail(index)"
              >
                Add Email
              </Button>
            </div>

            <!-- Phone Contacts -->
            <div class="space-y-2">
              <Label class="text-sm font-medium">Phone Numbers</Label>
              <div
                v-for="(phone, phoneIndex) in rep.contact?.phones || []"
                :key="`phone-${index}-${phoneIndex}`"
                class="flex gap-2 items-center"
              >
                <Input
                  v-model="phone.phone"
                  placeholder="+1234567890"
                  type="tel"
                  :disabled="isLoading"
                />
                <Button
                  variant="outline"
                  size="sm"
                  :disabled="isLoading"
                  @click="removePhone(index, phoneIndex)"
                >
                  Remove
                </Button>
              </div>
              <Button
                variant="outline"
                size="sm"
                :disabled="isLoading"
                @click="addPhone(index)"
              >
                Add Phone
              </Button>
            </div>
          </div>
        </div>

        <!-- Add Representative Button -->
        <Button
          variant="outline"
          :disabled="isLoading"
          class="w-full"
          @click="addRepresentative"
        >
          Add Representative
        </Button>
      </div>

      <!-- Step 3 Actions -->
      <div class="flex justify-between pt-4">
        <Button variant="outline" :disabled="isLoading" @click="previousStep">
          Back
        </Button>
        <div class="flex gap-2">
          <Button :disabled="isLoading" @click="createCompanyAndFinish">
            Create Company
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { useRouter } from "vue-router";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Stepper,
  StepperIndicator,
  StepperItem,
  StepperSeparator,
  StepperTitle,
  StepperTrigger,
} from "@/components/ui/stepper";
import CompanyAutocomplete from "./CompanyAutocomplete.vue";
import ImageUpload from "@/components/ImageUpload.vue";
import {
  createCompany,
  createCompanyParticipation,
  uploadCompanyInternalImage,
} from "@/api/companies";
import { createCompanyRepresentative } from "@/api/companies";
import type {
  CreateCompanyData,
  CreateCompanyRepData,
  Company,
} from "@/dto/companies";
import { BookIcon, ContactIcon, ImageIcon } from "lucide-vue-next";

const props = defineProps<{
  initialCompanyName?: string;
}>();

const emit = defineEmits<{
  cancel: [];
  success: [companyId: string];
}>();

const router = useRouter();

const steps = [
  {
    step: 1,
    title: "Info",
    icon: BookIcon,
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

// Company data
const formData = ref<CreateCompanyData>({
  name: props.initialCompanyName || "",
  description: "",
  site: "",
});

// Image upload ref
const imageUploadRef = ref<InstanceType<typeof ImageUpload> | null>(null);
const selectedImageFile = ref<File | null>(null);

// Handle image selection from ImageUpload component
const handleImageSelected = (file: File) => {
  selectedImageFile.value = file;
};

// Representatives data
const representatives = ref<CreateCompanyRepData[]>([]);

// Validation
const isStep1Valid = computed(() => {
  return formData.value.name.trim().length > 0;
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

const selectExistingCompany = (company: Company) => {
  // Close the dialog and navigate to the existing company
  emit("cancel");
  router.push({ name: "company", params: { companyId: company.id } });
};

// Validation functions
const validateStep1 = () => {
  errors.value = {};

  if (!formData.value.name.trim()) {
    errors.value.name = "Company name is required";
    return false;
  }

  if (formData.value.site && !isValidUrl(formData.value.site)) {
    errors.value.site = "Please enter a valid URL";
    return false;
  }

  return true;
};

const isValidUrl = (url: string) => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

// Representative management
const addRepresentative = () => {
  representatives.value.push({
    name: "",
    contact: {
      mails: [],
      phones: [],
      socials: {},
    },
  });
};

const removeRepresentative = (index: number) => {
  representatives.value.splice(index, 1);
};

// Contact management for representatives
const addEmail = (repIndex: number) => {
  representatives.value[repIndex].contact!.mails.push({
    mail: "",
    personal: false,
  });
};

const removeEmail = (repIndex: number, emailIndex: number) => {
  representatives.value[repIndex].contact!.mails.splice(emailIndex, 1);
};

const addPhone = (repIndex: number) => {
  representatives.value[repIndex].contact!.phones.push({
    phone: "",
  });
};

const removePhone = (repIndex: number, phoneIndex: number) => {
  representatives.value[repIndex].contact!.phones.splice(phoneIndex, 1);
};

// Company creation
const createCompanyAndFinish = async () => {
  if (!validateStep1()) return;

  isLoading.value = true;
  errors.value = {};

  try {
    // Create company
    const response = await createCompany(formData.value);
    const companyId = response.data.id;

    // Upload image if selected
    if (selectedImageFile.value) {
      const imageFormData = new FormData();
      imageFormData.append("image", selectedImageFile.value);
      await uploadCompanyInternalImage(companyId, imageFormData);
    }

    // Add representatives if any
    for (const rep of representatives.value) {
      if (
        rep.name?.trim() ||
        rep.contact?.mails.some((m) => m.mail.trim()) ||
        rep.contact?.phones.some((p) => p.phone.trim())
      ) {
        // Filter out empty contacts
        const filteredContact = {
          mails: rep.contact?.mails.filter((m) => m.mail.trim()) || [],
          phones: rep.contact?.phones.filter((p) => p.phone.trim()) || [],
          socials: rep.contact?.socials || {},
        };

        if (
          filteredContact.mails.length > 0 ||
          filteredContact.phones.length > 0 ||
          rep.name?.trim()
        ) {
          await createCompanyRepresentative(companyId, {
            name: rep.name || "Unnamed Representative",
            contact: filteredContact,
          });
        }
      }
    }

    // Create company participation
    await createCompanyParticipation(companyId, {
      partner: false,
    });

    emit("success", companyId); // Navigate to company page
    router.push({ name: "company", params: { companyId } });
  } catch (error) {
    console.error("Error creating company:", error);
    errors.value.general = "Failed to create company. Please try again.";
  } finally {
    isLoading.value = false;
  }
};
</script>
