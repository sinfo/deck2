<template>
  <div>
    <Button :size="size" :class="buttonClass" @click="isDialogOpen = true">
      <slot>Bulk {{ entitiesLabel }} Emails</slot>
    </Button>

    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent
          class="max-w-4xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>
              {{
                currentStep === 1
                  ? `Configure Bulk ${entitiesLabel} Emails`
                  : currentStep === 2
                    ? `Review & Create ${entitiesLabel} Emails`
                    : `${entitiesLabel} Email Results`
              }}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {{
                currentStep === 1
                  ? `Configure your bulk ${entitiesLabel.toLowerCase()} email settings and review before sending.`
                  : currentStep === 2
                    ? `Review ${entitiesLabel.toLowerCase()} and verify emails before creating drafts.`
                    : `View the results of your bulk ${entitiesLabel.toLowerCase()} email operation.`
              }}
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0 p-6">
            <!-- Simple Step Indicator -->
            <div class="flex items-center justify-between mb-6">
              <div class="flex items-center">
                <div
                  :class="`w-8 h-8 rounded-full border-2 flex items-center justify-center text-sm font-medium ${currentStep === 1 ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-blue-600 border-blue-600'}`"
                >
                  1
                </div>
                <span class="ml-2 text-sm font-medium">Configuration</span>
              </div>
              <div class="w-6 h-0.5 bg-gray-300"></div>
              <div class="flex items-center">
                <div
                  :class="`w-8 h-8 rounded-full border-2 flex items-center justify-center text-sm font-medium ${currentStep === 2 ? 'bg-blue-600 text-white border-blue-600' : currentStep > 2 ? 'bg-white text-blue-600 border-blue-600' : 'bg-gray-100 text-gray-400 border-gray-300'}`"
                >
                  2
                </div>
                <span
                  class="ml-2 text-sm font-medium"
                  :class="currentStep >= 2 ? 'text-gray-900' : 'text-gray-500'"
                  >Review</span
                >
              </div>
              <div class="w-6 h-0.5 bg-gray-300"></div>
              <div class="flex items-center">
                <div
                  :class="`w-8 h-8 rounded-full border-2 flex items-center justify-center text-sm font-medium ${currentStep === 3 ? 'bg-blue-600 text-white border-blue-600' : 'bg-gray-100 text-gray-400 border-gray-300'}`"
                >
                  3
                </div>
                <span
                  class="ml-2 text-sm font-medium"
                  :class="currentStep >= 3 ? 'text-gray-900' : 'text-gray-500'"
                  >Results</span
                >
              </div>
            </div>

            <!-- Step 1: Configuration -->
            <div v-if="currentStep === 1" class="mt-6 space-y-6">
              <div>
                <label
                  class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
                >
                  Select Email Template
                </label>
                <Select v-model="selectedTemplate">
                  <SelectTrigger class="w-full mt-2">
                    <SelectValue placeholder="Choose an email template..." />
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

              <div>
                <label
                  class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 mb-3 block"
                >
                  Select {{ entityLabel }} Status
                </label>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div
                    v-for="status in participationStatuses"
                    :key="status.value"
                    class="flex items-center space-x-2"
                  >
                    <Checkbox
                      :id="status.value"
                      :model-value="selectedStatuses.includes(status.value)"
                      @update:checked="
                        (value: any) =>
                          toggleStatusWithValue(status.value, value)
                      "
                    />
                    <label
                      :for="status.value"
                      class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                      @click="() => toggleStatusSimple(status.value)"
                    >
                      {{ status.label }}
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <!-- Step 2: Review -->
            <div v-if="currentStep === 2" class="mt-6 space-y-6">
              <div v-if="isProcessing || isSending" class="text-center py-8">
                <div
                  class="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto"
                ></div>
                <p class="mt-2 text-sm text-gray-600">
                  {{
                    isSending
                      ? "Creating draft emails..."
                      : `Processing ${entitiesLabel.toLowerCase()} and verifying emails...`
                  }}
                </p>

                <!-- Progress Bar -->
                <div class="mt-4 max-w-md mx-auto">
                  <div class="flex justify-between text-xs text-gray-600 mb-2">
                    <span v-if="isSending">
                      Creating draft {{ sentCount }} of {{ totalToSend }} emails
                    </span>
                    <span v-else>
                      Processing {{ processedCount }} of {{ totalToProcess }}
                      {{ entitiesLabel.toLowerCase() }}
                    </span>
                    <span>{{ Math.round(processingProgress) }}%</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2">
                    <div
                      class="bg-blue-600 h-2 rounded-full transition-all duration-300 ease-out"
                      :style="{ width: processingProgress + '%' }"
                    ></div>
                  </div>
                </div>
              </div>

              <div v-else-if="processResult" class="space-y-6">
                <!-- Ready to create -->
                <div v-if="processResult.ready.length > 0">
                  <h3 class="text-lg font-semibold text-green-700 mb-3">
                    Ready to Create ({{ processResult.ready.length }})
                  </h3>
                  <div
                    class="bg-green-50 rounded-lg p-4 max-h-40 overflow-y-auto"
                  >
                    <div
                      v-for="item in processResult.ready"
                      :key="item.entity.id"
                      class="flex justify-between items-center py-1"
                    >
                      <span class="font-medium">{{ item.entity.name }}</span>
                      <span class="text-sm text-gray-600"
                        >{{ item.email?.address }} ({{ item.email?.gender }},
                        {{ item.email?.language }})</span
                      >
                    </div>
                  </div>
                </div>

                <!-- Entities incomplete -->
                <div v-if="processResult.incomplete.length > 0">
                  <h3 class="text-lg font-semibold text-yellow-700 mb-3">
                    Incomplete ({{ processResult.incomplete.length }})
                  </h3>
                  <div
                    class="bg-yellow-50 rounded-lg p-4 max-h-40 overflow-y-auto"
                  >
                    <div
                      v-for="item in processResult.incomplete"
                      :key="item.entity.id"
                      class="flex justify-between items-center py-1"
                    >
                      <span class="font-medium">{{ item.entity.name }}</span>
                      <span class="text-sm text-gray-600">{{
                        item.error
                      }}</span>
                    </div>
                  </div>
                </div>

                <!-- Errors -->
                <div v-if="processResult.errors.length > 0">
                  <h3 class="text-lg font-semibold text-red-700 mb-3">
                    Errors ({{ processResult.errors.length }})
                  </h3>
                  <div
                    class="bg-red-50 rounded-lg p-4 max-h-40 overflow-y-auto"
                  >
                    <div
                      v-for="item in processResult.errors"
                      :key="item.entity.id"
                      class="flex justify-between items-center py-1"
                    >
                      <span class="font-medium">{{ item.entity.name }}</span>
                      <span class="text-sm text-gray-600">{{
                        item.error
                      }}</span>
                    </div>
                  </div>
                </div>

                <!-- Summary -->
                <div class="bg-blue-50 rounded-lg p-4">
                  <h4 class="font-semibold mb-2">Summary</h4>
                  <ul class="text-sm space-y-1">
                    <li>
                      ✅ {{ processResult.ready.length }}
                      {{ entityLabel.toLowerCase() }} ready to receive emails
                    </li>
                    <li v-if="processResult.incomplete.length > 0">
                      ⚠️ {{ processResult.incomplete.length }} incomplete
                      {{ entityLabel.toLowerCase() }}s
                    </li>
                    <li v-if="processResult.errors.length > 0">
                      ❌ {{ processResult.errors.length }}
                      {{ entityLabel.toLowerCase() }}s with errors
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            <!-- Step 3: Results -->
            <div v-if="currentStep === 3" class="mt-6 space-y-6">
              <div v-if="result" class="space-y-6">
                <!-- Success Results -->
                <div v-if="result.success.length > 0">
                  <h3 class="text-lg font-semibold text-green-700 mb-3">
                    ✅ Successfully Created ({{ result.success.length }})
                  </h3>
                  <div class="bg-green-50 rounded-lg p-4">
                    <p class="text-sm text-green-800">
                      {{ result.success.length }} draft email{{
                        result.success.length === 1 ? "" : "s"
                      }}
                      {{ result.success.length === 1 ? "has" : "have" }} been
                      created in your Gmail drafts folder.
                    </p>
                  </div>
                </div>

                <!-- Failed Results -->
                <div v-if="result.failed > 0">
                  <h3 class="text-lg font-semibold text-red-700 mb-3">
                    ❌ Failed to Create ({{ result.failed }})
                  </h3>
                  <div class="bg-red-50 rounded-lg p-4">
                    <p class="text-sm text-red-800 mb-3">
                      {{ result.failed }} draft email{{
                        result.failed === 1 ? "" : "s"
                      }}
                      failed to be created:
                    </p>
                    <div class="space-y-3 max-h-40 overflow-y-auto">
                      <div
                        v-for="(failedItem, index) in result.failedDetails"
                        :key="index"
                        class="bg-white rounded p-3 border border-red-200"
                      >
                        <div class="flex justify-between items-start mb-2">
                          <span class="font-medium text-gray-900">{{
                            failedItem.name
                          }}</span>
                          <span class="text-sm text-gray-600"
                            >{{ failedItem.email?.address }} ({{
                              failedItem.email?.gender
                            }}, {{ failedItem.email?.language }})</span
                          >
                        </div>
                        <div
                          class="text-sm text-red-700 font-mono bg-red-50 p-2 rounded"
                        >
                          {{ failedItem.additional }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Overall Summary -->
                <div class="bg-blue-50 rounded-lg p-4">
                  <h4 class="font-semibold mb-3">Final Summary</h4>
                  <div
                    class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center"
                  >
                    <div class="bg-white rounded-lg p-3">
                      <div class="text-2xl font-bold text-green-600">
                        {{ result.success.length }}
                      </div>
                      <div class="text-xs text-gray-600">Successful</div>
                    </div>
                    <div class="bg-white rounded-lg p-3">
                      <div class="text-2xl font-bold text-red-600">
                        {{ result.failed }}
                      </div>
                      <div class="text-xs text-gray-600">Failed</div>
                    </div>
                    <div class="bg-white rounded-lg p-3">
                      <div class="text-2xl font-bold text-blue-600">
                        {{ result.success.length + result.failed }}
                      </div>
                      <div class="text-xs text-gray-600">Total Attempted</div>
                    </div>
                  </div>

                  <div class="mt-4 text-center">
                    <p class="text-sm text-gray-700 mb-4">
                      You can now review and send the draft emails from your
                      Gmail drafts folder.
                    </p>
                    <Button
                      @click="openGmailDrafts"
                      variant="outline"
                      class="mr-2"
                    >
                      Open Gmail Drafts
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div
            class="flex justify-between items-center pt-4 border-t border-gray-200 px-6 pb-6 flex-shrink-0"
          >
            <Button
              v-if="currentStep === 2"
              variant="outline"
              @click="currentStep = 1"
            >
              Back
            </Button>
            <Button
              v-else-if="currentStep === 3"
              variant="outline"
              @click="currentStep = 2"
            >
              Back to Review
            </Button>
            <div v-else></div>

            <div class="flex gap-2">
              <Button variant="outline" @click="handleCancel">
                {{ currentStep === 3 ? "Close" : "Cancel" }}
              </Button>

              <Button
                v-if="currentStep === 1"
                @click="handleNext"
                :disabled="
                  !selectedTemplate ||
                  selectedStatuses.length === 0 ||
                  isProcessing
                "
              >
                {{ buttonText }}
              </Button>

              <Button
                v-if="
                  currentStep === 2 &&
                  processResult &&
                  processResult.ready.length > 0
                "
                @click="handleSendDrafts"
                :disabled="isProcessing || isSending"
              >
                {{
                  isSending
                    ? "Creating Drafts..."
                    : `Create ${processResult.ready.length} Draft Emails`
                }}
              </Button>
            </div>
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
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
import {
  companyTemplateCategories,
  speakerTemplateCategories,
  EmailTemplateCategory,
  templateCategoryHumanReadable,
} from "@/lib/templates";
import { humanReadableParticipationStatus } from "@/dto/index";
import type { ParticipationStatus } from "@/dto/index";
import type { CompanyWithParticipation } from "@/dto/companies";
import type { SpeakerWithParticipation } from "@/dto/speakers";
import {
  useBulkCompanyEmails,
  useBulkSpeakerEmails,
  type BulkEmailResult,
} from "@/composables/useBulkEmails";

interface Props {
  size?: "sm" | "default" | "lg" | "icon";
  buttonClass?: string;
  companies?: CompanyWithParticipation[];
  speakers?: SpeakerWithParticipation[];
  entityType: "companies" | "speakers";
}

const props = withDefaults(defineProps<Props>(), {
  size: "sm",
  buttonClass: "",
  companies: () => [],
  speakers: () => [],
});

const emit = defineEmits<{
  success: [template: EmailTemplateCategory, result: BulkEmailResult];
}>();

// Use the appropriate composable based on entity type
const bulkEmailComposable =
  props.entityType === "companies"
    ? useBulkCompanyEmails()
    : useBulkSpeakerEmails();

const {
  processBulkEmails,
  sendProcessedEmails,
  isProcessing,
  isSending,
  processResult,
  result,
  processedCount,
  totalToProcess,
  sentCount,
  totalToSend,
} = bulkEmailComposable;

const isDialogOpen = ref(false);
const currentStep = ref(1);
const selectedTemplate = ref<EmailTemplateCategory | null>(null);
const selectedStatuses = ref<ParticipationStatus[]>([]);

// Available email templates based on entity type
const availableTemplates = computed(() => {
  const templates =
    props.entityType === "companies"
      ? companyTemplateCategories
      : speakerTemplateCategories;

  return templates.map((template) => ({
    value: template,
    label: templateCategoryHumanReadable[template],
  }));
});

// Available participation statuses
const participationStatuses = computed(() => {
  return Object.entries(humanReadableParticipationStatus).map(
    ([value, label]) => ({
      value: value as ParticipationStatus,
      label,
    }),
  );
});

// Computed for button text in config step
const buttonText = computed(() => {
  if (isProcessing.value) {
    return "Processing...";
  }
  return props.entityType === "companies"
    ? "Process Companies"
    : "Process Speakers";
});

// Dynamic text labels based on entity type
const entityLabel = computed(() =>
  props.entityType === "companies" ? "Company" : "Speaker",
);
const entitiesLabel = computed(() =>
  props.entityType === "companies" ? "Companies" : "Speakers",
);

const processingProgress = computed(() => {
  if (isSending.value) {
    // Show sending progress
    const total = totalToSend.value;
    if (total === 0) return 0;
    const sent = sentCount.value;
    return Math.min((sent / total) * 100, 100);
  } else if (isProcessing.value) {
    // Show processing progress
    const total = totalToProcess.value;
    if (total === 0) return 0;
    const processed = processedCount.value;
    return Math.min((processed / total) * 100, 100);
  }
  return 0;
});

const toggleStatusWithValue = (status: ParticipationStatus, value: boolean) => {
  if (value) {
    if (!selectedStatuses.value.includes(status)) {
      selectedStatuses.value.push(status);
    }
  } else {
    selectedStatuses.value = selectedStatuses.value.filter((s) => s !== status);
  }
};

const toggleStatusSimple = (status: ParticipationStatus) => {
  const isSelected = selectedStatuses.value.includes(status);
  toggleStatusWithValue(status, !isSelected);
};

const handleCancel = () => {
  isDialogOpen.value = false;
  currentStep.value = 1;
  selectedTemplate.value = null;
  selectedStatuses.value = [];
};

const handleNext = async () => {
  if (!selectedTemplate.value || selectedStatuses.value.length === 0) {
    return;
  }

  try {
    // Move to review step immediately
    currentStep.value = 2;

    // Process the bulk emails (this will verify emails and prepare data)
    if (props.entityType === "companies") {
      await (processBulkEmails as any)(
        selectedTemplate.value,
        selectedStatuses.value,
        props.companies,
      );
    } else {
      await (processBulkEmails as any)(
        selectedTemplate.value,
        selectedStatuses.value,
        props.speakers,
      );
    }
  } catch (error) {
    const entityName =
      props.entityType === "companies" ? "companies" : "speakers";
    console.error(`Failed to process bulk emails for ${entityName}:`, error);
    alert(
      `Failed to process ${entityName}: ${error instanceof Error ? error.message : "Unknown error"}`,
    );
    // Move back to step 1 if there's an error
    currentStep.value = 1;
  }
};

const handleSendDrafts = async () => {
  try {
    const sendResult = await sendProcessedEmails();
    emit("success", selectedTemplate.value!, sendResult);
    currentStep.value = 3;
  } catch (error) {
    console.error("Failed to send draft emails:", error);
    alert(
      `Failed to create draft emails: ${error instanceof Error ? error.message : "Unknown error"}`,
    );
  }
};

const openGmailDrafts = () => {
  window.open("https://mail.google.com/mail/u/0/#drafts", "_blank");
};
</script>
