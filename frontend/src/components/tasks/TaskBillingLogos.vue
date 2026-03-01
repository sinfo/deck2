<template>
  <TaskTimelineItem
    :step-number="2"
    :title="entityType === 'company' ? 'Billing & Logos' : 'Logos'"
    :is-complete="isComplete"
  >
    <template #icon>
      <Receipt class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasAskedForBillingInfo"
        :description="
          entityType === 'company'
            ? 'Mark whether you\'ve asked the company for billing info and logos.'
            : 'Mark whether you\'ve asked the speaker for logos.'
        "
      />
    </template>

    <div class="space-y-4">
      <!-- Billing Section (companies only) -->
      <template v-if="entityType === 'company'">
        <div class="space-y-2">
          <!-- Billing Header -->
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium">Billing Information</span>

            <Button
              v-if="hasBillingInfo && !isEditingBilling"
              variant="outline"
              size="sm"
              class="h-7 text-xs"
              @click="startEditingBilling"
            >
              Edit
            </Button>
          </div>

          <!-- Billing Info Display -->
          <div
            v-if="hasBillingInfo && !isEditingBilling"
            class="p-3 bg-muted/50 rounded-md space-y-1"
          >
            <p class="text-sm">
              <span class="font-medium">Name:</span>
              {{ billingInfo?.name }}
            </p>
            <p class="text-sm">
              <span class="font-medium">Address:</span>
              {{ billingInfo?.address }}
            </p>
            <p class="text-sm">
              <span class="font-medium">TIN:</span>
              {{ billingInfo?.tin }}
            </p>
          </div>

          <!-- Billing Form (for editing) -->
          <div v-else-if="isEditingBilling" class="border rounded-md p-3">
            <BillingForm
              :initial-data="billingInfo"
              :is-loading="isUpdatingBilling"
              :mode="hasBillingInfo ? 'edit' : 'create'"
              @submit="handleBillingSubmit"
              @cancel="cancelEditingBilling"
            />
          </div>

          <!-- Empty State -->
          <EmptyStateCard
            v-else
            title="Click here to add billing information"
            @click="startEditingBilling"
          />
        </div>

        <!-- Separator -->
        <Separator />
      </template>

      <!-- Logos Section -->
      <div class="space-y-3">
        <span class="text-sm font-medium">Logos</span>

        <div class="flex items-center space-x-2">
          <Checkbox id="logos-received" v-model="logosReceived" />
          <Label for="logos-received" class="text-sm"> Logos received </Label>
        </div>

        <div class="flex items-center space-x-2">
          <Checkbox id="needs-reviewing" v-model="logosNeedReviewing" />
          <Label for="needs-reviewing" class="text-sm flex items-center gap-1">
            Needs reviewing
            <TooltipProvider>
              <Tooltip>
                <TooltipTrigger as-child>
                  <Info class="w-3 h-3 text-muted-foreground cursor-help" />
                </TooltipTrigger>
                <TooltipContent>
                  <p>
                    Check this if the
                    {{ entityType === "company" ? "company" : "speaker" }} wants
                    to review their logos before publishing
                  </p>
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          </Label>
        </div>
      </div>
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Separator } from "@/components/ui/separator";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Info, Receipt } from "lucide-vue-next";
import type { CompanyBillingInfo } from "@/dto/companies";
import type {
  EntityType,
  CompanyTasks,
  SpeakerTasks,
  TaskLogos,
} from "@/dto/tasks";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import BillingForm from "@/components/companies/BillingForm.vue";
import Button from "@/components/ui/button/Button.vue";
import EmptyStateCard from "@/components/ui/EmptyStateCard.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { useCompanyBillingMutation } from "@/mutations/companies";

interface Props {
  entityType: EntityType;
  billingInfo?: CompanyBillingInfo;
  entityId?: string;
  companyTasks?: CompanyTasks;
  speakerTasks?: SpeakerTasks;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  billingUpdated: [];
  "update:logos": [value: TaskLogos];
  "update:askedForInfo": [value: boolean];
}>();

// Billing info
const hasBillingInfo = computed(() => {
  if (!props.billingInfo) return false;
  return !!(
    props.billingInfo.name?.trim() ||
    props.billingInfo.address?.trim() ||
    props.billingInfo.tin?.trim()
  );
});

// Billing editing state
const isEditingBilling = ref(false);
const billingMutation = useCompanyBillingMutation();
const { mutate: updateBilling, isLoading: isUpdatingBilling } = billingMutation;

const startEditingBilling = () => {
  isEditingBilling.value = true;
};

const cancelEditingBilling = () => {
  isEditingBilling.value = false;
};

const handleBillingSubmit = async (data: CompanyBillingInfo) => {
  if (!props.entityId) return;

  billingMutation.companyId.value = props.entityId;
  billingMutation.billingInfo.value = data;

  try {
    await updateBilling();
    isEditingBilling.value = false;
    emit("billingUpdated");
  } catch (error) {
    console.error("Failed to update billing information:", error);
  }
};

// Initialise from saved tasks
const savedLogos =
  props.entityType === "company"
    ? props.companyTasks?.logos
    : props.speakerTasks?.logos;

const savedAsked =
  props.entityType === "company"
    ? props.companyTasks?.confirmation?.askedForInfo
    : props.speakerTasks?.askedForInfo;

// Task states
const hasAskedForBillingInfo = ref(savedAsked ?? false);
const logosReceived = ref(savedLogos?.received ?? false);
const logosNeedReviewing = ref(savedLogos?.needsReviewing ?? false);

watch(hasAskedForBillingInfo, (v) => {
  emit("update:askedForInfo", v);
});

watch([logosReceived, logosNeedReviewing], () => {
  emit("update:logos", {
    received: logosReceived.value,
    needsReviewing: logosNeedReviewing.value,
  });
});

// Completion state
const isComplete = computed(() => {
  if (props.entityType === "company") {
    return hasBillingInfo.value && logosReceived.value;
  }
  // For speakers, only logos matter
  return logosReceived.value;
});

defineExpose({
  isComplete,
});
</script>
