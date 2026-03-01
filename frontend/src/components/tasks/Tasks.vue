<template>
  <div class="p-4 space-y-6">
    <div class="flex items-center justify-between">
      <h2 class="text-lg font-semibold">
        {{ entityType === "company" ? "Company" : "Speaker" }} Tasks Timeline
      </h2>
      <span
        v-if="isSaving"
        class="text-xs text-muted-foreground flex items-center gap-1"
      >
        <Loader2 class="w-3 h-3 animate-spin" /> Saving…
      </span>
      <span v-else class="text-xs text-muted-foreground">Auto-saved</span>
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
        @update:po="onPoUpdate"
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
          :speaker-tasks="speakerTasks"
          @update:hotel="onHotelUpdate"
        />

        <TaskTestSchedule
          :entity-id="entityId"
          :step-number="7"
          :speaker-tasks="speakerTasks"
          @update:test-schedule="onTestScheduleUpdate"
        />
      </template>

      <!-- Images (both entities) -->
      <TaskImages
        :entity-id="entityId"
        :entity-type="entityType"
        :step-number="
          entityType === 'company' ? (showSessionTitles ? 7 : 6) : 8
        "
        :is-last="true"
        :company-public-img-url="
          entityType === 'company'
            ? (companyImgs?.public ?? undefined)
            : undefined
        "
        :speaker-img-url="
          entityType === 'speaker'
            ? (speakerImgs?.speaker ?? undefined)
            : undefined
        "
        :speaker-company-img-url="
          entityType === 'speaker'
            ? (speakerImgs?.company ?? undefined)
            : undefined
        "
      />
    </Stepper>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, provide } from "vue";
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
import type {
  CompanyBillingInfo,
  CompanyImages,
  CompanyParticipation,
} from "@/dto/companies";
import type { SpeakerImages, SpeakerParticipation } from "@/dto/speakers";
import type { Contact } from "@/dto/contacts";
import type { Item } from "@/dto/item";
import { Stepper } from "@/components/ui/stepper";
import { Loader2 } from "lucide-vue-next";
import { useCompanyTasksMutation } from "@/mutations/companies";
import { useSpeakerTasksMutation } from "@/mutations/speakers";
import { TASKS_SAVING_KEY } from "@/composables/useTasksSaving";
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
import TaskTestSchedule from "./TaskTestSchedule.vue";
import TaskImages from "./TaskImages.vue";

interface Props {
  entityType: EntityType;
  entityId: string;
  participation?: CompanyParticipation | SpeakerParticipation;
  billingInfo?: CompanyBillingInfo;
  contact?: Contact;
  companyImgs?: CompanyImages;
  speakerImgs?: SpeakerImages;
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

// ——————————————————————————————————————
// Save mutations
// ——————————————————————————————————————
const companyMutation = useCompanyTasksMutation();
companyMutation.companyId.value = props.entityId;

const speakerMutation = useSpeakerTasksMutation();
speakerMutation.speakerId.value = props.entityId;

const isSaving = ref(false);

// Provide saving state to all child task components so they can disable themselves
provide(TASKS_SAVING_KEY, isSaving);

// ——————————————————————————————————————
// Sync when participation refreshes from server (post-save cache invalidation)
// Guard with isSaving to avoid triggering the save watcher (infinite loop)
// ——————————————————————————————————————
let isSyncing = false;

watch(
  () => props.participation,
  (p) => {
    if (isSaving.value) return; // server refresh caused by our own save — ignore
    isSyncing = true;
    if (props.entityType === "company" && p) {
      const saved = (p as CompanyParticipation).tasks;
      if (saved) Object.assign(companyTasks, saved);
    }
    if (props.entityType === "speaker" && p) {
      const saved = (p as SpeakerParticipation).tasks;
      if (saved) Object.assign(speakerTasks, saved);
    }
    // Use nextTick boundary — reset flag after the watch flush
    setTimeout(() => {
      isSyncing = false;
    }, 0);
  },
);

// ——————————————————————————————————————
// Debounced auto-save
// ——————————————————————————————————————
let saveTimer: ReturnType<typeof setTimeout> | null = null;

function scheduleSave(delayMs = 600) {
  if (isSyncing) return; // don't schedule while applying server data
  if (saveTimer) clearTimeout(saveTimer);
  saveTimer = setTimeout(async () => {
    saveTimer = null;
    if (isSaving.value) return; // already saving
    isSaving.value = true;
    try {
      if (props.entityType === "company") {
        await companyMutation.mutateAsync({ ...companyTasks });
      } else {
        await speakerMutation.mutateAsync({ ...speakerTasks });
      }
    } catch (err) {
      console.error("Auto-save failed:", err);
      toast.error({ title: "Auto-save failed" });
    } finally {
      isSaving.value = false;
    }
  }, delayMs);
}

watch(
  () => JSON.stringify(companyTasks),
  () => scheduleSave(600),
  { deep: true },
);
watch(
  () => JSON.stringify(speakerTasks),
  () => scheduleSave(600),
  { deep: true },
);

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
function onTestScheduleUpdate(schedule: string, done: boolean) {
  speakerTasks.materials.testSchedule = schedule;
  speakerTasks.materials.testDone = done;
}

// ——————————————————————————————————————
// Shared update handlers
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
function onPoUpdate(v: string) {
  companyTasks.po = v;
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
