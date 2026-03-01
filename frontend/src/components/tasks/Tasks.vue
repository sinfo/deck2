<template>
  <div class="p-4 space-y-6">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-semibold">
        {{ entityType === "company" ? "Company" : "Speaker" }} Tasks Timeline
      </h2>
      <Button
        variant="default"
        size="sm"
        :disabled="isSaving"
        @click="saveTasks"
      >
        <Save class="w-4 h-4 mr-1" />
        {{ isSaving ? "Saving…" : "Save Tasks" }}
      </Button>
    </div>

    <!-- Stepper Container -->
    <Stepper
      v-model="currentStep"
      orientation="vertical"
      :linear="false"
      class="flex flex-col"
    >
      <TaskConfirmation
        :entity-id="entityId"
        :entity-type="entityType"
        :participation="currentParticipation"
        :contact="contact"
        :company-tasks="companyTasks"
        :speaker-tasks="speakerTasks"
        @package-changed="onPackageChanged"
        @update:company-confirmation="onCompanyConfirmationUpdate"
        @update:speaker-confirmation="onSpeakerConfirmationUpdate"
      />

      <TaskBillingLogos
        :entity-type="entityType"
        :billing-info="billingInfo"
        :entity-id="entityId"
        :company-tasks="companyTasks"
        :speaker-tasks="speakerTasks"
        @update:logos="onLogosUpdate"
        @update:asked-for-info="onAskedForInfoUpdate"
      />

      <TaskContract
        v-if="entityType === 'company'"
        :entity-type="entityType"
        :entity-id="entityId"
        :company-tasks="companyTasks"
        @update:contract="onContractUpdate"
      />

      <!-- Company-only steps -->
      <template v-if="entityType === 'company'">
        <TaskSessionTitles
          v-if="showSessionTitles"
          :package-items="packageItems"
          :company-tasks="companyTasks"
          @update:session-titles="onSessionTitlesUpdate"
        />

        <TaskCorlief
          :entity-id="entityId"
          :step-number="showSessionTitles ? 5 : 4"
          :company-tasks="companyTasks"
          @update:corlief="onCorliefUpdate"
        />

        <TaskLogistics
          :entity-id="entityId"
          :step-number="showSessionTitles ? 6 : 5"
          :is-last="true"
          :company-tasks="companyTasks"
          @update:logistics="onLogisticsUpdate"
        />
      </template>

      <!-- Speaker-only steps -->
      <template v-if="entityType === 'speaker'">
        <TaskFlights
          :entity-id="entityId"
          :step-number="3"
          :speaker-tasks="speakerTasks"
          @update:flights="onFlightsUpdate"
        />

        <TaskCoverage
          :entity-id="entityId"
          :step-number="4"
          :speaker-tasks="speakerTasks"
          @update:coverage="onCoverageUpdate"
        />

        <TaskMaterials
          :entity-id="entityId"
          :step-number="5"
          :speaker-tasks="speakerTasks"
          @update:materials="onMaterialsUpdate"
        />

        <TaskHotel
          :entity-id="entityId"
          :step-number="6"
          :is-last="true"
          :speaker-tasks="speakerTasks"
          @update:hotel="onHotelUpdate"
        />
      </template>
    </Stepper>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from "vue";
import type { EntityType } from "@/dto/tasks";
import {
  type CompanyTasks,
  type SpeakerTasks,
  type TaskLogos,
  type CompanyTaskConfirmation,
  type CompanyTaskContract,
  type CompanyTaskSessionTitles,
  type CompanyTaskCorlief,
  type CompanyTaskLogistics,
  type SpeakerTaskConfirmation,
  type SpeakerTaskFlights,
  type SpeakerTaskCoverage,
  type SpeakerTaskMaterials,
  type SpeakerTaskHotel,
  emptyCompanyTasks,
  emptySpeakerTasks,
} from "@/dto/tasks";
import type { CompanyBillingInfo, CompanyParticipation } from "@/dto/companies";
import type { SpeakerParticipation } from "@/dto/speakers";
import type { Contact } from "@/dto/contacts";
import type { Item } from "@/dto/item";
import { Button } from "@/components/ui/button";
import { Stepper } from "@/components/ui/stepper";
import { Save } from "lucide-vue-next";
import { useCompanyTasksMutation } from "@/mutations/companies";
import { useSpeakerTasksMutation } from "@/mutations/speakers";
import useToast from "@/lib/toast";
import TaskConfirmation from "./TaskConfirmation.vue";
import TaskBillingLogos from "./TaskBillingLogos.vue";
import TaskContract from "./TaskContract.vue";
import TaskSessionTitles from "./TaskSessionTitles.vue";
import TaskCorlief from "./TaskCorlief.vue";
import TaskLogistics from "./TaskLogistics.vue";
import TaskFlights from "./TaskFlights.vue";
import TaskCoverage from "./TaskCoverage.vue";
import TaskMaterials from "./TaskMaterials.vue";
import TaskHotel from "./TaskHotel.vue";

interface Props {
  entityType: EntityType;
  entityId: string;
  participation?: CompanyParticipation | SpeakerParticipation;
  billingInfo?: CompanyBillingInfo;
  contact?: Contact;
}

const props = defineProps<Props>();

const { toast } = useToast();

// ——————————————————————————————————————
// Reactive task state — initialised from participation
// ——————————————————————————————————————
const companyTasks = reactive<CompanyTasks>(
  props.entityType === "company"
    ? {
        ...emptyCompanyTasks(),
        ...((props.participation as CompanyParticipation)?.tasks ?? {}),
      }
    : emptyCompanyTasks(),
);

const speakerTasks = reactive<SpeakerTasks>(
  props.entityType === "speaker"
    ? {
        ...emptySpeakerTasks(),
        ...((props.participation as SpeakerParticipation)?.tasks ?? {}),
      }
    : emptySpeakerTasks(),
);

// Sync when participation changes externally
watch(
  () => props.participation,
  (p) => {
    if (props.entityType === "company" && p) {
      const saved = (p as CompanyParticipation).tasks;
      if (saved) Object.assign(companyTasks, saved);
    }
    if (props.entityType === "speaker" && p) {
      const saved = (p as SpeakerParticipation).tasks;
      if (saved) Object.assign(speakerTasks, saved);
    }
  },
);

// ——————————————————————————————————————
// Save mutations
// ——————————————————————————————————————
const companyMutation = useCompanyTasksMutation();
companyMutation.companyId.value = props.entityId;

const speakerMutation = useSpeakerTasksMutation();
speakerMutation.speakerId.value = props.entityId;

const isSaving = ref(false);

async function saveTasks() {
  isSaving.value = true;
  try {
    if (props.entityType === "company") {
      await companyMutation.mutate({ ...companyTasks });
    } else {
      await speakerMutation.mutate({ ...speakerTasks });
    }
    toast.success({ title: "Tasks saved" });
  } catch (err) {
    console.error("Failed to save tasks:", err);
    toast.error({ title: "Failed to save tasks" });
  } finally {
    isSaving.value = false;
  }
}

// ——————————————————————————————————————
// Child update handlers (company)
// ——————————————————————————————————————
function onCompanyConfirmationUpdate(v: CompanyTaskConfirmation) {
  Object.assign(companyTasks.confirmation, v);
}
function onContractUpdate(v: CompanyTaskContract) {
  Object.assign(companyTasks.contract, v);
}
function onSessionTitlesUpdate(v: CompanyTaskSessionTitles) {
  Object.assign(companyTasks.sessionTitles, v);
}
function onCorliefUpdate(v: CompanyTaskCorlief) {
  Object.assign(companyTasks.corlief, v);
}
function onLogisticsUpdate(v: CompanyTaskLogistics) {
  Object.assign(companyTasks.logistics, v);
}

// ——————————————————————————————————————
// Child update handlers (speaker)
// ——————————————————————————————————————
function onSpeakerConfirmationUpdate(v: SpeakerTaskConfirmation) {
  Object.assign(speakerTasks.confirmation, v);
}
function onFlightsUpdate(v: SpeakerTaskFlights) {
  Object.assign(speakerTasks.flights, v);
}
function onCoverageUpdate(v: SpeakerTaskCoverage) {
  Object.assign(speakerTasks.coverage, v);
}
function onMaterialsUpdate(v: SpeakerTaskMaterials) {
  Object.assign(speakerTasks.materials, v);
}
function onHotelUpdate(v: SpeakerTaskHotel) {
  Object.assign(speakerTasks.hotel, v);
}

// ——————————————————————————————————————
// Shared update handlers (logos / askedForInfo)
// ——————————————————————————————————————
function onLogosUpdate(v: TaskLogos) {
  if (props.entityType === "company") {
    Object.assign(companyTasks.logos, v);
  } else {
    Object.assign(speakerTasks.logos, v);
  }
}
function onAskedForInfoUpdate(v: boolean) {
  if (props.entityType === "company") {
    companyTasks.confirmation.askedForInfo = v;
  } else {
    speakerTasks.askedForInfo = v;
  }
}

// ——————————————————————————————————————
// Package items (company session titles logic)
// ——————————————————————————————————————
const currentParticipation = computed(() => props.participation);
const packageItems = ref<Item[]>([]);

const onPackageChanged = (_name: string, items: Item[]) => {
  packageItems.value = items;
};

const showSessionTitles = computed(() => {
  if (props.entityType !== "company") return false;
  return packageItems.value.some(
    (item) =>
      item.name?.toLowerCase() === "presentation" ||
      item.name?.toLowerCase() === "workshop",
  );
});

const currentStep = ref(0);
</script>
