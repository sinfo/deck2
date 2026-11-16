import type { InjectionKey, Ref } from "vue";

/** Injection key used by Tasks.vue to provide the isSaving state to child task components. */
export const TASKS_SAVING_KEY: InjectionKey<Ref<boolean>> =
  Symbol("tasksSaving");
