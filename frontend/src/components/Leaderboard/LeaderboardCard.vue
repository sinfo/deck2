<template>
  <Card>
    <CardHeader>
      <h3 class="font-semibold">{{ title }}</h3>
    </CardHeader>
    <CardContent>
      <div v-if="loading" class="p-4">Loading…</div>
      <div v-else-if="rows.length === 0" class="p-4 text-muted-foreground">
        {{ emptyMessage }}
      </div>
      <div v-else class="space-y-4">
        <div
          v-for="row in rows"
          :key="row.memberId"
          :class="[
            'leader-row flex items-center justify-between p-3 border rounded',
            getRowClass(row.rank),
          ]"
        >
          <div class="flex items-center gap-3">
            <div class="w-12 text-sm font-medium flex items-center gap-2">
              <Crown v-if="row.rank === 1" class="h-6 w-6 text-yellow-500" />
              <Trophy
                v-else-if="row.rank === 2"
                class="h-6 w-6 text-slate-400"
              />
              <Star v-else-if="row.rank === 3" class="h-5 w-5" />
              <span v-else class="text-sm">{{ row.rank }}</span>
            </div>

            <MemberWithAvatar :member="row.member" />
          </div>

          <div class="text-sm font-medium">{{ row.count }} {{ itemLabel }}</div>
        </div>
      </div>
    </CardContent>
  </Card>
</template>

<script setup lang="ts">
import type { Member } from "@/dto/members";
import Card from "@/components/ui/card/Card.vue";
import CardContent from "@/components/ui/card/CardContent.vue";
import CardHeader from "@/components/ui/card/CardHeader.vue";
import MemberWithAvatar from "@/components/members/MemberWithAvatar.vue";
import { Crown, Trophy, Star } from "lucide-vue-next";

interface Row {
  memberId: string;
  count: number;
  items: string[];
  member: Member;
  rank: number;
}

withDefaults(
  defineProps<{
    title: string;
    rows: Row[];
    loading?: boolean;
    itemLabel?: string;
    emptyMessage?: string;
  }>(),
  {
    loading: false,
    itemLabel: "items",
    emptyMessage: "No invitations found.",
  },
);

const getRowClass = (rank: number) => {
  switch (rank) {
    case 1:
      return "bg-yellow-50"; // light gold
    case 2:
      return "bg-slate-50"; // light silver
    case 3:
      return "bg-amber-50"; // light bronze/amber
    default:
      return "";
  }
};
</script>

<style scoped>
.leader-row img {
  border-radius: 0.375rem;
}
</style>
