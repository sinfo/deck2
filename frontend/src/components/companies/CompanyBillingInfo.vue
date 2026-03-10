<template>
  <Card class="w-full">
    <CardHeader>
      <div class="flex items-center justify-between">
        <div>
          <CardTitle class="text-lg">Billing</CardTitle>
          <CardDescription>
            Company details for billing and invoicing
          </CardDescription>
        </div>
        <Button
          v-if="!isEditing && hasBillingInfo"
          variant="outline"
          size="sm"
          :disabled="isUpdating"
          @click="startEditing"
        >
          Edit
        </Button>
      </div>
    </CardHeader>

    <CardContent>
      <!-- Loading State -->
      <div v-if="isLoading" class="text-center text-muted-foreground py-8">
        Loading billing information...
      </div>

      <!-- Editing Form -->
      <div v-else-if="isEditing">
        <BillingForm
          :initial-data="company?.billingInfo"
          :is-loading="isUpdating"
          :mode="hasBillingInfo ? 'edit' : 'create'"
          @submit="handleSubmit"
          @cancel="cancelEditing"
        />
      </div>

      <!-- Display Mode -->
      <div v-else-if="hasBillingInfo" class="space-y-4">
        <div class="space-y-3">
          <div>
            <span class="text-sm font-medium text-muted-foreground"
              >Company Name:</span
            >
            <p class="text-sm">{{ company?.billingInfo?.name }}</p>
          </div>

          <div>
            <span class="text-sm font-medium text-muted-foreground"
              >Address:</span
            >
            <p class="text-sm">{{ company?.billingInfo?.address }}</p>
          </div>

          <div>
            <span class="text-sm font-medium text-muted-foreground"
              >Tax ID (TIN):</span
            >
            <p class="text-sm">{{ company?.billingInfo?.tin }}</p>
          </div>
        </div>

        <ContractDownload
          v-if="canSeeContract"
          :company-id="company?.id as string"
        />
      </div>

      <!-- No Billing Info State -->
      <EmptyStateCard
        v-else
        title="Click here to add billing information"
        @click="startEditing"
      />
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import { ref, computed } from "vue";
import { useCompanyBillingMutation } from "@/mutations/companies";
import type { Company, CompanyBillingInfo } from "@/dto/companies";
import Card from "../ui/card/Card.vue";
import CardContent from "../ui/card/CardContent.vue";
import CardDescription from "../ui/card/CardDescription.vue";
import CardHeader from "../ui/card/CardHeader.vue";
import CardTitle from "../ui/card/CardTitle.vue";
import Button from "../ui/button/Button.vue";
import BillingForm from "./BillingForm.vue";
import EmptyStateCard from "../ui/EmptyStateCard.vue";
import ContractDownload from "./ContractDownload.vue";
import { usePermissions } from "@/composables/usePermissions";

interface Props {
  company?: Company;
  isLoading?: boolean;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  updated: [];
}>();

const isEditing = ref(false);

// Check if billing info exists and has meaningful values
const hasBillingInfo = computed(() => {
  const billingInfo = props.company?.billingInfo;
  if (!billingInfo) return false;

  // Check if any of the main fields have non-empty values
  return !!(
    billingInfo.name?.trim() ||
    billingInfo.address?.trim() ||
    billingInfo.tin?.trim()
  );
});

const billingMutation = useCompanyBillingMutation();
const { mutate: updateBilling, isLoading: isUpdating } = billingMutation;

const { isCoordinatorOrAdmin: canSeeContract } = usePermissions();

const startEditing = () => {
  isEditing.value = true;
};

const cancelEditing = () => {
  isEditing.value = false;
};

const handleSubmit = async (billingInfo: CompanyBillingInfo) => {
  if (!props.company?.id) return;

  billingMutation.companyId.value = props.company.id;
  billingMutation.billingInfo.value = billingInfo;

  try {
    await updateBilling();
    isEditing.value = false;
    emit("updated");
  } catch (error) {
    console.error("Failed to update billing information:", error);
    // You might want to show a toast notification here
  }
};
</script>
