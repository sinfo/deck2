<template>
  <WorkflowCard
    :key="company.id"
    :image="company.imgs?.internal || company.imgs?.public"
    :title="company.name"
    :current-status="company.participation?.status"
    :badges="badges"
    :is-loading="isUpdatingStatus"
    :to="{ name: 'company', params: { companyId: company.id } }"
    @status-change="updateCompanyStatus(company, $event)"
  />
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import type { CompanyWithParticipation } from "@/dto/companies";
import { useCompanyParticipationStepMutation } from "@/mutations/companies";
import { usePackageQuery } from "@/mutations/packages";
import WorkflowCard, { type WorkflowBadge } from "./WorkflowCard.vue";
import { Handshake, Crown, Trophy, Medal, Package } from "lucide-vue-next";

const props = defineProps<{
  company: CompanyWithParticipation;
}>();

// Fetch package data if the company has a package
const packageId = computed(() => props.company.participation?.package);
const { data: packageData } = usePackageQuery(packageId);

// Get appropriate icon and colors for package tier
const getPackageConfig = (packageName: string) => {
  const name = packageName.toLowerCase();
  if (name.includes("platinum")) {
    return {
      icon: Crown,
      color: "text-blue-600",
      bgColor: "bg-blue-100 hover:bg-blue-200",
    };
  }
  if (name.includes("gold")) {
    return {
      icon: Trophy,
      color: "text-yellow-600",
      bgColor: "bg-yellow-100 hover:bg-yellow-200",
    };
  }
  if (name.includes("silver")) {
    return {
      icon: Medal,
      color: "text-gray-400",
      bgColor: "bg-gray-100 hover:bg-gray-200",
    };
  }
  return {
    icon: Package,
    color: "text-muted-foreground",
    bgColor: "bg-muted hover:bg-muted/80",
  };
};

// Build badges array with icons
const badges = computed(() => {
  const result: WorkflowBadge[] = [];
  if (props.company.participation?.partner) {
    result.push({
      icon: Handshake,
      label: "Partner",
      color: "text-emerald-600",
      bgColor: "bg-emerald-100 hover:bg-emerald-200",
    });
  }
  if (packageData.value?.name) {
    const config = getPackageConfig(packageData.value.name);
    result.push({
      icon: config.icon,
      label: packageData.value.name,
      color: config.color,
      bgColor: config.bgColor,
    });
  }
  return result;
});

const companyParticipationStepMutation = useCompanyParticipationStepMutation();
const isUpdatingStatus = ref(false);

const updateCompanyStatus = async (
  company: CompanyWithParticipation,
  step: number,
) => {
  companyParticipationStepMutation.companyId.value = company.id;
  companyParticipationStepMutation.step.value = step;
  isUpdatingStatus.value = true;
  try {
    await companyParticipationStepMutation.mutateAsync();
  } finally {
    isUpdatingStatus.value = false;
  }
};
</script>
