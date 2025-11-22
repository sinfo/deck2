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
        <div class="mb-4 flex gap-2 items-center">
          <MemberSelect v-model="newCoordinator" :event-id="selectedEventId" />
          <Button :disabled="creating || !newCoordinator" @click="createTeam"
            >Create</Button
          >
        </div>

        <div v-if="isLoading" class="py-6 text-center">Loading…</div>

        <div v-else-if="teams.length === 0" class="text-zinc-500">
          No coordination teams yet.
        </div>

        <ul>
          <li v-for="t in teams" :key="t.id" class="mb-4">
            <Card class="p-3">
              <div class="flex justify-between items-start gap-4">
                <div class="flex-1">
                  <div class="font-semibold">{{ t.name }}</div>
                  <div class="text-sm text-zinc-600">Coordinated members:</div>
                  <ul class="mt-2">
                    <li
                      v-for="mId in t.coordinatedMembers"
                      :key="mId"
                      class="flex items-center gap-2"
                    >
                      <div class="text-sm text-zinc-700">
                        {{ membersCache[mId]?.name || mId }}
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
                  <div class="text-sm text-zinc-600 flex items-center gap-2">
                    <span class="text-sm text-zinc-600">Coordinator:</span>
                    <div class="flex items-center gap-2">
                      <Image
                        v-if="
                          t.coordinator && membersCache[t.coordinator.member]
                        "
                        :src="membersCache[t.coordinator.member]?.img"
                        :alt="
                          membersCache[t.coordinator.member]?.name ||
                          'coordinator'
                        "
                        class="w-6 h-6 rounded-full object-cover border"
                      />
                      <div class="text-sm text-zinc-700">
                        {{
                          membersCache[t.coordinator?.member || ""]?.name ||
                          (t.coordinator ? t.coordinator.member : "—")
                        }}
                      </div>
                    </div>
                  </div>

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

                    <div class="flex gap-2 items-center">
                      <MemberSelect
                        v-model="selectedCoordinator[t.id]"
                        :event-id="selectedEventId"
                      />
                      <Button
                        :disabled="settingCoordinator[t.id]"
                        @click="assignCoordinatorFor(t)"
                        >Set coordinator</Button
                      >
                    </div>
                  </div>
                </div>

                <div class="flex-shrink-0">
                  <div class="flex gap-2">
                    <Button variant="outline" @click="openEdit(t)">Edit</Button>
                    <Popover v-model:open="deleteConfirmOpen[t.id]">
                      <PopoverTrigger as-child>
                        <Button variant="destructive">Delete</Button>
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
          <Card class="w-96 p-6">
            <h2 class="font-bold mb-3">Edit {{ editing.name }}</h2>
            <Input v-model="editingName" class="mb-3" />
            <div class="flex gap-2 justify-end">
              <Button variant="outline" @click="closeEdit">Cancel</Button>
              <Button :disabled="saving" @click="saveEdit">Save</Button>
            </div>
          </Card>
        </div>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from "vue";
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

const queryCache = useQueryCache();

const newCoordinator = ref<string | undefined>(undefined);
const editing = ref<CoordinationTeam | null>(null);
const editingName = ref("");

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
      alert(
        "Selected member is not a coordinator for the current event. Please pick a coordinator.",
      );
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
};

const closeEdit = () => {
  editing.value = null;
  editingName.value = "";
};

const saveEdit = async () => {
  if (!editing.value) return;
  updateMutate({ id: editing.value.id, data: { name: editingName.value } });
  closeEdit();
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
const selectedCoordinator = reactive<Record<string, string | undefined>>({});
const adding = reactive<Record<string, boolean>>({});
const settingCoordinator = reactive<Record<string, boolean>>({});
const removing = reactive<Record<string, boolean>>({});
const deleting = reactive<Record<string, boolean>>({});

// popover open state maps (keyed by `${teamId}_${memberId}` for removes)
const removeConfirmOpen = reactive<Record<string, boolean>>({});
const deleteConfirmOpen = reactive<Record<string, boolean>>({});

// cache of fetched member objects by id
const membersCache = reactive<
  Record<string, { id: string; name: string; img?: string } | null>
>({});

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

const selectedEventId: number | undefined = undefined; // MemberSelect requires eventId prop; undefined lists all members

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

const assignCoordinatorFor = async (t: CoordinationTeam) => {
  const memberId = selectedCoordinator[t.id];
  if (!memberId) return;
  settingCoordinator[t.id] = true;
  try {
    setCoordinatorMutate({ id: t.id, memberId });
    selectedCoordinator[t.id] = undefined;
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
    settingCoordinator[t.id] = false;
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
