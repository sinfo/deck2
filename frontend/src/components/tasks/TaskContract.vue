<template>
  <TaskTimelineItem :step-number="3" title="Contract" :is-complete="isComplete">
    <template #icon>
      <FileText class="w-4 h-4" />
    </template>
    <template #header-actions>
      <StatusToggleBadge
        v-model="hasSentContract"
        active-label="Sent"
        inactive-label="Not Sent"
        description="Mark whether you've sent the contract to the company."
      />
    </template>

    <div class="space-y-4">
      <div class="flex items-center space-x-2">
        <Checkbox id="contract-created" v-model="hasCreatedContract" />
        <Label for="contract-created" class="text-sm"
          >Contract and invoice created</Label
        >
      </div>

      <div class="flex items-center space-x-2">
        <Checkbox id="has-signed" v-model="hasSigned" />
        <Label for="has-signed" class="text-sm">Has signed</Label>
      </div>

      <div class="flex items-center space-x-2">
        <Checkbox id="receipt-sent" v-model="hasReceiptSent" />
        <Label for="receipt-sent" class="text-sm">Receipt sent</Label>
      </div>

      <ContractDownload :company-id="props.companyId" />
    </div>
  </TaskTimelineItem>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import TaskTimelineItem from "./TaskTimelineItem.vue";
import StatusToggleBadge from "./StatusToggleBadge.vue";
import { FileText } from "lucide-vue-next";
import ContractDownload from "../companies/ContractDownload.vue";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";

const props = defineProps<{ companyId: string }>();

// Contract states
const hasCreatedContract = ref(false);
const hasSentContract = ref(false);
const hasSigned = ref(false);
const hasReceiptSent = ref(false);

const isComplete = computed(() => {
  return (
    hasCreatedContract.value &&
    hasSentContract.value &&
    hasSigned.value &&
    hasReceiptSent.value
  );
});

defineExpose({
  isComplete,
});
</script>
