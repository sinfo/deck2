<template>
  <div class="p-4">
    <Card>
      <CardHeader>
        <CardTitle>Coordination Teams</CardTitle>
        <CardDescription
          >Manage coordination teams and their mappings</CardDescription
        >
      </CardHeader>
      <CardContent>
        <div
          class="mb-4 flex flex-col sm:flex-row gap-2 items-start sm:items-center"
        >
          <div class="flex flex-col w-full sm:w-auto">
            <label class="text-sm text-zinc-700 mb-1">Coordinator</label>
            <MemberSelect
              v-model="newCoordinator"
              :event-id="selectedEventId"
            />
          </div>
          <div class="w-full sm:w-auto">
            <Button
              class="w-full sm:w-auto"
              :disabled="creating || !newCoordinator"
              @click="createTeam"
              >Create</Button
            >
          </div>
        </div>

        <div v-if="isLoading" class="py-6 text-center">Loading…</div>

        <div v-else-if="teams.length === 0" class="text-zinc-500">
          No coordination teams yet.
        </div>

        <ul>
          <li v-for="t in teams" :key="t.id" class="mb-4">
            <Card class="p-3">
              <div
                class="flex flex-col md:flex-row justify-between items-start gap-4"
              >
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <Image
                      v-if="t.coordinator && membersCache[t.coordinator.member]"
                      :src="(membersCache[t.coordinator.member] as any)?.img"
                      :alt="
                        (membersCache[t.coordinator.member] as any)?.name ||
                        'coordinator'
                      "
                      class="w-6 h-6 rounded-full object-cover border"
                    />
                    <div class="font-semibold">{{ t.name }}'s Team</div>
                  </div>
                  <div class="text-sm text-zinc-600">Coordinated members:</div>
                  <ul class="mt-2">
                    <li
                      v-for="mId in t.coordinatedMembers"
                      :key="mId"
                      class="flex items-center gap-2"
                    >
                      <div class="flex items-center gap-2">
                        <MemberWithAvatar
                          v-if="membersCache[mId]"
                          :member="membersCache[mId] as any"
                          size="sm"
                        />
                        <div v-else class="text-sm text-zinc-700">
                          {{ mId }}
                        </div>
                      </div>
                      <Popover
                        v-model:open="removeConfirmOpen[t.id + '_' + mId]"
                      >
                        <PopoverTrigger as-child>
                          <Button
                            size="sm"
                            variant="outline"
                            :disabled="removing[t.id + '_' + mId]"
                          >
                            {{
                              removing[t.id + "_" + mId]
                                ? "Removing..."
                                : "Remove"
                            }}
                          </Button>
                        </PopoverTrigger>
                        <PopoverContent class="w-80">
                          <ConfirmDelete
                            title="Remove member"
                            message="Remove this member from the coordination team?"
                            :is-deleting="removing[t.id + '_' + mId]"
                            @cancel="
                              removeConfirmOpen[t.id + '_' + mId] = false
                            "
                            @confirm="removeMemberConfirm(t, mId)"
                          />
                        </PopoverContent>
                      </Popover>
                    </li>
                  </ul>

                  <div class="mt-3 grid grid-cols-1 gap-2">
                    <div class="flex gap-2 items-center">
                      <MemberSelect
                        v-model="selectedTeamToAdd[t.id]"
                        :event-id="selectedEventId"
                      />
                      <Button
                        :disabled="adding[t.id]"
                        @click="addCoordinatedTeamFor(t)"
                        >Add</Button
                      >
                    </div>
                  </div>
                </div>

                <div
                  class="flex-shrink-0 mt-3 md:mt-0 md:ml-4 w-full md:w-auto"
                >
                  <div
                    class="flex flex-col md:flex-row gap-2 items-stretch md:items-center"
                  >
                    <Button
                      class="w-full md:w-auto"
                      variant="outline"
                      @click="openEdit(t)"
                      >Edit</Button
                    >
                    <Popover v-model:open="deleteConfirmOpen[t.id]">
                      <PopoverTrigger as-child>
                        <Button class="w-full md:w-auto" variant="destructive"
                          >Delete</Button
                        >
                      </PopoverTrigger>
                      <PopoverContent class="w-80">
                        <ConfirmDelete
                          title="Delete coordination team"
                          message="Are you sure you want to delete this coordination team? This action cannot be undone."
                          :is-deleting="deleting[t.id]"
                          @cancel="deleteConfirmOpen[t.id] = false"
                          @confirm="deleteTeamConfirm(t)"
                        />
                      </PopoverContent>
                    </Popover>
                  </div>
                </div>
              </div>
            </Card>
          </li>
        </ul>

        <div
          v-if="editing"
          class="fixed inset-0 bg-black/40 flex items-center justify-center"
        >
          <Card class="w-full max-w-md p-6">
            <h2 class="font-bold mb-3">Edit {{ editing.name }} Team</h2>
            <div class="mb-3">
              <label class="text-sm text-zinc-700 mb-1 block">Team name</label>
              <Input v-model="editingName" />
            </div>
            <div class="mb-3">
              <label class="text-sm text-zinc-700 mb-1 block"
                >Coordinator</label
              >
              <MemberSelect
                v-model="editingCoordinator"
                :event-id="selectedEventId"
              />
            </div>
            <div class="flex gap-2 justify-end">
              <Button variant="outline" @click="closeEdit">Cancel</Button>
              <Button :disabled="saving || savingEdit" @click="saveEdit"
                >Save</Button
              >
            </div>
          </Card>
        </div>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from "vue";
import { useEventStore } from "@/stores/event";
import { useQuery, useMutation, useQueryCache } from "@pinia/colada";
import type { CoordinationTeam } from "@/dto/coordinationTeams";
import {
  getAllCoordinationTeams,
  createCoordinationTeam,
  updateCoordinationTeamName,
} from "@/api/coordinationTeams";

import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import CardHeader from "@/components/ui/card/CardHeader.vue";
import CardTitle from "@/components/ui/card/CardTitle.vue";
import CardDescription from "@/components/ui/card/CardDescription.vue";
import Button from "@/components/ui/button/Button.vue";
import Input from "@/components/ui/input/Input.vue";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import ConfirmDelete from "@/components/ConfirmDelete.vue";
import Image from "@/components/Image.vue";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { useToast } from "@/lib/toast";

const queryCache = useQueryCache();

const newCoordinator = ref<string | undefined>(undefined);
const editing = ref<CoordinationTeam | null>(null);
const editingName = ref("");
// coordinator being edited in the modal and original for change detection
const editingCoordinator = ref<string | undefined>(undefined);
const editingOriginalCoordinator = ref<string | undefined>(undefined);
const savingEdit = ref(false);

const { data, isLoading } = useQuery({
  key: ["coordinationTeams"],
  query: () => getAllCoordinationTeams(),
});

const teams = computed(() => data.value?.data || []);

const { mutate: createMutate, isLoading: creating } = useMutation({
  mutation: (variables: { coordinator: string }) =>
    createCoordinationTeam({ coordinator: variables.coordinator }),
  onSuccess: () => {
    queryCache.invalidateQueries({ key: ["coordinationTeams"] });
    newCoordinator.value = undefined;
  },
});

const { mutate: updateMutate, isLoading: saving } = useMutation({
  mutation: (variables: { id: string; data: { name: string } }) =>
    updateCoordinationTeamName(variables.id, variables.data),
  onSuccess: () => queryCache.invalidateQueries({ key: ["coordinationTeams"] }),
});

const createTeam = async () => {
  if (!newCoordinator.value) return;
  try {
    // validate selected member is a coordinator in the current event
    const roleRes = await getMemberRole(newCoordinator.value);
    if (roleRes.data?.role !== "COORDINATOR") {
      toast.error({
        title: "Selected member is not a coordinator",
        description: "Please pick a coordinator.",
      });
      return;
    }
  } catch {
    // If role check fails, log and attempt create — server will return a clear error
    console.warn(
      "Could not validate member role before creating coordination team",
    );
  }

  createMutate({ coordinator: newCoordinator.value });
};

const openEdit = (t: CoordinationTeam) => {
  editing.value = t;
  editingName.value = t.name;
  // prefill coordinator selection in the edit modal
  editingCoordinator.value = t.coordinator?.member;
  editingOriginalCoordinator.value = t.coordinator?.member;
};

const closeEdit = () => {
  editing.value = null;
  editingName.value = "";
  editingCoordinator.value = undefined;
  editingOriginalCoordinator.value = undefined;
};

// (variables returned from hooks above are directly usable in the template)
import MemberSelect from "@/components/members/MemberSelect.vue";
import {
  addCoordinatedTeam,
  setCoordinator,
  deleteCoordinationTeam,
  removeCoordinatedTeam,
} from "@/api/coordinationTeams";
import { getMemberById, getMemberRole } from "@/api/members";

// selected maps and per-team loading states
const selectedTeamToAdd = reactive<Record<string, string | undefined>>({});
const adding = reactive<Record<string, boolean>>({});
const removing = reactive<Record<string, boolean>>({});
const deleting = reactive<Record<string, boolean>>({});

// popover open state maps (keyed by `${teamId}_${memberId}` for removes)
const removeConfirmOpen = reactive<Record<string, boolean>>({});
const deleteConfirmOpen = reactive<Record<string, boolean>>({});

// cached member shape used in this view (subset of Member)
type CachedMember = { id: string; name?: string; img?: string };

// cache of fetched member objects by id
const membersCache = reactive<Record<string, CachedMember | null>>({});

// load member details for any member ids present in teams
const loadMembersForTeams = async () => {
  if (!teams.value) return;
  for (const t of teams.value) {
    if (!t.coordinatedMembers) continue;
    for (const mid of t.coordinatedMembers) {
      if (!mid) continue;
      if (membersCache[mid]) continue;
      try {
        const res = await getMemberById(mid);
        membersCache[mid] = {
          id: res.data.id,
          name: res.data.name,
          img: res.data.img,
        };
      } catch {
        membersCache[mid] = null;
      }
    }
    // also add coordinator member details
    if (t.coordinator && t.coordinator.member) {
      const c = t.coordinator.member;
      if (c && !membersCache[c]) {
        try {
          const res = await getMemberById(c);
          membersCache[c] = {
            id: res.data.id,
            name: res.data.name,
            img: res.data.img,
          };
        } catch {
          membersCache[c] = null;
        }
      }
    }
  }
};

watch(teams, () => {
  loadMembersForTeams();
});

const eventStore = useEventStore();
const selectedEventId = ref<number | undefined>(
  eventStore.selectedEvent?.id ?? undefined,
);
const { toast } = useToast();

// Keep selectedEventId in sync with global selectedEvent
watch(
  () => eventStore.selectedEvent,
  (newEvent) => {
    const newId = newEvent?.id ?? undefined;
    if (selectedEventId.value !== newId) selectedEventId.value = newId;
  },
  { immediate: true },
);

const { mutate: addCoordinatedMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    addCoordinatedTeam(vars.id, { member: vars.memberId }),
  onSuccess: () => queryCache.invalidateQueries({ key: ["coordinationTeams"] }),
});

const { mutate: setCoordinatorMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    setCoordinator(vars.id, { member: vars.memberId }),
  onSuccess: () => queryCache.invalidateQueries({ key: ["coordinationTeams"] }),
});

const addCoordinatedTeamFor = async (t: CoordinationTeam) => {
  const memberId = selectedTeamToAdd[t.id];
  if (!memberId) return;
  adding[t.id] = true;
  try {
    addCoordinatedMutate({ id: t.id, memberId });
    selectedTeamToAdd[t.id] = undefined;
    // optimistic fetch of the member for UI
    try {
      const res = await getMemberById(memberId);
      membersCache[memberId] = {
        id: res.data.id,
        name: res.data.name,
        img: res.data.img,
      };
    } catch {
      membersCache[memberId] = null;
    }
  } finally {
    adding[t.id] = false;
  }
};

// save edited team name and (optionally) coordinator
const saveEdit = async () => {
  if (!editing.value) return;
  savingEdit.value = true;
  try {
    // update name if it changed
    if (editingName.value !== editing.value.name) {
      updateMutate({ id: editing.value.id, data: { name: editingName.value } });
    }

    // if coordinator changed, validate and set
    if (
      editingCoordinator.value !== editingOriginalCoordinator.value &&
      editingCoordinator.value
    ) {
      try {
        const roleRes = await getMemberRole(editingCoordinator.value);
        if (roleRes.data?.role !== "COORDINATOR") {
          toast.error({
            title: "Selected member is not a coordinator",
            description: "Please pick a coordinator.",
          });
          savingEdit.value = false;
          return;
        }
      } catch {
        console.warn(
          "Could not validate member role before assigning coordinator",
        );
      }

      setCoordinatorMutate({
        id: editing.value.id,
        memberId: editingCoordinator.value,
      });
      // optimistic fetch for UI
      try {
        const res = await getMemberById(editingCoordinator.value);
        membersCache[editingCoordinator.value] = {
          id: res.data.id,
          name: res.data.name,
          img: res.data.img,
        };
      } catch {
        membersCache[editingCoordinator.value] = null;
      }
    }
  } finally {
    savingEdit.value = false;
    closeEdit();
  }
};

// remove a coordinated member
const { mutate: removeCoordinatedMutate } = useMutation({
  mutation: (vars: { id: string; memberId: string }) =>
    removeCoordinatedTeam(vars.id, vars.memberId),
  onSuccess: () => queryCache.invalidateQueries({ key: ["coordinationTeams"] }),
});

const removeMemberConfirm = async (t: CoordinationTeam, memberId: string) => {
  try {
    removing[`${t.id}_${memberId}`] = true;
    removeCoordinatedMutate({ id: t.id, memberId });
  } finally {
    removing[`${t.id}_${memberId}`] = false;
    removeConfirmOpen[`${t.id}_${memberId}`] = false;
  }
};

// delete a coordination team
const { mutate: deleteMutate } = useMutation({
  mutation: (id: string) => deleteCoordinationTeam(id),
  onSuccess: () => queryCache.invalidateQueries({ key: ["coordinationTeams"] }),
});

const deleteTeamConfirm = async (t: CoordinationTeam) => {
  try {
    deleting[t.id] = true;
    deleteMutate(t.id);
  } finally {
    deleting[t.id] = false;
    deleteConfirmOpen[t.id] = false;
  }
};
</script>

<style scoped></style>
