import { computed } from "vue";
import type { Ref } from "vue";
import type { ParticipationStatus } from "@/dto";

// Generic composable to filter a Map<string, T[]> by participation.status
export function useParticipationFilter<
  T extends { participation?: { status?: ParticipationStatus } },
>(
  participations: Ref<Map<string, T[]> | undefined>,
  selectedStatus: Ref<ParticipationStatus | null>,
) {
  return computed(() => {
    if (!participations.value) return new Map<string, T[]>();

    if (!selectedStatus.value) return participations.value;

    const map = new Map<string, T[]>();
    for (const [memberId, items] of participations.value.entries()) {
      const filtered = items.filter(
        (it) => it.participation?.status === selectedStatus.value,
      );
      if (filtered.length) map.set(memberId, filtered);
    }

    return map;
  });
}
