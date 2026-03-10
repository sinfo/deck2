import { ref, computed, watch, type ComputedRef, type Ref } from "vue";
import createFuzzySearch, { type FuzzyResult } from "@nozbe/microfuzz";
import type { Company } from "@/dto/companies";
import type { Speaker } from "@/dto/speakers";
import type { Member } from "@/dto/members";

/**
 * @packageDocumentation
 *
 * NOTE: microfuzz score semantics:
 * - Lower score = better match (exact match is ~0)
 * So we always sort scores ASC, and use Infinity for no results.
 */

export type GroupId = "companies" | "speakers" | "members";

export type ResultItem =
  | (Company & { type: "company" })
  | (Speaker & { type: "speaker" })
  | (Member & { type: "member" });

type SelectedItem = Company | Speaker | Member;
type AnyId = Company["id"] | Speaker["id"] | Member["id"];

type Args = {
  searchTerm: Ref<string>;
  companies: ComputedRef<Company[]>;
  speakers: ComputedRef<Speaker[]>;
  members: ComputedRef<Member[]>;
  limit?: number;
  memberBias?: number;
};

const DEFAULT_LIMIT = 5;
/**
 * A composable that performs fuzzy search on a list of items based on a search term.
 * @param query - The search term to match against the items.
 * @param src - The source list of items to search through.
 * @param getText - A function that extracts an array of strings from an item for fuzzy matching.
 * @param limit - The maximum number of results to return (defaults to {@link DEFAULT_LIMIT}).
 * @param bias - A bias value added to the best score to influence group ordering (defaults to 0).
 */
function useFuzzy<T>(
  query: ComputedRef<string>,
  src: ComputedRef<T[]>,
  getText: (item: T) => string[],
  limit: number | undefined = DEFAULT_LIMIT,
  bias = 0,
) {
  const f = ref<null | ((q: string) => FuzzyResult<T>[])>(null);

  watch(
    () => src.value,
    (list) => {
      f.value = list.length ? createFuzzySearch(list, { getText }) : null;
    },
    { immediate: true },
  );

  const res = computed<FuzzyResult<T>[]>(() => {
    const term = query.value;
    const fn = f.value;
    if (!term || !fn) return [];
    return fn(term);
  });

  const items = computed<T[]>(() => {
    const list = src.value;
    if (!query.value) return list.slice(0, limit);
    return res.value.map((r) => r.item).slice(0, limit);
  });

  const best = computed(() => (res.value[0]?.score ?? Infinity) + bias);

  return { items, best };
}

export function useCompanySpeakerMemberSearch(args: Args) {
  const limit = args.limit;
  const memberBias = args.memberBias ?? 0;

  const q = computed(() => args.searchTerm.value.trim());

  const c = useFuzzy(
    q,
    args.companies,
    (x: Company) => [x.name, x.description],
    limit,
  );
  const s = useFuzzy(
    q,
    args.speakers,
    (x: Speaker) => [x.name, x.companyName],
    limit,
  );
  const m = useFuzzy(
    q,
    args.members,
    (x: Member) => [x.name],
    limit,
    memberBias,
  );

  const filteredCompanies = c.items;
  const filteredSpeakers = s.items;
  const filteredMembers = m.items;

  const ord: Record<GroupId, number> = {
    companies: 0,
    speakers: 1,
    members: 2,
  };

  const orderedGroups = computed<GroupId[]>(() => {
    if (!q.value) return ["companies", "speakers", "members"];

    const entries: { id: GroupId; score: number; len: number }[] = [
      {
        id: "companies",
        score: c.best.value,
        len: filteredCompanies.value.length,
      },
      {
        id: "speakers",
        score: s.best.value,
        len: filteredSpeakers.value.length,
      },
      { id: "members", score: m.best.value, len: filteredMembers.value.length },
    ];

    entries.sort((a, b) =>
      a.score === b.score ? ord[a.id] - ord[b.id] : a.score - b.score,
    );

    return entries.filter((e) => e.len > 0).map((e) => e.id);
  });

  const results = computed<ResultItem[]>(() => {
    const out: ResultItem[] = [];

    const add = (...items: ResultItem[]) => out.push(...items);

    for (const g of orderedGroups.value) {
      switch (g) {
        case "companies":
          add(
            ...filteredCompanies.value.map((x) => ({
              ...x,
              type: "company" as const,
            })),
          );
          break;

        case "speakers":
          add(
            ...filteredSpeakers.value.map((x) => ({
              ...x,
              type: "speaker" as const,
            })),
          );
          break;

        case "members":
          add(
            ...filteredMembers.value.map((x) => ({
              ...x,
              type: "member" as const,
            })),
          );
          break;
      }
    }

    return out;
  });

  const indexById = computed(() => {
    const map = new Map<AnyId, number>();
    results.value.forEach((r, i) => map.set(r.id as AnyId, i));
    return map;
  });

  const getItemIndex = (item: SelectedItem) => {
    return indexById.value.get(item.id as AnyId) ?? -1;
  };

  return {
    q,
    filteredCompanies,
    filteredSpeakers,
    filteredMembers,
    orderedGroups,
    results,
    getItemIndex,
  };
}
