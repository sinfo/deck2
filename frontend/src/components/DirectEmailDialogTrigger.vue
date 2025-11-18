<template>
  <div>
    <Button :size="size" :class="buttonClass" @click="openDialog">
      <slot>Create Draft Email</slot>
    </Button>

    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent class="max-w-2xl">
          <AlertDialogHeader>
            <AlertDialogTitle
              >Create Draft Email for {{ entity.name }}</AlertDialogTitle
            >
            <AlertDialogDescription>
              Select a template and recipients and create a draft in your Gmail
              drafts folder.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="space-y-4">
            <div>
              <label class="text-sm font-medium">Email Template</label>
              <Select v-model="selectedTemplate">
                <SelectTrigger class="w-full mt-1">
                  <SelectValue placeholder="Choose a template..." />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem
                    v-for="template in availableTemplates"
                    :key="template.value"
                    :value="template.value"
                  >
                    {{ template.label }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div v-if="isFetchingEmails">
              <p>Loading recipients...</p>
            </div>

            <div v-else-if="availableEmails.length > 0">
              <label class="text-sm font-medium">Recipients</label>
              <div
                class="mt-1 border rounded-md p-2 space-y-2 max-h-48 overflow-y-auto"
              >
                <div
                  v-for="email in availableEmails"
                  :key="email.address"
                  class="flex items-center cursor-pointer hover:bg-gray-50 p-1 rounded"
                  @click.prevent="toggleEmail(email)"
                >
                  <div class="pointer-events-none">
                    <Checkbox
                      :id="email.address"
                      :checked="
                        selectedEmails.some((e) => e.address === email.address)
                      "
                    />
                  </div>
                  <label
                    :for="email.address"
                    class="ml-2 text-sm flex-1 cursor-pointer pointer-events-none"
                  >
                    {{ email.name }} ({{ email.address }})
                  </label>
                </div>
              </div>
            </div>

            <div v-else>
              <p class="text-sm text-red-500">
                No contacts found for this {{ entityType }}.
              </p>
            </div>
          </div>

          <AlertDialogFooter>
            <Button variant="outline" @click="isDialogOpen = false"
              >Cancel</Button
            >
            <Button :disabled="!canSend" @click="handleSendEmail">
              <span v-if="isSending">Creating Draft...</span>
              <span v-else>Create Draft</span>
            </Button>
          </AlertDialogFooter>

          <div v-if="sendResult" class="mt-4">
            <div v-if="sendResult.success" class="bg-green-50 rounded-lg p-4">
              <h3 class="text-lg font-semibold text-green-700">
                ✅ Draft Created
              </h3>
              <p class="text-sm text-green-800 mt-2">
                A draft email was created in your Gmail drafts folder.
              </p>
              <div class="mt-3">
                <Button variant="outline" @click="openGmailDrafts"
                  >Open Gmail Drafts</Button
                >
              </div>
            </div>
            <div v-else class="bg-red-50 rounded-lg p-4">
              <h3 class="text-lg font-semibold text-red-700">
                ❌ Failed to Create Draft
              </h3>
              <p class="text-sm text-red-800 mt-2">
                {{ sendResult.error || "Unknown error" }}
              </p>
            </div>
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import {
  useDirectEmail,
  type DirectEmailEntity,
  type EmailWithDetails,
} from "@/composables/useDirectEmail";
import {
  companyTemplateCategories,
  speakerTemplateCategories,
  EmailTemplateCategory,
  templateCategoryHumanReadable,
} from "@/lib/templates";

interface Props {
  size?: "sm" | "default" | "lg" | "icon";
  buttonClass?: string;
  entity: DirectEmailEntity;
  entityType: "company" | "speaker";
}

const props = withDefaults(defineProps<Props>(), {
  size: "sm",
  buttonClass: "",
});

const emit = defineEmits<{
  success: [];
  error: [message: string];
}>();

const isDialogOpen = ref(false);
const selectedTemplate = ref<EmailTemplateCategory | null>(null);
const selectedEmails = ref<EmailWithDetails[]>([]);

const {
  isFetchingEmails,
  availableEmails,
  isSending,
  fetchAvailableEmails,
  sendEmail,
} = useDirectEmail(props.entity);

const availableTemplates = computed(() => {
  const templates =
    props.entityType === "company"
      ? companyTemplateCategories
      : speakerTemplateCategories;
  return templates.map((template) => ({
    value: template,
    label: templateCategoryHumanReadable[template],
  }));
});

const openDialog = () => {
  isDialogOpen.value = true;
};

watch(isDialogOpen, (isOpen) => {
  if (isOpen) {
    fetchAvailableEmails();
    selectedEmails.value = [];
    selectedTemplate.value = null;
  }
});

// Debug: watch selectedEmails to log changes and help debug the disabled button
watch(
  selectedEmails,
  (val) => {
    try {
      console.log(
        "selectedEmails changed:",
        val.map((e) => e.address),
      );
    } catch {
      console.log("selectedEmails changed (raw):", val);
    }
  },
  { deep: true },
);

// Debug: watch availableEmails to ensure fetch works
watch(availableEmails, (val) => {
  try {
    console.log(
      "availableEmails:",
      val.map((e) => e.address),
    );
  } catch {
    console.log("availableEmails changed:", val);
  }
});

const canSend = computed(
  () =>
    !!selectedTemplate.value &&
    selectedEmails.value.length > 0 &&
    !isSending.value,
);
watch(canSend, (val) => console.log("canSend:", val));

const sendResult = ref<{ success: boolean; error?: string } | null>(null);

const openGmailDrafts = () => {
  window.open("https://mail.google.com/mail/u/0/#drafts", "_blank");
};

const handleCheckboxChange = (email: EmailWithDetails, checked: boolean) => {
  console.log("handleCheckboxChange for:", email.address, checked);
  if (checked) {
    selectedEmails.value = Array.from(
      new Map(
        [...selectedEmails.value, email].map((e) => [e.address, e]),
      ).values(),
    );
  } else {
    selectedEmails.value = selectedEmails.value.filter(
      (e) => e.address !== email.address,
    );
  }
  console.log(
    "selectedEmails now:",
    selectedEmails.value.map((e) => e.address),
  );
};

const toggleEmail = (email: EmailWithDetails) => {
  const isSelected = selectedEmails.value.some(
    (e) => e.address === email.address,
  );
  handleCheckboxChange(email, !isSelected);
};

const handleSendEmail = async () => {
  if (!selectedTemplate.value || selectedEmails.value.length === 0) {
    return;
  }

  // reset previous result
  sendResult.value = null;

  const result = await sendEmail(selectedTemplate.value, selectedEmails.value);

  sendResult.value = { success: result.success, error: result.error };

  if (result.success) {
    emit("success");
    // keep dialog open to show results (like bulk)
  } else {
    emit("error", result.error || "An unknown error occurred.");
  }
};
</script>
