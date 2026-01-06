<template>
  <div class="flex flex-col h-full">
    <!-- Form Content - Scrollable -->
    <div class="flex-1 space-y-6">
      <!-- Name Field -->
      <div v-if="!withoutName" class="space-y-2">
        <Label for="name" class="text-sm font-medium">Name *</Label>
        <Input
          id="name"
          v-model="formData.name"
          placeholder="Enter representative name"
          :disabled="isLoading"
          :required="!withoutName"
        />
      </div>

      <!-- Gender Field -->
      <div class="space-y-2">
        <Label class="text-sm font-medium">Gender</Label>
        <ToggleGroup
          v-model="formData.contact.gender"
          type="single"
          variant="outline"
          class="justify-start"
          :disabled="isLoading"
        >
          <ToggleGroupItem :value="Gender.MALE" class="px-4">
            Male
          </ToggleGroupItem>
          <ToggleGroupItem :value="Gender.FEMALE" class="px-4">
            Female
          </ToggleGroupItem>
          <ToggleGroupItem :value="Gender.OTHER" class="px-4">
            Other
          </ToggleGroupItem>
        </ToggleGroup>
      </div>

      <!-- Language Field -->
      <div class="space-y-2">
        <Label class="text-sm font-medium">Language</Label>
        <ToggleGroup
          v-model="formData.contact.language"
          type="single"
          variant="outline"
          class="justify-start"
          :disabled="isLoading"
        >
          <ToggleGroupItem :value="Language.PORTUGUESE" class="px-4">
            Portuguese
          </ToggleGroupItem>
          <ToggleGroupItem :value="Language.ENGLISH" class="px-4">
            English
          </ToggleGroupItem>
        </ToggleGroup>
      </div>

      <!-- Contact Sections -->
      <div class="space-y-6">
        <!-- Email Section -->
        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <Label class="text-sm font-medium">Email Addresses *</Label>
            <Button
              variant="ghost"
              size="sm"
              :disabled="isLoading"
              class="h-8 px-2 text-xs"
              @click="addEmail"
            >
              + Add Email
            </Button>
          </div>

          <div class="space-y-2">
            <div
              v-for="(email, index) in formData.contact.mails"
              :key="index"
              class="flex gap-2 items-center"
            >
              <Input
                v-model="email.mail"
                placeholder="email@example.com"
                type="email"
                :disabled="isLoading"
                class="flex-1"
              />
              <div class="flex items-center gap-2">
                <label
                  class="text-xs flex items-center gap-1 whitespace-nowrap"
                >
                  <input
                    v-model="email.personal"
                    type="checkbox"
                    :disabled="isLoading"
                    class="w-3 h-3"
                  />
                  Personal
                </label>
                <Button
                  v-if="formData.contact.mails.length > 1"
                  variant="ghost"
                  size="sm"
                  :disabled="isLoading"
                  class="h-8 w-8 p-0 text-muted-foreground hover:text-destructive"
                  @click="removeEmail(index)"
                >
                  ×
                </Button>
              </div>
            </div>
          </div>
        </div>

        <!-- Phone Section -->
        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <Label class="text-sm font-medium">Phone Numbers</Label>
            <Button
              variant="ghost"
              size="sm"
              :disabled="isLoading"
              class="h-8 px-2 text-xs"
              @click="addPhone"
            >
              + Add Phone
            </Button>
          </div>

          <div class="space-y-2">
            <div
              v-for="(phone, index) in formData.contact.phones"
              :key="index"
              class="flex gap-2 items-center"
            >
              <Input
                v-model="phone.phone"
                placeholder="+351 912 345 678"
                type="tel"
                :disabled="isLoading"
                class="flex-1"
              />
              <Button
                v-if="formData.contact.phones.length > 1"
                variant="ghost"
                size="sm"
                :disabled="isLoading"
                class="h-8 w-8 p-0 text-muted-foreground hover:text-destructive"
                @click="removePhone(index)"
              >
                ×
              </Button>
            </div>
          </div>
        </div>

        <!-- Social Media Section -->
        <div class="space-y-3">
          <Label class="text-sm font-medium">Social Media</Label>
          <div class="grid grid-cols-1 gap-3">
            <div class="flex items-center gap-3">
              <Label for="linkedin" class="w-16 text-xs text-muted-foreground"
                >LinkedIn</Label
              >
              <Input
                id="linkedin"
                v-model="formData.contact.socials.linkedin"
                placeholder="username or profile URL"
                :disabled="isLoading"
                class="flex-1"
              />
            </div>
            <div class="flex items-center gap-3">
              <Label for="twitter" class="w-16 text-xs text-muted-foreground"
                >Twitter</Label
              >
              <Input
                id="twitter"
                v-model="formData.contact.socials.twitter"
                placeholder="@username or profile URL"
                :disabled="isLoading"
                class="flex-1"
              />
            </div>
            <div class="flex items-center gap-3">
              <Label for="github" class="w-16 text-xs text-muted-foreground"
                >GitHub</Label
              >
              <Input
                id="github"
                v-model="formData.contact.socials.github"
                placeholder="username or profile URL"
                :disabled="isLoading"
                class="flex-1"
              />
            </div>
          </div>

          <!-- Collapsible additional social media -->
          <div
            v-if="showMoreSocials"
            class="grid grid-cols-1 gap-3 pt-2 border-t"
          >
            <div class="flex items-center gap-3">
              <Label for="facebook" class="w-16 text-xs text-muted-foreground"
                >Facebook</Label
              >
              <Input
                id="facebook"
                v-model="formData.contact.socials.facebook"
                placeholder="username or profile URL"
                :disabled="isLoading"
                class="flex-1"
              />
            </div>
            <div class="flex items-center gap-3">
              <Label for="skype" class="w-16 text-xs text-muted-foreground"
                >Skype</Label
              >
              <Input
                id="skype"
                v-model="formData.contact.socials.skype"
                placeholder="username"
                :disabled="isLoading"
                class="flex-1"
              />
            </div>
          </div>

          <Button
            variant="ghost"
            size="sm"
            :disabled="isLoading"
            class="h-8 px-2 text-xs text-muted-foreground"
            @click="showMoreSocials = !showMoreSocials"
          >
            {{ showMoreSocials ? "- Less" : "+ More" }} social platforms
          </Button>
        </div>
      </div>
    </div>

    <!-- Action Buttons - Sticky -->
    <div
      v-if="!withoutAction"
      class="flex-shrink-0 mt-6 pt-4 border-t bg-background"
    >
      <div class="flex justify-end gap-3">
        <div class="flex-1">
          <p
            v-if="!isValid && validationMessage"
            class="text-xs text-muted-foreground"
          >
            {{ validationMessage }}
          </p>
        </div>
        <div class="flex gap-3">
          <Button
            variant="outline"
            :disabled="isLoading"
            @click="$emit('cancel')"
          >
            Cancel
          </Button>
          <Button :disabled="isLoading || !isValid" @click="handleSubmit">
            {{
              isLoading
                ? mode === "edit"
                  ? "Updating..."
                  : "Saving..."
                : mode === "edit"
                  ? "Update Contact"
                  : "Save Contact"
            }}
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import type { CreateCompanyRepData, CompanyRep } from "@/dto/companies";
import type { ContactSocials } from "@/dto/contacts";
import { Gender, Language } from "@/dto/contacts";
import Button from "../ui/button/Button.vue";
import Input from "../ui/input/Input.vue";
import Label from "../ui/label/Label.vue";
import ToggleGroup from "../ui/toggle-group/ToggleGroup.vue";
import ToggleGroupItem from "../ui/toggle-group/ToggleGroupItem.vue";

interface Props {
  isLoading?: boolean;
  mode?: "create" | "edit";
  initialData?: CompanyRep;
  withoutName?: boolean;
  withoutAction?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  mode: "create",
  initialData: undefined,
});

const emit = defineEmits<{
  submit: [data: CreateCompanyRepData];
  cancel: [];
  updated: [data: CreateCompanyRepData];
}>();

const showMoreSocials = ref(false);

const formData = reactive<Required<CreateCompanyRepData>>({
  name: "",
  contact: {
    gender: undefined,
    language: undefined,
    mails: [{ mail: "", personal: false }],
    phones: [{ phone: "" }],
    socials: {
      linkedin: "",
      twitter: "",
      facebook: "",
      github: "",
      skype: "",
    },
  },
});

// Initialize form data when in edit mode
watch(
  () => props.initialData,
  (newData) => {
    if (newData && props.mode === "edit") {
      formData.name = newData.name;
      formData.contact.gender = newData.contact.gender;
      formData.contact.language = newData.contact.language;
      formData.contact.mails =
        newData.contact.mails.length > 0
          ? [...newData.contact.mails]
          : [{ mail: "", personal: false }];
      formData.contact.phones =
        newData.contact.phones.length > 0
          ? [...newData.contact.phones]
          : [{ phone: "" }];
      formData.contact.socials = { ...newData.contact.socials };
    }
  },
  { immediate: true },
);

watch(
  () => formData,
  (newData) => emit("updated", newData),
  { deep: true, immediate: true },
);

const isValid = computed(() => {
  const hasName = props.withoutName || formData.name?.trim();
  const hasEmail = formData.contact.mails.some((mail) => mail.mail.trim());
  return hasName && hasEmail;
});

const validationMessage = computed(() => {
  if (!props.withoutName && !formData.name?.trim()) return "Name is required";
  if (!formData.contact.mails.some((mail) => mail.mail.trim()))
    return "At least one email is required";
  return "";
});

const addEmail = () => {
  formData.contact.mails.push({ mail: "", personal: false });
};

const removeEmail = (index: number) => {
  formData.contact.mails.splice(index, 1);
};

const addPhone = () => {
  formData.contact.phones.push({ phone: "" });
};

const removePhone = (index: number) => {
  formData.contact.phones.splice(index, 1);
};

const handleSubmit = () => {
  if (!isValid.value) return;

  // Clean up empty fields
  const cleanedData: CreateCompanyRepData = {
    name: formData.name?.trim(),
    contact: {
      gender: formData.contact.gender,
      language: formData.contact.language,
      mails: formData.contact.mails.filter((mail) => mail.mail.trim()),
      phones: formData.contact.phones.filter((phone) => phone.phone.trim()),
      socials: Object.fromEntries(
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        Object.entries(formData.contact.socials).filter(([_, value]) =>
          value?.trim(),
        ),
      ) as ContactSocials,
    },
  };

  emit("submit", cleanedData);
};
</script>
