<template>
  <!-- prettier-ignore -->
  <ParticipationsCard
      v-if="companyWithParticipation?.participations"
      :participations="companyWithParticipation.participations"
      :entity-id="companyWithParticipation.id"
      entity-type="company"
      class="mb-5"
    />

  <CompanyCommunications :company="companyWithParticipation" />
</template>

<script setup lang="ts">
import CompanyCommunications from "@/components/companies/CompanyCommunications.vue";
import ParticipationsCard from "@/components/ParticipationsCard.vue";
import type { CompanyWithParticipation } from "@/dto/companies";

defineProps<{
  companyWithParticipation: CompanyWithParticipation;
}>();
</script>
