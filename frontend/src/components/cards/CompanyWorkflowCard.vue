<template>
  <WorkflowCard
    :key="company.id"
    :image="company.imgs?.internal || company.imgs?.public"
    :title="company.name"
    :current-status="company.participation?.status"
    :badge="company.participation?.partner ? 'Partner' : ''"
    :to="{ name: 'company', params: { companyId: company.id } }"
    @status-change="updateCompanyStatus(company, $event)"
  />
</template>

<script setup lang="ts">
import type { CompanyWithParticipation } from "@/dto/companies";
import { useCompanyParticipationStepMutation } from "@/mutations/companies";
import WorkflowCard from "./WorkflowCard.vue";

defineProps<{
  company: CompanyWithParticipation;
}>();

const companyParticipationStepMutation = useCompanyParticipationStepMutation();
const updateCompanyStatus = (
  company: CompanyWithParticipation,
  step: number,
) => {
  companyParticipationStepMutation.companyId.value = company.id;
  companyParticipationStepMutation.step.value = step;
  companyParticipationStepMutation.mutate();
};
</script>
